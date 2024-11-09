#!/bin/bash

# Update package list and install zsh if it's not installed
if ! command -v zsh &> /dev/null
then
    echo "zsh not found, installing..."
    sudo apt-get update && sudo apt-get install zsh -y
fi

# Install Oh My Zsh if it's not installed
if [ ! -d "$HOME/.oh-my-zsh" ]
then
    echo "Oh My Zsh not found, installing..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "Oh My Zsh is already installed"
fi

# Set Zsh as the default shell if it's not already
if [ "$SHELL" != "$(which zsh)" ]
then
    echo "Changing default shell to zsh..."
    chsh -s $(which zsh)
fi

# Backup existing .zshrc file if it exists
if [ -f "$HOME/.zshrc" ]
then
    echo "Backing up existing .zshrc file..."
    mv "$HOME/.zshrc" "$HOME/.zshrc.backup_$(date +%Y%m%d_%H%M%S)"
fi

# Backup existing .p10k.zsh file if it exists
if [ -f "$HOME/.p10k.zsh" ]
then
    echo "Backing up existing .p10k.zsh file..."
    mv "$HOME/.p10k.zsh" "$HOME/.p10k.zsh.backup_$(date +%Y%m%d_%H%M%S)"
fi

# Copy the custom .zshrc and .p10k.zsh files to the home directory
echo "Copying custom .zshrc and .p10k.zsh files..."
cp .zshrc $HOME/.zshrc
cp .p10k.zsh $HOME/.p10k.zsh

# Clone the Powerlevel10k theme into the custom themes directory (if not already installed)
if [ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
    echo "Installing Powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $HOME/.oh-my-zsh/custom/themes/powerlevel10k
else
    echo "Powerlevel10k is already installed"
fi

# Clone the zsh-syntax-highlighting plugin
if [ ! -d "$HOME/zsh-syntax-highlighting" ]; then
    echo "Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $HOME/zsh-syntax-highlighting
else
    echo "zsh-syntax-highlighting is already installed"
fi

# Add zsh-syntax-highlighting to the end of .zshrc
echo "source $HOME/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> $HOME/.zshrc


# Add function to .zshrc to run the 'script' command and log output
echo "Adding terminal session logging to .zshrc..."

cat << 'EOF' >> $HOME/.zshrc

# Function to log terminal sessions without blocking
terminal_logger() {
    # Only start logging if we're in an interactive shell and not already logging
    if [[ -o interactive ]] && [[ -z "$TERMINAL_LOGGING" ]]; then
        # Set up logging directory
        local log_dir="${HOME}/logs"
        mkdir -p "$log_dir"

        # Generate timestamp and filename
        local timestamp=$(date +%Y%m%d_%H%M%S)
        local hostname=$(hostname)
        local log_file="${log_dir}/terminal_${hostname}_${timestamp}.log"

        # Set environment variable to prevent recursive logging
        export TERMINAL_LOGGING=1

        # Start logging in the background with proper terminal handling
        if [[ "$TERM" != "dumb" && -t 1 ]]; then
            # Using typescript instead of script for better terminal handling
            # -a: append mode
            # -q: quiet mode
            # -f: flush after each write
            script -aqf "$log_file"

            # Clean up when the shell exits
            trap "unset TERMINAL_LOGGING" EXIT
        else
            echo "Terminal logging requires an interactive terminal"
            return 1
        fi
    else
        # We're already logging or in a non-interactive shell
        return 0
    fi
}

# Function to start a new logged session
start_logging() {
    if [[ -z "$TERMINAL_LOGGING" ]]; then
        echo "Starting new logged session..."
        terminal_logger
    else
        echo "Already in a logged session"
    fi
}

start_logging

EOF

# Start a new Zsh shell
exec zsh
