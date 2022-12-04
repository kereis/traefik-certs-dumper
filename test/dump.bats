#!/usr/bin/env ./bats/bin/bats

setup() {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'

  DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
  PATH="$DIR/../bin:$PATH"

  TMP_OUTPUT_DIR="./tmp"

  mkdir "${TMP_OUTPUT_DIR}" || true
}

teardown() {
  rm -r "${TMP_OUTPUT_DIR}"
}

@test "should call post-hook script and create posthook.example" {
  POST_HOOK_FILE_PATH="${DIR}/test_post_hook.sh" . dump.sh

  run post_hook

  [ -f "${TMP_OUTPUT_DIR}/posthook.example" ]
}

@test "should create a combined PEM file if COMBINED_PEM is set" {
  return 1
}
