require_relative 'module'
require_relative './device'
require 'deliver/app_screenshot'

module Frameit
  module Color
    MATTE_BLACK ||= "Matte Black"
    SPACE_GRAY ||= "Space Gray"
    ROSE_GOLD ||= "Rose Gold"
    CLEARLY_WHITE ||= "Clearly White"
    JUST_BLACK ||= "Just Black"
    NOT_PINK ||= "Not Pink"
    SILVER_TITANIUM ||= "Silver Titanium"
    ARCTIC_SILVER ||= "Arctic Silver"
    CORAL_BLUE ||= "Coral Blue"
    MAPLE_GOLD ||= "Maple Gold"
    MIDNIGHT_BLACK ||= "Midnight Black"
    MIDNIGHT_GREEN ||= "Midnight Green"
    ORCHID_GRAY ||= "Orchid Gray"
    BURGUNDY_RED ||= "Burgundy Red"
    LILAC_PURPLE ||= "Lilac Purple"
    SUNRISE_GOLD ||= "Sunrise Gold"
    TITANIUM_GRAY ||= "Titanium Gray"
    FLAMINGO_PINK ||= "Flamingo Pink"
    PRISM_BLACK ||= "Prism Black"
    PRISM_BLUE ||= "Prism Blue"
    PRISM_GREEN ||= "Prism Green"
    PRISM_WHITE ||= "Prism White"
    CERAMIC_WHITE ||= "Ceramic White"
    OH_SO_ORANGE ||= "Oh So Orange"
    AURA_BLACK ||= "Aura Black"
    AURA_GLOW ||= "Aura Glow"
    AURA_PINK ||= "Aura Pink"
    AURA_RED ||= "Aura Red"
    AURA_WHITE ||= "Aura White"
    AURA_BLUE ||= "Aura Blue"
    CORAL ||= "Coral"
    BLACK ||= "Black"
    WHITE ||= "White"
    GOLD ||= "Gold"
    SILVER ||= "Silver"
    BLUE ||= "Blue"
    RED ||= "Red"
    YELLOW ||= "Yellow"
    GREEN ||= "Green"
    PINK ||= "Pink"
    PURPLE ||= "Purple"
    GRAPHITE ||= "Graphite"
    PACIFIC_BLUE ||= "Pacific Blue"
    MIDNIGHT ||= "Midnight"
    STARLIGHT ||= "Starlight"
    SIERRA ||= "Sierra"
    SORTA_SAGE ||= "Sorta Sage"

    def self.all_colors
      Color.constants.map { |c| Color.const_get(c).upcase.gsub(' ', '_') }
    end
  end

  module Orientation
    PORTRAIT ||= "PORTRAIT"
    LANDSCAPE ||= "LANDSCAPE"
  end

  module Platform
    ANDROID ||= "ANDROID"
    IOS ||= "IOS"
    ANY ||= "ANY"

    def self.all_platforms
      Platform.constants.map { |c| Platform.const_get(c) }
    end

    def self.symbol_to_constant(symbol)
      if symbol == :android
        ANDROID
      else
        IOS
      end
    end
  end

  module Devices
    GOOGLE_PIXEL_3 ||= Frameit::Device.new("google-pixel-3", "Google Pixel 3", 7, [[1080, 2160], [2160, 1080]], 443, Color::JUST_BLACK, Platform::ANDROID)
    GOOGLE_PIXEL_3_XL ||= Frameit::Device.new("google-pixel-3-xl", "Google Pixel 3 XL", 7, [[1440, 2960], [2960, 1440]], 523, Color::JUST_BLACK, Platform::ANDROID)
    # Google Pixel 4's priority should be higher than Samsung Galaxy S10+ (priority 8):
    GOOGLE_PIXEL_4 ||= Frameit::Device.new("google-pixel-4", "Google Pixel 4", 9, [[1080, 2280], [2280, 1080]], 444, Color::JUST_BLACK, Platform::ANDROID)
    GOOGLE_PIXEL_4_XL ||= Frameit::Device.new("google-pixel-4-xl", "Google Pixel 4 XL", 9, [[1440, 3040], [3040, 1440]], 537, Color::JUST_BLACK, Platform::ANDROID)
    GOOGLE_PIXEL_5 ||= Frameit::Device.new("google-pixel-5", "Google Pixel 5", 10, [[1080, 2340], [2340, 1080]], 432, Color::JUST_BLACK, Platform::ANDROID)
    HTC_ONE_A9 ||= Frameit::Device.new("htc-one-a9", "HTC One A9", 6, [[1080, 1920], [1920, 1080]], 441, Color::BLACK, Platform::ANDROID)
    HTC_ONE_M8 ||= Frameit::Device.new("htc-one-m8", "HTC One M8", 3, [[1080, 1920], [1920, 1080]], 441, Color::BLACK, Platform::ANDROID)
    HUAWEI_P8 ||= Frameit::Device.new("huawei-p8", "Huawei P8", 5, [[1080, 1920], [1920, 1080]], 424, Color::BLACK, Platform::ANDROID)
    MOTOROLA_MOTO_E ||= Frameit::Device.new("motorola-moto-e", "Motorola Moto E", 3, [[540, 960], [960, 540]], 245, Color::BLACK, Platform::ANDROID)
    MOTOROLA_MOTO_G ||= Frameit::Device.new("motorola-moto-g", "Motorola Moto G", 4, [[1080, 1920], [1920, 1080]], 401, nil, Platform::ANDROID, nil)
    NEXUS_4 ||= Frameit::Device.new("nexus-4", "Nexus 4", 7, [[768, 1280], [1820, 768]], 318, nil, Platform::ANDROID)
    NEXUS_5X ||= Frameit::Device.new("nexus-5x", "Nexus 5X", 7, [[1080, 1920], [1920, 1080]], 423, nil, Platform::ANDROID)
    NEXUS_6P ||= Frameit::Device.new("nexus-6p", "Nexus 6P", 7, [[1440, 2560], [2560, 1440]], 518, nil, Platform::ANDROID)
    NEXUS_9 ||= Frameit::Device.new("nexus-9", "Nexus 9", 7, [[1536, 2048], [2048, 1536]], 281, nil, Platform::ANDROID)
    SAMSUNG_GALAXY_GRAND_PRIME ||= Frameit::Device.new("samsung-galaxy-grand-prime", "Samsung Galaxy Grand Prime", 5, [[540, 960], [960, 540]], 220, Color::BLACK, Platform::ANDROID)
    SAMSUNG_GALAXY_NOTE_5 ||= Frameit::Device.new("samsung-galaxy-note-5", "Samsung Galaxy Note 5", 5, [[1440, 2560], [2560, 1440]], 518, Color::BLACK, Platform::ANDROID)
    SAMSUNG_GALAXY_NOTE_10 ||= Frameit::Device.new("samsung-galaxy-note-10", "Samsung Galaxy Note 10", 6, [[1080, 2280], [2280, 1080]], 401, Color::AURA_BLACK, Platform::ANDROID)
    SAMSUNG_GALAXY_NOTE_10_PLUS ||= Frameit::Device.new("samsung-galaxy-note-10-plus", "Samsung Galaxy Note 10+", 7, [[1440, 3040], [3040, 1440]], 498, Color::AURA_BLACK, Platform::ANDROID)
    SAMSUNG_GALAXY_S_DUOS ||= Frameit::Device.new("samsung-galaxy-s-duos", "Samsung Galaxy S Duos", 3, [[480, 800], [800, 480]], 233, nil, Platform::ANDROID)
    SAMSUNG_GALAXY_S3 ||= Frameit::Device.new("samsung-galaxy-s3", "Samsung Galaxy S3", 3, [[720, 1280], [1280, 720]], 306, nil, Platform::ANDROID)
    SAMSUNG_GALAXY_S5 ||= Frameit::Device.new("samsung-galaxy-s5", "Samsung Galaxy S5", 3, [[1080, 1920], [1920, 1080]], 432, Color::BLACK, Platform::ANDROID)
    SAMSUNG_GALAXY_S7 ||= Frameit::Device.new("samsung-galaxy-s7", "Samsung Galaxy S7", 4, [[1440, 2560], [2560, 1440]], 577, Color::BLACK, Platform::ANDROID)
    SAMSUNG_GALAXY_S8 ||= Frameit::Device.new("samsung-galaxy-s8", "Samsung Galaxy S8", 5, [[1440, 2960], [2960, 1440]], 570, Color::MIDNIGHT_BLACK, Platform::ANDROID)
    SAMSUNG_GALAXY_S9 ||= Frameit::Device.new("samsung-galaxy-s9", "Samsung Galaxy S9", 6, [[1440, 2960], [2960, 1440]], 570, Color::MIDNIGHT_BLACK, Platform::ANDROID)
    SAMSUNG_GALAXY_S10 ||= Frameit::Device.new("samsung-galaxy-s10", "Samsung Galaxy S10", 7, [[1440, 3040], [3040, 1440]], 550, Color::PRISM_BLACK, Platform::ANDROID)
    SAMSUNG_GALAXY_S10_PLUS ||= Frameit::Device.new("samsung-galaxy-s10-plus", "Samsung Galaxy S10+", 8, [[1440, 3040], [3040, 1440]], 522, Color::PRISM_BLACK, Platform::ANDROID)
    XIAOMI_MI_MIX_ALPHA ||= Frameit::Device.new("xiaomi-mi-mix-alpha", "Xiaomi Mi Mix Alpha", 1, [[2088, 2250], [2250, 2088]], 388, nil, Platform::ANDROID)
    IPHONE_5S ||= Frameit::Device.new("iphone-5s", "Apple iPhone 5s", 2, [[640, 1096], [640, 1136], [1136, 600], [1136, 640]], 326, Color::SPACE_GRAY, Platform::IOS, Deliver::AppScreenshot::ScreenSize::IOS_40, :use_legacy_iphone5s)
    IPHONE_5C ||= Frameit::Device.new("iphone-5c", "Apple iPhone 5c", 2, [[640, 1136], [1136, 640]], 326, Color::WHITE)
    IPHONE_SE ||= Frameit::Device.new("iphone-se", "Apple iPhone SE", 3, [[640, 1096], [640, 1136], [1136, 600], [1136, 640]], 326, Color::SPACE_GRAY, Platform::IOS, Deliver::AppScreenshot::ScreenSize::IOS_40)
    IPHONE_6S ||= Frameit::Device.new("iphone-6s", "Apple iPhone 6s", 4, [[750, 1334], [1334, 750]], 326, Color::SPACE_GRAY, Platform::IOS, Deliver::AppScreenshot::ScreenSize::IOS_47, :use_legacy_iphone6s)
    IPHONE_6S_PLUS ||= Frameit::Device.new("iphone-6s-plus", "Apple iPhone 6s Plus", 4, [[1242, 2208], [2208, 1242]], 401, Color::SPACE_GRAY, Platform::IOS, Deliver::AppScreenshot::ScreenSize::IOS_55, :use_legacy_iphone6s)
    IPHONE_7 ||= Frameit::Device.new("iphone-7", "Apple iPhone 7", 5, [[750, 1334], [1334, 750]], 326, Color::MATTE_BLACK, Platform::IOS, Deliver::AppScreenshot::ScreenSize::IOS_47, :use_legacy_iphone7)
    IPHONE_7_PLUS ||= Frameit::Device.new("iphone-7-plus", "Apple iPhone 7 Plus", 5, [[1242, 2208], [2208, 1242]], 401, Color::MATTE_BLACK, Platform::IOS, Deliver::AppScreenshot::ScreenSize::IOS_55, :use_legacy_iphone7)
    IPHONE_8 ||= Frameit::Device.new("iphone-8", "Apple iPhone 8", 6, [[750, 1334], [1334, 750]], 326, Color::SPACE_GRAY)
    IPHONE_8_PLUS ||= Frameit::Device.new("iphone-8-plus", "Apple iPhone 8 Plus", 6, [[1242, 2208], [2208, 1242]], 401, Color::SPACE_GRAY)
    IPHONE_X ||= Frameit::Device.new("iphone-X", "Apple iPhone X", 7, [[1125, 2436], [2436, 1125]], 458, Color::SPACE_GRAY, Platform::IOS, Deliver::AppScreenshot::ScreenSize::IOS_58, :use_legacy_iphonex)
    IPHONE_XS ||= Frameit::Device.new("iphone-XS", "Apple iPhone XS", 8, [[1125, 2436], [2436, 1125]], 458, Color::SPACE_GRAY, Platform::IOS, Deliver::AppScreenshot::ScreenSize::IOS_58, :use_legacy_iphonexs)
    IPHONE_XR ||= Frameit::Device.new("iphone-XR", "Apple iPhone XR", 8, [[828, 1792], [1792, 828]], 326, Color::SPACE_GRAY, Platform::IOS, Deliver::AppScreenshot::ScreenSize::IOS_65, :use_legacy_iphonexsmax)
    IPHONE_XS_MAX ||= Frameit::Device.new("iphone-XS-Max", "Apple iPhone XS Max", 8, [[1242, 2688], [2688, 1242]], 458, Color::SPACE_GRAY, Platform::IOS, Deliver::AppScreenshot::ScreenSize::IOS_65, :use_legacy_iphonexsmax)
    IPHONE_11 ||= Frameit::Device.new("iphone-11", "Apple iPhone 11", 9, [[828, 1792], [1792, 828]], 326, Color::BLACK, Platform::IOS)
    IPHONE_11_PRO ||= Frameit::Device.new("iphone-11-pro", "Apple iPhone 11 Pro", 9, [[1125, 2436], [2436, 1125]], 458, Color::SPACE_GRAY, Platform::IOS)
    IPHONE_11_PRO_MAX ||= Frameit::Device.new("iphone11-pro-max", "Apple iPhone 11 Pro Max", 9, [[1242, 2688], [2688, 1242]], 458, Color::SPACE_GRAY, Platform::IOS)
    IPHONE_12 ||= Frameit::Device.new("iphone-12", "Apple iPhone 12", 10, [[1170, 2532], [2532, 1170]], 460, Color::BLACK, Platform::IOS)
    IPHONE_12_PRO ||= Frameit::Device.new("iphone-12-pro", "Apple iPhone 12 Pro", 10, [[1170, 2532], [2532, 1170]], 460, Color::SPACE_GRAY, Platform::IOS)
    IPHONE_12_PRO_MAX ||= Frameit::Device.new("iphone12-pro-max", "Apple iPhone 12 Pro Max", 10, [[1284, 2778], [2778, 1284]], 458, Color::GRAPHITE, Platform::IOS)
    IPHONE_12_MINI ||= Frameit::Device.new("iphone-12-mini", "Apple iPhone 12 Mini", 10, [[1125, 2436], [2436, 1125]], 476, Color::BLACK, Platform::IOS)
    IPHONE_13 ||= Frameit::Device.new("iphone-13", "Apple iPhone 13", 11, [[1170, 2532], [2532, 1170]], 460, Color::MIDNIGHT, Platform::IOS)
    IPHONE_13_PRO ||= Frameit::Device.new("iphone-13-pro", "Apple iPhone 13 Pro", 11, [[1170, 2532], [2532, 1170]], 460, Color::GRAPHITE, Platform::IOS)
    IPHONE_13_PRO_MAX ||= Frameit::Device.new("iphone13-pro-max", "Apple iPhone 13 Pro Max", 11, [[1284, 2778], [2778, 1284]], 458, Color::GRAPHITE, Platform::IOS)
    IPHONE_13_MINI ||= Frameit::Device.new("iphone-13-mini", "Apple iPhone 13 Mini", 11, [[1080, 2340], [2340, 1080]], 476, Color::MIDNIGHT, Platform::IOS)
    IPHONE_14 ||= Frameit::Device.new("iphone-14", "Apple iPhone 14", 12, [[1170, 2532], [2532, 1170]], 460, Color::MIDNIGHT, Platform::IOS)
    IPHONE_14_PLUS ||= Frameit::Device.new("iphone-14-plus", "Apple iPhone 14 Plus", 12, [[1284, 2778], [2778, 1284]], 458, Color::MIDNIGHT, Platform::IOS)
    IPHONE_14_PRO ||= Frameit::Device.new("iphone-14-pro", "Apple iPhone 14 Pro", 12, [[1178, 2556], [2556, 1178]], 460, Color::BLACK, Platform::IOS)
    IPHONE_14_PRO_MAX ||= Frameit::Device.new("iphone14-pro-max", "Apple iPhone 14 Pro Max", 12, [[1290, 2796], [2796, 1290]], 458, Color::BLACK, Platform::IOS)
    IPAD_10_2 ||= Frameit::Device.new("ipad-10-2", "Apple iPad 10.2", 1, [[1620, 2160], [2160, 1620]], 264, Color::SPACE_GRAY, Platform::IOS)
    IPAD_AIR_2 ||= Frameit::Device.new("ipad-air-2", "Apple iPad Air 2", 1, [[1536, 2048], [2048, 1536]], 264, Color::SPACE_GRAY, Platform::IOS, Deliver::AppScreenshot::ScreenSize::IOS_IPAD)
    IPAD_AIR_2019 ||= Frameit::Device.new("ipad-air-2019", "Apple iPad Air (2019)", 2, [[1668, 2224], [2224, 1668]], 265, Color::SPACE_GRAY, Platform::IOS)
    IPAD_MINI_4 ||= Frameit::Device.new("ipad-mini-4", "Apple iPad Mini 4", 2, [[1536, 2048], [2048, 1536]], 324, Color::SPACE_GRAY)
    IPAD_MINI_2019 ||= Frameit::Device.new("ipad-mini-2019", "Apple iPad Mini (2019)", 3, [[1536, 2048], [2048, 1536]], 324, Color::SPACE_GRAY)
    # this is 1st or 2nd gen of iPad Pro 12.9:
    IPAD_PRO ||= Frameit::Device.new("ipad-pro", "Apple iPad Pro", 3, [[2048, 2732], [2732, 2048]], 264, Color::SPACE_GRAY, Platform::IOS, Deliver::AppScreenshot::ScreenSize::IOS_IPAD_PRO)
    # 3rd generation:
    IPAD_PRO_12_9 ||= Frameit::Device.new("ipadPro129", "Apple iPad Pro (12.9-inch) (3rd generation)", 4, [[2048, 2732], [2732, 2048]], 264, Color::SPACE_GRAY, Platform::IOS, Deliver::AppScreenshot::ScreenSize::IOS_IPAD_PRO_12_9)
    # 4th generation:
    IPAD_PRO_12_9_4 ||= Frameit::Device.new("ipadPro129", "Apple iPad Pro (12.9-inch) (4th generation)", 5, [[2048, 2732], [2732, 2048]], 264, Color::SPACE_GRAY, Platform::IOS, Deliver::AppScreenshot::ScreenSize::IOS_IPAD_PRO_12_9)
    # iPad Pro (10.5-inch) is not in frameit-frames repo, but must be included so that we are backward compatible with PR #15373
    # priority must be lower so that users who didn't copy the frame to their frameit frames folder will not get an error
    # ID and formatted name must be exactly as specified so that device.detect_device() will select this device if the filename includes them
    IPAD_PRO_10_5 ||= Frameit::Device.new("ipad105", "Apple iPad Pro (10.5-inch)", 1, [[1668, 2224], [2224, 1668]], 265, Color::SPACE_GRAY, Platform::IOS, Deliver::AppScreenshot::ScreenSize::IOS_IPAD_10_5)
    IPAD_PRO_11 ||= Frameit::Device.new("ipadPro11", "Apple iPad Pro (11-inch)", 1, [[1668, 2388], [2388, 1668]], 265, Color::SPACE_GRAY, Platform::IOS, Deliver::AppScreenshot::ScreenSize::IOS_IPAD_11)

    MAC ||= Frameit::Device.new("mac", "Apple MacBook", 0, [[1280, 800], [1440, 900], [2560, 1600], [2880, 1800]], nil, Color::SPACE_GRAY, Platform::IOS, Deliver::AppScreenshot::ScreenSize::MAC)

    def self.all_device_names_without_apple
      Devices.constants.map { |c| Devices.const_get(c).formatted_name_without_apple }
    end
  end
end
