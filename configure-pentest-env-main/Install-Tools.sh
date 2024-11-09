#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -e

# Variables
DJASPER_DIR="/opt/djasper"
BLOODHOUND_DIR="/opt/BloodHound"
WORDLIST_DIR="/usr/share/seclists/Discovery"
DIRECTORY_WORDLIST="$WORDLIST_DIR/Web-Content/directory-list-2.3-medium.txt"
SUBDOMAIN_WORDLIST="$WORDLIST_DIR/DNS/subdomains-top1million-110000.txt"
ZSHRC="$HOME/.zshrc"
USER_NAME="${SUDO_USER:-$(whoami)}"

# Function to update package list and install necessary packages
update_and_install_packages() {
    echo "----------------------------------------"
    echo "Updating package list and installing dependencies..."
    echo "----------------------------------------"
    sudo apt update -y
    sudo apt install -y docker-compose git gobuster feroxbuster seclists python3-pip python3-venv ldap-utils remmina rlwrap
    echo "----------------------------------------"
    echo "Package installation completed."
    echo "----------------------------------------"
}

# Function to install or update BloodHound
install_or_update_bloodhound() {
    echo "----------------------------------------"
    echo "Starting installation/update of BloodHound..."
    echo "----------------------------------------"

    if [ ! -d "$BLOODHOUND_DIR" ]; then
        echo "Cloning BloodHound repository to $BLOODHOUND_DIR..."
        sudo git clone https://github.com/SpecterOps/BloodHound.git "$BLOODHOUND_DIR"
    else
        echo "BloodHound directory exists. Pulling latest changes..."
        cd "$BLOODHOUND_DIR"
        sudo git pull
    fi

    # Navigate to the BloodHound directory
    cd "$BLOODHOUND_DIR"

    # Copy Docker Compose example files if they don't exist
    echo "Setting up Docker Compose files..."
    sudo cp -n examples/docker-compose/* ./  # Use -n to avoid overwriting existing files
    echo "Docker Compose files set up successfully."

    # Start Docker Compose in detached mode
    echo "Starting BloodHound services with Docker Compose..."
    sudo docker-compose up -d

    # Wait for services to initialize
    echo "Waiting for services to initialize..."
    sleep 15  # Adjust the sleep duration as needed

    # Retrieve logs and extract the BloodHound initial password
    echo "Retrieving BloodHound initial password from Docker Compose logs..."
    LOGS=$(sudo docker-compose logs)
    PASSWORD=$(echo "$LOGS" | grep -i "Initial Password Set To:" | awk -F'Initial Password Set To: ' '{print $2}' | tr -d '\r')

    if [ -z "$PASSWORD" ]; then
        echo "Failed to retrieve the BloodHound initial password. Please check the Docker Compose logs manually."
    else
        echo "----------------------------------------"
        echo "BloodHound has been installed/updated successfully."
        echo "BloodHound Initial Password: $PASSWORD"
        echo "----------------------------------------"
    fi

    # Navigate back to the original directory
    cd -
}

# Function to install Feroxbuster scripts
install_feroxbuster_scripts() {
    echo "----------------------------------------"
    echo "Setting up Feroxbuster scripts in $DJASPER_DIR..."
    echo "----------------------------------------"

    # Create the directory if it doesn't exist
    sudo mkdir -p "$DJASPER_DIR"

    # Function to create a script using here-doc
    create_script() {
        local script_name="$1"
        local script_description="$2"
        local script_content="$3"
        local script_path="$DJASPER_DIR/$script_name"

        if [ -f "$script_path" ]; then
            echo "$script_name already exists. Skipping creation."
        else
            echo "Creating $script_name..."
            sudo tee "$script_path" > /dev/null <<EOL
#!/bin/bash

# Script: $script_name
# Description: $script_description

# Check if at least one argument (URL or DOMAIN) is provided
if [ -z "\$1" ]; then
    echo "Usage: $script_name <URL|DOMAIN> [threads]"
    exit 1
fi

INPUT="\$1"
THREADS="\${2:-100}"  # Default to 100 threads if not specified

$script_content
EOL
            sudo chmod +x "$script_path"
            echo "$script_name created and made executable."
        fi
    }

    # Define script contents without quotes for variables
    DIR_WINDOWS_CMD='feroxbuster --url "$INPUT" \
    -r \
    -t "$THREADS" \
    -w '"$DIRECTORY_WORDLIST"' \
    -C 404,403,400,503,500,501,502 \
    -x exe,bat,msi,cmd,ps1 \
    --dont-scan "vendor,fonts,images,css,assets,docs,js,static,img,help"'

    DIR_LINUX_CMD='feroxbuster --url "$INPUT" \
    -r \
    -t "$THREADS" \
    -w '"$DIRECTORY_WORDLIST"' \
    -C 404,403,400,503,500,501,502 \
    -x txt,sh,zip,bak,py,php \
    --dont-scan "vendor,fonts,images,css,assets,docs,js,static,img,help"'

    SUBDOMAIN_CMD='feroxbuster --domain "$INPUT" \
    -r \
    -t "$THREADS" \
    -w '"$SUBDOMAIN_WORDLIST"' \
    --subdomains \
    --silent'

    # Create feroxbuster_windows.sh
    create_script "feroxbuster_windows.sh" "Runs feroxbuster with Windows-specific flags for directory enumeration." "$DIR_WINDOWS_CMD"

    # Create feroxbuster_linux.sh
    create_script "feroxbuster_linux.sh" "Runs feroxbuster with Linux-specific flags for directory enumeration." "$DIR_LINUX_CMD"

    # Create feroxbuster_subdomain.sh
    create_script "feroxbuster_subdomain.sh" "Runs feroxbuster for subdomain enumeration." "$SUBDOMAIN_CMD"

    echo "----------------------------------------"
    echo "Feroxbuster scripts set up successfully in $DJASPER_DIR."
    echo "----------------------------------------"

    # Add /opt/djasper/ to PATH in zsh if not already present
    if sudo -u "$USER_NAME" grep -q 'export PATH=.*\/opt/djasper/' "$ZSHRC"; then
        echo "/opt/djasper/ is already in your PATH."
    else
        echo "Adding /opt/djasper/ to PATH in $ZSHRC..."
        echo 'export PATH="$PATH:/opt/djasper/"' | sudo tee -a "$ZSHRC" > /dev/null
        echo "/opt/djasper/ added to PATH successfully."
        echo "Reloading zsh configuration..."
        sudo -u "$USER_NAME" bash -c "source '$ZSHRC'"
    fi
}

# Function to install Gobuster scripts
install_gobuster_scripts() {
    echo "----------------------------------------"
    echo "Setting up Gobuster scripts in $DJASPER_DIR..."
    echo "----------------------------------------"

    # Ensure Gobuster is installed
    if ! command -v gobuster &> /dev/null; then
        echo "Gobuster is not installed. Installing..."
        sudo apt install -y gobuster
    else
        echo "Gobuster is already installed."
    fi

    # Function to create a script using here-doc
    create_script() {
        local script_name="$1"
        local script_description="$2"
        local script_content="$3"
        local script_path="$DJASPER_DIR/$script_name"

        if [ -f "$script_path" ]; then
            echo "$script_name already exists. Skipping creation."
        else
            echo "Creating $script_name..."
            sudo tee "$script_path" > /dev/null <<EOL
#!/bin/bash

# Script: $script_name
# Description: $script_description

# Check if at least one argument (DOMAIN) is provided
if [ -z "\$1" ]; then
    echo "Usage: $script_name <DOMAIN> [threads]"
    exit 1
fi

DOMAIN="\$1"
THREADS="\${2:-100}"  # Default to 100 threads if not specified

$script_content
EOL
            sudo chmod +x "$script_path"
            echo "$script_name created and made executable."
        fi
    }

    # Define script contents without quotes for variables
    DNS_ENUM_CMD='gobuster dns -d "$DOMAIN" \
    -t "$THREADS" \
    -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-110000.txt \
    -o "$DJASPER_DIR/gobuster_dns_output.txt"'

    VHOST_ENUM_CMD='gobuster vhost -u http://"$DOMAIN" \
    -t "$THREADS" \
    -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-110000.txt \
    -o "$DJASPER_DIR/gobuster_vhost_output.txt"'

    # Create gobuster_dns.sh
    create_script "gobuster_dns.sh" "Runs Gobuster for DNS subdomain enumeration." "$DNS_ENUM_CMD"

    # Create gobuster_vhost.sh
    create_script "gobuster_vhost.sh" "Runs Gobuster for Virtual Host enumeration." "$VHOST_ENUM_CMD"

    echo "----------------------------------------"
    echo "Gobuster scripts set up successfully in $DJASPER_DIR."
    echo "----------------------------------------"

    # Add /opt/djasper/ to PATH in zsh if not already present (already handled in Feroxbuster section)
}

# Function to install additional tools
install_additional_tools() {
    echo "----------------------------------------"
    echo "Installing additional tools..."
    echo "----------------------------------------"

    # Unzip rockyou.txt.gz
    echo "Unzipping rockyou.txt.gz..."
    if [ -f "/usr/share/wordlists/rockyou.txt.gz" ]; then
        sudo gunzip /usr/share/wordlists/rockyou.txt.gz
        echo "rockyou.txt.gz unzipped successfully."
    else
        echo "rockyou.txt.gz not found or already unzipped."
    fi

    # Create the tools directory if it doesn't exist
    sudo mkdir -p "$DJASPER_DIR"

    # Download kerbrute into /opt/djasper
    echo "Downloading kerbrute..."
    if [ ! -f "$DJASPER_DIR/kerbrute" ]; then
        sudo wget https://github.com/ropnop/kerbrute/releases/download/v1.0.3/kerbrute_linux_amd64 -O "$DJASPER_DIR/kerbrute"
        sudo chmod +x "$DJASPER_DIR/kerbrute"
        echo "kerbrute downloaded and made executable."
    else
        echo "kerbrute already exists in $DJASPER_DIR."
    fi

    # Set up linWinPwn with Docker
    echo "Setting up linWinPwn with Docker..."
    if [ ! -d "$DJASPER_DIR/linWinPwn" ]; then
        sudo git clone https://github.com/lefayjey/linWinPwn "$DJASPER_DIR/linWinPwn"
    else
        echo "linWinPwn already exists. Pulling latest changes..."
        sudo git -C "$DJASPER_DIR/linWinPwn" pull
    fi
    # Build the Docker image
    echo "Building linWinPwn Docker image..."
    sudo docker build -t "linwinpwn:latest" "$DJASPER_DIR/linWinPwn"
    echo "linWinPwn Docker image built successfully."
    echo "To run linWinPwn Docker container, use:"
    echo "docker run --rm -it linwinpwn:latest"

    # Create /opt/djasper/binaries and download specified files
    echo "Setting up binaries folder..."
    sudo mkdir -p "$DJASPER_DIR/binaries"

    # Clone webshells
    echo "Cloning webshells..."
    if [ ! -d "$DJASPER_DIR/binaries/webshells" ]; then
        sudo git clone https://github.com/BlackArch/webshells.git "$DJASPER_DIR/binaries/webshells"
    else
        echo "webshells already exists."
    fi

    # Create linux-binary directory and download files
    echo "Setting up linux-binary tools..."
    sudo mkdir -p "$DJASPER_DIR/binaries/linux-binary"
    cd "$DJASPER_DIR/binaries/linux-binary"

    # Download chisel binaries
    if [ ! -f "chisel32" ]; then
        sudo wget https://github.com/jpillora/chisel/releases/download/v1.9.1/chisel_1.9.1_linux_386.gz
        sudo gunzip chisel_1.9.1_linux_386.gz
        sudo mv chisel_1.9.1_linux_386 chisel32
        sudo chmod +x chisel32
    else
        echo "chisel32 already exists."
    fi
    if [ ! -f "chisel64" ]; then
        sudo wget https://github.com/jpillora/chisel/releases/download/v1.9.1/chisel_1.9.1_linux_amd64.gz
        sudo gunzip chisel_1.9.1_linux_amd64.gz
        sudo mv chisel_1.9.1_linux_amd64 chisel64
        sudo chmod +x chisel64
    else
        echo "chisel64 already exists."
    fi

    # Clone LinEnum
    if [ ! -d "LinEnum" ]; then
        sudo git clone https://github.com/rebootuser/LinEnum.git
    else
        echo "LinEnum already exists."
    fi

    # Download linpeas.sh
    if [ ! -f "linpeas.sh" ]; then
        sudo wget https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh
        sudo chmod +x linpeas.sh
    else
        echo "linpeas.sh already exists."
    fi

    # Download pspy64
    if [ ! -f "pspy64" ]; then
        sudo wget https://github.com/DominicBreuker/pspy/releases/download/v1.2.1/pspy64
        sudo chmod +x pspy64
    else
        echo "pspy64 already exists."
    fi

    # Return to the main directory
    cd "$DJASPER_DIR/binaries"

    # Create windows-binary directory and download files
    echo "Setting up windows-binary tools..."
    sudo mkdir -p "$DJASPER_DIR/binaries/windows-binary"
    cd "$DJASPER_DIR/binaries/windows-binary"

    # Download chisel binaries
    if [ ! -f "chisel32.exe" ]; then
        sudo wget https://github.com/jpillora/chisel/releases/download/v1.9.1/chisel_1.9.1_windows_386.gz
        sudo gunzip chisel_1.9.1_windows_386.gz
        sudo mv chisel_1.9.1_windows_386 chisel32.exe
    else
        echo "chisel32.exe already exists."
    fi
    if [ ! -f "chisel64.exe" ]; then
        sudo wget https://github.com/jpillora/chisel/releases/download/v1.9.1/chisel_1.9.1_windows_amd64.gz
        sudo gunzip chisel_1.9.1_windows_amd64.gz
        sudo mv chisel_1.9.1_windows_amd64 chisel64.exe
    else
        echo "chisel64.exe already exists."
    fi

    # Download winPEASx64.exe
    if [ ! -f "winPEASx64.exe" ]; then
        sudo wget https://github.com/peass-ng/PEASS-ng/releases/latest/download/winPEASx64.exe
    else
        echo "winPEASx64.exe already exists."
    fi

    # Clone nc.exe
    if [ ! -d "nc.exe" ]; then
        sudo git clone https://github.com/int0x33/nc.exe.git
    else
        echo "nc.exe already exists."
    fi

    # Clone mimikatz
    if [ ! -d "mimikatz" ]; then
        sudo git clone https://github.com/ParrotSec/mimikatz.git
    else
        echo "mimikatz already exists."
    fi

    # Download Rubeus.exe
    if [ ! -f "Rubeus.exe" ]; then
        sudo wget https://github.com/r3motecontrol/Ghostpack-CompiledBinaries/raw/master/Rubeus.exe
    else
        echo "Rubeus.exe already exists."
    fi

    # Download Certify.exe
    if [ ! -f "Certify.exe" ]; then
        sudo wget https://github.com/r3motecontrol/Ghostpack-CompiledBinaries/raw/master/Certify.exe
    else
        echo "Certify.exe already exists."
    fi

    # Download SharpHound.exe
    if [ ! -f "SharpHound.exe" ]; then
        sudo wget https://github.com/BloodHoundAD/BloodHound/raw/master/Collectors/SharpHound.exe
    else
        echo "SharpHound.exe already exists."
    fi

    # Clone Powermad
    if [ ! -d "Powermad" ]; then
        sudo git clone https://github.com/Kevin-Robertson/Powermad.git
    else
        echo "Powermad already exists."
    fi

    # Download PowerView.ps1
    if [ ! -f "PowerView.ps1" ]; then
        sudo wget https://github.com/PowerShellMafia/PowerSploit/raw/master/Recon/PowerView.ps1
    else
        echo "PowerView.ps1 already exists."
    fi

    # Return to the main directory
    cd "$DJASPER_DIR"

    # Create /opt/djasper/zerologon and download tools
    echo "Setting up zerologon tools..."
    sudo mkdir -p "$DJASPER_DIR/zerologon"
    if [ ! -f "$DJASPER_DIR/zerologon/zerologon_tester.py" ]; then
        echo "Downloading zerologon_tester.py..."
        sudo wget https://github.com/SecuraBV/CVE-2020-1472/raw/master/zerologon_tester.py -O "$DJASPER_DIR/zerologon/zerologon_tester.py"
    else
        echo "zerologon_tester.py already exists."
    fi
    if [ ! -f "$DJASPER_DIR/zerologon/cve-2020-1472-exploit.py" ]; then
        echo "Downloading cve-2020-1472-exploit.py..."
        sudo wget https://github.com/dirkjanm/CVE-2020-1472/raw/master/cve-2020-1472-exploit.py -O "$DJASPER_DIR/zerologon/cve-2020-1472-exploit.py"
    else
        echo "cve-2020-1472-exploit.py already exists."
    fi
    if [ ! -f "$DJASPER_DIR/zerologon/restorepassword.py" ]; then
        echo "Downloading restorepassword.py..."
        sudo wget https://github.com/dirkjanm/CVE-2020-1472/raw/master/restorepassword.py -O "$DJASPER_DIR/zerologon/restorepassword.py"
    else
        echo "restorepassword.py already exists."
    fi
    # Create Syntax-Notes file
    if [ ! -f "$DJASPER_DIR/zerologon/Syntax-Notes" ]; then
        echo "Creating Syntax-Notes..."
        sudo tee "$DJASPER_DIR/zerologon/Syntax-Notes" > /dev/null <<EOL
for zerologon tester and exploit, it's: python3 (script) (NetBIOS name) (ip)
for password restoring it's: python3 restorepassword.py (domain-name)/(NetBIOS name)@(NetBIOS name) -target-ip (ip) -hexpass (hex hash)
EOL
    else
        echo "Syntax-Notes already exists."
    fi

    # Create a virtual environment in zerologon directory
    echo "Setting up virtual environment for zerologon tools..."
    if [ ! -d "$DJASPER_DIR/zerologon/venv" ]; then
        sudo python3 -m venv "$DJASPER_DIR/zerologon/venv"
        echo "Virtual environment created in $DJASPER_DIR/zerologon/venv"
        # Install required Python packages
        echo "Installing required Python packages in zerologon virtual environment..."
        sudo "$DJASPER_DIR/zerologon/venv/bin/pip" install impacket
    else
        echo "Virtual environment already exists."
    fi

    echo "----------------------------------------"
    echo "Additional tools installed successfully."
    echo "----------------------------------------"
}

# Function to update installed tools
update_tools() {
    echo "----------------------------------------"
    echo "Updating installed tools..."
    echo "----------------------------------------"
    update_and_install_packages

    # Update BloodHound
    if [ -d "$BLOODHOUND_DIR" ]; then
        install_or_update_bloodhound
    else
        echo "BloodHound is not installed. Skipping update."
    fi

    # Update Feroxbuster and Gobuster scripts
    if [ -d "$DJASPER_DIR" ]; then
        echo "Updating Feroxbuster and Gobuster scripts..."
        install_feroxbuster_scripts
        install_gobuster_scripts
        install_additional_tools
    else
        echo "Feroxbuster scripts are not installed. Skipping update."
    fi

    echo "----------------------------------------"
    echo "Update process completed."
    echo "----------------------------------------"
}

# Function to display the menu and get user selection
show_menu() {
    echo "----------------------------------------"
    echo "Please select an option:"
    echo "1. Update Installed Tools"
    echo "2. Install BloodHound"
    echo "3. Install Feroxbuster"
    echo "4. Install Gobuster"
    echo "5. Install Additional Tools"
    echo "A. Install All of the Above"
    echo "----------------------------------------"
    echo -n "Enter your choice (1-5 or A): "
    read -r choice
}

# Function to handle the user's selection
handle_selection() {
    case "$choice" in
        1)
            echo "Updating installed tools..."
            update_tools
            ;;
        2)
            install_or_update_bloodhound
            ;;
        3)
            install_feroxbuster_scripts
            ;;
        4)
            install_gobuster_scripts
            ;;
        5)
            install_additional_tools
            ;;
        A|a)
            echo "Installing all tools..."
            update_and_install_packages
            install_or_update_bloodhound
            install_feroxbuster_scripts
            install_gobuster_scripts
            install_additional_tools
            echo "----------------------------------------"
            echo "All tools have been installed/updated successfully."
            echo "----------------------------------------"
            ;;
        *)
            echo "----------------------------------------"
            echo "Invalid selection. Please run the script again and choose a valid option."
            echo "----------------------------------------"
            exit 1
            ;;
    esac
}

# Main script execution
main() {
    echo "========================================"
    echo "Welcome to the Tool Installation Script"
    echo "========================================"

    show_menu
    handle_selection

    echo "----------------------------------------"
    echo "Installation process completed."
    echo "----------------------------------------"
    echo "If you installed Feroxbuster, you can now use the following scripts from anywhere:"
    echo " - feroxbuster_windows.sh <URL> [threads]"
    echo " - feroxbuster_linux.sh <URL> [threads]"
    echo " - feroxbuster_subdomain.sh <DOMAIN> [threads]"
    echo "----------------------------------------"
    echo "If you installed Gobuster, you can now use the following scripts from anywhere:"
    echo " - gobuster_dns.sh <DOMAIN> [threads]"
    echo " - gobuster_vhost.sh <DOMAIN> [threads]"
    echo "----------------------------------------"
    echo "If you installed Additional Tools, they are located in $DJASPER_DIR"
    echo "----------------------------------------"
    echo "To use Feroxbuster and Gobuster scripts without specifying the full path, ensure $DJASPER_DIR is in your PATH."
    echo "----------------------------------------"
}

# Run the main function
main
