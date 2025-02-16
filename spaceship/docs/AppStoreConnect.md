# App Store Connect API

- [Usage](#usage)
  * [Login](#login)
  * [Applications](#applications)
  * [AppVersions](#appversions)
  * [Select a build for review](#select-a-build-for-review)
  * [Submit app for App Store Review](#submit-app-for-app-store-review)
  * [Release reviewed build](#release-reviewed-build)
  * [Build Trains (TestFlight)](#build-trains-testflight)
  * [Builds](#builds)
  * [Processing builds](#processing-builds)
  * [Testers](#testers)
  * [App ratings & reviews](#app-ratings--reviews)
  * [App Analytics](#app-analytics)
  * [Bundle Id](#bundle-id-auth-key)
  * [Bundle Id Capability](#bundle-id-capability-auth-key)
- [License](#license)

## Usage

To quickly play around with _spaceship_ launch `irb` in your terminal and execute `require "spaceship"`.

In general the classes are pre-fixed with the `ConnectAPI` module. If you want to use the legacy web API, make sure to use `Tunes`, which is an artifact from when "App Store Connect" was still called "iTunes Connect".

### Login

*Note*: If you use both the Developer Portal and App Store Connect API, you'll have to login on both, as the user might have different user credentials.

```ruby

token = Spaceship::ConnectAPI::Token.create(
  key_id: 'the-key-id',
  issuer_id: 'the-issuer-id',
  filepath:  File.absolute_path("../AuthKey_the-key-id.p8")
)

Spaceship::ConnectAPI.token = token

```

### Applications

```ruby
# Fetch all available applications
all_apps = Spaceship::ConnectAPI::App.all

# Find a specific app based on the bundle identifier
app = Spaceship::ConnectAPI::App.find("com.krausefx.app")

app = Spaceship::ConnectAPI.get_app(app_id: 1013943394).first

# Access information about the app
app.id              # => 1013943394
app.name            # => "Spaceship App"
app.bundle_id       # => "com.krausefx.app"
app.sku             # => "SpaceshipApp01"
app.primary_locale  # => "en-US"

# Show the names of all your apps
Spaceship::ConnectAPI::App.all.collect do |app|
  app.name
end

# Create a new app
# Currently only works with Apple ID login (not API Key)
app = Spaceship::ConnectAPI::App.create(name: "App Name",
                                        version_string: "1.0", # initial version
                                        sku: "123",
                                        primary_locale: "en-us",
                                        bundle_id: "com.krausefx.app",
                                        platforms: ["IOS"],
                                        company_name: "krause inc")
```

To update non version specific details, use the following code

```ruby
app = Spaceship::Tunes::Application.find("com.krausefx.app")
details = app.details
details.name['en-US'] = "App Name"
details.privacy_url['en-US'] = "https://fastlane.tools"
details.save!
```

To change the price of the app (it's not necessary to call `save!` when updating the price)

```ruby
app = Spaceship::Tunes::Application.find("com.krausefx.app")
app.update_price_tier!("3")
```

### AppVersions

<img src="/spaceship/assets/docs/AppVersions.png" width="500">

You can have up to 2 app versions at the same time. One is usually the version already available in the App Store (`get_live_app_store_version`) and one being the one you can edit (`get_edit_app_store_version`).

While you usually can modify some values in the production version (e.g. app description), most options are already locked.

With _spaceship_ you can access the versions like this

```ruby
app.get_live_app_store_version # the version that's currently available in the App Store
app.get_edit_app_store_version # the version that's in `Prepare for Submission`, `Metadata Rejected`, `Rejected`, `Developer Rejected`, `Waiting for Review`, `Invalid Binary` mode
app.get_latest_app_store_version # the version that's the latest one
app.get_pending_release_app_store_version # the version that's in `Pending Developer Release` or `Pending Apple Release` mode
app.get_in_review_app_store_version # the version that is in `In Review` mode
```

You can then go ahead and modify app metadata on the version objects:

```ruby
v = app.get_edit_app_store_version

# Access information
v.app_version_state       # => "Waiting for Review"
v.version_string          # => "0.9.14"

# Build is not always available in all app_version_state, e.g. not available in `Prepare for Submission`
build_number = v.build.nil? ? nil : v.build.version

# Update app metadata
copyright = "#{Time.now.year} Felix Krause"
v.update(attributes: { "copyright": copyright })

# Get a list of available languages for this app
version = app.get_edit_app_store_version(includes: 'appStoreVersionSubmission,build,appStoreVersionLocalizations')
localizations = version.appStoreVersionLocalizations

localization = localizations.first
localization.locale       # => "en-GB"
localization.description  # => "App description"

# Update localized app metadata
localization.update(attributes: { description: "New Description" })

# set the app age rating

# fetch_age_rating_declaration with `fetch_live_app_info` or `fetch_edit_app_info`
app_info = app.fetch_edit_app_info
declaration = app_info.fetch_age_rating_declaration unless app_info.nil?

# update age_rating_declaration
declaration.update(attributes: {
  "violenceCartoonOrFantasy": "NONE",
  "matureOrSuggestiveThemes": "NONE",
  "unrestrictedWebAccess": false
})
# Available values:
# https://github.com/fastlane/fastlane/blob/master/deliver/assets/example_rating_config.json
# https://docs.fastlane.tools/actions/deliver/#reference (Open "View all available categories, languages, etc.")

```

Available options:
```ruby
####
# General app store version metadata (app_store_version)
####

attr_accessor :platform
attr_accessor :version_string
attr_accessor :app_store_state
attr_accessor :app_version_state
attr_accessor :store_icon
attr_accessor :watch_store_icon
attr_accessor :copyright
attr_accessor :release_type
attr_accessor :earliest_release_date
attr_accessor :is_watch_only
attr_accessor :downloadable
attr_accessor :created_date
attr_accessor :app_store_version_submission
attr_accessor :app_store_version_phased_release
attr_accessor :app_store_review_detail
attr_accessor :app_store_version_localizations

####
# App Review Information (app_store_review_detail)
####

attr_accessor :contact_first_name
attr_accessor :contact_last_name
attr_accessor :contact_phone
attr_accessor :contact_email
attr_accessor :demo_account_name
attr_accessor :demo_account_password
attr_accessor :demo_account_required
attr_accessor :notes
attr_accessor :app_store_review_attachments

####
# Localized values (app_store_version_localization)
####

attr_accessor :description
attr_accessor :locale
attr_accessor :keywords
attr_accessor :marketing_url
attr_accessor :promotional_text
attr_accessor :support_url
attr_accessor :whats_new
attr_accessor :app_screenshot_sets
attr_accessor :app_preview_sets

```

**Important**: For a complete documentation with the return type, description and notes for each of the properties, check out [app_store_version.rb](https://github.com/fastlane/fastlane/blob/master/spaceship/lib/spaceship/connect_api/models/app_store_version.rb) and other models.

### Select a build for review

For a full list of available options, check out [submit_for_review.rb](https://github.com/fastlane/fastlane/blob/master/deliver/lib/deliver/submit_for_review.rb)

```ruby
version = app.get_edit_app_store_version
build = Spaceship::ConnectAPI::Build.all(app_id: app.id, platform: platform).first
version.select_build(build_id: build.id)
```
### Submit app for App Store Review

```ruby
# Check out submit_for_review.rb to get an overview how to modify submission information
version.create_app_store_version_submission
```

**Important**: For a complete example how to prepare version for review and submit it for review check out [submit_for_review.rb](https://github.com/fastlane/fastlane/blob/master/deliver/lib/deliver/submit_for_review.rb).


### Release reviewed build

```ruby
version = app.get_pending_release_app_store_version
unless version.nil?
  Spaceship::ConnectAPI.post_app_store_version_release_request(app_store_version_id: version.id)
end
```

or

```ruby
version = app.get_pending_release_app_store_version
version.create_app_store_version_release_request unless version.nil?
```

### Build Trains (TestFlight)

<img src="/spaceship/assets/docs/BuildTrains.png" width="700">

To clarify:

- **version number**: Is set via the `CFBundleShortVersionString` property. It's the version number that appears on the App Store. (`0.9.21` on the screenshot)
- **build number**: Is set via the `CFBundleVersion` property. It's not visible in the App Store. It has to be incremented before uploading a new build. (`99993` on the screenshot)

A build train contains all builds for a give `version number` (e.g. `0.9.21`). Within the build train you have *n* builds, each having a different `build number` (e.g. `99993`).

```ruby
app = Spaceship::Tunes::Application.find("com.krausefx.app")

# Access all build trains for an app
app.all_build_train_numbers   # => ["0.9.21"]

# Access the build train via the version number
train = app.build_trains["0.9.21"]

# Access all builds for a given train
train.count            # => 1
build = train.first
```

### Builds

```ruby
# Continue from the BuildTrains example
build.build_version           # => "99993"  (the build number)
build.train_version           # => "0.9.21" (the version number)
build.install_count           # => 1
build.crash_count             # => 0

build.internal_state          # => testflight.build.state.testing.ready
build.external_state          # => testflight.build.state.submit.ready
```

You can even submit a build for external beta review (after you have set all necessary metadata - see above)
```ruby
build.submit_for_testflight_review!
```

### Processing builds

To also access those builds that are "stuck" at `Processing` at App Store Connect for a while:

```ruby
Spaceship::ConnectAPI::Build.all(app_id: app.id, processing_states: "PROCESSING") # => Array of processing builds for this application
```

### Testers

There are 3 types of testers:

- **External testers**: usually not part of your team. You can invite up to 10000 external testers. Before distributing a build to those testers you need to submit your app to beta review.
- **Internal testers**: Employees that are registered in your App Store Connect team. They get access to all builds without having to wait for review.
- **Sandbox testers**: Dummy accounts to test development-mode apps with in-app purchase or Apple Pay.

```ruby
# Find a tester based on the email address
tester = Spaceship::TestFlight::Tester.find(app_id: "some_app_id", email: "felix@krausefx.com")

tester = Spaceship::ConnectAPI::BetaTester.find(email: "felix@krausefx.com")

# Creating new testers
Spaceship::TestFlight::Tester.create_app_level_tester(
      app_id: "io.myapp",
       email: "github@krausefx.com",
  first_name: "Felix",
   last_name: "Krause"
)

```
Right now, _spaceship_ can't modify or create internal testers.

```ruby
# Load all sandbox testers
testers = Spaceship::ConnectAPI::SandboxTester.all

# Delete sandbox testers
testers.each do |tester|
  if UI.confirm("Delete #{tester.email}?")
    tester.delete!
  end
end

# Create a sandbox tester
testers = Spaceship::ConnectAPI::SandboxTester.create(
  first_name: "Test", # required
  last_name: "Three", # required
  email: "sandbox@test.com", # required
  password: "Passwordtest1", # required. Must contain >=8 characters, >=1 uppercase, >=1 lowercase, >=1 numeric.
  confirm_password: "Passwordtest1", # required
  secret_question: "Question", # required. Must contain >=6 characters
  secret_answer: "Answer", # required. Must contain >=6 characters
  birth_date: "1980-03-01", # required
  app_store_territory: "USA" # required
)
```

### App ratings & reviews

```ruby
app = Spaceship::Tunes::Application.find("com.krausefx.app")

# Get the rating summary for an application
ratings = app.ratings # => Spaceship::Tunes::AppRatings

# Get the number of 5 star ratings
five_star_count = ratings.five_star_rating_count

# Find the average rating across all stores
average_rating = ratings.average_rating

# Find the average rating for a given store front
average_rating = app.ratings(storefront: "US").average_rating

# Get reviews for a given store front
reviews = ratings.reviews("US") # => Array of hashes representing review data

```

### App Analytics

```ruby
app = Spaceship::Tunes::Application.find("com.krausefx.app")

# Start app analytics
analytics = app.analytics                # => Spaceship::Tunes::AppAnalytics

# Get all the different metrics from App Analytics
# By default covering the last 7 days

# Get app units
units = analytics.app_units              # => Array of dates representing raw data for each day

# Get app store page views
views = analytics.app_views              # => Array of dates representing raw data for each day

# Get impressions metrics
impressions = analytics.app_impressions  # => Array of dates representing raw data for each day

# Get app sales
sales = analytics.app_sales              # => Array of dates representing raw data for each day

# Get paying users
users = analytics.paying_users           # => Array of dates representing raw data for each day

# Get in app purchases
iap = analytics.app_in_app_purchases     # => Array of dates representing raw data for each day

# Get app installs
installs = analytics.app_installs        # => Array of dates representing raw data for each day

# Get app sessions
sessions = analytics.app_sessions        # => Array of dates representing raw data for each day

# Get active devices
devices = analytics.app_active_devices   # => Array of dates representing raw data for each day

# Get crashes
crashes = analytics.app_crashes          # => Array of dates representing raw data for each day
```

### Bundle Id (Auth Key)

```ruby
# Fetch all bundle identifiers
all_identifiers = Spaceship::ConnectAPI::BundleId.all

# Find a specific identifier based on the bundle identifier
bundle_id = Spaceship::ConnectAPI::BundleId.find("com.krausefx.app")

# Access information about the bundle identifier
bundle_id.name
bundle_id.platform
bundle_id.identifier
bundle_id.seed_id

# Create a new identifier
identifier = Spaceship::ConnectAPI::BundleId.create(name: "Description of the identifier",
                                                    identifier: "com.krausefx.app")
```
Note: Platform will be set to UNIVERSAL no matter if you specify IOS or MAC_OS and seed_id is by default set to team_id


### Bundle Id Capability (Auth Key)

```ruby
# Fetch all capabilities for bundle identifier
bundle_id = Spaceship::ConnectAPI::BundleId.find("com.krausefx.app")
capabilities = bundle_id.get_capabilities

# Create a new capability for bundle identifier
bundle_id.create_capability(Spaceship::ConnectAPI::BundleIdCapability::Type::MAPS)

# Create a new capability with known bundle identifier id
bundle_id_capability = Spaceship::ConnectAPI::BundleIdCapability.create(bundle_id_id: "123456789",
                                                                        capability_type: Spaceship::ConnectAPI::BundleIdCapability::Type::MAPS)

# Delete an capability from bundle identifier
capabilities.each do |capability|
  if capability.capability_type == Spaceship::ConnectAPI::BundleIdCapability::Type::MAPS
    capability.delete!
  end
end
```

## License

> This project and all fastlane tools are in no way affiliated with Apple Inc. This project is open source under the MIT license, which means you have full access to the source code and can modify it to fit your own needs. All fastlane tools run on your own computer or server, so your credentials or other sensitive information will never leave your own computer. You are responsible for how you use fastlane tools.
