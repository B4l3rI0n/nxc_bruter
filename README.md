# nxc_bruter
nxc_bruter is a lightweight Bash utility for testing credentials across multiple network services using nxc/NetExec. Designed to streamline password spraying, brute-force authentication, and credential verification, nxc_bruter automatically loops through your specified services and passes file-based credential lists directly to nxc.

> **Note:** nxc_bruter relies on [nxc/NetExec](https://github.com/Pennyw0rth/NetExec) (or its alias netexec) being installed and available in your PATH.


## Features

- **Multi-Protocol Support:** Test credentials on services such as:
  - SMB, WINRM, LDAP, MSSQL, WMI, RDP, SSH, FTP, NFS, VNC
- **File-Based Credential Input:** Accepts files of usernames, passwords, or NTLM hashes (one per line). nxc handles the iteration internally.
- **Flexible Authentication Options:** Supports password-based, NTLM hash, and Kerberos authentication (with optional ccache file support). 
- **Domain and DNS Customization:** Specify a domain, custom DNS server, and use TCP for DNS queries. 
- **Service-Specific Options:** Pass nxc-specific options (e.g., --shares for SMB) for single-service tests.
- **Colored & Structured Output:** Uses ANSI colors and separator lines to clearly delineate testing progress.
- **Robust Input Validation:** Checks required options and validates that only supported protocols are used.
- **Flexible Target Specification:** Specify a single IP, an IP range (CIDR), or a file containing multiple targets.
- **Warning Suppression:** Suppresses Python deprecation warnings for cleaner output.

## Installation

### Prerequisites

- **nxc/NetExec:** Install [nxc/NetExec](https://github.com/Pennyw0rth/NetExec) (or netexec) and ensure it is in your PATH.  


### Clone the Repository

Clone this repository and make the script executable:
```bash
git clone https://github.com/B4l3rI0n/nxc_bruter.git
cd nxc_bruter
chmod +x nxc_bruter.sh
```
If you want to execute the tool from any where in the terminal 
```bash
sudo cp ./nxc_bruter.sh /usr/local/bin/nxc_bruter
```

## Usage

Run the script with the following syntax:
```bash
./nxc_bruter.sh -i <ip/range/file> -s <protocols: all or comma-separated list> -u <username> [-p <password> | -H <hash> | -k [--use-kcache]] [-d <domain>] [--dns-server <ip>] [--dns-tcp] [-- <nxc_service_options>]
```

### Options

- **`-i <ip/range/file>`**  
  Specify a single IP, an IP range (in CIDR notation), or a file containing multiple targets.
  
- **`-s <protocols>`**  
  Specify the protocols to test. Use `all` to test every available protocol or a comma-separated list (e.g., `smb,winrm,ssh`).

- **`-u <username>`**  
  Provide the username to test. This can also be a file containing a list of usernames (one per line).

- **`-p <password>`**  
  Specify the password to use. You can also supply a file with multiple passwords.

- **`-H <hash>`**  
  Use an NTLM hash instead of a password.

- **`-k`**  
  Use Kerberos authentication instead of NTLM.
  
 - **`--use-kcache`**  
  Use a Kerberos ccache file for authentication (requires `-k`). No password or hash is needed when this is specified.

- **`-d <domain>`**  
  Specify the domain for authentication (optional).

- **`--dns-server <ip>`**  
  Specify a custom DNS server IP address (optional).

- **`--dns-tcp`**  
  Use TCP instead of UDP for DNS queries (optional).

- **`-- <nxc_service_options>`**  
  Pass service-specific nxc options (e.g., `--shares` for SMB, `--asreproast` for LDAP) when testing a single service.

- **`-h, --help`**  
  Display the help menu with usage information. 

### Example Commands

- **Test a single target with a single password on all protocols:**
  ```bash
  ./nxc_bruter.sh -i 192.168.1.100 -s all -u myuser -p 'MyS3cr3t!'
  ```

- **Test specific protocols (e.g., SMB, WINRM, SSH) using a username and NTLM hash:**
  ```bash
  ./nxc_bruter.sh -i 192.168.1.0/24 -s smb,winrm,ssh -u admin -H '64FBAE31CC352FC26AF97CBDEF151E03'
  ```

- **Using file-based credentials:**
  ```bash
  ./nxc_bruter.sh -i hosts.txt -s ldap,rdp -u /path/to/users.txt -p /path/to/passwords.txt
  ```
- **Test a single target with a password on all protocols with a domain:**
  ```bash
  ./nxc_bruter.sh -i 192.168.1.100 -s all -u myuser -p 'MyS3cr3t!' -d example.com
  ```

- **Test SMB with an NTLM hash, custom DNS server, and service-specific option:**
  ```bash
  ./nxc_bruter.sh -i 192.168.1.0/24 -s smb -u admin -H '64FBAE31CC352FC26AF97CBDEF151E03' --dns-server 192.168.1.10 --dns-tcp -- --shares
  ```

- **Test LDAP with a password and service-specific option:**
  ```bash
  ./nxc_bruter.sh -i hosts.txt -s ldap -u myuser -p 'MyS3cr3t!' -- --asreproast
  ```

- **Test multiple protocols with Kerberos ccache authentication:**
  ```bash
  ./nxc_bruter.sh -i 192.168.1.0/24 -s winrm,smb,ldap,ssh -u myuser -k --use-kcache -d example.com
  ```

  
  [![asciicast](https://asciinema.org/a/0uFbKISe9rEx5qAX5w3IJd7ji.svg)](https://asciinema.org/a/0uFbKISe9rEx5qAX5w3IJd7ji)

  
## How It Works

1. **Environment Check:**  
   The script verifies that either `nxc` or `netexec` is available in your PATH and selects the correct command accordingly.

2. **Option Parsing & Validation:**  
   Using Bash’s option parsing, the script collects user inputs, converts protocols to lowercase, and validates that the provided protocols are supported and that service-specific options are used only with a single service.

3. **Dynamic Command Construction:**  
  For each specified protocol, nxc_bruter builds the corresponding nxc command, appending global options (e.g., domain, DNS settings), authentication flags (password, hash, or Kerberos), and any service-specific options.
4. **Execution & Output:**  
   The script prints colored separator lines and status messages to indicate progress, executes each command with Python warning suppression (PYTHONWARNINGS=ignore), and suppresses non-critical errors for cleaner output.
