#!/bin/bash
#
# Generic Shell Script Skeleton.
# Copyright (c) 2015 - Jeremias Longo <jeremias@pikel.org>
#
# Build with Shell Script Skeleton <https://github.com/z017/shell-script-skeleton>

#######################################
# SHELL OPTIONS
#######################################

# Exit immediately if a pipeline returns a non-zero status
set -o errexit

# The return value of a pipeline is the value of the last (rightmost) command to
# exit with a non-zero status, or zero if all commands in the pipeline exit
# successfully.
set -o pipefail

#######################################
# CONSTANTS & VARIABLES
#######################################

# Script version
readonly VERSION=0.0.1

# List of required tools, example: REQUIRED_TOOLS=(git ssh)
readonly REQUIRED_TOOLS=()

# Long Options. To expect an argument for an option, just place a : (colon)
# after the proper option flag.
readonly LONG_OPTS=(help version verbosity: quiet)

# Short Options. To expect an argument for an option, just place a : (colon)
# after the proper option flag.
readonly SHORT_OPTS=hvq

# Script name
readonly SCRIPT_NAME=${0##*/}

# Script Directory
readonly SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Verbose Levels
readonly VERBOSE_LEVELS=(none fatal error warning info debug)

# Level Colors
readonly LEVEL_COLORS=(39, 31, 31, 33, 32, 36)

# Defaults Verbose Level - 0 none, 1 fatal, 2 error, 3 warning, 4 info, 5 debug
readonly VERBOSE_DEFAULT=3

# Current verbose level
declare -i verbose_level="$VERBOSE_DEFAULT"

# Quiet Mode
QUIET=false

#######################################
# UTILS FUNCTIONS
#######################################

# Print out fatal error messages to STDERR and exit 2.
function err() {
  local level=1
  [[ $verbose_level -ge $level ]] \
    && echo -e "\033[0;${LEVEL_COLORS[$level]}mFATAL: $@\033[0m" >&2
  exit 2
}

# Print out messages with given verbose level to STDERR.
function message() {
  local level=4
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
  message warning "Invalid Verbosity Level '$1'"
}


#######################################
# help command
#######################################
function help_command() {
  cat <<END;

USAGE:
  $SCRIPT_NAME [options] <command>

OPTIONS:
  --quiet, -q             Disable all interactive prompts.
  --verbosity <level>     Override the default verbosity for the command. Must
                          be a standard logging verbosity level: [debug, info,
                          warning, error, fatal, none] (Default: [warning])
  --help, -h              Alias help command
  --version, -v           Alias version command
  --                      Denotes the end of the options.  Arguments after this
                          will be handled as parameters even if they start with
                          a '-'.

COMMANDS:
  help                    Display detailed help
  version                 Print version information.

END
  exit 1
}

#######################################
# version command
#######################################
function version_command() {
  echo "$SCRIPT_NAME version $VERSION"
}

#######################################
# default command
#######################################
function default_command() {
  # set default command here
  help_command
}

#######################################
#
# MAIN
#
#######################################
function main() {
  # Shows an error if required tools are not installed.
  for tool in "${REQUIRED_TOOLS[@]}"; do
  	[[ ! $(which $tool) ]] && err "$tool is required for running this script. Please install $tool and try again."
  done

  # Parse options
  while [[ $# -ge $OPTIND ]] && eval opt=\${$OPTIND} || break
        [[ $opt == -- ]] && shift && break
        if [[ $opt == --?* ]]; then
          opt=${opt#--}
      		shift

      		# Argument to option ?
          OPTARG=
          local has_arg=0
      		[[ $opt == *=* ]] && OPTARG=${opt#*=} && opt=${opt%=$OPTARG} && has_arg=1

      		# Check if known option and if it has an argument if it must:
          local state=0
          for option in "${LONG_OPTS[@]}"; do
            [[ "$option" == "$opt" ]] && state=1 && break
            [[ "${option%:}" == "$opt" ]] && state=2 && break
          done
          # Param not found
          [[ $state = 0 ]] && OPTARG=$opt && opt='?'
          # Param with no args, has args
          [[ $state = 1 && $has_arg = 1 ]] && OPTARG=$opt && opt=::
          # Param with args, has no args
          if [[ $state = 2 && $has_arg = 0 ]]; then
            [[ $# -ge $OPTIND ]] && eval OPTARG=\${$OPTIND} && shift || { OPTARG=$opt; opt=:; }
          fi

          # for the while
          true
      	else
          getopts ":$SHORT_OPTS" opt
      	fi
  do
    case "$opt" in
      # List of options
      v|version)    version_command; exit 0; ;;
      h|help)       help_command ;;
      q|quiet)      QUIET=true ;;
      verbosity)    verbosity "$OPTARG" ;;
      # Errors
      ::)	err "Unexpected argument to option '$OPTARG'" ;;
    	:)	err "Missing argument to option '$OPTARG'" ;;
    	\?)	err "Unknown option '$OPTARG'" ;;
    	*)	err "Internal script error, unmatched option '$opt'" ;;
    esac
  done
  shift $((OPTIND-1))
  readonly QUIET

  # No more arguments -> call default command
  [[ -z "$1" ]] && default_command

  # Set command and arguments
  command="$1" && shift
  args="$@"

  # Execute the command
  case "$command" in
    # help
    help)     help_command ;;

    # version
    version)  version_command ;;

    # Unknown command
    *)        err "Unknown command '$command'" ;;
  esac
}
#######################################
# Run the script
#######################################
main "$@"
