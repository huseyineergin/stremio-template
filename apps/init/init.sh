#!/bin/sh

# AIOStreams
mkdir -p /data/aiostreams
mkdir -p /data/aiostreams/db

# Authelia
mkdir -p /data/authelia
mkdir -p /data/authelia/db
mkdir -p /data/authelia/cache

# Beszel
mkdir -p /data/beszel/data
mkdir -p /data/beszel/agent
mkdir -p /data/beszel/socket

# Traefik
touch -c /letsencrypt/acme.json
chmod 600 /letsencrypt/acme.json
chown -R "${PUID}:${PGID}" /letsencrypt

# Uptime Kuma
mkdir -p /data/uptime-kuma

# WARP
mkdir -p /data/warp

chown -R "${PUID}:${PGID}" /data