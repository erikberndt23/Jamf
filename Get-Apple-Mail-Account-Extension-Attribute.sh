#!/bin/zsh

results=()

while IFS= read -r db; do
    userName=$(echo "$db" | awk -F'/' '{print $3}')
    [[ "$userName" == "Shared" ]] && continue
    [[ "$userName" == "jamf" ]] && continue

    /usr/bin/sqlite3 "$db" "PRAGMA wal_checkpoint(FULL);" 2>/dev/null

    googleAccounts=$(/usr/bin/sqlite3 "$db" "SELECT DISTINCT a.ZUSERNAME FROM ZACCOUNT a INNER JOIN ZACCOUNTTYPE t ON a.ZACCOUNTTYPE = t.Z_PK WHERE t.ZIDENTIFIER = 'com.apple.account.Google' AND a.ZUSERNAME IS NOT NULL AND a.ZUSERNAME != '';" 2>/dev/null)

    if [[ -n "$googleAccounts" ]]; then
        while IFS= read -r account; do
            results+=("$userName: $account")
        done <<< "$googleAccounts"
    fi

done < <(find /Users/ -maxdepth 4 -iname "Accounts4.sqlite" 2>/dev/null)

if [[ ${#results[@]} -gt 0 ]]; then
    echo "<result>$(printf '%s\n' "${results[@]}")</result>"
else
    echo "<result>No Google Workspace Internet accounts found</result>"
fi