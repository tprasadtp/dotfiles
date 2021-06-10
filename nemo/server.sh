#!/bin/bash
# shellcheck disable=SC2034,SC2155
readonly SCRIPT_DIR="$(cd -P -- "$(dirname -- "")" && pwd -P)"
go run "${SCRIPT_DIR}/main.go"
