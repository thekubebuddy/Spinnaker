This solution enables the IAP authentication mechanism on the Spinnaker UI, 
deplpoyed on the GKE.
** 

For enabling the IAP follow the given steps:

1. Set the PROJECT_ID and IAP_USER in the **properties** file in the current dir.
For example,
```
PROJECT_ID=my-gcp-project-1234
IAP_USER=octa.cat@gmail.com #The IAP user will be used to configure IAP
```

2. Run the "configure_endpoint.sh" script
```
./configure_endpoint.sh
```

3. The "configure_endpoint.sh" scripts done all of the hard-work and deploys the following and also makes some changes,

	1. An external ip adress 
	2. Google service and service endpoint
	3. Managed SSL certificate for the endpoint
	4. kubernetes secret from the OAut client id and client secret
	5. Create a SA and assing the necessary roles to it.
	6. Change the "spin-deck" service type from custerIP to NodePort
	7. Deploys the "deck-ingress"
	8. Configures the halyard pod with the nessacry IAP changes and finally deploys the changes

*Make sure to get OAuth client Id and secret for the below following step after step 3*

Below is the screen-shot for re-running the configure_endpoint.sh again:

![rerun-script](IMG_1.png)

4. For adding more IAP-secured Web App user, go to the below URL **ADD MEMBER**
with **Cloud_IAP.IAP_SECURED_WEB_APP_USER role**

https://console.cloud.google.com/security/iap?project= *PROJECT_IP*

![GCP-IAP](IAP_1.png)







