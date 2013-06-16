#!/bin/bash

ITEM_DIR="${1:-.}"

if [[ ! -d "${ITEM_DIR}" ]]; then
	echo "Error: target does not exist: ${ITEM_DIR}" 1>&2
	exit 1
fi

ITEM_DIR=$( realpath "${ITEM_DIR}" )

if [[ ! "${ITEM_DIR}" =~ \.f5$ ]]; then
	echo "Error: not an item directory: ${ITEM_DIR}" 1>&2
	exit 2
fi

[[ ! -d "${ITEM_DIR}/revisions" ]] && exit 0

find "${ITEM_DIR}/revisions" -type f -printf "%P\n" | \
	grep -E "[0-9]{1,}-[0-9]{2}/[0-9]{2}/[0-9]{6}" | \
	sort
