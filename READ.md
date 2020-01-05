Table of Content
===================

* [Artifact account](#artifact-account)
* [Spin CLI](#spin-cli)



###  Artifact Account

1. Enabling github as an Artifact account
```
hal config features edit --artifacts true
hal config artifact gitlab enable
hal config artifact gitlab account list
```

### Spin CLI
1. CLI configuration(Its better to configure in a sperate pod within the namespace where the spinnaker installed)
```
wget https://storage.googleapis.com/spinnaker-artifacts/spin/$(curl -s https://storage.googleapis.com/spinnaker-artifacts/spin/latest)/linux/amd64/spin

chmod +x ./spin

mv ./spin /usr/local/bin/spin
mkdir ~/.spin/

# configuring the gate endpoint so that spin can talk with spinnaker through gate
cat<<EOF> ~/.spin/config
gate:
  endpoint: http://spinnaker-gate-endpoint:8084
EOF
```
2. Handy-Cmds
```
# Listing all the pipelines in Spinnaker within application
spin pipeline list --application <app-name>

# Exporting the JSON Spinnaker pipeline from an application 	
spin pipeline get --name <pipline-name> --application <app-name> 

# Deleting a pipeline
spin pipeline delete <pipline-name> --application <app-name>

# Saving a spinnaker template as a pipeline
spin pipeline save --file template1.txt

``` 
3. Some bash useful-hacks
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







































