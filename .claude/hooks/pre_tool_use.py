#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.8"
# ///

import json
import re
import sys


def is_dangerous_rm_command(command):
    """Detect destructive rm -rf style commands."""
    normalized = ' '.join(command.lower().split())

    patterns = [
        r'\brm\s+.*-[a-z]*r[a-z]*f',
        r'\brm\s+.*-[a-z]*f[a-z]*r',
        r'\brm\s+--recursive\s+--force',
        r'\brm\s+--force\s+--recursive',
        r'\brm\s+-r\s+.*-f',
        r'\brm\s+-f\s+.*-r',
    ]
    for pattern in patterns:
        if re.search(pattern, normalized):
            return True

    dangerous_paths = [
        r'/',
        r'/\*',
        r'~',
        r'~/',
        r'\$HOME',
        r'\.\.',
        r'\*',
        r'\.',
        r'\.\s*$',
    ]
    # second pass: recursive rm aimed at root/home/wildcards — wide net to catch glob+typo cases
    if re.search(r'\brm\s+.*-[a-z]*r', normalized):
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
ALLOWED_SUFFIX_RE = re.compile(r'\.(sample|example)$')  # .env.sample / .env.example are templates, safe
TOKEN_RE = re.compile(r'[^\s;|&<>()`"\']+')  # crude bash tokenizer — splits on shell metachars, not quoting-aware


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
    if tool_name in ('Read', 'Edit', 'MultiEdit', 'Write'):
        return _is_sensitive_path(tool_input.get('file_path', ''))
    if tool_name == 'Bash':
        return _bash_touches_sensitive(tool_input.get('command', ''))
    return False


def main():
    try:
        input_data = json.load(sys.stdin)
        tool_name = input_data.get('tool_name', '')
        tool_input = input_data.get('tool_input', {})

        if is_sensitive_file_access(tool_name, tool_input):
            print("BLOCKED: Access to sensitive config files (.env, *.tfvars) is prohibited", file=sys.stderr)
            print("Use .sample or .example templates instead", file=sys.stderr)
            sys.exit(2)  # exit 2 = Claude Code blocks the tool call and surfaces stderr to the model

        if tool_name == 'Bash':
            command = tool_input.get('command', '')
            if is_dangerous_rm_command(command):
                print("BLOCKED: Dangerous rm command detected and prevented", file=sys.stderr)
                sys.exit(2)  # exit 2 = Claude Code blocks the tool call and surfaces stderr to the model

        sys.exit(0)

    except json.JSONDecodeError:
        sys.exit(0)
    except Exception:
        sys.exit(0)


if __name__ == '__main__':
    main()
