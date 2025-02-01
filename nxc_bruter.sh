#!/bin/bash


RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check for the tool
if ! command -v nxc &> /dev/null && ! command -v netexec &> /dev/null; then
    echo -e "${RED}Error:${NC} Neither nxc nor netexec (Netexec) found in PATH."
    exit 1
fi

# Set the command path either nxc or netexec
NXC_CMD=$(command -v nxc || command -v netexec)

# help
usage() {
    echo -e "${YELLOW}Usage:${NC} $0 -i <ip/range/file> -s <protocols: all or comma separated list> -u <username> [-p <password> | -H <hash> | -k]"
    echo "Example: $0 -i 192.168.1.100 -s all -u myuser -p mypass"
    echo "         $0 -i hosts.txt -s smb,winrm -u myuser -H '112233aabbcc'"
    echo "         $0 -i 192.168.1.0/24 -s ssh -u myuser -k"
    exit 1
}

ip=""
services=""
username=""
password=""
hash=""
kerberos="false"


while getopts "i:s:u:p:H:k" opt; do
    case $opt in
        i)
            ip="$OPTARG"
            ;;
        s)
            services=$(echo "$OPTARG" | tr '[:upper:]' '[:lower:]')
            ;;
        u)
            username="$OPTARG"
            ;;
        p)
            password="$OPTARG"
            ;;
        H)
            hash="$OPTARG"
            ;;
        k)
            kerberos="true"
            ;;
        *)
            usage
            ;;
    esac
done


if [ -z "$ip" ] || [ -z "$services" ] || [ -z "$username" ]; then
    usage
fi

if [ "$kerberos" = "true" ] && [ -n "$hash" ]; then
    echo -e "${RED}Error:${NC} Cannot use NTLM hash with Kerberos authentication. Use a plaintext password (or ticket cache) with -k."
    exit 1
fi


if [ -z "$password" ] && [ -z "$hash" ] && [ "$kerberos" = "false" ]; then
    echo -e "${RED}Error:${NC} You must specify a password (-p), hash (-H) or Kerberos (-k) authentication method."
    usage
fi


all_protocols=("smb" "winrm" "ldap" "mssql" "wmi" "rdp" "ssh" "ftp" "nfs" "vnc")


if [ "$services" = "all" ]; then
    selected_protocols=("${all_protocols[@]}")
else

    IFS=',' read -r -a selected_protocols <<< "$services"

    selected_protocols=("${selected_protocols[@],,}")
fi


for protocol in "${selected_protocols[@]}"; do
    if [[ ! " ${all_protocols[*]} " =~ " ${protocol} " ]]; then
        echo -e "${RED}Error:${NC} Invalid protocol '${protocol}' specified."
        exit 1
    fi
done

# Looping through each protocol to run the command
for protocol in "${selected_protocols[@]}"; do
    # Print a colored separator line.
    echo -e "${BLUE}----------------------------------------${NC}"
    

    echo -e "${YELLOW}Testing ${protocol} on ${ip}...${NC}"
    

    cmd=( "$NXC_CMD" "$protocol" "$ip" -u "$username" )
    

    if [ "$kerberos" = "true" ]; then
        cmd+=( -k )

        if [ -n "$password" ]; then
            cmd+=( -p "$password" )
        fi
    elif [ -n "$hash" ]; then
        cmd+=( -H "$hash" )
    elif [ -n "$password" ]; then
        cmd+=( -p "$password" )
    fi
    

    echo -e "${GREEN}Running: ${cmd[*]} 2>/dev/null${NC}"
    

    "${cmd[@]}" 2>/dev/null
done


echo -e "${BLUE}----------------------------------------${NC}"
