function Set-YAMAOptionsSysctl() {
    local sysctl_file="/etc/sysctl.d/anssi-configure-yama.conf"
    local params=(
        "kernel.yama.ptrace_scope=1"
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
            # echo "${key} = ${value}" >> "$sysctl_file"
            echo "" > /dev/null
        fi

        added=true
    done

    if [[ "$added" == true ]]; then
        # sysctl --system 2>/dev/null
        sysctl -p $sysctl_file 2>/dev/null
        echo -e "${GREEN}[Task R11] : Sysctl hardening options have been applied.${NC}"
    else
        echo -e "${YELLOW}[Task R11] : Sysctl hardening options are already configured.${NC}"
    fi
}

function Set-YAMAOptionsGrub() {
    local grub_file="/etc/default/grub"
    local params=(
        "security=yama"
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
        echo -e "${GREEN}[Task R11] : YAMA option have been added to the GRUB.${NC}"
    else
        echo -e "${YELLOW}[Task R11] : YAMA option is already configured in the GRUB.${NC}"
    fi
}