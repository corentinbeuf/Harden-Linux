function Set-IPAddressOnEachService() {
    local LOCAL_IP_ADDRESS
    LOCAL_IP_ADDRESS="$(hostname -I | awk '{print $1}')"

    local services_to_check=(
        "zabbix-agent"
        "glpi-agent"
        "mysql"
        "rsync"
    )

    local changed=false
    local changed_services=()

    for service in "${services_to_check[@]}"; do

        if ! dpkg -l "${service}" 2>/dev/null | grep -q "^ii"; then
            continue
        fi

        if ! systemctl is-active --quiet "${service}"; then
            continue
        fi

        if [ "$service" == "zabbix-agent" ]; then
            if ! grep -qF "ListenIP=${LOCAL_IP_ADDRESS}" "/etc/zabbix/zabbix_agentd.conf"; then
                sudo sed -i "s/^.*ListenIP=.*/ListenIP=${LOCAL_IP_ADDRESS}/" /etc/zabbix/zabbix_agentd.conf
                sudo systemctl --quiet restart "${service}"
                changed=true
                changed_services+=("${service}")
            fi

        elif [ "$service" == "glpi-agent" ]; then
            if ! grep -qF "httpd-ip = ${LOCAL_IP_ADDRESS}" "/etc/glpi-agent/agent.cfg"; then
                sudo sed -i "s/^.*httpd-ip =.*/httpd-ip = ${LOCAL_IP_ADDRESS}/" /etc/glpi-agent/agent.cfg
                sudo systemctl --quiet restart "${service}"
                changed=true
                changed_services+=("${service}")
            fi

        elif [ "$service" == "mysql" ]; then
            if ! grep -qF "bind-address = ${LOCAL_IP_ADDRESS}" "/etc/mysql/mysql.conf.d/mysqld.cnf"; then
                sudo sed -i "s/^.*bind-address.*/bind-address = ${LOCAL_IP_ADDRESS}/" /etc/mysql/mysql.conf.d/mysqld.cnf
                sudo systemctl --quiet restart "${service}"
                changed=true
                changed_services+=("${service}")
            fi

        elif [ "$service" == "rsync" ]; then
            if ! grep -qF "address = ${LOCAL_IP_ADDRESS}" "/etc/rsyncd.conf"; then
                sudo sed -i "/pid file/a address = ${LOCAL_IP_ADDRESS}" /etc/rsyncd.conf
                sudo systemctl --quiet restart "${service}"
                changed=true
                changed_services+=("${service}")
            fi
        fi

    done

    if [[ "$changed" == true ]]; then
        echo -e "${GREEN}[Task R80] : IP address restricted for : ${changed_services[*]}.${NC}"
    else
        echo -e "${YELLOW}[Task R80] : All services are already bound to a specific IP address.${NC}"
    fi
}