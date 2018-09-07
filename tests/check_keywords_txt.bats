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
  [ "${#lines[@]}" -eq 1 ]
  warningRegex='^WARNING: Specified folder: \./check_keywords_txt/NoKeywordsTxt doesn'\''t contain a keywords\.txt file\.'
  [[ "${lines[0]}" =~ $warningRegex ]]
}

@test "check_keywords_txt \"./check_keywords_txt/BOMcorruptedBlankLine\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/BOMcorruptedBlankLine"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
}

@test "check_keywords_txt \"./check_keywords_txt/BOMcorruptedComment\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/BOMcorruptedComment"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
}

@test "check_keywords_txt \"./check_keywords_txt/DoesntExist\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_KEYWORDS_TXT_FOLDER_DOESNT_EXIST_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/DoesntExist"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "check_keywords_txt \"./check_keywords_txt/MisspelledFilename\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_KEYWORDS_TXT_MISSPELLED_FILENAME_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/MisspelledFilename"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 2 ]
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

@test "check_keywords_txt \"./check_keywords_txt/InvalidKeyword\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_KEYWORDS_TXT_INVALID_KEYWORD_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/InvalidKeyword"
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
