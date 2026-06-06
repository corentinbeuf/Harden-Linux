function Set-TempDirectory() {
    packages_to_install=(
        "libpam-tmpdir"
    )

    for package in "${packages_to_install[@]}"; do
        if dpkg -l | awk '{print $2}' | grep -qi "$package"; then
            echo -e "${YELLOW}[Task R55] : Package ${package} has already installed.${NC}"
        else
            echo -e "${GREEN}[Task R55] : ${package} installed on the server.${NC}"
            export DEBIAN_FRONTEND=noninteractive
            sudo apt-get install -y $package >/dev/null 2>&1
            unset DEBIAN_FRONTEND

            if ! grep -q "pam_tmpdir.so" "/etc/pam.d/common-session"; then
                echo "session optional pam_tmpdir.so" | sudo tee -a /etc/pam.d/common-session >/dev/null
                echo -e "${GREEN}[Task R55] : PAM Module 'tmpdir' was configured.${NC}"
            else
                echo -e "${YELLOW}[Task R55] : tmpdir is already configured${NC}"
            fi
        fi
    done    
}

function Remove-SetuidAndSetgid() {
    local added=false
    local allowed=(
        "/usr/sbin/unix_chkpwd"
        "/usr/sbin/exim4"
        "/usr/bin/newgrp"
        "/usr/bin/passwd"
        "/usr/bin/ssh-agent"
        "/usr/bin/su"
        "/usr/bin/chsh"
        "/usr/bin/chage"
        "/usr/bin/gpasswd"
        "/usr/bin/crontab"
        "/usr/bin/mount"
        "/usr/bin/sudo"
        "/usr/bin/expiry"
        "/usr/bin/chfn"
        "/usr/bin/umount"
        "/usr/bin/dotlockfile"
        "/usr/libexec/pam-tmpdir/pam-tmpdir-helper"
        "/usr/lib/openssh/ssh-keysign"
        "/usr/lib/dbus-1.0/dbus-daemon-launch-helper"
    )

    while IFS= read -r file; do

        [[ -e "$file" ]] || continue

        local is_allowed=false

        for a in "${allowed[@]}"; do
            if [[ "$file" == "$a" ]]; then
                is_allowed=true
                break
            fi
        done

        if [[ "$is_allowed" == false ]]; then

            if sudo chmod u-s,g-s "$file"; then
                added=true
            else
                echo ""
            fi
        fi

    done < <(
        sudo find / -xdev -type f \( -perm -4000 -o -perm -2000 \) 2>/dev/null
    )

    if [[ "$added" == true ]]; then
        echo -e "${GREEN}[Task R56] : Non-legitimate SUID/SGID removed."
    else
        echo -e "${YELLOW}[Task R56] : No unauthorized SUID/SGID found."
    fi
}