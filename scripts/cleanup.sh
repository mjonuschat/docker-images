#!/bin/sh
apt-get -y autoremove
apt-get -y clean
rm -rf /tmp/* /var/tmp/*
rm -rf /var/lib/apt/lists/*
rm -f /var/cache/apt/archives/*.deb
rm -f /var/cache/apt/*cache.bin
