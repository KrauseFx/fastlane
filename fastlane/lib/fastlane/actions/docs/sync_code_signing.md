<p align="center">
  <img src="/img/actions/match.png" width="250">
</p>

###### Easily sync your certificates and profiles across your team

A new approach to iOS and macOS code signing: Share one code signing identity across your development team to simplify your codesigning setup and prevent code signing issues.

_match_ is the implementation of the [codesigning.guide concept](https://codesigning.guide). _match_ creates all required certificates & provisioning profiles and stores them in a separate git repository, Google Cloud, or Amazon S3. Every team member with access to the selected storage can use those credentials for code signing. _match_ also automatically repairs broken and expired credentials. It's the easiest way to share signing credentials across teams

[More information on how to get started with codesigning](https://docs.fastlane.tools/codesigning/getting-started/)

-------

<p align="center">
    <a href="#why-match">Why?</a> &bull;
    <a href="#usage">Usage</a> &bull;
    <a href="#is-this-secure">Is this secure?</a>
</p>

-------

<h5 align="center"><em>match</em> is part of <a href="https://fastlane.tools">fastlane</a>: The easiest way to automate beta deployments and releases for your iOS and Android apps.</h5>

## Why match?

Before starting to use _match_, make sure to read the [codesigning.guide](https://codesigning.guide):

> When deploying an app to the App Store, beta testing service or even installing it on a device, most development teams have separate code signing identities for every member. This results in dozens of profiles including a lot of duplicates.

> You have to manually renew and download the latest set of provisioning profiles every time you add a new device or a certificate expires. Additionally this requires spending a lot of time when setting up a new machine that will build your app.

**A new approach**

> Share one code signing identity across your development team to simplify your setup and prevent code signing issues. What if there was a central place where your code signing identity and profiles are kept, so anyone in the team can access them during the build process?

For more information about the concept, visit [codesigning.guide](https://codesigning.guide).

### Why not let Xcode handle all this?

- You have full control over what happens
- You have access to all the certificates and profiles, which are all securely stored in git
- You share one code signing identity across the team to have fewer certificates and profiles
- Xcode sometimes revokes certificates which breaks your setup causing failed builds
- More predictable builds by settings profiles in an explicit way instead of using the `Automatic` setting
- It just works™

### What does _match_ do for you?

|          |  match  |
|----------|---------|
🔄  | Automatically sync your iOS and macOS keys and profiles across all your team members using git
📦  | Handle all the heavy lifting of creating and storing your certificates and profiles
💻  | Setup codesigning on a new machine in under a minute
🎯 | Designed to work with apps with multiple targets and bundle identifiers
🔒 | You have full control over your files and Git repo, no third party service involved
✨ | Provisioning profile will always match the correct certificate
💥  | Easily reset your existing profiles and certificates if your current account has expired or invalid profiles
♻️  | Automatically renew your provisioning profiles to include all your devices using the `--force` option
👥  | Support for multiple Apple accounts and multiple teams
✨ | Tightly integrated with [_fastlane_](https://fastlane.tools) to work seamlessly with [_gym_](https://docs.fastlane.tools/actions/gym/) and other build tools

## Usage

### Setup

1. Optional: Create a **new, shared Apple Developer Portal account**, something like `office@company.com`, that will be shared across your team from now on (for more information visit [codesigning.guide](https://codesigning.guide))
1. Run the following in your project folder to start using _match_:

```no-highlight
fastlane match init
```

<img src="/img/actions/match_init.gif" width="550" />

You'll be asked if you want to store your code signing identities inside a **Git repo**, **Google Cloud** or **Amazon S3**.

#### Git Storage

Use Git Storage to store all code signing identities in a private git repo, owned and operated by you. The files will be encrypted using OpenSSL.

First, enter the URL to your private (!) Git repo (You can create one for free on e.g. [GitHub](https://github.com/new) or [BitBucket](https://bitbucket.org/repo/create)). The URL you enter can be either a `https://` or a `git` URL. `fastlane match init` won't read or modify your certificates or profiles yet, and also won't validate your git URL.

This will create a `Matchfile` in your current directory (or in your `./fastlane/` folder).

Example content (for more advanced setups check out the [fastlane section](#fastlane)):

```ruby-skip-tests
git_url("https://github.com/fastlane/certificates")

app_identifier("tools.fastlane.app")
username("user@fastlane.tools")
```

##### Git Storage on GitHub

If your machine is currently using SSH to authenticate with GitHub, you'll want to use a `git` URL, otherwise, you may see an authentication error when you attempt to use match. Alternatively, you can set a basic authorization for _match_:

Using parameter:

```
match(git_basic_authorization: '<YOUR BASE64 KEY>')
```

Using environment variable:

```
ENV['MATCH_GIT_BASIC_AUTHORIZATION'] = '<YOUR BASE64 KEY>'
match
```

To generate your base64 key [according to RFC 7617](https://tools.ietf.org/html/rfc7617), run this:

```
echo -n your_github_username:your_personal_access_token | base64
```

You can find more information about GitHub basic authentication and personal token generation here: [https://developer.github.com/v3/auth/#basic-authentication](https://developer.github.com/v3/auth/#basic-authentication)

##### Git Storage on GitHub - Deploy keys

If your machine does not have a private key set up for your certificates repository, you can give _match_ a path for one:

Using parameter:

```
match(git_private_key: '<PATH TO YOUR KEY>')
```

Using environment variable:

```
ENV['MATCH_GIT_PRIVATE_KEY'] = '<PATH TO YOUR KEY>'
match
```

You can find more information about GitHub basic authentication and personal token generation here: [https://developer.github.com/v3/auth/#basic-authentication](https://developer.github.com/v3/auth/#basic-authentication)

##### Git Storage on Azure DevOps

If you're running a pipeline on Azure DevOps and using git storage in a another repository on the same project, you might want to use `bearer` token authentication.

Using parameter:

```
match(git_bearer_authorization: '<YOUR TOKEN>')
```

Using environment variable:

```
ENV['MATCH_GIT_BEARER_AUTHORIZATION'] = '<YOUR TOKEN>'
match
```

You can find more information about this use case here: [https://docs.microsoft.com/en-us/azure/devops/pipelines/repos/azure-repos-git?view=azure-devops&tabs=yaml#authorize-access-to-your-repositories](https://docs.microsoft.com/en-us/azure/devops/pipelines/repos/azure-repos-git?view=azure-devops&tabs=yaml#authorize-access-to-your-repositories)

#### Google Cloud Storage

Use [Google Cloud Storage](https://cloud.google.com/storage/) for a fully hosted solution for your code signing identities. Certificates are stored on Google Cloud, encrypted using Google managed keys. Everything will be stored on your Google account, inside a storage bucket you provide. You can also directly access the files using the web console.

This will create a `Matchfile` in your current directory (or in your `./fastlane/` folder).

Example content (for more advanced setups check out the [fastlane section](#fastlane)):

```ruby-skip-tests
google_cloud_bucket_name("major-key-certificates")
```

#### Amazon S3

Use [Amazon S3](https://aws.amazon.com/s3/) for a fully hosted solution for your code signing identities. Certificates are stored on S3, inside a storage bucket you provide. You can also directly access the files using the web console.

This will create a `Matchfile` in your current directory (or in your `./fastlane/` folder).

Example content (for more advanced setups check out the [fastlane section](#fastlane)):

```ruby-skip-tests
s3_bucket("ios-certificates")
```

### Multiple teams

_match_ can store the codesigning files for multiple development teams:

#### Git Storage

Use one git branch per team. _match_ also supports storing certificates of multiple teams in one repo, by using separate git branches. If you work in multiple teams, make sure to set the `git_branch` parameter to a unique value per team. From there, _match_ will automatically create and use the specified branch for you.

```ruby
match(git_branch: "team1", username: "user@team1.com")
match(git_branch: "team2", username: "user@team2.com")
```

#### Google Cloud or Amazon S3 Storage

If you use Google Cloud or Amazon S3 Storage, you don't need to do anything manually. Just use Google Cloud or Amazon S3 Storage, and the top level folder will be the team ID.

### Run

> Before running _match_ for the first time, you should consider clearing your existing profiles and certificates using the [match nuke command](#nuke).

After running `fastlane match init` you can run the following to generate new certificates and profiles:

```no-highlight
fastlane match appstore
```

```no-highlight
fastlane match development
```

<img src="/img/actions/match_appstore_small.gif" width="550" />

This will create a new certificate and provisioning profile (if required) and store them in your selected storage.
If you previously ran _match_ with the configured storage it will automatically install the existing profiles from your storage.

The provisioning profiles are installed in `~/Library/MobileDevice/Provisioning Profiles` while the certificates and private keys are installed in your Keychain.

To get a more detailed output of what _match_ is doing use

```no-highlight
fastlane match --verbose
```

For a list of all available options run

```no-highlight
fastlane action match
```

#### Handle multiple targets

_match_ can use the same one Git repository, Google Cloud, or Amazon S3 Storage for all bundle identifiers.

If you have several targets with different bundle identifiers, supply them as a comma-separated list:

```no-highlight
fastlane match appstore -a tools.fastlane.app,tools.fastlane.app.watchkitapp
```

You can make this even easier using [_fastlane_](https://fastlane.tools) by creating a `certificates` lane like this:

```ruby
lane :certificates do
  match(app_identifier: ["tools.fastlane.app", "tools.fastlane.app.watchkitapp"])
end
```

Then all your team has to do is run `fastlane certificates` and the keys, certificates and profiles for all targets will be synced.

#### Handle multiple apps per developer/distribution certificate

If you want to use a single developer and/or distribution certificate for multiple apps belonging to the same development team, you may use the same signing identities repository and branch to store the signing identities for your apps:

`Matchfile` example for both App #1 and #2:

```ruby-skip-tests
git_url("https://github.com/example/example-repo.git")
git_branch("master")
```

_match_ will reuse certificates and will create separate provisioning profiles for each app.

#### Passphrase

*Git Repo storage only*

When running _match_ for the first time on a new machine, it will ask you for the passphrase for the Git repository. This is an additional layer of security: each of the files will be encrypted using `openssl`. Make sure to remember the password, as you'll need it when you run match on a different machine.

To set the passphrase to decrypt your profiles using an environment variable (and avoid the prompt) use `MATCH_PASSWORD`.

#### Migrate from Git Repo to Google Cloud

If you're already using a Git Repo, but would like to switch to using Google Cloud Storage, run the following command to automatically migrate all your existing code signing identities and provisioning profiles

```no-highlight
fastlane match migrate
```

After a successful migration you can safely delete your Git repo.

#### Google Cloud access control

*Google Cloud Storage only*

There are two cases for reading and writing certificates stored in a Google Cloud storage bucket:

1. Continuous integration jobs. These will authenticate to your Google Cloud project via a service account, and use a `gc_keys.json` file as credentials.
1. Developers on a local workstation. In this case, you should choose whether everyone on your team will create their own `gc_keys.json` file, or whether you want to manage access to the bucket directly using your developers' Google accounts.

When running `fastlane match init` the first time, the setup process will give you the option to create your `gc_keys.json` file. This file contains the authentication credentials needed to access your Google Cloud storage bucket. Make sure to keep that file secret and never add it to version control. We recommend adding `gc_keys.json` to your `.gitignore`

##### Managing developer access via keys

If you want to manage developer access to your certificates via authentication keys, every developer should create their own `gc_keys.json` and add the file to all their work machines. This will give the admin full control over who has read/write access to the given Storage bucket. At the same time it allows your team to revoke a single key if a file gets compromised.

##### Managing developer access via Google accounts

If your developers already have Google accounts and access to your Google Cloud project, you can also manage access to the storage bucket via [Cloud Identity and Access Management (IAM)](https://cloud.google.com/storage/docs/access-control/iam). Just [set up](https://cloud.google.com/storage/docs/access-control/lists) individual developer accounts or an entire Google Group containing your team as readers and writers on your storage bucket.

You can then specify the Google Cloud project id containing your storage bucket in your `Matchfile`:

```ruby-skip-tests
storage_mode("google_cloud")
google_cloud_bucket_name("my-app-certificates")
google_cloud_project_id("my-app-project")
```

This lets developers on your team use [Application Default Credentials](https://cloud.google.com/docs/authentication/production) when accessing your storage bucket. After installing the [Google Cloud SDK](https://cloud.google.com/sdk/), they only need to run the following command once:
```no-highlight
gcloud auth application-default login
```
... and log in with their Google account. Then, when they run `fastlane match`, _match_ will use these credentials to read from and write to the storage bucket.

#### New machine

To set up the certificates and provisioning profiles on a new machine, you just run the same command using:

```no-highlight
fastlane match development
```

You can also run _match_ in a `readonly` mode to be sure it won't create any new certificates or profiles.

```no-highlightno-highlight
fastlane match development --readonly
```

We recommend to always use `readonly` mode when running _fastlane_ on CI systems. This can be done using

```ruby
lane :beta do
  match(type: "appstore", readonly: is_ci)

  gym(scheme: "Release")
end
```

#### Access Control

A benefit of using _match_ is that it enables you to give the developers of your team access to the code signing certificates without having to give everyone access to the Developer Portal:

1. Run _match_ to store the certificates in a Git repo or Google Cloud Storage
2. Grant access to the Git repo / Google Cloud Storage Bucket to your developers and give them the passphrase (for git storage)
3. The developers can now run _match_ which will install the latest code signing profiles so they can build and sign the application without having to have access to the Apple Developer Portal
4. Every time you run _match_ to update the profiles (e.g. add a new device), all your developers will automatically get the latest profiles when running _match_

If you decide to run _match_ without access to the Developer Portal, make sure to use the `--readonly` option so that the commands don't ask you for the password to the Developer Portal.

The advantage of this approach is that no one in your team will revoke a certificate by mistake, while having all code signing secrets in one location.

#### Folder structure

After running _match_ for the first time, your Git repo or Google Cloud bucket will contain 2 directories:

- The `certs` folder contains all certificates with their private keys
- The `profiles` folder contains all provisioning profiles

Additionally, _match_ creates a nice repo `README.md` for you, making it easy to onboard new team members:

<p align="center">
  <img src="/img/actions/github_repo.png" width="700" />
</p>

In the case of Google Cloud, the top level folder will be the team ID.

#### fastlane

Add _match_ to your `Fastfile` to automatically fetch the latest code signing certificates with [_fastlane_](https://fastlane.tools).

```
match(type: "appstore")

match(type: "development")

match(type: "adhoc",
      app_identifier: "tools.fastlane.app")

match(type: "enterprise",
      app_identifier: "tools.fastlane.app")

# _match_ should be called before building the app with _gym_
gym
# ...
```

##### Registering new devices

By using _match_, you'll save a lot of time every time you add new device to your Ad Hoc or Development profiles. Use _match_ in combination with the [`register_devices`](https://docs.fastlane.tools/actions/register_devices/) action.

```ruby
lane :beta do
  register_devices(devices_file: "./devices.txt")
  match(type: "adhoc", force_for_new_devices: true)
end
```

By using the `force_for_new_devices` parameter, _match_ will check if the (enabled) device count has changed since the last time you ran _match_, and automatically re-generate the provisioning profile if necessary. You can also use `force: true` to re-generate the provisioning profile on each run.

_**Important:** The `force_for_new_devices` parameter is ignored for App Store provisioning profiles since they don't contain any device information._

If you're not using `Fastfile`, you can also use the `force_for_new_devices` option from the command line:

```no-highlight
fastlane match adhoc --force_for_new_devices
```

##### Offline profile use

If your profile requires the 'Offline support (7 day validity)' setting for use without Internet, use `offline_profile: true` to add this permission to generated profiles.

##### Templates (aka: custom entitlements)

_match_ can generate profiles that contain custom entitlements by passing in the entitlement's name with the `template_name` parameter.

```
match(type: "development",
      template_name: "Apple Pay Pass Suppression Development")
```

### Setup Xcode project

[Docs on how to set up your Xcode project](/codesigning/xcode-project/)

#### To build from the command line using [_fastlane_](https://fastlane.tools)

_match_ automatically pre-fills environment variables with the UUIDs of the correct provisioning profiles, ready to be used in your Xcode project.

More information about how to setup your Xcode project can be found [here](/codesigning/xcode-project/)

#### To build from Xcode manually

This is useful when installing your application on your device using the Development profile.

You can statically select the right provisioning profile in your Xcode project (the name will be `match Development tools.fastlane.app`).

[Docs on how to set up your Xcode project](/codesigning/xcode-project/)

### Continuous Integration

#### Git repo access

There is one tricky part of setting up a CI system to work with _match_, which is enabling the CI to access the repo. Usually you'd just add your CI's public ssh key as a deploy key to your _match_ repo, but since your CI will already likely be using its public ssh key to access the codebase repo, [you won't be able to do that](https://help.github.com/articles/error-key-already-in-use/).

Some repo hosts might allow you to use the same deploy key for different repos, but GitHub will not. If your host does, you don't need to worry about this, just add your CI's public ssh key as a deploy key for your _match_ repo and scroll down to "_Encryption password_".

There are a few ways around this:

1. Create a new account on your repo host with read-only access to your _match_ repo. Bitrise have a good description of this [here](http://devcenter.bitrise.io/faq/adding-projects-with-submodules/).
2. Some CIs allow you to upload your signing credentials manually, but obviously this means that you'll have to re-upload the profiles/keys/certs each time they change.

Neither solution is pretty. It's one of those _trade-off_ things. Do you care more about **not** having an extra account sitting around, or do you care more about having the :sparkles: of auto-syncing of credentials.

#### Git repo encryption password

Once you've decided which approach to take, all that's left to do is to set your encryption password as secret environment variable named `MATCH_PASSWORD`. _match_ will pick this up when it's run.

#### Google Cloud Storage access

Accessing Google Cloud Storage from your CI system requires you to provide the `gc_keys.json` file as part of your build. How you implement this is your decision. You can inject that file during build time.

#### Amazon S3 Storage access

Accessing Amazon S3 Storage from your CI system requires you to provide the `s3_region`, `s3_access_key`, `s3_secret_access_key` and `s3_bucket` options (or environment variables), with keys that has read access to the bucket.

### Nuke

If you never really cared about code signing and have a messy Apple Developer account with a lot of invalid, expired or Xcode managed profiles/certificates, you can use the `match nuke` command to revoke your certificates and provisioning profiles. Don't worry, apps that are already available in the App Store / TestFlight will still work. Builds distributed via Ad Hoc or Enterprise will be disabled after nuking your account, so you'll have to re-upload a new build. After clearing your account you'll start from a clean state, and you can run _match_ to generate your certificates and profiles again.

To revoke all certificates and provisioning profiles for a specific environment:

```no-highlight
fastlane match nuke development
fastlane match nuke distribution
fastlane match nuke enterprise
```

<img src="/img/actions/match_nuke.gif" width="550" />

You'll have to confirm a list of profiles / certificates that will be deleted.

## Advanced Git Storage features

### Change Password

To change the password of your repo and therefore decrypting and encrypting all files run:

```no-highlight
fastlane match change_password
```

You'll be asked for the new password on all your machines on the next run.

### Import

To import and encrypt a certificate (`.cer`), the private key (`.p12`) and the provisioning profiles (`.mobileprovision` or `.provisionprofile`) into the _match_ repo run:

```no-highlight
fastlane match import
```

You'll be prompted for the certificate (`.cer`), the private key (`.p12`) and the provisioning profiles (`.mobileprovision` or `.provisionprofile`) paths. _match_ will first validate the certificate (`.cer`) against the Developer Portal before importing the certificate, the private key and the provisioning profiles into the specified _match_ repository.

However if there is no access to the developer portal but there are certificates, private keys and profiles provided, you can use the `skip_certificate_matching` option to tell _match_ not to verify the certificates. Like this:

```no-highlight
fastlane match import --skip_certificate_matching true
```
This will skip login to Apple Developer Portal and will import the provided certificate, private key and profile directly to the certificates repo.

Please be careful when using this option and ensure the certificates and profiles match the type (development, adhoc, appstore, enterprise, developer_id) and are not revoked or expired.

### Manual Decrypt

If you want to manually decrypt or encrypt a file, you can use the companion script `match_file`:

```no-highlight
match_file encrypt "<fileYouWantToEncryptPath>" ["<encryptedFilePath>"]

match_file decrypt "<fileYouWantToDecryptPath>" ["<decryptedFilePath>"]
```

The password will be asked interactively.

_**Note:** You may need to swap double quotes `"` for single quotes `'` if your match password contains an exclamation mark `!`._

#### Export Distribution Certificate and Private Key as Single .p12 File

_match_ stores the certificate (`.cer`) and the private key (`.p12`) files separately. The following steps will repackage the separate certificate and private key into a single `.p12` file.

Decrypt your cert found in `certs/<type>/<unique-id>.cer` as a pem file:

```no-highlight
openssl aes-256-cbc -k "<password>" -in "certs/<type>/<unique-id>.cer" -out "cert.der" -a -d -md [md5|sha256]
openssl x509 -inform der -in cert.der -out cert.pem
```

Decrypt your private key found in `certs/<type>/<unique-id>.p12` as a pem file:

```no-highlight
openssl aes-256-cbc -k "<password>" -in "certs/distribution/<unique-id>.p12" -out "key.pem" -a -d -md [md5|sha256]
```

Generate an encrypted p12 file with the same or new password:

```no-highlight
openssl pkcs12 -export -out "cert.p12" -inkey "key.pem" -in "cert.pem" -password pass:<password>
```

## Is this secure?

### Git

Both your keys and provisioning profiles are encrypted using OpenSSL using a passphrase.

Storing your private keys in a Git repo may sound off-putting at first. We did an analysis of potential security issues, see section below.

### Google Cloud Storage

All your keys and provisioning profiles are encrypted using Google managed keys.

### What could happen if someone stole a private key?

If attackers would have your certificate and provisioning profile, they could codesign an application with the same bundle identifier.

What's the worst that could happen for each of the profile types?

#### App Store Profiles

An App Store profile can't be used for anything as long as it's not re-signed by Apple. The only way to get an app resigned is to submit an app for review which could take anywhere from 24 hours to a few days (checkout [appreviewtimes.com](http://appreviewtimes.com) for up-to-date expectations). Attackers could only submit an app for review, if they also got access to your App Store Connect credentials (which are not stored in git, but in your local keychain). Additionally you get an email notification every time a build gets uploaded to cancel the submission even before your app gets into the review stage.

#### Development and Ad Hoc Profiles

In general those profiles are harmless as they can only be used to install a signed application on a small subset of devices. To add new devices, the attacker would also need your Apple Developer Portal credentials (which are not stored in git, but in your local keychain).

#### Enterprise Profiles

Attackers could use an In-House profile to distribute signed application to a potentially unlimited number of devices. All this would run under your company name and it could eventually lead to Apple revoking your In-House account. However it is very easy to revoke a certificate to remotely break the app on all devices.

Because of the potentially dangerous nature of In-House profiles please use _match_ with enterprise profiles with caution, ensure your git repository is private and use a secure password.

#### To sum up

- You have full control over the access list of your Git repo, no third party service involved
- Even if your certificates are leaked, they can't be used to cause any harm without your App Store Connect login credentials
- Use In-House enterprise profile with _match_ with caution
- If you use GitHub or Bitbucket we encourage enabling 2 factor authentication for all accounts that have access to the certificates repo
- The complete source code of _match_ is fully open source on [GitHub](https://github.com/fastlane/fastlane/)
