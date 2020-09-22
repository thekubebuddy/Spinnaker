# Google IAP Authentication on Spinnaker

This solution enables the GCP IAP authentication mechanism on the Spinnaker preinstalled on the GKE cluster.

# Prerequisites

* gcloud util properly installed and gcloud auth configured.
* OAuth consent screen properly configured.
* OAuth client id and client secret generated for the Web application.



# Usage

1. Set the PROJECT_ID and IAP_USER in the **properties** file in the current dir.
For example,
```
PROJECT_ID=my-gcp-project-1234
IAP_USER=octa.cat@gmail.com #The IAP user will be used to configure IAP
```

2. Run the "setup_iap.sh" script which will do rest of the configuration and resource provisioning work.
```
./setup_iap.sh
```

3. The "setup_iap.sh" scripts does all of the hard-work and deploys the following resources:
	* A Global static external IP Address.
	* Google service endpoint for spinnaker domain.
	* Managed SSL certificate for the spinnaker endpoint service.
	* kubernetes secret from the OAuth client id and client secret.
	* Create a SA and assing the necessary roles to it.
	* Changes the "spin-deck" service type from custerIP to NodePort for the Ingress.
	* Deploys the "deck-ingress" with the above provisioned IP address.
	* Configures the halyard pod with the nessacry IAP configuration changes and finally deploys the changes


4. Adding more IAP-secured Web App user, go to the below URL **ADD MEMBER** --> **Cloud_IAP.IAP_SECURED_WEB_APP_USER role**

https://console.cloud.google.com/security/iap?project=PROJECT_ID


![GCP-IAP](IAP_1.png)


5. As the script is idemponent in nature,  below is the screen-shot for re-running the **setup_iap.sh**:

![rerun-script](IMG_1.png)



# Any Questions?

Open an issue.





