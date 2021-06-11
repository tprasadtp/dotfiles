#!/bin/env bats
function setup() {
    # get the containing directory of this file
    # use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0,
    # as those will point to the bats executable's location or the preprocessed file respectively
    PROJECT_ROOT="$( cd "$( dirname "$BATS_TEST_FILENAME" )/" >/dev/null 2>&1 && pwd )"
    # make executables in src/ visible to PATH
    PATH="$PROJECT_ROOT:$PATH"
    # set UTC
    TZ="UTC"
    # force colors in tests
    CLICOLOR_FORCE=1
}

@test 'default output' {
  run faketime 2000-01-01 ./demo.bash
  assert_output "$(cat $PROJECT_ROOT/fixtures/pretty.info.golden)"
}
