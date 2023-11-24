#!/usr/bin/env bash
#
# Generic Shell Script Skeleton.
# Copyright (c) {{ YEAR }} - {{ AUTHOR }} <{{ AUTHOR_EMAIL }}>
#
# Built with shell-script-skeleton v{{ SHELL_SCRIPT_SKELETON_VERSION }} <{{ SHELL_SCRIPT_SKELETON_URL }}>

# Import common script configurations and utilities
source "$(cd "$(dirname $(realpath "${BASH_SOURCE[0]}"))" && pwd)/_common.sh" || exit 1

readonly SCRIPT_NAME=${0##*/}
readonly SCRIPT_VERSION=0.0.1
readonly SCRIPT_DESCRIPTION="Shell script skeleton"

# Long Options. To expect an argument for an option, just place a : (colon)
# after the proper option flag.
readonly LONG_OPTS=(help version log-level: force)

# Short Options. To expect an argument for an option, just place a : (colon)
# after the proper option flag.
readonly SHORT_OPTS=hv

# Script Commands
readonly COMMANDS=(help version)

# List of required tools, example: REQUIRED_TOOLS=(git ssh)
readonly REQUIRED_TOOLS=()

# Force flag
declare FORCE=false

# -----------------------------------------------------------------------------
# Initialization
# -----------------------------------------------------------------------------
function on_init() {
  required "${REQUIRED_TOOLS-}"
}

function on_option() {
  case "$1" in
    h|help)       execute_help ;;
    v|version)    execute_version ;;
    log-level)    log_level "$OPTARG" ;;
    force)        FORCE=true ;;
    *)            fatal "Internal script error, unmatched option '$1'" ;;
  esac
}

function before_execute() {
  readonly FORCE
}

# -----------------------------------------------------------------------------
# Commands
# -----------------------------------------------------------------------------
function execute_command() {
  local cmd="$1"
  shift
  case "$cmd" in
    help)     execute_help ;;
    version)  execute_version ;;
    # default command
    *)        execute_default "$@" ;;
  esac
}

function execute_default() {
  info "default command executed"
}

function help_message() {
  cat <<END

  $SCRIPT_DESCRIPTION

Usage:
  $SCRIPT_NAME [options] [command] [args]

Available Commands:
  help                    Display detailed help.
  version                 Print version information.

Options:
  --help, -h              Alias help command.
  --version, -v           Alias version command.
  --force                 Don't ask for confirmation.
  --log-level             Set the log level severity. Lower level will be
                          ignored. Must be an integer or a level name:
                          ${SEVERITY_RANGES_NAMES[@]}.
  --                      Denotes the end of the options.  Arguments after this
                          will be handled as parameters even if they start with
                          a '-'.
END
}

# -----------------------------------------------------------------------------
# Run the script
# -----------------------------------------------------------------------------
parse_and_execute "$@"
