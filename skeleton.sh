#!/usr/bin/env bash -e
#
# Generic Shell Script Skeleton.
# Copyright (c) {{ YEAR }} - {{ AUTHOR }} <{{ AUTHOR_EMAIL }}>
#
# Built with shell-script-skeleton v0.0.3 <http://github.com/z017/shell-script-skeleton>

# Import common utilities
source "$(cd "$(dirname $(realpath "${BASH_SOURCE[0]}"))" && pwd)/common.sh"

#######################################
# SCRIPT CONSTANTS & VARIABLES
#######################################

readonly PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Script version
readonly VERSION=0.0.1

# List of required tools, example: REQUIRED_TOOLS=(git ssh)
readonly REQUIRED_TOOLS=()

# Long Options. To expect an argument for an option, just place a : (colon)
# after the proper option flag.
readonly LONG_OPTS=(help version force)

# Short Options. To expect an argument for an option, just place a : (colon)
# after the proper option flag.
readonly SHORT_OPTS=hv

# Script name
readonly SCRIPT_NAME=${0##*/}

# Force flag
declare FORCE=false

#######################################
# SCRIPT CONFIGURATION CONSTANTS
#######################################

# Put here configuration constants


#######################################
# help command
#######################################
function help_command() {
  cat <<END;

USAGE:
  $SCRIPT_NAME [options] <command>

OPTIONS:
  --help, -h              Alias help command
  --version, -v           Alias version command
  --force                 Don't ask for confirmation
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
  # Required tools
  required $REQUIRED_TOOLS

  # Parse options
  while [[ $# -ge $OPTIND ]] && eval opt=\${$OPTIND} || break
        [[ $opt == -- ]] && shift && break
        if [[ $opt == --?* ]]; then
          opt=${opt#--}; shift

          # Argument to option ?
          OPTARG=;local has_arg=0
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
      force)        FORCE=true ;;
      # Errors
      ::)	err "Unexpected argument to option '$OPTARG'"; exit 2; ;;
      :)	err "Missing argument to option '$OPTARG'"; exit 2; ;;
      \?)	err "Unknown option '$OPTARG'"; exit 2; ;;
      *)	err "Internal script error, unmatched option '$opt'"; exit 2; ;;
    esac
  done
  readonly FORCE
  shift $((OPTIND-1))

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
    *)  err "Unknown command '$command'"; exit 2; ;;
  esac
}
#######################################
# Run the script
#######################################
main "$@"
