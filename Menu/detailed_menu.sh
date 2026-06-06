#!/bin/bash

SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$PROJECT_ROOT/Tools/kernel_configuration/dynamic_configuration/memory_configuration.sh"
source "$PROJECT_ROOT/Tools/kernel_configuration/dynamic_configuration/kernel_configuration.sh"
source "$PROJECT_ROOT/Tools/kernel_configuration/dynamic_configuration/process_configuration.sh"
source "$PROJECT_ROOT/Tools/kernel_configuration/dynamic_configuration/network_configuration.sh"
source "$PROJECT_ROOT/Tools/kernel_configuration/dynamic_configuration/fs_configuration.sh"

source "$PROJECT_ROOT/Tools/system_configuration/account_access/administrator_account.sh"
source "$PROJECT_ROOT/Tools/system_configuration/account_access/service_account.sh"
source "$PROJECT_ROOT/Tools/system_configuration/files_and_directories/sensitive_files_and_directories.sh"
source "$PROJECT_ROOT/Tools/system_configuration/files_and_directories/access_rights.sh"
source "$PROJECT_ROOT/Tools/system_configuration/monitoring_and_maintenance/monitoring_and_maintenance.sh"
source "$PROJECT_ROOT/Tools/services_configuration/services_configuration.sh"
source "$PROJECT_ROOT/Tools/services_configuration/system_services/pam.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No color

RED_MENU=$'\e[0;31m'
CYAN_MENU=$'\e[0;36m'
NC_MENU=$'\e[0m'

PS3="Please select a task ? "
options=("${CYAN_MENU}R7 - Activating the IOMMU${NC_MENU}"\
 "${CYAN_MENU}R8 - Configuring the memory options${NC_MENU}"\
 "${CYAN_MENU}R9 - Configuring the kernel options${NC_MENU}"\
 "${CYAN_MENU}R11 - Configuration option of the Yama LSM${NC_MENU}"\
 "${CYAN_MENU}R12 - IPv4 configuration options${NC_MENU}"\
 "${CYAN_MENU}R13 - Disabling IPv6${NC_MENU}"\
 "${CYAN_MENU}R14 - File system configuration options${NC_MENU}"\
 "${CYAN_MENU}R33 - Ensuring the imputability of administration actions${NC_MENU}"\
 "${CYAN_MENU}R34 - Disabling the service accounts${NC_MENU}"\
 "${CYAN_MENU}R50 - Limiting the rights to access sensitive files and directories${NC_MENU}"\
 "${CYAN_MENU}R55 - Dedicating temporary directories to users${NC_MENU}"\
 "${CYAN_MENU}R56 - Avoiding using executables with setuid and setgid rights${NC_MENU}"\
 "${CYAN_MENU}R61 - Updating regularly the system${NC_MENU}"\
 "${CYAN_MENU}R62 - Disabling the non-necessary services${NC_MENU}"\
 "${CYAN_MENU}R68 - Protecting the stored passwords${NC_MENU}"\
  "${RED_MENU}Return${NC_MENU}")

select choice in "${options[@]}"; do
    case $REPLY in
        1)
            Set-Iommu #R7
            ;;
        2)
            Set-MemoryOptions #R8
            ;;
        3)
            Set-KernelOptions #R9
            ;;
        4)
            Set-YAMAOptionsSysctl #R11
            Set-YAMAOptionsGrub #R11
            ;;
        5)
            Set-NetworkOptions #R12
            ;;
        6)
            Set-Ipv6Sysctl #R13
            Set-Ipv6OptionsGrub #R13
            ;;
        7)
            Set-FileSystemOptions #R14
            ;;
        8)
            Set-AdminAccountabilit #R33
            ;;
        9)
            Disable-ServiceAccount #R34
            ;;
        10)
            Set-PermissionsOnSensitiveFiles #R50
            ;;
        11)
            Set-TempDirectory #R55
            ;;
        12)
            Remove-SetuidAndSetgid #R56
            ;;
        13)
            Set-UpdateService #R61
            ;;
        14)
            Disable-UnnecessaryService #R62
            ;;
        15)
            Set-PAMProtectedPassword #R68
            ;;
        16)
            break
            ;;
        *)
            echo -e "${RED} Invalid option, please try again !${NC}"
            ;;
    esac
done