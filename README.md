arduino-ci-script
==========

Bash script for continuous integration of [Arduino](http://www.arduino.cc/) projects. I'm using this centrally managed script for multiple repositories to make updates easy. I'm using this with [Travis CI](http://travis-ci.org/) but it could be easily adapted to other purposes.

[![Build Status](https://travis-ci.org/per1234/arduino-ci-script.svg?branch=master)](https://travis-ci.org/per1234/arduino-ci-script)

#### Installation
- You can download a .zip of all the files from https://github.com/per1234/arduino-ci-script/archive/master.zip
- Include the script in your project by adding the following line:
```bash
source arduino-ci-script.sh
```
- Or if you want to leave the files hosted in this repository:
```bash
source <(curl -SLs https://raw.githubusercontent.com/per1234/arduino-ci-script/master/arduino-ci-script.sh)
```


#### Usage
See https://github.com/per1234/arduino-ci-script/blob/master/.travis.yml for an example of the script in use.
##### `set_parameters APPLICATION_FOLDER SKETCHBOOK_FOLDER verboseArduinoOutput`
Used to pass some parameters from .travis.yml to the script.
- Parameter: **APPLICATION_FOLDER** - This should be set to `/usr/local/share`. The Arduino IDE will be installed in the `arduino` subfolder.
- Parameter: **SKETCHBOOK_FOLDER** - The folder to be set as the Arduino IDE's sketchbook folder. Libraries installed via the Arduino IDE CLI's `--install-library` option will be installed to the `libraries` subfolder of this folder. You can also use the `libraries` subfolder of this folder for [manually installing libraries in the recommended manner](https://www.arduino.cc/en/Guide/Libraries#toc5).
- Parameter: **verboseArduinoOutput** - Set to `true` to turn on verbose output during compilation.

##### `install_ide [IDE_VERSIONS]`
Install all versions of the Arduino IDE specified in the script file.
- Parameter(optional): **IDE_VERSIONS** - A list of the versions of the Arduino IDE you want installed. e.g. `'("1.6.5-r5" "1.6.9" "1.8.2")'`

##### `install_package packageID [packageURL]`
Install a hardware package. Only the **Arduino AVR Boards** package is included with the Arduino IDE installation. Packages are installed to `$HOME/.arduino15/packages.
- Parameter: **packageID** - `package name:platform architecture[:version]`. If `version` is omitted the most recent version will be installed. e.g. `arduino:samd` will install the most recent version of **Arduino SAM Boards**.
- Parameter(optional): **packageURL** - The URL of the Boards Manager JSON file for 3rd party hardware packages. This can be omitted for hardware packages that are included in the official Arduino JSON file (e.g. Arduino SAM Boards, Arduino SAMD Boards, Intel Curie Boards).

##### `install_library_from_repo`
Install the library from the current repository. Assumes the library is in the root of the repository.

##### `install_library_dependency libraryDependencyURL`
Install a library to the `libraries` subfolder of the sketchbook folder.
- Parameter: **libraryDependencyURL** - The URL of the library download. This can be any compressed file format or a .git file will cause that repository to be cloned. Assumes the library is located in the root of the file.

##### `build_sketch sketchPath boardID IDEversion allowFail`
Pass some parameters from .travis.yml to the script. `build_sketch` will echo the arduino exit code to the log, which is documented at https://github.com/arduino/Arduino/blob/master/build/shared/manpage.adoc#exit-status.
- Parameter: **sketchPath** - Path to a sketch or folder containing sketches. If a folder is specified it will be recursively searched and all sketches will be verified.
- Parameter: **boardID** - `package:arch:board[:parameters]` ID of the board to be compiled for. e.g. `arduino:avr:uno`.
- Parameter: **IDEversion** - The version of the Arduino IDE to use to verify the sketch. Use `"all"` to verify with all installed versions of the Arduino IDE. Use `"newest"` to verify with the newest installed version of the Arduino IDE.
- Parameter: **allowFail** - `true` or `false`. Allow the verification to fail without causing the CI build to fail.

##### `display_report`
Echo a tab separated report of all verification results to the log. The report consists of:
- Build timestamp
- Travis build number
- Branch
- Commit hash of the build
- Commit subject
- Sketch filename
- Board ID
- IDE version
- Program storage usage
- Dynamic memory usage by global variables (not available for some boards)
- Number of warnings
- Allowed to fail
- Sketch verification exit code

Note that Travis CI runs each build of the job in a separate virtual machine so if you have multiple jobs you will have multiple reports. The only way I have found to generate a single report for all tests is to run them as a single job. This means not setting multiple matrix environment variables in the `env` array. See https://docs.travis-ci.com/user/environment-variables.

##### `check_success`
This function returns an exit code of 1 if any sketch verification failed except for those that were allowed failure by setting the `build_sketch` function's `allowFail` argument to `"true"`. Returns 0 otherwise.


#### Contributing
Pull requests or issue reports are welcome! Please see the [contribution rules](https://github.com/per1234/arduino-ci-script/blob/master/CONTRIBUTING.md) for instructions.

