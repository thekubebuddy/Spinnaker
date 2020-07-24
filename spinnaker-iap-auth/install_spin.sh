#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

curl -LO https://storage.googleapis.com/spinnaker-artifacts/spin/$(curl -s https://storage.googleapis.com/spinnaker-artifacts/spin/latest)/linux/amd64/spin

chmod +x spin
mv spin ~

grep -q '^alias spin=~/spin' ~/.bashrc || echo 'alias spin=~/spin' >> ~/.bashrc

mkdir -p ~/.spin
# Only re-generate ~/.spin/config if Spinnaker installation in unsecured. Otherwise, leave whatever is there.
# The ~/.spin/config will always be restored by pull_config.sh in any case.
cat >~/.spin/config <<EOL
gate:
  endpoint: http://localhost:8080/gate
EOL
