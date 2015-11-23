#!/bin/bash -e
#
# Common utilities for scripts
# Copyright (c) 2015 - Jeremias Longo <jeremias@pikel.org>

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

#######################################
# FUNCTIONS
#######################################

# Print out error messages to STDERR.
function err() {
  [[ $verbose_level -ge 1 ]] \
    && echo -e "\033[0;${LEVEL_COLORS[1]}mERROR: $@\033[0m" >&2
}

# Print out messages with given verbose level to STDERR.
function ech() {
  local level=4 # Default Info
  if [[ $# -gt 1 ]]; then
    for lvl in "${!VERBOSE_LEVELS[@]}"; do
      [[ "${VERBOSE_LEVELS[$lvl]}" = "$1" ]] && level="${lvl}" && break
    done
    shift
  fi
  [[ $level = 0 || $level -gt $verbose_level ]] && return
  tag=$(echo ${VERBOSE_LEVELS[$level]} | tr "a-z" "A-Z" )
  echo -e "\033[0;${LEVEL_COLORS[$level]}m$tag: $@\033[0m" >&2
}

# Set verbose level index. Must be a standard logging verbosity level:
# debug, info, warning, error, fatal, none.
function verbosity() {
  for level in "${!VERBOSE_LEVELS[@]}"; do
    [[ "${VERBOSE_LEVELS[$level]}" = "$1" ]] && verbose_level="${level}" && return
  done
  ech warning "Invalid Verbosity Level '$1'"
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
