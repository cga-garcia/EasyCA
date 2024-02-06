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

# ***** command line interpreter *****

function usage
{
	echo "usage: ${0} -cn <common name> [-email <email>] [-selfsign | -certfile <cert file path> -keyfile <key file path>]"
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

		-keyfile )
			shift
			SIGN_KEY=${1}
			[ -z ${SIGN_SELF} ] && SIGN_SELF=no
			;;

		-certfile )
			shift
			SIGN_CERT=${1}
			[ -z ${SIGN_SELF} ] && SIGN_SELF=no
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

PREFIX=`echo ${CN}-${EMAIL} | sed -e "s/\./_/g" -e "s/@/_/g" -e "s/ /_/g" -e "s/-$//"`

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
	-new -newkey rsa:${CERT_LENGTH} -nodes \
	-subj "/CN=${CN}/emailAddress=${EMAIL}/O=${O}/OU=${OU}/C=${C}/ST=${ST}/L=${L}" \
	-keyout ${PRIVATE}/${PREFIX}.key -out ${CERTS}/${PREFIX}.req
chgrp ssl-cert ${PRIVATE}/${PREFIX}.key
chmod 600 ${PRIVATE}/${PREFIX}.key

echo
echo "2. create certificate"
echo

SIGN_OPTS="-cert ${SIGN_CERT} -keyfile ${SIGN_KEY}"
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
	-in ${CERTS}/${PREFIX}.req -out ${CERTS}/${PREFIX}.pem
rm ${CERTS}/${PREFIX}.req

HASH=`openssl x509 -noout -hash -in ${CERTS}/${PREFIX}.pem`
for ITER in 0 1 2 3 4 5 6 7 8 9
do
	[ -f "${CERTS}/${HASH}.${ITER}" ] && continue
	ln -s "${PREFIX}.pem" "${CERTS}/${HASH}.${ITER}"
	[ -L "${CERTS}/${HASH}.${ITER}" ] && break
done

echo
echo "3. prepare pkcs12 package"
echo

openssl pkcs12 \
	-export -inkey ${PRIVATE}/${PREFIX}.key \
	-in ${CERTS}/${PREFIX}.pem -out ${CERTS}/${PREFIX}.p12
