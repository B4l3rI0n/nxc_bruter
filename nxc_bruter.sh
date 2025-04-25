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

# Help
usage() {
    echo -e "${YELLOW}Usage:${NC} $0 -i <ip/range/file> -s <protocols: all or comma-separated list> -u <username> [-p <password> | -H <hash> | -k [--use-kcache]] [-d <domain>] [--dns-server <ip>] [--dns-tcp] [-- <nxc_service_options>]"
    echo "         Use -- <nxc_options> for service-specific nxc options (e.g., --shares for smb) when a single service is specified."
    echo "Example: $0 -i 192.168.1.100 -s all -u myuser -p mypass -d example.com"
    echo "         $0 -i hosts.txt -s smb -u myuser -H '112233aabbcc' --dns-server 192.168.1.10 --dns-tcp -- --shares"
    echo "         $0 -i hosts.txt -s ldap -u myuser -p mypass -- --asreproast"
    echo "         $0 -i 192.168.1.0/24 -s winrm,smb,ldap,ssh -u myuser -k --use-kcache -d example.com"
    exit 1
}

ip=""
services=""
username=""
password=""
hash=""
kerberos="false"
use_kcache="false"
domain=""
dns_server=""
dns_tcp="false"
nxc_options=()

# Parse options
while [ $# -gt 0 ]; do
    case "$1" in
        -i)
            ip="$2"
            shift 2
            ;;
        -s)
            services=$(echo "$2" | tr '[:upper:]' '[:lower:]')
            shift 2
            ;;
        -u)
            username="$2"
            shift 2
            ;;
        -p)
            password="$2"
            shift 2
            ;;
        -H)
            hash="$2"
            shift 2
            ;;
        -k)
            kerberos="true"
            shift
            ;;
        --use-kcache)
            use_kcache="true"
            shift
            ;;
        -d)
            domain="$2"
            shift 2
            ;;
        --dns-server)
            dns_server="$2"
            shift 2
            ;;
        --dns-tcp)
            dns_tcp="true"
            shift
            ;;
        --)
            shift
            nxc_options=("$@")
            break
            ;;
        -h|--help)
            usage
            ;;
        *)
            usage
            ;;
    esac
done

# Validation
if [ -z "$ip" ] || [ -z "$services" ] || [ -z "$username" ]; then
    usage
fi

if [ "$kerberos" = "true" ] && [ -n "$hash" ]; then
    echo -e "${RED}Error:${NC} Cannot use NTLM hash with Kerberos authentication. Use a plaintext password or --use-kcache with -k."
    exit 1
fi

if [ "$use_kcache" = "true" ] && [ "$kerberos" != "true" ]; then
    echo -e "${RED}Error:${NC} --use-kcache can only be used with -k."
    exit 1
fi

if [ "$use_kcache" = "true" ] && [ -n "$password" ]; then
    echo -e "${RED}Error:${NC} --use-kcache cannot be used with a password."
    exit 1
fi

if [ -z "$password" ] && [ -z "$hash" ] && [ "$kerberos" = "false" ] && [ "$use_kcache" = "false" ]; then
    echo -e "${RED}Error:${NC} You must specify a password (-p), hash (-H), or Kerberos (-k, optionally with --use-kcache) authentication method."
    usage
fi

# Handle protocols
all_protocols=("smb" "winrm" "ldap" "mssql" "wmi" "rdp" "ssh" "ftp" "nfs" "vnc")

if [ "$services" = "all" ]; then
    selected_protocols=("${all_protocols[@]}")
else
    IFS=',' read -r -a selected_protocols <<< "$services"
    selected_protocols=("${selected_protocols[@],,}")
fi

# Validate protocols
for protocol in "${selected_protocols[@]}"; do
    if [[ ! " ${all_protocols[*]} " =~ " ${protocol} " ]]; then
        echo -e "${RED}Error:${NC} Invalid protocol '${protocol}' specified."
        exit 1
    fi
done

# Only service specific options are are valid with one service
if [ "${#selected_protocols[@]}" -gt 1 ] && [ ${#nxc_options[@]} -gt 0 ]; then
    echo -e "${RED}Error:${NC} Service-specific options (after --) are only allowed when a single service is specified."
    exit 1
fi

# Loop through each protocol to run the command
for protocol in "${selected_protocols[@]}"; do
    echo -e "${BLUE}----------------------------------------${NC}"
    echo -e "${YELLOW}Testing ${protocol} on ${ip}...${NC}"


    cmd=( "$NXC_CMD" "$protocol" "$ip" -u "$username" )


    [ -n "$domain" ] && cmd+=( -d "$domain" )
    [ -n "$dns_server" ] && cmd+=( --dns-server "$dns_server" )
    [ "$dns_tcp" = "true" ] && cmd+=( --dns-tcp )


    if [ "$kerberos" = "true" ]; then
        cmd+=( -k )
        [ "$use_kcache" = "true" ] && cmd+=( --use-kcache )
        [ -n "$password" ] && cmd+=( -p "$password" )
    elif [ -n "$hash" ]; then
        cmd+=( -H "$hash" )
    elif [ -n "$password" ]; then
        cmd+=( -p "$password" )
    fi

    # Add service specific options
    if [ ${#nxc_options[@]} -gt 0 ]; then
        cmd+=( "${nxc_options[@]}" )
    fi

    echo -e "${GREEN}Running: ${cmd[*]} 2>/dev/null${NC}"
    PYTHONWARNINGS=ignore "${cmd[@]}" 2>/dev/null

done

echo -e "${BLUE}----------------------------------------${NC}"
