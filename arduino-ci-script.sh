#!/bin/bash
# This script is used to automate continuous integration tasks for Arduino projects
# https://github.com/per1234/arduino-ci-script


# https://docs.travis-ci.com/user/customizing-the-build/#Implementing-Complex-Build-Steps
# -e will cause the script to exit as soon as one command returns a non-zero exit code
set -e

# Save the location of the script
# http://stackoverflow.com/a/246128/7059512
ARDUINO_CI_SCRIPT_FOLDER="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


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
REPORT_FILENAME="travis_ci_job_report_$(printf "%05d\n" "${TRAVIS_BUILD_NUMBER}").$(printf "%03d\n" "$(echo "$TRAVIS_JOB_NUMBER" | cut -d'.' -f 2)").tsv"
REPORT_FOLDER="${HOME}/arduino-ci-script_report"
REPORT_FILE_PATH="${REPORT_FOLDER}/${REPORT_FILENAME}"
# The Arduino IDE returns exit code 255 after a failed file signature verification of the boards manager JSON file. This does not indicate an issue with the sketch and the problem may go away after a retry.
SKETCH_VERIFY_RETRIES=3
REPORT_PUSH_RETRIES=10


# Create the folder if it doesn't exist
function create_folder()
{
  local folderName="$1"
  if ! [[ -d "$folderName" ]]; then
    mkdir --parents "$folderName"
  fi
}


# Create the temporary folder
create_folder "$TEMPORARY_FOLDER"

# Create the report folder
create_folder "$REPORT_FOLDER"


# Add column names to report
echo "Build Timestamp (UTC)"$'\t'"Build"$'\t'"Job"$'\t'"Job URL"$'\t'"Build Trigger"$'\t'"Allow Job Failure"$'\t'"PR#"$'\t'"Branch"$'\t'"Commit"$'\t'"Commit Range"$'\t'"Commit Message"$'\t'"Sketch Filename"$'\t'"Board ID"$'\t'"IDE Version"$'\t'"Program Storage (bytes)"$'\t'"Dynamic Memory (bytes)"$'\t'"# Warnings"$'\t'"Allow Failure"$'\t'"Exit Code"$'\t'"Board Error"$'\r' > "$REPORT_FILE_PATH"


# Start the virtual display required by the Arduino IDE CLI: https://github.com/arduino/Arduino/blob/master/build/shared/manpage.adoc#bugs
# based on https://learn.adafruit.com/continuous-integration-arduino-and-you/testing-your-project
/sbin/start-stop-daemon --start --quiet --pidfile /tmp/custom_xvfb_1.pid --make-pidfile --background --exec /usr/bin/Xvfb -- :1 -ac -screen 0 1280x1024x16
sleep 3
export DISPLAY=:1.0


function set_script_verbosity()
{
  enable_verbosity

  SCRIPT_VERBOSITY_LEVEL="$1"

  if [[ "$SCRIPT_VERBOSITY_LEVEL" == "true" ]]; then
    SCRIPT_VERBOSITY_LEVEL=1
  fi

  if [[ "$SCRIPT_VERBOSITY_LEVEL" == 1 ]]; then
    VERBOSITY_OPTION="--verbose"
    # Show stderr only
    VERBOSITY_REDIRECT="1>/dev/null"
  elif [[ "$SCRIPT_VERBOSITY_LEVEL" == 2 ]]; then
    VERBOSE_SCRIPT_OUTPUT="true"
    MORE_VERBOSE_SCRIPT_OUTPUT="true"
    VERBOSITY_OPTION="--verbose"
    # Show stdout and stderr
    VERBOSITY_REDIRECT=""
  else
    SCRIPT_VERBOSITY_LEVEL=0
    VERBOSITY_OPTION=""
    # Don't show stderr or stdout
    VERBOSITY_REDIRECT="&>/dev/null"
  fi

  disable_verbosity
}


# Deprecated, use set_script_verbosity
function set_verbose_script_output()
{
  enable_verbosity

  if [[ "$VERBOSE_SCRIPT_OUTPUT" == "true" ]]; then
    set_script_verbosity 1
  else
    set_script_verbosity 0
  fi

  disable_verbosity
}


# Deprecated, use set_script_verbosity
function set_more_verbose_script_output()
{
  enable_verbosity

  if [[ "$MORE_VERBOSE_SCRIPT_OUTPUT" == "true" ]]; then
    set_script_verbosity 2
  else
    set_script_verbosity 0
  fi

  disable_verbosity
}


# Turn on verbosity based on the preferences set by set_script_verbosity
function enable_verbosity()
{
  if [[ "$SCRIPT_VERBOSITY_LEVEL" -gt 0 ]]; then
    # "Print shell input lines as they are read."
    # https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
    set -o verbose
  fi
  if [[ "$SCRIPT_VERBOSITY_LEVEL" -gt 1 ]]; then
    set -o verbose
    # "Print a trace of simple commands, for commands, case commands, select commands, and arithmetic for commands and their arguments or associated word lists after they are expanded and before they are executed. The value of the PS4 variable is expanded and the resultant value is printed before the command and its expanded arguments."
    # https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
    set -o xtrace
  fi
}


# Turn off verbosity based on the preferences set by set_verbose_script_output and set_more_verbose_script_output
function disable_verbosity()
{
  set +o verbose
  set +o xtrace
}


# Set default verbosity (must be called after the function definitions
set_script_verbosity 0


function set_application_folder()
{
  enable_verbosity

  APPLICATION_FOLDER="$1"

  disable_verbosity
}


function set_sketchbook_folder()
{
  enable_verbosity

  SKETCHBOOK_FOLDER="$1"

  # Create the sketchbook folder if it doesn't already exist
  create_folder "$SKETCHBOOK_FOLDER"

  disable_verbosity
}


# Deprecated
function set_parameters()
{
  enable_verbosity

  set_application_folder "$1"
  set_sketchbook_folder "$2"

  disable_verbosity
}


# Check for errors with the board definition that don't affect sketch verification
function set_board_testing()
{
  enable_verbosity

  TEST_BOARD="$1"

  disable_verbosity
}


# Install all specified versions of the Arduino IDE
function install_ide()
{
  enable_verbosity

  local startIDEversion="$1"
  local endIDEversion="$2"

  generate_ide_version_list_array "$FULL_IDE_VERSION_LIST_ARRAY" "$startIDEversion" "$endIDEversion"
  INSTALLED_IDE_VERSION_LIST_ARRAY="$GENERATED_IDE_VERSION_LIST_ARRAY"

  # Set "$NEWEST_INSTALLED_IDE_VERSION"
  determine_ide_version_extremes "$INSTALLED_IDE_VERSION_LIST_ARRAY"
  NEWEST_INSTALLED_IDE_VERSION="$DETERMINED_NEWEST_IDE_VERSION"


  # This runs the command contained in the $INSTALLED_IDE_VERSION_LIST_ARRAY string, thus declaring the array locally as $IDEversionListArray. This must be done in any function that uses the array
  # Dummy declaration to fix the "referenced but not assigned" warning.
  local IDEversionListArray
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
    create_folder "$SKETCHBOOK_FOLDER"

    # --save-prefs was added in Arduino IDE 1.5.8
    local regex="1.5.[6-7]"
    if ! [[ "$NEWEST_INSTALLED_IDE_VERSION" =~ $regex ]]; then
      arduino --pref compiler.warning_level=all --pref sketchbook.path="$SKETCHBOOK_FOLDER" --save-prefs
    else
      # Arduino IDE 1.5.6 - 1.5.7 load the GUI if you only set preferences without doing a verify. So I am doing an unnecessary verification just to set the preferences in those versions. Definitely a hack but I prefer to keep the preferences setting code all here instead of cluttering build_sketch and this will pretty much never be used.
      arduino --pref compiler.warning_level=all --pref sketchbook.path="$SKETCHBOOK_FOLDER" --verify "${APPLICATION_FOLDER}/arduino/examples/01.Basics/BareMinimum/BareMinimum.ino"
    fi
  fi

  # Uninstall the IDE
  uninstall_ide_version "$NEWEST_INSTALLED_IDE_VERSION"

  disable_verbosity
}


# Generate an array of Arduino IDE versions as a subset of the list provided in the base array defined by the start and end versions
# This function allows the same code to be shared by install_ide and build_sketch. The generated array is "returned" as a global named "$GENERATED_IDE_VERSION_LIST_ARRAY"
function generate_ide_version_list_array()
{
  enable_verbosity

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


  if [[ "$startIDEversion" == "" || "$startIDEversion" == "all" ]]; then
    # Use the full base array
    GENERATED_IDE_VERSION_LIST_ARRAY="$baseIDEversionArray"

  else
    # Start the array
    GENERATED_IDE_VERSION_LIST_ARRAY="$IDE_VERSION_LIST_ARRAY_DECLARATION"'('

    local regex="\("
    if [[ "$startIDEversion" =~ $regex ]]; then
      # IDE versions list was supplied
      # Convert it to a temporary array
      local suppliedIDEversionListArray="${IDE_VERSION_LIST_ARRAY_DECLARATION}${startIDEversion}"
      eval "$suppliedIDEversionListArray"
      local IDEversion
      for IDEversion in "${IDEversionListArray[@]}"; do
        # Convert any use of "oldest" or "newest" special version names to the actual version number
        if [[ "$IDEversion" == "oldest" ]]; then
          local IDEversion="$DETERMINED_OLDEST_IDE_VERSION"
        elif [[ "$IDEversion" == "newest" ]]; then
          local IDEversion="$DETERMINED_NEWEST_IDE_VERSION"
        fi
        # Add the version to the array
        GENERATED_IDE_VERSION_LIST_ARRAY="${GENERATED_IDE_VERSION_LIST_ARRAY} "'"'"$IDEversion"'"'
      done

    elif [[ "$endIDEversion" == "" ]]; then
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

  disable_verbosity
}


# Determine the oldest and newest (non-hourly unless hourly is the only version on the list) IDE version in the provided array
# The determined versions are "returned" by setting the global variables "$DETERMINED_OLDEST_IDE_VERSION" and "$DETERMINED_NEWEST_IDE_VERSION"
function determine_ide_version_extremes()
{
  enable_verbosity

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

  disable_verbosity
}


function install_ide_version()
{
  enable_verbosity

  local IDEversion="$1"
  sudo mv "${APPLICATION_FOLDER}/arduino-${IDEversion}" "${APPLICATION_FOLDER}/arduino"

  disable_verbosity
}


function uninstall_ide_version()
{
  enable_verbosity

  local IDEversion="$1"
  sudo mv "${APPLICATION_FOLDER}/arduino" "${APPLICATION_FOLDER}/arduino-${IDEversion}"

  disable_verbosity
}


# Install hardware packages
function install_package()
{
  enable_verbosity

  local regex="://"
  if [[ "$1" =~ $regex ]]; then
    # First argument is a URL, do a manual hardware package installation
    # Note: Assumes the package is in the root of the download and has the correct folder structure (e.g. architecture folder added in Arduino IDE 1.5+)

    local packageURL="$1"

    # Create the hardware folder if it doesn't exist
    create_folder "${SKETCHBOOK_FOLDER}/hardware"

    if [[ "$packageURL" =~ \.git$ ]]; then
      # Clone the repository
      cd "${SKETCHBOOK_FOLDER}/hardware"
      git clone "$packageURL"

    else
      cd "$TEMPORARY_FOLDER"

      # Clean up the temporary folder
      rm -f ./*.*

      # Download the package
      wget "$packageURL"

      # Uncompress the package
      # This script handles any compressed file type
      # shellcheck source=/dev/null
      source "${ARDUINO_CI_SCRIPT_FOLDER}/extract.sh"
      extract ./*.*

      # Clean up the temporary folder
      rm -f ./*.*

      # Install the package
      mv ./* "${SKETCHBOOK_FOLDER}/hardware/"
    fi

  elif [[ "$1" == "" ]]; then
    # Install hardware package from this repository
    # https://docs.travis-ci.com/user/environment-variables#Global-Variables
    local packageName
    packageName="$(echo "$TRAVIS_REPO_SLUG" | cut -d'/' -f 2)"
    mkdir --parents "${SKETCHBOOK_FOLDER}/hardware/$packageName"
    cd "$TRAVIS_BUILD_DIR"
    cp --recursive $VERBOSITY_OPTION ./* "${SKETCHBOOK_FOLDER}/hardware/${packageName}"
    # * doesn't copy .travis.yml but that file will be present in the user's installation so it should be there for the tests too
    cp $VERBOSITY_OPTION "${TRAVIS_BUILD_DIR}/.travis.yml" "${SKETCHBOOK_FOLDER}/hardware/${packageName}"

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

  disable_verbosity
}


function install_library()
{
  enable_verbosity

  local libraryIdentifier="$1"
  local newFolderName="$2"

  # Create the libraries folder if it doesn't already exist
  create_folder "${SKETCHBOOK_FOLDER}/libraries"

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
      rm -f ./*.*
      wget "$libraryIdentifier"

      # This script handles any compressed file type
      # shellcheck source=/dev/null
      source "${ARDUINO_CI_SCRIPT_FOLDER}/extract.sh"
      extract ./*.*
      # Clean up the temporary folder
      rm -f ./*.*
      # Install the library
      mv ./* "${SKETCHBOOK_FOLDER}/libraries/${newFolderName}"
    fi

  elif [[ "$libraryIdentifier" == "" ]]; then
    # Install library from the repository
    # https://docs.travis-ci.com/user/environment-variables#Global-Variables
    local libraryName
    libraryName="$(echo "$TRAVIS_REPO_SLUG" | cut -d'/' -f 2)"
    mkdir --parents "${SKETCHBOOK_FOLDER}/libraries/$libraryName"
    cd "$TRAVIS_BUILD_DIR"
    cp --recursive $VERBOSITY_OPTION ./* "${SKETCHBOOK_FOLDER}/libraries/${libraryName}"
    # * doesn't copy .travis.yml but that file will be present in the user's installation so it should be there for the tests too
    cp $VERBOSITY_OPTION "${TRAVIS_BUILD_DIR}/.travis.yml" "${SKETCHBOOK_FOLDER}/libraries/${libraryName}"

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

  disable_verbosity
}


function set_verbose_output_during_compilation()
{
  enable_verbosity

  local verboseOutputDuringCompilation="$1"
  if [[ "$verboseOutputDuringCompilation" == "true" ]]; then
    VERBOSE_BUILD="--verbose"
  else
    VERBOSE_BUILD=""
  fi

  disable_verbosity
}


# Verify the sketch
function build_sketch()
{
  enable_verbosity

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

    # For some reason the failure to install the dummy package causes the build to immediately fail with some IDE versions so I need to configure it to not do that
    set +e
    # The package_index files installed by some versions of the IDE (1.6.5, 1.6.5) can cause compilation to fail for other versions (1.6.5-r4, 1.6.5-r5). Attempting to install a dummy package ensures that the correct version of those files will be installed before the sketch verification.
    # Check if the newest installed IDE version supports --install-boards
    local regex1="1.5.[0-9]"
    local regex2="1.6.[0-3]"
    if ! [[ "$IDEversion" =~ $regex1 || "$IDEversion" =~ $regex2 ]]; then
      eval arduino --install-boards arduino:dummy "$VERBOSITY_REDIRECT"
      if [[ "$SCRIPT_VERBOSITY_LEVEL" -gt 1 ]]; then
        # The warning is printed to stdout
        echo "NOTE: The warning above \"Selected board is not available\" is caused intentionally and does not indicate a problem."
      fi
    fi
    # Apparently the default state should be set -e, this will still allow the build to complete through failed verifications before failing rather than immediately failing
    set -e

    if [[ "$sketchPath" =~ \.ino$ || "$sketchPath" =~ \.pde$ ]]; then
      # A sketch was specified
      build_this_sketch "$sketchPath" "$boardID" "$IDEversion" "$allowFail"
    else
      # Search for all sketches in the path and put them in an array
      # https://github.com/koalaman/shellcheck/wiki/SC2207
      declare -a sketches
      mapfile -t sketches < <(find "$sketchPath" -name "*.pde" -o -name "*.ino")
      local sketchName
      for sketchName in "${sketches[@]}"; do
        # Only verify the sketch that matches the name of the sketch folder, otherwise it will cause redundant verifications for sketches that have multiple .ino files
        local sketchFolder
        sketchFolder="$(echo "$sketchName" | rev | cut -d'/' -f 2 | rev)"
        local sketchNameWithoutPathWithExtension
        sketchNameWithoutPathWithExtension="$(echo "$sketchName" | rev | cut -d'/' -f 1 | rev)"
        local sketchNameWithoutPathWithoutExtension
        sketchNameWithoutPathWithoutExtension="${sketchNameWithoutPathWithExtension%.*}"
        if [[ "$sketchFolder" == "$sketchNameWithoutPathWithoutExtension" ]]; then
          build_this_sketch "$sketchName" "$boardID" "$IDEversion" "$allowFail"
        fi
      done
    fi
    # Uninstall the IDE
    uninstall_ide_version "$IDEversion"
  done

  disable_verbosity
}


function build_this_sketch()
{
  # Fold this section of output in the Travis CI build log to make it easier to read
  echo -e "travis_fold:start:build_sketch"

  enable_verbosity

  local sketchName="$1"
  local boardID="$2"
  local IDEversion="$3"
  local allowFail="$4"

  # Produce a useful label for the fold in the Travis log for this function call
  echo "build_sketch $sketchName $boardID $IDEversion $allowFail"

  # Arduino IDE 1.8.0 and 1.8.1 fail to verify a sketch if the absolute path to it is not specified
  # http://stackoverflow.com/a/3915420/7059512
  local sketchName
  sketchName="$(cd "$(dirname "$1")"; pwd)/$(basename "$1")"

  local sketchBuildExitCode=255
  # Retry the verification if it returns exit code 255
  while [[ "$sketchBuildExitCode" == "255" && $verifyCount -le $SKETCH_VERIFY_RETRIES ]]; do
    # Verify the sketch
    arduino $VERBOSE_BUILD --verify "$sketchName" --board "$boardID" 2>&1 | tee "$VERIFICATION_OUTPUT_FILENAME"; local sketchBuildExitCode="${PIPESTATUS[0]}"
    local verifyCount=$((verifyCount + 1))
  done

  # If the sketch build failed and failure is not allowed for this test then fail the Travis build after completing all sketch builds
  if [[ "$sketchBuildExitCode" != 0 ]]; then
    if [[ "$allowFail" != "true" ]]; then
      TRAVIS_BUILD_EXIT_CODE=1
    fi
  else
    # Parse through the output from the sketch verification to count warnings and determine the compile size
    local warningCount=0
    while read -r outputFileLine; do
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

      # Check for missing bootloader
      if [[ "$TEST_BOARD" == "true" ]]; then
        local regex="Bootloader file specified but missing: "
        if [[ "$outputFileLine" =~ $regex ]] > /dev/null; then
          local boardError="missing bootloader"
          if [[ "$allowFail" != "true" ]]; then
            TRAVIS_BUILD_EXIT_CODE=1
          fi
        fi
      fi
    done < "$VERIFICATION_OUTPUT_FILENAME"

    rm "$VERIFICATION_OUTPUT_FILENAME"

    # Remove the stupid comma from the memory values if present
    local programStorage=${programStorage//,}
    local dynamicMemory=${dynamicMemory//,}
  fi

  # Add the build data to the report file
  echo "$(date -u "+%Y-%m-%d %H:%M:%S")"$'\t'"$TRAVIS_BUILD_NUMBER"$'\t'"$TRAVIS_JOB_NUMBER"$'\t'"https://travis-ci.org/${TRAVIS_REPO_SLUG}/jobs/${TRAVIS_JOB_ID}"$'\t'"$TRAVIS_EVENT_TYPE"$'\t'"$TRAVIS_ALLOW_FAILURE"$'\t'"$TRAVIS_PULL_REQUEST"$'\t'"$TRAVIS_BRANCH"$'\t'"$TRAVIS_COMMIT"$'\t'"$TRAVIS_COMMIT_RANGE"$'\t'"${TRAVIS_COMMIT_MESSAGE%%$'\n'*}"$'\t'"$sketchName"$'\t'"$boardID"$'\t'"$IDEversion"$'\t'"$programStorage"$'\t'"$dynamicMemory"$'\t'"$warningCount"$'\t'"$allowFail"$'\t'"$sketchBuildExitCode"$'\t'"$boardError"$'\r' >> "$REPORT_FILE_PATH"

  # End the folded section of the Travis CI build log
  echo -e "travis_fold:end:build_sketch"
  # Add a useful message to the Travis CI build log

  disable_verbosity

  echo "arduino exit code: $sketchBuildExitCode"
}


# Print the contents of the report file
function display_report()
{
  enable_verbosity

  if [ -e "$REPORT_FILE_PATH" ]; then
    echo -e "\n\n\n**************Begin Report**************\n\n\n"
    cat "$REPORT_FILE_PATH"
    echo -e "\n\n"
  else
    echo "No report file available for this job"
  fi

  disable_verbosity
}


# Add the report file to a Git repository
function publish_report_to_repository()
{
  enable_verbosity

  local token="$1"
  local repositoryURL="$2"
  local reportBranch="$3"
  local reportFolder="$4"
  local doLinkComment="$5"

  if [[ "$token" != "" ]] && [[ "$repositoryURL" != "" ]] && [[ "$reportBranch" != "" ]]; then
    if [ -e "$REPORT_FILE_PATH" ]; then
      # Location is a repository
      git clone $VERBOSITY_OPTION --branch "$reportBranch" "$repositoryURL" "${HOME}/report-repository"; local gitCloneExitCode="${PIPESTATUS[0]}"
      if [[ "$gitCloneExitCode" == 0 ]]; then
        # Clone was successful
        create_folder "${HOME}/report-repository/${reportFolder}"
        cp $VERBOSITY_OPTION "$REPORT_FILE_PATH" "${HOME}/report-repository/${reportFolder}"
        cd "${HOME}/report-repository"
        git add $VERBOSITY_OPTION "${HOME}/report-repository/${reportFolder}/${REPORT_FILENAME}"
        git config user.email "arduino-ci-script@nospam.me"
        git config user.name "arduino-ci-script-bot"
        # Only pushes the current branch to the corresponding remote branch that 'git pull' uses to update the current branch.
        git config push.default simple
        if [[ "$TRAVIS_BUILD_EXIT_CODE" != "" ]]; then
          local jobSuccessMessage="FAILED"
        else
          local jobSuccessMessage="SUCCESSFUL"
        fi
        # Do a pull now in case another job has finished about the same time and pushed a report after the clone happened, which would otherwise cause the push to fail. This is the last chance to pull without having to deal with a merge or rebase.
        git pull
        git commit $VERBOSITY_OPTION --message="Add Travis CI job ${TRAVIS_JOB_NUMBER} report (${jobSuccessMessage})" --message="Job log: https://travis-ci.org/${TRAVIS_REPO_SLUG}/jobs/${TRAVIS_JOB_ID}" --message="Commit: https://github.com/${TRAVIS_REPO_SLUG}/commit/${TRAVIS_COMMIT}" --message="$TRAVIS_COMMIT_MESSAGE" --message="[skip ci]"
        local gitPushExitCode="1"
        local pushCount=0
        while [[ "$gitPushExitCode" != "0" && $pushCount -le $REPORT_PUSH_RETRIES ]]; do
          pushCount=$((pushCount + 1))
          # Do a pull now in case another job has finished about the same time and pushed a report since the last pull. This would require a merge or rebase. Rebase should be safe since the commits will be separate files.
          git pull --rebase
          git push $VERBOSITY_OPTION "https://${token}@${repositoryURL#*//}"; local gitPushExitCode="${PIPESTATUS[0]}"
        done
        rm $VERBOSITY_OPTION --recursive --force "${HOME}/report-repository"
        if [[ "$gitPushExitCode" == "0" ]]; then
          if [[ "$doLinkComment" == "true" ]]; then
            # Only comment if it's job 1
            local regex="\.1$"
            if [[ "$TRAVIS_JOB_NUMBER" =~ $regex ]]; then
              local reportURL
              reportURL="${repositoryURL%.*}/tree/${reportBranch}/${reportFolder}"
              comment_report_link "$token" "$reportURL"
            fi
          fi
        else
          echo "ERROR: Failed to push to remote branch."
        fi
      else
        echo "ERROR: Failed to clone branch ${reportBranch} of repository URL ${repositoryURL}. Do they exist?"
      fi
    else
      echo "No report file available for this job"
    fi
  else
    echo "Publishing report failed. GitHub token, repository URL, and repository branch must be defined to use this function. See https://github.com/per1234/arduino-ci-script#publishing-job-reports for instructions."
  fi

  disable_verbosity
}


# Add the report file to a gist
function publish_report_to_gist()
{
  enable_verbosity

  local token="$1"
  local gistURL="$2"
  local doLinkComment="$3"

  if [[ "$token" != "" ]] && [[ "$gistURL" != "" ]]; then
    if [ -e "$REPORT_FILE_PATH" ]; then
      # Get the gist ID from the gist URL
      local gistID
      gistID="$(echo "$gistURL" | rev | cut -d'/' -f 1 | rev)"

      # http://stackoverflow.com/a/33354920/7059512
      # Sanitize the report file content so it can be sent via a POST request without breaking the JSON
      # Remove \r (from Windows end-of-lines), replace tabs by \t, replace " by \", replace EOL by \n
      local reportContent
      reportContent=$(sed -e 's/\r//' -e's/\t/\\t/g' -e 's/"/\\"/g' "$REPORT_FILE_PATH" | awk '{ printf($0 "\\n") }')

      # Upload the report to the Gist. I have to use the here document to avoid the "Argument list too long" error from curl with long reports. Redirect output to dev/null because it dumps the whole gist to the log
      eval curl --header "\"Authorization: token ${token}\"" --data @- "\"https://api.github.com/gists/${gistID}\"" <<curlDataHere "$VERBOSITY_REDIRECT"
{"files":{"${REPORT_FILENAME}":{"content": "${reportContent}"}}}
curlDataHere

      if [[ "$doLinkComment" == "true" ]]; then
        # Only comment if it's job 1
        local regex="\.1$"
        if [[ "$TRAVIS_JOB_NUMBER" =~ $regex ]]; then
          local reportURL="${gistURL}#file-${REPORT_FILENAME//./-}"
          comment_report_link "$token" "$reportURL"
        fi
      fi
    else
      echo "No report file available for this job"
    fi
  else
    echo "Publishing report failed. GitHub token and gist URL must be defined in your Travis CI settings for this repository in order to use this function. See https://github.com/per1234/arduino-ci-script#publishing-job-reports for instructions."
  fi

  disable_verbosity
}


# Leave a comment on the commit with a link to the report
function comment_report_link()
{
  enable_verbosity

  local token="$1"
  local reportURL="$2"

  eval curl --header "\"Authorization: token ${token}\"" --data \"{'\"'body'\"':'\"'Once completed, the job reports for Travis CI [build ${TRAVIS_BUILD_NUMBER}]\(https://travis-ci.org/${TRAVIS_REPO_SLUG}/builds/${TRAVIS_BUILD_ID}\) will be found at:\\n${reportURL}'\"'}\" "\"https://api.github.com/repos/${TRAVIS_REPO_SLUG}/commits/${TRAVIS_COMMIT}/comments\"" "$VERBOSITY_REDIRECT"

  disable_verbosity
}


# Return 1 if any of the sketch builds failed
function check_success()
{
  enable_verbosity

  if [[ "$TRAVIS_BUILD_EXIT_CODE" != "" ]]; then
    set +e  # without this the build is ended immediately and none of the post-script build steps are run
    return 1
  fi

  disable_verbosity
}
