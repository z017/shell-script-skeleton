# STD example

Extends `verbosity` example by `quiet` option.

Usage:
```
$ ./std help

USAGE:
  std [options] <command>

OPTIONS:
  --verbosity <level>     Override the default verbosity for the command. Must
                          be a standard logging verbosity level: [debug, info,
                          warning, error, fatal, none] (Default: [warning])
  --quiet, -q             Print output to STDERR instead of STDOUT.
  --force-quiet, -Q       Hide all output.
  --help, -h              Alias help command
  --version, -v           Alias version command
  --                      Denotes the end of the options.  Arguments after this
                          will be handled as parameters even if they start with
                          a '-'.

COMMANDS:
  help                    Display detailed help
  version                 Print version information.
```
