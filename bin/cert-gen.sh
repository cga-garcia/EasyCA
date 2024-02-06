#!/bin/bash

CONFIG=./openssl.cnf
CERTS=./certs
PRIVATE=./private

# ***** default values *****

CN=
EMAIL=

C=FR
ST="your-state"
L="your-city"
O="your-organization"
OU=${O}

CERT_LENGTH=2048
CERT_EXPIRE=1095

SIGN_SELF=no
SERVER_CERT=no

# ***** command line interpreter *****

function usage
{
	echo "usage: ${0} -cn <common name> [-email <email>] [-selfsign | -icn | -issuerCn <issuer common name>]"
	echo "            [-c | -country <country id>] [-st | -state <state name>] [-l | -location <city name>]"
	echo "            [-o | -organisation <organisation name>] [-ou | -organisationunit <organisation unit name>]"
	echo "            [-server]"
}

while [ "${1}" != "" ]
do
	case ${1} in
		-cn )
			shift
			CN=${1}
			;;

		-email )
			shift
			EMAIL=${1}
			;;

		-ou | -organisationunit )
			shift
			OU=${1}
			;;

		-o | -organisation )
			shift
			O=${1}
			;;

		-l | -location )
			shift
			L=${1}
			;;

		-st | -state )
			shift
			ST=${1}
			;;

		-c | -country )
			shift
			C=${1}
			;;

		-icn | -issuerCn )
			shift
			ISSUER_CN=${1}
			SIGN_SELF=no
			;;

		-selfsign )
			SIGN_SELF=yes
			;;

		-server )
			SERVER_CERT=yes
			;;

		-h | --help )
			usage
			exit
			;;

		* )
			usage
			exit 1
	esac
	shift
done

# ***** check params *****

if [ "${CN}" = "" ]
then
	echo "ERROR : -cn option is mandatory"
	usage
	exit 2
fi

if [ "${SIGN_SELF}" = "no" & "${ISSUER_CN}" = "" ]
then
	echo "ERROR : -issuerCn option is mandatory"
	usage
	exit 3
fi

# CN=`echo ${CN} | sed -e "s/\./_/g" -e "s/@/_/g" -e "s/ /_/g"`
# ISSUER_CN=`echo ${ISSUER_CN} | sed -e "s/\./_/g" -e "s/@/_/g" -e "s/ /_/g"`

# ***** generate certificate *****

echo
echo "=============================================="
echo "> Generating ${1} certificate"
echo "=============================================="

echo
echo "1. prepare request"
echo

openssl req \
	-config ${CONFIG} \
	-new -newkey rsa:${CERT_LENGTH} \
	-subj "/CN=${CN}/emailAddress=${EMAIL}/O=${O}/OU=${OU}/C=${C}/ST=${ST}/L=${L}" \
	-keyout ${PRIVATE}/${CN}.key -out ${CERTS}/${CN}.req
chmod 600 ${PRIVATE}/${CN}.key

echo
echo "2. create certificate"
echo

SIGN_OPTS="-cert ${CERTS}/${ISSUER_CN}.pem -keyfile ${PRIVATE}/${ISSUER_CN}.key"
if [ "${SIGN_SELF}" = "yes" ]
then
	SIGN_OPTS="-selfsign"
fi

EXTS=
if [ "${SERVER_CERT}" = "yes" ]
then
	EXTS="-extensions server"
fi

openssl ca \
	-config ${CONFIG} \
	-days ${CERT_EXPIRE} \
	${SIGN_OPTS} ${EXTS} \
	-in ${CERTS}/${CN}.req -out ${CERTS}/${CN}.pem
rm ${CERTS}/${CN}.req

openssl x509 \
	-outform DER \
	-in ${CERTS}/${CN}.pem -out ${CERTS}/${CN}.der

HASH=`openssl x509 -noout -hash -in ${CERTS}/${CN}.pem`
for ITER in 0 1 2 3 4 5 6 7 8 9
do
	[ -f "${CERTS}/${HASH}.${ITER}" ] && continue
	ln -s "${CN}.pem" "${CERTS}/${HASH}.${ITER}"
	[ -L "${CERTS}/${HASH}.${ITER}" ] && break
done

echo
echo "3. prepare pkcs12 package"
echo

openssl pkcs12 \
	-export -inkey ${PRIVATE}/${CN}.key \
	-in ${CERTS}/${CN}.pem -out ${CERTS}/${CN}.p12
