function Disable-ServiceAccount() {
    local added=false
    local service_accounts_to_disable=()
    local minUserUID
    minUserUID=$(sudo awk '$1=="UID_MIN" {print $2}' /etc/login.defs)

    while IFS=: read -r user _ uid _ _ _ shell; do
        # Exclude root and nobody users
        [[ "$uid" -eq 0 || "$uid" -eq 65534 ]] && continue

        [[ "$uid" -lt 1 || "$uid" -ge "$minUserUID" ]] && continue

        if [[ "$shell" = "/bin/sh" || \
              "$shell" = "/usr/bin/sh" || \
              "$shell" = "/bin/bash" || \
              "$shell" = "/usr/bin/bash" || \
              "$shell" = "/bin/rbash" || \
              "$shell" = "/usr/bin/rbash" || \
              "$shell" = "/usr/bin/dash" ]]; then
            service_accounts_to_disable+=("$user")
        fi

    done < /etc/passwd

    local nologin_shell
    nologin_shell=$(command -v nologin)

     for service_user in "${service_accounts_to_disable[@]}"; do
        sudo usermod --shell "$nologin_shell" "$service_user"
        added=true
    done

    if [[ "$added" == true ]]; then
        echo -e "${GREEN}[Task R34] : Service account has been disabled.${NC}"
    else
        echo -e "${YELLOW}[Task R34] : Service accounts are already disabled.${NC}"
    fi
}