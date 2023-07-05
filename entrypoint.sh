#!/bin/sh

set -e

if [ -z "$AWS_S3_BUCKET" ]; then
  echo "AWS_S3_BUCKET is not set. Quitting."
  exit 1
fi

# Default to us-east-1 if AWS_REGION not set.
if [ -z "$AWS_REGION" ]; then
  AWS_REGION="us-east-1"
fi

# Override default AWS endpoint if user sets AWS_S3_ENDPOINT.
if [ -n "$AWS_S3_ENDPOINT" ]; then
  ENDPOINT_APPEND="--endpoint-url $AWS_S3_ENDPOINT"
fi

# Use the AWS directory as source to sync downstream.
# Default to false if AWS_DOWNSTREAM not set.
if [ "$AWS_DOWNSTREAM" = true ]; then
  SOURCE_PATH="s3://${AWS_S3_BUCKET}/${DEST_DIR}" # AWS S3 directory as source
  DEST_PATH="${SOURCE_DIR:-.}"                    # Local directory as destination
else
  SOURCE_PATH="${SOURCE_DIR:-.}"                # Local directory as source
  DEST_PATH="s3://${AWS_S3_BUCKET}/${DEST_DIR}" # AWS S3 directory as destination
fi

CMD_PREFIX="aws s3 sync"
sh -c "${CMD_PREFIX} ${SOURCE_PATH} ${DEST_PATH} ${ENDPOINT_APPEND} $*"

# Clear out credentials after we're done.
# We need to re-run `aws configure` with bogus input instead of
# deleting ~/.aws in case there are other credentials living there.
# https://forums.aws.amazon.com/thread.jspa?threadID=148833
aws configure --profile s3-sync-action <<- EOF > /dev/null 2>&1
null
null
null
text
EOF
