#!/bin/sh

if [ $# -ne 3 ] 
then
	echo "USAGE: $0 API_ENDPOINT REFRESH_TOKEN PUBLICATION_NAME"  
	echo "Where API_ENDPOINT is your API 1.5 endpoint found in the CM portal."
	echo "Where REFRESH_TOKEN is your refresh token found in the CM portal."
	echo "Where PUBLICATION_NAME is the actual name (e.g. the name of the ServerTemplate) of the item you want to find."
	exit 1
fi

my_token_endpoint=${1}
my_refresh_token=${2}
publication_name=${3}
base_uri=`echo ${my_token_endpoint} | cut -d"/" -f1,2,3`
tmpfile="./$0.tmp"

curl --include \
  -H "X-API-Version:1.5" \
  --request POST "$my_token_endpoint" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=$my_refresh_token"  |
sed 's/,/\
/g' > $tmpfile

access_token=`grep "access_token" $tmpfile |
cut -d":" -f2 |
sed 's/}//g' |
sed 's/\"//g'` 

rm $tmpfile

curl --include \
     -H "X-API-Version:1.5" \
     -H "Authorization: Bearer $access_token" \
     -X GET \
     -d filter[]="name==${publication_name}" \
${base_uri}/api/publications.xml
