#!/bin/bash
# shellcheck disable=SC2155

# Copyright (c) 2011 Float Mobile Learning
# http://www.floatlearning.com/
# Extension Copyright (c) 2013 Weptun Gmbh
# http://www.weptun.de
#
# Extended by Ronan O Ciosoig January 2012
#
# Extended by Patrick Blitz, April 2013
#
# Extended by John Turnipseed and Matthew Nespor, November 2014
# http://nanonation.net/
#
# Extended by Nicolas Bachschmidt, October 2015
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# Please let us know about any improvements you make to this script!
# ./floatsign source "iPhone Distribution: Name" -p "path/to/profile" [-d "display name"]  [-e entitlements] [-k keychain] [-b "BundleIdentifier"] outputIpa
#
#
# Modified 26th January 2012
#
# new features January 2012:
# 1. change the app display name
#
# new features April 2013
# 1. specify the target bundleId on the command line
# 2. correctly handles entitlements for keychain-enabled resigning
#
# new features November 2014
# 1. now re-signs embedded iOS frameworks, if present, prior to re-signing the application itself
# 2. extracts the team-identifier from provisioning profile and uses it to update previous entitlements
# 3. fixed bug in packaging if -e flag is used
# 4. renamed 'temp' directory and made it a variable so it can be easily modified
# 5. various code formatting and logging adjustments
#
# new features October 2015
# 1. now re-signs nested applications and app extensions, if present, prior to re-signing the application itself
# 2. enables the -p option to be used more than once
# 3. ensures the provisioning profile's bundle-identifier matches the app's bundle identifier
# 4. extracts the entitlements from the provisioning profile
# 5. copy the entitlements as archived-expanded-entitlements.xcent inside the app bundle (because Xcode does too)
#
# new features November 2018
# 1. only create the archived-expanded-entitlements.xcent file if the version of Xcode < 9.3 as Xcode 10 does not create it.
#
# new features January 2019
# 1. fixed bug where the com.apple.icloud-container-environment entitlement was being assigned an incorrect value
#
# new features March 2019
# 1. two more fixes for only creating the archived-expanded-entitlements.xcent file if the version of Xcode < 9.3 as Xcode 10 does not create it.
#
# new features June 2020
# 1. enable (re)signing of OnDemandResources when ipa has been built for the appstore
#
# new features August 2020
# 1. fixes usage for users with GNU-sed in their $PATH
#
# new features May 2021
# 1. fix entitlements merging when changing team
#
# new features June 2021
# 1. fix the way app entitlements are extracted
#
# new features October 2021
# 1. change codesign signature to use --generate-entitlement-der to include DER encoded entitlements

# Logging functions

log() {
    # Make sure it returns 0 code even when verbose mode is off (test 1)
    # To use like [[ condition ]] && log "x" && something
    if [[ -n "$VERBOSE" ]]; then echo -e "$@"; else test 1; fi
}

error() {
    echo "$@" >&2
    exit 1
}

warning() {
    echo "$@" >&2
}

function checkStatus {

    # shellcheck disable=SC2181
    if [ $? -ne 0 ]; then
        error "Encountered an error, aborting!"
    fi
}

usage() {
    echo -e "Usage: $(basename "$0") source identity -p|--provisioning provisioning" >&2
    echo -e "\t\t[-e|--entitlements entitlements]" >&2
    echo -e "\t\t[-k|--keychain keychain]" >&2
    echo -e "\t\t[-d|--display-name displayName]" >&2
    echo -e "\t\t[-n|--version-number version]" >&2
    echo -e "\t\t[--short-version shortVersion]" >&2
    echo -e "\t\t[--bundle-version bundleVersion]" >&2
    echo -e "\t\t[-b|--bundle-id bundleId]" >&2
    echo -e "\t\t[--use-app-entitlements]" >&2
    echo -e "\t\toutputIpa" >&2
    echo "Usage: $(basename "$0") -h|--help" >&2
    echo "Options:" >&2
    echo -e "\t-p, --provisioning provisioning\t\tProvisioning profile option, may be provided multiple times." >&2
    echo -e "\t\t\t\t\t\tYou can specify provisioning profile file name." >&2
    echo -e "\t\t\t\t\t\t\t-p xxx.mobileprovision" >&2
    echo "" >&2
    echo -e "\t\t\t\t\t\tAlternatively you may provide multiple provisioning profiles if the application contains" >&2
    echo -e "\t\t\t\t\t\tnested applications or app extensions, which need their own provisioning" >&2
    echo -e "\t\t\t\t\t\tprofile. You can do so by providing -p option multiple times specifying" >&2
    echo -e "\t\t\t\t\t\told bundle identifier and new provisioning profile for that bundle id joined with '='." >&2
    echo -e "\t\t\t\t\t\t\t-p com.main-app=main-app.mobileprovision" >&2
    echo -e "\t\t\t\t\t\t\t-p com.nested-app=nested-app.mobileprovision" >&2
    echo -e "\t\t\t\t\t\t\t-p com.nested-extension=nested-extension.mobileprovision" >&2
    echo "" >&2
    echo -e "\t-e, --entitlements entitlements\t\tSpecify entitlements file path for code signing." >&2
    echo -e "\t-k, --keychain keychain\t\t\tSpecify keychain for code signing." >&2
    echo -e "\t-d, --display-name displayName\t\tSpecify new display name." >&2
    echo -e "\t\t\t\t\t\t\tWarning: will apply for all nested apps and extensions." >&2
    echo -e "\t-n, --version-number version\t\tSpecify new version number." >&2
    echo -e "\t\t\t\t\t\t\tWill set CFBundleShortVersionString and CFBundleVersion values in Info.plist." >&2
    echo -e "\t\t\t\t\t\t\tWill apply for all nested apps and extensions." >&2
    echo -e "\t    --short-version shortVersion\tSpecify new short version string (CFBundleShortVersionString)." >&2
    echo -e "\t\t\t\t\t\t\tWill apply for all nested apps and extensions." >&2
    echo -e "\t\t\t\t\t\t\tCan't use together with '-n, --version-number' option." >&2
    echo -e "\t    --bundle-version bundleVersion\tSpecify new bundle version (CFBundleVersion) number." >&2
    echo -e "\t\t\t\t\t\t\tWill apply for all nested apps and extensions." >&2
    echo -e "\t\t\t\t\t\t\tCan't use together with '-n, --version-number' option." >&2
    echo -e "\t-b, --bundle-id bundleId\t\tSpecify new bundle identifier (CFBundleIdentifier)." >&2
    echo -e "\t\t\t\t\t\t\tWarning: will NOT apply for nested apps and extensions." >&2
    echo -e "\t    --use-app-entitlements\t\tExtract app bundle codesigning entitlements and combine with entitlements from new provisioning profile." >&2
    echo -e "\t\t\t\t\t\t\tCan't use together with '-e, --entitlements' option." >&2
    echo -e "\t--keychain-path path\t\t\tSpecify the path to a keychain that /usr/bin/codesign should use." >&2
    echo -e "\t-v, --verbose\t\t\t\tVerbose output." >&2
    echo -e "\t-h, --help\t\t\t\tDisplay help message." >&2
    exit 2
}

if [ $# -lt 3 ]; then
    usage
fi

ORIGINAL_FILE="$1"
CERTIFICATE="$2"
ENTITLEMENTS=
BUNDLE_IDENTIFIER=""
APPCLIP_BUNDLE_IDENTIFIER=""
DISPLAY_NAME=""
KEYCHAIN=""
VERSION_NUMBER=""
SHORT_VERSION=
BUNDLE_VERSION=
KEYCHAIN_PATH=
RAW_PROVISIONS=()
PROVISIONS_BY_ID=()
DEFAULT_PROVISION=""
TEMP_DIR="_floatsignTemp"
USE_APP_ENTITLEMENTS=""
XCODE_VERSION="$(xcodebuild -version | grep "Xcode" | /usr/bin/cut -f 2 -d ' ')"

# List of plist keys used for reference to and from nested apps and extensions
NESTED_APP_REFERENCE_KEYS=(":WKCompanionAppBundleIdentifier" ":NSExtension:NSExtensionAttributes:WKAppBundleIdentifier")

# options start index
shift 2

# Parse args
while [ "$1" != "" ]; do
    case $1 in
        -p | --provisioning )
            shift
            RAW_PROVISIONS+=("$1")
            ;;
        -e | --entitlements )
            shift
            ENTITLEMENTS="$1"
            ;;
        -d | --display-name )
            shift
            DISPLAY_NAME="$1"
            ;;
        -b | --bundle-id )
            shift
            BUNDLE_IDENTIFIER="$1"
            ;;
        --app-clip-bundle-id )
            shift
            APPCLIP_BUNDLE_IDENTIFIER="$1"
            ;;
        -k | --keychain )
            shift
            KEYCHAIN="$1"
            ;;
        -n | --version-number )
            shift
            VERSION_NUMBER="$1"
            ;;
        --short-version )
            shift
            SHORT_VERSION="$1"
            ;;
        --bundle-version )
            shift
            BUNDLE_VERSION="$1"
            ;;
        --use-app-entitlements )
            USE_APP_ENTITLEMENTS="YES"
            ;;
        --keychain-path )
            shift
            KEYCHAIN_PATH="$1"
            ;;
        -v | --verbose )
            VERBOSE="--verbose"
            ;;
        -h | --help )
            usage
            ;;
        * )
            [[ -n "$NEW_FILE" ]] && error "Multiple output file names specified!"
            [[ -z "$NEW_FILE" ]] && NEW_FILE="$1"
            ;;
    esac

    # Next arg
    shift
done

KEYCHAIN_FLAG=
if [ -n "$KEYCHAIN_PATH" ]; then
    KEYCHAIN_FLAG="--keychain $KEYCHAIN_PATH"
fi

# Log the options
for provision in "${RAW_PROVISIONS[@]}"; do
    if [[ "$provision" =~ .+=.+ ]]; then
        log "Specified provisioning profile: '${provision#*=}' for bundle identifier: '${provision%%=*}'"
    else
        log "Specified provisioning profile: '$provision'"
    fi
done

log "Original file: '$ORIGINAL_FILE'"
log "Certificate: '$CERTIFICATE'"
[[ -n "${DISPLAY_NAME}" ]] && log "Specified display name: '$DISPLAY_NAME'"
[[ -n "${ENTITLEMENTS}" ]] && log "Specified signing entitlements: '$ENTITLEMENTS'"
[[ -n "${BUNDLE_IDENTIFIER}" ]] && log "Specified bundle identifier: '$BUNDLE_IDENTIFIER'"
[[ -n "${APPCLIP_BUNDLE_IDENTIFIER}" ]] && log "Specified AppClip bundle identifier: '$APPCLIP_BUNDLE_IDENTIFIER'"
[[ -n "${KEYCHAIN}" ]] && log "Specified keychain to use: '$KEYCHAIN'"
[[ -n "${VERSION_NUMBER}" ]] && log "Specified version number to use: '$VERSION_NUMBER'"
[[ -n "${SHORT_VERSION}" ]] && log "Specified short version to use: '$SHORT_VERSION'"
[[ -n "${BUNDLE_VERSION}" ]] && log "Specified bundle version to use: '$BUNDLE_VERSION'"
[[ -n "${KEYCHAIN_FLAG}" ]] && log "Specified keychain to use: '$KEYCHAIN_PATH'"
[[ -n "${NEW_FILE}" ]] && log "Output file name: '$NEW_FILE'"
[[ -n "${USE_APP_ENTITLEMENTS}" ]] && log "Extract app entitlements: YES"

# Check that version number option is not clashing with short or bundle version options
[[ -n "$VERSION_NUMBER" && (-n "$SHORT_VERSION" || -n "$BUNDLE_VERSION") ]] && error "versionNumber option cannot be used in combination with shortVersion or bundleVersion options"

# Check that --use-app-entitlements and -e, --entitlements are not used at the same time
[[ -n "${USE_APP_ENTITLEMENTS}" && -n ${ENTITLEMENTS} ]] && error "--use-app-entitlements option cannot be used in combination with -e, --entitlements option."

# Check output file name
if [ -z "$NEW_FILE" ]; then
    error "Output file name required"
fi

if [[ "${#RAW_PROVISIONS[*]}" == "0" ]]; then
    error "-p 'xxxx.mobileprovision' argument is required"
fi

# Check for and remove the temporary directory if it already exists
if [ -d "$TEMP_DIR" ]; then
    log "Removing previous temporary directory: '$TEMP_DIR'"
    rm -Rf "$TEMP_DIR"
fi

filename=$(basename "$ORIGINAL_FILE")
extension="${filename##*.}"
filename="${filename%.*}"

# Check if the supplied file is an ipa or an app file
if [ "${extension}" = "ipa" ]; then
    # Unzip the old ipa quietly
    unzip -q "$ORIGINAL_FILE" -d $TEMP_DIR
    checkStatus
elif [ "${extension}" = "app" ]; then
    # Copy the app file into an ipa-like structure
    mkdir -p "$TEMP_DIR/Payload"
    cp -Rf "${ORIGINAL_FILE}" "$TEMP_DIR/Payload/${filename}.app"
    checkStatus
else
    error "Error: Only can resign .app files and .ipa files."
fi

# check the keychain
if [ "${KEYCHAIN}" != "" ]; then
    security list-keychains -s "$KEYCHAIN"
    security unlock "$KEYCHAIN"
    security default-keychain -s "$KEYCHAIN"
fi

# Set the app name
# In Payload directory may be another file except .app file, such as StoreKit folder.
# Search the first .app file within the Payload directory
# shellcheck disable=SC2010
APP_NAME=$(ls "$TEMP_DIR/Payload/" | grep ".app$" | head -1)

# Make sure that PATH includes the location of the PlistBuddy helper tool as its location is not standard
export PATH=$PATH:/usr/libexec

# Test whether two bundle identifiers match
# The first one may contain the wildcard character '*', in which case pattern matching will be used unless the third parameter is "STRICT"
function does_bundle_id_match {

    # shellcheck disable=SC2049
    if [[ "$1" == "$2" ]]; then
        return 0
    elif [[ "$3" != STRICT && "$1" =~ \* ]]; then
        local PATTERN0="${1//\./\\.}"       # com.example.*     -> com\.example\.*
        local PATTERN1="${PATTERN0//\*/.*}" # com\.example\.*   -> com\.example\..*
        if [[ "$2" =~ ^$PATTERN1$ ]]; then
            return 0
        fi
    fi

    return 1
}

# Find the provisioning profile for a given bundle identifier
function provision_for_bundle_id {

    for ARG in "${PROVISIONS_BY_ID[@]}"; do
        if does_bundle_id_match "${ARG%%=*}" "$1" "$2"; then
            echo "${ARG#*=}"
            break
        fi
    done
}

# Find the bundle identifier contained inside a provisioning profile
function bundle_id_for_provision {

    local FULL_BUNDLE_ID=$(PlistBuddy -c 'Print :Entitlements:application-identifier' /dev/stdin <<< "$(security cms -D -i "$1")")
    checkStatus
    echo "${FULL_BUNDLE_ID#*.}"
}

# Add given provisioning profile and bundle identifier to the search list
function add_provision_for_bundle_id {

    local PROVISION="$1"
    local BUNDLE_ID="$2"

    local CURRENT_PROVISION=$(provision_for_bundle_id "$BUNDLE_ID" STRICT)

    if [[ "$CURRENT_PROVISION" != "" && "$CURRENT_PROVISION" != "$PROVISION" ]]; then
        error "Conflicting provisioning profiles '$PROVISION' and '$CURRENT_PROVISION' for bundle identifier '$BUNDLE_ID'."
    fi

    PROVISIONS_BY_ID+=("$BUNDLE_ID=$PROVISION")
}

# Add given provisioning profile to the search list
function add_provision {

    local PROVISION="$1"

    if [[ "$1" =~ .+=.+ ]]; then
        PROVISION="${1#*=}"
        add_provision_for_bundle_id "$PROVISION" "${1%%=*}"
    elif [[ "$DEFAULT_PROVISION" == "" ]]; then
        DEFAULT_PROVISION="$PROVISION"
    fi

    if [[ ! -e "$PROVISION" ]]; then
        error "Provisioning profile '$PROVISION' file does not exist"
    fi

    local BUNDLE_ID=$(bundle_id_for_provision "$PROVISION")
    add_provision_for_bundle_id "$PROVISION" "$BUNDLE_ID"
}

# Load bundle identifiers from provisioning profiles
for ARG in "${RAW_PROVISIONS[@]}"; do
    add_provision "$ARG"
done

# Resign the given application
function resign {

    local APP_PATH="$1"
    local NESTED="$2"
    local IS_APPCLIP="$3"
    local BUNDLE_IDENTIFIER="$BUNDLE_IDENTIFIER"
    local APPCLIP_BUNDLE_IDENTIFIER="$APPCLIP_BUNDLE_IDENTIFIER"
    local NEW_PROVISION="$NEW_PROVISION"
    local APP_IDENTIFIER_PREFIX=""
    local TEAM_IDENTIFIER=""

    if [[ "$NESTED" == NESTED ]]; then
        if [[ "$IS_APPCLIP" == IS_APPCLIP ]]; then
            # Update bundle identifier for AppClips
            if [[ "$APPCLIP_BUNDLE_IDENTIFIER" == "" ]]; then
                # Supports appending `.Clip` to end of main bundle identifier as presented in Apple's documentation if explicit value is not provided.
                BUNDLE_IDENTIFIER="${BUNDLE_IDENTIFIER}.Clip"
            else
                BUNDLE_IDENTIFIER="$APPCLIP_BUNDLE_IDENTIFIER"
            fi
        else
            # Ignore bundle identifier for nested applications
            BUNDLE_IDENTIFIER=""
        fi        
    fi

    # Make sure that the Info.plist file is where we expect it
    if [ ! -e "$APP_PATH/Info.plist" ]; then
        error "Expected file does not exist: '$APP_PATH/Info.plist'"
    fi

    # Make a copy of old Info.plist, it will come handy later to extract some old values
    cp -f "$APP_PATH/Info.plist" "$TEMP_DIR/oldInfo.plist"

    # Read in current values from the app
    local CURRENT_NAME=$(PlistBuddy -c "Print :CFBundleDisplayName" "$APP_PATH/Info.plist")
    local CURRENT_BUNDLE_IDENTIFIER=$(PlistBuddy -c "Print :CFBundleIdentifier" "$APP_PATH/Info.plist")
    local NEW_PROVISION=$(provision_for_bundle_id "${BUNDLE_IDENTIFIER:-$CURRENT_BUNDLE_IDENTIFIER}")

    if [[ "$NEW_PROVISION" == "" && "$NESTED" != NESTED ]]; then
        NEW_PROVISION="$DEFAULT_PROVISION"
    fi

    if [[ "$NEW_PROVISION" == "" ]]; then
        if [[ "$NESTED" == NESTED ]]; then
            warning "No provisioning profile for nested application: '$APP_PATH' with bundle identifier '${BUNDLE_IDENTIFIER:-$CURRENT_BUNDLE_IDENTIFIER}'"
        else
            warning "No provisioning profile for application: '$APP_PATH' with bundle identifier '${BUNDLE_IDENTIFIER:-$CURRENT_BUNDLE_IDENTIFIER}'"
        fi
        error "Use the -p option (example: -p com.example.app=xxxx.mobileprovision)"
    fi

    local PROVISION_BUNDLE_IDENTIFIER=$(bundle_id_for_provision "$NEW_PROVISION")

    # Use provisioning profile's bundle identifier
    if [ "$BUNDLE_IDENTIFIER" == "" ]; then
        # shellcheck disable=SC2049
        if [[ "$PROVISION_BUNDLE_IDENTIFIER" =~ \* ]]; then
            log "Bundle Identifier contains a *, using the current bundle identifier"
            BUNDLE_IDENTIFIER="$CURRENT_BUNDLE_IDENTIFIER"
        else
            BUNDLE_IDENTIFIER="$PROVISION_BUNDLE_IDENTIFIER"
        fi
    fi

    if ! does_bundle_id_match "$PROVISION_BUNDLE_IDENTIFIER" "$BUNDLE_IDENTIFIER"; then
        error "Bundle Identifier '$PROVISION_BUNDLE_IDENTIFIER' in provisioning profile '$NEW_PROVISION' does not match the Bundle Identifier '$BUNDLE_IDENTIFIER' for application '$APP_PATH'."
    fi

    log "Current bundle identifier is: '$CURRENT_BUNDLE_IDENTIFIER'"
    log "New bundle identifier will be: '$BUNDLE_IDENTIFIER'"

    # Update the CFBundleDisplayName property in the Info.plist if a new name has been provided
    if [ "${DISPLAY_NAME}" != "" ]; then
        if [ "${DISPLAY_NAME}" != "${CURRENT_NAME}" ]; then
            log "Changing display name from '$CURRENT_NAME' to '$DISPLAY_NAME'"
            PlistBuddy -c "Set :CFBundleDisplayName $DISPLAY_NAME" "$APP_PATH/Info.plist"
        fi
    fi

    # Replace the embedded mobile provisioning profile
    log "Validating the new provisioning profile: $NEW_PROVISION"
    security cms -D -i "$NEW_PROVISION" > "$TEMP_DIR/profile.plist"
    checkStatus

    APP_IDENTIFIER_PREFIX=$(PlistBuddy -c "Print :Entitlements:application-identifier" "$TEMP_DIR/profile.plist" | grep -E '^[A-Z0-9]*' -o | tr -d '\n')
    if [ "$APP_IDENTIFIER_PREFIX" == "" ];
    then
        APP_IDENTIFIER_PREFIX=$(PlistBuddy -c "Print :ApplicationIdentifierPrefix:0" "$TEMP_DIR/profile.plist")
        if [ "$APP_IDENTIFIER_PREFIX" == "" ]; then
            error "Failed to extract any app identifier prefix from '$NEW_PROVISION'"
        else
            warning "WARNING: extracted an app identifier prefix '$APP_IDENTIFIER_PREFIX' from '$NEW_PROVISION', but it was not found in the profile's entitlements"
        fi
    else
        log "Profile app identifier prefix is '$APP_IDENTIFIER_PREFIX'"
    fi

    # Set new app identifier prefix if such entry exists in plist file
    PlistBuddy -c "Set :AppIdentifierPrefix $APP_IDENTIFIER_PREFIX." "$APP_PATH/Info.plist" 2>/dev/null

    TEAM_IDENTIFIER=$(PlistBuddy -c "Print :Entitlements:com.apple.developer.team-identifier" "$TEMP_DIR/profile.plist" | tr -d '\n')
    if [ "$TEAM_IDENTIFIER" == "" ]; then
        TEAM_IDENTIFIER=$(PlistBuddy -c "Print :TeamIdentifier:0" "$TEMP_DIR/profile.plist")
        if [ "$TEAM_IDENTIFIER" == "" ]; then
            warning "Failed to extract team identifier from '$NEW_PROVISION', resigned ipa may fail on iOS 8 and higher"
        else
            warning "WARNING: extracted a team identifier '$TEAM_IDENTIFIER' from '$NEW_PROVISION', but it was not found in the profile's entitlements, resigned ipa may fail on iOS 8 and higher"
        fi
    else
        log "Profile team identifier is '$TEAM_IDENTIFIER'"
    fi

    # Make a copy of old embedded provisioning profile for further use
    cp -f "$APP_PATH/embedded.mobileprovision" "$TEMP_DIR/old-embedded.mobileprovision"

    # Replace embedded provisioning profile with new file
    cp -f "$NEW_PROVISION" "$APP_PATH/embedded.mobileprovision"

    #if the current bundle identifier is different from the new one in the provisioning profile, then change it.
    if [ "$CURRENT_BUNDLE_IDENTIFIER" != "$BUNDLE_IDENTIFIER" ]; then
        log "Updating the bundle identifier from '$CURRENT_BUNDLE_IDENTIFIER' to '$BUNDLE_IDENTIFIER'"
        PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_IDENTIFIER" "$APP_PATH/Info.plist"
        checkStatus
    fi

    # Update the version number properties in the Info.plist if a version number has been provided
    if [ "$VERSION_NUMBER" != "" ]; then
        CURRENT_VERSION_NUMBER=$(PlistBuddy -c "Print :CFBundleVersion" "$APP_PATH/Info.plist")
        if [ "$VERSION_NUMBER" != "$CURRENT_VERSION_NUMBER" ]; then
            log "Updating the version from '$CURRENT_VERSION_NUMBER' to '$VERSION_NUMBER'"
            PlistBuddy -c "Set :CFBundleVersion $VERSION_NUMBER" "$APP_PATH/Info.plist"
            PlistBuddy -c "Set :CFBundleShortVersionString $VERSION_NUMBER" "$APP_PATH/Info.plist"
        fi
    fi

    # Update short version string in the Info.plist if provided
    if [[ -n "$SHORT_VERSION" ]]; then
        CURRENT_VALUE="$(PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_PATH/Info.plist")"
        # Even if the old value is same - just update, less code, less debugging
        log "Updating the short version string (CFBundleShortVersionString) from '$CURRENT_VALUE' to '$SHORT_VERSION'"
        PlistBuddy -c "Set :CFBundleShortVersionString $SHORT_VERSION" "$APP_PATH/Info.plist"
    fi

    # Update bundle version in the Info.plist if provided
    if [[ -n "$BUNDLE_VERSION" ]]; then
        CURRENT_VALUE="$(PlistBuddy -c "Print :CFBundleVersion" "$APP_PATH/Info.plist")"
        # Even if the old value is same - just update, less code, less debugging
        log "Updating the bundle version (CFBundleVersion) from '$CURRENT_VALUE' to '$BUNDLE_VERSION'"
        PlistBuddy -c "Set :CFBundleVersion $BUNDLE_VERSION" "$APP_PATH/Info.plist"
    fi

    # Check for and resign OnDemandResource folders
    ODR_DIR="$(dirname "$APP_PATH")/OnDemandResources"
    if [ -d "$ODR_DIR" ]; then
        for assetpack in "$ODR_DIR"/*
        do
            if [[ "$assetpack" == *.assetpack ]]; then
                rm -rf $assetpack/_CodeSignature
                /usr/bin/codesign ${VERBOSE} --generate-entitlement-der ${KEYCHAIN_FLAG} -f -s "$CERTIFICATE" "$assetpack"
                checkStatus
            else
                log "Ignoring non-assetpack: $assetpack"
            fi
        done
    fi

    # Check for and resign any embedded frameworks (new feature for iOS 8 and above apps)
    FRAMEWORKS_DIR="$APP_PATH/Frameworks"
    if [ -d "$FRAMEWORKS_DIR" ]; then
        if [ "$TEAM_IDENTIFIER" == "" ]; then
            error "ERROR: embedded frameworks detected, re-signing iOS 8 (or higher) applications without a team identifier in the certificate/profile does not work"
        fi

        log "Resigning embedded frameworks using certificate: '$CERTIFICATE'"
        for framework in "$FRAMEWORKS_DIR"/*
        do
            if [[ "$framework" == *.framework || "$framework" == *.dylib ]]; then
                log "Resigning '$framework'"
                # Must not quote KEYCHAIN_FLAG because it needs to be unwrapped and passed to codesign with spaces
                # shellcheck disable=SC2086
                /usr/bin/codesign ${VERBOSE} --generate-entitlement-der ${KEYCHAIN_FLAG} -f -s "$CERTIFICATE" "$framework"
                checkStatus
            else
                log "Ignoring non-framework: $framework"
            fi
        done
    fi

    # Check for and update bundle identifiers for extensions and associated nested apps
    log "Fixing nested app and extension references"
    for key in "${NESTED_APP_REFERENCE_KEYS[@]}"; do
        # Check if Info.plist has a reference to another app or extension
        REF_BUNDLE_ID=$(PlistBuddy -c "Print ${key}" "$APP_PATH/Info.plist" 2>/dev/null)
        if [ -n "$REF_BUNDLE_ID" ]; then
            # Found a reference bundle id, now get the corresponding provisioning profile for this bundle id
            REF_PROVISION=$(provision_for_bundle_id "$REF_BUNDLE_ID")
            # Map to the new bundle id
            NEW_REF_BUNDLE_ID=$(bundle_id_for_provision "$REF_PROVISION")
            # Change if not the same and if doesn't contain wildcard
            # shellcheck disable=SC2049
            if [[ "$REF_BUNDLE_ID" != "$NEW_REF_BUNDLE_ID" ]] && ! [[ "$NEW_REF_BUNDLE_ID" =~ \* ]]; then
                log "Updating nested app or extension reference for ${key} key from ${REF_BUNDLE_ID} to ${NEW_REF_BUNDLE_ID}"
                PlistBuddy -c "Set ${key} $NEW_REF_BUNDLE_ID" "$APP_PATH/Info.plist"
            fi
        fi
    done

    if [ "$ENTITLEMENTS" != "" ]; then
        if [ -n "$APP_IDENTIFIER_PREFIX" ]; then
            # sanity check the 'application-identifier' is present in the provided entitlements and matches the provisioning profile value
            ENTITLEMENTS_APP_ID_PREFIX=$(PlistBuddy -c "Print :application-identifier" "$ENTITLEMENTS" | grep -E '^[A-Z0-9]*' -o | tr -d '\n')
            if [ "$ENTITLEMENTS_APP_ID_PREFIX" == "" ]; then
                error "Provided entitlements file is missing a value for the required 'application-identifier' key"
            elif [ "$ENTITLEMENTS_APP_ID_PREFIX" != "$APP_IDENTIFIER_PREFIX" ]; then
                error "Provided entitlements file's app identifier prefix value '$ENTITLEMENTS_APP_ID_PREFIX' does not match the provided provisioning profile's value '$APP_IDENTIFIER_PREFIX'"
            fi
        fi

        if [ -n "$TEAM_IDENTIFIER" ]; then
            # sanity check the 'com.apple.developer.team-identifier' is present in the provided entitlements and matches the provisioning profile value
            ENTITLEMENTS_TEAM_IDENTIFIER=$(PlistBuddy -c "Print :com.apple.developer.team-identifier" "$ENTITLEMENTS" | tr -d '\n')
            if [ "$ENTITLEMENTS_TEAM_IDENTIFIER" == "" ]; then
                error "Provided entitlements file is missing a value for the required 'com.apple.developer.team-identifier' key"
            elif [ "$ENTITLEMENTS_TEAM_IDENTIFIER" != "$TEAM_IDENTIFIER" ]; then
                error "Provided entitlements file's 'com.apple.developer.team-identifier' '$ENTITLEMENTS_TEAM_IDENTIFIER' does not match the provided provisioning profile's value '$TEAM_IDENTIFIER'"
            fi
        fi

        log "Resigning application using certificate: '$CERTIFICATE'"
        log "and entitlements: $ENTITLEMENTS"
        if [[ "${XCODE_VERSION/.*/}" -lt 10 ]]; then
            log "Creating an archived-expanded-entitlements.xcent file for Xcode 9 builds or earlier"
            cp -f "$ENTITLEMENTS" "$APP_PATH/archived-expanded-entitlements.xcent"
        fi
        /usr/bin/codesign ${VERBOSE} --generate-entitlement-der -f -s "$CERTIFICATE" --entitlements "$ENTITLEMENTS" "$APP_PATH"
        checkStatus
    elif  [[ -n "${USE_APP_ENTITLEMENTS}" ]]; then
        # Extract entitlements from provisioning profile and from the app binary
        # then combine them together

        log "Extracting entitlements from provisioning profile"
        PROFILE_ENTITLEMENTS="$TEMP_DIR/profileEntitlements"
        PlistBuddy -x -c "Print Entitlements" "$TEMP_DIR/profile.plist" > "$PROFILE_ENTITLEMENTS"
        checkStatus

        log "Extracting entitlements from the app"
        APP_ENTITLEMENTS="$TEMP_DIR/appEntitlements"
        /usr/bin/codesign -d --entitlements :"$APP_ENTITLEMENTS" "$APP_PATH"
        checkStatus

        log "\nApp entitlements for ${APP_PATH}:"
        log "$(cat "$APP_ENTITLEMENTS")"

        # Get the old and new app identifier (prefix)
        APP_ID_KEY="application-identifier"
        # Extract just the identifier from the value
        # Use the fact that we are after some identifier, which is always at the start of the string
        OLD_APP_ID=$(PlistBuddy -c "Print $APP_ID_KEY" "$APP_ENTITLEMENTS" | grep -E '^[A-Z0-9]*' -o | tr -d '\n')
        NEW_APP_ID=$(PlistBuddy -c "Print $APP_ID_KEY" "$PROFILE_ENTITLEMENTS" | grep -E '^[A-Z0-9]*' -o | tr -d '\n')

        # Get the old and the new team ID
        # Old team ID is not part of app entitlements, have to get it from old embedded provisioning profile
        security cms -D -i "$TEMP_DIR/old-embedded.mobileprovision" > "$TEMP_DIR/old-embedded-profile.plist"
        OLD_TEAM_ID=$(PlistBuddy -c "Print :TeamIdentifier:0" "$TEMP_DIR/old-embedded-profile.plist")
        # New team ID is part of profile entitlements
        NEW_TEAM_ID=$(PlistBuddy -c "Print com.apple.developer.team-identifier" "$PROFILE_ENTITLEMENTS" | grep -E '^[A-Z0-9]*' -o | tr -d '\n')

        log "Patching profile entitlements with values from app entitlements"
        PATCHED_ENTITLEMENTS="$TEMP_DIR/patchedEntitlements"
        # Start with using what comes in provisioning profile entitlements before patching
        cp -f "$PROFILE_ENTITLEMENTS" "$PATCHED_ENTITLEMENTS"

        log "Removing denylisted keys from patched profile"
        # See https://github.com/facebook/buck/issues/798 and https://github.com/facebook/buck/pull/802/files

        # Update in https://github.com/facebook/buck/commit/99c0fbc3ab5ecf04d186913374f660683deccdef
        # Update in https://github.com/facebook/buck/commit/36db188da9f6acbb9df419dc1904315ab00c4e19

        # Buck changes referenced above are not self-explanatory and do not seem exhaustive or up-to-date
        # Comments below explain the rules applied to each key in order to make realignment with future Xcode export logic easier
        DENYLISTED_KEYS=(\
            # PP list identifiers inconsistent with app-defined ones and this key does not seem to appear in IPA entitlements, so ignore it
            "com.apple.developer.icloud-container-development-container-identifiers" \
            # This key has an invalid generic value in PP (actual value is set by Xcode during export), see dedicated processing a few blocks below
            "com.apple.developer.icloud-container-environment" \
            # PP enable all available services and not app-defined ones, must use App entitlements value
            "com.apple.developer.icloud-services" \
            # Was already denylisted in previous version, but has someone ever seen this key in a PP?
            "com.apple.developer.restricted-resource-mode" \
            # If actually used by the App, this value will be set in its entitlements
            "com.apple.developer.nfc.readersession.formats" \
            # If actually used by the App, this value will be set in its entitlements
            "com.apple.developer.siri" \
            # PP define a generic TeamID.* identifier and not the app-defined one, must use App entitlements value
            "com.apple.developer.ubiquity-kvstore-identifier" \
            # If actually used by the App, this value will be set in its entitlements
            "inter-app-audio" \
            # PP define a generic TeamID.* identifier and not the app-defined one, must use App entitlements value
            "keychain-access-groups" \
            # If actually used by the App, this value will be set in its entitlements
            "com.apple.developer.homekit" \
            # If actually used by the App, this value will be set in its entitlements
            "com.apple.developer.healthkit" \
            # If actually used by the App, this value will be set in its entitlements
            "com.apple.developer.healthkit.access" \
            # If actually used by the App, this value will be set in its entitlements
            "com.apple.developer.networking.vpn.api" \
            # If actually used by the App, this value will be set in its entitlements
            "com.apple.developer.networking.HotspotConfiguration" \
            # PP list all available extensions and not app-defined ones, must use App entitlements value
            "com.apple.developer.networking.networkextension" \
            # If actually used by the App, this value will be set in its entitlements
            "com.apple.developer.networking.multipath" \
            # PP enable all domains via a non-AppStore-compliant '*' value, must use App entitlements value
            "com.apple.developer.associated-domains" \
            # If actually used by the App, this value will be set in its entitlements
            "com.apple.developer.default-data-protection" \
            # Was already denylisted in previous version, seems to be an artifact from an old Xcode release
            "com.apple.developer.maps" \
            # If actually used by the App, this value will be set in its entitlements
            "com.apple.external-accessory.wireless-configuration"
        )

        # If we change team while resigning, we have no other choice than to use the following entitlements from the PP instead of the App
        # because they are based on unique identifiers (defined in the developer portal) that can't be shared between teams
        if [[ "$OLD_TEAM_ID" != "$NEW_TEAM_ID" ]]; then
            warning "WARNING: Changing team while resigning"
            warning "WARNING: Using these entitlements from the provisioning profile instead of the existing app:"
            warning "WARNING: App Groups, Merchant IDs (Apple Pay In-App Payments), iCloud Containers, Pass Type IDs (Wallet)"
            warning "WARNING: If these capabilities are enabled, make sure AppID and provisioning profile are properly configured"
            # For Pass Types, PP only list a single TeamID.* identifier and not the potential restricted list defined in the existing App
            # but we can't guess the new identifiers to be used, so this generic value is better than nothing and should be fine for most apps
            warning "WARNING: Resigned app will allow all pass types from the new team, even if old app only allowed a restricted list"
        else
            DENYLISTED_KEYS+=(\
                "com.apple.security.application-groups" \
                "com.apple.developer.in-app-payments" \
                "com.apple.developer.ubiquity-container-identifiers" \
                "com.apple.developer.icloud-container-identifiers" \
                "com.apple.developer.pass-type-identifiers" \
            )
        fi

        # Denylisted keys must not be included into new profile, so remove them from patched profile
        for KEY in "${DENYLISTED_KEYS[@]}"; do
            log "Removing denylisted key: $KEY"
            PlistBuddy -c "Delete $KEY" "$PATCHED_ENTITLEMENTS" 2>/dev/null
        done

        # List of rules for transferring entitlements from app to profile plist
        # The format for each entry is "KEY[|ID_TYPE]"
        # Where KEY is the plist key, e.g. "keychain-access-groups"
        # and ID_TYPE is optional part separated by '|' that specifies what value to patch:
        # TEAM_ID - patch the TeamIdentifierPrefix
        # APP_ID - patch the AppIdentifierPrefix
        # ICLOUD_ENV - patch the target iCloud Environment
        # Patching means replacing old value from app entitlements with new value from provisioning profile
        # For example, for KEY=keychain-access-groups the ID_TYPE=APP_ID
        # Which means that old app ID prefix in keychain-access-groups will be replaced with new app ID prefix
        # There can be only one ID_TYPE specified
        # If entitlements use more than one ID type for single entitlement, then this way of resigning will not work
        # instead an entitlements file must be provided explicitly
        ENTITLEMENTS_TRANSFER_RULES=(\
            "com.apple.developer.associated-domains" \
            "com.apple.developer.default-data-protection" \
            "com.apple.developer.healthkit" \
            "com.apple.developer.healthkit.access" \
            "com.apple.developer.homekit" \
            "com.apple.developer.icloud-container-environment|ICLOUD_ENV" \
            "com.apple.developer.icloud-services" \
            "com.apple.developer.networking.HotspotConfiguration" \
            "com.apple.developer.networking.multipath" \
            "com.apple.developer.networking.networkextension" \
            "com.apple.developer.networking.vpn.api" \
            "com.apple.developer.nfc.readersession.formats" \
            "com.apple.developer.siri" \
            "com.apple.developer.ubiquity-kvstore-identifier|TEAM_ID" \
            "com.apple.external-accessory.wireless-configuration" \
            "inter-app-audio" \
            "keychain-access-groups|APP_ID" \
        )

        # If we change team while resigning, we have no other choice than to use the following entitlements from the PP instead of the App
        # because they are based on unique identifiers (defined in the developer portal) that can't be shared between teams
        # If we don't change team while resigning, we should use the following entitlements from the existing App and not from the PP
        if [[ "$OLD_TEAM_ID" == "$NEW_TEAM_ID" ]]; then
            ENTITLEMENTS_TRANSFER_RULES+=(\
                "com.apple.security.application-groups" \
                "com.apple.developer.in-app-payments" \
                "com.apple.developer.ubiquity-container-identifiers" \
                "com.apple.developer.icloud-container-identifiers" \
                "com.apple.developer.pass-type-identifiers|TEAM_ID" \
            )
        fi

        # Loop over all the entitlement keys that need to be transferred from app entitlements
        for RULE in "${ENTITLEMENTS_TRANSFER_RULES[@]}"; do
            KEY=$(echo "$RULE" | cut -d'|' -f1)
            ID_TYPE=$(echo "$RULE" | cut -d'|' -f2)

            # Get the entry from app's entitlements
            # Read it with PlistBuddy as XML, then strip the header and <plist></plist> part
            ENTITLEMENTS_VALUE="$(PlistBuddy -x -c "Print $KEY" "$APP_ENTITLEMENTS" 2>/dev/null | tr -d '\n' | /usr/bin/sed -e 's,.*<plist[^>]*>\(.*\)</plist>,\1,g')"
            if [[ -z "$ENTITLEMENTS_VALUE" ]]; then
                log "No value for '$KEY'"
                continue
            fi

            log "App entitlements value for key '$KEY':"
            log "$ENTITLEMENTS_VALUE"

            # Patch the ID value if specified
            if [[ "$ID_TYPE" == "APP_ID" ]]; then
                # Replace old value with new value in patched entitlements
                log "Replacing old app ID '$OLD_APP_ID' with new app ID '$NEW_APP_ID'"
                ENTITLEMENTS_VALUE=$(echo "$ENTITLEMENTS_VALUE" | /usr/bin/sed -e "s/$OLD_APP_ID/$NEW_APP_ID/g")
            elif [[ "$ID_TYPE" == "TEAM_ID" ]]; then
                # Replace old team identifier with new value
                log "Replacing old team ID '$OLD_TEAM_ID' with new team ID '$NEW_TEAM_ID'"
                ENTITLEMENTS_VALUE=$(echo "$ENTITLEMENTS_VALUE" | /usr/bin/sed -e "s/$OLD_TEAM_ID/$NEW_TEAM_ID/g")
            elif [[ "$ID_TYPE" == "ICLOUD_ENV" ]]; then
                # Add specific iCloud Environment key to patched entitlements
                # This value is set by Xcode during export (manually selected for Development and AdHoc, automatically set to Production for Store)
                # Would need an additional dedicated option to specify the iCloud environment to be used (Development or Production)
                # For now, we assume Production is to be used when signing with a Distribution certificate, Development if not
                local certificate_name=$CERTIFICATE
                local sha1_pattern='[0-9A-F]{40}'

                if [[ "$CERTIFICATE" =~ $sha1_pattern ]]; then
                    log "Certificate $CERTIFICATE matches a SHA1 pattern"
                    local certificate_matches="$( security find-identity -v -p codesigning | grep -m 1 "$CERTIFICATE" )"
                    if [ -n "$certificate_matches" ]; then
                        certificate_name="$(/usr/bin/sed -E s/[^\"]+\"\([^\"]+\)\".*/\\1/ <<< $certificate_matches )"
                        log "Certificate name: $certificate_name"
                    fi
                fi

                OLD_ICLOUD_ENV=$(echo "$ENTITLEMENTS_VALUE" | /usr/bin/sed -e 's,<string>\(.*\)</string>,\1,g')
                if [[ "$certificate_name" =~ "Distribution:" ]]; then
                    NEW_ICLOUD_ENV="Production"
                else
                    NEW_ICLOUD_ENV="Development"
                fi
                log "Replacing iCloud environment '$OLD_ICLOUD_ENV' with '$NEW_ICLOUD_ENV'"
                ENTITLEMENTS_VALUE=$(echo "$ENTITLEMENTS_VALUE" | /usr/bin/sed -e "s/$OLD_ICLOUD_ENV/$NEW_ICLOUD_ENV/g")
            fi

            # Remove the entry for current key from provisioning profile entitlements (if exists)
            PlistBuddy -c "Delete $KEY" "$PATCHED_ENTITLEMENTS" 2>/dev/null

            # Add new entry to patched entitlements
            # plutil needs dots in the key path to be escaped (e.g. com\.apple\.security\.application-groups)
            # otherwise it interprets they key path as nested keys
            # TODO: Should be able to replace with echo ${KEY//\./\\\\.} and remove shellcheck disable directive
            # shellcheck disable=SC2001
            PLUTIL_KEY=$(echo "$KEY" | /usr/bin/sed -e 's/\./\\\./g')
            plutil -insert "$PLUTIL_KEY" -xml "$ENTITLEMENTS_VALUE" "$PATCHED_ENTITLEMENTS"
        done

        # Replace old bundle ID with new bundle ID in patched entitlements
        # Read old bundle ID from the old Info.plist which was saved for this purpose
        OLD_BUNDLE_ID="$(PlistBuddy -c "Print :CFBundleIdentifier" "$TEMP_DIR/oldInfo.plist")"
        NEW_BUNDLE_ID="$(bundle_id_for_provision "$NEW_PROVISION")"
        log "Replacing old bundle ID '$OLD_BUNDLE_ID' with new bundle ID '$NEW_BUNDLE_ID' in patched entitlements"
        # Note: ideally we'd match against the opening <string> tag too, but this isn't possible
        # because $OLD_BUNDLE_ID and $NEW_BUNDLE_ID do not include the team ID prefix which is
        # present in the entitlements file.
        # e.g. <string>AB1GP98Q19.com.example.foo</string>
        #         vs
        #      com.example.foo
        /usr/bin/sed -i .bak "s!${OLD_BUNDLE_ID}</string>!${NEW_BUNDLE_ID}</string>!g" "$PATCHED_ENTITLEMENTS"

        log "Resigning application using certificate: '$CERTIFICATE'"
        log "and patched entitlements:"
        log "$(cat "$PATCHED_ENTITLEMENTS")"
        if [[ "${XCODE_VERSION/.*/}" -lt 10 ]]; then
            log "Creating an archived-expanded-entitlements.xcent file for Xcode 9 builds or earlier"
            cp -f "$PATCHED_ENTITLEMENTS" "$APP_PATH/archived-expanded-entitlements.xcent"
        fi
        /usr/bin/codesign ${VERBOSE} --generate-entitlement-der -f -s "$CERTIFICATE" --entitlements "$PATCHED_ENTITLEMENTS" "$APP_PATH"
        checkStatus
    else
        log "Extracting entitlements from provisioning profile"
        PlistBuddy -x -c "Print Entitlements" "$TEMP_DIR/profile.plist" > "$TEMP_DIR/newEntitlements"
        checkStatus
        log "Resigning application using certificate: '$CERTIFICATE'"
        log "and entitlements from provisioning profile: $NEW_PROVISION"
        if [[ "${XCODE_VERSION/.*/}" -lt 10 ]]; then
            log "Creating an archived-expanded-entitlements.xcent file for Xcode 9 builds or earlier"
            cp -- "$TEMP_DIR/newEntitlements" "$APP_PATH/archived-expanded-entitlements.xcent"
        fi
        # Must not quote KEYCHAIN_FLAG because it needs to be unwrapped and passed to codesign with spaces
        # shellcheck disable=SC2086
        /usr/bin/codesign ${VERBOSE} --generate-entitlement-der ${KEYCHAIN_FLAG} -f -s "$CERTIFICATE" --entitlements "$TEMP_DIR/newEntitlements" "$APP_PATH"
        checkStatus
    fi

    # Remove the temporary files if they were created before generating ipa
    rm -f "$TEMP_DIR/newEntitlements"
    rm -f "$PROFILE_ENTITLEMENTS"
    rm -f "$APP_ENTITLEMENTS"
    rm -f "$PATCHED_ENTITLEMENTS"
    rm -f "$PATCHED_ENTITLEMENTS.bak"
    rm -f "$TEMP_DIR/old-embedded-profile.plist"
    rm -f "$TEMP_DIR/profile.plist"
    rm -f "$TEMP_DIR/old-embedded.mobileprovision"
    rm -f "$TEMP_DIR/oldInfo.plist"
}

# Sign nested applications and app extensions
while IFS= read -d '' -r app;
do
    log "Resigning nested application: '$app'"
    if [[ $app == *"AppClips"* ]]; then
        log "Nested application is an AppClip: '$app'"
        resign "$app" NESTED IS_APPCLIP 
    else
        resign "$app" NESTED
    fi    
done < <(find "$TEMP_DIR/Payload/$APP_NAME" -d -mindepth 1 \( -name "*.app" -or -name "*.appex" \) -print0)

# Resign the application
resign "$TEMP_DIR/Payload/$APP_NAME"

# Repackage quietly
log "Repackaging as $NEW_FILE"

# Zip up the contents of the "$TEMP_DIR" folder
# Navigate to the temporary directory (sending the output to null)
# Zip all the contents, saving the zip file in the above directory
# Navigate back to the originating directory (sending the output to null)
pushd "$TEMP_DIR" > /dev/null
# TODO: Fix shellcheck warning and remove directive
# shellcheck disable=SC2035
zip -qry "../$TEMP_DIR.ipa" *
popd > /dev/null

# Move the resulting ipa to the target destination
mv "$TEMP_DIR.ipa" "$NEW_FILE"

# Remove the temp directory
rm -rf "$TEMP_DIR"

log "Process complete"
