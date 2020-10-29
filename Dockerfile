
From cloudfoundry/cflinuxfs3:latest

Run mkdir -pv /home/vcap/app/php
Run mkdir -pv /tmp/input
Copy ./build.sh /root/
Run chmod 755 /root/build.sh

Entrypoint [ "/root/build.sh" ]
CMD [ "/bin/false" ]

#Run cd /home/vcap/app && tar -xpzf /tmp/input/droplet_be02e21b-c0b5-4093-9998-0bead1a3dc2b.tgz
#Run cd /home/vcap/app/php && unzip /tmp/input/php_buildpack-cached-cflinuxfs3-v4.4.22.zip
#Run echo "vcap ALL=(ALL:ALL) NOPASSWD: ALL" >>/etc/sudoers

ARG BUILDPACK
ENV BUILDPACK="${BUILDPACK:-}"

Run aptitude update

Run aptitude install -y wget vim php-pear tree git apache2-dev autoconf automake bison chrpath debhelper dh-apache2 dh-systemd dpkg-dev firebird-dev flex freetds-dev libapparmor-dev libapr1-dev libargon2-0-dev libbz2-dev libc-client-dev libcurl4-openssl-dev libdb-dev libedit-dev libenchant-dev libevent-dev libexpat1-dev libfreetype6-dev libgcrypt20-dev libgd-dev libgdbm-dev libglib2.0-dev libgmp3-dev libicu-dev libjpeg-dev libkrb5-dev libldap2-dev libmagic-dev libmcrypt-dev libmhash-dev libmariadb-dev-compat libnss-myhostname libonig-dev libpam0g-dev libpcre3-dev libpng-dev libpq-dev libpspell-dev libqdbm-dev librecode-dev libsasl2-dev libsnmp-dev libsodium-dev libsqlite3-dev libssl-dev libsystemd-dev libtidy-dev libtool libwebp-dev libwrap0-dev libxml2-dev libxmlrpc-epi-dev libxmltok1-dev libxslt1-dev libzip-dev locales-all mysql-server netbase netcat-traditional re2c systemtap-sdt-dev tzdata unixodbc-dev zlib1g-dev

Run cd /tmp/input && git clone https://github.com/php/php-src

