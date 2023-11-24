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

readonly COMMANDS=(help version generate)
readonly LONG_OPTS=(help version log-level: target-directory:)
readonly SHORT_OPTS=hvt:

readonly SCRIPTS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
readonly PROJECT_ROOT=$(dirname "${SCRIPTS_DIR}")

declare TARGET_DIRECTORY=gen

# -----------------------------------------------------------------------------
# Initialization
# -----------------------------------------------------------------------------
function on_init() {
  load_environment "$PROJECT_ROOT/.env"
}

function on_option() {
  case "$1" in
    h|help)             execute_help ;;
    v|version)          execute_version ;;
    log-level)          log_level "$OPTARG" ;;
    t|target-directory) TARGET_DIRECTORY="$OPTARG" ;;
    *)                  fatal "Internal script error, unmatched option '$1'" ;;
  esac
}

function before_execute() {
  readonly TARGET_DIRECTORY
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
    generate) execute_generate "$@" ;;
    *)        execute_help ;;
  esac
}

function execute_generate() {
  local tpl="skeleton.sh"

  mkdir -p "$TARGET_DIRECTORY"
  cp "$PROJECT_ROOT/scripts/_common.sh" "$TARGET_DIRECTORY"
  parse_template "$PROJECT_ROOT/templates/$tpl" "$TARGET_DIRECTORY"
  chmod +x "$TARGET_DIRECTORY/$tpl"
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
  --log-level             Set the log level severity. Lower level will be
                          ignored. Must be an integer or a level name:
                          ${SEVERITY_RANGES_NAMES[@]}.
  --target-directory, -t  Set the generator target directory. Default: gen.
  --                      Denotes the end of the options.  Arguments after this
                          will be handled as parameters even if they start with
                          a '-'.
END
}

# -----------------------------------------------------------------------------
# Run the script
# -----------------------------------------------------------------------------
parse_and_execute "$@"
