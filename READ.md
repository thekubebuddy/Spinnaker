Table of Content
===================

* [Artifact account](#artifact-account)
* [Spin CLI](#spin-cli)
* [Upgrading spinnaker version](#upgrading-spinnaker-version)
* [Spinnaker on minikube](#spinnaker-on-minikube)

###  Artifact Account

* Spinnaker Artifacts helps to pull the objects from the external resources, which can be further used in spinnaker pipeline.
* It could be a docker image, manifest file stored in VCS or an AMI 
* All the configuration of Spinnaker is solely managed by its **"halyard"** component, which is the centralized hub for managing spinnaker.
* For the artifact account configuration, make sure you either generated the authentication token or auth through the username and password,specially for bitbucket you will be needing password.
* Usecase: The github or any other VCS can be used to store the k8s manifest file which can be used further.

1. Configuring github/gitlab/bitbucket as an Artifact account

```

hal config features edit --artifacts true

# Enabling the github artifact account
hal config artifact github enable
# Listing the artifact account
hal config artifact github account list

ARTIFACT_ACCOUNT_NAME=sample-github-artifact-account
# For this configuration, token-needs to be generated either on Github or github
 echo "Secret_token" > ~/TOKEN
TOKEN_FILE=/home/spinnaker/TOKEN

hal config artifact github account add $ARTIFACT_ACCOUNT_NAME --token-file $TOKEN_FILE

# Configuring bitbucket artifact account
# hal config features edit --artifacts true
# hal config artifact bitbucket account list
# ARTIFACT_ACCOUNT_NAME=sample-bitbucket-artifact-account
# hal config artifact bitbucket account add $ARTIFACT_ACCOUNT_NAME --username <username> --password
# hal config artifact bitbucket account list
# Once configured, need to hit the "hal deploy" to take changes on spinnaker end
hal deploy apply
```
![bitbucket-artifact-example](pics/bitbucket-artifact-account.png)

**cloud_driver, echo, igor service will be restarted**
```
# deleting the the artifact account
hal config artifact github account delete $ARTIFACT_ACCOUNT_NAME 

```


### Spin CLI
1. CLI configuration
* Its better to configure spin in a sperate pod within the same namespace where the spinnaker is installed, since the "halyard pod" doesn't have permission to install any packages
* Before installing "spin", we need to know the spinnaker's-gate svc endpoint, maker sure we have before-hand
* Spinning an busybox pod in the spinnaker's namespace
```
k run lazybox --image smartbuddy/lazybox:v1 --replicas 1 -- /bin/sleep 99999999
```
* Run the following bash cmd for installing the "spin"
```
wget https://storage.googleapis.com/spinnaker-artifacts/spin/$(curl -s https://storage.googleapis.com/spinnaker-artifacts/spin/latest)/linux/amd64/spin

chmod +x ./spin

mv ./spin /usr/local/bin/spin
mkdir ~/.spin/

# configuring the gate endpoint so that spin can talk with spinnaker through gate
cat<<EOF> ~/.spin/config
gate:
  endpoint: http://<spinnaker-gate-endpoint>:8084
EOF
```
2. Handy-spin-Cmds
```
# Listing all the pipelines in Spinnaker within application
spin pipeline list --application <app-name>

# Exporting the JSON Spinnaker pipeline from an application 	
spin pipeline get --name <pipline-name> --application <app-name> 

# Deleting a pipeline
spin pipeline delete <pipline-name> --application <app-name>

# Saving a spinnaker template as a pipeline
spin pipeline save --file template1.tx, configure and deploy

hal version list
version=1.17.5
hal config version edit --version $version
hal deploy apply
hal version list
``` 
3. Some useful-bash-hacks
```
# Spliting single json template to many json template with "//" as a delimeter
csplit --digits=2  --quiet --prefix=template ./allPipelines.txt "////+1" "{*}"

# Looping and saving the pipeline
for x in `ls template*`
do
echo $x
echo spin pipeline save --file $x
done

# Deleting the pipelines in one-loop 
for x in $(cat pipeline_names.txt)
do
echo spin pipeline delete --name $x --application <app-name>
done
```


### Upgrading spinnaker version
* Exec into the halyard pod
```
k exec -it <spin-halyard-podname> bash
``` 
* Check the spinnaker version, select the version to deployed, configure and deploy
```
hal version list #checking the current version
version=1.17.5
hal config version edit --version $version
hal deploy apply
hal version list

```

### Spinnaker on minikube

**Step 1. For running spinnaker minikube vm must atleast have 8Gi,4 cores of compute power for deploying Spinnaker smootly, without any trouble.**
```
minikube start --vm-driver=virtualbox --kubernetes-version=1.16.0 --memory=8192 --cpus=4 --disk-size=50g
```

**Step 2. Deploy the minikube spinnaker stack i.e spin-minikube.yaml once the minikube cluster-up running**
```
kubectl create -f spin-minikube.yaml
```
*Deploying spinnaker on minikube is patience keeping process, with the above lease configuration*



































