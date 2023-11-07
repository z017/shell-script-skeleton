#!/usr/bin/env bash -e
#
# Common utilities for scripts
# Copyright (c) 2019 - Honza Hommer <honza@hommer.cz>

#######################################
# CONSTANTS & VARIABLES
#######################################
# Project Root Dir
readonly PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Verbose Levels
readonly VERBOSE_LEVELS=(none fatal error warning info debug)

# Level Colors
readonly LEVEL_COLORS=(39 31 31 33 32 36)

# Defaults Verbose Level - 0 none, 1 fatal, 2 error, 3 warning, 4 info, 5 debug
readonly VERBOSE_DEFAULT=5

# Current verbose level
declare -i verbose_level="$VERBOSE_DEFAULT"

# Standard streams
readonly STANDARD_STREAMS=(stdout stderr none)

# Default standard stream
readonly STANDARD_STREAM_DEFAULT=stdout

# Current standard stream
declare standard_stream="$STANDARD_STREAM_DEFAULT"

#######################################
# FUNCTIONS
#######################################

# Print out error messages to STDERR.
function err() {
  local message
  if [[ $verbose_level -ge 1 ]]; then
    message="\033[0;${LEVEL_COLORS[1]}mERROR: $@\033[0m"
    case "$standard_stream" in
      stderr) echo -e "$message" >&2 ;;
      stdout) echo -e "$message" ;;
    esac
  fi
}

# Print out messages with given verbose level to STDERR.
function ech() {
  local level=4 # Default Info
  local message
  if [[ $# -gt 1 ]]; then
    for lvl in "${!VERBOSE_LEVELS[@]}"; do
      [[ "${VERBOSE_LEVELS[$lvl]}" = "$1" ]] && level="${lvl}" && break
    done
    shift
  fi
  [[ $level = 0 || $level -gt $verbose_level ]] && return
  tag=$(echo ${VERBOSE_LEVELS[$level]} | tr "a-z" "A-Z" )
  message="\033[0;${LEVEL_COLORS[$level]}m$tag: $@\033[0m"
  case "$standard_stream" in
    stderr) echo -e "$message" >&2 ;;
    stdout) echo -e "$message" ;;
  esac
}

# Set verbose level index. Must be a standard logging verbosity level:
# debug, info, warning, error, fatal, none.
function verbosity() {
  for level in "${!VERBOSE_LEVELS[@]}"; do
    [[ "${VERBOSE_LEVELS[$level]}" = "$1" ]] && verbose_level="${level}" && return
  done
  ech warning "Invalid Verbosity Level '$1'"
}

# Set standard stream. Must be a standard stream:
# stderr, stdout, none.
function std() {
  if [[ $# -eq 0 ]]; then
    [ "$standard_stream" = "stdout" ] && std stderr || std none
  else
    for stream in "${!STANDARD_STREAMS[@]}"; do
      [[ "${STANDARD_STREAMS[$stream]}" = "$1" ]] && standard_stream="$1" && return
    done
    ech warning "Invalid Standard Stream '$1'"
  fi
}

# Shows an error if required tools are not installed.
function required {
  local e=0
  for tool in "$@"; do
    type $tool >/dev/null 2>&1 || {
      e=1 && err "$tool is required for running this script. Please install $tool and try again."
    }
  done
  [[ $e < 1 ]] || exit 2
}
