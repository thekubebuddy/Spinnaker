Table of Content
===================
	* Adding Artifact account(#1artifact-account)



###  Artifact Account

1. Enabling github as an Artifact account
```
hal config features edit --artifacts true
hal config artifact gitlab enable
hal config artifact gitlab account list
```

### Spin CLI
1. CLI configuration
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

2. Listing all the pipelines in Spinnaker within application
```
spin pipeline list --application <app-name>
``` 








































