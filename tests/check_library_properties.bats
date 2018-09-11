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
  outputRegex="^ERROR: Specified folder: \./check_library_properties/DoesntExist doesn't exist\.$"
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_library_properties \"./check_library_properties/MisspelledFilename\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_MISSPELLED_FILENAME_EXIT_STATUS
  run check_library_properties "./check_library_properties/MisspelledFilename"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^ERROR: \./check_library_properties/MisspelledFilename contains an incorrectly spelled library\.properties file\.$'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_library_properties \"./check_library_properties/InvalidFilenameCase\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_INCORRECT_FILENAME_CASE_EXIT_STATUS
  run check_library_properties "./check_library_properties/InvalidFilenameCase"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^ERROR: \./check_library_properties/InvalidFilenameCase/Library\.properties has incorrect filename case, which causes it to not be recognized on a filename case-sensitive OS such as Linux\. It must be exactly library\.properties$'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_library_properties \"./check_library_properties/MissingName\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_MISSING_NAME_EXIT_STATUS
  run check_library_properties "./check_library_properties/MissingName"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^ERROR: \./check_library_properties/MissingName is missing the required name field\. See https://github.com/arduino/Arduino/wiki/Arduino-IDE-1\.5:-Library-specification#libraryproperties-file-format$'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_library_properties \"./check_library_properties/MultipleInvalidLibraryProperties\" 1" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_MISSING_NAME_EXIT_STATUS
  run check_library_properties "./check_library_properties/MultipleInvalidLibraryProperties" 1
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^ERROR: \./check_library_properties/MultipleInvalidLibraryProperties/MissingName is missing the required name field\. See https://github.com/arduino/Arduino/wiki/Arduino-IDE-1\.5:-Library-specification#libraryproperties-file-format$'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_library_properties \"./check_library_properties/BOM\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_MISSING_NAME_EXIT_STATUS
  run check_library_properties "./check_library_properties/BOM"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  # The BOM corrupts the first line, which in this case is the name field
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^ERROR: \./check_library_properties/BOM is missing the required name field\. See https://github.com/arduino/Arduino/wiki/Arduino-IDE-1\.5:-Library-specification#libraryproperties-file-format$'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_library_properties \"./check_library_properties/MissingVersion\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_MISSING_VERSION_EXIT_STATUS
  run check_library_properties "./check_library_properties/MissingVersion"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^ERROR: \./check_library_properties/MissingVersion is the missing the required version field\. See https://github.com/arduino/Arduino/wiki/Arduino-IDE-1\.5:-Library-specification#libraryproperties-file-format$'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_library_properties \"./check_library_properties/MissingAuthor\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_MISSING_AUTHOR_EXIT_STATUS
  run check_library_properties "./check_library_properties/MissingAuthor"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^ERROR: \./check_library_properties/MissingAuthor is missing the required author field\. See https://github.com/arduino/Arduino/wiki/Arduino-IDE-1\.5:-Library-specification#libraryproperties-file-format$'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_library_properties \"./check_library_properties/EmailInsteadOfMaintainer\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_library_properties "./check_library_properties/EmailInsteadOfMaintainer"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex="^WARNING: Use of undocumented email field in \./check_library_properties/EmailInsteadOfMaintainer\. It's recommended to use the maintainer field instead, per the Arduino Library Specification\. See https://github.com/arduino/Arduino/wiki/Arduino-IDE-1\.5:-Library-specification#libraryproperties-file-format$"
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_library_properties \"./check_library_properties/MissingMaintainer\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_MISSING_MAINTAINER_EXIT_STATUS
  run check_library_properties "./check_library_properties/MissingMaintainer"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^ERROR: \./check_library_properties/MissingMaintainer is missing the required maintainer field\. See https://github.com/arduino/Arduino/wiki/Arduino-IDE-1\.5:-Library-specification#libraryproperties-file-format$'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_library_properties \"./check_library_properties/MissingSentence\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_MISSING_SENTENCE_EXIT_STATUS
  run check_library_properties "./check_library_properties/MissingSentence"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^ERROR: \./check_library_properties/MissingSentence is missing tne required sentence field\. See https://github.com/arduino/Arduino/wiki/Arduino-IDE-1\.5:-Library-specification#libraryproperties-file-format$'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_library_properties \"./check_library_properties/MissingParagraph\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_MISSING_PARAGRAPH_EXIT_STATUS
  run check_library_properties "./check_library_properties/MissingParagraph"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^ERROR: \./check_library_properties/MissingParagraph is missing the required paragraph field\. See https://github.com/arduino/Arduino/wiki/Arduino-IDE-1\.5:-Library-specification#libraryproperties-file-format$'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_library_properties \"./check_library_properties/MissingCategory\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_MISSING_CATEGORY_EXIT_STATUS
  run check_library_properties "./check_library_properties/MissingCategory"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^ERROR: \./check_library_properties/MissingCategory is missing the category field\. This results in an invalid category warning\. See https://github.com/arduino/Arduino/wiki/Arduino-IDE-1\.5:-Library-specification#libraryproperties-file-format$'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_library_properties \"./check_library_properties/MissingUrl\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_MISSING_URL_EXIT_STATUS
  run check_library_properties "./check_library_properties/MissingUrl"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^ERROR: \./check_library_properties/MissingUrl is missing the required url field\. See https://github.com/arduino/Arduino/wiki/Arduino-IDE-1\.5:-Library-specification#libraryproperties-file-format$'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_library_properties \"./check_library_properties/MissingArchitectures\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_library_properties "./check_library_properties/MissingArchitectures"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^WARNING: \./check_library_properties/MissingArchitectures is missing the architectures field\. This causes the Arduino IDE to assume the library is compatible with all architectures \(\*\)\. See https://github.com/arduino/Arduino/wiki/Arduino-IDE-1\.5:-Library-specification#libraryproperties-file-format$'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_library_properties \"./check_library_properties/InvalidLine\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_INVALID_LINE_EXIT_STATUS
  run check_library_properties "./check_library_properties/InvalidLine"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^ERROR: \./check_library_properties/InvalidLine contains an invalid line\. Installation of a library with invalid line will cause all compilations to fail\. library\.properties must only consist of property definitions, blank lines, and comments \(#\)\.$'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_library_properties \"./check_library_properties/BlankName\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_BLANK_NAME
  run check_library_properties "./check_library_properties/BlankName"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex="^ERROR: \./check_library_properties/BlankName's has an blank name value\.$"
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_library_properties \"./check_library_properties/InvalidVersion\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_INVALID_VERSION_EXIT_STATUS
  run check_library_properties "./check_library_properties/InvalidVersion"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^ERROR: \./check_library_properties/InvalidVersion has an invalid version value\. Follow the semver specification: https://semver\.org$'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_library_properties \"./check_library_properties/RedundantParagraph\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_REDUNDANT_PARAGRAPH_EXIT_STATUS
  run check_library_properties "./check_library_properties/RedundantParagraph"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex="^ERROR: \./check_library_properties/RedundantParagraph's paragraph value repeats the sentence\. These strings are displayed one after the other in Library Manager so there is no point in redundancy.$"
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_library_properties \"./check_library_properties/InvalidCategory\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_INVALID_CATEGORY_EXIT_STATUS
  run check_library_properties "./check_library_properties/InvalidCategory"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^ERROR: \./check_library_properties/InvalidCategory has an invalid category value\. Please chose a valid category from https://github.com/arduino/Arduino/wiki/Arduino-IDE-1\.5:-Library-specification#libraryproperties-file-format$'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_library_properties \"./check_library_properties/UncategorizedCategory\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_library_properties "./check_library_properties/UncategorizedCategory"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex="^WARNING: category 'Uncategorized' used in \./check_library_properties/UncategorizedCategory is not recommended\. Please chose an appropriate category from https://github.com/arduino/Arduino/wiki/Arduino-IDE-1\.5:-Library-specification#libraryproperties-file-format$"
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_library_properties \"./check_library_properties/BlankUrl\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_URL_BLANK_EXIT_STATUS
  run check_library_properties "./check_library_properties/BlankUrl"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^ERROR: \./check_library_properties/BlankUrl does not define the url field\. This results in a "More info" link in Library Manager that looks clickable but is not\.$'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_library_properties \"./check_library_properties/MissingScheme\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_URL_MISSING_SCHEME_EXIT_STATUS
  run check_library_properties "./check_library_properties/MissingScheme"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex="^ERROR: \./check_library_properties/MissingScheme's url value github\.com/arduino/Arduino is missing the scheme \(e\.g\. https://\)\. URL scheme must be specified for Library Manager's \"More info\" link to be clickable\.$"
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_library_properties \"./check_library_properties/DeadUrl\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_DEAD_URL_EXIT_STATUS
  run check_library_properties "./check_library_properties/DeadUrl"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex="^ERROR: \./check_library_properties/DeadUrl's url value https://foobar\.example\.com/ returned error status 000\.$"
  [[ "${lines[0]}" =~ $outputRegex ]]
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
  outputRegex="^ERROR: \./check_library_properties/IncorrectArchitecturesFieldCase's architectures field name has incorrect case\. It must be spelled exactly architectures\. See https://github.com/arduino/Arduino/wiki/Arduino-IDE-1\.5:-Library-specification#libraryproperties-file-format$"
  [[ "${lines[0]}" =~ $outputRegex ]]
  outputRegex="^WARNING: \./check_library_properties/IncorrectArchitecturesFieldCase is missing the architectures field\. This causes the Arduino IDE to assume the library is compatible with all architectures \(\*\)\. See https://github.com/arduino/Arduino/wiki/Arduino-IDE-1\.5:-Library-specification#libraryproperties-file-format$"
  [[ "${lines[1]}" =~ $outputRegex ]]
}

@test "check_library_properties \"./check_library_properties/ArchitecturesMisspelled\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_ARCHITECTURES_MISSPELLED_EXIT_STATUS
  run check_library_properties "./check_library_properties/ArchitecturesMisspelled"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 2 ]
  outputRegex='^ERROR: \./check_library_properties/ArchitecturesMisspelled has misspelled architectures field name as "architecture"\.$'
  [[ "${lines[0]}" =~ $outputRegex ]]
  outputRegex="^WARNING: \./check_library_properties/ArchitecturesMisspelled is missing the architectures field\. This causes the Arduino IDE to assume the library is compatible with all architectures \(\*\)\. See https://github.com/arduino/Arduino/wiki/Arduino-IDE-1\.5:-Library-specification#libraryproperties-file-format$"
  [[ "${lines[1]}" =~ $outputRegex ]]
}

@test "check_library_properties \"./check_library_properties/ArchitecturesEmpty\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_ARCHITECTURES_EMPTY_EXIT_STATUS
  run check_library_properties "./check_library_properties/ArchitecturesEmpty"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex='^ERROR: \./check_library_properties/ArchitecturesEmpty has an empty architectures field\. This causes the examples to be put under File > Examples > INCOMPATIBLE\.$'
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_library_properties \"./check_library_properties/ArchitectureAliasWithValidMatch\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS
  run check_library_properties "./check_library_properties/ArchitectureAliasWithValidMatch"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  unrecognizedArchitectureRegex='^ERROR: \./check_library_properties/ArchitecturesEmpty has an empty architectures field\. This causes the examples to be put under File > Examples > INCOMPATIBLE\.$'
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
  outputRegex="^ERROR: \./check_library_properties/ArchitectureAliasWithoutValidMatch's architectures field contains an invalid architecture AVR\. Note: architecture values are case-sensitive\.$"
  [[ "${lines[0]}" =~ $outputRegex ]]
  outputRegex="^ERROR: \./check_library_properties/ArchitectureAliasWithoutValidMatch's architectures field \(AVR\) doesn't contain any known architecture values\.$"
  [[ "${lines[1]}" =~ $outputRegex ]]
}

@test "check_library_properties \"./check_library_properties/NoRecognizedArchitecture\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_INVALID_ARCHITECTURE_EXIT_STATUS
  run check_library_properties "./check_library_properties/NoRecognizedArchitecture"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 2 ]
  outputRegex="^WARNING: \./check_library_properties/NoRecognizedArchitecture's architectures field contains an unknown architecture asdf\. Note: architecture values are case-sensitive\.$"
  [[ "${lines[0]}" =~ $outputRegex ]]
  outputRegex="^ERROR: \./check_library_properties/NoRecognizedArchitecture's architectures field \(asdf\) doesn't contain any known architecture values\.$"
  [[ "${lines[1]}" =~ $outputRegex ]]
}

@test "check_library_properties \"./check_library_properties/InvalidArchitecture\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_INVALID_ARCHITECTURE_EXIT_STATUS
  run check_library_properties "./check_library_properties/InvalidArchitecture"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 2 ]
  unrecognizedArchitectureRegex="^WARNING: \./check_library_properties/InvalidArchitecture's architectures field contains an unknown architecture foo\. Note: architecture values are case-sensitive\.$"
  [[ "${lines[0]}" =~ $IDEnotInstalledRegex ]]
  outputRegex="^ERROR: \./check_library_properties/InvalidArchitecture's architectures field \(foo\) doesn't contain any known architecture values\.$"
  [[ "${lines[1]}" =~ $outputRegex ]]
}

@test "check_library_properties \"./check_library_properties/IncorrectIncludesFieldCase\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_INCLUDES_MISSPELLED_EXIT_STATUS
  run check_library_properties "./check_library_properties/IncorrectIncludesFieldCase"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex="^ERROR: \./check_library_properties/IncorrectIncludesFieldCase's includes field name has incorrect case\. It must be spelled exactly includes\. See https://github.com/arduino/Arduino/wiki/Arduino-IDE-1\.5:-Library-specification#libraryproperties-file-format$"
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_library_properties \"./check_library_properties/IncludeField\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_INCLUDES_MISSPELLED_EXIT_STATUS
  run check_library_properties "./check_library_properties/IncludeField"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex="^ERROR: \./check_library_properties/IncludeField's includes field name is misspelled\. It must be spelled exactly \"includes\"\. See https://github.com/arduino/Arduino/wiki/Arduino-IDE-1\.5:-Library-specification#libraryproperties-file-format$"
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_library_properties \"./check_library_properties/EmptyIncludes\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_EMPTY_INCLUDES_EXIT_STATUS
  run check_library_properties "./check_library_properties/EmptyIncludes"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex="^ERROR: \./check_library_properties/EmptyIncludes's includes value is empty\. Either define the field or remove it\. See https://github.com/arduino/Arduino/wiki/Arduino-IDE-1\.5:-Library-specification#libraryproperties-file-format$"
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_library_properties \"./check_library_properties/IncorrectDotAlinkageFieldCase\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_DOT_A_LINKAGE_MISSPELLED_EXIT_STATUS
  run check_library_properties "./check_library_properties/IncorrectDotAlinkageFieldCase"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex="^ERROR: \./check_library_properties/IncorrectDotAlinkageFieldCase's dot_a_linkage field name has incorrect case\. It must be spelled exactly dot_a_linkage\. See https://github.com/arduino/Arduino/wiki/Arduino-IDE-1\.5:-Library-specification#libraryproperties-file-format$"
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_library_properties \"./check_library_properties/DotAlinkagesField\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_DOT_A_LINKAGE_MISSPELLED_EXIT_STATUS
  run check_library_properties "./check_library_properties/DotAlinkagesField"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex="^ERROR: \./check_library_properties/DotAlinkagesField's dot_a_linkage field name is misspelled\. It must be spelled exactly \"dot_a_linkage\"\. See https://github.com/arduino/Arduino/wiki/Arduino-IDE-1\.5:-Library-specification#libraryproperties-file-format$"
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_library_properties \"./check_library_properties/IncorrectPrecompiledFieldCase\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_PRECOMPILED_MISSPELLED_EXIT_STATUS
  run check_library_properties "./check_library_properties/IncorrectPrecompiledFieldCase"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex="^ERROR: \./check_library_properties/IncorrectPrecompiledFieldCase's precompiled field name has incorrect case\. It must be spelled exactly precompiled\. See https://github.com/arduino/Arduino/wiki/Arduino-IDE-1\.5:-Library-specification#libraryproperties-file-format$"
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_library_properties \"./check_library_properties/PrecompileField\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_PRECOMPILED_MISSPELLED_EXIT_STATUS
  run check_library_properties "./check_library_properties/PrecompileField"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex="^ERROR: \./check_library_properties/PrecompileField's precompiled field name is misspelled\. It must be spelled exactly \"precompiled\"\. See https://github.com/arduino/Arduino/wiki/Arduino-IDE-1\.5:-Library-specification#libraryproperties-file-format$"
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_library_properties \"./check_library_properties/IncorrectLdflagsFieldCase\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_LDFLAGS_MISSPELLED_EXIT_STATUS
  run check_library_properties "./check_library_properties/IncorrectLdflagsFieldCase"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex="^ERROR: \./check_library_properties/IncorrectLdflagsFieldCase's ldflags field name has incorrect case\. It must be spelled exactly ldflags\. See https://github.com/arduino/Arduino/wiki/Arduino-IDE-1\.5:-Library-specification#libraryproperties-file-format$"
  [[ "${lines[0]}" =~ $outputRegex ]]
}

@test "check_library_properties \"./check_library_properties/LdflagField\"" {
  expectedExitStatus=$ARDUINO_CI_SCRIPT_CHECK_LIBRARY_PROPERTIES_LDFLAGS_MISSPELLED_EXIT_STATUS
  run check_library_properties "./check_library_properties/LdflagField"
  echo "Exit status: $status | Expected: $expectedExitStatus"
  [ "$status" -eq $expectedExitStatus ]
  [ "${#lines[@]}" -eq 1 ]
  outputRegex="^ERROR: \./check_library_properties/LdflagField's ldflags field name is misspelled\. It must be spelled exactly \"ldflags\"\. See https://github.com/arduino/Arduino/wiki/Arduino-IDE-1\.5:-Library-specification#libraryproperties-file-format$"
  [[ "${lines[0]}" =~ $outputRegex ]]
}
