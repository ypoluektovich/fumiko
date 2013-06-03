#!/bin/bash

### Logging functions

log_error() {
	local message="$1"
	shift
	printf "\033[41mERROR\033[0m: $message\n" "$@"
}

log_info() {
	local message="$1"
	shift
	printf "$message\n" "$@"
}

log_debug() {
	local message="$1"
	shift
	printf "\t$message\n" "$@"
}
