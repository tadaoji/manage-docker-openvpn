# manage-docker-openvpn

# Overview
It uses docker and docker-compose to use OpenVPN.
Here's what you can do with this script.
* Create an OpenVPN environment.
* Create a client to connect to OpenVPN
* Delete a client registered with OpenVPN
* Shut down the connection of the client connected to OpenVPN.
* Delete the OpenVPN environment.

# Required environment
* Linux
* Docker
* Docker-compose

# Initialization
## Unpack.
Unpack this repository into any directory.
When unpacked, it will look like this
```
├─ LICENSE
├─ README.md
├─ build_ovpn_instance.sh
├─ client.conf.example
├─ create_account.sh
├─ delete_ovpn_instance.sh
├─ disconnect_account.sh
├─ docker_ovpn
│ ├─ delete_compose.sh
│ ├─ docker-compose.yml
│└─ docker_files
│└─ openvpn
│ ├─ Dockerfile
│└─ run.sh
├─ lib.sh
├──── mount_dir
│└─ mnt_ovpn
│ ├─ client.conf.example
│└─ server.conf.example
├──────── revoke_account.sh
└─ set_docker_env.sh
```
The docker_ovpn directory contains docker-compose, Dockerfile, and other files used by Docker.
The mount_dir is where OpenVPN generates configuration files, certificate files, and other files used by OpenVPN.

## Configuration(.env)
.env is the Configuration file.
Basically, this will configure the settings in .env only.
This file does not support commenting out.

### DOCKER_OVPN_HOST_PORT
Add any PORT number.
This PORT will be used between OpenVPN host and client.
### DOCKER_OVPN_PROTOCOL_TYPE
Select the communication protocol between the host and the client of OpenVPN.
Please set it to udp or tcp.
### DOCKER_OVPN_DEVICE_TYPE
You can select the network system to be used by the OpenVPN host.
tap <- bridge connection
tun <- router
### DOCKER_OVPN_NET
Add the virtual internal network to be used inside OpenVPN.
### DOCKER_OVPN_SUBNET_MASK
Specifies the subnet mask for the internal network of DOCKER_OVPN_NET.
### DOCKER_OVPN_DNS_IP
Select the server for DNS resolution.
By default Google DNS (8.8.8.8) is used.
### DOCKER_OVPN_CLIENT_TO_CLINET
Choose whether the connected clients should be allowed to access each other.
1 <- Allowed
0 <- Denied.
### DOCKER_OVPN_HOST_NAME
Set the domain name of the host.
### DOCKER_OVPN_DEST_HOST
Set the global IP address of the host.
This IP address will be the client's connection destination.
### DOCKER_OVPN_LOGS
Selects whether to output OpenVPN logs.
1 <- output
0 <- Do not output.
### EASYRSA_CRL_DAYS
Sets the validity period of the certificate.
The unit is days.
The default is 10 years (3650).
### EASYRSA_CERT_EXPIRE
Sets the expiration date of the certificate expiry list.
The unit is days.
The default value is 10 years (3650).
### DOCKER_OVPN_VIRTUAL_NET_NAME
Sets the name of the virtual network to use with Docker.
You can use any string that is consistent with Docker usage.


## How to use.
### Create an OpenVPN environment.
```bash
. /build_ovpn_instance.sh
```
Running this script will create one Docker container and one network with the name specified in .env.
```bash
docker network ls
NETWORK ID NAME DRIVER SCOPE

docker container ls
CONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
0e00647e9a63 tadaoji/openvpn "/run.sh" 18 seconds ago Up 18 seconds 0.0.0.0:45493->1194/udp, :::45493->1194/udp docker_ovpn_openvpn_
```
#### Files to be created
The certificate and other files will be created under /mount_dir.
server.conf file will be created reflecting the .env settings.
If you want to check or edit the configuration file directly, you can edit it with
. /mount_dir/mnt_ovpn/server.conf
if you want to check or edit the configuration file directly. This file is actually working with OpenVPN.

#### What happens when Docker Container is restarted
If the file exists under mount_dir, this script will use the existing configurations.
If you have rewritten server.conf, it will be loaded by restarting the container.

### Add a client.
```bash
. /create_account.sh <Client-Name>
````
Rewrite <Client-Name>.
You can add multiple clients. (This script cannot add clients in bulk.)
When you run it, you will see the following output at the end.
This directory contains the following files that the client needs to configure.
* ca file
* crt file
* key file
* ta.key file
* config file
  
Download this directory to your client using ftp, etc., and configure it in your OpenVPN client software.

If you have rewritten server.conf manually, you may need to rewrite the config file settings manually.

Example
``` .
. . /create_account.sh exampleuser

(Abbreviation)
r/exampleuser_ta.key
Complete to create USER: exampleuser

------------------------------------------------
Generated files DIR -> /PATH/TO/DIR/manage-docker-openvpn/mount_dir/mnt_easy-rsa/clients/exampleuser
------------------------------------------------
```

### Disconnect the connected client.
This disconnection is not permanent.
It will be resumed when the client connects again.
```bash
. /disconnect_account.sh <Client-Name>.
````

### Remove a registered client.
Connected clients will be immediately disconnected.
It will not be possible for the client to resume the connection.
```bash
. /revoke_account.sh <Client-Name>.
```

### Remove the OpenVPN environment.
```bash .
. /delete_ovpn_instance.sh
```
This will delete the Docker Container and Network that were being used.
When you run this script, it will enter interactive mode and ask you if you want to keep the configuration and certificate files.
```
Do you wish to remove the following directory and files?
. /mount_dir/mnt_easy-rsa
 . /mount_dir/mnt_ovpn/logs
 . /mount_dir/mnt_ovpn/server.conf
yes/no
```
If `no' is selected here, the files needed to restart will remain.
  
If `yes', all configuration files will be removed and you will be returned to the initial state.

# Credits
OpenVPN - [https://openvpn.net](https://openvpn.net)
 
