#!/usr/bin/env bash

[ -f /usr/share/cracklib/pw_dict.pwd ] && gzip -9 /usr/share/cracklib/pw_dict.pwd
localedef --list-archive | grep -v en_US | xargs localedef --delete-from-archive
mv /usr/lib/locale/locale-archive /usr/lib/locale/locale-archive.tmpl
/usr/sbin/build-locale-archive &> /dev/null
mv /usr/share/locale/en /usr/share/locale/en_US /tmp
rm -rf /usr/share/locale/*
mv /tmp/en /tmp/en_US /usr/share/locale/
mv /usr/share/i18n/locales/en_US /tmp
rm -rf /usr/share/i18n/locales/*
mv /tmp/en_US /usr/share/i18n/locales/
rm -vf /etc/yum/protected.d/*
rm -rf /boot/*
echo "yum clean"
yum clean all
truncate -c -s 0 /var/log/yum.log
rm -rf /var/lib/yum/yumdb/*
rm -rf /var/lib/yum/history/*
rm -rf /var/cache/*
rm -rf /var/tmp/*
rm -rf /tmp/*
find /usr/lib/python2.7/site-packages -name '*.pyc' -delete
