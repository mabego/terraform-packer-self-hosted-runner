#!/bin/bash

set -euo pipefail
. /etc/environment

pkg=actions-runner.tar.gz
pkg_url=https://github.com/actions/runner/releases/download/v2.319.1/actions-runner-linux-x64-2.319.1.tar.gz

echo Configuring runner for "$GITHUB_REPO"
mkdir actions-runner && cd actions-runner || exit
curl -o "$pkg" -L "$pkg_url"
tar xzf ./"$pkg"
mv /tmp/runner.py .
chmod +x runner.py
mkdir -p ~/.config/systemd/user/
mv /tmp/*.service ~/.config/systemd/user/

systemctl --user daemon-reload
systemctl --user enable runner.service
systemctl --user enable shutdown-runner.service
loginctl enable-linger ubuntu
