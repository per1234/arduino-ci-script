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

@test "check_library_structure \"./check_library_structure/ValidLibraryOnePointZero\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_library_structure "./check_library_structure/ValidLibraryOnePointZero"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_structure \"./check_library_structure/ValidLibraryOnePointFive\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_library_structure "./check_library_structure/ValidLibraryOnePointFive"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "check_library_structure \"./check_library_structure/DoesntExist\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_STRUCTURE_FOLDER_DOESNT_EXIST_EXIT_STATUS
  run check_library_structure "./check_library_structure/DoesntExist"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_structure \"./check_library_structure/IncorrectSrcFolderCase\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_STRUCTURE_INCORRECT_SRC_FOLDER_CASE_EXIT_STATUS
  run check_library_structure "./check_library_structure/IncorrectSrcFolderCase"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_structure \"./check_library_structure/NotLibrary\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_STRUCTURE_LIBRARY_NOT_FOUND_EXIT_STATUS
  run check_library_structure "./check_library_structure/NotLibrary"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_structure \"./check_library_structure/1FolderStartsWithNumber\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_library_structure "./check_library_structure/1FolderStartsWithNumber"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  warningRegex='^WARNING: Folder name \(.*\) beginning with a number'
  [[ "${lines[0]}" =~ $warningRegex ]]
}

@test "check_library_structure \"./check_library_structure/-FolderStartsWithInvalidCharacter\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_STRUCTURE_FOLDER_NAME_HAS_INVALID_FIRST_CHARACTER_EXIT_STATUS
  run check_library_structure "./check_library_structure/-FolderStartsWithInvalidCharacter"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_structure \"./check_library_structure/Invalid CharactersInFolder\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_STRUCTURE_FOLDER_NAME_HAS_INVALID_CHARACTER_EXIT_STATUS
  run check_library_structure "./check_library_structure/Invalid CharactersInFolder"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_structure \"./check_library_structure/FolderNameTooLongasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasd\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_STRUCTURE_FOLDER_NAME_TOO_LONG_EXIT_STATUS
  run check_library_structure "./check_library_structure/FolderNameTooLongasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasd"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_structure \"./check_library_structure/SpuriousDotFolder\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_STRUCTURE_SPURIOUS_DOT_FOLDER_EXIT_STATUS
  run check_library_structure "./check_library_structure/SpuriousDotFolder"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  errorRegex='^ERROR: \./check_library_structure/SpuriousDotFolder/\.asdf causes the Arduino IDE to display a spurious folder warning\.'
  [[ "${lines[0]}" =~ $warningRegex ]]
}

@test "check_library_structure \"./check_library_structure/IncorrectExtrasFolder\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_STRUCTURE_INCORRECT_EXTRAS_FOLDER_NAME_EXIT_STATUS
  run check_library_structure "./check_library_structure/IncorrectExtrasFolder"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_structure \"./check_library_structure/IncorrectExamplesFolder\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_STRUCTURE_INCORRECT_EXAMPLES_FOLDER_NAME_EXIT_STATUS
  run check_library_structure "./check_library_structure/IncorrectExamplesFolder"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_structure \"./check_library_structure/SrcAndUtiltyFolders\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_STRUCTURE_SRC_AND_UTILITY_FOLDERS_EXIT_STATUS
  run check_library_structure "./check_library_structure/SrcAndUtiltyFolders"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_structure \"./check_library_structure/MissingLibraryProperties\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_library_structure "./check_library_structure/MissingLibraryProperties"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  missingLibraryPropertiesWarningRegex='^WARNING: The library is missing a library\.properties'
  [[ "${lines[0]}" =~ $missingLibraryPropertiesWarningRegex ]]
}

@test "check_library_structure \"./check_library_structure/StrayLibraryProperties\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_STRUCTURE_STRAY_LIBRARY_PROPERTIES_EXIT_STATUS
  run check_library_structure "./check_library_structure/StrayLibraryProperties"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_structure \"./check_library_structure/MissingKeywordsTxt\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_library_structure "./check_library_structure/MissingKeywordsTxt"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  missingKeywordsTxtWarningRegex='^WARNING: The library is missing a keywords\.txt'
  [[ "${lines[0]}" =~ $missingKeywordsTxtWarningRegex ]]
}

@test "check_library_structure \"./check_library_structure/StrayKeywordsTxt\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_STRUCTURE_STRAY_KEYWORDS_TXT_EXIT_STATUS
  run check_library_structure "./check_library_structure/StrayKeywordsTxt"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_structure \"./check_library_structure/SketchOutsideExamples\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_STRUCTURE_STRAY_SKETCH_EXIT_STATUS
  run check_library_structure "./check_library_structure/SketchOutsideExamples"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

# check_sketch_structure

@test "check_sketch_structure \"./check_library_structure/DoesntExist\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_SKETCH_STRUCTURE_FOLDER_DOESNT_EXIST_EXIT_STATUS
  run check_sketch_structure "./check_library_structure/DoesntExist"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_sketch_structure \"./check_library_structure/PdeSketchExtension\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_sketch_structure "./check_library_structure/PdeSketchExtension"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  pdeWarningRegex='^WARNING: File .* uses the \.pde extension'
  [[ "${lines[0]}" =~ $pdeWarningRegex ]]
}

@test "check_sketch_structure \"./check_library_structure/IncorrectSketchExtensionCase\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_SKETCH_STRUCTURE_INCORRECT_EXTENSION_CASE_EXIT_STATUS
  run check_sketch_structure "./check_library_structure/IncorrectSketchExtensionCase"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_structure \"./check_library_structure/IncorrectSketchExtensionCase\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_STRUCTURE_INCORRECT_SKETCH_EXTENSION_CASE_EXIT_STATUS
  run check_library_structure "./check_library_structure/IncorrectSketchExtensionCase"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_sketch_structure \"./check_library_structure/SketchFolderStartsWithNumber\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_sketch_structure "./check_library_structure/SketchFolderStartsWithNumber"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  warningRegex='^WARNING: Folder name \(.*\) beginning with a number'
  [[ "${lines[0]}" =~ $warningRegex ]]
}

@test "check_sketch_structure \"./check_library_structure/InvalidCharactersAtStartOfSketchFolder\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_SKETCH_STRUCTURE_FOLDER_NAME_HAS_INVALID_FIRST_CHARACTER_EXIT_STATUS
  run check_sketch_structure "./check_library_structure/InvalidCharactersAtStartOfSketchFolder"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_structure \"./check_library_structure/InvalidCharactersAtStartOfSketchFolder\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_STRUCTURE_SKETCH_FOLDER_NAME_HAS_INVALID_FIRST_CHARACTER_EXIT_STATUS
  run check_library_structure "./check_library_structure/InvalidCharactersAtStartOfSketchFolder"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_sketch_structure \"./check_library_structure/InvalidCharactersInSketchFolder\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_SKETCH_STRUCTURE_FOLDER_NAME_HAS_INVALID_CHARACTER_EXIT_STATUS
  run check_sketch_structure "./check_library_structure/InvalidCharactersInSketchFolder"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_structure \"./check_library_structure/InvalidCharactersInSketchFolder\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_STRUCTURE_SKETCH_FOLDER_NAME_HAS_INVALID_CHARACTER_EXIT_STATUS
  run check_library_structure "./check_library_structure/InvalidCharactersInSketchFolder"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_sketch_structure \"./check_library_structure/SketchFolderNameTooLong\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_SKETCH_STRUCTURE_FOLDER_NAME_TOO_LONG_EXIT_STATUS
  run check_sketch_structure "./check_library_structure/SketchFolderNameTooLong"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_structure \"./check_library_structure/SketchFolderNameTooLong\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_STRUCTURE_SKETCH_FOLDER_NAME_TOO_LONG_EXIT_STATUS
  run check_library_structure "./check_library_structure/SketchFolderNameTooLong"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_sketch_structure \"./check_library_structure/SketchFolderNameTooLongExtras\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_SKETCH_STRUCTURE_FOLDER_NAME_TOO_LONG_EXIT_STATUS
  run check_sketch_structure "./check_library_structure/SketchFolderNameTooLongExtras"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_structure \"./check_library_structure/SketchFolderNameTooLongExtras\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_STRUCTURE_SKETCH_FOLDER_NAME_TOO_LONG_EXIT_STATUS
  run check_library_structure "./check_library_structure/SketchFolderNameTooLongExtras"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_sketch_structure \"./check_library_structure/SketchFolderNameMismatch\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_SKETCH_STRUCTURE_SKETCH_NAME_MISMATCH_EXIT_STATUS
  run check_sketch_structure "./check_library_structure/SketchFolderNameMismatch"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_structure \"./check_library_structure/SketchFolderNameMismatch\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_STRUCTURE_SKETCH_NAME_MISMATCH_EXIT_STATUS
  run check_library_structure "./check_library_structure/SketchFolderNameMismatch"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_sketch_structure \"./check_library_structure/MultipleSketchesInSameFolderUnix\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_SKETCH_STRUCTURE_MULTIPLE_SKETCHES_EXIT_STATUS
  run check_sketch_structure "./check_library_structure/MultipleSketchesInSameFolderUnix"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_structure \"./check_library_structure/MultipleSketchesInSameFolderUnix\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_STRUCTURE_MULTIPLE_SKETCHES_EXIT_STATUS
  run check_library_structure "./check_library_structure/MultipleSketchesInSameFolderUnix"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_sketch_structure \"./check_library_structure/MultipleSketchesInSameFolderMac\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_SKETCH_STRUCTURE_MULTIPLE_SKETCHES_EXIT_STATUS
  run check_sketch_structure "./check_library_structure/MultipleSketchesInSameFolderMac"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_structure \"./check_library_structure/MultipleSketchesInSameFolderMac\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_STRUCTURE_MULTIPLE_SKETCHES_EXIT_STATUS
  run check_library_structure "./check_library_structure/MultipleSketchesInSameFolderMac"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}
