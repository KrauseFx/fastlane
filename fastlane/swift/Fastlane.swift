// Fastlane.swift
// Copyright (c) 2024 FastlaneTools

import Foundation

/**
 Run ADB Actions

 - parameters:
   - serial: Android serial of the device to use for this command
   - command: All commands you want to pass to the adb command, e.g. `kill-server`
   - adbPath: The path to your `adb` binary (can be left blank if the ANDROID_SDK_ROOT, ANDROID_HOME or ANDROID_SDK environment variable is set)

 - returns: The output of the adb command

 see adb --help for more details
 */
@discardableResult public func adb(serial: String = "",
                                   command: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                   adbPath: String = "adb") -> String
{
    let serialArg = RubyCommand.Argument(name: "serial", value: serial, type: nil)
    let commandArg = command.asRubyArgument(name: "command", type: nil)
    let adbPathArg = RubyCommand.Argument(name: "adb_path", value: adbPath, type: nil)
    let array: [RubyCommand.Argument?] = [serialArg,
                                          commandArg,
                                          adbPathArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "adb", className: nil, args: args)
    return runner.executeCommand(command)
}

/**
 Get an array of Connected android device serials

 - parameter adbPath: The path to your `adb` binary (can be left blank if the ANDROID_SDK_ROOT environment variable is set)

 - returns: Returns an array of all currently connected android devices. Example: []

 Fetches device list via adb, e.g. run an adb command on all connected devices.
 */
public func adbDevices(adbPath: String = "adb") {
    let adbPathArg = RubyCommand.Argument(name: "adb_path", value: adbPath, type: nil)
    let array: [RubyCommand.Argument?] = [adbPathArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "adb_devices", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Modify the default list of supported platforms

 - parameter platforms: The optional extra platforms to support
 */
public func addExtraPlatforms(platforms: [String] = []) {
    let platformsArg = RubyCommand.Argument(name: "platforms", value: platforms, type: nil)
    let array: [RubyCommand.Argument?] = [platformsArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "add_extra_platforms", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 This will add an annotated git tag to the current branch

 - parameters:
   - tag: Define your own tag text. This will replace all other parameters
   - grouping: Is used to keep your tags organised under one 'folder'
   - includesLane: Whether the current lane should be included in the tag and message composition, e.g. '<grouping>/<lane>/<prefix><build_number><postfix>'
   - prefix: Anything you want to put in front of the version number (e.g. 'v')
   - postfix: Anything you want to put at the end of the version number (e.g. '-RC1')
   - buildNumber: The build number. Defaults to the result of increment_build_number if you're using it
   - message: The tag message. Defaults to the tag's name
   - commit: The commit or object where the tag will be set. Defaults to the current HEAD
   - force: Force adding the tag
   - sign: Make a GPG-signed tag, using the default e-mail address's key

 This will automatically tag your build with the following format: `<grouping>/<lane>/<prefix><build_number><postfix>`, where:|
 |
 >- `grouping` is just to keep your tags organised under one 'folder', defaults to 'builds'|
 - `lane` is the name of the current fastlane lane, if chosen to be included via 'includes_lane' option, which defaults to 'true'|
 - `prefix` is anything you want to stick in front of the version number, e.g. 'v'|
 - `postfix` is anything you want to stick at the end of the version number, e.g. '-RC1'|
 - `build_number` is the build number, which defaults to the value emitted by the `increment_build_number` action|
 >|
 For example, for build 1234 in the 'appstore' lane, it will tag the commit with `builds/appstore/1234`.
 */
public func addGitTag(tag: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      grouping: String = "builds",
                      includesLane: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                      prefix: String = "",
                      postfix: String = "",
                      buildNumber: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      message: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      commit: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      force: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                      sign: OptionalConfigValue<Bool> = .fastlaneDefault(false))
{
    let tagArg = tag.asRubyArgument(name: "tag", type: nil)
    let groupingArg = RubyCommand.Argument(name: "grouping", value: grouping, type: nil)
    let includesLaneArg = includesLane.asRubyArgument(name: "includes_lane", type: nil)
    let prefixArg = RubyCommand.Argument(name: "prefix", value: prefix, type: nil)
    let postfixArg = RubyCommand.Argument(name: "postfix", value: postfix, type: nil)
    let buildNumberArg = buildNumber.asRubyArgument(name: "build_number", type: nil)
    let messageArg = message.asRubyArgument(name: "message", type: nil)
    let commitArg = commit.asRubyArgument(name: "commit", type: nil)
    let forceArg = force.asRubyArgument(name: "force", type: nil)
    let signArg = sign.asRubyArgument(name: "sign", type: nil)
    let array: [RubyCommand.Argument?] = [tagArg,
                                          groupingArg,
                                          includesLaneArg,
                                          prefixArg,
                                          postfixArg,
                                          buildNumberArg,
                                          messageArg,
                                          commitArg,
                                          forceArg,
                                          signArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "add_git_tag", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Returns the current build_number of either live or edit version

 - parameters:
   - apiKeyPath: Path to your App Store Connect API Key JSON file (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-json-file)
   - apiKey: Your App Store Connect API Key information (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-hash-option)
   - initialBuildNumber: sets the build number to given value if no build is in current train
   - appIdentifier: The bundle identifier of your app
   - username: Your Apple ID Username
   - teamId: The ID of your App Store Connect team if you're in multiple teams
   - live: Query the live version (ready-for-sale)
   - version: The version number whose latest build number we want
   - platform: The platform to use (optional)
   - teamName: The name of your App Store Connect team if you're in multiple teams

 Returns the current build number of either the live or testflight version - it is useful for getting the build_number of the current or ready-for-sale app version, and it also works on non-live testflight version.
 If you need to handle more build-trains please see `latest_testflight_build_number`.
 */
public func appStoreBuildNumber(apiKeyPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                apiKey: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                                initialBuildNumber: String,
                                appIdentifier: String,
                                username: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                teamId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                live: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                                version: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                platform: String = "ios",
                                teamName: OptionalConfigValue<String?> = .fastlaneDefault(nil))
{
    let apiKeyPathArg = apiKeyPath.asRubyArgument(name: "api_key_path", type: nil)
    let apiKeyArg = apiKey.asRubyArgument(name: "api_key", type: nil)
    let initialBuildNumberArg = RubyCommand.Argument(name: "initial_build_number", value: initialBuildNumber, type: nil)
    let appIdentifierArg = RubyCommand.Argument(name: "app_identifier", value: appIdentifier, type: nil)
    let usernameArg = username.asRubyArgument(name: "username", type: nil)
    let teamIdArg = teamId.asRubyArgument(name: "team_id", type: nil)
    let liveArg = live.asRubyArgument(name: "live", type: nil)
    let versionArg = version.asRubyArgument(name: "version", type: nil)
    let platformArg = RubyCommand.Argument(name: "platform", value: platform, type: nil)
    let teamNameArg = teamName.asRubyArgument(name: "team_name", type: nil)
    let array: [RubyCommand.Argument?] = [apiKeyPathArg,
                                          apiKeyArg,
                                          initialBuildNumberArg,
                                          appIdentifierArg,
                                          usernameArg,
                                          teamIdArg,
                                          liveArg,
                                          versionArg,
                                          platformArg,
                                          teamNameArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "app_store_build_number", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Load the App Store Connect API token to use in other fastlane tools and actions

 - parameters:
   - keyId: The key ID
   - issuerId: The issuer ID. It can be nil if the key is individual API key
   - keyFilepath: The path to the key p8 file
   - keyContent: The content of the key p8 file
   - isKeyContentBase64: Whether :key_content is Base64 encoded or not
   - duration: The token session duration
   - inHouse: Is App Store or Enterprise (in house) team? App Store Connect API cannot determine this on its own (yet)
   - setSpaceshipToken: Authorizes all Spaceship::ConnectAPI requests by automatically setting Spaceship::ConnectAPI.token

 Load the App Store Connect API token to use in other fastlane tools and actions
 */
public func appStoreConnectApiKey(keyId: String,
                                  issuerId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  keyFilepath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  keyContent: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  isKeyContentBase64: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                  duration: Int = 500,
                                  inHouse: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                  setSpaceshipToken: OptionalConfigValue<Bool> = .fastlaneDefault(true))
{
    let keyIdArg = RubyCommand.Argument(name: "key_id", value: keyId, type: nil)
    let issuerIdArg = issuerId.asRubyArgument(name: "issuer_id", type: nil)
    let keyFilepathArg = keyFilepath.asRubyArgument(name: "key_filepath", type: nil)
    let keyContentArg = keyContent.asRubyArgument(name: "key_content", type: nil)
    let isKeyContentBase64Arg = isKeyContentBase64.asRubyArgument(name: "is_key_content_base64", type: nil)
    let durationArg = RubyCommand.Argument(name: "duration", value: duration, type: nil)
    let inHouseArg = inHouse.asRubyArgument(name: "in_house", type: nil)
    let setSpaceshipTokenArg = setSpaceshipToken.asRubyArgument(name: "set_spaceship_token", type: nil)
    let array: [RubyCommand.Argument?] = [keyIdArg,
                                          issuerIdArg,
                                          keyFilepathArg,
                                          keyContentArg,
                                          isKeyContentBase64Arg,
                                          durationArg,
                                          inHouseArg,
                                          setSpaceshipTokenArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "app_store_connect_api_key", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Upload your app to [Appaloosa Store](https://www.appaloosa-store.com/)

 - parameters:
   - binary: Binary path. Optional for ipa if you use the `ipa` or `xcodebuild` action
   - apiToken: Your API token
   - storeId: Your Store id
   - groupIds: Your app is limited to special users? Give us the group ids
   - screenshots: Add some screenshots application to your store or hit [enter]
   - locale: Select the folder locale for your screenshots
   - device: Select the device format for your screenshots
   - description: Your app description
   - changelog: Your app changelog

 Appaloosa is a private mobile application store. This action offers a quick deployment on the platform.
 You can create an account, push to your existing account, or manage your user groups.
 We accept iOS and Android applications.
 */
public func appaloosa(binary: String,
                      apiToken: String,
                      storeId: String,
                      groupIds: String = "",
                      screenshots: String,
                      locale: String = "en-US",
                      device: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      description: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      changelog: OptionalConfigValue<String?> = .fastlaneDefault(nil))
{
    let binaryArg = RubyCommand.Argument(name: "binary", value: binary, type: nil)
    let apiTokenArg = RubyCommand.Argument(name: "api_token", value: apiToken, type: nil)
    let storeIdArg = RubyCommand.Argument(name: "store_id", value: storeId, type: nil)
    let groupIdsArg = RubyCommand.Argument(name: "group_ids", value: groupIds, type: nil)
    let screenshotsArg = RubyCommand.Argument(name: "screenshots", value: screenshots, type: nil)
    let localeArg = RubyCommand.Argument(name: "locale", value: locale, type: nil)
    let deviceArg = device.asRubyArgument(name: "device", type: nil)
    let descriptionArg = description.asRubyArgument(name: "description", type: nil)
    let changelogArg = changelog.asRubyArgument(name: "changelog", type: nil)
    let array: [RubyCommand.Argument?] = [binaryArg,
                                          apiTokenArg,
                                          storeIdArg,
                                          groupIdsArg,
                                          screenshotsArg,
                                          localeArg,
                                          deviceArg,
                                          descriptionArg,
                                          changelogArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "appaloosa", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Upload your app to [Appetize.io](https://appetize.io/) to stream it in browser

 - parameters:
   - apiHost: Appetize API host
   - apiToken: Appetize.io API Token
   - url: URL from which the ipa file can be fetched. Alternative to :path
   - platform: Platform. Either `ios` or `android`
   - path: Path to zipped build on the local filesystem. Either this or `url` must be specified
   - publicKey: If not provided, a new app will be created. If provided, the existing build will be overwritten
   - note: Notes you wish to add to the uploaded app
   - timeout: The number of seconds to wait until automatically ending the session due to user inactivity. Must be 30, 60, 90, 120, 180, 300, 600, 1800, 3600 or 7200. Default is 120

 If you provide a `public_key`, this will overwrite an existing application. If you want to have this build as a new app version, you shouldn't provide this value.

 To integrate appetize into your GitHub workflow check out the [device_grid guide](https://github.com/fastlane/fastlane/blob/master/fastlane/lib/fastlane/actions/device_grid/README.md).
 */
public func appetize(apiHost: String = "api.appetize.io",
                     apiToken: String,
                     url: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     platform: String = "ios",
                     path: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     publicKey: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     note: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     timeout: OptionalConfigValue<Int?> = .fastlaneDefault(nil))
{
    let apiHostArg = RubyCommand.Argument(name: "api_host", value: apiHost, type: nil)
    let apiTokenArg = RubyCommand.Argument(name: "api_token", value: apiToken, type: nil)
    let urlArg = url.asRubyArgument(name: "url", type: nil)
    let platformArg = RubyCommand.Argument(name: "platform", value: platform, type: nil)
    let pathArg = path.asRubyArgument(name: "path", type: nil)
    let publicKeyArg = publicKey.asRubyArgument(name: "public_key", type: nil)
    let noteArg = note.asRubyArgument(name: "note", type: nil)
    let timeoutArg = timeout.asRubyArgument(name: "timeout", type: nil)
    let array: [RubyCommand.Argument?] = [apiHostArg,
                                          apiTokenArg,
                                          urlArg,
                                          platformArg,
                                          pathArg,
                                          publicKeyArg,
                                          noteArg,
                                          timeoutArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "appetize", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Generate an URL for appetize simulator

 - parameters:
   - publicKey: Public key of the app you wish to update
   - baseUrl: Base URL of Appetize service
   - device: Device type: iphone4s, iphone5s, iphone6, iphone6plus, ipadair, iphone6s, iphone6splus, ipadair2, nexus5, nexus7 or nexus9
   - scale: Scale of the simulator
   - orientation: Device orientation
   - language: Device language in ISO 639-1 language code, e.g. 'de'
   - color: Color of the device
   - launchUrl: Specify a deep link to open when your app is launched
   - osVersion: The operating system version on which to run your app, e.g. 10.3, 8.0
   - params: Specify params value to be passed to Appetize
   - proxy: Specify a HTTP proxy to be passed to Appetize

 - returns: The URL to preview the iPhone app

 Check out the [device_grid guide](https://github.com/fastlane/fastlane/blob/master/fastlane/lib/fastlane/actions/device_grid/README.md) for more information
 */
public func appetizeViewingUrlGenerator(publicKey: String,
                                        baseUrl: String = "https://appetize.io/embed",
                                        device: String = "iphone5s",
                                        scale: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        orientation: String = "portrait",
                                        language: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        color: String = "black",
                                        launchUrl: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        osVersion: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        params: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        proxy: OptionalConfigValue<String?> = .fastlaneDefault(nil))
{
    let publicKeyArg = RubyCommand.Argument(name: "public_key", value: publicKey, type: nil)
    let baseUrlArg = RubyCommand.Argument(name: "base_url", value: baseUrl, type: nil)
    let deviceArg = RubyCommand.Argument(name: "device", value: device, type: nil)
    let scaleArg = scale.asRubyArgument(name: "scale", type: nil)
    let orientationArg = RubyCommand.Argument(name: "orientation", value: orientation, type: nil)
    let languageArg = language.asRubyArgument(name: "language", type: nil)
    let colorArg = RubyCommand.Argument(name: "color", value: color, type: nil)
    let launchUrlArg = launchUrl.asRubyArgument(name: "launch_url", type: nil)
    let osVersionArg = osVersion.asRubyArgument(name: "os_version", type: nil)
    let paramsArg = params.asRubyArgument(name: "params", type: nil)
    let proxyArg = proxy.asRubyArgument(name: "proxy", type: nil)
    let array: [RubyCommand.Argument?] = [publicKeyArg,
                                          baseUrlArg,
                                          deviceArg,
                                          scaleArg,
                                          orientationArg,
                                          languageArg,
                                          colorArg,
                                          launchUrlArg,
                                          osVersionArg,
                                          paramsArg,
                                          proxyArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "appetize_viewing_url_generator", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Run UI test by Appium with RSpec

 - parameters:
   - platform: Appium platform name
   - specPath: Path to Appium spec directory
   - appPath: Path to Appium target app file
   - invokeAppiumServer: Use local Appium server with invoke automatically
   - host: Hostname of Appium server
   - port: HTTP port of Appium server
   - appiumPath: Path to Appium executable
   - caps: Hash of caps for Appium::Driver
   - appiumLib: Hash of appium_lib for Appium::Driver
 */
public func appium(platform: String,
                   specPath: String,
                   appPath: String,
                   invokeAppiumServer: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                   host: String = "0.0.0.0",
                   port: Int = 4723,
                   appiumPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   caps: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                   appiumLib: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil))
{
    let platformArg = RubyCommand.Argument(name: "platform", value: platform, type: nil)
    let specPathArg = RubyCommand.Argument(name: "spec_path", value: specPath, type: nil)
    let appPathArg = RubyCommand.Argument(name: "app_path", value: appPath, type: nil)
    let invokeAppiumServerArg = invokeAppiumServer.asRubyArgument(name: "invoke_appium_server", type: nil)
    let hostArg = RubyCommand.Argument(name: "host", value: host, type: nil)
    let portArg = RubyCommand.Argument(name: "port", value: port, type: nil)
    let appiumPathArg = appiumPath.asRubyArgument(name: "appium_path", type: nil)
    let capsArg = caps.asRubyArgument(name: "caps", type: nil)
    let appiumLibArg = appiumLib.asRubyArgument(name: "appium_lib", type: nil)
    let array: [RubyCommand.Argument?] = [platformArg,
                                          specPathArg,
                                          appPathArg,
                                          invokeAppiumServerArg,
                                          hostArg,
                                          portArg,
                                          appiumPathArg,
                                          capsArg,
                                          appiumLibArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "appium", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Generate Apple-like source code documentation from the source code

 - parameters:
   - input: Path(s) to source file directories or individual source files. Accepts a single path or an array of paths
   - output: Output path
   - templates: Template files path
   - docsetInstallPath: DocSet installation path
   - include: Include static doc(s) at path
   - ignore: Ignore given path
   - excludeOutput: Exclude given path from output
   - indexDesc: File including main index description
   - projectName: Project name
   - projectVersion: Project version
   - projectCompany: Project company
   - companyId: Company UTI (i.e. reverse DNS name)
   - createHtml: Create HTML
   - createDocset: Create documentation set
   - installDocset: Install documentation set to Xcode
   - publishDocset: Prepare DocSet for publishing
   - noCreateDocset: Create HTML and skip creating a DocSet
   - htmlAnchors: The html anchor format to use in DocSet HTML
   - cleanOutput: Remove contents of output path before starting
   - docsetBundleId: DocSet bundle identifier
   - docsetBundleName: DocSet bundle name
   - docsetDesc: DocSet description
   - docsetCopyright: DocSet copyright message
   - docsetFeedName: DocSet feed name
   - docsetFeedUrl: DocSet feed URL
   - docsetFeedFormats: DocSet feed formats. Separated by a comma [atom,xml]
   - docsetPackageUrl: DocSet package (.xar) URL
   - docsetFallbackUrl: DocSet fallback URL
   - docsetPublisherId: DocSet publisher identifier
   - docsetPublisherName: DocSet publisher name
   - docsetMinXcodeVersion: DocSet min. Xcode version
   - docsetPlatformFamily: DocSet platform family
   - docsetCertIssuer: DocSet certificate issuer
   - docsetCertSigner: DocSet certificate signer
   - docsetBundleFilename: DocSet bundle filename
   - docsetAtomFilename: DocSet atom feed filename
   - docsetXmlFilename: DocSet xml feed filename
   - docsetPackageFilename: DocSet package (.xar,.tgz) filename
   - options: Documentation generation options
   - crossrefFormat: Cross reference template regex
   - exitThreshold: Exit code threshold below which 0 is returned
   - docsSectionTitle: Title of the documentation section (defaults to "Programming Guides"
   - warnings: Documentation generation warnings
   - logformat: Log format [0-3]
   - verbose: Log verbosity level [0-6,xcode]

 Runs `appledoc [OPTIONS] <paths to source dirs or files>` for the project
 */
public func appledoc(input: [String],
                     output: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     templates: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     docsetInstallPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     include: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     ignore: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                     excludeOutput: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                     indexDesc: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     projectName: String,
                     projectVersion: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     projectCompany: String,
                     companyId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     createHtml: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                     createDocset: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                     installDocset: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                     publishDocset: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                     noCreateDocset: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                     htmlAnchors: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     cleanOutput: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                     docsetBundleId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     docsetBundleName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     docsetDesc: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     docsetCopyright: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     docsetFeedName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     docsetFeedUrl: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     docsetFeedFormats: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     docsetPackageUrl: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     docsetFallbackUrl: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     docsetPublisherId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     docsetPublisherName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     docsetMinXcodeVersion: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     docsetPlatformFamily: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     docsetCertIssuer: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     docsetCertSigner: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     docsetBundleFilename: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     docsetAtomFilename: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     docsetXmlFilename: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     docsetPackageFilename: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     options: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     crossrefFormat: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     exitThreshold: Int = 2,
                     docsSectionTitle: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     warnings: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     logformat: OptionalConfigValue<Int?> = .fastlaneDefault(nil),
                     verbose: OptionalConfigValue<String?> = .fastlaneDefault(nil))
{
    let inputArg = RubyCommand.Argument(name: "input", value: input, type: nil)
    let outputArg = output.asRubyArgument(name: "output", type: nil)
    let templatesArg = templates.asRubyArgument(name: "templates", type: nil)
    let docsetInstallPathArg = docsetInstallPath.asRubyArgument(name: "docset_install_path", type: nil)
    let includeArg = include.asRubyArgument(name: "include", type: nil)
    let ignoreArg = ignore.asRubyArgument(name: "ignore", type: nil)
    let excludeOutputArg = excludeOutput.asRubyArgument(name: "exclude_output", type: nil)
    let indexDescArg = indexDesc.asRubyArgument(name: "index_desc", type: nil)
    let projectNameArg = RubyCommand.Argument(name: "project_name", value: projectName, type: nil)
    let projectVersionArg = projectVersion.asRubyArgument(name: "project_version", type: nil)
    let projectCompanyArg = RubyCommand.Argument(name: "project_company", value: projectCompany, type: nil)
    let companyIdArg = companyId.asRubyArgument(name: "company_id", type: nil)
    let createHtmlArg = createHtml.asRubyArgument(name: "create_html", type: nil)
    let createDocsetArg = createDocset.asRubyArgument(name: "create_docset", type: nil)
    let installDocsetArg = installDocset.asRubyArgument(name: "install_docset", type: nil)
    let publishDocsetArg = publishDocset.asRubyArgument(name: "publish_docset", type: nil)
    let noCreateDocsetArg = noCreateDocset.asRubyArgument(name: "no_create_docset", type: nil)
    let htmlAnchorsArg = htmlAnchors.asRubyArgument(name: "html_anchors", type: nil)
    let cleanOutputArg = cleanOutput.asRubyArgument(name: "clean_output", type: nil)
    let docsetBundleIdArg = docsetBundleId.asRubyArgument(name: "docset_bundle_id", type: nil)
    let docsetBundleNameArg = docsetBundleName.asRubyArgument(name: "docset_bundle_name", type: nil)
    let docsetDescArg = docsetDesc.asRubyArgument(name: "docset_desc", type: nil)
    let docsetCopyrightArg = docsetCopyright.asRubyArgument(name: "docset_copyright", type: nil)
    let docsetFeedNameArg = docsetFeedName.asRubyArgument(name: "docset_feed_name", type: nil)
    let docsetFeedUrlArg = docsetFeedUrl.asRubyArgument(name: "docset_feed_url", type: nil)
    let docsetFeedFormatsArg = docsetFeedFormats.asRubyArgument(name: "docset_feed_formats", type: nil)
    let docsetPackageUrlArg = docsetPackageUrl.asRubyArgument(name: "docset_package_url", type: nil)
    let docsetFallbackUrlArg = docsetFallbackUrl.asRubyArgument(name: "docset_fallback_url", type: nil)
    let docsetPublisherIdArg = docsetPublisherId.asRubyArgument(name: "docset_publisher_id", type: nil)
    let docsetPublisherNameArg = docsetPublisherName.asRubyArgument(name: "docset_publisher_name", type: nil)
    let docsetMinXcodeVersionArg = docsetMinXcodeVersion.asRubyArgument(name: "docset_min_xcode_version", type: nil)
    let docsetPlatformFamilyArg = docsetPlatformFamily.asRubyArgument(name: "docset_platform_family", type: nil)
    let docsetCertIssuerArg = docsetCertIssuer.asRubyArgument(name: "docset_cert_issuer", type: nil)
    let docsetCertSignerArg = docsetCertSigner.asRubyArgument(name: "docset_cert_signer", type: nil)
    let docsetBundleFilenameArg = docsetBundleFilename.asRubyArgument(name: "docset_bundle_filename", type: nil)
    let docsetAtomFilenameArg = docsetAtomFilename.asRubyArgument(name: "docset_atom_filename", type: nil)
    let docsetXmlFilenameArg = docsetXmlFilename.asRubyArgument(name: "docset_xml_filename", type: nil)
    let docsetPackageFilenameArg = docsetPackageFilename.asRubyArgument(name: "docset_package_filename", type: nil)
    let optionsArg = options.asRubyArgument(name: "options", type: nil)
    let crossrefFormatArg = crossrefFormat.asRubyArgument(name: "crossref_format", type: nil)
    let exitThresholdArg = RubyCommand.Argument(name: "exit_threshold", value: exitThreshold, type: nil)
    let docsSectionTitleArg = docsSectionTitle.asRubyArgument(name: "docs_section_title", type: nil)
    let warningsArg = warnings.asRubyArgument(name: "warnings", type: nil)
    let logformatArg = logformat.asRubyArgument(name: "logformat", type: nil)
    let verboseArg = verbose.asRubyArgument(name: "verbose", type: nil)
    let array: [RubyCommand.Argument?] = [inputArg,
                                          outputArg,
                                          templatesArg,
                                          docsetInstallPathArg,
                                          includeArg,
                                          ignoreArg,
                                          excludeOutputArg,
                                          indexDescArg,
                                          projectNameArg,
                                          projectVersionArg,
                                          projectCompanyArg,
                                          companyIdArg,
                                          createHtmlArg,
                                          createDocsetArg,
                                          installDocsetArg,
                                          publishDocsetArg,
                                          noCreateDocsetArg,
                                          htmlAnchorsArg,
                                          cleanOutputArg,
                                          docsetBundleIdArg,
                                          docsetBundleNameArg,
                                          docsetDescArg,
                                          docsetCopyrightArg,
                                          docsetFeedNameArg,
                                          docsetFeedUrlArg,
                                          docsetFeedFormatsArg,
                                          docsetPackageUrlArg,
                                          docsetFallbackUrlArg,
                                          docsetPublisherIdArg,
                                          docsetPublisherNameArg,
                                          docsetMinXcodeVersionArg,
                                          docsetPlatformFamilyArg,
                                          docsetCertIssuerArg,
                                          docsetCertSignerArg,
                                          docsetBundleFilenameArg,
                                          docsetAtomFilenameArg,
                                          docsetXmlFilenameArg,
                                          docsetPackageFilenameArg,
                                          optionsArg,
                                          crossrefFormatArg,
                                          exitThresholdArg,
                                          docsSectionTitleArg,
                                          warningsArg,
                                          logformatArg,
                                          verboseArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "appledoc", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Alias for the `upload_to_app_store` action

 - parameters:
   - apiKeyPath: Path to your App Store Connect API Key JSON file (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-json-file)
   - apiKey: Your App Store Connect API Key information (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-hash-option)
   - username: Your Apple ID Username
   - appIdentifier: The bundle identifier of your app
   - appVersion: The version that should be edited or created
   - ipa: Path to your ipa file
   - pkg: Path to your pkg file
   - buildNumber: If set the given build number (already uploaded to iTC) will be used instead of the current built one
   - platform: The platform to use (optional)
   - editLive: Modify live metadata, this option disables ipa upload and screenshot upload
   - useLiveVersion: Force usage of live version rather than edit version
   - metadataPath: Path to the folder containing the metadata files
   - screenshotsPath: Path to the folder containing the screenshots
   - skipBinaryUpload: Skip uploading an ipa or pkg to App Store Connect
   - skipScreenshots: Don't upload the screenshots
   - skipMetadata: Don't upload the metadata (e.g. title, description). This will still upload screenshots
   - skipAppVersionUpdate: Don’t create or update the app version that is being prepared for submission
   - force: Skip verification of HTML preview file
   - overwriteScreenshots: Clear all previously uploaded screenshots before uploading the new ones
   - screenshotProcessingTimeout: Timeout in seconds to wait before considering screenshot processing as failed, used to handle cases where uploads to the App Store are stuck in processing
   - syncScreenshots: Sync screenshots with local ones. This is currently beta option so set true to 'FASTLANE_ENABLE_BETA_DELIVER_SYNC_SCREENSHOTS' environment variable as well
   - submitForReview: Submit the new version for Review after uploading everything
   - verifyOnly: Verifies archive with App Store Connect without uploading
   - rejectIfPossible: Rejects the previously submitted build if it's in a state where it's possible
   - versionCheckWaitRetryLimit: After submitting a new version, App Store Connect takes some time to recognize the new version and we must wait until it's available before attempting to upload metadata for it. There is a mechanism that will check if it's available and retry with an exponential backoff if it's not available yet. This option specifies how many times we should retry before giving up. Setting this to a value below 5 is not recommended and will likely cause failures. Increase this parameter when Apple servers seem to be degraded or slow
   - automaticRelease: Should the app be automatically released once it's approved? (Cannot be used together with `auto_release_date`)
   - autoReleaseDate: Date in milliseconds for automatically releasing on pending approval (Cannot be used together with `automatic_release`)
   - phasedRelease: Enable the phased release feature of iTC
   - resetRatings: Reset the summary rating when you release a new version of the application
   - priceTier: The price tier of this application
   - appRatingConfigPath: Path to the app rating's config
   - submissionInformation: Extra information for the submission (e.g. compliance specifications)
   - teamId: The ID of your App Store Connect team if you're in multiple teams
   - teamName: The name of your App Store Connect team if you're in multiple teams
   - devPortalTeamId: The short ID of your Developer Portal team, if you're in multiple teams. Different from your iTC team ID!
   - devPortalTeamName: The name of your Developer Portal team if you're in multiple teams
   - itcProvider: The provider short name to be used with the iTMSTransporter to identify your team. This value will override the automatically detected provider short name. To get provider short name run `xcrun iTMSTransporter -m provider -u 'USERNAME' -p 'PASSWORD' -account_type itunes_connect -v off`. The short names of providers should be listed in the second column
   - runPrecheckBeforeSubmit: Run precheck before submitting to app review
   - precheckDefaultRuleLevel: The default precheck rule level unless otherwise configured
   - individualMetadataItems: **DEPRECATED!** Removed after the migration to the new App Store Connect API in June 2020 - An array of localized metadata items to upload individually by language so that errors can be identified. E.g. ['name', 'keywords', 'description']. Note: slow
   - appIcon: **DEPRECATED!** Removed after the migration to the new App Store Connect API in June 2020 - Metadata: The path to the app icon
   - appleWatchAppIcon: **DEPRECATED!** Removed after the migration to the new App Store Connect API in June 2020 - Metadata: The path to the Apple Watch app icon
   - copyright: Metadata: The copyright notice
   - primaryCategory: Metadata: The english name of the primary category (e.g. `Business`, `Books`)
   - secondaryCategory: Metadata: The english name of the secondary category (e.g. `Business`, `Books`)
   - primaryFirstSubCategory: Metadata: The english name of the primary first sub category (e.g. `Educational`, `Puzzle`)
   - primarySecondSubCategory: Metadata: The english name of the primary second sub category (e.g. `Educational`, `Puzzle`)
   - secondaryFirstSubCategory: Metadata: The english name of the secondary first sub category (e.g. `Educational`, `Puzzle`)
   - secondarySecondSubCategory: Metadata: The english name of the secondary second sub category (e.g. `Educational`, `Puzzle`)
   - tradeRepresentativeContactInformation: **DEPRECATED!** This is no longer used by App Store Connect - Metadata: A hash containing the trade representative contact information
   - appReviewInformation: Metadata: A hash containing the review information
   - appReviewAttachmentFile: Metadata: Path to the app review attachment file
   - description: Metadata: The localised app description
   - name: Metadata: The localised app name
   - subtitle: Metadata: The localised app subtitle
   - keywords: Metadata: An array of localised keywords
   - promotionalText: Metadata: An array of localised promotional texts
   - releaseNotes: Metadata: Localised release notes for this version
   - privacyUrl: Metadata: Localised privacy url
   - appleTvPrivacyPolicy: Metadata: Localised Apple TV privacy policy text
   - supportUrl: Metadata: Localised support url
   - marketingUrl: Metadata: Localised marketing url
   - languages: Metadata: List of languages to activate
   - ignoreLanguageDirectoryValidation: Ignore errors when invalid languages are found in metadata and screenshot directories
   - precheckIncludeInAppPurchases: Should precheck check in-app purchases?
   - app: The (spaceship) app ID of the app you want to use/modify

 Using _upload_to_app_store_ after _build_app_ and _capture_screenshots_ will automatically upload the latest ipa and screenshots with no other configuration.

 If you don't want to verify an HTML preview for App Store builds, use the `:force` option.
 This is useful when running _fastlane_ on your Continuous Integration server:
 `_upload_to_app_store_(force: true)`
 If your account is on multiple teams and you need to tell the `iTMSTransporter` which 'provider' to use, you can set the `:itc_provider` option to pass this info.
 */
public func appstore(apiKeyPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     apiKey: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                     username: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     appIdentifier: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     appVersion: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     ipa: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     pkg: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     buildNumber: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     platform: String = "ios",
                     editLive: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                     useLiveVersion: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                     metadataPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     screenshotsPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     skipBinaryUpload: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                     skipScreenshots: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                     skipMetadata: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                     skipAppVersionUpdate: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                     force: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                     overwriteScreenshots: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                     screenshotProcessingTimeout: Int = 3600,
                     syncScreenshots: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                     submitForReview: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                     verifyOnly: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                     rejectIfPossible: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                     versionCheckWaitRetryLimit: Int = 7,
                     automaticRelease: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                     autoReleaseDate: OptionalConfigValue<Int?> = .fastlaneDefault(nil),
                     phasedRelease: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                     resetRatings: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                     priceTier: OptionalConfigValue<Int?> = .fastlaneDefault(nil),
                     appRatingConfigPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     submissionInformation: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                     teamId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     teamName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     devPortalTeamId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     devPortalTeamName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     itcProvider: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     runPrecheckBeforeSubmit: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                     precheckDefaultRuleLevel: String = "warn",
                     individualMetadataItems: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                     appIcon: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     appleWatchAppIcon: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     copyright: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     primaryCategory: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     secondaryCategory: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     primaryFirstSubCategory: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     primarySecondSubCategory: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     secondaryFirstSubCategory: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     secondarySecondSubCategory: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     tradeRepresentativeContactInformation: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                     appReviewInformation: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                     appReviewAttachmentFile: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     description: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                     name: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                     subtitle: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                     keywords: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                     promotionalText: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                     releaseNotes: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                     privacyUrl: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                     appleTvPrivacyPolicy: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                     supportUrl: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                     marketingUrl: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                     languages: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                     ignoreLanguageDirectoryValidation: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                     precheckIncludeInAppPurchases: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                     app: OptionalConfigValue<Int?> = .fastlaneDefault(nil))
{
    let apiKeyPathArg = apiKeyPath.asRubyArgument(name: "api_key_path", type: nil)
    let apiKeyArg = apiKey.asRubyArgument(name: "api_key", type: nil)
    let usernameArg = username.asRubyArgument(name: "username", type: nil)
    let appIdentifierArg = appIdentifier.asRubyArgument(name: "app_identifier", type: nil)
    let appVersionArg = appVersion.asRubyArgument(name: "app_version", type: nil)
    let ipaArg = ipa.asRubyArgument(name: "ipa", type: nil)
    let pkgArg = pkg.asRubyArgument(name: "pkg", type: nil)
    let buildNumberArg = buildNumber.asRubyArgument(name: "build_number", type: nil)
    let platformArg = RubyCommand.Argument(name: "platform", value: platform, type: nil)
    let editLiveArg = editLive.asRubyArgument(name: "edit_live", type: nil)
    let useLiveVersionArg = useLiveVersion.asRubyArgument(name: "use_live_version", type: nil)
    let metadataPathArg = metadataPath.asRubyArgument(name: "metadata_path", type: nil)
    let screenshotsPathArg = screenshotsPath.asRubyArgument(name: "screenshots_path", type: nil)
    let skipBinaryUploadArg = skipBinaryUpload.asRubyArgument(name: "skip_binary_upload", type: nil)
    let skipScreenshotsArg = skipScreenshots.asRubyArgument(name: "skip_screenshots", type: nil)
    let skipMetadataArg = skipMetadata.asRubyArgument(name: "skip_metadata", type: nil)
    let skipAppVersionUpdateArg = skipAppVersionUpdate.asRubyArgument(name: "skip_app_version_update", type: nil)
    let forceArg = force.asRubyArgument(name: "force", type: nil)
    let overwriteScreenshotsArg = overwriteScreenshots.asRubyArgument(name: "overwrite_screenshots", type: nil)
    let screenshotProcessingTimeoutArg = RubyCommand.Argument(name: "screenshot_processing_timeout", value: screenshotProcessingTimeout, type: nil)
    let syncScreenshotsArg = syncScreenshots.asRubyArgument(name: "sync_screenshots", type: nil)
    let submitForReviewArg = submitForReview.asRubyArgument(name: "submit_for_review", type: nil)
    let verifyOnlyArg = verifyOnly.asRubyArgument(name: "verify_only", type: nil)
    let rejectIfPossibleArg = rejectIfPossible.asRubyArgument(name: "reject_if_possible", type: nil)
    let versionCheckWaitRetryLimitArg = RubyCommand.Argument(name: "version_check_wait_retry_limit", value: versionCheckWaitRetryLimit, type: nil)
    let automaticReleaseArg = automaticRelease.asRubyArgument(name: "automatic_release", type: nil)
    let autoReleaseDateArg = autoReleaseDate.asRubyArgument(name: "auto_release_date", type: nil)
    let phasedReleaseArg = phasedRelease.asRubyArgument(name: "phased_release", type: nil)
    let resetRatingsArg = resetRatings.asRubyArgument(name: "reset_ratings", type: nil)
    let priceTierArg = priceTier.asRubyArgument(name: "price_tier", type: nil)
    let appRatingConfigPathArg = appRatingConfigPath.asRubyArgument(name: "app_rating_config_path", type: nil)
    let submissionInformationArg = submissionInformation.asRubyArgument(name: "submission_information", type: nil)
    let teamIdArg = teamId.asRubyArgument(name: "team_id", type: nil)
    let teamNameArg = teamName.asRubyArgument(name: "team_name", type: nil)
    let devPortalTeamIdArg = devPortalTeamId.asRubyArgument(name: "dev_portal_team_id", type: nil)
    let devPortalTeamNameArg = devPortalTeamName.asRubyArgument(name: "dev_portal_team_name", type: nil)
    let itcProviderArg = itcProvider.asRubyArgument(name: "itc_provider", type: nil)
    let runPrecheckBeforeSubmitArg = runPrecheckBeforeSubmit.asRubyArgument(name: "run_precheck_before_submit", type: nil)
    let precheckDefaultRuleLevelArg = RubyCommand.Argument(name: "precheck_default_rule_level", value: precheckDefaultRuleLevel, type: nil)
    let individualMetadataItemsArg = individualMetadataItems.asRubyArgument(name: "individual_metadata_items", type: nil)
    let appIconArg = appIcon.asRubyArgument(name: "app_icon", type: nil)
    let appleWatchAppIconArg = appleWatchAppIcon.asRubyArgument(name: "apple_watch_app_icon", type: nil)
    let copyrightArg = copyright.asRubyArgument(name: "copyright", type: nil)
    let primaryCategoryArg = primaryCategory.asRubyArgument(name: "primary_category", type: nil)
    let secondaryCategoryArg = secondaryCategory.asRubyArgument(name: "secondary_category", type: nil)
    let primaryFirstSubCategoryArg = primaryFirstSubCategory.asRubyArgument(name: "primary_first_sub_category", type: nil)
    let primarySecondSubCategoryArg = primarySecondSubCategory.asRubyArgument(name: "primary_second_sub_category", type: nil)
    let secondaryFirstSubCategoryArg = secondaryFirstSubCategory.asRubyArgument(name: "secondary_first_sub_category", type: nil)
    let secondarySecondSubCategoryArg = secondarySecondSubCategory.asRubyArgument(name: "secondary_second_sub_category", type: nil)
    let tradeRepresentativeContactInformationArg = tradeRepresentativeContactInformation.asRubyArgument(name: "trade_representative_contact_information", type: nil)
    let appReviewInformationArg = appReviewInformation.asRubyArgument(name: "app_review_information", type: nil)
    let appReviewAttachmentFileArg = appReviewAttachmentFile.asRubyArgument(name: "app_review_attachment_file", type: nil)
    let descriptionArg = description.asRubyArgument(name: "description", type: nil)
    let nameArg = name.asRubyArgument(name: "name", type: nil)
    let subtitleArg = subtitle.asRubyArgument(name: "subtitle", type: nil)
    let keywordsArg = keywords.asRubyArgument(name: "keywords", type: nil)
    let promotionalTextArg = promotionalText.asRubyArgument(name: "promotional_text", type: nil)
    let releaseNotesArg = releaseNotes.asRubyArgument(name: "release_notes", type: nil)
    let privacyUrlArg = privacyUrl.asRubyArgument(name: "privacy_url", type: nil)
    let appleTvPrivacyPolicyArg = appleTvPrivacyPolicy.asRubyArgument(name: "apple_tv_privacy_policy", type: nil)
    let supportUrlArg = supportUrl.asRubyArgument(name: "support_url", type: nil)
    let marketingUrlArg = marketingUrl.asRubyArgument(name: "marketing_url", type: nil)
    let languagesArg = languages.asRubyArgument(name: "languages", type: nil)
    let ignoreLanguageDirectoryValidationArg = ignoreLanguageDirectoryValidation.asRubyArgument(name: "ignore_language_directory_validation", type: nil)
    let precheckIncludeInAppPurchasesArg = precheckIncludeInAppPurchases.asRubyArgument(name: "precheck_include_in_app_purchases", type: nil)
    let appArg = app.asRubyArgument(name: "app", type: nil)
    let array: [RubyCommand.Argument?] = [apiKeyPathArg,
                                          apiKeyArg,
                                          usernameArg,
                                          appIdentifierArg,
                                          appVersionArg,
                                          ipaArg,
                                          pkgArg,
                                          buildNumberArg,
                                          platformArg,
                                          editLiveArg,
                                          useLiveVersionArg,
                                          metadataPathArg,
                                          screenshotsPathArg,
                                          skipBinaryUploadArg,
                                          skipScreenshotsArg,
                                          skipMetadataArg,
                                          skipAppVersionUpdateArg,
                                          forceArg,
                                          overwriteScreenshotsArg,
                                          screenshotProcessingTimeoutArg,
                                          syncScreenshotsArg,
                                          submitForReviewArg,
                                          verifyOnlyArg,
                                          rejectIfPossibleArg,
                                          versionCheckWaitRetryLimitArg,
                                          automaticReleaseArg,
                                          autoReleaseDateArg,
                                          phasedReleaseArg,
                                          resetRatingsArg,
                                          priceTierArg,
                                          appRatingConfigPathArg,
                                          submissionInformationArg,
                                          teamIdArg,
                                          teamNameArg,
                                          devPortalTeamIdArg,
                                          devPortalTeamNameArg,
                                          itcProviderArg,
                                          runPrecheckBeforeSubmitArg,
                                          precheckDefaultRuleLevelArg,
                                          individualMetadataItemsArg,
                                          appIconArg,
                                          appleWatchAppIconArg,
                                          copyrightArg,
                                          primaryCategoryArg,
                                          secondaryCategoryArg,
                                          primaryFirstSubCategoryArg,
                                          primarySecondSubCategoryArg,
                                          secondaryFirstSubCategoryArg,
                                          secondarySecondSubCategoryArg,
                                          tradeRepresentativeContactInformationArg,
                                          appReviewInformationArg,
                                          appReviewAttachmentFileArg,
                                          descriptionArg,
                                          nameArg,
                                          subtitleArg,
                                          keywordsArg,
                                          promotionalTextArg,
                                          releaseNotesArg,
                                          privacyUrlArg,
                                          appleTvPrivacyPolicyArg,
                                          supportUrlArg,
                                          marketingUrlArg,
                                          languagesArg,
                                          ignoreLanguageDirectoryValidationArg,
                                          precheckIncludeInAppPurchasesArg,
                                          appArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "appstore", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Upload dSYM file to [Apteligent (Crittercism)](http://www.apteligent.com/)

 - parameters:
   - dsym: dSYM.zip file to upload to Apteligent
   - appId: Apteligent App ID key e.g. 569f5c87cb99e10e00c7xxxx
   - apiKey: Apteligent App API key e.g. IXPQIi8yCbHaLliqzRoo065tH0lxxxxx
 */
public func apteligent(dsym: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                       appId: String,
                       apiKey: String)
{
    let dsymArg = dsym.asRubyArgument(name: "dsym", type: nil)
    let appIdArg = RubyCommand.Argument(name: "app_id", value: appId, type: nil)
    let apiKeyArg = RubyCommand.Argument(name: "api_key", value: apiKey, type: nil)
    let array: [RubyCommand.Argument?] = [dsymArg,
                                          appIdArg,
                                          apiKeyArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "apteligent", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 This action uploads an artifact to artifactory

 - parameters:
   - file: File to be uploaded to artifactory
   - repo: Artifactory repo to put the file in
   - repoPath: Path to deploy within the repo, including filename
   - endpoint: Artifactory endpoint
   - username: Artifactory username
   - password: Artifactory password
   - apiKey: Artifactory API key
   - properties: Artifact properties hash
   - sslPemFile: Location of pem file to use for ssl verification
   - sslVerify: Verify SSL
   - proxyUsername: Proxy username
   - proxyPassword: Proxy password
   - proxyAddress: Proxy address
   - proxyPort: Proxy port
   - readTimeout: Read timeout

 Connect to the artifactory server using either a username/password or an api_key
 */
public func artifactory(file: String,
                        repo: String,
                        repoPath: String,
                        endpoint: String,
                        username: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                        password: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                        apiKey: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                        properties: [String: Any] = [:],
                        sslPemFile: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                        sslVerify: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                        proxyUsername: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                        proxyPassword: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                        proxyAddress: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                        proxyPort: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                        readTimeout: OptionalConfigValue<String?> = .fastlaneDefault(nil))
{
    let fileArg = RubyCommand.Argument(name: "file", value: file, type: nil)
    let repoArg = RubyCommand.Argument(name: "repo", value: repo, type: nil)
    let repoPathArg = RubyCommand.Argument(name: "repo_path", value: repoPath, type: nil)
    let endpointArg = RubyCommand.Argument(name: "endpoint", value: endpoint, type: nil)
    let usernameArg = username.asRubyArgument(name: "username", type: nil)
    let passwordArg = password.asRubyArgument(name: "password", type: nil)
    let apiKeyArg = apiKey.asRubyArgument(name: "api_key", type: nil)
    let propertiesArg = RubyCommand.Argument(name: "properties", value: properties, type: nil)
    let sslPemFileArg = sslPemFile.asRubyArgument(name: "ssl_pem_file", type: nil)
    let sslVerifyArg = sslVerify.asRubyArgument(name: "ssl_verify", type: nil)
    let proxyUsernameArg = proxyUsername.asRubyArgument(name: "proxy_username", type: nil)
    let proxyPasswordArg = proxyPassword.asRubyArgument(name: "proxy_password", type: nil)
    let proxyAddressArg = proxyAddress.asRubyArgument(name: "proxy_address", type: nil)
    let proxyPortArg = proxyPort.asRubyArgument(name: "proxy_port", type: nil)
    let readTimeoutArg = readTimeout.asRubyArgument(name: "read_timeout", type: nil)
    let array: [RubyCommand.Argument?] = [fileArg,
                                          repoArg,
                                          repoPathArg,
                                          endpointArg,
                                          usernameArg,
                                          passwordArg,
                                          apiKeyArg,
                                          propertiesArg,
                                          sslPemFileArg,
                                          sslVerifyArg,
                                          proxyUsernameArg,
                                          proxyPasswordArg,
                                          proxyAddressArg,
                                          proxyPortArg,
                                          readTimeoutArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "artifactory", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Configures Xcode's Codesigning options

 - parameters:
   - path: Path to your Xcode project
   - useAutomaticSigning: Defines if project should use automatic signing
   - teamId: Team ID, is used when upgrading project
   - targets: Specify targets you want to toggle the signing mech. (default to all targets)
   - codeSignIdentity: Code signing identity type (iPhone Developer, iPhone Distribution)
   - profileName: Provisioning profile name to use for code signing
   - profileUuid: Provisioning profile UUID to use for code signing
   - bundleIdentifier: Application Product Bundle Identifier

 - returns: The current status (boolean) of codesigning after modification

 Configures Xcode's Codesigning options of all targets in the project
 */
public func automaticCodeSigning(path: String,
                                 useAutomaticSigning: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                 teamId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                 targets: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                                 codeSignIdentity: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                 profileName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                 profileUuid: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                 bundleIdentifier: OptionalConfigValue<String?> = .fastlaneDefault(nil))
{
    let pathArg = RubyCommand.Argument(name: "path", value: path, type: nil)
    let useAutomaticSigningArg = useAutomaticSigning.asRubyArgument(name: "use_automatic_signing", type: nil)
    let teamIdArg = teamId.asRubyArgument(name: "team_id", type: nil)
    let targetsArg = targets.asRubyArgument(name: "targets", type: nil)
    let codeSignIdentityArg = codeSignIdentity.asRubyArgument(name: "code_sign_identity", type: nil)
    let profileNameArg = profileName.asRubyArgument(name: "profile_name", type: nil)
    let profileUuidArg = profileUuid.asRubyArgument(name: "profile_uuid", type: nil)
    let bundleIdentifierArg = bundleIdentifier.asRubyArgument(name: "bundle_identifier", type: nil)
    let array: [RubyCommand.Argument?] = [pathArg,
                                          useAutomaticSigningArg,
                                          teamIdArg,
                                          targetsArg,
                                          codeSignIdentityArg,
                                          profileNameArg,
                                          profileUuidArg,
                                          bundleIdentifierArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "automatic_code_signing", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 This action backs up your file to "[path].back"

 - parameter path: Path to the file you want to backup
 */
public func backupFile(path: String) {
    let pathArg = RubyCommand.Argument(name: "path", value: path, type: nil)
    let array: [RubyCommand.Argument?] = [pathArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "backup_file", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Save your [zipped] xcarchive elsewhere from default path

 - parameters:
   - xcarchive: Path to your xcarchive file. Optional if you use the `xcodebuild` action
   - destination: Where your archive will be placed
   - zip: Enable compression of the archive
   - zipFilename: Filename of the compressed archive. Will be appended by `.xcarchive.zip`. Default value is the output xcarchive filename
   - versioned: Create a versioned (date and app version) subfolder where to put the archive
 */
public func backupXcarchive(xcarchive: String,
                            destination: String,
                            zip: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                            zipFilename: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            versioned: OptionalConfigValue<Bool> = .fastlaneDefault(true))
{
    let xcarchiveArg = RubyCommand.Argument(name: "xcarchive", value: xcarchive, type: nil)
    let destinationArg = RubyCommand.Argument(name: "destination", value: destination, type: nil)
    let zipArg = zip.asRubyArgument(name: "zip", type: nil)
    let zipFilenameArg = zipFilename.asRubyArgument(name: "zip_filename", type: nil)
    let versionedArg = versioned.asRubyArgument(name: "versioned", type: nil)
    let array: [RubyCommand.Argument?] = [xcarchiveArg,
                                          destinationArg,
                                          zipArg,
                                          zipFilenameArg,
                                          versionedArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "backup_xcarchive", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Automatically add a badge to your app icon

 - parameters:
   - dark: Adds a dark flavored badge on top of your icon
   - custom: Add your custom overlay/badge image
   - noBadge: Hides the beta badge
   - shield: Add a shield to your app icon from shields.io
   - alpha: Adds and alpha badge instead of the default beta one
   - path: Sets the root path to look for AppIcons
   - shieldIoTimeout: Set custom duration for the timeout of the shields.io request in seconds
   - glob: Glob pattern for finding image files
   - alphaChannel: Keeps/adds an alpha channel to the icon (useful for android icons)
   - shieldGravity: Position of shield on icon. Default: North - Choices include: NorthWest, North, NorthEast, West, Center, East, SouthWest, South, SouthEast
   - shieldNoResize: Shield image will no longer be resized to aspect fill the full icon. Instead it will only be shrunk to not exceed the icon graphic

 Please use the [badge plugin](https://github.com/HazAT/fastlane-plugin-badge) instead.
 This action will add a light/dark badge onto your app icon.
 You can also provide your custom badge/overlay or add a shield for more customization.
 More info: [https://github.com/HazAT/badge](https://github.com/HazAT/badge)
 **Note**: If you want to reset the badge back to default, you can use `sh 'git checkout -- <path>/Assets.xcassets/'`.
 */
public func badge(dark: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                  custom: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  noBadge: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                  shield: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  alpha: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                  path: String = ".",
                  shieldIoTimeout: OptionalConfigValue<Int?> = .fastlaneDefault(nil),
                  glob: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  alphaChannel: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                  shieldGravity: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  shieldNoResize: OptionalConfigValue<Bool?> = .fastlaneDefault(nil))
{
    let darkArg = dark.asRubyArgument(name: "dark", type: nil)
    let customArg = custom.asRubyArgument(name: "custom", type: nil)
    let noBadgeArg = noBadge.asRubyArgument(name: "no_badge", type: nil)
    let shieldArg = shield.asRubyArgument(name: "shield", type: nil)
    let alphaArg = alpha.asRubyArgument(name: "alpha", type: nil)
    let pathArg = RubyCommand.Argument(name: "path", value: path, type: nil)
    let shieldIoTimeoutArg = shieldIoTimeout.asRubyArgument(name: "shield_io_timeout", type: nil)
    let globArg = glob.asRubyArgument(name: "glob", type: nil)
    let alphaChannelArg = alphaChannel.asRubyArgument(name: "alpha_channel", type: nil)
    let shieldGravityArg = shieldGravity.asRubyArgument(name: "shield_gravity", type: nil)
    let shieldNoResizeArg = shieldNoResize.asRubyArgument(name: "shield_no_resize", type: nil)
    let array: [RubyCommand.Argument?] = [darkArg,
                                          customArg,
                                          noBadgeArg,
                                          shieldArg,
                                          alphaArg,
                                          pathArg,
                                          shieldIoTimeoutArg,
                                          globArg,
                                          alphaChannelArg,
                                          shieldGravityArg,
                                          shieldNoResizeArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "badge", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Generate and upload an ipa file to appetize.io

 - parameters:
   - xcodebuild: Parameters that are passed to the xcodebuild action
   - scheme: The scheme to build. Can also be passed using the `xcodebuild` parameter
   - apiToken: Appetize.io API Token
   - publicKey: If not provided, a new app will be created. If provided, the existing build will be overwritten
   - note: Notes you wish to add to the uploaded app
   - timeout: The number of seconds to wait until automatically ending the session due to user inactivity. Must be 30, 60, 90, 120, 180, 300, 600, 1800, 3600 or 7200. Default is 120

 This should be called from danger.
 More information in the [device_grid guide](https://github.com/fastlane/fastlane/blob/master/fastlane/lib/fastlane/actions/device_grid/README.md).
 */
public func buildAndUploadToAppetize(xcodebuild: [String: Any] = [:],
                                     scheme: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                     apiToken: String,
                                     publicKey: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                     note: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                     timeout: OptionalConfigValue<Int?> = .fastlaneDefault(nil))
{
    let xcodebuildArg = RubyCommand.Argument(name: "xcodebuild", value: xcodebuild, type: nil)
    let schemeArg = scheme.asRubyArgument(name: "scheme", type: nil)
    let apiTokenArg = RubyCommand.Argument(name: "api_token", value: apiToken, type: nil)
    let publicKeyArg = publicKey.asRubyArgument(name: "public_key", type: nil)
    let noteArg = note.asRubyArgument(name: "note", type: nil)
    let timeoutArg = timeout.asRubyArgument(name: "timeout", type: nil)
    let array: [RubyCommand.Argument?] = [xcodebuildArg,
                                          schemeArg,
                                          apiTokenArg,
                                          publicKeyArg,
                                          noteArg,
                                          timeoutArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "build_and_upload_to_appetize", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Alias for the `gradle` action

 - parameters:
   - task: The gradle task you want to execute, e.g. `assemble`, `bundle` or `test`. For tasks such as `assembleMyFlavorRelease` you should use gradle(task: 'assemble', flavor: 'Myflavor', build_type: 'Release')
   - flavor: The flavor that you want the task for, e.g. `MyFlavor`. If you are running the `assemble` task in a multi-flavor project, and you rely on Actions.lane_context[SharedValues::GRADLE_APK_OUTPUT_PATH] then you must specify a flavor here or else this value will be undefined
   - buildType: The build type that you want the task for, e.g. `Release`. Useful for some tasks such as `assemble`
   - tasks: The multiple gradle tasks that you want to execute, e.g. `[assembleDebug, bundleDebug]`
   - flags: All parameter flags you want to pass to the gradle command, e.g. `--exitcode --xml file.xml`
   - projectDir: The root directory of the gradle project
   - gradlePath: The path to your `gradlew`. If you specify a relative path, it is assumed to be relative to the `project_dir`
   - properties: Gradle properties to be exposed to the gradle script
   - systemProperties: Gradle system properties to be exposed to the gradle script
   - serial: Android serial, which device should be used for this command
   - printCommand: Control whether the generated Gradle command is printed as output before running it (true/false)
   - printCommandOutput: Control whether the output produced by given Gradle command is printed while running (true/false)

 - returns: The output of running the gradle task

 Run `./gradlew tasks` to get a list of all available gradle tasks for your project
 */
public func buildAndroidApp(task: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            flavor: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            buildType: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            tasks: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                            flags: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            projectDir: String = ".",
                            gradlePath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            properties: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                            systemProperties: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                            serial: String = "",
                            printCommand: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                            printCommandOutput: OptionalConfigValue<Bool> = .fastlaneDefault(true))
{
    let taskArg = task.asRubyArgument(name: "task", type: nil)
    let flavorArg = flavor.asRubyArgument(name: "flavor", type: nil)
    let buildTypeArg = buildType.asRubyArgument(name: "build_type", type: nil)
    let tasksArg = tasks.asRubyArgument(name: "tasks", type: nil)
    let flagsArg = flags.asRubyArgument(name: "flags", type: nil)
    let projectDirArg = RubyCommand.Argument(name: "project_dir", value: projectDir, type: nil)
    let gradlePathArg = gradlePath.asRubyArgument(name: "gradle_path", type: nil)
    let propertiesArg = properties.asRubyArgument(name: "properties", type: nil)
    let systemPropertiesArg = systemProperties.asRubyArgument(name: "system_properties", type: nil)
    let serialArg = RubyCommand.Argument(name: "serial", value: serial, type: nil)
    let printCommandArg = printCommand.asRubyArgument(name: "print_command", type: nil)
    let printCommandOutputArg = printCommandOutput.asRubyArgument(name: "print_command_output", type: nil)
    let array: [RubyCommand.Argument?] = [taskArg,
                                          flavorArg,
                                          buildTypeArg,
                                          tasksArg,
                                          flagsArg,
                                          projectDirArg,
                                          gradlePathArg,
                                          propertiesArg,
                                          systemPropertiesArg,
                                          serialArg,
                                          printCommandArg,
                                          printCommandOutputArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "build_android_app", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Easily build and sign your app (via _gym_)

 - parameters:
   - workspace: Path to the workspace file
   - project: Path to the project file
   - scheme: The project's scheme. Make sure it's marked as `Shared`
   - clean: Should the project be cleaned before building it?
   - outputDirectory: The directory in which the ipa file should be stored in
   - outputName: The name of the resulting ipa file
   - configuration: The configuration to use when building the app. Defaults to 'Release'
   - silent: Hide all information that's not necessary while building
   - codesigningIdentity: The name of the code signing identity to use. It has to match the name exactly. e.g. 'iPhone Distribution: SunApps GmbH'
   - skipPackageIpa: Should we skip packaging the ipa?
   - skipPackagePkg: Should we skip packaging the pkg?
   - includeSymbols: Should the ipa file include symbols?
   - includeBitcode: Should the ipa file include bitcode?
   - exportMethod: Method used to export the archive. Valid values are: app-store, validation, ad-hoc, package, enterprise, development, developer-id and mac-application
   - exportOptions: Path to an export options plist or a hash with export options. Use 'xcodebuild -help' to print the full set of available options
   - exportXcargs: Pass additional arguments to xcodebuild for the package phase. Be sure to quote the setting names and values e.g. OTHER_LDFLAGS="-ObjC -lstdc++"
   - skipBuildArchive: Export ipa from previously built xcarchive. Uses archive_path as source
   - skipArchive: After building, don't archive, effectively not including -archivePath param
   - skipCodesigning: Build without codesigning
   - catalystPlatform: Platform to build when using a Catalyst enabled app. Valid values are: ios, macos
   - installerCertName: Full name of 3rd Party Mac Developer Installer or Developer ID Installer certificate. Example: `3rd Party Mac Developer Installer: Your Company (ABC1234XWYZ)`
   - buildPath: The directory in which the archive should be stored in
   - archivePath: The path to the created archive
   - derivedDataPath: The directory where built products and other derived data will go
   - resultBundle: Should an Xcode result bundle be generated in the output directory
   - resultBundlePath: Path to the result bundle directory to create. Ignored if `result_bundle` if false
   - buildlogPath: The directory where to store the build log
   - sdk: The SDK that should be used for building the application
   - toolchain: The toolchain that should be used for building the application (e.g. com.apple.dt.toolchain.Swift_2_3, org.swift.30p620160816a)
   - destination: Use a custom destination for building the app
   - exportTeamId: Optional: Sometimes you need to specify a team id when exporting the ipa file
   - xcargs: Pass additional arguments to xcodebuild for the build phase. Be sure to quote the setting names and values e.g. OTHER_LDFLAGS="-ObjC -lstdc++"
   - xcconfig: Use an extra XCCONFIG file to build your app
   - suppressXcodeOutput: Suppress the output of xcodebuild to stdout. Output is still saved in buildlog_path
   - xcodebuildFormatter: xcodebuild formatter to use (ex: 'xcbeautify', 'xcbeautify --quieter', 'xcpretty', 'xcpretty -test'). Use empty string (ex: '') to disable any formatter (More information: https://docs.fastlane.tools/best-practices/xcodebuild-formatters/)
   - buildTimingSummary: Create a build timing summary
   - disableXcpretty: **DEPRECATED!** Use `xcodebuild_formatter: ''` instead - Disable xcpretty formatting of build output
   - xcprettyTestFormat: Use the test (RSpec style) format for build output
   - xcprettyFormatter: A custom xcpretty formatter to use
   - xcprettyReportJunit: Have xcpretty create a JUnit-style XML report at the provided path
   - xcprettyReportHtml: Have xcpretty create a simple HTML report at the provided path
   - xcprettyReportJson: Have xcpretty create a JSON compilation database at the provided path
   - xcprettyUtf: Have xcpretty use unicode encoding when reporting builds
   - analyzeBuildTime: Analyze the project build time and store the output in 'culprits.txt' file
   - skipProfileDetection: Do not try to build a profile mapping from the xcodeproj. Match or a manually provided mapping should be used
   - xcodebuildCommand: Allows for override of the default `xcodebuild` command
   - clonedSourcePackagesPath: Sets a custom path for Swift Package Manager dependencies
   - skipPackageDependenciesResolution: Skips resolution of Swift Package Manager dependencies
   - disablePackageAutomaticUpdates: Prevents packages from automatically being resolved to versions other than those recorded in the `Package.resolved` file
   - useSystemScm: Lets xcodebuild use system's scm configuration
   - packageAuthorizationProvider: Lets xcodebuild use a specified package authorization provider (keychain|netrc)

 - returns: The absolute path to the generated ipa file

 More information: https://fastlane.tools/gym
 */
@discardableResult public func buildApp(workspace: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        project: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        scheme: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        clean: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                        outputDirectory: String = ".",
                                        outputName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        configuration: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        silent: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                        codesigningIdentity: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        skipPackageIpa: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                        skipPackagePkg: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                        includeSymbols: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                        includeBitcode: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                        exportMethod: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        exportOptions: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                                        exportXcargs: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        skipBuildArchive: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                        skipArchive: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                        skipCodesigning: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                        catalystPlatform: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        installerCertName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        buildPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        archivePath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        derivedDataPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        resultBundle: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                        resultBundlePath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        buildlogPath: String = "~/Library/Logs/gym",
                                        sdk: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        toolchain: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        destination: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        exportTeamId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        xcargs: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        xcconfig: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        suppressXcodeOutput: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                        xcodebuildFormatter: String = "xcbeautify",
                                        buildTimingSummary: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                        disableXcpretty: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                        xcprettyTestFormat: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                        xcprettyFormatter: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        xcprettyReportJunit: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        xcprettyReportHtml: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        xcprettyReportJson: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        xcprettyUtf: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                        analyzeBuildTime: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                        skipProfileDetection: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                        xcodebuildCommand: String = "xcodebuild",
                                        clonedSourcePackagesPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        skipPackageDependenciesResolution: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                        disablePackageAutomaticUpdates: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                        useSystemScm: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                        packageAuthorizationProvider: OptionalConfigValue<String?> = .fastlaneDefault(nil)) -> String
{
    let workspaceArg = workspace.asRubyArgument(name: "workspace", type: nil)
    let projectArg = project.asRubyArgument(name: "project", type: nil)
    let schemeArg = scheme.asRubyArgument(name: "scheme", type: nil)
    let cleanArg = clean.asRubyArgument(name: "clean", type: nil)
    let outputDirectoryArg = RubyCommand.Argument(name: "output_directory", value: outputDirectory, type: nil)
    let outputNameArg = outputName.asRubyArgument(name: "output_name", type: nil)
    let configurationArg = configuration.asRubyArgument(name: "configuration", type: nil)
    let silentArg = silent.asRubyArgument(name: "silent", type: nil)
    let codesigningIdentityArg = codesigningIdentity.asRubyArgument(name: "codesigning_identity", type: nil)
    let skipPackageIpaArg = skipPackageIpa.asRubyArgument(name: "skip_package_ipa", type: nil)
    let skipPackagePkgArg = skipPackagePkg.asRubyArgument(name: "skip_package_pkg", type: nil)
    let includeSymbolsArg = includeSymbols.asRubyArgument(name: "include_symbols", type: nil)
    let includeBitcodeArg = includeBitcode.asRubyArgument(name: "include_bitcode", type: nil)
    let exportMethodArg = exportMethod.asRubyArgument(name: "export_method", type: nil)
    let exportOptionsArg = exportOptions.asRubyArgument(name: "export_options", type: nil)
    let exportXcargsArg = exportXcargs.asRubyArgument(name: "export_xcargs", type: nil)
    let skipBuildArchiveArg = skipBuildArchive.asRubyArgument(name: "skip_build_archive", type: nil)
    let skipArchiveArg = skipArchive.asRubyArgument(name: "skip_archive", type: nil)
    let skipCodesigningArg = skipCodesigning.asRubyArgument(name: "skip_codesigning", type: nil)
    let catalystPlatformArg = catalystPlatform.asRubyArgument(name: "catalyst_platform", type: nil)
    let installerCertNameArg = installerCertName.asRubyArgument(name: "installer_cert_name", type: nil)
    let buildPathArg = buildPath.asRubyArgument(name: "build_path", type: nil)
    let archivePathArg = archivePath.asRubyArgument(name: "archive_path", type: nil)
    let derivedDataPathArg = derivedDataPath.asRubyArgument(name: "derived_data_path", type: nil)
    let resultBundleArg = resultBundle.asRubyArgument(name: "result_bundle", type: nil)
    let resultBundlePathArg = resultBundlePath.asRubyArgument(name: "result_bundle_path", type: nil)
    let buildlogPathArg = RubyCommand.Argument(name: "buildlog_path", value: buildlogPath, type: nil)
    let sdkArg = sdk.asRubyArgument(name: "sdk", type: nil)
    let toolchainArg = toolchain.asRubyArgument(name: "toolchain", type: nil)
    let destinationArg = destination.asRubyArgument(name: "destination", type: nil)
    let exportTeamIdArg = exportTeamId.asRubyArgument(name: "export_team_id", type: nil)
    let xcargsArg = xcargs.asRubyArgument(name: "xcargs", type: nil)
    let xcconfigArg = xcconfig.asRubyArgument(name: "xcconfig", type: nil)
    let suppressXcodeOutputArg = suppressXcodeOutput.asRubyArgument(name: "suppress_xcode_output", type: nil)
    let xcodebuildFormatterArg = RubyCommand.Argument(name: "xcodebuild_formatter", value: xcodebuildFormatter, type: nil)
    let buildTimingSummaryArg = buildTimingSummary.asRubyArgument(name: "build_timing_summary", type: nil)
    let disableXcprettyArg = disableXcpretty.asRubyArgument(name: "disable_xcpretty", type: nil)
    let xcprettyTestFormatArg = xcprettyTestFormat.asRubyArgument(name: "xcpretty_test_format", type: nil)
    let xcprettyFormatterArg = xcprettyFormatter.asRubyArgument(name: "xcpretty_formatter", type: nil)
    let xcprettyReportJunitArg = xcprettyReportJunit.asRubyArgument(name: "xcpretty_report_junit", type: nil)
    let xcprettyReportHtmlArg = xcprettyReportHtml.asRubyArgument(name: "xcpretty_report_html", type: nil)
    let xcprettyReportJsonArg = xcprettyReportJson.asRubyArgument(name: "xcpretty_report_json", type: nil)
    let xcprettyUtfArg = xcprettyUtf.asRubyArgument(name: "xcpretty_utf", type: nil)
    let analyzeBuildTimeArg = analyzeBuildTime.asRubyArgument(name: "analyze_build_time", type: nil)
    let skipProfileDetectionArg = skipProfileDetection.asRubyArgument(name: "skip_profile_detection", type: nil)
    let xcodebuildCommandArg = RubyCommand.Argument(name: "xcodebuild_command", value: xcodebuildCommand, type: nil)
    let clonedSourcePackagesPathArg = clonedSourcePackagesPath.asRubyArgument(name: "cloned_source_packages_path", type: nil)
    let skipPackageDependenciesResolutionArg = skipPackageDependenciesResolution.asRubyArgument(name: "skip_package_dependencies_resolution", type: nil)
    let disablePackageAutomaticUpdatesArg = disablePackageAutomaticUpdates.asRubyArgument(name: "disable_package_automatic_updates", type: nil)
    let useSystemScmArg = useSystemScm.asRubyArgument(name: "use_system_scm", type: nil)
    let packageAuthorizationProviderArg = packageAuthorizationProvider.asRubyArgument(name: "package_authorization_provider", type: nil)
    let array: [RubyCommand.Argument?] = [workspaceArg,
                                          projectArg,
                                          schemeArg,
                                          cleanArg,
                                          outputDirectoryArg,
                                          outputNameArg,
                                          configurationArg,
                                          silentArg,
                                          codesigningIdentityArg,
                                          skipPackageIpaArg,
                                          skipPackagePkgArg,
                                          includeSymbolsArg,
                                          includeBitcodeArg,
                                          exportMethodArg,
                                          exportOptionsArg,
                                          exportXcargsArg,
                                          skipBuildArchiveArg,
                                          skipArchiveArg,
                                          skipCodesigningArg,
                                          catalystPlatformArg,
                                          installerCertNameArg,
                                          buildPathArg,
                                          archivePathArg,
                                          derivedDataPathArg,
                                          resultBundleArg,
                                          resultBundlePathArg,
                                          buildlogPathArg,
                                          sdkArg,
                                          toolchainArg,
                                          destinationArg,
                                          exportTeamIdArg,
                                          xcargsArg,
                                          xcconfigArg,
                                          suppressXcodeOutputArg,
                                          xcodebuildFormatterArg,
                                          buildTimingSummaryArg,
                                          disableXcprettyArg,
                                          xcprettyTestFormatArg,
                                          xcprettyFormatterArg,
                                          xcprettyReportJunitArg,
                                          xcprettyReportHtmlArg,
                                          xcprettyReportJsonArg,
                                          xcprettyUtfArg,
                                          analyzeBuildTimeArg,
                                          skipProfileDetectionArg,
                                          xcodebuildCommandArg,
                                          clonedSourcePackagesPathArg,
                                          skipPackageDependenciesResolutionArg,
                                          disablePackageAutomaticUpdatesArg,
                                          useSystemScmArg,
                                          packageAuthorizationProviderArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "build_app", className: nil, args: args)
    return runner.executeCommand(command)
}

/**
 Alias for the `build_app` action but only for iOS

 - parameters:
   - workspace: Path to the workspace file
   - project: Path to the project file
   - scheme: The project's scheme. Make sure it's marked as `Shared`
   - clean: Should the project be cleaned before building it?
   - outputDirectory: The directory in which the ipa file should be stored in
   - outputName: The name of the resulting ipa file
   - configuration: The configuration to use when building the app. Defaults to 'Release'
   - silent: Hide all information that's not necessary while building
   - codesigningIdentity: The name of the code signing identity to use. It has to match the name exactly. e.g. 'iPhone Distribution: SunApps GmbH'
   - skipPackageIpa: Should we skip packaging the ipa?
   - includeSymbols: Should the ipa file include symbols?
   - includeBitcode: Should the ipa file include bitcode?
   - exportMethod: Method used to export the archive. Valid values are: app-store, validation, ad-hoc, package, enterprise, development, developer-id and mac-application
   - exportOptions: Path to an export options plist or a hash with export options. Use 'xcodebuild -help' to print the full set of available options
   - exportXcargs: Pass additional arguments to xcodebuild for the package phase. Be sure to quote the setting names and values e.g. OTHER_LDFLAGS="-ObjC -lstdc++"
   - skipBuildArchive: Export ipa from previously built xcarchive. Uses archive_path as source
   - skipArchive: After building, don't archive, effectively not including -archivePath param
   - skipCodesigning: Build without codesigning
   - buildPath: The directory in which the archive should be stored in
   - archivePath: The path to the created archive
   - derivedDataPath: The directory where built products and other derived data will go
   - resultBundle: Should an Xcode result bundle be generated in the output directory
   - resultBundlePath: Path to the result bundle directory to create. Ignored if `result_bundle` if false
   - buildlogPath: The directory where to store the build log
   - sdk: The SDK that should be used for building the application
   - toolchain: The toolchain that should be used for building the application (e.g. com.apple.dt.toolchain.Swift_2_3, org.swift.30p620160816a)
   - destination: Use a custom destination for building the app
   - exportTeamId: Optional: Sometimes you need to specify a team id when exporting the ipa file
   - xcargs: Pass additional arguments to xcodebuild for the build phase. Be sure to quote the setting names and values e.g. OTHER_LDFLAGS="-ObjC -lstdc++"
   - xcconfig: Use an extra XCCONFIG file to build your app
   - suppressXcodeOutput: Suppress the output of xcodebuild to stdout. Output is still saved in buildlog_path
   - xcodebuildFormatter: xcodebuild formatter to use (ex: 'xcbeautify', 'xcbeautify --quieter', 'xcpretty', 'xcpretty -test'). Use empty string (ex: '') to disable any formatter (More information: https://docs.fastlane.tools/best-practices/xcodebuild-formatters/)
   - buildTimingSummary: Create a build timing summary
   - disableXcpretty: **DEPRECATED!** Use `xcodebuild_formatter: ''` instead - Disable xcpretty formatting of build output
   - xcprettyTestFormat: Use the test (RSpec style) format for build output
   - xcprettyFormatter: A custom xcpretty formatter to use
   - xcprettyReportJunit: Have xcpretty create a JUnit-style XML report at the provided path
   - xcprettyReportHtml: Have xcpretty create a simple HTML report at the provided path
   - xcprettyReportJson: Have xcpretty create a JSON compilation database at the provided path
   - xcprettyUtf: Have xcpretty use unicode encoding when reporting builds
   - analyzeBuildTime: Analyze the project build time and store the output in 'culprits.txt' file
   - skipProfileDetection: Do not try to build a profile mapping from the xcodeproj. Match or a manually provided mapping should be used
   - xcodebuildCommand: Allows for override of the default `xcodebuild` command
   - clonedSourcePackagesPath: Sets a custom path for Swift Package Manager dependencies
   - skipPackageDependenciesResolution: Skips resolution of Swift Package Manager dependencies
   - disablePackageAutomaticUpdates: Prevents packages from automatically being resolved to versions other than those recorded in the `Package.resolved` file
   - useSystemScm: Lets xcodebuild use system's scm configuration
   - packageAuthorizationProvider: Lets xcodebuild use a specified package authorization provider (keychain|netrc)

 - returns: The absolute path to the generated ipa file

 More information: https://fastlane.tools/gym
 */
@discardableResult public func buildIosApp(workspace: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           project: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           scheme: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           clean: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                           outputDirectory: String = ".",
                                           outputName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           configuration: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           silent: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                           codesigningIdentity: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           skipPackageIpa: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                           includeSymbols: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                           includeBitcode: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                           exportMethod: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           exportOptions: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                                           exportXcargs: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           skipBuildArchive: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                           skipArchive: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                           skipCodesigning: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                           buildPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           archivePath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           derivedDataPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           resultBundle: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                           resultBundlePath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           buildlogPath: String = "~/Library/Logs/gym",
                                           sdk: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           toolchain: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           destination: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           exportTeamId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           xcargs: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           xcconfig: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           suppressXcodeOutput: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                           xcodebuildFormatter: String = "xcbeautify",
                                           buildTimingSummary: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                           disableXcpretty: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                           xcprettyTestFormat: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                           xcprettyFormatter: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           xcprettyReportJunit: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           xcprettyReportHtml: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           xcprettyReportJson: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           xcprettyUtf: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                           analyzeBuildTime: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                           skipProfileDetection: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                           xcodebuildCommand: String = "xcodebuild",
                                           clonedSourcePackagesPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           skipPackageDependenciesResolution: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                           disablePackageAutomaticUpdates: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                           useSystemScm: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                           packageAuthorizationProvider: OptionalConfigValue<String?> = .fastlaneDefault(nil)) -> String
{
    let workspaceArg = workspace.asRubyArgument(name: "workspace", type: nil)
    let projectArg = project.asRubyArgument(name: "project", type: nil)
    let schemeArg = scheme.asRubyArgument(name: "scheme", type: nil)
    let cleanArg = clean.asRubyArgument(name: "clean", type: nil)
    let outputDirectoryArg = RubyCommand.Argument(name: "output_directory", value: outputDirectory, type: nil)
    let outputNameArg = outputName.asRubyArgument(name: "output_name", type: nil)
    let configurationArg = configuration.asRubyArgument(name: "configuration", type: nil)
    let silentArg = silent.asRubyArgument(name: "silent", type: nil)
    let codesigningIdentityArg = codesigningIdentity.asRubyArgument(name: "codesigning_identity", type: nil)
    let skipPackageIpaArg = skipPackageIpa.asRubyArgument(name: "skip_package_ipa", type: nil)
    let includeSymbolsArg = includeSymbols.asRubyArgument(name: "include_symbols", type: nil)
    let includeBitcodeArg = includeBitcode.asRubyArgument(name: "include_bitcode", type: nil)
    let exportMethodArg = exportMethod.asRubyArgument(name: "export_method", type: nil)
    let exportOptionsArg = exportOptions.asRubyArgument(name: "export_options", type: nil)
    let exportXcargsArg = exportXcargs.asRubyArgument(name: "export_xcargs", type: nil)
    let skipBuildArchiveArg = skipBuildArchive.asRubyArgument(name: "skip_build_archive", type: nil)
    let skipArchiveArg = skipArchive.asRubyArgument(name: "skip_archive", type: nil)
    let skipCodesigningArg = skipCodesigning.asRubyArgument(name: "skip_codesigning", type: nil)
    let buildPathArg = buildPath.asRubyArgument(name: "build_path", type: nil)
    let archivePathArg = archivePath.asRubyArgument(name: "archive_path", type: nil)
    let derivedDataPathArg = derivedDataPath.asRubyArgument(name: "derived_data_path", type: nil)
    let resultBundleArg = resultBundle.asRubyArgument(name: "result_bundle", type: nil)
    let resultBundlePathArg = resultBundlePath.asRubyArgument(name: "result_bundle_path", type: nil)
    let buildlogPathArg = RubyCommand.Argument(name: "buildlog_path", value: buildlogPath, type: nil)
    let sdkArg = sdk.asRubyArgument(name: "sdk", type: nil)
    let toolchainArg = toolchain.asRubyArgument(name: "toolchain", type: nil)
    let destinationArg = destination.asRubyArgument(name: "destination", type: nil)
    let exportTeamIdArg = exportTeamId.asRubyArgument(name: "export_team_id", type: nil)
    let xcargsArg = xcargs.asRubyArgument(name: "xcargs", type: nil)
    let xcconfigArg = xcconfig.asRubyArgument(name: "xcconfig", type: nil)
    let suppressXcodeOutputArg = suppressXcodeOutput.asRubyArgument(name: "suppress_xcode_output", type: nil)
    let xcodebuildFormatterArg = RubyCommand.Argument(name: "xcodebuild_formatter", value: xcodebuildFormatter, type: nil)
    let buildTimingSummaryArg = buildTimingSummary.asRubyArgument(name: "build_timing_summary", type: nil)
    let disableXcprettyArg = disableXcpretty.asRubyArgument(name: "disable_xcpretty", type: nil)
    let xcprettyTestFormatArg = xcprettyTestFormat.asRubyArgument(name: "xcpretty_test_format", type: nil)
    let xcprettyFormatterArg = xcprettyFormatter.asRubyArgument(name: "xcpretty_formatter", type: nil)
    let xcprettyReportJunitArg = xcprettyReportJunit.asRubyArgument(name: "xcpretty_report_junit", type: nil)
    let xcprettyReportHtmlArg = xcprettyReportHtml.asRubyArgument(name: "xcpretty_report_html", type: nil)
    let xcprettyReportJsonArg = xcprettyReportJson.asRubyArgument(name: "xcpretty_report_json", type: nil)
    let xcprettyUtfArg = xcprettyUtf.asRubyArgument(name: "xcpretty_utf", type: nil)
    let analyzeBuildTimeArg = analyzeBuildTime.asRubyArgument(name: "analyze_build_time", type: nil)
    let skipProfileDetectionArg = skipProfileDetection.asRubyArgument(name: "skip_profile_detection", type: nil)
    let xcodebuildCommandArg = RubyCommand.Argument(name: "xcodebuild_command", value: xcodebuildCommand, type: nil)
    let clonedSourcePackagesPathArg = clonedSourcePackagesPath.asRubyArgument(name: "cloned_source_packages_path", type: nil)
    let skipPackageDependenciesResolutionArg = skipPackageDependenciesResolution.asRubyArgument(name: "skip_package_dependencies_resolution", type: nil)
    let disablePackageAutomaticUpdatesArg = disablePackageAutomaticUpdates.asRubyArgument(name: "disable_package_automatic_updates", type: nil)
    let useSystemScmArg = useSystemScm.asRubyArgument(name: "use_system_scm", type: nil)
    let packageAuthorizationProviderArg = packageAuthorizationProvider.asRubyArgument(name: "package_authorization_provider", type: nil)
    let array: [RubyCommand.Argument?] = [workspaceArg,
                                          projectArg,
                                          schemeArg,
                                          cleanArg,
                                          outputDirectoryArg,
                                          outputNameArg,
                                          configurationArg,
                                          silentArg,
                                          codesigningIdentityArg,
                                          skipPackageIpaArg,
                                          includeSymbolsArg,
                                          includeBitcodeArg,
                                          exportMethodArg,
                                          exportOptionsArg,
                                          exportXcargsArg,
                                          skipBuildArchiveArg,
                                          skipArchiveArg,
                                          skipCodesigningArg,
                                          buildPathArg,
                                          archivePathArg,
                                          derivedDataPathArg,
                                          resultBundleArg,
                                          resultBundlePathArg,
                                          buildlogPathArg,
                                          sdkArg,
                                          toolchainArg,
                                          destinationArg,
                                          exportTeamIdArg,
                                          xcargsArg,
                                          xcconfigArg,
                                          suppressXcodeOutputArg,
                                          xcodebuildFormatterArg,
                                          buildTimingSummaryArg,
                                          disableXcprettyArg,
                                          xcprettyTestFormatArg,
                                          xcprettyFormatterArg,
                                          xcprettyReportJunitArg,
                                          xcprettyReportHtmlArg,
                                          xcprettyReportJsonArg,
                                          xcprettyUtfArg,
                                          analyzeBuildTimeArg,
                                          skipProfileDetectionArg,
                                          xcodebuildCommandArg,
                                          clonedSourcePackagesPathArg,
                                          skipPackageDependenciesResolutionArg,
                                          disablePackageAutomaticUpdatesArg,
                                          useSystemScmArg,
                                          packageAuthorizationProviderArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "build_ios_app", className: nil, args: args)
    return runner.executeCommand(command)
}

/**
 Alias for the `build_app` action but only for macOS

 - parameters:
   - workspace: Path to the workspace file
   - project: Path to the project file
   - scheme: The project's scheme. Make sure it's marked as `Shared`
   - clean: Should the project be cleaned before building it?
   - outputDirectory: The directory in which the ipa file should be stored in
   - outputName: The name of the resulting ipa file
   - configuration: The configuration to use when building the app. Defaults to 'Release'
   - silent: Hide all information that's not necessary while building
   - codesigningIdentity: The name of the code signing identity to use. It has to match the name exactly. e.g. 'iPhone Distribution: SunApps GmbH'
   - skipPackagePkg: Should we skip packaging the pkg?
   - includeSymbols: Should the ipa file include symbols?
   - includeBitcode: Should the ipa file include bitcode?
   - exportMethod: Method used to export the archive. Valid values are: app-store, validation, ad-hoc, package, enterprise, development, developer-id and mac-application
   - exportOptions: Path to an export options plist or a hash with export options. Use 'xcodebuild -help' to print the full set of available options
   - exportXcargs: Pass additional arguments to xcodebuild for the package phase. Be sure to quote the setting names and values e.g. OTHER_LDFLAGS="-ObjC -lstdc++"
   - skipBuildArchive: Export ipa from previously built xcarchive. Uses archive_path as source
   - skipArchive: After building, don't archive, effectively not including -archivePath param
   - skipCodesigning: Build without codesigning
   - installerCertName: Full name of 3rd Party Mac Developer Installer or Developer ID Installer certificate. Example: `3rd Party Mac Developer Installer: Your Company (ABC1234XWYZ)`
   - buildPath: The directory in which the archive should be stored in
   - archivePath: The path to the created archive
   - derivedDataPath: The directory where built products and other derived data will go
   - resultBundle: Should an Xcode result bundle be generated in the output directory
   - resultBundlePath: Path to the result bundle directory to create. Ignored if `result_bundle` if false
   - buildlogPath: The directory where to store the build log
   - sdk: The SDK that should be used for building the application
   - toolchain: The toolchain that should be used for building the application (e.g. com.apple.dt.toolchain.Swift_2_3, org.swift.30p620160816a)
   - destination: Use a custom destination for building the app
   - exportTeamId: Optional: Sometimes you need to specify a team id when exporting the ipa file
   - xcargs: Pass additional arguments to xcodebuild for the build phase. Be sure to quote the setting names and values e.g. OTHER_LDFLAGS="-ObjC -lstdc++"
   - xcconfig: Use an extra XCCONFIG file to build your app
   - suppressXcodeOutput: Suppress the output of xcodebuild to stdout. Output is still saved in buildlog_path
   - xcodebuildFormatter: xcodebuild formatter to use (ex: 'xcbeautify', 'xcbeautify --quieter', 'xcpretty', 'xcpretty -test'). Use empty string (ex: '') to disable any formatter (More information: https://docs.fastlane.tools/best-practices/xcodebuild-formatters/)
   - buildTimingSummary: Create a build timing summary
   - disableXcpretty: **DEPRECATED!** Use `xcodebuild_formatter: ''` instead - Disable xcpretty formatting of build output
   - xcprettyTestFormat: Use the test (RSpec style) format for build output
   - xcprettyFormatter: A custom xcpretty formatter to use
   - xcprettyReportJunit: Have xcpretty create a JUnit-style XML report at the provided path
   - xcprettyReportHtml: Have xcpretty create a simple HTML report at the provided path
   - xcprettyReportJson: Have xcpretty create a JSON compilation database at the provided path
   - xcprettyUtf: Have xcpretty use unicode encoding when reporting builds
   - analyzeBuildTime: Analyze the project build time and store the output in 'culprits.txt' file
   - skipProfileDetection: Do not try to build a profile mapping from the xcodeproj. Match or a manually provided mapping should be used
   - xcodebuildCommand: Allows for override of the default `xcodebuild` command
   - clonedSourcePackagesPath: Sets a custom path for Swift Package Manager dependencies
   - skipPackageDependenciesResolution: Skips resolution of Swift Package Manager dependencies
   - disablePackageAutomaticUpdates: Prevents packages from automatically being resolved to versions other than those recorded in the `Package.resolved` file
   - useSystemScm: Lets xcodebuild use system's scm configuration
   - packageAuthorizationProvider: Lets xcodebuild use a specified package authorization provider (keychain|netrc)

 - returns: The absolute path to the generated ipa file

 More information: https://fastlane.tools/gym
 */
@discardableResult public func buildMacApp(workspace: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           project: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           scheme: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           clean: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                           outputDirectory: String = ".",
                                           outputName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           configuration: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           silent: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                           codesigningIdentity: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           skipPackagePkg: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                           includeSymbols: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                           includeBitcode: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                           exportMethod: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           exportOptions: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                                           exportXcargs: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           skipBuildArchive: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                           skipArchive: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                           skipCodesigning: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                           installerCertName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           buildPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           archivePath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           derivedDataPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           resultBundle: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                           resultBundlePath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           buildlogPath: String = "~/Library/Logs/gym",
                                           sdk: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           toolchain: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           destination: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           exportTeamId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           xcargs: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           xcconfig: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           suppressXcodeOutput: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                           xcodebuildFormatter: String = "xcbeautify",
                                           buildTimingSummary: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                           disableXcpretty: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                           xcprettyTestFormat: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                           xcprettyFormatter: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           xcprettyReportJunit: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           xcprettyReportHtml: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           xcprettyReportJson: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           xcprettyUtf: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                           analyzeBuildTime: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                           skipProfileDetection: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                           xcodebuildCommand: String = "xcodebuild",
                                           clonedSourcePackagesPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                           skipPackageDependenciesResolution: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                           disablePackageAutomaticUpdates: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                           useSystemScm: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                           packageAuthorizationProvider: OptionalConfigValue<String?> = .fastlaneDefault(nil)) -> String
{
    let workspaceArg = workspace.asRubyArgument(name: "workspace", type: nil)
    let projectArg = project.asRubyArgument(name: "project", type: nil)
    let schemeArg = scheme.asRubyArgument(name: "scheme", type: nil)
    let cleanArg = clean.asRubyArgument(name: "clean", type: nil)
    let outputDirectoryArg = RubyCommand.Argument(name: "output_directory", value: outputDirectory, type: nil)
    let outputNameArg = outputName.asRubyArgument(name: "output_name", type: nil)
    let configurationArg = configuration.asRubyArgument(name: "configuration", type: nil)
    let silentArg = silent.asRubyArgument(name: "silent", type: nil)
    let codesigningIdentityArg = codesigningIdentity.asRubyArgument(name: "codesigning_identity", type: nil)
    let skipPackagePkgArg = skipPackagePkg.asRubyArgument(name: "skip_package_pkg", type: nil)
    let includeSymbolsArg = includeSymbols.asRubyArgument(name: "include_symbols", type: nil)
    let includeBitcodeArg = includeBitcode.asRubyArgument(name: "include_bitcode", type: nil)
    let exportMethodArg = exportMethod.asRubyArgument(name: "export_method", type: nil)
    let exportOptionsArg = exportOptions.asRubyArgument(name: "export_options", type: nil)
    let exportXcargsArg = exportXcargs.asRubyArgument(name: "export_xcargs", type: nil)
    let skipBuildArchiveArg = skipBuildArchive.asRubyArgument(name: "skip_build_archive", type: nil)
    let skipArchiveArg = skipArchive.asRubyArgument(name: "skip_archive", type: nil)
    let skipCodesigningArg = skipCodesigning.asRubyArgument(name: "skip_codesigning", type: nil)
    let installerCertNameArg = installerCertName.asRubyArgument(name: "installer_cert_name", type: nil)
    let buildPathArg = buildPath.asRubyArgument(name: "build_path", type: nil)
    let archivePathArg = archivePath.asRubyArgument(name: "archive_path", type: nil)
    let derivedDataPathArg = derivedDataPath.asRubyArgument(name: "derived_data_path", type: nil)
    let resultBundleArg = resultBundle.asRubyArgument(name: "result_bundle", type: nil)
    let resultBundlePathArg = resultBundlePath.asRubyArgument(name: "result_bundle_path", type: nil)
    let buildlogPathArg = RubyCommand.Argument(name: "buildlog_path", value: buildlogPath, type: nil)
    let sdkArg = sdk.asRubyArgument(name: "sdk", type: nil)
    let toolchainArg = toolchain.asRubyArgument(name: "toolchain", type: nil)
    let destinationArg = destination.asRubyArgument(name: "destination", type: nil)
    let exportTeamIdArg = exportTeamId.asRubyArgument(name: "export_team_id", type: nil)
    let xcargsArg = xcargs.asRubyArgument(name: "xcargs", type: nil)
    let xcconfigArg = xcconfig.asRubyArgument(name: "xcconfig", type: nil)
    let suppressXcodeOutputArg = suppressXcodeOutput.asRubyArgument(name: "suppress_xcode_output", type: nil)
    let xcodebuildFormatterArg = RubyCommand.Argument(name: "xcodebuild_formatter", value: xcodebuildFormatter, type: nil)
    let buildTimingSummaryArg = buildTimingSummary.asRubyArgument(name: "build_timing_summary", type: nil)
    let disableXcprettyArg = disableXcpretty.asRubyArgument(name: "disable_xcpretty", type: nil)
    let xcprettyTestFormatArg = xcprettyTestFormat.asRubyArgument(name: "xcpretty_test_format", type: nil)
    let xcprettyFormatterArg = xcprettyFormatter.asRubyArgument(name: "xcpretty_formatter", type: nil)
    let xcprettyReportJunitArg = xcprettyReportJunit.asRubyArgument(name: "xcpretty_report_junit", type: nil)
    let xcprettyReportHtmlArg = xcprettyReportHtml.asRubyArgument(name: "xcpretty_report_html", type: nil)
    let xcprettyReportJsonArg = xcprettyReportJson.asRubyArgument(name: "xcpretty_report_json", type: nil)
    let xcprettyUtfArg = xcprettyUtf.asRubyArgument(name: "xcpretty_utf", type: nil)
    let analyzeBuildTimeArg = analyzeBuildTime.asRubyArgument(name: "analyze_build_time", type: nil)
    let skipProfileDetectionArg = skipProfileDetection.asRubyArgument(name: "skip_profile_detection", type: nil)
    let xcodebuildCommandArg = RubyCommand.Argument(name: "xcodebuild_command", value: xcodebuildCommand, type: nil)
    let clonedSourcePackagesPathArg = clonedSourcePackagesPath.asRubyArgument(name: "cloned_source_packages_path", type: nil)
    let skipPackageDependenciesResolutionArg = skipPackageDependenciesResolution.asRubyArgument(name: "skip_package_dependencies_resolution", type: nil)
    let disablePackageAutomaticUpdatesArg = disablePackageAutomaticUpdates.asRubyArgument(name: "disable_package_automatic_updates", type: nil)
    let useSystemScmArg = useSystemScm.asRubyArgument(name: "use_system_scm", type: nil)
    let packageAuthorizationProviderArg = packageAuthorizationProvider.asRubyArgument(name: "package_authorization_provider", type: nil)
    let array: [RubyCommand.Argument?] = [workspaceArg,
                                          projectArg,
                                          schemeArg,
                                          cleanArg,
                                          outputDirectoryArg,
                                          outputNameArg,
                                          configurationArg,
                                          silentArg,
                                          codesigningIdentityArg,
                                          skipPackagePkgArg,
                                          includeSymbolsArg,
                                          includeBitcodeArg,
                                          exportMethodArg,
                                          exportOptionsArg,
                                          exportXcargsArg,
                                          skipBuildArchiveArg,
                                          skipArchiveArg,
                                          skipCodesigningArg,
                                          installerCertNameArg,
                                          buildPathArg,
                                          archivePathArg,
                                          derivedDataPathArg,
                                          resultBundleArg,
                                          resultBundlePathArg,
                                          buildlogPathArg,
                                          sdkArg,
                                          toolchainArg,
                                          destinationArg,
                                          exportTeamIdArg,
                                          xcargsArg,
                                          xcconfigArg,
                                          suppressXcodeOutputArg,
                                          xcodebuildFormatterArg,
                                          buildTimingSummaryArg,
                                          disableXcprettyArg,
                                          xcprettyTestFormatArg,
                                          xcprettyFormatterArg,
                                          xcprettyReportJunitArg,
                                          xcprettyReportHtmlArg,
                                          xcprettyReportJsonArg,
                                          xcprettyUtfArg,
                                          analyzeBuildTimeArg,
                                          skipProfileDetectionArg,
                                          xcodebuildCommandArg,
                                          clonedSourcePackagesPathArg,
                                          skipPackageDependenciesResolutionArg,
                                          disablePackageAutomaticUpdatesArg,
                                          useSystemScmArg,
                                          packageAuthorizationProviderArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "build_mac_app", className: nil, args: args)
    return runner.executeCommand(command)
}

/**
 This action runs `bundle install` (if available)

 - parameters:
   - binstubs: Generate bin stubs for bundled gems to ./bin
   - clean: Run bundle clean automatically after install
   - fullIndex: Use the rubygems modern index instead of the API endpoint
   - gemfile: Use the specified gemfile instead of Gemfile
   - jobs: Install gems using parallel workers
   - local: Do not attempt to fetch gems remotely and use the gem cache instead
   - deployment: Install using defaults tuned for deployment and CI environments
   - noCache: Don't update the existing gem cache
   - noPrune: Don't remove stale gems from the cache
   - path: Specify a different path than the system default ($BUNDLE_PATH or $GEM_HOME). Bundler will remember this value for future installs on this machine
   - system: Install to the system location ($BUNDLE_PATH or $GEM_HOME) even if the bundle was previously installed somewhere else for this application
   - quiet: Only output warnings and errors
   - retry: Retry network and git requests that have failed
   - shebang: Specify a different shebang executable name than the default (usually 'ruby')
   - standalone: Make a bundle that can work without the Bundler runtime
   - trustPolicy: Sets level of security when dealing with signed gems. Accepts `LowSecurity`, `MediumSecurity` and `HighSecurity` as values
   - without: Exclude gems that are part of the specified named group
   - with: Include gems that are part of the specified named group
   - frozen: Don't allow the Gemfile.lock to be updated after install
   - redownload: Force download every gem, even if the required versions are already available locally
 */
public func bundleInstall(binstubs: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                          clean: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                          fullIndex: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                          gemfile: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                          jobs: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                          local: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                          deployment: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                          noCache: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                          noPrune: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                          path: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                          system: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                          quiet: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                          retry: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                          shebang: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                          standalone: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                          trustPolicy: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                          without: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                          with: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                          frozen: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                          redownload: OptionalConfigValue<Bool> = .fastlaneDefault(false))
{
    let binstubsArg = binstubs.asRubyArgument(name: "binstubs", type: nil)
    let cleanArg = clean.asRubyArgument(name: "clean", type: nil)
    let fullIndexArg = fullIndex.asRubyArgument(name: "full_index", type: nil)
    let gemfileArg = gemfile.asRubyArgument(name: "gemfile", type: nil)
    let jobsArg = jobs.asRubyArgument(name: "jobs", type: nil)
    let localArg = local.asRubyArgument(name: "local", type: nil)
    let deploymentArg = deployment.asRubyArgument(name: "deployment", type: nil)
    let noCacheArg = noCache.asRubyArgument(name: "no_cache", type: nil)
    let noPruneArg = noPrune.asRubyArgument(name: "no_prune", type: nil)
    let pathArg = path.asRubyArgument(name: "path", type: nil)
    let systemArg = system.asRubyArgument(name: "system", type: nil)
    let quietArg = quiet.asRubyArgument(name: "quiet", type: nil)
    let retryArg = retry.asRubyArgument(name: "retry", type: nil)
    let shebangArg = shebang.asRubyArgument(name: "shebang", type: nil)
    let standaloneArg = standalone.asRubyArgument(name: "standalone", type: nil)
    let trustPolicyArg = trustPolicy.asRubyArgument(name: "trust_policy", type: nil)
    let withoutArg = without.asRubyArgument(name: "without", type: nil)
    let withArg = with.asRubyArgument(name: "with", type: nil)
    let frozenArg = frozen.asRubyArgument(name: "frozen", type: nil)
    let redownloadArg = redownload.asRubyArgument(name: "redownload", type: nil)
    let array: [RubyCommand.Argument?] = [binstubsArg,
                                          cleanArg,
                                          fullIndexArg,
                                          gemfileArg,
                                          jobsArg,
                                          localArg,
                                          deploymentArg,
                                          noCacheArg,
                                          noPruneArg,
                                          pathArg,
                                          systemArg,
                                          quietArg,
                                          retryArg,
                                          shebangArg,
                                          standaloneArg,
                                          trustPolicyArg,
                                          withoutArg,
                                          withArg,
                                          frozenArg,
                                          redownloadArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "bundle_install", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Automated localized screenshots of your Android app (via _screengrab_)

 - parameters:
   - androidHome: Path to the root of your Android SDK installation, e.g. ~/tools/android-sdk-macosx
   - buildToolsVersion: **DEPRECATED!** The Android build tools version to use, e.g. '23.0.2'
   - locales: A list of locales which should be used
   - clearPreviousScreenshots: Enabling this option will automatically clear previously generated screenshots before running screengrab
   - outputDirectory: The directory where to store the screenshots
   - skipOpenSummary: Don't open the summary after running _screengrab_
   - appPackageName: The package name of the app under test (e.g. com.yourcompany.yourapp)
   - testsPackageName: The package name of the tests bundle (e.g. com.yourcompany.yourapp.test)
   - useTestsInPackages: Only run tests in these Java packages
   - useTestsInClasses: Only run tests in these Java classes
   - launchArguments: Additional launch arguments
   - testInstrumentationRunner: The fully qualified class name of your test instrumentation runner
   - endingLocale: **DEPRECATED!** Return the device to this locale after running tests
   - useAdbRoot: **DEPRECATED!** Restarts the adb daemon using `adb root` to allow access to screenshots directories on device. Use if getting 'Permission denied' errors
   - appApkPath: The path to the APK for the app under test
   - testsApkPath: The path to the APK for the tests bundle
   - specificDevice: Use the device or emulator with the given serial number or qualifier
   - deviceType: Type of device used for screenshots. Matches Google Play Types (phone, sevenInch, tenInch, tv, wear)
   - exitOnTestFailure: Whether or not to exit Screengrab on test failure. Exiting on failure will not copy screenshots to local machine nor open screenshots summary
   - reinstallApp: Enabling this option will automatically uninstall the application before running it
   - useTimestampSuffix: Add timestamp suffix to screenshot filename
   - adbHost: Configure the host used by adb to connect, allows running on remote devices farm
 */
public func captureAndroidScreenshots(androidHome: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                      buildToolsVersion: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                      locales: [String] = ["en-US"],
                                      clearPreviousScreenshots: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                      outputDirectory: String = "fastlane/metadata/android",
                                      skipOpenSummary: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                      appPackageName: String,
                                      testsPackageName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                      useTestsInPackages: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                                      useTestsInClasses: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                                      launchArguments: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                                      testInstrumentationRunner: String = "androidx.test.runner.AndroidJUnitRunner",
                                      endingLocale: String = "en-US",
                                      useAdbRoot: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                      appApkPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                      testsApkPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                      specificDevice: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                      deviceType: String = "phone",
                                      exitOnTestFailure: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                                      reinstallApp: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                      useTimestampSuffix: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                                      adbHost: OptionalConfigValue<String?> = .fastlaneDefault(nil))
{
    let androidHomeArg = androidHome.asRubyArgument(name: "android_home", type: nil)
    let buildToolsVersionArg = buildToolsVersion.asRubyArgument(name: "build_tools_version", type: nil)
    let localesArg = RubyCommand.Argument(name: "locales", value: locales, type: nil)
    let clearPreviousScreenshotsArg = clearPreviousScreenshots.asRubyArgument(name: "clear_previous_screenshots", type: nil)
    let outputDirectoryArg = RubyCommand.Argument(name: "output_directory", value: outputDirectory, type: nil)
    let skipOpenSummaryArg = skipOpenSummary.asRubyArgument(name: "skip_open_summary", type: nil)
    let appPackageNameArg = RubyCommand.Argument(name: "app_package_name", value: appPackageName, type: nil)
    let testsPackageNameArg = testsPackageName.asRubyArgument(name: "tests_package_name", type: nil)
    let useTestsInPackagesArg = useTestsInPackages.asRubyArgument(name: "use_tests_in_packages", type: nil)
    let useTestsInClassesArg = useTestsInClasses.asRubyArgument(name: "use_tests_in_classes", type: nil)
    let launchArgumentsArg = launchArguments.asRubyArgument(name: "launch_arguments", type: nil)
    let testInstrumentationRunnerArg = RubyCommand.Argument(name: "test_instrumentation_runner", value: testInstrumentationRunner, type: nil)
    let endingLocaleArg = RubyCommand.Argument(name: "ending_locale", value: endingLocale, type: nil)
    let useAdbRootArg = useAdbRoot.asRubyArgument(name: "use_adb_root", type: nil)
    let appApkPathArg = appApkPath.asRubyArgument(name: "app_apk_path", type: nil)
    let testsApkPathArg = testsApkPath.asRubyArgument(name: "tests_apk_path", type: nil)
    let specificDeviceArg = specificDevice.asRubyArgument(name: "specific_device", type: nil)
    let deviceTypeArg = RubyCommand.Argument(name: "device_type", value: deviceType, type: nil)
    let exitOnTestFailureArg = exitOnTestFailure.asRubyArgument(name: "exit_on_test_failure", type: nil)
    let reinstallAppArg = reinstallApp.asRubyArgument(name: "reinstall_app", type: nil)
    let useTimestampSuffixArg = useTimestampSuffix.asRubyArgument(name: "use_timestamp_suffix", type: nil)
    let adbHostArg = adbHost.asRubyArgument(name: "adb_host", type: nil)
    let array: [RubyCommand.Argument?] = [androidHomeArg,
                                          buildToolsVersionArg,
                                          localesArg,
                                          clearPreviousScreenshotsArg,
                                          outputDirectoryArg,
                                          skipOpenSummaryArg,
                                          appPackageNameArg,
                                          testsPackageNameArg,
                                          useTestsInPackagesArg,
                                          useTestsInClassesArg,
                                          launchArgumentsArg,
                                          testInstrumentationRunnerArg,
                                          endingLocaleArg,
                                          useAdbRootArg,
                                          appApkPathArg,
                                          testsApkPathArg,
                                          specificDeviceArg,
                                          deviceTypeArg,
                                          exitOnTestFailureArg,
                                          reinstallAppArg,
                                          useTimestampSuffixArg,
                                          adbHostArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "capture_android_screenshots", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Generate new localized screenshots on multiple devices (via _snapshot_)

 - parameters:
   - workspace: Path to the workspace file
   - project: Path to the project file
   - xcargs: Pass additional arguments to xcodebuild for the test phase. Be sure to quote the setting names and values e.g. OTHER_LDFLAGS="-ObjC -lstdc++"
   - xcconfig: Use an extra XCCONFIG file to build your app
   - devices: A list of devices you want to take the screenshots from
   - languages: A list of languages which should be used
   - launchArguments: A list of launch arguments which should be used
   - outputDirectory: The directory where to store the screenshots
   - outputSimulatorLogs: If the logs generated by the app (e.g. using NSLog, perror, etc.) in the Simulator should be written to the output_directory
   - iosVersion: By default, the latest version should be used automatically. If you want to change it, do it here
   - skipOpenSummary: Don't open the HTML summary after running _snapshot_
   - skipHelperVersionCheck: Do not check for most recent SnapshotHelper code
   - clearPreviousScreenshots: Enabling this option will automatically clear previously generated screenshots before running snapshot
   - reinstallApp: Enabling this option will automatically uninstall the application before running it
   - eraseSimulator: Enabling this option will automatically erase the simulator before running the application
   - headless: Enabling this option will prevent displaying the simulator window
   - overrideStatusBar: Enabling this option will automatically override the status bar to show 9:41 AM, full battery, and full reception (Adjust 'SNAPSHOT_SIMULATOR_WAIT_FOR_BOOT_TIMEOUT' environment variable if override status bar is not working. Might be because simulator is not fully booted. Defaults to 10 seconds)
   - overrideStatusBarArguments: Fully customize the status bar by setting each option here. Requires `override_status_bar` to be set to `true`. See `xcrun simctl status_bar --help`
   - localizeSimulator: Enabling this option will configure the Simulator's system language
   - darkMode: Enabling this option will configure the Simulator to be in dark mode (false for light, true for dark)
   - appIdentifier: The bundle identifier of the app to uninstall (only needed when enabling reinstall_app)
   - addPhotos: A list of photos that should be added to the simulator before running the application
   - addVideos: A list of videos that should be added to the simulator before running the application
   - htmlTemplate: A path to screenshots.html template
   - buildlogPath: The directory where to store the build log
   - clean: Should the project be cleaned before building it?
   - testWithoutBuilding: Test without building, requires a derived data path
   - configuration: The configuration to use when building the app. Defaults to 'Release'
   - sdk: The SDK that should be used for building the application
   - scheme: The scheme you want to use, this must be the scheme for the UI Tests
   - numberOfRetries: The number of times a test can fail before snapshot should stop retrying
   - stopAfterFirstError: Should snapshot stop immediately after the tests completely failed on one device?
   - derivedDataPath: The directory where build products and other derived data will go
   - resultBundle: Should an Xcode result bundle be generated in the output directory
   - testTargetName: The name of the target you want to test (if you desire to override the Target Application from Xcode)
   - namespaceLogFiles: Separate the log files per device and per language
   - concurrentSimulators: Take snapshots on multiple simulators concurrently. Note: This option is only applicable when running against Xcode 9
   - disableSlideToType: Disable the simulator from showing the 'Slide to type' prompt
   - clonedSourcePackagesPath: Sets a custom path for Swift Package Manager dependencies
   - skipPackageDependenciesResolution: Skips resolution of Swift Package Manager dependencies
   - disablePackageAutomaticUpdates: Prevents packages from automatically being resolved to versions other than those recorded in the `Package.resolved` file
   - packageAuthorizationProvider: Lets xcodebuild use a specified package authorization provider (keychain|netrc)
   - testplan: The testplan associated with the scheme that should be used for testing
   - onlyTesting: Array of strings matching Test Bundle/Test Suite/Test Cases to run
   - skipTesting: Array of strings matching Test Bundle/Test Suite/Test Cases to skip
   - xcodebuildFormatter: xcodebuild formatter to use (ex: 'xcbeautify', 'xcbeautify --quieter', 'xcpretty', 'xcpretty -test'). Use empty string (ex: '') to disable any formatter (More information: https://docs.fastlane.tools/best-practices/xcodebuild-formatters/)
   - xcprettyArgs: **DEPRECATED!** Use `xcodebuild_formatter: ''` instead - Additional xcpretty arguments
   - disableXcpretty: Disable xcpretty formatting of build
   - suppressXcodeOutput: Suppress the output of xcodebuild to stdout. Output is still saved in buildlog_path
   - useSystemScm: Lets xcodebuild use system's scm configuration
 */
public func captureIosScreenshots(workspace: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  project: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  xcargs: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  xcconfig: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  devices: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                                  languages: [String] = ["en-US"],
                                  launchArguments: [String] = [""],
                                  outputDirectory: String = "screenshots",
                                  outputSimulatorLogs: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                  iosVersion: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  skipOpenSummary: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                  skipHelperVersionCheck: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                  clearPreviousScreenshots: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                  reinstallApp: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                  eraseSimulator: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                  headless: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                                  overrideStatusBar: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                  overrideStatusBarArguments: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  localizeSimulator: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                  darkMode: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                  appIdentifier: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  addPhotos: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                                  addVideos: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                                  htmlTemplate: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  buildlogPath: String = "~/Library/Logs/snapshot",
                                  clean: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                  testWithoutBuilding: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                  configuration: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  sdk: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  scheme: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  numberOfRetries: Int = 1,
                                  stopAfterFirstError: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                  derivedDataPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  resultBundle: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                  testTargetName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  namespaceLogFiles: Any? = nil,
                                  concurrentSimulators: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                                  disableSlideToType: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                  clonedSourcePackagesPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  skipPackageDependenciesResolution: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                  disablePackageAutomaticUpdates: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                  packageAuthorizationProvider: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  testplan: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  onlyTesting: Any? = nil,
                                  skipTesting: Any? = nil,
                                  xcodebuildFormatter: String = "xcbeautify",
                                  xcprettyArgs: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  disableXcpretty: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                  suppressXcodeOutput: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                  useSystemScm: OptionalConfigValue<Bool> = .fastlaneDefault(false))
{
    let workspaceArg = workspace.asRubyArgument(name: "workspace", type: nil)
    let projectArg = project.asRubyArgument(name: "project", type: nil)
    let xcargsArg = xcargs.asRubyArgument(name: "xcargs", type: nil)
    let xcconfigArg = xcconfig.asRubyArgument(name: "xcconfig", type: nil)
    let devicesArg = devices.asRubyArgument(name: "devices", type: nil)
    let languagesArg = RubyCommand.Argument(name: "languages", value: languages, type: nil)
    let launchArgumentsArg = RubyCommand.Argument(name: "launch_arguments", value: launchArguments, type: nil)
    let outputDirectoryArg = RubyCommand.Argument(name: "output_directory", value: outputDirectory, type: nil)
    let outputSimulatorLogsArg = outputSimulatorLogs.asRubyArgument(name: "output_simulator_logs", type: nil)
    let iosVersionArg = iosVersion.asRubyArgument(name: "ios_version", type: nil)
    let skipOpenSummaryArg = skipOpenSummary.asRubyArgument(name: "skip_open_summary", type: nil)
    let skipHelperVersionCheckArg = skipHelperVersionCheck.asRubyArgument(name: "skip_helper_version_check", type: nil)
    let clearPreviousScreenshotsArg = clearPreviousScreenshots.asRubyArgument(name: "clear_previous_screenshots", type: nil)
    let reinstallAppArg = reinstallApp.asRubyArgument(name: "reinstall_app", type: nil)
    let eraseSimulatorArg = eraseSimulator.asRubyArgument(name: "erase_simulator", type: nil)
    let headlessArg = headless.asRubyArgument(name: "headless", type: nil)
    let overrideStatusBarArg = overrideStatusBar.asRubyArgument(name: "override_status_bar", type: nil)
    let overrideStatusBarArgumentsArg = overrideStatusBarArguments.asRubyArgument(name: "override_status_bar_arguments", type: nil)
    let localizeSimulatorArg = localizeSimulator.asRubyArgument(name: "localize_simulator", type: nil)
    let darkModeArg = darkMode.asRubyArgument(name: "dark_mode", type: nil)
    let appIdentifierArg = appIdentifier.asRubyArgument(name: "app_identifier", type: nil)
    let addPhotosArg = addPhotos.asRubyArgument(name: "add_photos", type: nil)
    let addVideosArg = addVideos.asRubyArgument(name: "add_videos", type: nil)
    let htmlTemplateArg = htmlTemplate.asRubyArgument(name: "html_template", type: nil)
    let buildlogPathArg = RubyCommand.Argument(name: "buildlog_path", value: buildlogPath, type: nil)
    let cleanArg = clean.asRubyArgument(name: "clean", type: nil)
    let testWithoutBuildingArg = testWithoutBuilding.asRubyArgument(name: "test_without_building", type: nil)
    let configurationArg = configuration.asRubyArgument(name: "configuration", type: nil)
    let sdkArg = sdk.asRubyArgument(name: "sdk", type: nil)
    let schemeArg = scheme.asRubyArgument(name: "scheme", type: nil)
    let numberOfRetriesArg = RubyCommand.Argument(name: "number_of_retries", value: numberOfRetries, type: nil)
    let stopAfterFirstErrorArg = stopAfterFirstError.asRubyArgument(name: "stop_after_first_error", type: nil)
    let derivedDataPathArg = derivedDataPath.asRubyArgument(name: "derived_data_path", type: nil)
    let resultBundleArg = resultBundle.asRubyArgument(name: "result_bundle", type: nil)
    let testTargetNameArg = testTargetName.asRubyArgument(name: "test_target_name", type: nil)
    let namespaceLogFilesArg = RubyCommand.Argument(name: "namespace_log_files", value: namespaceLogFiles, type: nil)
    let concurrentSimulatorsArg = concurrentSimulators.asRubyArgument(name: "concurrent_simulators", type: nil)
    let disableSlideToTypeArg = disableSlideToType.asRubyArgument(name: "disable_slide_to_type", type: nil)
    let clonedSourcePackagesPathArg = clonedSourcePackagesPath.asRubyArgument(name: "cloned_source_packages_path", type: nil)
    let skipPackageDependenciesResolutionArg = skipPackageDependenciesResolution.asRubyArgument(name: "skip_package_dependencies_resolution", type: nil)
    let disablePackageAutomaticUpdatesArg = disablePackageAutomaticUpdates.asRubyArgument(name: "disable_package_automatic_updates", type: nil)
    let packageAuthorizationProviderArg = packageAuthorizationProvider.asRubyArgument(name: "package_authorization_provider", type: nil)
    let testplanArg = testplan.asRubyArgument(name: "testplan", type: nil)
    let onlyTestingArg = RubyCommand.Argument(name: "only_testing", value: onlyTesting, type: nil)
    let skipTestingArg = RubyCommand.Argument(name: "skip_testing", value: skipTesting, type: nil)
    let xcodebuildFormatterArg = RubyCommand.Argument(name: "xcodebuild_formatter", value: xcodebuildFormatter, type: nil)
    let xcprettyArgsArg = xcprettyArgs.asRubyArgument(name: "xcpretty_args", type: nil)
    let disableXcprettyArg = disableXcpretty.asRubyArgument(name: "disable_xcpretty", type: nil)
    let suppressXcodeOutputArg = suppressXcodeOutput.asRubyArgument(name: "suppress_xcode_output", type: nil)
    let useSystemScmArg = useSystemScm.asRubyArgument(name: "use_system_scm", type: nil)
    let array: [RubyCommand.Argument?] = [workspaceArg,
                                          projectArg,
                                          xcargsArg,
                                          xcconfigArg,
                                          devicesArg,
                                          languagesArg,
                                          launchArgumentsArg,
                                          outputDirectoryArg,
                                          outputSimulatorLogsArg,
                                          iosVersionArg,
                                          skipOpenSummaryArg,
                                          skipHelperVersionCheckArg,
                                          clearPreviousScreenshotsArg,
                                          reinstallAppArg,
                                          eraseSimulatorArg,
                                          headlessArg,
                                          overrideStatusBarArg,
                                          overrideStatusBarArgumentsArg,
                                          localizeSimulatorArg,
                                          darkModeArg,
                                          appIdentifierArg,
                                          addPhotosArg,
                                          addVideosArg,
                                          htmlTemplateArg,
                                          buildlogPathArg,
                                          cleanArg,
                                          testWithoutBuildingArg,
                                          configurationArg,
                                          sdkArg,
                                          schemeArg,
                                          numberOfRetriesArg,
                                          stopAfterFirstErrorArg,
                                          derivedDataPathArg,
                                          resultBundleArg,
                                          testTargetNameArg,
                                          namespaceLogFilesArg,
                                          concurrentSimulatorsArg,
                                          disableSlideToTypeArg,
                                          clonedSourcePackagesPathArg,
                                          skipPackageDependenciesResolutionArg,
                                          disablePackageAutomaticUpdatesArg,
                                          packageAuthorizationProviderArg,
                                          testplanArg,
                                          onlyTestingArg,
                                          skipTestingArg,
                                          xcodebuildFormatterArg,
                                          xcprettyArgsArg,
                                          disableXcprettyArg,
                                          suppressXcodeOutputArg,
                                          useSystemScmArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "capture_ios_screenshots", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Alias for the `capture_ios_screenshots` action

 - parameters:
   - workspace: Path to the workspace file
   - project: Path to the project file
   - xcargs: Pass additional arguments to xcodebuild for the test phase. Be sure to quote the setting names and values e.g. OTHER_LDFLAGS="-ObjC -lstdc++"
   - xcconfig: Use an extra XCCONFIG file to build your app
   - devices: A list of devices you want to take the screenshots from
   - languages: A list of languages which should be used
   - launchArguments: A list of launch arguments which should be used
   - outputDirectory: The directory where to store the screenshots
   - outputSimulatorLogs: If the logs generated by the app (e.g. using NSLog, perror, etc.) in the Simulator should be written to the output_directory
   - iosVersion: By default, the latest version should be used automatically. If you want to change it, do it here
   - skipOpenSummary: Don't open the HTML summary after running _snapshot_
   - skipHelperVersionCheck: Do not check for most recent SnapshotHelper code
   - clearPreviousScreenshots: Enabling this option will automatically clear previously generated screenshots before running snapshot
   - reinstallApp: Enabling this option will automatically uninstall the application before running it
   - eraseSimulator: Enabling this option will automatically erase the simulator before running the application
   - headless: Enabling this option will prevent displaying the simulator window
   - overrideStatusBar: Enabling this option will automatically override the status bar to show 9:41 AM, full battery, and full reception (Adjust 'SNAPSHOT_SIMULATOR_WAIT_FOR_BOOT_TIMEOUT' environment variable if override status bar is not working. Might be because simulator is not fully booted. Defaults to 10 seconds)
   - overrideStatusBarArguments: Fully customize the status bar by setting each option here. Requires `override_status_bar` to be set to `true`. See `xcrun simctl status_bar --help`
   - localizeSimulator: Enabling this option will configure the Simulator's system language
   - darkMode: Enabling this option will configure the Simulator to be in dark mode (false for light, true for dark)
   - appIdentifier: The bundle identifier of the app to uninstall (only needed when enabling reinstall_app)
   - addPhotos: A list of photos that should be added to the simulator before running the application
   - addVideos: A list of videos that should be added to the simulator before running the application
   - htmlTemplate: A path to screenshots.html template
   - buildlogPath: The directory where to store the build log
   - clean: Should the project be cleaned before building it?
   - testWithoutBuilding: Test without building, requires a derived data path
   - configuration: The configuration to use when building the app. Defaults to 'Release'
   - sdk: The SDK that should be used for building the application
   - scheme: The scheme you want to use, this must be the scheme for the UI Tests
   - numberOfRetries: The number of times a test can fail before snapshot should stop retrying
   - stopAfterFirstError: Should snapshot stop immediately after the tests completely failed on one device?
   - derivedDataPath: The directory where build products and other derived data will go
   - resultBundle: Should an Xcode result bundle be generated in the output directory
   - testTargetName: The name of the target you want to test (if you desire to override the Target Application from Xcode)
   - namespaceLogFiles: Separate the log files per device and per language
   - concurrentSimulators: Take snapshots on multiple simulators concurrently. Note: This option is only applicable when running against Xcode 9
   - disableSlideToType: Disable the simulator from showing the 'Slide to type' prompt
   - clonedSourcePackagesPath: Sets a custom path for Swift Package Manager dependencies
   - skipPackageDependenciesResolution: Skips resolution of Swift Package Manager dependencies
   - disablePackageAutomaticUpdates: Prevents packages from automatically being resolved to versions other than those recorded in the `Package.resolved` file
   - packageAuthorizationProvider: Lets xcodebuild use a specified package authorization provider (keychain|netrc)
   - testplan: The testplan associated with the scheme that should be used for testing
   - onlyTesting: Array of strings matching Test Bundle/Test Suite/Test Cases to run
   - skipTesting: Array of strings matching Test Bundle/Test Suite/Test Cases to skip
   - xcodebuildFormatter: xcodebuild formatter to use (ex: 'xcbeautify', 'xcbeautify --quieter', 'xcpretty', 'xcpretty -test'). Use empty string (ex: '') to disable any formatter (More information: https://docs.fastlane.tools/best-practices/xcodebuild-formatters/)
   - xcprettyArgs: **DEPRECATED!** Use `xcodebuild_formatter: ''` instead - Additional xcpretty arguments
   - disableXcpretty: Disable xcpretty formatting of build
   - suppressXcodeOutput: Suppress the output of xcodebuild to stdout. Output is still saved in buildlog_path
   - useSystemScm: Lets xcodebuild use system's scm configuration
 */
public func captureScreenshots(workspace: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               project: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               xcargs: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               xcconfig: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               devices: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                               languages: [String] = ["en-US"],
                               launchArguments: [String] = [""],
                               outputDirectory: String = "screenshots",
                               outputSimulatorLogs: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                               iosVersion: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               skipOpenSummary: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                               skipHelperVersionCheck: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                               clearPreviousScreenshots: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                               reinstallApp: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                               eraseSimulator: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                               headless: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                               overrideStatusBar: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                               overrideStatusBarArguments: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               localizeSimulator: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                               darkMode: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                               appIdentifier: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               addPhotos: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                               addVideos: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                               htmlTemplate: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               buildlogPath: String = "~/Library/Logs/snapshot",
                               clean: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                               testWithoutBuilding: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                               configuration: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               sdk: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               scheme: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               numberOfRetries: Int = 1,
                               stopAfterFirstError: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                               derivedDataPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               resultBundle: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                               testTargetName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               namespaceLogFiles: Any? = nil,
                               concurrentSimulators: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                               disableSlideToType: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                               clonedSourcePackagesPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               skipPackageDependenciesResolution: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                               disablePackageAutomaticUpdates: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                               packageAuthorizationProvider: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               testplan: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               onlyTesting: Any? = nil,
                               skipTesting: Any? = nil,
                               xcodebuildFormatter: String = "xcbeautify",
                               xcprettyArgs: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               disableXcpretty: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                               suppressXcodeOutput: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                               useSystemScm: OptionalConfigValue<Bool> = .fastlaneDefault(false))
{
    let workspaceArg = workspace.asRubyArgument(name: "workspace", type: nil)
    let projectArg = project.asRubyArgument(name: "project", type: nil)
    let xcargsArg = xcargs.asRubyArgument(name: "xcargs", type: nil)
    let xcconfigArg = xcconfig.asRubyArgument(name: "xcconfig", type: nil)
    let devicesArg = devices.asRubyArgument(name: "devices", type: nil)
    let languagesArg = RubyCommand.Argument(name: "languages", value: languages, type: nil)
    let launchArgumentsArg = RubyCommand.Argument(name: "launch_arguments", value: launchArguments, type: nil)
    let outputDirectoryArg = RubyCommand.Argument(name: "output_directory", value: outputDirectory, type: nil)
    let outputSimulatorLogsArg = outputSimulatorLogs.asRubyArgument(name: "output_simulator_logs", type: nil)
    let iosVersionArg = iosVersion.asRubyArgument(name: "ios_version", type: nil)
    let skipOpenSummaryArg = skipOpenSummary.asRubyArgument(name: "skip_open_summary", type: nil)
    let skipHelperVersionCheckArg = skipHelperVersionCheck.asRubyArgument(name: "skip_helper_version_check", type: nil)
    let clearPreviousScreenshotsArg = clearPreviousScreenshots.asRubyArgument(name: "clear_previous_screenshots", type: nil)
    let reinstallAppArg = reinstallApp.asRubyArgument(name: "reinstall_app", type: nil)
    let eraseSimulatorArg = eraseSimulator.asRubyArgument(name: "erase_simulator", type: nil)
    let headlessArg = headless.asRubyArgument(name: "headless", type: nil)
    let overrideStatusBarArg = overrideStatusBar.asRubyArgument(name: "override_status_bar", type: nil)
    let overrideStatusBarArgumentsArg = overrideStatusBarArguments.asRubyArgument(name: "override_status_bar_arguments", type: nil)
    let localizeSimulatorArg = localizeSimulator.asRubyArgument(name: "localize_simulator", type: nil)
    let darkModeArg = darkMode.asRubyArgument(name: "dark_mode", type: nil)
    let appIdentifierArg = appIdentifier.asRubyArgument(name: "app_identifier", type: nil)
    let addPhotosArg = addPhotos.asRubyArgument(name: "add_photos", type: nil)
    let addVideosArg = addVideos.asRubyArgument(name: "add_videos", type: nil)
    let htmlTemplateArg = htmlTemplate.asRubyArgument(name: "html_template", type: nil)
    let buildlogPathArg = RubyCommand.Argument(name: "buildlog_path", value: buildlogPath, type: nil)
    let cleanArg = clean.asRubyArgument(name: "clean", type: nil)
    let testWithoutBuildingArg = testWithoutBuilding.asRubyArgument(name: "test_without_building", type: nil)
    let configurationArg = configuration.asRubyArgument(name: "configuration", type: nil)
    let sdkArg = sdk.asRubyArgument(name: "sdk", type: nil)
    let schemeArg = scheme.asRubyArgument(name: "scheme", type: nil)
    let numberOfRetriesArg = RubyCommand.Argument(name: "number_of_retries", value: numberOfRetries, type: nil)
    let stopAfterFirstErrorArg = stopAfterFirstError.asRubyArgument(name: "stop_after_first_error", type: nil)
    let derivedDataPathArg = derivedDataPath.asRubyArgument(name: "derived_data_path", type: nil)
    let resultBundleArg = resultBundle.asRubyArgument(name: "result_bundle", type: nil)
    let testTargetNameArg = testTargetName.asRubyArgument(name: "test_target_name", type: nil)
    let namespaceLogFilesArg = RubyCommand.Argument(name: "namespace_log_files", value: namespaceLogFiles, type: nil)
    let concurrentSimulatorsArg = concurrentSimulators.asRubyArgument(name: "concurrent_simulators", type: nil)
    let disableSlideToTypeArg = disableSlideToType.asRubyArgument(name: "disable_slide_to_type", type: nil)
    let clonedSourcePackagesPathArg = clonedSourcePackagesPath.asRubyArgument(name: "cloned_source_packages_path", type: nil)
    let skipPackageDependenciesResolutionArg = skipPackageDependenciesResolution.asRubyArgument(name: "skip_package_dependencies_resolution", type: nil)
    let disablePackageAutomaticUpdatesArg = disablePackageAutomaticUpdates.asRubyArgument(name: "disable_package_automatic_updates", type: nil)
    let packageAuthorizationProviderArg = packageAuthorizationProvider.asRubyArgument(name: "package_authorization_provider", type: nil)
    let testplanArg = testplan.asRubyArgument(name: "testplan", type: nil)
    let onlyTestingArg = RubyCommand.Argument(name: "only_testing", value: onlyTesting, type: nil)
    let skipTestingArg = RubyCommand.Argument(name: "skip_testing", value: skipTesting, type: nil)
    let xcodebuildFormatterArg = RubyCommand.Argument(name: "xcodebuild_formatter", value: xcodebuildFormatter, type: nil)
    let xcprettyArgsArg = xcprettyArgs.asRubyArgument(name: "xcpretty_args", type: nil)
    let disableXcprettyArg = disableXcpretty.asRubyArgument(name: "disable_xcpretty", type: nil)
    let suppressXcodeOutputArg = suppressXcodeOutput.asRubyArgument(name: "suppress_xcode_output", type: nil)
    let useSystemScmArg = useSystemScm.asRubyArgument(name: "use_system_scm", type: nil)
    let array: [RubyCommand.Argument?] = [workspaceArg,
                                          projectArg,
                                          xcargsArg,
                                          xcconfigArg,
                                          devicesArg,
                                          languagesArg,
                                          launchArgumentsArg,
                                          outputDirectoryArg,
                                          outputSimulatorLogsArg,
                                          iosVersionArg,
                                          skipOpenSummaryArg,
                                          skipHelperVersionCheckArg,
                                          clearPreviousScreenshotsArg,
                                          reinstallAppArg,
                                          eraseSimulatorArg,
                                          headlessArg,
                                          overrideStatusBarArg,
                                          overrideStatusBarArgumentsArg,
                                          localizeSimulatorArg,
                                          darkModeArg,
                                          appIdentifierArg,
                                          addPhotosArg,
                                          addVideosArg,
                                          htmlTemplateArg,
                                          buildlogPathArg,
                                          cleanArg,
                                          testWithoutBuildingArg,
                                          configurationArg,
                                          sdkArg,
                                          schemeArg,
                                          numberOfRetriesArg,
                                          stopAfterFirstErrorArg,
                                          derivedDataPathArg,
                                          resultBundleArg,
                                          testTargetNameArg,
                                          namespaceLogFilesArg,
                                          concurrentSimulatorsArg,
                                          disableSlideToTypeArg,
                                          clonedSourcePackagesPathArg,
                                          skipPackageDependenciesResolutionArg,
                                          disablePackageAutomaticUpdatesArg,
                                          packageAuthorizationProviderArg,
                                          testplanArg,
                                          onlyTestingArg,
                                          skipTestingArg,
                                          xcodebuildFormatterArg,
                                          xcprettyArgsArg,
                                          disableXcprettyArg,
                                          suppressXcodeOutputArg,
                                          useSystemScmArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "capture_screenshots", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Runs `carthage` for your project

 - parameters:
   - command: Carthage command (one of: build, bootstrap, update, archive)
   - dependencies: Carthage dependencies to update, build or bootstrap
   - useSsh: Use SSH for downloading GitHub repositories
   - useSubmodules: Add dependencies as Git submodules
   - useNetrc: Use .netrc for downloading frameworks
   - useBinaries: Check out dependency repositories even when prebuilt frameworks exist
   - noCheckout: When bootstrapping Carthage do not checkout
   - noBuild: When bootstrapping Carthage do not build
   - noSkipCurrent: Don't skip building the Carthage project (in addition to its dependencies)
   - derivedData: Use derived data folder at path
   - verbose: Print xcodebuild output inline
   - platform: Define which platform to build for
   - cacheBuilds: By default Carthage will rebuild a dependency regardless of whether it's the same resolved version as before. Passing the --cache-builds will cause carthage to avoid rebuilding a dependency if it can
   - frameworks: Framework name or names to archive, could be applied only along with the archive command
   - output: Output name for the archive, could be applied only along with the archive command. Use following format *.framework.zip
   - configuration: Define which build configuration to use when building
   - toolchain: Define which xcodebuild toolchain to use when building
   - projectDirectory: Define the directory containing the Carthage project
   - newResolver: Use new resolver when resolving dependency graph
   - logPath: Path to the xcode build output
   - useXcframeworks: Create xcframework bundles instead of one framework per platform (requires Xcode 12+)
   - archive: Archive built frameworks from the current project
   - executable: Path to the `carthage` executable on your machine
 */
public func carthage(command: String = "bootstrap",
                     dependencies: [String] = [],
                     useSsh: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                     useSubmodules: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                     useNetrc: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                     useBinaries: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                     noCheckout: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                     noBuild: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                     noSkipCurrent: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                     derivedData: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     verbose: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                     platform: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     cacheBuilds: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                     frameworks: [String] = [],
                     output: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     configuration: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     toolchain: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     projectDirectory: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     newResolver: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                     logPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     useXcframeworks: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                     archive: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                     executable: String = "carthage")
{
    let commandArg = RubyCommand.Argument(name: "command", value: command, type: nil)
    let dependenciesArg = RubyCommand.Argument(name: "dependencies", value: dependencies, type: nil)
    let useSshArg = useSsh.asRubyArgument(name: "use_ssh", type: nil)
    let useSubmodulesArg = useSubmodules.asRubyArgument(name: "use_submodules", type: nil)
    let useNetrcArg = useNetrc.asRubyArgument(name: "use_netrc", type: nil)
    let useBinariesArg = useBinaries.asRubyArgument(name: "use_binaries", type: nil)
    let noCheckoutArg = noCheckout.asRubyArgument(name: "no_checkout", type: nil)
    let noBuildArg = noBuild.asRubyArgument(name: "no_build", type: nil)
    let noSkipCurrentArg = noSkipCurrent.asRubyArgument(name: "no_skip_current", type: nil)
    let derivedDataArg = derivedData.asRubyArgument(name: "derived_data", type: nil)
    let verboseArg = verbose.asRubyArgument(name: "verbose", type: nil)
    let platformArg = platform.asRubyArgument(name: "platform", type: nil)
    let cacheBuildsArg = cacheBuilds.asRubyArgument(name: "cache_builds", type: nil)
    let frameworksArg = RubyCommand.Argument(name: "frameworks", value: frameworks, type: nil)
    let outputArg = output.asRubyArgument(name: "output", type: nil)
    let configurationArg = configuration.asRubyArgument(name: "configuration", type: nil)
    let toolchainArg = toolchain.asRubyArgument(name: "toolchain", type: nil)
    let projectDirectoryArg = projectDirectory.asRubyArgument(name: "project_directory", type: nil)
    let newResolverArg = newResolver.asRubyArgument(name: "new_resolver", type: nil)
    let logPathArg = logPath.asRubyArgument(name: "log_path", type: nil)
    let useXcframeworksArg = useXcframeworks.asRubyArgument(name: "use_xcframeworks", type: nil)
    let archiveArg = archive.asRubyArgument(name: "archive", type: nil)
    let executableArg = RubyCommand.Argument(name: "executable", value: executable, type: nil)
    let array: [RubyCommand.Argument?] = [commandArg,
                                          dependenciesArg,
                                          useSshArg,
                                          useSubmodulesArg,
                                          useNetrcArg,
                                          useBinariesArg,
                                          noCheckoutArg,
                                          noBuildArg,
                                          noSkipCurrentArg,
                                          derivedDataArg,
                                          verboseArg,
                                          platformArg,
                                          cacheBuildsArg,
                                          frameworksArg,
                                          outputArg,
                                          configurationArg,
                                          toolchainArg,
                                          projectDirectoryArg,
                                          newResolverArg,
                                          logPathArg,
                                          useXcframeworksArg,
                                          archiveArg,
                                          executableArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "carthage", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Alias for the `get_certificates` action

 - parameters:
   - development: Create a development certificate instead of a distribution one
   - type: Create specific certificate type (takes precedence over :development)
   - force: Create a certificate even if an existing certificate exists
   - generateAppleCerts: Create a certificate type for Xcode 11 and later (Apple Development or Apple Distribution)
   - apiKeyPath: Path to your App Store Connect API Key JSON file (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-json-file)
   - apiKey: Your App Store Connect API Key information (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-hash-option)
   - username: Your Apple ID Username
   - teamId: The ID of your Developer Portal team if you're in multiple teams
   - teamName: The name of your Developer Portal team if you're in multiple teams
   - filename: The filename of certificate to store
   - outputPath: The path to a directory in which all certificates and private keys should be stored
   - keychainPath: Path to a custom keychain
   - keychainPassword: This might be required the first time you access certificates on a new mac. For the login/default keychain this is your macOS account password
   - skipSetPartitionList: Skips setting the partition list (which can sometimes take a long time). Setting the partition list is usually needed to prevent Xcode from prompting to allow a cert to be used for signing
   - platform: Set the provisioning profile's platform (ios, macos, tvos)

 **Important**: It is recommended to use [match](https://docs.fastlane.tools/actions/match/) according to the [codesigning.guide](https://codesigning.guide) for generating and maintaining your certificates. Use _cert_ directly only if you want full control over what's going on and know more about codesigning.
 Use this action to download the latest code signing identity.
 */
public func cert(development: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                 type: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                 force: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                 generateAppleCerts: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                 apiKeyPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                 apiKey: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                 username: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                 teamId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                 teamName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                 filename: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                 outputPath: String = ".",
                 keychainPath: String,
                 keychainPassword: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                 skipSetPartitionList: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                 platform: String = "ios")
{
    let developmentArg = development.asRubyArgument(name: "development", type: nil)
    let typeArg = type.asRubyArgument(name: "type", type: nil)
    let forceArg = force.asRubyArgument(name: "force", type: nil)
    let generateAppleCertsArg = generateAppleCerts.asRubyArgument(name: "generate_apple_certs", type: nil)
    let apiKeyPathArg = apiKeyPath.asRubyArgument(name: "api_key_path", type: nil)
    let apiKeyArg = apiKey.asRubyArgument(name: "api_key", type: nil)
    let usernameArg = username.asRubyArgument(name: "username", type: nil)
    let teamIdArg = teamId.asRubyArgument(name: "team_id", type: nil)
    let teamNameArg = teamName.asRubyArgument(name: "team_name", type: nil)
    let filenameArg = filename.asRubyArgument(name: "filename", type: nil)
    let outputPathArg = RubyCommand.Argument(name: "output_path", value: outputPath, type: nil)
    let keychainPathArg = RubyCommand.Argument(name: "keychain_path", value: keychainPath, type: nil)
    let keychainPasswordArg = keychainPassword.asRubyArgument(name: "keychain_password", type: nil)
    let skipSetPartitionListArg = skipSetPartitionList.asRubyArgument(name: "skip_set_partition_list", type: nil)
    let platformArg = RubyCommand.Argument(name: "platform", value: platform, type: nil)
    let array: [RubyCommand.Argument?] = [developmentArg,
                                          typeArg,
                                          forceArg,
                                          generateAppleCertsArg,
                                          apiKeyPathArg,
                                          apiKeyArg,
                                          usernameArg,
                                          teamIdArg,
                                          teamNameArg,
                                          filenameArg,
                                          outputPathArg,
                                          keychainPathArg,
                                          keychainPasswordArg,
                                          skipSetPartitionListArg,
                                          platformArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "cert", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Collect git commit messages into a changelog

 - parameters:
   - between: Array containing two Git revision values between which to collect messages, you mustn't use it with :commits_count key at the same time
   - commitsCount: Number of commits to include in changelog, you mustn't use it with :between key at the same time
   - path: Path of the git repository
   - pretty: The format applied to each commit while generating the collected value
   - dateFormat: The date format applied to each commit while generating the collected value
   - ancestryPath: Whether or not to use ancestry-path param
   - tagMatchPattern: A glob(7) pattern to match against when finding the last git tag
   - matchLightweightTag: Whether or not to match a lightweight tag when searching for the last one
   - quiet: Whether or not to disable changelog output
   - includeMerges: **DEPRECATED!** Use `:merge_commit_filtering` instead - Whether or not to include any commits that are merges
   - mergeCommitFiltering: Controls inclusion of merge commits when collecting the changelog. Valid values: 'include_merges', 'exclude_merges', 'only_include_merges'
   - appPath: Scopes the changelog to a specific subdirectory of the repository

 - returns: Returns a String containing your formatted git commits

 By default, messages will be collected back to the last tag, but the range can be controlled
 */
@discardableResult public func changelogFromGitCommits(between: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                                                       commitsCount: OptionalConfigValue<Int?> = .fastlaneDefault(nil),
                                                       path: String = "./",
                                                       pretty: String = "%B",
                                                       dateFormat: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                                       ancestryPath: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                                       tagMatchPattern: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                                       matchLightweightTag: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                                                       quiet: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                                       includeMerges: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                                       mergeCommitFiltering: String = "include_merges",
                                                       appPath: OptionalConfigValue<String?> = .fastlaneDefault(nil)) -> String
{
    let betweenArg = between.asRubyArgument(name: "between", type: nil)
    let commitsCountArg = commitsCount.asRubyArgument(name: "commits_count", type: nil)
    let pathArg = RubyCommand.Argument(name: "path", value: path, type: nil)
    let prettyArg = RubyCommand.Argument(name: "pretty", value: pretty, type: nil)
    let dateFormatArg = dateFormat.asRubyArgument(name: "date_format", type: nil)
    let ancestryPathArg = ancestryPath.asRubyArgument(name: "ancestry_path", type: nil)
    let tagMatchPatternArg = tagMatchPattern.asRubyArgument(name: "tag_match_pattern", type: nil)
    let matchLightweightTagArg = matchLightweightTag.asRubyArgument(name: "match_lightweight_tag", type: nil)
    let quietArg = quiet.asRubyArgument(name: "quiet", type: nil)
    let includeMergesArg = includeMerges.asRubyArgument(name: "include_merges", type: nil)
    let mergeCommitFilteringArg = RubyCommand.Argument(name: "merge_commit_filtering", value: mergeCommitFiltering, type: nil)
    let appPathArg = appPath.asRubyArgument(name: "app_path", type: nil)
    let array: [RubyCommand.Argument?] = [betweenArg,
                                          commitsCountArg,
                                          pathArg,
                                          prettyArg,
                                          dateFormatArg,
                                          ancestryPathArg,
                                          tagMatchPatternArg,
                                          matchLightweightTagArg,
                                          quietArg,
                                          includeMergesArg,
                                          mergeCommitFilteringArg,
                                          appPathArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "changelog_from_git_commits", className: nil, args: args)
    return runner.executeCommand(command)
}

/**
 Send a success/error message to [ChatWork](https://go.chatwork.com/)

 - parameters:
   - apiToken: ChatWork API Token
   - message: The message to post on ChatWork
   - roomid: The room ID
   - success: Was this build successful? (true/false)

 Information on how to obtain an API token: [http://developer.chatwork.com/ja/authenticate.html](http://developer.chatwork.com/ja/authenticate.html)
 */
public func chatwork(apiToken: String,
                     message: String,
                     roomid: Int,
                     success: OptionalConfigValue<Bool> = .fastlaneDefault(true))
{
    let apiTokenArg = RubyCommand.Argument(name: "api_token", value: apiToken, type: nil)
    let messageArg = RubyCommand.Argument(name: "message", value: message, type: nil)
    let roomidArg = RubyCommand.Argument(name: "roomid", value: roomid, type: nil)
    let successArg = success.asRubyArgument(name: "success", type: nil)
    let array: [RubyCommand.Argument?] = [apiTokenArg,
                                          messageArg,
                                          roomidArg,
                                          successArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "chatwork", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Check your app's metadata before you submit your app to review (via _precheck_)

 - parameters:
   - apiKeyPath: Path to your App Store Connect API Key JSON file (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-json-file)
   - apiKey: Your App Store Connect API Key information (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-hash-option)
   - appIdentifier: The bundle identifier of your app
   - username: Your Apple ID Username
   - teamId: The ID of your App Store Connect team if you're in multiple teams
   - teamName: The name of your App Store Connect team if you're in multiple teams
   - platform: The platform to use (optional)
   - defaultRuleLevel: The default rule level unless otherwise configured
   - includeInAppPurchases: Should check in-app purchases?
   - useLive: Should force check live app?
   - negativeAppleSentiment: mentioning  in a way that could be considered negative
   - placeholderText: using placeholder text (e.g.:"lorem ipsum", "text here", etc...)
   - otherPlatforms: mentioning other platforms, like Android or Blackberry
   - futureFunctionality: mentioning features or content that is not currently available in your app
   - testWords: using text indicating this release is a test
   - curseWords: including words that might be considered objectionable
   - freeStuffInIap: using text indicating that your IAP is free
   - customText: mentioning any of the user-specified words passed to custom_text(data: [words])
   - copyrightDate: using a copyright date that is any different from this current year, or missing a date
   - unreachableUrls: unreachable URLs in app metadata

 - returns: true if precheck passes, else, false

 More information: https://fastlane.tools/precheck
 */
@discardableResult public func checkAppStoreMetadata(apiKeyPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                                     apiKey: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                                                     appIdentifier: String,
                                                     username: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                                     teamId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                                     teamName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                                     platform: String = "ios",
                                                     defaultRuleLevel: String = "error",
                                                     includeInAppPurchases: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                                                     useLive: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                                     negativeAppleSentiment: Any? = nil,
                                                     placeholderText: Any? = nil,
                                                     otherPlatforms: Any? = nil,
                                                     futureFunctionality: Any? = nil,
                                                     testWords: Any? = nil,
                                                     curseWords: Any? = nil,
                                                     freeStuffInIap: Any? = nil,
                                                     customText: Any? = nil,
                                                     copyrightDate: Any? = nil,
                                                     unreachableUrls: Any? = nil) -> Bool
{
    let apiKeyPathArg = apiKeyPath.asRubyArgument(name: "api_key_path", type: nil)
    let apiKeyArg = apiKey.asRubyArgument(name: "api_key", type: nil)
    let appIdentifierArg = RubyCommand.Argument(name: "app_identifier", value: appIdentifier, type: nil)
    let usernameArg = username.asRubyArgument(name: "username", type: nil)
    let teamIdArg = teamId.asRubyArgument(name: "team_id", type: nil)
    let teamNameArg = teamName.asRubyArgument(name: "team_name", type: nil)
    let platformArg = RubyCommand.Argument(name: "platform", value: platform, type: nil)
    let defaultRuleLevelArg = RubyCommand.Argument(name: "default_rule_level", value: defaultRuleLevel, type: nil)
    let includeInAppPurchasesArg = includeInAppPurchases.asRubyArgument(name: "include_in_app_purchases", type: nil)
    let useLiveArg = useLive.asRubyArgument(name: "use_live", type: nil)
    let negativeAppleSentimentArg = RubyCommand.Argument(name: "negative_apple_sentiment", value: negativeAppleSentiment, type: nil)
    let placeholderTextArg = RubyCommand.Argument(name: "placeholder_text", value: placeholderText, type: nil)
    let otherPlatformsArg = RubyCommand.Argument(name: "other_platforms", value: otherPlatforms, type: nil)
    let futureFunctionalityArg = RubyCommand.Argument(name: "future_functionality", value: futureFunctionality, type: nil)
    let testWordsArg = RubyCommand.Argument(name: "test_words", value: testWords, type: nil)
    let curseWordsArg = RubyCommand.Argument(name: "curse_words", value: curseWords, type: nil)
    let freeStuffInIapArg = RubyCommand.Argument(name: "free_stuff_in_iap", value: freeStuffInIap, type: nil)
    let customTextArg = RubyCommand.Argument(name: "custom_text", value: customText, type: nil)
    let copyrightDateArg = RubyCommand.Argument(name: "copyright_date", value: copyrightDate, type: nil)
    let unreachableUrlsArg = RubyCommand.Argument(name: "unreachable_urls", value: unreachableUrls, type: nil)
    let array: [RubyCommand.Argument?] = [apiKeyPathArg,
                                          apiKeyArg,
                                          appIdentifierArg,
                                          usernameArg,
                                          teamIdArg,
                                          teamNameArg,
                                          platformArg,
                                          defaultRuleLevelArg,
                                          includeInAppPurchasesArg,
                                          useLiveArg,
                                          negativeAppleSentimentArg,
                                          placeholderTextArg,
                                          otherPlatformsArg,
                                          futureFunctionalityArg,
                                          testWordsArg,
                                          curseWordsArg,
                                          freeStuffInIapArg,
                                          customTextArg,
                                          copyrightDateArg,
                                          unreachableUrlsArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "check_app_store_metadata", className: nil, args: args)
    return parseBool(fromString: runner.executeCommand(command))
}

/**
 Deletes files created as result of running gym, cert, sigh or download_dsyms

 - parameter excludePattern: Exclude all files from clearing that match the given Regex pattern: e.g. '.*.mobileprovision'

 This action deletes the files that get created in your repo as a result of running the _gym_ and _sigh_ commands. It doesn't delete the `fastlane/report.xml` though, this is probably more suited for the .gitignore.

 Useful if you quickly want to send out a test build by dropping down to the command line and typing something like `fastlane beta`, without leaving your repo in a messy state afterwards.
 */
public func cleanBuildArtifacts(excludePattern: OptionalConfigValue<String?> = .fastlaneDefault(nil)) {
    let excludePatternArg = excludePattern.asRubyArgument(name: "exclude_pattern", type: nil)
    let array: [RubyCommand.Argument?] = [excludePatternArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "clean_build_artifacts", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Remove the cache for pods

 - parameters:
   - name: Pod name to be removed from cache
   - noAnsi: Show output without ANSI codes
   - verbose: Show more debugging information
   - silent: Show nothing
   - allowRoot: Allows CocoaPods to run as root
 */
public func cleanCocoapodsCache(name: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                noAnsi: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                verbose: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                silent: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                allowRoot: OptionalConfigValue<Bool> = .fastlaneDefault(false))
{
    let nameArg = name.asRubyArgument(name: "name", type: nil)
    let noAnsiArg = noAnsi.asRubyArgument(name: "no_ansi", type: nil)
    let verboseArg = verbose.asRubyArgument(name: "verbose", type: nil)
    let silentArg = silent.asRubyArgument(name: "silent", type: nil)
    let allowRootArg = allowRoot.asRubyArgument(name: "allow_root", type: nil)
    let array: [RubyCommand.Argument?] = [nameArg,
                                          noAnsiArg,
                                          verboseArg,
                                          silentArg,
                                          allowRootArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "clean_cocoapods_cache", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Deletes the Xcode Derived Data

 - parameter derivedDataPath: Custom path for derivedData

 Deletes the Derived Data from path set on Xcode or a supplied path
 */
public func clearDerivedData(derivedDataPath: String = "~/Library/Developer/Xcode/DerivedData") {
    let derivedDataPathArg = RubyCommand.Argument(name: "derived_data_path", value: derivedDataPath, type: nil)
    let array: [RubyCommand.Argument?] = [derivedDataPathArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "clear_derived_data", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Copies a given string into the clipboard. Works only on macOS

 - parameter value: The string that should be copied into the clipboard
 */
public func clipboard(value: String) {
    let valueArg = RubyCommand.Argument(name: "value", value: value, type: nil)
    let array: [RubyCommand.Argument?] = [valueArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "clipboard", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Generates a Code Count that can be read by Jenkins (xml format)

 - parameters:
   - binaryPath: Where the cloc binary lives on your system (full path including 'cloc')
   - excludeDir: Comma separated list of directories to exclude
   - outputDirectory: Where to put the generated report file
   - sourceDirectory: Where to look for the source code (relative to the project root folder)
   - xml: Should we generate an XML File (if false, it will generate a plain text file)?

 This action will run cloc to generate a SLOC report that the Jenkins SLOCCount plugin can read.
 See [https://wiki.jenkins-ci.org/display/JENKINS/SLOCCount+Plugin](https://wiki.jenkins-ci.org/display/JENKINS/SLOCCount+Plugin) and [https://github.com/AlDanial/cloc](https://github.com/AlDanial/cloc) for more information.
 */
public func cloc(binaryPath: String = "/usr/local/bin/cloc",
                 excludeDir: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                 outputDirectory: String = "build",
                 sourceDirectory: String = "",
                 xml: OptionalConfigValue<Bool> = .fastlaneDefault(true))
{
    let binaryPathArg = RubyCommand.Argument(name: "binary_path", value: binaryPath, type: nil)
    let excludeDirArg = excludeDir.asRubyArgument(name: "exclude_dir", type: nil)
    let outputDirectoryArg = RubyCommand.Argument(name: "output_directory", value: outputDirectory, type: nil)
    let sourceDirectoryArg = RubyCommand.Argument(name: "source_directory", value: sourceDirectory, type: nil)
    let xmlArg = xml.asRubyArgument(name: "xml", type: nil)
    let array: [RubyCommand.Argument?] = [binaryPathArg,
                                          excludeDirArg,
                                          outputDirectoryArg,
                                          sourceDirectoryArg,
                                          xmlArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "cloc", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Print a Club Mate in your build output
 */
public func clubmate() {
    let args: [RubyCommand.Argument] = []
    let command = RubyCommand(commandID: "", methodName: "clubmate", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Runs `pod install` for the project

 - parameters:
   - repoUpdate: Add `--repo-update` flag to `pod install` command
   - cleanInstall: Execute a full pod installation ignoring the content of the project cache
   - silent: Execute command without logging output
   - verbose: Show more debugging information
   - ansi: Show output with ANSI codes
   - useBundleExec: Use bundle exec when there is a Gemfile presented
   - podfile: Explicitly specify the path to the Cocoapods' Podfile. You can either set it to the Podfile's path or to the folder containing the Podfile file
   - errorCallback: A callback invoked with the command output if there is a non-zero exit status
   - tryRepoUpdateOnError: Retry with --repo-update if action was finished with error
   - deployment: Disallow any changes to the Podfile or the Podfile.lock during installation
   - allowRoot: Allows CocoaPods to run as root
   - clean: **DEPRECATED!** (Option renamed as clean_install) Remove SCM directories
   - integrate: **DEPRECATED!** (Option removed from cocoapods) Integrate the Pods libraries into the Xcode project(s)

 If you use [CocoaPods](http://cocoapods.org) you can use the `cocoapods` integration to run `pod install` before building your app.
 */
public func cocoapods(repoUpdate: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                      cleanInstall: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                      silent: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                      verbose: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                      ansi: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                      useBundleExec: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                      podfile: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      errorCallback: ((String) -> Void)? = nil,
                      tryRepoUpdateOnError: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                      deployment: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                      allowRoot: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                      clean: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                      integrate: OptionalConfigValue<Bool> = .fastlaneDefault(true))
{
    let repoUpdateArg = repoUpdate.asRubyArgument(name: "repo_update", type: nil)
    let cleanInstallArg = cleanInstall.asRubyArgument(name: "clean_install", type: nil)
    let silentArg = silent.asRubyArgument(name: "silent", type: nil)
    let verboseArg = verbose.asRubyArgument(name: "verbose", type: nil)
    let ansiArg = ansi.asRubyArgument(name: "ansi", type: nil)
    let useBundleExecArg = useBundleExec.asRubyArgument(name: "use_bundle_exec", type: nil)
    let podfileArg = podfile.asRubyArgument(name: "podfile", type: nil)
    let errorCallbackArg = RubyCommand.Argument(name: "error_callback", value: errorCallback, type: .stringClosure)
    let tryRepoUpdateOnErrorArg = tryRepoUpdateOnError.asRubyArgument(name: "try_repo_update_on_error", type: nil)
    let deploymentArg = deployment.asRubyArgument(name: "deployment", type: nil)
    let allowRootArg = allowRoot.asRubyArgument(name: "allow_root", type: nil)
    let cleanArg = clean.asRubyArgument(name: "clean", type: nil)
    let integrateArg = integrate.asRubyArgument(name: "integrate", type: nil)
    let array: [RubyCommand.Argument?] = [repoUpdateArg,
                                          cleanInstallArg,
                                          silentArg,
                                          verboseArg,
                                          ansiArg,
                                          useBundleExecArg,
                                          podfileArg,
                                          errorCallbackArg,
                                          tryRepoUpdateOnErrorArg,
                                          deploymentArg,
                                          allowRootArg,
                                          cleanArg,
                                          integrateArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "cocoapods", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
  This will commit a file directly on GitHub via the API

  - parameters:
    - repositoryName: The path to your repo, e.g. 'fastlane/fastlane'
    - serverUrl: The server url. e.g. 'https://your.internal.github.host/api/v3' (Default: 'https://api.github.com')
    - apiToken: Personal API Token for GitHub - generate one at https://github.com/settings/tokens
    - apiBearer: Use a Bearer authorization token. Usually generated by GitHub Apps, e.g. GitHub Actions GITHUB_TOKEN environment variable
    - branch: The branch that the file should be committed on (default: master)
    - path: The relative path to your file from project root e.g. assets/my_app.xcarchive
    - message: The commit message. Defaults to the file name
    - secure: Optionally disable secure requests (ssl_verify_peer)

  - returns: A hash containing all relevant information for this commit
 Access things like 'html_url', 'sha', 'message'

  Commits a file directly to GitHub. You must provide your GitHub Personal token (get one from [https://github.com/settings/tokens/new](https://github.com/settings/tokens/new)), the repository name and the relative file path from the root git project.
  Out parameters provide the commit sha created, which can be used for later usage for examples such as releases, the direct download link and the full response JSON.
  Documentation: [https://developer.github.com/v3/repos/contents/#create-a-file](https://developer.github.com/v3/repos/contents/#create-a-file).
 */
@discardableResult public func commitGithubFile(repositoryName: String,
                                                serverUrl: String = "https://api.github.com",
                                                apiToken: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                                apiBearer: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                                branch: String = "master",
                                                path: String,
                                                message: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                                secure: OptionalConfigValue<Bool> = .fastlaneDefault(true)) -> [String: String]
{
    let repositoryNameArg = RubyCommand.Argument(name: "repository_name", value: repositoryName, type: nil)
    let serverUrlArg = RubyCommand.Argument(name: "server_url", value: serverUrl, type: nil)
    let apiTokenArg = apiToken.asRubyArgument(name: "api_token", type: nil)
    let apiBearerArg = apiBearer.asRubyArgument(name: "api_bearer", type: nil)
    let branchArg = RubyCommand.Argument(name: "branch", value: branch, type: nil)
    let pathArg = RubyCommand.Argument(name: "path", value: path, type: nil)
    let messageArg = message.asRubyArgument(name: "message", type: nil)
    let secureArg = secure.asRubyArgument(name: "secure", type: nil)
    let array: [RubyCommand.Argument?] = [repositoryNameArg,
                                          serverUrlArg,
                                          apiTokenArg,
                                          apiBearerArg,
                                          branchArg,
                                          pathArg,
                                          messageArg,
                                          secureArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "commit_github_file", className: nil, args: args)
    return parseDictionary(fromString: runner.executeCommand(command))
}

/**
 Creates a 'Version Bump' commit. Run after `increment_build_number`

 - parameters:
   - message: The commit message when committing the version bump
   - xcodeproj: The path to your project file (Not the workspace). If you have only one, this is optional
   - force: Forces the commit, even if other files than the ones containing the version number have been modified
   - settings: Include Settings.bundle/Root.plist with version bump
   - ignore: A regular expression used to filter matched plist files to be modified
   - include: A list of extra files to be included in the version bump (string array or comma-separated string)
   - noVerify: Whether or not to use --no-verify

 This action will create a 'Version Bump' commit in your repo. Useful in conjunction with `increment_build_number`.
 It checks the repo to make sure that only the relevant files have changed. These are the files that `increment_build_number` (`agvtool`) touches:|
 |
 >- All `.plist` files|
 - The `.xcodeproj/project.pbxproj` file|
 >|
 Then commits those files to the repo.
 Customize the message with the `:message` option. It defaults to 'Version Bump'.
 If you have other uncommitted changes in your repo, this action will fail. If you started off in a clean repo, and used the _ipa_ and or _sigh_ actions, then you can use the [clean_build_artifacts](https://docs.fastlane.tools/actions/clean_build_artifacts/) action to clean those temporary files up before running this action.
 */
public func commitVersionBump(message: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                              xcodeproj: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                              force: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                              settings: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                              ignore: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                              include: [String] = [],
                              noVerify: OptionalConfigValue<Bool> = .fastlaneDefault(false))
{
    let messageArg = message.asRubyArgument(name: "message", type: nil)
    let xcodeprojArg = xcodeproj.asRubyArgument(name: "xcodeproj", type: nil)
    let forceArg = force.asRubyArgument(name: "force", type: nil)
    let settingsArg = settings.asRubyArgument(name: "settings", type: nil)
    let ignoreArg = ignore.asRubyArgument(name: "ignore", type: nil)
    let includeArg = RubyCommand.Argument(name: "include", value: include, type: nil)
    let noVerifyArg = noVerify.asRubyArgument(name: "no_verify", type: nil)
    let array: [RubyCommand.Argument?] = [messageArg,
                                          xcodeprojArg,
                                          forceArg,
                                          settingsArg,
                                          ignoreArg,
                                          includeArg,
                                          noVerifyArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "commit_version_bump", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Copy and save your build artifacts (useful when you use reset_git_repo)

 - parameters:
   - keepOriginal: Set this to false if you want move, rather than copy, the found artifacts
   - targetPath: The directory in which you want your artifacts placed
   - artifacts: An array of file patterns of the files/folders you want to preserve
   - failOnMissing: Fail when a source file isn't found

 This action copies artifacts to a target directory. It's useful if you have a CI that will pick up these artifacts and attach them to the build. Useful e.g. for storing your `.ipa`s, `.dSYM.zip`s, `.mobileprovision`s, `.cert`s.
 Make sure your `:target_path` is ignored from git, and if you use `reset_git_repo`, make sure the artifacts are added to the exclude list.
 */
public func copyArtifacts(keepOriginal: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                          targetPath: String = "artifacts",
                          artifacts: [String] = [],
                          failOnMissing: OptionalConfigValue<Bool> = .fastlaneDefault(false))
{
    let keepOriginalArg = keepOriginal.asRubyArgument(name: "keep_original", type: nil)
    let targetPathArg = RubyCommand.Argument(name: "target_path", value: targetPath, type: nil)
    let artifactsArg = RubyCommand.Argument(name: "artifacts", value: artifacts, type: nil)
    let failOnMissingArg = failOnMissing.asRubyArgument(name: "fail_on_missing", type: nil)
    let array: [RubyCommand.Argument?] = [keepOriginalArg,
                                          targetPathArg,
                                          artifactsArg,
                                          failOnMissingArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "copy_artifacts", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Create Managed Google Play Apps

 - parameters:
   - jsonKey: The path to a file containing service account JSON, used to authenticate with Google
   - jsonKeyData: The raw service account JSON data used to authenticate with Google
   - developerAccountId: The ID of your Google Play Console account. Can be obtained from the URL when you log in (`https://play.google.com/apps/publish/?account=...` or when you 'Obtain private app publishing rights' (https://developers.google.com/android/work/play/custom-app-api/get-started#retrieve_the_developer_account_id)
   - apk: Path to the APK file to upload
   - appTitle: App Title
   - language: Default app language (e.g. 'en_US')
   - rootUrl: Root URL for the Google Play API. The provided URL will be used for API calls in place of https://www.googleapis.com/
   - timeout: Timeout for read, open, and send (in seconds)

 Create new apps on Managed Google Play.
 */
public func createAppOnManagedPlayStore(jsonKey: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        jsonKeyData: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        developerAccountId: String,
                                        apk: String,
                                        appTitle: String,
                                        language: String = "en_US",
                                        rootUrl: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        timeout: Int = 300)
{
    let jsonKeyArg = jsonKey.asRubyArgument(name: "json_key", type: nil)
    let jsonKeyDataArg = jsonKeyData.asRubyArgument(name: "json_key_data", type: nil)
    let developerAccountIdArg = RubyCommand.Argument(name: "developer_account_id", value: developerAccountId, type: nil)
    let apkArg = RubyCommand.Argument(name: "apk", value: apk, type: nil)
    let appTitleArg = RubyCommand.Argument(name: "app_title", value: appTitle, type: nil)
    let languageArg = RubyCommand.Argument(name: "language", value: language, type: nil)
    let rootUrlArg = rootUrl.asRubyArgument(name: "root_url", type: nil)
    let timeoutArg = RubyCommand.Argument(name: "timeout", value: timeout, type: nil)
    let array: [RubyCommand.Argument?] = [jsonKeyArg,
                                          jsonKeyDataArg,
                                          developerAccountIdArg,
                                          apkArg,
                                          appTitleArg,
                                          languageArg,
                                          rootUrlArg,
                                          timeoutArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "create_app_on_managed_play_store", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Creates the given application on iTC and the Dev Portal (via _produce_)

 - parameters:
   - username: Your Apple ID Username
   - appIdentifier: App Identifier (Bundle ID, e.g. com.krausefx.app)
   - bundleIdentifierSuffix: App Identifier Suffix (Ignored if App Identifier does not end with .*)
   - appName: App Name
   - appVersion: Initial version number (e.g. '1.0')
   - sku: SKU Number (e.g. '1234')
   - platform: The platform to use (optional)
   - platforms: The platforms to use (optional)
   - language: Primary Language (e.g. 'en-US', 'fr-FR')
   - companyName: The name of your company. It's used to set company name on App Store Connect team's app pages. Only required if it's the first app you create
   - skipItc: Skip the creation of the app on App Store Connect
   - itcUsers: Array of App Store Connect users. If provided, you can limit access to this newly created app for users with the App Manager, Developer, Marketer or Sales roles
   - enabledFeatures: **DEPRECATED!** Please use `enable_services` instead - Array with Spaceship App Services
   - enableServices: Array with Spaceship App Services (e.g. access_wifi: (on|off), app_attest: (on|off), app_group: (on|off), apple_pay: (on|off), associated_domains: (on|off), auto_fill_credential: (on|off), class_kit: (on|off), icloud: (legacy|cloudkit), custom_network_protocol: (on|off), data_protection: (complete|unlessopen|untilfirstauth), extended_virtual_address_space: (on|off), family_controls: (on|off), file_provider_testing_mode: (on|off), fonts: (on|off), game_center: (ios|mac), health_kit: (on|off), hls_interstitial_preview: (on|off), home_kit: (on|off), hotspot: (on|off), in_app_purchase: (on|off), inter_app_audio: (on|off), low_latency_hls: (on|off), managed_associated_domains: (on|off), maps: (on|off), multipath: (on|off), network_extension: (on|off), nfc_tag_reading: (on|off), personal_vpn: (on|off), passbook: (on|off), push_notification: (on|off), sign_in_with_apple: (on), siri_kit: (on|off), system_extension: (on|off), user_management: (on|off), vpn_configuration: (on|off), wallet: (on|off), wireless_accessory: (on|off), car_play_audio_app: (on|off), car_play_messaging_app: (on|off), car_play_navigation_app: (on|off), car_play_voip_calling_app: (on|off), critical_alerts: (on|off), hotspot_helper: (on|off), driver_kit: (on|off), driver_kit_endpoint_security: (on|off), driver_kit_family_hid_device: (on|off), driver_kit_family_networking: (on|off), driver_kit_family_serial: (on|off), driver_kit_hid_event_service: (on|off), driver_kit_transport_hid: (on|off), multitasking_camera_access: (on|off), sf_universal_link_api: (on|off), vp9_decoder: (on|off), music_kit: (on|off), shazam_kit: (on|off), communication_notifications: (on|off), group_activities: (on|off), health_kit_estimate_recalibration: (on|off), time_sensitive_notifications: (on|off))
   - skipDevcenter: Skip the creation of the app on the Apple Developer Portal
   - teamId: The ID of your Developer Portal team if you're in multiple teams
   - teamName: The name of your Developer Portal team if you're in multiple teams
   - itcTeamId: The ID of your App Store Connect team if you're in multiple teams
   - itcTeamName: The name of your App Store Connect team if you're in multiple teams

 Create new apps on App Store Connect and Apple Developer Portal via _produce_.
 If the app already exists, `create_app_online` will not do anything.
 For more information about _produce_, visit its documentation page: [https://docs.fastlane.tools/actions/produce/](https://docs.fastlane.tools/actions/produce/).
 */
public func createAppOnline(username: String,
                            appIdentifier: String,
                            bundleIdentifierSuffix: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            appName: String,
                            appVersion: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            sku: String,
                            platform: String = "ios",
                            platforms: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                            language: String = "English",
                            companyName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            skipItc: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                            itcUsers: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                            enabledFeatures: [String: Any] = [:],
                            enableServices: [String: Any] = [:],
                            skipDevcenter: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                            teamId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            teamName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            itcTeamId: Any? = nil,
                            itcTeamName: OptionalConfigValue<String?> = .fastlaneDefault(nil))
{
    let usernameArg = RubyCommand.Argument(name: "username", value: username, type: nil)
    let appIdentifierArg = RubyCommand.Argument(name: "app_identifier", value: appIdentifier, type: nil)
    let bundleIdentifierSuffixArg = bundleIdentifierSuffix.asRubyArgument(name: "bundle_identifier_suffix", type: nil)
    let appNameArg = RubyCommand.Argument(name: "app_name", value: appName, type: nil)
    let appVersionArg = appVersion.asRubyArgument(name: "app_version", type: nil)
    let skuArg = RubyCommand.Argument(name: "sku", value: sku, type: nil)
    let platformArg = RubyCommand.Argument(name: "platform", value: platform, type: nil)
    let platformsArg = platforms.asRubyArgument(name: "platforms", type: nil)
    let languageArg = RubyCommand.Argument(name: "language", value: language, type: nil)
    let companyNameArg = companyName.asRubyArgument(name: "company_name", type: nil)
    let skipItcArg = skipItc.asRubyArgument(name: "skip_itc", type: nil)
    let itcUsersArg = itcUsers.asRubyArgument(name: "itc_users", type: nil)
    let enabledFeaturesArg = RubyCommand.Argument(name: "enabled_features", value: enabledFeatures, type: nil)
    let enableServicesArg = RubyCommand.Argument(name: "enable_services", value: enableServices, type: nil)
    let skipDevcenterArg = skipDevcenter.asRubyArgument(name: "skip_devcenter", type: nil)
    let teamIdArg = teamId.asRubyArgument(name: "team_id", type: nil)
    let teamNameArg = teamName.asRubyArgument(name: "team_name", type: nil)
    let itcTeamIdArg = RubyCommand.Argument(name: "itc_team_id", value: itcTeamId, type: nil)
    let itcTeamNameArg = itcTeamName.asRubyArgument(name: "itc_team_name", type: nil)
    let array: [RubyCommand.Argument?] = [usernameArg,
                                          appIdentifierArg,
                                          bundleIdentifierSuffixArg,
                                          appNameArg,
                                          appVersionArg,
                                          skuArg,
                                          platformArg,
                                          platformsArg,
                                          languageArg,
                                          companyNameArg,
                                          skipItcArg,
                                          itcUsersArg,
                                          enabledFeaturesArg,
                                          enableServicesArg,
                                          skipDevcenterArg,
                                          teamIdArg,
                                          teamNameArg,
                                          itcTeamIdArg,
                                          itcTeamNameArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "create_app_online", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Create a new Keychain

 - parameters:
   - name: Keychain name
   - path: Path to keychain
   - password: Password for the keychain
   - defaultKeychain: Should the newly created Keychain be the new system default keychain
   - unlock: Unlock keychain after create
   - timeout: timeout interval in seconds. Set `0` if you want to specify "no time-out"
   - lockWhenSleeps: Lock keychain when the system sleeps
   - lockAfterTimeout: Lock keychain after timeout interval
   - addToSearchList: Add keychain to search list
   - requireCreate: Fail the action if the Keychain already exists
 */
public func createKeychain(name: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                           path: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                           password: String,
                           defaultKeychain: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                           unlock: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                           timeout: Int = 300,
                           lockWhenSleeps: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                           lockAfterTimeout: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                           addToSearchList: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                           requireCreate: OptionalConfigValue<Bool> = .fastlaneDefault(false))
{
    let nameArg = name.asRubyArgument(name: "name", type: nil)
    let pathArg = path.asRubyArgument(name: "path", type: nil)
    let passwordArg = RubyCommand.Argument(name: "password", value: password, type: nil)
    let defaultKeychainArg = defaultKeychain.asRubyArgument(name: "default_keychain", type: nil)
    let unlockArg = unlock.asRubyArgument(name: "unlock", type: nil)
    let timeoutArg = RubyCommand.Argument(name: "timeout", value: timeout, type: nil)
    let lockWhenSleepsArg = lockWhenSleeps.asRubyArgument(name: "lock_when_sleeps", type: nil)
    let lockAfterTimeoutArg = lockAfterTimeout.asRubyArgument(name: "lock_after_timeout", type: nil)
    let addToSearchListArg = addToSearchList.asRubyArgument(name: "add_to_search_list", type: nil)
    let requireCreateArg = requireCreate.asRubyArgument(name: "require_create", type: nil)
    let array: [RubyCommand.Argument?] = [nameArg,
                                          pathArg,
                                          passwordArg,
                                          defaultKeychainArg,
                                          unlockArg,
                                          timeoutArg,
                                          lockWhenSleepsArg,
                                          lockAfterTimeoutArg,
                                          addToSearchListArg,
                                          requireCreateArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "create_keychain", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 This will create a new pull request on GitHub

 - parameters:
   - apiToken: Personal API Token for GitHub - generate one at https://github.com/settings/tokens
   - apiBearer: Use a Bearer authorization token. Usually generated by GitHub Apps, e.g. GitHub Actions GITHUB_TOKEN environment variable
   - repo: The name of the repository you want to submit the pull request to
   - title: The title of the pull request
   - body: The contents of the pull request
   - draft: Indicates whether the pull request is a draft
   - labels: The labels for the pull request
   - milestone: The milestone ID (Integer) for the pull request
   - head: The name of the branch where your changes are implemented (defaults to the current branch name)
   - base: The name of the branch you want your changes pulled into (defaults to `master`)
   - apiUrl: The URL of GitHub API - used when the Enterprise (default to `https://api.github.com`)
   - assignees: The assignees for the pull request
   - reviewers: The reviewers (slug) for the pull request
   - teamReviewers: The team reviewers (slug) for the pull request

 - returns: The pull request URL when successful
 */
public func createPullRequest(apiToken: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                              apiBearer: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                              repo: String,
                              title: String,
                              body: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                              draft: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                              labels: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                              milestone: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                              head: String = "master",
                              base: String = "master",
                              apiUrl: String = "https://api.github.com",
                              assignees: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                              reviewers: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                              teamReviewers: OptionalConfigValue<[String]?> = .fastlaneDefault(nil))
{
    let apiTokenArg = apiToken.asRubyArgument(name: "api_token", type: nil)
    let apiBearerArg = apiBearer.asRubyArgument(name: "api_bearer", type: nil)
    let repoArg = RubyCommand.Argument(name: "repo", value: repo, type: nil)
    let titleArg = RubyCommand.Argument(name: "title", value: title, type: nil)
    let bodyArg = body.asRubyArgument(name: "body", type: nil)
    let draftArg = draft.asRubyArgument(name: "draft", type: nil)
    let labelsArg = labels.asRubyArgument(name: "labels", type: nil)
    let milestoneArg = milestone.asRubyArgument(name: "milestone", type: nil)
    let headArg = RubyCommand.Argument(name: "head", value: head, type: nil)
    let baseArg = RubyCommand.Argument(name: "base", value: base, type: nil)
    let apiUrlArg = RubyCommand.Argument(name: "api_url", value: apiUrl, type: nil)
    let assigneesArg = assignees.asRubyArgument(name: "assignees", type: nil)
    let reviewersArg = reviewers.asRubyArgument(name: "reviewers", type: nil)
    let teamReviewersArg = teamReviewers.asRubyArgument(name: "team_reviewers", type: nil)
    let array: [RubyCommand.Argument?] = [apiTokenArg,
                                          apiBearerArg,
                                          repoArg,
                                          titleArg,
                                          bodyArg,
                                          draftArg,
                                          labelsArg,
                                          milestoneArg,
                                          headArg,
                                          baseArg,
                                          apiUrlArg,
                                          assigneesArg,
                                          reviewersArg,
                                          teamReviewersArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "create_pull_request", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Package multiple build configs of a library/framework into a single xcframework

 - parameters:
   - frameworks: Frameworks (without dSYMs) to add to the target xcframework
   - frameworksWithDsyms: Frameworks (with dSYMs) to add to the target xcframework
   - libraries: Libraries (without headers or dSYMs) to add to the target xcframework
   - librariesWithHeadersOrDsyms: Libraries (with headers or dSYMs) to add to the target xcframework
   - output: The path to write the xcframework to
   - allowInternalDistribution: Specifies that the created xcframework contains information not suitable for public distribution

 Utility for packaging multiple build configurations of a given library
 or framework into a single xcframework.

 If you want to package several frameworks just provide one of:

   * An array containing the list of frameworks using the :frameworks parameter
     (if they have no associated dSYMs):
       ['FrameworkA.framework', 'FrameworkB.framework']

   * A hash containing the list of frameworks with their dSYMs using the
     :frameworks_with_dsyms parameter:
       {
         'FrameworkA.framework' => {},
         'FrameworkB.framework' => { dsyms: 'FrameworkB.framework.dSYM' }
       }

 If you want to package several libraries just provide one of:

   * An array containing the list of libraries using the :libraries parameter
     (if they have no associated headers or dSYMs):
       ['LibraryA.so', 'LibraryB.so']

   * A hash containing the list of libraries with their headers and dSYMs
     using the :libraries_with_headers_or_dsyms parameter:
       {
         'LibraryA.so' => { dsyms: 'libraryA.so.dSYM' },
         'LibraryB.so' => { headers: 'headers' }
       }

 Finally specify the location of the xcframework to be generated using the :output
 parameter.

 */
public func createXcframework(frameworks: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                              frameworksWithDsyms: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                              libraries: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                              librariesWithHeadersOrDsyms: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                              output: String,
                              allowInternalDistribution: OptionalConfigValue<Bool> = .fastlaneDefault(false))
{
    let frameworksArg = frameworks.asRubyArgument(name: "frameworks", type: nil)
    let frameworksWithDsymsArg = frameworksWithDsyms.asRubyArgument(name: "frameworks_with_dsyms", type: nil)
    let librariesArg = libraries.asRubyArgument(name: "libraries", type: nil)
    let librariesWithHeadersOrDsymsArg = librariesWithHeadersOrDsyms.asRubyArgument(name: "libraries_with_headers_or_dsyms", type: nil)
    let outputArg = RubyCommand.Argument(name: "output", value: output, type: nil)
    let allowInternalDistributionArg = allowInternalDistribution.asRubyArgument(name: "allow_internal_distribution", type: nil)
    let array: [RubyCommand.Argument?] = [frameworksArg,
                                          frameworksWithDsymsArg,
                                          librariesArg,
                                          librariesWithHeadersOrDsymsArg,
                                          outputArg,
                                          allowInternalDistributionArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "create_xcframework", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Runs `danger` for the project

 - parameters:
   - useBundleExec: Use bundle exec when there is a Gemfile presented
   - verbose: Show more debugging information
   - dangerId: The identifier of this Danger instance
   - dangerfile: The location of your Dangerfile
   - githubApiToken: GitHub API token for danger
   - githubEnterpriseHost: GitHub host URL for GitHub Enterprise
   - githubEnterpriseApiBaseUrl: GitHub API base URL for GitHub Enterprise
   - failOnErrors: Should always fail the build process, defaults to false
   - newComment: Makes Danger post a new comment instead of editing its previous one
   - removePreviousComments: Makes Danger remove all previous comment and create a new one in the end of the list
   - base: A branch/tag/commit to use as the base of the diff. [master|dev|stable]
   - head: A branch/tag/commit to use as the head. [master|dev|stable]
   - pr: Run danger on a specific pull request. e.g. "https://github.com/danger/danger/pull/518"
   - failIfNoPr: Fail Danger execution if no PR is found

 Formalize your Pull Request etiquette.
 More information: [https://github.com/danger/danger](https://github.com/danger/danger).
 */
public func danger(useBundleExec: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                   verbose: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                   dangerId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   dangerfile: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   githubApiToken: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   githubEnterpriseHost: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   githubEnterpriseApiBaseUrl: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   failOnErrors: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                   newComment: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                   removePreviousComments: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                   base: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   head: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   pr: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   failIfNoPr: OptionalConfigValue<Bool> = .fastlaneDefault(false))
{
    let useBundleExecArg = useBundleExec.asRubyArgument(name: "use_bundle_exec", type: nil)
    let verboseArg = verbose.asRubyArgument(name: "verbose", type: nil)
    let dangerIdArg = dangerId.asRubyArgument(name: "danger_id", type: nil)
    let dangerfileArg = dangerfile.asRubyArgument(name: "dangerfile", type: nil)
    let githubApiTokenArg = githubApiToken.asRubyArgument(name: "github_api_token", type: nil)
    let githubEnterpriseHostArg = githubEnterpriseHost.asRubyArgument(name: "github_enterprise_host", type: nil)
    let githubEnterpriseApiBaseUrlArg = githubEnterpriseApiBaseUrl.asRubyArgument(name: "github_enterprise_api_base_url", type: nil)
    let failOnErrorsArg = failOnErrors.asRubyArgument(name: "fail_on_errors", type: nil)
    let newCommentArg = newComment.asRubyArgument(name: "new_comment", type: nil)
    let removePreviousCommentsArg = removePreviousComments.asRubyArgument(name: "remove_previous_comments", type: nil)
    let baseArg = base.asRubyArgument(name: "base", type: nil)
    let headArg = head.asRubyArgument(name: "head", type: nil)
    let prArg = pr.asRubyArgument(name: "pr", type: nil)
    let failIfNoPrArg = failIfNoPr.asRubyArgument(name: "fail_if_no_pr", type: nil)
    let array: [RubyCommand.Argument?] = [useBundleExecArg,
                                          verboseArg,
                                          dangerIdArg,
                                          dangerfileArg,
                                          githubApiTokenArg,
                                          githubEnterpriseHostArg,
                                          githubEnterpriseApiBaseUrlArg,
                                          failOnErrorsArg,
                                          newCommentArg,
                                          removePreviousCommentsArg,
                                          baseArg,
                                          headArg,
                                          prArg,
                                          failIfNoPrArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "danger", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Print out an overview of the lane context values
 */
public func debug() {
    let args: [RubyCommand.Argument] = []
    let command = RubyCommand(commandID: "", methodName: "debug", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Defines a default platform to not have to specify the platform
 */
public func defaultPlatform() {
    let args: [RubyCommand.Argument] = []
    let command = RubyCommand(commandID: "", methodName: "default_platform", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Delete keychains and remove them from the search list

 - parameters:
   - name: Keychain name
   - keychainPath: Keychain path

 Keychains can be deleted after being created with `create_keychain`
 */
public func deleteKeychain(name: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                           keychainPath: OptionalConfigValue<String?> = .fastlaneDefault(nil))
{
    let nameArg = name.asRubyArgument(name: "name", type: nil)
    let keychainPathArg = keychainPath.asRubyArgument(name: "keychain_path", type: nil)
    let array: [RubyCommand.Argument?] = [nameArg,
                                          keychainPathArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "delete_keychain", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Alias for the `upload_to_app_store` action

 - parameters:
   - apiKeyPath: Path to your App Store Connect API Key JSON file (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-json-file)
   - apiKey: Your App Store Connect API Key information (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-hash-option)
   - username: Your Apple ID Username
   - appIdentifier: The bundle identifier of your app
   - appVersion: The version that should be edited or created
   - ipa: Path to your ipa file
   - pkg: Path to your pkg file
   - buildNumber: If set the given build number (already uploaded to iTC) will be used instead of the current built one
   - platform: The platform to use (optional)
   - editLive: Modify live metadata, this option disables ipa upload and screenshot upload
   - useLiveVersion: Force usage of live version rather than edit version
   - metadataPath: Path to the folder containing the metadata files
   - screenshotsPath: Path to the folder containing the screenshots
   - skipBinaryUpload: Skip uploading an ipa or pkg to App Store Connect
   - skipScreenshots: Don't upload the screenshots
   - skipMetadata: Don't upload the metadata (e.g. title, description). This will still upload screenshots
   - skipAppVersionUpdate: Don’t create or update the app version that is being prepared for submission
   - force: Skip verification of HTML preview file
   - overwriteScreenshots: Clear all previously uploaded screenshots before uploading the new ones
   - screenshotProcessingTimeout: Timeout in seconds to wait before considering screenshot processing as failed, used to handle cases where uploads to the App Store are stuck in processing
   - syncScreenshots: Sync screenshots with local ones. This is currently beta option so set true to 'FASTLANE_ENABLE_BETA_DELIVER_SYNC_SCREENSHOTS' environment variable as well
   - submitForReview: Submit the new version for Review after uploading everything
   - verifyOnly: Verifies archive with App Store Connect without uploading
   - rejectIfPossible: Rejects the previously submitted build if it's in a state where it's possible
   - versionCheckWaitRetryLimit: After submitting a new version, App Store Connect takes some time to recognize the new version and we must wait until it's available before attempting to upload metadata for it. There is a mechanism that will check if it's available and retry with an exponential backoff if it's not available yet. This option specifies how many times we should retry before giving up. Setting this to a value below 5 is not recommended and will likely cause failures. Increase this parameter when Apple servers seem to be degraded or slow
   - automaticRelease: Should the app be automatically released once it's approved? (Cannot be used together with `auto_release_date`)
   - autoReleaseDate: Date in milliseconds for automatically releasing on pending approval (Cannot be used together with `automatic_release`)
   - phasedRelease: Enable the phased release feature of iTC
   - resetRatings: Reset the summary rating when you release a new version of the application
   - priceTier: The price tier of this application
   - appRatingConfigPath: Path to the app rating's config
   - submissionInformation: Extra information for the submission (e.g. compliance specifications)
   - teamId: The ID of your App Store Connect team if you're in multiple teams
   - teamName: The name of your App Store Connect team if you're in multiple teams
   - devPortalTeamId: The short ID of your Developer Portal team, if you're in multiple teams. Different from your iTC team ID!
   - devPortalTeamName: The name of your Developer Portal team if you're in multiple teams
   - itcProvider: The provider short name to be used with the iTMSTransporter to identify your team. This value will override the automatically detected provider short name. To get provider short name run `xcrun iTMSTransporter -m provider -u 'USERNAME' -p 'PASSWORD' -account_type itunes_connect -v off`. The short names of providers should be listed in the second column
   - runPrecheckBeforeSubmit: Run precheck before submitting to app review
   - precheckDefaultRuleLevel: The default precheck rule level unless otherwise configured
   - individualMetadataItems: **DEPRECATED!** Removed after the migration to the new App Store Connect API in June 2020 - An array of localized metadata items to upload individually by language so that errors can be identified. E.g. ['name', 'keywords', 'description']. Note: slow
   - appIcon: **DEPRECATED!** Removed after the migration to the new App Store Connect API in June 2020 - Metadata: The path to the app icon
   - appleWatchAppIcon: **DEPRECATED!** Removed after the migration to the new App Store Connect API in June 2020 - Metadata: The path to the Apple Watch app icon
   - copyright: Metadata: The copyright notice
   - primaryCategory: Metadata: The english name of the primary category (e.g. `Business`, `Books`)
   - secondaryCategory: Metadata: The english name of the secondary category (e.g. `Business`, `Books`)
   - primaryFirstSubCategory: Metadata: The english name of the primary first sub category (e.g. `Educational`, `Puzzle`)
   - primarySecondSubCategory: Metadata: The english name of the primary second sub category (e.g. `Educational`, `Puzzle`)
   - secondaryFirstSubCategory: Metadata: The english name of the secondary first sub category (e.g. `Educational`, `Puzzle`)
   - secondarySecondSubCategory: Metadata: The english name of the secondary second sub category (e.g. `Educational`, `Puzzle`)
   - tradeRepresentativeContactInformation: **DEPRECATED!** This is no longer used by App Store Connect - Metadata: A hash containing the trade representative contact information
   - appReviewInformation: Metadata: A hash containing the review information
   - appReviewAttachmentFile: Metadata: Path to the app review attachment file
   - description: Metadata: The localised app description
   - name: Metadata: The localised app name
   - subtitle: Metadata: The localised app subtitle
   - keywords: Metadata: An array of localised keywords
   - promotionalText: Metadata: An array of localised promotional texts
   - releaseNotes: Metadata: Localised release notes for this version
   - privacyUrl: Metadata: Localised privacy url
   - appleTvPrivacyPolicy: Metadata: Localised Apple TV privacy policy text
   - supportUrl: Metadata: Localised support url
   - marketingUrl: Metadata: Localised marketing url
   - languages: Metadata: List of languages to activate
   - ignoreLanguageDirectoryValidation: Ignore errors when invalid languages are found in metadata and screenshot directories
   - precheckIncludeInAppPurchases: Should precheck check in-app purchases?
   - app: The (spaceship) app ID of the app you want to use/modify

 Using _upload_to_app_store_ after _build_app_ and _capture_screenshots_ will automatically upload the latest ipa and screenshots with no other configuration.

 If you don't want to verify an HTML preview for App Store builds, use the `:force` option.
 This is useful when running _fastlane_ on your Continuous Integration server:
 `_upload_to_app_store_(force: true)`
 If your account is on multiple teams and you need to tell the `iTMSTransporter` which 'provider' to use, you can set the `:itc_provider` option to pass this info.
 */
public func deliver(apiKeyPath: OptionalConfigValue<String?> = .fastlaneDefault(deliverfile.apiKeyPath),
                    apiKey: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(deliverfile.apiKey),
                    username: OptionalConfigValue<String?> = .fastlaneDefault(deliverfile.username),
                    appIdentifier: OptionalConfigValue<String?> = .fastlaneDefault(deliverfile.appIdentifier),
                    appVersion: OptionalConfigValue<String?> = .fastlaneDefault(deliverfile.appVersion),
                    ipa: OptionalConfigValue<String?> = .fastlaneDefault(deliverfile.ipa),
                    pkg: OptionalConfigValue<String?> = .fastlaneDefault(deliverfile.pkg),
                    buildNumber: OptionalConfigValue<String?> = .fastlaneDefault(deliverfile.buildNumber),
                    platform: String = deliverfile.platform,
                    editLive: OptionalConfigValue<Bool> = .fastlaneDefault(deliverfile.editLive),
                    useLiveVersion: OptionalConfigValue<Bool> = .fastlaneDefault(deliverfile.useLiveVersion),
                    metadataPath: OptionalConfigValue<String?> = .fastlaneDefault(deliverfile.metadataPath),
                    screenshotsPath: OptionalConfigValue<String?> = .fastlaneDefault(deliverfile.screenshotsPath),
                    skipBinaryUpload: OptionalConfigValue<Bool> = .fastlaneDefault(deliverfile.skipBinaryUpload),
                    skipScreenshots: OptionalConfigValue<Bool> = .fastlaneDefault(deliverfile.skipScreenshots),
                    skipMetadata: OptionalConfigValue<Bool> = .fastlaneDefault(deliverfile.skipMetadata),
                    skipAppVersionUpdate: OptionalConfigValue<Bool> = .fastlaneDefault(deliverfile.skipAppVersionUpdate),
                    force: OptionalConfigValue<Bool> = .fastlaneDefault(deliverfile.force),
                    overwriteScreenshots: OptionalConfigValue<Bool> = .fastlaneDefault(deliverfile.overwriteScreenshots),
                    screenshotProcessingTimeout: Int = deliverfile.screenshotProcessingTimeout,
                    syncScreenshots: OptionalConfigValue<Bool> = .fastlaneDefault(deliverfile.syncScreenshots),
                    submitForReview: OptionalConfigValue<Bool> = .fastlaneDefault(deliverfile.submitForReview),
                    verifyOnly: OptionalConfigValue<Bool> = .fastlaneDefault(deliverfile.verifyOnly),
                    rejectIfPossible: OptionalConfigValue<Bool> = .fastlaneDefault(deliverfile.rejectIfPossible),
                    versionCheckWaitRetryLimit: Int = deliverfile.versionCheckWaitRetryLimit,
                    automaticRelease: OptionalConfigValue<Bool?> = .fastlaneDefault(deliverfile.automaticRelease),
                    autoReleaseDate: OptionalConfigValue<Int?> = .fastlaneDefault(deliverfile.autoReleaseDate),
                    phasedRelease: OptionalConfigValue<Bool> = .fastlaneDefault(deliverfile.phasedRelease),
                    resetRatings: OptionalConfigValue<Bool> = .fastlaneDefault(deliverfile.resetRatings),
                    priceTier: OptionalConfigValue<Int?> = .fastlaneDefault(deliverfile.priceTier),
                    appRatingConfigPath: OptionalConfigValue<String?> = .fastlaneDefault(deliverfile.appRatingConfigPath),
                    submissionInformation: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(deliverfile.submissionInformation),
                    teamId: OptionalConfigValue<String?> = .fastlaneDefault(deliverfile.teamId),
                    teamName: OptionalConfigValue<String?> = .fastlaneDefault(deliverfile.teamName),
                    devPortalTeamId: OptionalConfigValue<String?> = .fastlaneDefault(deliverfile.devPortalTeamId),
                    devPortalTeamName: OptionalConfigValue<String?> = .fastlaneDefault(deliverfile.devPortalTeamName),
                    itcProvider: OptionalConfigValue<String?> = .fastlaneDefault(deliverfile.itcProvider),
                    runPrecheckBeforeSubmit: OptionalConfigValue<Bool> = .fastlaneDefault(deliverfile.runPrecheckBeforeSubmit),
                    precheckDefaultRuleLevel: Any = deliverfile.precheckDefaultRuleLevel,
                    individualMetadataItems: OptionalConfigValue<[String]?> = .fastlaneDefault(deliverfile.individualMetadataItems),
                    appIcon: OptionalConfigValue<String?> = .fastlaneDefault(deliverfile.appIcon),
                    appleWatchAppIcon: OptionalConfigValue<String?> = .fastlaneDefault(deliverfile.appleWatchAppIcon),
                    copyright: OptionalConfigValue<String?> = .fastlaneDefault(deliverfile.copyright),
                    primaryCategory: OptionalConfigValue<String?> = .fastlaneDefault(deliverfile.primaryCategory),
                    secondaryCategory: OptionalConfigValue<String?> = .fastlaneDefault(deliverfile.secondaryCategory),
                    primaryFirstSubCategory: OptionalConfigValue<String?> = .fastlaneDefault(deliverfile.primaryFirstSubCategory),
                    primarySecondSubCategory: OptionalConfigValue<String?> = .fastlaneDefault(deliverfile.primarySecondSubCategory),
                    secondaryFirstSubCategory: OptionalConfigValue<String?> = .fastlaneDefault(deliverfile.secondaryFirstSubCategory),
                    secondarySecondSubCategory: OptionalConfigValue<String?> = .fastlaneDefault(deliverfile.secondarySecondSubCategory),
                    tradeRepresentativeContactInformation: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(deliverfile.tradeRepresentativeContactInformation),
                    appReviewInformation: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(deliverfile.appReviewInformation),
                    appReviewAttachmentFile: OptionalConfigValue<String?> = .fastlaneDefault(deliverfile.appReviewAttachmentFile),
                    description: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(deliverfile.description),
                    name: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(deliverfile.name),
                    subtitle: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(deliverfile.subtitle),
                    keywords: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(deliverfile.keywords),
                    promotionalText: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(deliverfile.promotionalText),
                    releaseNotes: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(deliverfile.releaseNotes),
                    privacyUrl: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(deliverfile.privacyUrl),
                    appleTvPrivacyPolicy: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(deliverfile.appleTvPrivacyPolicy),
                    supportUrl: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(deliverfile.supportUrl),
                    marketingUrl: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(deliverfile.marketingUrl),
                    languages: OptionalConfigValue<[String]?> = .fastlaneDefault(deliverfile.languages),
                    ignoreLanguageDirectoryValidation: OptionalConfigValue<Bool> = .fastlaneDefault(deliverfile.ignoreLanguageDirectoryValidation),
                    precheckIncludeInAppPurchases: OptionalConfigValue<Bool> = .fastlaneDefault(deliverfile.precheckIncludeInAppPurchases),
                    app: OptionalConfigValue<Int?> = .fastlaneDefault(deliverfile.app))
{
    let apiKeyPathArg = apiKeyPath.asRubyArgument(name: "api_key_path", type: nil)
    let apiKeyArg = apiKey.asRubyArgument(name: "api_key", type: nil)
    let usernameArg = username.asRubyArgument(name: "username", type: nil)
    let appIdentifierArg = appIdentifier.asRubyArgument(name: "app_identifier", type: nil)
    let appVersionArg = appVersion.asRubyArgument(name: "app_version", type: nil)
    let ipaArg = ipa.asRubyArgument(name: "ipa", type: nil)
    let pkgArg = pkg.asRubyArgument(name: "pkg", type: nil)
    let buildNumberArg = buildNumber.asRubyArgument(name: "build_number", type: nil)
    let platformArg = RubyCommand.Argument(name: "platform", value: platform, type: nil)
    let editLiveArg = editLive.asRubyArgument(name: "edit_live", type: nil)
    let useLiveVersionArg = useLiveVersion.asRubyArgument(name: "use_live_version", type: nil)
    let metadataPathArg = metadataPath.asRubyArgument(name: "metadata_path", type: nil)
    let screenshotsPathArg = screenshotsPath.asRubyArgument(name: "screenshots_path", type: nil)
    let skipBinaryUploadArg = skipBinaryUpload.asRubyArgument(name: "skip_binary_upload", type: nil)
    let skipScreenshotsArg = skipScreenshots.asRubyArgument(name: "skip_screenshots", type: nil)
    let skipMetadataArg = skipMetadata.asRubyArgument(name: "skip_metadata", type: nil)
    let skipAppVersionUpdateArg = skipAppVersionUpdate.asRubyArgument(name: "skip_app_version_update", type: nil)
    let forceArg = force.asRubyArgument(name: "force", type: nil)
    let overwriteScreenshotsArg = overwriteScreenshots.asRubyArgument(name: "overwrite_screenshots", type: nil)
    let screenshotProcessingTimeoutArg = RubyCommand.Argument(name: "screenshot_processing_timeout", value: screenshotProcessingTimeout, type: nil)
    let syncScreenshotsArg = syncScreenshots.asRubyArgument(name: "sync_screenshots", type: nil)
    let submitForReviewArg = submitForReview.asRubyArgument(name: "submit_for_review", type: nil)
    let verifyOnlyArg = verifyOnly.asRubyArgument(name: "verify_only", type: nil)
    let rejectIfPossibleArg = rejectIfPossible.asRubyArgument(name: "reject_if_possible", type: nil)
    let versionCheckWaitRetryLimitArg = RubyCommand.Argument(name: "version_check_wait_retry_limit", value: versionCheckWaitRetryLimit, type: nil)
    let automaticReleaseArg = automaticRelease.asRubyArgument(name: "automatic_release", type: nil)
    let autoReleaseDateArg = autoReleaseDate.asRubyArgument(name: "auto_release_date", type: nil)
    let phasedReleaseArg = phasedRelease.asRubyArgument(name: "phased_release", type: nil)
    let resetRatingsArg = resetRatings.asRubyArgument(name: "reset_ratings", type: nil)
    let priceTierArg = priceTier.asRubyArgument(name: "price_tier", type: nil)
    let appRatingConfigPathArg = appRatingConfigPath.asRubyArgument(name: "app_rating_config_path", type: nil)
    let submissionInformationArg = submissionInformation.asRubyArgument(name: "submission_information", type: nil)
    let teamIdArg = teamId.asRubyArgument(name: "team_id", type: nil)
    let teamNameArg = teamName.asRubyArgument(name: "team_name", type: nil)
    let devPortalTeamIdArg = devPortalTeamId.asRubyArgument(name: "dev_portal_team_id", type: nil)
    let devPortalTeamNameArg = devPortalTeamName.asRubyArgument(name: "dev_portal_team_name", type: nil)
    let itcProviderArg = itcProvider.asRubyArgument(name: "itc_provider", type: nil)
    let runPrecheckBeforeSubmitArg = runPrecheckBeforeSubmit.asRubyArgument(name: "run_precheck_before_submit", type: nil)
    let precheckDefaultRuleLevelArg = RubyCommand.Argument(name: "precheck_default_rule_level", value: precheckDefaultRuleLevel, type: nil)
    let individualMetadataItemsArg = individualMetadataItems.asRubyArgument(name: "individual_metadata_items", type: nil)
    let appIconArg = appIcon.asRubyArgument(name: "app_icon", type: nil)
    let appleWatchAppIconArg = appleWatchAppIcon.asRubyArgument(name: "apple_watch_app_icon", type: nil)
    let copyrightArg = copyright.asRubyArgument(name: "copyright", type: nil)
    let primaryCategoryArg = primaryCategory.asRubyArgument(name: "primary_category", type: nil)
    let secondaryCategoryArg = secondaryCategory.asRubyArgument(name: "secondary_category", type: nil)
    let primaryFirstSubCategoryArg = primaryFirstSubCategory.asRubyArgument(name: "primary_first_sub_category", type: nil)
    let primarySecondSubCategoryArg = primarySecondSubCategory.asRubyArgument(name: "primary_second_sub_category", type: nil)
    let secondaryFirstSubCategoryArg = secondaryFirstSubCategory.asRubyArgument(name: "secondary_first_sub_category", type: nil)
    let secondarySecondSubCategoryArg = secondarySecondSubCategory.asRubyArgument(name: "secondary_second_sub_category", type: nil)
    let tradeRepresentativeContactInformationArg = tradeRepresentativeContactInformation.asRubyArgument(name: "trade_representative_contact_information", type: nil)
    let appReviewInformationArg = appReviewInformation.asRubyArgument(name: "app_review_information", type: nil)
    let appReviewAttachmentFileArg = appReviewAttachmentFile.asRubyArgument(name: "app_review_attachment_file", type: nil)
    let descriptionArg = description.asRubyArgument(name: "description", type: nil)
    let nameArg = name.asRubyArgument(name: "name", type: nil)
    let subtitleArg = subtitle.asRubyArgument(name: "subtitle", type: nil)
    let keywordsArg = keywords.asRubyArgument(name: "keywords", type: nil)
    let promotionalTextArg = promotionalText.asRubyArgument(name: "promotional_text", type: nil)
    let releaseNotesArg = releaseNotes.asRubyArgument(name: "release_notes", type: nil)
    let privacyUrlArg = privacyUrl.asRubyArgument(name: "privacy_url", type: nil)
    let appleTvPrivacyPolicyArg = appleTvPrivacyPolicy.asRubyArgument(name: "apple_tv_privacy_policy", type: nil)
    let supportUrlArg = supportUrl.asRubyArgument(name: "support_url", type: nil)
    let marketingUrlArg = marketingUrl.asRubyArgument(name: "marketing_url", type: nil)
    let languagesArg = languages.asRubyArgument(name: "languages", type: nil)
    let ignoreLanguageDirectoryValidationArg = ignoreLanguageDirectoryValidation.asRubyArgument(name: "ignore_language_directory_validation", type: nil)
    let precheckIncludeInAppPurchasesArg = precheckIncludeInAppPurchases.asRubyArgument(name: "precheck_include_in_app_purchases", type: nil)
    let appArg = app.asRubyArgument(name: "app", type: nil)
    let array: [RubyCommand.Argument?] = [apiKeyPathArg,
                                          apiKeyArg,
                                          usernameArg,
                                          appIdentifierArg,
                                          appVersionArg,
                                          ipaArg,
                                          pkgArg,
                                          buildNumberArg,
                                          platformArg,
                                          editLiveArg,
                                          useLiveVersionArg,
                                          metadataPathArg,
                                          screenshotsPathArg,
                                          skipBinaryUploadArg,
                                          skipScreenshotsArg,
                                          skipMetadataArg,
                                          skipAppVersionUpdateArg,
                                          forceArg,
                                          overwriteScreenshotsArg,
                                          screenshotProcessingTimeoutArg,
                                          syncScreenshotsArg,
                                          submitForReviewArg,
                                          verifyOnlyArg,
                                          rejectIfPossibleArg,
                                          versionCheckWaitRetryLimitArg,
                                          automaticReleaseArg,
                                          autoReleaseDateArg,
                                          phasedReleaseArg,
                                          resetRatingsArg,
                                          priceTierArg,
                                          appRatingConfigPathArg,
                                          submissionInformationArg,
                                          teamIdArg,
                                          teamNameArg,
                                          devPortalTeamIdArg,
                                          devPortalTeamNameArg,
                                          itcProviderArg,
                                          runPrecheckBeforeSubmitArg,
                                          precheckDefaultRuleLevelArg,
                                          individualMetadataItemsArg,
                                          appIconArg,
                                          appleWatchAppIconArg,
                                          copyrightArg,
                                          primaryCategoryArg,
                                          secondaryCategoryArg,
                                          primaryFirstSubCategoryArg,
                                          primarySecondSubCategoryArg,
                                          secondaryFirstSubCategoryArg,
                                          secondarySecondSubCategoryArg,
                                          tradeRepresentativeContactInformationArg,
                                          appReviewInformationArg,
                                          appReviewAttachmentFileArg,
                                          descriptionArg,
                                          nameArg,
                                          subtitleArg,
                                          keywordsArg,
                                          promotionalTextArg,
                                          releaseNotesArg,
                                          privacyUrlArg,
                                          appleTvPrivacyPolicyArg,
                                          supportUrlArg,
                                          marketingUrlArg,
                                          languagesArg,
                                          ignoreLanguageDirectoryValidationArg,
                                          precheckIncludeInAppPurchasesArg,
                                          appArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "deliver", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Upload a new build to [DeployGate](https://deploygate.com/)

 - parameters:
   - apiToken: Deploygate API Token
   - user: Target username or organization name
   - ipa: Path to your IPA file. Optional if you use the _gym_ or _xcodebuild_ action
   - apk: Path to your APK file
   - message: Release Notes
   - distributionKey: Target Distribution Key
   - releaseNote: Release note for distribution page
   - disableNotify: Disables Push notification emails
   - distributionName: Target Distribution Name

 You can retrieve your username and API token on [your settings page](https://deploygate.com/settings).
 More information about the available options can be found in the [DeployGate Push API document](https://deploygate.com/docs/api).
 */
public func deploygate(apiToken: String,
                       user: String,
                       ipa: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                       apk: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                       message: String = "No changelog provided",
                       distributionKey: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                       releaseNote: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                       disableNotify: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                       distributionName: OptionalConfigValue<String?> = .fastlaneDefault(nil))
{
    let apiTokenArg = RubyCommand.Argument(name: "api_token", value: apiToken, type: nil)
    let userArg = RubyCommand.Argument(name: "user", value: user, type: nil)
    let ipaArg = ipa.asRubyArgument(name: "ipa", type: nil)
    let apkArg = apk.asRubyArgument(name: "apk", type: nil)
    let messageArg = RubyCommand.Argument(name: "message", value: message, type: nil)
    let distributionKeyArg = distributionKey.asRubyArgument(name: "distribution_key", type: nil)
    let releaseNoteArg = releaseNote.asRubyArgument(name: "release_note", type: nil)
    let disableNotifyArg = disableNotify.asRubyArgument(name: "disable_notify", type: nil)
    let distributionNameArg = distributionName.asRubyArgument(name: "distribution_name", type: nil)
    let array: [RubyCommand.Argument?] = [apiTokenArg,
                                          userArg,
                                          ipaArg,
                                          apkArg,
                                          messageArg,
                                          distributionKeyArg,
                                          releaseNoteArg,
                                          disableNotifyArg,
                                          distributionNameArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "deploygate", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Reads in production secrets set in a dotgpg file and puts them in ENV

 - parameter dotgpgFile: Path to your gpg file

 More information about dotgpg can be found at [https://github.com/ConradIrwin/dotgpg](https://github.com/ConradIrwin/dotgpg).
 */
public func dotgpgEnvironment(dotgpgFile: String) {
    let dotgpgFileArg = RubyCommand.Argument(name: "dotgpg_file", value: dotgpgFile, type: nil)
    let array: [RubyCommand.Argument?] = [dotgpgFileArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "dotgpg_environment", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Download a file from a remote server (e.g. JSON file)

 - parameter url: The URL that should be downloaded

 Specify the URL to download and get the content as a return value.
 Automatically parses JSON into a Ruby data structure.
 For more advanced networking code, use the Ruby functions instead: [http://docs.ruby-lang.org/en/2.0.0/Net/HTTP.html](http://docs.ruby-lang.org/en/2.0.0/Net/HTTP.html).
 */
public func download(url: String) {
    let urlArg = RubyCommand.Argument(name: "url", value: url, type: nil)
    let array: [RubyCommand.Argument?] = [urlArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "download", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Download App Privacy Details from an app in App Store Connect

 - parameters:
   - username: Your Apple ID Username for App Store Connect
   - appIdentifier: The bundle identifier of your app
   - teamId: The ID of your App Store Connect team if you're in multiple teams
   - teamName: The name of your App Store Connect team if you're in multiple teams
   - outputJsonPath: Path to the app usage data JSON file generated by interactive questions

 Download App Privacy Details from an app in App Store Connect. For more detail information, view https://docs.fastlane.tools/uploading-app-privacy-details
 */
public func downloadAppPrivacyDetailsFromAppStore(username: String,
                                                  appIdentifier: String,
                                                  teamId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                                  teamName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                                  outputJsonPath: String = "./fastlane/app_privacy_details.json")
{
    let usernameArg = RubyCommand.Argument(name: "username", value: username, type: nil)
    let appIdentifierArg = RubyCommand.Argument(name: "app_identifier", value: appIdentifier, type: nil)
    let teamIdArg = teamId.asRubyArgument(name: "team_id", type: nil)
    let teamNameArg = teamName.asRubyArgument(name: "team_name", type: nil)
    let outputJsonPathArg = RubyCommand.Argument(name: "output_json_path", value: outputJsonPath, type: nil)
    let array: [RubyCommand.Argument?] = [usernameArg,
                                          appIdentifierArg,
                                          teamIdArg,
                                          teamNameArg,
                                          outputJsonPathArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "download_app_privacy_details_from_app_store", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Download dSYM files from App Store Connect for Bitcode apps

 - parameters:
   - apiKeyPath: Path to your App Store Connect API Key JSON file (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-json-file)
   - apiKey: Your App Store Connect API Key information (https://docs.fastlane.tools/app-store-connect-api/#use-return-value-and-pass-in-as-an-option)
   - username: Your Apple ID Username for App Store Connect
   - appIdentifier: The bundle identifier of your app
   - teamId: The ID of your App Store Connect team if you're in multiple teams
   - teamName: The name of your App Store Connect team if you're in multiple teams
   - platform: The app platform for dSYMs you wish to download (ios, xros, appletvos)
   - version: The app version for dSYMs you wish to download, pass in 'latest' to download only the latest build's dSYMs or 'live' to download only the live version dSYMs
   - buildNumber: The app build_number for dSYMs you wish to download
   - minVersion: The minimum app version for dSYMs you wish to download
   - afterUploadedDate: The uploaded date after which you wish to download dSYMs
   - outputDirectory: Where to save the download dSYMs, defaults to the current path
   - waitForDsymProcessing: Wait for dSYMs to process
   - waitTimeout: Number of seconds to wait for dSYMs to process

 This action downloads dSYM files from App Store Connect after the ipa gets re-compiled by Apple. Useful if you have Bitcode enabled.|
 |
 ```ruby|
 lane :refresh_dsyms do|
   download_dsyms                  # Download dSYM files from iTC|
   upload_symbols_to_crashlytics   # Upload them to Crashlytics|
   clean_build_artifacts           # Delete the local dSYM files|
 end|
 ```|
 >|
 */
public func downloadDsyms(apiKeyPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                          apiKey: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                          username: String,
                          appIdentifier: String,
                          teamId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                          teamName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                          platform: String = "ios",
                          version: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                          buildNumber: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                          minVersion: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                          afterUploadedDate: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                          outputDirectory: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                          waitForDsymProcessing: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                          waitTimeout: Int = 300)
{
    let apiKeyPathArg = apiKeyPath.asRubyArgument(name: "api_key_path", type: nil)
    let apiKeyArg = apiKey.asRubyArgument(name: "api_key", type: nil)
    let usernameArg = RubyCommand.Argument(name: "username", value: username, type: nil)
    let appIdentifierArg = RubyCommand.Argument(name: "app_identifier", value: appIdentifier, type: nil)
    let teamIdArg = teamId.asRubyArgument(name: "team_id", type: nil)
    let teamNameArg = teamName.asRubyArgument(name: "team_name", type: nil)
    let platformArg = RubyCommand.Argument(name: "platform", value: platform, type: nil)
    let versionArg = version.asRubyArgument(name: "version", type: nil)
    let buildNumberArg = buildNumber.asRubyArgument(name: "build_number", type: nil)
    let minVersionArg = minVersion.asRubyArgument(name: "min_version", type: nil)
    let afterUploadedDateArg = afterUploadedDate.asRubyArgument(name: "after_uploaded_date", type: nil)
    let outputDirectoryArg = outputDirectory.asRubyArgument(name: "output_directory", type: nil)
    let waitForDsymProcessingArg = waitForDsymProcessing.asRubyArgument(name: "wait_for_dsym_processing", type: nil)
    let waitTimeoutArg = RubyCommand.Argument(name: "wait_timeout", value: waitTimeout, type: nil)
    let array: [RubyCommand.Argument?] = [apiKeyPathArg,
                                          apiKeyArg,
                                          usernameArg,
                                          appIdentifierArg,
                                          teamIdArg,
                                          teamNameArg,
                                          platformArg,
                                          versionArg,
                                          buildNumberArg,
                                          minVersionArg,
                                          afterUploadedDateArg,
                                          outputDirectoryArg,
                                          waitForDsymProcessingArg,
                                          waitTimeoutArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "download_dsyms", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Download metadata and binaries from Google Play (via _supply_)

 - parameters:
   - packageName: The package name of the application to use
   - versionName: Version name (used when uploading new apks/aabs) - defaults to 'versionName' in build.gradle or AndroidManifest.xml
   - track: The track of the application to use. The default available tracks are: production, beta, alpha, internal
   - metadataPath: Path to the directory containing the metadata files
   - key: **DEPRECATED!** Use `--json_key` instead - The p12 File used to authenticate with Google
   - issuer: **DEPRECATED!** Use `--json_key` instead - The issuer of the p12 file (email address of the service account)
   - jsonKey: The path to a file containing service account JSON, used to authenticate with Google
   - jsonKeyData: The raw service account JSON data used to authenticate with Google
   - rootUrl: Root URL for the Google Play API. The provided URL will be used for API calls in place of https://www.googleapis.com/
   - timeout: Timeout for read, open, and send (in seconds)

 More information: https://docs.fastlane.tools/actions/download_from_play_store/
 */
public func downloadFromPlayStore(packageName: String,
                                  versionName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  track: String = "production",
                                  metadataPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  key: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  issuer: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  jsonKey: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  jsonKeyData: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  rootUrl: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  timeout: Int = 300)
{
    let packageNameArg = RubyCommand.Argument(name: "package_name", value: packageName, type: nil)
    let versionNameArg = versionName.asRubyArgument(name: "version_name", type: nil)
    let trackArg = RubyCommand.Argument(name: "track", value: track, type: nil)
    let metadataPathArg = metadataPath.asRubyArgument(name: "metadata_path", type: nil)
    let keyArg = key.asRubyArgument(name: "key", type: nil)
    let issuerArg = issuer.asRubyArgument(name: "issuer", type: nil)
    let jsonKeyArg = jsonKey.asRubyArgument(name: "json_key", type: nil)
    let jsonKeyDataArg = jsonKeyData.asRubyArgument(name: "json_key_data", type: nil)
    let rootUrlArg = rootUrl.asRubyArgument(name: "root_url", type: nil)
    let timeoutArg = RubyCommand.Argument(name: "timeout", value: timeout, type: nil)
    let array: [RubyCommand.Argument?] = [packageNameArg,
                                          versionNameArg,
                                          trackArg,
                                          metadataPathArg,
                                          keyArg,
                                          issuerArg,
                                          jsonKeyArg,
                                          jsonKeyDataArg,
                                          rootUrlArg,
                                          timeoutArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "download_from_play_store", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Download the Universal APK of a given version code from the Google Play Console

 - parameters:
   - packageName: The package name of the application to use
   - versionCode: The versionCode for which to download the generated APK
   - jsonKey: The path to a file containing service account JSON, used to authenticate with Google
   - jsonKeyData: The raw service account JSON data used to authenticate with Google
   - rootUrl: Root URL for the Google Play API. The provided URL will be used for API calls in place of https://www.googleapis.com/
   - timeout: Timeout for read, open, and send (in seconds)
   - destination: The path on disk where to download the Generated Universal APK
   - certificateSha256Hash: The SHA256 hash of the signing key for which to download the Universal, Code-Signed APK for. Use 'xx:xx:xx:…' format (32 hex bytes separated by colons), as printed by `keytool -list -keystore <keystorefile>`. Only useful to provide if you have multiple signing keys configured on GPC, to specify which generated APK to download

 - returns: The path to the downloaded Universal APK. The action will raise an exception if it failed to find or download the APK in Google Play

 Download the universal APK of a given version code from the Google Play Console.

 This uses _fastlane_ `supply` (and the `AndroidPublisher` Google API) to download the Universal APK
 generated by Google after you uploaded an `.aab` bundle to the Play Console.

 See https://developers.google.com/android-publisher/api-ref/rest/v3/generatedapks/list

 */
public func downloadUniversalApkFromGooglePlay(packageName: String,
                                               versionCode: OptionalConfigValue<Int?> = .fastlaneDefault(nil),
                                               jsonKey: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                               jsonKeyData: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                               rootUrl: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                               timeout: Int = 300,
                                               destination: String,
                                               certificateSha256Hash: OptionalConfigValue<String?> = .fastlaneDefault(nil))
{
    let packageNameArg = RubyCommand.Argument(name: "package_name", value: packageName, type: nil)
    let versionCodeArg = versionCode.asRubyArgument(name: "version_code", type: nil)
    let jsonKeyArg = jsonKey.asRubyArgument(name: "json_key", type: nil)
    let jsonKeyDataArg = jsonKeyData.asRubyArgument(name: "json_key_data", type: nil)
    let rootUrlArg = rootUrl.asRubyArgument(name: "root_url", type: nil)
    let timeoutArg = RubyCommand.Argument(name: "timeout", value: timeout, type: nil)
    let destinationArg = RubyCommand.Argument(name: "destination", value: destination, type: nil)
    let certificateSha256HashArg = certificateSha256Hash.asRubyArgument(name: "certificate_sha256_hash", type: nil)
    let array: [RubyCommand.Argument?] = [packageNameArg,
                                          versionCodeArg,
                                          jsonKeyArg,
                                          jsonKeyDataArg,
                                          rootUrlArg,
                                          timeoutArg,
                                          destinationArg,
                                          certificateSha256HashArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "download_universal_apk_from_google_play", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Creates a zipped dSYM in the project root from the .xcarchive

 - parameters:
   - archivePath: Path to your xcarchive file. Optional if you use the `xcodebuild` action
   - dsymPath: Path for generated dsym. Optional, default is your apps root directory
   - all: Whether or not all dSYM files are to be included. Optional, default is false in which only your app dSYM is included

 You can manually specify the path to the xcarchive (not needed if you use `xcodebuild`/`xcarchive` to build your archive)
 */
public func dsymZip(archivePath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                    dsymPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                    all: OptionalConfigValue<Bool> = .fastlaneDefault(false))
{
    let archivePathArg = archivePath.asRubyArgument(name: "archive_path", type: nil)
    let dsymPathArg = dsymPath.asRubyArgument(name: "dsym_path", type: nil)
    let allArg = all.asRubyArgument(name: "all", type: nil)
    let array: [RubyCommand.Argument?] = [archivePathArg,
                                          dsymPathArg,
                                          allArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "dsym_zip", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Alias for the `puts` action

 - parameter message: Message to be printed out
 */
public func echo(message: OptionalConfigValue<String?> = .fastlaneDefault(nil)) {
    let messageArg = message.asRubyArgument(name: "message", type: nil)
    let array: [RubyCommand.Argument?] = [messageArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "echo", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Raises an exception if not using `bundle exec` to run fastlane

 This action will check if you are using `bundle exec` to run fastlane.
 You can put it into `before_all` to make sure that fastlane is ran using the `bundle exec fastlane` command.
 */
public func ensureBundleExec() {
    let args: [RubyCommand.Argument] = []
    let command = RubyCommand(commandID: "", methodName: "ensure_bundle_exec", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Raises an exception if the specified env vars are not set

 - parameter envVars: The environment variables names that should be checked

 This action will check if some environment variables are set.
 */
public func ensureEnvVars(envVars: [String]) {
    let envVarsArg = RubyCommand.Argument(name: "env_vars", value: envVars, type: nil)
    let array: [RubyCommand.Argument?] = [envVarsArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "ensure_env_vars", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Raises an exception if not on a specific git branch

 - parameter branch: The branch that should be checked for. String that can be either the full name of the branch or a regex e.g. `^feature/.*$` to match

 This action will check if your git repo is checked out to a specific branch.
 You may only want to make releases from a specific branch, so `ensure_git_branch` will stop a lane if it was accidentally executed on an incorrect branch.
 */
public func ensureGitBranch(branch: String = "master") {
    let branchArg = RubyCommand.Argument(name: "branch", value: branch, type: nil)
    let array: [RubyCommand.Argument?] = [branchArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "ensure_git_branch", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Raises an exception if there are uncommitted git changes

 - parameters:
   - showUncommittedChanges: The flag whether to show uncommitted changes if the repo is dirty
   - showDiff: The flag whether to show the git diff if the repo is dirty
   - ignored: The handling mode of the ignored files. The available options are: `'traditional'`, `'none'` (default) and `'matching'`. Specifying `'none'` to this parameter is the same as not specifying the parameter at all, which means that no ignored file will be used to check if the repo is dirty or not. Specifying `'traditional'` or `'matching'` causes some ignored files to be used to check if the repo is dirty or not (more info in the official docs: https://git-scm.com/docs/git-status#Documentation/git-status.txt---ignoredltmodegt)
   - ignoreFiles: Array of files to ignore

 A sanity check to make sure you are working in a repo that is clean.
 Especially useful to put at the beginning of your Fastfile in the `before_all` block, if some of your other actions will touch your filesystem, do things to your git repo, or just as a general reminder to save your work.
 Also needed as a prerequisite for some other actions like `reset_git_repo`.
 */
public func ensureGitStatusClean(showUncommittedChanges: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                 showDiff: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                 ignored: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                 ignoreFiles: OptionalConfigValue<[String]?> = .fastlaneDefault(nil))
{
    let showUncommittedChangesArg = showUncommittedChanges.asRubyArgument(name: "show_uncommitted_changes", type: nil)
    let showDiffArg = showDiff.asRubyArgument(name: "show_diff", type: nil)
    let ignoredArg = ignored.asRubyArgument(name: "ignored", type: nil)
    let ignoreFilesArg = ignoreFiles.asRubyArgument(name: "ignore_files", type: nil)
    let array: [RubyCommand.Argument?] = [showUncommittedChangesArg,
                                          showDiffArg,
                                          ignoredArg,
                                          ignoreFilesArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "ensure_git_status_clean", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Ensures the given text is nowhere in the code base

 - parameters:
   - text: The text that must not be in the code base
   - path: The directory containing all the source files
   - extension: The extension that should be searched for
   - extensions: An array of file extensions that should be searched for
   - exclude: Exclude a certain pattern from the search
   - excludeDirs: An array of dirs that should not be included in the search

 You don't want any debug code to slip into production.
 This can be used to check if there is any debug code still in your codebase or if you have things like `// TO DO` or similar.
 */
public func ensureNoDebugCode(text: String,
                              path: String = ".",
                              extension: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                              extensions: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                              exclude: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                              excludeDirs: OptionalConfigValue<[String]?> = .fastlaneDefault(nil))
{
    let textArg = RubyCommand.Argument(name: "text", value: text, type: nil)
    let pathArg = RubyCommand.Argument(name: "path", value: path, type: nil)
    let extensionArg = `extension`.asRubyArgument(name: "extension", type: nil)
    let extensionsArg = extensions.asRubyArgument(name: "extensions", type: nil)
    let excludeArg = exclude.asRubyArgument(name: "exclude", type: nil)
    let excludeDirsArg = excludeDirs.asRubyArgument(name: "exclude_dirs", type: nil)
    let array: [RubyCommand.Argument?] = [textArg,
                                          pathArg,
                                          extensionArg,
                                          extensionsArg,
                                          excludeArg,
                                          excludeDirsArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "ensure_no_debug_code", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Ensure the right version of Xcode is used

 - parameters:
   - version: Xcode version to verify that is selected
   - strict: Should the version be verified strictly (all 3 version numbers), or matching only the given version numbers (i.e. `11.3` == `11.3.x`)

 If building your app requires a specific version of Xcode, you can invoke this command before using gym.
 For example, to ensure that a beta version of Xcode is not accidentally selected to build, which would make uploading to TestFlight fail.
 You can either manually provide a specific version using `version:` or you make use of the `.xcode-version` file.
 Using the `strict` parameter, you can either verify the full set of version numbers strictly (i.e. `11.3.1`) or only a subset of them (i.e. `11.3` or `11`).
 */
public func ensureXcodeVersion(version: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               strict: OptionalConfigValue<Bool> = .fastlaneDefault(true))
{
    let versionArg = version.asRubyArgument(name: "version", type: nil)
    let strictArg = strict.asRubyArgument(name: "strict", type: nil)
    let array: [RubyCommand.Argument?] = [versionArg,
                                          strictArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "ensure_xcode_version", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Sets/gets env vars for Fastlane.swift. Don't use in ruby, use `ENV[key] = val`

 - parameters:
   - set: Set the environment variables named
   - get: Get the environment variable named
   - remove: Remove the environment variable named
 */
@discardableResult public func environmentVariable(set: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                                                   get: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                                   remove: OptionalConfigValue<String?> = .fastlaneDefault(nil)) -> String
{
    let setArg = set.asRubyArgument(name: "set", type: nil)
    let getArg = get.asRubyArgument(name: "get", type: nil)
    let removeArg = remove.asRubyArgument(name: "remove", type: nil)
    let array: [RubyCommand.Argument?] = [setArg,
                                          getArg,
                                          removeArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "environment_variable", className: nil, args: args)
    return runner.executeCommand(command)
}

/**
 Allows to Generate output files based on ERB templates

 - parameters:
   - template: ERB Template File
   - destination: Destination file
   - placeholders: Placeholders given as a hash
   - trimMode: Trim mode applied to the ERB

 Renders an ERB template with `:placeholders` given as a hash via parameter.
 If no `:destination` is set, it returns the rendered template as string.
 */
public func erb(template: String,
                destination: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                placeholders: [String: Any] = [:],
                trimMode: OptionalConfigValue<String?> = .fastlaneDefault(nil))
{
    let templateArg = RubyCommand.Argument(name: "template", value: template, type: nil)
    let destinationArg = destination.asRubyArgument(name: "destination", type: nil)
    let placeholdersArg = RubyCommand.Argument(name: "placeholders", value: placeholders, type: nil)
    let trimModeArg = trimMode.asRubyArgument(name: "trim_mode", type: nil)
    let array: [RubyCommand.Argument?] = [templateArg,
                                          destinationArg,
                                          placeholdersArg,
                                          trimModeArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "erb", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Alias for the `min_fastlane_version` action

 Add this to your `Fastfile` to require a certain version of _fastlane_.
 Use it if you use an action that just recently came out and you need it.
 */
public func fastlaneVersion() {
    let args: [RubyCommand.Argument] = []
    let command = RubyCommand(commandID: "", methodName: "fastlane_version", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Send a message to a [Flock](https://flock.com/) group

 - parameters:
   - message: Message text
   - token: Token for the Flock incoming webhook
   - baseUrl: Base URL of the Flock incoming message webhook

 To obtain the token, create a new [incoming message webhook](https://dev.flock.co/wiki/display/FlockAPI/Incoming+Webhooks) in your Flock admin panel.
 */
public func flock(message: String,
                  token: String,
                  baseUrl: String = "https://api.flock.co/hooks/sendMessage")
{
    let messageArg = RubyCommand.Argument(name: "message", value: message, type: nil)
    let tokenArg = RubyCommand.Argument(name: "token", value: token, type: nil)
    let baseUrlArg = RubyCommand.Argument(name: "base_url", value: baseUrl, type: nil)
    let array: [RubyCommand.Argument?] = [messageArg,
                                          tokenArg,
                                          baseUrlArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "flock", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Adds device frames around all screenshots (via _frameit_)

 - parameters:
   - white: Use white device frames
   - silver: Use white device frames. Alias for :white
   - roseGold: Use rose gold device frames. Alias for :rose_gold
   - gold: Use gold device frames. Alias for :gold
   - forceDeviceType: Forces a given device type, useful for Mac screenshots, as their sizes vary
   - useLegacyIphone5s: Use iPhone 5s instead of iPhone SE frames
   - useLegacyIphone6s: Use iPhone 6s frames instead of iPhone 7 frames
   - useLegacyIphone7: Use iPhone 7 frames instead of iPhone 8 frames
   - useLegacyIphonex: Use iPhone X instead of iPhone XS frames
   - useLegacyIphonexr: Use iPhone XR instead of iPhone 11 frames
   - useLegacyIphonexs: Use iPhone XS instead of iPhone 11 Pro frames
   - useLegacyIphonexsmax: Use iPhone XS Max instead of iPhone 11 Pro Max frames
   - forceOrientationBlock: [Advanced] A block to customize your screenshots' device orientation
   - debugMode: Output debug information in framed screenshots
   - resume: Resume frameit instead of reprocessing all screenshots
   - usePlatform: Choose a platform, the valid options are IOS, ANDROID and ANY (default is either general platform defined in the fastfile or IOS to ensure backward compatibility)
   - path: The path to the directory containing the screenshots

 Uses [frameit](https://docs.fastlane.tools/actions/frameit/) to prepare perfect screenshots for the App Store, your website, QA or emails.
 You can add background and titles to the framed screenshots as well.
 */
public func frameScreenshots(white: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                             silver: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                             roseGold: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                             gold: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                             forceDeviceType: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             useLegacyIphone5s: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                             useLegacyIphone6s: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                             useLegacyIphone7: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                             useLegacyIphonex: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                             useLegacyIphonexr: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                             useLegacyIphonexs: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                             useLegacyIphonexsmax: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                             forceOrientationBlock: ((String) -> Void)? = nil,
                             debugMode: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                             resume: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                             usePlatform: String = "IOS",
                             path: String = "./")
{
    let whiteArg = white.asRubyArgument(name: "white", type: nil)
    let silverArg = silver.asRubyArgument(name: "silver", type: nil)
    let roseGoldArg = roseGold.asRubyArgument(name: "rose_gold", type: nil)
    let goldArg = gold.asRubyArgument(name: "gold", type: nil)
    let forceDeviceTypeArg = forceDeviceType.asRubyArgument(name: "force_device_type", type: nil)
    let useLegacyIphone5sArg = useLegacyIphone5s.asRubyArgument(name: "use_legacy_iphone5s", type: nil)
    let useLegacyIphone6sArg = useLegacyIphone6s.asRubyArgument(name: "use_legacy_iphone6s", type: nil)
    let useLegacyIphone7Arg = useLegacyIphone7.asRubyArgument(name: "use_legacy_iphone7", type: nil)
    let useLegacyIphonexArg = useLegacyIphonex.asRubyArgument(name: "use_legacy_iphonex", type: nil)
    let useLegacyIphonexrArg = useLegacyIphonexr.asRubyArgument(name: "use_legacy_iphonexr", type: nil)
    let useLegacyIphonexsArg = useLegacyIphonexs.asRubyArgument(name: "use_legacy_iphonexs", type: nil)
    let useLegacyIphonexsmaxArg = useLegacyIphonexsmax.asRubyArgument(name: "use_legacy_iphonexsmax", type: nil)
    let forceOrientationBlockArg = RubyCommand.Argument(name: "force_orientation_block", value: forceOrientationBlock, type: .stringClosure)
    let debugModeArg = debugMode.asRubyArgument(name: "debug_mode", type: nil)
    let resumeArg = resume.asRubyArgument(name: "resume", type: nil)
    let usePlatformArg = RubyCommand.Argument(name: "use_platform", value: usePlatform, type: nil)
    let pathArg = RubyCommand.Argument(name: "path", value: path, type: nil)
    let array: [RubyCommand.Argument?] = [whiteArg,
                                          silverArg,
                                          roseGoldArg,
                                          goldArg,
                                          forceDeviceTypeArg,
                                          useLegacyIphone5sArg,
                                          useLegacyIphone6sArg,
                                          useLegacyIphone7Arg,
                                          useLegacyIphonexArg,
                                          useLegacyIphonexrArg,
                                          useLegacyIphonexsArg,
                                          useLegacyIphonexsmaxArg,
                                          forceOrientationBlockArg,
                                          debugModeArg,
                                          resumeArg,
                                          usePlatformArg,
                                          pathArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "frame_screenshots", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Alias for the `frame_screenshots` action

 - parameters:
   - white: Use white device frames
   - silver: Use white device frames. Alias for :white
   - roseGold: Use rose gold device frames. Alias for :rose_gold
   - gold: Use gold device frames. Alias for :gold
   - forceDeviceType: Forces a given device type, useful for Mac screenshots, as their sizes vary
   - useLegacyIphone5s: Use iPhone 5s instead of iPhone SE frames
   - useLegacyIphone6s: Use iPhone 6s frames instead of iPhone 7 frames
   - useLegacyIphone7: Use iPhone 7 frames instead of iPhone 8 frames
   - useLegacyIphonex: Use iPhone X instead of iPhone XS frames
   - useLegacyIphonexr: Use iPhone XR instead of iPhone 11 frames
   - useLegacyIphonexs: Use iPhone XS instead of iPhone 11 Pro frames
   - useLegacyIphonexsmax: Use iPhone XS Max instead of iPhone 11 Pro Max frames
   - forceOrientationBlock: [Advanced] A block to customize your screenshots' device orientation
   - debugMode: Output debug information in framed screenshots
   - resume: Resume frameit instead of reprocessing all screenshots
   - usePlatform: Choose a platform, the valid options are IOS, ANDROID and ANY (default is either general platform defined in the fastfile or IOS to ensure backward compatibility)
   - path: The path to the directory containing the screenshots

 Uses [frameit](https://docs.fastlane.tools/actions/frameit/) to prepare perfect screenshots for the App Store, your website, QA or emails.
 You can add background and titles to the framed screenshots as well.
 */
public func frameit(white: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                    silver: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                    roseGold: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                    gold: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                    forceDeviceType: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                    useLegacyIphone5s: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                    useLegacyIphone6s: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                    useLegacyIphone7: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                    useLegacyIphonex: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                    useLegacyIphonexr: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                    useLegacyIphonexs: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                    useLegacyIphonexsmax: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                    forceOrientationBlock: ((String) -> Void)? = nil,
                    debugMode: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                    resume: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                    usePlatform: String = "IOS",
                    path: String = "./")
{
    let whiteArg = white.asRubyArgument(name: "white", type: nil)
    let silverArg = silver.asRubyArgument(name: "silver", type: nil)
    let roseGoldArg = roseGold.asRubyArgument(name: "rose_gold", type: nil)
    let goldArg = gold.asRubyArgument(name: "gold", type: nil)
    let forceDeviceTypeArg = forceDeviceType.asRubyArgument(name: "force_device_type", type: nil)
    let useLegacyIphone5sArg = useLegacyIphone5s.asRubyArgument(name: "use_legacy_iphone5s", type: nil)
    let useLegacyIphone6sArg = useLegacyIphone6s.asRubyArgument(name: "use_legacy_iphone6s", type: nil)
    let useLegacyIphone7Arg = useLegacyIphone7.asRubyArgument(name: "use_legacy_iphone7", type: nil)
    let useLegacyIphonexArg = useLegacyIphonex.asRubyArgument(name: "use_legacy_iphonex", type: nil)
    let useLegacyIphonexrArg = useLegacyIphonexr.asRubyArgument(name: "use_legacy_iphonexr", type: nil)
    let useLegacyIphonexsArg = useLegacyIphonexs.asRubyArgument(name: "use_legacy_iphonexs", type: nil)
    let useLegacyIphonexsmaxArg = useLegacyIphonexsmax.asRubyArgument(name: "use_legacy_iphonexsmax", type: nil)
    let forceOrientationBlockArg = RubyCommand.Argument(name: "force_orientation_block", value: forceOrientationBlock, type: .stringClosure)
    let debugModeArg = debugMode.asRubyArgument(name: "debug_mode", type: nil)
    let resumeArg = resume.asRubyArgument(name: "resume", type: nil)
    let usePlatformArg = RubyCommand.Argument(name: "use_platform", value: usePlatform, type: nil)
    let pathArg = RubyCommand.Argument(name: "path", value: path, type: nil)
    let array: [RubyCommand.Argument?] = [whiteArg,
                                          silverArg,
                                          roseGoldArg,
                                          goldArg,
                                          forceDeviceTypeArg,
                                          useLegacyIphone5sArg,
                                          useLegacyIphone6sArg,
                                          useLegacyIphone7Arg,
                                          useLegacyIphonexArg,
                                          useLegacyIphonexrArg,
                                          useLegacyIphonexsArg,
                                          useLegacyIphonexsmaxArg,
                                          forceOrientationBlockArg,
                                          debugModeArg,
                                          resumeArg,
                                          usePlatformArg,
                                          pathArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "frameit", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Runs test coverage reports for your Xcode project

 Generate summarized code coverage reports using [gcovr](http://gcovr.com/)
 */
public func gcovr() {
    let args: [RubyCommand.Argument] = []
    let command = RubyCommand(commandID: "", methodName: "gcovr", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Get the build number of your project

 - parameters:
   - xcodeproj: optional, you must specify the path to your main Xcode project if it is not in the project root directory
   - hideErrorWhenVersioningDisabled: Used during `fastlane init` to hide the error message

 This action will return the current build number set on your project.
 You first have to set up your Xcode project, if you haven't done it already: [https://developer.apple.com/library/ios/qa/qa1827/_index.html](https://developer.apple.com/library/ios/qa/qa1827/_index.html).
 */
@discardableResult public func getBuildNumber(xcodeproj: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                              hideErrorWhenVersioningDisabled: OptionalConfigValue<Bool> = .fastlaneDefault(false)) -> String
{
    let xcodeprojArg = xcodeproj.asRubyArgument(name: "xcodeproj", type: nil)
    let hideErrorWhenVersioningDisabledArg = hideErrorWhenVersioningDisabled.asRubyArgument(name: "hide_error_when_versioning_disabled", type: nil)
    let array: [RubyCommand.Argument?] = [xcodeprojArg,
                                          hideErrorWhenVersioningDisabledArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "get_build_number", className: nil, args: args)
    return runner.executeCommand(command)
}

/**
 Get the build number from the current repository

 - parameter useHgRevisionNumber: Use hg revision number instead of hash (ignored for non-hg repos)

 - returns: The build number from the current repository

 This action will get the **build number** according to what the SCM HEAD reports.
 Currently supported SCMs are svn (uses root revision), git-svn (uses svn revision), git (uses short hash) and mercurial (uses short hash or revision number).
 There is an option, `:use_hg_revision_number`, which allows to use mercurial revision number instead of hash.
 */
public func getBuildNumberRepository(useHgRevisionNumber: OptionalConfigValue<Bool> = .fastlaneDefault(false)) {
    let useHgRevisionNumberArg = useHgRevisionNumber.asRubyArgument(name: "use_hg_revision_number", type: nil)
    let array: [RubyCommand.Argument?] = [useHgRevisionNumberArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "get_build_number_repository", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Create new iOS code signing certificates (via _cert_)

 - parameters:
   - development: Create a development certificate instead of a distribution one
   - type: Create specific certificate type (takes precedence over :development)
   - force: Create a certificate even if an existing certificate exists
   - generateAppleCerts: Create a certificate type for Xcode 11 and later (Apple Development or Apple Distribution)
   - apiKeyPath: Path to your App Store Connect API Key JSON file (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-json-file)
   - apiKey: Your App Store Connect API Key information (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-hash-option)
   - username: Your Apple ID Username
   - teamId: The ID of your Developer Portal team if you're in multiple teams
   - teamName: The name of your Developer Portal team if you're in multiple teams
   - filename: The filename of certificate to store
   - outputPath: The path to a directory in which all certificates and private keys should be stored
   - keychainPath: Path to a custom keychain
   - keychainPassword: This might be required the first time you access certificates on a new mac. For the login/default keychain this is your macOS account password
   - skipSetPartitionList: Skips setting the partition list (which can sometimes take a long time). Setting the partition list is usually needed to prevent Xcode from prompting to allow a cert to be used for signing
   - platform: Set the provisioning profile's platform (ios, macos, tvos)

 **Important**: It is recommended to use [match](https://docs.fastlane.tools/actions/match/) according to the [codesigning.guide](https://codesigning.guide) for generating and maintaining your certificates. Use _cert_ directly only if you want full control over what's going on and know more about codesigning.
 Use this action to download the latest code signing identity.
 */
public func getCertificates(development: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                            type: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            force: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                            generateAppleCerts: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                            apiKeyPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            apiKey: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                            username: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            teamId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            teamName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            filename: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            outputPath: String = ".",
                            keychainPath: String,
                            keychainPassword: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            skipSetPartitionList: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                            platform: String = "ios")
{
    let developmentArg = development.asRubyArgument(name: "development", type: nil)
    let typeArg = type.asRubyArgument(name: "type", type: nil)
    let forceArg = force.asRubyArgument(name: "force", type: nil)
    let generateAppleCertsArg = generateAppleCerts.asRubyArgument(name: "generate_apple_certs", type: nil)
    let apiKeyPathArg = apiKeyPath.asRubyArgument(name: "api_key_path", type: nil)
    let apiKeyArg = apiKey.asRubyArgument(name: "api_key", type: nil)
    let usernameArg = username.asRubyArgument(name: "username", type: nil)
    let teamIdArg = teamId.asRubyArgument(name: "team_id", type: nil)
    let teamNameArg = teamName.asRubyArgument(name: "team_name", type: nil)
    let filenameArg = filename.asRubyArgument(name: "filename", type: nil)
    let outputPathArg = RubyCommand.Argument(name: "output_path", value: outputPath, type: nil)
    let keychainPathArg = RubyCommand.Argument(name: "keychain_path", value: keychainPath, type: nil)
    let keychainPasswordArg = keychainPassword.asRubyArgument(name: "keychain_password", type: nil)
    let skipSetPartitionListArg = skipSetPartitionList.asRubyArgument(name: "skip_set_partition_list", type: nil)
    let platformArg = RubyCommand.Argument(name: "platform", value: platform, type: nil)
    let array: [RubyCommand.Argument?] = [developmentArg,
                                          typeArg,
                                          forceArg,
                                          generateAppleCertsArg,
                                          apiKeyPathArg,
                                          apiKeyArg,
                                          usernameArg,
                                          teamIdArg,
                                          teamNameArg,
                                          filenameArg,
                                          outputPathArg,
                                          keychainPathArg,
                                          keychainPasswordArg,
                                          skipSetPartitionListArg,
                                          platformArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "get_certificates", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 This will verify if a given release version is available on GitHub

 - parameters:
   - url: The path to your repo, e.g. 'KrauseFx/fastlane'
   - serverUrl: The server url. e.g. 'https://your.github.server/api/v3' (Default: 'https://api.github.com')
   - version: The version tag of the release to check
   - apiToken: GitHub Personal Token (required for private repositories)
   - apiBearer: Use a Bearer authorization token. Usually generated by GitHub Apps, e.g. GitHub Actions GITHUB_TOKEN environment variable

 This will return all information about a release. For example:|
 |
 ```no-highlight|
 {|
   "url"=>"https://api.github.com/repos/KrauseFx/fastlane/releases/1537713",|
    "assets_url"=>"https://api.github.com/repos/KrauseFx/fastlane/releases/1537713/assets",|
    "upload_url"=>"https://uploads.github.com/repos/KrauseFx/fastlane/releases/1537713/assets{?name}",|
    "html_url"=>"https://github.com/fastlane/fastlane/releases/tag/1.8.0",|
    "id"=>1537713,|
    "tag_name"=>"1.8.0",|
    "target_commitish"=>"master",|
    "name"=>"1.8.0 Switch Lanes & Pass Parameters",|
    "draft"=>false,|
    "author"=>|
     {"login"=>"KrauseFx",|
      "id"=>869950,|
      "avatar_url"=>"https://avatars.githubusercontent.com/u/869950?v=3",|
      "gravatar_id"=>"",|
      "url"=>"https://api.github.com/users/KrauseFx",|
      "html_url"=>"https://github.com/fastlane",|
      "followers_url"=>"https://api.github.com/users/KrauseFx/followers",|
      "following_url"=>"https://api.github.com/users/KrauseFx/following{/other_user}",|
      "gists_url"=>"https://api.github.com/users/KrauseFx/gists{/gist_id}",|
      "starred_url"=>"https://api.github.com/users/KrauseFx/starred{/owner}{/repo}",|
      "subscriptions_url"=>"https://api.github.com/users/KrauseFx/subscriptions",|
      "organizations_url"=>"https://api.github.com/users/KrauseFx/orgs",|
      "repos_url"=>"https://api.github.com/users/KrauseFx/repos",|
      "events_url"=>"https://api.github.com/users/KrauseFx/events{/privacy}",|
      "received_events_url"=>"https://api.github.com/users/KrauseFx/received_events",|
      "type"=>"User",|
      "site_admin"=>false},|
    "prerelease"=>false,|
    "created_at"=>"2015-07-14T23:33:01Z",|
    "published_at"=>"2015-07-14T23:44:10Z",|
    "assets"=>[],|
    "tarball_url"=>"https://api.github.com/repos/KrauseFx/fastlane/tarball/1.8.0",|
    "zipball_url"=>"https://api.github.com/repos/KrauseFx/fastlane/zipball/1.8.0",|
    "body"=> ...Markdown...|
   "This is one of the biggest updates of _fastlane_ yet"|
 }|
 ```|
 >|
 */
public func getGithubRelease(url: String,
                             serverUrl: String = "https://api.github.com",
                             version: String,
                             apiToken: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             apiBearer: OptionalConfigValue<String?> = .fastlaneDefault(nil))
{
    let urlArg = RubyCommand.Argument(name: "url", value: url, type: nil)
    let serverUrlArg = RubyCommand.Argument(name: "server_url", value: serverUrl, type: nil)
    let versionArg = RubyCommand.Argument(name: "version", value: version, type: nil)
    let apiTokenArg = apiToken.asRubyArgument(name: "api_token", type: nil)
    let apiBearerArg = apiBearer.asRubyArgument(name: "api_bearer", type: nil)
    let array: [RubyCommand.Argument?] = [urlArg,
                                          serverUrlArg,
                                          versionArg,
                                          apiTokenArg,
                                          apiBearerArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "get_github_release", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Returns value from Info.plist of your project as native Ruby data structures

 - parameters:
   - key: Name of parameter
   - path: Path to plist file you want to read

 Get a value from a plist file, which can be used to fetch the app identifier and more information about your app
 */
@discardableResult public func getInfoPlistValue(key: String,
                                                 path: String) -> String
{
    let keyArg = RubyCommand.Argument(name: "key", value: key, type: nil)
    let pathArg = RubyCommand.Argument(name: "path", value: path, type: nil)
    let array: [RubyCommand.Argument?] = [keyArg,
                                          pathArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "get_info_plist_value", className: nil, args: args)
    return runner.executeCommand(command)
}

/**
 Returns a value from Info.plist inside a .ipa file

 - parameters:
   - key: Name of parameter
   - ipa: Path to IPA

 - returns: Returns the value in the .ipa's Info.plist corresponding to the passed in Key

 This is useful for introspecting Info.plist files for `.ipa` files that have already been built.
 */
@discardableResult public func getIpaInfoPlistValue(key: String,
                                                    ipa: String) -> String
{
    let keyArg = RubyCommand.Argument(name: "key", value: key, type: nil)
    let ipaArg = RubyCommand.Argument(name: "ipa", value: ipa, type: nil)
    let array: [RubyCommand.Argument?] = [keyArg,
                                          ipaArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "get_ipa_info_plist_value", className: nil, args: args)
    return runner.executeCommand(command)
}

/**
 Obtain publishing rights for custom apps on Managed Google Play Store

 - parameters:
   - jsonKey: The path to a file containing service account JSON, used to authenticate with Google
   - jsonKeyData: The raw service account JSON data used to authenticate with Google

 - returns: An URI to obtain publishing rights for custom apps on Managed Play Store

 If you haven't done so before, start by following the first two steps of Googles ["Get started with custom app publishing"](https://developers.google.com/android/work/play/custom-app-api/get-started) -> ["Preliminary setup"](https://developers.google.com/android/work/play/custom-app-api/get-started#preliminary_setup) instructions:
 "[Enable the Google Play Custom App Publishing API](https://developers.google.com/android/work/play/custom-app-api/get-started#enable_the_google_play_custom_app_publishing_api)" and "[Create a service account](https://developers.google.com/android/work/play/custom-app-api/get-started#create_a_service_account)".
 You need the "service account's private key file" to continue.
 Run the action and supply the "private key file" to it as the `json_key` parameter. The command will output a URL to visit. After logging in you are redirected to a page that outputs your "Developer Account ID" - take note of that, you will need it to be able to use [`create_app_on_managed_play_store`](https://docs.fastlane.tools/actions/create_app_on_managed_play_store/).
 */
public func getManagedPlayStorePublishingRights(jsonKey: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                                jsonKeyData: OptionalConfigValue<String?> = .fastlaneDefault(nil))
{
    let jsonKeyArg = jsonKey.asRubyArgument(name: "json_key", type: nil)
    let jsonKeyDataArg = jsonKeyData.asRubyArgument(name: "json_key_data", type: nil)
    let array: [RubyCommand.Argument?] = [jsonKeyArg,
                                          jsonKeyDataArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "get_managed_play_store_publishing_rights", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Generates a provisioning profile, saving it in the current folder (via _sigh_)

 - parameters:
   - adhoc: Setting this flag will generate AdHoc profiles instead of App Store Profiles
   - developerId: Setting this flag will generate Developer ID profiles instead of App Store Profiles
   - development: Renew the development certificate instead of the production one
   - skipInstall: By default, the certificate will be added to your local machine. Setting this flag will skip this action
   - force: Renew provisioning profiles regardless of its state - to automatically add all devices for ad hoc profiles
   - includeMacInProfiles: Include Apple Silicon Mac devices in provisioning profiles for iOS/iPadOS apps
   - appIdentifier: The bundle identifier of your app
   - apiKeyPath: Path to your App Store Connect API Key JSON file (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-json-file)
   - apiKey: Your App Store Connect API Key information (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-hash-option)
   - username: Your Apple ID Username
   - teamId: The ID of your Developer Portal team if you're in multiple teams
   - teamName: The name of your Developer Portal team if you're in multiple teams
   - provisioningName: The name of the profile that is used on the Apple Developer Portal
   - ignoreProfilesWithDifferentName: Use in combination with :provisioning_name - when true only profiles matching this exact name will be downloaded
   - outputPath: Directory in which the profile should be stored
   - certId: The ID of the code signing certificate to use (e.g. 78ADL6LVAA)
   - certOwnerName: The certificate name to use for new profiles, or to renew with. (e.g. "Felix Krause")
   - filename: Filename to use for the generated provisioning profile (must include .mobileprovision)
   - skipFetchProfiles: Skips the verification of existing profiles which is useful if you have thousands of profiles
   - includeAllCertificates: Include all matching certificates in the provisioning profile. Works only for the 'development' provisioning profile type
   - skipCertificateVerification: Skips the verification of the certificates for every existing profiles. This will make sure the provisioning profile can be used on the local machine
   - platform: Set the provisioning profile's platform (i.e. ios, tvos, macos, catalyst)
   - readonly: Only fetch existing profile, don't generate new ones
   - templateName: The name of provisioning profile template. If the developer account has provisioning profile templates (aka: custom entitlements), the template name can be found by inspecting the Entitlements drop-down while creating/editing a provisioning profile (e.g. "Apple Pay Pass Suppression Development")
   - failOnNameTaken: Should the command fail if it was about to create a duplicate of an existing provisioning profile. It can happen due to issues on Apple Developer Portal, when profile to be recreated was not properly deleted first
   - cachedCertificates: A list of cached certificates
   - cachedDevices: A list of cached devices
   - cachedBundleIds: A list of cached bundle ids
   - cachedProfiles: A list of cached bundle ids

 - returns: The UUID of the profile sigh just fetched/generated

 **Note**: It is recommended to use [match](https://docs.fastlane.tools/actions/match/) according to the [codesigning.guide](https://codesigning.guide) for generating and maintaining your provisioning profiles. Use _sigh_ directly only if you want full control over what's going on and know more about codesigning.
 */
@discardableResult public func getProvisioningProfile(adhoc: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                                      developerId: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                                      development: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                                      skipInstall: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                                      force: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                                      includeMacInProfiles: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                                      appIdentifier: String,
                                                      apiKeyPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                                      apiKey: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                                                      username: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                                      teamId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                                      teamName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                                      provisioningName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                                      ignoreProfilesWithDifferentName: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                                      outputPath: String = ".",
                                                      certId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                                      certOwnerName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                                      filename: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                                      skipFetchProfiles: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                                      includeAllCertificates: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                                      skipCertificateVerification: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                                      platform: Any = "ios",
                                                      readonly: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                                      templateName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                                      failOnNameTaken: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                                      cachedCertificates: Any? = nil,
                                                      cachedDevices: Any? = nil,
                                                      cachedBundleIds: Any? = nil,
                                                      cachedProfiles: Any? = nil) -> String
{
    let adhocArg = adhoc.asRubyArgument(name: "adhoc", type: nil)
    let developerIdArg = developerId.asRubyArgument(name: "developer_id", type: nil)
    let developmentArg = development.asRubyArgument(name: "development", type: nil)
    let skipInstallArg = skipInstall.asRubyArgument(name: "skip_install", type: nil)
    let forceArg = force.asRubyArgument(name: "force", type: nil)
    let includeMacInProfilesArg = includeMacInProfiles.asRubyArgument(name: "include_mac_in_profiles", type: nil)
    let appIdentifierArg = RubyCommand.Argument(name: "app_identifier", value: appIdentifier, type: nil)
    let apiKeyPathArg = apiKeyPath.asRubyArgument(name: "api_key_path", type: nil)
    let apiKeyArg = apiKey.asRubyArgument(name: "api_key", type: nil)
    let usernameArg = username.asRubyArgument(name: "username", type: nil)
    let teamIdArg = teamId.asRubyArgument(name: "team_id", type: nil)
    let teamNameArg = teamName.asRubyArgument(name: "team_name", type: nil)
    let provisioningNameArg = provisioningName.asRubyArgument(name: "provisioning_name", type: nil)
    let ignoreProfilesWithDifferentNameArg = ignoreProfilesWithDifferentName.asRubyArgument(name: "ignore_profiles_with_different_name", type: nil)
    let outputPathArg = RubyCommand.Argument(name: "output_path", value: outputPath, type: nil)
    let certIdArg = certId.asRubyArgument(name: "cert_id", type: nil)
    let certOwnerNameArg = certOwnerName.asRubyArgument(name: "cert_owner_name", type: nil)
    let filenameArg = filename.asRubyArgument(name: "filename", type: nil)
    let skipFetchProfilesArg = skipFetchProfiles.asRubyArgument(name: "skip_fetch_profiles", type: nil)
    let includeAllCertificatesArg = includeAllCertificates.asRubyArgument(name: "include_all_certificates", type: nil)
    let skipCertificateVerificationArg = skipCertificateVerification.asRubyArgument(name: "skip_certificate_verification", type: nil)
    let platformArg = RubyCommand.Argument(name: "platform", value: platform, type: nil)
    let readonlyArg = readonly.asRubyArgument(name: "readonly", type: nil)
    let templateNameArg = templateName.asRubyArgument(name: "template_name", type: nil)
    let failOnNameTakenArg = failOnNameTaken.asRubyArgument(name: "fail_on_name_taken", type: nil)
    let cachedCertificatesArg = RubyCommand.Argument(name: "cached_certificates", value: cachedCertificates, type: nil)
    let cachedDevicesArg = RubyCommand.Argument(name: "cached_devices", value: cachedDevices, type: nil)
    let cachedBundleIdsArg = RubyCommand.Argument(name: "cached_bundle_ids", value: cachedBundleIds, type: nil)
    let cachedProfilesArg = RubyCommand.Argument(name: "cached_profiles", value: cachedProfiles, type: nil)
    let array: [RubyCommand.Argument?] = [adhocArg,
                                          developerIdArg,
                                          developmentArg,
                                          skipInstallArg,
                                          forceArg,
                                          includeMacInProfilesArg,
                                          appIdentifierArg,
                                          apiKeyPathArg,
                                          apiKeyArg,
                                          usernameArg,
                                          teamIdArg,
                                          teamNameArg,
                                          provisioningNameArg,
                                          ignoreProfilesWithDifferentNameArg,
                                          outputPathArg,
                                          certIdArg,
                                          certOwnerNameArg,
                                          filenameArg,
                                          skipFetchProfilesArg,
                                          includeAllCertificatesArg,
                                          skipCertificateVerificationArg,
                                          platformArg,
                                          readonlyArg,
                                          templateNameArg,
                                          failOnNameTakenArg,
                                          cachedCertificatesArg,
                                          cachedDevicesArg,
                                          cachedBundleIdsArg,
                                          cachedProfilesArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "get_provisioning_profile", className: nil, args: args)
    return runner.executeCommand(command)
}

/**
 Ensure a valid push profile is active, creating a new one if needed (via _pem_)

 - parameters:
   - platform: Set certificate's platform. Used for creation of production & development certificates. Supported platforms: ios, macos
   - development: Renew the development push certificate instead of the production one
   - websitePush: Create a Website Push certificate
   - generateP12: Generate a p12 file additionally to a PEM file
   - activeDaysLimit: If the current certificate is active for less than this number of days, generate a new one
   - force: Create a new push certificate, even if the current one is active for 30 (or PEM_ACTIVE_DAYS_LIMIT) more days
   - savePrivateKey: Set to save the private RSA key
   - appIdentifier: The bundle identifier of your app
   - username: Your Apple ID Username
   - teamId: The ID of your Developer Portal team if you're in multiple teams
   - teamName: The name of your Developer Portal team if you're in multiple teams
   - p12Password: The password that is used for your p12 file
   - pemName: The file name of the generated .pem file
   - outputPath: The path to a directory in which all certificates and private keys should be stored
   - newProfile: Block that is called if there is a new profile

 Additionally to the available options, you can also specify a block that only gets executed if a new profile was created. You can use it to upload the new profile to your server.
 Use it like this:|
 |
 ```ruby|
 get_push_certificate(|
   new_profile: proc do|
     # your upload code|
   end|
 )|
 ```|
 >|
 */
public func getPushCertificate(platform: String = "ios",
                               development: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                               websitePush: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                               generateP12: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                               activeDaysLimit: Int = 30,
                               force: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                               savePrivateKey: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                               appIdentifier: String,
                               username: String,
                               teamId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               teamName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               p12Password: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               pemName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               outputPath: String = ".",
                               newProfile: ((String) -> Void)? = nil)
{
    let platformArg = RubyCommand.Argument(name: "platform", value: platform, type: nil)
    let developmentArg = development.asRubyArgument(name: "development", type: nil)
    let websitePushArg = websitePush.asRubyArgument(name: "website_push", type: nil)
    let generateP12Arg = generateP12.asRubyArgument(name: "generate_p12", type: nil)
    let activeDaysLimitArg = RubyCommand.Argument(name: "active_days_limit", value: activeDaysLimit, type: nil)
    let forceArg = force.asRubyArgument(name: "force", type: nil)
    let savePrivateKeyArg = savePrivateKey.asRubyArgument(name: "save_private_key", type: nil)
    let appIdentifierArg = RubyCommand.Argument(name: "app_identifier", value: appIdentifier, type: nil)
    let usernameArg = RubyCommand.Argument(name: "username", value: username, type: nil)
    let teamIdArg = teamId.asRubyArgument(name: "team_id", type: nil)
    let teamNameArg = teamName.asRubyArgument(name: "team_name", type: nil)
    let p12PasswordArg = p12Password.asRubyArgument(name: "p12_password", type: nil)
    let pemNameArg = pemName.asRubyArgument(name: "pem_name", type: nil)
    let outputPathArg = RubyCommand.Argument(name: "output_path", value: outputPath, type: nil)
    let newProfileArg = RubyCommand.Argument(name: "new_profile", value: newProfile, type: .stringClosure)
    let array: [RubyCommand.Argument?] = [platformArg,
                                          developmentArg,
                                          websitePushArg,
                                          generateP12Arg,
                                          activeDaysLimitArg,
                                          forceArg,
                                          savePrivateKeyArg,
                                          appIdentifierArg,
                                          usernameArg,
                                          teamIdArg,
                                          teamNameArg,
                                          p12PasswordArg,
                                          pemNameArg,
                                          outputPathArg,
                                          newProfileArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "get_push_certificate", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Get the version number of your project

 - parameters:
   - xcodeproj: Path to the Xcode project to read version number from, or its containing directory, optional. If omitted, or if a directory is passed instead, it will use the first Xcode project found within the given directory, or the project root directory if none is passed
   - target: Target name, optional. Will be needed if you have more than one non-test target to avoid being prompted to select one
   - configuration: Configuration name, optional. Will be needed if you have altered the configurations from the default or your version number depends on the configuration selected

 This action will return the current version number set on your project. It first looks in the plist and then for '$(MARKETING_VERSION)' in the build settings.
 */
@discardableResult public func getVersionNumber(xcodeproj: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                                target: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                                configuration: OptionalConfigValue<String?> = .fastlaneDefault(nil)) -> String
{
    let xcodeprojArg = xcodeproj.asRubyArgument(name: "xcodeproj", type: nil)
    let targetArg = target.asRubyArgument(name: "target", type: nil)
    let configurationArg = configuration.asRubyArgument(name: "configuration", type: nil)
    let array: [RubyCommand.Argument?] = [xcodeprojArg,
                                          targetArg,
                                          configurationArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "get_version_number", className: nil, args: args)
    return runner.executeCommand(command)
}

/**
 Directly add the given file or all files

 - parameters:
   - path: The file(s) and path(s) you want to add
   - shellEscape: Shell escapes paths (set to false if using wildcards or manually escaping spaces in :path)
   - force: Allow adding otherwise ignored files
   - pathspec: **DEPRECATED!** Use `--path` instead - The pathspec you want to add files from
 */
public func gitAdd(path: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                   shellEscape: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                   force: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                   pathspec: OptionalConfigValue<String?> = .fastlaneDefault(nil))
{
    let pathArg = path.asRubyArgument(name: "path", type: nil)
    let shellEscapeArg = shellEscape.asRubyArgument(name: "shell_escape", type: nil)
    let forceArg = force.asRubyArgument(name: "force", type: nil)
    let pathspecArg = pathspec.asRubyArgument(name: "pathspec", type: nil)
    let array: [RubyCommand.Argument?] = [pathArg,
                                          shellEscapeArg,
                                          forceArg,
                                          pathspecArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "git_add", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Returns the name of the current git branch, possibly as managed by CI ENV vars

 If no branch could be found, this action will return an empty string. If `FL_GIT_BRANCH_DONT_USE_ENV_VARS` is `true`, it'll ignore CI ENV vars. This is a wrapper for the internal action Actions.git_branch
 */
@discardableResult public func gitBranch() -> String {
    let args: [RubyCommand.Argument] = []
    let command = RubyCommand(commandID: "", methodName: "git_branch", className: nil, args: args)
    return runner.executeCommand(command)
}

/**
 Directly commit the given file with the given message

 - parameters:
   - path: The file(s) or directory(ies) you want to commit. You can pass an array of multiple file-paths or fileglobs "*.txt" to commit all matching files. The files already staged but not specified and untracked files won't be committed
   - message: The commit message that should be used
   - skipGitHooks: Set to true to pass `--no-verify` to git
   - allowNothingToCommit: Set to true to allow commit without any git changes in the files you want to commit
 */
public func gitCommit(path: [String],
                      message: String,
                      skipGitHooks: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                      allowNothingToCommit: OptionalConfigValue<Bool> = .fastlaneDefault(false))
{
    let pathArg = RubyCommand.Argument(name: "path", value: path, type: nil)
    let messageArg = RubyCommand.Argument(name: "message", value: message, type: nil)
    let skipGitHooksArg = skipGitHooks.asRubyArgument(name: "skip_git_hooks", type: nil)
    let allowNothingToCommitArg = allowNothingToCommit.asRubyArgument(name: "allow_nothing_to_commit", type: nil)
    let array: [RubyCommand.Argument?] = [pathArg,
                                          messageArg,
                                          skipGitHooksArg,
                                          allowNothingToCommitArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "git_commit", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Executes a simple git pull command

 - parameters:
   - onlyTags: Simply pull the tags, and not bring new commits to the current branch from the remote
   - rebase: Rebase on top of the remote branch instead of merge
 */
public func gitPull(onlyTags: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                    rebase: OptionalConfigValue<Bool> = .fastlaneDefault(false))
{
    let onlyTagsArg = onlyTags.asRubyArgument(name: "only_tags", type: nil)
    let rebaseArg = rebase.asRubyArgument(name: "rebase", type: nil)
    let array: [RubyCommand.Argument?] = [onlyTagsArg,
                                          rebaseArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "git_pull", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Returns the name of the current git remote default branch

 - parameter remoteName: The remote repository to check

 If no default remote branch could be found, this action will return nil. This is a wrapper for the internal action Actions.git_default_remote_branch_name
 */
@discardableResult public func gitRemoteBranch(remoteName: OptionalConfigValue<String?> = .fastlaneDefault(nil)) -> String {
    let remoteNameArg = remoteName.asRubyArgument(name: "remote_name", type: nil)
    let array: [RubyCommand.Argument?] = [remoteNameArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "git_remote_branch", className: nil, args: args)
    return runner.executeCommand(command)
}

/**
 Executes a git submodule update command

 - parameters:
   - recursive: Should the submodules be updated recursively?
   - init: Should the submodules be initiated before update?
 */
public func gitSubmoduleUpdate(recursive: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                               init: OptionalConfigValue<Bool> = .fastlaneDefault(false))
{
    let recursiveArg = recursive.asRubyArgument(name: "recursive", type: nil)
    let initArg = `init`.asRubyArgument(name: "init", type: nil)
    let array: [RubyCommand.Argument?] = [recursiveArg,
                                          initArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "git_submodule_update", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Checks if the git tag with the given name exists in the current repo

 - parameters:
   - tag: The tag name that should be checked
   - remote: Whether to check remote. Defaults to `false`
   - remoteName: The remote to check. Defaults to `origin`

 - returns: Boolean value whether the tag exists or not
 */
@discardableResult public func gitTagExists(tag: String,
                                            remote: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                            remoteName: String = "origin") -> Bool
{
    let tagArg = RubyCommand.Argument(name: "tag", value: tag, type: nil)
    let remoteArg = remote.asRubyArgument(name: "remote", type: nil)
    let remoteNameArg = RubyCommand.Argument(name: "remote_name", value: remoteName, type: nil)
    let array: [RubyCommand.Argument?] = [tagArg,
                                          remoteArg,
                                          remoteNameArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "git_tag_exists", className: nil, args: args)
    return parseBool(fromString: runner.executeCommand(command))
}

/**
 Call a GitHub API endpoint and get the resulting JSON response

 - parameters:
   - serverUrl: The server url. e.g. 'https://your.internal.github.host/api/v3' (Default: 'https://api.github.com')
   - apiToken: Personal API Token for GitHub - generate one at https://github.com/settings/tokens
   - apiBearer: Use a Bearer authorization token. Usually generated by GitHub Apps, e.g. GitHub Actions GITHUB_TOKEN environment variable
   - httpMethod: The HTTP method. e.g. GET / POST
   - body: The request body in JSON or hash format
   - rawBody: The request body taken verbatim instead of as JSON, useful for file uploads
   - path: The endpoint path. e.g. '/repos/:owner/:repo/readme'
   - url: The complete full url - used instead of path. e.g. 'https://uploads.github.com/repos/fastlane...'
   - errorHandlers: Optional error handling hash based on status code, or pass '*' to handle all errors
   - headers: Optional headers to apply
   - secure: Optionally disable secure requests (ssl_verify_peer)

 - returns: A hash including the HTTP status code (:status), the response body (:body), and if valid JSON has been returned the parsed JSON (:json).

 Calls any GitHub API endpoint. You must provide your GitHub Personal token (get one from [https://github.com/settings/tokens/new](https://github.com/settings/tokens/new)).
 Out parameters provide the status code and the full response JSON if valid, otherwise the raw response body.
 Documentation: [https://developer.github.com/v3](https://developer.github.com/v3).
 */
public func githubApi(serverUrl: String = "https://api.github.com",
                      apiToken: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      apiBearer: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      httpMethod: String = "GET",
                      body: [String: Any] = [:],
                      rawBody: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      path: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      url: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      errorHandlers: [String: Any] = [:],
                      headers: [String: Any] = [:],
                      secure: OptionalConfigValue<Bool> = .fastlaneDefault(true))
{
    let serverUrlArg = RubyCommand.Argument(name: "server_url", value: serverUrl, type: nil)
    let apiTokenArg = apiToken.asRubyArgument(name: "api_token", type: nil)
    let apiBearerArg = apiBearer.asRubyArgument(name: "api_bearer", type: nil)
    let httpMethodArg = RubyCommand.Argument(name: "http_method", value: httpMethod, type: nil)
    let bodyArg = RubyCommand.Argument(name: "body", value: body, type: nil)
    let rawBodyArg = rawBody.asRubyArgument(name: "raw_body", type: nil)
    let pathArg = path.asRubyArgument(name: "path", type: nil)
    let urlArg = url.asRubyArgument(name: "url", type: nil)
    let errorHandlersArg = RubyCommand.Argument(name: "error_handlers", value: errorHandlers, type: nil)
    let headersArg = RubyCommand.Argument(name: "headers", value: headers, type: nil)
    let secureArg = secure.asRubyArgument(name: "secure", type: nil)
    let array: [RubyCommand.Argument?] = [serverUrlArg,
                                          apiTokenArg,
                                          apiBearerArg,
                                          httpMethodArg,
                                          bodyArg,
                                          rawBodyArg,
                                          pathArg,
                                          urlArg,
                                          errorHandlersArg,
                                          headersArg,
                                          secureArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "github_api", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Retrieves release names for a Google Play track

 - parameters:
   - packageName: The package name of the application to use
   - track: The track of the application to use. The default available tracks are: production, beta, alpha, internal
   - key: **DEPRECATED!** Use `--json_key` instead - The p12 File used to authenticate with Google
   - issuer: **DEPRECATED!** Use `--json_key` instead - The issuer of the p12 file (email address of the service account)
   - jsonKey: The path to a file containing service account JSON, used to authenticate with Google
   - jsonKeyData: The raw service account JSON data used to authenticate with Google
   - rootUrl: Root URL for the Google Play API. The provided URL will be used for API calls in place of https://www.googleapis.com/
   - timeout: Timeout for read, open, and send (in seconds)

 - returns: Array of strings representing the release names for the given Google Play track

 More information: [https://docs.fastlane.tools/actions/supply/](https://docs.fastlane.tools/actions/supply/)
 */
public func googlePlayTrackReleaseNames(packageName: String,
                                        track: String = "production",
                                        key: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        issuer: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        jsonKey: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        jsonKeyData: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        rootUrl: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        timeout: Int = 300)
{
    let packageNameArg = RubyCommand.Argument(name: "package_name", value: packageName, type: nil)
    let trackArg = RubyCommand.Argument(name: "track", value: track, type: nil)
    let keyArg = key.asRubyArgument(name: "key", type: nil)
    let issuerArg = issuer.asRubyArgument(name: "issuer", type: nil)
    let jsonKeyArg = jsonKey.asRubyArgument(name: "json_key", type: nil)
    let jsonKeyDataArg = jsonKeyData.asRubyArgument(name: "json_key_data", type: nil)
    let rootUrlArg = rootUrl.asRubyArgument(name: "root_url", type: nil)
    let timeoutArg = RubyCommand.Argument(name: "timeout", value: timeout, type: nil)
    let array: [RubyCommand.Argument?] = [packageNameArg,
                                          trackArg,
                                          keyArg,
                                          issuerArg,
                                          jsonKeyArg,
                                          jsonKeyDataArg,
                                          rootUrlArg,
                                          timeoutArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "google_play_track_release_names", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Retrieves version codes for a Google Play track

 - parameters:
   - packageName: The package name of the application to use
   - track: The track of the application to use. The default available tracks are: production, beta, alpha, internal
   - key: **DEPRECATED!** Use `--json_key` instead - The p12 File used to authenticate with Google
   - issuer: **DEPRECATED!** Use `--json_key` instead - The issuer of the p12 file (email address of the service account)
   - jsonKey: The path to a file containing service account JSON, used to authenticate with Google
   - jsonKeyData: The raw service account JSON data used to authenticate with Google
   - rootUrl: Root URL for the Google Play API. The provided URL will be used for API calls in place of https://www.googleapis.com/
   - timeout: Timeout for read, open, and send (in seconds)

 - returns: Array of integers representing the version codes for the given Google Play track

 More information: [https://docs.fastlane.tools/actions/supply/](https://docs.fastlane.tools/actions/supply/)
 */
public func googlePlayTrackVersionCodes(packageName: String,
                                        track: String = "production",
                                        key: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        issuer: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        jsonKey: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        jsonKeyData: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        rootUrl: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        timeout: Int = 300)
{
    let packageNameArg = RubyCommand.Argument(name: "package_name", value: packageName, type: nil)
    let trackArg = RubyCommand.Argument(name: "track", value: track, type: nil)
    let keyArg = key.asRubyArgument(name: "key", type: nil)
    let issuerArg = issuer.asRubyArgument(name: "issuer", type: nil)
    let jsonKeyArg = jsonKey.asRubyArgument(name: "json_key", type: nil)
    let jsonKeyDataArg = jsonKeyData.asRubyArgument(name: "json_key_data", type: nil)
    let rootUrlArg = rootUrl.asRubyArgument(name: "root_url", type: nil)
    let timeoutArg = RubyCommand.Argument(name: "timeout", value: timeout, type: nil)
    let array: [RubyCommand.Argument?] = [packageNameArg,
                                          trackArg,
                                          keyArg,
                                          issuerArg,
                                          jsonKeyArg,
                                          jsonKeyDataArg,
                                          rootUrlArg,
                                          timeoutArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "google_play_track_version_codes", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 All gradle related actions, including building and testing your Android app

 - parameters:
   - task: The gradle task you want to execute, e.g. `assemble`, `bundle` or `test`. For tasks such as `assembleMyFlavorRelease` you should use gradle(task: 'assemble', flavor: 'Myflavor', build_type: 'Release')
   - flavor: The flavor that you want the task for, e.g. `MyFlavor`. If you are running the `assemble` task in a multi-flavor project, and you rely on Actions.lane_context[SharedValues::GRADLE_APK_OUTPUT_PATH] then you must specify a flavor here or else this value will be undefined
   - buildType: The build type that you want the task for, e.g. `Release`. Useful for some tasks such as `assemble`
   - tasks: The multiple gradle tasks that you want to execute, e.g. `[assembleDebug, bundleDebug]`
   - flags: All parameter flags you want to pass to the gradle command, e.g. `--exitcode --xml file.xml`
   - projectDir: The root directory of the gradle project
   - gradlePath: The path to your `gradlew`. If you specify a relative path, it is assumed to be relative to the `project_dir`
   - properties: Gradle properties to be exposed to the gradle script
   - systemProperties: Gradle system properties to be exposed to the gradle script
   - serial: Android serial, which device should be used for this command
   - printCommand: Control whether the generated Gradle command is printed as output before running it (true/false)
   - printCommandOutput: Control whether the output produced by given Gradle command is printed while running (true/false)

 - returns: The output of running the gradle task

 Run `./gradlew tasks` to get a list of all available gradle tasks for your project
 */
public func gradle(task: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   flavor: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   buildType: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   tasks: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                   flags: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   projectDir: String = ".",
                   gradlePath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   properties: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                   systemProperties: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                   serial: String = "",
                   printCommand: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                   printCommandOutput: OptionalConfigValue<Bool> = .fastlaneDefault(true))
{
    let taskArg = task.asRubyArgument(name: "task", type: nil)
    let flavorArg = flavor.asRubyArgument(name: "flavor", type: nil)
    let buildTypeArg = buildType.asRubyArgument(name: "build_type", type: nil)
    let tasksArg = tasks.asRubyArgument(name: "tasks", type: nil)
    let flagsArg = flags.asRubyArgument(name: "flags", type: nil)
    let projectDirArg = RubyCommand.Argument(name: "project_dir", value: projectDir, type: nil)
    let gradlePathArg = gradlePath.asRubyArgument(name: "gradle_path", type: nil)
    let propertiesArg = properties.asRubyArgument(name: "properties", type: nil)
    let systemPropertiesArg = systemProperties.asRubyArgument(name: "system_properties", type: nil)
    let serialArg = RubyCommand.Argument(name: "serial", value: serial, type: nil)
    let printCommandArg = printCommand.asRubyArgument(name: "print_command", type: nil)
    let printCommandOutputArg = printCommandOutput.asRubyArgument(name: "print_command_output", type: nil)
    let array: [RubyCommand.Argument?] = [taskArg,
                                          flavorArg,
                                          buildTypeArg,
                                          tasksArg,
                                          flagsArg,
                                          projectDirArg,
                                          gradlePathArg,
                                          propertiesArg,
                                          systemPropertiesArg,
                                          serialArg,
                                          printCommandArg,
                                          printCommandOutputArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "gradle", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Alias for the `build_app` action

 - parameters:
   - workspace: Path to the workspace file
   - project: Path to the project file
   - scheme: The project's scheme. Make sure it's marked as `Shared`
   - clean: Should the project be cleaned before building it?
   - outputDirectory: The directory in which the ipa file should be stored in
   - outputName: The name of the resulting ipa file
   - configuration: The configuration to use when building the app. Defaults to 'Release'
   - silent: Hide all information that's not necessary while building
   - codesigningIdentity: The name of the code signing identity to use. It has to match the name exactly. e.g. 'iPhone Distribution: SunApps GmbH'
   - skipPackageIpa: Should we skip packaging the ipa?
   - skipPackagePkg: Should we skip packaging the pkg?
   - includeSymbols: Should the ipa file include symbols?
   - includeBitcode: Should the ipa file include bitcode?
   - exportMethod: Method used to export the archive. Valid values are: app-store, validation, ad-hoc, package, enterprise, development, developer-id and mac-application
   - exportOptions: Path to an export options plist or a hash with export options. Use 'xcodebuild -help' to print the full set of available options
   - exportXcargs: Pass additional arguments to xcodebuild for the package phase. Be sure to quote the setting names and values e.g. OTHER_LDFLAGS="-ObjC -lstdc++"
   - skipBuildArchive: Export ipa from previously built xcarchive. Uses archive_path as source
   - skipArchive: After building, don't archive, effectively not including -archivePath param
   - skipCodesigning: Build without codesigning
   - catalystPlatform: Platform to build when using a Catalyst enabled app. Valid values are: ios, macos
   - installerCertName: Full name of 3rd Party Mac Developer Installer or Developer ID Installer certificate. Example: `3rd Party Mac Developer Installer: Your Company (ABC1234XWYZ)`
   - buildPath: The directory in which the archive should be stored in
   - archivePath: The path to the created archive
   - derivedDataPath: The directory where built products and other derived data will go
   - resultBundle: Should an Xcode result bundle be generated in the output directory
   - resultBundlePath: Path to the result bundle directory to create. Ignored if `result_bundle` if false
   - buildlogPath: The directory where to store the build log
   - sdk: The SDK that should be used for building the application
   - toolchain: The toolchain that should be used for building the application (e.g. com.apple.dt.toolchain.Swift_2_3, org.swift.30p620160816a)
   - destination: Use a custom destination for building the app
   - exportTeamId: Optional: Sometimes you need to specify a team id when exporting the ipa file
   - xcargs: Pass additional arguments to xcodebuild for the build phase. Be sure to quote the setting names and values e.g. OTHER_LDFLAGS="-ObjC -lstdc++"
   - xcconfig: Use an extra XCCONFIG file to build your app
   - suppressXcodeOutput: Suppress the output of xcodebuild to stdout. Output is still saved in buildlog_path
   - xcodebuildFormatter: xcodebuild formatter to use (ex: 'xcbeautify', 'xcbeautify --quieter', 'xcpretty', 'xcpretty -test'). Use empty string (ex: '') to disable any formatter (More information: https://docs.fastlane.tools/best-practices/xcodebuild-formatters/)
   - buildTimingSummary: Create a build timing summary
   - disableXcpretty: **DEPRECATED!** Use `xcodebuild_formatter: ''` instead - Disable xcpretty formatting of build output
   - xcprettyTestFormat: Use the test (RSpec style) format for build output
   - xcprettyFormatter: A custom xcpretty formatter to use
   - xcprettyReportJunit: Have xcpretty create a JUnit-style XML report at the provided path
   - xcprettyReportHtml: Have xcpretty create a simple HTML report at the provided path
   - xcprettyReportJson: Have xcpretty create a JSON compilation database at the provided path
   - xcprettyUtf: Have xcpretty use unicode encoding when reporting builds
   - analyzeBuildTime: Analyze the project build time and store the output in 'culprits.txt' file
   - skipProfileDetection: Do not try to build a profile mapping from the xcodeproj. Match or a manually provided mapping should be used
   - xcodebuildCommand: Allows for override of the default `xcodebuild` command
   - clonedSourcePackagesPath: Sets a custom path for Swift Package Manager dependencies
   - skipPackageDependenciesResolution: Skips resolution of Swift Package Manager dependencies
   - disablePackageAutomaticUpdates: Prevents packages from automatically being resolved to versions other than those recorded in the `Package.resolved` file
   - useSystemScm: Lets xcodebuild use system's scm configuration
   - packageAuthorizationProvider: Lets xcodebuild use a specified package authorization provider (keychain|netrc)

 - returns: The absolute path to the generated ipa file

 More information: https://fastlane.tools/gym
 */
@discardableResult public func gym(workspace: OptionalConfigValue<String?> = .fastlaneDefault(gymfile.workspace),
                                   project: OptionalConfigValue<String?> = .fastlaneDefault(gymfile.project),
                                   scheme: OptionalConfigValue<String?> = .fastlaneDefault(gymfile.scheme),
                                   clean: OptionalConfigValue<Bool> = .fastlaneDefault(gymfile.clean),
                                   outputDirectory: String = gymfile.outputDirectory,
                                   outputName: OptionalConfigValue<String?> = .fastlaneDefault(gymfile.outputName),
                                   configuration: OptionalConfigValue<String?> = .fastlaneDefault(gymfile.configuration),
                                   silent: OptionalConfigValue<Bool> = .fastlaneDefault(gymfile.silent),
                                   codesigningIdentity: OptionalConfigValue<String?> = .fastlaneDefault(gymfile.codesigningIdentity),
                                   skipPackageIpa: OptionalConfigValue<Bool> = .fastlaneDefault(gymfile.skipPackageIpa),
                                   skipPackagePkg: OptionalConfigValue<Bool> = .fastlaneDefault(gymfile.skipPackagePkg),
                                   includeSymbols: OptionalConfigValue<Bool?> = .fastlaneDefault(gymfile.includeSymbols),
                                   includeBitcode: OptionalConfigValue<Bool?> = .fastlaneDefault(gymfile.includeBitcode),
                                   exportMethod: OptionalConfigValue<String?> = .fastlaneDefault(gymfile.exportMethod),
                                   exportOptions: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(gymfile.exportOptions),
                                   exportXcargs: OptionalConfigValue<String?> = .fastlaneDefault(gymfile.exportXcargs),
                                   skipBuildArchive: OptionalConfigValue<Bool?> = .fastlaneDefault(gymfile.skipBuildArchive),
                                   skipArchive: OptionalConfigValue<Bool?> = .fastlaneDefault(gymfile.skipArchive),
                                   skipCodesigning: OptionalConfigValue<Bool?> = .fastlaneDefault(gymfile.skipCodesigning),
                                   catalystPlatform: OptionalConfigValue<String?> = .fastlaneDefault(gymfile.catalystPlatform),
                                   installerCertName: OptionalConfigValue<String?> = .fastlaneDefault(gymfile.installerCertName),
                                   buildPath: OptionalConfigValue<String?> = .fastlaneDefault(gymfile.buildPath),
                                   archivePath: OptionalConfigValue<String?> = .fastlaneDefault(gymfile.archivePath),
                                   derivedDataPath: OptionalConfigValue<String?> = .fastlaneDefault(gymfile.derivedDataPath),
                                   resultBundle: OptionalConfigValue<Bool> = .fastlaneDefault(gymfile.resultBundle),
                                   resultBundlePath: OptionalConfigValue<String?> = .fastlaneDefault(gymfile.resultBundlePath),
                                   buildlogPath: String = gymfile.buildlogPath,
                                   sdk: OptionalConfigValue<String?> = .fastlaneDefault(gymfile.sdk),
                                   toolchain: OptionalConfigValue<String?> = .fastlaneDefault(gymfile.toolchain),
                                   destination: OptionalConfigValue<String?> = .fastlaneDefault(gymfile.destination),
                                   exportTeamId: OptionalConfigValue<String?> = .fastlaneDefault(gymfile.exportTeamId),
                                   xcargs: OptionalConfigValue<String?> = .fastlaneDefault(gymfile.xcargs),
                                   xcconfig: OptionalConfigValue<String?> = .fastlaneDefault(gymfile.xcconfig),
                                   suppressXcodeOutput: OptionalConfigValue<Bool?> = .fastlaneDefault(gymfile.suppressXcodeOutput),
                                   xcodebuildFormatter: String = gymfile.xcodebuildFormatter,
                                   buildTimingSummary: OptionalConfigValue<Bool> = .fastlaneDefault(gymfile.buildTimingSummary),
                                   disableXcpretty: OptionalConfigValue<Bool?> = .fastlaneDefault(gymfile.disableXcpretty),
                                   xcprettyTestFormat: OptionalConfigValue<Bool?> = .fastlaneDefault(gymfile.xcprettyTestFormat),
                                   xcprettyFormatter: OptionalConfigValue<String?> = .fastlaneDefault(gymfile.xcprettyFormatter),
                                   xcprettyReportJunit: OptionalConfigValue<String?> = .fastlaneDefault(gymfile.xcprettyReportJunit),
                                   xcprettyReportHtml: OptionalConfigValue<String?> = .fastlaneDefault(gymfile.xcprettyReportHtml),
                                   xcprettyReportJson: OptionalConfigValue<String?> = .fastlaneDefault(gymfile.xcprettyReportJson),
                                   xcprettyUtf: OptionalConfigValue<Bool?> = .fastlaneDefault(gymfile.xcprettyUtf),
                                   analyzeBuildTime: OptionalConfigValue<Bool?> = .fastlaneDefault(gymfile.analyzeBuildTime),
                                   skipProfileDetection: OptionalConfigValue<Bool> = .fastlaneDefault(gymfile.skipProfileDetection),
                                   xcodebuildCommand: String = gymfile.xcodebuildCommand,
                                   clonedSourcePackagesPath: OptionalConfigValue<String?> = .fastlaneDefault(gymfile.clonedSourcePackagesPath),
                                   skipPackageDependenciesResolution: OptionalConfigValue<Bool> = .fastlaneDefault(gymfile.skipPackageDependenciesResolution),
                                   disablePackageAutomaticUpdates: OptionalConfigValue<Bool> = .fastlaneDefault(gymfile.disablePackageAutomaticUpdates),
                                   useSystemScm: OptionalConfigValue<Bool> = .fastlaneDefault(gymfile.useSystemScm),
                                   packageAuthorizationProvider: OptionalConfigValue<String?> = .fastlaneDefault(gymfile.packageAuthorizationProvider)) -> String
{
    let workspaceArg = workspace.asRubyArgument(name: "workspace", type: nil)
    let projectArg = project.asRubyArgument(name: "project", type: nil)
    let schemeArg = scheme.asRubyArgument(name: "scheme", type: nil)
    let cleanArg = clean.asRubyArgument(name: "clean", type: nil)
    let outputDirectoryArg = RubyCommand.Argument(name: "output_directory", value: outputDirectory, type: nil)
    let outputNameArg = outputName.asRubyArgument(name: "output_name", type: nil)
    let configurationArg = configuration.asRubyArgument(name: "configuration", type: nil)
    let silentArg = silent.asRubyArgument(name: "silent", type: nil)
    let codesigningIdentityArg = codesigningIdentity.asRubyArgument(name: "codesigning_identity", type: nil)
    let skipPackageIpaArg = skipPackageIpa.asRubyArgument(name: "skip_package_ipa", type: nil)
    let skipPackagePkgArg = skipPackagePkg.asRubyArgument(name: "skip_package_pkg", type: nil)
    let includeSymbolsArg = includeSymbols.asRubyArgument(name: "include_symbols", type: nil)
    let includeBitcodeArg = includeBitcode.asRubyArgument(name: "include_bitcode", type: nil)
    let exportMethodArg = exportMethod.asRubyArgument(name: "export_method", type: nil)
    let exportOptionsArg = exportOptions.asRubyArgument(name: "export_options", type: nil)
    let exportXcargsArg = exportXcargs.asRubyArgument(name: "export_xcargs", type: nil)
    let skipBuildArchiveArg = skipBuildArchive.asRubyArgument(name: "skip_build_archive", type: nil)
    let skipArchiveArg = skipArchive.asRubyArgument(name: "skip_archive", type: nil)
    let skipCodesigningArg = skipCodesigning.asRubyArgument(name: "skip_codesigning", type: nil)
    let catalystPlatformArg = catalystPlatform.asRubyArgument(name: "catalyst_platform", type: nil)
    let installerCertNameArg = installerCertName.asRubyArgument(name: "installer_cert_name", type: nil)
    let buildPathArg = buildPath.asRubyArgument(name: "build_path", type: nil)
    let archivePathArg = archivePath.asRubyArgument(name: "archive_path", type: nil)
    let derivedDataPathArg = derivedDataPath.asRubyArgument(name: "derived_data_path", type: nil)
    let resultBundleArg = resultBundle.asRubyArgument(name: "result_bundle", type: nil)
    let resultBundlePathArg = resultBundlePath.asRubyArgument(name: "result_bundle_path", type: nil)
    let buildlogPathArg = RubyCommand.Argument(name: "buildlog_path", value: buildlogPath, type: nil)
    let sdkArg = sdk.asRubyArgument(name: "sdk", type: nil)
    let toolchainArg = toolchain.asRubyArgument(name: "toolchain", type: nil)
    let destinationArg = destination.asRubyArgument(name: "destination", type: nil)
    let exportTeamIdArg = exportTeamId.asRubyArgument(name: "export_team_id", type: nil)
    let xcargsArg = xcargs.asRubyArgument(name: "xcargs", type: nil)
    let xcconfigArg = xcconfig.asRubyArgument(name: "xcconfig", type: nil)
    let suppressXcodeOutputArg = suppressXcodeOutput.asRubyArgument(name: "suppress_xcode_output", type: nil)
    let xcodebuildFormatterArg = RubyCommand.Argument(name: "xcodebuild_formatter", value: xcodebuildFormatter, type: nil)
    let buildTimingSummaryArg = buildTimingSummary.asRubyArgument(name: "build_timing_summary", type: nil)
    let disableXcprettyArg = disableXcpretty.asRubyArgument(name: "disable_xcpretty", type: nil)
    let xcprettyTestFormatArg = xcprettyTestFormat.asRubyArgument(name: "xcpretty_test_format", type: nil)
    let xcprettyFormatterArg = xcprettyFormatter.asRubyArgument(name: "xcpretty_formatter", type: nil)
    let xcprettyReportJunitArg = xcprettyReportJunit.asRubyArgument(name: "xcpretty_report_junit", type: nil)
    let xcprettyReportHtmlArg = xcprettyReportHtml.asRubyArgument(name: "xcpretty_report_html", type: nil)
    let xcprettyReportJsonArg = xcprettyReportJson.asRubyArgument(name: "xcpretty_report_json", type: nil)
    let xcprettyUtfArg = xcprettyUtf.asRubyArgument(name: "xcpretty_utf", type: nil)
    let analyzeBuildTimeArg = analyzeBuildTime.asRubyArgument(name: "analyze_build_time", type: nil)
    let skipProfileDetectionArg = skipProfileDetection.asRubyArgument(name: "skip_profile_detection", type: nil)
    let xcodebuildCommandArg = RubyCommand.Argument(name: "xcodebuild_command", value: xcodebuildCommand, type: nil)
    let clonedSourcePackagesPathArg = clonedSourcePackagesPath.asRubyArgument(name: "cloned_source_packages_path", type: nil)
    let skipPackageDependenciesResolutionArg = skipPackageDependenciesResolution.asRubyArgument(name: "skip_package_dependencies_resolution", type: nil)
    let disablePackageAutomaticUpdatesArg = disablePackageAutomaticUpdates.asRubyArgument(name: "disable_package_automatic_updates", type: nil)
    let useSystemScmArg = useSystemScm.asRubyArgument(name: "use_system_scm", type: nil)
    let packageAuthorizationProviderArg = packageAuthorizationProvider.asRubyArgument(name: "package_authorization_provider", type: nil)
    let array: [RubyCommand.Argument?] = [workspaceArg,
                                          projectArg,
                                          schemeArg,
                                          cleanArg,
                                          outputDirectoryArg,
                                          outputNameArg,
                                          configurationArg,
                                          silentArg,
                                          codesigningIdentityArg,
                                          skipPackageIpaArg,
                                          skipPackagePkgArg,
                                          includeSymbolsArg,
                                          includeBitcodeArg,
                                          exportMethodArg,
                                          exportOptionsArg,
                                          exportXcargsArg,
                                          skipBuildArchiveArg,
                                          skipArchiveArg,
                                          skipCodesigningArg,
                                          catalystPlatformArg,
                                          installerCertNameArg,
                                          buildPathArg,
                                          archivePathArg,
                                          derivedDataPathArg,
                                          resultBundleArg,
                                          resultBundlePathArg,
                                          buildlogPathArg,
                                          sdkArg,
                                          toolchainArg,
                                          destinationArg,
                                          exportTeamIdArg,
                                          xcargsArg,
                                          xcconfigArg,
                                          suppressXcodeOutputArg,
                                          xcodebuildFormatterArg,
                                          buildTimingSummaryArg,
                                          disableXcprettyArg,
                                          xcprettyTestFormatArg,
                                          xcprettyFormatterArg,
                                          xcprettyReportJunitArg,
                                          xcprettyReportHtmlArg,
                                          xcprettyReportJsonArg,
                                          xcprettyUtfArg,
                                          analyzeBuildTimeArg,
                                          skipProfileDetectionArg,
                                          xcodebuildCommandArg,
                                          clonedSourcePackagesPathArg,
                                          skipPackageDependenciesResolutionArg,
                                          disablePackageAutomaticUpdatesArg,
                                          useSystemScmArg,
                                          packageAuthorizationProviderArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "gym", className: nil, args: args)
    return runner.executeCommand(command)
}

/**
 This will add a hg tag to the current branch

 - parameter tag: Tag to create
 */
public func hgAddTag(tag: String) {
    let tagArg = RubyCommand.Argument(name: "tag", value: tag, type: nil)
    let array: [RubyCommand.Argument?] = [tagArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "hg_add_tag", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 This will commit a version bump to the hg repo

 - parameters:
   - message: The commit message when committing the version bump
   - xcodeproj: The path to your project file (Not the workspace). If you have only one, this is optional
   - force: Forces the commit, even if other files than the ones containing the version number have been modified
   - testDirtyFiles: A list of dirty files passed in for testing
   - testExpectedFiles: A list of expected changed files passed in for testing

 The mercurial equivalent of the [commit_version_bump](https://docs.fastlane.tools/actions/commit_version_bump/) git action. Like the git version, it is useful in conjunction with [`increment_build_number`](https://docs.fastlane.tools/actions/increment_build_number/).
 It checks the repo to make sure that only the relevant files have changed, these are the files that `increment_build_number` (`agvtool`) touches:|
 |
 >- All `.plist` files|
 - The `.xcodeproj/project.pbxproj` file|
 >|
 Then commits those files to the repo.
 Customize the message with the `:message` option, defaults to 'Version Bump'
 If you have other uncommitted changes in your repo, this action will fail. If you started off in a clean repo, and used the _ipa_ and or _sigh_ actions, then you can use the [clean_build_artifacts](https://docs.fastlane.tools/actions/clean_build_artifacts/) action to clean those temporary files up before running this action.
 */
public func hgCommitVersionBump(message: String = "Version Bump",
                                xcodeproj: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                force: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                testDirtyFiles: String = "file1, file2",
                                testExpectedFiles: String = "file1, file2")
{
    let messageArg = RubyCommand.Argument(name: "message", value: message, type: nil)
    let xcodeprojArg = xcodeproj.asRubyArgument(name: "xcodeproj", type: nil)
    let forceArg = force.asRubyArgument(name: "force", type: nil)
    let testDirtyFilesArg = RubyCommand.Argument(name: "test_dirty_files", value: testDirtyFiles, type: nil)
    let testExpectedFilesArg = RubyCommand.Argument(name: "test_expected_files", value: testExpectedFiles, type: nil)
    let array: [RubyCommand.Argument?] = [messageArg,
                                          xcodeprojArg,
                                          forceArg,
                                          testDirtyFilesArg,
                                          testExpectedFilesArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "hg_commit_version_bump", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Raises an exception if there are uncommitted hg changes

 Along the same lines as the [ensure_git_status_clean](https://docs.fastlane.tools/actions/ensure_git_status_clean/) action, this is a sanity check to ensure the working mercurial repo is clean. Especially useful to put at the beginning of your Fastfile in the `before_all` block.
 */
public func hgEnsureCleanStatus() {
    let args: [RubyCommand.Argument] = []
    let command = RubyCommand(commandID: "", methodName: "hg_ensure_clean_status", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 This will push changes to the remote hg repository

 - parameters:
   - force: Force push to remote
   - destination: The destination to push to

 The mercurial equivalent of [push_to_git_remote](https://docs.fastlane.tools/actions/push_to_git_remote/). Pushes your local commits to a remote mercurial repo. Useful when local changes such as adding a version bump commit or adding a tag are part of your lane’s actions.
 */
public func hgPush(force: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                   destination: String = "")
{
    let forceArg = force.asRubyArgument(name: "force", type: nil)
    let destinationArg = RubyCommand.Argument(name: "destination", value: destination, type: nil)
    let array: [RubyCommand.Argument?] = [forceArg,
                                          destinationArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "hg_push", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Send a error/success message to [HipChat](https://www.hipchat.com/)

 - parameters:
   - message: The message to post on HipChat
   - channel: The room or @username
   - apiToken: Hipchat API Token
   - customColor: Specify a custom color, this overrides the success boolean. Can be one of 'yellow', 'red', 'green', 'purple', 'gray', or 'random'
   - success: Was this build successful? (true/false)
   - version: Version of the Hipchat API. Must be 1 or 2
   - notifyRoom: Should the people in the room be notified? (true/false)
   - apiHost: The host of the HipChat-Server API
   - messageFormat: Format of the message to post. Must be either 'html' or 'text'
   - includeHtmlHeader: Should html formatted messages include a preformatted header? (true/false)
   - from: Name the message will appear to be sent from

 Send a message to **room** (by default) or a direct message to **@username** with success (green) or failure (red) status.
 */
public func hipchat(message: String = "",
                    channel: String,
                    apiToken: String,
                    customColor: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                    success: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                    version: String,
                    notifyRoom: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                    apiHost: String = "api.hipchat.com",
                    messageFormat: String = "html",
                    includeHtmlHeader: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                    from: String = "fastlane")
{
    let messageArg = RubyCommand.Argument(name: "message", value: message, type: nil)
    let channelArg = RubyCommand.Argument(name: "channel", value: channel, type: nil)
    let apiTokenArg = RubyCommand.Argument(name: "api_token", value: apiToken, type: nil)
    let customColorArg = customColor.asRubyArgument(name: "custom_color", type: nil)
    let successArg = success.asRubyArgument(name: "success", type: nil)
    let versionArg = RubyCommand.Argument(name: "version", value: version, type: nil)
    let notifyRoomArg = notifyRoom.asRubyArgument(name: "notify_room", type: nil)
    let apiHostArg = RubyCommand.Argument(name: "api_host", value: apiHost, type: nil)
    let messageFormatArg = RubyCommand.Argument(name: "message_format", value: messageFormat, type: nil)
    let includeHtmlHeaderArg = includeHtmlHeader.asRubyArgument(name: "include_html_header", type: nil)
    let fromArg = RubyCommand.Argument(name: "from", value: from, type: nil)
    let array: [RubyCommand.Argument?] = [messageArg,
                                          channelArg,
                                          apiTokenArg,
                                          customColorArg,
                                          successArg,
                                          versionArg,
                                          notifyRoomArg,
                                          apiHostArg,
                                          messageFormatArg,
                                          includeHtmlHeaderArg,
                                          fromArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "hipchat", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Refer to [App Center](https://github.com/Microsoft/fastlane-plugin-appcenter/)

 - parameters:
   - apk: Path to your APK file
   - apiToken: API Token for Hockey Access
   - ipa: Path to your IPA file. Optional if you use the _gym_ or _xcodebuild_ action. For Mac zip the .app. For Android provide path to .apk file. In addition you could use this to upload .msi, .zip, .pkg, etc if you use the 'create_update' mechanism
   - dsym: Path to your symbols file. For iOS and Mac provide path to app.dSYM.zip. For Android provide path to mappings.txt file
   - createUpdate: Set true if you want to create then update your app as opposed to just upload it. You will need the 'public_identifier', 'bundle_version' and 'bundle_short_version'
   - notes: Beta Notes
   - notify: Notify testers? "1" for yes
   - status: Download status: "1" = No user can download; "2" = Available for download (only possible with full-access token)
   - createStatus: Download status for initial version creation when create_update is true: "1" = No user can download; "2" = Available for download (only possible with full-access token)
   - notesType: Notes type for your :notes, "0" = Textile, "1" = Markdown (default)
   - releaseType: Release type of the app: "0" = Beta (default), "1" = Store, "2" = Alpha, "3" = Enterprise
   - mandatory: Set to "1" to make this update mandatory
   - teams: Comma separated list of team ID numbers to which this build will be restricted
   - users: Comma separated list of user ID numbers to which this build will be restricted
   - tags: Comma separated list of tags which will receive access to the build
   - bundleShortVersion: The bundle_short_version of your application, required when using `create_update`
   - bundleVersion: The bundle_version of your application, required when using `create_update`
   - publicIdentifier: App id of the app you are targeting, usually you won't need this value. Required, if `upload_dsym_only` set to `true`
   - commitSha: The Git commit SHA for this build
   - repositoryUrl: The URL of your source repository
   - buildServerUrl: The URL of the build job on your build server
   - uploadDsymOnly: Flag to upload only the dSYM file to hockey app
   - ownerId: ID for the owner of the app
   - strategy: Strategy: 'add' = to add the build as a new build even if it has the same build number (default); 'replace' = to replace a build with the same build number
   - timeout: Request timeout in seconds
   - bypassCdn: Flag to bypass Hockey CDN when it uploads successfully but reports error
   - dsaSignature: DSA signature for sparkle updates for macOS

 HockeyApp will be no longer supported and will be transitioned into App Center on November 16, 2019.
 Please migrate over to [App Center](https://github.com/Microsoft/fastlane-plugin-appcenter/)

 Symbols will also be uploaded automatically if a `app.dSYM.zip` file is found next to `app.ipa`. In case it is located in a different place you can specify the path explicitly in the `:dsym` parameter.
 More information about the available options can be found in the [HockeyApp Docs](http://support.hockeyapp.net/kb/api/api-versions#upload-version).
 */
public func hockey(apk: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   apiToken: String,
                   ipa: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   dsym: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   createUpdate: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                   notes: String = "No changelog given",
                   notify: String = "1",
                   status: String = "2",
                   createStatus: String = "2",
                   notesType: String = "1",
                   releaseType: String = "0",
                   mandatory: String = "0",
                   teams: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   users: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   tags: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   bundleShortVersion: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   bundleVersion: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   publicIdentifier: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   commitSha: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   repositoryUrl: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   buildServerUrl: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   uploadDsymOnly: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                   ownerId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   strategy: String = "add",
                   timeout: OptionalConfigValue<Int?> = .fastlaneDefault(nil),
                   bypassCdn: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                   dsaSignature: String = "")
{
    let apkArg = apk.asRubyArgument(name: "apk", type: nil)
    let apiTokenArg = RubyCommand.Argument(name: "api_token", value: apiToken, type: nil)
    let ipaArg = ipa.asRubyArgument(name: "ipa", type: nil)
    let dsymArg = dsym.asRubyArgument(name: "dsym", type: nil)
    let createUpdateArg = createUpdate.asRubyArgument(name: "create_update", type: nil)
    let notesArg = RubyCommand.Argument(name: "notes", value: notes, type: nil)
    let notifyArg = RubyCommand.Argument(name: "notify", value: notify, type: nil)
    let statusArg = RubyCommand.Argument(name: "status", value: status, type: nil)
    let createStatusArg = RubyCommand.Argument(name: "create_status", value: createStatus, type: nil)
    let notesTypeArg = RubyCommand.Argument(name: "notes_type", value: notesType, type: nil)
    let releaseTypeArg = RubyCommand.Argument(name: "release_type", value: releaseType, type: nil)
    let mandatoryArg = RubyCommand.Argument(name: "mandatory", value: mandatory, type: nil)
    let teamsArg = teams.asRubyArgument(name: "teams", type: nil)
    let usersArg = users.asRubyArgument(name: "users", type: nil)
    let tagsArg = tags.asRubyArgument(name: "tags", type: nil)
    let bundleShortVersionArg = bundleShortVersion.asRubyArgument(name: "bundle_short_version", type: nil)
    let bundleVersionArg = bundleVersion.asRubyArgument(name: "bundle_version", type: nil)
    let publicIdentifierArg = publicIdentifier.asRubyArgument(name: "public_identifier", type: nil)
    let commitShaArg = commitSha.asRubyArgument(name: "commit_sha", type: nil)
    let repositoryUrlArg = repositoryUrl.asRubyArgument(name: "repository_url", type: nil)
    let buildServerUrlArg = buildServerUrl.asRubyArgument(name: "build_server_url", type: nil)
    let uploadDsymOnlyArg = uploadDsymOnly.asRubyArgument(name: "upload_dsym_only", type: nil)
    let ownerIdArg = ownerId.asRubyArgument(name: "owner_id", type: nil)
    let strategyArg = RubyCommand.Argument(name: "strategy", value: strategy, type: nil)
    let timeoutArg = timeout.asRubyArgument(name: "timeout", type: nil)
    let bypassCdnArg = bypassCdn.asRubyArgument(name: "bypass_cdn", type: nil)
    let dsaSignatureArg = RubyCommand.Argument(name: "dsa_signature", value: dsaSignature, type: nil)
    let array: [RubyCommand.Argument?] = [apkArg,
                                          apiTokenArg,
                                          ipaArg,
                                          dsymArg,
                                          createUpdateArg,
                                          notesArg,
                                          notifyArg,
                                          statusArg,
                                          createStatusArg,
                                          notesTypeArg,
                                          releaseTypeArg,
                                          mandatoryArg,
                                          teamsArg,
                                          usersArg,
                                          tagsArg,
                                          bundleShortVersionArg,
                                          bundleVersionArg,
                                          publicIdentifierArg,
                                          commitShaArg,
                                          repositoryUrlArg,
                                          buildServerUrlArg,
                                          uploadDsymOnlyArg,
                                          ownerIdArg,
                                          strategyArg,
                                          timeoutArg,
                                          bypassCdnArg,
                                          dsaSignatureArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "hockey", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Connect to the [IFTTT Maker Channel](https://ifttt.com/maker)

 - parameters:
   - apiKey: API key
   - eventName: The name of the event that will be triggered
   - value1: Extra data sent with the event
   - value2: Extra data sent with the event
   - value3: Extra data sent with the event

 Connect to the IFTTT [Maker Channel](https://ifttt.com/maker). An IFTTT Recipe has two components: a Trigger and an Action. In this case, the Trigger will fire every time the Maker Channel receives a web request (made by this _fastlane_ action) to notify it of an event. The Action can be anything that IFTTT supports: email, SMS, etc.
 */
public func ifttt(apiKey: String,
                  eventName: String,
                  value1: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  value2: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  value3: OptionalConfigValue<String?> = .fastlaneDefault(nil))
{
    let apiKeyArg = RubyCommand.Argument(name: "api_key", value: apiKey, type: nil)
    let eventNameArg = RubyCommand.Argument(name: "event_name", value: eventName, type: nil)
    let value1Arg = value1.asRubyArgument(name: "value1", type: nil)
    let value2Arg = value2.asRubyArgument(name: "value2", type: nil)
    let value3Arg = value3.asRubyArgument(name: "value3", type: nil)
    let array: [RubyCommand.Argument?] = [apiKeyArg,
                                          eventNameArg,
                                          value1Arg,
                                          value2Arg,
                                          value3Arg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "ifttt", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Import certificate from inputfile into a keychain

 - parameters:
   - certificatePath: Path to certificate
   - certificatePassword: Certificate password
   - keychainName: Keychain the items should be imported to
   - keychainPath: Path to the Keychain file to which the items should be imported
   - keychainPassword: The password for the keychain. Note that for the login keychain this is your user's password
   - logOutput: If output should be logged to the console

 Import certificates (and private keys) into the current default keychain. Use the `create_keychain` action to create a new keychain.
 */
public func importCertificate(certificatePath: String,
                              certificatePassword: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                              keychainName: String,
                              keychainPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                              keychainPassword: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                              logOutput: OptionalConfigValue<Bool> = .fastlaneDefault(false))
{
    let certificatePathArg = RubyCommand.Argument(name: "certificate_path", value: certificatePath, type: nil)
    let certificatePasswordArg = certificatePassword.asRubyArgument(name: "certificate_password", type: nil)
    let keychainNameArg = RubyCommand.Argument(name: "keychain_name", value: keychainName, type: nil)
    let keychainPathArg = keychainPath.asRubyArgument(name: "keychain_path", type: nil)
    let keychainPasswordArg = keychainPassword.asRubyArgument(name: "keychain_password", type: nil)
    let logOutputArg = logOutput.asRubyArgument(name: "log_output", type: nil)
    let array: [RubyCommand.Argument?] = [certificatePathArg,
                                          certificatePasswordArg,
                                          keychainNameArg,
                                          keychainPathArg,
                                          keychainPasswordArg,
                                          logOutputArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "import_certificate", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Increment the build number of your project

 - parameters:
   - buildNumber: Change to a specific version. When you provide this parameter, Apple Generic Versioning does not have to be enabled
   - skipInfoPlist: Don't update Info.plist files when updating the build version
   - xcodeproj: optional, you must specify the path to your main Xcode project if it is not in the project root directory

 - returns: The new build number
 */
@discardableResult public func incrementBuildNumber(buildNumber: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                                    skipInfoPlist: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                                    xcodeproj: OptionalConfigValue<String?> = .fastlaneDefault(nil)) -> String
{
    let buildNumberArg = buildNumber.asRubyArgument(name: "build_number", type: nil)
    let skipInfoPlistArg = skipInfoPlist.asRubyArgument(name: "skip_info_plist", type: nil)
    let xcodeprojArg = xcodeproj.asRubyArgument(name: "xcodeproj", type: nil)
    let array: [RubyCommand.Argument?] = [buildNumberArg,
                                          skipInfoPlistArg,
                                          xcodeprojArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "increment_build_number", className: nil, args: args)
    return runner.executeCommand(command)
}

/**
 Increment the version number of your project

 - parameters:
   - bumpType: The type of this version bump. Available: patch, minor, major
   - versionNumber: Change to a specific version. This will replace the bump type value
   - xcodeproj: optional, you must specify the path to your main Xcode project if it is not in the project root directory

 - returns: The new version number

 This action will increment the version number.
 You first have to set up your Xcode project, if you haven't done it already: [https://developer.apple.com/library/ios/qa/qa1827/_index.html](https://developer.apple.com/library/ios/qa/qa1827/_index.html).
 */
@discardableResult public func incrementVersionNumber(bumpType: String = "bump",
                                                      versionNumber: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                                      xcodeproj: OptionalConfigValue<String?> = .fastlaneDefault(nil)) -> String
{
    let bumpTypeArg = RubyCommand.Argument(name: "bump_type", value: bumpType, type: nil)
    let versionNumberArg = versionNumber.asRubyArgument(name: "version_number", type: nil)
    let xcodeprojArg = xcodeproj.asRubyArgument(name: "xcodeproj", type: nil)
    let array: [RubyCommand.Argument?] = [bumpTypeArg,
                                          versionNumberArg,
                                          xcodeprojArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "increment_version_number", className: nil, args: args)
    return runner.executeCommand(command)
}

/**
 Installs an .ipa file on a connected iOS-device via usb or wifi

 - parameters:
   - extra: Extra Command-line arguments passed to ios-deploy
   - deviceId: id of the device / if not set defaults to first found device
   - skipWifi: Do not search for devices via WiFi
   - ipa: The IPA file to put on the device

 Installs the ipa on the device. If no id is given, the first found iOS device will be used. Works via USB or Wi-Fi. This requires `ios-deploy` to be installed. Please have a look at [ios-deploy](https://github.com/ios-control/ios-deploy). To quickly install it, use `brew install ios-deploy`
 */
public func installOnDevice(extra: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            deviceId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            skipWifi: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                            ipa: OptionalConfigValue<String?> = .fastlaneDefault(nil))
{
    let extraArg = extra.asRubyArgument(name: "extra", type: nil)
    let deviceIdArg = deviceId.asRubyArgument(name: "device_id", type: nil)
    let skipWifiArg = skipWifi.asRubyArgument(name: "skip_wifi", type: nil)
    let ipaArg = ipa.asRubyArgument(name: "ipa", type: nil)
    let array: [RubyCommand.Argument?] = [extraArg,
                                          deviceIdArg,
                                          skipWifiArg,
                                          ipaArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "install_on_device", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Install provisioning profile from path

 - parameter path: Path to provisioning profile

 - returns: The absolute path to the installed provisioning profile

 Install provisioning profile from path for current user
 */
@discardableResult public func installProvisioningProfile(path: String) -> String {
    let pathArg = RubyCommand.Argument(name: "path", value: path, type: nil)
    let array: [RubyCommand.Argument?] = [pathArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "install_provisioning_profile", className: nil, args: args)
    return runner.executeCommand(command)
}

/**
 Install an Xcode plugin for the current user

 - parameters:
   - url: URL for Xcode plugin ZIP file
   - github: GitHub repository URL for Xcode plugin
 */
public func installXcodePlugin(url: String,
                               github: OptionalConfigValue<String?> = .fastlaneDefault(nil))
{
    let urlArg = RubyCommand.Argument(name: "url", value: url, type: nil)
    let githubArg = github.asRubyArgument(name: "github", type: nil)
    let array: [RubyCommand.Argument?] = [urlArg,
                                          githubArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "install_xcode_plugin", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Upload a new build to [Installr](http://installrapp.com/)

 - parameters:
   - apiToken: API Token for Installr Access
   - ipa: Path to your IPA file. Optional if you use the _gym_ or _xcodebuild_ action
   - notes: Release notes
   - notify: Groups to notify (e.g. 'dev,qa')
   - add: Groups to add (e.g. 'exec,ops')
 */
public func installr(apiToken: String,
                     ipa: String,
                     notes: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     notify: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     add: OptionalConfigValue<String?> = .fastlaneDefault(nil))
{
    let apiTokenArg = RubyCommand.Argument(name: "api_token", value: apiToken, type: nil)
    let ipaArg = RubyCommand.Argument(name: "ipa", value: ipa, type: nil)
    let notesArg = notes.asRubyArgument(name: "notes", type: nil)
    let notifyArg = notify.asRubyArgument(name: "notify", type: nil)
    let addArg = add.asRubyArgument(name: "add", type: nil)
    let array: [RubyCommand.Argument?] = [apiTokenArg,
                                          ipaArg,
                                          notesArg,
                                          notifyArg,
                                          addArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "installr", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Easily build and sign your app using shenzhen

 - parameters:
   - workspace: WORKSPACE Workspace (.xcworkspace) file to use to build app (automatically detected in current directory)
   - project: Project (.xcodeproj) file to use to build app (automatically detected in current directory, overridden by --workspace option, if passed)
   - configuration: Configuration used to build
   - scheme: Scheme used to build app
   - clean: Clean project before building
   - archive: Archive project after building
   - destination: Build destination. Defaults to current directory
   - embed: Sign .ipa file with .mobileprovision
   - identity: Identity to be used along with --embed
   - sdk: Use SDK as the name or path of the base SDK when building the project
   - ipa: Specify the name of the .ipa file to generate (including file extension)
   - xcconfig: Use an extra XCCONFIG file to build the app
   - xcargs: Pass additional arguments to xcodebuild when building the app. Be sure to quote multiple args
 */
public func ipa(workspace: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                project: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                configuration: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                scheme: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                clean: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                archive: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                destination: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                embed: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                identity: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                sdk: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                ipa: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                xcconfig: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                xcargs: OptionalConfigValue<String?> = .fastlaneDefault(nil))
{
    let workspaceArg = workspace.asRubyArgument(name: "workspace", type: nil)
    let projectArg = project.asRubyArgument(name: "project", type: nil)
    let configurationArg = configuration.asRubyArgument(name: "configuration", type: nil)
    let schemeArg = scheme.asRubyArgument(name: "scheme", type: nil)
    let cleanArg = clean.asRubyArgument(name: "clean", type: nil)
    let archiveArg = archive.asRubyArgument(name: "archive", type: nil)
    let destinationArg = destination.asRubyArgument(name: "destination", type: nil)
    let embedArg = embed.asRubyArgument(name: "embed", type: nil)
    let identityArg = identity.asRubyArgument(name: "identity", type: nil)
    let sdkArg = sdk.asRubyArgument(name: "sdk", type: nil)
    let ipaArg = ipa.asRubyArgument(name: "ipa", type: nil)
    let xcconfigArg = xcconfig.asRubyArgument(name: "xcconfig", type: nil)
    let xcargsArg = xcargs.asRubyArgument(name: "xcargs", type: nil)
    let array: [RubyCommand.Argument?] = [workspaceArg,
                                          projectArg,
                                          configurationArg,
                                          schemeArg,
                                          cleanArg,
                                          archiveArg,
                                          destinationArg,
                                          embedArg,
                                          identityArg,
                                          sdkArg,
                                          ipaArg,
                                          xcconfigArg,
                                          xcargsArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "ipa", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Is the current run being executed on a CI system, like Jenkins or Travis

 The return value of this method is true if fastlane is currently executed on Travis, Jenkins, Circle or a similar CI service
 */
@discardableResult public func isCi() -> Bool {
    let args: [RubyCommand.Argument] = []
    let command = RubyCommand(commandID: "", methodName: "is_ci", className: nil, args: args)
    return parseBool(fromString: runner.executeCommand(command))
}

/**
 Generate docs using Jazzy

 - parameters:
   - config: Path to jazzy config file
   - moduleVersion: Version string to use as part of the default docs title and inside the docset
 */
public func jazzy(config: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  moduleVersion: OptionalConfigValue<String?> = .fastlaneDefault(nil))
{
    let configArg = config.asRubyArgument(name: "config", type: nil)
    let moduleVersionArg = moduleVersion.asRubyArgument(name: "module_version", type: nil)
    let array: [RubyCommand.Argument?] = [configArg,
                                          moduleVersionArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "jazzy", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
  Leave a comment on a Jira ticket

  - parameters:
    - url: URL for Jira instance
    - contextPath: Appends to the url (ex: "/jira")
    - username: Username for Jira instance
    - password: Password or API token for Jira
    - ticketId: Ticket ID for Jira, i.e. IOS-123
    - commentText: Text to add to the ticket as a comment
    - failOnError: Should an error adding the Jira comment cause a failure?

  - returns: A hash containing all relevant information of the Jira comment
 Access Jira comment 'id', 'author', 'body', and more
 */
@discardableResult public func jira(url: String,
                                    contextPath: String = "",
                                    username: String,
                                    password: String,
                                    ticketId: String,
                                    commentText: String,
                                    failOnError: OptionalConfigValue<Bool> = .fastlaneDefault(true)) -> [String: Any]
{
    let urlArg = RubyCommand.Argument(name: "url", value: url, type: nil)
    let contextPathArg = RubyCommand.Argument(name: "context_path", value: contextPath, type: nil)
    let usernameArg = RubyCommand.Argument(name: "username", value: username, type: nil)
    let passwordArg = RubyCommand.Argument(name: "password", value: password, type: nil)
    let ticketIdArg = RubyCommand.Argument(name: "ticket_id", value: ticketId, type: nil)
    let commentTextArg = RubyCommand.Argument(name: "comment_text", value: commentText, type: nil)
    let failOnErrorArg = failOnError.asRubyArgument(name: "fail_on_error", type: nil)
    let array: [RubyCommand.Argument?] = [urlArg,
                                          contextPathArg,
                                          usernameArg,
                                          passwordArg,
                                          ticketIdArg,
                                          commentTextArg,
                                          failOnErrorArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "jira", className: nil, args: args)
    return parseDictionary(fromString: runner.executeCommand(command))
}

/**
 Access lane context values

 Access the fastlane lane context values.
 More information about how the lane context works: [https://docs.fastlane.tools/advanced/#lane-context](https://docs.fastlane.tools/advanced/#lane-context).
 */
@discardableResult public func laneContext() -> [String: Any] {
    let args: [RubyCommand.Argument] = []
    let command = RubyCommand(commandID: "", methodName: "lane_context", className: nil, args: args)
    return parseDictionary(fromString: runner.executeCommand(command))
}

/**
 Return last git commit hash, abbreviated commit hash, commit message and author

 - returns: Returns the following dict: {commit_hash: "commit hash", abbreviated_commit_hash: "abbreviated commit hash" author: "Author", author_email: "author email", message: "commit message"}. Example: {:message=>"message", :author=>"author", :author_email=>"author_email", :commit_hash=>"commit_hash", :abbreviated_commit_hash=>"short_hash"}
 */
@discardableResult public func lastGitCommit() -> [String: String] {
    let args: [RubyCommand.Argument] = []
    let command = RubyCommand(commandID: "", methodName: "last_git_commit", className: nil, args: args)
    return parseDictionary(fromString: runner.executeCommand(command))
}

/**
 Get the most recent git tag

 - parameter pattern: Pattern to filter tags when looking for last one. Limit tags to ones matching given shell glob. If pattern lacks ?, *, or [, * at the end is implied

 If you are using this action on a **shallow clone**, *the default with some CI systems like Bamboo*, you need to ensure that you have also pulled all the git tags appropriately. Assuming your git repo has the correct remote set you can issue `sh('git fetch --tags')`.
 Pattern parameter allows you to filter to a subset of tags.
 */
@discardableResult public func lastGitTag(pattern: OptionalConfigValue<String?> = .fastlaneDefault(nil)) -> String {
    let patternArg = pattern.asRubyArgument(name: "pattern", type: nil)
    let array: [RubyCommand.Argument?] = [patternArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "last_git_tag", className: nil, args: args)
    return runner.executeCommand(command)
}

/**
 Fetches most recent build number from TestFlight

 - parameters:
   - apiKeyPath: Path to your App Store Connect API Key JSON file (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-json-file)
   - apiKey: Your App Store Connect API Key information (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-hash-option)
   - live: Query the live version (ready-for-sale)
   - appIdentifier: The bundle identifier of your app
   - username: Your Apple ID Username
   - version: The version number whose latest build number we want
   - platform: The platform to use (optional)
   - initialBuildNumber: sets the build number to given value if no build is in current train
   - teamId: The ID of your App Store Connect team if you're in multiple teams
   - teamName: The name of your App Store Connect team if you're in multiple teams

 - returns: Integer representation of the latest build number uploaded to TestFlight. Example: 2

 Provides a way to have `increment_build_number` be based on the latest build you uploaded to iTC.
 Fetches the most recent build number from TestFlight based on the version number. Provides a way to have `increment_build_number` be based on the latest build you uploaded to iTC.
 */
@discardableResult public func latestTestflightBuildNumber(apiKeyPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                                           apiKey: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                                                           live: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                                           appIdentifier: String,
                                                           username: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                                           version: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                                           platform: String = "ios",
                                                           initialBuildNumber: Int = 1,
                                                           teamId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                                           teamName: OptionalConfigValue<String?> = .fastlaneDefault(nil)) -> Int
{
    let apiKeyPathArg = apiKeyPath.asRubyArgument(name: "api_key_path", type: nil)
    let apiKeyArg = apiKey.asRubyArgument(name: "api_key", type: nil)
    let liveArg = live.asRubyArgument(name: "live", type: nil)
    let appIdentifierArg = RubyCommand.Argument(name: "app_identifier", value: appIdentifier, type: nil)
    let usernameArg = username.asRubyArgument(name: "username", type: nil)
    let versionArg = version.asRubyArgument(name: "version", type: nil)
    let platformArg = RubyCommand.Argument(name: "platform", value: platform, type: nil)
    let initialBuildNumberArg = RubyCommand.Argument(name: "initial_build_number", value: initialBuildNumber, type: nil)
    let teamIdArg = teamId.asRubyArgument(name: "team_id", type: nil)
    let teamNameArg = teamName.asRubyArgument(name: "team_name", type: nil)
    let array: [RubyCommand.Argument?] = [apiKeyPathArg,
                                          apiKeyArg,
                                          liveArg,
                                          appIdentifierArg,
                                          usernameArg,
                                          versionArg,
                                          platformArg,
                                          initialBuildNumberArg,
                                          teamIdArg,
                                          teamNameArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "latest_testflight_build_number", className: nil, args: args)
    return parseInt(fromString: runner.executeCommand(command))
}

/**
 Generates coverage data using lcov

 - parameters:
   - projectName: Name of the project
   - scheme: Scheme of the project
   - arch: The build arch where will search .gcda files
   - outputDir: The output directory that coverage data will be stored. If not passed will use coverage_reports as default value
 */
public func lcov(projectName: String,
                 scheme: String,
                 arch: String = "i386",
                 outputDir: String = "coverage_reports")
{
    let projectNameArg = RubyCommand.Argument(name: "project_name", value: projectName, type: nil)
    let schemeArg = RubyCommand.Argument(name: "scheme", value: scheme, type: nil)
    let archArg = RubyCommand.Argument(name: "arch", value: arch, type: nil)
    let outputDirArg = RubyCommand.Argument(name: "output_dir", value: outputDir, type: nil)
    let array: [RubyCommand.Argument?] = [projectNameArg,
                                          schemeArg,
                                          archArg,
                                          outputDirArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "lcov", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Send a success/error message to an email group

 - parameters:
   - mailgunSandboxDomain: Mailgun sandbox domain postmaster for your mail. Please use postmaster instead
   - mailgunSandboxPostmaster: Mailgun sandbox domain postmaster for your mail. Please use postmaster instead
   - mailgunApikey: Mailgun apikey for your mail. Please use postmaster instead
   - postmaster: Mailgun sandbox domain postmaster for your mail
   - apikey: Mailgun apikey for your mail
   - to: Destination of your mail
   - from: Mailgun sender name
   - message: Message of your mail
   - subject: Subject of your mail
   - success: Was this build successful? (true/false)
   - appLink: App Release link
   - ciBuildLink: CI Build Link
   - templatePath: Mail HTML template
   - replyTo: Mail Reply to
   - attachment: Mail Attachment filenames, either an array or just one string
   - customPlaceholders: Placeholders for template given as a hash
 */
public func mailgun(mailgunSandboxDomain: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                    mailgunSandboxPostmaster: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                    mailgunApikey: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                    postmaster: String,
                    apikey: String,
                    to: String,
                    from: String = "Mailgun Sandbox",
                    message: String,
                    subject: String = "fastlane build",
                    success: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                    appLink: String,
                    ciBuildLink: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                    templatePath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                    replyTo: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                    attachment: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                    customPlaceholders: [String: Any] = [:])
{
    let mailgunSandboxDomainArg = mailgunSandboxDomain.asRubyArgument(name: "mailgun_sandbox_domain", type: nil)
    let mailgunSandboxPostmasterArg = mailgunSandboxPostmaster.asRubyArgument(name: "mailgun_sandbox_postmaster", type: nil)
    let mailgunApikeyArg = mailgunApikey.asRubyArgument(name: "mailgun_apikey", type: nil)
    let postmasterArg = RubyCommand.Argument(name: "postmaster", value: postmaster, type: nil)
    let apikeyArg = RubyCommand.Argument(name: "apikey", value: apikey, type: nil)
    let toArg = RubyCommand.Argument(name: "to", value: to, type: nil)
    let fromArg = RubyCommand.Argument(name: "from", value: from, type: nil)
    let messageArg = RubyCommand.Argument(name: "message", value: message, type: nil)
    let subjectArg = RubyCommand.Argument(name: "subject", value: subject, type: nil)
    let successArg = success.asRubyArgument(name: "success", type: nil)
    let appLinkArg = RubyCommand.Argument(name: "app_link", value: appLink, type: nil)
    let ciBuildLinkArg = ciBuildLink.asRubyArgument(name: "ci_build_link", type: nil)
    let templatePathArg = templatePath.asRubyArgument(name: "template_path", type: nil)
    let replyToArg = replyTo.asRubyArgument(name: "reply_to", type: nil)
    let attachmentArg = attachment.asRubyArgument(name: "attachment", type: nil)
    let customPlaceholdersArg = RubyCommand.Argument(name: "custom_placeholders", value: customPlaceholders, type: nil)
    let array: [RubyCommand.Argument?] = [mailgunSandboxDomainArg,
                                          mailgunSandboxPostmasterArg,
                                          mailgunApikeyArg,
                                          postmasterArg,
                                          apikeyArg,
                                          toArg,
                                          fromArg,
                                          messageArg,
                                          subjectArg,
                                          successArg,
                                          appLinkArg,
                                          ciBuildLinkArg,
                                          templatePathArg,
                                          replyToArg,
                                          attachmentArg,
                                          customPlaceholdersArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "mailgun", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Generate a changelog using the Changes section from the current Jenkins build

 - parameters:
   - fallbackChangelog: Fallback changelog if there is not one on Jenkins, or it couldn't be read
   - includeCommitBody: Include the commit body along with the summary

 This is useful when deploying automated builds. The changelog from Jenkins lists all the commit messages since the last build.
 */
public func makeChangelogFromJenkins(fallbackChangelog: String = "",
                                     includeCommitBody: OptionalConfigValue<Bool> = .fastlaneDefault(true))
{
    let fallbackChangelogArg = RubyCommand.Argument(name: "fallback_changelog", value: fallbackChangelog, type: nil)
    let includeCommitBodyArg = includeCommitBody.asRubyArgument(name: "include_commit_body", type: nil)
    let array: [RubyCommand.Argument?] = [fallbackChangelogArg,
                                          includeCommitBodyArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "make_changelog_from_jenkins", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Alias for the `sync_code_signing` action

 - parameters:
   - type: Define the profile type, can be appstore, adhoc, development, enterprise, developer_id, mac_installer_distribution, developer_id_installer
   - additionalCertTypes: Create additional cert types needed for macOS installers (valid values: mac_installer_distribution, developer_id_installer)
   - readonly: Only fetch existing certificates and profiles, don't generate new ones
   - generateAppleCerts: Create a certificate type for Xcode 11 and later (Apple Development or Apple Distribution)
   - skipProvisioningProfiles: Skip syncing provisioning profiles
   - appIdentifier: The bundle identifier(s) of your app (comma-separated string or array of strings)
   - apiKeyPath: Path to your App Store Connect API Key JSON file (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-json-file)
   - apiKey: Your App Store Connect API Key information (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-hash-option)
   - username: Your Apple ID Username
   - teamId: The ID of your Developer Portal team if you're in multiple teams
   - teamName: The name of your Developer Portal team if you're in multiple teams
   - storageMode: Define where you want to store your certificates
   - gitUrl: URL to the git repo containing all the certificates
   - gitBranch: Specific git branch to use
   - gitFullName: git user full name to commit
   - gitUserEmail: git user email to commit
   - shallowClone: Make a shallow clone of the repository (truncate the history to 1 revision)
   - cloneBranchDirectly: Clone just the branch specified, instead of the whole repo. This requires that the branch already exists. Otherwise the command will fail
   - gitBasicAuthorization: Use a basic authorization header to access the git repo (e.g.: access via HTTPS, GitHub Actions, etc), usually a string in Base64
   - gitBearerAuthorization: Use a bearer authorization header to access the git repo (e.g.: access to an Azure DevOps repository), usually a string in Base64
   - gitPrivateKey: Use a private key to access the git repo (e.g.: access to GitHub repository via Deploy keys), usually a id_rsa named file or the contents hereof
   - googleCloudBucketName: Name of the Google Cloud Storage bucket to use
   - googleCloudKeysFile: Path to the gc_keys.json file
   - googleCloudProjectId: ID of the Google Cloud project to use for authentication
   - skipGoogleCloudAccountConfirmation: Skips confirming to use the system google account
   - s3Region: Name of the S3 region
   - s3AccessKey: S3 access key
   - s3SecretAccessKey: S3 secret access key
   - s3Bucket: Name of the S3 bucket
   - s3ObjectPrefix: Prefix to be used on all objects uploaded to S3
   - s3SkipEncryption: Skip encryption of all objects uploaded to S3. WARNING: only enable this on S3 buckets with sufficiently restricted permissions and server-side encryption enabled. See https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingEncryption.html
   - gitlabProject: GitLab Project Path (i.e. 'gitlab-org/gitlab')
   - gitlabHost: GitLab Host (i.e. 'https://gitlab.com')
   - jobToken: GitLab CI_JOB_TOKEN
   - privateToken: GitLab Access Token
   - keychainName: Keychain the items should be imported to
   - keychainPassword: This might be required the first time you access certificates on a new mac. For the login/default keychain this is your macOS account password
   - force: Renew the provisioning profiles every time you run match
   - forceForNewDevices: Renew the provisioning profiles if the device count on the developer portal has changed. Ignored for profile types 'appstore' and 'developer_id'
   - includeMacInProfiles: Include Apple Silicon Mac devices in provisioning profiles for iOS/iPadOS apps
   - includeAllCertificates: Include all matching certificates in the provisioning profile. Works only for the 'development' provisioning profile type
   - certificateId: Select certificate by id. Useful if multiple certificates are stored in one place
   - forceForNewCertificates: Renew the provisioning profiles if the certificate count on the developer portal has changed. Works only for the 'development' provisioning profile type. Requires 'include_all_certificates' option to be 'true'
   - skipConfirmation: Disables confirmation prompts during nuke, answering them with yes
   - safeRemoveCerts: Remove certs from repository during nuke without revoking them on the developer portal
   - skipDocs: Skip generation of a README.md for the created git repository
   - platform: Set the provisioning profile's platform to work with (i.e. ios, tvos, macos, catalyst)
   - deriveCatalystAppIdentifier: Enable this if you have the Mac Catalyst capability enabled and your project was created with Xcode 11.3 or earlier. Prepends 'maccatalyst.' to the app identifier for the provisioning profile mapping
   - templateName: The name of provisioning profile template. If the developer account has provisioning profile templates (aka: custom entitlements), the template name can be found by inspecting the Entitlements drop-down while creating/editing a provisioning profile (e.g. "Apple Pay Pass Suppression Development")
   - profileName: A custom name for the provisioning profile. This will replace the default provisioning profile name if specified
   - failOnNameTaken: Should the command fail if it was about to create a duplicate of an existing provisioning profile. It can happen due to issues on Apple Developer Portal, when profile to be recreated was not properly deleted first
   - skipCertificateMatching: Set to true if there is no access to Apple developer portal but there are certificates, keys and profiles provided. Only works with match import action
   - outputPath: Path in which to export certificates, key and profile
   - skipSetPartitionList: Skips setting the partition list (which can sometimes take a long time). Setting the partition list is usually needed to prevent Xcode from prompting to allow a cert to be used for signing
   - forceLegacyEncryption: Force encryption to use legacy cbc algorithm for backwards compatibility with older match versions
   - verbose: Print out extra information and all commands

 More information: https://docs.fastlane.tools/actions/match/
 */
public func match(type: String = matchfile.type,
                  additionalCertTypes: OptionalConfigValue<[String]?> = .fastlaneDefault(matchfile.additionalCertTypes),
                  readonly: OptionalConfigValue<Bool> = .fastlaneDefault(matchfile.readonly),
                  generateAppleCerts: OptionalConfigValue<Bool> = .fastlaneDefault(matchfile.generateAppleCerts),
                  skipProvisioningProfiles: OptionalConfigValue<Bool> = .fastlaneDefault(matchfile.skipProvisioningProfiles),
                  appIdentifier: [String] = matchfile.appIdentifier,
                  apiKeyPath: OptionalConfigValue<String?> = .fastlaneDefault(matchfile.apiKeyPath),
                  apiKey: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(matchfile.apiKey),
                  username: OptionalConfigValue<String?> = .fastlaneDefault(matchfile.username),
                  teamId: OptionalConfigValue<String?> = .fastlaneDefault(matchfile.teamId),
                  teamName: OptionalConfigValue<String?> = .fastlaneDefault(matchfile.teamName),
                  storageMode: String = matchfile.storageMode,
                  gitUrl: String = matchfile.gitUrl,
                  gitBranch: String = matchfile.gitBranch,
                  gitFullName: OptionalConfigValue<String?> = .fastlaneDefault(matchfile.gitFullName),
                  gitUserEmail: OptionalConfigValue<String?> = .fastlaneDefault(matchfile.gitUserEmail),
                  shallowClone: OptionalConfigValue<Bool> = .fastlaneDefault(matchfile.shallowClone),
                  cloneBranchDirectly: OptionalConfigValue<Bool> = .fastlaneDefault(matchfile.cloneBranchDirectly),
                  gitBasicAuthorization: OptionalConfigValue<String?> = .fastlaneDefault(matchfile.gitBasicAuthorization),
                  gitBearerAuthorization: OptionalConfigValue<String?> = .fastlaneDefault(matchfile.gitBearerAuthorization),
                  gitPrivateKey: OptionalConfigValue<String?> = .fastlaneDefault(matchfile.gitPrivateKey),
                  googleCloudBucketName: OptionalConfigValue<String?> = .fastlaneDefault(matchfile.googleCloudBucketName),
                  googleCloudKeysFile: OptionalConfigValue<String?> = .fastlaneDefault(matchfile.googleCloudKeysFile),
                  googleCloudProjectId: OptionalConfigValue<String?> = .fastlaneDefault(matchfile.googleCloudProjectId),
                  skipGoogleCloudAccountConfirmation: OptionalConfigValue<Bool> = .fastlaneDefault(matchfile.skipGoogleCloudAccountConfirmation),
                  s3Region: OptionalConfigValue<String?> = .fastlaneDefault(matchfile.s3Region),
                  s3AccessKey: OptionalConfigValue<String?> = .fastlaneDefault(matchfile.s3AccessKey),
                  s3SecretAccessKey: OptionalConfigValue<String?> = .fastlaneDefault(matchfile.s3SecretAccessKey),
                  s3Bucket: OptionalConfigValue<String?> = .fastlaneDefault(matchfile.s3Bucket),
                  s3ObjectPrefix: OptionalConfigValue<String?> = .fastlaneDefault(matchfile.s3ObjectPrefix),
                  s3SkipEncryption: OptionalConfigValue<Bool> = .fastlaneDefault(matchfile.s3SkipEncryption),
                  gitlabProject: OptionalConfigValue<String?> = .fastlaneDefault(matchfile.gitlabProject),
                  gitlabHost: String = matchfile.gitlabHost,
                  jobToken: OptionalConfigValue<String?> = .fastlaneDefault(matchfile.jobToken),
                  privateToken: OptionalConfigValue<String?> = .fastlaneDefault(matchfile.privateToken),
                  keychainName: String = matchfile.keychainName,
                  keychainPassword: OptionalConfigValue<String?> = .fastlaneDefault(matchfile.keychainPassword),
                  force: OptionalConfigValue<Bool> = .fastlaneDefault(matchfile.force),
                  forceForNewDevices: OptionalConfigValue<Bool> = .fastlaneDefault(matchfile.forceForNewDevices),
                  includeMacInProfiles: OptionalConfigValue<Bool> = .fastlaneDefault(matchfile.includeMacInProfiles),
                  includeAllCertificates: OptionalConfigValue<Bool> = .fastlaneDefault(matchfile.includeAllCertificates),
                  certificateId: OptionalConfigValue<String?> = .fastlaneDefault(matchfile.certificateId),
                  forceForNewCertificates: OptionalConfigValue<Bool> = .fastlaneDefault(matchfile.forceForNewCertificates),
                  skipConfirmation: OptionalConfigValue<Bool> = .fastlaneDefault(matchfile.skipConfirmation),
                  safeRemoveCerts: OptionalConfigValue<Bool> = .fastlaneDefault(matchfile.safeRemoveCerts),
                  skipDocs: OptionalConfigValue<Bool> = .fastlaneDefault(matchfile.skipDocs),
                  platform: String = matchfile.platform,
                  deriveCatalystAppIdentifier: OptionalConfigValue<Bool> = .fastlaneDefault(matchfile.deriveCatalystAppIdentifier),
                  templateName: OptionalConfigValue<String?> = .fastlaneDefault(matchfile.templateName),
                  profileName: OptionalConfigValue<String?> = .fastlaneDefault(matchfile.profileName),
                  failOnNameTaken: OptionalConfigValue<Bool> = .fastlaneDefault(matchfile.failOnNameTaken),
                  skipCertificateMatching: OptionalConfigValue<Bool> = .fastlaneDefault(matchfile.skipCertificateMatching),
                  outputPath: OptionalConfigValue<String?> = .fastlaneDefault(matchfile.outputPath),
                  skipSetPartitionList: OptionalConfigValue<Bool> = .fastlaneDefault(matchfile.skipSetPartitionList),
                  forceLegacyEncryption: OptionalConfigValue<Bool> = .fastlaneDefault(matchfile.forceLegacyEncryption),
                  verbose: OptionalConfigValue<Bool> = .fastlaneDefault(matchfile.verbose))
{
    let typeArg = RubyCommand.Argument(name: "type", value: type, type: nil)
    let additionalCertTypesArg = additionalCertTypes.asRubyArgument(name: "additional_cert_types", type: nil)
    let readonlyArg = readonly.asRubyArgument(name: "readonly", type: nil)
    let generateAppleCertsArg = generateAppleCerts.asRubyArgument(name: "generate_apple_certs", type: nil)
    let skipProvisioningProfilesArg = skipProvisioningProfiles.asRubyArgument(name: "skip_provisioning_profiles", type: nil)
    let appIdentifierArg = RubyCommand.Argument(name: "app_identifier", value: appIdentifier, type: nil)
    let apiKeyPathArg = apiKeyPath.asRubyArgument(name: "api_key_path", type: nil)
    let apiKeyArg = apiKey.asRubyArgument(name: "api_key", type: nil)
    let usernameArg = username.asRubyArgument(name: "username", type: nil)
    let teamIdArg = teamId.asRubyArgument(name: "team_id", type: nil)
    let teamNameArg = teamName.asRubyArgument(name: "team_name", type: nil)
    let storageModeArg = RubyCommand.Argument(name: "storage_mode", value: storageMode, type: nil)
    let gitUrlArg = RubyCommand.Argument(name: "git_url", value: gitUrl, type: nil)
    let gitBranchArg = RubyCommand.Argument(name: "git_branch", value: gitBranch, type: nil)
    let gitFullNameArg = gitFullName.asRubyArgument(name: "git_full_name", type: nil)
    let gitUserEmailArg = gitUserEmail.asRubyArgument(name: "git_user_email", type: nil)
    let shallowCloneArg = shallowClone.asRubyArgument(name: "shallow_clone", type: nil)
    let cloneBranchDirectlyArg = cloneBranchDirectly.asRubyArgument(name: "clone_branch_directly", type: nil)
    let gitBasicAuthorizationArg = gitBasicAuthorization.asRubyArgument(name: "git_basic_authorization", type: nil)
    let gitBearerAuthorizationArg = gitBearerAuthorization.asRubyArgument(name: "git_bearer_authorization", type: nil)
    let gitPrivateKeyArg = gitPrivateKey.asRubyArgument(name: "git_private_key", type: nil)
    let googleCloudBucketNameArg = googleCloudBucketName.asRubyArgument(name: "google_cloud_bucket_name", type: nil)
    let googleCloudKeysFileArg = googleCloudKeysFile.asRubyArgument(name: "google_cloud_keys_file", type: nil)
    let googleCloudProjectIdArg = googleCloudProjectId.asRubyArgument(name: "google_cloud_project_id", type: nil)
    let skipGoogleCloudAccountConfirmationArg = skipGoogleCloudAccountConfirmation.asRubyArgument(name: "skip_google_cloud_account_confirmation", type: nil)
    let s3RegionArg = s3Region.asRubyArgument(name: "s3_region", type: nil)
    let s3AccessKeyArg = s3AccessKey.asRubyArgument(name: "s3_access_key", type: nil)
    let s3SecretAccessKeyArg = s3SecretAccessKey.asRubyArgument(name: "s3_secret_access_key", type: nil)
    let s3BucketArg = s3Bucket.asRubyArgument(name: "s3_bucket", type: nil)
    let s3ObjectPrefixArg = s3ObjectPrefix.asRubyArgument(name: "s3_object_prefix", type: nil)
    let s3SkipEncryptionArg = s3SkipEncryption.asRubyArgument(name: "s3_skip_encryption", type: nil)
    let gitlabProjectArg = gitlabProject.asRubyArgument(name: "gitlab_project", type: nil)
    let gitlabHostArg = RubyCommand.Argument(name: "gitlab_host", value: gitlabHost, type: nil)
    let jobTokenArg = jobToken.asRubyArgument(name: "job_token", type: nil)
    let privateTokenArg = privateToken.asRubyArgument(name: "private_token", type: nil)
    let keychainNameArg = RubyCommand.Argument(name: "keychain_name", value: keychainName, type: nil)
    let keychainPasswordArg = keychainPassword.asRubyArgument(name: "keychain_password", type: nil)
    let forceArg = force.asRubyArgument(name: "force", type: nil)
    let forceForNewDevicesArg = forceForNewDevices.asRubyArgument(name: "force_for_new_devices", type: nil)
    let includeMacInProfilesArg = includeMacInProfiles.asRubyArgument(name: "include_mac_in_profiles", type: nil)
    let includeAllCertificatesArg = includeAllCertificates.asRubyArgument(name: "include_all_certificates", type: nil)
    let certificateIdArg = certificateId.asRubyArgument(name: "certificate_id", type: nil)
    let forceForNewCertificatesArg = forceForNewCertificates.asRubyArgument(name: "force_for_new_certificates", type: nil)
    let skipConfirmationArg = skipConfirmation.asRubyArgument(name: "skip_confirmation", type: nil)
    let safeRemoveCertsArg = safeRemoveCerts.asRubyArgument(name: "safe_remove_certs", type: nil)
    let skipDocsArg = skipDocs.asRubyArgument(name: "skip_docs", type: nil)
    let platformArg = RubyCommand.Argument(name: "platform", value: platform, type: nil)
    let deriveCatalystAppIdentifierArg = deriveCatalystAppIdentifier.asRubyArgument(name: "derive_catalyst_app_identifier", type: nil)
    let templateNameArg = templateName.asRubyArgument(name: "template_name", type: nil)
    let profileNameArg = profileName.asRubyArgument(name: "profile_name", type: nil)
    let failOnNameTakenArg = failOnNameTaken.asRubyArgument(name: "fail_on_name_taken", type: nil)
    let skipCertificateMatchingArg = skipCertificateMatching.asRubyArgument(name: "skip_certificate_matching", type: nil)
    let outputPathArg = outputPath.asRubyArgument(name: "output_path", type: nil)
    let skipSetPartitionListArg = skipSetPartitionList.asRubyArgument(name: "skip_set_partition_list", type: nil)
    let forceLegacyEncryptionArg = forceLegacyEncryption.asRubyArgument(name: "force_legacy_encryption", type: nil)
    let verboseArg = verbose.asRubyArgument(name: "verbose", type: nil)
    let array: [RubyCommand.Argument?] = [typeArg,
                                          additionalCertTypesArg,
                                          readonlyArg,
                                          generateAppleCertsArg,
                                          skipProvisioningProfilesArg,
                                          appIdentifierArg,
                                          apiKeyPathArg,
                                          apiKeyArg,
                                          usernameArg,
                                          teamIdArg,
                                          teamNameArg,
                                          storageModeArg,
                                          gitUrlArg,
                                          gitBranchArg,
                                          gitFullNameArg,
                                          gitUserEmailArg,
                                          shallowCloneArg,
                                          cloneBranchDirectlyArg,
                                          gitBasicAuthorizationArg,
                                          gitBearerAuthorizationArg,
                                          gitPrivateKeyArg,
                                          googleCloudBucketNameArg,
                                          googleCloudKeysFileArg,
                                          googleCloudProjectIdArg,
                                          skipGoogleCloudAccountConfirmationArg,
                                          s3RegionArg,
                                          s3AccessKeyArg,
                                          s3SecretAccessKeyArg,
                                          s3BucketArg,
                                          s3ObjectPrefixArg,
                                          s3SkipEncryptionArg,
                                          gitlabProjectArg,
                                          gitlabHostArg,
                                          jobTokenArg,
                                          privateTokenArg,
                                          keychainNameArg,
                                          keychainPasswordArg,
                                          forceArg,
                                          forceForNewDevicesArg,
                                          includeMacInProfilesArg,
                                          includeAllCertificatesArg,
                                          certificateIdArg,
                                          forceForNewCertificatesArg,
                                          skipConfirmationArg,
                                          safeRemoveCertsArg,
                                          skipDocsArg,
                                          platformArg,
                                          deriveCatalystAppIdentifierArg,
                                          templateNameArg,
                                          profileNameArg,
                                          failOnNameTakenArg,
                                          skipCertificateMatchingArg,
                                          outputPathArg,
                                          skipSetPartitionListArg,
                                          forceLegacyEncryptionArg,
                                          verboseArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "match", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Easily nuke your certificate and provisioning profiles (via _match_)

 - parameters:
   - type: Define the profile type, can be appstore, adhoc, development, enterprise, developer_id, mac_installer_distribution, developer_id_installer
   - additionalCertTypes: Create additional cert types needed for macOS installers (valid values: mac_installer_distribution, developer_id_installer)
   - readonly: Only fetch existing certificates and profiles, don't generate new ones
   - generateAppleCerts: Create a certificate type for Xcode 11 and later (Apple Development or Apple Distribution)
   - skipProvisioningProfiles: Skip syncing provisioning profiles
   - appIdentifier: The bundle identifier(s) of your app (comma-separated string or array of strings)
   - apiKeyPath: Path to your App Store Connect API Key JSON file (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-json-file)
   - apiKey: Your App Store Connect API Key information (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-hash-option)
   - username: Your Apple ID Username
   - teamId: The ID of your Developer Portal team if you're in multiple teams
   - teamName: The name of your Developer Portal team if you're in multiple teams
   - storageMode: Define where you want to store your certificates
   - gitUrl: URL to the git repo containing all the certificates
   - gitBranch: Specific git branch to use
   - gitFullName: git user full name to commit
   - gitUserEmail: git user email to commit
   - shallowClone: Make a shallow clone of the repository (truncate the history to 1 revision)
   - cloneBranchDirectly: Clone just the branch specified, instead of the whole repo. This requires that the branch already exists. Otherwise the command will fail
   - gitBasicAuthorization: Use a basic authorization header to access the git repo (e.g.: access via HTTPS, GitHub Actions, etc), usually a string in Base64
   - gitBearerAuthorization: Use a bearer authorization header to access the git repo (e.g.: access to an Azure DevOps repository), usually a string in Base64
   - gitPrivateKey: Use a private key to access the git repo (e.g.: access to GitHub repository via Deploy keys), usually a id_rsa named file or the contents hereof
   - googleCloudBucketName: Name of the Google Cloud Storage bucket to use
   - googleCloudKeysFile: Path to the gc_keys.json file
   - googleCloudProjectId: ID of the Google Cloud project to use for authentication
   - skipGoogleCloudAccountConfirmation: Skips confirming to use the system google account
   - s3Region: Name of the S3 region
   - s3AccessKey: S3 access key
   - s3SecretAccessKey: S3 secret access key
   - s3Bucket: Name of the S3 bucket
   - s3ObjectPrefix: Prefix to be used on all objects uploaded to S3
   - s3SkipEncryption: Skip encryption of all objects uploaded to S3. WARNING: only enable this on S3 buckets with sufficiently restricted permissions and server-side encryption enabled. See https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingEncryption.html
   - gitlabProject: GitLab Project Path (i.e. 'gitlab-org/gitlab')
   - gitlabHost: GitLab Host (i.e. 'https://gitlab.com')
   - jobToken: GitLab CI_JOB_TOKEN
   - privateToken: GitLab Access Token
   - keychainName: Keychain the items should be imported to
   - keychainPassword: This might be required the first time you access certificates on a new mac. For the login/default keychain this is your macOS account password
   - force: Renew the provisioning profiles every time you run match
   - forceForNewDevices: Renew the provisioning profiles if the device count on the developer portal has changed. Ignored for profile types 'appstore' and 'developer_id'
   - includeMacInProfiles: Include Apple Silicon Mac devices in provisioning profiles for iOS/iPadOS apps
   - includeAllCertificates: Include all matching certificates in the provisioning profile. Works only for the 'development' provisioning profile type
   - certificateId: Select certificate by id. Useful if multiple certificates are stored in one place
   - forceForNewCertificates: Renew the provisioning profiles if the certificate count on the developer portal has changed. Works only for the 'development' provisioning profile type. Requires 'include_all_certificates' option to be 'true'
   - skipConfirmation: Disables confirmation prompts during nuke, answering them with yes
   - safeRemoveCerts: Remove certs from repository during nuke without revoking them on the developer portal
   - skipDocs: Skip generation of a README.md for the created git repository
   - platform: Set the provisioning profile's platform to work with (i.e. ios, tvos, macos, catalyst)
   - deriveCatalystAppIdentifier: Enable this if you have the Mac Catalyst capability enabled and your project was created with Xcode 11.3 or earlier. Prepends 'maccatalyst.' to the app identifier for the provisioning profile mapping
   - templateName: The name of provisioning profile template. If the developer account has provisioning profile templates (aka: custom entitlements), the template name can be found by inspecting the Entitlements drop-down while creating/editing a provisioning profile (e.g. "Apple Pay Pass Suppression Development")
   - profileName: A custom name for the provisioning profile. This will replace the default provisioning profile name if specified
   - failOnNameTaken: Should the command fail if it was about to create a duplicate of an existing provisioning profile. It can happen due to issues on Apple Developer Portal, when profile to be recreated was not properly deleted first
   - skipCertificateMatching: Set to true if there is no access to Apple developer portal but there are certificates, keys and profiles provided. Only works with match import action
   - outputPath: Path in which to export certificates, key and profile
   - skipSetPartitionList: Skips setting the partition list (which can sometimes take a long time). Setting the partition list is usually needed to prevent Xcode from prompting to allow a cert to be used for signing
   - forceLegacyEncryption: Force encryption to use legacy cbc algorithm for backwards compatibility with older match versions
   - verbose: Print out extra information and all commands

 Use the match_nuke action to revoke your certificates and provisioning profiles.
 Don't worry, apps that are already available in the App Store / TestFlight will still work.
 Builds distributed via Ad Hoc or Enterprise will be disabled after nuking your account, so you'll have to re-upload a new build.
 After clearing your account you'll start from a clean state, and you can run match to generate your certificates and profiles again.
 More information: https://docs.fastlane.tools/actions/match/
 */
public func matchNuke(type: String = "development",
                      additionalCertTypes: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                      readonly: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                      generateAppleCerts: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                      skipProvisioningProfiles: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                      appIdentifier: [String],
                      apiKeyPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      apiKey: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                      username: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      teamId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      teamName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      storageMode: String = "git",
                      gitUrl: String,
                      gitBranch: String = "master",
                      gitFullName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      gitUserEmail: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      shallowClone: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                      cloneBranchDirectly: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                      gitBasicAuthorization: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      gitBearerAuthorization: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      gitPrivateKey: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      googleCloudBucketName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      googleCloudKeysFile: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      googleCloudProjectId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      skipGoogleCloudAccountConfirmation: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                      s3Region: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      s3AccessKey: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      s3SecretAccessKey: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      s3Bucket: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      s3ObjectPrefix: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      s3SkipEncryption: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                      gitlabProject: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      gitlabHost: String = "https://gitlab.com",
                      jobToken: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      privateToken: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      keychainName: String = "login.keychain",
                      keychainPassword: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      force: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                      forceForNewDevices: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                      includeMacInProfiles: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                      includeAllCertificates: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                      certificateId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      forceForNewCertificates: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                      skipConfirmation: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                      safeRemoveCerts: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                      skipDocs: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                      platform: String = "ios",
                      deriveCatalystAppIdentifier: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                      templateName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      profileName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      failOnNameTaken: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                      skipCertificateMatching: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                      outputPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      skipSetPartitionList: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                      forceLegacyEncryption: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                      verbose: OptionalConfigValue<Bool> = .fastlaneDefault(false))
{
    let typeArg = RubyCommand.Argument(name: "type", value: type, type: nil)
    let additionalCertTypesArg = additionalCertTypes.asRubyArgument(name: "additional_cert_types", type: nil)
    let readonlyArg = readonly.asRubyArgument(name: "readonly", type: nil)
    let generateAppleCertsArg = generateAppleCerts.asRubyArgument(name: "generate_apple_certs", type: nil)
    let skipProvisioningProfilesArg = skipProvisioningProfiles.asRubyArgument(name: "skip_provisioning_profiles", type: nil)
    let appIdentifierArg = RubyCommand.Argument(name: "app_identifier", value: appIdentifier, type: nil)
    let apiKeyPathArg = apiKeyPath.asRubyArgument(name: "api_key_path", type: nil)
    let apiKeyArg = apiKey.asRubyArgument(name: "api_key", type: nil)
    let usernameArg = username.asRubyArgument(name: "username", type: nil)
    let teamIdArg = teamId.asRubyArgument(name: "team_id", type: nil)
    let teamNameArg = teamName.asRubyArgument(name: "team_name", type: nil)
    let storageModeArg = RubyCommand.Argument(name: "storage_mode", value: storageMode, type: nil)
    let gitUrlArg = RubyCommand.Argument(name: "git_url", value: gitUrl, type: nil)
    let gitBranchArg = RubyCommand.Argument(name: "git_branch", value: gitBranch, type: nil)
    let gitFullNameArg = gitFullName.asRubyArgument(name: "git_full_name", type: nil)
    let gitUserEmailArg = gitUserEmail.asRubyArgument(name: "git_user_email", type: nil)
    let shallowCloneArg = shallowClone.asRubyArgument(name: "shallow_clone", type: nil)
    let cloneBranchDirectlyArg = cloneBranchDirectly.asRubyArgument(name: "clone_branch_directly", type: nil)
    let gitBasicAuthorizationArg = gitBasicAuthorization.asRubyArgument(name: "git_basic_authorization", type: nil)
    let gitBearerAuthorizationArg = gitBearerAuthorization.asRubyArgument(name: "git_bearer_authorization", type: nil)
    let gitPrivateKeyArg = gitPrivateKey.asRubyArgument(name: "git_private_key", type: nil)
    let googleCloudBucketNameArg = googleCloudBucketName.asRubyArgument(name: "google_cloud_bucket_name", type: nil)
    let googleCloudKeysFileArg = googleCloudKeysFile.asRubyArgument(name: "google_cloud_keys_file", type: nil)
    let googleCloudProjectIdArg = googleCloudProjectId.asRubyArgument(name: "google_cloud_project_id", type: nil)
    let skipGoogleCloudAccountConfirmationArg = skipGoogleCloudAccountConfirmation.asRubyArgument(name: "skip_google_cloud_account_confirmation", type: nil)
    let s3RegionArg = s3Region.asRubyArgument(name: "s3_region", type: nil)
    let s3AccessKeyArg = s3AccessKey.asRubyArgument(name: "s3_access_key", type: nil)
    let s3SecretAccessKeyArg = s3SecretAccessKey.asRubyArgument(name: "s3_secret_access_key", type: nil)
    let s3BucketArg = s3Bucket.asRubyArgument(name: "s3_bucket", type: nil)
    let s3ObjectPrefixArg = s3ObjectPrefix.asRubyArgument(name: "s3_object_prefix", type: nil)
    let s3SkipEncryptionArg = s3SkipEncryption.asRubyArgument(name: "s3_skip_encryption", type: nil)
    let gitlabProjectArg = gitlabProject.asRubyArgument(name: "gitlab_project", type: nil)
    let gitlabHostArg = RubyCommand.Argument(name: "gitlab_host", value: gitlabHost, type: nil)
    let jobTokenArg = jobToken.asRubyArgument(name: "job_token", type: nil)
    let privateTokenArg = privateToken.asRubyArgument(name: "private_token", type: nil)
    let keychainNameArg = RubyCommand.Argument(name: "keychain_name", value: keychainName, type: nil)
    let keychainPasswordArg = keychainPassword.asRubyArgument(name: "keychain_password", type: nil)
    let forceArg = force.asRubyArgument(name: "force", type: nil)
    let forceForNewDevicesArg = forceForNewDevices.asRubyArgument(name: "force_for_new_devices", type: nil)
    let includeMacInProfilesArg = includeMacInProfiles.asRubyArgument(name: "include_mac_in_profiles", type: nil)
    let includeAllCertificatesArg = includeAllCertificates.asRubyArgument(name: "include_all_certificates", type: nil)
    let certificateIdArg = certificateId.asRubyArgument(name: "certificate_id", type: nil)
    let forceForNewCertificatesArg = forceForNewCertificates.asRubyArgument(name: "force_for_new_certificates", type: nil)
    let skipConfirmationArg = skipConfirmation.asRubyArgument(name: "skip_confirmation", type: nil)
    let safeRemoveCertsArg = safeRemoveCerts.asRubyArgument(name: "safe_remove_certs", type: nil)
    let skipDocsArg = skipDocs.asRubyArgument(name: "skip_docs", type: nil)
    let platformArg = RubyCommand.Argument(name: "platform", value: platform, type: nil)
    let deriveCatalystAppIdentifierArg = deriveCatalystAppIdentifier.asRubyArgument(name: "derive_catalyst_app_identifier", type: nil)
    let templateNameArg = templateName.asRubyArgument(name: "template_name", type: nil)
    let profileNameArg = profileName.asRubyArgument(name: "profile_name", type: nil)
    let failOnNameTakenArg = failOnNameTaken.asRubyArgument(name: "fail_on_name_taken", type: nil)
    let skipCertificateMatchingArg = skipCertificateMatching.asRubyArgument(name: "skip_certificate_matching", type: nil)
    let outputPathArg = outputPath.asRubyArgument(name: "output_path", type: nil)
    let skipSetPartitionListArg = skipSetPartitionList.asRubyArgument(name: "skip_set_partition_list", type: nil)
    let forceLegacyEncryptionArg = forceLegacyEncryption.asRubyArgument(name: "force_legacy_encryption", type: nil)
    let verboseArg = verbose.asRubyArgument(name: "verbose", type: nil)
    let array: [RubyCommand.Argument?] = [typeArg,
                                          additionalCertTypesArg,
                                          readonlyArg,
                                          generateAppleCertsArg,
                                          skipProvisioningProfilesArg,
                                          appIdentifierArg,
                                          apiKeyPathArg,
                                          apiKeyArg,
                                          usernameArg,
                                          teamIdArg,
                                          teamNameArg,
                                          storageModeArg,
                                          gitUrlArg,
                                          gitBranchArg,
                                          gitFullNameArg,
                                          gitUserEmailArg,
                                          shallowCloneArg,
                                          cloneBranchDirectlyArg,
                                          gitBasicAuthorizationArg,
                                          gitBearerAuthorizationArg,
                                          gitPrivateKeyArg,
                                          googleCloudBucketNameArg,
                                          googleCloudKeysFileArg,
                                          googleCloudProjectIdArg,
                                          skipGoogleCloudAccountConfirmationArg,
                                          s3RegionArg,
                                          s3AccessKeyArg,
                                          s3SecretAccessKeyArg,
                                          s3BucketArg,
                                          s3ObjectPrefixArg,
                                          s3SkipEncryptionArg,
                                          gitlabProjectArg,
                                          gitlabHostArg,
                                          jobTokenArg,
                                          privateTokenArg,
                                          keychainNameArg,
                                          keychainPasswordArg,
                                          forceArg,
                                          forceForNewDevicesArg,
                                          includeMacInProfilesArg,
                                          includeAllCertificatesArg,
                                          certificateIdArg,
                                          forceForNewCertificatesArg,
                                          skipConfirmationArg,
                                          safeRemoveCertsArg,
                                          skipDocsArg,
                                          platformArg,
                                          deriveCatalystAppIdentifierArg,
                                          templateNameArg,
                                          profileNameArg,
                                          failOnNameTakenArg,
                                          skipCertificateMatchingArg,
                                          outputPathArg,
                                          skipSetPartitionListArg,
                                          forceLegacyEncryptionArg,
                                          verboseArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "match_nuke", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Verifies the minimum fastlane version required

 Add this to your `Fastfile` to require a certain version of _fastlane_.
 Use it if you use an action that just recently came out and you need it.
 */
public func minFastlaneVersion() {
    let args: [RubyCommand.Argument] = []
    let command = RubyCommand(commandID: "", methodName: "min_fastlane_version", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Modifies the services of the app created on Developer Portal

 - parameters:
   - username: Your Apple ID Username
   - appIdentifier: App Identifier (Bundle ID, e.g. com.krausefx.app)
   - services: Array with Spaceship App Services (e.g. access_wifi: (on|off)(:on|:off)(true|false), app_attest: (on|off)(:on|:off)(true|false), app_group: (on|off)(:on|:off)(true|false), apple_pay: (on|off)(:on|:off)(true|false), associated_domains: (on|off)(:on|:off)(true|false), auto_fill_credential: (on|off)(:on|:off)(true|false), class_kit: (on|off)(:on|:off)(true|false), icloud: (legacy|cloudkit)(:on|:off)(true|false), custom_network_protocol: (on|off)(:on|:off)(true|false), data_protection: (complete|unlessopen|untilfirstauth)(:on|:off)(true|false), extended_virtual_address_space: (on|off)(:on|:off)(true|false), family_controls: (on|off)(:on|:off)(true|false), file_provider_testing_mode: (on|off)(:on|:off)(true|false), fonts: (on|off)(:on|:off)(true|false), game_center: (ios|mac)(:on|:off)(true|false), health_kit: (on|off)(:on|:off)(true|false), hls_interstitial_preview: (on|off)(:on|:off)(true|false), home_kit: (on|off)(:on|:off)(true|false), hotspot: (on|off)(:on|:off)(true|false), in_app_purchase: (on|off)(:on|:off)(true|false), inter_app_audio: (on|off)(:on|:off)(true|false), low_latency_hls: (on|off)(:on|:off)(true|false), managed_associated_domains: (on|off)(:on|:off)(true|false), maps: (on|off)(:on|:off)(true|false), multipath: (on|off)(:on|:off)(true|false), network_extension: (on|off)(:on|:off)(true|false), nfc_tag_reading: (on|off)(:on|:off)(true|false), personal_vpn: (on|off)(:on|:off)(true|false), passbook: (on|off)(:on|:off)(true|false), push_notification: (on|off)(:on|:off)(true|false), sign_in_with_apple: (on)(:on|:off)(true|false), siri_kit: (on|off)(:on|:off)(true|false), system_extension: (on|off)(:on|:off)(true|false), user_management: (on|off)(:on|:off)(true|false), vpn_configuration: (on|off)(:on|:off)(true|false), wallet: (on|off)(:on|:off)(true|false), wireless_accessory: (on|off)(:on|:off)(true|false), car_play_audio_app: (on|off)(:on|:off)(true|false), car_play_messaging_app: (on|off)(:on|:off)(true|false), car_play_navigation_app: (on|off)(:on|:off)(true|false), car_play_voip_calling_app: (on|off)(:on|:off)(true|false), critical_alerts: (on|off)(:on|:off)(true|false), hotspot_helper: (on|off)(:on|:off)(true|false), driver_kit: (on|off)(:on|:off)(true|false), driver_kit_endpoint_security: (on|off)(:on|:off)(true|false), driver_kit_family_hid_device: (on|off)(:on|:off)(true|false), driver_kit_family_networking: (on|off)(:on|:off)(true|false), driver_kit_family_serial: (on|off)(:on|:off)(true|false), driver_kit_hid_event_service: (on|off)(:on|:off)(true|false), driver_kit_transport_hid: (on|off)(:on|:off)(true|false), multitasking_camera_access: (on|off)(:on|:off)(true|false), sf_universal_link_api: (on|off)(:on|:off)(true|false), vp9_decoder: (on|off)(:on|:off)(true|false), music_kit: (on|off)(:on|:off)(true|false), shazam_kit: (on|off)(:on|:off)(true|false), communication_notifications: (on|off)(:on|:off)(true|false), group_activities: (on|off)(:on|:off)(true|false), health_kit_estimate_recalibration: (on|off)(:on|:off)(true|false), time_sensitive_notifications: (on|off)(:on|:off)(true|false))
   - teamId: The ID of your Developer Portal team if you're in multiple teams
   - teamName: The name of your Developer Portal team if you're in multiple teams

 The options are the same as `:enable_services` in the [produce action](https://docs.fastlane.tools/actions/produce/#parameters_1)
 */
public func modifyServices(username: String,
                           appIdentifier: String,
                           services: [String: Any] = [:],
                           teamId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                           teamName: OptionalConfigValue<String?> = .fastlaneDefault(nil))
{
    let usernameArg = RubyCommand.Argument(name: "username", value: username, type: nil)
    let appIdentifierArg = RubyCommand.Argument(name: "app_identifier", value: appIdentifier, type: nil)
    let servicesArg = RubyCommand.Argument(name: "services", value: services, type: nil)
    let teamIdArg = teamId.asRubyArgument(name: "team_id", type: nil)
    let teamNameArg = teamName.asRubyArgument(name: "team_name", type: nil)
    let array: [RubyCommand.Argument?] = [usernameArg,
                                          appIdentifierArg,
                                          servicesArg,
                                          teamIdArg,
                                          teamNameArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "modify_services", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Upload a file to [Sonatype Nexus platform](https://www.sonatype.com)

 - parameters:
   - file: File to be uploaded to Nexus
   - repoId: Nexus repository id e.g. artefacts
   - repoGroupId: Nexus repository group id e.g. com.company
   - repoProjectName: Nexus repository commandect name. Only letters, digits, underscores(_), hyphens(-), and dots(.) are allowed
   - repoProjectVersion: Nexus repository commandect version
   - repoClassifier: Nexus repository artifact classifier (optional)
   - endpoint: Nexus endpoint e.g. http://nexus:8081
   - mountPath: Nexus mount path (Nexus 3 instances have this configured as empty by default)
   - username: Nexus username
   - password: Nexus password
   - sslVerify: Verify SSL
   - nexusVersion: Nexus major version
   - verbose: Make detailed output
   - proxyUsername: Proxy username
   - proxyPassword: Proxy password
   - proxyAddress: Proxy address
   - proxyPort: Proxy port
 */
public func nexusUpload(file: String,
                        repoId: String,
                        repoGroupId: String,
                        repoProjectName: String,
                        repoProjectVersion: String,
                        repoClassifier: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                        endpoint: String,
                        mountPath: String = "/nexus",
                        username: String,
                        password: String,
                        sslVerify: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                        nexusVersion: Int = 2,
                        verbose: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                        proxyUsername: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                        proxyPassword: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                        proxyAddress: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                        proxyPort: OptionalConfigValue<String?> = .fastlaneDefault(nil))
{
    let fileArg = RubyCommand.Argument(name: "file", value: file, type: nil)
    let repoIdArg = RubyCommand.Argument(name: "repo_id", value: repoId, type: nil)
    let repoGroupIdArg = RubyCommand.Argument(name: "repo_group_id", value: repoGroupId, type: nil)
    let repoProjectNameArg = RubyCommand.Argument(name: "repo_project_name", value: repoProjectName, type: nil)
    let repoProjectVersionArg = RubyCommand.Argument(name: "repo_project_version", value: repoProjectVersion, type: nil)
    let repoClassifierArg = repoClassifier.asRubyArgument(name: "repo_classifier", type: nil)
    let endpointArg = RubyCommand.Argument(name: "endpoint", value: endpoint, type: nil)
    let mountPathArg = RubyCommand.Argument(name: "mount_path", value: mountPath, type: nil)
    let usernameArg = RubyCommand.Argument(name: "username", value: username, type: nil)
    let passwordArg = RubyCommand.Argument(name: "password", value: password, type: nil)
    let sslVerifyArg = sslVerify.asRubyArgument(name: "ssl_verify", type: nil)
    let nexusVersionArg = RubyCommand.Argument(name: "nexus_version", value: nexusVersion, type: nil)
    let verboseArg = verbose.asRubyArgument(name: "verbose", type: nil)
    let proxyUsernameArg = proxyUsername.asRubyArgument(name: "proxy_username", type: nil)
    let proxyPasswordArg = proxyPassword.asRubyArgument(name: "proxy_password", type: nil)
    let proxyAddressArg = proxyAddress.asRubyArgument(name: "proxy_address", type: nil)
    let proxyPortArg = proxyPort.asRubyArgument(name: "proxy_port", type: nil)
    let array: [RubyCommand.Argument?] = [fileArg,
                                          repoIdArg,
                                          repoGroupIdArg,
                                          repoProjectNameArg,
                                          repoProjectVersionArg,
                                          repoClassifierArg,
                                          endpointArg,
                                          mountPathArg,
                                          usernameArg,
                                          passwordArg,
                                          sslVerifyArg,
                                          nexusVersionArg,
                                          verboseArg,
                                          proxyUsernameArg,
                                          proxyPasswordArg,
                                          proxyAddressArg,
                                          proxyPortArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "nexus_upload", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Notarizes a macOS app

 - parameters:
   - package: Path to package to notarize, e.g. .app bundle or disk image
   - useNotarytool: Whether to `xcrun notarytool` or `xcrun altool`
   - tryEarlyStapling: Whether to try early stapling while the notarization request is in progress
   - skipStapling: Do not staple the notarization ticket to the artifact; useful for single file executables and ZIP archives
   - bundleId: Bundle identifier to uniquely identify the package
   - username: Apple ID username
   - ascProvider: Provider short name for accounts associated with multiple providers
   - printLog: Whether to print notarization log file, listing issues on failure and warnings on success
   - verbose: Whether to log requests
   - apiKeyPath: Path to your App Store Connect API Key JSON file (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-json-file)
   - apiKey: Your App Store Connect API Key information (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-hash-option)
 */
public func notarize(package: String,
                     useNotarytool: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                     tryEarlyStapling: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                     skipStapling: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                     bundleId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     username: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     ascProvider: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     printLog: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                     verbose: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                     apiKeyPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                     apiKey: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil))
{
    let packageArg = RubyCommand.Argument(name: "package", value: package, type: nil)
    let useNotarytoolArg = useNotarytool.asRubyArgument(name: "use_notarytool", type: nil)
    let tryEarlyStaplingArg = tryEarlyStapling.asRubyArgument(name: "try_early_stapling", type: nil)
    let skipStaplingArg = skipStapling.asRubyArgument(name: "skip_stapling", type: nil)
    let bundleIdArg = bundleId.asRubyArgument(name: "bundle_id", type: nil)
    let usernameArg = username.asRubyArgument(name: "username", type: nil)
    let ascProviderArg = ascProvider.asRubyArgument(name: "asc_provider", type: nil)
    let printLogArg = printLog.asRubyArgument(name: "print_log", type: nil)
    let verboseArg = verbose.asRubyArgument(name: "verbose", type: nil)
    let apiKeyPathArg = apiKeyPath.asRubyArgument(name: "api_key_path", type: nil)
    let apiKeyArg = apiKey.asRubyArgument(name: "api_key", type: nil)
    let array: [RubyCommand.Argument?] = [packageArg,
                                          useNotarytoolArg,
                                          tryEarlyStaplingArg,
                                          skipStaplingArg,
                                          bundleIdArg,
                                          usernameArg,
                                          ascProviderArg,
                                          printLogArg,
                                          verboseArg,
                                          apiKeyPathArg,
                                          apiKeyArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "notarize", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Display a macOS notification with custom message and title

 - parameters:
   - title: The title to display in the notification
   - subtitle: A subtitle to display in the notification
   - message: The message to display in the notification
   - sound: The name of a sound to play when the notification appears (names are listed in Sound Preferences)
   - activate: Bundle identifier of application to be opened when the notification is clicked
   - appIcon: The URL of an image to display instead of the application icon (Mavericks+ only)
   - contentImage: The URL of an image to display attached to the notification (Mavericks+ only)
   - open: URL of the resource to be opened when the notification is clicked
   - execute: Shell command to run when the notification is clicked
 */
public func notification(title: String = "fastlane",
                         subtitle: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                         message: String,
                         sound: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                         activate: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                         appIcon: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                         contentImage: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                         open: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                         execute: OptionalConfigValue<String?> = .fastlaneDefault(nil))
{
    let titleArg = RubyCommand.Argument(name: "title", value: title, type: nil)
    let subtitleArg = subtitle.asRubyArgument(name: "subtitle", type: nil)
    let messageArg = RubyCommand.Argument(name: "message", value: message, type: nil)
    let soundArg = sound.asRubyArgument(name: "sound", type: nil)
    let activateArg = activate.asRubyArgument(name: "activate", type: nil)
    let appIconArg = appIcon.asRubyArgument(name: "app_icon", type: nil)
    let contentImageArg = contentImage.asRubyArgument(name: "content_image", type: nil)
    let openArg = open.asRubyArgument(name: "open", type: nil)
    let executeArg = execute.asRubyArgument(name: "execute", type: nil)
    let array: [RubyCommand.Argument?] = [titleArg,
                                          subtitleArg,
                                          messageArg,
                                          soundArg,
                                          activateArg,
                                          appIconArg,
                                          contentImageArg,
                                          openArg,
                                          executeArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "notification", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Shows a macOS notification - use `notification` instead
 */
public func notify() {
    let args: [RubyCommand.Argument] = []
    let command = RubyCommand(commandID: "", methodName: "notify", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Return the number of commits in current git branch

 - parameter all: Returns number of all commits instead of current branch

 - returns: The total number of all commits in current git branch

 You can use this action to get the number of commits of this branch. This is useful if you want to set the build number to the number of commits. See `fastlane actions number_of_commits` for more details.
 */
@discardableResult public func numberOfCommits(all: OptionalConfigValue<Bool?> = .fastlaneDefault(nil)) -> Int {
    let allArg = all.asRubyArgument(name: "all", type: nil)
    let array: [RubyCommand.Argument?] = [allArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "number_of_commits", className: nil, args: args)
    return parseInt(fromString: runner.executeCommand(command))
}

/**
 Lints implementation files with OCLint

 - parameters:
   - oclintPath: The path to oclint binary
   - compileCommands: The json compilation database, use xctool reporter 'json-compilation-database'
   - selectReqex: **DEPRECATED!** Use `:select_regex` instead - Select all files matching this reqex
   - selectRegex: Select all files matching this regex
   - excludeRegex: Exclude all files matching this regex
   - reportType: The type of the report (default: html)
   - reportPath: The reports file path
   - listEnabledRules: List enabled rules
   - rc: Override the default behavior of rules
   - thresholds: List of rule thresholds to override the default behavior of rules
   - enableRules: List of rules to pick explicitly
   - disableRules: List of rules to disable
   - maxPriority1: The max allowed number of priority 1 violations
   - maxPriority2: The max allowed number of priority 2 violations
   - maxPriority3: The max allowed number of priority 3 violations
   - enableClangStaticAnalyzer: Enable Clang Static Analyzer, and integrate results into OCLint report
   - enableGlobalAnalysis: Compile every source, and analyze across global contexts (depends on number of source files, could results in high memory load)
   - allowDuplicatedViolations: Allow duplicated violations in the OCLint report
   - extraArg: Additional argument to append to the compiler command line

 Run the static analyzer tool [OCLint](http://oclint.org) for your project. You need to have a `compile_commands.json` file in your _fastlane_ directory or pass a path to your file.
 */
public func oclint(oclintPath: String = "oclint",
                   compileCommands: String = "compile_commands.json",
                   selectReqex: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   selectRegex: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   excludeRegex: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   reportType: String = "html",
                   reportPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   listEnabledRules: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                   rc: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   thresholds: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                   enableRules: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                   disableRules: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                   maxPriority1: OptionalConfigValue<Int?> = .fastlaneDefault(nil),
                   maxPriority2: OptionalConfigValue<Int?> = .fastlaneDefault(nil),
                   maxPriority3: OptionalConfigValue<Int?> = .fastlaneDefault(nil),
                   enableClangStaticAnalyzer: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                   enableGlobalAnalysis: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                   allowDuplicatedViolations: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                   extraArg: OptionalConfigValue<String?> = .fastlaneDefault(nil))
{
    let oclintPathArg = RubyCommand.Argument(name: "oclint_path", value: oclintPath, type: nil)
    let compileCommandsArg = RubyCommand.Argument(name: "compile_commands", value: compileCommands, type: nil)
    let selectReqexArg = selectReqex.asRubyArgument(name: "select_reqex", type: nil)
    let selectRegexArg = selectRegex.asRubyArgument(name: "select_regex", type: nil)
    let excludeRegexArg = excludeRegex.asRubyArgument(name: "exclude_regex", type: nil)
    let reportTypeArg = RubyCommand.Argument(name: "report_type", value: reportType, type: nil)
    let reportPathArg = reportPath.asRubyArgument(name: "report_path", type: nil)
    let listEnabledRulesArg = listEnabledRules.asRubyArgument(name: "list_enabled_rules", type: nil)
    let rcArg = rc.asRubyArgument(name: "rc", type: nil)
    let thresholdsArg = thresholds.asRubyArgument(name: "thresholds", type: nil)
    let enableRulesArg = enableRules.asRubyArgument(name: "enable_rules", type: nil)
    let disableRulesArg = disableRules.asRubyArgument(name: "disable_rules", type: nil)
    let maxPriority1Arg = maxPriority1.asRubyArgument(name: "max_priority_1", type: nil)
    let maxPriority2Arg = maxPriority2.asRubyArgument(name: "max_priority_2", type: nil)
    let maxPriority3Arg = maxPriority3.asRubyArgument(name: "max_priority_3", type: nil)
    let enableClangStaticAnalyzerArg = enableClangStaticAnalyzer.asRubyArgument(name: "enable_clang_static_analyzer", type: nil)
    let enableGlobalAnalysisArg = enableGlobalAnalysis.asRubyArgument(name: "enable_global_analysis", type: nil)
    let allowDuplicatedViolationsArg = allowDuplicatedViolations.asRubyArgument(name: "allow_duplicated_violations", type: nil)
    let extraArgArg = extraArg.asRubyArgument(name: "extra_arg", type: nil)
    let array: [RubyCommand.Argument?] = [oclintPathArg,
                                          compileCommandsArg,
                                          selectReqexArg,
                                          selectRegexArg,
                                          excludeRegexArg,
                                          reportTypeArg,
                                          reportPathArg,
                                          listEnabledRulesArg,
                                          rcArg,
                                          thresholdsArg,
                                          enableRulesArg,
                                          disableRulesArg,
                                          maxPriority1Arg,
                                          maxPriority2Arg,
                                          maxPriority3Arg,
                                          enableClangStaticAnalyzerArg,
                                          enableGlobalAnalysisArg,
                                          allowDuplicatedViolationsArg,
                                          extraArgArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "oclint", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Create or update a new [OneSignal](https://onesignal.com/) application

 - parameters:
   - appId: OneSignal App ID. Setting this updates an existing app
   - authToken: OneSignal Authorization Key
   - appName: OneSignal App Name. This is required when creating an app (in other words, when `:app_id` is not set, and optional when updating an app
   - androidToken: ANDROID GCM KEY
   - androidGcmSenderId: GCM SENDER ID
   - fcmJson: FCM Service Account JSON File (in .json format)
   - apnsP12: APNS P12 File (in .p12 format)
   - apnsP12Password: APNS P12 password
   - apnsEnv: APNS environment
   - organizationId: OneSignal Organization ID

 You can use this action to automatically create or update a OneSignal application. You can also upload a `.p12` with password, a GCM key, or both.
 */
public func onesignal(appId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      authToken: String,
                      appName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      androidToken: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      androidGcmSenderId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      fcmJson: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      apnsP12: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      apnsP12Password: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      apnsEnv: String = "production",
                      organizationId: OptionalConfigValue<String?> = .fastlaneDefault(nil))
{
    let appIdArg = appId.asRubyArgument(name: "app_id", type: nil)
    let authTokenArg = RubyCommand.Argument(name: "auth_token", value: authToken, type: nil)
    let appNameArg = appName.asRubyArgument(name: "app_name", type: nil)
    let androidTokenArg = androidToken.asRubyArgument(name: "android_token", type: nil)
    let androidGcmSenderIdArg = androidGcmSenderId.asRubyArgument(name: "android_gcm_sender_id", type: nil)
    let fcmJsonArg = fcmJson.asRubyArgument(name: "fcm_json", type: nil)
    let apnsP12Arg = apnsP12.asRubyArgument(name: "apns_p12", type: nil)
    let apnsP12PasswordArg = apnsP12Password.asRubyArgument(name: "apns_p12_password", type: nil)
    let apnsEnvArg = RubyCommand.Argument(name: "apns_env", value: apnsEnv, type: nil)
    let organizationIdArg = organizationId.asRubyArgument(name: "organization_id", type: nil)
    let array: [RubyCommand.Argument?] = [appIdArg,
                                          authTokenArg,
                                          appNameArg,
                                          androidTokenArg,
                                          androidGcmSenderIdArg,
                                          fcmJsonArg,
                                          apnsP12Arg,
                                          apnsP12PasswordArg,
                                          apnsEnvArg,
                                          organizationIdArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "onesignal", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 This will prevent reports from being uploaded when _fastlane_ crashes

 _fastlane_ doesn't have crash reporting anymore. Feel free to remove `opt_out_crash_reporting` from your Fastfile.
 */
public func optOutCrashReporting() {
    let args: [RubyCommand.Argument] = []
    let command = RubyCommand(commandID: "", methodName: "opt_out_crash_reporting", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 This will stop uploading the information which actions were run

 By default, _fastlane_ will track what actions are being used. No personal/sensitive information is recorded.
 Learn more at [https://docs.fastlane.tools/#metrics](https://docs.fastlane.tools/#metrics).
 Add `opt_out_usage` at the top of your Fastfile to disable metrics collection.
 */
public func optOutUsage() {
    let args: [RubyCommand.Argument] = []
    let command = RubyCommand(commandID: "", methodName: "opt_out_usage", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Alias for the `get_push_certificate` action

 - parameters:
   - platform: Set certificate's platform. Used for creation of production & development certificates. Supported platforms: ios, macos
   - development: Renew the development push certificate instead of the production one
   - websitePush: Create a Website Push certificate
   - generateP12: Generate a p12 file additionally to a PEM file
   - activeDaysLimit: If the current certificate is active for less than this number of days, generate a new one
   - force: Create a new push certificate, even if the current one is active for 30 (or PEM_ACTIVE_DAYS_LIMIT) more days
   - savePrivateKey: Set to save the private RSA key
   - appIdentifier: The bundle identifier of your app
   - username: Your Apple ID Username
   - teamId: The ID of your Developer Portal team if you're in multiple teams
   - teamName: The name of your Developer Portal team if you're in multiple teams
   - p12Password: The password that is used for your p12 file
   - pemName: The file name of the generated .pem file
   - outputPath: The path to a directory in which all certificates and private keys should be stored
   - newProfile: Block that is called if there is a new profile

 Additionally to the available options, you can also specify a block that only gets executed if a new profile was created. You can use it to upload the new profile to your server.
 Use it like this:|
 |
 ```ruby|
 get_push_certificate(|
   new_profile: proc do|
     # your upload code|
   end|
 )|
 ```|
 >|
 */
public func pem(platform: String = "ios",
                development: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                websitePush: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                generateP12: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                activeDaysLimit: Int = 30,
                force: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                savePrivateKey: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                appIdentifier: String,
                username: String,
                teamId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                teamName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                p12Password: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                pemName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                outputPath: String = ".",
                newProfile: ((String) -> Void)? = nil)
{
    let platformArg = RubyCommand.Argument(name: "platform", value: platform, type: nil)
    let developmentArg = development.asRubyArgument(name: "development", type: nil)
    let websitePushArg = websitePush.asRubyArgument(name: "website_push", type: nil)
    let generateP12Arg = generateP12.asRubyArgument(name: "generate_p12", type: nil)
    let activeDaysLimitArg = RubyCommand.Argument(name: "active_days_limit", value: activeDaysLimit, type: nil)
    let forceArg = force.asRubyArgument(name: "force", type: nil)
    let savePrivateKeyArg = savePrivateKey.asRubyArgument(name: "save_private_key", type: nil)
    let appIdentifierArg = RubyCommand.Argument(name: "app_identifier", value: appIdentifier, type: nil)
    let usernameArg = RubyCommand.Argument(name: "username", value: username, type: nil)
    let teamIdArg = teamId.asRubyArgument(name: "team_id", type: nil)
    let teamNameArg = teamName.asRubyArgument(name: "team_name", type: nil)
    let p12PasswordArg = p12Password.asRubyArgument(name: "p12_password", type: nil)
    let pemNameArg = pemName.asRubyArgument(name: "pem_name", type: nil)
    let outputPathArg = RubyCommand.Argument(name: "output_path", value: outputPath, type: nil)
    let newProfileArg = RubyCommand.Argument(name: "new_profile", value: newProfile, type: .stringClosure)
    let array: [RubyCommand.Argument?] = [platformArg,
                                          developmentArg,
                                          websitePushArg,
                                          generateP12Arg,
                                          activeDaysLimitArg,
                                          forceArg,
                                          savePrivateKeyArg,
                                          appIdentifierArg,
                                          usernameArg,
                                          teamIdArg,
                                          teamNameArg,
                                          p12PasswordArg,
                                          pemNameArg,
                                          outputPathArg,
                                          newProfileArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "pem", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Alias for the `upload_to_testflight` action

 - parameters:
   - apiKeyPath: Path to your App Store Connect API Key JSON file (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-json-file)
   - apiKey: Your App Store Connect API Key information (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-hash-option)
   - username: Your Apple ID Username
   - appIdentifier: The bundle identifier of the app to upload or manage testers (optional)
   - appPlatform: The platform to use (optional)
   - appleId: Apple ID property in the App Information section in App Store Connect
   - ipa: Path to the ipa file to upload
   - pkg: Path to your pkg file
   - demoAccountRequired: Do you need a demo account when Apple does review?
   - betaAppReviewInfo: Beta app review information for contact info and demo account
   - localizedAppInfo: Localized beta app test info for description, feedback email, marketing url, and privacy policy
   - betaAppDescription: Provide the 'Beta App Description' when uploading a new build
   - betaAppFeedbackEmail: Provide the beta app email when uploading a new build
   - localizedBuildInfo: Localized beta app test info for what's new
   - changelog: Provide the 'What to Test' text when uploading a new build
   - skipSubmission: Skip the distributing action of pilot and only upload the ipa file
   - skipWaitingForBuildProcessing: If set to true, the `distribute_external` option won't work and no build will be distributed to testers. (You might want to use this option if you are using this action on CI and have to pay for 'minutes used' on your CI plan). If set to `true` and a changelog is provided, it will partially wait for the build to appear on AppStore Connect so the changelog can be set, and skip the remaining processing steps
   - updateBuildInfoOnUpload: **DEPRECATED!** Update build info immediately after validation. This is deprecated and will be removed in a future release. App Store Connect no longer supports setting build info until after build processing has completed, which is when build info is updated by default
   - distributeOnly: Distribute a previously uploaded build (equivalent to the `fastlane pilot distribute` command)
   - usesNonExemptEncryption: Provide the 'Uses Non-Exempt Encryption' for export compliance. This is used if there is 'ITSAppUsesNonExemptEncryption' is not set in the Info.plist
   - distributeExternal: Should the build be distributed to external testers? If set to true, use of `groups` option is required
   - notifyExternalTesters: Should notify external testers? (Not setting a value will use App Store Connect's default which is to notify)
   - appVersion: The version number of the application build to distribute. If the version number is not specified, then the most recent build uploaded to TestFlight will be distributed. If specified, the most recent build for the version number will be distributed
   - buildNumber: The build number of the application build to distribute. If the build number is not specified, the most recent build is distributed
   - expirePreviousBuilds: Should expire previous builds?
   - firstName: The tester's first name
   - lastName: The tester's last name
   - email: The tester's email
   - testersFilePath: Path to a CSV file of testers
   - groups: Associate tester to one group or more by group name / group id. E.g. `-g "Team 1","Team 2"` This is required when `distribute_external` option is set to true or when we want to add a tester to one or more external testing groups
   - teamId: The ID of your App Store Connect team if you're in multiple teams
   - teamName: The name of your App Store Connect team if you're in multiple teams
   - devPortalTeamId: The short ID of your team in the developer portal, if you're in multiple teams. Different from your iTC team ID!
   - itcProvider: The provider short name to be used with the iTMSTransporter to identify your team. This value will override the automatically detected provider short name. To get provider short name run `xcrun iTMSTransporter -m provider -u 'USERNAME' -p 'PASSWORD' -account_type itunes_connect -v off`. The short names of providers should be listed in the second column
   - waitProcessingInterval: Interval in seconds to wait for App Store Connect processing
   - waitProcessingTimeoutDuration: Timeout duration in seconds to wait for App Store Connect processing. If set, after exceeding timeout duration, this will `force stop` to wait for App Store Connect processing and exit with exception
   - waitForUploadedBuild: **DEPRECATED!** No longer needed with the transition over to the App Store Connect API - Use version info from uploaded ipa file to determine what build to use for distribution. If set to false, latest processing or any latest build will be used
   - rejectBuildWaitingForReview: Expire previous if it's 'waiting for review'
   - submitBetaReview: Send the build for a beta review

 More details can be found on https://docs.fastlane.tools/actions/pilot/.
 This integration will only do the TestFlight upload.
 */
public func pilot(apiKeyPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  apiKey: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                  username: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  appIdentifier: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  appPlatform: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  appleId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  ipa: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  pkg: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  demoAccountRequired: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                  betaAppReviewInfo: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                  localizedAppInfo: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                  betaAppDescription: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  betaAppFeedbackEmail: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  localizedBuildInfo: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                  changelog: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  skipSubmission: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                  skipWaitingForBuildProcessing: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                  updateBuildInfoOnUpload: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                  distributeOnly: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                  usesNonExemptEncryption: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                  distributeExternal: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                  notifyExternalTesters: Any? = nil,
                  appVersion: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  buildNumber: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  expirePreviousBuilds: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                  firstName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  lastName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  email: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  testersFilePath: String = "./testers.csv",
                  groups: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                  teamId: Any? = nil,
                  teamName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  devPortalTeamId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  itcProvider: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  waitProcessingInterval: Int = 30,
                  waitProcessingTimeoutDuration: OptionalConfigValue<Int?> = .fastlaneDefault(nil),
                  waitForUploadedBuild: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                  rejectBuildWaitingForReview: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                  submitBetaReview: OptionalConfigValue<Bool> = .fastlaneDefault(true))
{
    let apiKeyPathArg = apiKeyPath.asRubyArgument(name: "api_key_path", type: nil)
    let apiKeyArg = apiKey.asRubyArgument(name: "api_key", type: nil)
    let usernameArg = username.asRubyArgument(name: "username", type: nil)
    let appIdentifierArg = appIdentifier.asRubyArgument(name: "app_identifier", type: nil)
    let appPlatformArg = appPlatform.asRubyArgument(name: "app_platform", type: nil)
    let appleIdArg = appleId.asRubyArgument(name: "apple_id", type: nil)
    let ipaArg = ipa.asRubyArgument(name: "ipa", type: nil)
    let pkgArg = pkg.asRubyArgument(name: "pkg", type: nil)
    let demoAccountRequiredArg = demoAccountRequired.asRubyArgument(name: "demo_account_required", type: nil)
    let betaAppReviewInfoArg = betaAppReviewInfo.asRubyArgument(name: "beta_app_review_info", type: nil)
    let localizedAppInfoArg = localizedAppInfo.asRubyArgument(name: "localized_app_info", type: nil)
    let betaAppDescriptionArg = betaAppDescription.asRubyArgument(name: "beta_app_description", type: nil)
    let betaAppFeedbackEmailArg = betaAppFeedbackEmail.asRubyArgument(name: "beta_app_feedback_email", type: nil)
    let localizedBuildInfoArg = localizedBuildInfo.asRubyArgument(name: "localized_build_info", type: nil)
    let changelogArg = changelog.asRubyArgument(name: "changelog", type: nil)
    let skipSubmissionArg = skipSubmission.asRubyArgument(name: "skip_submission", type: nil)
    let skipWaitingForBuildProcessingArg = skipWaitingForBuildProcessing.asRubyArgument(name: "skip_waiting_for_build_processing", type: nil)
    let updateBuildInfoOnUploadArg = updateBuildInfoOnUpload.asRubyArgument(name: "update_build_info_on_upload", type: nil)
    let distributeOnlyArg = distributeOnly.asRubyArgument(name: "distribute_only", type: nil)
    let usesNonExemptEncryptionArg = usesNonExemptEncryption.asRubyArgument(name: "uses_non_exempt_encryption", type: nil)
    let distributeExternalArg = distributeExternal.asRubyArgument(name: "distribute_external", type: nil)
    let notifyExternalTestersArg = RubyCommand.Argument(name: "notify_external_testers", value: notifyExternalTesters, type: nil)
    let appVersionArg = appVersion.asRubyArgument(name: "app_version", type: nil)
    let buildNumberArg = buildNumber.asRubyArgument(name: "build_number", type: nil)
    let expirePreviousBuildsArg = expirePreviousBuilds.asRubyArgument(name: "expire_previous_builds", type: nil)
    let firstNameArg = firstName.asRubyArgument(name: "first_name", type: nil)
    let lastNameArg = lastName.asRubyArgument(name: "last_name", type: nil)
    let emailArg = email.asRubyArgument(name: "email", type: nil)
    let testersFilePathArg = RubyCommand.Argument(name: "testers_file_path", value: testersFilePath, type: nil)
    let groupsArg = groups.asRubyArgument(name: "groups", type: nil)
    let teamIdArg = RubyCommand.Argument(name: "team_id", value: teamId, type: nil)
    let teamNameArg = teamName.asRubyArgument(name: "team_name", type: nil)
    let devPortalTeamIdArg = devPortalTeamId.asRubyArgument(name: "dev_portal_team_id", type: nil)
    let itcProviderArg = itcProvider.asRubyArgument(name: "itc_provider", type: nil)
    let waitProcessingIntervalArg = RubyCommand.Argument(name: "wait_processing_interval", value: waitProcessingInterval, type: nil)
    let waitProcessingTimeoutDurationArg = waitProcessingTimeoutDuration.asRubyArgument(name: "wait_processing_timeout_duration", type: nil)
    let waitForUploadedBuildArg = waitForUploadedBuild.asRubyArgument(name: "wait_for_uploaded_build", type: nil)
    let rejectBuildWaitingForReviewArg = rejectBuildWaitingForReview.asRubyArgument(name: "reject_build_waiting_for_review", type: nil)
    let submitBetaReviewArg = submitBetaReview.asRubyArgument(name: "submit_beta_review", type: nil)
    let array: [RubyCommand.Argument?] = [apiKeyPathArg,
                                          apiKeyArg,
                                          usernameArg,
                                          appIdentifierArg,
                                          appPlatformArg,
                                          appleIdArg,
                                          ipaArg,
                                          pkgArg,
                                          demoAccountRequiredArg,
                                          betaAppReviewInfoArg,
                                          localizedAppInfoArg,
                                          betaAppDescriptionArg,
                                          betaAppFeedbackEmailArg,
                                          localizedBuildInfoArg,
                                          changelogArg,
                                          skipSubmissionArg,
                                          skipWaitingForBuildProcessingArg,
                                          updateBuildInfoOnUploadArg,
                                          distributeOnlyArg,
                                          usesNonExemptEncryptionArg,
                                          distributeExternalArg,
                                          notifyExternalTestersArg,
                                          appVersionArg,
                                          buildNumberArg,
                                          expirePreviousBuildsArg,
                                          firstNameArg,
                                          lastNameArg,
                                          emailArg,
                                          testersFilePathArg,
                                          groupsArg,
                                          teamIdArg,
                                          teamNameArg,
                                          devPortalTeamIdArg,
                                          itcProviderArg,
                                          waitProcessingIntervalArg,
                                          waitProcessingTimeoutDurationArg,
                                          waitForUploadedBuildArg,
                                          rejectBuildWaitingForReviewArg,
                                          submitBetaReviewArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "pilot", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 [31mNo description provided[0m

 - parameters:
   - outputPath:
   - templatePath:
   - cachePath:
 */
public func pluginScores(outputPath: String,
                         templatePath: String,
                         cachePath: String)
{
    let outputPathArg = RubyCommand.Argument(name: "output_path", value: outputPath, type: nil)
    let templatePathArg = RubyCommand.Argument(name: "template_path", value: templatePath, type: nil)
    let cachePathArg = RubyCommand.Argument(name: "cache_path", value: cachePath, type: nil)
    let array: [RubyCommand.Argument?] = [outputPathArg,
                                          templatePathArg,
                                          cachePathArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "plugin_scores", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Pod lib lint

 - parameters:
   - useBundleExec: Use bundle exec when there is a Gemfile presented
   - podspec: Path of spec to lint
   - verbose: Allow output detail in console
   - allowWarnings: Allow warnings during pod lint
   - sources: The sources of repos you want the pod spec to lint with, separated by commas
   - subspec: A specific subspec to lint instead of the entire spec
   - includePodspecs: A Glob of additional ancillary podspecs which are used for linting via :path (available since cocoapods >= 1.7)
   - externalPodspecs: A Glob of additional ancillary podspecs which are used for linting via :podspec. If there are --include-podspecs, then these are removed from them (available since cocoapods >= 1.7)
   - swiftVersion: The SWIFT_VERSION that should be used to lint the spec. This takes precedence over a .swift-version file
   - useLibraries: Lint uses static libraries to install the spec
   - useModularHeaders: Lint using modular libraries (available since cocoapods >= 1.6)
   - failFast: Lint stops on the first failing platform or subspec
   - private: Lint skips checks that apply only to public specs
   - quick: Lint skips checks that would require to download and build the spec
   - noClean: Lint leaves the build directory intact for inspection
   - noSubspecs: Lint skips validation of subspecs
   - platforms: Lint against specific platforms (defaults to all platforms supported by the podspec). Multiple platforms must be comma-delimited (available since cocoapods >= 1.6)
   - skipImportValidation: Lint skips validating that the pod can be imported (available since cocoapods >= 1.3)
   - skipTests: Lint skips building and running tests during validation (available since cocoapods >= 1.3)
   - analyze: Validate with the Xcode Static Analysis tool (available since cocoapods >= 1.6.1)

 Test the syntax of your Podfile by linting the pod against the files of its directory
 */
public func podLibLint(useBundleExec: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                       podspec: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                       verbose: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                       allowWarnings: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                       sources: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                       subspec: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                       includePodspecs: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                       externalPodspecs: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                       swiftVersion: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                       useLibraries: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                       useModularHeaders: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                       failFast: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                       private: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                       quick: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                       noClean: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                       noSubspecs: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                       platforms: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                       skipImportValidation: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                       skipTests: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                       analyze: OptionalConfigValue<Bool> = .fastlaneDefault(false))
{
    let useBundleExecArg = useBundleExec.asRubyArgument(name: "use_bundle_exec", type: nil)
    let podspecArg = podspec.asRubyArgument(name: "podspec", type: nil)
    let verboseArg = verbose.asRubyArgument(name: "verbose", type: nil)
    let allowWarningsArg = allowWarnings.asRubyArgument(name: "allow_warnings", type: nil)
    let sourcesArg = sources.asRubyArgument(name: "sources", type: nil)
    let subspecArg = subspec.asRubyArgument(name: "subspec", type: nil)
    let includePodspecsArg = includePodspecs.asRubyArgument(name: "include_podspecs", type: nil)
    let externalPodspecsArg = externalPodspecs.asRubyArgument(name: "external_podspecs", type: nil)
    let swiftVersionArg = swiftVersion.asRubyArgument(name: "swift_version", type: nil)
    let useLibrariesArg = useLibraries.asRubyArgument(name: "use_libraries", type: nil)
    let useModularHeadersArg = useModularHeaders.asRubyArgument(name: "use_modular_headers", type: nil)
    let failFastArg = failFast.asRubyArgument(name: "fail_fast", type: nil)
    let privateArg = `private`.asRubyArgument(name: "private", type: nil)
    let quickArg = quick.asRubyArgument(name: "quick", type: nil)
    let noCleanArg = noClean.asRubyArgument(name: "no_clean", type: nil)
    let noSubspecsArg = noSubspecs.asRubyArgument(name: "no_subspecs", type: nil)
    let platformsArg = platforms.asRubyArgument(name: "platforms", type: nil)
    let skipImportValidationArg = skipImportValidation.asRubyArgument(name: "skip_import_validation", type: nil)
    let skipTestsArg = skipTests.asRubyArgument(name: "skip_tests", type: nil)
    let analyzeArg = analyze.asRubyArgument(name: "analyze", type: nil)
    let array: [RubyCommand.Argument?] = [useBundleExecArg,
                                          podspecArg,
                                          verboseArg,
                                          allowWarningsArg,
                                          sourcesArg,
                                          subspecArg,
                                          includePodspecsArg,
                                          externalPodspecsArg,
                                          swiftVersionArg,
                                          useLibrariesArg,
                                          useModularHeadersArg,
                                          failFastArg,
                                          privateArg,
                                          quickArg,
                                          noCleanArg,
                                          noSubspecsArg,
                                          platformsArg,
                                          skipImportValidationArg,
                                          skipTestsArg,
                                          analyzeArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "pod_lib_lint", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Push a Podspec to Trunk or a private repository

 - parameters:
   - useBundleExec: Use bundle exec when there is a Gemfile presented
   - path: The Podspec you want to push
   - repo: The repo you want to push. Pushes to Trunk by default
   - allowWarnings: Allow warnings during pod push
   - useLibraries: Allow lint to use static libraries to install the spec
   - sources: The sources of repos you want the pod spec to lint with, separated by commas
   - swiftVersion: The SWIFT_VERSION that should be used to lint the spec. This takes precedence over a .swift-version file
   - skipImportValidation: Lint skips validating that the pod can be imported
   - skipTests: Lint skips building and running tests during validation
   - useJson: Convert the podspec to JSON before pushing it to the repo
   - verbose: Show more debugging information
   - useModularHeaders: Use modular headers option during validation
   - synchronous: If validation depends on other recently pushed pods, synchronize
   - noOverwrite: Disallow pushing that would overwrite an existing spec
   - localOnly: Does not perform the step of pushing REPO to its remote
 */
public func podPush(useBundleExec: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                    path: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                    repo: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                    allowWarnings: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                    useLibraries: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                    sources: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                    swiftVersion: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                    skipImportValidation: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                    skipTests: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                    useJson: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                    verbose: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                    useModularHeaders: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                    synchronous: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                    noOverwrite: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                    localOnly: OptionalConfigValue<Bool?> = .fastlaneDefault(nil))
{
    let useBundleExecArg = useBundleExec.asRubyArgument(name: "use_bundle_exec", type: nil)
    let pathArg = path.asRubyArgument(name: "path", type: nil)
    let repoArg = repo.asRubyArgument(name: "repo", type: nil)
    let allowWarningsArg = allowWarnings.asRubyArgument(name: "allow_warnings", type: nil)
    let useLibrariesArg = useLibraries.asRubyArgument(name: "use_libraries", type: nil)
    let sourcesArg = sources.asRubyArgument(name: "sources", type: nil)
    let swiftVersionArg = swiftVersion.asRubyArgument(name: "swift_version", type: nil)
    let skipImportValidationArg = skipImportValidation.asRubyArgument(name: "skip_import_validation", type: nil)
    let skipTestsArg = skipTests.asRubyArgument(name: "skip_tests", type: nil)
    let useJsonArg = useJson.asRubyArgument(name: "use_json", type: nil)
    let verboseArg = verbose.asRubyArgument(name: "verbose", type: nil)
    let useModularHeadersArg = useModularHeaders.asRubyArgument(name: "use_modular_headers", type: nil)
    let synchronousArg = synchronous.asRubyArgument(name: "synchronous", type: nil)
    let noOverwriteArg = noOverwrite.asRubyArgument(name: "no_overwrite", type: nil)
    let localOnlyArg = localOnly.asRubyArgument(name: "local_only", type: nil)
    let array: [RubyCommand.Argument?] = [useBundleExecArg,
                                          pathArg,
                                          repoArg,
                                          allowWarningsArg,
                                          useLibrariesArg,
                                          sourcesArg,
                                          swiftVersionArg,
                                          skipImportValidationArg,
                                          skipTestsArg,
                                          useJsonArg,
                                          verboseArg,
                                          useModularHeadersArg,
                                          synchronousArg,
                                          noOverwriteArg,
                                          localOnlyArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "pod_push", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Creates or updates an item within your Podio app

 - parameters:
   - clientId: Client ID for Podio API (see https://developers.podio.com/api-key)
   - clientSecret: Client secret for Podio API (see https://developers.podio.com/api-key)
   - appId: App ID of the app you intend to authenticate with (see https://developers.podio.com/authentication/app_auth)
   - appToken: App token of the app you intend to authenticate with (see https://developers.podio.com/authentication/app_auth)
   - identifyingField: String specifying the field key used for identification of an item
   - identifyingValue: String uniquely specifying an item within the app
   - otherFields: Dictionary of your app fields. Podio supports several field types, see https://developers.podio.com/doc/items

 Use this action to create or update an item within your Podio app (see [https://help.podio.com/hc/en-us/articles/201019278-Creating-apps-](https://help.podio.com/hc/en-us/articles/201019278-Creating-apps-)).
 Pass in dictionary with field keys and their values.
 Field key is located under `Modify app` -> `Advanced` -> `Developer` -> `External ID` (see [https://developers.podio.com/examples/items](https://developers.podio.com/examples/items)).
 */
public func podioItem(clientId: String,
                      clientSecret: String,
                      appId: String,
                      appToken: String,
                      identifyingField: String,
                      identifyingValue: String,
                      otherFields: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil))
{
    let clientIdArg = RubyCommand.Argument(name: "client_id", value: clientId, type: nil)
    let clientSecretArg = RubyCommand.Argument(name: "client_secret", value: clientSecret, type: nil)
    let appIdArg = RubyCommand.Argument(name: "app_id", value: appId, type: nil)
    let appTokenArg = RubyCommand.Argument(name: "app_token", value: appToken, type: nil)
    let identifyingFieldArg = RubyCommand.Argument(name: "identifying_field", value: identifyingField, type: nil)
    let identifyingValueArg = RubyCommand.Argument(name: "identifying_value", value: identifyingValue, type: nil)
    let otherFieldsArg = otherFields.asRubyArgument(name: "other_fields", type: nil)
    let array: [RubyCommand.Argument?] = [clientIdArg,
                                          clientSecretArg,
                                          appIdArg,
                                          appTokenArg,
                                          identifyingFieldArg,
                                          identifyingValueArg,
                                          otherFieldsArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "podio_item", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Alias for the `check_app_store_metadata` action

 - parameters:
   - apiKeyPath: Path to your App Store Connect API Key JSON file (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-json-file)
   - apiKey: Your App Store Connect API Key information (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-hash-option)
   - appIdentifier: The bundle identifier of your app
   - username: Your Apple ID Username
   - teamId: The ID of your App Store Connect team if you're in multiple teams
   - teamName: The name of your App Store Connect team if you're in multiple teams
   - platform: The platform to use (optional)
   - defaultRuleLevel: The default rule level unless otherwise configured
   - includeInAppPurchases: Should check in-app purchases?
   - useLive: Should force check live app?
   - freeStuffInIap: using text indicating that your IAP is free

 - returns: true if precheck passes, else, false

 More information: https://fastlane.tools/precheck
 */
@discardableResult public func precheck(apiKeyPath: OptionalConfigValue<String?> = .fastlaneDefault(precheckfile.apiKeyPath),
                                        apiKey: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(precheckfile.apiKey),
                                        appIdentifier: String = precheckfile.appIdentifier,
                                        username: OptionalConfigValue<String?> = .fastlaneDefault(precheckfile.username),
                                        teamId: OptionalConfigValue<String?> = .fastlaneDefault(precheckfile.teamId),
                                        teamName: OptionalConfigValue<String?> = .fastlaneDefault(precheckfile.teamName),
                                        platform: String = precheckfile.platform,
                                        defaultRuleLevel: Any = precheckfile.defaultRuleLevel,
                                        includeInAppPurchases: OptionalConfigValue<Bool> = .fastlaneDefault(precheckfile.includeInAppPurchases),
                                        useLive: OptionalConfigValue<Bool> = .fastlaneDefault(precheckfile.useLive),
                                        freeStuffInIap: Any? = precheckfile.freeStuffInIap) -> Bool
{
    let apiKeyPathArg = apiKeyPath.asRubyArgument(name: "api_key_path", type: nil)
    let apiKeyArg = apiKey.asRubyArgument(name: "api_key", type: nil)
    let appIdentifierArg = RubyCommand.Argument(name: "app_identifier", value: appIdentifier, type: nil)
    let usernameArg = username.asRubyArgument(name: "username", type: nil)
    let teamIdArg = teamId.asRubyArgument(name: "team_id", type: nil)
    let teamNameArg = teamName.asRubyArgument(name: "team_name", type: nil)
    let platformArg = RubyCommand.Argument(name: "platform", value: platform, type: nil)
    let defaultRuleLevelArg = RubyCommand.Argument(name: "default_rule_level", value: defaultRuleLevel, type: nil)
    let includeInAppPurchasesArg = includeInAppPurchases.asRubyArgument(name: "include_in_app_purchases", type: nil)
    let useLiveArg = useLive.asRubyArgument(name: "use_live", type: nil)
    let freeStuffInIapArg = RubyCommand.Argument(name: "free_stuff_in_iap", value: freeStuffInIap, type: nil)
    let array: [RubyCommand.Argument?] = [apiKeyPathArg,
                                          apiKeyArg,
                                          appIdentifierArg,
                                          usernameArg,
                                          teamIdArg,
                                          teamNameArg,
                                          platformArg,
                                          defaultRuleLevelArg,
                                          includeInAppPurchasesArg,
                                          useLiveArg,
                                          freeStuffInIapArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "precheck", className: nil, args: args)
    return parseBool(fromString: runner.executeCommand(command))
}

/**
 Alias for the `puts` action

 - parameter message: Message to be printed out
 */
public func println(message: OptionalConfigValue<String?> = .fastlaneDefault(nil)) {
    let messageArg = message.asRubyArgument(name: "message", type: nil)
    let array: [RubyCommand.Argument?] = [messageArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "println", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Alias for the `create_app_online` action

 - parameters:
   - username: Your Apple ID Username
   - appIdentifier: App Identifier (Bundle ID, e.g. com.krausefx.app)
   - bundleIdentifierSuffix: App Identifier Suffix (Ignored if App Identifier does not end with .*)
   - appName: App Name
   - appVersion: Initial version number (e.g. '1.0')
   - sku: SKU Number (e.g. '1234')
   - platform: The platform to use (optional)
   - platforms: The platforms to use (optional)
   - language: Primary Language (e.g. 'en-US', 'fr-FR')
   - companyName: The name of your company. It's used to set company name on App Store Connect team's app pages. Only required if it's the first app you create
   - skipItc: Skip the creation of the app on App Store Connect
   - itcUsers: Array of App Store Connect users. If provided, you can limit access to this newly created app for users with the App Manager, Developer, Marketer or Sales roles
   - enabledFeatures: **DEPRECATED!** Please use `enable_services` instead - Array with Spaceship App Services
   - enableServices: Array with Spaceship App Services (e.g. access_wifi: (on|off), app_attest: (on|off), app_group: (on|off), apple_pay: (on|off), associated_domains: (on|off), auto_fill_credential: (on|off), class_kit: (on|off), icloud: (legacy|cloudkit), custom_network_protocol: (on|off), data_protection: (complete|unlessopen|untilfirstauth), extended_virtual_address_space: (on|off), family_controls: (on|off), file_provider_testing_mode: (on|off), fonts: (on|off), game_center: (ios|mac), health_kit: (on|off), hls_interstitial_preview: (on|off), home_kit: (on|off), hotspot: (on|off), in_app_purchase: (on|off), inter_app_audio: (on|off), low_latency_hls: (on|off), managed_associated_domains: (on|off), maps: (on|off), multipath: (on|off), network_extension: (on|off), nfc_tag_reading: (on|off), personal_vpn: (on|off), passbook: (on|off), push_notification: (on|off), sign_in_with_apple: (on), siri_kit: (on|off), system_extension: (on|off), user_management: (on|off), vpn_configuration: (on|off), wallet: (on|off), wireless_accessory: (on|off), car_play_audio_app: (on|off), car_play_messaging_app: (on|off), car_play_navigation_app: (on|off), car_play_voip_calling_app: (on|off), critical_alerts: (on|off), hotspot_helper: (on|off), driver_kit: (on|off), driver_kit_endpoint_security: (on|off), driver_kit_family_hid_device: (on|off), driver_kit_family_networking: (on|off), driver_kit_family_serial: (on|off), driver_kit_hid_event_service: (on|off), driver_kit_transport_hid: (on|off), multitasking_camera_access: (on|off), sf_universal_link_api: (on|off), vp9_decoder: (on|off), music_kit: (on|off), shazam_kit: (on|off), communication_notifications: (on|off), group_activities: (on|off), health_kit_estimate_recalibration: (on|off), time_sensitive_notifications: (on|off))
   - skipDevcenter: Skip the creation of the app on the Apple Developer Portal
   - teamId: The ID of your Developer Portal team if you're in multiple teams
   - teamName: The name of your Developer Portal team if you're in multiple teams
   - itcTeamId: The ID of your App Store Connect team if you're in multiple teams
   - itcTeamName: The name of your App Store Connect team if you're in multiple teams

 Create new apps on App Store Connect and Apple Developer Portal via _produce_.
 If the app already exists, `create_app_online` will not do anything.
 For more information about _produce_, visit its documentation page: [https://docs.fastlane.tools/actions/produce/](https://docs.fastlane.tools/actions/produce/).
 */
public func produce(username: String,
                    appIdentifier: String,
                    bundleIdentifierSuffix: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                    appName: String,
                    appVersion: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                    sku: String,
                    platform: String = "ios",
                    platforms: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                    language: String = "English",
                    companyName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                    skipItc: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                    itcUsers: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                    enabledFeatures: [String: Any] = [:],
                    enableServices: [String: Any] = [:],
                    skipDevcenter: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                    teamId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                    teamName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                    itcTeamId: Any? = nil,
                    itcTeamName: OptionalConfigValue<String?> = .fastlaneDefault(nil))
{
    let usernameArg = RubyCommand.Argument(name: "username", value: username, type: nil)
    let appIdentifierArg = RubyCommand.Argument(name: "app_identifier", value: appIdentifier, type: nil)
    let bundleIdentifierSuffixArg = bundleIdentifierSuffix.asRubyArgument(name: "bundle_identifier_suffix", type: nil)
    let appNameArg = RubyCommand.Argument(name: "app_name", value: appName, type: nil)
    let appVersionArg = appVersion.asRubyArgument(name: "app_version", type: nil)
    let skuArg = RubyCommand.Argument(name: "sku", value: sku, type: nil)
    let platformArg = RubyCommand.Argument(name: "platform", value: platform, type: nil)
    let platformsArg = platforms.asRubyArgument(name: "platforms", type: nil)
    let languageArg = RubyCommand.Argument(name: "language", value: language, type: nil)
    let companyNameArg = companyName.asRubyArgument(name: "company_name", type: nil)
    let skipItcArg = skipItc.asRubyArgument(name: "skip_itc", type: nil)
    let itcUsersArg = itcUsers.asRubyArgument(name: "itc_users", type: nil)
    let enabledFeaturesArg = RubyCommand.Argument(name: "enabled_features", value: enabledFeatures, type: nil)
    let enableServicesArg = RubyCommand.Argument(name: "enable_services", value: enableServices, type: nil)
    let skipDevcenterArg = skipDevcenter.asRubyArgument(name: "skip_devcenter", type: nil)
    let teamIdArg = teamId.asRubyArgument(name: "team_id", type: nil)
    let teamNameArg = teamName.asRubyArgument(name: "team_name", type: nil)
    let itcTeamIdArg = RubyCommand.Argument(name: "itc_team_id", value: itcTeamId, type: nil)
    let itcTeamNameArg = itcTeamName.asRubyArgument(name: "itc_team_name", type: nil)
    let array: [RubyCommand.Argument?] = [usernameArg,
                                          appIdentifierArg,
                                          bundleIdentifierSuffixArg,
                                          appNameArg,
                                          appVersionArg,
                                          skuArg,
                                          platformArg,
                                          platformsArg,
                                          languageArg,
                                          companyNameArg,
                                          skipItcArg,
                                          itcUsersArg,
                                          enabledFeaturesArg,
                                          enableServicesArg,
                                          skipDevcenterArg,
                                          teamIdArg,
                                          teamNameArg,
                                          itcTeamIdArg,
                                          itcTeamNameArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "produce", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Ask the user for a value or for confirmation

 - parameters:
   - text: The text that will be displayed to the user
   - ciInput: The default text that will be used when being executed on a CI service
   - boolean: Is that a boolean question (yes/no)? This will add (y/n) at the end
   - secureText: Is that a secure text (yes/no)?
   - multiLineEndKeyword: Enable multi-line inputs by providing an end text (e.g. 'END') which will stop the user input

 You can use `prompt` to ask the user for a value or to just let the user confirm the next step.
 When this is executed on a CI service, the passed `ci_input` value will be returned.
 This action also supports multi-line inputs using the `multi_line_end_keyword` option.
 */
@discardableResult public func prompt(text: String = "Please enter some text: ",
                                      ciInput: String = "",
                                      boolean: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                      secureText: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                      multiLineEndKeyword: OptionalConfigValue<String?> = .fastlaneDefault(nil)) -> String
{
    let textArg = RubyCommand.Argument(name: "text", value: text, type: nil)
    let ciInputArg = RubyCommand.Argument(name: "ci_input", value: ciInput, type: nil)
    let booleanArg = boolean.asRubyArgument(name: "boolean", type: nil)
    let secureTextArg = secureText.asRubyArgument(name: "secure_text", type: nil)
    let multiLineEndKeywordArg = multiLineEndKeyword.asRubyArgument(name: "multi_line_end_keyword", type: nil)
    let array: [RubyCommand.Argument?] = [textArg,
                                          ciInputArg,
                                          booleanArg,
                                          secureTextArg,
                                          multiLineEndKeywordArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "prompt", className: nil, args: args)
    return runner.executeCommand(command)
}

/**
 Push local tags to the remote - this will only push tags

 - parameters:
   - force: Force push to remote
   - remote: The remote to push tags to
   - tag: The tag to push to remote

 If you only want to push the tags and nothing else, you can use the `push_git_tags` action
 */
public func pushGitTags(force: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                        remote: String = "origin",
                        tag: OptionalConfigValue<String?> = .fastlaneDefault(nil))
{
    let forceArg = force.asRubyArgument(name: "force", type: nil)
    let remoteArg = RubyCommand.Argument(name: "remote", value: remote, type: nil)
    let tagArg = tag.asRubyArgument(name: "tag", type: nil)
    let array: [RubyCommand.Argument?] = [forceArg,
                                          remoteArg,
                                          tagArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "push_git_tags", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Push local changes to the remote branch

 - parameters:
   - localBranch: The local branch to push from. Defaults to the current branch
   - remoteBranch: The remote branch to push to. Defaults to the local branch
   - force: Force push to remote
   - forceWithLease: Force push with lease to remote
   - tags: Whether tags are pushed to remote
   - remote: The remote to push to
   - noVerify: Whether or not to use --no-verify
   - setUpstream: Whether or not to use --set-upstream
   - pushOptions: Array of strings to be passed using the '--push-option' option

 Lets you push your local commits to a remote git repo. Useful if you make local changes such as adding a version bump commit (using `commit_version_bump`) or a git tag (using 'add_git_tag') on a CI server, and you want to push those changes back to your canonical/main repo.
 If this is a new branch, use the `set_upstream` option to set the remote branch as upstream.
 */
public func pushToGitRemote(localBranch: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            remoteBranch: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            force: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                            forceWithLease: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                            tags: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                            remote: String = "origin",
                            noVerify: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                            setUpstream: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                            pushOptions: [String] = [])
{
    let localBranchArg = localBranch.asRubyArgument(name: "local_branch", type: nil)
    let remoteBranchArg = remoteBranch.asRubyArgument(name: "remote_branch", type: nil)
    let forceArg = force.asRubyArgument(name: "force", type: nil)
    let forceWithLeaseArg = forceWithLease.asRubyArgument(name: "force_with_lease", type: nil)
    let tagsArg = tags.asRubyArgument(name: "tags", type: nil)
    let remoteArg = RubyCommand.Argument(name: "remote", value: remote, type: nil)
    let noVerifyArg = noVerify.asRubyArgument(name: "no_verify", type: nil)
    let setUpstreamArg = setUpstream.asRubyArgument(name: "set_upstream", type: nil)
    let pushOptionsArg = RubyCommand.Argument(name: "push_options", value: pushOptions, type: nil)
    let array: [RubyCommand.Argument?] = [localBranchArg,
                                          remoteBranchArg,
                                          forceArg,
                                          forceWithLeaseArg,
                                          tagsArg,
                                          remoteArg,
                                          noVerifyArg,
                                          setUpstreamArg,
                                          pushOptionsArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "push_to_git_remote", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Prints out the given text

 - parameter message: Message to be printed out
 */
public func puts(message: OptionalConfigValue<String?> = .fastlaneDefault(nil)) {
    let messageArg = message.asRubyArgument(name: "message", type: nil)
    let array: [RubyCommand.Argument?] = [messageArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "puts", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Loads a CocoaPods spec as JSON

 - parameter path: Path to the podspec to be read

 This can be used for only specifying a version string in your podspec - and during your release process you'd read it from the podspec by running `version = read_podspec['version']` at the beginning of your lane.
 Loads the specified (or the first found) podspec in the folder as JSON, so that you can inspect its `version`, `files` etc.
 This can be useful when basing your release process on the version string only stored in one place - in the podspec.
 As one of the first steps you'd read the podspec and its version and the rest of the workflow can use that version string (when e.g. creating a new git tag or a GitHub Release).
 */
@discardableResult public func readPodspec(path: String) -> [String: Any] {
    let pathArg = RubyCommand.Argument(name: "path", value: path, type: nil)
    let array: [RubyCommand.Argument?] = [pathArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "read_podspec", className: nil, args: args)
    return parseDictionary(fromString: runner.executeCommand(command))
}

/**
 Recreate not shared Xcode project schemes

 - parameter project: The Xcode project
 */
public func recreateSchemes(project: String) {
    let projectArg = RubyCommand.Argument(name: "project", value: project, type: nil)
    let array: [RubyCommand.Argument?] = [projectArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "recreate_schemes", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Registers a new device to the Apple Dev Portal

 - parameters:
   - name: Provide the name of the device to register as
   - platform: Provide the platform of the device to register as (ios, mac)
   - udid: Provide the UDID of the device to register as
   - apiKeyPath: Path to your App Store Connect API Key JSON file (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-json-file)
   - apiKey: Your App Store Connect API Key information (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-hash-option)
   - teamId: The ID of your Developer Portal team if you're in multiple teams
   - teamName: The name of your Developer Portal team if you're in multiple teams
   - username: Optional: Your Apple ID

 This will register an iOS device with the Developer Portal so that you can include it in your provisioning profiles.
 This is an optimistic action, in that it will only ever add a device to the member center. If the device has already been registered within the member center, it will be left alone in the member center.
 The action will connect to the Apple Developer Portal using the username you specified in your `Appfile` with `apple_id`, but you can override it using the `:username` option.
 */
@discardableResult public func registerDevice(name: String,
                                              platform: String = "ios",
                                              udid: String,
                                              apiKeyPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                              apiKey: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                                              teamId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                              teamName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                              username: OptionalConfigValue<String?> = .fastlaneDefault(nil)) -> String
{
    let nameArg = RubyCommand.Argument(name: "name", value: name, type: nil)
    let platformArg = RubyCommand.Argument(name: "platform", value: platform, type: nil)
    let udidArg = RubyCommand.Argument(name: "udid", value: udid, type: nil)
    let apiKeyPathArg = apiKeyPath.asRubyArgument(name: "api_key_path", type: nil)
    let apiKeyArg = apiKey.asRubyArgument(name: "api_key", type: nil)
    let teamIdArg = teamId.asRubyArgument(name: "team_id", type: nil)
    let teamNameArg = teamName.asRubyArgument(name: "team_name", type: nil)
    let usernameArg = username.asRubyArgument(name: "username", type: nil)
    let array: [RubyCommand.Argument?] = [nameArg,
                                          platformArg,
                                          udidArg,
                                          apiKeyPathArg,
                                          apiKeyArg,
                                          teamIdArg,
                                          teamNameArg,
                                          usernameArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "register_device", className: nil, args: args)
    return runner.executeCommand(command)
}

/**
 Registers new devices to the Apple Dev Portal

 - parameters:
   - devices: A hash of devices, with the name as key and the UDID as value
   - devicesFile: Provide a path to a file with the devices to register. For the format of the file see the examples
   - apiKeyPath: Path to your App Store Connect API Key JSON file (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-json-file)
   - apiKey: Your App Store Connect API Key information (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-hash-option)
   - teamId: The ID of your Developer Portal team if you're in multiple teams
   - teamName: The name of your Developer Portal team if you're in multiple teams
   - username: Optional: Your Apple ID
   - platform: The platform to use (optional)

 This will register iOS/Mac devices with the Developer Portal so that you can include them in your provisioning profiles.
 This is an optimistic action, in that it will only ever add new devices to the member center, and never remove devices. If a device which has already been registered within the member center is not passed to this action, it will be left alone in the member center and continue to work.
 The action will connect to the Apple Developer Portal using the username you specified in your `Appfile` with `apple_id`, but you can override it using the `username` option, or by setting the env variable `ENV['DELIVER_USER']`.
 */
public func registerDevices(devices: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                            devicesFile: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            apiKeyPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            apiKey: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                            teamId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            teamName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            username: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            platform: String = "ios")
{
    let devicesArg = devices.asRubyArgument(name: "devices", type: nil)
    let devicesFileArg = devicesFile.asRubyArgument(name: "devices_file", type: nil)
    let apiKeyPathArg = apiKeyPath.asRubyArgument(name: "api_key_path", type: nil)
    let apiKeyArg = apiKey.asRubyArgument(name: "api_key", type: nil)
    let teamIdArg = teamId.asRubyArgument(name: "team_id", type: nil)
    let teamNameArg = teamName.asRubyArgument(name: "team_name", type: nil)
    let usernameArg = username.asRubyArgument(name: "username", type: nil)
    let platformArg = RubyCommand.Argument(name: "platform", value: platform, type: nil)
    let array: [RubyCommand.Argument?] = [devicesArg,
                                          devicesFileArg,
                                          apiKeyPathArg,
                                          apiKeyArg,
                                          teamIdArg,
                                          teamNameArg,
                                          usernameArg,
                                          platformArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "register_devices", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Resets git repo to a clean state by discarding uncommitted changes

 - parameters:
   - files: Array of files the changes should be discarded. If not given, all files will be discarded
   - force: Skip verifying of previously clean state of repo. Only recommended in combination with `files` option
   - skipClean: Skip 'git clean' to avoid removing untracked files like `.env`
   - disregardGitignore: Setting this to true will clean the whole repository, ignoring anything in your local .gitignore. Set this to true if you want the equivalent of a fresh clone, and for all untracked and ignore files to also be removed
   - exclude: You can pass a string, or array of, file pattern(s) here which you want to have survive the cleaning process, and remain on disk, e.g. to leave the `artifacts` directory you would specify `exclude: 'artifacts'`. Make sure this pattern is also in your gitignore! See the gitignore documentation for info on patterns

 This action will reset your git repo to a clean state, discarding any uncommitted and untracked changes. Useful in case you need to revert the repo back to a clean state, e.g. after running _fastlane_.
 Untracked files like `.env` will also be deleted, unless `:skip_clean` is true.
 It's a pretty drastic action so it comes with a sort of safety latch. It will only proceed with the reset if this condition is met:|
 |
 >- You have called the `ensure_git_status_clean` action prior to calling this action. This ensures that your repo started off in a clean state, so the only things that will get destroyed by this action are files that are created as a byproduct of the fastlane run.|
 >|
 */
public func resetGitRepo(files: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                         force: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                         skipClean: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                         disregardGitignore: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                         exclude: OptionalConfigValue<String?> = .fastlaneDefault(nil))
{
    let filesArg = files.asRubyArgument(name: "files", type: nil)
    let forceArg = force.asRubyArgument(name: "force", type: nil)
    let skipCleanArg = skipClean.asRubyArgument(name: "skip_clean", type: nil)
    let disregardGitignoreArg = disregardGitignore.asRubyArgument(name: "disregard_gitignore", type: nil)
    let excludeArg = exclude.asRubyArgument(name: "exclude", type: nil)
    let array: [RubyCommand.Argument?] = [filesArg,
                                          forceArg,
                                          skipCleanArg,
                                          disregardGitignoreArg,
                                          excludeArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "reset_git_repo", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Shutdown and reset running simulators

 - parameters:
   - ios: **DEPRECATED!** Use `:os_versions` instead - Which OS versions of Simulators you want to reset content and settings, this does not remove/recreate the simulators
   - osVersions: Which OS versions of Simulators you want to reset content and settings, this does not remove/recreate the simulators
 */
public func resetSimulatorContents(ios: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                                   osVersions: OptionalConfigValue<[String]?> = .fastlaneDefault(nil))
{
    let iosArg = ios.asRubyArgument(name: "ios", type: nil)
    let osVersionsArg = osVersions.asRubyArgument(name: "os_versions", type: nil)
    let array: [RubyCommand.Argument?] = [iosArg,
                                          osVersionsArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "reset_simulator_contents", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Codesign an existing ipa file

 - parameters:
   - ipa: Path to the ipa file to resign. Optional if you use the _gym_ or _xcodebuild_ action
   - signingIdentity: Code signing identity to use. e.g. `iPhone Distribution: Luka Mirosevic (0123456789)`
   - entitlements: Path to the entitlement file to use, e.g. `myApp/MyApp.entitlements`
   - provisioningProfile: Path to your provisioning_profile. Optional if you use _sigh_
   - version: Version number to force resigned ipa to use. Updates both `CFBundleShortVersionString` and `CFBundleVersion` values in `Info.plist`. Applies for main app and all nested apps or extensions
   - displayName: Display name to force resigned ipa to use
   - shortVersion: Short version string to force resigned ipa to use (`CFBundleShortVersionString`)
   - bundleVersion: Bundle version to force resigned ipa to use (`CFBundleVersion`)
   - bundleId: Set new bundle ID during resign (`CFBundleIdentifier`)
   - useAppEntitlements: Extract app bundle codesigning entitlements and combine with entitlements from new provisioning profile
   - keychainPath: Provide a path to a keychain file that should be used by `/usr/bin/codesign`
 */
public func resign(ipa: String,
                   signingIdentity: String,
                   entitlements: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   provisioningProfile: String,
                   version: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   displayName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   shortVersion: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   bundleVersion: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   bundleId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   useAppEntitlements: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                   keychainPath: OptionalConfigValue<String?> = .fastlaneDefault(nil))
{
    let ipaArg = RubyCommand.Argument(name: "ipa", value: ipa, type: nil)
    let signingIdentityArg = RubyCommand.Argument(name: "signing_identity", value: signingIdentity, type: nil)
    let entitlementsArg = entitlements.asRubyArgument(name: "entitlements", type: nil)
    let provisioningProfileArg = RubyCommand.Argument(name: "provisioning_profile", value: provisioningProfile, type: nil)
    let versionArg = version.asRubyArgument(name: "version", type: nil)
    let displayNameArg = displayName.asRubyArgument(name: "display_name", type: nil)
    let shortVersionArg = shortVersion.asRubyArgument(name: "short_version", type: nil)
    let bundleVersionArg = bundleVersion.asRubyArgument(name: "bundle_version", type: nil)
    let bundleIdArg = bundleId.asRubyArgument(name: "bundle_id", type: nil)
    let useAppEntitlementsArg = useAppEntitlements.asRubyArgument(name: "use_app_entitlements", type: nil)
    let keychainPathArg = keychainPath.asRubyArgument(name: "keychain_path", type: nil)
    let array: [RubyCommand.Argument?] = [ipaArg,
                                          signingIdentityArg,
                                          entitlementsArg,
                                          provisioningProfileArg,
                                          versionArg,
                                          displayNameArg,
                                          shortVersionArg,
                                          bundleVersionArg,
                                          bundleIdArg,
                                          useAppEntitlementsArg,
                                          keychainPathArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "resign", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 This action restore your file that was backed up with the `backup_file` action

 - parameter path: Original file name you want to restore
 */
public func restoreFile(path: String) {
    let pathArg = RubyCommand.Argument(name: "path", value: path, type: nil)
    let array: [RubyCommand.Argument?] = [pathArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "restore_file", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Outputs ascii-art for a rocket 🚀

 Print an ascii Rocket :rocket:. Useful after using _crashlytics_ or _pilot_ to indicate that your new build has been shipped to outer-space.
 */
@discardableResult public func rocket() -> String {
    let args: [RubyCommand.Argument] = []
    let command = RubyCommand(commandID: "", methodName: "rocket", className: nil, args: args)
    return runner.executeCommand(command)
}

/**
 Run tests using rspec
 */
public func rspec() {
    let args: [RubyCommand.Argument] = []
    let command = RubyCommand(commandID: "", methodName: "rspec", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Rsync files from :source to :destination

 - parameters:
   - extra: Port
   - source: source file/folder
   - destination: destination file/folder

 A wrapper around `rsync`, which is a tool that lets you synchronize files, including permissions and so on. For a more detailed information about `rsync`, please see [rsync(1) man page](https://linux.die.net/man/1/rsync).
 */
public func rsync(extra: String = "-av",
                  source: String,
                  destination: String)
{
    let extraArg = RubyCommand.Argument(name: "extra", value: extra, type: nil)
    let sourceArg = RubyCommand.Argument(name: "source", value: source, type: nil)
    let destinationArg = RubyCommand.Argument(name: "destination", value: destination, type: nil)
    let array: [RubyCommand.Argument?] = [extraArg,
                                          sourceArg,
                                          destinationArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "rsync", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Runs the code style checks
 */
public func rubocop() {
    let args: [RubyCommand.Argument] = []
    let command = RubyCommand(commandID: "", methodName: "rubocop", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Verifies the minimum ruby version required

 Add this to your `Fastfile` to require a certain version of _ruby_.
 Put it at the top of your `Fastfile` to ensure that _fastlane_ is executed appropriately.
 */
public func rubyVersion() {
    let args: [RubyCommand.Argument] = []
    let command = RubyCommand(commandID: "", methodName: "ruby_version", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Easily run tests of your iOS app (via _scan_)

 - parameters:
   - workspace: Path to the workspace file
   - project: Path to the project file
   - packagePath: Path to the Swift Package
   - scheme: The project's scheme. Make sure it's marked as `Shared`
   - device: The name of the simulator type you want to run tests on (e.g. 'iPhone 6' or 'iPhone SE (2nd generation) (14.5)')
   - devices: Array of devices to run the tests on (e.g. ['iPhone 6', 'iPad Air', 'iPhone SE (2nd generation) (14.5)'])
   - skipDetectDevices: Should skip auto detecting of devices if none were specified
   - ensureDevicesFound: Should fail if devices not found
   - forceQuitSimulator: Enabling this option will automatically killall Simulator processes before the run
   - resetSimulator: Enabling this option will automatically erase the simulator before running the application
   - disableSlideToType: Enabling this option will disable the simulator from showing the 'Slide to type' prompt
   - prelaunchSimulator: Enabling this option will launch the first simulator prior to calling any xcodebuild command
   - reinstallApp: Enabling this option will automatically uninstall the application before running it
   - appIdentifier: The bundle identifier of the app to uninstall (only needed when enabling reinstall_app)
   - onlyTesting: Array of strings matching Test Bundle/Test Suite/Test Cases to run
   - skipTesting: Array of strings matching Test Bundle/Test Suite/Test Cases to skip
   - testplan: The testplan associated with the scheme that should be used for testing
   - onlyTestConfigurations: Array of strings matching test plan configurations to run
   - skipTestConfigurations: Array of strings matching test plan configurations to skip
   - xctestrun: Run tests using the provided `.xctestrun` file
   - toolchain: The toolchain that should be used for building the application (e.g. `com.apple.dt.toolchain.Swift_2_3, org.swift.30p620160816a`)
   - clean: Should the project be cleaned before building it?
   - codeCoverage: Should code coverage be generated? (Xcode 7 and up)
   - addressSanitizer: Should the address sanitizer be turned on?
   - threadSanitizer: Should the thread sanitizer be turned on?
   - openReport: Should the HTML report be opened when tests are completed?
   - outputDirectory: The directory in which all reports will be stored
   - outputStyle: Define how the output should look like. Valid values are: standard, basic, rspec, or raw (disables xcpretty during xcodebuild)
   - outputTypes: Comma separated list of the output types (e.g. html, junit, json-compilation-database)
   - outputFiles: Comma separated list of the output files, corresponding to the types provided by :output_types (order should match). If specifying an output type of json-compilation-database with :use_clang_report_name enabled, that option will take precedence
   - buildlogPath: The directory where to store the raw log
   - includeSimulatorLogs: If the logs generated by the app (e.g. using NSLog, perror, etc.) in the Simulator should be written to the output_directory
   - suppressXcodeOutput: Suppress the output of xcodebuild to stdout. Output is still saved in buildlog_path
   - xcodebuildFormatter: xcodebuild formatter to use (ex: 'xcbeautify', 'xcbeautify --quieter', 'xcpretty', 'xcpretty -test'). Use empty string (ex: '') to disable any formatter (More information: https://docs.fastlane.tools/best-practices/xcodebuild-formatters/)
   - outputRemoveRetryAttempts: Remove retry attempts from test results table and the JUnit report (if not using xcpretty)
   - disableXcpretty: **DEPRECATED!** Use `output_style: 'raw'` instead - Disable xcpretty formatting of build, similar to `output_style='raw'` but this will also skip the test results table
   - formatter: **DEPRECATED!** Use 'xcpretty_formatter' instead - A custom xcpretty formatter to use
   - xcprettyFormatter: A custom xcpretty formatter to use
   - xcprettyArgs: Pass in xcpretty additional command line arguments (e.g. '--test --no-color' or '--tap --no-utf')
   - derivedDataPath: The directory where build products and other derived data will go
   - shouldZipBuildProducts: Should zip the derived data build products and place in output path?
   - outputXctestrun: Should provide additional copy of .xctestrun file (settings.xctestrun) and place in output path?
   - resultBundlePath: Custom path for the result bundle, overrides result_bundle
   - resultBundle: Should an Xcode result bundle be generated in the output directory
   - useClangReportName: Generate the json compilation database with clang naming convention (compile_commands.json)
   - parallelTesting: Optionally override the per-target setting in the scheme for running tests in parallel. Equivalent to -parallel-testing-enabled
   - concurrentWorkers: Specify the exact number of test runners that will be spawned during parallel testing. Equivalent to -parallel-testing-worker-count
   - maxConcurrentSimulators: Constrain the number of simulator devices on which to test concurrently. Equivalent to -maximum-concurrent-test-simulator-destinations
   - disableConcurrentTesting: Do not run test bundles in parallel on the specified destinations. Testing will occur on each destination serially. Equivalent to -disable-concurrent-testing
   - skipBuild: Should debug build be skipped before test build?
   - testWithoutBuilding: Test without building, requires a derived data path
   - buildForTesting: Build for testing only, does not run tests
   - sdk: The SDK that should be used for building the application
   - configuration: The configuration to use when building the app. Defaults to 'Release'
   - xcargs: Pass additional arguments to xcodebuild. Be sure to quote the setting names and values e.g. OTHER_LDFLAGS="-ObjC -lstdc++"
   - xcconfig: Use an extra XCCONFIG file to build your app
   - appName: App name to use in slack message and logfile name
   - deploymentTargetVersion: Target version of the app being build or tested. Used to filter out simulator version
   - slackUrl: Create an Incoming WebHook for your Slack group to post results there
   - slackChannel: #channel or @username
   - slackMessage: The message included with each message posted to slack
   - slackUseWebhookConfiguredUsernameAndIcon: Use webhook's default username and icon settings? (true/false)
   - slackUsername: Overrides the webhook's username property if slack_use_webhook_configured_username_and_icon is false
   - slackIconUrl: Overrides the webhook's image property if slack_use_webhook_configured_username_and_icon is false
   - skipSlack: Don't publish to slack, even when an URL is given
   - slackOnlyOnFailure: Only post on Slack if the tests fail
   - slackDefaultPayloads: Specifies default payloads to include in Slack messages. For more info visit https://docs.fastlane.tools/actions/slack
   - destination: Use only if you're a pro, use the other options instead
   - runRosettaSimulator: Adds arch=x86_64 to the xcodebuild 'destination' argument to run simulator in a Rosetta mode
   - catalystPlatform: Platform to build when using a Catalyst enabled app. Valid values are: ios, macos
   - customReportFileName: **DEPRECATED!** Use `--output_files` instead - Sets custom full report file name when generating a single report
   - xcodebuildCommand: Allows for override of the default `xcodebuild` command
   - clonedSourcePackagesPath: Sets a custom path for Swift Package Manager dependencies
   - skipPackageDependenciesResolution: Skips resolution of Swift Package Manager dependencies
   - disablePackageAutomaticUpdates: Prevents packages from automatically being resolved to versions other than those recorded in the `Package.resolved` file
   - useSystemScm: Lets xcodebuild use system's scm configuration
   - numberOfRetries: The number of times a test can fail
   - failBuild: Should this step stop the build if the tests fail? Set this to false if you're using trainer
   - packageAuthorizationProvider: Lets xcodebuild use a specified package authorization provider (keychain|netrc)

 - returns: Outputs hash of results with the following keys: :number_of_tests, :number_of_failures, :number_of_retries, :number_of_tests_excluding_retries, :number_of_failures_excluding_retries

 More information: https://docs.fastlane.tools/actions/scan/
 */
@discardableResult public func runTests(workspace: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        project: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        packagePath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        scheme: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        device: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        devices: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                                        skipDetectDevices: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                        ensureDevicesFound: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                        forceQuitSimulator: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                        resetSimulator: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                        disableSlideToType: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                                        prelaunchSimulator: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                        reinstallApp: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                        appIdentifier: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        onlyTesting: Any? = nil,
                                        skipTesting: Any? = nil,
                                        testplan: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        onlyTestConfigurations: Any? = nil,
                                        skipTestConfigurations: Any? = nil,
                                        xctestrun: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        toolchain: Any? = nil,
                                        clean: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                        codeCoverage: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                        addressSanitizer: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                        threadSanitizer: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                        openReport: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                        outputDirectory: String = "./test_output",
                                        outputStyle: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        outputTypes: String = "html,junit",
                                        outputFiles: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        buildlogPath: String = "~/Library/Logs/scan",
                                        includeSimulatorLogs: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                        suppressXcodeOutput: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                        xcodebuildFormatter: String = "xcbeautify",
                                        outputRemoveRetryAttempts: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                        disableXcpretty: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                        formatter: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        xcprettyFormatter: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        xcprettyArgs: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        derivedDataPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        shouldZipBuildProducts: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                        outputXctestrun: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                        resultBundlePath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        resultBundle: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                        useClangReportName: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                        parallelTesting: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                        concurrentWorkers: OptionalConfigValue<Int?> = .fastlaneDefault(nil),
                                        maxConcurrentSimulators: OptionalConfigValue<Int?> = .fastlaneDefault(nil),
                                        disableConcurrentTesting: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                        skipBuild: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                        testWithoutBuilding: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                        buildForTesting: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                                        sdk: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        configuration: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        xcargs: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        xcconfig: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        appName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        deploymentTargetVersion: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        slackUrl: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        slackChannel: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        slackMessage: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        slackUseWebhookConfiguredUsernameAndIcon: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                        slackUsername: String = "fastlane",
                                        slackIconUrl: String = "https://fastlane.tools/assets/img/fastlane_icon.png",
                                        skipSlack: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                        slackOnlyOnFailure: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                        slackDefaultPayloads: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                                        destination: Any? = nil,
                                        runRosettaSimulator: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                        catalystPlatform: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        customReportFileName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        xcodebuildCommand: String = "env NSUnbufferedIO=YES xcodebuild",
                                        clonedSourcePackagesPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                        skipPackageDependenciesResolution: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                        disablePackageAutomaticUpdates: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                        useSystemScm: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                        numberOfRetries: Int = 0,
                                        failBuild: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                                        packageAuthorizationProvider: OptionalConfigValue<String?> = .fastlaneDefault(nil)) -> [String: Any]
{
    let workspaceArg = workspace.asRubyArgument(name: "workspace", type: nil)
    let projectArg = project.asRubyArgument(name: "project", type: nil)
    let packagePathArg = packagePath.asRubyArgument(name: "package_path", type: nil)
    let schemeArg = scheme.asRubyArgument(name: "scheme", type: nil)
    let deviceArg = device.asRubyArgument(name: "device", type: nil)
    let devicesArg = devices.asRubyArgument(name: "devices", type: nil)
    let skipDetectDevicesArg = skipDetectDevices.asRubyArgument(name: "skip_detect_devices", type: nil)
    let ensureDevicesFoundArg = ensureDevicesFound.asRubyArgument(name: "ensure_devices_found", type: nil)
    let forceQuitSimulatorArg = forceQuitSimulator.asRubyArgument(name: "force_quit_simulator", type: nil)
    let resetSimulatorArg = resetSimulator.asRubyArgument(name: "reset_simulator", type: nil)
    let disableSlideToTypeArg = disableSlideToType.asRubyArgument(name: "disable_slide_to_type", type: nil)
    let prelaunchSimulatorArg = prelaunchSimulator.asRubyArgument(name: "prelaunch_simulator", type: nil)
    let reinstallAppArg = reinstallApp.asRubyArgument(name: "reinstall_app", type: nil)
    let appIdentifierArg = appIdentifier.asRubyArgument(name: "app_identifier", type: nil)
    let onlyTestingArg = RubyCommand.Argument(name: "only_testing", value: onlyTesting, type: nil)
    let skipTestingArg = RubyCommand.Argument(name: "skip_testing", value: skipTesting, type: nil)
    let testplanArg = testplan.asRubyArgument(name: "testplan", type: nil)
    let onlyTestConfigurationsArg = RubyCommand.Argument(name: "only_test_configurations", value: onlyTestConfigurations, type: nil)
    let skipTestConfigurationsArg = RubyCommand.Argument(name: "skip_test_configurations", value: skipTestConfigurations, type: nil)
    let xctestrunArg = xctestrun.asRubyArgument(name: "xctestrun", type: nil)
    let toolchainArg = RubyCommand.Argument(name: "toolchain", value: toolchain, type: nil)
    let cleanArg = clean.asRubyArgument(name: "clean", type: nil)
    let codeCoverageArg = codeCoverage.asRubyArgument(name: "code_coverage", type: nil)
    let addressSanitizerArg = addressSanitizer.asRubyArgument(name: "address_sanitizer", type: nil)
    let threadSanitizerArg = threadSanitizer.asRubyArgument(name: "thread_sanitizer", type: nil)
    let openReportArg = openReport.asRubyArgument(name: "open_report", type: nil)
    let outputDirectoryArg = RubyCommand.Argument(name: "output_directory", value: outputDirectory, type: nil)
    let outputStyleArg = outputStyle.asRubyArgument(name: "output_style", type: nil)
    let outputTypesArg = RubyCommand.Argument(name: "output_types", value: outputTypes, type: nil)
    let outputFilesArg = outputFiles.asRubyArgument(name: "output_files", type: nil)
    let buildlogPathArg = RubyCommand.Argument(name: "buildlog_path", value: buildlogPath, type: nil)
    let includeSimulatorLogsArg = includeSimulatorLogs.asRubyArgument(name: "include_simulator_logs", type: nil)
    let suppressXcodeOutputArg = suppressXcodeOutput.asRubyArgument(name: "suppress_xcode_output", type: nil)
    let xcodebuildFormatterArg = RubyCommand.Argument(name: "xcodebuild_formatter", value: xcodebuildFormatter, type: nil)
    let outputRemoveRetryAttemptsArg = outputRemoveRetryAttempts.asRubyArgument(name: "output_remove_retry_attempts", type: nil)
    let disableXcprettyArg = disableXcpretty.asRubyArgument(name: "disable_xcpretty", type: nil)
    let formatterArg = formatter.asRubyArgument(name: "formatter", type: nil)
    let xcprettyFormatterArg = xcprettyFormatter.asRubyArgument(name: "xcpretty_formatter", type: nil)
    let xcprettyArgsArg = xcprettyArgs.asRubyArgument(name: "xcpretty_args", type: nil)
    let derivedDataPathArg = derivedDataPath.asRubyArgument(name: "derived_data_path", type: nil)
    let shouldZipBuildProductsArg = shouldZipBuildProducts.asRubyArgument(name: "should_zip_build_products", type: nil)
    let outputXctestrunArg = outputXctestrun.asRubyArgument(name: "output_xctestrun", type: nil)
    let resultBundlePathArg = resultBundlePath.asRubyArgument(name: "result_bundle_path", type: nil)
    let resultBundleArg = resultBundle.asRubyArgument(name: "result_bundle", type: nil)
    let useClangReportNameArg = useClangReportName.asRubyArgument(name: "use_clang_report_name", type: nil)
    let parallelTestingArg = parallelTesting.asRubyArgument(name: "parallel_testing", type: nil)
    let concurrentWorkersArg = concurrentWorkers.asRubyArgument(name: "concurrent_workers", type: nil)
    let maxConcurrentSimulatorsArg = maxConcurrentSimulators.asRubyArgument(name: "max_concurrent_simulators", type: nil)
    let disableConcurrentTestingArg = disableConcurrentTesting.asRubyArgument(name: "disable_concurrent_testing", type: nil)
    let skipBuildArg = skipBuild.asRubyArgument(name: "skip_build", type: nil)
    let testWithoutBuildingArg = testWithoutBuilding.asRubyArgument(name: "test_without_building", type: nil)
    let buildForTestingArg = buildForTesting.asRubyArgument(name: "build_for_testing", type: nil)
    let sdkArg = sdk.asRubyArgument(name: "sdk", type: nil)
    let configurationArg = configuration.asRubyArgument(name: "configuration", type: nil)
    let xcargsArg = xcargs.asRubyArgument(name: "xcargs", type: nil)
    let xcconfigArg = xcconfig.asRubyArgument(name: "xcconfig", type: nil)
    let appNameArg = appName.asRubyArgument(name: "app_name", type: nil)
    let deploymentTargetVersionArg = deploymentTargetVersion.asRubyArgument(name: "deployment_target_version", type: nil)
    let slackUrlArg = slackUrl.asRubyArgument(name: "slack_url", type: nil)
    let slackChannelArg = slackChannel.asRubyArgument(name: "slack_channel", type: nil)
    let slackMessageArg = slackMessage.asRubyArgument(name: "slack_message", type: nil)
    let slackUseWebhookConfiguredUsernameAndIconArg = slackUseWebhookConfiguredUsernameAndIcon.asRubyArgument(name: "slack_use_webhook_configured_username_and_icon", type: nil)
    let slackUsernameArg = RubyCommand.Argument(name: "slack_username", value: slackUsername, type: nil)
    let slackIconUrlArg = RubyCommand.Argument(name: "slack_icon_url", value: slackIconUrl, type: nil)
    let skipSlackArg = skipSlack.asRubyArgument(name: "skip_slack", type: nil)
    let slackOnlyOnFailureArg = slackOnlyOnFailure.asRubyArgument(name: "slack_only_on_failure", type: nil)
    let slackDefaultPayloadsArg = slackDefaultPayloads.asRubyArgument(name: "slack_default_payloads", type: nil)
    let destinationArg = RubyCommand.Argument(name: "destination", value: destination, type: nil)
    let runRosettaSimulatorArg = runRosettaSimulator.asRubyArgument(name: "run_rosetta_simulator", type: nil)
    let catalystPlatformArg = catalystPlatform.asRubyArgument(name: "catalyst_platform", type: nil)
    let customReportFileNameArg = customReportFileName.asRubyArgument(name: "custom_report_file_name", type: nil)
    let xcodebuildCommandArg = RubyCommand.Argument(name: "xcodebuild_command", value: xcodebuildCommand, type: nil)
    let clonedSourcePackagesPathArg = clonedSourcePackagesPath.asRubyArgument(name: "cloned_source_packages_path", type: nil)
    let skipPackageDependenciesResolutionArg = skipPackageDependenciesResolution.asRubyArgument(name: "skip_package_dependencies_resolution", type: nil)
    let disablePackageAutomaticUpdatesArg = disablePackageAutomaticUpdates.asRubyArgument(name: "disable_package_automatic_updates", type: nil)
    let useSystemScmArg = useSystemScm.asRubyArgument(name: "use_system_scm", type: nil)
    let numberOfRetriesArg = RubyCommand.Argument(name: "number_of_retries", value: numberOfRetries, type: nil)
    let failBuildArg = failBuild.asRubyArgument(name: "fail_build", type: nil)
    let packageAuthorizationProviderArg = packageAuthorizationProvider.asRubyArgument(name: "package_authorization_provider", type: nil)
    let array: [RubyCommand.Argument?] = [workspaceArg,
                                          projectArg,
                                          packagePathArg,
                                          schemeArg,
                                          deviceArg,
                                          devicesArg,
                                          skipDetectDevicesArg,
                                          ensureDevicesFoundArg,
                                          forceQuitSimulatorArg,
                                          resetSimulatorArg,
                                          disableSlideToTypeArg,
                                          prelaunchSimulatorArg,
                                          reinstallAppArg,
                                          appIdentifierArg,
                                          onlyTestingArg,
                                          skipTestingArg,
                                          testplanArg,
                                          onlyTestConfigurationsArg,
                                          skipTestConfigurationsArg,
                                          xctestrunArg,
                                          toolchainArg,
                                          cleanArg,
                                          codeCoverageArg,
                                          addressSanitizerArg,
                                          threadSanitizerArg,
                                          openReportArg,
                                          outputDirectoryArg,
                                          outputStyleArg,
                                          outputTypesArg,
                                          outputFilesArg,
                                          buildlogPathArg,
                                          includeSimulatorLogsArg,
                                          suppressXcodeOutputArg,
                                          xcodebuildFormatterArg,
                                          outputRemoveRetryAttemptsArg,
                                          disableXcprettyArg,
                                          formatterArg,
                                          xcprettyFormatterArg,
                                          xcprettyArgsArg,
                                          derivedDataPathArg,
                                          shouldZipBuildProductsArg,
                                          outputXctestrunArg,
                                          resultBundlePathArg,
                                          resultBundleArg,
                                          useClangReportNameArg,
                                          parallelTestingArg,
                                          concurrentWorkersArg,
                                          maxConcurrentSimulatorsArg,
                                          disableConcurrentTestingArg,
                                          skipBuildArg,
                                          testWithoutBuildingArg,
                                          buildForTestingArg,
                                          sdkArg,
                                          configurationArg,
                                          xcargsArg,
                                          xcconfigArg,
                                          appNameArg,
                                          deploymentTargetVersionArg,
                                          slackUrlArg,
                                          slackChannelArg,
                                          slackMessageArg,
                                          slackUseWebhookConfiguredUsernameAndIconArg,
                                          slackUsernameArg,
                                          slackIconUrlArg,
                                          skipSlackArg,
                                          slackOnlyOnFailureArg,
                                          slackDefaultPayloadsArg,
                                          destinationArg,
                                          runRosettaSimulatorArg,
                                          catalystPlatformArg,
                                          customReportFileNameArg,
                                          xcodebuildCommandArg,
                                          clonedSourcePackagesPathArg,
                                          skipPackageDependenciesResolutionArg,
                                          disablePackageAutomaticUpdatesArg,
                                          useSystemScmArg,
                                          numberOfRetriesArg,
                                          failBuildArg,
                                          packageAuthorizationProviderArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "run_tests", className: nil, args: args)
    return parseDictionary(fromString: runner.executeCommand(command))
}

/**
 Generates a plist file and uploads all to AWS S3

 - parameters:
   - ipa: .ipa file for the build
   - dsym: zipped .dsym package for the build
   - uploadMetadata: Upload relevant metadata for this build
   - plistTemplatePath: plist template path
   - plistFileName: uploaded plist filename
   - htmlTemplatePath: html erb template path
   - htmlFileName: uploaded html filename
   - versionTemplatePath: version erb template path
   - versionFileName: uploaded version filename
   - accessKey: AWS Access Key ID
   - secretAccessKey: AWS Secret Access Key
   - bucket: AWS bucket name
   - region: AWS region (for bucket creation)
   - path: S3 'path'. Values from Info.plist will be substituted for keys wrapped in {}
   - source: Optional source directory e.g. ./build
   - acl: Uploaded object permissions e.g public_read (default), private, public_read_write, authenticated_read

 Upload a new build to Amazon S3 to distribute the build to beta testers.
 Works for both Ad Hoc and Enterprise signed applications. This step will generate the necessary HTML, plist, and version files for you.
 It is recommended to **not** store the AWS access keys in the `Fastfile`. The uploaded `version.json` file provides an easy way for apps to poll if a new update is available.
 */
public func s3(ipa: OptionalConfigValue<String?> = .fastlaneDefault(nil),
               dsym: OptionalConfigValue<String?> = .fastlaneDefault(nil),
               uploadMetadata: OptionalConfigValue<Bool> = .fastlaneDefault(true),
               plistTemplatePath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
               plistFileName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
               htmlTemplatePath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
               htmlFileName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
               versionTemplatePath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
               versionFileName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
               accessKey: OptionalConfigValue<String?> = .fastlaneDefault(nil),
               secretAccessKey: OptionalConfigValue<String?> = .fastlaneDefault(nil),
               bucket: OptionalConfigValue<String?> = .fastlaneDefault(nil),
               region: OptionalConfigValue<String?> = .fastlaneDefault(nil),
               path: String = "v{CFBundleShortVersionString}_b{CFBundleVersion}/",
               source: OptionalConfigValue<String?> = .fastlaneDefault(nil),
               acl: String = "public_read")
{
    let ipaArg = ipa.asRubyArgument(name: "ipa", type: nil)
    let dsymArg = dsym.asRubyArgument(name: "dsym", type: nil)
    let uploadMetadataArg = uploadMetadata.asRubyArgument(name: "upload_metadata", type: nil)
    let plistTemplatePathArg = plistTemplatePath.asRubyArgument(name: "plist_template_path", type: nil)
    let plistFileNameArg = plistFileName.asRubyArgument(name: "plist_file_name", type: nil)
    let htmlTemplatePathArg = htmlTemplatePath.asRubyArgument(name: "html_template_path", type: nil)
    let htmlFileNameArg = htmlFileName.asRubyArgument(name: "html_file_name", type: nil)
    let versionTemplatePathArg = versionTemplatePath.asRubyArgument(name: "version_template_path", type: nil)
    let versionFileNameArg = versionFileName.asRubyArgument(name: "version_file_name", type: nil)
    let accessKeyArg = accessKey.asRubyArgument(name: "access_key", type: nil)
    let secretAccessKeyArg = secretAccessKey.asRubyArgument(name: "secret_access_key", type: nil)
    let bucketArg = bucket.asRubyArgument(name: "bucket", type: nil)
    let regionArg = region.asRubyArgument(name: "region", type: nil)
    let pathArg = RubyCommand.Argument(name: "path", value: path, type: nil)
    let sourceArg = source.asRubyArgument(name: "source", type: nil)
    let aclArg = RubyCommand.Argument(name: "acl", value: acl, type: nil)
    let array: [RubyCommand.Argument?] = [ipaArg,
                                          dsymArg,
                                          uploadMetadataArg,
                                          plistTemplatePathArg,
                                          plistFileNameArg,
                                          htmlTemplatePathArg,
                                          htmlFileNameArg,
                                          versionTemplatePathArg,
                                          versionFileNameArg,
                                          accessKeyArg,
                                          secretAccessKeyArg,
                                          bucketArg,
                                          regionArg,
                                          pathArg,
                                          sourceArg,
                                          aclArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "s3", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 This action speaks the given text out loud

 - parameters:
   - text: Text to be spoken out loud (as string or array of strings)
   - mute: If say should be muted with text printed out
 */
public func say(text: [String],
                mute: OptionalConfigValue<Bool> = .fastlaneDefault(false))
{
    let textArg = RubyCommand.Argument(name: "text", value: text, type: nil)
    let muteArg = mute.asRubyArgument(name: "mute", type: nil)
    let array: [RubyCommand.Argument?] = [textArg,
                                          muteArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "say", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Alias for the `run_tests` action

 - parameters:
   - workspace: Path to the workspace file
   - project: Path to the project file
   - packagePath: Path to the Swift Package
   - scheme: The project's scheme. Make sure it's marked as `Shared`
   - device: The name of the simulator type you want to run tests on (e.g. 'iPhone 6' or 'iPhone SE (2nd generation) (14.5)')
   - devices: Array of devices to run the tests on (e.g. ['iPhone 6', 'iPad Air', 'iPhone SE (2nd generation) (14.5)'])
   - skipDetectDevices: Should skip auto detecting of devices if none were specified
   - ensureDevicesFound: Should fail if devices not found
   - forceQuitSimulator: Enabling this option will automatically killall Simulator processes before the run
   - resetSimulator: Enabling this option will automatically erase the simulator before running the application
   - disableSlideToType: Enabling this option will disable the simulator from showing the 'Slide to type' prompt
   - prelaunchSimulator: Enabling this option will launch the first simulator prior to calling any xcodebuild command
   - reinstallApp: Enabling this option will automatically uninstall the application before running it
   - appIdentifier: The bundle identifier of the app to uninstall (only needed when enabling reinstall_app)
   - onlyTesting: Array of strings matching Test Bundle/Test Suite/Test Cases to run
   - skipTesting: Array of strings matching Test Bundle/Test Suite/Test Cases to skip
   - testplan: The testplan associated with the scheme that should be used for testing
   - onlyTestConfigurations: Array of strings matching test plan configurations to run
   - skipTestConfigurations: Array of strings matching test plan configurations to skip
   - xctestrun: Run tests using the provided `.xctestrun` file
   - toolchain: The toolchain that should be used for building the application (e.g. `com.apple.dt.toolchain.Swift_2_3, org.swift.30p620160816a`)
   - clean: Should the project be cleaned before building it?
   - codeCoverage: Should code coverage be generated? (Xcode 7 and up)
   - addressSanitizer: Should the address sanitizer be turned on?
   - threadSanitizer: Should the thread sanitizer be turned on?
   - openReport: Should the HTML report be opened when tests are completed?
   - outputDirectory: The directory in which all reports will be stored
   - outputStyle: Define how the output should look like. Valid values are: standard, basic, rspec, or raw (disables xcpretty during xcodebuild)
   - outputTypes: Comma separated list of the output types (e.g. html, junit, json-compilation-database)
   - outputFiles: Comma separated list of the output files, corresponding to the types provided by :output_types (order should match). If specifying an output type of json-compilation-database with :use_clang_report_name enabled, that option will take precedence
   - buildlogPath: The directory where to store the raw log
   - includeSimulatorLogs: If the logs generated by the app (e.g. using NSLog, perror, etc.) in the Simulator should be written to the output_directory
   - suppressXcodeOutput: Suppress the output of xcodebuild to stdout. Output is still saved in buildlog_path
   - xcodebuildFormatter: xcodebuild formatter to use (ex: 'xcbeautify', 'xcbeautify --quieter', 'xcpretty', 'xcpretty -test'). Use empty string (ex: '') to disable any formatter (More information: https://docs.fastlane.tools/best-practices/xcodebuild-formatters/)
   - outputRemoveRetryAttempts: Remove retry attempts from test results table and the JUnit report (if not using xcpretty)
   - disableXcpretty: **DEPRECATED!** Use `output_style: 'raw'` instead - Disable xcpretty formatting of build, similar to `output_style='raw'` but this will also skip the test results table
   - formatter: **DEPRECATED!** Use 'xcpretty_formatter' instead - A custom xcpretty formatter to use
   - xcprettyFormatter: A custom xcpretty formatter to use
   - xcprettyArgs: Pass in xcpretty additional command line arguments (e.g. '--test --no-color' or '--tap --no-utf')
   - derivedDataPath: The directory where build products and other derived data will go
   - shouldZipBuildProducts: Should zip the derived data build products and place in output path?
   - outputXctestrun: Should provide additional copy of .xctestrun file (settings.xctestrun) and place in output path?
   - resultBundlePath: Custom path for the result bundle, overrides result_bundle
   - resultBundle: Should an Xcode result bundle be generated in the output directory
   - useClangReportName: Generate the json compilation database with clang naming convention (compile_commands.json)
   - parallelTesting: Optionally override the per-target setting in the scheme for running tests in parallel. Equivalent to -parallel-testing-enabled
   - concurrentWorkers: Specify the exact number of test runners that will be spawned during parallel testing. Equivalent to -parallel-testing-worker-count
   - maxConcurrentSimulators: Constrain the number of simulator devices on which to test concurrently. Equivalent to -maximum-concurrent-test-simulator-destinations
   - disableConcurrentTesting: Do not run test bundles in parallel on the specified destinations. Testing will occur on each destination serially. Equivalent to -disable-concurrent-testing
   - skipBuild: Should debug build be skipped before test build?
   - testWithoutBuilding: Test without building, requires a derived data path
   - buildForTesting: Build for testing only, does not run tests
   - sdk: The SDK that should be used for building the application
   - configuration: The configuration to use when building the app. Defaults to 'Release'
   - xcargs: Pass additional arguments to xcodebuild. Be sure to quote the setting names and values e.g. OTHER_LDFLAGS="-ObjC -lstdc++"
   - xcconfig: Use an extra XCCONFIG file to build your app
   - appName: App name to use in slack message and logfile name
   - deploymentTargetVersion: Target version of the app being build or tested. Used to filter out simulator version
   - slackUrl: Create an Incoming WebHook for your Slack group to post results there
   - slackChannel: #channel or @username
   - slackMessage: The message included with each message posted to slack
   - slackUseWebhookConfiguredUsernameAndIcon: Use webhook's default username and icon settings? (true/false)
   - slackUsername: Overrides the webhook's username property if slack_use_webhook_configured_username_and_icon is false
   - slackIconUrl: Overrides the webhook's image property if slack_use_webhook_configured_username_and_icon is false
   - skipSlack: Don't publish to slack, even when an URL is given
   - slackOnlyOnFailure: Only post on Slack if the tests fail
   - slackDefaultPayloads: Specifies default payloads to include in Slack messages. For more info visit https://docs.fastlane.tools/actions/slack
   - destination: Use only if you're a pro, use the other options instead
   - runRosettaSimulator: Adds arch=x86_64 to the xcodebuild 'destination' argument to run simulator in a Rosetta mode
   - catalystPlatform: Platform to build when using a Catalyst enabled app. Valid values are: ios, macos
   - customReportFileName: **DEPRECATED!** Use `--output_files` instead - Sets custom full report file name when generating a single report
   - xcodebuildCommand: Allows for override of the default `xcodebuild` command
   - clonedSourcePackagesPath: Sets a custom path for Swift Package Manager dependencies
   - skipPackageDependenciesResolution: Skips resolution of Swift Package Manager dependencies
   - disablePackageAutomaticUpdates: Prevents packages from automatically being resolved to versions other than those recorded in the `Package.resolved` file
   - useSystemScm: Lets xcodebuild use system's scm configuration
   - numberOfRetries: The number of times a test can fail
   - failBuild: Should this step stop the build if the tests fail? Set this to false if you're using trainer
   - packageAuthorizationProvider: Lets xcodebuild use a specified package authorization provider (keychain|netrc)

 - returns: Outputs hash of results with the following keys: :number_of_tests, :number_of_failures, :number_of_retries, :number_of_tests_excluding_retries, :number_of_failures_excluding_retries

 More information: https://docs.fastlane.tools/actions/scan/
 */
@discardableResult public func scan(workspace: OptionalConfigValue<String?> = .fastlaneDefault(scanfile.workspace),
                                    project: OptionalConfigValue<String?> = .fastlaneDefault(scanfile.project),
                                    packagePath: OptionalConfigValue<String?> = .fastlaneDefault(scanfile.packagePath),
                                    scheme: OptionalConfigValue<String?> = .fastlaneDefault(scanfile.scheme),
                                    device: OptionalConfigValue<String?> = .fastlaneDefault(scanfile.device),
                                    devices: OptionalConfigValue<[String]?> = .fastlaneDefault(scanfile.devices),
                                    skipDetectDevices: OptionalConfigValue<Bool> = .fastlaneDefault(scanfile.skipDetectDevices),
                                    ensureDevicesFound: OptionalConfigValue<Bool> = .fastlaneDefault(scanfile.ensureDevicesFound),
                                    forceQuitSimulator: OptionalConfigValue<Bool> = .fastlaneDefault(scanfile.forceQuitSimulator),
                                    resetSimulator: OptionalConfigValue<Bool> = .fastlaneDefault(scanfile.resetSimulator),
                                    disableSlideToType: OptionalConfigValue<Bool> = .fastlaneDefault(scanfile.disableSlideToType),
                                    prelaunchSimulator: OptionalConfigValue<Bool?> = .fastlaneDefault(scanfile.prelaunchSimulator),
                                    reinstallApp: OptionalConfigValue<Bool> = .fastlaneDefault(scanfile.reinstallApp),
                                    appIdentifier: OptionalConfigValue<String?> = .fastlaneDefault(scanfile.appIdentifier),
                                    onlyTesting: Any? = scanfile.onlyTesting,
                                    skipTesting: Any? = scanfile.skipTesting,
                                    testplan: OptionalConfigValue<String?> = .fastlaneDefault(scanfile.testplan),
                                    onlyTestConfigurations: Any? = scanfile.onlyTestConfigurations,
                                    skipTestConfigurations: Any? = scanfile.skipTestConfigurations,
                                    xctestrun: OptionalConfigValue<String?> = .fastlaneDefault(scanfile.xctestrun),
                                    toolchain: Any? = scanfile.toolchain,
                                    clean: OptionalConfigValue<Bool> = .fastlaneDefault(scanfile.clean),
                                    codeCoverage: OptionalConfigValue<Bool?> = .fastlaneDefault(scanfile.codeCoverage),
                                    addressSanitizer: OptionalConfigValue<Bool?> = .fastlaneDefault(scanfile.addressSanitizer),
                                    threadSanitizer: OptionalConfigValue<Bool?> = .fastlaneDefault(scanfile.threadSanitizer),
                                    openReport: OptionalConfigValue<Bool> = .fastlaneDefault(scanfile.openReport),
                                    outputDirectory: String = scanfile.outputDirectory,
                                    outputStyle: OptionalConfigValue<String?> = .fastlaneDefault(scanfile.outputStyle),
                                    outputTypes: String = scanfile.outputTypes,
                                    outputFiles: OptionalConfigValue<String?> = .fastlaneDefault(scanfile.outputFiles),
                                    buildlogPath: String = scanfile.buildlogPath,
                                    includeSimulatorLogs: OptionalConfigValue<Bool> = .fastlaneDefault(scanfile.includeSimulatorLogs),
                                    suppressXcodeOutput: OptionalConfigValue<Bool?> = .fastlaneDefault(scanfile.suppressXcodeOutput),
                                    xcodebuildFormatter: String = scanfile.xcodebuildFormatter,
                                    outputRemoveRetryAttempts: OptionalConfigValue<Bool> = .fastlaneDefault(scanfile.outputRemoveRetryAttempts),
                                    disableXcpretty: OptionalConfigValue<Bool?> = .fastlaneDefault(scanfile.disableXcpretty),
                                    formatter: OptionalConfigValue<String?> = .fastlaneDefault(scanfile.formatter),
                                    xcprettyFormatter: OptionalConfigValue<String?> = .fastlaneDefault(scanfile.xcprettyFormatter),
                                    xcprettyArgs: OptionalConfigValue<String?> = .fastlaneDefault(scanfile.xcprettyArgs),
                                    derivedDataPath: OptionalConfigValue<String?> = .fastlaneDefault(scanfile.derivedDataPath),
                                    shouldZipBuildProducts: OptionalConfigValue<Bool> = .fastlaneDefault(scanfile.shouldZipBuildProducts),
                                    outputXctestrun: OptionalConfigValue<Bool> = .fastlaneDefault(scanfile.outputXctestrun),
                                    resultBundlePath: OptionalConfigValue<String?> = .fastlaneDefault(scanfile.resultBundlePath),
                                    resultBundle: OptionalConfigValue<Bool> = .fastlaneDefault(scanfile.resultBundle),
                                    useClangReportName: OptionalConfigValue<Bool> = .fastlaneDefault(scanfile.useClangReportName),
                                    parallelTesting: OptionalConfigValue<Bool?> = .fastlaneDefault(scanfile.parallelTesting),
                                    concurrentWorkers: OptionalConfigValue<Int?> = .fastlaneDefault(scanfile.concurrentWorkers),
                                    maxConcurrentSimulators: OptionalConfigValue<Int?> = .fastlaneDefault(scanfile.maxConcurrentSimulators),
                                    disableConcurrentTesting: OptionalConfigValue<Bool> = .fastlaneDefault(scanfile.disableConcurrentTesting),
                                    skipBuild: OptionalConfigValue<Bool> = .fastlaneDefault(scanfile.skipBuild),
                                    testWithoutBuilding: OptionalConfigValue<Bool?> = .fastlaneDefault(scanfile.testWithoutBuilding),
                                    buildForTesting: OptionalConfigValue<Bool?> = .fastlaneDefault(scanfile.buildForTesting),
                                    sdk: OptionalConfigValue<String?> = .fastlaneDefault(scanfile.sdk),
                                    configuration: OptionalConfigValue<String?> = .fastlaneDefault(scanfile.configuration),
                                    xcargs: OptionalConfigValue<String?> = .fastlaneDefault(scanfile.xcargs),
                                    xcconfig: OptionalConfigValue<String?> = .fastlaneDefault(scanfile.xcconfig),
                                    appName: OptionalConfigValue<String?> = .fastlaneDefault(scanfile.appName),
                                    deploymentTargetVersion: OptionalConfigValue<String?> = .fastlaneDefault(scanfile.deploymentTargetVersion),
                                    slackUrl: OptionalConfigValue<String?> = .fastlaneDefault(scanfile.slackUrl),
                                    slackChannel: OptionalConfigValue<String?> = .fastlaneDefault(scanfile.slackChannel),
                                    slackMessage: OptionalConfigValue<String?> = .fastlaneDefault(scanfile.slackMessage),
                                    slackUseWebhookConfiguredUsernameAndIcon: OptionalConfigValue<Bool> = .fastlaneDefault(scanfile.slackUseWebhookConfiguredUsernameAndIcon),
                                    slackUsername: String = scanfile.slackUsername,
                                    slackIconUrl: String = scanfile.slackIconUrl,
                                    skipSlack: OptionalConfigValue<Bool> = .fastlaneDefault(scanfile.skipSlack),
                                    slackOnlyOnFailure: OptionalConfigValue<Bool> = .fastlaneDefault(scanfile.slackOnlyOnFailure),
                                    slackDefaultPayloads: OptionalConfigValue<[String]?> = .fastlaneDefault(scanfile.slackDefaultPayloads),
                                    destination: Any? = scanfile.destination,
                                    runRosettaSimulator: OptionalConfigValue<Bool> = .fastlaneDefault(scanfile.runRosettaSimulator),
                                    catalystPlatform: OptionalConfigValue<String?> = .fastlaneDefault(scanfile.catalystPlatform),
                                    customReportFileName: OptionalConfigValue<String?> = .fastlaneDefault(scanfile.customReportFileName),
                                    xcodebuildCommand: String = scanfile.xcodebuildCommand,
                                    clonedSourcePackagesPath: OptionalConfigValue<String?> = .fastlaneDefault(scanfile.clonedSourcePackagesPath),
                                    skipPackageDependenciesResolution: OptionalConfigValue<Bool> = .fastlaneDefault(scanfile.skipPackageDependenciesResolution),
                                    disablePackageAutomaticUpdates: OptionalConfigValue<Bool> = .fastlaneDefault(scanfile.disablePackageAutomaticUpdates),
                                    useSystemScm: OptionalConfigValue<Bool> = .fastlaneDefault(scanfile.useSystemScm),
                                    numberOfRetries: Int = scanfile.numberOfRetries,
                                    failBuild: OptionalConfigValue<Bool> = .fastlaneDefault(scanfile.failBuild),
                                    packageAuthorizationProvider: OptionalConfigValue<String?> = .fastlaneDefault(scanfile.packageAuthorizationProvider)) -> [String: Any]
{
    let workspaceArg = workspace.asRubyArgument(name: "workspace", type: nil)
    let projectArg = project.asRubyArgument(name: "project", type: nil)
    let packagePathArg = packagePath.asRubyArgument(name: "package_path", type: nil)
    let schemeArg = scheme.asRubyArgument(name: "scheme", type: nil)
    let deviceArg = device.asRubyArgument(name: "device", type: nil)
    let devicesArg = devices.asRubyArgument(name: "devices", type: nil)
    let skipDetectDevicesArg = skipDetectDevices.asRubyArgument(name: "skip_detect_devices", type: nil)
    let ensureDevicesFoundArg = ensureDevicesFound.asRubyArgument(name: "ensure_devices_found", type: nil)
    let forceQuitSimulatorArg = forceQuitSimulator.asRubyArgument(name: "force_quit_simulator", type: nil)
    let resetSimulatorArg = resetSimulator.asRubyArgument(name: "reset_simulator", type: nil)
    let disableSlideToTypeArg = disableSlideToType.asRubyArgument(name: "disable_slide_to_type", type: nil)
    let prelaunchSimulatorArg = prelaunchSimulator.asRubyArgument(name: "prelaunch_simulator", type: nil)
    let reinstallAppArg = reinstallApp.asRubyArgument(name: "reinstall_app", type: nil)
    let appIdentifierArg = appIdentifier.asRubyArgument(name: "app_identifier", type: nil)
    let onlyTestingArg = RubyCommand.Argument(name: "only_testing", value: onlyTesting, type: nil)
    let skipTestingArg = RubyCommand.Argument(name: "skip_testing", value: skipTesting, type: nil)
    let testplanArg = testplan.asRubyArgument(name: "testplan", type: nil)
    let onlyTestConfigurationsArg = RubyCommand.Argument(name: "only_test_configurations", value: onlyTestConfigurations, type: nil)
    let skipTestConfigurationsArg = RubyCommand.Argument(name: "skip_test_configurations", value: skipTestConfigurations, type: nil)
    let xctestrunArg = xctestrun.asRubyArgument(name: "xctestrun", type: nil)
    let toolchainArg = RubyCommand.Argument(name: "toolchain", value: toolchain, type: nil)
    let cleanArg = clean.asRubyArgument(name: "clean", type: nil)
    let codeCoverageArg = codeCoverage.asRubyArgument(name: "code_coverage", type: nil)
    let addressSanitizerArg = addressSanitizer.asRubyArgument(name: "address_sanitizer", type: nil)
    let threadSanitizerArg = threadSanitizer.asRubyArgument(name: "thread_sanitizer", type: nil)
    let openReportArg = openReport.asRubyArgument(name: "open_report", type: nil)
    let outputDirectoryArg = RubyCommand.Argument(name: "output_directory", value: outputDirectory, type: nil)
    let outputStyleArg = outputStyle.asRubyArgument(name: "output_style", type: nil)
    let outputTypesArg = RubyCommand.Argument(name: "output_types", value: outputTypes, type: nil)
    let outputFilesArg = outputFiles.asRubyArgument(name: "output_files", type: nil)
    let buildlogPathArg = RubyCommand.Argument(name: "buildlog_path", value: buildlogPath, type: nil)
    let includeSimulatorLogsArg = includeSimulatorLogs.asRubyArgument(name: "include_simulator_logs", type: nil)
    let suppressXcodeOutputArg = suppressXcodeOutput.asRubyArgument(name: "suppress_xcode_output", type: nil)
    let xcodebuildFormatterArg = RubyCommand.Argument(name: "xcodebuild_formatter", value: xcodebuildFormatter, type: nil)
    let outputRemoveRetryAttemptsArg = outputRemoveRetryAttempts.asRubyArgument(name: "output_remove_retry_attempts", type: nil)
    let disableXcprettyArg = disableXcpretty.asRubyArgument(name: "disable_xcpretty", type: nil)
    let formatterArg = formatter.asRubyArgument(name: "formatter", type: nil)
    let xcprettyFormatterArg = xcprettyFormatter.asRubyArgument(name: "xcpretty_formatter", type: nil)
    let xcprettyArgsArg = xcprettyArgs.asRubyArgument(name: "xcpretty_args", type: nil)
    let derivedDataPathArg = derivedDataPath.asRubyArgument(name: "derived_data_path", type: nil)
    let shouldZipBuildProductsArg = shouldZipBuildProducts.asRubyArgument(name: "should_zip_build_products", type: nil)
    let outputXctestrunArg = outputXctestrun.asRubyArgument(name: "output_xctestrun", type: nil)
    let resultBundlePathArg = resultBundlePath.asRubyArgument(name: "result_bundle_path", type: nil)
    let resultBundleArg = resultBundle.asRubyArgument(name: "result_bundle", type: nil)
    let useClangReportNameArg = useClangReportName.asRubyArgument(name: "use_clang_report_name", type: nil)
    let parallelTestingArg = parallelTesting.asRubyArgument(name: "parallel_testing", type: nil)
    let concurrentWorkersArg = concurrentWorkers.asRubyArgument(name: "concurrent_workers", type: nil)
    let maxConcurrentSimulatorsArg = maxConcurrentSimulators.asRubyArgument(name: "max_concurrent_simulators", type: nil)
    let disableConcurrentTestingArg = disableConcurrentTesting.asRubyArgument(name: "disable_concurrent_testing", type: nil)
    let skipBuildArg = skipBuild.asRubyArgument(name: "skip_build", type: nil)
    let testWithoutBuildingArg = testWithoutBuilding.asRubyArgument(name: "test_without_building", type: nil)
    let buildForTestingArg = buildForTesting.asRubyArgument(name: "build_for_testing", type: nil)
    let sdkArg = sdk.asRubyArgument(name: "sdk", type: nil)
    let configurationArg = configuration.asRubyArgument(name: "configuration", type: nil)
    let xcargsArg = xcargs.asRubyArgument(name: "xcargs", type: nil)
    let xcconfigArg = xcconfig.asRubyArgument(name: "xcconfig", type: nil)
    let appNameArg = appName.asRubyArgument(name: "app_name", type: nil)
    let deploymentTargetVersionArg = deploymentTargetVersion.asRubyArgument(name: "deployment_target_version", type: nil)
    let slackUrlArg = slackUrl.asRubyArgument(name: "slack_url", type: nil)
    let slackChannelArg = slackChannel.asRubyArgument(name: "slack_channel", type: nil)
    let slackMessageArg = slackMessage.asRubyArgument(name: "slack_message", type: nil)
    let slackUseWebhookConfiguredUsernameAndIconArg = slackUseWebhookConfiguredUsernameAndIcon.asRubyArgument(name: "slack_use_webhook_configured_username_and_icon", type: nil)
    let slackUsernameArg = RubyCommand.Argument(name: "slack_username", value: slackUsername, type: nil)
    let slackIconUrlArg = RubyCommand.Argument(name: "slack_icon_url", value: slackIconUrl, type: nil)
    let skipSlackArg = skipSlack.asRubyArgument(name: "skip_slack", type: nil)
    let slackOnlyOnFailureArg = slackOnlyOnFailure.asRubyArgument(name: "slack_only_on_failure", type: nil)
    let slackDefaultPayloadsArg = slackDefaultPayloads.asRubyArgument(name: "slack_default_payloads", type: nil)
    let destinationArg = RubyCommand.Argument(name: "destination", value: destination, type: nil)
    let runRosettaSimulatorArg = runRosettaSimulator.asRubyArgument(name: "run_rosetta_simulator", type: nil)
    let catalystPlatformArg = catalystPlatform.asRubyArgument(name: "catalyst_platform", type: nil)
    let customReportFileNameArg = customReportFileName.asRubyArgument(name: "custom_report_file_name", type: nil)
    let xcodebuildCommandArg = RubyCommand.Argument(name: "xcodebuild_command", value: xcodebuildCommand, type: nil)
    let clonedSourcePackagesPathArg = clonedSourcePackagesPath.asRubyArgument(name: "cloned_source_packages_path", type: nil)
    let skipPackageDependenciesResolutionArg = skipPackageDependenciesResolution.asRubyArgument(name: "skip_package_dependencies_resolution", type: nil)
    let disablePackageAutomaticUpdatesArg = disablePackageAutomaticUpdates.asRubyArgument(name: "disable_package_automatic_updates", type: nil)
    let useSystemScmArg = useSystemScm.asRubyArgument(name: "use_system_scm", type: nil)
    let numberOfRetriesArg = RubyCommand.Argument(name: "number_of_retries", value: numberOfRetries, type: nil)
    let failBuildArg = failBuild.asRubyArgument(name: "fail_build", type: nil)
    let packageAuthorizationProviderArg = packageAuthorizationProvider.asRubyArgument(name: "package_authorization_provider", type: nil)
    let array: [RubyCommand.Argument?] = [workspaceArg,
                                          projectArg,
                                          packagePathArg,
                                          schemeArg,
                                          deviceArg,
                                          devicesArg,
                                          skipDetectDevicesArg,
                                          ensureDevicesFoundArg,
                                          forceQuitSimulatorArg,
                                          resetSimulatorArg,
                                          disableSlideToTypeArg,
                                          prelaunchSimulatorArg,
                                          reinstallAppArg,
                                          appIdentifierArg,
                                          onlyTestingArg,
                                          skipTestingArg,
                                          testplanArg,
                                          onlyTestConfigurationsArg,
                                          skipTestConfigurationsArg,
                                          xctestrunArg,
                                          toolchainArg,
                                          cleanArg,
                                          codeCoverageArg,
                                          addressSanitizerArg,
                                          threadSanitizerArg,
                                          openReportArg,
                                          outputDirectoryArg,
                                          outputStyleArg,
                                          outputTypesArg,
                                          outputFilesArg,
                                          buildlogPathArg,
                                          includeSimulatorLogsArg,
                                          suppressXcodeOutputArg,
                                          xcodebuildFormatterArg,
                                          outputRemoveRetryAttemptsArg,
                                          disableXcprettyArg,
                                          formatterArg,
                                          xcprettyFormatterArg,
                                          xcprettyArgsArg,
                                          derivedDataPathArg,
                                          shouldZipBuildProductsArg,
                                          outputXctestrunArg,
                                          resultBundlePathArg,
                                          resultBundleArg,
                                          useClangReportNameArg,
                                          parallelTestingArg,
                                          concurrentWorkersArg,
                                          maxConcurrentSimulatorsArg,
                                          disableConcurrentTestingArg,
                                          skipBuildArg,
                                          testWithoutBuildingArg,
                                          buildForTestingArg,
                                          sdkArg,
                                          configurationArg,
                                          xcargsArg,
                                          xcconfigArg,
                                          appNameArg,
                                          deploymentTargetVersionArg,
                                          slackUrlArg,
                                          slackChannelArg,
                                          slackMessageArg,
                                          slackUseWebhookConfiguredUsernameAndIconArg,
                                          slackUsernameArg,
                                          slackIconUrlArg,
                                          skipSlackArg,
                                          slackOnlyOnFailureArg,
                                          slackDefaultPayloadsArg,
                                          destinationArg,
                                          runRosettaSimulatorArg,
                                          catalystPlatformArg,
                                          customReportFileNameArg,
                                          xcodebuildCommandArg,
                                          clonedSourcePackagesPathArg,
                                          skipPackageDependenciesResolutionArg,
                                          disablePackageAutomaticUpdatesArg,
                                          useSystemScmArg,
                                          numberOfRetriesArg,
                                          failBuildArg,
                                          packageAuthorizationProviderArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "scan", className: nil, args: args)
    return parseDictionary(fromString: runner.executeCommand(command))
}

/**
 Transfer files via SCP

 - parameters:
   - username: Username
   - password: Password
   - host: Hostname
   - port: Port
   - upload: Upload
   - download: Download
 */
public func scp(username: String,
                password: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                host: String,
                port: String = "22",
                upload: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                download: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil))
{
    let usernameArg = RubyCommand.Argument(name: "username", value: username, type: nil)
    let passwordArg = password.asRubyArgument(name: "password", type: nil)
    let hostArg = RubyCommand.Argument(name: "host", value: host, type: nil)
    let portArg = RubyCommand.Argument(name: "port", value: port, type: nil)
    let uploadArg = upload.asRubyArgument(name: "upload", type: nil)
    let downloadArg = download.asRubyArgument(name: "download", type: nil)
    let array: [RubyCommand.Argument?] = [usernameArg,
                                          passwordArg,
                                          hostArg,
                                          portArg,
                                          uploadArg,
                                          downloadArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "scp", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Alias for the `capture_android_screenshots` action

 - parameters:
   - androidHome: Path to the root of your Android SDK installation, e.g. ~/tools/android-sdk-macosx
   - buildToolsVersion: **DEPRECATED!** The Android build tools version to use, e.g. '23.0.2'
   - locales: A list of locales which should be used
   - clearPreviousScreenshots: Enabling this option will automatically clear previously generated screenshots before running screengrab
   - outputDirectory: The directory where to store the screenshots
   - skipOpenSummary: Don't open the summary after running _screengrab_
   - appPackageName: The package name of the app under test (e.g. com.yourcompany.yourapp)
   - testsPackageName: The package name of the tests bundle (e.g. com.yourcompany.yourapp.test)
   - useTestsInPackages: Only run tests in these Java packages
   - useTestsInClasses: Only run tests in these Java classes
   - launchArguments: Additional launch arguments
   - testInstrumentationRunner: The fully qualified class name of your test instrumentation runner
   - endingLocale: **DEPRECATED!** Return the device to this locale after running tests
   - useAdbRoot: **DEPRECATED!** Restarts the adb daemon using `adb root` to allow access to screenshots directories on device. Use if getting 'Permission denied' errors
   - appApkPath: The path to the APK for the app under test
   - testsApkPath: The path to the APK for the tests bundle
   - specificDevice: Use the device or emulator with the given serial number or qualifier
   - deviceType: Type of device used for screenshots. Matches Google Play Types (phone, sevenInch, tenInch, tv, wear)
   - exitOnTestFailure: Whether or not to exit Screengrab on test failure. Exiting on failure will not copy screenshots to local machine nor open screenshots summary
   - reinstallApp: Enabling this option will automatically uninstall the application before running it
   - useTimestampSuffix: Add timestamp suffix to screenshot filename
   - adbHost: Configure the host used by adb to connect, allows running on remote devices farm
 */
public func screengrab(androidHome: OptionalConfigValue<String?> = .fastlaneDefault(screengrabfile.androidHome),
                       buildToolsVersion: OptionalConfigValue<String?> = .fastlaneDefault(screengrabfile.buildToolsVersion),
                       locales: [String] = screengrabfile.locales,
                       clearPreviousScreenshots: OptionalConfigValue<Bool> = .fastlaneDefault(screengrabfile.clearPreviousScreenshots),
                       outputDirectory: String = screengrabfile.outputDirectory,
                       skipOpenSummary: OptionalConfigValue<Bool> = .fastlaneDefault(screengrabfile.skipOpenSummary),
                       appPackageName: String = screengrabfile.appPackageName,
                       testsPackageName: OptionalConfigValue<String?> = .fastlaneDefault(screengrabfile.testsPackageName),
                       useTestsInPackages: OptionalConfigValue<[String]?> = .fastlaneDefault(screengrabfile.useTestsInPackages),
                       useTestsInClasses: OptionalConfigValue<[String]?> = .fastlaneDefault(screengrabfile.useTestsInClasses),
                       launchArguments: OptionalConfigValue<[String]?> = .fastlaneDefault(screengrabfile.launchArguments),
                       testInstrumentationRunner: String = screengrabfile.testInstrumentationRunner,
                       endingLocale: String = screengrabfile.endingLocale,
                       useAdbRoot: OptionalConfigValue<Bool> = .fastlaneDefault(screengrabfile.useAdbRoot),
                       appApkPath: OptionalConfigValue<String?> = .fastlaneDefault(screengrabfile.appApkPath),
                       testsApkPath: OptionalConfigValue<String?> = .fastlaneDefault(screengrabfile.testsApkPath),
                       specificDevice: OptionalConfigValue<String?> = .fastlaneDefault(screengrabfile.specificDevice),
                       deviceType: String = screengrabfile.deviceType,
                       exitOnTestFailure: OptionalConfigValue<Bool> = .fastlaneDefault(screengrabfile.exitOnTestFailure),
                       reinstallApp: OptionalConfigValue<Bool> = .fastlaneDefault(screengrabfile.reinstallApp),
                       useTimestampSuffix: OptionalConfigValue<Bool> = .fastlaneDefault(screengrabfile.useTimestampSuffix),
                       adbHost: OptionalConfigValue<String?> = .fastlaneDefault(screengrabfile.adbHost))
{
    let androidHomeArg = androidHome.asRubyArgument(name: "android_home", type: nil)
    let buildToolsVersionArg = buildToolsVersion.asRubyArgument(name: "build_tools_version", type: nil)
    let localesArg = RubyCommand.Argument(name: "locales", value: locales, type: nil)
    let clearPreviousScreenshotsArg = clearPreviousScreenshots.asRubyArgument(name: "clear_previous_screenshots", type: nil)
    let outputDirectoryArg = RubyCommand.Argument(name: "output_directory", value: outputDirectory, type: nil)
    let skipOpenSummaryArg = skipOpenSummary.asRubyArgument(name: "skip_open_summary", type: nil)
    let appPackageNameArg = RubyCommand.Argument(name: "app_package_name", value: appPackageName, type: nil)
    let testsPackageNameArg = testsPackageName.asRubyArgument(name: "tests_package_name", type: nil)
    let useTestsInPackagesArg = useTestsInPackages.asRubyArgument(name: "use_tests_in_packages", type: nil)
    let useTestsInClassesArg = useTestsInClasses.asRubyArgument(name: "use_tests_in_classes", type: nil)
    let launchArgumentsArg = launchArguments.asRubyArgument(name: "launch_arguments", type: nil)
    let testInstrumentationRunnerArg = RubyCommand.Argument(name: "test_instrumentation_runner", value: testInstrumentationRunner, type: nil)
    let endingLocaleArg = RubyCommand.Argument(name: "ending_locale", value: endingLocale, type: nil)
    let useAdbRootArg = useAdbRoot.asRubyArgument(name: "use_adb_root", type: nil)
    let appApkPathArg = appApkPath.asRubyArgument(name: "app_apk_path", type: nil)
    let testsApkPathArg = testsApkPath.asRubyArgument(name: "tests_apk_path", type: nil)
    let specificDeviceArg = specificDevice.asRubyArgument(name: "specific_device", type: nil)
    let deviceTypeArg = RubyCommand.Argument(name: "device_type", value: deviceType, type: nil)
    let exitOnTestFailureArg = exitOnTestFailure.asRubyArgument(name: "exit_on_test_failure", type: nil)
    let reinstallAppArg = reinstallApp.asRubyArgument(name: "reinstall_app", type: nil)
    let useTimestampSuffixArg = useTimestampSuffix.asRubyArgument(name: "use_timestamp_suffix", type: nil)
    let adbHostArg = adbHost.asRubyArgument(name: "adb_host", type: nil)
    let array: [RubyCommand.Argument?] = [androidHomeArg,
                                          buildToolsVersionArg,
                                          localesArg,
                                          clearPreviousScreenshotsArg,
                                          outputDirectoryArg,
                                          skipOpenSummaryArg,
                                          appPackageNameArg,
                                          testsPackageNameArg,
                                          useTestsInPackagesArg,
                                          useTestsInClassesArg,
                                          launchArgumentsArg,
                                          testInstrumentationRunnerArg,
                                          endingLocaleArg,
                                          useAdbRootArg,
                                          appApkPathArg,
                                          testsApkPathArg,
                                          specificDeviceArg,
                                          deviceTypeArg,
                                          exitOnTestFailureArg,
                                          reinstallAppArg,
                                          useTimestampSuffixArg,
                                          adbHostArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "screengrab", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Set the build number from the current repository

 - parameters:
   - useHgRevisionNumber: Use hg revision number instead of hash (ignored for non-hg repos)
   - xcodeproj: explicitly specify which xcodeproj to use

 This action will set the **build number** according to what the SCM HEAD reports.
 Currently supported SCMs are svn (uses root revision), git-svn (uses svn revision) and git (uses short hash) and mercurial (uses short hash or revision number).
 There is an option, `:use_hg_revision_number`, which allows to use mercurial revision number instead of hash.
 */
public func setBuildNumberRepository(useHgRevisionNumber: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                     xcodeproj: OptionalConfigValue<String?> = .fastlaneDefault(nil))
{
    let useHgRevisionNumberArg = useHgRevisionNumber.asRubyArgument(name: "use_hg_revision_number", type: nil)
    let xcodeprojArg = xcodeproj.asRubyArgument(name: "xcodeproj", type: nil)
    let array: [RubyCommand.Argument?] = [useHgRevisionNumberArg,
                                          xcodeprojArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "set_build_number_repository", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Set the changelog for all languages on App Store Connect

 - parameters:
   - apiKeyPath: Path to your App Store Connect API Key JSON file (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-json-file)
   - apiKey: Your App Store Connect API Key information (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-hash-option)
   - appIdentifier: The bundle identifier of your app
   - username: Your Apple ID Username
   - version: The version number to create/update
   - changelog: Changelog text that should be uploaded to App Store Connect
   - teamId: The ID of your App Store Connect team if you're in multiple teams
   - teamName: The name of your App Store Connect team if you're in multiple teams
   - platform: The platform of the app (ios, appletvos, xros, mac)

 This is useful if you have only one changelog for all languages.
 You can store the changelog in `./changelog.txt` and it will automatically get loaded from there. This integration is useful if you support e.g. 10 languages and want to use the same "What's new"-text for all languages.
 Defining the version is optional. _fastlane_ will try to automatically detect it if you don't provide one.
 */
public func setChangelog(apiKeyPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                         apiKey: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                         appIdentifier: String,
                         username: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                         version: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                         changelog: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                         teamId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                         teamName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                         platform: String = "ios")
{
    let apiKeyPathArg = apiKeyPath.asRubyArgument(name: "api_key_path", type: nil)
    let apiKeyArg = apiKey.asRubyArgument(name: "api_key", type: nil)
    let appIdentifierArg = RubyCommand.Argument(name: "app_identifier", value: appIdentifier, type: nil)
    let usernameArg = username.asRubyArgument(name: "username", type: nil)
    let versionArg = version.asRubyArgument(name: "version", type: nil)
    let changelogArg = changelog.asRubyArgument(name: "changelog", type: nil)
    let teamIdArg = teamId.asRubyArgument(name: "team_id", type: nil)
    let teamNameArg = teamName.asRubyArgument(name: "team_name", type: nil)
    let platformArg = RubyCommand.Argument(name: "platform", value: platform, type: nil)
    let array: [RubyCommand.Argument?] = [apiKeyPathArg,
                                          apiKeyArg,
                                          appIdentifierArg,
                                          usernameArg,
                                          versionArg,
                                          changelogArg,
                                          teamIdArg,
                                          teamNameArg,
                                          platformArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "set_changelog", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
  This will create a new release on GitHub and upload assets for it

  - parameters:
    - repositoryName: The path to your repo, e.g. 'fastlane/fastlane'
    - serverUrl: The server url. e.g. 'https://your.internal.github.host/api/v3' (Default: 'https://api.github.com')
    - apiToken: Personal API Token for GitHub - generate one at https://github.com/settings/tokens
    - apiBearer: Use a Bearer authorization token. Usually generated by GitHub Apps, e.g. GitHub Actions GITHUB_TOKEN environment variable
    - tagName: Pass in the tag name
    - name: Name of this release
    - commitish: Specifies the commitish value that determines where the Git tag is created from. Can be any branch or commit SHA. Unused if the Git tag already exists. Default: the repository's default branch (usually master)
    - description: Description of this release
    - isDraft: Whether the release should be marked as draft
    - isPrerelease: Whether the release should be marked as prerelease
    - isGenerateReleaseNotes: Whether the name and body of this release should be generated automatically
    - uploadAssets: Path to assets to be uploaded with the release

  - returns: A hash containing all relevant information of this release
 Access things like 'html_url', 'tag_name', 'name', 'body'

  Creates a new release on GitHub. You must provide your GitHub Personal token (get one from [https://github.com/settings/tokens/new](https://github.com/settings/tokens/new)), the repository name and tag name. By default, that's `master`.
  If the tag doesn't exist, one will be created on the commit or branch passed in as commitish.
  Out parameters provide the release's id, which can be used for later editing and the release HTML link to GitHub. You can also specify a list of assets to be uploaded to the release with the `:upload_assets` parameter.
 */
@discardableResult public func setGithubRelease(repositoryName: String,
                                                serverUrl: String = "https://api.github.com",
                                                apiToken: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                                apiBearer: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                                tagName: String,
                                                name: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                                commitish: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                                description: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                                isDraft: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                                isPrerelease: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                                isGenerateReleaseNotes: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                                uploadAssets: OptionalConfigValue<[String]?> = .fastlaneDefault(nil)) -> [String: Any]
{
    let repositoryNameArg = RubyCommand.Argument(name: "repository_name", value: repositoryName, type: nil)
    let serverUrlArg = RubyCommand.Argument(name: "server_url", value: serverUrl, type: nil)
    let apiTokenArg = apiToken.asRubyArgument(name: "api_token", type: nil)
    let apiBearerArg = apiBearer.asRubyArgument(name: "api_bearer", type: nil)
    let tagNameArg = RubyCommand.Argument(name: "tag_name", value: tagName, type: nil)
    let nameArg = name.asRubyArgument(name: "name", type: nil)
    let commitishArg = commitish.asRubyArgument(name: "commitish", type: nil)
    let descriptionArg = description.asRubyArgument(name: "description", type: nil)
    let isDraftArg = isDraft.asRubyArgument(name: "is_draft", type: nil)
    let isPrereleaseArg = isPrerelease.asRubyArgument(name: "is_prerelease", type: nil)
    let isGenerateReleaseNotesArg = isGenerateReleaseNotes.asRubyArgument(name: "is_generate_release_notes", type: nil)
    let uploadAssetsArg = uploadAssets.asRubyArgument(name: "upload_assets", type: nil)
    let array: [RubyCommand.Argument?] = [repositoryNameArg,
                                          serverUrlArg,
                                          apiTokenArg,
                                          apiBearerArg,
                                          tagNameArg,
                                          nameArg,
                                          commitishArg,
                                          descriptionArg,
                                          isDraftArg,
                                          isPrereleaseArg,
                                          isGenerateReleaseNotesArg,
                                          uploadAssetsArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "set_github_release", className: nil, args: args)
    return parseDictionary(fromString: runner.executeCommand(command))
}

/**
 Sets value to Info.plist of your project as native Ruby data structures

 - parameters:
   - key: Name of key in plist
   - subkey: Name of subkey in plist
   - value: Value to setup
   - path: Path to plist file you want to update
   - outputFileName: Path to the output file you want to generate
 */
public func setInfoPlistValue(key: String,
                              subkey: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                              value: String,
                              path: String,
                              outputFileName: OptionalConfigValue<String?> = .fastlaneDefault(nil))
{
    let keyArg = RubyCommand.Argument(name: "key", value: key, type: nil)
    let subkeyArg = subkey.asRubyArgument(name: "subkey", type: nil)
    let valueArg = RubyCommand.Argument(name: "value", value: value, type: nil)
    let pathArg = RubyCommand.Argument(name: "path", value: path, type: nil)
    let outputFileNameArg = outputFileName.asRubyArgument(name: "output_file_name", type: nil)
    let array: [RubyCommand.Argument?] = [keyArg,
                                          subkeyArg,
                                          valueArg,
                                          pathArg,
                                          outputFileNameArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "set_info_plist_value", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Sets a value for a key with cocoapods-keys

 - parameters:
   - useBundleExec: Use bundle exec when there is a Gemfile presented
   - key: The key to be saved with cocoapods-keys
   - value: The value to be saved with cocoapods-keys
   - project: The project name

 Adds a key to [cocoapods-keys](https://github.com/orta/cocoapods-keys)
 */
public func setPodKey(useBundleExec: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                      key: String,
                      value: String,
                      project: OptionalConfigValue<String?> = .fastlaneDefault(nil))
{
    let useBundleExecArg = useBundleExec.asRubyArgument(name: "use_bundle_exec", type: nil)
    let keyArg = RubyCommand.Argument(name: "key", value: key, type: nil)
    let valueArg = RubyCommand.Argument(name: "value", value: value, type: nil)
    let projectArg = project.asRubyArgument(name: "project", type: nil)
    let array: [RubyCommand.Argument?] = [useBundleExecArg,
                                          keyArg,
                                          valueArg,
                                          projectArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "set_pod_key", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Setup the keychain and match to work with CI

 - parameters:
   - force: Force setup, even if not executed by CI
   - provider: CI provider. If none is set, the provider is detected automatically
   - timeout: Set a custom timeout in seconds for keychain.  Set `0` if you want to specify 'no time-out'

 - Creates a new temporary keychain for use with match|
 - Switches match to `readonly` mode to not create new profiles/cert on CI|
 - Sets up log and test result paths to be easily collectible|
 >|
 This action helps with CI integration. Add this to the top of your Fastfile if you use CI.
 */
public func setupCi(force: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                    provider: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                    timeout: Int = 3600)
{
    let forceArg = force.asRubyArgument(name: "force", type: nil)
    let providerArg = provider.asRubyArgument(name: "provider", type: nil)
    let timeoutArg = RubyCommand.Argument(name: "timeout", value: timeout, type: nil)
    let array: [RubyCommand.Argument?] = [forceArg,
                                          providerArg,
                                          timeoutArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "setup_ci", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Setup the keychain and match to work with CircleCI

 - parameter force: Force setup, even if not executed by CircleCI

 - Creates a new temporary keychain for use with match|
 - Switches match to `readonly` mode to not create new profiles/cert on CI|
 - Sets up log and test result paths to be easily collectible|
 >|
 This action helps with CircleCI integration. Add this to the top of your Fastfile if you use CircleCI.
 */
public func setupCircleCi(force: OptionalConfigValue<Bool> = .fastlaneDefault(false)) {
    let forceArg = force.asRubyArgument(name: "force", type: nil)
    let array: [RubyCommand.Argument?] = [forceArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "setup_circle_ci", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Setup xcodebuild, gym and scan for easier Jenkins integration

 - parameters:
   - force: Force setup, even if not executed by Jenkins
   - unlockKeychain: Unlocks keychain
   - addKeychainToSearchList: Add to keychain search list, valid values are true, false, :add, and :replace
   - setDefaultKeychain: Set keychain as default
   - keychainPath: Path to keychain
   - keychainPassword: Keychain password
   - setCodeSigningIdentity: Set code signing identity from CODE_SIGNING_IDENTITY environment
   - codeSigningIdentity: Code signing identity
   - outputDirectory: The directory in which the ipa file should be stored in
   - derivedDataPath: The directory where built products and other derived data will go
   - resultBundle: Produce the result bundle describing what occurred will be placed

 - Adds and unlocks keychains from Jenkins 'Keychains and Provisioning Profiles Plugin'|
 - Sets unlocked keychain to be used by Match|
 - Sets code signing identity from Jenkins 'Keychains and Provisioning Profiles Plugin'|
 - Sets output directory to './output' (gym, scan and backup_xcarchive)|
 - Sets derived data path to './derivedData' (xcodebuild, gym, scan and clear_derived_data, carthage)|
 - Produce result bundle (gym and scan)|
 >|
 This action helps with Jenkins integration. Creates own derived data for each job. All build results like IPA files and archives will be stored in the `./output` directory.
 The action also works with [Keychains and Provisioning Profiles Plugin](https://wiki.jenkins-ci.org/display/JENKINS/Keychains+and+Provisioning+Profiles+Plugin), the selected keychain will be automatically unlocked and the selected code signing identity will be used.
 [Match](https://docs.fastlane.tools/actions/match/) will be also set up to use the unlocked keychain and set in read-only mode, if its environment variables were not yet defined.
 By default this action will only work when _fastlane_ is executed on a CI system.
 */
public func setupJenkins(force: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                         unlockKeychain: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                         addKeychainToSearchList: String = "replace",
                         setDefaultKeychain: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                         keychainPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                         keychainPassword: String,
                         setCodeSigningIdentity: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                         codeSigningIdentity: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                         outputDirectory: String = "./output",
                         derivedDataPath: String = "./derivedData",
                         resultBundle: OptionalConfigValue<Bool> = .fastlaneDefault(true))
{
    let forceArg = force.asRubyArgument(name: "force", type: nil)
    let unlockKeychainArg = unlockKeychain.asRubyArgument(name: "unlock_keychain", type: nil)
    let addKeychainToSearchListArg = RubyCommand.Argument(name: "add_keychain_to_search_list", value: addKeychainToSearchList, type: nil)
    let setDefaultKeychainArg = setDefaultKeychain.asRubyArgument(name: "set_default_keychain", type: nil)
    let keychainPathArg = keychainPath.asRubyArgument(name: "keychain_path", type: nil)
    let keychainPasswordArg = RubyCommand.Argument(name: "keychain_password", value: keychainPassword, type: nil)
    let setCodeSigningIdentityArg = setCodeSigningIdentity.asRubyArgument(name: "set_code_signing_identity", type: nil)
    let codeSigningIdentityArg = codeSigningIdentity.asRubyArgument(name: "code_signing_identity", type: nil)
    let outputDirectoryArg = RubyCommand.Argument(name: "output_directory", value: outputDirectory, type: nil)
    let derivedDataPathArg = RubyCommand.Argument(name: "derived_data_path", value: derivedDataPath, type: nil)
    let resultBundleArg = resultBundle.asRubyArgument(name: "result_bundle", type: nil)
    let array: [RubyCommand.Argument?] = [forceArg,
                                          unlockKeychainArg,
                                          addKeychainToSearchListArg,
                                          setDefaultKeychainArg,
                                          keychainPathArg,
                                          keychainPasswordArg,
                                          setCodeSigningIdentityArg,
                                          codeSigningIdentityArg,
                                          outputDirectoryArg,
                                          derivedDataPathArg,
                                          resultBundleArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "setup_jenkins", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Setup the keychain and match to work with Travis CI

 - parameter force: Force setup, even if not executed by travis

 - Creates a new temporary keychain for use with match|
 - Switches match to `readonly` mode to not create new profiles/cert on CI|
 >|
 This action helps with Travis integration. Add this to the top of your Fastfile if you use Travis.
 */
public func setupTravis(force: OptionalConfigValue<Bool> = .fastlaneDefault(false)) {
    let forceArg = force.asRubyArgument(name: "force", type: nil)
    let array: [RubyCommand.Argument?] = [forceArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "setup_travis", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Runs a shell command

 - parameters:
   - command: Shell command to be executed
   - log: Determines whether fastlane should print out the executed command itself and output of the executed command. If command line option --troubleshoot is used, then it overrides this option to true
   - errorCallback: A callback invoked with the command output if there is a non-zero exit status

 - returns: Outputs the string and executes it. When running in tests, it returns the actual command instead of executing it

 Allows running an arbitrary shell command.
 Be aware of a specific behavior of `sh` action with regard to the working directory. For details, refer to [Advanced](https://docs.fastlane.tools/advanced/#directory-behavior).
 */
@discardableResult public func sh(command: String,
                                  log: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                                  errorCallback: ((String) -> Void)? = nil) -> String
{
    let commandArg = RubyCommand.Argument(name: "command", value: command, type: nil)
    let logArg = log.asRubyArgument(name: "log", type: nil)
    let errorCallbackArg = RubyCommand.Argument(name: "error_callback", value: errorCallback, type: .stringClosure)
    let array: [RubyCommand.Argument?] = [commandArg,
                                          logArg,
                                          errorCallbackArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "sh", className: nil, args: args)
    return runner.executeCommand(command)
}

/**
 Alias for the `get_provisioning_profile` action

 - parameters:
   - adhoc: Setting this flag will generate AdHoc profiles instead of App Store Profiles
   - developerId: Setting this flag will generate Developer ID profiles instead of App Store Profiles
   - development: Renew the development certificate instead of the production one
   - skipInstall: By default, the certificate will be added to your local machine. Setting this flag will skip this action
   - force: Renew provisioning profiles regardless of its state - to automatically add all devices for ad hoc profiles
   - includeMacInProfiles: Include Apple Silicon Mac devices in provisioning profiles for iOS/iPadOS apps
   - appIdentifier: The bundle identifier of your app
   - apiKeyPath: Path to your App Store Connect API Key JSON file (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-json-file)
   - apiKey: Your App Store Connect API Key information (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-hash-option)
   - username: Your Apple ID Username
   - teamId: The ID of your Developer Portal team if you're in multiple teams
   - teamName: The name of your Developer Portal team if you're in multiple teams
   - provisioningName: The name of the profile that is used on the Apple Developer Portal
   - ignoreProfilesWithDifferentName: Use in combination with :provisioning_name - when true only profiles matching this exact name will be downloaded
   - outputPath: Directory in which the profile should be stored
   - certId: The ID of the code signing certificate to use (e.g. 78ADL6LVAA)
   - certOwnerName: The certificate name to use for new profiles, or to renew with. (e.g. "Felix Krause")
   - filename: Filename to use for the generated provisioning profile (must include .mobileprovision)
   - skipFetchProfiles: Skips the verification of existing profiles which is useful if you have thousands of profiles
   - includeAllCertificates: Include all matching certificates in the provisioning profile. Works only for the 'development' provisioning profile type
   - skipCertificateVerification: Skips the verification of the certificates for every existing profiles. This will make sure the provisioning profile can be used on the local machine
   - platform: Set the provisioning profile's platform (i.e. ios, tvos, macos, catalyst)
   - readonly: Only fetch existing profile, don't generate new ones
   - templateName: The name of provisioning profile template. If the developer account has provisioning profile templates (aka: custom entitlements), the template name can be found by inspecting the Entitlements drop-down while creating/editing a provisioning profile (e.g. "Apple Pay Pass Suppression Development")
   - failOnNameTaken: Should the command fail if it was about to create a duplicate of an existing provisioning profile. It can happen due to issues on Apple Developer Portal, when profile to be recreated was not properly deleted first
   - cachedCertificates: A list of cached certificates
   - cachedDevices: A list of cached devices
   - cachedBundleIds: A list of cached bundle ids
   - cachedProfiles: A list of cached bundle ids

 - returns: The UUID of the profile sigh just fetched/generated

 **Note**: It is recommended to use [match](https://docs.fastlane.tools/actions/match/) according to the [codesigning.guide](https://codesigning.guide) for generating and maintaining your provisioning profiles. Use _sigh_ directly only if you want full control over what's going on and know more about codesigning.
 */
@discardableResult public func sigh(adhoc: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                    developerId: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                    development: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                    skipInstall: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                    force: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                    includeMacInProfiles: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                    appIdentifier: String,
                                    apiKeyPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                    apiKey: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                                    username: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                    teamId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                    teamName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                    provisioningName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                    ignoreProfilesWithDifferentName: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                    outputPath: String = ".",
                                    certId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                    certOwnerName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                    filename: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                    skipFetchProfiles: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                    includeAllCertificates: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                    skipCertificateVerification: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                    platform: Any = "ios",
                                    readonly: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                    templateName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                    failOnNameTaken: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                    cachedCertificates: Any? = nil,
                                    cachedDevices: Any? = nil,
                                    cachedBundleIds: Any? = nil,
                                    cachedProfiles: Any? = nil) -> String
{
    let adhocArg = adhoc.asRubyArgument(name: "adhoc", type: nil)
    let developerIdArg = developerId.asRubyArgument(name: "developer_id", type: nil)
    let developmentArg = development.asRubyArgument(name: "development", type: nil)
    let skipInstallArg = skipInstall.asRubyArgument(name: "skip_install", type: nil)
    let forceArg = force.asRubyArgument(name: "force", type: nil)
    let includeMacInProfilesArg = includeMacInProfiles.asRubyArgument(name: "include_mac_in_profiles", type: nil)
    let appIdentifierArg = RubyCommand.Argument(name: "app_identifier", value: appIdentifier, type: nil)
    let apiKeyPathArg = apiKeyPath.asRubyArgument(name: "api_key_path", type: nil)
    let apiKeyArg = apiKey.asRubyArgument(name: "api_key", type: nil)
    let usernameArg = username.asRubyArgument(name: "username", type: nil)
    let teamIdArg = teamId.asRubyArgument(name: "team_id", type: nil)
    let teamNameArg = teamName.asRubyArgument(name: "team_name", type: nil)
    let provisioningNameArg = provisioningName.asRubyArgument(name: "provisioning_name", type: nil)
    let ignoreProfilesWithDifferentNameArg = ignoreProfilesWithDifferentName.asRubyArgument(name: "ignore_profiles_with_different_name", type: nil)
    let outputPathArg = RubyCommand.Argument(name: "output_path", value: outputPath, type: nil)
    let certIdArg = certId.asRubyArgument(name: "cert_id", type: nil)
    let certOwnerNameArg = certOwnerName.asRubyArgument(name: "cert_owner_name", type: nil)
    let filenameArg = filename.asRubyArgument(name: "filename", type: nil)
    let skipFetchProfilesArg = skipFetchProfiles.asRubyArgument(name: "skip_fetch_profiles", type: nil)
    let includeAllCertificatesArg = includeAllCertificates.asRubyArgument(name: "include_all_certificates", type: nil)
    let skipCertificateVerificationArg = skipCertificateVerification.asRubyArgument(name: "skip_certificate_verification", type: nil)
    let platformArg = RubyCommand.Argument(name: "platform", value: platform, type: nil)
    let readonlyArg = readonly.asRubyArgument(name: "readonly", type: nil)
    let templateNameArg = templateName.asRubyArgument(name: "template_name", type: nil)
    let failOnNameTakenArg = failOnNameTaken.asRubyArgument(name: "fail_on_name_taken", type: nil)
    let cachedCertificatesArg = RubyCommand.Argument(name: "cached_certificates", value: cachedCertificates, type: nil)
    let cachedDevicesArg = RubyCommand.Argument(name: "cached_devices", value: cachedDevices, type: nil)
    let cachedBundleIdsArg = RubyCommand.Argument(name: "cached_bundle_ids", value: cachedBundleIds, type: nil)
    let cachedProfilesArg = RubyCommand.Argument(name: "cached_profiles", value: cachedProfiles, type: nil)
    let array: [RubyCommand.Argument?] = [adhocArg,
                                          developerIdArg,
                                          developmentArg,
                                          skipInstallArg,
                                          forceArg,
                                          includeMacInProfilesArg,
                                          appIdentifierArg,
                                          apiKeyPathArg,
                                          apiKeyArg,
                                          usernameArg,
                                          teamIdArg,
                                          teamNameArg,
                                          provisioningNameArg,
                                          ignoreProfilesWithDifferentNameArg,
                                          outputPathArg,
                                          certIdArg,
                                          certOwnerNameArg,
                                          filenameArg,
                                          skipFetchProfilesArg,
                                          includeAllCertificatesArg,
                                          skipCertificateVerificationArg,
                                          platformArg,
                                          readonlyArg,
                                          templateNameArg,
                                          failOnNameTakenArg,
                                          cachedCertificatesArg,
                                          cachedDevicesArg,
                                          cachedBundleIdsArg,
                                          cachedProfilesArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "sigh", className: nil, args: args)
    return runner.executeCommand(command)
}

/**
 Skip the creation of the fastlane/README.md file when running fastlane

 Tell _fastlane_ to not automatically create a `fastlane/README.md` when running _fastlane_. You can always trigger the creation of this file manually by running `fastlane docs`.
 */
public func skipDocs() {
    let args: [RubyCommand.Argument] = []
    let command = RubyCommand(commandID: "", methodName: "skip_docs", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Send a success/error message to your [Slack](https://slack.com) group

 - parameters:
   - message: The message that should be displayed on Slack. This supports the standard Slack markup language
   - pretext: This is optional text that appears above the message attachment block. This supports the standard Slack markup language
   - channel: #channel or @username
   - useWebhookConfiguredUsernameAndIcon: Use webhook's default username and icon settings? (true/false)
   - slackUrl: Create an Incoming WebHook for your Slack group
   - username: Overrides the webhook's username property if use_webhook_configured_username_and_icon is false
   - iconUrl: Specifies a URL of an image to use as the photo of the message. Overrides the webhook's image property if use_webhook_configured_username_and_icon is false
   - iconEmoji: Specifies an emoji (using colon shortcodes, eg. :white_check_mark:) to use as the photo of the message. Overrides the webhook's image property if use_webhook_configured_username_and_icon is false. This parameter takes precedence over icon_url
   - payload: Add additional information to this post. payload must be a hash containing any key with any value
   - defaultPayloads: Specifies default payloads to include. Pass an empty array to suppress all the default payloads
   - attachmentProperties: Merge additional properties in the slack attachment, see https://api.slack.com/docs/attachments
   - success: Was this build successful? (true/false)
   - failOnError: Should an error sending the slack notification cause a failure? (true/false)
   - linkNames: Find and link channel names and usernames (true/false)

 Create an Incoming WebHook and export this as `SLACK_URL`. Can send a message to **#channel** (by default), a direct message to **@username** or a message to a private group **group** with success (green) or failure (red) status.
 */
public func slack(message: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  pretext: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  channel: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  useWebhookConfiguredUsernameAndIcon: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                  slackUrl: String,
                  username: String = "fastlane",
                  iconUrl: String = "https://fastlane.tools/assets/img/fastlane_icon.png",
                  iconEmoji: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  payload: [String: Any] = [:],
                  defaultPayloads: [String] = ["lane", "test_result", "git_branch", "git_author", "last_git_commit", "last_git_commit_hash"],
                  attachmentProperties: [String: Any] = [:],
                  success: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                  failOnError: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                  linkNames: OptionalConfigValue<Bool> = .fastlaneDefault(false))
{
    let messageArg = message.asRubyArgument(name: "message", type: nil)
    let pretextArg = pretext.asRubyArgument(name: "pretext", type: nil)
    let channelArg = channel.asRubyArgument(name: "channel", type: nil)
    let useWebhookConfiguredUsernameAndIconArg = useWebhookConfiguredUsernameAndIcon.asRubyArgument(name: "use_webhook_configured_username_and_icon", type: nil)
    let slackUrlArg = RubyCommand.Argument(name: "slack_url", value: slackUrl, type: nil)
    let usernameArg = RubyCommand.Argument(name: "username", value: username, type: nil)
    let iconUrlArg = RubyCommand.Argument(name: "icon_url", value: iconUrl, type: nil)
    let iconEmojiArg = iconEmoji.asRubyArgument(name: "icon_emoji", type: nil)
    let payloadArg = RubyCommand.Argument(name: "payload", value: payload, type: nil)
    let defaultPayloadsArg = RubyCommand.Argument(name: "default_payloads", value: defaultPayloads, type: nil)
    let attachmentPropertiesArg = RubyCommand.Argument(name: "attachment_properties", value: attachmentProperties, type: nil)
    let successArg = success.asRubyArgument(name: "success", type: nil)
    let failOnErrorArg = failOnError.asRubyArgument(name: "fail_on_error", type: nil)
    let linkNamesArg = linkNames.asRubyArgument(name: "link_names", type: nil)
    let array: [RubyCommand.Argument?] = [messageArg,
                                          pretextArg,
                                          channelArg,
                                          useWebhookConfiguredUsernameAndIconArg,
                                          slackUrlArg,
                                          usernameArg,
                                          iconUrlArg,
                                          iconEmojiArg,
                                          payloadArg,
                                          defaultPayloadsArg,
                                          attachmentPropertiesArg,
                                          successArg,
                                          failOnErrorArg,
                                          linkNamesArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "slack", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Show a train of the fastlane progress

 - returns: A string that is being sent to slack
 */
public func slackTrain() {
    let args: [RubyCommand.Argument] = []
    let command = RubyCommand(commandID: "", methodName: "slack_train", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**

 */
public func slackTrainCrash() {
    let args: [RubyCommand.Argument] = []
    let command = RubyCommand(commandID: "", methodName: "slack_train_crash", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Show a train of the fastlane progress

 - parameters:
   - distance: How many rails do we need?
   - train: Train emoji
   - rail: Character or emoji for the rail
   - reverseDirection: Pass true if you want the train to go from left to right
 */
public func slackTrainStart(distance: Int = 5,
                            train: String = "🚝",
                            rail: String = "=",
                            reverseDirection: OptionalConfigValue<Bool> = .fastlaneDefault(false))
{
    let distanceArg = RubyCommand.Argument(name: "distance", value: distance, type: nil)
    let trainArg = RubyCommand.Argument(name: "train", value: train, type: nil)
    let railArg = RubyCommand.Argument(name: "rail", value: rail, type: nil)
    let reverseDirectionArg = reverseDirection.asRubyArgument(name: "reverse_direction", type: nil)
    let array: [RubyCommand.Argument?] = [distanceArg,
                                          trainArg,
                                          railArg,
                                          reverseDirectionArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "slack_train_start", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Use slather to generate a code coverage report

 - parameters:
   - buildDirectory: The location of the build output
   - proj: The project file that slather looks at
   - workspace: The workspace that slather looks at
   - scheme: Scheme to use when calling slather
   - configuration: Configuration to use when calling slather (since slather-2.4.1)
   - inputFormat: The input format that slather should look for
   - github: Tell slather that it is running on GitHub Actions
   - buildkite: Tell slather that it is running on Buildkite
   - teamcity: Tell slather that it is running on TeamCity
   - jenkins: Tell slather that it is running on Jenkins
   - travis: Tell slather that it is running on TravisCI
   - travisPro: Tell slather that it is running on TravisCI Pro
   - circleci: Tell slather that it is running on CircleCI
   - coveralls: Tell slather that it should post data to Coveralls
   - simpleOutput: Tell slather that it should output results to the terminal
   - gutterJson: Tell slather that it should output results as Gutter JSON format
   - coberturaXml: Tell slather that it should output results as Cobertura XML format
   - sonarqubeXml: Tell slather that it should output results as SonarQube Generic XML format
   - llvmCov: Tell slather that it should output results as llvm-cov show format
   - json: Tell slather that it should output results as static JSON report
   - html: Tell slather that it should output results as static HTML pages
   - show: Tell slather that it should open static html pages automatically
   - sourceDirectory: Tell slather the location of your source files
   - outputDirectory: Tell slather the location of for your output files
   - ignore: Tell slather to ignore files matching a path or any path from an array of paths
   - verbose: Tell slather to enable verbose mode
   - useBundleExec: Use bundle exec to execute slather. Make sure it is in the Gemfile
   - binaryBasename: Basename of the binary file, this should match the name of your bundle excluding its extension (i.e. YourApp [for YourApp.app bundle])
   - binaryFile: Binary file name to be used for code coverage
   - arch: Specify which architecture the binary file is in. Needed for universal binaries
   - sourceFiles: A Dir.glob compatible pattern used to limit the lookup to specific source files. Ignored in gcov mode
   - decimals: The amount of decimals to use for % coverage reporting
   - ymlfile: Relative path to a file used in place of '.slather.yml'

 Slather works with multiple code coverage formats, including Xcode 7 code coverage.
 Slather is available at [https://github.com/SlatherOrg/slather](https://github.com/SlatherOrg/slather).
 */
public func slather(buildDirectory: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                    proj: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                    workspace: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                    scheme: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                    configuration: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                    inputFormat: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                    github: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                    buildkite: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                    teamcity: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                    jenkins: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                    travis: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                    travisPro: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                    circleci: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                    coveralls: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                    simpleOutput: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                    gutterJson: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                    coberturaXml: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                    sonarqubeXml: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                    llvmCov: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                    json: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                    html: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                    show: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                    sourceDirectory: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                    outputDirectory: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                    ignore: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                    verbose: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                    useBundleExec: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                    binaryBasename: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                    binaryFile: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                    arch: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                    sourceFiles: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                    decimals: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                    ymlfile: OptionalConfigValue<String?> = .fastlaneDefault(nil))
{
    let buildDirectoryArg = buildDirectory.asRubyArgument(name: "build_directory", type: nil)
    let projArg = proj.asRubyArgument(name: "proj", type: nil)
    let workspaceArg = workspace.asRubyArgument(name: "workspace", type: nil)
    let schemeArg = scheme.asRubyArgument(name: "scheme", type: nil)
    let configurationArg = configuration.asRubyArgument(name: "configuration", type: nil)
    let inputFormatArg = inputFormat.asRubyArgument(name: "input_format", type: nil)
    let githubArg = github.asRubyArgument(name: "github", type: nil)
    let buildkiteArg = buildkite.asRubyArgument(name: "buildkite", type: nil)
    let teamcityArg = teamcity.asRubyArgument(name: "teamcity", type: nil)
    let jenkinsArg = jenkins.asRubyArgument(name: "jenkins", type: nil)
    let travisArg = travis.asRubyArgument(name: "travis", type: nil)
    let travisProArg = travisPro.asRubyArgument(name: "travis_pro", type: nil)
    let circleciArg = circleci.asRubyArgument(name: "circleci", type: nil)
    let coverallsArg = coveralls.asRubyArgument(name: "coveralls", type: nil)
    let simpleOutputArg = simpleOutput.asRubyArgument(name: "simple_output", type: nil)
    let gutterJsonArg = gutterJson.asRubyArgument(name: "gutter_json", type: nil)
    let coberturaXmlArg = coberturaXml.asRubyArgument(name: "cobertura_xml", type: nil)
    let sonarqubeXmlArg = sonarqubeXml.asRubyArgument(name: "sonarqube_xml", type: nil)
    let llvmCovArg = llvmCov.asRubyArgument(name: "llvm_cov", type: nil)
    let jsonArg = json.asRubyArgument(name: "json", type: nil)
    let htmlArg = html.asRubyArgument(name: "html", type: nil)
    let showArg = show.asRubyArgument(name: "show", type: nil)
    let sourceDirectoryArg = sourceDirectory.asRubyArgument(name: "source_directory", type: nil)
    let outputDirectoryArg = outputDirectory.asRubyArgument(name: "output_directory", type: nil)
    let ignoreArg = ignore.asRubyArgument(name: "ignore", type: nil)
    let verboseArg = verbose.asRubyArgument(name: "verbose", type: nil)
    let useBundleExecArg = useBundleExec.asRubyArgument(name: "use_bundle_exec", type: nil)
    let binaryBasenameArg = binaryBasename.asRubyArgument(name: "binary_basename", type: nil)
    let binaryFileArg = binaryFile.asRubyArgument(name: "binary_file", type: nil)
    let archArg = arch.asRubyArgument(name: "arch", type: nil)
    let sourceFilesArg = sourceFiles.asRubyArgument(name: "source_files", type: nil)
    let decimalsArg = decimals.asRubyArgument(name: "decimals", type: nil)
    let ymlfileArg = ymlfile.asRubyArgument(name: "ymlfile", type: nil)
    let array: [RubyCommand.Argument?] = [buildDirectoryArg,
                                          projArg,
                                          workspaceArg,
                                          schemeArg,
                                          configurationArg,
                                          inputFormatArg,
                                          githubArg,
                                          buildkiteArg,
                                          teamcityArg,
                                          jenkinsArg,
                                          travisArg,
                                          travisProArg,
                                          circleciArg,
                                          coverallsArg,
                                          simpleOutputArg,
                                          gutterJsonArg,
                                          coberturaXmlArg,
                                          sonarqubeXmlArg,
                                          llvmCovArg,
                                          jsonArg,
                                          htmlArg,
                                          showArg,
                                          sourceDirectoryArg,
                                          outputDirectoryArg,
                                          ignoreArg,
                                          verboseArg,
                                          useBundleExecArg,
                                          binaryBasenameArg,
                                          binaryFileArg,
                                          archArg,
                                          sourceFilesArg,
                                          decimalsArg,
                                          ymlfileArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "slather", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Alias for the `capture_ios_screenshots` action

 - parameters:
   - workspace: Path to the workspace file
   - project: Path to the project file
   - xcargs: Pass additional arguments to xcodebuild for the test phase. Be sure to quote the setting names and values e.g. OTHER_LDFLAGS="-ObjC -lstdc++"
   - xcconfig: Use an extra XCCONFIG file to build your app
   - devices: A list of devices you want to take the screenshots from
   - languages: A list of languages which should be used
   - launchArguments: A list of launch arguments which should be used
   - outputDirectory: The directory where to store the screenshots
   - outputSimulatorLogs: If the logs generated by the app (e.g. using NSLog, perror, etc.) in the Simulator should be written to the output_directory
   - iosVersion: By default, the latest version should be used automatically. If you want to change it, do it here
   - skipOpenSummary: Don't open the HTML summary after running _snapshot_
   - skipHelperVersionCheck: Do not check for most recent SnapshotHelper code
   - clearPreviousScreenshots: Enabling this option will automatically clear previously generated screenshots before running snapshot
   - reinstallApp: Enabling this option will automatically uninstall the application before running it
   - eraseSimulator: Enabling this option will automatically erase the simulator before running the application
   - headless: Enabling this option will prevent displaying the simulator window
   - overrideStatusBar: Enabling this option will automatically override the status bar to show 9:41 AM, full battery, and full reception (Adjust 'SNAPSHOT_SIMULATOR_WAIT_FOR_BOOT_TIMEOUT' environment variable if override status bar is not working. Might be because simulator is not fully booted. Defaults to 10 seconds)
   - overrideStatusBarArguments: Fully customize the status bar by setting each option here. Requires `override_status_bar` to be set to `true`. See `xcrun simctl status_bar --help`
   - localizeSimulator: Enabling this option will configure the Simulator's system language
   - darkMode: Enabling this option will configure the Simulator to be in dark mode (false for light, true for dark)
   - appIdentifier: The bundle identifier of the app to uninstall (only needed when enabling reinstall_app)
   - addPhotos: A list of photos that should be added to the simulator before running the application
   - addVideos: A list of videos that should be added to the simulator before running the application
   - htmlTemplate: A path to screenshots.html template
   - buildlogPath: The directory where to store the build log
   - clean: Should the project be cleaned before building it?
   - testWithoutBuilding: Test without building, requires a derived data path
   - configuration: The configuration to use when building the app. Defaults to 'Release'
   - sdk: The SDK that should be used for building the application
   - scheme: The scheme you want to use, this must be the scheme for the UI Tests
   - numberOfRetries: The number of times a test can fail before snapshot should stop retrying
   - stopAfterFirstError: Should snapshot stop immediately after the tests completely failed on one device?
   - derivedDataPath: The directory where build products and other derived data will go
   - resultBundle: Should an Xcode result bundle be generated in the output directory
   - testTargetName: The name of the target you want to test (if you desire to override the Target Application from Xcode)
   - namespaceLogFiles: Separate the log files per device and per language
   - concurrentSimulators: Take snapshots on multiple simulators concurrently. Note: This option is only applicable when running against Xcode 9
   - disableSlideToType: Disable the simulator from showing the 'Slide to type' prompt
   - clonedSourcePackagesPath: Sets a custom path for Swift Package Manager dependencies
   - skipPackageDependenciesResolution: Skips resolution of Swift Package Manager dependencies
   - disablePackageAutomaticUpdates: Prevents packages from automatically being resolved to versions other than those recorded in the `Package.resolved` file
   - packageAuthorizationProvider: Lets xcodebuild use a specified package authorization provider (keychain|netrc)
   - testplan: The testplan associated with the scheme that should be used for testing
   - onlyTesting: Array of strings matching Test Bundle/Test Suite/Test Cases to run
   - skipTesting: Array of strings matching Test Bundle/Test Suite/Test Cases to skip
   - xcodebuildFormatter: xcodebuild formatter to use (ex: 'xcbeautify', 'xcbeautify --quieter', 'xcpretty', 'xcpretty -test'). Use empty string (ex: '') to disable any formatter (More information: https://docs.fastlane.tools/best-practices/xcodebuild-formatters/)
   - xcprettyArgs: **DEPRECATED!** Use `xcodebuild_formatter: ''` instead - Additional xcpretty arguments
   - disableXcpretty: Disable xcpretty formatting of build
   - suppressXcodeOutput: Suppress the output of xcodebuild to stdout. Output is still saved in buildlog_path
   - useSystemScm: Lets xcodebuild use system's scm configuration
 */
public func snapshot(workspace: OptionalConfigValue<String?> = .fastlaneDefault(snapshotfile.workspace),
                     project: OptionalConfigValue<String?> = .fastlaneDefault(snapshotfile.project),
                     xcargs: OptionalConfigValue<String?> = .fastlaneDefault(snapshotfile.xcargs),
                     xcconfig: OptionalConfigValue<String?> = .fastlaneDefault(snapshotfile.xcconfig),
                     devices: OptionalConfigValue<[String]?> = .fastlaneDefault(snapshotfile.devices),
                     languages: [String] = snapshotfile.languages,
                     launchArguments: [String] = snapshotfile.launchArguments,
                     outputDirectory: String = snapshotfile.outputDirectory,
                     outputSimulatorLogs: OptionalConfigValue<Bool> = .fastlaneDefault(snapshotfile.outputSimulatorLogs),
                     iosVersion: OptionalConfigValue<String?> = .fastlaneDefault(snapshotfile.iosVersion),
                     skipOpenSummary: OptionalConfigValue<Bool> = .fastlaneDefault(snapshotfile.skipOpenSummary),
                     skipHelperVersionCheck: OptionalConfigValue<Bool> = .fastlaneDefault(snapshotfile.skipHelperVersionCheck),
                     clearPreviousScreenshots: OptionalConfigValue<Bool> = .fastlaneDefault(snapshotfile.clearPreviousScreenshots),
                     reinstallApp: OptionalConfigValue<Bool> = .fastlaneDefault(snapshotfile.reinstallApp),
                     eraseSimulator: OptionalConfigValue<Bool> = .fastlaneDefault(snapshotfile.eraseSimulator),
                     headless: OptionalConfigValue<Bool> = .fastlaneDefault(snapshotfile.headless),
                     overrideStatusBar: OptionalConfigValue<Bool> = .fastlaneDefault(snapshotfile.overrideStatusBar),
                     overrideStatusBarArguments: OptionalConfigValue<String?> = .fastlaneDefault(snapshotfile.overrideStatusBarArguments),
                     localizeSimulator: OptionalConfigValue<Bool> = .fastlaneDefault(snapshotfile.localizeSimulator),
                     darkMode: OptionalConfigValue<Bool?> = .fastlaneDefault(snapshotfile.darkMode),
                     appIdentifier: OptionalConfigValue<String?> = .fastlaneDefault(snapshotfile.appIdentifier),
                     addPhotos: OptionalConfigValue<[String]?> = .fastlaneDefault(snapshotfile.addPhotos),
                     addVideos: OptionalConfigValue<[String]?> = .fastlaneDefault(snapshotfile.addVideos),
                     htmlTemplate: OptionalConfigValue<String?> = .fastlaneDefault(snapshotfile.htmlTemplate),
                     buildlogPath: String = snapshotfile.buildlogPath,
                     clean: OptionalConfigValue<Bool> = .fastlaneDefault(snapshotfile.clean),
                     testWithoutBuilding: OptionalConfigValue<Bool?> = .fastlaneDefault(snapshotfile.testWithoutBuilding),
                     configuration: OptionalConfigValue<String?> = .fastlaneDefault(snapshotfile.configuration),
                     sdk: OptionalConfigValue<String?> = .fastlaneDefault(snapshotfile.sdk),
                     scheme: OptionalConfigValue<String?> = .fastlaneDefault(snapshotfile.scheme),
                     numberOfRetries: Int = snapshotfile.numberOfRetries,
                     stopAfterFirstError: OptionalConfigValue<Bool> = .fastlaneDefault(snapshotfile.stopAfterFirstError),
                     derivedDataPath: OptionalConfigValue<String?> = .fastlaneDefault(snapshotfile.derivedDataPath),
                     resultBundle: OptionalConfigValue<Bool> = .fastlaneDefault(snapshotfile.resultBundle),
                     testTargetName: OptionalConfigValue<String?> = .fastlaneDefault(snapshotfile.testTargetName),
                     namespaceLogFiles: Any? = snapshotfile.namespaceLogFiles,
                     concurrentSimulators: OptionalConfigValue<Bool> = .fastlaneDefault(snapshotfile.concurrentSimulators),
                     disableSlideToType: OptionalConfigValue<Bool> = .fastlaneDefault(snapshotfile.disableSlideToType),
                     clonedSourcePackagesPath: OptionalConfigValue<String?> = .fastlaneDefault(snapshotfile.clonedSourcePackagesPath),
                     skipPackageDependenciesResolution: OptionalConfigValue<Bool> = .fastlaneDefault(snapshotfile.skipPackageDependenciesResolution),
                     disablePackageAutomaticUpdates: OptionalConfigValue<Bool> = .fastlaneDefault(snapshotfile.disablePackageAutomaticUpdates),
                     packageAuthorizationProvider: OptionalConfigValue<String?> = .fastlaneDefault(snapshotfile.packageAuthorizationProvider),
                     testplan: OptionalConfigValue<String?> = .fastlaneDefault(snapshotfile.testplan),
                     onlyTesting: Any? = snapshotfile.onlyTesting,
                     skipTesting: Any? = snapshotfile.skipTesting,
                     xcodebuildFormatter: String = snapshotfile.xcodebuildFormatter,
                     xcprettyArgs: OptionalConfigValue<String?> = .fastlaneDefault(snapshotfile.xcprettyArgs),
                     disableXcpretty: OptionalConfigValue<Bool?> = .fastlaneDefault(snapshotfile.disableXcpretty),
                     suppressXcodeOutput: OptionalConfigValue<Bool?> = .fastlaneDefault(snapshotfile.suppressXcodeOutput),
                     useSystemScm: OptionalConfigValue<Bool> = .fastlaneDefault(snapshotfile.useSystemScm))
{
    let workspaceArg = workspace.asRubyArgument(name: "workspace", type: nil)
    let projectArg = project.asRubyArgument(name: "project", type: nil)
    let xcargsArg = xcargs.asRubyArgument(name: "xcargs", type: nil)
    let xcconfigArg = xcconfig.asRubyArgument(name: "xcconfig", type: nil)
    let devicesArg = devices.asRubyArgument(name: "devices", type: nil)
    let languagesArg = RubyCommand.Argument(name: "languages", value: languages, type: nil)
    let launchArgumentsArg = RubyCommand.Argument(name: "launch_arguments", value: launchArguments, type: nil)
    let outputDirectoryArg = RubyCommand.Argument(name: "output_directory", value: outputDirectory, type: nil)
    let outputSimulatorLogsArg = outputSimulatorLogs.asRubyArgument(name: "output_simulator_logs", type: nil)
    let iosVersionArg = iosVersion.asRubyArgument(name: "ios_version", type: nil)
    let skipOpenSummaryArg = skipOpenSummary.asRubyArgument(name: "skip_open_summary", type: nil)
    let skipHelperVersionCheckArg = skipHelperVersionCheck.asRubyArgument(name: "skip_helper_version_check", type: nil)
    let clearPreviousScreenshotsArg = clearPreviousScreenshots.asRubyArgument(name: "clear_previous_screenshots", type: nil)
    let reinstallAppArg = reinstallApp.asRubyArgument(name: "reinstall_app", type: nil)
    let eraseSimulatorArg = eraseSimulator.asRubyArgument(name: "erase_simulator", type: nil)
    let headlessArg = headless.asRubyArgument(name: "headless", type: nil)
    let overrideStatusBarArg = overrideStatusBar.asRubyArgument(name: "override_status_bar", type: nil)
    let overrideStatusBarArgumentsArg = overrideStatusBarArguments.asRubyArgument(name: "override_status_bar_arguments", type: nil)
    let localizeSimulatorArg = localizeSimulator.asRubyArgument(name: "localize_simulator", type: nil)
    let darkModeArg = darkMode.asRubyArgument(name: "dark_mode", type: nil)
    let appIdentifierArg = appIdentifier.asRubyArgument(name: "app_identifier", type: nil)
    let addPhotosArg = addPhotos.asRubyArgument(name: "add_photos", type: nil)
    let addVideosArg = addVideos.asRubyArgument(name: "add_videos", type: nil)
    let htmlTemplateArg = htmlTemplate.asRubyArgument(name: "html_template", type: nil)
    let buildlogPathArg = RubyCommand.Argument(name: "buildlog_path", value: buildlogPath, type: nil)
    let cleanArg = clean.asRubyArgument(name: "clean", type: nil)
    let testWithoutBuildingArg = testWithoutBuilding.asRubyArgument(name: "test_without_building", type: nil)
    let configurationArg = configuration.asRubyArgument(name: "configuration", type: nil)
    let sdkArg = sdk.asRubyArgument(name: "sdk", type: nil)
    let schemeArg = scheme.asRubyArgument(name: "scheme", type: nil)
    let numberOfRetriesArg = RubyCommand.Argument(name: "number_of_retries", value: numberOfRetries, type: nil)
    let stopAfterFirstErrorArg = stopAfterFirstError.asRubyArgument(name: "stop_after_first_error", type: nil)
    let derivedDataPathArg = derivedDataPath.asRubyArgument(name: "derived_data_path", type: nil)
    let resultBundleArg = resultBundle.asRubyArgument(name: "result_bundle", type: nil)
    let testTargetNameArg = testTargetName.asRubyArgument(name: "test_target_name", type: nil)
    let namespaceLogFilesArg = RubyCommand.Argument(name: "namespace_log_files", value: namespaceLogFiles, type: nil)
    let concurrentSimulatorsArg = concurrentSimulators.asRubyArgument(name: "concurrent_simulators", type: nil)
    let disableSlideToTypeArg = disableSlideToType.asRubyArgument(name: "disable_slide_to_type", type: nil)
    let clonedSourcePackagesPathArg = clonedSourcePackagesPath.asRubyArgument(name: "cloned_source_packages_path", type: nil)
    let skipPackageDependenciesResolutionArg = skipPackageDependenciesResolution.asRubyArgument(name: "skip_package_dependencies_resolution", type: nil)
    let disablePackageAutomaticUpdatesArg = disablePackageAutomaticUpdates.asRubyArgument(name: "disable_package_automatic_updates", type: nil)
    let packageAuthorizationProviderArg = packageAuthorizationProvider.asRubyArgument(name: "package_authorization_provider", type: nil)
    let testplanArg = testplan.asRubyArgument(name: "testplan", type: nil)
    let onlyTestingArg = RubyCommand.Argument(name: "only_testing", value: onlyTesting, type: nil)
    let skipTestingArg = RubyCommand.Argument(name: "skip_testing", value: skipTesting, type: nil)
    let xcodebuildFormatterArg = RubyCommand.Argument(name: "xcodebuild_formatter", value: xcodebuildFormatter, type: nil)
    let xcprettyArgsArg = xcprettyArgs.asRubyArgument(name: "xcpretty_args", type: nil)
    let disableXcprettyArg = disableXcpretty.asRubyArgument(name: "disable_xcpretty", type: nil)
    let suppressXcodeOutputArg = suppressXcodeOutput.asRubyArgument(name: "suppress_xcode_output", type: nil)
    let useSystemScmArg = useSystemScm.asRubyArgument(name: "use_system_scm", type: nil)
    let array: [RubyCommand.Argument?] = [workspaceArg,
                                          projectArg,
                                          xcargsArg,
                                          xcconfigArg,
                                          devicesArg,
                                          languagesArg,
                                          launchArgumentsArg,
                                          outputDirectoryArg,
                                          outputSimulatorLogsArg,
                                          iosVersionArg,
                                          skipOpenSummaryArg,
                                          skipHelperVersionCheckArg,
                                          clearPreviousScreenshotsArg,
                                          reinstallAppArg,
                                          eraseSimulatorArg,
                                          headlessArg,
                                          overrideStatusBarArg,
                                          overrideStatusBarArgumentsArg,
                                          localizeSimulatorArg,
                                          darkModeArg,
                                          appIdentifierArg,
                                          addPhotosArg,
                                          addVideosArg,
                                          htmlTemplateArg,
                                          buildlogPathArg,
                                          cleanArg,
                                          testWithoutBuildingArg,
                                          configurationArg,
                                          sdkArg,
                                          schemeArg,
                                          numberOfRetriesArg,
                                          stopAfterFirstErrorArg,
                                          derivedDataPathArg,
                                          resultBundleArg,
                                          testTargetNameArg,
                                          namespaceLogFilesArg,
                                          concurrentSimulatorsArg,
                                          disableSlideToTypeArg,
                                          clonedSourcePackagesPathArg,
                                          skipPackageDependenciesResolutionArg,
                                          disablePackageAutomaticUpdatesArg,
                                          packageAuthorizationProviderArg,
                                          testplanArg,
                                          onlyTestingArg,
                                          skipTestingArg,
                                          xcodebuildFormatterArg,
                                          xcprettyArgsArg,
                                          disableXcprettyArg,
                                          suppressXcodeOutputArg,
                                          useSystemScmArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "snapshot", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Invokes sonar-scanner to programmatically run SonarQube analysis

 - parameters:
   - projectConfigurationPath: The path to your sonar project configuration file; defaults to `sonar-project.properties`
   - projectKey: The key sonar uses to identify the project, e.g. `name.gretzki.awesomeApp`. Must either be specified here or inside the sonar project configuration file
   - projectName: The name of the project that gets displayed on the sonar report page. Must either be specified here or inside the sonar project configuration file
   - projectVersion: The project's version that gets displayed on the sonar report page. Must either be specified here or inside the sonar project configuration file
   - sourcesPath: Comma-separated paths to directories containing source files. Must either be specified here or inside the sonar project configuration file
   - exclusions: Comma-separated paths to directories to be excluded from the analysis
   - projectLanguage: Language key, e.g. objc
   - sourceEncoding: Used encoding of source files, e.g., UTF-8
   - sonarRunnerArgs: Pass additional arguments to sonar-scanner. Be sure to provide the arguments with a leading `-D` e.g. FL_SONAR_RUNNER_ARGS="-Dsonar.verbose=true"
   - sonarLogin: **DEPRECATED!** Login and password were deprecated in favor of login token. See https://community.sonarsource.com/t/deprecating-sonar-login-and-sonar-password-in-favor-of-sonar-token/95829 for more details - Pass the Sonar Login Token (e.g: xxxxxxprivate_token_XXXXbXX7e)
   - sonarToken: Pass the Sonar Token (e.g: xxxxxxprivate_token_XXXXbXX7e)
   - sonarUrl: Pass the url of the Sonar server
   - sonarOrganization: Key of the organization on SonarCloud
   - branchName: Pass the branch name which is getting scanned
   - pullRequestBranch: The name of the branch that contains the changes to be merged
   - pullRequestBase: The long-lived branch into which the PR will be merged
   - pullRequestKey: Unique identifier of your PR. Must correspond to the key of the PR in GitHub or TFS

 - returns: The exit code of the sonar-scanner binary

 See [http://docs.sonarqube.org/display/SCAN/Analyzing+with+SonarQube+Scanner](http://docs.sonarqube.org/display/SCAN/Analyzing+with+SonarQube+Scanner) for details.
 It can process unit test results if formatted as junit report as shown in [xctest](https://docs.fastlane.tools/actions/xctest/) action. It can also integrate coverage reports in Cobertura format, which can be transformed into by the [slather](https://docs.fastlane.tools/actions/slather/) action.
 */
public func sonar(projectConfigurationPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  projectKey: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  projectName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  projectVersion: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  sourcesPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  exclusions: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  projectLanguage: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  sourceEncoding: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  sonarRunnerArgs: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  sonarLogin: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  sonarToken: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  sonarUrl: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  sonarOrganization: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  branchName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  pullRequestBranch: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  pullRequestBase: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                  pullRequestKey: OptionalConfigValue<String?> = .fastlaneDefault(nil))
{
    let projectConfigurationPathArg = projectConfigurationPath.asRubyArgument(name: "project_configuration_path", type: nil)
    let projectKeyArg = projectKey.asRubyArgument(name: "project_key", type: nil)
    let projectNameArg = projectName.asRubyArgument(name: "project_name", type: nil)
    let projectVersionArg = projectVersion.asRubyArgument(name: "project_version", type: nil)
    let sourcesPathArg = sourcesPath.asRubyArgument(name: "sources_path", type: nil)
    let exclusionsArg = exclusions.asRubyArgument(name: "exclusions", type: nil)
    let projectLanguageArg = projectLanguage.asRubyArgument(name: "project_language", type: nil)
    let sourceEncodingArg = sourceEncoding.asRubyArgument(name: "source_encoding", type: nil)
    let sonarRunnerArgsArg = sonarRunnerArgs.asRubyArgument(name: "sonar_runner_args", type: nil)
    let sonarLoginArg = sonarLogin.asRubyArgument(name: "sonar_login", type: nil)
    let sonarTokenArg = sonarToken.asRubyArgument(name: "sonar_token", type: nil)
    let sonarUrlArg = sonarUrl.asRubyArgument(name: "sonar_url", type: nil)
    let sonarOrganizationArg = sonarOrganization.asRubyArgument(name: "sonar_organization", type: nil)
    let branchNameArg = branchName.asRubyArgument(name: "branch_name", type: nil)
    let pullRequestBranchArg = pullRequestBranch.asRubyArgument(name: "pull_request_branch", type: nil)
    let pullRequestBaseArg = pullRequestBase.asRubyArgument(name: "pull_request_base", type: nil)
    let pullRequestKeyArg = pullRequestKey.asRubyArgument(name: "pull_request_key", type: nil)
    let array: [RubyCommand.Argument?] = [projectConfigurationPathArg,
                                          projectKeyArg,
                                          projectNameArg,
                                          projectVersionArg,
                                          sourcesPathArg,
                                          exclusionsArg,
                                          projectLanguageArg,
                                          sourceEncodingArg,
                                          sonarRunnerArgsArg,
                                          sonarLoginArg,
                                          sonarTokenArg,
                                          sonarUrlArg,
                                          sonarOrganizationArg,
                                          branchNameArg,
                                          pullRequestBranchArg,
                                          pullRequestBaseArg,
                                          pullRequestKeyArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "sonar", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Generate docs using SourceDocs

 - parameters:
   - allModules: Generate documentation for all modules in a Swift package
   - spmModule: Generate documentation for Swift Package Manager module
   - moduleName: Generate documentation for a Swift module
   - linkBeginning: The text to begin links with
   - linkEnding: The text to end links with (default: .md)
   - outputFolder: Output directory to clean (default: Documentation/Reference)
   - minAcl: Access level to include in documentation [private, fileprivate, internal, public, open] (default: public)
   - moduleNamePath: Include the module name as part of the output folder path
   - clean: Delete output folder before generating documentation
   - collapsible: Put methods, properties and enum cases inside collapsible blocks
   - tableOfContents: Generate a table of contents with properties and methods for each type
   - reproducible: Generate documentation that is reproducible: only depends on the sources
   - scheme: Create documentation for specific scheme
   - sdkPlatform: Create documentation for specific sdk platform
 */
public func sourcedocs(allModules: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                       spmModule: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                       moduleName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                       linkBeginning: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                       linkEnding: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                       outputFolder: String,
                       minAcl: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                       moduleNamePath: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                       clean: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                       collapsible: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                       tableOfContents: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                       reproducible: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                       scheme: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                       sdkPlatform: OptionalConfigValue<String?> = .fastlaneDefault(nil))
{
    let allModulesArg = allModules.asRubyArgument(name: "all_modules", type: nil)
    let spmModuleArg = spmModule.asRubyArgument(name: "spm_module", type: nil)
    let moduleNameArg = moduleName.asRubyArgument(name: "module_name", type: nil)
    let linkBeginningArg = linkBeginning.asRubyArgument(name: "link_beginning", type: nil)
    let linkEndingArg = linkEnding.asRubyArgument(name: "link_ending", type: nil)
    let outputFolderArg = RubyCommand.Argument(name: "output_folder", value: outputFolder, type: nil)
    let minAclArg = minAcl.asRubyArgument(name: "min_acl", type: nil)
    let moduleNamePathArg = moduleNamePath.asRubyArgument(name: "module_name_path", type: nil)
    let cleanArg = clean.asRubyArgument(name: "clean", type: nil)
    let collapsibleArg = collapsible.asRubyArgument(name: "collapsible", type: nil)
    let tableOfContentsArg = tableOfContents.asRubyArgument(name: "table_of_contents", type: nil)
    let reproducibleArg = reproducible.asRubyArgument(name: "reproducible", type: nil)
    let schemeArg = scheme.asRubyArgument(name: "scheme", type: nil)
    let sdkPlatformArg = sdkPlatform.asRubyArgument(name: "sdk_platform", type: nil)
    let array: [RubyCommand.Argument?] = [allModulesArg,
                                          spmModuleArg,
                                          moduleNameArg,
                                          linkBeginningArg,
                                          linkEndingArg,
                                          outputFolderArg,
                                          minAclArg,
                                          moduleNamePathArg,
                                          cleanArg,
                                          collapsibleArg,
                                          tableOfContentsArg,
                                          reproducibleArg,
                                          schemeArg,
                                          sdkPlatformArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "sourcedocs", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Find, print, and copy Spaceship logs

 - parameters:
   - latest: Finds only the latest Spaceshop log file if set to true, otherwise returns all
   - printContents: Prints the contents of the found Spaceship log file(s)
   - printPaths: Prints the paths of the found Spaceship log file(s)
   - copyToPath: Copies the found Spaceship log file(s) to a directory
   - copyToClipboard: Copies the contents of the found Spaceship log file(s) to the clipboard

 - returns: The array of Spaceship logs
 */
@discardableResult public func spaceshipLogs(latest: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                                             printContents: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                             printPaths: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                             copyToPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                             copyToClipboard: OptionalConfigValue<Bool> = .fastlaneDefault(false)) -> [String]
{
    let latestArg = latest.asRubyArgument(name: "latest", type: nil)
    let printContentsArg = printContents.asRubyArgument(name: "print_contents", type: nil)
    let printPathsArg = printPaths.asRubyArgument(name: "print_paths", type: nil)
    let copyToPathArg = copyToPath.asRubyArgument(name: "copy_to_path", type: nil)
    let copyToClipboardArg = copyToClipboard.asRubyArgument(name: "copy_to_clipboard", type: nil)
    let array: [RubyCommand.Argument?] = [latestArg,
                                          printContentsArg,
                                          printPathsArg,
                                          copyToPathArg,
                                          copyToClipboardArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "spaceship_logs", className: nil, args: args)
    return parseArray(fromString: runner.executeCommand(command))
}

/**
 Print out Spaceship stats from this session (number of request to each domain)

 - parameter printRequestLogs: Print all URLs requested
 */
public func spaceshipStats(printRequestLogs: OptionalConfigValue<Bool> = .fastlaneDefault(false)) {
    let printRequestLogsArg = printRequestLogs.asRubyArgument(name: "print_request_logs", type: nil)
    let array: [RubyCommand.Argument?] = [printRequestLogsArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "spaceship_stats", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Upload dSYM file to [Splunk MINT](https://mint.splunk.com/)

 - parameters:
   - dsym: dSYM.zip file to upload to Splunk MINT
   - apiKey: Splunk MINT App API key e.g. f57a57ca
   - apiToken: Splunk MINT API token e.g. e05ba40754c4869fb7e0b61
   - verbose: Make detailed output
   - uploadProgress: Show upload progress
   - proxyUsername: Proxy username
   - proxyPassword: Proxy password
   - proxyAddress: Proxy address
   - proxyPort: Proxy port
 */
public func splunkmint(dsym: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                       apiKey: String,
                       apiToken: String,
                       verbose: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                       uploadProgress: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                       proxyUsername: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                       proxyPassword: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                       proxyAddress: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                       proxyPort: OptionalConfigValue<String?> = .fastlaneDefault(nil))
{
    let dsymArg = dsym.asRubyArgument(name: "dsym", type: nil)
    let apiKeyArg = RubyCommand.Argument(name: "api_key", value: apiKey, type: nil)
    let apiTokenArg = RubyCommand.Argument(name: "api_token", value: apiToken, type: nil)
    let verboseArg = verbose.asRubyArgument(name: "verbose", type: nil)
    let uploadProgressArg = uploadProgress.asRubyArgument(name: "upload_progress", type: nil)
    let proxyUsernameArg = proxyUsername.asRubyArgument(name: "proxy_username", type: nil)
    let proxyPasswordArg = proxyPassword.asRubyArgument(name: "proxy_password", type: nil)
    let proxyAddressArg = proxyAddress.asRubyArgument(name: "proxy_address", type: nil)
    let proxyPortArg = proxyPort.asRubyArgument(name: "proxy_port", type: nil)
    let array: [RubyCommand.Argument?] = [dsymArg,
                                          apiKeyArg,
                                          apiTokenArg,
                                          verboseArg,
                                          uploadProgressArg,
                                          proxyUsernameArg,
                                          proxyPasswordArg,
                                          proxyAddressArg,
                                          proxyPortArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "splunkmint", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Runs Swift Package Manager on your project

 - parameters:
   - command: The swift command (one of: build, test, clean, reset, update, resolve, generate-xcodeproj, init)
   - enableCodeCoverage: Enables code coverage for the generated Xcode project when using the 'generate-xcodeproj' and the 'test' command
   - scratchPath: Specify build/cache directory [default: ./.build]
   - parallel: Enables running tests in parallel when using the 'test' command
   - buildPath: **DEPRECATED!** `build_path` option is deprecated, use `scratch_path` instead - Specify build/cache directory [default: ./.build]
   - packagePath: Change working directory before any other operation
   - xcconfig: Use xcconfig file to override swift package generate-xcodeproj defaults
   - configuration: Build with configuration (debug|release) [default: debug]
   - disableSandbox: Disable using the sandbox when executing subprocesses
   - xcprettyOutput: Specifies the output type for xcpretty. eg. 'test', or 'simple'
   - xcprettyArgs: Pass in xcpretty additional command line arguments (e.g. '--test --no-color' or '--tap --no-utf'), requires xcpretty_output to be specified also
   - verbose: Increase verbosity of informational output
   - veryVerbose: Increase verbosity to include debug output
   - simulator: Specifies the simulator to pass for Swift Compiler (one of: iphonesimulator, macosx)
   - simulatorArch: Specifies the architecture of the simulator to pass for Swift Compiler (one of: x86_64, arm64). Requires the simulator option to be specified also, otherwise, it's ignored
 */
public func spm(command: String = "build",
                enableCodeCoverage: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                scratchPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                parallel: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                buildPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                packagePath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                xcconfig: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                configuration: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                disableSandbox: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                xcprettyOutput: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                xcprettyArgs: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                verbose: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                veryVerbose: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                simulator: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                simulatorArch: String = "arm64")
{
    let commandArg = RubyCommand.Argument(name: "command", value: command, type: nil)
    let enableCodeCoverageArg = enableCodeCoverage.asRubyArgument(name: "enable_code_coverage", type: nil)
    let scratchPathArg = scratchPath.asRubyArgument(name: "scratch_path", type: nil)
    let parallelArg = parallel.asRubyArgument(name: "parallel", type: nil)
    let buildPathArg = buildPath.asRubyArgument(name: "build_path", type: nil)
    let packagePathArg = packagePath.asRubyArgument(name: "package_path", type: nil)
    let xcconfigArg = xcconfig.asRubyArgument(name: "xcconfig", type: nil)
    let configurationArg = configuration.asRubyArgument(name: "configuration", type: nil)
    let disableSandboxArg = disableSandbox.asRubyArgument(name: "disable_sandbox", type: nil)
    let xcprettyOutputArg = xcprettyOutput.asRubyArgument(name: "xcpretty_output", type: nil)
    let xcprettyArgsArg = xcprettyArgs.asRubyArgument(name: "xcpretty_args", type: nil)
    let verboseArg = verbose.asRubyArgument(name: "verbose", type: nil)
    let veryVerboseArg = veryVerbose.asRubyArgument(name: "very_verbose", type: nil)
    let simulatorArg = simulator.asRubyArgument(name: "simulator", type: nil)
    let simulatorArchArg = RubyCommand.Argument(name: "simulator_arch", value: simulatorArch, type: nil)
    let array: [RubyCommand.Argument?] = [commandArg,
                                          enableCodeCoverageArg,
                                          scratchPathArg,
                                          parallelArg,
                                          buildPathArg,
                                          packagePathArg,
                                          xcconfigArg,
                                          configurationArg,
                                          disableSandboxArg,
                                          xcprettyOutputArg,
                                          xcprettyArgsArg,
                                          verboseArg,
                                          veryVerboseArg,
                                          simulatorArg,
                                          simulatorArchArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "spm", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Allows remote command execution using ssh

 - parameters:
   - username: Username
   - password: Password
   - host: Hostname
   - port: Port
   - commands: Commands
   - log: Log commands and output

 Lets you execute remote commands via ssh using username/password or ssh-agent. If one of the commands in command-array returns non 0, it fails.
 */
public func ssh(username: String,
                password: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                host: String,
                port: String = "22",
                commands: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                log: OptionalConfigValue<Bool> = .fastlaneDefault(true))
{
    let usernameArg = RubyCommand.Argument(name: "username", value: username, type: nil)
    let passwordArg = password.asRubyArgument(name: "password", type: nil)
    let hostArg = RubyCommand.Argument(name: "host", value: host, type: nil)
    let portArg = RubyCommand.Argument(name: "port", value: port, type: nil)
    let commandsArg = commands.asRubyArgument(name: "commands", type: nil)
    let logArg = log.asRubyArgument(name: "log", type: nil)
    let array: [RubyCommand.Argument?] = [usernameArg,
                                          passwordArg,
                                          hostArg,
                                          portArg,
                                          commandsArg,
                                          logArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "ssh", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Alias for the `upload_to_play_store` action

 - parameters:
   - packageName: The package name of the application to use
   - versionName: Version name (used when uploading new apks/aabs) - defaults to 'versionName' in build.gradle or AndroidManifest.xml
   - versionCode: The versionCode for which to download the generated APK
   - releaseStatus: Release status (used when uploading new apks/aabs) - valid values are completed, draft, halted, inProgress
   - track: The track of the application to use. The default available tracks are: production, beta, alpha, internal
   - rollout: The percentage of the user fraction when uploading to the rollout track (setting to 1 will complete the rollout)
   - metadataPath: Path to the directory containing the metadata files
   - key: **DEPRECATED!** Use `--json_key` instead - The p12 File used to authenticate with Google
   - issuer: **DEPRECATED!** Use `--json_key` instead - The issuer of the p12 file (email address of the service account)
   - jsonKey: The path to a file containing service account JSON, used to authenticate with Google
   - jsonKeyData: The raw service account JSON data used to authenticate with Google
   - apk: Path to the APK file to upload
   - apkPaths: An array of paths to APK files to upload
   - aab: Path to the AAB file to upload
   - aabPaths: An array of paths to AAB files to upload
   - skipUploadApk: Whether to skip uploading APK
   - skipUploadAab: Whether to skip uploading AAB
   - skipUploadMetadata: Whether to skip uploading metadata, changelogs not included
   - skipUploadChangelogs: Whether to skip uploading changelogs
   - skipUploadImages: Whether to skip uploading images, screenshots not included
   - skipUploadScreenshots: Whether to skip uploading SCREENSHOTS
   - syncImageUpload: Whether to use sha256 comparison to skip upload of images and screenshots that are already in Play Store
   - trackPromoteTo: The track to promote to. The default available tracks are: production, beta, alpha, internal
   - trackPromoteReleaseStatus: Promoted track release status (used when promoting a track) - valid values are completed, draft, halted, inProgress
   - validateOnly: Only validate changes with Google Play rather than actually publish
   - mapping: Path to the mapping file to upload (mapping.txt or native-debug-symbols.zip alike)
   - mappingPaths: An array of paths to mapping files to upload (mapping.txt or native-debug-symbols.zip alike)
   - rootUrl: Root URL for the Google Play API. The provided URL will be used for API calls in place of https://www.googleapis.com/
   - checkSupersededTracks: **DEPRECATED!** Google Play does this automatically now - Check the other tracks for superseded versions and disable them
   - timeout: Timeout for read, open, and send (in seconds)
   - deactivateOnPromote: **DEPRECATED!** Google Play does this automatically now - When promoting to a new track, deactivate the binary in the origin track
   - versionCodesToRetain: An array of version codes to retain when publishing a new APK
   - changesNotSentForReview: Indicates that the changes in this edit will not be reviewed until they are explicitly sent for review from the Google Play Console UI
   - rescueChangesNotSentForReview: Catches changes_not_sent_for_review errors when an edit is committed and retries with the configuration that the error message recommended
   - inAppUpdatePriority: In-app update priority for all the newly added apks in the release. Can take values between [0,5]
   - obbMainReferencesVersion: References version of 'main' expansion file
   - obbMainFileSize: Size of 'main' expansion file in bytes
   - obbPatchReferencesVersion: References version of 'patch' expansion file
   - obbPatchFileSize: Size of 'patch' expansion file in bytes
   - ackBundleInstallationWarning: Must be set to true if the bundle installation may trigger a warning on user devices (e.g can only be downloaded over wifi). Typically this is required for bundles over 150MB

 More information: https://docs.fastlane.tools/actions/supply/
 */
public func supply(packageName: String,
                   versionName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   versionCode: OptionalConfigValue<Int?> = .fastlaneDefault(nil),
                   releaseStatus: String = "completed",
                   track: String = "production",
                   rollout: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   metadataPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   key: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   issuer: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   jsonKey: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   jsonKeyData: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   apk: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   apkPaths: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                   aab: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   aabPaths: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                   skipUploadApk: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                   skipUploadAab: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                   skipUploadMetadata: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                   skipUploadChangelogs: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                   skipUploadImages: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                   skipUploadScreenshots: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                   syncImageUpload: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                   trackPromoteTo: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   trackPromoteReleaseStatus: String = "completed",
                   validateOnly: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                   mapping: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   mappingPaths: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                   rootUrl: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   checkSupersededTracks: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                   timeout: Int = 300,
                   deactivateOnPromote: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                   versionCodesToRetain: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                   changesNotSentForReview: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                   rescueChangesNotSentForReview: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                   inAppUpdatePriority: OptionalConfigValue<Int?> = .fastlaneDefault(nil),
                   obbMainReferencesVersion: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   obbMainFileSize: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   obbPatchReferencesVersion: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   obbPatchFileSize: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                   ackBundleInstallationWarning: OptionalConfigValue<Bool> = .fastlaneDefault(false))
{
    let packageNameArg = RubyCommand.Argument(name: "package_name", value: packageName, type: nil)
    let versionNameArg = versionName.asRubyArgument(name: "version_name", type: nil)
    let versionCodeArg = versionCode.asRubyArgument(name: "version_code", type: nil)
    let releaseStatusArg = RubyCommand.Argument(name: "release_status", value: releaseStatus, type: nil)
    let trackArg = RubyCommand.Argument(name: "track", value: track, type: nil)
    let rolloutArg = rollout.asRubyArgument(name: "rollout", type: nil)
    let metadataPathArg = metadataPath.asRubyArgument(name: "metadata_path", type: nil)
    let keyArg = key.asRubyArgument(name: "key", type: nil)
    let issuerArg = issuer.asRubyArgument(name: "issuer", type: nil)
    let jsonKeyArg = jsonKey.asRubyArgument(name: "json_key", type: nil)
    let jsonKeyDataArg = jsonKeyData.asRubyArgument(name: "json_key_data", type: nil)
    let apkArg = apk.asRubyArgument(name: "apk", type: nil)
    let apkPathsArg = apkPaths.asRubyArgument(name: "apk_paths", type: nil)
    let aabArg = aab.asRubyArgument(name: "aab", type: nil)
    let aabPathsArg = aabPaths.asRubyArgument(name: "aab_paths", type: nil)
    let skipUploadApkArg = skipUploadApk.asRubyArgument(name: "skip_upload_apk", type: nil)
    let skipUploadAabArg = skipUploadAab.asRubyArgument(name: "skip_upload_aab", type: nil)
    let skipUploadMetadataArg = skipUploadMetadata.asRubyArgument(name: "skip_upload_metadata", type: nil)
    let skipUploadChangelogsArg = skipUploadChangelogs.asRubyArgument(name: "skip_upload_changelogs", type: nil)
    let skipUploadImagesArg = skipUploadImages.asRubyArgument(name: "skip_upload_images", type: nil)
    let skipUploadScreenshotsArg = skipUploadScreenshots.asRubyArgument(name: "skip_upload_screenshots", type: nil)
    let syncImageUploadArg = syncImageUpload.asRubyArgument(name: "sync_image_upload", type: nil)
    let trackPromoteToArg = trackPromoteTo.asRubyArgument(name: "track_promote_to", type: nil)
    let trackPromoteReleaseStatusArg = RubyCommand.Argument(name: "track_promote_release_status", value: trackPromoteReleaseStatus, type: nil)
    let validateOnlyArg = validateOnly.asRubyArgument(name: "validate_only", type: nil)
    let mappingArg = mapping.asRubyArgument(name: "mapping", type: nil)
    let mappingPathsArg = mappingPaths.asRubyArgument(name: "mapping_paths", type: nil)
    let rootUrlArg = rootUrl.asRubyArgument(name: "root_url", type: nil)
    let checkSupersededTracksArg = checkSupersededTracks.asRubyArgument(name: "check_superseded_tracks", type: nil)
    let timeoutArg = RubyCommand.Argument(name: "timeout", value: timeout, type: nil)
    let deactivateOnPromoteArg = deactivateOnPromote.asRubyArgument(name: "deactivate_on_promote", type: nil)
    let versionCodesToRetainArg = versionCodesToRetain.asRubyArgument(name: "version_codes_to_retain", type: nil)
    let changesNotSentForReviewArg = changesNotSentForReview.asRubyArgument(name: "changes_not_sent_for_review", type: nil)
    let rescueChangesNotSentForReviewArg = rescueChangesNotSentForReview.asRubyArgument(name: "rescue_changes_not_sent_for_review", type: nil)
    let inAppUpdatePriorityArg = inAppUpdatePriority.asRubyArgument(name: "in_app_update_priority", type: nil)
    let obbMainReferencesVersionArg = obbMainReferencesVersion.asRubyArgument(name: "obb_main_references_version", type: nil)
    let obbMainFileSizeArg = obbMainFileSize.asRubyArgument(name: "obb_main_file_size", type: nil)
    let obbPatchReferencesVersionArg = obbPatchReferencesVersion.asRubyArgument(name: "obb_patch_references_version", type: nil)
    let obbPatchFileSizeArg = obbPatchFileSize.asRubyArgument(name: "obb_patch_file_size", type: nil)
    let ackBundleInstallationWarningArg = ackBundleInstallationWarning.asRubyArgument(name: "ack_bundle_installation_warning", type: nil)
    let array: [RubyCommand.Argument?] = [packageNameArg,
                                          versionNameArg,
                                          versionCodeArg,
                                          releaseStatusArg,
                                          trackArg,
                                          rolloutArg,
                                          metadataPathArg,
                                          keyArg,
                                          issuerArg,
                                          jsonKeyArg,
                                          jsonKeyDataArg,
                                          apkArg,
                                          apkPathsArg,
                                          aabArg,
                                          aabPathsArg,
                                          skipUploadApkArg,
                                          skipUploadAabArg,
                                          skipUploadMetadataArg,
                                          skipUploadChangelogsArg,
                                          skipUploadImagesArg,
                                          skipUploadScreenshotsArg,
                                          syncImageUploadArg,
                                          trackPromoteToArg,
                                          trackPromoteReleaseStatusArg,
                                          validateOnlyArg,
                                          mappingArg,
                                          mappingPathsArg,
                                          rootUrlArg,
                                          checkSupersededTracksArg,
                                          timeoutArg,
                                          deactivateOnPromoteArg,
                                          versionCodesToRetainArg,
                                          changesNotSentForReviewArg,
                                          rescueChangesNotSentForReviewArg,
                                          inAppUpdatePriorityArg,
                                          obbMainReferencesVersionArg,
                                          obbMainFileSizeArg,
                                          obbPatchReferencesVersionArg,
                                          obbPatchFileSizeArg,
                                          ackBundleInstallationWarningArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "supply", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Run swift code validation using SwiftLint

 - parameters:
   - mode: SwiftLint mode: :lint, :fix, :autocorrect or :analyze
   - path: Specify path to lint
   - outputFile: Path to output SwiftLint result
   - configFile: Custom configuration file of SwiftLint
   - strict: Fail on warnings? (true/false)
   - files: List of files to process
   - ignoreExitStatus: Ignore the exit status of the SwiftLint command, so that serious violations                                                     don't fail the build (true/false)
   - raiseIfSwiftlintError: Raises an error if swiftlint fails, so you can fail CI/CD jobs if necessary                                                     (true/false)
   - reporter: Choose output reporter. Available: xcode, json, csv, checkstyle, codeclimate,                                                      junit, html, emoji, sonarqube, markdown, github-actions-logging
   - quiet: Don't print status logs like 'Linting <file>' & 'Done linting'
   - executable: Path to the `swiftlint` executable on your machine
   - format: Format code when mode is :autocorrect
   - noCache: Ignore the cache when mode is :autocorrect or :lint
   - compilerLogPath: Compiler log path when mode is :analyze
 */
public func swiftlint(mode: String = "lint",
                      path: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      outputFile: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      configFile: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      strict: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                      files: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                      ignoreExitStatus: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                      raiseIfSwiftlintError: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                      reporter: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      quiet: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                      executable: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      format: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                      noCache: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                      compilerLogPath: OptionalConfigValue<String?> = .fastlaneDefault(nil))
{
    let modeArg = RubyCommand.Argument(name: "mode", value: mode, type: nil)
    let pathArg = path.asRubyArgument(name: "path", type: nil)
    let outputFileArg = outputFile.asRubyArgument(name: "output_file", type: nil)
    let configFileArg = configFile.asRubyArgument(name: "config_file", type: nil)
    let strictArg = strict.asRubyArgument(name: "strict", type: nil)
    let filesArg = files.asRubyArgument(name: "files", type: nil)
    let ignoreExitStatusArg = ignoreExitStatus.asRubyArgument(name: "ignore_exit_status", type: nil)
    let raiseIfSwiftlintErrorArg = raiseIfSwiftlintError.asRubyArgument(name: "raise_if_swiftlint_error", type: nil)
    let reporterArg = reporter.asRubyArgument(name: "reporter", type: nil)
    let quietArg = quiet.asRubyArgument(name: "quiet", type: nil)
    let executableArg = executable.asRubyArgument(name: "executable", type: nil)
    let formatArg = format.asRubyArgument(name: "format", type: nil)
    let noCacheArg = noCache.asRubyArgument(name: "no_cache", type: nil)
    let compilerLogPathArg = compilerLogPath.asRubyArgument(name: "compiler_log_path", type: nil)
    let array: [RubyCommand.Argument?] = [modeArg,
                                          pathArg,
                                          outputFileArg,
                                          configFileArg,
                                          strictArg,
                                          filesArg,
                                          ignoreExitStatusArg,
                                          raiseIfSwiftlintErrorArg,
                                          reporterArg,
                                          quietArg,
                                          executableArg,
                                          formatArg,
                                          noCacheArg,
                                          compilerLogPathArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "swiftlint", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Easily sync your certificates and profiles across your team (via _match_)

 - parameters:
   - type: Define the profile type, can be appstore, adhoc, development, enterprise, developer_id, mac_installer_distribution, developer_id_installer
   - additionalCertTypes: Create additional cert types needed for macOS installers (valid values: mac_installer_distribution, developer_id_installer)
   - readonly: Only fetch existing certificates and profiles, don't generate new ones
   - generateAppleCerts: Create a certificate type for Xcode 11 and later (Apple Development or Apple Distribution)
   - skipProvisioningProfiles: Skip syncing provisioning profiles
   - appIdentifier: The bundle identifier(s) of your app (comma-separated string or array of strings)
   - apiKeyPath: Path to your App Store Connect API Key JSON file (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-json-file)
   - apiKey: Your App Store Connect API Key information (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-hash-option)
   - username: Your Apple ID Username
   - teamId: The ID of your Developer Portal team if you're in multiple teams
   - teamName: The name of your Developer Portal team if you're in multiple teams
   - storageMode: Define where you want to store your certificates
   - gitUrl: URL to the git repo containing all the certificates
   - gitBranch: Specific git branch to use
   - gitFullName: git user full name to commit
   - gitUserEmail: git user email to commit
   - shallowClone: Make a shallow clone of the repository (truncate the history to 1 revision)
   - cloneBranchDirectly: Clone just the branch specified, instead of the whole repo. This requires that the branch already exists. Otherwise the command will fail
   - gitBasicAuthorization: Use a basic authorization header to access the git repo (e.g.: access via HTTPS, GitHub Actions, etc), usually a string in Base64
   - gitBearerAuthorization: Use a bearer authorization header to access the git repo (e.g.: access to an Azure DevOps repository), usually a string in Base64
   - gitPrivateKey: Use a private key to access the git repo (e.g.: access to GitHub repository via Deploy keys), usually a id_rsa named file or the contents hereof
   - googleCloudBucketName: Name of the Google Cloud Storage bucket to use
   - googleCloudKeysFile: Path to the gc_keys.json file
   - googleCloudProjectId: ID of the Google Cloud project to use for authentication
   - skipGoogleCloudAccountConfirmation: Skips confirming to use the system google account
   - s3Region: Name of the S3 region
   - s3AccessKey: S3 access key
   - s3SecretAccessKey: S3 secret access key
   - s3Bucket: Name of the S3 bucket
   - s3ObjectPrefix: Prefix to be used on all objects uploaded to S3
   - s3SkipEncryption: Skip encryption of all objects uploaded to S3. WARNING: only enable this on S3 buckets with sufficiently restricted permissions and server-side encryption enabled. See https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingEncryption.html
   - gitlabProject: GitLab Project Path (i.e. 'gitlab-org/gitlab')
   - gitlabHost: GitLab Host (i.e. 'https://gitlab.com')
   - jobToken: GitLab CI_JOB_TOKEN
   - privateToken: GitLab Access Token
   - keychainName: Keychain the items should be imported to
   - keychainPassword: This might be required the first time you access certificates on a new mac. For the login/default keychain this is your macOS account password
   - force: Renew the provisioning profiles every time you run match
   - forceForNewDevices: Renew the provisioning profiles if the device count on the developer portal has changed. Ignored for profile types 'appstore' and 'developer_id'
   - includeMacInProfiles: Include Apple Silicon Mac devices in provisioning profiles for iOS/iPadOS apps
   - includeAllCertificates: Include all matching certificates in the provisioning profile. Works only for the 'development' provisioning profile type
   - certificateId: Select certificate by id. Useful if multiple certificates are stored in one place
   - forceForNewCertificates: Renew the provisioning profiles if the certificate count on the developer portal has changed. Works only for the 'development' provisioning profile type. Requires 'include_all_certificates' option to be 'true'
   - skipConfirmation: Disables confirmation prompts during nuke, answering them with yes
   - safeRemoveCerts: Remove certs from repository during nuke without revoking them on the developer portal
   - skipDocs: Skip generation of a README.md for the created git repository
   - platform: Set the provisioning profile's platform to work with (i.e. ios, tvos, macos, catalyst)
   - deriveCatalystAppIdentifier: Enable this if you have the Mac Catalyst capability enabled and your project was created with Xcode 11.3 or earlier. Prepends 'maccatalyst.' to the app identifier for the provisioning profile mapping
   - templateName: The name of provisioning profile template. If the developer account has provisioning profile templates (aka: custom entitlements), the template name can be found by inspecting the Entitlements drop-down while creating/editing a provisioning profile (e.g. "Apple Pay Pass Suppression Development")
   - profileName: A custom name for the provisioning profile. This will replace the default provisioning profile name if specified
   - failOnNameTaken: Should the command fail if it was about to create a duplicate of an existing provisioning profile. It can happen due to issues on Apple Developer Portal, when profile to be recreated was not properly deleted first
   - skipCertificateMatching: Set to true if there is no access to Apple developer portal but there are certificates, keys and profiles provided. Only works with match import action
   - outputPath: Path in which to export certificates, key and profile
   - skipSetPartitionList: Skips setting the partition list (which can sometimes take a long time). Setting the partition list is usually needed to prevent Xcode from prompting to allow a cert to be used for signing
   - forceLegacyEncryption: Force encryption to use legacy cbc algorithm for backwards compatibility with older match versions
   - verbose: Print out extra information and all commands

 More information: https://docs.fastlane.tools/actions/match/
 */
public func syncCodeSigning(type: String = "development",
                            additionalCertTypes: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                            readonly: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                            generateAppleCerts: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                            skipProvisioningProfiles: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                            appIdentifier: [String],
                            apiKeyPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            apiKey: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                            username: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            teamId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            teamName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            storageMode: String = "git",
                            gitUrl: String,
                            gitBranch: String = "master",
                            gitFullName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            gitUserEmail: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            shallowClone: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                            cloneBranchDirectly: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                            gitBasicAuthorization: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            gitBearerAuthorization: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            gitPrivateKey: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            googleCloudBucketName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            googleCloudKeysFile: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            googleCloudProjectId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            skipGoogleCloudAccountConfirmation: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                            s3Region: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            s3AccessKey: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            s3SecretAccessKey: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            s3Bucket: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            s3ObjectPrefix: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            s3SkipEncryption: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                            gitlabProject: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            gitlabHost: String = "https://gitlab.com",
                            jobToken: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            privateToken: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            keychainName: String = "login.keychain",
                            keychainPassword: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            force: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                            forceForNewDevices: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                            includeMacInProfiles: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                            includeAllCertificates: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                            certificateId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            forceForNewCertificates: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                            skipConfirmation: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                            safeRemoveCerts: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                            skipDocs: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                            platform: String = "ios",
                            deriveCatalystAppIdentifier: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                            templateName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            profileName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            failOnNameTaken: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                            skipCertificateMatching: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                            outputPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            skipSetPartitionList: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                            forceLegacyEncryption: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                            verbose: OptionalConfigValue<Bool> = .fastlaneDefault(false))
{
    let typeArg = RubyCommand.Argument(name: "type", value: type, type: nil)
    let additionalCertTypesArg = additionalCertTypes.asRubyArgument(name: "additional_cert_types", type: nil)
    let readonlyArg = readonly.asRubyArgument(name: "readonly", type: nil)
    let generateAppleCertsArg = generateAppleCerts.asRubyArgument(name: "generate_apple_certs", type: nil)
    let skipProvisioningProfilesArg = skipProvisioningProfiles.asRubyArgument(name: "skip_provisioning_profiles", type: nil)
    let appIdentifierArg = RubyCommand.Argument(name: "app_identifier", value: appIdentifier, type: nil)
    let apiKeyPathArg = apiKeyPath.asRubyArgument(name: "api_key_path", type: nil)
    let apiKeyArg = apiKey.asRubyArgument(name: "api_key", type: nil)
    let usernameArg = username.asRubyArgument(name: "username", type: nil)
    let teamIdArg = teamId.asRubyArgument(name: "team_id", type: nil)
    let teamNameArg = teamName.asRubyArgument(name: "team_name", type: nil)
    let storageModeArg = RubyCommand.Argument(name: "storage_mode", value: storageMode, type: nil)
    let gitUrlArg = RubyCommand.Argument(name: "git_url", value: gitUrl, type: nil)
    let gitBranchArg = RubyCommand.Argument(name: "git_branch", value: gitBranch, type: nil)
    let gitFullNameArg = gitFullName.asRubyArgument(name: "git_full_name", type: nil)
    let gitUserEmailArg = gitUserEmail.asRubyArgument(name: "git_user_email", type: nil)
    let shallowCloneArg = shallowClone.asRubyArgument(name: "shallow_clone", type: nil)
    let cloneBranchDirectlyArg = cloneBranchDirectly.asRubyArgument(name: "clone_branch_directly", type: nil)
    let gitBasicAuthorizationArg = gitBasicAuthorization.asRubyArgument(name: "git_basic_authorization", type: nil)
    let gitBearerAuthorizationArg = gitBearerAuthorization.asRubyArgument(name: "git_bearer_authorization", type: nil)
    let gitPrivateKeyArg = gitPrivateKey.asRubyArgument(name: "git_private_key", type: nil)
    let googleCloudBucketNameArg = googleCloudBucketName.asRubyArgument(name: "google_cloud_bucket_name", type: nil)
    let googleCloudKeysFileArg = googleCloudKeysFile.asRubyArgument(name: "google_cloud_keys_file", type: nil)
    let googleCloudProjectIdArg = googleCloudProjectId.asRubyArgument(name: "google_cloud_project_id", type: nil)
    let skipGoogleCloudAccountConfirmationArg = skipGoogleCloudAccountConfirmation.asRubyArgument(name: "skip_google_cloud_account_confirmation", type: nil)
    let s3RegionArg = s3Region.asRubyArgument(name: "s3_region", type: nil)
    let s3AccessKeyArg = s3AccessKey.asRubyArgument(name: "s3_access_key", type: nil)
    let s3SecretAccessKeyArg = s3SecretAccessKey.asRubyArgument(name: "s3_secret_access_key", type: nil)
    let s3BucketArg = s3Bucket.asRubyArgument(name: "s3_bucket", type: nil)
    let s3ObjectPrefixArg = s3ObjectPrefix.asRubyArgument(name: "s3_object_prefix", type: nil)
    let s3SkipEncryptionArg = s3SkipEncryption.asRubyArgument(name: "s3_skip_encryption", type: nil)
    let gitlabProjectArg = gitlabProject.asRubyArgument(name: "gitlab_project", type: nil)
    let gitlabHostArg = RubyCommand.Argument(name: "gitlab_host", value: gitlabHost, type: nil)
    let jobTokenArg = jobToken.asRubyArgument(name: "job_token", type: nil)
    let privateTokenArg = privateToken.asRubyArgument(name: "private_token", type: nil)
    let keychainNameArg = RubyCommand.Argument(name: "keychain_name", value: keychainName, type: nil)
    let keychainPasswordArg = keychainPassword.asRubyArgument(name: "keychain_password", type: nil)
    let forceArg = force.asRubyArgument(name: "force", type: nil)
    let forceForNewDevicesArg = forceForNewDevices.asRubyArgument(name: "force_for_new_devices", type: nil)
    let includeMacInProfilesArg = includeMacInProfiles.asRubyArgument(name: "include_mac_in_profiles", type: nil)
    let includeAllCertificatesArg = includeAllCertificates.asRubyArgument(name: "include_all_certificates", type: nil)
    let certificateIdArg = certificateId.asRubyArgument(name: "certificate_id", type: nil)
    let forceForNewCertificatesArg = forceForNewCertificates.asRubyArgument(name: "force_for_new_certificates", type: nil)
    let skipConfirmationArg = skipConfirmation.asRubyArgument(name: "skip_confirmation", type: nil)
    let safeRemoveCertsArg = safeRemoveCerts.asRubyArgument(name: "safe_remove_certs", type: nil)
    let skipDocsArg = skipDocs.asRubyArgument(name: "skip_docs", type: nil)
    let platformArg = RubyCommand.Argument(name: "platform", value: platform, type: nil)
    let deriveCatalystAppIdentifierArg = deriveCatalystAppIdentifier.asRubyArgument(name: "derive_catalyst_app_identifier", type: nil)
    let templateNameArg = templateName.asRubyArgument(name: "template_name", type: nil)
    let profileNameArg = profileName.asRubyArgument(name: "profile_name", type: nil)
    let failOnNameTakenArg = failOnNameTaken.asRubyArgument(name: "fail_on_name_taken", type: nil)
    let skipCertificateMatchingArg = skipCertificateMatching.asRubyArgument(name: "skip_certificate_matching", type: nil)
    let outputPathArg = outputPath.asRubyArgument(name: "output_path", type: nil)
    let skipSetPartitionListArg = skipSetPartitionList.asRubyArgument(name: "skip_set_partition_list", type: nil)
    let forceLegacyEncryptionArg = forceLegacyEncryption.asRubyArgument(name: "force_legacy_encryption", type: nil)
    let verboseArg = verbose.asRubyArgument(name: "verbose", type: nil)
    let array: [RubyCommand.Argument?] = [typeArg,
                                          additionalCertTypesArg,
                                          readonlyArg,
                                          generateAppleCertsArg,
                                          skipProvisioningProfilesArg,
                                          appIdentifierArg,
                                          apiKeyPathArg,
                                          apiKeyArg,
                                          usernameArg,
                                          teamIdArg,
                                          teamNameArg,
                                          storageModeArg,
                                          gitUrlArg,
                                          gitBranchArg,
                                          gitFullNameArg,
                                          gitUserEmailArg,
                                          shallowCloneArg,
                                          cloneBranchDirectlyArg,
                                          gitBasicAuthorizationArg,
                                          gitBearerAuthorizationArg,
                                          gitPrivateKeyArg,
                                          googleCloudBucketNameArg,
                                          googleCloudKeysFileArg,
                                          googleCloudProjectIdArg,
                                          skipGoogleCloudAccountConfirmationArg,
                                          s3RegionArg,
                                          s3AccessKeyArg,
                                          s3SecretAccessKeyArg,
                                          s3BucketArg,
                                          s3ObjectPrefixArg,
                                          s3SkipEncryptionArg,
                                          gitlabProjectArg,
                                          gitlabHostArg,
                                          jobTokenArg,
                                          privateTokenArg,
                                          keychainNameArg,
                                          keychainPasswordArg,
                                          forceArg,
                                          forceForNewDevicesArg,
                                          includeMacInProfilesArg,
                                          includeAllCertificatesArg,
                                          certificateIdArg,
                                          forceForNewCertificatesArg,
                                          skipConfirmationArg,
                                          safeRemoveCertsArg,
                                          skipDocsArg,
                                          platformArg,
                                          deriveCatalystAppIdentifierArg,
                                          templateNameArg,
                                          profileNameArg,
                                          failOnNameTakenArg,
                                          skipCertificateMatchingArg,
                                          outputPathArg,
                                          skipSetPartitionListArg,
                                          forceLegacyEncryptionArg,
                                          verboseArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "sync_code_signing", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Specify the Team ID you want to use for the Apple Developer Portal
 */
public func teamId() {
    let args: [RubyCommand.Argument] = []
    let command = RubyCommand(commandID: "", methodName: "team_id", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Set a team to use by its name
 */
public func teamName() {
    let args: [RubyCommand.Argument] = []
    let command = RubyCommand(commandID: "", methodName: "team_name", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Upload a new build to [TestFairy](https://www.testfairy.com/)

 - parameters:
   - apiKey: API Key for TestFairy
   - ipa: Path to your IPA file for iOS
   - apk: Path to your APK file for Android
   - symbolsFile: Symbols mapping file
   - uploadUrl: API URL for TestFairy
   - testersGroups: Array of tester groups to be notified
   - metrics: Array of metrics to record (cpu,memory,network,phone_signal,gps,battery,mic,wifi)
   - comment: Additional release notes for this upload. This text will be added to email notifications
   - autoUpdate: Allows an easy upgrade of all users to the current version. To enable set to 'on'
   - notify: Send email to testers
   - options: Array of options (shake,video_only_wifi,anonymous)
   - custom: Array of custom options. Contact support for more information
   - timeout: Request timeout in seconds
   - tags: Custom tags that can be used to organize your builds
   - folderName: Name of the dashboard folder that contains this app
   - landingPageMode: Visibility of build landing after upload. Can be 'open' or 'closed'
   - uploadToSaucelabs: Upload file directly to Sauce Labs. It can be 'on' or 'off'
   - platform: Use if upload build is not iOS or Android. Contact support for more information

 You can retrieve your API key on [your settings page](https://free.testfairy.com/settings/)
 */
public func testfairy(apiKey: String,
                      ipa: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      apk: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      symbolsFile: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                      uploadUrl: String = "https://upload.testfairy.com",
                      testersGroups: [String] = [],
                      metrics: [String] = [],
                      comment: String = "No comment provided",
                      autoUpdate: String = "off",
                      notify: String = "off",
                      options: [String] = [],
                      custom: String = "",
                      timeout: OptionalConfigValue<Int?> = .fastlaneDefault(nil),
                      tags: [String] = [],
                      folderName: String = "",
                      landingPageMode: String = "open",
                      uploadToSaucelabs: String = "off",
                      platform: String = "")
{
    let apiKeyArg = RubyCommand.Argument(name: "api_key", value: apiKey, type: nil)
    let ipaArg = ipa.asRubyArgument(name: "ipa", type: nil)
    let apkArg = apk.asRubyArgument(name: "apk", type: nil)
    let symbolsFileArg = symbolsFile.asRubyArgument(name: "symbols_file", type: nil)
    let uploadUrlArg = RubyCommand.Argument(name: "upload_url", value: uploadUrl, type: nil)
    let testersGroupsArg = RubyCommand.Argument(name: "testers_groups", value: testersGroups, type: nil)
    let metricsArg = RubyCommand.Argument(name: "metrics", value: metrics, type: nil)
    let commentArg = RubyCommand.Argument(name: "comment", value: comment, type: nil)
    let autoUpdateArg = RubyCommand.Argument(name: "auto_update", value: autoUpdate, type: nil)
    let notifyArg = RubyCommand.Argument(name: "notify", value: notify, type: nil)
    let optionsArg = RubyCommand.Argument(name: "options", value: options, type: nil)
    let customArg = RubyCommand.Argument(name: "custom", value: custom, type: nil)
    let timeoutArg = timeout.asRubyArgument(name: "timeout", type: nil)
    let tagsArg = RubyCommand.Argument(name: "tags", value: tags, type: nil)
    let folderNameArg = RubyCommand.Argument(name: "folder_name", value: folderName, type: nil)
    let landingPageModeArg = RubyCommand.Argument(name: "landing_page_mode", value: landingPageMode, type: nil)
    let uploadToSaucelabsArg = RubyCommand.Argument(name: "upload_to_saucelabs", value: uploadToSaucelabs, type: nil)
    let platformArg = RubyCommand.Argument(name: "platform", value: platform, type: nil)
    let array: [RubyCommand.Argument?] = [apiKeyArg,
                                          ipaArg,
                                          apkArg,
                                          symbolsFileArg,
                                          uploadUrlArg,
                                          testersGroupsArg,
                                          metricsArg,
                                          commentArg,
                                          autoUpdateArg,
                                          notifyArg,
                                          optionsArg,
                                          customArg,
                                          timeoutArg,
                                          tagsArg,
                                          folderNameArg,
                                          landingPageModeArg,
                                          uploadToSaucelabsArg,
                                          platformArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "testfairy", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Alias for the `upload_to_testflight` action

 - parameters:
   - apiKeyPath: Path to your App Store Connect API Key JSON file (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-json-file)
   - apiKey: Your App Store Connect API Key information (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-hash-option)
   - username: Your Apple ID Username
   - appIdentifier: The bundle identifier of the app to upload or manage testers (optional)
   - appPlatform: The platform to use (optional)
   - appleId: Apple ID property in the App Information section in App Store Connect
   - ipa: Path to the ipa file to upload
   - pkg: Path to your pkg file
   - demoAccountRequired: Do you need a demo account when Apple does review?
   - betaAppReviewInfo: Beta app review information for contact info and demo account
   - localizedAppInfo: Localized beta app test info for description, feedback email, marketing url, and privacy policy
   - betaAppDescription: Provide the 'Beta App Description' when uploading a new build
   - betaAppFeedbackEmail: Provide the beta app email when uploading a new build
   - localizedBuildInfo: Localized beta app test info for what's new
   - changelog: Provide the 'What to Test' text when uploading a new build
   - skipSubmission: Skip the distributing action of pilot and only upload the ipa file
   - skipWaitingForBuildProcessing: If set to true, the `distribute_external` option won't work and no build will be distributed to testers. (You might want to use this option if you are using this action on CI and have to pay for 'minutes used' on your CI plan). If set to `true` and a changelog is provided, it will partially wait for the build to appear on AppStore Connect so the changelog can be set, and skip the remaining processing steps
   - updateBuildInfoOnUpload: **DEPRECATED!** Update build info immediately after validation. This is deprecated and will be removed in a future release. App Store Connect no longer supports setting build info until after build processing has completed, which is when build info is updated by default
   - distributeOnly: Distribute a previously uploaded build (equivalent to the `fastlane pilot distribute` command)
   - usesNonExemptEncryption: Provide the 'Uses Non-Exempt Encryption' for export compliance. This is used if there is 'ITSAppUsesNonExemptEncryption' is not set in the Info.plist
   - distributeExternal: Should the build be distributed to external testers? If set to true, use of `groups` option is required
   - notifyExternalTesters: Should notify external testers? (Not setting a value will use App Store Connect's default which is to notify)
   - appVersion: The version number of the application build to distribute. If the version number is not specified, then the most recent build uploaded to TestFlight will be distributed. If specified, the most recent build for the version number will be distributed
   - buildNumber: The build number of the application build to distribute. If the build number is not specified, the most recent build is distributed
   - expirePreviousBuilds: Should expire previous builds?
   - firstName: The tester's first name
   - lastName: The tester's last name
   - email: The tester's email
   - testersFilePath: Path to a CSV file of testers
   - groups: Associate tester to one group or more by group name / group id. E.g. `-g "Team 1","Team 2"` This is required when `distribute_external` option is set to true or when we want to add a tester to one or more external testing groups
   - teamId: The ID of your App Store Connect team if you're in multiple teams
   - teamName: The name of your App Store Connect team if you're in multiple teams
   - devPortalTeamId: The short ID of your team in the developer portal, if you're in multiple teams. Different from your iTC team ID!
   - itcProvider: The provider short name to be used with the iTMSTransporter to identify your team. This value will override the automatically detected provider short name. To get provider short name run `xcrun iTMSTransporter -m provider -u 'USERNAME' -p 'PASSWORD' -account_type itunes_connect -v off`. The short names of providers should be listed in the second column
   - waitProcessingInterval: Interval in seconds to wait for App Store Connect processing
   - waitProcessingTimeoutDuration: Timeout duration in seconds to wait for App Store Connect processing. If set, after exceeding timeout duration, this will `force stop` to wait for App Store Connect processing and exit with exception
   - waitForUploadedBuild: **DEPRECATED!** No longer needed with the transition over to the App Store Connect API - Use version info from uploaded ipa file to determine what build to use for distribution. If set to false, latest processing or any latest build will be used
   - rejectBuildWaitingForReview: Expire previous if it's 'waiting for review'
   - submitBetaReview: Send the build for a beta review

 More details can be found on https://docs.fastlane.tools/actions/pilot/.
 This integration will only do the TestFlight upload.
 */
public func testflight(apiKeyPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                       apiKey: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                       username: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                       appIdentifier: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                       appPlatform: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                       appleId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                       ipa: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                       pkg: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                       demoAccountRequired: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                       betaAppReviewInfo: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                       localizedAppInfo: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                       betaAppDescription: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                       betaAppFeedbackEmail: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                       localizedBuildInfo: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                       changelog: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                       skipSubmission: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                       skipWaitingForBuildProcessing: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                       updateBuildInfoOnUpload: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                       distributeOnly: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                       usesNonExemptEncryption: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                       distributeExternal: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                       notifyExternalTesters: Any? = nil,
                       appVersion: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                       buildNumber: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                       expirePreviousBuilds: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                       firstName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                       lastName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                       email: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                       testersFilePath: String = "./testers.csv",
                       groups: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                       teamId: Any? = nil,
                       teamName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                       devPortalTeamId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                       itcProvider: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                       waitProcessingInterval: Int = 30,
                       waitProcessingTimeoutDuration: OptionalConfigValue<Int?> = .fastlaneDefault(nil),
                       waitForUploadedBuild: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                       rejectBuildWaitingForReview: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                       submitBetaReview: OptionalConfigValue<Bool> = .fastlaneDefault(true))
{
    let apiKeyPathArg = apiKeyPath.asRubyArgument(name: "api_key_path", type: nil)
    let apiKeyArg = apiKey.asRubyArgument(name: "api_key", type: nil)
    let usernameArg = username.asRubyArgument(name: "username", type: nil)
    let appIdentifierArg = appIdentifier.asRubyArgument(name: "app_identifier", type: nil)
    let appPlatformArg = appPlatform.asRubyArgument(name: "app_platform", type: nil)
    let appleIdArg = appleId.asRubyArgument(name: "apple_id", type: nil)
    let ipaArg = ipa.asRubyArgument(name: "ipa", type: nil)
    let pkgArg = pkg.asRubyArgument(name: "pkg", type: nil)
    let demoAccountRequiredArg = demoAccountRequired.asRubyArgument(name: "demo_account_required", type: nil)
    let betaAppReviewInfoArg = betaAppReviewInfo.asRubyArgument(name: "beta_app_review_info", type: nil)
    let localizedAppInfoArg = localizedAppInfo.asRubyArgument(name: "localized_app_info", type: nil)
    let betaAppDescriptionArg = betaAppDescription.asRubyArgument(name: "beta_app_description", type: nil)
    let betaAppFeedbackEmailArg = betaAppFeedbackEmail.asRubyArgument(name: "beta_app_feedback_email", type: nil)
    let localizedBuildInfoArg = localizedBuildInfo.asRubyArgument(name: "localized_build_info", type: nil)
    let changelogArg = changelog.asRubyArgument(name: "changelog", type: nil)
    let skipSubmissionArg = skipSubmission.asRubyArgument(name: "skip_submission", type: nil)
    let skipWaitingForBuildProcessingArg = skipWaitingForBuildProcessing.asRubyArgument(name: "skip_waiting_for_build_processing", type: nil)
    let updateBuildInfoOnUploadArg = updateBuildInfoOnUpload.asRubyArgument(name: "update_build_info_on_upload", type: nil)
    let distributeOnlyArg = distributeOnly.asRubyArgument(name: "distribute_only", type: nil)
    let usesNonExemptEncryptionArg = usesNonExemptEncryption.asRubyArgument(name: "uses_non_exempt_encryption", type: nil)
    let distributeExternalArg = distributeExternal.asRubyArgument(name: "distribute_external", type: nil)
    let notifyExternalTestersArg = RubyCommand.Argument(name: "notify_external_testers", value: notifyExternalTesters, type: nil)
    let appVersionArg = appVersion.asRubyArgument(name: "app_version", type: nil)
    let buildNumberArg = buildNumber.asRubyArgument(name: "build_number", type: nil)
    let expirePreviousBuildsArg = expirePreviousBuilds.asRubyArgument(name: "expire_previous_builds", type: nil)
    let firstNameArg = firstName.asRubyArgument(name: "first_name", type: nil)
    let lastNameArg = lastName.asRubyArgument(name: "last_name", type: nil)
    let emailArg = email.asRubyArgument(name: "email", type: nil)
    let testersFilePathArg = RubyCommand.Argument(name: "testers_file_path", value: testersFilePath, type: nil)
    let groupsArg = groups.asRubyArgument(name: "groups", type: nil)
    let teamIdArg = RubyCommand.Argument(name: "team_id", value: teamId, type: nil)
    let teamNameArg = teamName.asRubyArgument(name: "team_name", type: nil)
    let devPortalTeamIdArg = devPortalTeamId.asRubyArgument(name: "dev_portal_team_id", type: nil)
    let itcProviderArg = itcProvider.asRubyArgument(name: "itc_provider", type: nil)
    let waitProcessingIntervalArg = RubyCommand.Argument(name: "wait_processing_interval", value: waitProcessingInterval, type: nil)
    let waitProcessingTimeoutDurationArg = waitProcessingTimeoutDuration.asRubyArgument(name: "wait_processing_timeout_duration", type: nil)
    let waitForUploadedBuildArg = waitForUploadedBuild.asRubyArgument(name: "wait_for_uploaded_build", type: nil)
    let rejectBuildWaitingForReviewArg = rejectBuildWaitingForReview.asRubyArgument(name: "reject_build_waiting_for_review", type: nil)
    let submitBetaReviewArg = submitBetaReview.asRubyArgument(name: "submit_beta_review", type: nil)
    let array: [RubyCommand.Argument?] = [apiKeyPathArg,
                                          apiKeyArg,
                                          usernameArg,
                                          appIdentifierArg,
                                          appPlatformArg,
                                          appleIdArg,
                                          ipaArg,
                                          pkgArg,
                                          demoAccountRequiredArg,
                                          betaAppReviewInfoArg,
                                          localizedAppInfoArg,
                                          betaAppDescriptionArg,
                                          betaAppFeedbackEmailArg,
                                          localizedBuildInfoArg,
                                          changelogArg,
                                          skipSubmissionArg,
                                          skipWaitingForBuildProcessingArg,
                                          updateBuildInfoOnUploadArg,
                                          distributeOnlyArg,
                                          usesNonExemptEncryptionArg,
                                          distributeExternalArg,
                                          notifyExternalTestersArg,
                                          appVersionArg,
                                          buildNumberArg,
                                          expirePreviousBuildsArg,
                                          firstNameArg,
                                          lastNameArg,
                                          emailArg,
                                          testersFilePathArg,
                                          groupsArg,
                                          teamIdArg,
                                          teamNameArg,
                                          devPortalTeamIdArg,
                                          itcProviderArg,
                                          waitProcessingIntervalArg,
                                          waitProcessingTimeoutDurationArg,
                                          waitForUploadedBuildArg,
                                          rejectBuildWaitingForReviewArg,
                                          submitBetaReviewArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "testflight", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Convert the Xcode plist log to a JUnit report

 - parameters:
   - path: Path to the directory that should be converted
   - extension: The extension for the newly created file. Usually .xml or .junit
   - outputDirectory: Directory in which the xml files should be written to. Same directory as source by default
   - outputFilename: Filename the xml file should be written to. Defaults to name of input file. (Only works if one input file is used)
   - failBuild: Should this step stop the build if the tests fail? Set this to false if you're handling this with a test reporter
   - xcprettyNaming: Produces class name and test name identical to xcpretty naming in junit file
   - silent: Silences all output
   - outputRemoveRetryAttempts: Doesn't include retry attempts in the output

 - returns: A hash with the key being the path of the generated file, the value being if the tests were successful
 */
public func trainer(path: String = ".",
                    extension: String = ".xml",
                    outputDirectory: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                    outputFilename: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                    failBuild: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                    xcprettyNaming: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                    silent: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                    outputRemoveRetryAttempts: OptionalConfigValue<Bool> = .fastlaneDefault(false))
{
    let pathArg = RubyCommand.Argument(name: "path", value: path, type: nil)
    let extensionArg = RubyCommand.Argument(name: "extension", value: `extension`, type: nil)
    let outputDirectoryArg = outputDirectory.asRubyArgument(name: "output_directory", type: nil)
    let outputFilenameArg = outputFilename.asRubyArgument(name: "output_filename", type: nil)
    let failBuildArg = failBuild.asRubyArgument(name: "fail_build", type: nil)
    let xcprettyNamingArg = xcprettyNaming.asRubyArgument(name: "xcpretty_naming", type: nil)
    let silentArg = silent.asRubyArgument(name: "silent", type: nil)
    let outputRemoveRetryAttemptsArg = outputRemoveRetryAttempts.asRubyArgument(name: "output_remove_retry_attempts", type: nil)
    let array: [RubyCommand.Argument?] = [pathArg,
                                          extensionArg,
                                          outputDirectoryArg,
                                          outputFilenameArg,
                                          failBuildArg,
                                          xcprettyNamingArg,
                                          silentArg,
                                          outputRemoveRetryAttemptsArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "trainer", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Upload a new build to [Tryouts](https://tryouts.io/)

 - parameters:
   - appId: Tryouts application hash
   - apiToken: API Token (api_key:api_secret) for Tryouts Access
   - buildFile: Path to your IPA or APK file. Optional if you use the _gym_ or _xcodebuild_ action
   - notes: Release notes
   - notesPath: Release notes text file path. Overrides the :notes parameter
   - notify: Notify testers? 0 for no
   - status: 2 to make your release public. Release will be distributed to available testers. 1 to make your release private. Release won't be distributed to testers. This also prevents release from showing up for SDK update

 More information: [http://tryouts.readthedocs.org/en/latest/releases.html#create-release](http://tryouts.readthedocs.org/en/latest/releases.html#create-release)
 */
public func tryouts(appId: String,
                    apiToken: String,
                    buildFile: String,
                    notes: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                    notesPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                    notify: Int = 1,
                    status: Int = 2)
{
    let appIdArg = RubyCommand.Argument(name: "app_id", value: appId, type: nil)
    let apiTokenArg = RubyCommand.Argument(name: "api_token", value: apiToken, type: nil)
    let buildFileArg = RubyCommand.Argument(name: "build_file", value: buildFile, type: nil)
    let notesArg = notes.asRubyArgument(name: "notes", type: nil)
    let notesPathArg = notesPath.asRubyArgument(name: "notes_path", type: nil)
    let notifyArg = RubyCommand.Argument(name: "notify", value: notify, type: nil)
    let statusArg = RubyCommand.Argument(name: "status", value: status, type: nil)
    let array: [RubyCommand.Argument?] = [appIdArg,
                                          apiTokenArg,
                                          buildFileArg,
                                          notesArg,
                                          notesPathArg,
                                          notifyArg,
                                          statusArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "tryouts", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Post a tweet on [Twitter.com](https://twitter.com)

 - parameters:
   - consumerKey: Consumer Key
   - consumerSecret: Consumer Secret
   - accessToken: Access Token
   - accessTokenSecret: Access Token Secret
   - message: The tweet

 Post a tweet on Twitter. Requires you to setup an app on [twitter.com](https://twitter.com) and obtain `consumer` and `access_token`.
 */
public func twitter(consumerKey: String,
                    consumerSecret: String,
                    accessToken: String,
                    accessTokenSecret: String,
                    message: String)
{
    let consumerKeyArg = RubyCommand.Argument(name: "consumer_key", value: consumerKey, type: nil)
    let consumerSecretArg = RubyCommand.Argument(name: "consumer_secret", value: consumerSecret, type: nil)
    let accessTokenArg = RubyCommand.Argument(name: "access_token", value: accessToken, type: nil)
    let accessTokenSecretArg = RubyCommand.Argument(name: "access_token_secret", value: accessTokenSecret, type: nil)
    let messageArg = RubyCommand.Argument(name: "message", value: message, type: nil)
    let array: [RubyCommand.Argument?] = [consumerKeyArg,
                                          consumerSecretArg,
                                          accessTokenArg,
                                          accessTokenSecretArg,
                                          messageArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "twitter", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Post a message to [Typetalk](https://www.typetalk.com/)
 */
public func typetalk() {
    let args: [RubyCommand.Argument] = []
    let command = RubyCommand(commandID: "", methodName: "typetalk", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Unlock a keychain

 - parameters:
   - path: Path to the keychain file
   - password: Keychain password
   - addToSearchList: Add to keychain search list, valid values are true, false, :add, and :replace
   - setDefault: Set as default keychain

 Unlocks the given keychain file and adds it to the keychain search list.
 Keychains can be replaced with `add_to_search_list: :replace`.
 */
public func unlockKeychain(path: String = "login",
                           password: String,
                           addToSearchList: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                           setDefault: OptionalConfigValue<Bool> = .fastlaneDefault(false))
{
    let pathArg = RubyCommand.Argument(name: "path", value: path, type: nil)
    let passwordArg = RubyCommand.Argument(name: "password", value: password, type: nil)
    let addToSearchListArg = addToSearchList.asRubyArgument(name: "add_to_search_list", type: nil)
    let setDefaultArg = setDefault.asRubyArgument(name: "set_default", type: nil)
    let array: [RubyCommand.Argument?] = [pathArg,
                                          passwordArg,
                                          addToSearchListArg,
                                          setDefaultArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "unlock_keychain", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 This action changes the app group identifiers in the entitlements file

 - parameters:
   - entitlementsFile: The path to the entitlement file which contains the app group identifiers
   - appGroupIdentifiers: An Array of unique identifiers for the app groups. Eg. ['group.com.test.testapp']

 Updates the App Group Identifiers in the given Entitlements file, so you can have app groups for the app store build and app groups for an enterprise build.
 */
public func updateAppGroupIdentifiers(entitlementsFile: String,
                                      appGroupIdentifiers: [String])
{
    let entitlementsFileArg = RubyCommand.Argument(name: "entitlements_file", value: entitlementsFile, type: nil)
    let appGroupIdentifiersArg = RubyCommand.Argument(name: "app_group_identifiers", value: appGroupIdentifiers, type: nil)
    let array: [RubyCommand.Argument?] = [entitlementsFileArg,
                                          appGroupIdentifiersArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "update_app_group_identifiers", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Update the project's bundle identifier

 - parameters:
   - xcodeproj: Path to your Xcode project
   - plistPath: Path to info plist, relative to your Xcode project
   - appIdentifier: The app Identifier you want to set

 Update an app identifier by either setting `CFBundleIdentifier` or `PRODUCT_BUNDLE_IDENTIFIER`, depending on which is already in use.
 */
public func updateAppIdentifier(xcodeproj: String,
                                plistPath: String,
                                appIdentifier: String)
{
    let xcodeprojArg = RubyCommand.Argument(name: "xcodeproj", value: xcodeproj, type: nil)
    let plistPathArg = RubyCommand.Argument(name: "plist_path", value: plistPath, type: nil)
    let appIdentifierArg = RubyCommand.Argument(name: "app_identifier", value: appIdentifier, type: nil)
    let array: [RubyCommand.Argument?] = [xcodeprojArg,
                                          plistPathArg,
                                          appIdentifierArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "update_app_identifier", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Configures Xcode's Codesigning options

 - parameters:
   - path: Path to your Xcode project
   - useAutomaticSigning: Defines if project should use automatic signing
   - sdk: Build target SDKs (iphoneos*, macosx*, iphonesimulator*)
   - teamId: Team ID, is used when upgrading project
   - targets: Specify targets you want to toggle the signing mech. (default to all targets)
   - buildConfigurations: Specify build_configurations you want to toggle the signing mech. (default to all configurations)
   - codeSignIdentity: Code signing identity type (iPhone Developer, iPhone Distribution)
   - entitlementsFilePath: Path to your entitlements file
   - profileName: Provisioning profile name to use for code signing
   - profileUuid: Provisioning profile UUID to use for code signing
   - bundleIdentifier: Application Product Bundle Identifier

 - returns: The current status (boolean) of codesigning after modification

 Configures Xcode's Codesigning options of all targets in the project
 */
public func updateCodeSigningSettings(path: String,
                                      useAutomaticSigning: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                      sdk: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                      teamId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                      targets: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                                      buildConfigurations: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                                      codeSignIdentity: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                      entitlementsFilePath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                      profileName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                      profileUuid: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                      bundleIdentifier: OptionalConfigValue<String?> = .fastlaneDefault(nil))
{
    let pathArg = RubyCommand.Argument(name: "path", value: path, type: nil)
    let useAutomaticSigningArg = useAutomaticSigning.asRubyArgument(name: "use_automatic_signing", type: nil)
    let sdkArg = sdk.asRubyArgument(name: "sdk", type: nil)
    let teamIdArg = teamId.asRubyArgument(name: "team_id", type: nil)
    let targetsArg = targets.asRubyArgument(name: "targets", type: nil)
    let buildConfigurationsArg = buildConfigurations.asRubyArgument(name: "build_configurations", type: nil)
    let codeSignIdentityArg = codeSignIdentity.asRubyArgument(name: "code_sign_identity", type: nil)
    let entitlementsFilePathArg = entitlementsFilePath.asRubyArgument(name: "entitlements_file_path", type: nil)
    let profileNameArg = profileName.asRubyArgument(name: "profile_name", type: nil)
    let profileUuidArg = profileUuid.asRubyArgument(name: "profile_uuid", type: nil)
    let bundleIdentifierArg = bundleIdentifier.asRubyArgument(name: "bundle_identifier", type: nil)
    let array: [RubyCommand.Argument?] = [pathArg,
                                          useAutomaticSigningArg,
                                          sdkArg,
                                          teamIdArg,
                                          targetsArg,
                                          buildConfigurationsArg,
                                          codeSignIdentityArg,
                                          entitlementsFilePathArg,
                                          profileNameArg,
                                          profileUuidArg,
                                          bundleIdentifierArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "update_code_signing_settings", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Makes sure fastlane-tools are up-to-date when running fastlane

 - parameters:
   - noUpdate: Don't update during this run. This is used internally
   - nightly: **DEPRECATED!** Nightly builds are no longer being made available - Opt-in to install and use nightly fastlane builds

 This action will update fastlane to the most recent version - major version updates will not be performed automatically, as they might include breaking changes. If an update was performed, fastlane will be restarted before the run continues.

 If you are using rbenv or rvm, everything should be good to go. However, if you are using the system's default ruby, some additional setup is needed for this action to work correctly. In short, fastlane needs to be able to access your gem library without running in `sudo` mode.

 The simplest possible fix for this is putting the following lines into your `~/.bashrc` or `~/.zshrc` file:|
 |
 ```bash|
 export GEM_HOME=~/.gems|
 export PATH=$PATH:~/.gems/bin|
 ```|
 >|
 After the above changes, restart your terminal, then run `mkdir $GEM_HOME` to create the new gem directory. After this, you're good to go!

 Recommended usage of the `update_fastlane` action is at the top inside of the `before_all` block, before running any other action.
 */
public func updateFastlane(noUpdate: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                           nightly: OptionalConfigValue<Bool> = .fastlaneDefault(false))
{
    let noUpdateArg = noUpdate.asRubyArgument(name: "no_update", type: nil)
    let nightlyArg = nightly.asRubyArgument(name: "nightly", type: nil)
    let array: [RubyCommand.Argument?] = [noUpdateArg,
                                          nightlyArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "update_fastlane", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 This action changes the iCloud container identifiers in the entitlements file

 - parameters:
   - entitlementsFile: The path to the entitlement file which contains the iCloud container identifiers
   - icloudContainerIdentifiers: An Array of unique identifiers for the iCloud containers. Eg. ['iCloud.com.test.testapp']

 Updates the iCloud Container Identifiers in the given Entitlements file, so you can use different iCloud containers for different builds like Adhoc, App Store, etc.
 */
public func updateIcloudContainerIdentifiers(entitlementsFile: String,
                                             icloudContainerIdentifiers: [String])
{
    let entitlementsFileArg = RubyCommand.Argument(name: "entitlements_file", value: entitlementsFile, type: nil)
    let icloudContainerIdentifiersArg = RubyCommand.Argument(name: "icloud_container_identifiers", value: icloudContainerIdentifiers, type: nil)
    let array: [RubyCommand.Argument?] = [entitlementsFileArg,
                                          icloudContainerIdentifiersArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "update_icloud_container_identifiers", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Update a Info.plist file with bundle identifier and display name

 - parameters:
   - xcodeproj: Path to your Xcode project
   - plistPath: Path to info plist
   - scheme: Scheme of info plist
   - appIdentifier: The App Identifier of your app
   - displayName: The Display Name of your app
   - block: A block to process plist with custom logic

 This action allows you to modify your `Info.plist` file before building. This may be useful if you want a separate build for alpha, beta or nightly builds, but don't want a separate target.
 */
public func updateInfoPlist(xcodeproj: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            plistPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            scheme: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            appIdentifier: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            displayName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            block: ((String) -> Void)? = nil)
{
    let xcodeprojArg = xcodeproj.asRubyArgument(name: "xcodeproj", type: nil)
    let plistPathArg = plistPath.asRubyArgument(name: "plist_path", type: nil)
    let schemeArg = scheme.asRubyArgument(name: "scheme", type: nil)
    let appIdentifierArg = appIdentifier.asRubyArgument(name: "app_identifier", type: nil)
    let displayNameArg = displayName.asRubyArgument(name: "display_name", type: nil)
    let blockArg = RubyCommand.Argument(name: "block", value: block, type: .stringClosure)
    let array: [RubyCommand.Argument?] = [xcodeprojArg,
                                          plistPathArg,
                                          schemeArg,
                                          appIdentifierArg,
                                          displayNameArg,
                                          blockArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "update_info_plist", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 This action changes the keychain access groups in the entitlements file

 - parameters:
   - entitlementsFile: The path to the entitlement file which contains the keychain access groups
   - identifiers: An Array of unique identifiers for the keychain access groups. Eg. ['your.keychain.access.groups.identifiers']

 Updates the Keychain Group Access Groups in the given Entitlements file, so you can have keychain access groups for the app store build and keychain access groups for an enterprise build.
 */
public func updateKeychainAccessGroups(entitlementsFile: String,
                                       identifiers: [String])
{
    let entitlementsFileArg = RubyCommand.Argument(name: "entitlements_file", value: entitlementsFile, type: nil)
    let identifiersArg = RubyCommand.Argument(name: "identifiers", value: identifiers, type: nil)
    let array: [RubyCommand.Argument?] = [entitlementsFileArg,
                                          identifiersArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "update_keychain_access_groups", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Update a plist file

 - parameters:
   - plistPath: Path to plist file
   - block: A block to process plist with custom logic

 This action allows you to modify any value inside any `plist` file.
 */
public func updatePlist(plistPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                        block: ((String) -> Void)? = nil)
{
    let plistPathArg = plistPath.asRubyArgument(name: "plist_path", type: nil)
    let blockArg = RubyCommand.Argument(name: "block", value: block, type: .stringClosure)
    let array: [RubyCommand.Argument?] = [plistPathArg,
                                          blockArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "update_plist", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Updated code signing settings from 'Automatic' to a specific profile

 - parameters:
   - path: Path to your Xcode project
   - udid: **DEPRECATED!** Use `:uuid` instead
   - uuid: The UUID of the provisioning profile you want to use
 */
public func updateProjectCodeSigning(path: String,
                                     udid: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                     uuid: String)
{
    let pathArg = RubyCommand.Argument(name: "path", value: path, type: nil)
    let udidArg = udid.asRubyArgument(name: "udid", type: nil)
    let uuidArg = RubyCommand.Argument(name: "uuid", value: uuid, type: nil)
    let array: [RubyCommand.Argument?] = [pathArg,
                                          udidArg,
                                          uuidArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "update_project_code_signing", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Update projects code signing settings from your provisioning profile

 - parameters:
   - xcodeproj: Path to your Xcode project
   - profile: Path to provisioning profile (.mobileprovision)
   - targetFilter: A filter for the target name. Use a standard regex
   - buildConfigurationFilter: Legacy option, use 'target_filter' instead
   - buildConfiguration: A filter for the build configuration name. Use a standard regex. Applied to all configurations if not specified
   - certificate: Path to apple root certificate
   - codeSigningIdentity: Code sign identity for build configuration

 You should check out the [code signing guide](https://docs.fastlane.tools/codesigning/getting-started/) before using this action.
 This action retrieves a provisioning profile UUID from a provisioning profile (`.mobileprovision`) to set up the Xcode projects' code signing settings in `*.xcodeproj/project.pbxproj`.
 The `:target_filter` value can be used to only update code signing for the specified targets.
 The `:build_configuration` value can be used to only update code signing for the specified build configurations of the targets passing through the `:target_filter`.
 Example usage is the WatchKit Extension or WatchKit App, where you need separate provisioning profiles.
 Example: `update_project_provisioning(xcodeproj: "..", target_filter: ".*WatchKit App.*")`.
 */
public func updateProjectProvisioning(xcodeproj: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                      profile: String,
                                      targetFilter: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                      buildConfigurationFilter: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                      buildConfiguration: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                      certificate: String = "/tmp/AppleIncRootCertificate.cer",
                                      codeSigningIdentity: OptionalConfigValue<String?> = .fastlaneDefault(nil))
{
    let xcodeprojArg = xcodeproj.asRubyArgument(name: "xcodeproj", type: nil)
    let profileArg = RubyCommand.Argument(name: "profile", value: profile, type: nil)
    let targetFilterArg = targetFilter.asRubyArgument(name: "target_filter", type: nil)
    let buildConfigurationFilterArg = buildConfigurationFilter.asRubyArgument(name: "build_configuration_filter", type: nil)
    let buildConfigurationArg = buildConfiguration.asRubyArgument(name: "build_configuration", type: nil)
    let certificateArg = RubyCommand.Argument(name: "certificate", value: certificate, type: nil)
    let codeSigningIdentityArg = codeSigningIdentity.asRubyArgument(name: "code_signing_identity", type: nil)
    let array: [RubyCommand.Argument?] = [xcodeprojArg,
                                          profileArg,
                                          targetFilterArg,
                                          buildConfigurationFilterArg,
                                          buildConfigurationArg,
                                          certificateArg,
                                          codeSigningIdentityArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "update_project_provisioning", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Update Xcode Development Team ID

 - parameters:
   - path: Path to your Xcode project
   - targets: Name of the targets you want to update
   - teamid: The Team ID you want to use

 This action updates the Developer Team ID of your Xcode project.
 */
public func updateProjectTeam(path: String,
                              targets: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                              teamid: String)
{
    let pathArg = RubyCommand.Argument(name: "path", value: path, type: nil)
    let targetsArg = targets.asRubyArgument(name: "targets", type: nil)
    let teamidArg = RubyCommand.Argument(name: "teamid", value: teamid, type: nil)
    let array: [RubyCommand.Argument?] = [pathArg,
                                          targetsArg,
                                          teamidArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "update_project_team", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Set [Urban Airship](https://www.urbanairship.com/) plist configuration values

 - parameters:
   - plistPath: Path to Urban Airship configuration Plist
   - developmentAppKey: The development app key
   - developmentAppSecret: The development app secret
   - productionAppKey: The production app key
   - productionAppSecret: The production app secret
   - detectProvisioningMode: Automatically detect provisioning mode

 This action updates the `AirshipConfig.plist` needed to configure the Urban Airship SDK at runtime, allowing keys and secrets to easily be set for the Enterprise and Production versions of the application.
 */
public func updateUrbanAirshipConfiguration(plistPath: String,
                                            developmentAppKey: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                            developmentAppSecret: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                            productionAppKey: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                            productionAppSecret: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                            detectProvisioningMode: OptionalConfigValue<Bool?> = .fastlaneDefault(nil))
{
    let plistPathArg = RubyCommand.Argument(name: "plist_path", value: plistPath, type: nil)
    let developmentAppKeyArg = developmentAppKey.asRubyArgument(name: "development_app_key", type: nil)
    let developmentAppSecretArg = developmentAppSecret.asRubyArgument(name: "development_app_secret", type: nil)
    let productionAppKeyArg = productionAppKey.asRubyArgument(name: "production_app_key", type: nil)
    let productionAppSecretArg = productionAppSecret.asRubyArgument(name: "production_app_secret", type: nil)
    let detectProvisioningModeArg = detectProvisioningMode.asRubyArgument(name: "detect_provisioning_mode", type: nil)
    let array: [RubyCommand.Argument?] = [plistPathArg,
                                          developmentAppKeyArg,
                                          developmentAppSecretArg,
                                          productionAppKeyArg,
                                          productionAppSecretArg,
                                          detectProvisioningModeArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "update_urban_airship_configuration", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Updates the URL schemes in the given Info.plist

 - parameters:
   - path: The Plist file's path
   - urlSchemes: The new URL schemes
   - updateUrlSchemes: Block that is called to update schemes with current schemes passed in as parameter

 This action allows you to update the URL schemes of the app before building it.
 For example, you can use this to set a different URL scheme for the alpha or beta version of the app.
 */
public func updateUrlSchemes(path: String,
                             urlSchemes: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                             updateUrlSchemes: ((String) -> Void)? = nil)
{
    let pathArg = RubyCommand.Argument(name: "path", value: path, type: nil)
    let urlSchemesArg = urlSchemes.asRubyArgument(name: "url_schemes", type: nil)
    let updateUrlSchemesArg = RubyCommand.Argument(name: "update_url_schemes", value: updateUrlSchemes, type: .stringClosure)
    let array: [RubyCommand.Argument?] = [pathArg,
                                          urlSchemesArg,
                                          updateUrlSchemesArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "update_url_schemes", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Upload App Privacy Details for an app in App Store Connect

 - parameters:
   - username: Your Apple ID Username for App Store Connect
   - appIdentifier: The bundle identifier of your app
   - teamId: The ID of your App Store Connect team if you're in multiple teams
   - teamName: The name of your App Store Connect team if you're in multiple teams
   - jsonPath: Path to the app usage data JSON
   - outputJsonPath: Path to the app usage data JSON file generated by interactive questions
   - skipJsonFileSaving: Whether to skip the saving of the JSON file
   - skipUpload: Whether to skip the upload and only create the JSON file with interactive questions
   - skipPublish: Whether to skip the publishing

 Upload App Privacy Details for an app in App Store Connect. For more detail information, view https://docs.fastlane.tools/uploading-app-privacy-details
 */
public func uploadAppPrivacyDetailsToAppStore(username: String,
                                              appIdentifier: String,
                                              teamId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                              teamName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                              jsonPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                              outputJsonPath: String = "./fastlane/app_privacy_details.json",
                                              skipJsonFileSaving: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                              skipUpload: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                              skipPublish: OptionalConfigValue<Bool> = .fastlaneDefault(false))
{
    let usernameArg = RubyCommand.Argument(name: "username", value: username, type: nil)
    let appIdentifierArg = RubyCommand.Argument(name: "app_identifier", value: appIdentifier, type: nil)
    let teamIdArg = teamId.asRubyArgument(name: "team_id", type: nil)
    let teamNameArg = teamName.asRubyArgument(name: "team_name", type: nil)
    let jsonPathArg = jsonPath.asRubyArgument(name: "json_path", type: nil)
    let outputJsonPathArg = RubyCommand.Argument(name: "output_json_path", value: outputJsonPath, type: nil)
    let skipJsonFileSavingArg = skipJsonFileSaving.asRubyArgument(name: "skip_json_file_saving", type: nil)
    let skipUploadArg = skipUpload.asRubyArgument(name: "skip_upload", type: nil)
    let skipPublishArg = skipPublish.asRubyArgument(name: "skip_publish", type: nil)
    let array: [RubyCommand.Argument?] = [usernameArg,
                                          appIdentifierArg,
                                          teamIdArg,
                                          teamNameArg,
                                          jsonPathArg,
                                          outputJsonPathArg,
                                          skipJsonFileSavingArg,
                                          skipUploadArg,
                                          skipPublishArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "upload_app_privacy_details_to_app_store", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Upload dSYM symbolication files to Crashlytics

 - parameters:
   - dsymPath: Path to the DSYM file or zip to upload
   - dsymPaths: Paths to the DSYM files or zips to upload
   - apiToken: Crashlytics API Key
   - gspPath: Path to GoogleService-Info.plist
   - appId: Firebase Crashlytics APP ID
   - binaryPath: The path to the upload-symbols file of the Fabric app
   - platform: The platform of the app (ios, appletvos, mac)
   - dsymWorkerThreads: The number of threads to use for simultaneous dSYM upload
   - debug: Enable debug mode for upload-symbols

 This action allows you to upload symbolication files to Crashlytics. It's extra useful if you use it to download the latest dSYM files from Apple when you use Bitcode. This action will not fail the build if one of the uploads failed. The reason for that is that sometimes some of dSYM files are invalid, and we don't want them to fail the complete build.
 */
public func uploadSymbolsToCrashlytics(dsymPath: String = "./spec/fixtures/dSYM/Themoji2.dSYM",
                                       dsymPaths: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                                       apiToken: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                       gspPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                       appId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                       binaryPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                       platform: String = "ios",
                                       dsymWorkerThreads: Int = 1,
                                       debug: OptionalConfigValue<Bool> = .fastlaneDefault(false))
{
    let dsymPathArg = RubyCommand.Argument(name: "dsym_path", value: dsymPath, type: nil)
    let dsymPathsArg = dsymPaths.asRubyArgument(name: "dsym_paths", type: nil)
    let apiTokenArg = apiToken.asRubyArgument(name: "api_token", type: nil)
    let gspPathArg = gspPath.asRubyArgument(name: "gsp_path", type: nil)
    let appIdArg = appId.asRubyArgument(name: "app_id", type: nil)
    let binaryPathArg = binaryPath.asRubyArgument(name: "binary_path", type: nil)
    let platformArg = RubyCommand.Argument(name: "platform", value: platform, type: nil)
    let dsymWorkerThreadsArg = RubyCommand.Argument(name: "dsym_worker_threads", value: dsymWorkerThreads, type: nil)
    let debugArg = debug.asRubyArgument(name: "debug", type: nil)
    let array: [RubyCommand.Argument?] = [dsymPathArg,
                                          dsymPathsArg,
                                          apiTokenArg,
                                          gspPathArg,
                                          appIdArg,
                                          binaryPathArg,
                                          platformArg,
                                          dsymWorkerThreadsArg,
                                          debugArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "upload_symbols_to_crashlytics", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Upload dSYM symbolication files to Sentry

 - parameters:
   - apiHost: API host url for Sentry
   - apiKey: API key for Sentry
   - authToken: Authentication token for Sentry
   - orgSlug: Organization slug for Sentry project
   - projectSlug: Project slug for Sentry
   - dsymPath: Path to your symbols file. For iOS and Mac provide path to app.dSYM.zip
   - dsymPaths: Path to an array of your symbols file. For iOS and Mac provide path to app.dSYM.zip

 - returns: The uploaded dSYM path(s)

 This action allows you to upload symbolication files to Sentry. It's extra useful if you use it to download the latest dSYM files from Apple when you use Bitcode.
 */
public func uploadSymbolsToSentry(apiHost: String = "https://app.getsentry.com/api/0",
                                  apiKey: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  authToken: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  orgSlug: String,
                                  projectSlug: String,
                                  dsymPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  dsymPaths: OptionalConfigValue<[String]?> = .fastlaneDefault(nil))
{
    let apiHostArg = RubyCommand.Argument(name: "api_host", value: apiHost, type: nil)
    let apiKeyArg = apiKey.asRubyArgument(name: "api_key", type: nil)
    let authTokenArg = authToken.asRubyArgument(name: "auth_token", type: nil)
    let orgSlugArg = RubyCommand.Argument(name: "org_slug", value: orgSlug, type: nil)
    let projectSlugArg = RubyCommand.Argument(name: "project_slug", value: projectSlug, type: nil)
    let dsymPathArg = dsymPath.asRubyArgument(name: "dsym_path", type: nil)
    let dsymPathsArg = dsymPaths.asRubyArgument(name: "dsym_paths", type: nil)
    let array: [RubyCommand.Argument?] = [apiHostArg,
                                          apiKeyArg,
                                          authTokenArg,
                                          orgSlugArg,
                                          projectSlugArg,
                                          dsymPathArg,
                                          dsymPathsArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "upload_symbols_to_sentry", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Upload metadata and binary to App Store Connect (via _deliver_)

 - parameters:
   - apiKeyPath: Path to your App Store Connect API Key JSON file (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-json-file)
   - apiKey: Your App Store Connect API Key information (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-hash-option)
   - username: Your Apple ID Username
   - appIdentifier: The bundle identifier of your app
   - appVersion: The version that should be edited or created
   - ipa: Path to your ipa file
   - pkg: Path to your pkg file
   - buildNumber: If set the given build number (already uploaded to iTC) will be used instead of the current built one
   - platform: The platform to use (optional)
   - editLive: Modify live metadata, this option disables ipa upload and screenshot upload
   - useLiveVersion: Force usage of live version rather than edit version
   - metadataPath: Path to the folder containing the metadata files
   - screenshotsPath: Path to the folder containing the screenshots
   - skipBinaryUpload: Skip uploading an ipa or pkg to App Store Connect
   - skipScreenshots: Don't upload the screenshots
   - skipMetadata: Don't upload the metadata (e.g. title, description). This will still upload screenshots
   - skipAppVersionUpdate: Don’t create or update the app version that is being prepared for submission
   - force: Skip verification of HTML preview file
   - overwriteScreenshots: Clear all previously uploaded screenshots before uploading the new ones
   - screenshotProcessingTimeout: Timeout in seconds to wait before considering screenshot processing as failed, used to handle cases where uploads to the App Store are stuck in processing
   - syncScreenshots: Sync screenshots with local ones. This is currently beta option so set true to 'FASTLANE_ENABLE_BETA_DELIVER_SYNC_SCREENSHOTS' environment variable as well
   - submitForReview: Submit the new version for Review after uploading everything
   - verifyOnly: Verifies archive with App Store Connect without uploading
   - rejectIfPossible: Rejects the previously submitted build if it's in a state where it's possible
   - versionCheckWaitRetryLimit: After submitting a new version, App Store Connect takes some time to recognize the new version and we must wait until it's available before attempting to upload metadata for it. There is a mechanism that will check if it's available and retry with an exponential backoff if it's not available yet. This option specifies how many times we should retry before giving up. Setting this to a value below 5 is not recommended and will likely cause failures. Increase this parameter when Apple servers seem to be degraded or slow
   - automaticRelease: Should the app be automatically released once it's approved? (Cannot be used together with `auto_release_date`)
   - autoReleaseDate: Date in milliseconds for automatically releasing on pending approval (Cannot be used together with `automatic_release`)
   - phasedRelease: Enable the phased release feature of iTC
   - resetRatings: Reset the summary rating when you release a new version of the application
   - priceTier: The price tier of this application
   - appRatingConfigPath: Path to the app rating's config
   - submissionInformation: Extra information for the submission (e.g. compliance specifications)
   - teamId: The ID of your App Store Connect team if you're in multiple teams
   - teamName: The name of your App Store Connect team if you're in multiple teams
   - devPortalTeamId: The short ID of your Developer Portal team, if you're in multiple teams. Different from your iTC team ID!
   - devPortalTeamName: The name of your Developer Portal team if you're in multiple teams
   - itcProvider: The provider short name to be used with the iTMSTransporter to identify your team. This value will override the automatically detected provider short name. To get provider short name run `xcrun iTMSTransporter -m provider -u 'USERNAME' -p 'PASSWORD' -account_type itunes_connect -v off`. The short names of providers should be listed in the second column
   - runPrecheckBeforeSubmit: Run precheck before submitting to app review
   - precheckDefaultRuleLevel: The default precheck rule level unless otherwise configured
   - individualMetadataItems: **DEPRECATED!** Removed after the migration to the new App Store Connect API in June 2020 - An array of localized metadata items to upload individually by language so that errors can be identified. E.g. ['name', 'keywords', 'description']. Note: slow
   - appIcon: **DEPRECATED!** Removed after the migration to the new App Store Connect API in June 2020 - Metadata: The path to the app icon
   - appleWatchAppIcon: **DEPRECATED!** Removed after the migration to the new App Store Connect API in June 2020 - Metadata: The path to the Apple Watch app icon
   - copyright: Metadata: The copyright notice
   - primaryCategory: Metadata: The english name of the primary category (e.g. `Business`, `Books`)
   - secondaryCategory: Metadata: The english name of the secondary category (e.g. `Business`, `Books`)
   - primaryFirstSubCategory: Metadata: The english name of the primary first sub category (e.g. `Educational`, `Puzzle`)
   - primarySecondSubCategory: Metadata: The english name of the primary second sub category (e.g. `Educational`, `Puzzle`)
   - secondaryFirstSubCategory: Metadata: The english name of the secondary first sub category (e.g. `Educational`, `Puzzle`)
   - secondarySecondSubCategory: Metadata: The english name of the secondary second sub category (e.g. `Educational`, `Puzzle`)
   - tradeRepresentativeContactInformation: **DEPRECATED!** This is no longer used by App Store Connect - Metadata: A hash containing the trade representative contact information
   - appReviewInformation: Metadata: A hash containing the review information
   - appReviewAttachmentFile: Metadata: Path to the app review attachment file
   - description: Metadata: The localised app description
   - name: Metadata: The localised app name
   - subtitle: Metadata: The localised app subtitle
   - keywords: Metadata: An array of localised keywords
   - promotionalText: Metadata: An array of localised promotional texts
   - releaseNotes: Metadata: Localised release notes for this version
   - privacyUrl: Metadata: Localised privacy url
   - appleTvPrivacyPolicy: Metadata: Localised Apple TV privacy policy text
   - supportUrl: Metadata: Localised support url
   - marketingUrl: Metadata: Localised marketing url
   - languages: Metadata: List of languages to activate
   - ignoreLanguageDirectoryValidation: Ignore errors when invalid languages are found in metadata and screenshot directories
   - precheckIncludeInAppPurchases: Should precheck check in-app purchases?
   - app: The (spaceship) app ID of the app you want to use/modify

 Using _upload_to_app_store_ after _build_app_ and _capture_screenshots_ will automatically upload the latest ipa and screenshots with no other configuration.

 If you don't want to verify an HTML preview for App Store builds, use the `:force` option.
 This is useful when running _fastlane_ on your Continuous Integration server:
 `_upload_to_app_store_(force: true)`
 If your account is on multiple teams and you need to tell the `iTMSTransporter` which 'provider' to use, you can set the `:itc_provider` option to pass this info.
 */
public func uploadToAppStore(apiKeyPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             apiKey: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                             username: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             appIdentifier: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             appVersion: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             ipa: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             pkg: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             buildNumber: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             platform: String = "ios",
                             editLive: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                             useLiveVersion: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                             metadataPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             screenshotsPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             skipBinaryUpload: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                             skipScreenshots: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                             skipMetadata: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                             skipAppVersionUpdate: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                             force: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                             overwriteScreenshots: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                             screenshotProcessingTimeout: Int = 3600,
                             syncScreenshots: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                             submitForReview: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                             verifyOnly: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                             rejectIfPossible: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                             versionCheckWaitRetryLimit: Int = 7,
                             automaticRelease: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                             autoReleaseDate: OptionalConfigValue<Int?> = .fastlaneDefault(nil),
                             phasedRelease: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                             resetRatings: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                             priceTier: OptionalConfigValue<Int?> = .fastlaneDefault(nil),
                             appRatingConfigPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             submissionInformation: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                             teamId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             teamName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             devPortalTeamId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             devPortalTeamName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             itcProvider: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             runPrecheckBeforeSubmit: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                             precheckDefaultRuleLevel: String = "warn",
                             individualMetadataItems: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                             appIcon: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             appleWatchAppIcon: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             copyright: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             primaryCategory: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             secondaryCategory: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             primaryFirstSubCategory: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             primarySecondSubCategory: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             secondaryFirstSubCategory: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             secondarySecondSubCategory: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             tradeRepresentativeContactInformation: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                             appReviewInformation: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                             appReviewAttachmentFile: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             description: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                             name: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                             subtitle: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                             keywords: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                             promotionalText: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                             releaseNotes: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                             privacyUrl: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                             appleTvPrivacyPolicy: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                             supportUrl: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                             marketingUrl: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                             languages: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                             ignoreLanguageDirectoryValidation: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                             precheckIncludeInAppPurchases: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                             app: OptionalConfigValue<Int?> = .fastlaneDefault(nil))
{
    let apiKeyPathArg = apiKeyPath.asRubyArgument(name: "api_key_path", type: nil)
    let apiKeyArg = apiKey.asRubyArgument(name: "api_key", type: nil)
    let usernameArg = username.asRubyArgument(name: "username", type: nil)
    let appIdentifierArg = appIdentifier.asRubyArgument(name: "app_identifier", type: nil)
    let appVersionArg = appVersion.asRubyArgument(name: "app_version", type: nil)
    let ipaArg = ipa.asRubyArgument(name: "ipa", type: nil)
    let pkgArg = pkg.asRubyArgument(name: "pkg", type: nil)
    let buildNumberArg = buildNumber.asRubyArgument(name: "build_number", type: nil)
    let platformArg = RubyCommand.Argument(name: "platform", value: platform, type: nil)
    let editLiveArg = editLive.asRubyArgument(name: "edit_live", type: nil)
    let useLiveVersionArg = useLiveVersion.asRubyArgument(name: "use_live_version", type: nil)
    let metadataPathArg = metadataPath.asRubyArgument(name: "metadata_path", type: nil)
    let screenshotsPathArg = screenshotsPath.asRubyArgument(name: "screenshots_path", type: nil)
    let skipBinaryUploadArg = skipBinaryUpload.asRubyArgument(name: "skip_binary_upload", type: nil)
    let skipScreenshotsArg = skipScreenshots.asRubyArgument(name: "skip_screenshots", type: nil)
    let skipMetadataArg = skipMetadata.asRubyArgument(name: "skip_metadata", type: nil)
    let skipAppVersionUpdateArg = skipAppVersionUpdate.asRubyArgument(name: "skip_app_version_update", type: nil)
    let forceArg = force.asRubyArgument(name: "force", type: nil)
    let overwriteScreenshotsArg = overwriteScreenshots.asRubyArgument(name: "overwrite_screenshots", type: nil)
    let screenshotProcessingTimeoutArg = RubyCommand.Argument(name: "screenshot_processing_timeout", value: screenshotProcessingTimeout, type: nil)
    let syncScreenshotsArg = syncScreenshots.asRubyArgument(name: "sync_screenshots", type: nil)
    let submitForReviewArg = submitForReview.asRubyArgument(name: "submit_for_review", type: nil)
    let verifyOnlyArg = verifyOnly.asRubyArgument(name: "verify_only", type: nil)
    let rejectIfPossibleArg = rejectIfPossible.asRubyArgument(name: "reject_if_possible", type: nil)
    let versionCheckWaitRetryLimitArg = RubyCommand.Argument(name: "version_check_wait_retry_limit", value: versionCheckWaitRetryLimit, type: nil)
    let automaticReleaseArg = automaticRelease.asRubyArgument(name: "automatic_release", type: nil)
    let autoReleaseDateArg = autoReleaseDate.asRubyArgument(name: "auto_release_date", type: nil)
    let phasedReleaseArg = phasedRelease.asRubyArgument(name: "phased_release", type: nil)
    let resetRatingsArg = resetRatings.asRubyArgument(name: "reset_ratings", type: nil)
    let priceTierArg = priceTier.asRubyArgument(name: "price_tier", type: nil)
    let appRatingConfigPathArg = appRatingConfigPath.asRubyArgument(name: "app_rating_config_path", type: nil)
    let submissionInformationArg = submissionInformation.asRubyArgument(name: "submission_information", type: nil)
    let teamIdArg = teamId.asRubyArgument(name: "team_id", type: nil)
    let teamNameArg = teamName.asRubyArgument(name: "team_name", type: nil)
    let devPortalTeamIdArg = devPortalTeamId.asRubyArgument(name: "dev_portal_team_id", type: nil)
    let devPortalTeamNameArg = devPortalTeamName.asRubyArgument(name: "dev_portal_team_name", type: nil)
    let itcProviderArg = itcProvider.asRubyArgument(name: "itc_provider", type: nil)
    let runPrecheckBeforeSubmitArg = runPrecheckBeforeSubmit.asRubyArgument(name: "run_precheck_before_submit", type: nil)
    let precheckDefaultRuleLevelArg = RubyCommand.Argument(name: "precheck_default_rule_level", value: precheckDefaultRuleLevel, type: nil)
    let individualMetadataItemsArg = individualMetadataItems.asRubyArgument(name: "individual_metadata_items", type: nil)
    let appIconArg = appIcon.asRubyArgument(name: "app_icon", type: nil)
    let appleWatchAppIconArg = appleWatchAppIcon.asRubyArgument(name: "apple_watch_app_icon", type: nil)
    let copyrightArg = copyright.asRubyArgument(name: "copyright", type: nil)
    let primaryCategoryArg = primaryCategory.asRubyArgument(name: "primary_category", type: nil)
    let secondaryCategoryArg = secondaryCategory.asRubyArgument(name: "secondary_category", type: nil)
    let primaryFirstSubCategoryArg = primaryFirstSubCategory.asRubyArgument(name: "primary_first_sub_category", type: nil)
    let primarySecondSubCategoryArg = primarySecondSubCategory.asRubyArgument(name: "primary_second_sub_category", type: nil)
    let secondaryFirstSubCategoryArg = secondaryFirstSubCategory.asRubyArgument(name: "secondary_first_sub_category", type: nil)
    let secondarySecondSubCategoryArg = secondarySecondSubCategory.asRubyArgument(name: "secondary_second_sub_category", type: nil)
    let tradeRepresentativeContactInformationArg = tradeRepresentativeContactInformation.asRubyArgument(name: "trade_representative_contact_information", type: nil)
    let appReviewInformationArg = appReviewInformation.asRubyArgument(name: "app_review_information", type: nil)
    let appReviewAttachmentFileArg = appReviewAttachmentFile.asRubyArgument(name: "app_review_attachment_file", type: nil)
    let descriptionArg = description.asRubyArgument(name: "description", type: nil)
    let nameArg = name.asRubyArgument(name: "name", type: nil)
    let subtitleArg = subtitle.asRubyArgument(name: "subtitle", type: nil)
    let keywordsArg = keywords.asRubyArgument(name: "keywords", type: nil)
    let promotionalTextArg = promotionalText.asRubyArgument(name: "promotional_text", type: nil)
    let releaseNotesArg = releaseNotes.asRubyArgument(name: "release_notes", type: nil)
    let privacyUrlArg = privacyUrl.asRubyArgument(name: "privacy_url", type: nil)
    let appleTvPrivacyPolicyArg = appleTvPrivacyPolicy.asRubyArgument(name: "apple_tv_privacy_policy", type: nil)
    let supportUrlArg = supportUrl.asRubyArgument(name: "support_url", type: nil)
    let marketingUrlArg = marketingUrl.asRubyArgument(name: "marketing_url", type: nil)
    let languagesArg = languages.asRubyArgument(name: "languages", type: nil)
    let ignoreLanguageDirectoryValidationArg = ignoreLanguageDirectoryValidation.asRubyArgument(name: "ignore_language_directory_validation", type: nil)
    let precheckIncludeInAppPurchasesArg = precheckIncludeInAppPurchases.asRubyArgument(name: "precheck_include_in_app_purchases", type: nil)
    let appArg = app.asRubyArgument(name: "app", type: nil)
    let array: [RubyCommand.Argument?] = [apiKeyPathArg,
                                          apiKeyArg,
                                          usernameArg,
                                          appIdentifierArg,
                                          appVersionArg,
                                          ipaArg,
                                          pkgArg,
                                          buildNumberArg,
                                          platformArg,
                                          editLiveArg,
                                          useLiveVersionArg,
                                          metadataPathArg,
                                          screenshotsPathArg,
                                          skipBinaryUploadArg,
                                          skipScreenshotsArg,
                                          skipMetadataArg,
                                          skipAppVersionUpdateArg,
                                          forceArg,
                                          overwriteScreenshotsArg,
                                          screenshotProcessingTimeoutArg,
                                          syncScreenshotsArg,
                                          submitForReviewArg,
                                          verifyOnlyArg,
                                          rejectIfPossibleArg,
                                          versionCheckWaitRetryLimitArg,
                                          automaticReleaseArg,
                                          autoReleaseDateArg,
                                          phasedReleaseArg,
                                          resetRatingsArg,
                                          priceTierArg,
                                          appRatingConfigPathArg,
                                          submissionInformationArg,
                                          teamIdArg,
                                          teamNameArg,
                                          devPortalTeamIdArg,
                                          devPortalTeamNameArg,
                                          itcProviderArg,
                                          runPrecheckBeforeSubmitArg,
                                          precheckDefaultRuleLevelArg,
                                          individualMetadataItemsArg,
                                          appIconArg,
                                          appleWatchAppIconArg,
                                          copyrightArg,
                                          primaryCategoryArg,
                                          secondaryCategoryArg,
                                          primaryFirstSubCategoryArg,
                                          primarySecondSubCategoryArg,
                                          secondaryFirstSubCategoryArg,
                                          secondarySecondSubCategoryArg,
                                          tradeRepresentativeContactInformationArg,
                                          appReviewInformationArg,
                                          appReviewAttachmentFileArg,
                                          descriptionArg,
                                          nameArg,
                                          subtitleArg,
                                          keywordsArg,
                                          promotionalTextArg,
                                          releaseNotesArg,
                                          privacyUrlArg,
                                          appleTvPrivacyPolicyArg,
                                          supportUrlArg,
                                          marketingUrlArg,
                                          languagesArg,
                                          ignoreLanguageDirectoryValidationArg,
                                          precheckIncludeInAppPurchasesArg,
                                          appArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "upload_to_app_store", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Upload metadata, screenshots and binaries to Google Play (via _supply_)

 - parameters:
   - packageName: The package name of the application to use
   - versionName: Version name (used when uploading new apks/aabs) - defaults to 'versionName' in build.gradle or AndroidManifest.xml
   - versionCode: The versionCode for which to download the generated APK
   - releaseStatus: Release status (used when uploading new apks/aabs) - valid values are completed, draft, halted, inProgress
   - track: The track of the application to use. The default available tracks are: production, beta, alpha, internal
   - rollout: The percentage of the user fraction when uploading to the rollout track (setting to 1 will complete the rollout)
   - metadataPath: Path to the directory containing the metadata files
   - key: **DEPRECATED!** Use `--json_key` instead - The p12 File used to authenticate with Google
   - issuer: **DEPRECATED!** Use `--json_key` instead - The issuer of the p12 file (email address of the service account)
   - jsonKey: The path to a file containing service account JSON, used to authenticate with Google
   - jsonKeyData: The raw service account JSON data used to authenticate with Google
   - apk: Path to the APK file to upload
   - apkPaths: An array of paths to APK files to upload
   - aab: Path to the AAB file to upload
   - aabPaths: An array of paths to AAB files to upload
   - skipUploadApk: Whether to skip uploading APK
   - skipUploadAab: Whether to skip uploading AAB
   - skipUploadMetadata: Whether to skip uploading metadata, changelogs not included
   - skipUploadChangelogs: Whether to skip uploading changelogs
   - skipUploadImages: Whether to skip uploading images, screenshots not included
   - skipUploadScreenshots: Whether to skip uploading SCREENSHOTS
   - syncImageUpload: Whether to use sha256 comparison to skip upload of images and screenshots that are already in Play Store
   - trackPromoteTo: The track to promote to. The default available tracks are: production, beta, alpha, internal
   - trackPromoteReleaseStatus: Promoted track release status (used when promoting a track) - valid values are completed, draft, halted, inProgress
   - validateOnly: Only validate changes with Google Play rather than actually publish
   - mapping: Path to the mapping file to upload (mapping.txt or native-debug-symbols.zip alike)
   - mappingPaths: An array of paths to mapping files to upload (mapping.txt or native-debug-symbols.zip alike)
   - rootUrl: Root URL for the Google Play API. The provided URL will be used for API calls in place of https://www.googleapis.com/
   - checkSupersededTracks: **DEPRECATED!** Google Play does this automatically now - Check the other tracks for superseded versions and disable them
   - timeout: Timeout for read, open, and send (in seconds)
   - deactivateOnPromote: **DEPRECATED!** Google Play does this automatically now - When promoting to a new track, deactivate the binary in the origin track
   - versionCodesToRetain: An array of version codes to retain when publishing a new APK
   - changesNotSentForReview: Indicates that the changes in this edit will not be reviewed until they are explicitly sent for review from the Google Play Console UI
   - rescueChangesNotSentForReview: Catches changes_not_sent_for_review errors when an edit is committed and retries with the configuration that the error message recommended
   - inAppUpdatePriority: In-app update priority for all the newly added apks in the release. Can take values between [0,5]
   - obbMainReferencesVersion: References version of 'main' expansion file
   - obbMainFileSize: Size of 'main' expansion file in bytes
   - obbPatchReferencesVersion: References version of 'patch' expansion file
   - obbPatchFileSize: Size of 'patch' expansion file in bytes
   - ackBundleInstallationWarning: Must be set to true if the bundle installation may trigger a warning on user devices (e.g can only be downloaded over wifi). Typically this is required for bundles over 150MB

 More information: https://docs.fastlane.tools/actions/supply/
 */
public func uploadToPlayStore(packageName: String,
                              versionName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                              versionCode: OptionalConfigValue<Int?> = .fastlaneDefault(nil),
                              releaseStatus: String = "completed",
                              track: String = "production",
                              rollout: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                              metadataPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                              key: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                              issuer: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                              jsonKey: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                              jsonKeyData: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                              apk: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                              apkPaths: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                              aab: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                              aabPaths: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                              skipUploadApk: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                              skipUploadAab: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                              skipUploadMetadata: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                              skipUploadChangelogs: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                              skipUploadImages: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                              skipUploadScreenshots: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                              syncImageUpload: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                              trackPromoteTo: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                              trackPromoteReleaseStatus: String = "completed",
                              validateOnly: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                              mapping: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                              mappingPaths: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                              rootUrl: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                              checkSupersededTracks: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                              timeout: Int = 300,
                              deactivateOnPromote: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                              versionCodesToRetain: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                              changesNotSentForReview: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                              rescueChangesNotSentForReview: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                              inAppUpdatePriority: OptionalConfigValue<Int?> = .fastlaneDefault(nil),
                              obbMainReferencesVersion: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                              obbMainFileSize: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                              obbPatchReferencesVersion: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                              obbPatchFileSize: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                              ackBundleInstallationWarning: OptionalConfigValue<Bool> = .fastlaneDefault(false))
{
    let packageNameArg = RubyCommand.Argument(name: "package_name", value: packageName, type: nil)
    let versionNameArg = versionName.asRubyArgument(name: "version_name", type: nil)
    let versionCodeArg = versionCode.asRubyArgument(name: "version_code", type: nil)
    let releaseStatusArg = RubyCommand.Argument(name: "release_status", value: releaseStatus, type: nil)
    let trackArg = RubyCommand.Argument(name: "track", value: track, type: nil)
    let rolloutArg = rollout.asRubyArgument(name: "rollout", type: nil)
    let metadataPathArg = metadataPath.asRubyArgument(name: "metadata_path", type: nil)
    let keyArg = key.asRubyArgument(name: "key", type: nil)
    let issuerArg = issuer.asRubyArgument(name: "issuer", type: nil)
    let jsonKeyArg = jsonKey.asRubyArgument(name: "json_key", type: nil)
    let jsonKeyDataArg = jsonKeyData.asRubyArgument(name: "json_key_data", type: nil)
    let apkArg = apk.asRubyArgument(name: "apk", type: nil)
    let apkPathsArg = apkPaths.asRubyArgument(name: "apk_paths", type: nil)
    let aabArg = aab.asRubyArgument(name: "aab", type: nil)
    let aabPathsArg = aabPaths.asRubyArgument(name: "aab_paths", type: nil)
    let skipUploadApkArg = skipUploadApk.asRubyArgument(name: "skip_upload_apk", type: nil)
    let skipUploadAabArg = skipUploadAab.asRubyArgument(name: "skip_upload_aab", type: nil)
    let skipUploadMetadataArg = skipUploadMetadata.asRubyArgument(name: "skip_upload_metadata", type: nil)
    let skipUploadChangelogsArg = skipUploadChangelogs.asRubyArgument(name: "skip_upload_changelogs", type: nil)
    let skipUploadImagesArg = skipUploadImages.asRubyArgument(name: "skip_upload_images", type: nil)
    let skipUploadScreenshotsArg = skipUploadScreenshots.asRubyArgument(name: "skip_upload_screenshots", type: nil)
    let syncImageUploadArg = syncImageUpload.asRubyArgument(name: "sync_image_upload", type: nil)
    let trackPromoteToArg = trackPromoteTo.asRubyArgument(name: "track_promote_to", type: nil)
    let trackPromoteReleaseStatusArg = RubyCommand.Argument(name: "track_promote_release_status", value: trackPromoteReleaseStatus, type: nil)
    let validateOnlyArg = validateOnly.asRubyArgument(name: "validate_only", type: nil)
    let mappingArg = mapping.asRubyArgument(name: "mapping", type: nil)
    let mappingPathsArg = mappingPaths.asRubyArgument(name: "mapping_paths", type: nil)
    let rootUrlArg = rootUrl.asRubyArgument(name: "root_url", type: nil)
    let checkSupersededTracksArg = checkSupersededTracks.asRubyArgument(name: "check_superseded_tracks", type: nil)
    let timeoutArg = RubyCommand.Argument(name: "timeout", value: timeout, type: nil)
    let deactivateOnPromoteArg = deactivateOnPromote.asRubyArgument(name: "deactivate_on_promote", type: nil)
    let versionCodesToRetainArg = versionCodesToRetain.asRubyArgument(name: "version_codes_to_retain", type: nil)
    let changesNotSentForReviewArg = changesNotSentForReview.asRubyArgument(name: "changes_not_sent_for_review", type: nil)
    let rescueChangesNotSentForReviewArg = rescueChangesNotSentForReview.asRubyArgument(name: "rescue_changes_not_sent_for_review", type: nil)
    let inAppUpdatePriorityArg = inAppUpdatePriority.asRubyArgument(name: "in_app_update_priority", type: nil)
    let obbMainReferencesVersionArg = obbMainReferencesVersion.asRubyArgument(name: "obb_main_references_version", type: nil)
    let obbMainFileSizeArg = obbMainFileSize.asRubyArgument(name: "obb_main_file_size", type: nil)
    let obbPatchReferencesVersionArg = obbPatchReferencesVersion.asRubyArgument(name: "obb_patch_references_version", type: nil)
    let obbPatchFileSizeArg = obbPatchFileSize.asRubyArgument(name: "obb_patch_file_size", type: nil)
    let ackBundleInstallationWarningArg = ackBundleInstallationWarning.asRubyArgument(name: "ack_bundle_installation_warning", type: nil)
    let array: [RubyCommand.Argument?] = [packageNameArg,
                                          versionNameArg,
                                          versionCodeArg,
                                          releaseStatusArg,
                                          trackArg,
                                          rolloutArg,
                                          metadataPathArg,
                                          keyArg,
                                          issuerArg,
                                          jsonKeyArg,
                                          jsonKeyDataArg,
                                          apkArg,
                                          apkPathsArg,
                                          aabArg,
                                          aabPathsArg,
                                          skipUploadApkArg,
                                          skipUploadAabArg,
                                          skipUploadMetadataArg,
                                          skipUploadChangelogsArg,
                                          skipUploadImagesArg,
                                          skipUploadScreenshotsArg,
                                          syncImageUploadArg,
                                          trackPromoteToArg,
                                          trackPromoteReleaseStatusArg,
                                          validateOnlyArg,
                                          mappingArg,
                                          mappingPathsArg,
                                          rootUrlArg,
                                          checkSupersededTracksArg,
                                          timeoutArg,
                                          deactivateOnPromoteArg,
                                          versionCodesToRetainArg,
                                          changesNotSentForReviewArg,
                                          rescueChangesNotSentForReviewArg,
                                          inAppUpdatePriorityArg,
                                          obbMainReferencesVersionArg,
                                          obbMainFileSizeArg,
                                          obbPatchReferencesVersionArg,
                                          obbPatchFileSizeArg,
                                          ackBundleInstallationWarningArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "upload_to_play_store", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Upload binaries to Google Play Internal App Sharing (via _supply_)

 - parameters:
   - packageName: The package name of the application to use
   - jsonKey: The path to a file containing service account JSON, used to authenticate with Google
   - jsonKeyData: The raw service account JSON data used to authenticate with Google
   - apk: Path to the APK file to upload
   - apkPaths: An array of paths to APK files to upload
   - aab: Path to the AAB file to upload
   - aabPaths: An array of paths to AAB files to upload
   - rootUrl: Root URL for the Google Play API. The provided URL will be used for API calls in place of https://www.googleapis.com/
   - timeout: Timeout for read, open, and send (in seconds)

 - returns: Returns a string containing the download URL for the uploaded APK/AAB (or array of strings if multiple were uploaded).

 More information: https://docs.fastlane.tools/actions/upload_to_play_store_internal_app_sharing/
 */
public func uploadToPlayStoreInternalAppSharing(packageName: String,
                                                jsonKey: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                                jsonKeyData: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                                apk: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                                apkPaths: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                                                aab: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                                aabPaths: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                                                rootUrl: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                                timeout: Int = 300)
{
    let packageNameArg = RubyCommand.Argument(name: "package_name", value: packageName, type: nil)
    let jsonKeyArg = jsonKey.asRubyArgument(name: "json_key", type: nil)
    let jsonKeyDataArg = jsonKeyData.asRubyArgument(name: "json_key_data", type: nil)
    let apkArg = apk.asRubyArgument(name: "apk", type: nil)
    let apkPathsArg = apkPaths.asRubyArgument(name: "apk_paths", type: nil)
    let aabArg = aab.asRubyArgument(name: "aab", type: nil)
    let aabPathsArg = aabPaths.asRubyArgument(name: "aab_paths", type: nil)
    let rootUrlArg = rootUrl.asRubyArgument(name: "root_url", type: nil)
    let timeoutArg = RubyCommand.Argument(name: "timeout", value: timeout, type: nil)
    let array: [RubyCommand.Argument?] = [packageNameArg,
                                          jsonKeyArg,
                                          jsonKeyDataArg,
                                          apkArg,
                                          apkPathsArg,
                                          aabArg,
                                          aabPathsArg,
                                          rootUrlArg,
                                          timeoutArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "upload_to_play_store_internal_app_sharing", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Upload new binary to App Store Connect for TestFlight beta testing (via _pilot_)

 - parameters:
   - apiKeyPath: Path to your App Store Connect API Key JSON file (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-json-file)
   - apiKey: Your App Store Connect API Key information (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-hash-option)
   - username: Your Apple ID Username
   - appIdentifier: The bundle identifier of the app to upload or manage testers (optional)
   - appPlatform: The platform to use (optional)
   - appleId: Apple ID property in the App Information section in App Store Connect
   - ipa: Path to the ipa file to upload
   - pkg: Path to your pkg file
   - demoAccountRequired: Do you need a demo account when Apple does review?
   - betaAppReviewInfo: Beta app review information for contact info and demo account
   - localizedAppInfo: Localized beta app test info for description, feedback email, marketing url, and privacy policy
   - betaAppDescription: Provide the 'Beta App Description' when uploading a new build
   - betaAppFeedbackEmail: Provide the beta app email when uploading a new build
   - localizedBuildInfo: Localized beta app test info for what's new
   - changelog: Provide the 'What to Test' text when uploading a new build
   - skipSubmission: Skip the distributing action of pilot and only upload the ipa file
   - skipWaitingForBuildProcessing: If set to true, the `distribute_external` option won't work and no build will be distributed to testers. (You might want to use this option if you are using this action on CI and have to pay for 'minutes used' on your CI plan). If set to `true` and a changelog is provided, it will partially wait for the build to appear on AppStore Connect so the changelog can be set, and skip the remaining processing steps
   - updateBuildInfoOnUpload: **DEPRECATED!** Update build info immediately after validation. This is deprecated and will be removed in a future release. App Store Connect no longer supports setting build info until after build processing has completed, which is when build info is updated by default
   - distributeOnly: Distribute a previously uploaded build (equivalent to the `fastlane pilot distribute` command)
   - usesNonExemptEncryption: Provide the 'Uses Non-Exempt Encryption' for export compliance. This is used if there is 'ITSAppUsesNonExemptEncryption' is not set in the Info.plist
   - distributeExternal: Should the build be distributed to external testers? If set to true, use of `groups` option is required
   - notifyExternalTesters: Should notify external testers? (Not setting a value will use App Store Connect's default which is to notify)
   - appVersion: The version number of the application build to distribute. If the version number is not specified, then the most recent build uploaded to TestFlight will be distributed. If specified, the most recent build for the version number will be distributed
   - buildNumber: The build number of the application build to distribute. If the build number is not specified, the most recent build is distributed
   - expirePreviousBuilds: Should expire previous builds?
   - firstName: The tester's first name
   - lastName: The tester's last name
   - email: The tester's email
   - testersFilePath: Path to a CSV file of testers
   - groups: Associate tester to one group or more by group name / group id. E.g. `-g "Team 1","Team 2"` This is required when `distribute_external` option is set to true or when we want to add a tester to one or more external testing groups
   - teamId: The ID of your App Store Connect team if you're in multiple teams
   - teamName: The name of your App Store Connect team if you're in multiple teams
   - devPortalTeamId: The short ID of your team in the developer portal, if you're in multiple teams. Different from your iTC team ID!
   - itcProvider: The provider short name to be used with the iTMSTransporter to identify your team. This value will override the automatically detected provider short name. To get provider short name run `xcrun iTMSTransporter -m provider -u 'USERNAME' -p 'PASSWORD' -account_type itunes_connect -v off`. The short names of providers should be listed in the second column
   - waitProcessingInterval: Interval in seconds to wait for App Store Connect processing
   - waitProcessingTimeoutDuration: Timeout duration in seconds to wait for App Store Connect processing. If set, after exceeding timeout duration, this will `force stop` to wait for App Store Connect processing and exit with exception
   - waitForUploadedBuild: **DEPRECATED!** No longer needed with the transition over to the App Store Connect API - Use version info from uploaded ipa file to determine what build to use for distribution. If set to false, latest processing or any latest build will be used
   - rejectBuildWaitingForReview: Expire previous if it's 'waiting for review'
   - submitBetaReview: Send the build for a beta review

 More details can be found on https://docs.fastlane.tools/actions/pilot/.
 This integration will only do the TestFlight upload.
 */
public func uploadToTestflight(apiKeyPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               apiKey: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                               username: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               appIdentifier: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               appPlatform: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               appleId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               ipa: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               pkg: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               demoAccountRequired: OptionalConfigValue<Bool?> = .fastlaneDefault(nil),
                               betaAppReviewInfo: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                               localizedAppInfo: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                               betaAppDescription: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               betaAppFeedbackEmail: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               localizedBuildInfo: OptionalConfigValue<[String: Any]?> = .fastlaneDefault(nil),
                               changelog: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               skipSubmission: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                               skipWaitingForBuildProcessing: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                               updateBuildInfoOnUpload: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                               distributeOnly: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                               usesNonExemptEncryption: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                               distributeExternal: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                               notifyExternalTesters: Any? = nil,
                               appVersion: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               buildNumber: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               expirePreviousBuilds: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                               firstName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               lastName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               email: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               testersFilePath: String = "./testers.csv",
                               groups: OptionalConfigValue<[String]?> = .fastlaneDefault(nil),
                               teamId: Any? = nil,
                               teamName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               devPortalTeamId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               itcProvider: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               waitProcessingInterval: Int = 30,
                               waitProcessingTimeoutDuration: OptionalConfigValue<Int?> = .fastlaneDefault(nil),
                               waitForUploadedBuild: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                               rejectBuildWaitingForReview: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                               submitBetaReview: OptionalConfigValue<Bool> = .fastlaneDefault(true))
{
    let apiKeyPathArg = apiKeyPath.asRubyArgument(name: "api_key_path", type: nil)
    let apiKeyArg = apiKey.asRubyArgument(name: "api_key", type: nil)
    let usernameArg = username.asRubyArgument(name: "username", type: nil)
    let appIdentifierArg = appIdentifier.asRubyArgument(name: "app_identifier", type: nil)
    let appPlatformArg = appPlatform.asRubyArgument(name: "app_platform", type: nil)
    let appleIdArg = appleId.asRubyArgument(name: "apple_id", type: nil)
    let ipaArg = ipa.asRubyArgument(name: "ipa", type: nil)
    let pkgArg = pkg.asRubyArgument(name: "pkg", type: nil)
    let demoAccountRequiredArg = demoAccountRequired.asRubyArgument(name: "demo_account_required", type: nil)
    let betaAppReviewInfoArg = betaAppReviewInfo.asRubyArgument(name: "beta_app_review_info", type: nil)
    let localizedAppInfoArg = localizedAppInfo.asRubyArgument(name: "localized_app_info", type: nil)
    let betaAppDescriptionArg = betaAppDescription.asRubyArgument(name: "beta_app_description", type: nil)
    let betaAppFeedbackEmailArg = betaAppFeedbackEmail.asRubyArgument(name: "beta_app_feedback_email", type: nil)
    let localizedBuildInfoArg = localizedBuildInfo.asRubyArgument(name: "localized_build_info", type: nil)
    let changelogArg = changelog.asRubyArgument(name: "changelog", type: nil)
    let skipSubmissionArg = skipSubmission.asRubyArgument(name: "skip_submission", type: nil)
    let skipWaitingForBuildProcessingArg = skipWaitingForBuildProcessing.asRubyArgument(name: "skip_waiting_for_build_processing", type: nil)
    let updateBuildInfoOnUploadArg = updateBuildInfoOnUpload.asRubyArgument(name: "update_build_info_on_upload", type: nil)
    let distributeOnlyArg = distributeOnly.asRubyArgument(name: "distribute_only", type: nil)
    let usesNonExemptEncryptionArg = usesNonExemptEncryption.asRubyArgument(name: "uses_non_exempt_encryption", type: nil)
    let distributeExternalArg = distributeExternal.asRubyArgument(name: "distribute_external", type: nil)
    let notifyExternalTestersArg = RubyCommand.Argument(name: "notify_external_testers", value: notifyExternalTesters, type: nil)
    let appVersionArg = appVersion.asRubyArgument(name: "app_version", type: nil)
    let buildNumberArg = buildNumber.asRubyArgument(name: "build_number", type: nil)
    let expirePreviousBuildsArg = expirePreviousBuilds.asRubyArgument(name: "expire_previous_builds", type: nil)
    let firstNameArg = firstName.asRubyArgument(name: "first_name", type: nil)
    let lastNameArg = lastName.asRubyArgument(name: "last_name", type: nil)
    let emailArg = email.asRubyArgument(name: "email", type: nil)
    let testersFilePathArg = RubyCommand.Argument(name: "testers_file_path", value: testersFilePath, type: nil)
    let groupsArg = groups.asRubyArgument(name: "groups", type: nil)
    let teamIdArg = RubyCommand.Argument(name: "team_id", value: teamId, type: nil)
    let teamNameArg = teamName.asRubyArgument(name: "team_name", type: nil)
    let devPortalTeamIdArg = devPortalTeamId.asRubyArgument(name: "dev_portal_team_id", type: nil)
    let itcProviderArg = itcProvider.asRubyArgument(name: "itc_provider", type: nil)
    let waitProcessingIntervalArg = RubyCommand.Argument(name: "wait_processing_interval", value: waitProcessingInterval, type: nil)
    let waitProcessingTimeoutDurationArg = waitProcessingTimeoutDuration.asRubyArgument(name: "wait_processing_timeout_duration", type: nil)
    let waitForUploadedBuildArg = waitForUploadedBuild.asRubyArgument(name: "wait_for_uploaded_build", type: nil)
    let rejectBuildWaitingForReviewArg = rejectBuildWaitingForReview.asRubyArgument(name: "reject_build_waiting_for_review", type: nil)
    let submitBetaReviewArg = submitBetaReview.asRubyArgument(name: "submit_beta_review", type: nil)
    let array: [RubyCommand.Argument?] = [apiKeyPathArg,
                                          apiKeyArg,
                                          usernameArg,
                                          appIdentifierArg,
                                          appPlatformArg,
                                          appleIdArg,
                                          ipaArg,
                                          pkgArg,
                                          demoAccountRequiredArg,
                                          betaAppReviewInfoArg,
                                          localizedAppInfoArg,
                                          betaAppDescriptionArg,
                                          betaAppFeedbackEmailArg,
                                          localizedBuildInfoArg,
                                          changelogArg,
                                          skipSubmissionArg,
                                          skipWaitingForBuildProcessingArg,
                                          updateBuildInfoOnUploadArg,
                                          distributeOnlyArg,
                                          usesNonExemptEncryptionArg,
                                          distributeExternalArg,
                                          notifyExternalTestersArg,
                                          appVersionArg,
                                          buildNumberArg,
                                          expirePreviousBuildsArg,
                                          firstNameArg,
                                          lastNameArg,
                                          emailArg,
                                          testersFilePathArg,
                                          groupsArg,
                                          teamIdArg,
                                          teamNameArg,
                                          devPortalTeamIdArg,
                                          itcProviderArg,
                                          waitProcessingIntervalArg,
                                          waitProcessingTimeoutDurationArg,
                                          waitForUploadedBuildArg,
                                          rejectBuildWaitingForReviewArg,
                                          submitBetaReviewArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "upload_to_testflight", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Validate that the Google Play Store `json_key` works

 - parameters:
   - jsonKey: The path to a file containing service account JSON, used to authenticate with Google
   - jsonKeyData: The raw service account JSON data used to authenticate with Google
   - rootUrl: Root URL for the Google Play API. The provided URL will be used for API calls in place of https://www.googleapis.com/
   - timeout: Timeout for read, open, and send (in seconds)

 Use this action to test and validate your private key json key file used to connect and authenticate with the Google Play API
 */
public func validatePlayStoreJsonKey(jsonKey: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                     jsonKeyData: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                     rootUrl: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                     timeout: Int = 300)
{
    let jsonKeyArg = jsonKey.asRubyArgument(name: "json_key", type: nil)
    let jsonKeyDataArg = jsonKeyData.asRubyArgument(name: "json_key_data", type: nil)
    let rootUrlArg = rootUrl.asRubyArgument(name: "root_url", type: nil)
    let timeoutArg = RubyCommand.Argument(name: "timeout", value: timeout, type: nil)
    let array: [RubyCommand.Argument?] = [jsonKeyArg,
                                          jsonKeyDataArg,
                                          rootUrlArg,
                                          timeoutArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "validate_play_store_json_key", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Able to verify various settings in ipa file

 - parameters:
   - provisioningType: Required type of provisioning
   - provisioningUuid: Required UUID of provisioning profile
   - teamIdentifier: Required team identifier
   - teamName: Required team name
   - appName: Required app name
   - bundleIdentifier: Required bundle identifier
   - ipaPath: Explicitly set the ipa path
   - buildPath: Explicitly set the ipa, app or xcarchive path

 Verifies that the built app was built using the expected build resources. This is relevant for people who build on machines that are used to build apps with different profiles, certificates and/or bundle identifiers to guard against configuration mistakes.
 */
public func verifyBuild(provisioningType: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                        provisioningUuid: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                        teamIdentifier: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                        teamName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                        appName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                        bundleIdentifier: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                        ipaPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                        buildPath: OptionalConfigValue<String?> = .fastlaneDefault(nil))
{
    let provisioningTypeArg = provisioningType.asRubyArgument(name: "provisioning_type", type: nil)
    let provisioningUuidArg = provisioningUuid.asRubyArgument(name: "provisioning_uuid", type: nil)
    let teamIdentifierArg = teamIdentifier.asRubyArgument(name: "team_identifier", type: nil)
    let teamNameArg = teamName.asRubyArgument(name: "team_name", type: nil)
    let appNameArg = appName.asRubyArgument(name: "app_name", type: nil)
    let bundleIdentifierArg = bundleIdentifier.asRubyArgument(name: "bundle_identifier", type: nil)
    let ipaPathArg = ipaPath.asRubyArgument(name: "ipa_path", type: nil)
    let buildPathArg = buildPath.asRubyArgument(name: "build_path", type: nil)
    let array: [RubyCommand.Argument?] = [provisioningTypeArg,
                                          provisioningUuidArg,
                                          teamIdentifierArg,
                                          teamNameArg,
                                          appNameArg,
                                          bundleIdentifierArg,
                                          ipaPathArg,
                                          buildPathArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "verify_build", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Verifies all keys referenced from the Podfile are non-empty

 Runs a check against all keys specified in your Podfile to make sure they're more than a single character long. This is to ensure you don't deploy with stubbed keys.
 */
public func verifyPodKeys() {
    let args: [RubyCommand.Argument] = []
    let command = RubyCommand(commandID: "", methodName: "verify_pod_keys", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Verifies that the Xcode installation is properly signed by Apple

 - parameter xcodePath: The path to the Xcode installation to test

 This action was implemented after the recent Xcode attack to make sure you're not using a [hacked Xcode installation](http://researchcenter.paloaltonetworks.com/2015/09/novel-malware-xcodeghost-modifies-xcode-infects-apple-ios-apps-and-hits-app-store/).
 */
public func verifyXcode(xcodePath: String) {
    let xcodePathArg = RubyCommand.Argument(name: "xcode_path", value: xcodePath, type: nil)
    let array: [RubyCommand.Argument?] = [xcodePathArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "verify_xcode", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Increment or set the version in a podspec file

 - parameters:
   - path: You must specify the path to the podspec file to update
   - bumpType: The type of this version bump. Available: patch, minor, major
   - versionNumber: Change to a specific version. This will replace the bump type value
   - versionAppendix: Change version appendix to a specific value. For example 1.4.14.4.1 -> 1.4.14.5
   - requireVariablePrefix: true by default, this is used for non CocoaPods version bumps only

 You can use this action to manipulate any 'version' variable contained in a ruby file.
 For example, you can use it to bump the version of a CocoaPods' podspec file.
 It also supports versions that are not semantic: `1.4.14.4.1`.
 For such versions, there is an option to change the appendix (e.g. `4.1`).
 */
public func versionBumpPodspec(path: String,
                               bumpType: String = "patch",
                               versionNumber: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               versionAppendix: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               requireVariablePrefix: OptionalConfigValue<Bool> = .fastlaneDefault(true))
{
    let pathArg = RubyCommand.Argument(name: "path", value: path, type: nil)
    let bumpTypeArg = RubyCommand.Argument(name: "bump_type", value: bumpType, type: nil)
    let versionNumberArg = versionNumber.asRubyArgument(name: "version_number", type: nil)
    let versionAppendixArg = versionAppendix.asRubyArgument(name: "version_appendix", type: nil)
    let requireVariablePrefixArg = requireVariablePrefix.asRubyArgument(name: "require_variable_prefix", type: nil)
    let array: [RubyCommand.Argument?] = [pathArg,
                                          bumpTypeArg,
                                          versionNumberArg,
                                          versionAppendixArg,
                                          requireVariablePrefixArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "version_bump_podspec", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Receive the version number from a podspec file

 - parameters:
   - path: You must specify the path to the podspec file
   - requireVariablePrefix: true by default, this is used for non CocoaPods version bumps only
 */
public func versionGetPodspec(path: String,
                              requireVariablePrefix: OptionalConfigValue<Bool> = .fastlaneDefault(true))
{
    let pathArg = RubyCommand.Argument(name: "path", value: path, type: nil)
    let requireVariablePrefixArg = requireVariablePrefix.asRubyArgument(name: "require_variable_prefix", type: nil)
    let array: [RubyCommand.Argument?] = [pathArg,
                                          requireVariablePrefixArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "version_get_podspec", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Archives the project using `xcodebuild`
 */
public func xcarchive() {
    let args: [RubyCommand.Argument] = []
    let command = RubyCommand(commandID: "", methodName: "xcarchive", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Builds the project using `xcodebuild`
 */
public func xcbuild() {
    let args: [RubyCommand.Argument] = []
    let command = RubyCommand(commandID: "", methodName: "xcbuild", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Cleans the project using `xcodebuild`
 */
public func xcclean() {
    let args: [RubyCommand.Argument] = []
    let command = RubyCommand(commandID: "", methodName: "xcclean", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Exports the project using `xcodebuild`
 */
public func xcexport() {
    let args: [RubyCommand.Argument] = []
    let command = RubyCommand(commandID: "", methodName: "xcexport", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Make sure a certain version of Xcode is installed

 - parameters:
   - version: The version number of the version of Xcode to install
   - username: Your Apple ID Username
   - teamId: The ID of your team if you're in multiple teams
   - downloadRetryAttempts: Number of times the download will be retried in case of failure

 - returns: The path to the newly installed Xcode version

 Makes sure a specific version of Xcode is installed. If that's not the case, it will automatically be downloaded by the [xcode_install](https://github.com/neonichu/xcode-install) gem. This will make sure to use the correct Xcode for later actions.
 */
@discardableResult public func xcodeInstall(version: String,
                                            username: String,
                                            teamId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                            downloadRetryAttempts: Int = 3) -> String
{
    let versionArg = RubyCommand.Argument(name: "version", value: version, type: nil)
    let usernameArg = RubyCommand.Argument(name: "username", value: username, type: nil)
    let teamIdArg = teamId.asRubyArgument(name: "team_id", type: nil)
    let downloadRetryAttemptsArg = RubyCommand.Argument(name: "download_retry_attempts", value: downloadRetryAttempts, type: nil)
    let array: [RubyCommand.Argument?] = [versionArg,
                                          usernameArg,
                                          teamIdArg,
                                          downloadRetryAttemptsArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "xcode_install", className: nil, args: args)
    return runner.executeCommand(command)
}

/**
 Change the xcode-path to use. Useful for beta versions of Xcode

 Select and build with the Xcode installed at the provided path.
 Use the `xcodes` action if you want to select an Xcode:
 - Based on a version specifier or
 - You don't have known, stable paths, as may happen in a CI environment.
 */
public func xcodeSelect() {
    let args: [RubyCommand.Argument] = []
    let command = RubyCommand(commandID: "", methodName: "xcode_select", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Downloads Xcode Bot assets like the `.xcarchive` and logs

 - parameters:
   - host: IP Address/Hostname of Xcode Server
   - botName: Name of the Bot to pull assets from
   - integrationNumber: Optionally you can override which integration's assets should be downloaded. If not provided, the latest integration is used
   - username: Username for your Xcode Server
   - password: Password for your Xcode Server
   - targetFolder: Relative path to a folder into which to download assets
   - keepAllAssets: Whether to keep all assets or let the script delete everything except for the .xcarchive
   - trustSelfSignedCerts: Whether to trust self-signed certs on your Xcode Server

 This action downloads assets from your Xcode Server Bot (works with Xcode Server using Xcode 6 and 7. By default, this action downloads all assets, unzips them and deletes everything except for the `.xcarchive`.
 If you'd like to keep all downloaded assets, pass `keep_all_assets: true`.
 This action returns the path to the downloaded assets folder and puts into shared values the paths to the asset folder and to the `.xcarchive` inside it.
 */
@discardableResult public func xcodeServerGetAssets(host: String,
                                                    botName: String,
                                                    integrationNumber: OptionalConfigValue<Int?> = .fastlaneDefault(nil),
                                                    username: String = "",
                                                    password: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                                    targetFolder: String = "./xcs_assets",
                                                    keepAllAssets: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                                    trustSelfSignedCerts: OptionalConfigValue<Bool> = .fastlaneDefault(true)) -> [String]
{
    let hostArg = RubyCommand.Argument(name: "host", value: host, type: nil)
    let botNameArg = RubyCommand.Argument(name: "bot_name", value: botName, type: nil)
    let integrationNumberArg = integrationNumber.asRubyArgument(name: "integration_number", type: nil)
    let usernameArg = RubyCommand.Argument(name: "username", value: username, type: nil)
    let passwordArg = password.asRubyArgument(name: "password", type: nil)
    let targetFolderArg = RubyCommand.Argument(name: "target_folder", value: targetFolder, type: nil)
    let keepAllAssetsArg = keepAllAssets.asRubyArgument(name: "keep_all_assets", type: nil)
    let trustSelfSignedCertsArg = trustSelfSignedCerts.asRubyArgument(name: "trust_self_signed_certs", type: nil)
    let array: [RubyCommand.Argument?] = [hostArg,
                                          botNameArg,
                                          integrationNumberArg,
                                          usernameArg,
                                          passwordArg,
                                          targetFolderArg,
                                          keepAllAssetsArg,
                                          trustSelfSignedCertsArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "xcode_server_get_assets", className: nil, args: args)
    return parseArray(fromString: runner.executeCommand(command))
}

/**
 Use the `xcodebuild` command to build and sign your app

 **Note**: `xcodebuild` is a complex command, so it is recommended to use [_gym_](https://docs.fastlane.tools/actions/gym/) for building your ipa file and [_scan_](https://docs.fastlane.tools/actions/scan/) for testing your app instead.
 */
public func xcodebuild() {
    let args: [RubyCommand.Argument] = []
    let command = RubyCommand(commandID: "", methodName: "xcodebuild", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Make sure a certain version of Xcode is installed, installing it only if needed

 - parameters:
   - version: The version number of the version of Xcode to install. Defaults to the value specified in the .xcode-version file
   - updateList: Whether the list of available Xcode versions should be updated before running the install command
   - selectForCurrentBuildOnly: When true, it won't attempt to install an Xcode version, just find the installed Xcode version that best matches the passed version argument, and select it for the current build steps. It doesn't change the global Xcode version (e.g. via 'xcrun xcode-select'), which would require sudo permissions — when this option is true, this action doesn't require sudo permissions
   - binaryPath: Where the xcodes binary lives on your system (full path)
   - xcodesArgs: Pass in xcodes command line arguments directly. When present, other parameters are ignored and only this parameter is used to build the command to be executed

 - returns: The path to the newly installed Xcode version

 Makes sure a specific version of Xcode is installed. If that's not the case, it will automatically be downloaded by [xcodes](https://github.com/RobotsAndPencils/xcodes).
 This will make sure to use the correct Xcode version for later actions.
 Note that this action depends on [xcodes](https://github.com/RobotsAndPencils/xcodes) CLI, so make sure you have it installed in your environment. For the installation guide, see: https://github.com/RobotsAndPencils/xcodes#installation
 */
@discardableResult public func xcodes(version: String,
                                      updateList: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                                      selectForCurrentBuildOnly: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                      binaryPath: String = "/opt/homebrew/bin/xcodes",
                                      xcodesArgs: OptionalConfigValue<String?> = .fastlaneDefault(nil)) -> String
{
    let versionArg = RubyCommand.Argument(name: "version", value: version, type: nil)
    let updateListArg = updateList.asRubyArgument(name: "update_list", type: nil)
    let selectForCurrentBuildOnlyArg = selectForCurrentBuildOnly.asRubyArgument(name: "select_for_current_build_only", type: nil)
    let binaryPathArg = RubyCommand.Argument(name: "binary_path", value: binaryPath, type: nil)
    let xcodesArgsArg = xcodesArgs.asRubyArgument(name: "xcodes_args", type: nil)
    let array: [RubyCommand.Argument?] = [versionArg,
                                          updateListArg,
                                          selectForCurrentBuildOnlyArg,
                                          binaryPathArg,
                                          xcodesArgsArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "xcodes", className: nil, args: args)
    return runner.executeCommand(command)
}

/**
 Nice code coverage reports without hassle

 - parameters:
   - workspace: Path the workspace file
   - project: Path the project file
   - scheme: The project's scheme. Make sure it's marked as `Shared`
   - configuration: The configuration used when building the app. Defaults to 'Release'
   - sourceDirectory: The path to project's root directory
   - derivedDataPath: The directory where build products and other derived data will go
   - outputDirectory: The directory in which all reports will be stored
   - htmlReport: Produce an HTML report
   - markdownReport: Produce a Markdown report
   - jsonReport: Produce a JSON report
   - minimumCoveragePercentage: Raise exception if overall coverage percentage is under this value (ie. 75)
   - slackUrl: Create an Incoming WebHook for your Slack group to post results there
   - slackChannel: #channel or @username
   - skipSlack: Don't publish to slack, even when an URL is given
   - slackUsername: The username which is used to publish to slack
   - slackMessage: The message which is published together with a successful report
   - ignoreFilePath: Relative or absolute path to the file containing the list of ignored files
   - includeTestTargets: Enables coverage reports for .xctest targets
   - excludeTargets: Comma separated list of targets to exclude from coverage report
   - includeTargets: Comma separated list of targets to include in coverage report. If specified then exlude_targets will be ignored
   - onlyProjectTargets: Display the coverage only for main project targets (e.g. skip Pods targets)
   - disableCoveralls: Add this flag to disable automatic submission to Coveralls
   - coverallsServiceName: Name of the CI service compatible with Coveralls. i.e. travis-ci. This option must be defined along with coveralls_service_job_id
   - coverallsServiceJobId: Name of the current job running on a CI service compatible with Coveralls. This option must be defined along with coveralls_service_name
   - coverallsRepoToken: Repository token to be used by integrations not compatible with Coveralls
   - xcconfig: Use an extra XCCONFIG file to build your app
   - ideFoundationPath: Absolute path to the IDEFoundation.framework binary
   - legacySupport: Whether xcov should parse a xccoverage file instead on xccovreport

 Create nice code coverage reports and post coverage summaries on Slack *(xcov gem is required)*.
 More information: [https://github.com/nakiostudio/xcov](https://github.com/nakiostudio/xcov).
 */
public func xcov(workspace: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                 project: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                 scheme: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                 configuration: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                 sourceDirectory: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                 derivedDataPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                 outputDirectory: String = "./xcov_report",
                 htmlReport: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                 markdownReport: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                 jsonReport: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                 minimumCoveragePercentage: Float = 0.0,
                 slackUrl: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                 slackChannel: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                 skipSlack: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                 slackUsername: String = "xcov",
                 slackMessage: String = "Your *xcov* coverage report",
                 ignoreFilePath: String = "./.xcovignore",
                 includeTestTargets: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                 excludeTargets: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                 includeTargets: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                 onlyProjectTargets: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                 disableCoveralls: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                 coverallsServiceName: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                 coverallsServiceJobId: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                 coverallsRepoToken: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                 xcconfig: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                 ideFoundationPath: String = "/Applications/Xcode_15.4.app/Contents/Developer/../Frameworks/IDEFoundation.framework/Versions/A/IDEFoundation",
                 legacySupport: OptionalConfigValue<Bool> = .fastlaneDefault(false))
{
    let workspaceArg = workspace.asRubyArgument(name: "workspace", type: nil)
    let projectArg = project.asRubyArgument(name: "project", type: nil)
    let schemeArg = scheme.asRubyArgument(name: "scheme", type: nil)
    let configurationArg = configuration.asRubyArgument(name: "configuration", type: nil)
    let sourceDirectoryArg = sourceDirectory.asRubyArgument(name: "source_directory", type: nil)
    let derivedDataPathArg = derivedDataPath.asRubyArgument(name: "derived_data_path", type: nil)
    let outputDirectoryArg = RubyCommand.Argument(name: "output_directory", value: outputDirectory, type: nil)
    let htmlReportArg = htmlReport.asRubyArgument(name: "html_report", type: nil)
    let markdownReportArg = markdownReport.asRubyArgument(name: "markdown_report", type: nil)
    let jsonReportArg = jsonReport.asRubyArgument(name: "json_report", type: nil)
    let minimumCoveragePercentageArg = RubyCommand.Argument(name: "minimum_coverage_percentage", value: minimumCoveragePercentage, type: nil)
    let slackUrlArg = slackUrl.asRubyArgument(name: "slack_url", type: nil)
    let slackChannelArg = slackChannel.asRubyArgument(name: "slack_channel", type: nil)
    let skipSlackArg = skipSlack.asRubyArgument(name: "skip_slack", type: nil)
    let slackUsernameArg = RubyCommand.Argument(name: "slack_username", value: slackUsername, type: nil)
    let slackMessageArg = RubyCommand.Argument(name: "slack_message", value: slackMessage, type: nil)
    let ignoreFilePathArg = RubyCommand.Argument(name: "ignore_file_path", value: ignoreFilePath, type: nil)
    let includeTestTargetsArg = includeTestTargets.asRubyArgument(name: "include_test_targets", type: nil)
    let excludeTargetsArg = excludeTargets.asRubyArgument(name: "exclude_targets", type: nil)
    let includeTargetsArg = includeTargets.asRubyArgument(name: "include_targets", type: nil)
    let onlyProjectTargetsArg = onlyProjectTargets.asRubyArgument(name: "only_project_targets", type: nil)
    let disableCoverallsArg = disableCoveralls.asRubyArgument(name: "disable_coveralls", type: nil)
    let coverallsServiceNameArg = coverallsServiceName.asRubyArgument(name: "coveralls_service_name", type: nil)
    let coverallsServiceJobIdArg = coverallsServiceJobId.asRubyArgument(name: "coveralls_service_job_id", type: nil)
    let coverallsRepoTokenArg = coverallsRepoToken.asRubyArgument(name: "coveralls_repo_token", type: nil)
    let xcconfigArg = xcconfig.asRubyArgument(name: "xcconfig", type: nil)
    let ideFoundationPathArg = RubyCommand.Argument(name: "ideFoundationPath", value: ideFoundationPath, type: nil)
    let legacySupportArg = legacySupport.asRubyArgument(name: "legacy_support", type: nil)
    let array: [RubyCommand.Argument?] = [workspaceArg,
                                          projectArg,
                                          schemeArg,
                                          configurationArg,
                                          sourceDirectoryArg,
                                          derivedDataPathArg,
                                          outputDirectoryArg,
                                          htmlReportArg,
                                          markdownReportArg,
                                          jsonReportArg,
                                          minimumCoveragePercentageArg,
                                          slackUrlArg,
                                          slackChannelArg,
                                          skipSlackArg,
                                          slackUsernameArg,
                                          slackMessageArg,
                                          ignoreFilePathArg,
                                          includeTestTargetsArg,
                                          excludeTargetsArg,
                                          includeTargetsArg,
                                          onlyProjectTargetsArg,
                                          disableCoverallsArg,
                                          coverallsServiceNameArg,
                                          coverallsServiceJobIdArg,
                                          coverallsRepoTokenArg,
                                          xcconfigArg,
                                          ideFoundationPathArg,
                                          legacySupportArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "xcov", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Runs tests on the given simulator
 */
public func xctest() {
    let args: [RubyCommand.Argument] = []
    let command = RubyCommand(commandID: "", methodName: "xctest", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Run tests using xctool

 You can run any `xctool` action. This will require having [xctool](https://github.com/facebook/xctool) installed through [Homebrew](http://brew.sh).
 It is recommended to store the build configuration in the `.xctool-args` file.
 More information: [https://docs.fastlane.tools/actions/xctool/](https://docs.fastlane.tools/actions/xctool/).
 */
public func xctool() {
    let args: [RubyCommand.Argument] = []
    let command = RubyCommand(commandID: "", methodName: "xctool", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Select an Xcode to use by version specifier

 - parameter version: The version of Xcode to select specified as a Gem::Version requirement string (e.g. '~> 7.1.0'). Defaults to the value specified in the .xcode-version file

 Finds and selects a version of an installed Xcode that best matches the provided [`Gem::Version` requirement specifier](http://www.rubydoc.info/github/rubygems/rubygems/Gem/Version)
 You can either manually provide a specific version using `version:` or you make use of the `.xcode-version` file.
 */
public func xcversion(version: String) {
    let versionArg = RubyCommand.Argument(name: "version", value: version, type: nil)
    let array: [RubyCommand.Argument?] = [versionArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "xcversion", className: nil, args: args)
    _ = runner.executeCommand(command)
}

/**
 Compress a file or folder to a zip

 - parameters:
   - path: Path to the directory or file to be zipped
   - outputPath: The name of the resulting zip file
   - verbose: Enable verbose output of zipped file
   - password: Encrypt the contents of the zip archive using a password
   - symlinks: Store symbolic links as such in the zip archive
   - include: Array of paths or patterns to include
   - exclude: Array of paths or patterns to exclude

 - returns: The path to the output zip file
 */
@discardableResult public func zip(path: String,
                                   outputPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                   verbose: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                                   password: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                   symlinks: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                   include: [String] = [],
                                   exclude: [String] = []) -> String
{
    let pathArg = RubyCommand.Argument(name: "path", value: path, type: nil)
    let outputPathArg = outputPath.asRubyArgument(name: "output_path", type: nil)
    let verboseArg = verbose.asRubyArgument(name: "verbose", type: nil)
    let passwordArg = password.asRubyArgument(name: "password", type: nil)
    let symlinksArg = symlinks.asRubyArgument(name: "symlinks", type: nil)
    let includeArg = RubyCommand.Argument(name: "include", value: include, type: nil)
    let excludeArg = RubyCommand.Argument(name: "exclude", value: exclude, type: nil)
    let array: [RubyCommand.Argument?] = [pathArg,
                                          outputPathArg,
                                          verboseArg,
                                          passwordArg,
                                          symlinksArg,
                                          includeArg,
                                          excludeArg]
    let args: [RubyCommand.Argument] = array
        .filter { $0?.value != nil }
        .compactMap { $0 }
    let command = RubyCommand(commandID: "", methodName: "zip", className: nil, args: args)
    return runner.executeCommand(command)
}

// These are all the parsing functions needed to transform our data into the expected types
func parseArray(fromString: String, function: String = #function) -> [String] {
    verbose(message: "parsing an Array from data: \(fromString), from function: \(function)")
    let potentialArray: String
    if fromString.count < 2 {
        potentialArray = "[\(fromString)]"
    } else {
        potentialArray = fromString
    }
    let array: [String] = try! JSONSerialization.jsonObject(with: potentialArray.data(using: .utf8)!, options: []) as! [String]
    return array
}

func parseDictionary(fromString: String, function: String = #function) -> [String: String] {
    return parseDictionaryHelper(fromString: fromString, function: function) as! [String: String]
}

func parseDictionary(fromString: String, function: String = #function) -> [String: Any] {
    return parseDictionaryHelper(fromString: fromString, function: function)
}

func parseDictionaryHelper(fromString: String, function: String = #function) -> [String: Any] {
    verbose(message: "parsing an Array from data: \(fromString), from function: \(function)")
    let potentialDictionary: String
    if fromString.count < 2 {
        verbose(message: "Dictionary value too small: \(fromString), from function: \(function)")
        potentialDictionary = "{}"
    } else {
        potentialDictionary = fromString
    }
    let dictionary: [String: Any] = try! JSONSerialization.jsonObject(with: potentialDictionary.data(using: .utf8)!, options: []) as! [String: Any]
    return dictionary
}

func parseBool(fromString: String, function: String = #function) -> Bool {
    verbose(message: "parsing a Bool from data: \(fromString), from function: \(function)")
    return NSString(string: fromString.trimmingCharacters(in: .punctuationCharacters)).boolValue
}

func parseInt(fromString: String, function: String = #function) -> Int {
    verbose(message: "parsing an Int from data: \(fromString), from function: \(function)")
    return NSString(string: fromString.trimmingCharacters(in: .punctuationCharacters)).integerValue
}

public let deliverfile: Deliverfile = .init()
public let gymfile: Gymfile = .init()
public let matchfile: Matchfile = .init()
public let precheckfile: Precheckfile = .init()
public let scanfile: Scanfile = .init()
public let screengrabfile: Screengrabfile = .init()
public let snapshotfile: Snapshotfile = .init()

// Please don't remove the lines below
// They are used to detect outdated files
// FastlaneRunnerAPIVersion [0.9.185]
