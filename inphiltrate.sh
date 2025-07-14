#!/bin/bash

# INPHILTRATE - Interactive New Public-key Handler for Injecting Legitimate Trust, 
# Remotely Automating Target Environments
# 
# This script streamlines SSH key setup for Windows servers by generating fresh keypairs
# and providing both automatic (via SSH) and manual (via RDP) installation methods.

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Color codes for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Function to validate IP address format
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        IFS='.' read -ra ADDR <<< "$ip"
        for i in "${ADDR[@]}"; do
            if [[ $i -lt 0 || $i -gt 255 ]]; then
                return 1
            fi
        done
        return 0
    fi
    return 1
}

# Function to test SSH connectivity
test_ssh_connection() {
    local user=$1
    local ip=$2
    local timeout=10
    
    print_status "Testing SSH connectivity to ${user}@${ip}..."
    
    if timeout $timeout ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o BatchMode=yes "${user}@${ip}" "echo 'SSH connection test successful'" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to install key via SSH
install_key_via_ssh() {
    local user=$1
    local ip=$2
    local keyfile=$3
    
    print_status "Attempting to install SSH key on ${user}@${ip}..."
    print_warning "You will be prompted for the Windows password for user '${user}'"
    
    # Read the public key content
    local pubkey_content
    pubkey_content=$(< "${keyfile}.pub")
    
    # Escape the key content for PowerShell
    local escaped_key="${pubkey_content//\'/\'\''}"
    
    # PowerShell command to setup SSH key
    local powershell_cmd="powershell -Command \"
New-Item -Force -ItemType Directory -Path \$env:USERPROFILE\\.ssh -ErrorAction SilentlyContinue | Out-Null;
\$keyContent = '${escaped_key}';
Add-Content -Force -Path \$env:USERPROFILE\\.ssh\\authorized_keys -Value \$keyContent;
Write-Host 'SSH key installed successfully';
\""
    
    if ssh -o StrictHostKeyChecking=accept-new "${user}@${ip}" "$powershell_cmd"; then
        print_status "SSH key successfully installed on ${user}@${ip}"
        return 0
    else
        print_error "Failed to install SSH key via SSH"
        return 1
    fi
}

# Function to display manual setup instructions
show_manual_instructions() {
    local user=$1
    local ip=$2
    local hostname=$3
    local keyfile=$4
    
    echo ""
    print_header "Manual Setup Instructions"
    echo ""
    echo "Since automatic SSH installation failed or was not chosen, follow these steps:"
    echo ""
    echo "1. Copy the public key below to your clipboard:"
    echo "   ${YELLOW}--- BEGIN PUBLIC KEY ---${NC}"
    cat "${keyfile}.pub"
    echo "   ${YELLOW}--- END PUBLIC KEY ---${NC}"
    echo ""
    echo "2. Connect to the Windows server (${hostname}) via RDP as user '${user}'"
    echo ""
    echo "3. On the Windows server, open PowerShell as ${user} and run:"
    echo "   ${BLUE}New-Item -Force -ItemType Directory -Path \$env:USERPROFILE\\.ssh${NC}"
    echo "   ${BLUE}Set-Content -Path \$env:USERPROFILE\\.ssh\\authorized_keys -Value '<paste the public key here>'${NC}"
    echo ""
    echo "   Or alternatively, create the file manually:"
    echo "   - Open Notepad"
    echo "   - Paste the public key content"
    echo "   - Save as 'C:\\Users\\${user}\\.ssh\\authorized_keys' (no file extension)"
    echo ""
    echo "4. Ensure OpenSSH Server is installed and running:"
    echo "   - Open Services (services.msc)"
    echo "   - Find 'OpenSSH SSH Server' and ensure it's running"
    echo "   - If not installed, run: Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0"
    echo ""
    echo "5. Test the connection:"
    echo "   ${BLUE}ssh -i ${keyfile} ${user}@${ip}${NC}"
    echo ""
    echo "6. Deliver the private key file '${keyfile}' to the end user securely"
    echo ""
}

# Function to cleanup on exit
cleanup() {
    if [[ -n "${keyfile:-}" && -f "$keyfile" ]]; then
        print_status "SSH key files generated:"
        echo "   Private key: ${keyfile}"
        echo "   Public key:  ${keyfile}.pub"
        echo ""
        print_warning "Keep the private key secure and deliver it to the end user"
    fi
}

# Set up cleanup trap
trap cleanup EXIT

# Main script
main() {
    print_header "INPHILTRATE - Windows SSH Key Setup"
    echo ""
    echo "This script will generate a fresh SSH keypair and help you install it"
    echo "on a Windows server for passwordless SSH access."
    echo ""
    
    # Get user input
    echo -n "Enter Windows server hostname (for reference): "
    read -r hostname
    
    echo -n "Enter Windows server IP address: "
    read -r ip
    
    # Validate IP address
    while ! validate_ip "$ip"; do
        print_error "Invalid IP address format. Please enter a valid IP (e.g., 192.168.1.100)"
        echo -n "Enter Windows server IP address: "
        read -r ip
    done
    
    echo -n "Enter Windows username to set up SSH for: "
    read -r username
    
    # Validate username (basic check)
    if [[ -z "$username" ]]; then
        print_error "Username cannot be empty"
        exit 1
    fi
    
    echo ""
    echo "Choose how to install the SSH key on the Windows server:"
    echo "1) Automatic via SSH (requires OpenSSH server running on Windows)"
    echo "2) Manual via RDP (if SSH is not available)"
    echo ""
    
    while true; do
        echo -n "Enter 1 or 2: "
        read -r method
        
        if [[ "$method" == "1" || "$method" == "2" ]]; then
            break
        else
            print_error "Please enter 1 or 2"
        fi
    done
    
    # Generate SSH keypair
    print_status "Generating fresh SSH keypair..."
    
    keyfile="${hostname}_${username}_$(date +%Y%m%d_%H%M%S)"
    
    if ! ssh-keygen -t ed25519 -N "" -f "$keyfile" -C "${username}@${hostname}" -q; then
        print_error "Failed to generate SSH keypair"
        exit 1
    fi
    
    print_status "SSH keypair generated successfully"
    echo "   Private key: ${keyfile}"
    echo "   Public key:  ${keyfile}.pub"
    echo ""
    
    # Handle installation method
    if [[ "$method" == "1" ]]; then
        print_status "Attempting automatic SSH installation..."
        
        # Test SSH connectivity first
        if test_ssh_connection "$username" "$ip"; then
            print_status "SSH connection test successful"
            
            if install_key_via_ssh "$username" "$ip" "$keyfile"; then
                echo ""
                print_status "Setup completed successfully!"
                echo "You can now SSH to ${hostname} as ${username} using:"
                echo "   ${BLUE}ssh -i ${keyfile} ${username}@${ip}${NC}"
                echo ""
                print_warning "Remember to deliver the private key file '${keyfile}' to the end user securely"
                exit 0
            else
                print_warning "Automatic SSH installation failed, falling back to manual instructions"
                show_manual_instructions "$username" "$ip" "$hostname" "$keyfile"
            fi
        else
            print_warning "SSH connection test failed. The Windows server may not have OpenSSH running."
            print_warning "Falling back to manual instructions"
            show_manual_instructions "$username" "$ip" "$hostname" "$keyfile"
        fi
    else
        show_manual_instructions "$username" "$ip" "$hostname" "$keyfile"
    fi
}

# Check prerequisites
check_prerequisites() {
    # Check if ssh-keygen is available
    if ! command -v ssh-keygen >/dev/null 2>&1; then
        print_error "ssh-keygen is not available. Please install OpenSSH client."
        exit 1
    fi
    
    # Check if ssh is available
    if ! command -v ssh >/dev/null 2>&1; then
        print_error "ssh is not available. Please install OpenSSH client."
        exit 1
    fi
    
    # Check if timeout is available (for connection testing)
    if ! command -v timeout >/dev/null 2>&1; then
        print_warning "timeout command not available. Connection testing may not work properly."
    fi
}

# Run prerequisite check and main function
check_prerequisites
main
