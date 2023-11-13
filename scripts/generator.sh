#!/usr/bin/env bash
#
# Shell script skeleton generator
# http://github.com/z017/shell-script-skeleton
#
# Copyright (c) 2015 - Jeremías Longo <jeremiaslongo@gmail.com>

# Import common script configurations and utilities
source "$(cd "$(dirname $(realpath "${BASH_SOURCE[0]}"))" && pwd)/_common.sh" || exit 1

readonly SCRIPT_NAME=${0##*/}
readonly SCRIPT_VERSION=0.0.1
readonly SCRIPT_DESCRIPTION="Shell script skeleton generator"

readonly SCRIPTS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
readonly PROJECT_ROOT=$(dirname "${SCRIPTS_DIR}")

<<<<<<< HEAD
# -----------------------------------------------------------------------------
# Options
# -----------------------------------------------------------------------------
readonly LONG_OPTS=(help version log-level:)
=======
# Script version
readonly VERSION=0.1.0

# List of required tools, example: REQUIRED_TOOLS=(git ssh)
readonly REQUIRED_TOOLS=()

# Long Options. To expect an argument for an option, just place a : (colon)
# after the proper option flag.
readonly LONG_OPTS=(help version force)

# Short Options. To expect an argument for an option, just place a : (colon)
# after the proper option flag.
>>>>>>> 58802cae5cb911495d15ef4ddbfb68ad98164f32
readonly SHORT_OPTS=hv

function on_option() {
  case "$1" in
    h|help)       execute_help ;;
    v|version)    execute_version ;;
    log-level)    log_level $OPTARG ;;
    *)            fatal "Internal script error, unmatched option '$1'" ;;
  esac
}

# -----------------------------------------------------------------------------
# Commands
# -----------------------------------------------------------------------------
readonly COMMANDS=(help version generate)

function execute_command() {
  local cmd="$1"
  shift
  case "$cmd" in
    help)     execute_help ;;
    version)  execute_version ;;
    generate) execute_generate "$@" ;;
    *)        execute_help ;;
  esac
}

function execute_generate() {
  fatal "TODO generate"
}

function help_message() {
  cat <<END

  $SCRIPT_DESCRIPTION

Usage:
  $SCRIPT_NAME [options] [command] [args]

Available Commands:
  generate                Generate a shell script skeleton from templates.
  help                    Display detailed help.
  version                 Print version information.

Options:
  --help, -h              Alias help command.
  --version, -v           Alias version command.
  --log-level lvl         Set the log level severity. Lower level will be
                          ignored. Must be an integer or a level name:
                          ${SEVERITY_RANGES_NAMES[@]}
  --                      Denotes the end of the options.  Arguments after this
                          will be handled as parameters even if they start with
                          a '-'.
END
}

# -----------------------------------------------------------------------------
# Run the script
# -----------------------------------------------------------------------------
parse_and_execute "$@"
