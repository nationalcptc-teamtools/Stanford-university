#!/usr/bin/env python3

import os
import shutil
import sys
import time
from pathlib import Path

# Import configuration
sys.path.append("/home/user/gcp_utils")
gcp_utils_path = (Path(__file__).parent / "../../gcp_utils").resolve()
sys.path.append(str(gcp_utils_path))
from config import COMMAND_LOG_DIR

# === Setup paths ===
SCRIPT_DIR = Path.cwd()
LOG_DIR = SCRIPT_DIR / COMMAND_LOG_DIR
LOG_DIR.mkdir(exist_ok=True)

STARTMARKER = "# === AUTO-MONITOR START - DO NOT EDIT ==="
ENDMARKER = "# === AUTO-MONITOR END - DO NOT EDIT ==="

BASHRC_CONTENT = f"""{STARTMARKER}
if [ -z "$UNDER_ASCIINEMA" ] && [ -t 1 ]; then
    export UNDER_ASCIINEMA=1

    LOG_DIR="$HOME/participant_env/verbose-log/logs"
    mkdir -p "$LOG_DIR"

    LOGF="$LOG_DIR/command-logs-$(date +%Y%m%d-%H%M%S)-$$-$USER.log"

    asciinema rec --stdin -q -c "$SHELL" "$LOGF"
    exit
fi
{ENDMARKER}"""

def log_cmd():
    """Insert command logging into current user's bashrc"""
    # Get current user's home directory
    home_dir = Path.home()
    bashrc = home_dir / ".bashrc"

    print(f"Setting up command monitoring for user: {os.getenv('USER', 'unknown')}")
    print(f"Home directory: {home_dir}")

    # Create .bashrc if it doesn't exist
    if not bashrc.exists():
        bashrc.touch()
        print(f"Created new .bashrc file: {bashrc}")

    # Check if monitoring is already installed
    if bashrc.exists():
        content = bashrc.read_text()
        if STARTMARKER in content:
            print("Command monitoring is already installed in .bashrc")
            return

        # Create backup
        backup_name = f"{bashrc}.backup.{int(time.time())}"
        try:
            shutil.copy2(bashrc, backup_name)
            print(f"Created backup: {backup_name}")
        except (PermissionError, OSError) as e:
            print(f"Warning: Could not create backup: {e}")

        # Append monitoring content
        with open(bashrc, "a") as f:
            f.write(f"\n{BASHRC_CONTENT}\n")

        print("Command monitoring added to .bashrc")
        print(f"Command logs will be saved to: {LOG_DIR}")
        print(
            "Note: You will need to start a new shell or run 'source ~/.bashrc' for changes to take effect."
        )


def cleanup():
    """Clean up logging config from current user's bashrc"""
    home_dir = Path.home()
    bashrc = home_dir / ".bashrc"

    print(f"Cleaning up command monitoring for user: {os.getenv('USER', 'unknown')}")

    if bashrc.exists():
        content = bashrc.read_text()
        if STARTMARKER in content:
            # Remove monitoring content
            lines = content.split("\n")
            new_lines = []
            skip_section = False

            for line in lines:
                if STARTMARKER in line:
                    skip_section = True
                    continue
                elif ENDMARKER in line:
                    skip_section = False
                    continue
                elif not skip_section:
                    new_lines.append(line)

            # Write back cleaned content
            with open(bashrc, "w") as f:
                f.write("\n".join(new_lines))

            print("Command monitoring removed from .bashrc")
        else:
            print("No command monitoring found in .bashrc")
    else:
        print(".bashrc file not found")


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "cleanup":
        cleanup()
        sys.exit(0)

    log_cmd()
