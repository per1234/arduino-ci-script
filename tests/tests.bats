#!/usr/bin/env bats

source ../arduino-ci-script.sh

# Must be >= 1.8.0
TESTS_BATS_IDE_VERSION="1.8.5"
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

@test "set_script_verbosity 0" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run set_script_verbosity 0
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "set_script_verbosity 1" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run set_script_verbosity 1
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "set_script_verbosity 2" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run set_script_verbosity 2
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "set_application_folder \"$TESTS_BATS_APPLICATION_FOLDER\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run set_application_folder "$TESTS_BATS_APPLICATION_FOLDER"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "set_sketchbook_folder" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run set_sketchbook_folder .
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "set_board_testing \"true\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run set_board_testing "true"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "set_board_testing \"false\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run set_board_testing "false"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "set_library_testing \"true\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run set_library_testing "true"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "set_library_testing \"false\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run set_library_testing "false"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "install_ide \"$TESTS_BATS_IDE_VERSION\" (w/o setting application folder first)" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_FAILURE_EXIT_STATUS
  run install_ide "$TESTS_BATS_IDE_VERSION"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  errorRegex='^ERROR: Application folder was not set.'
  [[ "${lines[0]}" =~ $errorRegex ]]
}

@test "set_verbose_output_during_compilation \"true\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run set_verbose_output_during_compilation "true"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "set_verbose_output_during_compilation \"false\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run set_verbose_output_during_compilation "false"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "display_report" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run display_report
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  reportRegex='Begin Report'
  [[ "$lines" =~ $reportRegex ]]
}

# check_library_structure

@test "check_library_structure \"./check_library_structure/ValidLibraryOnePointZero\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_library_structure "./check_library_structure/ValidLibraryOnePointZero"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 0 ]
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

# check_library_properties

@test "check_library_properties \"./check_library_properties/ValidLibraryPropertiesUnix\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_library_properties "./check_library_properties/ValidLibraryPropertiesUnix"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "check_library_properties \"./check_library_properties/ValidLibraryPropertiesWindows\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_library_properties "./check_library_properties/ValidLibraryPropertiesWindows"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "check_library_properties \"./check_library_properties/ValidLibraryPropertiesMac\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_library_properties "./check_library_properties/ValidLibraryPropertiesMac"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "check_library_properties \"./check_library_properties/NoLibraryProperties\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_library_properties "./check_library_properties/NoLibraryProperties"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "check_library_properties \"./check_library_properties/DoesntExist\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_FOLDER_DOESNT_EXIST_EXIT_STATUS
  run check_library_properties "./check_library_properties/DoesntExist"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/InvalidFilenameCase\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_INCORRECT_FILENAME_CASE_EXIT_STATUS
  run check_library_properties "./check_library_properties/InvalidFilenameCase"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/MissingName\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_MISSING_NAME_EXIT_STATUS
  run check_library_properties "./check_library_properties/MissingName"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/BOM\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_MISSING_NAME_EXIT_STATUS
  run check_library_properties "./check_library_properties/BOM"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  # The BOM corrupts the first line, which in this case is the name field
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/MissingVersion\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_MISSING_VERSION_EXIT_STATUS
  run check_library_properties "./check_library_properties/MissingVersion"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/MissingAuthor\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_MISSING_AUTHOR_EXIT_STATUS
  run check_library_properties "./check_library_properties/MissingAuthor"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/EmailInsteadOfMaintainer\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_library_properties "./check_library_properties/EmailInsteadOfMaintainer"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  warningRegex='^WARNING: Use of undocumented email field'
  [[ "${lines[0]}" =~ $warningRegex ]]
}

@test "check_library_properties \"./check_library_properties/MissingMaintainer\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_MISSING_MAINTAINER_EXIT_STATUS
  run check_library_properties "./check_library_properties/MissingMaintainer"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/MissingSentence\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_MISSING_SENTENCE_EXIT_STATUS
  run check_library_properties "./check_library_properties/MissingSentence"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/MissingParagraph\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_MISSING_PARAGRAPH_EXIT_STATUS
  run check_library_properties "./check_library_properties/MissingParagraph"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/MissingCategory\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_MISSING_CATEGORY_EXIT_STATUS
  run check_library_properties "./check_library_properties/MissingCategory"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/MissingUrl\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_MISSING_URL_EXIT_STATUS
  run check_library_properties "./check_library_properties/MissingUrl"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/MissingArchitectures\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_library_properties "./check_library_properties/MissingArchitectures"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  warningRegex='^WARNING: .* is missing the architectures field'
  [[ "${lines[0]}" =~ $warningRegex ]]
}

@test "check_library_properties \"./check_library_properties/InvalidLine\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_INVALID_LINE_EXIT_STATUS
  run check_library_properties "./check_library_properties/InvalidLine"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/InvalidCharactersAtStartOfName\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_NAME_HAS_INVALID_FIRST_CHARACTER_EXIT_STATUS
  run check_library_properties "./check_library_properties/InvalidCharactersAtStartOfName"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  # check_valid_folder_name outputs an error message, then check_library_properties another
  [ "${#lines[@]}" -eq 2 ]
}

@test "check_library_properties \"./check_library_properties/InvalidCharactersInName\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_NAME_HAS_INVALID_CHARACTER_EXIT_STATUS
  run check_library_properties "./check_library_properties/InvalidCharactersInName"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 2 ]
}

@test "check_library_properties \"./check_library_properties/NameTooLong\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_NAME_TOO_LONG_EXIT_STATUS
  run check_library_properties "./check_library_properties/NameTooLong"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 2 ]
}

@test "check_library_properties \"./check_library_properties/InvalidVersion\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_INVALID_VERSION_EXIT_STATUS
  run check_library_properties "./check_library_properties/InvalidVersion"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/RedundantParagraph\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_REDUNDANT_PARAGRAPH_EXIT_STATUS
  run check_library_properties "./check_library_properties/RedundantParagraph"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/InvalidCategory\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_INVALID_CATEGORY_EXIT_STATUS
  run check_library_properties "./check_library_properties/InvalidCategory"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/UncategorizedCategory\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_library_properties "./check_library_properties/UncategorizedCategory"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  warningRegex="^WARNING: category 'Uncategorized' used in"
  [[ "${lines[0]}" =~ $warningRegex ]]
}

@test "check_library_properties \"./check_library_properties/BlankUrl\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_URL_BLANK_EXIT_STATUS
  run check_library_properties "./check_library_properties/BlankUrl"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/MissingScheme\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_URL_MISSING_SCHEME_EXIT_STATUS
  run check_library_properties "./check_library_properties/MissingScheme"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/DeadUrl\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_DEAD_URL_EXIT_STATUS
  run check_library_properties "./check_library_properties/DeadUrl"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/ArchitecturesMisspelled\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_ARCHITECTURES_MISSPELLED_EXIT_STATUS
  run check_library_properties "./check_library_properties/ArchitecturesMisspelled"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/ArchitectureAliasWithValidMatch\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_library_properties "./check_library_properties/ArchitectureAliasWithValidMatch"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  unrecognizedArchitectureRegex='^WARNING: \./check_library_properties/ArchitectureAliasWithValidMatch/library\.properties'\''s architectures field contains an unknown architecture Avr'
  [[ "${lines[0]}" =~ $IDEnotInstalledRegex ]]
}

@test "check_library_properties \"./check_library_properties/InvalidArchitectureWithWildcard\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_library_properties "./check_library_properties/InvalidArchitectureWithWildcard"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "check_library_properties \"./check_library_properties/ValidArchitecturesWithSpace\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_library_properties "./check_library_properties/ValidArchitecturesWithSpace"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "check_library_properties \"./check_library_properties/ArchitectureAliasWithoutValidMatch\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_INVALID_ARCHITECTURE_EXIT_STATUS
  run check_library_properties "./check_library_properties/ArchitectureAliasWithoutValidMatch"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 2 ]
}

@test "check_library_properties \"./check_library_properties/NoRecognizedArchitecture\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_INVALID_ARCHITECTURE_EXIT_STATUS
  run check_library_properties "./check_library_properties/NoRecognizedArchitecture"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 2 ]
}

@test "check_library_properties \"./check_library_properties/InvalidArchitecture\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_INVALID_ARCHITECTURE_EXIT_STATUS
  run check_library_properties "./check_library_properties/InvalidArchitecture"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 2 ]
  unrecognizedArchitectureRegex='^WARNING:\./check_library_properties/InvalidArchitecture/library\.properties'\''s architectures field contains an unknown architecture asdf'
  [[ "${lines[0]}" =~ $IDEnotInstalledRegex ]]
}

@test "check_library_properties \"./check_library_properties/EmptyIncludes\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_EMPTY_INCLUDES_EXIT_STATUS
  run check_library_properties "./check_library_properties/EmptyIncludes"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

# check_keywords_txt

@test "check_keywords_txt \"./check_keywords_txt/ValidKeywordsTxtUnix\" (w/o IDE installed)" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/ValidKeywordsTxtUnix"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  # One warning is printed for each reference link (currently there are two)
  [ "${#lines[@]}" -eq 2 ]
  IDEnotInstalledRegex='^WARNING: Arduino IDE is not installed'
  [[ "${lines[0]}" =~ $IDEnotInstalledRegex ]]
  [[ "${lines[1]}" =~ $IDEnotInstalledRegex ]]
}

@test "check_keywords_txt \"./check_keywords_txt/ValidKeywordsTxtUnix\" (w/ IDE installed)" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run set_application_folder "$TESTS_BATS_APPLICATION_FOLDER"
  # The environment variable set by set_application_folder is not preserved so it must be set here
  ARDUINO_CI_SCRIPT_APPLICATION_FOLDER="$TESTS_BATS_APPLICATION_FOLDER"
  run install_ide "$TESTS_BATS_IDE_VERSION"
  # The environment variable set by install_ide is not preserved so it must be set here
  NEWEST_INSTALLED_IDE_VERSION="$TESTS_BATS_IDE_VERSION"
  run check_keywords_txt "./check_keywords_txt/ValidKeywordsTxtUnix"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "check_keywords_txt \"./check_keywords_txt/ValidKeywordsTxtWindows\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/ValidKeywordsTxtWindows"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
}

@test "check_keywords_txt \"./check_keywords_txt/ValidKeywordsTxtMac\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/ValidKeywordsTxtMac"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
}

@test "check_keywords_txt \"./check_keywords_txt/NoKeywordsTxt\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/NoKeywordsTxt"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "check_keywords_txt \"./check_keywords_txt/DoesntExist\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_KEYWORDS_TXT_FOLDER_DOESNT_EXIST_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/DoesntExist"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_keywords_txt \"./check_keywords_txt/IncorrectFilenameCase\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_KEYWORDS_TXT_INCORRECT_FILENAME_CASE_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/IncorrectFilenameCase"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
}

@test "check_keywords_txt \"./check_keywords_txt/InvalidSeparator\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_KEYWORDS_TXT_INVALID_FIELD_SEPARATOR_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/InvalidSeparator"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
}

@test "check_keywords_txt \"./check_keywords_txt/ConsequentialMultipleTabs\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_KEYWORDS_TXT_MULTIPLE_TABS_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/ConsequentialMultipleTabs"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
}

@test "check_keywords_txt \"./check_keywords_txt/InconsequentialMultipleTabs\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_KEYWORDS_TXT_INCONSEQUENTIAL_MULTIPLE_TABS_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/InconsequentialMultipleTabs"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
}

@test "check_keywords_txt \"./check_keywords_txt/InvalidLine\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_KEYWORDS_TXT_INVALID_LINE_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/InvalidLine"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
}

@test "check_keywords_txt \"./check_keywords_txt/BOMcorruptedKeyword\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_KEYWORDS_TXT_BOM_CORRUPTED_KEYWORD_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/BOMcorruptedKeyword"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
}

@test "check_keywords_txt \"./check_keywords_txt/InconsequentialLeadingSpaceOnKeywordTokentype\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_KEYWORDS_TXT_INCONSEQUENTIAL_LEADING_SPACE_ON_KEYWORD_TOKENTYPE_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/InconsequentialLeadingSpaceOnKeywordTokentype"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
}

@test "check_keywords_txt \"./check_keywords_txt/ConsequentialLeadingSpaceOnKeywordTokentype\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_KEYWORDS_TXT_LEADING_SPACE_ON_KEYWORD_TOKENTYPE_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/ConsequentialLeadingSpaceOnKeywordTokentype"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
}

@test "check_keywords_txt \"./check_keywords_txt/InvalidKeywordTokentypeUnix\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_KEYWORDS_TXT_INVALID_KEYWORD_TOKENTYPE_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/InvalidKeywordTokentypeUnix"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
}

@test "check_keywords_txt \"./check_keywords_txt/InvalidKeywordTokentypeWindows\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_KEYWORDS_TXT_INVALID_KEYWORD_TOKENTYPE_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/InvalidKeywordTokentypeWindows"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
}

@test "check_keywords_txt \"./check_keywords_txt/InvalidKeywordTokentypeMac\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_KEYWORDS_TXT_INVALID_KEYWORD_TOKENTYPE_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/InvalidKeywordTokentypeMac"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
}

@test "check_keywords_txt \"./check_keywords_txt/InvalidKeywordTokentypeLastLine\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_KEYWORDS_TXT_INVALID_KEYWORD_TOKENTYPE_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/InvalidKeywordTokentypeLastLine"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
}

@test "check_keywords_txt \"./check_keywords_txt/LeadingSpaceOnRsyntaxtextareaTokentype\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_KEYWORDS_TXT_LEADING_SPACE_ON_RSYNTAXTEXTAREA_TOKENTYPE_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/LeadingSpaceOnRsyntaxtextareaTokentype"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
}

@test "check_keywords_txt \"./check_keywords_txt/InvalidRsyntaxtextareaTokentype\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_KEYWORDS_TXT_INVALID_RSYNTAXTEXTAREA_TOKENTYPE_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/InvalidRsyntaxtextareaTokentype"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
}

@test "check_keywords_txt \"./check_keywords_txt/InvalidRsyntaxtextareaTokentypeNoReferenceLink\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_KEYWORDS_TXT_INVALID_RSYNTAXTEXTAREA_TOKENTYPE_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/InvalidRsyntaxtextareaTokentypeNoReferenceLink"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
}

@test "check_keywords_txt \"./check_keywords_txt/InvalidReferenceLink\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_KEYWORDS_TXT_INVALID_REFERENCE_LINK_EXIT_STATUS
  run set_application_folder "$TESTS_BATS_APPLICATION_FOLDER"
  # The environment variable set by set_application_folder is not preserved so it must be set here
  ARDUINO_CI_SCRIPT_APPLICATION_FOLDER="$TESTS_BATS_APPLICATION_FOLDER"
  run install_ide "$TESTS_BATS_IDE_VERSION"
  # The environment variable set by install_ide is not preserved so it must be set here
  NEWEST_INSTALLED_IDE_VERSION="$TESTS_BATS_IDE_VERSION"
  run check_keywords_txt "./check_keywords_txt/InvalidReferenceLink"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_keywords_txt \"./check_keywords_txt/IncorrectCaseReferenceLink\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_KEYWORDS_TXT_INVALID_REFERENCE_LINK_EXIT_STATUS
  run set_application_folder "$TESTS_BATS_APPLICATION_FOLDER"
  # The environment variable set by set_application_folder is not preserved so it must be set here
  ARDUINO_CI_SCRIPT_APPLICATION_FOLDER="$TESTS_BATS_APPLICATION_FOLDER"
  run install_ide "$TESTS_BATS_IDE_VERSION"
  # The environment variable set by install_ide is not preserved so it must be set here
  NEWEST_INSTALLED_IDE_VERSION="$TESTS_BATS_IDE_VERSION"
  run check_keywords_txt "./check_keywords_txt/IncorrectCaseReferenceLink"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

# check_library_manager_compliance

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
