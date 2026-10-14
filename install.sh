#!/bin/sh
# Builds clockwork-relay and runs it as a service on a Linux server (made for Ubuntu Server).
# Run from a checkout of this repository:  sudo ./install.sh
# Needs just a C++20 compiler (installed if missing).
set -e
R=$(cd "$(dirname "$0")" && pwd)

if [ "$(id -u)" -ne 0 ]; then
    echo "run it with sudo: sudo $0" >&2
    exit 1
fi
if ! command -v g++ >/dev/null; then
    echo "installing a C++ compiler (build-essential)"
    apt-get update -q && apt-get install -y -q build-essential
fi

echo "building clockwork-relay"
g++ -std=c++20 -O2 -Wall "$R/src/relay.cpp" "$R/src/relay_main.cpp" \
    -o /usr/local/bin/clockwork-relay.new
strip /usr/local/bin/clockwork-relay.new
mv /usr/local/bin/clockwork-relay.new /usr/local/bin/clockwork-relay

echo "installing the service"
install -m 644 "$R/systemd/clockwork-relay.service" /etc/systemd/system/clockwork-relay.service
systemctl daemon-reload
systemctl enable clockwork-relay >/dev/null 2>&1
systemctl restart clockwork-relay

if command -v ufw >/dev/null && ufw status | grep -q "Status: active"; then
    echo "opening UDP port 47830 in the firewall (ufw)"
    ufw allow 47830/udp >/dev/null
fi

sleep 1
systemctl --no-pager --lines=3 status clockwork-relay
echo
echo "clockwork-relay is running on UDP port 47830."
echo "Next: forward UDP 47830 on your router to this machine (see README.md)."
