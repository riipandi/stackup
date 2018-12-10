# Linux Nginx PHP Stack

Another LEMP Stack installer script.

## Usage

Clone this repo, run `setup.sh`, and answer the questions.

```bash
apt -y install git curl

git clone https://github.com/riipandi/lempstack /usr/src/lempstack ; cd $_

find . -type f -name '*.sh' -exec chmod +x {} \;
find . -type f -name '.git*' -exec rm -fr {} \;

bash setup.sh
```

## Create MySQL Database

```bash
mysql -uroot -e "CREATE DATABASE IF NOT EXISTS dbname"
mysql -uroot -e "CREATE USER IF NOT EXISTS 'dbname'@'127.0.0.1' IDENTIFIED BY 'dbpass'"
mysql -uroot -e "GRANT ALL PRIVILEGES ON dbname.* TO 'dbname'@'127.0.0.1'; FLUSH PRIVILEGES"
```

## Create Nginx vHost

```bash
# Web directory
mkdir -p /srv/domain.tld/public
cp /etc/nginx/manifest/welcome.tpl /srv/domain.tld/public/index.php
chown -R www-data: /srv/domain.tld

# Virtual Host Configuration
cp /etc/nginx/manifest/vhost-php.tpl /etc/nginx/vhost.d/domain.tld.conf
sed -i "s/HOSTNAME/domain.tld/" /etc/nginx/vhost.d/domain.tld.conf

# Generet SSL Certificate
systemctl stop nginx ; certbot certonly --standalone --rsa-key-size 4096 \
 --agree-tos --register-unsafely-without-email \
 -d domain.tld -d www.domain.tld

# Set Permission File dan Folder
cd /srv/domain.tld
find . -type d -exec chmod 0777 {} \;
find . -type f -exec chmod 0775 {} \;
find . -exec chown -R www-data: {} \;
```

## License

This project is open-sourced software licensed under the
[MIT license](https://opensource.org/licenses/MIT).
