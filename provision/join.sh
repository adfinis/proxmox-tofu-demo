#!/bin/bash
set -eux

first="$1"
second="$2"

# Add ssh keys to known-hosts of both servers
sudo ssh -oStrictHostKeyChecking=accept-new "$first" /bin/true
sudo ssh "$first" ssh -oStrictHostKeyChecking=accept-new "$second" /bin/true

# add entries in hosts to find each other via hostname
echo "first $first" >> /etc/hosts

sudo ssh "$first" /bin/sh -c "echo 'second $second' >> /etc/hosts"

# Create cluster on first node
sudo ssh "$first" pvecm create --link0 "$first" demo
# Join second node
sudo pvecm add --use_ssh -- "$first"
