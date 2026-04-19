"""Shared log-path resolution for Claude Code hooks.

All hooks write to ~/.claude-code-logs/<project-basename>/ so logs stay
out of the project tree. Project is taken from $CLAUDE_PROJECT_DIR
(set by Claude Code), falling back to cwd.
"""
import os
from pathlib import Path


def log_dir() -> Path:
    project = os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd()
    basename = os.path.basename(os.path.abspath(project)) or "unknown"
    d = Path.home() / ".claude-code-logs" / basename
    d.mkdir(parents=True, exist_ok=True)
    return d
