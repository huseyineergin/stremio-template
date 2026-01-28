# Stremio Compose Template

This is a simplified version of [Viren070's template](https://github.com/Viren070/docker-compose-template) with few changes, focusing only on Stremio services.

## Contents

- [Services](#services)
- [VPS Setup](#vps-setup)
    * [Essential Setup](#essential-setup)
    * [Extra Setup](#extra-setup)
- [Getting Started](#getting-started)
    * [Prerequisites](#prerequisites)
    * [Installation](#installation)

## Services

- **[AIOStreams](https://github.com/Viren070/AIOStreams)** consolidates multiple Stremio addons and debrid services, including its own suite of built-in addons, into a single, highly customisable super-addon.
- **[Authelia](https://www.authelia.com/)** is an open-source authentication and authorization server and portal.
- **[Beszel](https://beszel.dev/)** is a lightweight server monitoring platform that includes Docker statistics, historical data, and alert functions.
- **[Dozzle](https://dozzle.dev/)** is a lightweight, web-based log viewer designed to simplify monitoring and debugging containerized applications across Docker, Docker Swarm, and Kubernetes environments.
- **[MediaFlow Proxy](https://github.com/mhdzumair/mediaflow-proxy)** is a powerful and flexible solution for proxifying various types of media streams.
- **[Traefik](https://github.com/traefik/traefik)** is a modern HTTP reverse proxy and load balancer that makes deploying microservices easy.
- **[Uptime Kuma](https://github.com/louislam/uptime-kuma)** is an easy-to-use self-hosted monitoring tool.
- **[WARP-Docker](https://github.com/cmj2002/warp-docker)** runs official [Cloudflare WARP](1.1.1.1) client in Docker.

## VPS Setup

Follow [Viren070's selfhosting guide](https://guides.viren070.me/selfhosting) to set up an Oracle VPS, or use an existing one. This section focuses on what to do after creating a VPS instance to walk through the essential post-setup steps to turn it into a "production-ready" server. Most of this section is based on **“My First 5 Minutes on a Server; or, Essential Security for Linux Servers”** by Bryan Kennedy.

> **Note:** The following instructions are written for Debian/Ubuntu. Commands may vary depending on the Linux distribution.

### Essential Setup

As the first step, log in to the VPS as the `root` user using SSH.
```sh
ssh -i /path/to/private/key root@VPS_PUBLIC_IP
```

#### Change Root Password

Change the `root` password to something long and complex. This password should be stored securely. It is needed if SSH access is lost or the `sudo` password needs to be recovered.
```sh
passwd
```

#### Update and Upgrade Packages

Update the package list and upgrade all installed packages to their latest versions.
```sh
apt-get update && apt-get upgrade -y
```

Install `fail2ban`. It is a daemon that monitors login attempts to a server and blocks suspicious activity as it occurs. It’s well configured out of the box.
```sh
apt install fail2ban
```

#### Add a New User

Add a login user. Feel free to name the user something besides `debian`.
```sh
useradd -s /bin/bash -m debian
mkdir /home/debian/.ssh
chmod 700 /home/debian/.ssh
```

Set a password for login user. Use a complex password. This password will be used for `sudo` access.
```sh
passwd debian
```

Add login user to the `sudoers`.
```sh
usermod -aG sudo debian
```

#### Configure Public Key Authentication

Add public keys for authentication. It'll enhance security and ease of use by ditching passwords and employing [public key authentication](https://en.wikipedia.org/wiki/Public-key_cryptography) for user accounts. Add the contents of the local public key file, along with any additional public keys requiring access to this server, to this file.
```sh
vim /home/debian/.ssh/authorized_keys
# ...
chmod 400 /home/debian/.ssh/authorized_keys
chown debian:debian /home/debian -R
```

#### Harden SSH Configuration

Configure SSH to prevent password and `root` logins.
```sh
vim /etc/ssh/sshd_config
```

Add the following lines to the file.
```conf
PermitRootLogin no
PasswordAuthentication no
```

Restart SSH.
```sh
service ssh restart
# or
systemctl restart sshd.service
```

#### Configure Firewall

Set up a firewall. [`ufs`](https://wiki.debian.org/Uncomplicated%20Firewall%20%28ufw%29) and [`firewalld`](https://firewalld.org/) provide a simple setup, while [`iptables`](https://wiki.archlinux.org/title/Iptables) and [`nftables`](https://wiki.nftables.org/wiki-nftables/index.php/Main_Page) offer more advanced configuration options.
```sh
ufw allow <SOURCE_PUBLIC_IP> to any port 22
ufw allow 80
ufw allow 443
```
This sets up a basic firewall and allows traffic on ports 80 and 443.

### Extra Setup

The configurations outlined in this section are optional and serve to enhance the security of the environment. While not mandatory for basic server operation, implementing a private network tunnel is a recommended best practice for administrative access. Most of this section is based on ["How To Set Up WireGuard on Ubuntu 22.04"](https://www.digitalocean.com/community/tutorials/how-to-set-up-wireguard-on-ubuntu-22-04) by Jamon Camisso.

#### Tunneling vs. Public Exposure

Exposing service ports, such as SSH (Port 22), directly to the public network increases the attack surface of a server. Publicly accessible ports are subject to continuous automated brute-force attacks and vulnerability scanning. By utilizing a Virtual Private Network (VPN) like WireGuard, administrative services can be restricted to a private network interface.

Connecting via a private IP address ensures that:
- The SSH daemon can be configured to listen only on the internal WireGuard IP (e.g., `10.8.0.1`), making it invisible to the public network.
- An additional layer of cryptographic authentication is required before a user can even attempt to authenticate with the server.
- Lateral movement is restricted, as only authenticated peers can route traffic through the tunnel.

#### Overview of WireGuard

[WireGuard](https://www.wireguard.com/) is a modern, high-performance VPN protocol that utilizes state-of-the-art cryptography. It aims to be faster, simpler, leaner, and more useful than older protocols like IPsec and OpenVPN, while avoiding the massive headache. Initially released for the Linux kernel, it is now cross-platform (Windows, macOS, BSD, iOS, Android) and widely deployable.

#### How WireGuard Works

- **Cryptographic Key Routing**: WireGuard associates public keys with a list of allowed tunnel IP addresses. Each peer has a private key and a public key used for mutual authentication.
- **UDP-Based**: It operates over UDP. If the server receives a packet that does not contain a valid cryptographic signature from a known peer, it simply drops the packet. This makes the server appear "silent" to unauthorized scanners.
- **Stateless Feel**: To the user, the connection feels stateless. Because it does not maintain a persistent connection in the traditional sense, it handles roaming seamlessly without requiring a manual reconnect.

#### Understanding Server and Peer

In this specific setup:
  - **WireGuard Server**: Refers to the Virtual Private Server (VPS).
  - **WireGuard Peer**: Refers to the local machine.

#### Installing WireGuard and Generating a Key Pair

Install WireGuard on **WireGuard Server**.
```sh
sudo apt update
sudo apt install wireguard
```

Create the private key for **WireGuard Server** and change its permissions.
```sh
wg genkey | sudo tee /etc/wireguard/private.key
sudo chmod go= /etc/wireguard/private.key
```
The `sudo chmod go=...` command removes any permissions on the file for users and groups other than the root user to ensure that only it can access the private key.

A single line of base64-encoded output will be produced, which is the private key. A copy of the output is also stored in the `/etc/wireguard/private.key` file. Copy it somewhere for reference, as it is needed when configuring WireGuard in a later step.

The next step is to create the corresponding public key, which is derived from the private key.
```sh
sudo cat /etc/wireguard/private.key | wg pubkey | sudo tee /etc/wireguard/public.key
```

A single line of base64-encoded output will be produced again, which is the public key this time. Copy it somewhere for reference as well, since the public key needs to be distributed to any peer that will connect to the server.

#### Choosing IPv4 Address

Choose an IPv4 range. The server needs a range of private IPv4 addresses to use for clients, and for its tunnel interface. Any range of IP addresses may be selected from the following reserved address blocks.
- `10.0.0.0` to `10.255.255.255` (10/8 prefix)
- `172.16.0.0` to `172.31.255.255`  (172.16/12 prefix)
- `192.168.0.0` to `192.168.255.255` (192.168/16 prefix)

For the purposes of this guide, `10.8.0.0/24` is used as a block of IP addresses from the first range. This range will allow up to 255 different peer connections. Choose a range of addresses that is compatible with the network configuration if the example range is unsuitable.

The **WireGuard Server** will use a single IP address from the range for its private tunnel IPv4 address, `10.8.0.1/24` in this case, but any address in the range of `10.8.0.1` to `10.8.0.255` can be used.

#### Creating a WireGuard Server Configuration

After obtaining the required private key and IP address, create a new configuration file using `vim` or another preferred editor.
```sh
sudo vim /etc/wireguard/wg0.conf
```

Add the following lines to the file, replacing the highlighted `base64_encoded_SERVER_PRIVATE_key_goes_here` with the private key, and updating the `Address` line with the appropriate IP address. The `ListenPort` line can also be modified to use a different port for WireGuard.
```conf
# /etc/wireguard/wg0.conf
[Interface]
PrivateKey = base64_encoded_SERVER_PRIVATE_key_goes_here
Address = 10.8.0.1/24
ListenPort = 51820
```
Save and close the `/etc/wireguard/wg0.conf` file.

#### Starting the WireGuard Server

WireGuard can be configured to run as a `systemd` service using its built-in `wg-quick` script. Using a `systemd` service means that WireGuard can be configured to start up at boot so that peers can connect to the server at any time as long as the server is running. To do this, enable the `wg-quick` service for the `wg0` tunnel that has been defined by adding it to `systemctl`.
```sh
sudo systemctl enable wg-quick@wg0.service
```

Now start the service.
```sh
sudo systemctl start wg-quick@wg0.service
```

Double check that the WireGuard service is active with the following command.
```sh
sudo systemctl status wg-quick@wg0.service
```

#### Configuring a WireGuard Peer

Configuring a **WireGuard Peer** is similar to setting up the **WireGuard Server** if **WireGuard Peer** is using Debian/Ubuntu as well. However, if the **WireGuard Peer** is using a different platform, such as Windows, the configuration steps differ slightly. In this guide, the **WireGuard Peer** is a Windows machine.

Download and install the WireGuard client from the [official website](https://www.wireguard.com/install/).

Open WireGuard and select `Add Tunnel` → `Add empty tunnel`. The interface automatically generates a private key and a public key.

Configure the interface section.
```conf
[Interface]
PrivateKey = base64_encoded_PEER_PRIVATE_key_goes_here
Address = 10.0.0.2/24
```

Add server details under `[Peer]`:
```conf
[Peer]
PublicKey = base64_encoded_SERVER_PUBLIC_key_goes_here
AllowedIPs = 10.8.0.0/24
Endpoint = WIREGUARD_SERVER_PUBLIC_IP:51820
```

#### Adding the WireGuard Peer’s Public Key to the WireGuard Server

Copy the **WireGuard Peer** public key and `Address`. Then, add them to the **WireGuard Server** configuration.
```conf
# /etc/wireguard/wg0.conf
[Interface]
PrivateKey = base64_encoded_SERVER_PRIVATE_key_goes_here
Address = 10.8.0.1/24
ListenPort = 51820

[Peer]
PublicKey = base64_encoded_PEER_PUBLIC_key_goes_here
AllowedIPs = 10.8.0.2
```

#### Update SSH Daemon and WireGuard to Apply Changes

Bind SSH to the WireGuard interface, blocking public access.
```sh
sudo vim /etc/ssh/sshd_config
```

Add the following lines to the file.
```conf
ListenAddress 10.8.0.1
```

Restart SSH.
```sh
sudo service ssh restart
# or
sudo systemctl restart sshd.service
```

Reload or restart the WireGuard service to apply changes.
```sh
sudo service wg-quick@wg0 restart
# or
sudo systemctl restart wg-quick@wg0.service
```

#### Verify the Connection

In the WireGuard client, select the tunnel and click `Activate`. A successful handshake indicates active connectivity.

## Getting Started

### Prerequisites

- A VPS with [Docker](https://www.docker.com/) installed. Follow the [official installation steps](https://docs.docker.com/engine/install/) for the selected platform.
- Ports 80 and 443 are accessible on the VPS.
- A domain with DNS records configured to point to the VPS IP for each domain or subdomain in use.

### Installation

1. Clone this repository and navigate into it:
```sh
cd /opt
git clone https://github.com/huseyineergin/stremio-template.git
cd stremio
```

2. Use a text editor (nano, vim) to open the `.env` file in the `apps` folder. **VS Code (with the `Remote - SSH` extension)** can also be used to edit the files.
```sh
vim .env
```

3. Set the following values in the `.env` file in the `apps` folder:
- `DOMAIN`
- `AUTHELIA_JWT_SECRET`
- `AUTHELIA_SESSION_SECRET`
- `AUTHELIA_STORAGE_ENCRYPTION_KEY`
- `ADDON_PROXY`

4. Set the following values in the `.env` file in the `apps/aiostreams` folder:
- `ADDON_ID`
- `SECRET_KEY`
- `ADDON_PASSWORD`
- `DATABASE_URI`
- `ADDON_PROXY`

When using PostgreSQL for AIOStreams’ database, set `POSTGRES_PASSWORD`, `POSTGRES_USER`, and `POSTGRES_DB`.

5. Set the following values in the `.env` file in the `apps/authelia` folder:
- `REDIS_PASSWORD`
- `POSTGRES_PASSWORD`
- `POSTGRES_USER`
- `POSTGRES_DB`

6. Set the following values in the `.env` file in the `apps/mediaflow-proxy` folder:
- `API_PASSWORD`
- `PROXY_URL`

7. Set the email address in the `traefik.yaml` file in the `apps/traefik` folder:
```yaml
certificatesResolvers:
  letsencrypt:
    acme:
      email: you@example.com # change this
      storage: /letsencrypt/acme.json
      httpChallenge:
        entryPoint: web
```

8. Ensure the current directory is the root of the apps folder, `/opt/stremio` if unchanged, and not inside an app-specific folder. This can be verified by running `pwd` and confirming it returns `/opt/stremio`. Once the folder is confirmed, start the services:
```sh
docker compose up -d
```

Once the services are running, follow the instructions in the `.env` file in the `apps/beszel` folder to set up Beszel.
