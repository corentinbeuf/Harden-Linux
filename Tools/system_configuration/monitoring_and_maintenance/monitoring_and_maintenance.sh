function Set-UpdateService() {
    local changed=false

    services_to_check=(
        "apt-daily-upgrade.service"
        "apt-daily.timer"
    )

    for service in "${services_to_check[@]}"; do
        if ! systemctl is-active --quiet "$service" &>/dev/null; then
            sudo systemctl start "$service"
            changed=true
        fi

        if ! systemctl is-enabled --quiet "$service" &>/dev/null; then
            sudo systemctl enable "$service"
            changed=true
        fi
    done

    if [[ "$changed" == true ]]; then
        echo -e "${GREEN}[Task R61] : Update service has been enabled.${NC}"
    else
        echo -e "${YELLOW}[Task R61] : Update service are already enabled.${NC}"
    fi 
}