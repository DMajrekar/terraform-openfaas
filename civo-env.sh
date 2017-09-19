export OS_AUTH_URL=https://auth.civo.com/v3
export OS_USER_DOMAIN_NAME=default
export OS_REGION_NAME=lon1

echo "Please enter your Civo OpenStack API Username (from https://www.civo.com/api): "
read -sr OS_USERNAME_INPUT
export OS_USERNAME=$OS_USERNAME_INPUT

echo "Please enter your Civo OpenStack API Password (from https://www.civo.com/api): "
read -sr OS_PASSWORD_INPUT
export OS_PASSWORD=$OS_PASSWORD_INPUT

