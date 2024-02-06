#!/bin/bash

CERTS=./certs
PRIVATE=./private
TMP=.

# ***** default values *****

CN=

# ***** command line interpreter *****

function usage
{
	echo "usage: ${0} -cn <common name>"
}

while [ "${1}" != "" ]
do
	case ${1} in
		-cn )
			shift
			CN=${1}
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

# ===== prepare ZIP file =====
openssl x509 -dates -noout -in ${CERTS}/${CN}.pem

