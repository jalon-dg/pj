# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`pj` is a zsh plugin for quickly switching between git project directories with fuzzy search.

## Architecture

Single-file zsh script (`pj.sh`) that provides:
- Project directory discovery via `find` command scanning `.git` directories
- Caching system with 5-minute TTL for performance
- Fuzzy matching for project search
- Auto-tracking of newly cloned git repositories

## Commands

```bash
source pj.sh          # Source the plugin in zsh

pj list               # List all cached git repositories
pj -p <keyword>       # Fuzzy search and jump to project
pj <project-name>     # Exact or fuzzy match project name
pj adddir <path>      # Add custom monitoring directory
pj refresh            # Force refresh cache
pj help               # Show help
```

## Key Implementation Details

- Config directory: `~/.pj-dirs` (customizable via `PJ_CONFIG_DIR`)
- Default projects dir: `~/Documents/Projects`
- Cache file: `~/.pj-dirs/cache` (timestamp + project list)
- Monitored dirs: `~/.pj-dirs/dirs`
- Wraps `git` command to auto-detect `git clone` operations