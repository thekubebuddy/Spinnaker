#!/usr/bin/env bash
set -o errexit
set -o pipefail

gcurl() {
  curl -s -H "Authorization:Bearer $(gcloud auth print-access-token)" \
    -H "Content-Type: application/json" -H "Accept: application/json" \
    -H "X-Goog-User-Project: $PROJECT_ID" $*
}


bold() {
  echo "* $(tput bold)" "$*" "$(tput sgr0)";
}

EXISTING_SECRET_NAME=$(kubectl get secret -n $NAMESPACE \
  --field-selector metadata.name=="$SECRET_NAME" \
  -o json | jq .items[0].metadata.name)

if [ $EXISTING_SECRET_NAME == 'null' ]; then
  bold "Creating Kubernetes secret $SECRET_NAME..."

  read -p 'Enter your OAuth credentials Client ID: ' CLIENT_ID
  read -p 'Enter your OAuth credentials Client secret: ' CLIENT_SECRET

bold "Setting-up spin CLI with the domain name..."
./install_spin.sh
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

K8S_REQUIRED_ROLES=(cloudbuild.builds.editor container.admin logging.logWriter monitoring.admin storage.admin)
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

  kubectl create secret generic $SECRET_NAME -n $NAMESPACE --from-literal=client_id=$CLIENT_ID \
    --from-literal=client_secret=$CLIENT_SECRET
else
  bold "Using existing Kubernetes secret $SECRET_NAME..."
fi


envsubst < ./backend-config.yml | kubectl apply -f -

# Associate deck service with backend config.
kubectl patch svc -n $NAMESPACE spin-deck --patch \
  "[{'op': 'add', 'path': '/metadata/annotations/beta.cloud.google.com~1backend-config', \
  'value':'{\"default\": \"config-default\"}'}]" --type json

# Change spin-deck service to NodePort:
DECK_SERVICE_TYPE=$(kubectl get service -n $NAMESPACE spin-deck \
  --output=jsonpath={.spec.type})

if [ $DECK_SERVICE_TYPE != 'NodePort' ]; then
  bold "Patching spin-deck service to be NodePort instead of $DECK_SERVICE_TYPE..."

  kubectl patch service -n $NAMESPACE spin-deck --patch \
    "[{'op': 'replace', 'path': '/spec/type', \
    'value':'NodePort'}]" --type json
else
  bold "Service spin-deck is already NodePort..."
fi

# Create ingress:
bold "Creating the ingress resource.."
bold $(envsubst < ./deck-ingress.yml | kubectl apply -f -)

#source ./set_iap_properties.sh
SECRET_JSON=$(kubectl get secret -n $NAMESPACE $SECRET_NAME -o json)
export CLIENT_ID=$(echo $SECRET_JSON | jq -r .data.client_id | base64 -d)
export CLIENT_SECRET=$(echo $SECRET_JSON | jq -r .data.client_secret | base64 -d)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")

bold "Querying for backend service id..."

export BACKEND_SERVICE_ID=$(gcloud compute backend-services list --project $PROJECT_ID \
  --filter="iap.oauth2ClientId:$CLIENT_ID AND description:$NAMESPACE/spin-deck" --format="value(id)")

while [ -z "$BACKEND_SERVICE_ID" ]; do
  bold "Waiting for backend service to be provisioned..."
  sleep 30

  export BACKEND_SERVICE_ID=$(gcloud compute backend-services list --project $PROJECT_ID \
    --filter="iap.oauth2ClientId:$CLIENT_ID AND description:$NAMESPACE/spin-deck" --format="value(id)")
done

export AUD_CLAIM=/projects/$PROJECT_NUMBER/global/backendServices/$BACKEND_SERVICE_ID
export IAP_IAM_POLICY_ETAG=$(gcurl -X POST -d "{"options":{"requested_policy_version":3}}" \
  https://iap.googleapis.com/v1beta1/projects/$PROJECT_NUMBER/iap_web/compute/services/$BACKEND_SERVICE_ID:getIamPolicy | jq .etag)

cat ./iap_policy.json | envsubst | gcurl -X POST -d @- \
  https://iap.googleapis.com/v1beta1/projects/$PROJECT_NUMBER/iap_web/compute/services/$BACKEND_SERVICE_ID:setIamPolicy

# command -v hal >/dev/null 2>&1 && { echo >&2 "Installing the hal cli for configuring spinnaker security settings.." && ./install_hal.sh --version $HALYARD_VERSION; }


bold "Configuring Spinnaker security settings..."

cat <<-EOF>hal-config.sh
hal config security api edit --override-base-url https://$DOMAIN_NAME/gate
hal config security ui edit --override-base-url https://$DOMAIN_NAME
hal config security authn iap edit --audience $AUD_CLAIM
hal config security authn iap enable
hal deploy apply
EOF

chmod +x ./hal-config.sh
export HALYARD_POD=$(kubectl get po -l stack=halyard -n $NAMESPACE -o jsonpath="{.items[0].metadata.name}")
echo $HALYARD_POD
kubectl cp -n $NAMESPACE  ./hal-config.sh $HALYARD_POD:/home/spinnaker/  
kubectl exec $HALYARD_POD -n $NAMESPACE -- bash -c "/home/spinnaker/hal-config.sh"

bold "IAP successfully configured, wait for atmost 30min to get deck-ingress properly configured and DNS changes to propagate"

bold "======================================================================================="
bold "ACTION REQUIRED:"
bold "  - Navigate to: https://console.developers.google.com/apis/credentials/oauthclient/$CLIENT_ID?project=$PROJECT_ID"
bold "  - Add \"https://iap.googleapis.com/v1/oauth/clientIds/$CLIENT_ID:handleRedirect\" to your Web client ID as an Authorized redirect URI."
bold "======================================================================================="

