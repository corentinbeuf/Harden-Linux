function Set-Iommu() {
    local grub_file="/etc/default/grub"
    local params=(
        "iommu=force"
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
        update-grub 2>/dev/null
        echo -e "${GREEN}[Task R7] : IOMMU option have been added to the GRUB.${NC}"
    else
        echo -e "${YELLOW}[Task R7] : IOMMU option is already configured in the GRUB.${NC}"
    fi
}