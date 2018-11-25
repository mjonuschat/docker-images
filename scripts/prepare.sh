#!/bin/sh
apt-get update -q
apt-get dist-upgrade -y --no-install-recommends -o Dpkg::Options::='--force-confold'
apt-get install -y sudo curl
