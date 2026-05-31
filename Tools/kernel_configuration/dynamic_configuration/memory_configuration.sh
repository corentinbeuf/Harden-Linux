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
        update-grub2 2>/dev/null
        echo -e "${GREEN}[Task R7] : IOMMU option have been added to the GRUB.${NC}"
    else
        echo -e "${YELLOW}[Task R7] : IOMMU option is already configured in the GRUB.${NC}"
    fi
}

function Set-MemoryOptions() {
    local grub_file="/etc/default/grub"
    local params=(
        "l1tf=full,force"
        "page_poison=on"
        "pti=on"
        "slab_nomerge=yes"
        "slub_debug=FZP"
        "spec_store_bypass_disable=seccomp"
        "spectre_v2=on"
        "mds=full,nosmt"
        "mce=0"
        "page_alloc.shuffle=1"
        "rng_core.default_quality=500"
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
        echo -e "${GREEN}[Task R8] : Memory hardening options have been added to GRUB.${NC}"
    else
        echo -e "${YELLOW}[Task R8] : Memory hardening options are already configured in GRUB.${NC}"
    fi
}