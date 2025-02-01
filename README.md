# nxc_bruter
nxc_bruter is a lightweight Bash utility for testing credentials across multiple network services using nxc/NetExec. Designed to streamline password spraying, brute-force authentication, and credential verification, nxc_bruter automatically loops through your specified services and passes file-based credential lists directly to nxc.

> **Note:** nxc_bruter relies on [nxc/NetExec](https://github.com/Pennyw0rth/NetExec) (or its alias netexec) being installed and available in your PATH.

## Features

- **Multi-Protocol Support:** Test credentials on services such as:
  - SMB, WINRM, LDAP, MSSQL, WMI, RDP, SSH, FTP, NFS, VNC
- **File-Based Credential Input:** Accepts files of usernames, passwords, or NTLM hashes (one per line). nxc handles the iteration internally.
- **Flexible Authentication Options:** Supports password-based, NTLM hash, and Kerberos authentication.
- **Colored & Structured Output:** Uses ANSI colors and separator lines to clearly delineate testing progress.
- **Robust Input Validation:** Checks required options and validates that only supported protocols are used.
- **Flexible Target Specification:** Specify a single IP, an IP range (CIDR), or a file containing multiple targets.

## Installation

### Prerequisites

- **nxc/NetExec:** Install [nxc/NetExec](https://github.com/Pennyw0rth/NetExec) (or netexec) and ensure it is in your PATH.  


### Clone the Repository

Clone this repository and make the script executable:
```bash
git clone https://github.com/Zyad-Elsayed/nxc_bruter.git
cd nxc_bruter
chmod +x nxc_bruter.sh
```

## Usage

Run the script with the following syntax:
```bash
./nxc_bruter.sh -i <ip/range/file> -s <protocols: all or comma separated list> -u <username> [-p <password> | -H <hash>]  [-k]
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

## How It Works

1. **Environment Check:**  
   The script verifies that either `nxc` or `netexec` is available in your PATH and selects the correct command accordingly.

2. **Option Parsing & Validation:**  
   Using Bash’s `getopts`, the script collects user inputs, converts protocols to lowercase, and validates that the provided protocols are supported.

3. **Dynamic Command Construction:**  
   For each specified protocol, nxc_bruter builds the corresponding nxc command. It appends the appropriate authentication flags based on whether you provided a password, NTLM hash, or the Kerberos flag.

4. **Execution & Output:**  
   The script prints colored separator lines and status messages to clearly indicate the progress and then executes each command.

## Contributing

Contributions are welcome! If you have ideas to enhance nxc_bruter (such as additional logging, extended protocol support, or improved error handling), please follow these steps:
1. Fork the repository.
2. Create a feature branch (e.g., `feature/your-feature`).
3. Commit your changes with clear commit messages.
4. Open a pull request describing your changes.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
