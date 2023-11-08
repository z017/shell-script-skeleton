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
function log_level() {
  LOG_LEVEL=$1
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
  log  0 "$*"
}

# Log warning messages to stderr
function warn() {
  log  4 "$*"
}

# Log error messages to stderr
function error() {
  log  8 "$*"
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
  printf "$*\n" >&2
}

# -----------------------------------------------------------------------------
# Ensure script is sourced
# -----------------------------------------------------------------------------
[[ -n "$BASH_VERSION" ]] || fatal "This file must be sourced from bash."
[[ "$(caller 2>/dev/null | awk '{print $1}')" != "0" ]] || fatal "This file must be sourced, not executed."

# -----------------------------------------------------------------------------
# Utility functions
# -----------------------------------------------------------------------------

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
