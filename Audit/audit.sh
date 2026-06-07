#!/bin/bash
# FR : https://messervices.cyber.gouv.fr/documents-guides/fr_np_linux_configuration-v2.0.pdf
# EN : https://messervices.cyber.gouv.fr/documents-guides/linux_configuration-en-v2.pdf

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

OK_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

function Print-Ok() {
    echo -e "${GREEN}[ OK ]${NC} $1"
    ((OK_COUNT++))
}

function Print-Fail() {
    echo -e "${RED}[ FAIL ]${NC} $1"
    ((FAIL_COUNT++))
}

function Print-Warn() {
    echo -e "${YELLOW}[ WARN ]${NC} $1"
    ((WARN_COUNT++))
}

function Get-UEFI() {
    local desc="$1"

    if [[ "$(mokutil --sb-state)" == "SecureBoot enabled" ]]; then
        Print-Ok "$desc"
    else
        Print-Fail "$desc"
    fi
}

function Get-GrubPassword() {
    local desc="$1"

    local result
    result=$(sudo grep -iE "password_pbkdf2|superusers" /boot/grub/grub.cfg /etc/grub.d/* 2>/dev/null)

    if [[ -n "$result" ]]; then
        Print-Ok "$desc"
    else
        Print-Fail "$desc"
    fi
}

function Get-GrubOption() {
    local option="$1"
    local expected="$2"
    local desc="$3"

    if sudo grep -qE "(^| )${option}=${expected}( |$)" /proc/cmdline; then
        Print-Ok "$desc"
    else
        Print-Fail "$desc (missing or incorrect)"
    fi
}

function Get-SysctlOption() {
    local expected="$1"
    local path="$2"
    local desc="$3"

    if sudo grep -qE "^${expected}$" "/proc/sys/$path"; then
        Print-Ok "$desc"
    else
        Print-Fail "$desc (missing or incorrect)"
    fi
}

# function Get-DefaultAccount() {
#     local uid="$1"
#     local desc="$2"

#     if ! sudo grep -qE "${uid}" "/etc/passwd"; then
#         Print-Ok "$desc"
#     else
#         Print-Fail "$desc (missing or incorrect)"
#     fi
# }

function Get-UnusedAccounts() {
    local days="${1:-180}"
    local desc="$2"
    local unused_users=()

    # Récupère les comptes utilisateurs réels
    while IFS=: read -r user _ uid _ _ _ shell; do
        [[ "$uid" -lt 1000 || "$uid" -eq 65534 ]] && continue
        [[ "$shell" =~ nologin|false ]] && continue

        local last_activity=0

        # Source 1 : lastlog
        local ll_date
        ll_date=$(lastlog -u "$user" 2>/dev/null | tail -1)
        if echo "$ll_date" | grep -qv "Never logged"; then
            local ll_epoch
            ll_epoch=$(date -d "$(echo "$ll_date" | awk '{print $4,$5,$6,$7,$8}')" +%s 2>/dev/null)
            [[ "$ll_epoch" -gt "$last_activity" ]] && last_activity=$ll_epoch
        fi

        # Source 2 : last (wtmp)
        local last_date
        last_date=$(last -w "$user" 2>/dev/null | head -1 | awk '{print $5,$6,$7,$8}')
        if [[ -n "$last_date" && "$last_date" != "wtmp" ]]; then
            local last_epoch
            last_epoch=$(date -d "$last_date" +%s 2>/dev/null)
            [[ "$last_epoch" -gt "$last_activity" ]] && last_activity=$last_epoch
        fi

        # Source 3 : auth.log (sudo/su/ssh)
        local auth_date
        auth_date=$(grep -E "(sudo|su|sshd).*\b${user}\b" /var/log/auth.log 2>/dev/null \
            | tail -1 | awk '{print $1,$2,$3}')
        if [[ -n "$auth_date" ]]; then
            local auth_epoch
            auth_epoch=$(date -d "${auth_date} $(date +%Y)" +%s 2>/dev/null)
            [[ "$auth_epoch" -gt "$last_activity" ]] && last_activity=$auth_epoch
        fi

        # Comparaison
        local threshold
        threshold=$(date -d "$days days ago" +%s)

        if [[ "$last_activity" -eq 0 || "$last_activity" -lt "$threshold" ]]; then
            unused_users+=("$user")
        fi

    done < /etc/passwd

    if [[ "${#unused_users[@]}" -eq 0 ]]; then
        Print-Ok "$desc"
    else
        Print-Fail "$desc : ${unused_users[*]}"
    fi
}

function Get-AdminAccountability() {
    local desc="$1"
    local failures=()

    # 1. Connexion SSH root désactivée
    local permit_root
    permit_root=$(sshd -T 2>/dev/null | grep -i "permitrootlogin" | awk '{print $2}')
    if [[ "$permit_root" != "no" ]]; then
        failures+=("SSH root login allowed ($permit_root)")
    fi

    # 2. Shell root désactivé
    local root_shell
    root_shell=$(awk -F: '$1 == "root" {print $7}' /etc/passwd)
    if [[ "$root_shell" != "/usr/sbin/nologin" && "$root_shell" != "/bin/false" ]]; then
        failures+=("Shell root enabled ($root_shell)")
    fi

    # 3. Sudo configuré avec logs
    local sudo_log
    sudo_log=$(sudo grep -rE "^Defaults.*logfile|^Defaults.*log_output" \
        /etc/sudoers /etc/sudoers.d/* 2>/dev/null)
    if [[ -z "$sudo_log" ]]; then
        failures+=("Sudo without logging configured")
    fi

    # 4. Journalisation centralisée configurée
    # local remote_log
    # remote_log=$(grep -rE "^[^#].*@@?" \
    #     /etc/rsyslog.conf /etc/rsyslog.d/*.conf 2>/dev/null)
    # if [[ -z "$remote_log" ]]; then
    #     failures+=("Aucune journalisation distante configurée")
    # fi

    # 5. Logs sudo protégés (attribut immuable ou droits stricts)
    if [[ -f /var/log/sudo.log ]]; then
        local log_attr
        log_attr=$(lsattr /var/log/sudo.log 2>/dev/null | awk '{print $1}')
        local log_perm
        log_perm=$(stat -c "%a" /var/log/sudo.log 2>/dev/null)
        if [[ "$log_attr" != *"a"* && "$log_perm" != "640" && "$log_perm" != "600" ]]; then
            failures+=("Unprotected Sudo logs (permissions: $log_perm, attr: $log_attr)")
        fi
    else
        failures+=("File /var/log/sudo.log missing")
    fi

    # Résultat
    if [[ "${#failures[@]}" -eq 0 ]]; then
        Print-Ok "$desc"
    else
        for failure in "${failures[@]}"; do
            Print-Fail "$desc : $failure"
        done
    fi
}

function Get-ServiceAccounts() {
    local desc="$1"
    local failures=()

    # Comptes système (UID < 1000) avec un shell interactif
    while IFS=: read -r user _ uid _ _ _ shell; do
        # Exclure root (géré par Get-AdminAccountability)
        # Exclure nobody
        [[ "$uid" -eq 0 || "$uid" -eq 65534 ]] && continue

        # Comptes système uniquement (UID entre 1 et 999)
        [[ "$uid" -lt 1 || "$uid" -ge 1000 ]] && continue

        # Shell interactif = problème
        if [[ "$shell" = "/bin/sh" || \
              "$shell" = "/usr/bin/sh" || \
              "$shell" = "/bin/bash" || \
              "$shell" = "/usr/bin/bash" || \
              "$shell" = "/bin/rbash" || \
              "$shell" = "/usr/bin/rbash" || \
              "$shell" = "/usr/bin/dash" ]]; then
            failures+=("$user (UID $uid) shell actif : $shell")
        fi

    done < /etc/passwd

    if [[ "${#failures[@]}" -eq 0 ]]; then
        Print-Ok "$desc"
    else
        for failure in "${failures[@]}"; do
            Print-Fail "$desc : $failure"
        done
    fi
}

function Get-UniqueServiceAccounts() {
    local desc="$1"
    local failures=()

    # Récupère les comptes système (UID 1-999) utilisés par des processus actifs
    declare -A user_processes

    while IFS= read -r line; do
        local user proc
        user=$(echo "$line" | awk '{print $1}')
        proc=$(echo "$line" | awk '{print $11}' | xargs basename 2>/dev/null)

        [[ -z "$user" || -z "$proc" ]] && continue
        [[ "$proc" == "-" || "$proc" == ps ]] && continue

        # Récupère l'UID du compte
        local uid
        uid=$(id -u "$user" 2>/dev/null)
        [[ -z "$uid" ]] && continue
        [[ "$uid" -eq 0 || "$uid" -ge 1000 || "$uid" -eq 65534 ]] && continue

        # Accumule les processus distincts par utilisateur
        if [[ -n "${user_processes[$user]}" ]]; then
            if [[ "${user_processes[$user]}" != *"$proc"* ]]; then
                user_processes[$user]+=" $proc"
            fi
        else
            user_processes[$user]="$proc"
        fi

    done < <(ps aux --no-headers 2>/dev/null)

    # Comptes génériques connus à risque
    local generic_accounts=("nobody" "www-data" "daemon" "bin" "sys")

    for user in "${!user_processes[@]}"; do
        local procs="${user_processes[$user]}"
        local proc_count
        proc_count=$(echo "$procs" | wc -w)

        # Signale si un compte générique est utilisé par des processus actifs
        if [[ " ${generic_accounts[*]} " == *" $user "* ]]; then
            failures+=("$user : compte générique utilisé par des processus ($procs)")
            continue
        fi

        # Signale si un compte fait tourner plusieurs services distincts
        if [[ "$proc_count" -gt 2 ]]; then
            failures+=("$user : compte partagé entre plusieurs processus ($procs)")
        fi
    done

    if [[ "${#failures[@]}" -eq 0 ]]; then
        Print-Ok "$desc"
    else
        for failure in "${failures[@]}"; do
            Print-Fail "$desc : $failure"
        done
    fi
}

function Get-SudoConfiguration () {
    local option="$1"
    local expected="$2"
    local desc="$3"

    if sudo grep -qE "(^| )${option} ${expected}( |$)" /etc/sudoers; then
        Print-Ok "$desc"
    else
        Print-Fail "$desc (missing or incorrect)"
    fi
}

function Get-Permission() {
    local path="$1"
    local perms="$2"
    local owner="$3"
    local desc="$4"

    local files=( $path )

    if [[ "${#files[@]}" -eq 1 && "${files[0]}" == "$path" && "$path" == *"*"* ]]; then
        Print-Warn "$desc : no file found for $path"
        return 1
    fi

    for file in "${files[@]}"; do
        if [[ ! -e "$file" ]]; then
            Print-Warn "$desc : $file (no file)"
            continue
        fi

        local current_perms
        current_perms=$(sudo stat -c "%a" "$file" 2>/dev/null)

        if [[ -z "$current_perms" ]]; then
            Print-Fail "$desc : $file (cannot read permissions)"
            continue
        elif [[ "$current_perms" != "$perms" ]]; then
            Print-Fail "$desc : $file (has $current_perms, expected $perms)"
        else
            Print-Ok "$desc : $file"
        fi

        if [[ -n "$owner" ]]; then
            local exp_user exp_group
            IFS=: read -r exp_user exp_group <<< "$owner"

            local current_user current_group
            current_user=$(sudo stat -c "%U" "$file" 2>/dev/null)
            current_group=$(sudo stat -c "%G" "$file" 2>/dev/null)

            if [[ -n "$exp_user" && "$current_user" != "$exp_user" ]]; then
                Print-Fail "$desc : $file (owner $current_user, expected $exp_user)"
            fi
            if [[ -n "$exp_group" && "$current_group" != "$exp_group" ]]; then
                Print-Fail "$desc : $file (group $current_group, expected $exp_group)"
            fi
        fi

    done
}

function Get-PermissionOnFS() {
    local type="$1"
    local args="$2"
    local desc="$3"

    local result
    result=$(eval sudo find / -type "${type}" ${args} -ls 2>/dev/null)

    if [[ -z "$result" ]]; then
        Print-Ok "$desc"
    else
        Print-Fail "$desc (missing or incorrect)"
    fi
}

function Get-LineInFile() {
    local option="$1"
    local file="$2"
    local desc="$3"

    if grep -qF "$option" "$file" 2>/dev/null; then
        Print-Ok "$desc"
    else
        Print-Fail "$desc : '$option' missing in the $file file"
    fi
}

function Get-ActiveService() {
    local service="$1"
    local type="$2"
    local desc="$3"

    local result
    result=$(eval sudo systemctl list-units --type "${type}" | grep "${service}")

    if [[ -n "$result" ]]; then
        Print-Ok "$desc"
    else
        Print-Fail "$desc (missing or incorrect)"
    fi
}

function Get-DisableService() {
    local service="$1"
    local type="$2"
    local desc="$3"

    local result
    result=$(eval sudo systemctl list-units --type "${type}" | grep "${service}")

    if [[ -z "$result" ]]; then
        Print-Ok "$desc"
    else
        Print-Fail "$desc (missing or incorrect)"
    fi
}

function Get-ParamInFile() {
    local option="$1"
    local expected="$2"
    local path="$3"
    local desc="$4"

    if sudo grep -qE "(^| )${option}=${expected}( |$)" $path; then
        Print-Ok "$desc"
    else
        Print-Fail "$desc (missing or incorrect)"
    fi
}

function Get-LocalAddress() {
    local desc="$1"

    local result
    result=$(eval sudo ss -tupln | awk 'NR>1 {print $5}' | grep "0.0.0.0" 2>/dev/null)

    if [[ -z "$result" ]]; then
        Print-Ok "$desc"
    else
        Print-Fail "$desc (missing or incorrect)"
    fi
}


echo -e "\n===================================="
echo -e "   🔍 LINUX HARDENING AUDIT"
echo -e "===================================="

Get-UEFI "R3 - Activating the UEFI secure boot"

Get-GrubPassword "R5 - Configuring a password on the bootloader"

Get-GrubOption "iommu" "force" "R7 - Activating the IOMMU"
Get-GrubOption "l1tf" "full,force" "R8 - Configuring the memory options (l1tf)"
Get-GrubOption "page_poison" "on" "R8 - Configuring the memory options (page_poison)"
Get-GrubOption "pti" "on" "R8 - Configuring the memory options (pti)"
Get-GrubOption "slab_nomerge" "yes" "R8 - Configuring the memory options (slab_nomerge)"
Get-GrubOption "slub_debug" "FZP" "R8 - Configuring the memory options (slub_debug)"
Get-GrubOption "spec_store_bypass_disable" "seccomp" "R8 - Configuring the memory options (spec_store_bypass_disable)"
Get-GrubOption "spectre_v2" "on" "R8 - Configuring the memory options (spectre_v2)"
Get-GrubOption "mds" "full,nosmt" "R8 - Configuring the memory options (mds)"
Get-GrubOption "mce" "0" "R8 - Configuring the memory options (mce)"
Get-GrubOption "page_alloc.shuffle" "1" "R8 - Configuring the memory options (page_alloc.shuffle)"
Get-GrubOption "rng_core.default_quality" "500" "R8 - Configuring the memory options (rng_core.default_quality)"
Get-SysctlOption "1" "kernel/dmesg_restrict" "R9 - Configuring the kernel options (dmesg_restrict)"
Get-SysctlOption "2" "kernel/kptr_restrict" "R9 - Configuring the kernel options (kptr_restrict)"
# Get-SysctlOption "???" "kernel/pid_max" "R9 - Configuring the kernel options (pid_max)"
Get-SysctlOption "1" "kernel/perf_cpu_time_max_percent" "R9 - Configuring the kernel options (perf_cpu_time_max_percent)"
Get-SysctlOption "1" "kernel/perf_event_max_sample_rate" "R9 - Configuring the kernel options (perf_event_max_sample_rate)"
Get-SysctlOption "2" "kernel/perf_event_paranoid" "R9 - Configuring the kernel options (perf_event_paranoid)"
Get-SysctlOption "2" "kernel/randomize_va_space" "R9 - Configuring the kernel options (randomize_va_space)"
Get-SysctlOption "0" "kernel/sysrq" "R9 - Configuring the kernel options (sysrq)"
Get-SysctlOption "1" "kernel/unprivileged_bpf_disabled" "R9 - Configuring the kernel options (unprivileged_bpf_disabled)"
Get-SysctlOption "1" "kernel/panic_on_oops" "R9 - Configuring the kernel options (panic_on_oops)"
Get-SysctlOption "1" "kernel/modules_disabled" "R10 - Disabling kernel modules loading (modules_disabled)"
Get-SysctlOption "1" "kernel/yama/ptrace_scope" "R11 - Configuration option of the Yama LSM (ptrace_scope)"
Get-GrubOption "security" "yama" "R11 - Configuration option of the Yama LSM"
Get-SysctlOption "2" "net/core/bpf_jit_harden" "R12 - IPv4 configuration options (bpf_jit_harden)"
Get-SysctlOption "0" "net/ipv4/ip_forward" "R12 - IPv4 configuration options (ip_forward)"
Get-SysctlOption "0" "net/ipv4/conf/all/accept_local" "R12 - IPv4 configuration options (accept_local)"
Get-SysctlOption "0" "net/ipv4/conf/all/accept_redirects" "R12 - IPv4 configuration options (accept_redirects)"
Get-SysctlOption "0" "net/ipv4/conf/default/accept_redirects" "R12 - IPv4 configuration options (accept_redirects)"
Get-SysctlOption "0" "net/ipv4/conf/all/secure_redirects" "R12 - IPv4 configuration options (secure_redirects)"
Get-SysctlOption "0" "net/ipv4/conf/default/secure_redirects" "R12 - IPv4 configuration options (secure_redirects)"
Get-SysctlOption "0" "net/ipv4/conf/all/shared_media" "R12 - IPv4 configuration options (shared_media)"
Get-SysctlOption "0" "net/ipv4/conf/default/shared_media" "R12 - IPv4 configuration options (shared_media)"
Get-SysctlOption "0" "net/ipv4/conf/all/accept_source_route" "R12 - IPv4 configuration options (accept_source_route)"
Get-SysctlOption "0" "net/ipv4/conf/default/accept_source_route" "R12 - IPv4 configuration options (accept_source_route)"
Get-SysctlOption "1" "net/ipv4/conf/all/arp_filter" "R12 - IPv4 configuration options (arp_filter)"
Get-SysctlOption "2" "net/ipv4/conf/all/arp_ignore" "R12 - IPv4 configuration options (arp_ignore)"
Get-SysctlOption "0" "net/ipv4/conf/all/route_localnet" "R12 - IPv4 configuration options (route_localnet)"
Get-SysctlOption "1" "net/ipv4/conf/all/drop_gratuitous_arp" "R12 - IPv4 configuration options (drop_gratuitous_arp)"
Get-SysctlOption "1" "net/ipv4/conf/default/rp_filter" "R12 - IPv4 configuration options (rp_filter)"
Get-SysctlOption "1" "net/ipv4/conf/all/rp_filter" "R12 - IPv4 configuration options (rp_filter)"
Get-SysctlOption "0" "net/ipv4/conf/default/send_redirects" "R12 - IPv4 configuration options (send_redirects)"
Get-SysctlOption "0" "net/ipv4/conf/all/send_redirects" "R12 - IPv4 configuration options (send_redirects)"
Get-SysctlOption "1" "net/ipv4/icmp_ignore_bogus_error_responses" "R12 - IPv4 configuration options (icmp_ignore_bogus_error_responses)"
Get-SysctlOption "32768 65535" "net/ipv4/ip_local_port_range" "R12 - IPv4 configuration options (ip_local_port_range)"
Get-SysctlOption "1" "net/ipv4/tcp_rfc1337" "R12 - IPv4 configuration options (tcp_rfc1337)"
Get-SysctlOption "1" "net/ipv4/tcp_syncookies" "R12 - IPv4 configuration options (tcp_syncookies)"
Get-SysctlOption "1" "net/ipv6/conf/all/disable_ipv6" "R13 - Disabling IPv6 (disable_ipv6)"
Get-SysctlOption "1" "net/ipv6/conf/default/disable_ipv6" "R13 - Disabling IPv6 (disable_ipv6)"
Get-GrubOption "ipv6.disable" "1" "R13 - Disabling IPv6"
Get-SysctlOption "0" "fs/suid_dumpable" "R14 - File system configuration options (suid_dumpable)"
Get-SysctlOption "2" "fs/protected_fifos" "R14 - File system configuration options (protected_fifos)"
Get-SysctlOption "2" "fs/protected_regular" "R14 - File system configuration options (protected_regular)"
Get-SysctlOption "1" "fs/protected_symlinks" "R14 - File system configuration options (protected_symlinks)"
Get-SysctlOption "1" "fs/protected_hardlinks" "R14 - File system configuration options (protected_hardlinks)"

Get-UnusedAccounts "180" "R30 - Removing the unused user accounts"
# Get-DefaultAccount "500" "R30 - Removing the unused user accounts"
# Get-DefaultAccount "1000" "R30 - Removing the unused user accounts"

Get-AdminAccountability "R33 - Ensuring the imputability of administration actions"
Get-ServiceAccounts "R34 - Disabling the service accounts"
Get-UniqueServiceAccounts "R35 - Uniqueness and exclusivity of service accounts"

Get-SudoConfiguration "Defaults" "noexec,requiretty ,use_pty ,umask=0027" "R39 - Sudo configuration guidelines"
Get-SudoConfiguration "Defaults" "ignore_dot ,env_reset" "R39 - Sudo configuration guidelines"

Get-Permission "/etc/passwd" "644" "root:root" "R50 - Limiting the rights to access sensitive files and directories (/etc/passwd)"
Get-Permission "/etc/shadow" "640" "root:shadow" "R50 - Limiting the rights to access sensitive files and directories (/etc/shadow)"
Get-Permission "/etc/group" "644" "root:root" "R50 - Limiting the rights to access sensitive files and directories (/etc/group)"
Get-Permission "/etc/gshadow" "640" "root:shadow" "R50 - Limiting the rights to access sensitive files and directories (/etc/group)"
Get-Permission "/etc/sudoers" "440" "root:root" "R50 - Limiting the rights to access sensitive files and directories (/etc/sudoers)"
Get-Permission "/etc/ssh/sshd_config" "600" "root:root" "R50 - Limiting the rights to access sensitive files and directories (/etc/ssh/sshd_config)"
Get-Permission "/var/log/journal" "2755" "root:systemd-journal" "R50 - Limiting the rights to access sensitive files and directories (/var/log/journal)"
Get-Permission "/var/log/private" "700" "root:root" "R50 - Limiting the rights to access sensitive files and directories (/var/log/private)"
Get-Permission "/var/log/wtmp" "664" "root:utmp" "R50 - Limiting the rights to access sensitive files and directories (/var/log/wtmp)"
Get-Permission "/var/log/btmp" "660" "root:utmp" "R50 - Limiting the rights to access sensitive files and directories (/var/log/btmp)"
Get-Permission "/boot/grub/grub.cfg" "600" "root:root" "R50 - Limiting the rights to access sensitive files and directories (/boot/grub/grub.cfg)"

Get-PermissionOnFS "f" "\( -nouser -o -nogroup \)" "R53 - Avoiding files or directories without a known user or group"
Get-PermissionOnFS "d" "\( -perm -0002 -a \! -perm -1000 \)" "R54 - Setting the sticky bit on the writable directories"
Get-PermissionOnFS "d" "-perm -0002 -a \! -uid 0" "R54 - Setting the sticky bit on the writable directories"
Get-LineInFile "pam_tmpdir" "/etc/pam.d/common-session" "R55 - Dedicating temporary directories to users"
Get-PermissionOnFS "f" "-perm -0002" "R55 - Dedicating temporary directories to users"
Get-PermissionOnFS "f" "-perm /6000" "R56 - Avoiding using executables with setuid and setgid rights"
#R57
#R58
#R59
#R60
#R61
Get-ActiveService "apt-daily" "timer" "R61 - Updating regularly the system"
Get-ActiveService "pt-daily-upgrade" "service" "R61 - Updating regularly the system"
Get-DisableService "portmap" "service" "R62 - Disabling the non-necessary services"
Get-DisableService "rpc.statd" "service" "R62 - Disabling the non-necessary services"
Get-DisableService "rpcbind" "service" "R62 - Disabling the non-necessary services"
Get-DisableService "dbus" "service" "R62 - Disabling the non-necessary services"
Get-DisableService "hald" "service" "R62 - Disabling the non-necessary services"
Get-DisableService "ConsoleKit" "service" "R62 - Disabling the non-necessary services"
Get-DisableService "cups" "service" "R62 - Disabling the non-necessary services"
Get-DisableService "PolicyKit" "service" "R62 - Disabling the non-necessary services"
Get-DisableService "avahi" "service" "R62 - Disabling the non-necessary services"
#Get-DisableService "x" "service" "R62 - Disabling the non-necessary services"
Get-PermissionOnFS "f" "-perm /111 -exec getcap {} \;" "R63 - Disabling non-essential features of services"

Get-ParamInFile "rounds" "11" "/etc/pam.d/common-password" "R68 - Protecting the stored passwords"

Get-LocalAddress "R80 - Minimizing the attack surface of network services"

echo -e "\n===================================="
echo -e "           📊 RESULT SUMMARY"
echo -e "===================================="
echo -e "${GREEN}OK : $OK_COUNT${NC}"
echo -e "${YELLOW}WARN  : $WARN_COUNT${NC}"
echo -e "${RED}FAIL : $FAIL_COUNT${NC}"
echo ""

if [[ "$FAIL_COUNT" -eq 0 ]]; then
    echo -e "${GREEN}✅ Server is compliant with hardened Linux configuration.${NC}"
else
    echo -e "${RED}❌ Server is NOT compliant — review FAILED checks.${NC}"
fi