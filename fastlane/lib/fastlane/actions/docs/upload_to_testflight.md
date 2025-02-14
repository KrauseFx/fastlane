<p align="center">
  <img src="/img/actions/PilotTextTransparentSmall.png" width="500">
</p>

###### The best way to manage your TestFlight testers and builds from your terminal

_pilot_ makes it easier to manage your app on Apple’s TestFlight. You can:

- Upload & distribute builds
- Add & remove testers
- Retrieve information about testers & devices
- Import/export all available testers

_pilot_ uses [spaceship.airforce](https://spaceship.airforce) to interact with App Store Connect 🚀

-------

<p align="center">
    <a href="#usage">Usage</a> &bull;
    <a href="#tips">Tips</a>
</p>

-------

<h5 align="center"><em>pilot</em> is part of <a href="https://fastlane.tools">fastlane</a>: The easiest way to automate beta deployments and releases for your iOS and Android apps.</h5>

# Usage

For all commands, you can either use an [API Key](#app-store-connect-api-key) or your [Apple ID](#apple-id).

### App Store Connect API Key

The App Store Connect API Key is the preferred authentication method (if you are able to use it).

- Uses official App Store Connect API
- No need for 2FA
- Better performance over Apple ID

Specify the API key using `--api_key_path ./path/to/api_key_info.json` or `--api_key "{\"key_id\": \"D83848D23\", \"issuer_id\": \"227b0bbf-ada8-458c-9d62-3d8022b7d07f\", \"key_filepath\": \"D83848D23.p8\"}"`

Go to [Using App Store Connect API](/app-store-connect-api) for information on obtaining an API key, the _fastlane_ `api_key_info.json` format, and other API key usage.

### Apple ID

Specify the Apple ID to use using `-u felix@krausefx.com`. If you execute _pilot_ in a project already using [_fastlane_](https://fastlane.tools) the username and app identifier will automatically be determined.

## Uploading builds

To upload a new build, just run

```no-highlight
fastlane pilot upload
```

This will automatically look for an `ipa` in your current directory and tries to fetch the login credentials from your [fastlane setup](https://fastlane.tools).

You'll be asked for any missing information. Additionally, you can pass all kinds of parameters:

```no-highlight
fastlane action pilot
```

You can pass a changelog using

```no-highlight
fastlane pilot upload --changelog "Something that is new here"
```

You can also skip the submission of the binary, which means, the `ipa` file will only be uploaded and not distributed to testers:

```no-highlight
fastlane pilot upload --skip_submission
```

_pilot_ does all kinds of magic for you:

- Automatically detects the bundle identifier from your `ipa` file
- Automatically fetch the AppID of your app based on the bundle identifier

_pilot_ uses [_spaceship_](https://spaceship.airforce) to submit the build metadata and the iTunes Transporter to upload the binary.

### Upload from Linux

To upload binaries from Linux:
- make sure you have [Transporter on Linux](https://help.apple.com/itc/transporteruserguide/en.lproj/static.html) installed
- set the following environment variables:
    - `FASTLANE_ITUNES_TRANSPORTER_USE_SHELL_SCRIPT=true`
    - `FASTLANE_ITUNES_TRANSPORTER_PATH=/usr/local/itms` (_or the path where Transporter is installed_)

## List builds

To list all builds for specific application use

```no-highlight
fastlane pilot builds
```

The result lists all active builds and processing builds:

```no-highlight
+-----------+---------+----------+
|      Great App Builds          |
+-----------+---------+----------+
| Version # | Build # | Installs |
+-----------+---------+----------+
| 0.9.13    | 1       | 0        |
| 0.9.13    | 2       | 0        |
| 0.9.20    | 3       | 0        |
| 0.9.20    | 4       | 3        |
+-----------+---------+----------+
```

## Managing beta testers

### List of Testers

This command will list all your testers, both internal and external.

```no-highlight
fastlane pilot list
```

The output will look like this:

```no-highlight
+--------+--------+--------------------------+-----------+
|                    Internal Testers                    |
+--------+--------+--------------------------+-----------+
| First  | Last   | Email                    | # Devices |
+--------+--------+--------------------------+-----------+
| Felix  | Krause | felix@krausefx.com       | 2         |
+--------+--------+--------------------------+-----------+

+-----------+---------+----------------------------+-----------+
|                       External Testers                       |
+-----------+---------+----------------------------+-----------+
| First     | Last    | Email                      | # Devices |
+-----------+---------+----------------------------+-----------+
| Max       | Manfred | email@email.com            | 0         |
| Detlef    | Müller  | detlef@krausefx.com        | 1         |
+-----------+---------+----------------------------+-----------+
```

### Add a new tester

To add a new tester to your App Store Connect account and to associate it to at least one testing group of your app, use the `pilot add` command. This will create a new tester (if necessary) or add an existing tester to the app to test.

```no-highlight
fastlane pilot add email@invite.com -g group-1,group-2
```

Additionally you can specify the app identifier (if necessary):

```no-highlight
fastlane pilot add email@email.com -a com.krausefx.app -g group-1,group-2
```

### Find a tester

To find a specific tester use

```no-highlight
fastlane pilot find felix@krausefx.com
```

The resulting output will look like this:

```no-highlight
+---------------------+---------------------+
|            felix@krausefx.com             |
+---------------------+---------------------+
| First name          | Felix               |
| Last name           | Krause              |
| Email               | felix@krausefx.com  |
| Latest Version      | 0.9.14 (23          |
| Latest Install Date | 03/28/15 19:00      |
| 2 Devices           | • iPhone 6, iOS 8.3 |
|                     | • iPhone 5, iOS 7.0 |
+---------------------+---------------------+
```

### Remove a tester

This command will remove beta tester from app (from all internal and external groups)

```no-highlight
fastlane pilot remove felix@krausefx.com
```

You can also use `groups` option to remove the tester from the groups specified:

```no-highlight
fastlane pilot remove felix@krausefx.com -g group-1,group-2
```

### Export testers

To export all external testers to a CSV file. Useful if you need to import tester info to another system or a new account.

```no-highlight
fastlane pilot export
```

### Import testers

Add external testers from a CSV file. Create a file (ex: `testers.csv`) and fill it with the following format:

```no-highlight
John,Appleseed,appleseed_john@mac.com,group-1;group-2
```

```no-highlight
fastlane pilot import
```

You can also specify the directory using

```no-highlight
fastlane pilot export -c ~/Desktop/testers.csv
fastlane pilot import -c ~/Desktop/testers.csv
```

# Tips

## Debug information

If you run into any issues you can use the `verbose` mode to get a more detailed output:

```no-highlight
fastlane pilot upload --verbose
```

## Firewall Issues

_pilot_ uses the iTunes [Transporter](https://help.apple.com/itc/transporteruserguide/#/apdATD1E1288-D1E1A1303-D1E1288A1126) to upload metadata and binaries. In case you are behind a firewall, you can specify a different transporter protocol from the command line using

```no-highlight
DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS="-t DAV" pilot ...
```

If you are using _pilot_ via the [fastlane action](https://docs.fastlane.tools/actions#pilot), add the following to your `Fastfile`

```no-highlight
ENV["DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS"] = "-t DAV"
pilot...
```

Note, however, that Apple recommends you don’t specify the `-t transport` and instead allow Transporter to use automatic transport discovery to determine the best transport mode for your packages. For this reason, if the `t` option is passed, we will raise a warning.

Also note that `-t` is not the only additional parameter that can be used. The string specified in the `DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS` environment variable will be forwarded to Transporter. For all the available options, check [Apple's Transporter User Guide](https://help.apple.com/itc/transporteruserguide/#/apdATD1E1288-D1E1A1303-D1E1288A1126).

## Credentials Issues

If your password contains special characters, _pilot_ may throw a confusing error saying your "Your Apple ID or password was entered incorrectly". The easiest way to fix this error is to change your password to something that **does not** contains special characters.

## How is my password stored?

_pilot_ uses the [CredentialsManager](https://github.com/fastlane/fastlane/tree/master/credentials_manager) from _fastlane_.

## Provider Short Name
If you are on multiple App Store Connect teams, iTunes Transporter may need a provider short name to know where to upload your binary. _pilot_ will try to use the long name of the selected team to detect the provider short name. To override the detected value with an explicit one, use the `itc_provider` option.

## Use an Application Specific Password to upload

_pilot_/`upload_to_testflight` can use an [Application Specific Password via the `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD` environment variable](https://docs.fastlane.tools/best-practices/continuous-integration/#application-specific-passwords) to upload a binary if both the `skip_waiting_for_build_processing` and `apple_id` options are set. (If any of those are not set, it will use the normal Apple login process that might require 2FA authentication.)

## Role for App Store Connect User
_pilot_/`upload_to_testflight` updates build information and testers after the build has finished processing. App Store Connect requires the  "App Manager" or "Admin" role for your Apple account to update this information. The "Developer" role will allow builds to be uploaded but _will not_ allow updating of build information and testers.
