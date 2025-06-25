#!/usr/bin/env bash

set -u -o pipefail

# git credential
sudo dnf install git-credential-libsecret
git config --global set credential.helper libsecret

# lazygit
sudo dnf copr enable atim/lazygit -y
sudo dnf install lazygit

# getnf nerd fonts
curl -fsSL https://raw.githubusercontent.com/getnf/getnf/main/install.sh | bash

