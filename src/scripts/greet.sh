#!/bin/bash


             helm registry login cciserver.azurecr.io -u $AZURECR_USERNAME -p $AZURECR_PASSWORD
             # Fetch the Helm chart for inspection. Replace `<version>` with the full version of CircleCI server.
             helm fetch oci://cciserver.azurecr.io/circleci-server --version $HELM_VERSION --untar
             export CIRCLE_AGENT_VERSION=$(grep 'circleci/picard:' ./circleci-server/images.yaml | cut -d' ' -f2)
             echo "Circle Agent version for this release is >>>> $CIRCLE_AGENT_VERSION"
             wget https://circleci-binary-releases.s3.amazonaws.com/circleci-agent/$CIRCLE_AGENT_VERSION/linux/amd64/circleci-agent
             wget https://circleci-binary-releases.s3.amazonaws.com/circleci-agent/$CIRCLE_AGENT_VERSION/checksums.txt
             ls -lah
             pwd
             aws s3 rm s3://$AGENT_BUCKET --recursive
             echo $CIRCLE_AGENT_VERSION > release.txt
             agent_version="$CIRCLE_AGENT_VERSION"
             gzip circleci-agent
             aws s3 cp circleci-agent.gz s3://$AGENT_BUCKET/circleci-data/$CIRCLE_AGENT_VERSION/linux/amd64/circleci-agent.gz
             aws s3 cp release.txt s3://$AGENT_BUCKET/circleci-data/$CIRCLE_AGENT_VERSION/release.txt
             aws s3 cp checksums.txt s3://$AGENT_BUCKET/circleci-data/$CIRCLE_AGENT_VERSION/checksums.txt
             # Loop through each file path and set ACL
             for file in "${files[@]}"; do
                 aws s3api put-object-acl --bucket $AGENT_BUCKET --key "$file" \
                     --grant-full-control id=<< pipeline.parameters.canonical-id >> \
                     --grant-read uri=http://acs.amazonaws.com/groups/global/AllUsers \
                     --grant-read-acp uri=http://acs.amazonaws.com/groups/global/AllUsers
             done
