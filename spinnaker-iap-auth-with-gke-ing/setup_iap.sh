#!/usr/bin/env bash
set -o errexit
set -o pipefail


bold() {
  echo "* $(tput bold)" "$*" "$(tput sgr0)";
}
bold "Invoking the propety file"

source ./properties

REQUIRED_APIS="container.googleapis.com endpoints.googleapis.com iap.googleapis.com monitoring.googleapis.com"
NUM_REQUIRED_APIS=$(wc -w <<< "$REQUIRED_APIS")
NUM_ENABLED_APIS=$(gcloud services list --project $PROJECT_ID \
  --filter="config.name:($REQUIRED_APIS)" \
  --format="value(config.name)" | wc -l)

if [ $NUM_ENABLED_APIS != $NUM_REQUIRED_APIS ]; then
  bold "Enabling required APIs ($REQUIRED_APIS) in $PROJECT_ID..."
  bold "This phase will take a few minutes (progress will not be reported during this operation)."
  bold
  bold "Once the required APIs are enabled, the remaining components will be installed and configured. The entire installation may take 10 minutes or more."

  gcloud services --project $PROJECT_ID enable $REQUIRED_APIS
fi

bold "Checking the hostname name max length \"$HOST_NAME\""

HOST_NAME_LENGTH=$(echo -n $HOST_NAME | wc -m)

if [ "$HOST_NAME_LENGTH" -gt "63" ]; then
  echo "hostname name $HOST_NAME is greater than 63 characters. Please specify a \
hostname name not longer than 63 characters. The domain name is specified in the \
properties file."
  exit 1
fi


export IP_ADDR=$(gcloud compute addresses list --filter="name=$STATIC_IP_NAME" \
  --format="value(address)" --global --project $PROJECT_ID)

if [ -z "$IP_ADDR" ]; then
  bold "Creating static IP address $STATIC_IP_NAME..."

  gcloud compute addresses create $STATIC_IP_NAME --global --project $PROJECT_ID

  export IP_ADDR=$(gcloud compute addresses list --filter="name=$STATIC_IP_NAME" \
    --format="value(address)" --global --project $PROJECT_ID)
else
   bold "Using existing static IP address $STATIC_IP_NAME ($IP_ADDR)..."
fi


CURRENT_IP_ADDR=$(dig +short $HOST_NAME)

if [ -z "$CURRENT_IP_ADDR" ]; then
  CURRENT_IP_ADDR="UNRESOLVABLE"
fi

bold "Using existing host $HOST_NAME ($CURRENT_IP_ADDR)..."

if [ $CURRENT_IP_ADDR != $IP_ADDR ]; then
  bold "** This host currently resolves to $CURRENT_IP_ADDR
   ** You must configure $HOST_NAME's DNS settings such that it instead resolves to $IP_ADDR
   ** Or if you already configured than hold your breath until DNS is propagated properly.!"
  exit 0
fi

bold "======================================================================================="
bold ">>>> Configure the OAuth 2.0 Client ID (Web application-type)  <<<<"
bold "https://console.developers.google.com/apis/credentials?project=$PROJECT_ID"
bold "======================================================================================="

./configure_iap.sh
echo 
bold "+=====================================================================================+"
bold "| >>>>>>>> https://$HOST_NAME <<<<<<<<<						                                     |"					 	
bold "+=====================================================================================+"

exit


#deleting cmd:
# gcloud compute addresses delete $STATIC_IP_NAME --global -q
# gcloud compute addresses delete $STATIC_IP_NAME --global -q
