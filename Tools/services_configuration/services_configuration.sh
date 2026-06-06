# TODO: Implement the graphical service (X)
function Disable-UnnecessaryService() {
    local changed=false

    services_to_check=(
        "portmap"
        "rpc.statd"
        "rpcbind"
        "dbus"
        "hald"
        "ConsoleKit"
        "cups"
        "PolicyKit"
        "avahi"
    )

    for service in "${services_to_check[@]}"; do
        if sudo systemctl list-units --type service | grep "${service}" &>/dev/null; then
            sudo systemctl stop "${service}"
            sudo systemctl disable "${service}"
            sudo systemctl mask "${service}"
            changed=true
        fi
    done

    if [[ "$changed" == true ]]; then
        echo -e "${GREEN}[Task R62] : Unnecessary service has been disabled.${NC}"
    else
        echo -e "${YELLOW}[Task R62] : Unnecessary service are already disabled.${NC}"
    fi 
}