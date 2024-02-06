#!/bin/bash

CERTS=./certs
PRIVATE=./private
TMP=.

# ***** default values *****

CN=
EMAIL=

# ***** command line interpreter *****

function usage
{
	echo "usage: ${0} -cn <common name> [-email <email>]"
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

# ***** prepare ZIP file *****

zip -j ${TMP}/${CN}.zip ${CERTS}/cacert.pem ${CERTS}/${CN}.pem ${CERTS}/${CN}.p12 ${PRIVATE}/${CN}.key

# ***** email if possible *****

if [ ! -z ${EMAIL} ]
then
	echo "EMAIL = "${EMAIL}

	echo "certs = "${CN} > ${TMP}/${CN}.txt
	mutt -s "certs" -a ${TMP}/${CN}.zip -- ${EMAIL} < ${TMP}/${CN}.txt
	rm ${TMP}/${CN}.txt
fi

