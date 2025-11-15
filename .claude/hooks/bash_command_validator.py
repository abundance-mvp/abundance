#!/usr/bin/env python3
"""
Bash Command Validator Hook
Blocks dangerous commands from Claude Code Bash tool
"""

import sys
import re

# Dangerous command patterns
DANGEROUS_PATTERNS = [
    r"rm\s+-rf\s+/",  # rm -rf / (recursive delete root)
    r"rm\s+-rf\s+\*",  # rm -rf * (delete all files)
    r":\(\)\{\s*:\|:&\s*\};:",  # Fork bomb
    r"dd\s+if=.*of=/dev/sd",  # Overwrite disk
    r"mkfs\.",  # Format filesystem
    r"curl.*\|\s*bash",  # Pipe to bash (unsafe)
    r"wget.*\|\s*sh",  # Pipe to sh (unsafe)
]

def validate_command(command: str) -> bool:
    """
    Validate a bash command for safety.
    Returns True if safe, False if dangerous.
    """
    for pattern in DANGEROUS_PATTERNS:
        if re.search(pattern, command, re.IGNORECASE):
            print(f"❌ BLOCKED: Dangerous command pattern detected")
            print(f"   Pattern: {pattern}")
            print(f"   Command: {command}")
            return False
    return True

def main():
    if len(sys.argv) < 2:
        print("Usage: bash_command_validator.py <command>")
        sys.exit(1)

    command = " ".join(sys.argv[1:])

    if validate_command(command):
        print("✅ Command validated as safe")
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()
