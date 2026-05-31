# "kernel.pid_max=65536"
function Set-KernelOptions() {
    local sysctl_file="/etc/sysctl.d/anssi-configure-kernel.conf"
    local params=(
        "kernel.dmesg_restrict=1"
        "kernel.kptr_restrict=2"
        "kernel.perf_cpu_time_max_percent=1"
        "kernel.perf_event_max_sample_rate=1"
        "kernel.perf_event_paranoid=2"
        "kernel.randomize_va_space=2"
        "kernel.sysrq=0"
        "kernel.unprivileged_bpf_disabled=1"
        "kernel.panic_on_oops=1"
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
        echo -e "${GREEN}[Task R9] : Sysctl hardening options have been applied.${NC}"
    else
        echo -e "${YELLOW}[Task R9] : Sysctl hardening options are already configured.${NC}"
    fi
}

function Set-KernelModulesLoading() {
    local sysctl_file="/etc/sysctl.d/anssi-configure-kernel.conf"
    local params=(
        "kernel.modules_disabled=1"
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
        echo -e "${GREEN}[Task R10] : Sysctl hardening options have been applied.${NC}"
    else
        echo -e "${YELLOW}[Task R10] : Sysctl hardening options are already configured.${NC}"
    fi
}