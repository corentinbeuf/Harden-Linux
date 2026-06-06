function Set-PAMProtectedPassword() {
    if grep -Eq 'pam_unix\.so.*yescrypt.*rounds=11' /etc/pam.d/common-password; then
        echo -e "${YELLOW}[Task R68] : Stored passwords are already protected.${NC}"
        return
    fi

    if grep -Eq 'pam_unix\.so.*yescrypt' /etc/pam.d/common-password; then
        sudo sed -i -E '/pam_unix\.so/ s/yescrypt/& rounds=11/' /etc/pam.d/common-password

        echo -e "${GREEN}[Task R68] : Added rounds=11 to yescrypt configuration.${NC}"
    fi   
}