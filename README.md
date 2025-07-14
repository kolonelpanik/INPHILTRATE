# INPHILTRATE

**Interactive New Public-key Handler for Injecting Legitimate Trust, Remotely Automating Target Environments**

A comprehensive Bash script that streamlines SSH key setup for Windows servers by generating fresh keypairs and providing both automatic (via SSH) and manual (via RDP) installation methods.

## Features

- 🔐 **Fresh Key Generation**: Creates unique Ed25519 SSH keypairs for each user/server combination
- 🤖 **Automatic Installation**: Attempts to install keys directly via SSH using PowerShell commands
- 📋 **Manual Fallback**: Provides clear instructions for manual installation via RDP
- 🎨 **Colorized Output**: User-friendly interface with colored status messages
- ✅ **Input Validation**: Validates IP addresses and user inputs
- 🔍 **Connectivity Testing**: Tests SSH connectivity before attempting automatic installation
- 📝 **Comprehensive Logging**: Clear feedback and error messages throughout the process

## Prerequisites

- Bash shell environment
- OpenSSH client (`ssh` and `ssh-keygen` commands)
- Network connectivity to the target Windows server
- Windows server with OpenSSH Server installed (for automatic installation)

## Usage

### Quick Start

```bash
./inphiltrate.sh
```

### Interactive Prompts

The script will prompt you for:

1. **Windows Server Hostname** (for reference and key naming)
2. **Windows Server IP Address** (validated format)
3. **Windows Username** (the account that will receive the SSH key)
4. **Installation Method**:
   - Option 1: Automatic via SSH (requires OpenSSH server running)
   - Option 2: Manual via RDP (if SSH is not available)

### Example Session

```
=== INPHILTRATE - Windows SSH Key Setup ===

This script will generate a fresh SSH keypair and help you install it
on a Windows server for passwordless SSH access.

Enter Windows server hostname (for reference): WIN-SERVER-01
Enter Windows server IP address: 192.168.1.100
Enter Windows username to set up SSH for: administrator

Choose how to install the SSH key on the Windows server:
1) Automatic via SSH (requires OpenSSH server running on Windows)
2) Manual via RDP (if SSH is not available)

Enter 1 or 2: 1

[INFO] Generating fresh SSH keypair...
[INFO] SSH keypair generated successfully
   Private key: WIN-SERVER-01_administrator_20241201_105730
   Public key:  WIN-SERVER-01_administrator_20241201_105730.pub

[INFO] Attempting automatic SSH installation...
[INFO] Testing SSH connectivity to administrator@192.168.1.100...
[INFO] SSH connection test successful
[WARNING] You will be prompted for the Windows password for user 'administrator'
[INFO] SSH key successfully installed on administrator@192.168.1.100

[INFO] Setup completed successfully!
You can now SSH to WIN-SERVER-01 as administrator using:
   ssh -i WIN-SERVER-01_administrator_20241201_105730 administrator@192.168.1.100

[WARNING] Remember to deliver the private key file 'WIN-SERVER-01_administrator_20241201_105730' to the end user securely
```

## Installation Methods

### Automatic Installation (Option 1)

The script will:

1. Test SSH connectivity to the Windows server
2. Prompt for the Windows user password
3. Execute PowerShell commands to:
   - Create the `.ssh` directory in the user's profile
   - Add the public key to `authorized_keys`
4. Provide the SSH command for testing the connection

**Requirements:**
- OpenSSH Server installed and running on Windows
- Network connectivity to the Windows server
- Valid Windows user credentials

### Manual Installation (Option 2)

If automatic installation fails or is not chosen, the script provides:

1. **Public Key Display**: Shows the generated public key for copy-paste
2. **Step-by-step Instructions**: Clear manual setup steps including:
   - PowerShell commands to create directories and files
   - Alternative manual file creation via Notepad
   - OpenSSH Server installation and configuration
   - Connection testing commands

## Generated Files

The script creates two files with descriptive names:

- **Private Key**: `{hostname}_{username}_{timestamp}` (e.g., `WIN-SERVER-01_administrator_20241201_105730`)
- **Public Key**: `{hostname}_{username}_{timestamp}.pub` (e.g., `WIN-SERVER-01_administrator_20241201_105730.pub`)

## Security Considerations

- **Fresh Keys**: Each user/server combination gets a unique keypair
- **No Passphrase**: Keys are generated without passphrases for server automation
- **Secure Delivery**: Private keys should be delivered to end users through secure channels
- **File Permissions**: The script handles Windows file permissions appropriately
- **Key Rotation**: Generate new keys regularly for enhanced security

## Windows Server Setup

### Installing OpenSSH Server

On Windows Server 2019/2022 or Windows 10/11:

```powershell
# Install OpenSSH Server
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Start the SSH service
Start-Service sshd

# Set service to start automatically
Set-Service -Name sshd -StartupType 'Automatic'
```

### File Locations

- **Standard Users**: `C:\Users\{Username}\.ssh\authorized_keys`
- **Administrators**: `C:\ProgramData\ssh\administrators_authorized_keys`

## Troubleshooting

### Common Issues

1. **SSH Connection Failed**
   - Verify OpenSSH Server is installed and running
   - Check firewall settings (port 22)
   - Ensure network connectivity

2. **Authentication Failed**
   - Verify username and password are correct
   - Check if the user account is not locked

3. **Permission Denied**
   - Ensure the user has appropriate permissions
   - Check file system permissions on the `.ssh` directory

### Testing the Connection

After setup, test the connection:

```bash
ssh -i {private_key_file} {username}@{ip_address}
```

## Error Handling

The script includes comprehensive error handling:

- **Input Validation**: IP address format and username validation
- **Prerequisite Checking**: Verifies required commands are available
- **Graceful Fallback**: Falls back to manual instructions if automatic installation fails
- **Clear Error Messages**: Colorized output for different message types

## Contributing

This script is designed to be easily extensible. Key areas for enhancement:

- Support for different key types (RSA, ECDSA)
- Administrator account handling with proper ACLs
- Batch processing for multiple servers
- Integration with configuration management systems

## License

This project is open source and available under the MIT License.

## Support

For issues or questions, please check the troubleshooting section above or create an issue in the project repository. 