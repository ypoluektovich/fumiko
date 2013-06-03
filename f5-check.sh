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


### Retrieves the item's current remote content

getItem() {
	local item="$1"
	log_debug "Getting item's remote content..."

	if [[ ! -f "${PROFILE_DIR}/${item}/url" ]]; then
		log_error "The url file is missing"
		return 1
	fi
	
	local url=$( cat "${PROFILE_DIR}/${item}/url" )
	log_debug "URL: $url\n"
	
	local itemTmpRemote="${F5_TEMP_DIR}/${item}/remote"
	mkdir -p "${itemTmpRemote}"
	date -Iseconds -u >"${itemTmpRemote}/timestamp"
	curl --output "${itemTmpRemote}/content" --dump-header "${itemTmpRemote}/header" "$url"
	local exit_code="$?"
	[[ "$exit_code" != 0 ]] && log_error "Failed to retrieve remote content (curl exited with status %d)" "$exit_code" && return 2
	return 0
}


### Given an item, its revision path, and a destination dir name, unpack the revision into the item's temporary dir

unpackItem() {
	local item="$1"
	local rev="$2"
	local dest="$3"
	log_debug "Unpacking item's revision ${rev} as ${dest}"
	
	local itemCache="${PROFILE_DIR}/${item}/revisions/${rev}"
	local itemTmpCache="${F5_TEMP_DIR}/${item}/${dest}"
	
	mkdir -p "${itemTmpCache}"
	tar --extract --xz --file "${itemCache}" -C "${itemTmpCache}"
	local exit_code="$?"
	[[ "$exit_code" != 0 ]] && log_error "Failed to extract content of %s %s (curl exited with status %d)" "$item" "$rev" "$exit_code" && return 2
	return 0
}


### Do the diff

doDiff() {
	local item="$1"
	local first="$2"
	local second="$3"
	log_debug "Diffing ${first} and ${second}"
	
	local diffScript="${PROFILE_DIR}/${item}/diff"
	"${diffScript}" "${F5_TEMP_DIR}/${item}/${first}/content" "${F5_TEMP_DIR}/${item}/${second}/content"
}


### Store retrieved item

storeItem() {
	local item="$1"
	log_debug "Storing remote"
	
	local itemTmpRemote="${F5_TEMP_DIR}/${item}/remote"
	local timePath=$( date -d $( cat "${itemTmpRemote}/timestamp" ) -u "+%Y-%m/%d/%H%M%S" )
	local storeFile="${PROFILE_DIR}/${item}/revisions/${timePath}"
	mkdir -p $( dirname "$storeFile" )
	tar --create --xz --file "$storeFile" \
		-C "${itemTmpRemote}" "timestamp" "header" "content"
	local exit_code="$?"
	[[ "$exit_code" != 0 ]] && log_error "Failed to store remote content (tar exited with status %d)" "$exit_code" && return 2
	log_debug "Stored %s" "${timePath}"
	echo "${timePath}" >"${F5_TEMP_DIR}/${item}/stored"
}

storeItemAsLatest() {
	local item="$1"
	
	storeItem "$item" || return $?
	local storedRevision=$( cat "${F5_TEMP_DIR}/${item}/stored" )
	
	log_debug "Recreating revisions/latest"
	local latestLink="${PROFILE_DIR}/${item}/revisions/latest"
	rm -f "$latestLink" || return 2
	ln -s "${storedRevision}" "$latestLink" || return 2
	return 0
}


### Checks a single item

checkSingle() {
	local item="$1"
	log_info "Processing: %s" "$item"

	local latestLink="${PROFILE_DIR}/${item}/revisions/latest"
	if [[ -L "$latestLink" ]]; then
		log_debug "Found a latest cache link"
		unpackItem "$item" "latest" "latest" || return $?
		getItem "$item" || return $?
		
		doDiff "$item" "latest" "remote"
		local diff_exit_code="$?"
		if [[ "$diff_exit_code" == 0 ]]; then
			log_debug "No differences"
			return 0
		elif [[ "$diff_exit_code" == 1 ]]; then
			log_debug "Differences detected"
			storeItemAsLatest "$item"
			return $?
		else
			log_error "Error while diffing (script returned %d" "$diff_exit_code"
			return 2
		fi
	else
		log_debug "Latest cache link missing or corrupted"
		getItem "$item" || return $?
		storeItemAsLatest "$item"
		return $?
	fi
}


### Operational parameters

PROFILE_DIR=$( realpath "${1:-profile}" )
F5_TEMP_DIR=$( mktemp -d )

### Main

log_info "Profile dir: %s" "${PROFILE_DIR}"
log_info "F5 temp dir: %s" "${F5_TEMP_DIR}"

for item in $( find "${PROFILE_DIR}" -mindepth 1 -type d -name "*.f5" -printf "%P\n" -prune ); do
	checkSingle "$item"
done

rm -rf "${F5_TEMP_DIR}"
