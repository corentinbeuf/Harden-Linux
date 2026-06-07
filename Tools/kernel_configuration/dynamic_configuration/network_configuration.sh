function Set-NetworkOptions() {
    local sysctl_file="/etc/sysctl.d/anssi-configure-network.conf"
    local params=(
        "net.core.bpf_jit_harden=2"
        "net.ipv4.ip_forward=0"
        "net.ipv4.conf.all.accept_local=0"
        "net.ipv4.conf.all.accept_redirects=0"
        "net.ipv4.conf.default.accept_redirects=0"
        "net.ipv4.conf.all.secure_redirects=0"
        "net.ipv4.conf.default.secure_redirects=0"
        "net.ipv4.conf.all.shared_media=0"
        "net.ipv4.conf.default.shared_media=0"
        "net.ipv4.conf.all.accept_source_route=0"
        "net.ipv4.conf.default.accept_source_route=0"
        "net.ipv4.conf.all.arp_filter=1"
        "net.ipv4.conf.all.arp_ignore=2"
        "net.ipv4.conf.all.route_localnet=0"
        "net.ipv4.conf.all.drop_gratuitous_arp=1"
        "net.ipv4.conf.default.rp_filter=1"
        "net.ipv4.conf.all.rp_filter=1"
        "net.ipv4.conf.default.send_redirects=0"
        "net.ipv4.conf.all.send_redirects=0"
        "net.ipv4.icmp_ignore_bogus_error_responses=1"
        "net.ipv4.ip_local_port_range=32768 65535"
        "net.ipv4.tcp_rfc1337=1"
        "net.ipv4.tcp_syncookies=1"
    )

    local added=false

    for param in "${params[@]}"; do
        local key value
        key=$(echo "$param" | cut -d= -f1 | tr -d ' ')
        value=$(echo "$param" | cut -d= -f2-)

        # Vérifier si la clé est déjà présente avec la bonne valeur
        if grep -qE "^${key}\s*=\s*${value}" "$sysctl_file" 2>/dev/null; then
            continue
        fi

        # Clé présente mais mauvaise valeur → remplacer
        if grep -qE "^${key}\s*=" "$sysctl_file" 2>/dev/null; then
            sed -i "s|^${key}\s*=.*|${key} = ${value}|" "$sysctl_file"
        else
            echo "${key} = ${value}" | sudo tee -a "$sysctl_file" > /dev/null
        fi

        added=true
    done

    if [[ "$added" == true ]]; then
        # sysctl --system 2>/dev/null
        sysctl -p $sysctl_file 2>/dev/null
        echo -e "${GREEN}[Task R12] : Sysctl hardening options have been applied.${NC}"
    else
        echo -e "${YELLOW}[Task R12] : Sysctl hardening options are already configured.${NC}"
    fi
}

function Set-Ipv6Sysctl() {
    local sysctl_file="/etc/sysctl.d/anssi-configure-ipv6.conf"
    local params=(
        "net.ipv6.conf.default.disable_ipv6=1"
        "net.ipv6.conf.all.disable_ipv6=1"
    )

    local added=false

    for param in "${params[@]}"; do
        local key value
        key=$(echo "$param" | cut -d= -f1 | tr -d ' ')
        value=$(echo "$param" | cut -d= -f2 | tr -d ' ')

        # Vérifier si la clé est déjà présente avec la bonne valeur
        if grep -qE "^${key}\s*=\s*${value}" "$sysctl_file" 2>/dev/null; then
            continue
        fi

        # Clé présente mais mauvaise valeur → remplacer
        if grep -qE "^${key}\s*=" "$sysctl_file" 2>/dev/null; then
            sed -i "s|^${key}\s*=.*|${key} = ${value}|" "$sysctl_file"
        else
            echo "${key} = ${value}" | sudo tee -a "$sysctl_file" > /dev/null
        fi

        added=true
    done

    if [[ "$added" == true ]]; then
        # sysctl --system 2>/dev/null
        sysctl -p $sysctl_file 2>/dev/null
        echo -e "${GREEN}[Task R13] : Sysctl hardening options have been applied.${NC}"
    else
        echo -e "${YELLOW}[Task R13] : Sysctl hardening options are already configured.${NC}"
    fi
}

function Set-Ipv6OptionsGrub() {
    local grub_file="/etc/default/grub"
    local params=(
        "ipv6.disable=1"
    )

    local current
    current=$(grep '^GRUB_CMDLINE_LINUX=' "$grub_file" | sed 's/GRUB_CMDLINE_LINUX="\(.*\)"/\1/')

    local added=false

    for param in "${params[@]}"; do
        if ! echo "$current" | grep -qw "$param"; then
            if [[ -z "$current" ]]; then
                current="$param"
            else
                current="$current $param"
            fi
            added=true
        fi
    done

    if [[ "$added" == true ]]; then
        sed -i "s|^GRUB_CMDLINE_LINUX=\".*\"|GRUB_CMDLINE_LINUX=\"$current\"|" "$grub_file"
        update-grub2 2>/dev/null
        echo -e "${GREEN}[Task R13] : IPV6 option have been added to the GRUB.${NC}"
    else
        echo -e "${YELLOW}[Task R13] : IPV6 option is already configured in the GRUB.${NC}"
    fi
}