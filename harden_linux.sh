#!/bin/bash

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

VERSION="2.0"
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
            
            ;;
        3)

            ;;
        4)
            break
            ;;
        *)
            echo -e "${RED} Invalid option, please try again !${NC}"
            ;;
    esac
done