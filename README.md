# VestaCP
Vesta control panel with docker. Just debian and vestacp.

<b>What's different from [niiknow/vestacp](https://github.com/niiknow/vestacp)?</b>

Removed golang, couchdb, redis, openvpn, mongodb, nodejs and dotnet.
Based on debian 9.

Comparison of size with <i>niiknow/vestacp</i>:

| image               | compressed | uncompressed |
| ------------------- |:----------:| ------------:|
| niiknow/vestacp     | 1.69 GB    |       4.87GB |
| __modos189/vestacp-lite__ | __789 MB__  |       __2.19GB__ |

<b>What's included?</b>
* debian 9 + Vesta 0.9.8-24
* nginx (proxy) -> apache2
* ssh/sftp, letsencrypt, memcached, MariaDB 10.2
* folder redirection for data persistence and automatic daily backup provided by VestaCP
* vesta panel SSL (LE-issued) for mail and control panel - provide $HOSTNAME environment variable

<b>Run this image:</b>
```
mkdir -p /opt/vestacp/{vesta,home,backup}

docker run -d --restart=always \
-p 3322:22 -p 80:80 -p 443:443 -p 8083:8083 \
-v /opt/vestacp/vesta:/vesta -v /opt/vestacp/home:/home -v /opt/vestacp/backup:/backup \
modos189/vestacp-lite
```

## Volumes
/vesta  -- configurations

/home   -- users data

/backup -- users backup

## Authorization
Login: admin

To get the password, run

`sudo docker exec $CONTAINER_ID cat /vesta-start/root/password.txt`

Alternatively, you can change the password with:
```
sudo docker exec $CONTAINER_ID /usr/local/vesta/bin/v-change-user-password admin YOURNEWPASSWORD
```

## SSH for FTP
FTP was not installed on purpose because it's not secure.  Use SFTP instead on the 3322 port.  Disable ssh if you don't really need it and use the Vesta FileManager plugin.  Also, make sure you change the user shell in the Vesta panel in order to use ssh.

## How to running VestaCP-docker behind a Caddy Reverse Proxy with Free SSL

First, download [Caddy](https://caddyserver.com/)

`curl https://getcaddy.com | bash -s personal`

Now Caddy is installed, but you still need a service to run Caddy http server on the background.

You can find services backed by the community [here](https://github.com/mholt/caddy/tree/master/dist/init)

You must have at least the port **443** opened so the Caddy server will request an SSL certificate from Let's Encrypt

You can also open the port 80 to redirect http requests to https.

Open `/etc/caddy/Caddyfile`

Insert

```
your_domain.com {
        proxy / 127.0.0.1:8080 {
                header_upstream X-Forwarded-Proto {scheme}
                header_upstream X-Forwarded-For {host}
                header_upstream Host {host}
                websocket
        }
}
```

Your site is now proxied to vestcp-docker and automatically received a ssl certificate.

You can also access the panel from a separate subdomain:

Open `/opt/vestacp/vesta/local/vesta/nginx/conf/nginx.conf` and change
`ssl on;` to `ssl off;`

Then restart vesta:

`docker exec $CONTAINER_ID service vesta restart`

Open `/etc/caddy/Caddyfile` again

Insert

```
panel.your_domain.com {
        proxy / 127.0.0.1:8083 {
                header_upstream X-Forwarded-Proto {scheme}
                header_upstream X-Forwarded-For {host}
                header_upstream Host {host}
                header_upstream X-Forwarded-Port 8083
                websocket
        }
}
```

# MIT
