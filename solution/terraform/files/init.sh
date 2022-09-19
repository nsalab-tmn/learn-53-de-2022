#!/bin/bash
sudo apt-get update && sudo apt-get install -y python3 python3-pip screen
mkdir -p ~/.ssh
echo '${key}' > ~/.ssh/id_ed25519
chmod 400 ~/.ssh/id_ed25519
ssh-keyscan github.com >> ~/.ssh/known_hosts
git clone ${repo} ~/web53
cd ~/web53/app
pip3 install -r requirements.txt
echo '${env_file}' > env.yaml
screen -d -m bash -c "python3 app.py"