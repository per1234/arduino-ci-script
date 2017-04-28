# This script is used to automate continuous integration tasks for Arduino projects
# https://github.com/per1234/arduino-ci-script

#!/bin/bash

# https://docs.travis-ci.com/user/customizing-the-build/#Implementing-Complex-Build-Steps
# -e will cause the script to exit as soon as one command returns a non-zero exit code
set -e


# Based on https://github.com/adafruit/travis-ci-arduino/blob/eeaeaf8fa253465d18785c2bb589e14ea9893f9f/install.sh#L11
# It seems that arrays can't been seen in other functions. So instead I'm setting $IDE_VERSIONS to a string that is the command to create the array
IDE_VERSION_LIST_ARRAY_DECLARATION="declare -a IDEversionListArray="

# https://github.com/arduino/Arduino/blob/master/build/shared/manpage.adoc#history shows CLI was added in IDE 1.5.2, Boards and Library Manager support added in 1.6.4
# This is a list of every version of the Arduino IDE that supports CLI. As new versions are released they will be added to the list.
# The newest IDE version must always be placed at the end of the array because the code for setting $NEWEST_INSTALLED_IDE_VERSION assumes that
# Arduino IDE 1.6.2 has the nasty behavior of moving the included hardware cores to the .arduino15 folder, causing those versions to be used for all builds after Arduino IDE 1.6.2 is used. For this reason 1.6.2 has been left off the list.
FULL_IDE_VERSION_LIST_ARRAY="${IDE_VERSION_LIST_ARRAY_DECLARATION}"'("1.5.2" "1.5.3" "1.5.4" "1.5.5" "1.5.6" "1.5.6-r2" "1.5.7" "1.5.8" "1.6.0" "1.6.1" "1.6.3" "1.6.4" "1.6.5" "1.6.5-r4" "1.6.5-r5" "1.6.6" "1.6.7" "1.6.8" "1.6.9" "1.6.10" "1.6.11" "1.6.12" "1.6.13" "1.8.0" "1.8.1" "1.8.2" "hourly")'


TEMPORARY_FOLDER="${HOME}/temporary/arduino-ci-script"
VERIFICATION_OUTPUT_FILENAME="${TEMPORARY_FOLDER}/verification_output.txt"
REPORT_FILENAME="${HOME}/report.txt"
# The Arduino IDE returns exit code 255 after a failed file signature verification of the boards manager JSON file. This does not indicate an issue with the sketch and the problem may go away after a retry.
SKETCH_VERIFY_RETRIES=3


# Add column names to report
echo "Build Timestamp (UTC)"$'\t'"Build"$'\t'"Job"$'\t'"Build Trigger"$'\t'"Allow Job Failure"$'\t'"PR#"$'\t'"Branch"$'\t'"Commit"$'\t'"Commit Range"$'\t'"Commit Message"$'\t'"Sketch Filename"$'\t'"Board ID"$'\t'"IDE Version"$'\t'"Program Storage (bytes)"$'\t'"Dynamic Memory (bytes)"$'\t'"# Warnings"$'\t'"Allow Failure"$'\t'"Exit Code" > "$REPORT_FILENAME"

# Create the temporary folder
if ! [[ -d "$TEMPORARY_FOLDER" ]]; then
  mkdir --parents "$TEMPORARY_FOLDER"
fi

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

  # Create the sketchbook folder if it doesn't already exist
  if ! [[ -d "$SKETCHBOOK_FOLDER" ]]; then
    mkdir --parents "$SKETCHBOOK_FOLDER"
  fi

  if [[ "$verboseArduinoOutput" == "true" ]]; then
    VERBOSE_BUILD="--verbose"
  fi
}


# Install all specified versions of the Arduino IDE
function install_ide()
{
  local startIDEversion="$1"
  local endIDEversion="$2"

  generate_ide_version_list_array "$FULL_IDE_VERSION_LIST_ARRAY" "$startIDEversion" "$endIDEversion"
  INSTALLED_IDE_VERSION_LIST_ARRAY="$GENERATED_IDE_VERSION_LIST_ARRAY"

  # Set "$NEWEST_INSTALLED_IDE_VERSION" and "$OLDEST_INSTALLED_IDE_VERSION"
  determine_ide_version_extremes "$INSTALLED_IDE_VERSION_LIST_ARRAY"
  OLDEST_INSTALLED_IDE_VERSION="$DETERMINED_OLDEST_IDE_VERSION"
  NEWEST_INSTALLED_IDE_VERSION="$DETERMINED_NEWEST_IDE_VERSION"


  # This runs the command contained in the $INSTALLED_IDE_VERSION_LIST_ARRAY string, thus declaring the array locally as $IDEversionListArray. This must be done in any function that uses the array
  eval "$INSTALLED_IDE_VERSION_LIST_ARRAY"
  local IDEversion
  for IDEversion in "${IDEversionListArray[@]}"; do
    # Determine download file extension
    local regex="1.5.[0-9]"
    if [[ "$IDEversion" =~ $regex ]]; then
      # The download file extension prior to 1.6.0 is .tgz
      local downloadFileExtension="tgz"
    else
      local downloadFileExtension="tar.xz"
    fi

    if [[ "$IDEversion" == "hourly" ]]; then
      # Deal with the inaccurate name given to the hourly build download
      wget "http://downloads.arduino.cc/arduino-nightly-linux64.${downloadFileExtension}"
      tar xf "arduino-nightly-linux64.${downloadFileExtension}"
      rm "arduino-nightly-linux64.${downloadFileExtension}"
      sudo mv "arduino-nightly" "$APPLICATION_FOLDER/arduino-${IDEversion}"

    else
      wget "http://downloads.arduino.cc/arduino-${IDEversion}-linux64.${downloadFileExtension}"
      tar xf "arduino-${IDEversion}-linux64.${downloadFileExtension}"
      rm "arduino-${IDEversion}-linux64.${downloadFileExtension}"
      sudo mv "arduino-${IDEversion}" "$APPLICATION_FOLDER/arduino-${IDEversion}"
    fi
  done

  # Temporarily install the latest IDE version
  install_ide_version "$NEWEST_INSTALLED_IDE_VERSION"
  # Create the link that will be used for all IDE installations
  sudo ln --symbolic "$APPLICATION_FOLDER/arduino/arduino" /usr/local/bin/arduino

  # Set the preferences
  # --pref option is only supported by Arduino IDE 1.5.6 and newer
  local regex="1.5.[0-5]"
  if ! [[ "$NEWEST_INSTALLED_IDE_VERSION" =~ $regex ]]; then
    # Create the sketchbook folder if it doesn't already exist. The location can't be set in preferences if the folder doesn't exist.
    if ! [[ -d "$SKETCHBOOK_FOLDER" ]]; then
      mkdir --parents "$SKETCHBOOK_FOLDER"
    fi

    # --save-prefs was added in Arduino IDE 1.5.8
    local regex="1.5.[6-7]"
    if ! [[ "$NEWEST_INSTALLED_IDE_VERSION" =~ $regex ]]; then
      local savePrefs="--save-prefs"
    fi
    arduino --pref compiler.warning_level=all --pref sketchbook.path="$SKETCHBOOK_FOLDER" "$savePrefs"
  fi

  # Uninstall the IDE
  uninstall_ide_version "$NEWEST_INSTALLED_IDE_VERSION"
}


# Generate an array of Arduino IDE versions as a subset of the list provided in the base array defined by the start and end versions
# This function allows the same code to be shared by install_ide and build_sketch. The generated array is "returned" as a global named "$GENERATED_IDE_VERSION_LIST_ARRAY"
function generate_ide_version_list_array()
{
  local baseIDEversionArray="$1"
  local startIDEversion="$2"
  local endIDEversion="$3"

  # Convert "oldest" or "newest" to actual version numbers
  determine_ide_version_extremes "$baseIDEversionArray"
  if [[ "$startIDEversion" == "oldest" ]]; then
    local startIDEversion="$DETERMINED_OLDEST_IDE_VERSION"
  elif [[ "$startIDEversion" == "newest" ]]; then
    local startIDEversion="$DETERMINED_NEWEST_IDE_VERSION"
  fi

  if [[ "$endIDEversion" == "oldest" ]]; then
    local endIDEversion="$DETERMINED_OLDEST_IDE_VERSION"
  elif [[ "$endIDEversion" == "newest" ]]; then
    local endIDEversion="$DETERMINED_NEWEST_IDE_VERSION"
  fi


  local regex="\("
  if [[ "$startIDEversion" =~ $regex ]]; then
    # IDE versions list was supplied
    GENERATED_IDE_VERSION_LIST_ARRAY="${IDE_VERSION_LIST_ARRAY_DECLARATION}${startIDEversion}"

  elif [[ "$startIDEversion" == "" || "$startIDEversion" == "all" ]]; then
    # Use the full base array
    GENERATED_IDE_VERSION_LIST_ARRAY="$baseIDEversionArray"

  else
    # Start the array
    GENERATED_IDE_VERSION_LIST_ARRAY="$IDE_VERSION_LIST_ARRAY_DECLARATION"'('

    if [[ "$endIDEversion" == "" ]]; then
      # Only a single version was specified
      GENERATED_IDE_VERSION_LIST_ARRAY="$GENERATED_IDE_VERSION_LIST_ARRAY"'"'"$startIDEversion"'"'

    else
      # A version range was specified
      eval "$baseIDEversionArray"
      local IDEversion
      for IDEversion in "${IDEversionListArray[@]}"; do
        if [[ "$IDEversion" == "$startIDEversion" ]]; then
          # Start of the list reached, set a flag
          local listIsStarted="true"
        fi

        if [[ "$listIsStarted" == "true" ]]; then
          # Add the version to the list
          GENERATED_IDE_VERSION_LIST_ARRAY="${GENERATED_IDE_VERSION_LIST_ARRAY} "'"'"$IDEversion"'"'
        fi

        if [[ "$IDEversion" == "$endIDEversion" ]]; then
          # End of the list was reached, exit the loop
          break
        fi
      done
    fi

    # Finish the list
    GENERATED_IDE_VERSION_LIST_ARRAY="$GENERATED_IDE_VERSION_LIST_ARRAY"')'
  fi
}


# Determine the oldest and newest (non-hourly unless hourly is the only version on the list) IDE version in the provided array
# The determined versions are "returned" by setting the global variables "$DETERMINED_OLDEST_IDE_VERSION" and "$DETERMINED_NEWEST_IDE_VERSION"
function determine_ide_version_extremes()
{
  local baseIDEversionArray="$1"

  # Reset the variables from any value they were assigned the last time the function was ran
  DETERMINED_OLDEST_IDE_VERSION=""
  DETERMINED_NEWEST_IDE_VERSION=""

  # Determine the oldest and newest (non-hourly) IDE version in the base array
  eval "$baseIDEversionArray"
  local IDEversion
  for IDEversion in "${IDEversionListArray[@]}"; do
    if [[ "$DETERMINED_OLDEST_IDE_VERSION" == "" ]]; then
      DETERMINED_OLDEST_IDE_VERSION="$IDEversion"
    fi
    if [[ "$DETERMINED_NEWEST_IDE_VERSION" == "" || "$IDEversion" != "hourly" ]]; then
      DETERMINED_NEWEST_IDE_VERSION="$IDEversion"
    fi
  done
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

  local regex="://"
  if [[ "$1" =~ $regex ]]; then
    # First argument is a URL, do a manual hardware package installation
    # Note: Assumes the package is in the root of the download and has the correct folder structure (e.g. architecture folder added in Arduino IDE 1.5+)

    local packageURL="$1"

    # Create the hardware folder if it doesn't exist
    if ! [[ -d "${SKETCHBOOK_FOLDER}/hardware" ]]; then
      mkdir --parents "${SKETCHBOOK_FOLDER}/hardware"
    fi

    if [[ "$packageURL" =~ \.git$ ]]; then
      # Clone the repository
      cd "${SKETCHBOOK_FOLDER}/hardware"
      git clone "$packageURL"

    else
      cd "$TEMPORARY_FOLDER"

      # Clean up the temporary folder
      rm -f *.*

      # Download the package
      wget "$packageURL"

      # Uncompress the package
      # This script handles any compressed file type
      source "${TRAVIS_BUILD_DIR}/extract.sh"
      extract *.*

      # Clean up the temporary folder
      rm -f *.*

      # Install the package
      mv * "${SKETCHBOOK_FOLDER}/hardware/"
    fi

  elif [[ "$1" == "" ]]; then
    # Install hardware package from this repository
    # https://docs.travis-ci.com/user/environment-variables#Global-Variables
    local packageName="$(echo $TRAVIS_REPO_SLUG | cut -d'/' -f 2)"
    mkdir --parents "${SKETCHBOOK_FOLDER}/hardware/$packageName"
    cd "$TRAVIS_BUILD_DIR"
    cp --recursive --verbose * "${SKETCHBOOK_FOLDER}/hardware/${packageName}"
    # * doesn't copy .travis.yml but that file will be present in the user's installation so it should be there for the tests too
    cp --verbose "${TRAVIS_BUILD_DIR}/.travis.yml" "${SKETCHBOOK_FOLDER}/hardware/${packageName}"

  else
    # Install package via Boards Manager

    local packageID="$1"
    local packageURL="$2"

    # Check if the newest installed IDE version supports --install-boards
    local regex1="1.5.[0-9]"
    local regex2="1.6.[0-3]"
    if [[ "$NEWEST_INSTALLED_IDE_VERSION" =~ $regex1 || "$NEWEST_INSTALLED_IDE_VERSION" =~ $regex2 ]]; then
      echo "ERROR: --install-boards option is not supported by the newest version of the Arduino IDE you have installed. You must have Arduino IDE 1.6.4 or newer installed to use this function."
      return 1
    else
      # Temporarily install the latest IDE version to use for the package installation
      install_ide_version "$NEWEST_INSTALLED_IDE_VERSION"

      # If defined add the boards manager URL to preferences
      if [[ "$packageURL" != "" ]]; then
        arduino --pref boardsmanager.additional.urls="$packageURL" --save-prefs
      fi

      # Install the package
      arduino --install-boards "$packageID"

      # Uninstall the IDE
      uninstall_ide_version "$NEWEST_INSTALLED_IDE_VERSION"
    fi
  fi
}


function install_library()
{
  local libraryIdentifier="$1"
  local newFolderName="$2"

  # Create the libraries folder if it doesn't already exist
  if ! [[ -d "${SKETCHBOOK_FOLDER}/libraries" ]]; then
    mkdir --parents "${SKETCHBOOK_FOLDER}/libraries"
  fi

  local regex="://"
  if [[ "$libraryIdentifier" =~ $regex ]]; then
    # The argument is a URL
    # Note: this assumes the library is in the root of the file
    if [[ "$libraryIdentifier" =~ \.git$ ]]; then
      # Clone the repository
      cd "${SKETCHBOOK_FOLDER}/libraries"
      if [[ "$newFolderName" == "" ]]; then
        git clone "$libraryIdentifier"
      else
        git clone "$libraryIdentifier" "$newFolderName"
      fi

    else
      # Assume it's a compressed file

      # Download the file to the temporary folder
      cd "$TEMPORARY_FOLDER"
      # Clean up the temporary folder
      rm -f *.*
      wget "$libraryIdentifier"

      # This script handles any compressed file type
      source "${TRAVIS_BUILD_DIR}/extract.sh"
      extract *.*
      # Clean up the temporary folder
      rm -f *.*
      # Install the library
      mv * "${SKETCHBOOK_FOLDER}/libraries/${newFolderName}"
    fi

  elif [[ "$libraryIdentifier" == "" ]]; then
    # Install library from the repository
    # https://docs.travis-ci.com/user/environment-variables#Global-Variables
    local libraryName="$(echo $TRAVIS_REPO_SLUG | cut -d'/' -f 2)"
    mkdir --parents "${SKETCHBOOK_FOLDER}/libraries/$libraryName"
    cd "$TRAVIS_BUILD_DIR"
    cp --recursive --verbose * "${SKETCHBOOK_FOLDER}/libraries/${libraryName}"
    # * doesn't copy .travis.yml but that file will be present in the user's installation so it should be there for the tests too
    cp --verbose "${TRAVIS_BUILD_DIR}/.travis.yml" "${SKETCHBOOK_FOLDER}/libraries/${libraryName}"

  else
    # Install a library that is part of the Library Manager index
    # Check if the newest installed IDE version supports --install-library
    local regex1="1.5.[0-9]"
    local regex2="1.6.[0-3]"
    if [[ "$NEWEST_INSTALLED_IDE_VERSION" =~ $regex1 || "$NEWEST_INSTALLED_IDE_VERSION" =~ $regex2 ]]; then
      echo "ERROR: --install-library option is not supported by the newest version of the Arduino IDE you have installed. You must have Arduino IDE 1.6.4 or newer installed to use this function."
      return 1
    else
      local libraryName="$1"

      # Temporarily install the latest IDE version to use for the library installation
      install_ide_version "$NEWEST_INSTALLED_IDE_VERSION"

       # Install the library
      arduino --install-library "$libraryName"

      # Uninstall the IDE
      uninstall_ide_version "$NEWEST_INSTALLED_IDE_VERSION"
    fi
  fi
}


# Verify the sketch
function build_sketch()
{
  local sketchPath="$1"
  local boardID="$2"
  local allowFail="$3"
  local startIDEversion="$4"
  local endIDEversion="$5"

  generate_ide_version_list_array "$INSTALLED_IDE_VERSION_LIST_ARRAY" "$startIDEversion" "$endIDEversion"

  eval "$GENERATED_IDE_VERSION_LIST_ARRAY"
  local IDEversion
  for IDEversion in "${IDEversionListArray[@]}"; do
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
      local sketchName
      for sketchName in "${sketches[@]}"; do
        # Only verify the sketch that matches the name of the sketch folder, otherwise it will cause redundant verifications for sketches that have multiple .ino files
        local sketchFolder="$(echo $sketchName | rev | cut -d'/' -f 2 | rev)"
        local sketchNameWithoutPathWithExtension="$(echo $sketchName | rev | cut -d'/' -f 1 | rev)"
        local sketchNameWithoutPathWithoutExtension="$(echo $sketchNameWithoutPathWithExtension | cut -d'.' -f1)"
        if [[ "$sketchFolder" == "$sketchNameWithoutPathWithoutExtension" ]]; then
          build_this_sketch "$sketchName" "$boardID" "$IDEversion" "$allowFail"
        fi
      done
    fi
    # Uninstall the IDE
    uninstall_ide_version "$IDEversion"
  done
}


function build_this_sketch()
{
  # Fold this section of output in the Travis CI build log to make it easier to read
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
  while read outputFileLine; do
    # Determine program storage memory usage
    local regex="Sketch uses ([0-9,]+) *"
    if [[ "$outputFileLine" =~ $regex ]] > /dev/null; then
      local programStorage=${BASH_REMATCH[1]}
    fi

    # Determine dynamic memory usage
    local regex="Global variables use ([0-9,]+) *"
    if [[ "$outputFileLine" =~ $regex ]] > /dev/null; then
      local dynamicMemory=${BASH_REMATCH[1]}
    fi

    # Increment warning count
    local regex="warning: "
    if [[ "$outputFileLine" =~ $regex ]] > /dev/null; then
      local warningCount=$((warningCount + 1))
    fi
  done < "$VERIFICATION_OUTPUT_FILENAME"

  rm "$VERIFICATION_OUTPUT_FILENAME"

  # Remove the stupid comma from the memory values if present
  local programStorage=${programStorage//,}
  local dynamicMemory=${dynamicMemory//,}

  # Add the build data to the report file
  echo `date -u "+%Y-%m-%d %H:%M:%S"`$'\t'"$TRAVIS_BUILD_NUMBER"$'\t'"$TRAVIS_JOB_NUMBER"$'\t'"$TRAVIS_EVENT_TYPE"$'\t'"$TRAVIS_ALLOW_FAILURE"$'\t'"$TRAVIS_PULL_REQUEST"$'\t'"$TRAVIS_BRANCH"$'\t'"$TRAVIS_COMMIT"$'\t'"$TRAVIS_COMMIT_RANGE"$'\t'"${TRAVIS_COMMIT_MESSAGE%%$'\n'*}"$'\t'"$sketchName"$'\t'"$boardID"$'\t'"$IDEversion"$'\t'"$programStorage"$'\t'"$dynamicMemory"$'\t'"$warningCount"$'\t'"$allowFail"$'\t'"$sketchBuildExitCode" >> "$REPORT_FILENAME"

  # If the sketch build failed and failure is not allowed for this test then fail the Travis build after completing all sketch builds
  if [[ "$sketchBuildExitCode" != 0 ]]; then
    if [[ "$allowFail" != "true" ]]; then
      TRAVIS_BUILD_EXIT_CODE=1
    fi
  fi

  # End the folded section of the Travis CI build log
  echo -e "travis_fold:end:build_sketch"
  # Add a useful message to the Travis CI build log
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
