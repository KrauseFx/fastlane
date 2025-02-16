// DeliverfileProtocol.swift
// Copyright (c) 2024 FastlaneTools

public protocol DeliverfileProtocol: AnyObject {
    /// Path to your App Store Connect API Key JSON file (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-json-file)
    var apiKeyPath: String? { get }

    /// Your App Store Connect API Key information (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-hash-option)
    var apiKey: [String: Any]? { get }

    /// Your Apple ID Username
    var username: String? { get }

    /// The bundle identifier of your app
    var appIdentifier: String? { get }

    /// The version that should be edited or created
    var appVersion: String? { get }

    /// Path to your ipa file
    var ipa: String? { get }

    /// Path to your pkg file
    var pkg: String? { get }

    /// If set the given build number (already uploaded to iTC) will be used instead of the current built one
    var buildNumber: String? { get }

    /// The platform to use (optional)
    var platform: String { get }

    /// Modify live metadata, this option disables ipa upload and screenshot upload
    var editLive: Bool { get }

    /// Force usage of live version rather than edit version
    var useLiveVersion: Bool { get }

    /// Path to the folder containing the metadata files
    var metadataPath: String? { get }

    /// Path to the folder containing the screenshots
    var screenshotsPath: String? { get }

    /// Skip uploading an ipa or pkg to App Store Connect
    var skipBinaryUpload: Bool { get }

    /// Don't upload the screenshots
    var skipScreenshots: Bool { get }

    /// Don't upload the metadata (e.g. title, description). This will still upload screenshots
    var skipMetadata: Bool { get }

    /// Don’t create or update the app version that is being prepared for submission
    var skipAppVersionUpdate: Bool { get }

    /// Skip verification of HTML preview file
    var force: Bool { get }

    /// Clear all previously uploaded screenshots before uploading the new ones
    var overwriteScreenshots: Bool { get }

    /// Timeout in seconds to wait before considering screenshot processing as failed, used to handle cases where uploads to the App Store are stuck in processing
    var screenshotProcessingTimeout: Int { get }

    /// Sync screenshots with local ones. This is currently beta option so set true to 'FASTLANE_ENABLE_BETA_DELIVER_SYNC_SCREENSHOTS' environment variable as well
    var syncScreenshots: Bool { get }

    /// Submit the new version for Review after uploading everything
    var submitForReview: Bool { get }

    /// Verifies archive with App Store Connect without uploading
    var verifyOnly: Bool { get }

    /// Rejects the previously submitted build if it's in a state where it's possible
    var rejectIfPossible: Bool { get }

    /// After submitting a new version, App Store Connect takes some time to recognize the new version and we must wait until it's available before attempting to upload metadata for it. There is a mechanism that will check if it's available and retry with an exponential backoff if it's not available yet. This option specifies how many times we should retry before giving up. Setting this to a value below 5 is not recommended and will likely cause failures. Increase this parameter when Apple servers seem to be degraded or slow
    var versionCheckWaitRetryLimit: Int { get }

    /// Should the app be automatically released once it's approved? (Cannot be used together with `auto_release_date`)
    var automaticRelease: Bool? { get }

    /// Date in milliseconds for automatically releasing on pending approval (Cannot be used together with `automatic_release`)
    var autoReleaseDate: Int? { get }

    /// Enable the phased release feature of iTC
    var phasedRelease: Bool { get }

    /// Reset the summary rating when you release a new version of the application
    var resetRatings: Bool { get }

    /// The price tier of this application
    var priceTier: Int? { get }

    /// Path to the app rating's config
    var appRatingConfigPath: String? { get }

    /// Extra information for the submission (e.g. compliance specifications)
    var submissionInformation: [String: Any]? { get }

    /// The ID of your App Store Connect team if you're in multiple teams
    var teamId: String? { get }

    /// The name of your App Store Connect team if you're in multiple teams
    var teamName: String? { get }

    /// The short ID of your Developer Portal team, if you're in multiple teams. Different from your iTC team ID!
    var devPortalTeamId: String? { get }

    /// The name of your Developer Portal team if you're in multiple teams
    var devPortalTeamName: String? { get }

    /// The provider short name to be used with the iTMSTransporter to identify your team. This value will override the automatically detected provider short name. To get provider short name run `xcrun iTMSTransporter -m provider -u 'USERNAME' -p 'PASSWORD' -account_type itunes_connect -v off`. The short names of providers should be listed in the second column
    var itcProvider: String? { get }

    /// Run precheck before submitting to app review
    var runPrecheckBeforeSubmit: Bool { get }

    /// The default precheck rule level unless otherwise configured
    var precheckDefaultRuleLevel: String { get }

    /// **DEPRECATED!** Removed after the migration to the new App Store Connect API in June 2020 - An array of localized metadata items to upload individually by language so that errors can be identified. E.g. ['name', 'keywords', 'description']. Note: slow
    var individualMetadataItems: [String]? { get }

    /// **DEPRECATED!** Removed after the migration to the new App Store Connect API in June 2020 - Metadata: The path to the app icon
    var appIcon: String? { get }

    /// **DEPRECATED!** Removed after the migration to the new App Store Connect API in June 2020 - Metadata: The path to the Apple Watch app icon
    var appleWatchAppIcon: String? { get }

    /// Metadata: The copyright notice
    var copyright: String? { get }

    /// Metadata: The english name of the primary category (e.g. `Business`, `Books`)
    var primaryCategory: String? { get }

    /// Metadata: The english name of the secondary category (e.g. `Business`, `Books`)
    var secondaryCategory: String? { get }

    /// Metadata: The english name of the primary first sub category (e.g. `Educational`, `Puzzle`)
    var primaryFirstSubCategory: String? { get }

    /// Metadata: The english name of the primary second sub category (e.g. `Educational`, `Puzzle`)
    var primarySecondSubCategory: String? { get }

    /// Metadata: The english name of the secondary first sub category (e.g. `Educational`, `Puzzle`)
    var secondaryFirstSubCategory: String? { get }

    /// Metadata: The english name of the secondary second sub category (e.g. `Educational`, `Puzzle`)
    var secondarySecondSubCategory: String? { get }

    /// **DEPRECATED!** This is no longer used by App Store Connect - Metadata: A hash containing the trade representative contact information
    var tradeRepresentativeContactInformation: [String: Any]? { get }

    /// Metadata: A hash containing the review information
    var appReviewInformation: [String: Any]? { get }

    /// Metadata: Path to the app review attachment file
    var appReviewAttachmentFile: String? { get }

    /// Metadata: The localised app description
    var description: [String: Any]? { get }

    /// Metadata: The localised app name
    var name: [String: Any]? { get }

    /// Metadata: The localised app subtitle
    var subtitle: [String: Any]? { get }

    /// Metadata: An array of localised keywords
    var keywords: [String: Any]? { get }

    /// Metadata: An array of localised promotional texts
    var promotionalText: [String: Any]? { get }

    /// Metadata: Localised release notes for this version
    var releaseNotes: [String: Any]? { get }

    /// Metadata: Localised privacy url
    var privacyUrl: [String: Any]? { get }

    /// Metadata: Localised Apple TV privacy policy text
    var appleTvPrivacyPolicy: [String: Any]? { get }

    /// Metadata: Localised support url
    var supportUrl: [String: Any]? { get }

    /// Metadata: Localised marketing url
    var marketingUrl: [String: Any]? { get }

    /// Metadata: List of languages to activate
    var languages: [String]? { get }

    /// Ignore errors when invalid languages are found in metadata and screenshot directories
    var ignoreLanguageDirectoryValidation: Bool { get }

    /// Should precheck check in-app purchases?
    var precheckIncludeInAppPurchases: Bool { get }

    /// The (spaceship) app ID of the app you want to use/modify
    var app: Int? { get }
}

public extension DeliverfileProtocol {
    var apiKeyPath: String? { return nil }
    var apiKey: [String: Any]? { return nil }
    var username: String? { return nil }
    var appIdentifier: String? { return nil }
    var appVersion: String? { return nil }
    var ipa: String? { return nil }
    var pkg: String? { return nil }
    var buildNumber: String? { return nil }
    var platform: String { return "ios" }
    var editLive: Bool { return false }
    var useLiveVersion: Bool { return false }
    var metadataPath: String? { return nil }
    var screenshotsPath: String? { return nil }
    var skipBinaryUpload: Bool { return false }
    var skipScreenshots: Bool { return false }
    var skipMetadata: Bool { return false }
    var skipAppVersionUpdate: Bool { return false }
    var force: Bool { return false }
    var overwriteScreenshots: Bool { return false }
    var screenshotProcessingTimeout: Int { return 3600 }
    var syncScreenshots: Bool { return false }
    var submitForReview: Bool { return false }
    var verifyOnly: Bool { return false }
    var rejectIfPossible: Bool { return false }
    var versionCheckWaitRetryLimit: Int { return 7 }
    var automaticRelease: Bool? { return nil }
    var autoReleaseDate: Int? { return nil }
    var phasedRelease: Bool { return false }
    var resetRatings: Bool { return false }
    var priceTier: Int? { return nil }
    var appRatingConfigPath: String? { return nil }
    var submissionInformation: [String: Any]? { return nil }
    var teamId: String? { return nil }
    var teamName: String? { return nil }
    var devPortalTeamId: String? { return nil }
    var devPortalTeamName: String? { return nil }
    var itcProvider: String? { return nil }
    var runPrecheckBeforeSubmit: Bool { return true }
    var precheckDefaultRuleLevel: String { return "warn" }
    var individualMetadataItems: [String]? { return nil }
    var appIcon: String? { return nil }
    var appleWatchAppIcon: String? { return nil }
    var copyright: String? { return nil }
    var primaryCategory: String? { return nil }
    var secondaryCategory: String? { return nil }
    var primaryFirstSubCategory: String? { return nil }
    var primarySecondSubCategory: String? { return nil }
    var secondaryFirstSubCategory: String? { return nil }
    var secondarySecondSubCategory: String? { return nil }
    var tradeRepresentativeContactInformation: [String: Any]? { return nil }
    var appReviewInformation: [String: Any]? { return nil }
    var appReviewAttachmentFile: String? { return nil }
    var description: [String: Any]? { return nil }
    var name: [String: Any]? { return nil }
    var subtitle: [String: Any]? { return nil }
    var keywords: [String: Any]? { return nil }
    var promotionalText: [String: Any]? { return nil }
    var releaseNotes: [String: Any]? { return nil }
    var privacyUrl: [String: Any]? { return nil }
    var appleTvPrivacyPolicy: [String: Any]? { return nil }
    var supportUrl: [String: Any]? { return nil }
    var marketingUrl: [String: Any]? { return nil }
    var languages: [String]? { return nil }
    var ignoreLanguageDirectoryValidation: Bool { return false }
    var precheckIncludeInAppPurchases: Bool { return true }
    var app: Int? { return nil }
}

// Please don't remove the lines below
// They are used to detect outdated files
// FastlaneRunnerAPIVersion [0.9.132]
