"""

Example process to use AWS services via roles anywhere
Does not require aws_signing_helper application

"""

import json
from dotenv import dotenv_values
from iam_rolesanywhere_session import IAMRolesAnywhereSession
import boto3

#call .env file with non-sensitive AWS details
#env_val = dotenv_values("pca/.env")
env_val = dotenv_values("test.cab.local/.env")

# session with a profile with SSM access
#------------------------------------------------
roles_anywhere_session = IAMRolesAnywhereSession(
    trust_anchor_arn=env_val.get('TRUST_ANCHOR_ARN'),
    profile_arn=env_val.get('PROFILE_ARN'),
    role_arn=env_val.get('ROLE_ARN'),
    certificate=env_val.get('CERT_PATH'),
    private_key=env_val.get('PRIVATE_KEY_PATH'),
    private_key_passphrase=env_val.get('PRIVATE_KEY_PASSPHRASE'),
    region='us-east-1',
).get_session()

client = roles_anywhere_session.client('secretsmanager')

# test the ssm access by listing the secrets
response = client.list_secrets()
print('Existing secrets:')
for secret in response['SecretList']:
    print(f'  {secret["Name"]}')
