#!/usr/bin/env bats

source ../arduino-ci-script.sh

@test "check_sketch_structure \"./check_library_structure/DoesntExist\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_SKETCH_STRUCTURE_FOLDER_DOESNT_EXIST_EXIT_STATUS
  run check_sketch_structure "./check_library_structure/DoesntExist"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_sketch_structure \"./check_library_structure/PdeSketchExtension\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_sketch_structure "./check_library_structure/PdeSketchExtension"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_sketch_structure \"./check_library_structure/IncorrectSketchExtensionCase\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_SKETCH_STRUCTURE_INCORRECT_EXTENSION_CASE_EXIT_STATUS
  run check_sketch_structure "./check_library_structure/IncorrectSketchExtensionCase"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_sketch_structure \"./check_library_structure/SketchFolderStartsWithNumber\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_sketch_structure "./check_library_structure/SketchFolderStartsWithNumber"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_sketch_structure \"./check_library_structure/InvalidCharactersAtStartOfSketchFolder\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_SKETCH_STRUCTURE_FOLDER_NAME_HAS_INVALID_FIRST_CHARACTER_EXIT_STATUS
  run check_sketch_structure "./check_library_structure/InvalidCharactersAtStartOfSketchFolder"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_sketch_structure \"./check_library_structure/InvalidCharactersInSketchFolder\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_SKETCH_STRUCTURE_FOLDER_NAME_HAS_INVALID_CHARACTER_EXIT_STATUS
  run check_sketch_structure "./check_library_structure/InvalidCharactersInSketchFolder"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_sketch_structure \"./check_library_structure/SketchFolderNameTooLong\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_SKETCH_STRUCTURE_FOLDER_NAME_TOO_LONG_EXIT_STATUS
  run check_sketch_structure "./check_library_structure/SketchFolderNameTooLong"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^ERROR: Folder name asdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdf exceeds the maximum of 63 characters\.'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_sketch_structure \"./check_library_structure/SketchFolderNameTooLongExtras\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_SKETCH_STRUCTURE_FOLDER_NAME_TOO_LONG_EXIT_STATUS
  run check_sketch_structure "./check_library_structure/SketchFolderNameTooLongExtras"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^ERROR: Folder name asdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdf exceeds the maximum of 63 characters\.'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_sketch_structure \"./check_library_structure/SketchFolderNameMismatch\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_SKETCH_STRUCTURE_SKETCH_NAME_MISMATCH_EXIT_STATUS
  run check_sketch_structure "./check_library_structure/SketchFolderNameMismatch"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^ERROR: Sketch folder name \./check_library_structure/SketchFolderNameMismatch/examples/example1 does not match the sketch filename\.'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_sketch_structure \"./check_library_structure/MultipleSketchesInSameFolderUnix\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_SKETCH_STRUCTURE_MULTIPLE_SKETCHES_EXIT_STATUS
  run check_sketch_structure "./check_library_structure/MultipleSketchesInSameFolderUnix"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^ERROR: Multiple sketches found in the same folder \(\./check_library_structure/MultipleSketchesInSameFolderUnix/examples/example1\)\.'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_sketch_structure \"./check_library_structure/MultipleSketchesInSameFolderMac\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_SKETCH_STRUCTURE_MULTIPLE_SKETCHES_EXIT_STATUS
  run check_sketch_structure "./check_library_structure/MultipleSketchesInSameFolderMac"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^ERROR: Multiple sketches found in the same folder \(\./check_library_structure/MultipleSketchesInSameFolderMac/examples/example1\)\.'
  [[ "${lines[0]}" =~ $outputRegex ]]
}
