#!/bin/bash

# ***** default values *****

C=FR					# Country
ST="Some state"			# State
L=						# City
O="Some organization"	# Organization
OU=						# Organization unit

KEY_LENGTH=2048
CERT_DAYS=1095			# 3 years

# ***** other variables *****

CONFIG=./config
CERTS=./certs
NEWCERTS=./newcerts
PRIVATE=./private

BASE_CNF_FILE=${CONFIG}/openssl.cnf
SELF_SIGN=no

# ***** error handling *****

function handle_error()
{
    if [ $1 -ne 0 ]
    then
        echo "NOK"
        echo "ERROR : \"$2\" exited with code $1"

		[ -f $3 ] && cat $3
    fi
	[ -f $3 ] && rm $3
    
    return $1
}

# ***** command line interpreter *****

function usage()
{
	echo "usage: ${0}"
	echo "    [-cn  | --commonName <common name>]"
	echo
	echo "    [-c   | --country <country id>]"
	echo "    [-st  | --state <state name>]"
	echo "    [-l   | --location <city name>]"
	echo "    [-o   | --organisation <organisation name>]"
	echo "    [-ou  | --organisationUnit <organisation unit name>]"
	echo
	# echo "    [-san | --subjectAltName <subject alternative name>]"
	echo "    [-d   | --domain <domain name (for SSL)>]"
	echo "    [-e   | --email <email>]"
	echo
	echo "    [--selfsign]"
	echo "    [-icn | --issuerCommonName <issuer common name>]"
	echo
	echo "    [--days <nb validity days>]"
	echo "    [--root | --intermediate | --server | --user]"
	echo
	echo "    [-p   | --passphrase]"
	echo
	echo "Note :"
	# echo "- you can use multiple -san options"
	echo "- you can use multiple -d options = multiple domain names covered by your certificate"
	echo "- you can use multiple -e options"
}

while [ "${1}" != "" ]
do
	case ${1} in
		-cn | --commonName )
			shift
			CN=${1}
			;;

		# -san | --subjectAltName )
		# 	shift
		# 	SANS="${SANS}|${1}"
		# 	;;

		-d | --domain )
			shift
			DOMAINS="${DOMAINS}|${1}"
			;;

		-e | --email )
			shift
			EMAILS="${EMAILS}|${1}"
			;;

		-ou | --organisationUnit )
			shift
			OU=${1}
			;;

		-o | --organisation )
			shift
			O=${1}
			;;

		-l | --location )
			shift
			L=${1}
			;;

		-st | --state )
			shift
			ST=${1}
			;;

		-c | --country )
			shift
			C=${1}
			;;

		-icn | --issuerCommonName )
			shift
			ISSUER_CN=${1}
			SELF_SIGN=no
			;;

		-p | --passphrase )
			shift
			PASSPHRASE=${1}
			;;

		--days )
			shift
			CERT_DAYS=${1}
			;;

		--selfsign )
			ISSUER_CN=
			SELF_SIGN=yes
			;;

		--root )
			CERT_TYPE=root
			;;

		--intermediate )
			CERT_TYPE=intermediate
			;;

		--server )
			CERT_TYPE=server
			;;

		--user )
			CERT_TYPE=user
			;;

		-h | --help )
			echo "HELP requested ;o)"
			usage
			exit
			;;

		* )
			echo "UNKNOWN option ${1}"
			usage
			exit 1
	esac
	shift
done

SANS=`echo "${SANS}" | sed -e "s/^|//"`
DOMAINS=`echo "${DOMAINS}" | sed -e "s/^|//"`
EMAILS=`echo "${EMAILS}" | sed -e "s/^|//"`

# ***** check params *****

if [ -z "${CERT_TYPE}" ]
then
	echo "ERROR : one of --root / --intermediate / --server / --user options is mandatory"
	usage
	exit 2
fi

if [ -z "${CN}" ]
then
	# ***** lookup first SANS / DOMAINS / EMAILS to create a fake CN (used also as CERT_NAME to create files) *****
	CN=`echo "${SANS}||${DOMAINS}||${EMAILS}" | sed -e "s/^[|]*//" | sed -e "s/[|]*$//" | sed -e "s/^\([^|]*\)||.*$/\1/"`
	CN=`echo ${CN} | sed -e "s/\./_/g" -e "s/@/_/g" -e "s/ /_/g"`
fi

if [ -z "${CN}" ]
then
	echo "ERROR : one of -cn / -san / -d / -e options is mandatory"
	usage
	exit 3
fi

if [ "${SELF_SIGN}" = "no" -a -z "${ISSUER_CN}" ]
then
	echo "ERROR : one of --selfsign / -icn option is mandatory"
	usage
	exit 4
fi

CERT_NAME=${CN}

# ********************************
# ***** generate certificate *****
# ********************************

# ***** prepare environment *****

[ ! -e ${PRIVATE} ] && mkdir -p ${PRIVATE}
[ ! -e ${CERTS} ] && mkdir -p ${CERTS}
[ ! -e ${NEWCERTS} ] && mkdir -p ${NEWCERTS}

[ ! -f index.txt ] && cat /dev/null > index.txt
[ ! -f serial ] && echo "01" > serial

echo "=============================================="
echo "Generating certificate : ${CN}"
echo "=============================================="
echo

# ***** capture additional values *****

if [ -z "${C}" -o -z "${ST}" -o -z "${C}" ]
then
	echo "Enter missing mandatory info"
	echo "----------------------------"
	echo

	[ -z "${C}" ] 		&& read -p "Country ................ : " C
	[ -z "${ST}" ] 		&& read -p "State .................. : " ST
	[ -z "${O}" ] 		&& read -p "Organization ........... : " O
	echo
fi

if [ -z "${PASSPHRASE}" ]
then
	[ -z "${PASSPHRASE}" ] 	&& (echo -n "Passphrase ............. : "; read -r -s PASSPHRASE)
	echo
	echo
fi

echo -n "- Prepare config file .. : "

# ***** prepare subject *****

SUBJ=
[ -n "${CN}" ] 	&& SUBJ="/CN=${CN}${SUBJ}"
[ -n "${C}" ] 	&& SUBJ="/C=${C}${SUBJ}"
[ -n "${ST}" ] 	&& SUBJ="/ST=${ST}${SUBJ}"
[ -n "${L}" ] 	&& SUBJ="/L=${L}${SUBJ}"
[ -n "${O}" ] 	&& SUBJ="/O=${O}${SUBJ}"
[ -n "${OU}" ] 	&& SUBJ="/OU=${OU}${SUBJ}"

# ***** prepare cert cnf file *****

CNF_FILE=./${CERT_NAME}.cnf
cp ${BASE_CNF_FILE} ${CNF_FILE}

# ***** add extension info *****

if [ -n "${SANS}" -o -n "${DOMAINS}" -o -n "${EMAILS}" ]
then

	if [ -n "${SANS}" ]
	then
		SANS=`echo ${SANS} | sed -e "s/ /#/g" | sed -e "s/|/ /g"`

		cnt=1
		for SAN in ${SANS}
		do
			[ -z "${SAN}" ] && continue

			SAN=`echo ${SAN} | sed -e "s/#/ /g"`
			echo "otherName.${cnt} = ${SAN}" >> ${CNF_FILE}
			((cnt=cnt+1))
		done
	fi

	if [ -n "${DOMAINS}" ]
	then
		DOMAINS=`echo ${DOMAINS} | sed -e "s/ /#/g" | sed -e "s/|/ /g"`

		cnt=1
		for DOMAIN in ${DOMAINS}
		do
			[ -z "${DOMAIN}" ] && continue

			DOMAIN=`echo ${DOMAIN} | sed -e "s/#/ /g"`
			echo "DNS.${cnt} = ${DOMAIN}" >> ${CNF_FILE}
			((cnt=cnt+1))
		done
	fi

	if [ -n "${EMAILS}" ]
	then
		EMAILS=`echo ${EMAILS} | sed -e "s/ /#/g" | sed -e "s/|/ /g"`

		cnt=1
		for EMAIL in ${EMAILS}
		do
			[ -z "${EMAIL}" ] && continue

			EMAIL=`echo ${EMAIL} | sed -e "s/#/ /g"`
			echo "email.${cnt} = ${EMAIL}" >> ${CNF_FILE}
			((cnt=cnt+1))
		done
	fi

	echo >> ${CNF_FILE}
else
	# ***** no extensions = remove references from config *****
	cat ${CNF_FILE} | sed -e "/^subjectAltName/d" > ${CNF_FILE}.tmp
	mv ${CNF_FILE}.tmp ${CNF_FILE}
fi

echo "OK"

# ***** create private key *****

echo -n "- Create private key ... : "

openssl genrsa \
	-passout "pass:${PASSPHRASE}" \
	-out ${PRIVATE}/${CERT_NAME}.key \
	${KEY_LENGTH} \
	2> ${CERT_NAME}.err 1> /dev/null

handle_error $? "openssl rsagen ..." ${CERT_NAME}.err || exit
echo "OK"

# ***** create certificate request *****

echo -n "- Create cert request .. : "

openssl req \
	-config ${CNF_FILE} \
	-reqexts "req_ext" \
	-new \
	-subj "${SUBJ}" \
	-passin "pass:${PASSPHRASE}" -passout "pass:${PASSPHRASE}" \
	-key ${PRIVATE}/${CERT_NAME}.key -out ${CERTS}/${CERT_NAME}.req 
	# 2> ${CERT_NAME}.err 1> /dev/null

handle_error $? "openssl req ..." ${CERT_NAME}.err || exit

chmod 600 ${PRIVATE}/${CERT_NAME}.key

echo "OK"

# ***** create certificate *****

echo -n "- Create certificate ... : "

if [ "${SELF_SIGN}" = "yes" ]
then
	SIGN_OPTS="-selfsign"
else
	SIGN_OPTS="-cert ${CERTS}/${ISSUER_CN}.pem -keyfile ${PRIVATE}/${ISSUER_CN}.key"
fi

openssl ca \
	-config ${CNF_FILE} \
	-extensions "${CERT_TYPE}" \
	-batch -notext \
	-days ${CERT_DAYS} \
	${SIGN_OPTS} \
	-passin "pass:${PASSPHRASE}" \
	-in ${CERTS}/${CERT_NAME}.req -out ${CERTS}/${CERT_NAME}.pem \
	2> ${CERT_NAME}.err 1> /dev/null

handle_error $? "openssl ca ..." ${CERT_NAME}.err || exit

rm ${CNF_FILE}
rm ${CERTS}/${CERT_NAME}.req

echo "OK"

# ***** export DER *****

echo -n "- Export DER ........... : "

openssl x509 \
	-outform DER \
	-passin "pass:${PASSPHRASE}" \
	-in ${CERTS}/${CERT_NAME}.pem -out ${CERTS}/${CERT_NAME}.der \
	2> ${CERT_NAME}.err 1> /dev/null

handle_error $? "openssl x509 ..." ${CERT_NAME}.err || exit

# *****

HASH=`openssl x509 -noout -hash -in ${CERTS}/${CERT_NAME}.pem`
for ITER in 0 1 2 3 4 5 6 7 8 9
do
	[ -f "${CERTS}/${HASH}.${ITER}" ] && continue
	ln -s "${CERT_NAME}.pem" "${CERTS}/${HASH}.${ITER}"
	[ -L "${CERTS}/${HASH}.${ITER}" ] && break
done

echo "OK"

# ***** export PKCS12 *****

echo -n "- Export PKCS12 ........ : "

openssl pkcs12 \
	-export -inkey ${PRIVATE}/${CERT_NAME}.key \
	-passin "pass:${PASSPHRASE}" -passout "pass:${PASSPHRASE}" \
	-in ${CERTS}/${CERT_NAME}.pem -out ${CERTS}/${CERT_NAME}.p12 \
	2> ${CERT_NAME}.err 1> /dev/null

handle_error $? "openssl pkcs12 ..." ${CERT_NAME}.err || exit

echo "OK"
echo