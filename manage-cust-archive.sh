#!/bin/bash
OCP_USERNAME=$1
OCP_PASSWORD=$2
OCP_SERVER=$3
# AWS_BUCKET Example: s3://<bucketname>/customer/masdemo
AWS_BUCKET=$4
# AWS_BUCKER_URL Example: https://<bucketname>.s3.amazonaws.com/customer/masdemo/
AWS_BUCKET_URL=$5
# Constants for the script
NS=mas-inst1-manage
MW=ManageWorkspace
MWN=inst1-masdemo
DATE_TIMESTAMP=$(date +%Y%m%d%H%M%S)
GIT_LAST_COMMIT=$(git rev-parse --short HEAD)


die () {
    echo >&2 "$@"
    exit 1
}
# Validate arguments count
argDie () {
    [ "$1" -eq "$2" ] || die "$1 argument(-s) required, $2 provided. $3"
}

argDie 5 $# "USAGE: <ocp_username> <ocp_password> <ocp_server> <customization_archive_url> <aws_bucket> <aws_bucket_url>"

# ---------------------------------------------------------------------
# 1. Create zip file from manage folder and put it to build folder
# ---------------------------------------------------------------------
CUST_ARCHIVE_FILE_NAME=$DATE_TIMESTAMP-custarch-$GIT_LAST_COMMIT.zip
echo "1. Create zip file from manage folder and put it to build folder"
[ -d build ] || mkdir build
rm -rf build/*
(cd manage && zip -r ../build/$CUST_ARCHIVE_FILE_NAME .)


# ---------------------------------------------------------------------
# 2. Create zip file from manage folder and put it to build folder
# --------------------------------------------------------------------- 
PATH_TO_CUST_ARCHIVE=./build/$CUST_ARCHIVE_FILE_NAME
echo "2. Upload customisation archive to S3 bucket: $PATH_TO_CUST_ARCHIVE"
aws s3 cp $PATH_TO_CUST_ARCHIVE $AWS_BUCKET/$CUST_ARCHIVE_FILE_NAME --acl public-read


# Check if the file exists at the given S3 URL
CUST_ARCHIVE_URL=$AWS_BUCKET_URL$CUST_ARCHIVE_FILE_NAME
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$CUST_ARCHIVE_URL")
if [ "$HTTP_STATUS" -ne 200 ]; then
  die "Customization archive file does not exist at $CUST_ARCHIVE_URL"
fi

echo "Customization archive file exists at $CUST_ARCHIVE_URL"

# ---------------------------------------------------------------------
# 3. Update customisation archive in ManageWorkspace definition
# ---------------------------------------------------------------------
echo "2. Update customisation archive in ManageWorkspace definition"
oc login $OCP_SERVER -u $OCP_USERNAME -p $OCP_PASSWORD --insecure-skip-tls-verify=true
if [ $? -ne 0 ]; then
  echo "Failed to login to OpenShift cluster"
  exit 1
fi
echo "Successfully logged in to OpenShift cluster"
oc project $NS
if [ $? -ne 0 ]; then
  echo "Failed to switch to project $NS"
  exit 1
fi
echo "Successfully switched to project $NS"

# Display current customisation archive file url
CURRENT_CUST_URL=$(oc get $MW $MWN -n $NS -o yaml | yq '.spec.settings.customizationList[0].customizationArchiveUrl')
echo "Current Customization Archive URL: $CURRENT_CUST_URL"
echo "New Customization Archive URL: $CUST_ARCHIVE_URL"

# Apply new customisation archive file url
oc get $MW $MWN -n $NS -o yaml \
    | CUST_ARCHIVE_URL="$CUST_ARCHIVE_URL" yq '.spec.settings.customizationList[0].customizationArchiveUrl = strenv(CUST_ARCHIVE_URL)' \
    | oc apply -f -