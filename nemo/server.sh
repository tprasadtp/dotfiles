#!/bin/bash
readonly SCRIPT_DIR="$(cd -P -- "$(dirname -- "")" && pwd -P)"
go run "${SCRIPT_DIR}/main.go"