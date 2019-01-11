#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi

PWD=$(dirname "$(readlink -f "$0")")
PARENT=$(dirname "$PWD")


# Install phpPgAdmin
#-----------------------------------------------------------------------------------------
[[ ! -d /var/www/pgadmin ]] || rm -fr /var/www/pgadmin

project="https://api.github.com/repos/phppgadmin/phppgadmin/releases/latest"
release=`curl -s $project | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'`

curl -fsSL https://github.com/phppgadmin/phppgadmin/archive/$release.zip | bsdtar -xvf- -C /tmp
mv /tmp/phppgadmin-$release /var/www/pgadmin

cat > /var/www/pgadmin/conf/config.inc.php <<EOF
<?php @ini_set('display_errors', '0');
\$conf['servers'][0]['desc']            = 'PostgreSQL';
\$conf['servers'][0]['host']            = '127.0.0.1';
\$conf['servers'][0]['port']            = 5432;
\$conf['servers'][0]['sslmode']         = 'allow';
\$conf['servers'][0]['defaultdb']       = 'template1';
\$conf['servers'][0]['pg_dump_path']    = '/usr/bin/pg_dump';
\$conf['servers'][0]['pg_dumpall_path'] = '/usr/bin/pg_dumpall';
\$conf['default_lang']                  = 'auto';
\$conf['autocomplete']                  = 'default on';
\$conf['extra_login_security']          = false;
\$conf['owned_only']                    = false;
\$conf['show_comments']                 = true;
\$conf['show_advanced']                 = false;
\$conf['show_system']                   = false;
\$conf['min_password_length']           = 8;
\$conf['left_width']                    = 260;
\$conf['theme']                         = 'default';
\$conf['show_oids']                     = false;
\$conf['max_rows']                      = 30;
\$conf['max_chars']                     = 50;
\$conf['use_xhtml_strict']              = false;
\$conf['ajax_refresh']                  = 3;
\$conf['plugins']                       = array();
\$conf['version']                       = 19;
EOF

chmod 0755 /var/www/pgadmin
find /var/www/pgadmin/. -type d -exec chmod 0777 {} \;
find /var/www/pgadmin/. -type f -exec chmod 0644 {} \;
chown -R www-data: /var/www/pgadmin
