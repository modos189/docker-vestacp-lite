FROM jgoerzen/debian-base-minimal:stretch
LABEL maintainer="modos189 <docker@modos189.ru>"
ENV VESTA=/usr/local/vesta

ADD ["https://raw.githubusercontent.com/LolHens/docker-tools/master/bin/cleanimage", "/usr/local/bin/"]
RUN chmod +x "/usr/local/bin/cleanimage"

RUN apt-get update \
 && apt-get dist-upgrade -y \
 && apt-get install -y apt-transport-https ca-certificates wget curl gnupg jq nano unzip pwgen apt-utils memcached rsyslog ntp \
 && cleanimage

# generate secure password
RUN pwgen -c -n -1 12 > $HOME/password.txt \
 && cd "/tmp" \
# begin install vesta
 && curl http://vestacp.com/pub/vst-install.sh | bash -s -- \
      -y no -f \
      --password $(cat $HOME/password.txt) \
      --nginx yes --apache yes --phpfpm no \
      --vsftpd no --proftpd no \
      --exim yes --dovecot yes --spamassassin yes --clamav yes \
      --named yes \
      --iptables no --fail2ban yes \
      --mysql yes --postgresql yes \
      --remi yes \
      --quota yes \
 && cleanimage

COPY rootfs/. /

RUN cd /usr/local/vesta/data/ips && mv * 127.0.0.1 \
# increase memcache max size from 64m to 256m
 && sed -i -e "s/^\-m 64/\-m 256/g" /etc/memcached.conf \
# secure ssh
 && sed -i -e "s/PermitRootLogin prohibit-password/PermitRootLogin no/g" /etc/ssh/sshd_config \
 && sed -i -e "s/^#PermitRootLogin yes/PermitRootLogin no/g" /etc/ssh/sshd_config \
# docker specific
 && cd /etc/apache2/conf.d \
 && sed -i -e "s/172.*.*.*:80/127.0.0.1:80/g" * \
 && sed -i -e "s/172.*.*.*:8443/127.0.0.1:8443/g" * \
 && cd /etc/nginx/conf.d \
 && sed -i -e "s/172.*.*.*:80/127.0.0.1:80/g" * \
 && sed -i -e "s/172.*.*.*:8080/127.0.0.1:8080/g" * \
 && mv 172.*.*.*.conf 127.0.0.1.conf \
 && cd /home/admin/conf/web \
 && sed -i -e "s/172.*.*.*:80;/80;/g" * \
 && sed -i -e "s/172.*.*.*:8080/127.0.0.1:8080/g" * \
 && cd /tmp \
# postgres patch for this docker
 && sed -i -e "s/%q%u@%d '/%q%u@%d %r '/g" /etc/postgresql/9.6/main/postgresql.conf \
 && sed -i -e "s/^#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/9.6/main/postgresql.conf \
# php stuff - after vesta because of vesta-php installs
 && sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 600M/" /etc/php/7.0/apache2/php.ini \
 && sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 600M/" /etc/php/7.0/cli/php.ini \
 && sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 600M/" /etc/php/7.0/cgi/php.ini \
 \
 && sed -i "s/post_max_size = 8M/post_max_size = 600M/" /etc/php/7.0/apache2/php.ini \
 && sed -i "s/post_max_size = 8M/post_max_size = 600M/" /etc/php/7.0/cli/php.ini \
 && sed -i "s/post_max_size = 8M/post_max_size = 600M/" /etc/php/7.0/cgi/php.ini \
 \
 && sed -i "s/max_input_time = 60/max_input_time = 3600/" /etc/php/7.0/apache2/php.ini \
 && sed -i "s/max_input_time = 60/max_input_time = 3600/" /etc/php/7.0/cli/php.ini \
 && sed -i "s/max_input_time = 60/max_input_time = 3600/" /etc/php/7.0/cgi/php.ini \
 \
 && sed -i "s/max_execution_time = 30/max_execution_time = 300/" /etc/php/7.0/apache2/php.ini \
 && sed -i "s/max_execution_time = 30/max_execution_time = 300/" /etc/php/7.0/cli/php.ini \
 && sed -i "s/max_execution_time = 30/max_execution_time = 300/" /etc/php/7.0/cgi/php.ini \
 \
 && sed -i -e "s/;sendmail_path =/sendmail_path = \/usr\/sbin\/exim \-t/g" /etc/php/7.0/apache2/php.ini \
 && sed -i -e "s/;sendmail_path =/sendmail_path = \/usr\/sbin\/exim \-t/g" /etc/php/7.0/cli/php.ini \
 && sed -i -e "s/;sendmail_path =/sendmail_path = \/usr\/sbin\/exim \-t/g" /etc/php/7.0/cgi/php.ini \
# docker specific patching
 && sed -i -e "s/^if (\$dir_name/\/\/if (\$dir_name/g" /usr/local/vesta/web/list/rrd/image.php \
# increase open file limit for nginx and apache
 && echo "\n\n* soft nofile 800000\n* hard nofile 800000\n\n" >> /etc/security/limits.conf \
# apache stuff
 && echo "\nServerName localhost\n" >> /etc/apache2/apache2.conf \
 && chmod +x /etc/rc.local

# begin folder redirections
RUN mkdir -p /vesta-start/etc \
 && mkdir -p /vesta-start/var/lib \
 && mkdir -p /vesta-start/local \
 \
 && mv /etc/apache2 /vesta-start/etc/apache2 \
 && rm -rf /etc/apache2 \
 && ln -s /vesta/etc/apache2 /etc/apache2 \
 \
 && mv /etc/ssh /vesta-start/etc/ssh \
 && rm -rf /etc/ssh \
 && ln -s /vesta/etc/ssh /etc/ssh \
 \
 && mkdir -p /etc/fail2ban \
 && mv /etc/fail2ban /vesta-start/etc/fail2ban \
 && rm -rf /etc/fail2ban \
 && ln -s /vesta/etc/fail2ban /etc/fail2ban \
 \
 && mv /etc/php /vesta-start/etc/php \
 && rm -rf /etc/php \
 && ln -s /vesta/etc/php /etc/php \
 \
 && mv /etc/nginx   /vesta-start/etc/nginx \
 && rm -rf /etc/nginx \
 && ln -s /vesta/etc/nginx /etc/nginx \
 \
 && mv /etc/exim4   /vesta-start/etc/exim4 \
 && rm -rf /etc/exim4 \
 && ln -s /vesta/etc/exim4 /etc/exim4 \
 \
 && mv /etc/spamassassin   /vesta-start/etc/spamassassin \
 && rm -rf /etc/spamassassin \
 && ln -s /vesta/etc/spamassassin /etc/spamassassin \
 \
 && mv /etc/mail   /vesta-start/etc/mail \
 && rm -rf /etc/mail \
 && ln -s /vesta/etc/mail /etc/mail \
 \
 && mv /etc/awstats /vesta-start/etc/awstats \
 && rm -rf /etc/awstats \
 && ln -s /vesta/etc/awstats /etc/awstats \
 \
 && mv /etc/dovecot /vesta-start/etc/dovecot \
 && rm -rf /etc/dovecot \
 && ln -s /vesta/etc/dovecot /etc/dovecot \
 \
 && mv /etc/mysql   /vesta-start/etc/mysql \
 && rm -rf /etc/mysql \
 && ln -s /vesta/etc/mysql /etc/mysql \
 \
 && mv /var/lib/mysql /vesta-start/var/lib/mysql \
 && rm -rf /var/lib/mysql \
 && ln -s /vesta/var/lib/mysql /var/lib/mysql \
 \
 && mv /etc/postgresql   /vesta-start/etc/postgresql \
 && rm -rf /etc/postgresql \
 && ln -s /vesta/etc/postgresql /etc/postgresql \
 \
 && mv /var/lib/postgresql /vesta-start/var/lib/postgresql \
 && rm -rf /var/lib/postgresql \
 && ln -s /vesta/var/lib/postgresql /var/lib/postgresql \
 \
 && mv /root /vesta-start/root \
 && rm -rf /root \
 && ln -s /vesta/root /root \
 \
 && mv /usr/local/vesta /vesta-start/local/vesta \
 && rm -rf /usr/local/vesta \
 && ln -s /vesta/local/vesta /usr/local/vesta \
 \
 && mv /etc/memcached.conf /vesta-start/etc/memcached.conf \
 && rm -rf /etc/memcached.conf \
 && ln -s /vesta/etc/memcached.conf /etc/memcached.conf \
 \
 && mv /etc/timezone /vesta-start/etc/timezone \
 && rm -rf /etc/timezone \
 && ln -s /vesta/etc/timezone /etc/timezone \
 \
 && mv /etc/bind /vesta-start/etc/bind \
 && rm -rf /etc/bind \
 && ln -s /vesta/etc/bind /etc/bind \
 \
 && mv /etc/profile /vesta-start/etc/profile \
 && rm -rf /etc/profile \
 && ln -s /vesta/etc/profile /etc/profile \
 \
 && mv /var/log /vesta-start/var/log \
 && rm -rf /var/log \
 && ln -s /vesta/var/log /var/log \
 \
 && mkdir -p /sysprepz/home \
 && rsync -a /home/* /sysprepz/home \
 && mv /sysprepz/admin/bin /sysprepz/home/admin \
 && chown -R admin:admin /sysprepz/home/admin/bin \
 \
 && mkdir -p /vesta-start/local/vesta/data/sessions \
 && chmod 775 /vesta-start/local/vesta/data/sessions \
 && chown root:admin /vesta-start/local/vesta/data/sessions \
# fix roundcube error log permission
 && touch /vesta-start/var/log/roundcube/errors \
 && chown -R www-data:www-data /vesta-start/var/log/roundcube \
 && chmod 775 /vesta-start/var/log/roundcube/errors \
## inetutils-syslogd is not installed, but this file is present and conflicts with /etc/logrotate.d/rsyslog
 && rm -f /etc/logrotate.d/inetutils-syslogd

VOLUME ["/vesta", "/home", "/backup"]

EXPOSE 22 25 53 54 80 110 143 443 465 587 993 995 1194 3000 3306 5432 5984 6379 8083 10022 11211 27017
