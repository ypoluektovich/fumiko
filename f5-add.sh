#!/bin/bash

source ./f5-utils.sh


### Add a single item

addSingle() {
	local item="$1"
	local url="$2"
	log_info "Adding item %s" "$item"
	
	if [[ ! "$item" =~ \.f5$ ]]; then
		log_debug "Item name does not end with .f5; adding"
		item="${item}.f5"
	fi
	
	local itemDir="${PROFILE_DIR}/${item}"
	mkdir -p "${itemDir}" || return 2
	
	log_debug "Writing url: %s" "${url}"
	echo "$url" >"${itemDir}/url" || return 2
	
	log_debug "Using ${CMP} as diff"
	ln -s "${CMP}" "${itemDir}/diff" || return 2
	
	return 0
}


### Operational parameters

PROFILE_DIR=$( realpath "${1:-.}" )
CMP=$( which cmp )

### Main

log_info "Profile dir: %s" "${PROFILE_DIR}"

while read item url ; do
	addSingle "$item" "$url"
done
