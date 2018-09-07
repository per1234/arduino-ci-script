#!/usr/bin/env bats

source ../arduino-ci-script.sh

# Must be >= 1.8.0
TESTS_BATS_IDE_VERSION="1.8.6"
TESTS_BATS_APPLICATION_FOLDER="$APPLICATION_FOLDER"

# Make sure the test's environment variables were configured

@test "\"\$TESTS_BATS_IDE_VERSION\" != \"\"" {
  [ "$TESTS_BATS_IDE_VERSION" != "" ]
  # The Xvfb command breaks the unit tests on Travis CI. That command is run with Arduino IDE 1.6.13 or older.
  virtualFramebufferRequiredIDEversionsRegex="^1.[56]"
  [[ ! "$TESTS_BATS_IDE_VERSION" =~ $virtualFramebufferRequiredIDEversionsRegex ]]
}

@test "\"\$TESTS_BATS_APPLICATION_FOLDER\" != \"\"" {
  [ "$TESTS_BATS_APPLICATION_FOLDER" != "" ]
}

@test "check_library_manager_compliance \"./check_library_manager_compliance/ValidLibrary\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_library_manager_compliance "./check_library_manager_compliance/ValidLibrary"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "check_library_manager_compliance \"./check_library_manager_compliance/DoesntExist\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_MANAGER_COMPLIANCE_FOLDER_DOESNT_EXIST_EXIT_STATUS
  run check_library_manager_compliance "./check_library_manager_compliance/DoesntExist"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_manager_compliance \"./check_library_manager_compliance/ContainsExe\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_MANAGER_COMPLIANCE_EXE_FOUND_EXIT_STATUS
  run check_library_manager_compliance "./check_library_manager_compliance/ContainsExe"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_manager_compliance \"./check_library_manager_compliance/ContainsDotDevelopment\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_MANAGER_COMPLIANCE_DOT_DEVELOPMENT_FOUND_EXIT_STATUS
  run check_library_manager_compliance "./check_library_manager_compliance/ContainsDotDevelopment"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_manager_compliance \"./check_library_manager_compliance/ContainsSymlink\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_MANAGER_COMPLIANCE_SYMLINK_FOUND_EXIT_STATUS
  run check_library_manager_compliance "./check_library_manager_compliance/ContainsSymlink"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_manager_compliance \"./check_library_manager_compliance/InvalidCharactersAtStartOfName\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_MANAGER_COMPLIANCE_NAME_HAS_INVALID_FIRST_CHARACTER_EXIT_STATUS
  run check_library_manager_compliance "./check_library_manager_compliance/InvalidCharactersAtStartOfName"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  # check_valid_folder_name outputs an error message, then check_library_properties another
  [ "${#lines[@]}" -eq 2 ]
}

@test "check_library_manager_compliance \"./check_library_manager_compliance/InvalidCharactersInName\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_MANAGER_COMPLIANCE_NAME_HAS_INVALID_CHARACTER_EXIT_STATUS
  run check_library_manager_compliance "./check_library_manager_compliance/InvalidCharactersInName"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 2 ]
}

@test "check_library_manager_compliance \"./check_library_manager_compliance/NameTooLong\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_MANAGER_COMPLIANCE_NAME_TOO_LONG_EXIT_STATUS
  run check_library_manager_compliance "./check_library_manager_compliance/NameTooLong"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 2 ]
}
