# EasyCA
Scripts for generating CA eaisly ;o)

Everytime I have to generate certificates, I struggle on the web to find something easy to use and it became a nightmare ;o)

I came out with thes 4 scripts that does the job and I decide to put them in security in a github repo
And to share them ...

You get a proper CA structure

You will get your certificates in multiple formats :
- PEM
- DER
- PKCS12 (for Windows)


## dependencies
### openssl
Used to create the certificates

you will find in the package a `openssl.cnf` file that is used to give it minimum config options

### mutt
As an email client

Used only by the `cert-pack.sh` script if you need to send the certificates to someone


## Define your default values
### cert-gen.sh
modify the default values to match your needs

Available values :
- Country
- State
- City
- Organization


## Usage
Open a terminal and create a directory for your new CA

Ensure the `bin` directory and the `openssl.cnf` file are present in this directory
the you can run commands


```
./bin/ca-gen.sh
```
This is the script to create it all

It is in there that you can configure all the certificates you need by adding calls to `cert-gen.sh`

You will find in examples (in remark in the script) :
- with 1 level of signature
- with 2 level of signature

It verifies :
- directories existance
- work files existance and intialization

Then it runs `cert-gen.sh` to create :
- the main CA certificate (selfsigned)
- the users certificates signed by the CA certificate


```
./bin/cert-gen.sh
```
This is the main script that pilots `openssl`

It does all the work :
- creates the certificate request
- create the private key
- create the certificate + signature
- packages the certificate in PEM + PKCS12 (for Windows) formats

The script asks some questions during the creation process = answear 'y'

Then it asks for a passphrase = this is for the PKCS12 package that contains the public AND the private key. So it has to be crypted

It is possible to set an empty passphrase even if this is a bit dangerous.


```
./bin/cert-info.sh
```
This script extracts information from the certificates

Available info are :
- certificate subject
- issuer subject
- certificate hash
- validity dates


```
./bin/cert-pack.sh
```
This script takes the certificate files and ZIP them together

You can provide an email address and the zip fil will be sent

It relies on `mutt` as the email client
