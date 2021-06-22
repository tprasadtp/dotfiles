#!/usr/bin/env bash

set -eo pipefail

if [[ ! -e logger/logger.bash ]]; then
  echo "logger/logger.bash not found"
  exit 1
fi

lead="^#>> diana::snippet:bash-logger:begin <<#$"
tail="^#>> diana::snippet:bash-logger:end <<#$"

echo "- Update sign.sh"
sed -i "/$lead/,/$tail/{ /$lead/{p; r logger/logger.bash
            }; /$tail/p; d }" sign.sh

echo "- Update install.sh"
sed -i "/$lead/,/$tail/{ /$lead/{p; r logger/logger.bash
            }; /$tail/p; d }" install.sh

echo "- Update shellcheck.sh"
sed -i "/$lead/,/$tail/{ /$lead/{p; r logger/logger.bash
            }; /$tail/p; d }" hack/shellcheck.sh
