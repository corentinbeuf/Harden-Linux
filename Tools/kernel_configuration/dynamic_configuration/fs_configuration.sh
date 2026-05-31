function Set-FileSystemOptions() {
    local sysctl_file="/etc/sysctl.d/anssi-configure-fs.conf"
    local params=(
        "fs.suid_dumpable = 0"
        "fs.protected_fifos=2"
        "fs.protected_regular=2"
        "fs.protected_symlinks=1"
        "fs.protected_hardlinks=1"
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
        echo -e "${GREEN}[Task R14] : Sysctl hardening options have been applied.${NC}"
    else
        echo -e "${YELLOW}[Task R14] : Sysctl hardening options are already configured.${NC}"
    fi
}