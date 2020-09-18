#!/usr/bin/env bash

# Test the shellscripts in this repo using shellcheck
# Version:0.1
# Author: Prasad Tengse
# Licence: MIT

set -eo pipefail
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "Testing ShellScripts"
ERRORS=()

# find all executables and run `shellcheck`
for file in $(find . -type f -not -iwholename '*.git*' -not -iwholename 'vendor*' -executable | sort -u); do
	if file "${file}" ; then
		{
			shellcheck -x -e SC2059 -e SC1071 "${file}" && printf " [ OK ]: sucessfully linted %s\n\n" "${file}"

		} ||
		{
			# If shell check failed
			ERRORS+=("${file}")
		}
	fi
done

if [ ${#ERRORS[@]} -eq 0 ]; then
	printf "\nNo errors, hooray!!\n"
else
	echo "These files failed shellcheck: ${ERRORS[*]}"
	exit 1
fi
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
