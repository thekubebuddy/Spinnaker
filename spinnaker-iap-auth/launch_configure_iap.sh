#!/usr/bin/env bash

pushd ~/cloudshell_open/spinnaker-for-gcp/scripts

source ./install/properties

# cat expose/configure_iap.md | envsubst > expose/configure_iap_expanded.md
# at this pointn you should have the oauth client id
~/cloudshell_open/spinnaker-for-gcp/scripts/expose/configure_iap.sh
popd
