#!/usr/bin/env bash

# SHA=$(kubectl get po -n management-portal -oname | grep management-portal-backend -m 1 \
  # | xargs -I {} kubectl get {} -n management-portal -ogo-template --template '{{(index .status.containerStatuses 0).imageID}}' \
  # | sed -n "s/.*sha256:\(.*\)$/\1/p")

IMAGE_RESULTS=$(kubectl get po -n "$NAMESPACE" -oname | grep "$DEPLOYMENT" -m 1 \
  | xargs -I {} kubectl get {} -n "$NAMESPACE" -ogo-template --template '{{(index .status.containerStatuses 0).image}} {{(index .status.containerStatuses 0).imageID}}')

echo "$IMAGE_RESULTS"

IMAGE_RESULTS_ARR=($IMAGE_RESULTS)

IMAGE="${IMAGE_RESULTS_ARR[0]}"
IMAGE_ID="${IMAGE_RESULTS_ARR[1]}"

IMAGE_REPOSITORY=$(echo "${IMAGE}" | sed -n 's/.*amazonaws.com\/\(.*\):.*$/\1/p')
IMAGE_TAG=$(echo "${IMAGE}" | sed -n 's/.*amazonaws.com\/.*:\(.*\)$/\1/p')
IMAGE_DIGEST=$(echo "${IMAGE_ID}" | sed -n 's/.*\(sha256:.*\)$/\1/p')

echo "Current Image: ${IMAGE}"
echo "Current ImageDigest: ${IMAGE_DIGEST}"
echo "Registry: ${REGISTRY}"

ASSUMED_CREDS=$(aws sts assume-role --role-arn arn:aws:iam::901498207434:role/ECRReadOnlyRole --role-session-name Test)
echo "$ASSUMED_CREDS"
export AWS_ACCESS_KEY_ID=$(echo "${ASSUMED_CREDS}" | jq -r .Credentials.AccessKeyId)
export AWS_SECRET_ACCESS_KEY=$(echo "${ASSUMED_CREDS}" | jq -r .Credentials.SecretAccessKey)
export AWS_SESSION_TOKEN=$(echo "${ASSUMED_CREDS}" | jq -r .Credentials.SessionToken)

ECR_IMAGE=$(aws ecr list-images --repository-name "${IMAGE_REPOSITORY}" --registry "${REGISTRY}" | jq --arg IMAGE_TAG "${IMAGE_TAG}" '.imageIds[] | select(.imageTag | contains($IMAGE_TAG))')

if [ -z "${ECR_IMAGE}" ]; then
  echo "Tag does not exist in ECR."
  exit 0
else
  echo "ECR Image: ${ECR_IMAGE}"
  ECR_IMAGE_DIGEST=$(ECR_IMAGE="${ECR_IMAGE}" jq -r -n 'env.ECR_IMAGE | fromjson.imageDigest')
  # [[ "${IMAGE_DIGEST}" == "${ECR_IMAGE_DIGEST}" ]] && echo "Image is up to date." || (kubectl set image deployment/"${DEPLOYMENT}" -n "${NAMESPACE}" "${CONTAINER}"="${IMAGE}" --record && kubectl rollout restart deployment/"${DEPLOYMENT}" -n "${NAMESPACE}")
  [[ "${IMAGE_DIGEST}" == "${ECR_IMAGE_DIGEST}" ]] && echo "Image is up to date." || kubectl rollout restart deployment/"${DEPLOYMENT}" -n "${NAMESPACE}"
fi
