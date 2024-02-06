#!/bin/bash

CERTS=./certs
NEWCERTS=./newcerts
PRIVATE=./private

CA_CN=cacert

# ***** prepare environment *****

[ ! -e ${PRIVATE} ] && mkdir -p ${PRIVATE}
[ ! -e ${CERTS} ] && mkdir -p ${CERTS}
[ ! -e ${NEWCERTS} ] && mkdir -p ${NEWCERTS}

cat /dev/null > index.txt
echo "01" > serial

rm *.old *.attr
rm ${PRIVATE}/* ${CERTS}/* ${NEWCERTS}/*

# ***** create CA certificate *****

./bin/cert-gen.sh -cn ${CA_CN} -selfsign

# ***** create user certificates *****

./bin/cert-gen.sh -cn my-user-cn -server -certfile ${CERTS}/${CA_CN}.pem -keyfile ${PRIVATE}/${CA_CN}.key

