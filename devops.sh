#!/usr/bin/env bash
if [[ ! $EUID -ne 0 ]]; then echo -e 'This script must be run as non-root user' ; exit 1 ; fi


# Switch to another user: sudo -u goku bash
#-----------------------------------------------------------------------------------------

echo "Instaling Composer packages..."

composer global require hirak/prestissimo laravel/installer wp-cli/wp-cli riipandi/wink-installer

echo "Instaling NPM packages using Yarn..."

yarn global add ghost-cli@latest

# Add Yarn and Composer to path
echo "Configuring environment variables..."
if ! grep -q 'Composer' $HOME/.bashrc ; then
    touch "$HOME/.bashrc"
    {
        echo ''
        echo '# Composer and Yarn'
        echo 'export PATH=$PATH:$HOME/.config/composer/vendor/bin:$HOME/.yarn/bin'
        echo ''
    } >> "$HOME/.bashrc"
    source "$HOME/.bashrc"
fi

# Setup SSH Key
mkdir -p $HOME/.ssh ; chmod 0700 $_
touch $HOME/.ssh/id_rsa ; chmod 0600 $_
touch $HOME/.ssh/id_rsa.pub ; chmod 0600 $_
touch $HOME/.ssh/authorized_keys ; chmod 0600 $_
