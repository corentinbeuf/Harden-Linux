# Désactiver la connexion SSH root
sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart sshd

# Vérifier que root a un shell désactivé
usermod -s /usr/sbin/nologin root

#Sudo tracé — chaque admin utilise son compte + sudo
# /etc/sudoers.d/admins
%sudo ALL=(ALL) ALL
Defaults logfile=/var/log/sudo.log
Defaults log_input, log_output          # enregistre les entrées/sorties
Defaults iolog_dir=/var/log/sudo-io/%{user}

#Journalisation centralisée — envoyer les logs hors du serveur
# /etc/rsyslog.d/remote.conf
# Envoyer tous les logs vers un syslog central
*.* @syslog-central.mondomaine.fr:514   # UDP
*.* @@syslog-central.mondomaine.fr:514  # TCP (recommandé)

# Redémarrer rsyslog
systemctl restart rsyslog

#Logs protégés — intégrité et rétention
# Droits stricts sur les logs sudo
chmod 640 /var/log/sudo.log
chown root:adm /var/log/sudo.log

# Rétention via logrotate (/etc/logrotate.d/sudo)
/var/log/sudo.log {
    rotate 90
    daily
    compress
    missingok
    notifempty
    create 640 root adm
}

# Protéger contre la suppression (attribut immuable)
chattr +a /var/log/sudo.log

#Vérification rapide de l'ensemble
# Connexion root SSH désactivée ?
grep PermitRootLogin /etc/ssh/sshd_config

# Sudo configuré avec logs ?
grep -E "logfile|log_output" /etc/sudoers /etc/sudoers.d/* 2>/dev/null

# Logs envoyés à distance ?
grep -E "^[^#].*@" /etc/rsyslog.d/*.conf /etc/rsyslog.conf 2>/dev/null

# Attribut immuable sur les logs ?
lsattr /var/log/sudo.log 2>/dev/null