#!/bin/bash

PWD=$(dirname "$(readlink -f "$0")")
PARENT=$(dirname $PWD)

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

if [ $SETUP_IMAPSYNC == "yes" ]; then
  echo '- Installing IMAPSync'
  apt install -y make cpanminus libauthen-ntlm-perl libclass-load-perl libcrypt-ssleay-perl \
  libdata-uniqid-perl libdigest-hmac-perl libdist-checkconflicts-perl libio-compress-perl \
  libfile-copy-recursive-perl libio-socket-inet6-perl libio-socket-ssl-perl libio-tee-perl \
  libmail-imapclient-perl libmodule-scandeps-perl libnet-ssleay-perl libpar-packer-perl \
  libreadonly-perl libregexp-common-perl libsys-meminfo-perl libterm-readkey-perl \
  libtest-fatal-perl libtest-mock-guard-perl libtest-pod-perl libtest-requires-perl \
  libtest-simple-perl libunicode-string-perl liburi-perl libtest-nowarnings-perl \
  libtest-deep-perl libtest-warn-perl

  cpanm Sys::MemInfo Data::Uniqid Mail::IMAPClient Email::Address JSON::WebToken
  git clone https://github.com/imapsync/imapsync.git /usr/src/imapsync
  cp /usr/src/imapsync/imapsync /usr/bin ; imapsync --testslive
fi
