#!/bin/bash -e
#
# Common utilities for scripts
# Copyright (c) {{ YEAR }} - {{ AUTHOR }} <{{ AUTHOR_EMAIL }}>
#
# Built with shell-script-skeleton v0.0.3 <http://github.com/z017/shell-script-skeleton>

#######################################
# CONSTANTS & VARIABLES
#######################################
readonly PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

#######################################
# FUNCTIONS
#######################################

# Print out messages to STDERR.
function ech() { echo -e "$@" >&2; }

# Print out error messages to STDERR.
function err() { echo -e "\033[0;31mERROR: $@\033[0m" >&2;  }

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

# Parse template file variables in the format "{{ VAR }}" with the "VAR" value.
# parse_template <input file template> <output file> <string of variables>
function parse_template {
  local e=0
  [[ ! -f "$1" ]] && err "$1 is not a valid file." && e=1
  [[ $2 != ${2%/*} ]] && mkdir -p ${2%/*}
  [[ -z $3 ]] && err "$3, must be an string of variables to replace" && e=1
  if [[ $e > 0 ]]; then
    ech "Usage: parse_template <input file template> <output file> <string of variables>"
    exit 2
  fi
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
  [[ ! -d $1 ]] && err "$1 is not a valid directory." && e=1
  [[ -z $3 ]] && err "$3, must be an string of variables to replace" && e=1
  if [[ $e > 0 ]]; then
    ech "Usage: parse_templates <input_dir> <output_dir> <string of variables>"
    exit 2
  fi
  # parse each file
  for file in "$1"/*.tpl*; do
    local filename=${file##*/}
    local outfile=${filename%.tpl*}${filename##*.tpl}
    parse_template $file $2/$outfile "$3"
  done
}
