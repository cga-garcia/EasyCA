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

# ********************************************************************
# ***** create server / user certificates (1 level of signature) *****
# ********************************************************************

# ./bin/cert-gen.sh -cn my_server_cn -server -issuerCn ${CA_CN} 
# ./bin/cert-gen.sh -cn my_user_cn -server -issuerCn ${CA_CN} 

# ****************************************************************************************
# ***** create intermediate cert + server / user certificates (2 level of signature) *****
# ****************************************************************************************

./bin/cert-gen.sh -cn my_intermediate_cn -issuerCn ${CA_CN} 

./bin/cert-gen.sh -cn my_server_cn -server -issuerCn my_intermediate_cn 
./bin/cert-gen.sh -cn my_user_cn -issuerCn my_intermediate_cn

