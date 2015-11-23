#!/bin/bash -e
#
# Common utilities for scripts
# Copyright (c) 2015 - Jeremias Longo <jeremias@pikel.org>

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
