#!/bin/sh

# services below are enabled to support mininum default backup job
service mysql start

# ./fail2ban start \ # -- only if you run with: --cap-add=NET_ADMIN --cap-add=NET_RAW
