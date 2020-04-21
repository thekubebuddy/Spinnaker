#!/usr/bin/env bash

bold() {
  echo "* $(tput bold)" "$*" "$(tput sgr0)";
}

EXISTING_SECRET_NAME=$(kubectl get secret -n spinnaker \
  --field-selector metadata.name=="$SECRET_NAME" \
  -o json | jq .items[0].metadata.name)

if [ $EXISTING_SECRET_NAME == 'null' ]; then
  bold "Creating Kubernetes secret $SECRET_NAME..."

  read -p 'Enter your OAuth credentials Client ID: ' CLIENT_ID
  read -p 'Enter your OAuth credentials Client secret: ' CLIENT_SECRET

  cat >~/.spin/config <<EOL
gate:
  endpoint: https://$DOMAIN_NAME/gate

auth:
  enabled: true
  iap:
    # check detailed config in https://cloud.google.com/iap/docs/authentication-howto#authenticating_from_a_desktop_app
    iapClientId: $CLIENT_ID
    serviceAccountKeyPath: "$HOME/.spin/key.json"
EOL

SA_EMAIL=$(gcloud iam service-accounts --project $PROJECT_ID list \
  --filter="displayName:$SERVICE_ACCOUNT_NAME" \
  --format='value(email)')

if [ -z "$SA_EMAIL" ]; then
  bold "Creating service account $SERVICE_ACCOUNT_NAME..."

  gcloud iam service-accounts --project $PROJECT_ID create \
    $SERVICE_ACCOUNT_NAME \
    --display-name $SERVICE_ACCOUNT_NAME

  while [ -z "$SA_EMAIL" ]; do
    SA_EMAIL=$(gcloud iam service-accounts --project $PROJECT_ID list \
      --filter="displayName:$SERVICE_ACCOUNT_NAME" \
      --format='value(email)')
    sleep 5
  done
else
  bold "Using existing service account $SERVICE_ACCOUNT_NAME..."
fi

bold "Assigning required roles to $SERVICE_ACCOUNT_NAME..."

K8S_REQUIRED_ROLES=(cloudbuild.builds.editor container.admin logging.logWriter monitoring.admin pubsub.admin storage.admin)
EXISTING_ROLES=$(gcloud projects get-iam-policy --filter bindings.members:$SA_EMAIL $PROJECT_ID \
  --flatten bindings[].members --format="value(bindings.role)")

for r in "${K8S_REQUIRED_ROLES[@]}"; do
  if [ -z "$(echo $EXISTING_ROLES | grep $r)" ]; then
    bold "Assigning role $r..."
    gcloud projects add-iam-policy-binding $PROJECT_ID \
      --member serviceAccount:$SA_EMAIL \
      --role roles/$r \
      --format=none
  fi
done

  gcloud iam service-accounts keys create ~/.spin/key.json \
    --iam-account $SA_EMAIL \
    --project $PROJECT_ID

  kubectl create secret generic $SECRET_NAME -n spinnaker --from-literal=client_id=$CLIENT_ID \
    --from-literal=client_secret=$CLIENT_SECRET
else
  bold "Using existing Kubernetes secret $SECRET_NAME..."
fi


envsubst < ./backend-config.yml | kubectl apply -f -

# Associate deck service with backend config.
kubectl patch svc -n spinnaker spin-deck --patch \
  "[{'op': 'add', 'path': '/metadata/annotations/beta.cloud.google.com~1backend-config', \
  'value':'{\"default\": \"config-default\"}'}]" --type json

# Change spin-deck service to NodePort:
DECK_SERVICE_TYPE=$(kubectl get service -n spinnaker spin-deck \
  --output=jsonpath={.spec.type})

if [ $DECK_SERVICE_TYPE != 'NodePort' ]; then
  bold "Patching spin-deck service to be NodePort instead of $DECK_SERVICE_TYPE..."

  kubectl patch service -n spinnaker spin-deck --patch \
    "[{'op': 'replace', 'path': '/spec/type', \
    'value':'NodePort'}]" --type json
else
  bold "Service spin-deck is already NodePort..."
fi

# Create ingress:
bold $(envsubst < ./deck-ingress.yml | kubectl apply -f -)

source ./set_iap_properties.sh

gcurl() {
  curl -s -H "Authorization:Bearer $(gcloud auth print-access-token)" \
    -H "Content-Type: application/json" -H "Accept: application/json" \
    -H "X-Goog-User-Project: $PROJECT_ID" $*
}

export IAP_IAM_POLICY_ETAG=$(gcurl -X POST -d "{"options":{"requested_policy_version":3}}" \
  https://iap.googleapis.com/v1beta1/projects/$PROJECT_NUMBER/iap_web/compute/services/$BACKEND_SERVICE_ID:getIamPolicy | jq .etag)

cat ./iap_policy.json | envsubst | gcurl -X POST -d @- \
  https://iap.googleapis.com/v1beta1/projects/$PROJECT_NUMBER/iap_web/compute/services/$BACKEND_SERVICE_ID:setIamPolicy

command -v hal >/dev/null 2>&1 && { echo >&2 "Installing the hal cli for configuring spinnaker security settings.." && ./install_hal.sh --version $HALYARD_VERSION; }


bold "Configuring Spinnaker security settings..."
./configure_hal_security.sh
export HALYARD_POD=$(kubectl get po -l stack=halyard -o jsonpath="{.items[0].metadata.name}")
echo $HALYARD_POD
kubectl exec $HALYARD_POD -n spinnaker -- bash -c 'hal deploy apply'
