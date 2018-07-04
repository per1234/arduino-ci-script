#!/bin/bash
# This script is used to automate continuous integration tasks for Arduino projects
# https://github.com/per1234/arduino-ci-script


# Based on https://github.com/adafruit/travis-ci-arduino/blob/eeaeaf8fa253465d18785c2bb589e14ea9893f9f/install.sh#L11
# It seems that arrays can't been seen in other functions. So instead I'm setting $IDE_VERSIONS to a string that is the command to create the array
readonly ARDUINO_CI_SCRIPT_IDE_VERSION_LIST_ARRAY_DECLARATION="declare -a -r IDEversionListArray="

readonly ARDUINO_CI_SCRIPT_TEMPORARY_FOLDER="${HOME}/temporary/arduino-ci-script"
readonly ARDUINO_CI_SCRIPT_IDE_INSTALLATION_FOLDER="arduino"
readonly ARDUINO_CI_SCRIPT_VERIFICATION_OUTPUT_FILENAME="${ARDUINO_CI_SCRIPT_TEMPORARY_FOLDER}/verification_output.txt"
readonly ARDUINO_CI_SCRIPT_REPORT_FILENAME="travis_ci_job_report_$(printf '%05d\n' "${TRAVIS_BUILD_NUMBER}").$(printf '%03d\n' "$(echo "$TRAVIS_JOB_NUMBER" | cut -d'.' -f 2)").tsv"
readonly ARDUINO_CI_SCRIPT_REPORT_FOLDER="${HOME}/arduino-ci-script_report"
readonly ARDUINO_CI_SCRIPT_REPORT_FILE_PATH="${ARDUINO_CI_SCRIPT_REPORT_FOLDER}/${ARDUINO_CI_SCRIPT_REPORT_FILENAME}"
# The arduino manpage(https://github.com/arduino/Arduino/blob/master/build/shared/manpage.adoc#exit-status) documents a range of exit statuses. These exit statuses indicate success, invalid arduino command, or compilation failed due to legitimate code errors. arduino sometimes returns other exit statuses that may indicate problems that may go away after a retry.
readonly ARDUINO_CI_SCRIPT_HIGHEST_ACCEPTABLE_ARDUINO_EXIT_STATUS=4
readonly ARDUINO_CI_SCRIPT_SKETCH_VERIFY_RETRIES=3
readonly ARDUINO_CI_SCRIPT_REPORT_PUSH_RETRIES=10

readonly ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS=0
readonly ARDUINO_CI_SCRIPT_FAILURE_EXIT_STATUS=1

# Arduino IDE 1.8.2 and newer generates a ton of garbage output (appears to be something related to jmdns) that must be filtered for the log to be readable and to avoid exceeding the maximum log length
readonly ARDUINO_CI_SCRIPT_ARDUINO_OUTPUT_FILTER_REGEX='(^\[SocketListener\(travis-job-*|^  *[0-9][0-9]*: [0-9a-g][0-9a-g]*|^dns\[query,[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*:[0-9][0-9]*, length=[0-9][0-9]*, id=|^dns\[response,[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*:[0-9][0-9]*, length=[0-9][0-9]*, id=|^questions:$|\[DNSQuestion@|type: TYPE_IGNORE|^\.\]$|^\.\]\]$|^.\.\]$|^.\.\]\]$)'

# Default value
ARDUINO_CI_SCRIPT_TOTAL_SKETCH_BUILD_FAILURE_COUNT=0

# Set the arduino command name according to OS (on Windows arduino_debug should be used)
if [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]]; then
  ARDUINO_CI_SCRIPT_ARDUINO_COMMAND="arduino_debug"
else
  ARDUINO_CI_SCRIPT_ARDUINO_COMMAND="arduino"
fi


# Create the folder if it doesn't exist
function create_folder()
{
  local -r folderName="$1"
  if ! [[ -d "$folderName" ]]; then
    # shellcheck disable=SC2086
    mkdir --parents $ARDUINO_CI_SCRIPT_VERBOSITY_OPTION "$folderName"
  fi
}


function set_script_verbosity()
{
  enable_verbosity

  ARDUINO_CI_SCRIPT_VERBOSITY_LEVEL="$1"

  if [[ "$ARDUINO_CI_SCRIPT_VERBOSITY_LEVEL" == "true" ]]; then
    ARDUINO_CI_SCRIPT_VERBOSITY_LEVEL=1
  fi

  if [[ "$ARDUINO_CI_SCRIPT_VERBOSITY_LEVEL" -eq 1 ]]; then
    ARDUINO_CI_SCRIPT_VERBOSITY_OPTION="--verbose"
    ARDUINO_CI_SCRIPT_QUIET_OPTION=""
    # Show stderr only
    ARDUINO_CI_SCRIPT_VERBOSITY_REDIRECT="1>/dev/null"
  elif [[ "$ARDUINO_CI_SCRIPT_VERBOSITY_LEVEL" -eq 2 ]]; then
    ARDUINO_CI_SCRIPT_VERBOSITY_OPTION="--verbose"
    ARDUINO_CI_SCRIPT_QUIET_OPTION=""
    # Show stdout and stderr
    ARDUINO_CI_SCRIPT_VERBOSITY_REDIRECT=""
  else
    ARDUINO_CI_SCRIPT_VERBOSITY_LEVEL=0
    ARDUINO_CI_SCRIPT_VERBOSITY_OPTION=""
    # cabextract only takes the short option name so this is more universally useful than --quiet
    ARDUINO_CI_SCRIPT_QUIET_OPTION="-q"
    # Don't show stderr or stdout
    ARDUINO_CI_SCRIPT_VERBOSITY_REDIRECT="&>/dev/null"
  fi

  disable_verbosity
}


# Deprecated, use set_script_verbosity
function set_verbose_script_output()
{
  set_script_verbosity 1
}


# Deprecated, use set_script_verbosity
function set_more_verbose_script_output()
{
  set_script_verbosity 2
}


# Turn on verbosity based on the preferences set by set_script_verbosity
function enable_verbosity()
{
  # Store previous verbosity settings so they can be set back to their original values at the end of the function
  shopt -q -o verbose
  ARDUINO_CI_SCRIPT_PREVIOUS_VERBOSE_SETTING="$?"

  shopt -q -o xtrace
  ARDUINO_CI_SCRIPT_PREVIOUS_XTRACE_SETTING="$?"

  if [[ "$ARDUINO_CI_SCRIPT_VERBOSITY_LEVEL" -gt 0 ]]; then
    # "Print shell input lines as they are read."
    # https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
    set -o verbose
  fi
  if [[ "$ARDUINO_CI_SCRIPT_VERBOSITY_LEVEL" -gt 1 ]]; then
    # "Print a trace of simple commands, for commands, case commands, select commands, and arithmetic for commands and their arguments or associated word lists after they are expanded and before they are executed. The value of the PS4 variable is expanded and the resultant value is printed before the command and its expanded arguments."
    # https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
    set -o xtrace
  fi
}


# Return verbosity settings to their previous values
function disable_verbosity()
{
  if [[ "$ARDUINO_CI_SCRIPT_PREVIOUS_VERBOSE_SETTING" == "0" ]]; then
    set -o verbose
  else
    set +o verbose
  fi

  if [[ "$ARDUINO_CI_SCRIPT_PREVIOUS_XTRACE_SETTING" == "0" ]]; then
    set -o xtrace
  else
    set +o xtrace
  fi
}


# Verbosity and, in some cases, errexit must be disabled before an early return from a public function, this allows it to be done in a single line instead of two
function return_handler()
{
  local -r exitStatus="$1"

  # If exit status is success and errexit is enabled then it must be disabled before exiting the script because errexit must be disabled by default and only enabled in the functions that specifically require it.
  # If exit status is not success then errexit should not be disabled, otherwise Travis CI won't fail the build even though the exit status was failure.
  if [[ "$exitStatus" == "$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS" ]] && shopt -q -o errexit; then
      set +o errexit
  fi

  disable_verbosity

  return "$exitStatus"
}


function set_application_folder()
{
  enable_verbosity

  ARDUINO_CI_SCRIPT_APPLICATION_FOLDER="$1"

  disable_verbosity
}


function set_sketchbook_folder()
{
  enable_verbosity

  ARDUINO_CI_SCRIPT_SKETCHBOOK_FOLDER="$1"

  # Create the sketchbook folder if it doesn't already exist
  create_folder "$ARDUINO_CI_SCRIPT_SKETCHBOOK_FOLDER"

  # Set sketchbook location preference if the IDE is already installed
  if [[ "$INSTALLED_IDE_VERSION_LIST_ARRAY" != "" ]]; then
    set_ide_preference "sketchbook.path=$ARDUINO_CI_SCRIPT_SKETCHBOOK_FOLDER"
  fi

  disable_verbosity
}


# Deprecated
function set_parameters()
{
  set_application_folder "$1"
  set_sketchbook_folder "$2"
}


# Check for errors with the board definition that don't affect sketch verification
function set_board_testing()
{
  enable_verbosity

  ARDUINO_CI_SCRIPT_TEST_BOARD="$1"

  disable_verbosity
}


# Check for errors with libraries that don't affect sketch verification
function set_library_testing()
{
  enable_verbosity

  ARDUINO_CI_SCRIPT_TEST_LIBRARY="$1"

  disable_verbosity
}


# Install all specified versions of the Arduino IDE
function install_ide()
{
  enable_verbosity

  local -r startIDEversion="$1"
  local -r endIDEversion="$2"

  # https://docs.travis-ci.com/user/customizing-the-build/#Implementing-Complex-Build-Steps
  # set -o errexit will cause the script to exit as soon as any command returns a non-zero exit status. Without this the success of the function call is determined by the exit status of the last command in the function
  set -o errexit

  # Generate an array declaration string containing a list all Arduino IDE versions which support CLI (1.5.2+ according to https://github.com/arduino/Arduino/blob/master/build/shared/manpage.adoc#history)
  # Save the current folder
  local -r previousFolder="$PWD"
  cd "$ARDUINO_CI_SCRIPT_TEMPORARY_FOLDER"
  # Create empty local repo for the purpose of getting a list of tags in the arduino/Arduino repository
  git init --quiet Arduino
  cd Arduino
  git remote add origin https://github.com/arduino/Arduino.git
  if [[ "$startIDEversion" != "1.6.2" ]] && [[ "$startIDEversion" != "1.6.2" ]]; then
    # Arduino IDE 1.6.2 has the nasty behavior of moving the included hardware cores to the .arduino15 folder, causing those versions to be used for all builds after Arduino IDE 1.6.2 is used. For that reason, 1.6.2 will only be installed if explicitely specified in the install_ide version arguments
    local -r IDEversion162regex=--regex='refs/tags/1\.6\.2'
    if [[ "$ARDUINO_CI_SCRIPT_VERBOSITY_LEVEL" -gt 0 ]]; then
      echo "NOTE: Due to not playing nicely with other versions, Arduino IDE 1.6.2 will not be installed unless explicitly specified in the version arguments."
    fi
  fi
  local -r ARDUINO_CI_SCRIPT_FULL_IDE_VERSION_LIST_ARRAY="${ARDUINO_CI_SCRIPT_IDE_VERSION_LIST_ARRAY_DECLARATION}'(\"$(git ls-remote --quiet --tags --refs  | grep --invert-match --regexp='refs/tags/1\.0' --regexp='refs/tags/1\.5$' --regexp='refs/tags/1\.5\.1$' --regexp='refs/tags/1\.5\.4-r2$' --regexp='refs/tags/1\.5\.5-r2$' --regexp='refs/tags/1\.5\.7-macosx-java7$' --regexp='refs/tags/1\.5\.8-macosx-java7$' ${IDEversion162regex} --regexp='refs/tags/1\.6\.5-r2$' --regexp='refs/tags/1\.6\.5-r3$' | grep --regexp='refs/tags/[0-9]\+\.[0-9]\+\.[0-9]\+\(\(-.*$\)\|$\)' | cut --delimiter='/' --fields=3 | sort --version-sort | sed ':a;N;$!ba;s/\n/\" \"/g')\")'"
  cd ..
  # Remove the temporary repo
  rm Arduino --recursive --force
  # Go back to the previous folder location
  cd "$previousFolder"

  # Determine list of IDE versions to install
  generate_ide_version_list_array "$ARDUINO_CI_SCRIPT_FULL_IDE_VERSION_LIST_ARRAY" "$startIDEversion" "$endIDEversion"
  INSTALLED_IDE_VERSION_LIST_ARRAY="$ARDUINO_CI_SCRIPT_GENERATED_IDE_VERSION_LIST_ARRAY"

  # Set "$NEWEST_INSTALLED_IDE_VERSION"
  determine_ide_version_extremes "$INSTALLED_IDE_VERSION_LIST_ARRAY"
  NEWEST_INSTALLED_IDE_VERSION="$ARDUINO_CI_SCRIPT_DETERMINED_NEWEST_IDE_VERSION"

  if [[ "$ARDUINO_CI_SCRIPT_APPLICATION_FOLDER" == "" ]]; then
    echo "ERROR: Application folder was not set. Please use the set_application_folder function to define the location of the application folder."
    return_handler "$ARDUINO_CI_SCRIPT_FAILURE_EXIT_STATUS"
  fi
  create_folder "$ARDUINO_CI_SCRIPT_APPLICATION_FOLDER"

  # This runs the command contained in the $INSTALLED_IDE_VERSION_LIST_ARRAY string, thus declaring the array locally as $IDEversionListArray. This must be done in any function that uses the array
  # Dummy declaration to fix the "referenced but not assigned" warning.
  local IDEversionListArray
  eval "$INSTALLED_IDE_VERSION_LIST_ARRAY"
  local IDEversion
  for IDEversion in "${IDEversionListArray[@]}"; do
    local IDEinstallFolder="$ARDUINO_CI_SCRIPT_APPLICATION_FOLDER/arduino-${IDEversion}"

    # Don't unnecessarily install the IDE
    if ! [[ -d "$IDEinstallFolder" ]]; then
      if [[ "$ARDUINO_CI_SCRIPT_VERBOSITY_LEVEL" -eq 0 ]]; then
        # If the download/installation process is going slowly when installing a lot of IDE versions this function may cause the build to fail due to exceeding Travis CI's 10 minutes without log output timeout so it's necessary to periodically print something.
        echo "Installing: $IDEversion"
      fi

      # Determine download file extension
      local tgzExtensionVersionsRegex="^1\.5\.[0-9]$"
      if [[ "$IDEversion" =~ $tgzExtensionVersionsRegex ]]; then
        # The download file extension prior to 1.6.0 is .tgz
        local downloadFileExtension="tgz"
      else
        local downloadFileExtension="tar.xz"
      fi

      if [[ "$IDEversion" == "hourly" ]]; then
        # Deal with the inaccurate name given to the hourly build download
        local downloadVersion="nightly"
      else
        local downloadVersion="$IDEversion"
      fi

      wget --no-verbose $ARDUINO_CI_SCRIPT_QUIET_OPTION "http://downloads.arduino.cc/arduino-${downloadVersion}-linux64.${downloadFileExtension}"
      tar --extract --file="arduino-${downloadVersion}-linux64.${downloadFileExtension}"
      rm $ARDUINO_CI_SCRIPT_VERBOSITY_OPTION "arduino-${downloadVersion}-linux64.${downloadFileExtension}"
      mv $ARDUINO_CI_SCRIPT_VERBOSITY_OPTION "arduino-${downloadVersion}" "$IDEinstallFolder"
    fi
  done

  set_ide_preference "compiler.warning_level=all"

  # If a sketchbook location has been defined then set the location in the Arduino IDE preferences
  if [[ -d "$ARDUINO_CI_SCRIPT_SKETCHBOOK_FOLDER" ]]; then
    set_ide_preference "sketchbook.path=$ARDUINO_CI_SCRIPT_SKETCHBOOK_FOLDER"
  fi

  # Return errexit to the default state
  set +o errexit

  disable_verbosity
}


# Generate an array of Arduino IDE versions as a subset of the list provided in the base array defined by the start and end versions
# This function allows the same code to be shared by install_ide and build_sketch. The generated array is "returned" as a global named "$ARDUINO_CI_SCRIPT_GENERATED_IDE_VERSION_LIST_ARRAY"
function generate_ide_version_list_array()
{
  local -r baseIDEversionArray="$1"
  local startIDEversion="$2"
  local endIDEversion="$3"

  # Convert "oldest" or "newest" to actual version numbers
  determine_ide_version_extremes "$baseIDEversionArray"
  if [[ "$startIDEversion" == "oldest" ]]; then
    startIDEversion="$ARDUINO_CI_SCRIPT_DETERMINED_OLDEST_IDE_VERSION"
  elif [[ "$startIDEversion" == "newest" ]]; then
    startIDEversion="$ARDUINO_CI_SCRIPT_DETERMINED_NEWEST_IDE_VERSION"
  fi

  if [[ "$endIDEversion" == "oldest" ]]; then
    endIDEversion="$ARDUINO_CI_SCRIPT_DETERMINED_OLDEST_IDE_VERSION"
  elif [[ "$endIDEversion" == "newest" ]]; then
    endIDEversion="$ARDUINO_CI_SCRIPT_DETERMINED_NEWEST_IDE_VERSION"
  fi


  if [[ "$startIDEversion" == "" || "$startIDEversion" == "all" ]]; then
    # Use the full base array
    ARDUINO_CI_SCRIPT_GENERATED_IDE_VERSION_LIST_ARRAY="$baseIDEversionArray"

  else
    local rawIDElist
    local -r IDEversionListRegex='\('
    if [[ "$startIDEversion" =~ $IDEversionListRegex ]]; then
      # IDE versions list was supplied
      # Convert it to a temporary array
      local -r suppliedIDEversionListArray="${ARDUINO_CI_SCRIPT_IDE_VERSION_LIST_ARRAY_DECLARATION}${startIDEversion}"
      eval "$suppliedIDEversionListArray"
      local IDEversion
      for IDEversion in "${IDEversionListArray[@]}"; do
        # Convert any use of "oldest" or "newest" special version names to the actual version number
        if [[ "$IDEversion" == "oldest" ]]; then
          IDEversion="$ARDUINO_CI_SCRIPT_DETERMINED_OLDEST_IDE_VERSION"
        elif [[ "$IDEversion" == "newest" ]]; then
          IDEversion="$ARDUINO_CI_SCRIPT_DETERMINED_NEWEST_IDE_VERSION"
        fi
        # Add the version to the array
        rawIDElist="${rawIDElist} "'"'"$IDEversion"'"'
      done

    elif [[ "$endIDEversion" == "" ]]; then
      # Only a single version was specified
      rawIDElist="$rawIDElist"'"'"$startIDEversion"'"'

    else
      # A version range was specified
      eval "$baseIDEversionArray"
      local IDEversion
      for IDEversion in "${IDEversionListArray[@]}"; do
        if [[ "$IDEversion" == "$startIDEversion" ]]; then
          # Start of the list reached, set a flag
          local -r listIsStarted="true"
        fi

        if [[ "$listIsStarted" == "true" ]]; then
          # Add the version to the list
          rawIDElist="${rawIDElist} "'"'"$IDEversion"'"'
        fi

        if [[ "$IDEversion" == "$endIDEversion" ]]; then
          # End of the list was reached, exit the loop
          break
        fi
      done
    fi

    # Turn the raw IDE version list into an array
    declare -a -r rawIDElistArray="(${rawIDElist})"

    # Remove duplicates from list https://stackoverflow.com/a/13648438
    # shellcheck disable=SC2207
    readonly local uniqueIDElistArray=($(echo "${rawIDElistArray[@]}" | tr ' ' '\n' | sort --unique --version-sort | tr '\n' ' '))

    # Generate ARDUINO_CI_SCRIPT_GENERATED_IDE_VERSION_LIST_ARRAY
    ARDUINO_CI_SCRIPT_GENERATED_IDE_VERSION_LIST_ARRAY="$ARDUINO_CI_SCRIPT_IDE_VERSION_LIST_ARRAY_DECLARATION"'('
    for uniqueIDElistArrayIndex in "${!uniqueIDElistArray[@]}"; do
      ARDUINO_CI_SCRIPT_GENERATED_IDE_VERSION_LIST_ARRAY="${ARDUINO_CI_SCRIPT_GENERATED_IDE_VERSION_LIST_ARRAY} "'"'"${uniqueIDElistArray[$uniqueIDElistArrayIndex]}"'"'
    done
    ARDUINO_CI_SCRIPT_GENERATED_IDE_VERSION_LIST_ARRAY="$ARDUINO_CI_SCRIPT_GENERATED_IDE_VERSION_LIST_ARRAY"')'
  fi
}


# Determine the oldest and newest (non-hourly unless hourly is the only version on the list) IDE version in the provided array
# The determined versions are "returned" by setting the global variables "$ARDUINO_CI_SCRIPT_DETERMINED_OLDEST_IDE_VERSION" and "$ARDUINO_CI_SCRIPT_DETERMINED_NEWEST_IDE_VERSION"
function determine_ide_version_extremes()
{
  local -r baseIDEversionArray="$1"

  # Reset the variables from any value they were assigned the last time the function was ran
  ARDUINO_CI_SCRIPT_DETERMINED_OLDEST_IDE_VERSION=""
  ARDUINO_CI_SCRIPT_DETERMINED_NEWEST_IDE_VERSION=""

  # Determine the oldest and newest (non-hourly) IDE version in the base array
  eval "$baseIDEversionArray"
  local IDEversion
  for IDEversion in "${IDEversionListArray[@]}"; do
    if [[ "$ARDUINO_CI_SCRIPT_DETERMINED_OLDEST_IDE_VERSION" == "" ]]; then
      ARDUINO_CI_SCRIPT_DETERMINED_OLDEST_IDE_VERSION="$IDEversion"
    fi
    if [[ "$ARDUINO_CI_SCRIPT_DETERMINED_NEWEST_IDE_VERSION" == "" || "$IDEversion" != "hourly" ]]; then
      ARDUINO_CI_SCRIPT_DETERMINED_NEWEST_IDE_VERSION="$IDEversion"
    fi
  done
}


function set_ide_preference()
{
  local -r preferenceString="$1"

  # --pref option is only supported by Arduino IDE 1.5.6 and newer
  local -r unsupportedPrefOptionVersionsRegex="^1\.5\.[0-5]$"
  if ! [[ "$NEWEST_INSTALLED_IDE_VERSION" =~ $unsupportedPrefOptionVersionsRegex ]]; then
    install_ide_version "$NEWEST_INSTALLED_IDE_VERSION"

    # --save-prefs was added in Arduino IDE 1.5.8
    local -r unsupportedSavePrefsOptionVersionsRegex="^1\.5\.[6-7]$"
    if ! [[ "$NEWEST_INSTALLED_IDE_VERSION" =~ $unsupportedSavePrefsOptionVersionsRegex ]]; then
      # shellcheck disable=SC2086
      eval \"${ARDUINO_CI_SCRIPT_APPLICATION_FOLDER}/${ARDUINO_CI_SCRIPT_IDE_INSTALLATION_FOLDER}/${ARDUINO_CI_SCRIPT_ARDUINO_COMMAND}\" --pref "$preferenceString" --save-prefs "$ARDUINO_CI_SCRIPT_VERBOSITY_REDIRECT"
    else
      # Arduino IDE 1.5.6 - 1.5.7 load the GUI if you only set preferences without doing a verify. So I am doing an unnecessary verification just to set the preferences in those versions. Definitely a hack but I prefer to keep the preferences setting code all here instead of cluttering build_sketch and this will pretty much never be used.
      # shellcheck disable=SC2086
      eval \"${ARDUINO_CI_SCRIPT_APPLICATION_FOLDER}/${ARDUINO_CI_SCRIPT_IDE_INSTALLATION_FOLDER}/${ARDUINO_CI_SCRIPT_ARDUINO_COMMAND}\" --pref "$preferenceString" --verify "${ARDUINO_CI_SCRIPT_APPLICATION_FOLDER}/arduino/examples/01.Basics/BareMinimum/BareMinimum.ino" "$ARDUINO_CI_SCRIPT_VERBOSITY_REDIRECT"
    fi
  fi
}


function install_ide_version()
{
  local -r IDEversion="$1"

  # Create a symbolic link so that the Arduino IDE can always be referenced by the user from the same path no matter which version is being used.
  if [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]]; then
    # git-bash's ln just does a copy instead of making a symlink, which takes forever and fails when the target folder exists (despite --force), which takes forever.
    # Therefore, use the native Windows command mklink to create a directory junction instead.
    # Using a directory junction instead of symlink because supposedly a symlink requires admin privileges.

    # Windows doesn't seem to provide any way to overwrite directory junctions
    if [[ -d "${ARDUINO_CI_SCRIPT_APPLICATION_FOLDER}/${ARDUINO_CI_SCRIPT_IDE_INSTALLATION_FOLDER}" ]]; then
      rm --recursive --force "${ARDUINO_CI_SCRIPT_APPLICATION_FOLDER}/${ARDUINO_CI_SCRIPT_IDE_INSTALLATION_FOLDER:?}"
    fi
    # https://stackoverflow.com/a/25394801
    cmd <<< "mklink /J \"${ARDUINO_CI_SCRIPT_APPLICATION_FOLDER}\\${ARDUINO_CI_SCRIPT_IDE_INSTALLATION_FOLDER}\" \"${ARDUINO_CI_SCRIPT_APPLICATION_FOLDER//\//\\}\\arduino-${IDEversion}\"" > /dev/null
  else
    ln --symbolic --force --no-dereference $ARDUINO_CI_SCRIPT_VERBOSITY_OPTION "${ARDUINO_CI_SCRIPT_APPLICATION_FOLDER}/arduino-${IDEversion}" "${ARDUINO_CI_SCRIPT_APPLICATION_FOLDER}/${ARDUINO_CI_SCRIPT_IDE_INSTALLATION_FOLDER}"
  fi
}


# Install hardware packages
function install_package()
{
  enable_verbosity

  set -o errexit

  local -r URLregex="://"
  if [[ "$1" =~ $URLregex ]]; then
    # First argument is a URL, do a manual hardware package installation
    # Note: Assumes the package is in the root of the download and has the correct folder structure (e.g. architecture folder added in Arduino IDE 1.5+)

    local -r packageURL="$1"

    # Create the hardware folder if it doesn't exist
    create_folder "${ARDUINO_CI_SCRIPT_SKETCHBOOK_FOLDER}/hardware"

    if [[ "$packageURL" =~ \.git$ ]]; then
      # Clone the repository
      local -r branchName="$2"

      local -r previousFolder="$PWD"
      cd "${ARDUINO_CI_SCRIPT_SKETCHBOOK_FOLDER}/hardware"

      if [[ "$branchName" == "" ]]; then
        git clone --quiet "$packageURL"
      else
        git clone --quiet --branch "$branchName" "$packageURL"
      fi
      cd "$previousFolder"
    else
      local -r previousFolder="$PWD"
      cd "$ARDUINO_CI_SCRIPT_TEMPORARY_FOLDER"

      # Delete everything from the temporary folder
      find ./ -mindepth 1 -delete

      # Download the package
      wget --no-verbose $ARDUINO_CI_SCRIPT_QUIET_OPTION "$packageURL"

      # Uncompress the package
      extract ./*.*

      # Delete all files from the temporary folder
      find ./ -type f -maxdepth 1 -delete

      # Install the package
      mv $ARDUINO_CI_SCRIPT_VERBOSITY_OPTION ./* "${ARDUINO_CI_SCRIPT_SKETCHBOOK_FOLDER}/hardware/"
      cd "$previousFolder"
    fi

  elif [[ "$1" == "" ]]; then
    # Install hardware package from this repository
    # https://docs.travis-ci.com/user/environment-variables#Global-Variables
    local packageName
    packageName="$(echo "$TRAVIS_REPO_SLUG" | cut -d'/' -f 2)"
    mkdir --parents $ARDUINO_CI_SCRIPT_VERBOSITY_OPTION "${ARDUINO_CI_SCRIPT_SKETCHBOOK_FOLDER}/hardware/$packageName"
    local -r previousFolder="$PWD"
    cd "$TRAVIS_BUILD_DIR"
    cp --recursive $ARDUINO_CI_SCRIPT_VERBOSITY_OPTION ./* "${ARDUINO_CI_SCRIPT_SKETCHBOOK_FOLDER}/hardware/${packageName}"
    # * doesn't copy .travis.yml but that file will be present in the user's installation so it should be there for the tests too
    cp $ARDUINO_CI_SCRIPT_VERBOSITY_OPTION "${TRAVIS_BUILD_DIR}/.travis.yml" "${ARDUINO_CI_SCRIPT_SKETCHBOOK_FOLDER}/hardware/${packageName}"
    cd "$previousFolder"

  else
    # Install package via Boards Manager

    local -r packageID="$1"
    local -r packageURL="$2"

    # Check if Arduino IDE is installed
    if [[ "$INSTALLED_IDE_VERSION_LIST_ARRAY" == "" ]]; then
      echo "ERROR: Installing a hardware package via Boards Manager requires the Arduino IDE to be installed. Please call install_ide before this command."
      return_handler "$ARDUINO_CI_SCRIPT_FAILURE_EXIT_STATUS"
    fi

    # Check if the newest installed IDE version supports --install-boards
    local -r unsupportedInstallBoardsOptionVersionsRange1regex="^1\.5\.[0-9]$"
    local -r unsupportedInstallBoardsOptionVersionsRange2regex="^1\.6\.[0-3]$"
    if [[ "$NEWEST_INSTALLED_IDE_VERSION" =~ $unsupportedInstallBoardsOptionVersionsRange1regex || "$NEWEST_INSTALLED_IDE_VERSION" =~ $unsupportedInstallBoardsOptionVersionsRange2regex ]]; then
      echo "ERROR: --install-boards option is not supported by the newest version of the Arduino IDE you have installed. You must have Arduino IDE 1.6.4 or newer installed to use this function."
      return_handler "$ARDUINO_CI_SCRIPT_FAILURE_EXIT_STATUS"
    else
      # Temporarily install the latest IDE version to use for the package installation
      install_ide_version "$NEWEST_INSTALLED_IDE_VERSION"

      # If defined add the boards manager URL to preferences
      if [[ "$packageURL" != "" ]]; then
        # Get the current Additional Boards Manager URLs preference value so it won't be overwritten when the new URL is added
        local priorBoardsmanagerAdditionalURLs
        if [[ "$ARDUINO_CI_SCRIPT_VERBOSITY_LEVEL" -eq 0 ]]; then
          priorBoardsmanagerAdditionalURLs=$("${ARDUINO_CI_SCRIPT_APPLICATION_FOLDER}/${ARDUINO_CI_SCRIPT_IDE_INSTALLATION_FOLDER}/${ARDUINO_CI_SCRIPT_ARDUINO_COMMAND}" --get-pref boardsmanager.additional.urls 2>/dev/null | tail --lines=1)
        elif [[ "$ARDUINO_CI_SCRIPT_VERBOSITY_LEVEL" -eq 1 ]]; then
          priorBoardsmanagerAdditionalURLs=$("${ARDUINO_CI_SCRIPT_APPLICATION_FOLDER}/${ARDUINO_CI_SCRIPT_IDE_INSTALLATION_FOLDER}/${ARDUINO_CI_SCRIPT_ARDUINO_COMMAND}" --get-pref boardsmanager.additional.urls | tail --lines=1)
        else
          priorBoardsmanagerAdditionalURLs=$("${ARDUINO_CI_SCRIPT_APPLICATION_FOLDER}/${ARDUINO_CI_SCRIPT_IDE_INSTALLATION_FOLDER}/${ARDUINO_CI_SCRIPT_ARDUINO_COMMAND}" --get-pref boardsmanager.additional.urls | tee /dev/tty | tail --lines=1)
        fi
        local -r blankregex="^[ ]*$"
        if [[ "$priorBoardsmanagerAdditionalURLs" =~ $blankregex ]]; then
          # There is no previous Additional Boards Manager URLs preference value
          local boardsmanagerAdditionalURLs="$packageURL"
        else
          # There is a previous Additional Boards Manager URLs preference value so append the new one to the end of it
          local boardsmanagerAdditionalURLs="${priorBoardsmanagerAdditionalURLs},${packageURL}"
        fi

        # grep returns 1 when a line matches the regular expression so it's necessary to unset errexit
        set +o errexit
        # shellcheck disable=SC2086
        eval \"${ARDUINO_CI_SCRIPT_APPLICATION_FOLDER}/${ARDUINO_CI_SCRIPT_IDE_INSTALLATION_FOLDER}/${ARDUINO_CI_SCRIPT_ARDUINO_COMMAND}\" --pref boardsmanager.additional.urls="$boardsmanagerAdditionalURLs" --save-prefs "$ARDUINO_CI_SCRIPT_VERBOSITY_REDIRECT" | tr -Cd '[:print:]\n\t' | tr --squeeze-repeats '\n'| grep --extended-regexp --invert-match "$ARDUINO_CI_SCRIPT_ARDUINO_OUTPUT_FILTER_REGEX"; local -r arduinoPreferenceSettingExitStatus="${PIPESTATUS[0]}"
        set -o errexit
        # this is required because otherwise the exit status of arduino is ignored
        if [[ "$arduinoPreferenceSettingExitStatus" != "$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS" ]]; then
          return_handler "$arduinoPreferenceSettingExitStatus"
        fi
      fi

      # Install the package
      # grep returns 1 when a line matches the regular expression so it's necessary to unset errexit
      set +o errexit
      # shellcheck disable=SC2086
      eval \"${ARDUINO_CI_SCRIPT_APPLICATION_FOLDER}/${ARDUINO_CI_SCRIPT_IDE_INSTALLATION_FOLDER}/${ARDUINO_CI_SCRIPT_ARDUINO_COMMAND}\" --install-boards "$packageID" "$ARDUINO_CI_SCRIPT_VERBOSITY_REDIRECT" | tr -Cd '[:print:]\n\t' | tr --squeeze-repeats '\n'| grep --extended-regexp --invert-match "$ARDUINO_CI_SCRIPT_ARDUINO_OUTPUT_FILTER_REGEX"; local -r arduinoInstallPackageExitStatus="${PIPESTATUS[0]}"
      set -o errexit
      # this is required because otherwise the exit status of arduino is ignored
      if [[ "$arduinoInstallPackageExitStatus" != "$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS" ]]; then
        return_handler "$arduinoPreferenceSettingExitStatus"
      fi

    fi
  fi

  set +o errexit

  disable_verbosity
}


function install_library()
{
  enable_verbosity

  set -o errexit

  local -r libraryIdentifier="$1"

  # Create the libraries folder if it doesn't already exist
  create_folder "${ARDUINO_CI_SCRIPT_SKETCHBOOK_FOLDER}/libraries"

  local -r URLregex="://"
  if [[ "$libraryIdentifier" =~ $URLregex ]]; then
    # The argument is a URL
    # Note: this assumes the library is in the root of the file
    if [[ "$libraryIdentifier" =~ \.git$ ]]; then
      # Clone the repository
      local -r branchName="$2"
      local -r newFolderName="$3"

      local -r previousFolder="$PWD"
      cd "${ARDUINO_CI_SCRIPT_SKETCHBOOK_FOLDER}/libraries"

      if [[ "$branchName" == "" && "$newFolderName" == "" ]]; then
        git clone --quiet "$libraryIdentifier"
      elif [[ "$branchName" == "" ]]; then
        git clone --quiet "$libraryIdentifier" "$newFolderName"
      elif [[ "$newFolderName" == "" ]]; then
        git clone --quiet --branch "$branchName" "$libraryIdentifier"
      else
        git clone --quiet --branch "$branchName" "$libraryIdentifier" "$newFolderName"
      fi
      cd "$previousFolder"
    else
      # Assume it's a compressed file
      local -r newFolderName="$2"
      # Download the file to the temporary folder
      local -r previousFolder="$PWD"
      cd "$ARDUINO_CI_SCRIPT_TEMPORARY_FOLDER"

      # Delete everything from the temporary folder
      find ./ -mindepth 1 -delete

      wget --no-verbose $ARDUINO_CI_SCRIPT_QUIET_OPTION "$libraryIdentifier"

      extract ./*.*

      # Delete all files from the temporary folder
      find ./ -type f -maxdepth 1 -delete

      # Install the library
      mv $ARDUINO_CI_SCRIPT_VERBOSITY_OPTION ./* "${ARDUINO_CI_SCRIPT_SKETCHBOOK_FOLDER}/libraries/${newFolderName}"
      cd "$previousFolder"
    fi

  elif [[ "$libraryIdentifier" == "" ]]; then
    # Install library from the repository
    # https://docs.travis-ci.com/user/environment-variables#Global-Variables
    local libraryName
    libraryName="$(echo "$TRAVIS_REPO_SLUG" | cut -d'/' -f 2)"
    mkdir --parents $ARDUINO_CI_SCRIPT_VERBOSITY_OPTION "${ARDUINO_CI_SCRIPT_SKETCHBOOK_FOLDER}/libraries/$libraryName"
    local -r previousFolder="$PWD"
    cd "$TRAVIS_BUILD_DIR"
    cp --recursive $ARDUINO_CI_SCRIPT_VERBOSITY_OPTION ./* "${ARDUINO_CI_SCRIPT_SKETCHBOOK_FOLDER}/libraries/${libraryName}"
    # * doesn't copy .travis.yml but that file will be present in the user's installation so it should be there for the tests too
    cp $ARDUINO_CI_SCRIPT_VERBOSITY_OPTION "${TRAVIS_BUILD_DIR}/.travis.yml" "${ARDUINO_CI_SCRIPT_SKETCHBOOK_FOLDER}/libraries/${libraryName}"
    cd "$previousFolder"

  else
    # Install a library that is part of the Library Manager index

    # Check if Arduino IDE is installed
    if [[ "$INSTALLED_IDE_VERSION_LIST_ARRAY" == "" ]]; then
      echo "ERROR: Installing a library via Library Manager requires the Arduino IDE to be installed. Please call install_ide before this command."
      return_handler "$ARDUINO_CI_SCRIPT_FAILURE_EXIT_STATUS"
    fi

    # Check if the newest installed IDE version supports --install-library
    local -r unsupportedInstallLibraryOptionVersionsRange1regex="^1\.5\.[0-9]$"
    local -r unsupportedInstallLibraryOptionVersionsRange2regex="^1\.6\.[0-3]$"
    if [[ "$NEWEST_INSTALLED_IDE_VERSION" =~ $unsupportedInstallLibraryOptionVersionsRange1regex || "$NEWEST_INSTALLED_IDE_VERSION" =~ $unsupportedInstallLibraryOptionVersionsRange2regex ]]; then
      echo "ERROR: --install-library option is not supported by the newest version of the Arduino IDE you have installed. You must have Arduino IDE 1.6.4 or newer installed to use this function."
      return_handler "$ARDUINO_CI_SCRIPT_FAILURE_EXIT_STATUS"
    else
      local -r libraryName="$1"

      # Temporarily install the latest IDE version to use for the library installation
      install_ide_version "$NEWEST_INSTALLED_IDE_VERSION"

       # Install the library
      # shellcheck disable=SC2086
      eval \"${ARDUINO_CI_SCRIPT_APPLICATION_FOLDER}/${ARDUINO_CI_SCRIPT_IDE_INSTALLATION_FOLDER}/${ARDUINO_CI_SCRIPT_ARDUINO_COMMAND}\" --install-library "$libraryName" "$ARDUINO_CI_SCRIPT_VERBOSITY_REDIRECT"

    fi
  fi

  set +o errexit

  disable_verbosity
}


# Extract common file formats
# https://github.com/xvoland/Extract
function extract
{
  if [ -z "$1" ]; then
    # display usage if no parameters given
    echo "Usage: extract <path/file_name>.<zip|rar|bz2|gz|tar|tbz2|tgz|Z|7z|xz|ex|tar.bz2|tar.gz|tar.xz>"
    echo "       extract <path/file_name_1.ext> [path/file_name_2.ext] [path/file_name_3.ext]"
    return "$ARDUINO_CI_SCRIPT_FAILURE_EXIT_STATUS"
  else
    local filename
    for filename in "$@"
    do
      if [ -f "$filename" ]; then
        case "${filename%,}" in
          *.tar.bz2|*.tar.gz|*.tar.xz|*.tbz2|*.tgz|*.txz|*.tar)
            tar --extract --file="$filename"
          ;;
          *.lzma)
            unlzma $ARDUINO_CI_SCRIPT_QUIET_OPTION ./"$filename"
          ;;
          *.bz2)
            bunzip2 $ARDUINO_CI_SCRIPT_QUIET_OPTION ./"$filename"
          ;;
          *.rar)
            eval unrar x -ad ./"$filename" "$ARDUINO_CI_SCRIPT_VERBOSITY_REDIRECT"
          ;;
          *.gz)
            gunzip ./"$filename"
          ;;
          *.zip)
            unzip -qq ./"$filename"
          ;;
          *.z)
            eval uncompress ./"$filename" "$ARDUINO_CI_SCRIPT_VERBOSITY_REDIRECT"
          ;;
          *.7z|*.arj|*.cab|*.chm|*.deb|*.dmg|*.iso|*.lzh|*.msi|*.rpm|*.udf|*.wim|*.xar)
            7z x ./"$filename"
          ;;
          *.xz)
            unxz $ARDUINO_CI_SCRIPT_QUIET_OPTION ./"$filename"
          ;;
          *.exe)
            cabextract $ARDUINO_CI_SCRIPT_QUIET_OPTION ./"$filename"
          ;;
          *)
            echo "extract: '$filename' - unknown archive method"
            return "$ARDUINO_CI_SCRIPT_FAILURE_EXIT_STATUS"
          ;;
        esac
      else
        echo "extract: '$filename' - file does not exist"
        return "$ARDUINO_CI_SCRIPT_FAILURE_EXIT_STATUS"
      fi
    done
  fi
}


function set_verbose_output_during_compilation()
{
  enable_verbosity

  local -r verboseOutputDuringCompilation="$1"
  if [[ "$verboseOutputDuringCompilation" == "true" ]]; then
    ARDUINO_CI_SCRIPT_DETERMINED_VERBOSE_BUILD="--verbose"
  else
    ARDUINO_CI_SCRIPT_DETERMINED_VERBOSE_BUILD=""
  fi

  disable_verbosity
}


# Verify the sketch
function build_sketch()
{
  enable_verbosity

  local -r sketchPath="$1"
  local -r boardID="$2"
  local -r allowFail="$3"
  local -r startIDEversion="$4"
  local -r endIDEversion="$5"

  # Set default value for buildSketchExitStatus
  local buildSketchExitStatus="$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS"

  generate_ide_version_list_array "$INSTALLED_IDE_VERSION_LIST_ARRAY" "$startIDEversion" "$endIDEversion"

  if [[ "$ARDUINO_CI_SCRIPT_GENERATED_IDE_VERSION_LIST_ARRAY" == "$ARDUINO_CI_SCRIPT_IDE_VERSION_LIST_ARRAY_DECLARATION"'()' ]]; then
    echo "ERROR: The IDE version(s) specified are not installed"
    buildSketchExitStatus="$ARDUINO_CI_SCRIPT_FAILURE_EXIT_STATUS"
  else
    eval "$ARDUINO_CI_SCRIPT_GENERATED_IDE_VERSION_LIST_ARRAY"
    local IDEversion
    for IDEversion in "${IDEversionListArray[@]}"; do
      # Install the IDE
      # This must be done before searching for sketches in case the path specified is in the Arduino IDE installation folder
      install_ide_version "$IDEversion"

      # The package_index files installed by some versions of the IDE (1.6.5, 1.6.5) can cause compilation to fail for other versions (1.6.5-r4, 1.6.5-r5). Attempting to install a dummy package ensures that the correct version of those files will be installed before the sketch verification.
      # Check if the newest installed IDE version supports --install-boards
      local unsupportedInstallBoardsOptionVersionsRange1regex="^1\.5\.[0-9]$"
      local unsupportedInstallBoardsOptionVersionsRange2regex="^1\.6\.[0-3]$"
      if ! [[ "$IDEversion" =~ $unsupportedInstallBoardsOptionVersionsRange1regex || "$IDEversion" =~ $unsupportedInstallBoardsOptionVersionsRange2regex ]]; then
        # shellcheck disable=SC2086
        eval \"${ARDUINO_CI_SCRIPT_APPLICATION_FOLDER}/${ARDUINO_CI_SCRIPT_IDE_INSTALLATION_FOLDER}/${ARDUINO_CI_SCRIPT_ARDUINO_COMMAND}\" --install-boards arduino:dummy "$ARDUINO_CI_SCRIPT_VERBOSITY_REDIRECT"
        if [[ "$ARDUINO_CI_SCRIPT_VERBOSITY_LEVEL" -gt 1 ]]; then
          # The warning is printed to stdout
          echo "NOTE: The warning above \"Selected board is not available\" is caused intentionally and does not indicate a problem."
        fi
      fi

      if [[ "$sketchPath" =~ \.ino$ || "$sketchPath" =~ \.pde$ ]]; then
        # A sketch was specified
        if ! [[ -f "$sketchPath" ]]; then
          echo "ERROR: Specified sketch: $sketchPath doesn't exist"
          buildSketchExitStatus="$ARDUINO_CI_SCRIPT_FAILURE_EXIT_STATUS"
        elif ! build_this_sketch "$sketchPath" "$boardID" "$IDEversion" "$allowFail"; then
          # build_this_sketch returned a non-zero exit status
          buildSketchExitStatus="$ARDUINO_CI_SCRIPT_FAILURE_EXIT_STATUS"
        fi
      else
        # Search for all sketches in the path and put them in an array
        local sketchFound="false"
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
            sketchFound="true"
            if ! build_this_sketch "$sketchName" "$boardID" "$IDEversion" "$allowFail"; then
              # build_this_sketch returned a non-zero exit status
              buildSketchExitStatus="$ARDUINO_CI_SCRIPT_FAILURE_EXIT_STATUS"
            fi
          fi
        done

        if [[ "$sketchFound" == "false" ]]; then
          echo "ERROR: No valid sketches were found in the specified path"
          buildSketchExitStatus="$ARDUINO_CI_SCRIPT_FAILURE_EXIT_STATUS"
        fi
      fi
    done
  fi

  disable_verbosity

  return $buildSketchExitStatus
}


function build_this_sketch()
{
  # Fold this section of output in the Travis CI build log to make it easier to read
  echo -e "travis_fold:start:build_sketch"

  local -r sketchName="$1"
  local -r boardID="$2"
  local -r IDEversion="$3"
  local -r allowFail="$4"

  # Produce a useful label for the fold in the Travis log for this function call
  echo "build_sketch $sketchName $boardID $allowFail $IDEversion"

  # Arduino IDE 1.8.0 and 1.8.1 fail to verify a sketch if the absolute path to it is not specified
  # http://stackoverflow.com/a/3915420/7059512
  local absoluteSketchName
  absoluteSketchName="$(cd "$(dirname "$1")"; pwd)/$(basename "$1")"

  # Define a dummy value for arduinoExitStatus so that the while loop will run at least once
  local arduinoExitStatus=255
  # Retry the verification if arduino returns an exit status that indicates there may have been a temporary error not caused by a bug in the sketch or the arduino command
  while [[ $arduinoExitStatus -gt $ARDUINO_CI_SCRIPT_HIGHEST_ACCEPTABLE_ARDUINO_EXIT_STATUS && $verifyCount -le $ARDUINO_CI_SCRIPT_SKETCH_VERIFY_RETRIES ]]; do
    # Verify the sketch
    # shellcheck disable=SC2086
    "${ARDUINO_CI_SCRIPT_APPLICATION_FOLDER}/${ARDUINO_CI_SCRIPT_IDE_INSTALLATION_FOLDER}/${ARDUINO_CI_SCRIPT_ARDUINO_COMMAND}" $ARDUINO_CI_SCRIPT_DETERMINED_VERBOSE_BUILD --verify "$absoluteSketchName" --board "$boardID" 2>&1 | tr -Cd '[:print:]\n\t'  | tr --squeeze-repeats '\n'| grep --extended-regexp --invert-match "$ARDUINO_CI_SCRIPT_ARDUINO_OUTPUT_FILTER_REGEX" | tee "$ARDUINO_CI_SCRIPT_VERIFICATION_OUTPUT_FILENAME"; local arduinoExitStatus="${PIPESTATUS[0]}"
    local verifyCount=$((verifyCount + 1))
  done

  if [[ "$arduinoExitStatus" != "$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS" ]]; then
    # Sketch verification failed
    local buildThisSketchExitStatus="$ARDUINO_CI_SCRIPT_FAILURE_EXIT_STATUS"
  else
    # Sketch verification succeeded
    local buildThisSketchExitStatus="$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS"

    # Parse through the output from the sketch verification to count warnings and determine the compile size
    local warningCount=0
    local boardIssueCount=0
    local libraryIssueCount=0
    while read -r outputFileLine; do
      # Determine program storage memory usage
      local programStorageRegex="Sketch uses ([0-9,]+) *"
      if [[ "$outputFileLine" =~ $programStorageRegex ]] > /dev/null; then
        local -r programStorageWithComma=${BASH_REMATCH[1]}
      fi

      # Determine dynamic memory usage
      local dynamicMemoryRegex="Global variables use ([0-9,]+) *"
      if [[ "$outputFileLine" =~ $dynamicMemoryRegex ]] > /dev/null; then
        local -r dynamicMemoryWithComma=${BASH_REMATCH[1]}
      fi

      # Increment warning count
      local warningRegex="warning: "
      if [[ "$outputFileLine" =~ $warningRegex ]] > /dev/null; then
        warningCount=$((warningCount + 1))
      fi

      # Check for board issues
      local bootloaderMissingRegex="Bootloader file specified but missing: "
      if [[ "$outputFileLine" =~ $bootloaderMissingRegex ]] > /dev/null; then
        local boardIssue="missing bootloader"
        boardIssueCount=$((boardIssueCount + 1))
      fi

      local boardsDotTxtMissingRegex="Could not find boards.txt"
      if [[ "$outputFileLine" =~ $boardsDotTxtMissingRegex ]] > /dev/null; then
        local boardIssue="Could not find boards.txt"
        boardIssueCount=$((boardIssueCount + 1))
      fi

      local buildDotBoardNotDefinedRegex="doesn't define a 'build.board' preference"
      if [[ "$outputFileLine" =~ $buildDotBoardNotDefinedRegex ]] > /dev/null; then
        local boardIssue="doesn't define a 'build.board' preference"
        boardIssueCount=$((boardIssueCount + 1))
      fi

      # Check for library issues
      # This is the generic "invalid library" warning that doesn't specify the reason
      local invalidLibrarRegex1="Invalid library found in"
      local invalidLibrarRegex2="from library$"
      if [[ "$outputFileLine" =~ $invalidLibrarRegex1 ]] && ! [[ "$outputFileLine" =~ $invalidLibrarRegex2 ]] > /dev/null; then
        local libraryIssue="Invalid library"
        libraryIssueCount=$((libraryIssueCount + 1))
      fi

      local missingNameRegex="Invalid library found in .* Missing 'name' from library"
      if [[ "$outputFileLine" =~ $missingNameRegex ]] > /dev/null; then
        local libraryIssue="Missing 'name' from library"
        libraryIssueCount=$((libraryIssueCount + 1))
      fi

      local missingVersionRegex="Invalid library found in .* Missing 'version' from library"
      if [[ "$outputFileLine" =~ $missingVersionRegex ]] > /dev/null; then
        local libraryIssue="Missing 'version' from library"
        libraryIssueCount=$((libraryIssueCount + 1))
      fi

      local missingAuthorRegex="Invalid library found in .* Missing 'author' from library"
      if [[ "$outputFileLine" =~ $missingAuthorRegex ]] > /dev/null; then
        local libraryIssue="Missing 'author' from library"
        libraryIssueCount=$((libraryIssueCount + 1))
      fi

      local missingMaintainerRegex="Invalid library found in .* Missing 'maintainer' from library"
      if [[ "$outputFileLine" =~ $missingMaintainerRegex ]] > /dev/null; then
        local libraryIssue="Missing 'maintainer' from library"
        libraryIssueCount=$((libraryIssueCount + 1))
      fi

      local missingSentenceRegex="Invalid library found in .* Missing 'sentence' from library"
      if [[ "$outputFileLine" =~ $missingSentenceRegex ]] > /dev/null; then
        local libraryIssue="Missing 'sentence' from library"
        libraryIssueCount=$((libraryIssueCount + 1))
      fi

      local missingParagraphRegex="Invalid library found in .* Missing 'paragraph' from library"
      if [[ "$outputFileLine" =~ $missingParagraphRegex ]] > /dev/null; then
        local libraryIssue="Missing 'paragraph' from library"
        libraryIssueCount=$((libraryIssueCount + 1))
      fi

      local missingURLregex="Invalid library found in .* Missing 'url' from library"
      if [[ "$outputFileLine" =~ $missingURLregex ]] > /dev/null; then
        local libraryIssue="Missing 'url' from library"
        libraryIssueCount=$((libraryIssueCount + 1))
      fi

      local invalidVersionRegex="Invalid version found:"
      if [[ "$outputFileLine" =~ $invalidVersionRegex ]] > /dev/null; then
        local libraryIssue="Invalid version found:"
        libraryIssueCount=$((libraryIssueCount + 1))
      fi

      local invalidCategoryRegex="is not valid. Setting to 'Uncategorized'"
      if [[ "$outputFileLine" =~ $invalidCategoryRegex ]] > /dev/null; then
        local libraryIssue="Invalid category"
        libraryIssueCount=$((libraryIssueCount + 1))
      fi

      local spuriousFolderRegex="WARNING: Spurious"
      if [[ "$outputFileLine" =~ $spuriousFolderRegex ]] > /dev/null; then
        local libraryIssue="Spurious folder"
        libraryIssueCount=$((libraryIssueCount + 1))
      fi

    done < "$ARDUINO_CI_SCRIPT_VERIFICATION_OUTPUT_FILENAME"

    rm $ARDUINO_CI_SCRIPT_VERBOSITY_OPTION "$ARDUINO_CI_SCRIPT_VERIFICATION_OUTPUT_FILENAME"

    # Remove the stupid comma from the memory values if present
    local -r programStorage=${programStorageWithComma//,}
    local -r dynamicMemory=${dynamicMemoryWithComma//,}

    if [[ "$boardIssue" != "" && "$ARDUINO_CI_SCRIPT_TEST_BOARD" == "true" ]]; then
      # There was a board issue and board testing is enabled so fail the build
      local buildThisSketchExitStatus="$ARDUINO_CI_SCRIPT_FAILURE_EXIT_STATUS"
    fi

    if [[ "$libraryIssue" != "" && "$ARDUINO_CI_SCRIPT_TEST_LIBRARY" == "true" ]]; then
      # There was a library issue and library testing is enabled so fail the build
      local buildThisSketchExitStatus="$ARDUINO_CI_SCRIPT_FAILURE_EXIT_STATUS"
    fi
  fi

  # Add the build data to the report file
  echo "$(date -u "+%Y-%m-%d %H:%M:%S")"$'\t'"$TRAVIS_BUILD_NUMBER"$'\t'"$TRAVIS_JOB_NUMBER"$'\t'"https://travis-ci.org/${TRAVIS_REPO_SLUG}/jobs/${TRAVIS_JOB_ID}"$'\t'"$TRAVIS_EVENT_TYPE"$'\t'"$TRAVIS_ALLOW_FAILURE"$'\t'"$TRAVIS_PULL_REQUEST"$'\t'"$TRAVIS_BRANCH"$'\t'"$TRAVIS_COMMIT"$'\t'"$TRAVIS_COMMIT_RANGE"$'\t'"${TRAVIS_COMMIT_MESSAGE%%$'\n'*}"$'\t'"$sketchName"$'\t'"$boardID"$'\t'"$IDEversion"$'\t'"$programStorage"$'\t'"$dynamicMemory"$'\t'"$warningCount"$'\t'"$allowFail"$'\t'"$arduinoExitStatus"$'\t'"$boardIssueCount"$'\t'"$boardIssue"$'\t'"$libraryIssueCount"$'\t'"$libraryIssue"$'\r' >> "$ARDUINO_CI_SCRIPT_REPORT_FILE_PATH"

  # Adjust the exit status according to the allowFail setting
  if [[ "$buildThisSketchExitStatus" == "$ARDUINO_CI_SCRIPT_FAILURE_EXIT_STATUS" && ("$allowFail" == "true" || "$allowFail" == "require") ]]; then
    buildThisSketchExitStatus="$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS"
  elif [[ "$buildThisSketchExitStatus" == "$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS" && "$allowFail" == "require" ]]; then
    buildThisSketchExitStatus="$ARDUINO_CI_SCRIPT_FAILURE_EXIT_STATUS"
  fi

  if [[ "$buildThisSketchExitStatus" != "$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS" ]]; then
    ARDUINO_CI_SCRIPT_TOTAL_SKETCH_BUILD_FAILURE_COUNT=$((ARDUINO_CI_SCRIPT_TOTAL_SKETCH_BUILD_FAILURE_COUNT + 1))
  fi
  ARDUINO_CI_SCRIPT_TOTAL_WARNING_COUNT=$((ARDUINO_CI_SCRIPT_TOTAL_WARNING_COUNT + warningCount + 0))
  ARDUINO_CI_SCRIPT_TOTAL_BOARD_ISSUE_COUNT=$((ARDUINO_CI_SCRIPT_TOTAL_BOARD_ISSUE_COUNT + boardIssueCount + 0))
  ARDUINO_CI_SCRIPT_TOTAL_LIBRARY_ISSUE_COUNT=$((ARDUINO_CI_SCRIPT_TOTAL_LIBRARY_ISSUE_COUNT + libraryIssueCount + 0))

  # End the folded section of the Travis CI build log
  echo -e "travis_fold:end:build_sketch"
  # Add a useful message to the Travis CI build log

  echo "arduino Exit Status: ${arduinoExitStatus}, Allow Failure: ${allowFail}, # Warnings: ${warningCount}, # Board Issues: ${boardIssueCount}, # Library Issues: ${libraryIssueCount}"

  return $buildThisSketchExitStatus
}


# Print the contents of the report file
function display_report()
{
  enable_verbosity

  if [ -e "$ARDUINO_CI_SCRIPT_REPORT_FILE_PATH" ]; then
    echo -e '\n\n\n**************Begin Report**************\n\n\n'
    cat "$ARDUINO_CI_SCRIPT_REPORT_FILE_PATH"
    echo -e '\n\n'
    echo "Total failed sketch builds: $ARDUINO_CI_SCRIPT_TOTAL_SKETCH_BUILD_FAILURE_COUNT"
    echo "Total warnings: $ARDUINO_CI_SCRIPT_TOTAL_WARNING_COUNT"
    echo "Total board issues: $ARDUINO_CI_SCRIPT_TOTAL_BOARD_ISSUE_COUNT"
    echo "Total library issues: $ARDUINO_CI_SCRIPT_TOTAL_LIBRARY_ISSUE_COUNT"
    echo -e '\n\n'
  else
    echo "No report file available for this job"
  fi

  disable_verbosity
}


# Add the report file to a Git repository
function publish_report_to_repository()
{
  enable_verbosity

  local -r token="$1"
  local -r repositoryURL="$2"
  local -r reportBranch="$3"
  local -r reportFolder="$4"
  local -r doLinkComment="$5"

  if [[ "$token" != "" ]] && [[ "$repositoryURL" != "" ]] && [[ "$reportBranch" != "" ]]; then
    if [ -e "$ARDUINO_CI_SCRIPT_REPORT_FILE_PATH" ]; then
      # Location is a repository
      if git clone --quiet --branch "$reportBranch" "$repositoryURL" "${HOME}/report-repository"; then
        # Clone was successful
        create_folder "${HOME}/report-repository/${reportFolder}"
        cp $ARDUINO_CI_SCRIPT_VERBOSITY_OPTION "$ARDUINO_CI_SCRIPT_REPORT_FILE_PATH" "${HOME}/report-repository/${reportFolder}"
        local -r previousFolder="$PWD"
        cd "${HOME}/report-repository"
        git add $ARDUINO_CI_SCRIPT_VERBOSITY_OPTION "${HOME}/report-repository/${reportFolder}/${ARDUINO_CI_SCRIPT_REPORT_FILENAME}"
        git config user.email "arduino-ci-script@nospam.me"
        git config user.name "arduino-ci-script-bot"
        # Only pushes the current branch to the corresponding remote branch that 'git pull' uses to update the current branch.
        git config push.default simple
        if [[ "$TRAVIS_TEST_RESULT" != "0" ]]; then
          local -r jobSuccessMessage="FAILED"
        else
          local -r jobSuccessMessage="SUCCESSFUL"
        fi
        # Do a pull now in case another job has finished about the same time and pushed a report after the clone happened, which would otherwise cause the push to fail. This is the last chance to pull without having to deal with a merge or rebase.
        git pull $ARDUINO_CI_SCRIPT_QUIET_OPTION
        git commit $ARDUINO_CI_SCRIPT_QUIET_OPTION $ARDUINO_CI_SCRIPT_VERBOSITY_OPTION --message="Add Travis CI job ${TRAVIS_JOB_NUMBER} report (${jobSuccessMessage})" --message="Total failed sketch builds: $ARDUINO_CI_SCRIPT_TOTAL_SKETCH_BUILD_FAILURE_COUNT" --message="Total warnings: $ARDUINO_CI_SCRIPT_TOTAL_WARNING_COUNT" --message="Total board issues: $ARDUINO_CI_SCRIPT_TOTAL_BOARD_ISSUE_COUNT" --message="Total library issues: $ARDUINO_CI_SCRIPT_TOTAL_LIBRARY_ISSUE_COUNT" --message="Job log: https://travis-ci.org/${TRAVIS_REPO_SLUG}/jobs/${TRAVIS_JOB_ID}" --message="Commit: https://github.com/${TRAVIS_REPO_SLUG}/commit/${TRAVIS_COMMIT}" --message="$TRAVIS_COMMIT_MESSAGE" --message="[skip ci]"
        local gitPushExitStatus="1"
        local pushCount=0
        while [[ "$gitPushExitStatus" != "$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS" && $pushCount -le $ARDUINO_CI_SCRIPT_REPORT_PUSH_RETRIES ]]; do
          pushCount=$((pushCount + 1))
          # Do a pull now in case another job has finished about the same time and pushed a report since the last pull. This would require a merge or rebase. Rebase should be safe since the commits will be separate files.
          git pull $ARDUINO_CI_SCRIPT_QUIET_OPTION --rebase
          git push $ARDUINO_CI_SCRIPT_QUIET_OPTION $ARDUINO_CI_SCRIPT_VERBOSITY_OPTION "https://${token}@${repositoryURL#*//}"
          gitPushExitStatus="$?"
        done
        cd "$previousFolder"
        rm --recursive --force "${HOME}/report-repository"
        if [[ "$gitPushExitStatus" == "$ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS" ]]; then
          if [[ "$doLinkComment" == "true" ]]; then
            # Only comment if it's job 1
            local -r firstJobRegex='\.1$'
            if [[ "$TRAVIS_JOB_NUMBER" =~ $firstJobRegex ]]; then
              local reportURL
              reportURL="${repositoryURL%.*}/tree/${reportBranch}/${reportFolder}"
              comment_report_link "$token" "$reportURL"
            fi
          fi
        else
          echo "ERROR: Failed to push to remote branch."
          return_handler "$ARDUINO_CI_SCRIPT_FAILURE_EXIT_STATUS"
        fi
      else
        echo "ERROR: Failed to clone branch ${reportBranch} of repository URL ${repositoryURL}. Do they exist?"
        return_handler "$ARDUINO_CI_SCRIPT_FAILURE_EXIT_STATUS"
      fi
    else
      echo "No report file available for this job"
    fi
  else
    if [[ "$token" == "" ]]; then
      echo "ERROR: GitHub token not specified. Failed to publish build report. See https://github.com/per1234/arduino-ci-script#publishing-job-reports for instructions."
    fi
    if [[ "$repositoryURL" == "" ]]; then
      echo "ERROR: Repository URL not specified. Failed to publish build report."
    fi
    if [[ "$reportBranch" == "" ]]; then
      echo "ERROR: Repository branch not specified. Failed to publish build report."
    fi
    return_handler "$ARDUINO_CI_SCRIPT_FAILURE_EXIT_STATUS"
  fi

  disable_verbosity
}


# Add the report file to a gist
function publish_report_to_gist()
{
  enable_verbosity

  local -r token="$1"
  local -r gistURL="$2"
  local -r doLinkComment="$3"

  if [[ "$token" != "" ]] && [[ "$gistURL" != "" ]]; then
    if [ -e "$ARDUINO_CI_SCRIPT_REPORT_FILE_PATH" ]; then
      # Get the gist ID from the gist URL
      local gistID
      gistID="$(echo "$gistURL" | rev | cut -d'/' -f 1 | rev)"

      # http://stackoverflow.com/a/33354920/7059512
      # Sanitize the report file content so it can be sent via a POST request without breaking the JSON
      # Remove \r (from Windows end-of-lines), replace tabs by \t, replace " by \", replace EOL by \n
      local reportContent
      reportContent=$(sed -e 's/\r//' -e's/\t/\\t/g' -e 's/"/\\"/g' "$ARDUINO_CI_SCRIPT_REPORT_FILE_PATH" | awk '{ printf($0 "\\n") }')

      # Upload the report to the Gist. I have to use the here document to avoid the "Argument list too long" error from curl with long reports. Redirect output to dev/null because it dumps the whole gist to the log
      eval curl --header "\"Authorization: token ${token}\"" --data @- "\"https://api.github.com/gists/${gistID}\"" <<curlDataHere "$ARDUINO_CI_SCRIPT_VERBOSITY_REDIRECT"
{"files":{"${ARDUINO_CI_SCRIPT_REPORT_FILENAME}":{"content": "${reportContent}"}}}
curlDataHere

      if [[ "$doLinkComment" == "true" ]]; then
        # Only comment if it's job 1
        local -r firstJobRegex='\.1$'
        if [[ "$TRAVIS_JOB_NUMBER" =~ $firstJobRegex ]]; then
          local reportURL="${gistURL}#file-${ARDUINO_CI_SCRIPT_REPORT_FILENAME//./-}"
          comment_report_link "$token" "$reportURL"
        fi
      fi
    else
      echo "No report file available for this job"
    fi
  else
    if [[ "$token" == "" ]]; then
      echo "ERROR: GitHub token not specified. Failed to publish build report. See https://github.com/per1234/arduino-ci-script#publishing-job-reports for instructions."
    fi
    if [[ "$gistURL" == "" ]]; then
      echo "ERROR: Gist URL not specified. Failed to publish build report. See https://github.com/per1234/arduino-ci-script#publishing-job-reports for instructions."
    fi
    return_handler "$ARDUINO_CI_SCRIPT_FAILURE_EXIT_STATUS"
  fi

  disable_verbosity
}


# Leave a comment on the commit with a link to the report
function comment_report_link()
{
  local -r token="$1"
  local -r reportURL="$2"

  # shellcheck disable=SC1083
  # shellcheck disable=SC2026
  # shellcheck disable=SC2086
  eval curl $ARDUINO_CI_SCRIPT_VERBOSITY_OPTION --header "\"Authorization: token ${token}\"" --data \"{'\"'body'\"':'\"'Once completed, the job reports for Travis CI [build ${TRAVIS_BUILD_NUMBER}]\(https://travis-ci.org/${TRAVIS_REPO_SLUG}/builds/${TRAVIS_BUILD_ID}\) will be found at:\\n${reportURL}'\"'}\" "\"https://api.github.com/repos/${TRAVIS_REPO_SLUG}/commits/${TRAVIS_COMMIT}/comments\"" "$ARDUINO_CI_SCRIPT_VERBOSITY_REDIRECT"
  if [[ $? -ne $ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS ]]; then
    echo "ERROR: Failed to comment link to published report location"
  fi
}


# Deprecated because no longer necessary. Left only to maintain backwards compatibility
function check_success()
{
  echo "The check_success function is no longer necessary and has been deprecated"
}


# https://github.com/arduino/Arduino/wiki/Arduino-IDE-1.5:-Library-specification
function check_library_structure()
{
  local -r libraryPath="$1"
  # Replace backslashes with slashes
  local -r libraryPathWithSlashes="${libraryPath//\\//}"
  # Remove trailing slash
  local -r normalizedLibraryPath="${libraryPathWithSlashes%/}"

  # Check whether folder exists
  if [[ ! -d "$normalizedLibraryPath" ]]; then
    echo "ERROR: Specified folder: $libraryPath doesn't exist."
    return 1
  fi

  # Check for valid 1.0 or 1.5 format
  if [[ $(find "$normalizedLibraryPath" -maxdepth 1 -type f \( -name '*.h' -or -name '*.hh' -or -name '*.hpp' \)) ]]; then
    # 1.0 format library, do nothing (this if just makes the logic more simple)
    :
  elif [[ $(find "$normalizedLibraryPath" -maxdepth 1 \( -type f -and -name 'library.properties' \)) && $(find "$normalizedLibraryPath" -maxdepth 1 -type d -and -regex '^.*[sS][rR][cC]$') ]]; then
    # 1.5 format library
    if [[ ! $(find "$normalizedLibraryPath" -maxdepth 1 -type d -and -name 'src') ]]; then
      echo 'ERROR: 1.5 format library with incorrect case in src subfolder name, which causes library to not be recognized on a filename case-sensitive OS such as Linux.'
      return 2
    elif [[ $(find "${normalizedLibraryPath}/src" -maxdepth 1 -type f \( -name '*.h' -or -name '*.hh' -or -name '*.hpp' \)) ]]; then
      local -r onePointFiveFormat=true
    fi
  else
    echo "ERROR: No valid library found in $libraryPath"
    return 3
  fi

  # Check if folder name is valid
  check_valid_folder_name "$normalizedLibraryPath"
  local -r checkValidFolderNameExitStatus=$?
  if [[ $checkValidFolderNameExitStatus -ne $ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS ]]; then
    return $((3 + checkValidFolderNameExitStatus))
  fi

  # Check for incorrect spelling of examples folder
  if [[ $(find "$normalizedLibraryPath" -maxdepth 1 -type d -and -regex '^.*/[eE][xX][aA][mM][pP][lL][eE].?$') && ! $(find "$normalizedLibraryPath" -maxdepth 1 -type d -and -name 'examples') ]]; then
    echo 'ERROR: Incorrect examples folder name.'
    return 7
  fi

  # Check for 1.5 format with  src and utility folders in library root
  if [[ "$onePointFiveFormat" == true && $(find "$normalizedLibraryPath" -maxdepth 1 -type d -and -name 'utility') ]]; then
    echo 'ERROR: 1.5 format library with src and utility folders in library root.'
    return 8
  fi

  # Check for sketch files outside of the src or extras folders
  if [[ $(find "$normalizedLibraryPath" -maxdepth 1 -path './examples' -prune -or -path './extras' -prune -or \( -type f -and \( -regex '^.*\.[iI][nN][oO]' -or -regex '^.*\.[pP][dD][eE]' \) \)) ]]; then
    echo 'ERROR: Sketch files found outside of examples and extras folders.'
    return 9
  fi

  # Run check_sketch_structure() on examples and extras folders
  if [[ -d "${normalizedLibraryPath}/examples" ]]; then
    check_sketch_structure "${normalizedLibraryPath}/examples"
    local -r checkExamplesSketchStructureExitStatus=$?
    if [[ $checkExamplesSketchStructureExitStatus -ne $ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS ]]; then
      return $((9 + checkExamplesSketchStructureExitStatus))
    fi
  fi
  if [[ -d "${normalizedLibraryPath}/extras" ]]; then
    check_sketch_structure "${normalizedLibraryPath}/extras"
    local -r checkExtrasSketchStructureExitStatus=$?
    if [[ $checkExtrasSketchStructureExitStatus -ne $ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS ]]; then
      return $((9 + checkExtrasSketchStructureExitStatus))
    fi
  fi
}


# The same folder name restrictions apply to libraries and sketches so this function may be used for both
function check_valid_folder_name()
{
  local -r path="$1"
  # Get the folder name from the path
  local -r folderName="${path##*/}"

  # Starting folder name with a number is only supported by Arduino IDE 1.8.4 and newer
  local -r startsWithNumberRegex="^[0-9]"
  if [[ "$folderName" =~ $startsWithNumberRegex ]]; then
    echo "WARNING: Folder name (${folderName}) beginning with a number is only supported by Arduino IDE 1.8.4 and newer."
  fi

  # Starting folder name with a - or . is not allowed
  local -r startsWithInvalidCharacterRegex="^[-.]"
  if [[ "$folderName" =~ $startsWithInvalidCharacterRegex ]]; then
    echo "ERROR: Folder name (${folderName}) beginning with a - or . is not allowed."
    return 1
  fi

  # Allowed characters: a-z, A-Z, 0-1, -._
  local -r disallowedCharactersRegex="[^a-zA-Z0-9._-]"
  if [[ "$folderName" =~ $disallowedCharactersRegex ]]; then
    echo "ERROR: Folder name $folderName contains disallowed characters. Only letters, numbers, dots, dashes, and underscores are allowed."
    return 2
  fi

  # <64 characters
  if [[ ${#folderName} -gt 63 ]]; then
    echo "ERROR: Folder name $folderName exceeds the maximum of 63 characters."
    return 3
  fi
  return 0
}


function check_sketch_structure()
{
  local -r searchPath="$1"
  # Replace backslashes with slashes
  local -r searchPathWithSlashes="${searchPath//\\//}"
  # Remove trailing slash
  local -r normalizedSearchPath="${searchPathWithSlashes%/}"

  # Check whether folder exists
  if [[ ! -d "$normalizedSearchPath" ]]; then
    echo "ERROR: Specified folder: $searchPath doesn't exist."
    return 1
  fi

  # find all folders that contain a sketch file
  find "$normalizedSearchPath" -type f \( -regex '^.*\.[iI][nN][oO]' -or -regex '^.*\.[pP][dD][eE]' \) -printf '%h\n' | sort --unique | while read -r sketchPath; do

    # Check for sketches with incorrect extension case
    find "$sketchPath" -maxdepth 1 -type f \( -regex '^.*\.[iI][nN][oO]' -or -regex '^.*\.[pP][dD][eE]' \) -print | while read -r sketchName; do
      if [[ "${sketchName: -4}" != ".ino" && "${sketchName: -4}" != ".pde" ]]; then
        echo "ERROR: Sketch file $sketchName has incorrect extension case, which causes it to not be recognized on a filename case-sensitive OS such as Linux."
        # This only breaks out of the pipe, it does not return from the function
        return 1
      fi
    done
    if [[ $? -eq 1 ]]; then
      return 2
    fi

    # Check if sketch name is valid
    check_valid_folder_name "$sketchPath"
    local checkValidFolderNameExitStatus=$?
    if [[ $checkValidFolderNameExitStatus -ne $ARDUINO_CI_SCRIPT_SUCCESS_EXIT_STATUS ]]; then
      return $((2 + checkValidFolderNameExitStatus))
    fi

    # Check for folder name mismatch
    if
      find "$sketchPath" -maxdepth 1 -type f \( -name '*.ino' -or -name '*.pde' \) -print | while read -r sketchFilePath; do
        local sketchFileFolderName="${sketchPath##*/}"
        local sketchFilenameWithExtension="${sketchFilePath##*/}"
        local sketchFilenameWithoutExtension="${sketchFilenameWithExtension%.*}"
        if [[ "$sketchFileFolderName" == "$sketchFilenameWithoutExtension" ]]; then
          # Sketch file found that matches the folder name
          # I need to return 1 because the exit status when no matches are found is 0
          return 1
        fi
      done
    then
      echo "ERROR: Sketch folder name $sketchPath does not match the sketch filename."
      return 6
    fi

    # Check for multiple sketches in folder
    if
      ! find "$sketchPath" -maxdepth 1 -type f \( -name '*.ino' -or -name '*.pde' \) -print | while read -r sketchFilePath; do
        if grep --quiet --regexp='void  *setup *( *)' "$sketchFilePath"; then
          if [[ "$primarySketchFound" == true ]]; then
            # A primary sketch file was previously found in this folder
            return 1
          fi
          local primarySketchFound=true
        fi
      done
    then
      echo "ERROR: Multiple sketches found in the same folder (${sketchPath})."
      return 7
    fi

  done
}


# https://github.com/arduino/Arduino/wiki/Arduino-IDE-1.5:-Library-specification#libraryproperties-file-format
function check_library_properties()
{
  local -r searchPath="$1"

  # Replace backslashes with slashes
  local -r searchPathWithSlashes="${searchPath//\\//}"
  # Remove trailing slash
  local -r normalizedSearchPath="${searchPathWithSlashes%/}"

  # Check whether folder exists
  if [[ ! -d "$normalizedSearchPath" ]]; then
    echo "ERROR: Specified folder: $normalizedSearchPath doesn't exist."
    return 1
  fi

  # find all folders that contain a library.properties file
  find "$normalizedSearchPath" -type f -regex '.*/[lL][iI][bB][rR][aA][rR][yY]\.[pP][rR][oO][pP][eE][rR][tT][iI][eE][sS]' | while read -r libraryPropertiesPath; do

    # Check for incorrect filename case
    if [[ "${libraryPropertiesPath: -18}" != 'library.properties' ]]; then
        echo "ERROR: $libraryPropertiesPath has incorrect filename case, which causes it to not be recognized on a filename case-sensitive OS such as Linux. It must be library.properties"
        return 2
    fi

    # Get rid of the CRs
    local libraryProperties
    libraryProperties=$(tr "\r" "\n" <"$libraryPropertiesPath")

    # Check that all required fields exist
    if ! grep --quiet --regexp='^[[:space:]]*name[[:space:]]*=' <<<"$libraryProperties"; then
      echo "ERROR: $libraryPropertiesPath is missing required name field."
      return 3
    fi
    if ! grep --quiet --regexp='^[[:space:]]*version[[:space:]]*=' <<<"$libraryProperties"; then
      echo "ERROR: $libraryPropertiesPath is missing required version field."
      return 4
    fi
    if ! grep --quiet --regexp='^[[:space:]]*author[[:space:]]*=' <<<"$libraryProperties"; then
      echo "ERROR: $libraryPropertiesPath is missing required author field."
      return 5
    fi
    if ! grep --quiet --regexp='^[[:space:]]*maintainer[[:space:]]*=' <<<"$libraryProperties"; then
      if grep --quiet --regexp='^[[:space:]]*email[[:space:]]*=' <<<"$libraryProperties"; then
        echo "WARNING: Use of undocumented email field in $libraryPropertiesPath. It's recommended to use the maintainer field instead, per the Arduino Library Specification."
      else
        echo "ERROR: $libraryPropertiesPath is missing required maintainer field."
        return 6
      fi
    fi
    if ! grep --quiet --regexp='^[[:space:]]*sentence[[:space:]]*=' <<<"$libraryProperties"; then
      echo "ERROR: $libraryPropertiesPath is missing required sentence field."
      return 7
    fi
    if ! grep --quiet --regexp='^[[:space:]]*paragraph[[:space:]]*=' <<<"$libraryProperties"; then
      echo "ERROR: $libraryPropertiesPath is missing required paragraph field."
      return 8
    fi
    if ! grep --quiet --regexp='^[[:space:]]*category[[:space:]]*=' <<<"$libraryProperties"; then
      echo "ERROR: $libraryPropertiesPath is missing category field. This results in an invalid category warning."
      return 9
    fi
    if ! grep --quiet --regexp='^[[:space:]]*url[[:space:]]*=' <<<"$libraryProperties"; then
      echo "ERROR: $libraryPropertiesPath is missing required url field."
      return 10
    fi

    # Check for invalid lines (anything other than property, comment, or blank line)
    if grep --quiet --invert-match --extended-regexp --regexp='=' --regexp='^[[:space:]]*(#|$)' <<<"$libraryProperties"; then
      echo "ERROR: $libraryPropertiesPath contains an invalid line."
      return 11
    fi

    # Check for characters in the name value disallowed by the Library Manager indexer
    if
      ! grep --regexp='^[[:space:]]*name[[:space:]]*=' <<<"$libraryProperties" | while read -r nameLine; do
        local validNameRegex='^[[:space:]]*name[[:space:]]*=[[:space:]]*[a-zA-Z0-9._ -]+[[:space:]]*$'
        if ! [[ "$nameLine" =~ $validNameRegex ]]; then
          echo "ERROR: ${libraryPropertiesPath}\'s name value uses characters not allowed by the Arduino Library Manager indexer. See: https://github.com/arduino/Arduino/wiki/Arduino-IDE-1.5:-Library-specification#libraryproperties-file-format"
          return 1
        fi
      done
    then
      return 12
    fi


    # Check for invalid version
    if ! grep --quiet --extended-regexp --regexp='^[[:space:]]*version[[:space:]]*=[[:space:]]*(((([1-9][0-9]*)|0)\.){0,2})(([1-9][0-9]*)|0)(-(([a-zA-Z0-9-]*\.)*)([a-zA-Z0-9-]+))?(\+(([a-zA-Z0-9-]*\.)*)([a-zA-Z0-9-]+))?[[:space:]]*$' <<<"$libraryProperties"; then
      echo "ERROR: $libraryPropertiesPath has an invalid version value. Follow the semver specification: https://semver.org/"
      return 13
    fi

    # Check for repeat of sentence in paragraph
    if
      ! grep --regexp='^[[:space:]]*sentence[[:space:]]*=' <<<"$libraryProperties" | while read -r sentenceLine; do
        local sentenceLineFrontStripped="${sentenceLine#"${sentenceLine%%[![:space:]]*}"}"
        local sentenceValueEquals=${sentenceLineFrontStripped#sentence}
        local sentenceValueEqualsFrontStripped="${sentenceValueEquals#"${sentenceValueEquals%%[![:space:]]*}"}"
        local sentenceValue=${sentenceValueEqualsFrontStripped#=}
        local sentenceValueFrontStripped="${sentenceValue#"${sentenceValue%%[![:space:]]*}"}"
        local sentenceValueStripped="${sentenceValueFrontStripped%"${sentenceValueFrontStripped##*[![:space:]]}"}"
        local sentenceValueStrippedNoPunctuation=${sentenceValueStripped%%\.}
        if [[ "$sentenceValueStrippedNoPunctuation" != "" ]]; then
          grep --regexp='^[[:space:]]*paragraph[[:space:]]*=' <<<"$libraryProperties" | while read -r paragraphLine; do
            local paragraphLineFrontStripped="${paragraphLine#"${paragraphLine%%[![:space:]]*}"}"
            local paragraphValueEquals=${paragraphLineFrontStripped#sentence}
            local paragraphValueEqualsFrontStripped="${paragraphValueEquals#"${paragraphValueEquals%%[![:space:]]*}"}"
            local paragraphValue=${paragraphValueEqualsFrontStripped#=}
            if [[ "$paragraphValue" == *"$sentenceValueStrippedNoPunctuation"* ]]; then
              echo "ERROR: ${libraryPropertiesPath}\'s paragraph value repeats the sentence. These strings are displayed one after the other in Library Manager so there is no point in redundancy."
              return 1
            fi
          done
        fi
      done
    then
      return 14
    fi


    # Check for invalid category
    if ! grep --quiet --extended-regexp --regexp='^[[:space:]]*category[[:space:]]*=[[:space:]]*((Display)|(Communication)|(Signal Input/Output)|(Sensors)|(Device Control)|(Timing)|(Data Storage)|(Data Processing)|(Other))[[:space:]]*$' <<<"$libraryProperties"; then
      if grep --quiet --regexp='^[[:space:]]*category[[:space:]]*=[[:space:]]*Uncategorized[[:space:]]*$' <<<"$libraryProperties"; then
        echo "WARNING: category \'Uncategorized\' used in $libraryPropertiesPath is not recommended. Please chose an appropriate category from https://github.com/arduino/Arduino/wiki/Arduino-IDE-1.5:-Library-specification#libraryproperties-file-format"
      else
        echo "ERROR: $libraryPropertiesPath has an invalid category value. Please chose a valid category from https://github.com/arduino/Arduino/wiki/Arduino-IDE-1.5:-Library-specification#libraryproperties-file-format"
        return 15
      fi
    fi

    # Check for missing scheme on url value
    if ! grep --quiet --extended-regexp --regexp='^[[:space:]]*url[[:space:]]*=[[:space:]]*(http://)|(https://)' <<<"$libraryProperties"; then
      echo "ERROR: ${libraryPropertiesPath}\'s url value is missing the scheme (e.g. https://). URL scheme must be specified for Library Manager's \"More info\" link to be clickable."
      return 16
    fi

    # Check for dead url value
    if
      ! grep --regexp='^[[:space:]]*url[[:space:]]*=' <<<"$libraryProperties" | while read -r urlLine; do
        local urlLineWithoutSpaces=${urlLine//[[:space:]]/}
        local urlValue=${urlLineWithoutSpaces//url=/}
        local urlStatus
        urlStatus=$(curl --location --output /dev/null --silent --head --write-out '%{http_code}' "$urlValue")
        local errorStatusRegex='^[045]'
        if [[ "$urlStatus" =~ $errorStatusRegex ]]; then
          echo "ERROR: ${libraryPropertiesPath}\'s url value returned error status $urlStatus."
          return 1
        fi
      done
    then
      return 17
    fi

    # Check for invalid architectures
    if
      ! grep --regexp='^[[:space:]]*architectures[[:space:]]*=' <<<"$libraryProperties" | while read -r architecturesLine; do
        local architecturesLineWithoutSpaces=${architecturesLine//[[:space:]]/}
        local architecturesValue=${architecturesLineWithoutSpaces//architectures=/}
        local validArchitecturesRegex='^((\*)|(avr)|(sam)|(samd)|(stm32f4)|(nrf52)|(i586)|(i686)|(arc32)|(win10)|(esp8266)|(esp32)|(ameba)|(arm)|(efm32)|(iot2000)|(msp430)|(navspark)|(nRF5)|(pic)|(pic32)|(RFduino)|(solox)|(stm32)|(stm)|(STM32)|(STM32F1)|(STM32F3)|(STM32F4)|(STM32F2)|(STM32L1)|(STM32L4))$'
        # Split string on ,
        IFS=','
        # Disable globbing, otherwise it fails when one of the architecture values is *
        set -o noglob
        for architecture in $architecturesValue; do
          if ! [[ "$architecture" =~ $validArchitecturesRegex ]]; then
            echo "ERROR: ${libraryPropertiesPath}\'s architectures field contains an invalid architecture ${architecture}. Note: architecture values are case-sensitive."
            return 1
          fi
        done
        # Re-enable globbing
        set +o noglob
        # Set IFS back to default
        unset IFS
      done
    then
      return 18
    fi

    # Check for empty includes value
    if grep --quiet --regexp='^[[:space:]]*includes[[:space:]]*=[[:space:]]*$' <<<"$libraryProperties"; then
      echo "ERROR: ${libraryPropertiesPath}\'s includes value is empty. Either define the field or remove it."
      return 19
    fi

  done
}


# https://github.com/arduino/Arduino/wiki/Arduino-IDE-1.5:-Library-specification#keywords
function check_keywords_txt()
{
  local -r searchPath="$1"

  # Replace backslashes with slashes
  local -r searchPathWithSlashes="${searchPath//\\//}"
  # Remove trailing slash
  local -r normalizedSearchPath="${searchPathWithSlashes%/}"

  # Check whether folder exists
  if [[ ! -d "$normalizedSearchPath" ]]; then
    echo "ERROR: Specified folder: $normalizedSearchPath doesn't exist."
    return 1
  fi

  # find all folders that contain a keywords.txt file
  find "$normalizedSearchPath" -type f -regex '.*/[kK][eE][yY][wW][oO][rR][dD][sS]\.[tT][xX][tT]' | while read -r keywordsTxtPath; do

    # Check for incorrect filename case
    if [[ "${keywordsTxtPath: -12}" != 'keywords.txt' ]]; then
        echo "ERROR: $keywordsTxtPath uses incorrect filename case, which causes it to not be recognized on a filename case-sensitive OS such as Linux."
        return 2
    fi

    # Read the keywords.txt file line by line
    # Split into lines by CR
    while IFS='' read -d $'\r' -r keywordsTxtCRline || [[ -n "$keywordsTxtCRline" ]]; do
      # Split into lines by LN
      while IFS='' read -r keywordsTxtLine || [[ -n "$keywordsTxtLine" ]]; do
        local blankLineRegex='^[[:space:]]*$'
        local commentRegex='^[[:space:]]*#'
        if ! [[ ("$keywordsTxtLine" =~ $blankLineRegex) || ("$keywordsTxtLine" =~ $commentRegex) ]]; then

          # Check for invalid separator
          local validSeparatorRegex='^[[:space:]]*[^[:space:]]+[[:space:]]*'$'\t''+[^[:space:]]+'
          if ! [[ "$keywordsTxtLine" =~ $validSeparatorRegex ]]; then
            echo "ERROR: $keywordsTxtPath uses invalid field separator. It must be a true tab."
            return 3
          fi

          # Check for multiple tabs used as separator where this causes unintended results
          local consequentialMultipleSeparatorRegex='^[[:space:]]*[^[:space:]]+[[:space:]]*'$'\t\t''+((KEYWORD1)|(LITERAL1))'
          if [[ "$keywordsTxtLine" =~ $consequentialMultipleSeparatorRegex ]]; then
            echo "ERROR: $keywordsTxtPath uses multiple tabs as field separator. It must be a single tab. This causes the default keyword coloring (as used by KEYWORD2, KEYWORD3, LITERAL2) to be used rather than the intended coloration."
            return 4
          fi

          # Get the field values
          # Use a unique, non-whitespace field separator character
          fieldSeparator=$'\a'
          IFS=$fieldSeparator
          # Change tabs to the field separator character for line splitting
          local keywordsTxtLineSwappedTabs=(${keywordsTxtLine//$'\t'/$fieldSeparator})

          # Unused, so commented
          # # KEYWORD is the 1st field
          # local keywordRaw=${keywordsTxtLineSwappedTabs[0]}
          # # The Arduino IDE strips leading whitespace and trailing spaces from KEYWORD
          # # Strip leading whitespace
          # local keywordFrontStripped="${keywordRaw#"${keywordRaw%%[![:space:]]*}"}"
          # # Strip trailing spaces
          # local keyword="${keywordFrontStripped%"${keywordFrontStripped##*[! ]}"}"

          # KEYWORD_TOKENTYPE is the 2nd field
          local keywordTokentypeRaw=${keywordsTxtLineSwappedTabs[1]}
          # The Arduino IDE strips trailing spaces from KEYWORD_TOKENTYPE
          # Strip trailing spaces
          local keywordTokentype="${keywordTokentypeRaw%"${keywordTokentypeRaw##*[! ]}"}"

          # REFERENCE_LINK is the 3rd field
          local referenceLinkRaw=${keywordsTxtLineSwappedTabs[2]}
          # The Arduino IDE strips leading and trailing whitespace from REFERENCE_LINK
          # Strip leading spaces
          local referenceLinkFrontStripped="${referenceLinkRaw#"${referenceLinkRaw%%[! ]*}"}"
          # Strip trailing spaces
          local referenceLink="${referenceLinkFrontStripped%"${referenceLinkFrontStripped##*[! ]}"}"

          # RSYNTAXTEXTAREA_TOKENTYPE is the 4th field
          local rsyntaxtextareaTokentypeRaw=${keywordsTxtLineSwappedTabs[3]}
          # The Arduino IDE strips trailing spaces from RSYNTAXTEXTAREA_TOKENTYPE
          # Strip trailing spaces
          local rsyntaxtextareaTokentype="${rsyntaxtextareaTokentypeRaw%"${rsyntaxtextareaTokentypeRaw##*[! ]}"}"

          # Reset IFS to default
          unset IFS

          # Check for multiple tabs used as separator where this causes no unintended results
          # A large percentage of Arduino libraries have this problem
          local inconsequentialMultipleSeparatorRegex='^[[:space:]]*[^[:space:]]+[[:space:]]*'$'\t\t''+((KEYWORD2)|(KEYWORD3)|(LITERAL2))'
          if [[ "$keywordsTxtLine" =~ $inconsequentialMultipleSeparatorRegex ]]; then
            echo "WARNING: $keywordsTxtPath uses multiple tabs as field separator. It must be a single tab. This causes the default keyword coloring (as used by KEYWORD2, KEYWORD3, LITERAL2). In this case that doesn't cause the keywords to be incorrectly colored as expected but it's recommended to fully comply with the Arduino library specification."
          else
            # The rest of the checks will be borked by the use of multiple tabs as a separator

            # Check for invalid KEYWORD_TOKENTYPE
            local validKeywordTokentypeRegex='^((KEYWORD1)|(KEYWORD2)|(KEYWORD3)|(LITERAL1)|(LITERAL2))$'
            if ! [[ "$keywordTokentype" =~ $validKeywordTokentypeRegex ]]; then
              echo "ERROR: $keywordsTxtPath uses invalid KEYWORD_TOKENTYPE: ${keywordTokentype}, which causes the default keyword coloration to be used. See: https://github.com/arduino/Arduino/wiki/Arduino-IDE-1.5:-Library-specification#keyword_tokentype"
              return 5
            fi

            # Check for invalid RSYNTAXTEXTAREA_TOKENTYPE
            if [[ "$rsyntaxtextareaTokentype" != "" ]]; then
              local validRsyntaxtextareaTokentypeRegex='^((RESERVED_WORD)|(RESERVED_WORD2)|(DATA_TYPE)|(PREPROCESSOR))$'
              if ! [[ "$rsyntaxtextareaTokentype" =~ $validRsyntaxtextareaTokentypeRegex ]]; then
                echo "ERROR: $keywordsTxtPath uses invalid RSYNTAXTEXTAREA_TOKENTYPE: ${rsyntaxtextareaTokentype}, which causes the default keyword coloration to be used. See: https://github.com/arduino/Arduino/wiki/Arduino-IDE-1.5:-Library-specification#rsyntaxtextarea_tokentype"
                return 6
              fi
            fi

            # Check for invalid REFERENCE_LINK
            if [[ "$referenceLink" != "" ]]; then
              # The Arduino IDE must be installed to check if the reference page exists
              if [[ "$NEWEST_INSTALLED_IDE_VERSION" == "" ]]; then
                echo "WARNING: Arduino IDE is not installed so unable to check for invalid reference links. Please call install_ide before running check_keywords_txt."
              else
                install_ide_version "$NEWEST_INSTALLED_IDE_VERSION"
                if ! [[ -e "${ARDUINO_CI_SCRIPT_APPLICATION_FOLDER}/${ARDUINO_CI_SCRIPT_IDE_INSTALLATION_FOLDER}/reference/www.arduino.cc/en/Reference/${referenceLink}.html" ]]; then
                  echo "ERROR: $keywordsTxtPath uses a REFERENCE_LINK value: $referenceLink that is not a valid Arduino Language Reference page. See: https://github.com/arduino/Arduino/wiki/Arduino-IDE-1.5:-Library-specification#reference_link"
                  return 7
                fi
              fi
            fi

          fi
        fi
      done <<< "$keywordsTxtCRline"
    done < "$keywordsTxtPath"
  done
}


# https://github.com/arduino/Arduino/wiki/Library-Manager-FAQ#how-is-the-library-list-generated
function check_library_manager_compliance()
{
  local -r libraryPath="$1"
  # Replace backslashes with slashes
  local -r libraryPathWithSlashes="${libraryPath//\\//}"
  # Remove trailing slash
  local -r normalizedLibraryPath="${libraryPathWithSlashes%/}"

  # Check whether folder exists
  if [[ ! -d "$normalizedLibraryPath" ]]; then
    echo "ERROR: Specified folder: $libraryPath doesn't exist."
    return 1
  fi

  # Check for .exe files
  if [[ $(find "$normalizedLibraryPath" -type f -name '*.exe') ]]; then
    echo "ERROR: .exe file found."
    return 2
  fi

  # Check for .development file
  if [[ $(find "$normalizedLibraryPath" -type f -name '.development') ]]; then
    echo "ERROR: .development file found."
    return 3
  fi

  # Check for .development file
  if [[ $(find "$normalizedLibraryPath" -type l) ]]; then
    echo "ERROR: Symlink found."
    return 4
  fi
}


# Set default verbosity (must be called after the function definitions
set_script_verbosity 0


# Create the temporary folder
create_folder "$ARDUINO_CI_SCRIPT_TEMPORARY_FOLDER"

# Create the report folder
create_folder "$ARDUINO_CI_SCRIPT_REPORT_FOLDER"


# Add column names to report
echo "Build Timestamp (UTC)"$'\t'"Build"$'\t'"Job"$'\t'"Job URL"$'\t'"Build Trigger"$'\t'"Allow Job Failure"$'\t'"PR#"$'\t'"Branch"$'\t'"Commit"$'\t'"Commit Range"$'\t'"Commit Message"$'\t'"Sketch Filename"$'\t'"Board ID"$'\t'"IDE Version"$'\t'"Program Storage (bytes)"$'\t'"Dynamic Memory (bytes)"$'\t'"# Warnings"$'\t'"Allow Failure"$'\t'"Exit Status"$'\t'"# Board Issues"$'\t'"Board Issue"$'\t'"# Library Issues"$'\t'"Library Issue"$'\r' > "$ARDUINO_CI_SCRIPT_REPORT_FILE_PATH"


# Start the virtual display required by the Arduino IDE CLI: https://github.com/arduino/Arduino/blob/master/build/shared/manpage.adoc#bugs
# based on https://learn.adafruit.com/continuous-integration-arduino-and-you/testing-your-project
if [ -e /usr/bin/Xvfb ]; then
  /sbin/start-stop-daemon --start $ARDUINO_CI_SCRIPT_QUIET_OPTION $ARDUINO_CI_SCRIPT_VERBOSITY_OPTION --pidfile /tmp/custom_xvfb_1.pid --make-pidfile --background --exec /usr/bin/Xvfb -- :1 -ac -screen 0 1280x1024x16
  sleep 3
  export DISPLAY=:1.0
fi
