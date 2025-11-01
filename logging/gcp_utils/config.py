#!/usr/bin/env python3

# === Logging configuration ===
# Default log directories
SCREEN_RECORD_LOG_DIR = "logs/recordings"
SCREEN_RECORD_PROGRESS_DIR = "logs/in_progress"
VERBOSE_LOG_DIR = "logs"
WINDOW_LOG_FILE = "logs/window_info.log"
COMMAND_LOG_DIR = "logs"


# === File patterns ===
SCREEN_RECORD_PATTERN = "*.mp4"
COMMAND_LOG_PATTERN = "command-logs-*.log"

# === Log tags? ===
LOG_TAG = "Uploader"

# === Timing ===
DISPLAY_DETECTION_MAX_ATTEMPTS = 15
DISPLAY_DETECTION_SLEEP_TIME = 2
WINDOW_LOG_SLEEP_TIME = 2
SCREEN_RECORD_DURATION = 60  # seconds

# === Permissions ===
LOG_DIR_PERMISSIONS = 0o777
LOG_FILE_PERMISSIONS = 0o666


# === Validation ===
def validate_config():
    """Validate that all required configuration is set."""
    required_vars = ["PROJECT", "BUCKET_LOCATION", "INSTANCE_FILTER", "ROLE", "SCOPES"]

    missing_vars = []
    for var in required_vars:
        if not globals().get(var):
            missing_vars.append(var)

    if missing_vars:
        raise ValueError(f"Missing required configuration variables: {missing_vars}")

    return True


if __name__ == "__main__":
    # Test configuration
    try:
        validate_config()
        print("Configuration validation passed!")
        print(f"Project: {PROJECT}")
        print(f"Bucket Location: {BUCKET_LOCATION}")
        print(f"Instance Filter: {INSTANCE_FILTER}")
        print(f"Role: {ROLE}")
        print(f"Scopes: {SCOPES}")
    except ValueError as e:
        print(f"Configuration validation failed: {e}")
        exit(1)
