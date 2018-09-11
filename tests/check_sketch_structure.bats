#!/usr/bin/env bats

source ../arduino-ci-script.sh

@test "check_sketch_structure \"./check_library_structure/DoesntExist\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_SKETCH_STRUCTURE_FOLDER_DOESNT_EXIST_EXIT_STATUS
  run check_sketch_structure "./check_library_structure/DoesntExist"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex="^ERROR: \./check_library_structure/DoesntExist: Folder doesn't exist\.$"
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_sketch_structure \"./check_library_structure/PdeSketchExtension\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_sketch_structure "./check_library_structure/PdeSketchExtension"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex="^WARNING: \./check_library_structure/PdeSketchExtension/examples/example1/foo\.pde: Uses \.pde extension\. For Arduino sketches, it's recommended to use the \.ino extension instead\. If this is a Processing sketch then \.pde is the correct extension\.$"
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_sketch_structure \"./check_library_structure/IncorrectSketchExtensionCase\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_SKETCH_STRUCTURE_INCORRECT_EXTENSION_CASE_EXIT_STATUS
  run check_sketch_structure "./check_library_structure/IncorrectSketchExtensionCase"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^ERROR: \./check_library_structure/IncorrectSketchExtensionCase/examples/example1/example1\.Ino: Incorrect extension case\. This causes it to not be recognized on a filename case-sensitive OS such as Linux\.$'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_sketch_structure \"./check_library_structure/SketchFolderStartsWithNumber\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_sketch_structure "./check_library_structure/SketchFolderStartsWithNumber"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^WARNING: Discouraged folder name: 1example1\. Folder name beginning with a number is only supported by Arduino IDE 1\.8\.4 and newer\.$'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_sketch_structure \"./check_library_structure/InvalidCharactersAtStartOfSketchFolder\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_SKETCH_STRUCTURE_FOLDER_NAME_HAS_INVALID_FIRST_CHARACTER_EXIT_STATUS
  run check_sketch_structure "./check_library_structure/InvalidCharactersAtStartOfSketchFolder"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^ERROR: Invalid folder name: -example1\. Folder name beginning with a - or \. is not allowed\.$'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_sketch_structure \"./check_library_structure/InvalidCharactersInSketchFolder\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_SKETCH_STRUCTURE_FOLDER_NAME_HAS_INVALID_CHARACTER_EXIT_STATUS
  run check_sketch_structure "./check_library_structure/InvalidCharactersInSketchFolder"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^ERROR: Invalid folder name: example 1\. Only letters, numbers, dots, dashes, and underscores are allowed\.$'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_sketch_structure \"./check_library_structure/SketchFolderNameTooLong\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_SKETCH_STRUCTURE_FOLDER_NAME_TOO_LONG_EXIT_STATUS
  run check_sketch_structure "./check_library_structure/SketchFolderNameTooLong"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^ERROR: Folder name asdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdf exceeds the maximum of 63 characters\.$'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_sketch_structure \"./check_library_structure/SketchFolderNameTooLongExtras\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_SKETCH_STRUCTURE_FOLDER_NAME_TOO_LONG_EXIT_STATUS
  run check_sketch_structure "./check_library_structure/SketchFolderNameTooLongExtras"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^ERROR: Folder name asdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdf exceeds the maximum of 63 characters\.$'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_sketch_structure \"./check_library_structure/SketchFolderNameMismatch\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_SKETCH_STRUCTURE_SKETCH_NAME_MISMATCH_EXIT_STATUS
  run check_sketch_structure "./check_library_structure/SketchFolderNameMismatch"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^ERROR: \./check_library_structure/SketchFolderNameMismatch/examples/example1: Folder name does not match the sketch filename\.$'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_sketch_structure \"./check_library_structure/MultipleSketchesInSameFolderUnix\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_SKETCH_STRUCTURE_MULTIPLE_SKETCHES_EXIT_STATUS
  run check_sketch_structure "./check_library_structure/MultipleSketchesInSameFolderUnix"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^ERROR: \./check_library_structure/MultipleSketchesInSameFolderUnix/examples/example1: Multiple sketches found in the same folder\.$'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_sketch_structure \"./check_library_structure/MultipleSketchesInSameFolderMac\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_SKETCH_STRUCTURE_MULTIPLE_SKETCHES_EXIT_STATUS
  run check_sketch_structure "./check_library_structure/MultipleSketchesInSameFolderMac"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^ERROR: \./check_library_structure/MultipleSketchesInSameFolderMac/examples/example1: Multiple sketches found in the same folder\.$'
  [[ "${lines[0]}" =~ $outputRegex ]]
}
