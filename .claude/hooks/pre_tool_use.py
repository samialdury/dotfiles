#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.8"
# ///

import json
import sys
import re
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from utils.log_paths import log_dir as _log_dir

def is_dangerous_rm_command(command):
    """
    Comprehensive detection of dangerous rm commands.
    Matches various forms of rm -rf and similar destructive patterns.
    """
    # Normalize command by removing extra spaces and converting to lowercase
    normalized = ' '.join(command.lower().split())
    
    # Pattern 1: Standard rm -rf variations
    patterns = [
        r'\brm\s+.*-[a-z]*r[a-z]*f',  # rm -rf, rm -fr, rm -Rf, etc.
        r'\brm\s+.*-[a-z]*f[a-z]*r',  # rm -fr variations
        r'\brm\s+--recursive\s+--force',  # rm --recursive --force
        r'\brm\s+--force\s+--recursive',  # rm --force --recursive
        r'\brm\s+-r\s+.*-f',  # rm -r ... -f
        r'\brm\s+-f\s+.*-r',  # rm -f ... -r
    ]
    
    # Check for dangerous patterns
    for pattern in patterns:
        if re.search(pattern, normalized):
            return True
    
    # Pattern 2: Check for rm with recursive flag targeting dangerous paths
    dangerous_paths = [
        r'/',           # Root directory
        r'/\*',         # Root with wildcard
        r'~',           # Home directory
        r'~/',          # Home directory path
        r'\$HOME',      # Home environment variable
        r'\.\.',        # Parent directory references
        r'\*',          # Wildcards in general rm -rf context
        r'\.',          # Current directory
        r'\.\s*$',      # Current directory at end of command
    ]
    
    if re.search(r'\brm\s+.*-[a-z]*r', normalized):  # If rm has recursive flag
        for path in dangerous_paths:
            if re.search(path, normalized):
                return True
    
    return False

SENSITIVE_SUFFIX_RE = re.compile(
    r'(^|/)('
    r'\.env(\.[^/]*)?'
    r'|[^/]*\.tfvars(\.json)?'
    r'|[^/]*\.auto\.tfvars(\.json)?'
    r')$'
)
ALLOWED_SUFFIX_RE = re.compile(r'\.(sample|example)$')
TOKEN_RE = re.compile(r'[^\s;|&<>()`"\']+')


def _is_sensitive_path(path):
    if not path:
        return False
    if ALLOWED_SUFFIX_RE.search(path):
        return False
    return bool(SENSITIVE_SUFFIX_RE.search(path))


def _bash_touches_sensitive(command):
    for token in TOKEN_RE.findall(command):
        token = token.lstrip('>').lstrip('<')
        if _is_sensitive_path(token):
            return True
    return False


def is_sensitive_file_access(tool_name, tool_input):
    """
    Check if any tool is trying to access sensitive config files
    (.env variants, Terraform *.tfvars / *.auto.tfvars).
    """
    if tool_name in ('Read', 'Edit', 'MultiEdit', 'Write'):
        return _is_sensitive_path(tool_input.get('file_path', ''))
    if tool_name == 'Bash':
        return _bash_touches_sensitive(tool_input.get('command', ''))
    return False

def main():
    try:
        # Read JSON input from stdin
        input_data = json.load(sys.stdin)
        
        tool_name = input_data.get('tool_name', '')
        tool_input = input_data.get('tool_input', {})
        
        # Block access to sensitive config files (.env*, *.tfvars, *.auto.tfvars)
        if is_sensitive_file_access(tool_name, tool_input):
            print("BLOCKED: Access to sensitive config files (.env, *.tfvars) is prohibited", file=sys.stderr)
            print("Use .sample or .example templates instead", file=sys.stderr)
            sys.exit(2)  # Exit code 2 blocks tool call and shows error to Claude
        
        # Check for dangerous rm -rf commands
        if tool_name == 'Bash':
            command = tool_input.get('command', '')
            
            # Block rm -rf commands with comprehensive pattern matching
            if is_dangerous_rm_command(command):
                print("BLOCKED: Dangerous rm command detected and prevented", file=sys.stderr)
                sys.exit(2)  # Exit code 2 blocks tool call and shows error to Claude
        
        log_path = _log_dir() / 'pre_tool_use.json'
        
        # Read existing log data or initialize empty list
        if log_path.exists():
            with open(log_path, 'r') as f:
                try:
                    log_data = json.load(f)
                except (json.JSONDecodeError, ValueError):
                    log_data = []
        else:
            log_data = []
        
        # Append new data
        log_data.append(input_data)
        
        # Write back to file with formatting
        with open(log_path, 'w') as f:
            json.dump(log_data, f, indent=2)
        
        sys.exit(0)
        
    except json.JSONDecodeError:
        # Gracefully handle JSON decode errors
        sys.exit(0)
    except Exception:
        # Handle any other errors gracefully
        sys.exit(0)

if __name__ == '__main__':
    main()