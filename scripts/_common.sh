#!/usr/bin/env bash
#
# Common script configurations and utilities
# This should only be sourced, not executed directly
#
# http://github.com/z017/shell-script-skeleton
#
# Copyright (c) 2015 - Jeremías Longo <jeremiaslongo@gmail.com>

# Bash strict mode
set -Eeuo pipefail

readonly SHELL_SCRIPT_SKELETON_VERSION=0.1.0
readonly SHELL_SCRIPT_SKELETON_URL=http://github.com/z017/shell-script-skeleton

# -----------------------------------------------------------------------------
# Logs
# -----------------------------------------------------------------------------
declare -ir LOG_INCLUDE_TIME=${LOG_INCLUDE_TIME-1}
readonly LOG_TIME_FMT=${LOG_TIME_FMT-"%Y/%m/%d %H:%M:%S"}

declare -ir LOG_INCLUDE_SEVERITY=${LOG_INCLUDE_SEVERITY-1}
readonly SEVERITY_RANGES=(-8 -4 0 4 8 12)
readonly SEVERITY_RANGES_NAMES=(trace debug info warn error fatal)
readonly SEVERITY_RANGES_SHORTNAMES=(TRC DBG INF WRN ERR FTL)
readonly SEVERITY_RANGES_COLORS=(62 63 86 192 204 134)

declare -i LOG_LEVEL=${LOG_LEVEL-0}

# Set log level and make it readonly
# Usage: log_level level_number|level_name
function log_level() {
  local level=${1-$LOG_LEVEL}
  if [[ "$level" =~ ^[-]?[0-9]+$ ]]; then
    # level is a number
    LOG_LEVEL=$level
  else
    # level is a range name
    level=$(echo $level | tr "A-Z" "a-z")
    local found=0
    for i in "${!SEVERITY_RANGES_NAMES[@]}"; do
      if [[ "${SEVERITY_RANGES_NAMES[$i]}" == "$level" ]]; then
        level="${SEVERITY_RANGES[$i]}"
        found=1
        break
      fi
    done
    [[ "$found" == 0 ]] && fatal "invalid log level '$level', must be one of: ${SEVERITY_RANGES_NAMES[@]}"
    LOG_LEVEL=$level
  fi
  readonly LOG_LEVEL
}

# Log trace messages to stderr
function trace() {
  log -8 "$*"
}

# Log debug messages to stderr
function debug() {
  log -4 "$*"
}

# Log info messages to stderr
function info() {
  log 0 "$*"
}

# Log warning messages to stderr
function warn() {
  log 4 "$*"
}

# Log error messages to stderr
function error() {
  log 8 "$*"
}

# Log fatal messages to stderr and exit with status 1
function fatal() {
  log 12 "$*"
  exit 1
}

# Log messages to stderr with custom severity level
# Params: severity_level messages...
function log() {
  local severity_level=$1
  shift
  # if severity level is lower than log level, messages are discarded
  [[ $severity_level -lt $LOG_LEVEL ]] && return

  if [[ $LOG_INCLUDE_TIME -ne 0 ]]; then
    # print time with defined format
    local time=$(date "+$LOG_TIME_FMT")
    printf "\033[2;39m%s\033[0;00m " $time >&2
  fi

  if [[ $LOG_INCLUDE_SEVERITY -ne 0 ]]; then
    # print severity level
    local range=${SEVERITY_RANGES[0]}
    local range_index=0
    if [[ $severity_level -gt $range ]]; then
      for current_range in "${SEVERITY_RANGES[@]:1}"; do
        [[ $severity_level -lt $current_range ]] && break
        range=$current_range
        range_index=$((range_index + 1))
      done
    fi
    local severity_name="${SEVERITY_RANGES_SHORTNAMES[$range_index]}"
    local severity_color="${SEVERITY_RANGES_COLORS[$range_index]}"
    printf "\033[1;38;5;%dm%s\033[0;00m " $severity_color $severity_name >&2
  fi

  # print log
  printf -- "$*\n" >&2
}

# log_key key value
# Print to stdout a formatted key value for logs only if value is not an empty
# string.
# Example: info "log in successful$(log_key user $user)"
function log_key() {
  [[ $# -lt 2 || -z $2 ]] && return
  printf " \033[2;39m%s=\033[0;00m%s" $1 $2
}

# -----------------------------------------------------------------------------
# Ensure script is sourced
# -----------------------------------------------------------------------------
[[ -n "$BASH_VERSION" ]] || fatal "This file must be sourced from bash."
[[ "$(caller 2>/dev/null | awk '{print $1}')" != "0" ]] || fatal "This file must be sourced, not executed."

# -----------------------------------------------------------------------------
# Utility functions
# -----------------------------------------------------------------------------

# Check if function exists
function fn_exists() {
  declare -F "$1" > /dev/null
}

# Ensure script is running as sudo
# Usage: ensureSudo "$@"
function ensureSudo() {
  if [[ $(id -u) -ne 0 ]]; then
    info "script require root privileges, trying sudo"
    exec sudo --preserve-env $0 $@
  fi
}

# Shows an error if required tools are not installed.
function required {
  local e=0
  for tool in "$@"; do
    type $tool >/dev/null 2>&1 || {
      e=1 && error "$tool is required"
    }
  done
  [[ $e < 1 ]] || fatal "please install missing tools required for running this script and try again"
}

# Parse template file variables in the format "{{ VAR }}" with the "VAR" value.
# parse_template <input file template> <output file> <string of variables>
function parse_template {
  local e=0
  [[ ! -f "$1" ]] && error "$1 is not a valid file." && e=1
  [[ $2 != ${2%/*} ]] && mkdir -p ${2%/*}
  [[ -z $3 ]] && error "$3, must be an string of variables to replace" && e=1
  [[ $e > 0 ]] && fatal "usage: parse_template <input file template> <output file> <string of variables>"
  # parse file
  local args
  for v in $3; do
    args="${args}s~{{ $v }}~${!v}~g;"
  done
  sed "$args" < $1 > $2
}

# Parse all template files ".tpl" in the input_dir and saved them to output_dir
# parse_templates <input_dir> <output_dir> <string of variables>
function parse_templates {
  local e=0
  [[ ! -d $1 ]] && error "$1 is not a valid directory." && e=1
  [[ -z $3 ]] && error "$3, must be an string of variables to replace" && e=1
  [[ $e > 0 ]] && fatal "usage: parse_templates <input_dir> <output_dir> <string of variables>"
  # parse each file
  for file in "$1"/*.tpl*; do
    local filename=${file##*/}
    local outfile=${filename%.tpl*}${filename##*.tpl}
    parse_template $file $2/$outfile "$3"
  done
}

# Parse the arguments and executes the following functions:
# - on_option with the short or long option found, OPTARG contains the option
#   argument if defined. The valid options must be declared in LONG_OPTS and
#   SHORT_OPTS with a : (colon) after the proper option to expect an
#   argument.
# - before_execute with the arguments, before calling execute_command. It can
#   be used to set script variables modified by options to readonly.
# - execute_command with the arguments.
# If a list of valid commands are defined in COMMANDS the first argument is
# the command to be executed or '--' by default.
function parse_and_execute() {
  local only_args=1 # 1 is true, 0 is false
  local args=()
  local OPT
  while get_options $@; do
    if [[ $OPT == -- ]]; then
      # add param to accumulated arguments
      args+=($OPTARG)
      # the first argument could be a command
      only_args=0
      continue
    fi
    # verify errors
    case "$OPT" in
        ::)	fatal "Unexpected argument to option '$OPTARG'"; ;;
        :)	fatal "Missing argument to option '$OPTARG'"; ;;
        \?)	fatal "Unknown option '$OPTARG'"; ;;
    esac
    [[ "${OPTARG-}" =~ ^-[A-Za-z-]+ ]] && fatal "Missing argument to option '$OPT'"
    # call on_option if exists
    fn_exists on_option && on_option $OPT
  done
  shift $((OPTIND-1))

  # the remaining params are arguments
  args+=(${@})

  local send_command=1
  if [[ -z "${COMMANDS-}" || "${#COMMANDS[@]}" == 0 ]]; then
    # if valid commands are not defined, the first argument is not a command
    send_command=0
    only_args=1
  fi

  if [[ "$only_args" == 0 ]]; then
    # check if the first argument is a valid command
    only_args=1
    for valid_cmd in "${COMMANDS[@]}"; do
      if [[ "$valid_cmd" == "${args[0]}" ]]; then
        # the first argument is a command
        only_args=0
        break
      fi
    done

  fi

  if [[ "$only_args" == 1 && "$send_command" == 1 ]]; then
    # send '--' as the default command
    args=('--' ${args[@]})
  fi

  # call before_execute if exists
  fn_exists before_execute && before_execute "${args[@]}"

  # call execute_command if exists
  fn_exists execute_command && execute_command "${args[@]}"
}

# Internal function used by parse_arguments to parse short and long options
# from arguments.
# Support options between commands or command arguments.
# All params after '--' are considered command arguments.
function get_options() {
  if [[ $# -lt $OPTIND ]]; then
    # no more params
    return 1
  fi
  OPT="${!OPTIND}"
  if [[ $OPT == -- ]]; then
    # only arguments left
    OPTIND=$((OPTIND+1))
    return 1
  elif [[ $OPT == --?* ]]; then
    # long option
    OPT=${OPT#--}
    OPTIND=$((OPTIND+1))
    OPTARG=
    local has_arg=0
    if [[ $OPT == *=* ]]; then
      # option has an argument
      OPTARG=${OPT#*=}
      OPT=${OPT%=$OPTARG}
      has_arg=1
    fi
    # check if option is valid
    local state=0
    for valid_option in "${LONG_OPTS[@]}"; do
      [[ "$valid_option" == "$OPT" ]] && state=1 && break
      [[ "${valid_option%:}" == "$OPT" ]] && state=2 && break
    done
    if [[ $state = 0 ]]; then
      # unknown option
      OPTARG=$OPT
      OPT='?'
    elif [[ $state = 1 && $has_arg = 1 ]]; then
      # unexpected argument to option
      OPTARG=$OPT
      OPT='::'
    elif [[ $state = 2 && $has_arg = 0 ]]; then
      if [[ $# -ge $OPTIND ]]; then
        # next param is the option argument
        OPTARG="${!OPTIND}"
        OPTIND=$((OPTIND+1))
      else
        # missing argument to option
        OPTARG=$OPT
        OPT=':'
      fi
    fi
    return 0
  elif [[ $OPT == -?* ]]; then
    # short option
    getopts ":${SHORT_OPTS-}" OPT
  else
    # command or argument
    OPTARG=$OPT
    OPT='--'
    OPTIND=$((OPTIND+1))
    return 0
  fi
}

# Version command
# Prints a default version message using SCRIPT_NAME and SCRIPT_VERSION to
# stdout.
# Define the function version_message to customize.
function execute_version() {
  if fn_exists version_message; then
    version_message
  else
    printf "%s version %s\n" ${SCRIPT_NAME-0##*/} ${SCRIPT_VERSION-0.0.0}
    printf "\nGenerated by shell-script-skeleton %s <%s> %s\n" $SHELL_SCRIPT_SKELETON_VERSION $SHELL_SCRIPT_SKELETON_URL
  fi
  exit 0
}

# -----------------------------------------------------------------------------
# Traps
# -----------------------------------------------------------------------------

# Error trap
#
# Declare ERRTEXT before a possible error ocurrence to replace default error
# message, for example add the next code as first line of a function:
# local ERRTEXT="bootnode section failed"
function error_trap() {
  fatal "${ERRTEXT:-script failed}$(log_key code ${1-})$(log_key line ${2-})$(log_key fn ${3-})"
}
trap 'error_trap $? ${LINENO-} ${FUNCNAME-}' ERR

# Shutdown trap
function shutdown_trap() {
  printf "\n" >&2
  info "interruption received, shutting down"
  trap '' ERR
  # if on_shutdown function exists, execute it
  fn_exists on_shutdown && on_shutdown
}
trap shutdown_trap SIGINT SIGTERM

# Exit trap
function exit_trap() {
  # if on_exit function exists, execute it
  fn_exists on_exit && on_exit
  exit
}
trap exit_trap EXIT
