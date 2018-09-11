#!/usr/bin/env bats

source ../arduino-ci-script.sh

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
  outputRegex="^ERROR: Specified folder: \./check_library_manager_compliance/DoesntExist doesn't exist\.$"
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_library_manager_compliance \"./check_library_manager_compliance/ContainsExe\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_MANAGER_COMPLIANCE_EXE_FOUND_EXIT_STATUS
  run check_library_manager_compliance "./check_library_manager_compliance/ContainsExe"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^ERROR: \.exe file found at \./check_library_manager_compliance/ContainsExe/asdf\.exe$'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_library_manager_compliance \"./check_library_manager_compliance/ContainsDotDevelopment\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_MANAGER_COMPLIANCE_DOT_DEVELOPMENT_FOUND_EXIT_STATUS
  run check_library_manager_compliance "./check_library_manager_compliance/ContainsDotDevelopment"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^ERROR: \.development file found at \./check_library_manager_compliance/ContainsDotDevelopment/\.development$'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_library_manager_compliance \"./check_library_manager_compliance/ContainsSymlink\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_MANAGER_COMPLIANCE_SYMLINK_FOUND_EXIT_STATUS
  run check_library_manager_compliance "./check_library_manager_compliance/ContainsSymlink"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^ERROR: Symlink found at \./check_library_manager_compliance/ContainsSymlink/IsSymlink$'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_library_manager_compliance \"./check_library_manager_compliance/InvalidCharactersAtStartOfName\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_MANAGER_COMPLIANCE_NAME_HAS_INVALID_FIRST_CHARACTER_EXIT_STATUS
  run check_library_manager_compliance "./check_library_manager_compliance/InvalidCharactersAtStartOfName"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  # check_valid_folder_name outputs an error message, then check_library_properties another
  [ "${#lines[@]}" -eq 2 ]
  outputRegex='^ERROR: Invalid folder name: -Foobar\. Folder name beginning with a - or \. is not allowed\.$'
  [[ "${lines[0]}" =~ $outputRegex ]]
  outputRegex="^ERROR: \./check_library_manager_compliance/InvalidCharactersAtStartOfName's name value -Foobar does not meet the requirements of the Arduino Library Manager indexer\. See: https://github.com/arduino/Arduino/wiki/Arduino-IDE-1.5:-Library-specification#libraryproperties-file-format$"
  [[ "${lines[1]}" =~ $outputRegex ]]
}

@test "check_library_manager_compliance \"./check_library_manager_compliance/InvalidCharactersInName\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_MANAGER_COMPLIANCE_NAME_HAS_INVALID_CHARACTER_EXIT_STATUS
  run check_library_manager_compliance "./check_library_manager_compliance/InvalidCharactersInName"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 2 ]
  outputRegex='^ERROR: Invalid folder name: Foo\(bar\)\. Only letters, numbers, dots, dashes, and underscores are allowed\.$'
  [[ "${lines[0]}" =~ $outputRegex ]]
  outputRegex="^ERROR: \./check_library_manager_compliance/InvalidCharactersInName's name value Foo\(bar\) does not meet the requirements of the Arduino Library Manager indexer\. See: https://github.com/arduino/Arduino/wiki/Arduino-IDE-1.5:-Library-specification#libraryproperties-file-format$"
  [[ "${lines[1]}" =~ $outputRegex ]]
}

@test "check_library_manager_compliance \"./check_library_manager_compliance/NameTooLong\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_MANAGER_COMPLIANCE_NAME_TOO_LONG_EXIT_STATUS
  run check_library_manager_compliance "./check_library_manager_compliance/NameTooLong"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 2 ]
  outputRegex='^ERROR: Folder name asdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdf exceeds the maximum of 63 characters\.$'
  [[ "${lines[0]}" =~ $outputRegex ]]
  outputRegex="^ERROR: \./check_library_manager_compliance/NameTooLong's name value asdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdf does not meet the requirements of the Arduino Library Manager indexer\. See: https://github.com/arduino/Arduino/wiki/Arduino-IDE-1.5:-Library-specification#libraryproperties-file-format$"
  [[ "${lines[1]}" =~ $outputRegex ]]
}
