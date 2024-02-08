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

rm *.old *.attr 2> /dev/null
rm ${PRIVATE}/* ${CERTS}/* ${NEWCERTS}/* 2> /dev/null

# ***** create CA certificate *****

./bin/cert-gen.sh -cn ${CA_CN} --root --selfsign

# ********************************************************************
# ***** create server / user certificates (1 level of signature) *****
# ********************************************************************

# ./bin/cert-gen.sh -cn my_server_cn -icn ${CA_CN} --server -d toto.fr -d titi.fr
# ./bin/cert-gen.sh -cn my_user_cn -icn ${CA_CN} --user -e toto@toto.fr

# ****************************************************************************************
# ***** create intermediate cert + server / user certificates (2 level of signature) *****
# ****************************************************************************************

./bin/cert-gen.sh -cn my_intermediate_cn -icn ${CA_CN} --intermediate

./bin/cert-gen.sh -cn my_server_cn -icn my_intermediate_cn --server -d toto.fr -d titi.fr
./bin/cert-gen.sh -cn my_user_cn -icn my_intermediate_cn --user -e toto@toto.fr -e titi@titi.fr

# ***** verify cert contents *****
# openssl x509 -text -noout -in ./certs/cacert.pem
# openssl x509 -text -noout -in ./certs/my_intermediate_cn.pem
# openssl x509 -text -noout -in ./certs/my_server_cn.pem
# openssl x509 -text -noout -in ./certs/my_user_cn.pem
