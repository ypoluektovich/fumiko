#!/bin/bash

emitItem() {
	echo "$1"
}

PROFILE_DIR=$( realpath -e "${1:-.}" )

if [[ "${PROFILE_DIR}" =~ \.f5$ ]]; then
	emitItem "."
else
	for item in $( find "${PROFILE_DIR}" -type d -name "*.f5" -printf "%P\n" -prune ); do
		emitItem "$item"
	done
fi
