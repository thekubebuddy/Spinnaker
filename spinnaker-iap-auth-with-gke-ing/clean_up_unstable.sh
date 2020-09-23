
bold() {
  echo "* $(tput bold)" "$*" "$(tput sgr0)";
}

bold "Invoking the propety file"

source ./properties


cat <<-EOF>hal-revert-config.sh
# hal config security api edit --override-base-url /gate
# hal config security ui edit --override-base-url https://$HOST_NAME
hal config security authn iap disable
hal deploy apply
EOF

chmod +x ./hal-revert-config.sh

# if hal running on the GCE VM instead of pod uncomment the below line and comment out 158-161  
# ./hal-revert-config.sh

# export HALYARD_POD=$(kubectl get po -l stack=halyard -n $NAMESPACE -o jsonpath="{.items[0].metadata.name}")
# echo $HALYARD_POD
# kubectl cp -n $NAMESPACE  ./hal-revert-config.sh $HALYARD_POD:/home/spinnaker/  
# kubectl exec $HALYARD_POD -n $NAMESPACE -- bash -c "/home/spinnaker/hal-revert-config.sh"

echo 
bold "deleting the ingress resource for the spinnaker.."
envsubst < ./deck-ingress.yml | kubectl delete  -n $NAMESPACE -f -

echo 
bold "deleting the backend config.."
envsubst < ./backend-config.yml | kubectl delete  -n $NAMESPACE -f -

echo 
bold "deleting the oauth secret.."
echo $SECRET_NAME
kubectl delete secret $SECRET_NAME -n $NAMESPACE

echo 
bold "finally pathcing the spin-deck service.."
kubectl patch service -n $NAMESPACE spin-deck --patch "[{'op': 'replace', 'path': '/spec/type', 'value':'ClusterIP'}]" --type json

# gcloud compute addresses delete spin-deck-ing-ext-ip $STATIC_IP_NAME --global -q
