# AWS SecretsManager for onprem

Simple example of an on-prem script assuming an AWS IAM Role using AWS IAM Role Anywhere.  

## Setup

To make it work, you have to provision:
- an AWS Private Certificate Authority (ie. a root certificate that will be used to sign the client certificates)
- in AWS IAM Role Anywhere create a trust anchor and profile associated with this root CA
- then create an AWS IAM Role granting read permissions to AWS SecretsManager
- in AWS Certificate Manager create a certificate signed with the private CA created earlier
- download the certificate, certificate chain, private key and install them in a ./pca subfolder
- add a .env file in this ./pca folder containing:
    - TRUST_ANCHOR_ARN="arn:aws:rolesanywhere:region:account:trust-anchor/anchor"
    - PROFILE_ARN="arn:aws:rolesanywhere:region:account:profile/profile"
    - ROLE_ARN="arn:aws:iam::account:role/role"
    - CERT_PATH="./pca/certificate.txt"
    - PRIVATE_KEY_PATH="./pca/private_key.txt"
    - PRIVATE_KEY_PASSPHRASE="my_secret"

Use the provided scripts to automate these steps:
- setup/01-setup-pca.sh
    - to create the AWS Private Certificate Authority
- setup/02-create-cert.sh _machine_name_
    - to create all the resources required to authenticate and authorise one client

The profile/role is attached to the trust anchor using a policy condition,  
the trust anchor is attached to the private certificate authority.  

You can also attach the profile/role to the certificate using another condition (not yet demonstrated).  
At the moment the role is attached to a very permissive policy it should be reduced to offer access only to specific secrets (ie. least privileges).  

## Test

You can test opening a session using ``test.py``, change line 15 and enter the name of your machine ``env_val = dotenv_values("test.cab.local/.env")``.

## Cleanup

You can delete created resources for one client using:
- setup/02-delete-cert.sh _machine_name_

You have to delete the certificate authority manually.  
