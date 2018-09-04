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

@test "check_library_properties \"./check_library_properties/MultipleValidLibraryProperties\" 1" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_library_properties "./check_library_properties/MultipleValidLibraryProperties" 1
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "check_library_properties \"./check_library_properties/InvalidLibraryPropertiesBelowMaximumSearchDepth\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_library_properties "./check_library_properties/InvalidLibraryPropertiesBelowMaximumSearchDepth"
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

@test "check_library_properties \"./check_library_properties/MisspelledFilename\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_MISSPELLED_FILENAME_EXIT_STATUS
  run check_library_properties "./check_library_properties/MisspelledFilename"
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

@test "check_library_properties \"./check_library_properties/MultipleInvalidLibraryProperties\" 1" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_MISSING_NAME_EXIT_STATUS
  run check_library_properties "./check_library_properties/MultipleInvalidLibraryProperties" 1
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

@test "check_library_properties \"./check_library_properties/BlankName\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_BLANK_NAME
  run check_library_properties "./check_library_properties/BlankName"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
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

@test "check_library_properties \"./check_library_properties/ProblematicGoogleUrl\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_library_properties "./check_library_properties/ProblematicGoogleUrl"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "check_library_properties \"./check_library_properties/ProblematicMicrosoftUrl\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_library_properties "./check_library_properties/ProblematicMicrosoftUrl"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "check_library_properties \"./check_library_properties/IncorrectArchitecturesFieldCase\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_ARCHITECTURES_MISSPELLED_EXIT_STATUS
  run check_library_properties "./check_library_properties/IncorrectArchitecturesFieldCase"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 2 ]
  warningRegex="^WARNING: \./check_library_properties/IncorrectArchitecturesFieldCase is missing the architectures field\."
  [[ "${lines[1]}" =~ $warningRegex ]]
}

@test "check_library_properties \"./check_library_properties/ArchitecturesMisspelled\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_ARCHITECTURES_MISSPELLED_EXIT_STATUS
  run check_library_properties "./check_library_properties/ArchitecturesMisspelled"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 2 ]
  warningRegex="^WARNING: \./check_library_properties/ArchitecturesMisspelled is missing the architectures field."
  [[ "${lines[1]}" =~ $warningRegex ]]
}

@test "check_library_properties \"./check_library_properties/ArchitecturesEmpty\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_ARCHITECTURES_EMPTY_EXIT_STATUS
  run check_library_properties "./check_library_properties/ArchitecturesEmpty"
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

@test "check_library_properties \"./check_library_properties/IncorrectIncludesFieldCase\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_INCLUDES_MISSPELLED_EXIT_STATUS
  run check_library_properties "./check_library_properties/IncorrectIncludesFieldCase"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/IncludeField\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_INCLUDES_MISSPELLED_EXIT_STATUS
  run check_library_properties "./check_library_properties/IncludeField"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/EmptyIncludes\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_EMPTY_INCLUDES_EXIT_STATUS
  run check_library_properties "./check_library_properties/EmptyIncludes"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/IncorrectDotAlinkageFieldCase\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_DOT_A_LINKAGE_MISSPELLED_EXIT_STATUS
  run check_library_properties "./check_library_properties/IncorrectDotAlinkageFieldCase"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/DotAlinkagesField\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_DOT_A_LINKAGE_MISSPELLED_EXIT_STATUS
  run check_library_properties "./check_library_properties/DotAlinkagesField"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/IncorrectPrecompiledFieldCase\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_PRECOMPILED_MISSPELLED_EXIT_STATUS
  run check_library_properties "./check_library_properties/IncorrectPrecompiledFieldCase"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/PrecompileField\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_PRECOMPILED_MISSPELLED_EXIT_STATUS
  run check_library_properties "./check_library_properties/PrecompileField"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/IncorrectLdflagsFieldCase\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_LDFLAGS_MISSPELLED_EXIT_STATUS
  run check_library_properties "./check_library_properties/IncorrectLdflagsFieldCase"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_library_properties \"./check_library_properties/LdflagField\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_LDFLAGS_MISSPELLED_EXIT_STATUS
  run check_library_properties "./check_library_properties/LdflagField"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}
