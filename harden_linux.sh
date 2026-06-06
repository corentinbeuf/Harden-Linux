#!/bin/bash

SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

chmod +x "$SCRIPT_DIR/Menu/detailed_menu.sh"
chmod +x "$SCRIPT_DIR/Audit/audit.sh"

source "$SCRIPT_DIR/Tools/kernel_configuration/dynamic_configuration/memory_configuration.sh"
source "$SCRIPT_DIR/Tools/kernel_configuration/dynamic_configuration/kernel_configuration.sh"
source "$SCRIPT_DIR/Tools/kernel_configuration/dynamic_configuration/process_configuration.sh"
source "$SCRIPT_DIR/Tools/kernel_configuration/dynamic_configuration/network_configuration.sh"
source "$SCRIPT_DIR/Tools/kernel_configuration/dynamic_configuration/fs_configuration.sh"

source "$SCRIPT_DIR/Tools/system_configuration/files_and_directories/access_rights.sh"
source "$SCRIPT_DIR/Tools/system_configuration/monitoring_and_maintenance/monitoring_and_maintenance.sh"

function Show-Banner() {
    clear
    echo -e "${CYAN}"

    echo -e "${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}  Linux Hardening & Security Configuration${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  Version:${NC} ${VERSION}"
    echo -e "${CYAN}  Author:${NC}  ${AUTHOR}"
    echo -e "${CYAN}  GitHub:${NC}  ${GITHUB}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # Aucune couleur

VERSION="1.0"
AUTHOR="Corentin Beuf"
GITHUB="https://github.com/corentinbeuf/Harden-Linux"

Show-Banner

PS3="Please select a task ? "
options=("Audit" "Configure all tasks" "Configure a specific task" "Quit")

select choix in "${options[@]}"; do
    case $REPLY in
        1)
            ./Audit/audit.sh
            ;;
        2)
            Set-Iommu #R7
            Set-MemoryOptions #R8
            Set-KernelOptions #R9
            Set-KernelModulesLoading #R10
            Set-YAMAOptionsSysctl #R11
            Set-YAMAOptionsGrub #R11
            Set-NetworkOptions #R12
            Set-Ipv6Sysctl #R13
            Set-Ipv6OptionsGrub #R13
            Set-FileSystemOptions #R14

            Set-TempDirectory #R55
            Remove-SetuidAndSetgid #R56

            Set-UpdateService #R61
            ;;
        3)

            ;;
        4)
            echo -e "${YELLOW} You need to restart the system to fully take in consideration the modifications !${NC}"
            break
            ;;
        *)
            echo -e "${RED} Invalid option, please try again !${NC}"
            ;;
    esac
done