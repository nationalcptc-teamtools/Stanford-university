#!/usr/bin/env python3

import os
import signal
import subprocess  # nosec B404
import sys
import time
from pathlib import Path

# Import configuration
sys.path.append(str(Path(__file__).parent.parent.parent / "gcp_utils"))
from config import (
    DISPLAY_DETECTION_MAX_ATTEMPTS,
    DISPLAY_DETECTION_SLEEP_TIME,
    LOG_DIR_PERMISSIONS,
    SCREEN_RECORD_DURATION,
    SCREEN_RECORD_LOG_DIR,
    SCREEN_RECORD_PROGRESS_DIR,
)

# === Setup paths ===
OUTPUT_DIR = Path.cwd() / SCREEN_RECORD_LOG_DIR
PROGRESS_DIR = Path.cwd() / SCREEN_RECORD_PROGRESS_DIR
PROGRESS_DIR.mkdir(parents=True, exist_ok=True)
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# Set permissions
os.chmod(PROGRESS_DIR, LOG_DIR_PERMISSIONS)
os.chmod(OUTPUT_DIR, LOG_DIR_PERMISSIONS)

# Clear out any files in the directory in case restarting from crash
progress_files = list(PROGRESS_DIR.iterdir())
if not progress_files:
    print("Partially completed videos do not exist")
else:
    for file in progress_files:
        if file.is_file():
            file.rename(OUTPUT_DIR / file.name)

# Try to get the most recent X display
display = None
for _ in range(DISPLAY_DETECTION_MAX_ATTEMPTS):
    try:
        # Get the most recent X display
        xorg_result = subprocess.run(
            ["pgrep", "-a", "Xorg"], capture_output=True, text=True, check=False
        )  # nosec B603 B607
        xorg_processes = xorg_result.stdout.strip()

        if not xorg_processes:
            time.sleep(DISPLAY_DETECTION_SLEEP_TIME)
            continue

        # Extract display numbers, sort them, and get the most recent one
        import re

        display_numbers = re.findall(r":[0-9]*", xorg_processes)
        if not display_numbers:
            time.sleep(DISPLAY_DETECTION_SLEEP_TIME)
            continue

        sorted_displays = sorted(set(display_numbers))
        display = sorted_displays[-1] if sorted_displays else None

        if display:
            # Test if display is valid
            test_result = subprocess.run(
                ["xdpyinfo", "-display", display], capture_output=True, check=False
            )  # nosec B603 B607
            if test_result.returncode == 0:
                os.environ["DISPLAY"] = display
                break

        time.sleep(DISPLAY_DETECTION_SLEEP_TIME)
    except Exception:
        time.sleep(DISPLAY_DETECTION_SLEEP_TIME)
        continue

if not display:
    print("ERROR: No valid display found.")
    sys.exit(1)

# Test display again
test_result = subprocess.run(
    ["xdpyinfo", "-display", display], capture_output=True, check=False
)  # nosec B603 B607
if test_result.returncode != 0:
    print(f"ERROR: DISPLAY {display} became invalid. Exiting.")
    sys.exit(1)


# Get screen resolution
def get_screen_resolution():
    try:
        xdpyinfo_output = subprocess.run(
            ["xdpyinfo"], capture_output=True, text=True, check=False
        ).stdout  # nosec B603 B607
        for line in xdpyinfo_output.split("\n"):
            if "dimensions" in line:
                return line.split()[1]
    except Exception:
        pass
    return None


ffmpeg_pid = None


def cleanup(signum, frame):
    global ffmpeg_pid
    if ffmpeg_pid:
        try:
            os.kill(ffmpeg_pid, signal.SIGINT)
            time.sleep(2)
            os.waitpid(ffmpeg_pid, 0)
        except (OSError, ProcessLookupError):
            pass
    sys.exit(0)


signal.signal(signal.SIGTERM, cleanup)
signal.signal(signal.SIGINT, cleanup)

while True:
    resolution = get_screen_resolution()
    if not resolution:
        print("ERROR: Could not get screen resolution.")
        sys.exit(1)

    timestamp = time.strftime("%Y-%m-%d_%H-%M-%S")
    filename = OUTPUT_DIR / f"screen_recording_{timestamp}.mp4"
    progress_filename = PROGRESS_DIR / f"screen_recording_{timestamp}.mp4"

    # Start ffmpeg process
    ffmpeg_cmd = [
        "ffmpeg",
        "-video_size",
        resolution,
        "-framerate",
        "30",
        "-f",
        "x11grab",
        "-i",
        f"{display}.0",
        "-preset",
        "ultrafast",
        "-movflags",
        "+faststart",
        "-t",
        str(SCREEN_RECORD_DURATION),
        str(progress_filename),
    ]

    with open("logs/screen-record.log", "a") as log_file:
        process = subprocess.Popen(
            ffmpeg_cmd, stdout=log_file, stderr=log_file
        )  # nosec B603
        ffmpeg_pid = process.pid
        exit_code = process.wait()

    if exit_code != 0:
        with open(Path.cwd() / "logs" / "error.log", "a") as error_log:
            error_log.write(
                f"ERROR: ffmpeg exited with code {exit_code} at {timestamp}\n"
            )
        sys.exit(1)

    if progress_filename.exists():
        # Move files from progress to output directory
        for file in PROGRESS_DIR.iterdir():
            if file.is_file():
                file.rename(OUTPUT_DIR / file.name)
