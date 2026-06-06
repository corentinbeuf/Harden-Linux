function Set-PermissionsOnSensitiveFiles() {
    sensitive_files=(
        "/etc/passwd|644|root:root"
        "/etc/shadow|640|root:shadow"
        "/etc/group|644|root:root"
        "/etc/gshadow|640|root:shadow"
        "/etc/sudoers|440|root:root"
        "/etc/ssh/sshd_config|600|root:root"
        "/var/log/journal|2755|root:systemd-journal"
        "/var/log/private|700|root:root"
        "/var/log/wtmp|664|root:utpm"
        "/var/log/btmp|660|root:utpm"
        "/boot/grub/grub.cfg|600|root:root"
    )

    for file in "${sensitive_files[@]}"; do
        IFS='|' read -r path perms owner <<< "$file"

        if [[ ! -e "$path" ]]; then
            continue
        fi

        IFS=':' read -r exp_user exp_group <<< "$owner"

        current_user=$(stat -c "%U" "$path")
        current_group=$(stat -c "%G" "$path")
        current_perms=$(stat -c "%a" "$path")

        if [[ "$current_perms" != "$perms" ]]; then
            sudo chmod "$perms" "$path"
            added=true
        fi

        if [[ "$current_user" != "$exp_user" ]]; then
            sudo chown "$exp_user" "$path"
            added=true
        fi

        if [[ "$current_group" != "$exp_group" ]]; then
            sudo chgrp "$exp_group" "$path"
            added=true
        fi

    done

    if [[ "$added" == true ]]; then
        echo -e "${GREEN}[Task R50] : Setup correct permissions on the sensitive files.${NC}"
    else
        echo -e "${YELLOW}[Task R50] : Permissions on the sensitive files are correct.${NC}"
    fi
}