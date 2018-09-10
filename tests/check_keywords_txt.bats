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
  outputRegex='^WARNING: Arduino IDE is not installed so unable to check for invalid reference links\. Please call install_ide before running check_keywords_txt\.$'
  [[ "${lines[0]}" =~ $outputRegex ]]
  [[ "${lines[1]}" =~ $outputRegex ]]
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
  [ "${#lines[@]}" -eq 2 ]
  outputRegex='^WARNING: Arduino IDE is not installed so unable to check for invalid reference links\. Please call install_ide before running check_keywords_txt\.$'
  [[ "${lines[0]}" =~ $outputRegex ]]
  [[ "${lines[1]}" =~ $outputRegex ]]
}

@test "check_keywords_txt \"./check_keywords_txt/ValidKeywordsTxtMac\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/ValidKeywordsTxtMac"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 2 ]
  outputRegex='^WARNING: Arduino IDE is not installed so unable to check for invalid reference links\. Please call install_ide before running check_keywords_txt\.$'
  [[ "${lines[0]}" =~ $outputRegex ]]
  [[ "${lines[1]}" =~ $outputRegex ]]
}

@test "check_keywords_txt \"./check_keywords_txt/MultipleValidKeywordsTxt\" 1" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/MultipleValidKeywordsTxt" 1
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 4 ]
  outputRegex='^WARNING: Arduino IDE is not installed so unable to check for invalid reference links\. Please call install_ide before running check_keywords_txt\.$'
  [[ "${lines[0]}" =~ $outputRegex ]]
  [[ "${lines[1]}" =~ $outputRegex ]]
  [[ "${lines[2]}" =~ $outputRegex ]]
  [[ "${lines[3]}" =~ $outputRegex ]]
}

@test "check_keywords_txt \"./check_keywords_txt/InvalidKeywordsTxtBelowMaximumSearchDepth\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/InvalidKeywordsTxtBelowMaximumSearchDepth"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 2 ]
  outputRegex='^WARNING: Arduino IDE is not installed so unable to check for invalid reference links\. Please call install_ide before running check_keywords_txt\.$'
  [[ "${lines[0]}" =~ $outputRegex ]]
  [[ "${lines[1]}" =~ $outputRegex ]]
}

@test "check_keywords_txt \"./check_keywords_txt/NoKeywordsTxt\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/NoKeywordsTxt"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 0 ]
}

@test "check_keywords_txt \"./check_keywords_txt/BOMcorruptedBlankLine\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/BOMcorruptedBlankLine"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 3 ]
  outputRegex='^WARNING: BOM found'
  [[ "${lines[0]}" =~ $outputRegex ]]
  outputRegex='^WARNING: Arduino IDE is not installed so unable to check for invalid reference links\. Please call install_ide before running check_keywords_txt\.$'
  [[ "${lines[1]}" =~ $outputRegex ]]
  [[ "${lines[2]}" =~ $outputRegex ]]
}

@test "check_keywords_txt \"./check_keywords_txt/BOMcorruptedComment\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/BOMcorruptedComment"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 3 ]
  outputRegex='^WARNING: BOM found'
  [[ "${lines[0]}" =~ $outputRegex ]]
  outputRegex='^WARNING: Arduino IDE is not installed so unable to check for invalid reference links\. Please call install_ide before running check_keywords_txt\.$'
  [[ "${lines[1]}" =~ $outputRegex ]]
  [[ "${lines[2]}" =~ $outputRegex ]]
}

@test "check_keywords_txt \"./check_keywords_txt/DoesntExist\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_KEYWORDS_TXT_FOLDER_DOESNT_EXIST_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/DoesntExist"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex="^ERROR: Specified folder: \./check_keywords_txt/DoesntExist doesn't exist\.$"
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_keywords_txt \"./check_keywords_txt/MisspelledFilename\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_KEYWORDS_TXT_MISSPELLED_FILENAME_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/MisspelledFilename"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^ERROR: \./check_keywords_txt/MisspelledFilename contains an incorrectly spelled keywords\.txt file.$'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_keywords_txt \"./check_keywords_txt/IncorrectFilenameCase\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_KEYWORDS_TXT_INCORRECT_FILENAME_CASE_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/IncorrectFilenameCase"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^ERROR: \./check_keywords_txt/IncorrectFilenameCase/Keywords\.txt has incorrect filename case, which causes it to not be recognized on a filename case-sensitive OS such as Linux\. It must be exactly keywords\.txt$'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_keywords_txt \"./check_keywords_txt/InvalidSeparator\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_KEYWORDS_TXT_INVALID_FIELD_SEPARATOR_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/InvalidSeparator"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 3 ]
  outputRegex='^ERROR: \./check_keywords_txt/InvalidSeparator \(k1 KEYWORD1\) uses space\(s\) as a field separator\. It must be a true tab\.$'
  [[ "${lines[0]}" =~ $outputRegex ]]
  outputRegex='^WARNING: Arduino IDE is not installed so unable to check for invalid reference links\. Please call install_ide before running check_keywords_txt\.$'
  [[ "${lines[1]}" =~ $outputRegex ]]
  [[ "${lines[2]}" =~ $outputRegex ]]
}

@test "check_keywords_txt \"./check_keywords_txt/MultipleInvalidKeywordsTxt\" 1" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_KEYWORDS_TXT_INVALID_FIELD_SEPARATOR_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/MultipleInvalidKeywordsTxt" 1
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 5 ]
  outputRegex='^ERROR: \./check_keywords_txt/MultipleInvalidKeywordsTxt/InvalidSeparator \(k1 KEYWORD1\) uses space\(s\) as a field separator\. It must be a true tab\.$'
  [[ "${lines[0]}" =~ $outputRegex ]]
  outputRegex='^WARNING: Arduino IDE is not installed so unable to check for invalid reference links\. Please call install_ide before running check_keywords_txt\.$'
  [[ "${lines[1]}" =~ $outputRegex ]]
  [[ "${lines[2]}" =~ $outputRegex ]]
  [[ "${lines[3]}" =~ $outputRegex ]]
  [[ "${lines[4]}" =~ $outputRegex ]]
}

@test "check_keywords_txt \"./check_keywords_txt/ConsequentialMultipleTabs\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_KEYWORDS_TXT_MULTIPLE_TABS_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/ConsequentialMultipleTabs"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 3 ]
  outputRegex='^ERROR: \./check_keywords_txt/ConsequentialMultipleTabs \(k1		KEYWORD1\) uses multiple tabs as field separator\. It must be a single tab\. This causes the default keyword highlighting \(as used by KEYWORD2, KEYWORD3, LITERAL2\) to be used rather than the intended highlighting\.$'
  [[ "${lines[0]}" =~ $outputRegex ]]
  outputRegex='^WARNING: Arduino IDE is not installed so unable to check for invalid reference links\. Please call install_ide before running check_keywords_txt\.$'
  [[ "${lines[1]}" =~ $outputRegex ]]
  [[ "${lines[2]}" =~ $outputRegex ]]
}

@test "check_keywords_txt \"./check_keywords_txt/InconsequentialMultipleTabs\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_KEYWORDS_TXT_INCONSEQUENTIAL_MULTIPLE_TABS_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/InconsequentialMultipleTabs"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 3 ]
  outputRegex="^ERROR: \./check_keywords_txt/InconsequentialMultipleTabs \(k3		KEYWORD2\) uses multiple tabs as field separator\. It must be a single tab\. This causes the default keyword highlighting \(as used by KEYWORD2, KEYWORD3, LITERAL2\)\. In this case that doesn't cause the keywords to be incorrectly colored as expected but it's recommended to fully comply with the Arduino library specification\.$"
  [[ "${lines[0]}" =~ $outputRegex ]]
  outputRegex='^WARNING: Arduino IDE is not installed so unable to check for invalid reference links\. Please call install_ide before running check_keywords_txt\.$'
  [[ "${lines[1]}" =~ $outputRegex ]]
  [[ "${lines[2]}" =~ $outputRegex ]]
}

@test "check_keywords_txt \"./check_keywords_txt/InvalidLine\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_KEYWORDS_TXT_INVALID_LINE_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/InvalidLine"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 3 ]
  outputRegex='^WARNING: Arduino IDE is not installed so unable to check for invalid reference links\. Please call install_ide before running check_keywords_txt\.$'
  [[ "${lines[0]}" =~ $outputRegex ]]
  [[ "${lines[1]}" =~ $outputRegex ]]
  outputRegex='^ERROR: \./check_keywords_txt/InvalidLine has an invalid line: invalidLine\. If this was intended as a comment, it should use the correct # syntax\.$'
  [[ "${lines[2]}" =~ $outputRegex ]]
}

@test "check_keywords_txt \"./check_keywords_txt/BOMcorruptedKeyword\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_KEYWORDS_TXT_BOM_CORRUPTED_KEYWORD_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/BOMcorruptedKeyword"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 3 ]
  outputRegex='^ERROR: \./check_keywords_txt/BOMcorruptedKeyword uses UTF-8 BOM file encoding, which has corrupted the first keyword definition\. Please change the file encoding to standard UTF-8\.$'
  [[ "${lines[0]}" =~ $outputRegex ]]
  outputRegex='^WARNING: Arduino IDE is not installed so unable to check for invalid reference links\. Please call install_ide before running check_keywords_txt\.$'
  [[ "${lines[1]}" =~ $outputRegex ]]
  [[ "${lines[2]}" =~ $outputRegex ]]
}

@test "check_keywords_txt \"./check_keywords_txt/InvalidKeyword\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_KEYWORDS_TXT_INVALID_KEYWORD_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/InvalidKeyword"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 3 ]
  outputRegex='^ERROR: Keyword k::3 in \./check_keywords_txt/InvalidKeyword contains invalid character\(s\), which causes it to not be recognized by the Arduino IDE\. Keywords may only contain the characters a-z, A-Z, 0-9, and _\.$'
  [[ "${lines[0]}" =~ $outputRegex ]]
  outputRegex='^WARNING: Arduino IDE is not installed so unable to check for invalid reference links\. Please call install_ide before running check_keywords_txt\.$'
  [[ "${lines[1]}" =~ $outputRegex ]]
  [[ "${lines[2]}" =~ $outputRegex ]]
}

@test "check_keywords_txt \"./check_keywords_txt/InconsequentialLeadingSpaceOnKeywordTokentype\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_KEYWORDS_TXT_INCONSEQUENTIAL_LEADING_SPACE_ON_KEYWORD_TOKENTYPE_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/InconsequentialLeadingSpaceOnKeywordTokentype"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 3 ]
  outputRegex="^ERROR: \./check_keywords_txt/InconsequentialLeadingSpaceOnKeywordTokentype \(k3	 KEYWORD2\) has leading space on the KEYWORD_TOKENTYPE field, which causes it to not be recognized, so the default keyword highlighting is used\.  In this case that doesn't cause the keywords to be incorrectly colored as expected but it's recommended to fully comply with the Arduino library specification\.$"
  [[ "${lines[0]}" =~ $outputRegex ]]
  outputRegex='^WARNING: Arduino IDE is not installed so unable to check for invalid reference links\. Please call install_ide before running check_keywords_txt\.$'
  [[ "${lines[1]}" =~ $outputRegex ]]
  [[ "${lines[2]}" =~ $outputRegex ]]
}

@test "check_keywords_txt \"./check_keywords_txt/ConsequentialLeadingSpaceOnKeywordTokentype\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_KEYWORDS_TXT_LEADING_SPACE_ON_KEYWORD_TOKENTYPE_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/ConsequentialLeadingSpaceOnKeywordTokentype"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 3 ]
  outputRegex='^ERROR: \./check_keywords_txt/ConsequentialLeadingSpaceOnKeywordTokentype \(l1	 LITERAL1\) has leading space on the KEYWORD_TOKENTYPE field, which causes it to not be recognized, so the default keyword highlighting is used\.$'
  [[ "${lines[0]}" =~ $outputRegex ]]
  outputRegex='^WARNING: Arduino IDE is not installed so unable to check for invalid reference links\. Please call install_ide before running check_keywords_txt\.$'
  [[ "${lines[1]}" =~ $outputRegex ]]
  [[ "${lines[2]}" =~ $outputRegex ]]
}

@test "check_keywords_txt \"./check_keywords_txt/InvalidKeywordTokentypeUnix\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_KEYWORDS_TXT_INVALID_KEYWORD_TOKENTYPE_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/InvalidKeywordTokentypeUnix"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 3 ]
  outputRegex='^ERROR: \./check_keywords_txt/InvalidKeywordTokentypeUnix \(k1	KEYWORD1x\) uses invalid KEYWORD_TOKENTYPE: KEYWORD1x, which causes the default keyword highlighting to be used\. See: https://github.com/arduino/Arduino/wiki/Arduino-IDE-1.5:-Library-specification#keyword_tokentype$'
  [[ "${lines[0]}" =~ $outputRegex ]]
  outputRegex='^WARNING: Arduino IDE is not installed so unable to check for invalid reference links\. Please call install_ide before running check_keywords_txt\.$'
  [[ "${lines[1]}" =~ $outputRegex ]]
  [[ "${lines[2]}" =~ $outputRegex ]]
}

@test "check_keywords_txt \"./check_keywords_txt/InvalidKeywordTokentypeWindows\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_KEYWORDS_TXT_INVALID_KEYWORD_TOKENTYPE_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/InvalidKeywordTokentypeWindows"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 3 ]
  outputRegex='^ERROR: \./check_keywords_txt/InvalidKeywordTokentypeWindows \(k1	KEYWORD1x\) uses invalid KEYWORD_TOKENTYPE: KEYWORD1x, which causes the default keyword highlighting to be used\. See: https://github.com/arduino/Arduino/wiki/Arduino-IDE-1.5:-Library-specification#keyword_tokentype$'
  [[ "${lines[0]}" =~ $outputRegex ]]
  outputRegex='^WARNING: Arduino IDE is not installed so unable to check for invalid reference links\. Please call install_ide before running check_keywords_txt\.$'
  [[ "${lines[1]}" =~ $outputRegex ]]
  [[ "${lines[2]}" =~ $outputRegex ]]
}

@test "check_keywords_txt \"./check_keywords_txt/InvalidKeywordTokentypeMac\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_KEYWORDS_TXT_INVALID_KEYWORD_TOKENTYPE_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/InvalidKeywordTokentypeMac"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 3 ]
  outputRegex='^ERROR: \./check_keywords_txt/InvalidKeywordTokentypeMac \(k1	KEYWORD1x\) uses invalid KEYWORD_TOKENTYPE: KEYWORD1x, which causes the default keyword highlighting to be used\. See: https://github.com/arduino/Arduino/wiki/Arduino-IDE-1.5:-Library-specification#keyword_tokentype$'
  [[ "${lines[0]}" =~ $outputRegex ]]
  outputRegex='^WARNING: Arduino IDE is not installed so unable to check for invalid reference links\. Please call install_ide before running check_keywords_txt\.$'
  [[ "${lines[1]}" =~ $outputRegex ]]
  [[ "${lines[2]}" =~ $outputRegex ]]
}

@test "check_keywords_txt \"./check_keywords_txt/InvalidKeywordTokentypeLastLine\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_KEYWORDS_TXT_INVALID_KEYWORD_TOKENTYPE_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/InvalidKeywordTokentypeLastLine"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 3 ]
  outputRegex='^WARNING: Arduino IDE is not installed so unable to check for invalid reference links\. Please call install_ide before running check_keywords_txt\.$'
  [[ "${lines[0]}" =~ $outputRegex ]]
  [[ "${lines[1]}" =~ $outputRegex ]]
  outputRegex='^ERROR: \./check_keywords_txt/InvalidKeywordTokentypeLastLine \(k1	KEYWORD1x\) uses invalid KEYWORD_TOKENTYPE: KEYWORD1x, which causes the default keyword highlighting to be used\. See: https://github.com/arduino/Arduino/wiki/Arduino-IDE-1.5:-Library-specification#keyword_tokentype$'
  [[ "${lines[2]}" =~ $outputRegex ]]
  }

@test "check_keywords_txt \"./check_keywords_txt/LeadingSpaceOnRsyntaxtextareaTokentype\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_KEYWORDS_TXT_LEADING_SPACE_ON_RSYNTAXTEXTAREA_TOKENTYPE_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/LeadingSpaceOnRsyntaxtextareaTokentype"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 3 ]
  outputRegex='^WARNING: Arduino IDE is not installed so unable to check for invalid reference links\. Please call install_ide before running check_keywords_txt\.$'
  [[ "${lines[0]}" =~ $outputRegex ]]
  [[ "${lines[1]}" =~ $outputRegex ]]
  outputRegex='^ERROR: \./check_keywords_txt/LeadingSpaceOnRsyntaxtextareaTokentype \(rw	KEYWORD1		 RESERVED_WORD\) has leading space on the RSYNTAXTEXTAREA_TOKENTYPE field, which causes it to not be recognized, so the default keyword highlighting is used.$'
  [[ "${lines[2]}" =~ $outputRegex ]]
}

@test "check_keywords_txt \"./check_keywords_txt/InvalidRsyntaxtextareaTokentype\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_KEYWORDS_TXT_INVALID_RSYNTAXTEXTAREA_TOKENTYPE_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/InvalidRsyntaxtextareaTokentype"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 3 ]
  outputRegex='^WARNING: Arduino IDE is not installed so unable to check for invalid reference links\. Please call install_ide before running check_keywords_txt\.$'
  [[ "${lines[0]}" =~ $outputRegex ]]
  [[ "${lines[1]}" =~ $outputRegex ]]
  outputRegex='^ERROR: \./check_keywords_txt/InvalidRsyntaxtextareaTokentype \(ref2	KEYWORD1	AnalogRead	xRESERVED_WORD\) uses invalid RSYNTAXTEXTAREA_TOKENTYPE: xRESERVED_WORD, which causes the default keyword highlighting to be used\. See: https://github.com/arduino/Arduino/wiki/Arduino-IDE-1.5:-Library-specification#rsyntaxtextarea_tokentype$'
  [[ "${lines[2]}" =~ $outputRegex ]]
}

@test "check_keywords_txt \"./check_keywords_txt/InvalidRsyntaxtextareaTokentypeNoReferenceLink\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_KEYWORDS_TXT_INVALID_RSYNTAXTEXTAREA_TOKENTYPE_EXIT_STATUS
  run check_keywords_txt "./check_keywords_txt/InvalidRsyntaxtextareaTokentypeNoReferenceLink"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 2 ]
  outputRegex='^WARNING: Arduino IDE is not installed so unable to check for invalid reference links\. Please call install_ide before running check_keywords_txt\.$'
  [[ "${lines[0]}" =~ $outputRegex ]]
  outputRegex='^ERROR: \./check_keywords_txt/InvalidRsyntaxtextareaTokentypeNoReferenceLink \(ref2	KEYWORD1		RESERVED_WORDx\) uses invalid RSYNTAXTEXTAREA_TOKENTYPE: RESERVED_WORDx, which causes the default keyword highlighting to be used\. See: https://github.com/arduino/Arduino/wiki/Arduino-IDE-1.5:-Library-specification#rsyntaxtextarea_tokentype$'
  [[ "${lines[1]}" =~ $outputRegex ]]
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
  outputRegex='^ERROR: \./check_keywords_txt/InvalidReferenceLink \(ref2	KEYWORD1	AnalogReadx	RESERVED_WORD\) uses a REFERENCE_LINK value: AnalogReadx that is not a valid Arduino Language Reference page\. See: https://github.com/arduino/Arduino/wiki/Arduino-IDE-1.5:-Library-specification#reference_link$'
  [[ "${lines[0]}" =~ $outputRegex ]]
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
  outputRegex='^ERROR: \./check_keywords_txt/IncorrectCaseReferenceLink \(ref2	KEYWORD1	Analogread	RESERVED_WORD\) uses a REFERENCE_LINK value: Analogread that is not a valid Arduino Language Reference page\. See: https://github.com/arduino/Arduino/wiki/Arduino-IDE-1.5:-Library-specification#reference_link$'
  [[ "${lines[0]}" =~ $outputRegex ]]
}
