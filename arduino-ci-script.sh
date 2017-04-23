# This script is used to automate continuous integration tasks for Arduino projects
# https://github.com/per1234/arduino-ci-script

#!/bin/bash

# https://docs.travis-ci.com/user/customizing-the-build/#Implementing-Complex-Build-Steps
# -e will cause the script to exit as soon as one command returns a non-zero exit code
set -e


# Based on https://github.com/adafruit/travis-ci-arduino/blob/eeaeaf8fa253465d18785c2bb589e14ea9893f9f/install.sh#L11
# It seems that arrays can't been seen in other functions. So instead I'm setting $IDE_VERSIONS to a string that is the command to create the array
# https://github.com/arduino/Arduino/blob/master/build/shared/manpage.adoc#history shows CLI was added in IDE 1.5.2, Boards and Library Manager support added in 1.6.4
# This is a list of every version of the Arduino IDE that supports CLI. As new versions are released they will be added to the list.
# The newest IDE version must always be placed at the end of the array because the code for setting $NEWEST_IDE_VERSION assumes that
# Arduino IDE 1.6.2 has the nasty behavior of copying the included hardware cores to the .arduino15 folder, causing those versions to be used for all builds after Arduino IDE 1.6.2 is used. For this reason 1.6.2 has been left off the list.
IDE_VERSIONS_DECLARATION="declare -a ide_versions="
IDE_VERSIONS="$IDE_VERSIONS_DECLARATION"'("1.5.2" "1.5.3" "1.5.4" "1.5.5" "1.5.6-r2" "1.5.7" "1.5.8" "1.6.0" "1.6.1" "1.6.3" "1.6.4" "1.6.5-r5" "1.6.6" "1.6.7" "1.6.8" "1.6.9" "1.6.10" "1.6.11" "1.6.12" "1.6.13" "1.8.0" "1.8.1" "1.8.2" "hourly")'


TEMPORARY_FOLDER="$HOME/temporary"
VERIFICATION_OUTPUT_FILENAME="$TEMPORARY_FOLDER/verification_output.txt"
REPORT_FILENAME="$HOME/report.txt"
# The Arduino IDE returns exit code 255 after a failed file signature verification of the boards manager JSON file. This does not indicate an issue with the sketch and the problem may go away after a retry.
SKETCH_VERIFY_RETRIES=3


# Add column names to report
echo "Build Timestamp (UTC)"$'\t'"Build #"$'\t'"Branch"$'\t'"Commit"$'\t'"Commit Message"$'\t'"Sketch Filename"$'\t'"Board ID"$'\t'"IDE Version"$'\t'"Program Storage (bytes)"$'\t'"Dynamic Memory (bytes)"$'\t'"# Warnings"$'\t'"Allow Failure"$'\t'"Exit Code" > "$REPORT_FILENAME"

# Create the temporary folder
mkdir "$TEMPORARY_FOLDER"


# Start the virtual display required by the Arduino IDE CLI: https://github.com/arduino/Arduino/blob/master/build/shared/manpage.adoc#bugs
# based on https://learn.adafruit.com/continuous-integration-arduino-and-you/testing-your-project
/sbin/start-stop-daemon --start --quiet --pidfile /tmp/custom_xvfb_1.pid --make-pidfile --background --exec /usr/bin/Xvfb -- :1 -ac -screen 0 1280x1024x16
sleep 3
export DISPLAY=:1.0


function set_parameters()
{
  APPLICATION_FOLDER="$1"
  SKETCHBOOK_FOLDER="$2"
  local verboseArduinoOutput="$3"

  if [[ "$verboseArduinoOutput" == "true" ]]; then
    VERBOSE_BUILD="--verbose"
  fi
}


# Install all versions of the Arduino IDE defined in the ide_versions array in set_parameters()
function install_ide()
{
  if [[ "$1" != "" ]]; then
    local re="\("
    if [[ "$1" =~ $re ]]; then
      # IDE versions list was supplied
      IDE_VERSIONS="${IDE_VERSIONS_DECLARATION}${1}"
    elif [[ "$1" != "all" ]]; then
      local startVersion="$1"

      # get the array of all IDE versions
      eval "$IDE_VERSIONS"
      for IDEversion in "${ide_versions[@]}"; do
        if [[ "$oldestVersion" == "" ]]; then
          local oldestVersion="$IDEversion"
        fi
        if [[ "$IDEversion" != "hourly" ]]; then
          local newestVersion="$IDEversion"
        fi
      done

      if [[ "$startVersion" == "oldest" ]]; then
        local startVersion="$oldestVersion"
      elif [[ "$startVersion" == "newest" ]]; then
        local startVersion="$newestVersion"
      fi

      if [[ "$2" != "" ]]; then
        local endVersion="$2"

        if [[ "$endVersion" == "oldest" ]]; then
          local endVersion="$oldestVersion"
        elif [[ "$endVersion" == "newest" ]]; then
          local endVersion="$newestVersion"
        fi

        # Assemble list of IDE versions in the specified range
        # Begin the list
        IDE_VERSIONS="$IDE_VERSIONS_DECLARATION"'('
        for IDEversion in "${ide_versions[@]}"; do
          if [[ "$IDEversion" == "$startVersion" ]]; then
            # Set a flag
            local listIsStarted="true"
          fi
          if [[ "$endVersion" == "newest" && "$IDEversion" == "hourly" ]]; then
            # "newest" indicates the newest release, not the hourly build so the list is complete
            break
          fi
          if [[ "$listIsStarted" == "true" ]]; then
            IDE_VERSIONS="${IDE_VERSIONS} "'"'"$IDEversion"'"'
          fi
          if [[ "$IDEversion" == "$endVersion" ]]; then
            break
          fi
        done
        # Finish the list
        IDE_VERSIONS="$IDE_VERSIONS"')'
      else
        # Only a single version argument was specified
        IDE_VERSIONS="$IDE_VERSIONS_DECLARATION"'("'"${startVersion}"'")'
      fi
    fi
  fi

  # This runs the command contained in the $IDE_VERSIONS string, thus declaring the array locally as $ide_versions. This must be done in any function that uses the array
  eval "$IDE_VERSIONS"

  for IDEversion in "${ide_versions[@]}"; do
    # Determine download file extension
    local re="1.5.[0-9]"
    if [[ "$IDEversion" =~ $re ]]; then
      # The download file extension prior to 1.6.0 is .tgz
      local downloadFileExtension="tgz"
    else
      local downloadFileExtension="tar.xz"
    fi

    if [[ "$OLDEST_IDE_VERSION" == "" ]]; then
      OLDEST_IDE_VERSION="$IDEversion"
    fi

    if [[ "$IDEversion" == "hourly" ]]; then
      # Deal with the inaccurate name given to the hourly build download
      wget "http://downloads.arduino.cc/arduino-nightly-linux64.${downloadFileExtension}"
      tar xf "arduino-nightly-linux64.${downloadFileExtension}"
      rm "arduino-nightly-linux64.${downloadFileExtension}"
      sudo mv "arduino-nightly" "$APPLICATION_FOLDER/arduino-${IDEversion}"
    else
      # "newest" does not include the hourly build
      NEWEST_IDE_VERSION="$IDEversion"

      wget "http://downloads.arduino.cc/arduino-${IDEversion}-linux64.${downloadFileExtension}"
      tar xf "arduino-${IDEversion}-linux64.${downloadFileExtension}"
      rm "arduino-${IDEversion}-linux64.${downloadFileExtension}"
      sudo mv "arduino-${IDEversion}" "$APPLICATION_FOLDER/arduino-${IDEversion}"
    fi
  done

  # Temporarily install the latest IDE version
  install_ide_version "$NEWEST_IDE_VERSION"
  # Create the link that will be used for all IDE installations
  sudo ln -s "$APPLICATION_FOLDER/arduino/arduino" /usr/local/bin/arduino

  # Set the preferences
  # Create the sketchbook folder. The location can't be set in preferences if the folder doesn't exist.
  mkdir "$SKETCHBOOK_FOLDER"
  # --pref option is only supported by Arduino IDE 1.5.6 and newer
  local re="1.5.[0-5]"
  if ! [[ "$NEWEST_IDE_VERSION" =~ $re ]]; then
    # --save-prefs was added in Arduino IDE 1.5.8
    local re="1.5.[6-7]"
    if ! [[ "$NEWEST_IDE_VERSION" =~ $re ]]; then
      local savePrefs="--save-prefs"
    fi
    arduino --pref compiler.warning_level=all --pref sketchbook.path="$SKETCHBOOK_FOLDER" "$savePrefs"
  fi

  # Uninstall the IDE
  uninstall_ide_version "$NEWEST_IDE_VERSION"
}


function install_ide_version()
{
  local IDEversion="$1"
  sudo mv "${APPLICATION_FOLDER}/arduino-${IDEversion}" "${APPLICATION_FOLDER}/arduino"
}


function uninstall_ide_version()
{
  local IDEversion="$1"
  sudo mv "${APPLICATION_FOLDER}/arduino" "${APPLICATION_FOLDER}/arduino-${IDEversion}"
}


# Install hardware packages
function install_package()
{
  local packageID="$1"
  local packageURL="$2"

  # Temporarily install the latest IDE version to use for the package installation
  install_ide_version "$NEWEST_IDE_VERSION"

  # If defined add the boards manager URL to preferences
  if [[ "$packageURL" != "" ]]; then
    arduino --pref boardsmanager.additional.urls="$packageURL" --save-prefs
  fi

  # Install the package
  arduino --install-boards "$packageID"

  # Uninstall the IDE
  uninstall_ide_version "$NEWEST_IDE_VERSION"
}


# Install the library from the current repository
function install_library_from_repo()
{
  # https://docs.travis-ci.com/user/environment-variables#Global-Variables
  local library_name="$(echo $TRAVIS_REPO_SLUG | cut -d'/' -f 2)"
  mkdir "${SKETCHBOOK_FOLDER}/libraries/$library_name"
  cd "$TRAVIS_BUILD_DIR"
  cp -r -v * "${SKETCHBOOK_FOLDER}/libraries/${library_name}"
  # * doesn't copy .travis.yml but that file will be present in the user's installation so it should be there for the tests too
  cp -v "${TRAVIS_BUILD_DIR}/.travis.yml" "${SKETCHBOOK_FOLDER}/libraries/${library_name}"
}


# Install external libraries
# Note: this assumes the library is in the root of the file
function install_library_dependency()
{
  local libraryDependencyURL="$1"

  if [[ "$libraryDependencyURL" =~ \.git$ ]]; then
    # Clone the repository
    cd "${SKETCHBOOK_FOLDER}/libraries"
    git clone "$libraryDependencyURL"
  else
    # Assume it's a compressed file

    # Download the file to the temporary folder
    cd "$TEMPORARY_FOLDER"
    wget "$libraryDependencyURL"

    # This script handles any compressed file type
    source "${TRAVIS_BUILD_DIR}/extract.sh"
    extract *.*
    # Clean up the temporary folder
    rm *.*
    # Install the library
    mv * "${SKETCHBOOK_FOLDER}/libraries"
  fi
}


# Verify the sketch
function build_sketch()
{
  local sketchPath="$1"
  local boardID="$2"
  local IDEversion="$3"
  local allowFail="$4"

  if [[ "$IDEversion" == "all" ]]; then
    eval "$IDE_VERSIONS"
    for IDEversion in "${ide_versions[@]}"; do
      find_sketches "$sketchPath" "$boardID" "$IDEversion" "$allowFail"
    done
  else
    if [[ "$IDEversion" == "oldest" ]]; then
      local IDEversion="$OLDEST_IDE_VERSION"
    elif [[ "$IDEversion" == "newest" ]]; then
      local IDEversion="$NEWEST_IDE_VERSION"
    fi
    find_sketches "$sketchPath" "$boardID" "$IDEversion" "$allowFail"
  fi
}


function find_sketches()
{
  local sketchPath="$1"
  local boardID="$2"
  local IDEversion="$3"
  local allowFail="$4"

  # Install the IDE
  # This must be done before searching for sketches in case the path specified is in the Arduino IDE installation folder
  install_ide_version "$IDEversion"

  if [[ "$sketchPath" =~ \.ino$ || "$sketchPath" =~ \.pde$ ]]; then
    # A sketch was specified
    build_this_sketch "$sketchPath" "$boardID" "$IDEversion" "$allowFail"
  else
    # Search for all sketches in the path and put them in an array
    # https://github.com/adafruit/travis-ci-arduino/blob/eeaeaf8fa253465d18785c2bb589e14ea9893f9f/install.sh#L100
    declare -a sketches
    sketches=($(find "$sketchPath" -name "*.pde" -o -name "*.ino"))
    for sketchName in "${sketches[@]}"; do
      # Only verify the sketch that matches the name of the sketch folder, otherwise it will cause redundant verifications for sketches that have multiple .ino files
      local sketchFolder="$(echo $sketchName | rev | cut -d'/' -f 2 | rev)"
      local sketchNameWithoutPathWithExtension=$(echo $sketchName | rev | cut -d'/' -f 1 | rev)
      local sketchNameWithoutPathWithoutExtension=$(echo $sketchNameWithoutPathWithExtension | cut -d'.' -f1)
      if [[ "$sketchFolder" == "$sketchNameWithoutPathWithoutExtension" ]]; then
        build_this_sketch "$sketchName" "$boardID" "$IDEversion" "$allowFail"
      fi
    done
  fi
  # Uninstall the IDE
  uninstall_ide_version "$IDEversion"
}


function build_this_sketch()
{
  echo -e "travis_fold:start:build_sketch"

  local sketchName="$1"
  local boardID="$2"
  local IDEversion="$3"
  local allowFail="$4"

  # Produce a useful label for the fold in the Travis log for this function call
  echo "build_sketch $sketchName $boardID $IDEversion $allowFail"

  local sketchBuildExitCode=255
  # Retry the verification if it returns exit code 255
  while [[ "$sketchBuildExitCode" == "255" && $verifyCount -le $SKETCH_VERIFY_RETRIES ]]; do
    # Verify the sketch
    arduino $VERBOSE_BUILD --verify "$sketchName" --board "$boardID" 2>&1 | tee "$VERIFICATION_OUTPUT_FILENAME"; local sketchBuildExitCode="${PIPESTATUS[0]}"
    local verifyCount=$((verifyCount + 1))
  done

  # Parse through the output from the sketch verification to count warnings and determine the compile size
  local warningCount=0
  while read line; do
    # Determine program storage memory usage
    local re="Sketch uses ([0-9,]+) *"
    if [[ "$line" =~ $re ]] > /dev/null; then
      local programStorage=${BASH_REMATCH[1]}
    fi

    # Determine dynamic memory usage
    local re="Global variables use ([0-9,]+) *"
    if [[ "$line" =~ $re ]] > /dev/null; then
      local dynamicMemory=${BASH_REMATCH[1]}
    fi

    # Increment warning count
    local re="warning: "
    if [[ "$line" =~ $re ]] > /dev/null; then
      local warningCount=$((warningCount + 1))
    fi
  done < "$VERIFICATION_OUTPUT_FILENAME"

  rm "$VERIFICATION_OUTPUT_FILENAME"

  # Remove the stupid comma from the memory values if present
  local programStorage=${programStorage//,}
  local dynamicMemory=${dynamicMemory//,}

  # Add the build data to the report file
  echo `date -u "+%Y-%m-%d %H:%M:%S"`$'\t'"$TRAVIS_BUILD_NUMBER"$'\t'"$TRAVIS_BRANCH"$'\t'"$TRAVIS_COMMIT"$'\t'"${TRAVIS_COMMIT_MESSAGE%%$'\n'*}"$'\t'"$sketchName"$'\t'"$boardID"$'\t'"$IDEversion"$'\t'"$programStorage"$'\t'"$dynamicMemory"$'\t'"$warningCount"$'\t'"$allowFail"$'\t'"$sketchBuildExitCode" >> "$REPORT_FILENAME"

  # If the sketch build failed and failure is not allowed for this test then fail the Travis build after completing all sketch builds
  if [[ "$sketchBuildExitCode" != 0 ]]; then
    if [[ "$allowFail" != "true" ]]; then
      TRAVIS_BUILD_EXIT_CODE=1
    fi
  fi

  echo -e "travis_fold:end:build_sketch"
  echo "arduino exit code: $sketchBuildExitCode"
}


# Print the contents of the report file
function display_report()
{
  if [ -e "$REPORT_FILENAME" ]; then
    echo -e "\n\n\n**************Begin Report**************\n\n\n"
    cat "$REPORT_FILENAME"
    echo -e "\n\n"
  else
    echo "No report file available for this job"
  fi
}


# Return 1 if any of the sketch builds failed
function check_success()
{
  if [[ "$TRAVIS_BUILD_EXIT_CODE" != "" ]]; then
    return 1
  fi
}
