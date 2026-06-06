# # Partie. audi :
#     local days="${1:-180}"
#     local desc="$2"
#     local unused_users=()

#     # Récupère les comptes utilisateurs réels
#     while IFS=: read -r user _ uid _ _ _ shell; do
#         [[ "$uid" -lt 1000 || "$uid" -eq 65534 ]] && continue
#         [[ "$shell" =~ nologin|false ]] && continue

#         local last_activity=0

#         # Source 1 : lastlog
#         local ll_date
#         ll_date=$(lastlog -u "$user" 2>/dev/null | tail -1)
#         if echo "$ll_date" | grep -qv "Never logged"; then
#             local ll_epoch
#             ll_epoch=$(date -d "$(echo "$ll_date" | awk '{print $4,$5,$6,$7,$8}')" +%s 2>/dev/null)
#             [[ "$ll_epoch" -gt "$last_activity" ]] && last_activity=$ll_epoch
#         fi

#         # Source 2 : last (wtmp)
#         local last_date
#         last_date=$(last -w "$user" 2>/dev/null | head -1 | awk '{print $5,$6,$7,$8}')
#         if [[ -n "$last_date" && "$last_date" != "wtmp" ]]; then
#             local last_epoch
#             last_epoch=$(date -d "$last_date" +%s 2>/dev/null)
#             [[ "$last_epoch" -gt "$last_activity" ]] && last_activity=$last_epoch
#         fi

#         # Source 3 : auth.log (sudo/su/ssh)
#         local auth_date
#         auth_date=$(grep -E "(sudo|su|sshd).*\b${user}\b" /var/log/auth.log 2>/dev/null \
#             | tail -1 | awk '{print $1,$2,$3}')
#         if [[ -n "$auth_date" ]]; then
#             local auth_epoch
#             auth_epoch=$(date -d "${auth_date} $(date +%Y)" +%s 2>/dev/null)
#             [[ "$auth_epoch" -gt "$last_activity" ]] && last_activity=$auth_epoch
#         fi

#         # Comparaison
#         local threshold
#         threshold=$(date -d "$days days ago" +%s)

#         if [[ "$last_activity" -eq 0 || "$last_activity" -lt "$threshold" ]]; then
#             unused_users+=("$user")
#         fi

#     done < /etc/passwd

#     if [[ "${#unused_users[@]}" -eq 0 ]]; then
#         Print-Ok "$desc"
#     else
#         Print-Fail "$desc : ${unused_users[*]}"
#     fi

#Pour R32 :
# To check if you are in a TTY session on Debian, run the tty command in the terminal; it will return /dev/ttyX for a TTY and /dev/pts/X for a GUI terminal session.