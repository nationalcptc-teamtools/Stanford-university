# Run and then kill 'p10k configure' to set up the time prompt
echo "Running Powerlevel10k configuration..."
zsh -c 'p10k configure' & sleep 5 && pkill -f 'p10k configure' # Hacky trick to get the prompt's timing functionality to work correctly
