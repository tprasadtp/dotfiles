#!/usr/bin/env bash

set -eo pipefail

if [[ ! -e libs/logger/logger.sh ]]; then
  echo "libs/logger/logger.sh not found"
  exit 1
fi

logger_lead="^#>> diana::snippet:bash-logger:begin <<#$"
logger_tail="^#>> diana::snippet:bash-logger:end <<#$"

logger_files=("sign.sh" "install.sh" "config/bin-hpc/jobctl" "config/bin-hpc/vnc-ctl" "scripts/shellcheck.sh" "scripts/changelog.sh")

for f in "${logger_files[@]}"; do
  echo "- Update $f (logger)"
  sed -i "/$logger_lead/,/$logger_tail/{ /$logger_lead/{p; r libs/logger/logger.sh
              }; /$logger_tail/p; d }" "$f"
done
