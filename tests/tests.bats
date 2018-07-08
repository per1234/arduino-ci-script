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
  run set_script_verbosity 0
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "set_script_verbosity 1" {
  run set_script_verbosity 1
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "set_script_verbosity 2" {
  run set_script_verbosity 2
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "set_application_folder \"$TESTS_BATS_APPLICATION_FOLDER\"" {
  run set_application_folder "$TESTS_BATS_APPLICATION_FOLDER"
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "set_sketchbook_folder" {
  run set_sketchbook_folder .
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "set_board_testing \"true\"" {
  run set_board_testing "true"
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "set_board_testing \"false\"" {
  run set_board_testing "false"
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "set_library_testing \"true\"" {
  run set_library_testing "true"
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "set_library_testing \"false\"" {
  run set_library_testing "false"
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "install_ide \"$TESTS_BATS_IDE_VERSION\" (w/o setting application folder first)" {
  run install_ide "$TESTS_BATS_IDE_VERSION"
  echo "status: $status"
  echo "lines:"
  echo "$lines"
  [ "$status" -eq 1 ]
  [ "${#lines[@]}" -eq 1 ]
  errorRegex='^ERROR: Application folder was not set.'
  [[ "${lines[0]}" =~ $errorRegex ]]
}

@test "set_verbose_output_during_compilation \"true\"" {
  run set_verbose_output_during_compilation "true"
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "set_verbose_output_during_compilation \"false\"" {
  run set_verbose_output_during_compilation "false"
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "display_report" {
  run display_report
  [ "$status" -eq 0 ]
  reportRegex='Begin Report'
  [[ "$lines" =~ $reportRegex ]]
}

# check_library_structure

@test "check_library_structure \"./check_library_structure/ValidLibraryOnePointZero\"" {
  run check_library_structure "./check_library_structure/ValidLibraryOnePointZero"
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "check_library_structure \"./check_library_structure/ValidLibraryOnePointFive\"" {
  run check_library_structure "./check_library_structure/ValidLibraryOnePointFive"
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "check_library_structure \"./check_library_structure/DoesntExist\"" {
  run check_library_structure "./check_library_structure/DoesntExist"
  [ "$status" -eq 1 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_structure \"./check_library_structure/IncorrectSrcFolderCase\"" {
  run check_library_structure "./check_library_structure/IncorrectSrcFolderCase"
  [ "$status" -eq 2 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_structure \"./check_library_structure/NotLibrary\"" {
  run check_library_structure "./check_library_structure/NotLibrary"
  [ "$status" -eq 3 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_structure \"./check_library_structure/-FolderStartsWithInvalidCharacter\"" {
  run check_library_structure "./check_library_structure/-FolderStartsWithInvalidCharacter"
  [ "$status" -eq 4 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_structure \"./check_library_structure/Invalid CharactersInFolder\"" {
  run check_library_structure "./check_library_structure/Invalid CharactersInFolder"
  [ "$status" -eq 5 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_structure \"./check_library_structure/FolderNameTooLongasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasd\"" {
  run check_library_structure "./check_library_structure/FolderNameTooLongasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasd"
  [ "$status" -eq 6 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_structure \"./check_library_structure/IncorrectExamplesFolder\"" {
  run check_library_structure "./check_library_structure/IncorrectExamplesFolder"
  [ "$status" -eq 7 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_structure \"./check_library_structure/SrcAndUtiltyFolders\"" {
  run check_library_structure "./check_library_structure/SrcAndUtiltyFolders"
  [ "$status" -eq 8 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_structure \"./check_library_structure/SketchOutsideExamples\"" {
  run check_library_structure "./check_library_structure/SketchOutsideExamples"
  [ "$status" -eq 9 ]
  [ "${#lines[@]}" -eq 1 ]
}

# check_sketch_structure

@test "check_sketch_structure \"./check_library_structure/DoesntExist\"" {
  run check_sketch_structure "./check_library_structure/DoesntExist"
  [ "$status" -eq 1 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_sketch_structure \"./check_library_structure/IncorrectSketchExtensionCase\"" {
  run check_sketch_structure "./check_library_structure/IncorrectSketchExtensionCase"
  [ "$status" -eq 2 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_structure \"./check_library_structure/IncorrectSketchExtensionCase\"" {
  run check_library_structure "./check_library_structure/IncorrectSketchExtensionCase"
  [ "$status" -eq 11 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_sketch_structure \"./check_library_structure/InvalidCharactersAtStartOfSketchFolder\"" {
  run check_sketch_structure "./check_library_structure/InvalidCharactersAtStartOfSketchFolder"
  [ "$status" -eq 3 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_structure \"./check_library_structure/InvalidCharactersAtStartOfSketchFolder\"" {
  run check_library_structure "./check_library_structure/InvalidCharactersAtStartOfSketchFolder"
  [ "$status" -eq 12 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_sketch_structure \"./check_library_structure/InvalidCharactersInSketchFolder\"" {
  run check_sketch_structure "./check_library_structure/InvalidCharactersInSketchFolder"
  [ "$status" -eq 4 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_structure \"./check_library_structure/InvalidCharactersInSketchFolder\"" {
  run check_library_structure "./check_library_structure/InvalidCharactersInSketchFolder"
  [ "$status" -eq 13 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_sketch_structure \"./check_library_structure/SketchFolderNameTooLong\"" {
  run check_sketch_structure "./check_library_structure/SketchFolderNameTooLong"
  [ "$status" -eq 5 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_structure \"./check_library_structure/SketchFolderNameTooLong\"" {
  run check_library_structure "./check_library_structure/SketchFolderNameTooLong"
  [ "$status" -eq 14 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_sketch_structure \"./check_library_structure/SketchFolderNameTooLongExtras\"" {
  run check_sketch_structure "./check_library_structure/SketchFolderNameTooLongExtras"
  [ "$status" -eq 5 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_structure \"./check_library_structure/SketchFolderNameTooLongExtras\"" {
  run check_library_structure "./check_library_structure/SketchFolderNameTooLongExtras"
  [ "$status" -eq 14 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_sketch_structure \"./check_library_structure/SketchFolderNameMismatch\"" {
  run check_sketch_structure "./check_library_structure/SketchFolderNameMismatch"
  [ "$status" -eq 6 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_structure \"./check_library_structure/SketchFolderNameMismatch\"" {
  run check_library_structure "./check_library_structure/SketchFolderNameMismatch"
  [ "$status" -eq 15 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_sketch_structure \"./check_library_structure/MultipleSketchesInSameFolderUnix\"" {
  run check_sketch_structure "./check_library_structure/MultipleSketchesInSameFolderUnix"
  [ "$status" -eq 7 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_structure \"./check_library_structure/MultipleSketchesInSameFolderUnix\"" {
  run check_library_structure "./check_library_structure/MultipleSketchesInSameFolderUnix"
  [ "$status" -eq 16 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_sketch_structure \"./check_library_structure/MultipleSketchesInSameFolderMac\"" {
  run check_sketch_structure "./check_library_structure/MultipleSketchesInSameFolderMac"
  [ "$status" -eq 7 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_structure \"./check_library_structure/MultipleSketchesInSameFolderMac\"" {
  run check_library_structure "./check_library_structure/MultipleSketchesInSameFolderMac"
  [ "$status" -eq 16 ]
  [ "${#lines[@]}" -eq 1 ]
}

# check_library_properties

@test "check_library_properties \"./check_library_properties/ValidLibraryPropertiesUnix\"" {
  run check_library_properties "./check_library_properties/ValidLibraryPropertiesUnix"
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "check_library_properties \"./check_library_properties/ValidLibraryPropertiesWindows\"" {
  run check_library_properties "./check_library_properties/ValidLibraryPropertiesWindows"
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "check_library_properties \"./check_library_properties/ValidLibraryPropertiesMac\"" {
  run check_library_properties "./check_library_properties/ValidLibraryPropertiesMac"
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "check_library_properties \"./check_library_properties/NoLibraryProperties\"" {
  run check_library_properties "./check_library_properties/NoLibraryProperties"
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "check_library_properties \"./check_library_properties/DoesntExist\"" {
  run check_library_properties "./check_library_properties/DoesntExist"
  [ "$status" -eq 1 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/InvalidFilenameCase\"" {
  run check_library_properties "./check_library_properties/InvalidFilenameCase"
  [ "$status" -eq 2 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/MissingName\"" {
  run check_library_properties "./check_library_properties/MissingName"
  [ "$status" -eq 3 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/BOM\"" {
  run check_library_properties "./check_library_properties/BOM"
  # The BOM corrupts the first line, which in this case is the name field
  [ "$status" -eq 3 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/MissingVersion\"" {
  run check_library_properties "./check_library_properties/MissingVersion"
  [ "$status" -eq 4 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/MissingAuthor\"" {
  run check_library_properties "./check_library_properties/MissingAuthor"
  [ "$status" -eq 5 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/EmailInsteadOfMaintainer\"" {
  run check_library_properties "./check_library_properties/EmailInsteadOfMaintainer"
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 1 ]
  warningRegex='^WARNING: Use of undocumented email field'
  [[ "${lines[0]}" =~ $warningRegex ]]
}

@test "check_library_properties \"./check_library_properties/MissingMaintainer\"" {
  run check_library_properties "./check_library_properties/MissingMaintainer"
  [ "$status" -eq 6 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/MissingSentence\"" {
  run check_library_properties "./check_library_properties/MissingSentence"
  [ "$status" -eq 7 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/MissingParagraph\"" {
  run check_library_properties "./check_library_properties/MissingParagraph"
  [ "$status" -eq 8 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/MissingCategory\"" {
  run check_library_properties "./check_library_properties/MissingCategory"
  [ "$status" -eq 9 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/MissingUrl\"" {
  run check_library_properties "./check_library_properties/MissingUrl"
  [ "$status" -eq 10 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/InvalidLine\"" {
  run check_library_properties "./check_library_properties/InvalidLine"
  [ "$status" -eq 11 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/InvalidName\"" {
  run check_library_properties "./check_library_properties/InvalidName"
  [ "$status" -eq 12 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/InvalidVersion\"" {
  run check_library_properties "./check_library_properties/InvalidVersion"
  [ "$status" -eq 13 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/RedundantParagraph\"" {
  run check_library_properties "./check_library_properties/RedundantParagraph"
  [ "$status" -eq 14 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/InvalidCategory\"" {
  run check_library_properties "./check_library_properties/InvalidCategory"
  [ "$status" -eq 15 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/MissingScheme\"" {
  run check_library_properties "./check_library_properties/MissingScheme"
  [ "$status" -eq 16 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/DeadUrl\"" {
  run check_library_properties "./check_library_properties/DeadUrl"
  [ "$status" -eq 17 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/InvalidArchitecture\"" {
  run check_library_properties "./check_library_properties/InvalidArchitecture"
  [ "$status" -eq 18 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/EmptyIncludes\"" {
  run check_library_properties "./check_library_properties/EmptyIncludes"
  [ "$status" -eq 19 ]
  [ "${#lines[@]}" -eq 1 ]
}

# check_keywords_txt

@test "check_keywords_txt \"./check_keywords_txt/ValidKeywordsTxtUnix\" (w/o IDE installed)" {
  run check_keywords_txt "./check_keywords_txt/ValidKeywordsTxtUnix"
  [ "$status" -eq 0 ]
  # One warning is printed for each reference link (currently there are two)
  [ "${#lines[@]}" -eq 2 ]
  IDEnotInstalledRegex='^WARNING: Arduino IDE is not installed'
  [[ "${lines[0]}" =~ $IDEnotInstalledRegex ]]
  [[ "${lines[1]}" =~ $IDEnotInstalledRegex ]]
}

@test "check_keywords_txt \"./check_keywords_txt/ValidKeywordsTxtUnix\" (w/ IDE installed)" {
  run set_application_folder "$TESTS_BATS_APPLICATION_FOLDER"
  # The environment variable set by set_application_folder is not preserved so it must be set here
  ARDUINO_CI_SCRIPT_APPLICATION_FOLDER="$TESTS_BATS_APPLICATION_FOLDER"
  run install_ide "$TESTS_BATS_IDE_VERSION"
  # The environment variable set by install_ide is not preserved so it must be set here
  NEWEST_INSTALLED_IDE_VERSION="$TESTS_BATS_IDE_VERSION"
  run check_keywords_txt "./check_keywords_txt/ValidKeywordsTxtUnix"
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "check_keywords_txt \"./check_keywords_txt/ValidKeywordsTxtWindows\"" {
  run check_keywords_txt "./check_keywords_txt/ValidKeywordsTxtWindows"
  [ "$status" -eq 0 ]
}

@test "check_keywords_txt \"./check_keywords_txt/ValidKeywordsTxtMac\"" {
  run check_keywords_txt "./check_keywords_txt/ValidKeywordsTxtMac"
  [ "$status" -eq 0 ]
}

@test "check_keywords_txt \"./check_keywords_txt/NoKeywordsTxt\"" {
  run check_keywords_txt "./check_keywords_txt/NoKeywordsTxt"
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "check_keywords_txt \"./check_keywords_txt/DoesntExist\"" {
  run check_keywords_txt "./check_keywords_txt/DoesntExist"
  [ "$status" -eq 1 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_keywords_txt \"./check_keywords_txt/IncorrectFilenameCase\"" {
  run check_keywords_txt "./check_keywords_txt/IncorrectFilenameCase"
  [ "$status" -eq 2 ]
}

@test "check_keywords_txt \"./check_keywords_txt/InvalidSeparator\"" {
  run check_keywords_txt "./check_keywords_txt/InvalidSeparator"
  [ "$status" -eq 3 ]
}

@test "check_keywords_txt \"./check_keywords_txt/MultipleTabsError\"" {
  run check_keywords_txt "./check_keywords_txt/MultipleTabsError"
  [ "$status" -eq 4 ]
}

@test "check_keywords_txt \"./check_keywords_txt/MultipleTabsWarning\"" {
  run check_keywords_txt "./check_keywords_txt/MultipleTabsWarning"
  [ "$status" -eq 0 ]
  warningRegex='^WARNING: ./check_keywords_txt/MultipleTabsWarning/keywords.txt uses multiple tabs as field separator.'
  [[ "${lines[0]}" =~ $warningRegex ]]
}

@test "check_keywords_txt \"./check_keywords_txt/InvalidKeywordTokentypeUnix\"" {
  run check_keywords_txt "./check_keywords_txt/InvalidKeywordTokentypeUnix"
  [ "$status" -eq 5 ]
}

@test "check_keywords_txt \"./check_keywords_txt/InvalidKeywordTokentypeWindows\"" {
  run check_keywords_txt "./check_keywords_txt/InvalidKeywordTokentypeWindows"
  [ "$status" -eq 5 ]
}

@test "check_keywords_txt \"./check_keywords_txt/InvalidKeywordTokentypeMac\"" {
  run check_keywords_txt "./check_keywords_txt/InvalidKeywordTokentypeMac"
  [ "$status" -eq 5 ]
}

@test "check_keywords_txt \"./check_keywords_txt/InvalidKeywordTokentypeLastLine\"" {
  run check_keywords_txt "./check_keywords_txt/InvalidKeywordTokentypeLastLine"
  [ "$status" -eq 5 ]
  errorRegex='^ERROR: \./check_keywords_txt/InvalidKeywordTokentypeLastLine/keywords.txt uses invalid KEYWORD_TOKENTYPE: KEYWORD1x'
  [[ "${lines[2]}" =~ $errorRegex ]]
}

@test "check_keywords_txt \"./check_keywords_txt/InvalidRsyntaxtextareaTokentype\"" {
  run check_keywords_txt "./check_keywords_txt/InvalidRsyntaxtextareaTokentype"
  [ "$status" -eq 6 ]
  errorRegex='^ERROR: \./check_keywords_txt/InvalidRsyntaxtextareaTokentype/keywords.txt uses invalid RSYNTAXTEXTAREA_TOKENTYPE: xRESERVED_WORD'
  [[ "${lines[1]}" =~ $errorRegex ]]
}

@test "check_keywords_txt \"./check_keywords_txt/InvalidRsyntaxtextareaTokentypeNoReferenceLink\"" {
  run check_keywords_txt "./check_keywords_txt/InvalidRsyntaxtextareaTokentypeNoReferenceLink"
  [ "$status" -eq 6 ]
  errorRegex='^ERROR: \./check_keywords_txt/InvalidRsyntaxtextareaTokentypeNoReferenceLink/keywords.txt uses invalid RSYNTAXTEXTAREA_TOKENTYPE: RESERVED_WORDx'
  [[ "${lines[1]}" =~ $errorRegex ]]
}

@test "check_keywords_txt \"./check_keywords_txt/InvalidReferenceLink\"" {
  run set_application_folder "$TESTS_BATS_APPLICATION_FOLDER"
  # The environment variable set by set_application_folder is not preserved so it must be set here
  ARDUINO_CI_SCRIPT_APPLICATION_FOLDER="$TESTS_BATS_APPLICATION_FOLDER"
  run install_ide "$TESTS_BATS_IDE_VERSION"
  # The environment variable set by install_ide is not preserved so it must be set here
  NEWEST_INSTALLED_IDE_VERSION="$TESTS_BATS_IDE_VERSION"
  run check_keywords_txt "./check_keywords_txt/InvalidReferenceLink"
  [ "$status" -eq 7 ]
  [ "${#lines[@]}" -eq 1 ]
}

# check_library_manager_compliance

@test "check_library_manager_compliance \"./check_library_manager_compliance/ValidLibrary\"" {
  run check_library_manager_compliance "./check_library_manager_compliance/ValidLibrary"
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "check_library_manager_compliance \"./check_library_manager_compliance/DoesntExist\"" {
  run check_library_manager_compliance "./check_library_manager_compliance/DoesntExist"
  [ "$status" -eq 1 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_manager_compliance \"./check_library_manager_compliance/ContainsExe\"" {
  run check_library_manager_compliance "./check_library_manager_compliance/ContainsExe"
  [ "$status" -eq 2 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_manager_compliance \"./check_library_manager_compliance/ContainsDotDevelopment\"" {
  run check_library_manager_compliance "./check_library_manager_compliance/ContainsDotDevelopment"
  [ "$status" -eq 3 ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_manager_compliance \"./check_library_manager_compliance/ContainsSymlink\"" {
  run check_library_manager_compliance "./check_library_manager_compliance/ContainsSymlink"
  [ "$status" -eq 4 ]
  [ "${#lines[@]}" -eq 1 ]
}
