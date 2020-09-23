# Google IAP Authentication on Spinnaker

* This solution enables the GCP IAP authentication mechanism on the Spinnaker installed on the GKE cluster.
* 


## Prerequisites

* gcloud util properly installed and gcloud auth configured with neccessary permissions.
* OAuth consent screen properly configured.
* OAuth client id and client secret generated for the Web application.
* External IP with DNS mapped with the ingress host name

## Usage

**Note: Please do read the configurational echo comments properly, specially the last `ACTION REQUIRED` step**


#### Step 1. Deploying the spinnaker on GKE (if not deployed)
```
k create ns spinnaker
k config set-context --current --namespace=spinnaker
k apply -f spinstack-on-gke.yaml
```

* The state of the world before running the script, must be seen as follows
![spinnaker-1](./screenshots/spinnaker-deployed.png)



2. Setting up the **properties** file in the current dir.
For example,
```
export PROJECT_ID="" #GCP project id
export IAP_USER="user.name@mydomain.com"  # mail id for the IAP user configuring
export NAMESPACE="spinnaker" # spinnaker deployed namespace name
export DEPLOYMENT_NAME="spinnaker-iap"
export SERVICE_ACCOUNT_NAME="$DEPLOYMENT_NAME-sa-1586329621"
export STATIC_IP_NAME="" #  Static External IP name to be created for the ingress/or if already created 
export MANAGED_CERT="" # Cert file name for the terminating TLS on spin-deck ingress 
export SECRET_NAME="spin-oauth-client-secret" #OAuth secret name for the backend config
export HOST_NAME="spin-deck.mydomain.com" #hostname name for mapping in with the ingress host

```

2. Run the "setup_iap.sh" script which will do rest of the configuration and resource provisioning work.
```
./setup_iap.sh
```

3. The "setup_iap.sh" scripts does all of the hard-work and deploys the following resources:
	* A Global static external IP Address.
	* Managed SSL certificate for the spinnaker ingress.
	* Changes the "spin-deck" service type from custerIP to NodePort for the Ingress.
	* Deploys the "deck-ingress" with the above provisioned IP address and SSL cert.
	* Configures the halyard pod with the nessacry IAP configuration changes.


4. Adding more IAP-secured Web App user, go to the below URL **ADD MEMBER** --> **Cloud_IAP.IAP_SECURED_WEB_APP_USER role**

https://console.cloud.google.com/security/iap?project=PROJECT_ID


![GCP-IAP](IAP_1.png)


5. As the script is idemponent in nature,  below is the screen-shot for re-running the **setup_iap.sh**:

![rerun-script](IMG_1.png)


# Any Questions?

Open an issue.





