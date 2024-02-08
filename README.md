# EasyCA

Scripts for generating CA and certificates easily ;o)

Everytime I have to generate certificates, I struggle on the web to find something easy to use and it became a nightmare ;o)

I came out with these 4 scripts that does the job and I decided to share them ...

Let me know if they have been useful for you !

## Features

- Create a proper CA structure
- Supports different types of sertificates : root / intermediate / server / client
- Supports certificate extensions to add email / domain (for SSL) in the certificates
- Exports certificates in multiple formats : PEM / DER / PKCS12 (for Windows)

## Dependencies

#### openssl

Used to create the certificates

#### mutt

As an email client. Used only by the `cert-pack.sh` script to email certificates to someone

## Installation

- Open a terminal
- Create a directory for your new CA
- Copy the `bin` and the `config` directories in your CA directory

Your ready to go !

## Define your default values

In `cert-gen.sh` you will find a default value section that you can modify to match your needs and make the certificate creation process easier. You can always override thos default values using command line options

Available values :

- Country\*
- State\*
- City
- Organization\*
- Organization unit

\* Mandatory values

## Usage

### ./bin/cert-gen.sh

```
usage: ./bin/cert-gen.sh
    [-cn  | --commonName <common name>]

    [-c   | --country <country id>]
    [-st  | --state <state name>]
    [-l   | --location <city name>]
    [-o   | --organisation <organisation name>]
    [-ou  | --organisationUnit <organisation unit name>]

    [-d   | --domain <domain name (for SSL)>]
    [-e   | --email <email>]

    [--selfsign]
    [-icn | --issuerCommonName <issuer common name>]

    [--days <nb validity days>]
    [--root | --intermediate | --server | --user]

    [-p   | --passphrase]

Note :
- you can use multiple -d options = multiple domain names covered by your certificate
- you can use multiple -e options
```

Command line examples :

```
# Create the ROOT certificate
./bin/cert-gen.sh -cn cacert --root --selfsign

# Create an INTERMEDIATE certificate
./bin/cert-gen.sh -cn my_intermediate_cn -icn cacert --intermediate

# Create SERVER or USER certificates
./bin/cert-gen.sh -cn my_server_cn -icn my_intermediate_cn --server -d www.my_domain.com
./bin/cert-gen.sh -cn my_user_cn -icn my_intermediate_cn --user -e my_user@my_domain.com
```

It does all the work :

- Ask for missing mandatory values if not defined in the defaults or the command line
- Ask for a passphrase to use for the private key and the PKSC12 package

- Creates the certificate request
- Create the private key
- Create the certificate + signature
- Packages the certificate in PEM + PKCS12 (for Windows) formats

### ./bin/ca-gen.sh

This is the script to create it all

It is in there that you can configure all the certificates you need by adding calls to `cert-gen.sh`

WARNING : this script removes everything in the CA before recreating everything. Usually, it will be use once to produce the ROOT certificate then the `cert-gen.sh` script will be your good friend to add other certificates ;o)

You will find examples (in remark in the script) :

- with 1 level of signature
- with 2 level of signature

It verifies :

- directories existance
- work files existance and intialization

Then it runs `cert-gen.sh` to create :

- the main CA certificate (selfsigned)
- the users certificates signed by the CA certificate

# ./bin/cert-info.sh

This script extracts information from the certificates

Available info are :

- certificate subject
- issuer subject
- certificate hash
- validity dates

# ./bin/cert-pack.sh

This script takes the certificate files and ZIP them together

You can provide an email address and the zip fil will be sent

It relies on `mutt` as the email client
