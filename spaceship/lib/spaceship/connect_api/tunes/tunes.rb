require 'spaceship/connect_api/tunes/client'

module Spaceship
  class ConnectAPI
    module Tunes
      module API
        module Version
          V1 = "v1"
          V2 = "v2"
          V3 = "v3"
        end

        def tunes_request_client=(tunes_request_client)
          @tunes_request_client = tunes_request_client
        end

        def tunes_request_client
          return @tunes_request_client if @tunes_request_client
          raise TypeError, "You need to instantiate this module with tunes_request_client"
        end

        #
        # ageRatingDeclarations
        #

        def get_age_rating_declaration(app_info_id: nil, app_store_version_id: nil)
          raise "Keyword 'app_store_version_id' is deprecated and 'app_info_id' is required" if app_store_version_id || app_info_id.nil?

          params = tunes_request_client.build_params(filter: nil, includes: nil, limit: nil, sort: nil)
          tunes_request_client.get("#{Version::V1}/appInfos/#{app_info_id}/ageRatingDeclaration", params)
        end

        def patch_age_rating_declaration(age_rating_declaration_id: nil, attributes: nil)
          body = {
            data: {
              type: "ageRatingDeclarations",
              id: age_rating_declaration_id,
              attributes: attributes
            }
          }

          tunes_request_client.patch("#{Version::V1}/ageRatingDeclarations/#{age_rating_declaration_id}", body)
        end

        #
        # app
        #

        def post_app(name: nil, version_string: nil, sku: nil, primary_locale: nil, bundle_id: nil, platforms: nil, company_name: nil)
          included = []
          included << {
            type: "appInfos",
            id: "${new-appInfo-id}",
            relationships: {
              appInfoLocalizations: {
                data: [
                  {
                    type: "appInfoLocalizations",
                    id: "${new-appInfoLocalization-id}"
                  }
                ]
              }
            }
          }
          included << {
            type: "appInfoLocalizations",
            id: "${new-appInfoLocalization-id}",
            attributes: {
              locale: primary_locale,
              name: name
            }
          }

          platforms.each do |platform|
            included << {
              type: "appStoreVersions",
              id: "${store-version-#{platform}}",
              attributes: {
                platform: platform,
                versionString: version_string
              },
              relationships: {
                appStoreVersionLocalizations: {
                  data: [
                    {
                      type: "appStoreVersionLocalizations",
                      id: "${new-#{platform}VersionLocalization-id}"
                    }
                  ]
                }
              }
            }

            included << {
              type: "appStoreVersionLocalizations",
              id: "${new-#{platform}VersionLocalization-id}",
              attributes: {
                locale: primary_locale
              }
            }
          end

          data_for_app_store_versions = platforms.map do |platform|
            {
              type: "appStoreVersions",
              id: "${store-version-#{platform}}"
            }
          end

          relationships = {
            appStoreVersions: {
              data: data_for_app_store_versions
            },
            appInfos: {
              data: [
                {
                  type: "appInfos",
                  id: "${new-appInfo-id}"
                }
              ]
            }
          }

          app_attributes = {
            sku: sku,
            primaryLocale: primary_locale,
            bundleId: bundle_id
          }
          app_attributes[:companyName] = company_name if company_name

          body = {
            data: {
              type: "apps",
              attributes: app_attributes,
              relationships: relationships
            },
            included: included
          }

          tunes_request_client.post("#{Version::V1}/apps", body)
        end

        # Updates app attributes, price tier, visibility in regions or countries.
        # Use territory_ids with allow_removing_from_sale to remove app from sale
        # @param territory_ids updates app visibility in regions or countries.
        #   Possible values:
        #   empty array will remove app from sale if allow_removing_from_sale is true,
        #   array with territory ids will set availability to territories with those ids,
        #   nil will leave app availability on AppStore as is
        # @param allow_removing_from_sale allows for removing app from sale when territory_ids is an empty array
        def patch_app(app_id: nil, attributes: {}, app_price_tier_id: nil, territory_ids: nil, allow_removing_from_sale: false)
          relationships = {}
          included = []

          # Price tier
          unless app_price_tier_id.nil?
            relationships[:prices] = {
              data: [
                {
                  type: "appPrices",
                  id: "${price1}"
                }
              ]
            }

            included << {
              type: "appPrices",
              id: "${price1}",
              relationships: {
                app: {
                  data: {
                    type: "apps",
                    id: app_id
                  }
                },
                priceTier: {
                  data: {
                    type: "appPriceTiers",
                    id: app_price_tier_id.to_s
                  }
                }
              }
            }
          end

          # Territories
          unless territory_ids.nil?
            territories_data = territory_ids.map do |id|
              { type: "territories", id: id }
            end
            if !territories_data.empty? || allow_removing_from_sale
              relationships[:availableTerritories] = {
                data: territories_data
              }
            end
          end

          # Data
          data = {
            type: "apps",
            id: app_id
          }
          data[:relationships] = relationships unless relationships.empty?

          if !attributes.nil? && !attributes.empty?
            data[:attributes] = attributes
          end

          # Body
          body = {
            data: data
          }
          body[:included] = included unless included.empty?

          tunes_request_client.patch("#{Version::V1}/apps/#{app_id}", body)
        end

        #
        # appDataUsage
        #

        def get_app_data_usages(app_id: nil, filter: {}, includes: nil, limit: nil, sort: nil)
          params = tunes_request_client.build_params(filter: filter, includes: includes, limit: limit, sort: sort)
          tunes_request_client.get("#{Version::V1}/apps/#{app_id}/dataUsages", params)
        end

        def post_app_data_usage(app_id:, app_data_usage_category_id: nil, app_data_usage_protection_id: nil, app_data_usage_purpose_id: nil)
          raise "app_id is required " if app_id.nil?

          relationships = {
            app: {
              data: {
                type: "apps",
                id: app_id
              }
            }
          }

          if app_data_usage_category_id
            relationships[:category] = {
              data: {
                type: "appDataUsageCategories",
                id: app_data_usage_category_id
              }
            }
          end

          if app_data_usage_protection_id
            relationships[:dataProtection] = {
              data: {
                type: "appDataUsageDataProtections",
                id: app_data_usage_protection_id
              }
            }
          end

          if app_data_usage_purpose_id
            relationships[:purpose] = {
              data: {
                type: "appDataUsagePurposes",
                id: app_data_usage_purpose_id
              }
            }
          end

          body = {
            data: {
              type: "appDataUsages",
              relationships: relationships
            }
          }

          tunes_request_client.post("#{Version::V1}/appDataUsages", body)
        end

        def delete_app_data_usage(app_data_usage_id: nil)
          tunes_request_client.delete("#{Version::V1}/appDataUsages/#{app_data_usage_id}")
        end

        #
        # appDataUsageCategory
        #

        def get_app_data_usage_categories(filter: {}, includes: nil, limit: nil, sort: nil)
          params = tunes_request_client.build_params(filter: filter, includes: includes, limit: limit, sort: sort)
          tunes_request_client.get("#{Version::V1}/appDataUsageCategories", params)
        end

        #
        # appDataUsagePurpose
        #

        def get_app_data_usage_purposes(filter: {}, includes: nil, limit: nil, sort: nil)
          params = tunes_request_client.build_params(filter: filter, includes: includes, limit: limit, sort: sort)
          tunes_request_client.get("#{Version::V1}/appDataUsagePurposes", params)
        end

        #
        # appDataUsagesPublishState
        #

        def get_app_data_usages_publish_state(app_id: nil)
          params = tunes_request_client.build_params(filter: nil, includes: nil, limit: nil, sort: nil)
          tunes_request_client.get("#{Version::V1}/apps/#{app_id}/dataUsagePublishState", params)
        end

        def patch_app_data_usages_publish_state(app_data_usages_publish_state_id: nil, published: nil)
          body = {
            data: {
              type: "appDataUsagesPublishState",
              id: app_data_usages_publish_state_id,
              attributes: {
                published: published
              }
            }
          }

          tunes_request_client.patch("#{Version::V1}/appDataUsagesPublishState/#{app_data_usages_publish_state_id}", body)
        end

        #
        # appPreview
        #

        def get_app_preview(app_preview_id: nil)
          params = tunes_request_client.build_params(filter: nil, includes: nil, limit: nil, sort: nil)
          tunes_request_client.get("#{Version::V1}/appPreviews/#{app_preview_id}", params)
        end

        def post_app_preview(app_preview_set_id: nil, attributes: {})
          body = {
            data: {
              type: "appPreviews",
              attributes: attributes,
              relationships: {
                appPreviewSet: {
                  data: {
                    type: "appPreviewSets",
                    id: app_preview_set_id
                  }
                }
              }
            }
          }

          tunes_request_client.post("#{Version::V1}/appPreviews", body)
        end

        def patch_app_preview(app_preview_id: nil, attributes: {})
          body = {
            data: {
              type: "appPreviews",
              id: app_preview_id,
              attributes: attributes
            }
          }

          tunes_request_client.patch("#{Version::V1}/appPreviews/#{app_preview_id}", body)
        end

        def delete_app_preview(app_preview_id: nil)
          params = tunes_request_client.build_params(filter: nil, includes: nil, limit: nil, sort: nil)
          tunes_request_client.delete("#{Version::V1}/appPreviews/#{app_preview_id}", params)
        end

        #
        # appPreviewSets
        #

        def get_app_preview_sets(filter: {}, includes: nil, limit: nil, sort: nil)
          params = tunes_request_client.build_params(filter: filter, includes: includes, limit: limit, sort: sort)
          tunes_request_client.get("#{Version::V1}/appPreviewSets", params)
        end

        def get_app_preview_set(app_preview_set_id: nil, filter: {}, includes: nil, limit: nil, sort: nil)
          params = tunes_request_client.build_params(filter: filter, includes: includes, limit: limit, sort: sort)
          tunes_request_client.get("#{Version::V1}/appPreviewSets/#{app_preview_set_id}", params)
        end

        def post_app_preview_set(app_store_version_localization_id: nil, attributes: {})
          body = {
            data: {
              type: "appPreviewSets",
              attributes: attributes,
              relationships: {
                appStoreVersionLocalization: {
                  data: {
                    type: "appStoreVersionLocalizations",
                    id: app_store_version_localization_id
                  }
                }
              }
            }
          }

          tunes_request_client.post("#{Version::V1}/appPreviewSets", body)
        end

        def delete_app_preview_set(app_preview_set_id: nil)
          params = tunes_request_client.build_params(filter: nil, includes: nil, limit: nil, sort: nil)
          tunes_request_client.delete("#{Version::V1}/appPreviewSets/#{app_preview_set_id}", params)
        end

        def patch_app_preview_set_previews(app_preview_set_id: nil, app_preview_ids: nil)
          app_preview_ids ||= []

          body = {
            data: app_preview_ids.map do |app_preview_id|
              {
                type: "appPreviews",
                id: app_preview_id
              }
            end
          }

          tunes_request_client.patch("#{Version::V1}/appPreviewSets/#{app_preview_set_id}/relationships/appPreviews", body)
        end

        #
        # appAvailabilities
        #

        def get_app_availabilities(app_id: nil, filter: nil, includes: nil, limit: nil, sort: nil)
          params = tunes_request_client.build_params(filter: nil, includes: includes, limit: limit, sort: nil)
          tunes_request_client.get("#{Version::V2}/appAvailabilities/#{app_id}", params)
        end

        #
        # availableTerritories
        #

        def get_available_territories(app_id: nil, filter: {}, includes: nil, limit: nil, sort: nil)
          params = tunes_request_client.build_params(filter: filter, includes: includes, limit: limit, sort: sort)
          tunes_request_client.get("#{Version::V1}/apps/#{app_id}/availableTerritories", params)
        end

        #
        # appPrices
        #

        def get_app_prices(app_id: nil, filter: {}, includes: nil, limit: nil, sort: nil)
          params = tunes_request_client.build_params(filter: filter, includes: includes, limit: limit, sort: sort)
          tunes_request_client.get("#{Version::V1}/appPrices", params)
        end

        def get_app_price(app_price_id: nil, filter: {}, includes: nil, limit: nil, sort: nil)
          params = tunes_request_client.build_params(filter: filter, includes: includes, limit: limit, sort: sort)
          tunes_request_client.get("#{Version::V1}/appPrices/#{app_price_id}", params)
        end

        #
        # appPricePoints
        #
        def get_app_price_points(filter: {}, includes: nil, limit: nil, sort: nil)
          params = tunes_request_client.build_params(filter: filter, includes: includes, limit: limit, sort: sort)
          tunes_request_client.get("#{Version::V1}/appPricePoints", params)
        end

        #
        # appReviewAttachments
        #

        def post_app_store_review_attachment(app_store_review_detail_id: nil, attributes: {})
          body = {
            data: {
              type: "appStoreReviewAttachments",
              attributes: attributes,
              relationships: {
                appStoreReviewDetail: {
                  data: {
                    type: "appStoreReviewDetails",
                    id: app_store_review_detail_id
                  }
                }
              }
            }
          }

          tunes_request_client.post("#{Version::V1}/appStoreReviewAttachments", body)
        end

        def patch_app_store_review_attachment(app_store_review_attachment_id: nil, attributes: {})
          body = {
            data: {
              type: "appStoreReviewAttachments",
              id: app_store_review_attachment_id,
              attributes: attributes
            }
          }

          tunes_request_client.patch("#{Version::V1}/appStoreReviewAttachments/#{app_store_review_attachment_id}", body)
        end

        def delete_app_store_review_attachment(app_store_review_attachment_id: nil)
          params = tunes_request_client.build_params(filter: nil, includes: nil, limit: nil, sort: nil)
          tunes_request_client.delete("#{Version::V1}/appStoreReviewAttachments/#{app_store_review_attachment_id}", params)
        end

        #
        # appScreenshotSets
        #

        def get_app_screenshot_sets(app_store_version_localization_id: nil, filter: {}, includes: nil, limit: nil, sort: nil)
          params = tunes_request_client.build_params(filter: filter, includes: includes, limit: limit, sort: sort)
          tunes_request_client.get("#{Version::V1}/appStoreVersionLocalizations/#{app_store_version_localization_id}/appScreenshotSets", params)
        end

        def get_app_screenshot_set(app_screenshot_set_id: nil, filter: {}, includes: nil, limit: nil, sort: nil)
          params = tunes_request_client.build_params(filter: filter, includes: includes, limit: limit, sort: sort)
          tunes_request_client.get("#{Version::V1}/appScreenshotSets/#{app_screenshot_set_id}", params)
        end

        def post_app_screenshot_set(app_store_version_localization_id: nil, attributes: {})
          body = {
            data: {
              type: "appScreenshotSets",
              attributes: attributes,
              relationships: {
                appStoreVersionLocalization: {
                  data: {
                    type: "appStoreVersionLocalizations",
                    id: app_store_version_localization_id
                  }
                }
              }
            }
          }

          tunes_request_client.post("#{Version::V1}/appScreenshotSets", body)
        end

        def patch_app_screenshot_set_screenshots(app_screenshot_set_id: nil, app_screenshot_ids: nil)
          app_screenshot_ids ||= []

          body = {
            data: app_screenshot_ids.map do |app_screenshot_id|
              {
                type: "appScreenshots",
                id: app_screenshot_id
              }
            end
          }

          tunes_request_client.patch("#{Version::V1}/appScreenshotSets/#{app_screenshot_set_id}/relationships/appScreenshots", body)
        end

        def delete_app_screenshot_set(app_screenshot_set_id: nil)
          params = tunes_request_client.build_params(filter: nil, includes: nil, limit: nil, sort: nil)
          tunes_request_client.delete("#{Version::V1}/appScreenshotSets/#{app_screenshot_set_id}", params)
        end

        #
        # appScreenshots
        #

        def get_app_screenshot(app_screenshot_id: nil)
          params = tunes_request_client.build_params(filter: nil, includes: nil, limit: nil, sort: nil)
          tunes_request_client.get("#{Version::V1}/appScreenshots/#{app_screenshot_id}", params)
        end

        def post_app_screenshot(app_screenshot_set_id: nil, attributes: {})
          body = {
            data: {
              type: "appScreenshots",
              attributes: attributes,
              relationships: {
                appScreenshotSet: {
                  data: {
                    type: "appScreenshotSets",
                    id: app_screenshot_set_id
                  }
                }
              }
            }
          }

          tunes_request_client.post("#{Version::V1}/appScreenshots", body, tries: 1)
        end

        def patch_app_screenshot(app_screenshot_id: nil, attributes: {})
          body = {
            data: {
              type: "appScreenshots",
              id: app_screenshot_id,
              attributes: attributes
            }
          }

          tunes_request_client.patch("#{Version::V1}/appScreenshots/#{app_screenshot_id}", body)
        end

        def delete_app_screenshot(app_screenshot_id: nil)
          params = tunes_request_client.build_params(filter: nil, includes: nil, limit: nil, sort: nil)
          tunes_request_client.delete("#{Version::V1}/appScreenshots/#{app_screenshot_id}", params)
        end

        #
        # appInfos
        #

        def get_app_infos(app_id: nil, filter: {}, includes: nil, limit: nil, sort: nil)
          params = tunes_request_client.build_params(filter: filter, includes: includes, limit: limit, sort: sort)
          tunes_request_client.get("#{Version::V1}/apps/#{app_id}/appInfos", params)
        end

        def patch_app_info(app_info_id: nil, attributes: {})
          attributes ||= {}

          data = {
            type: "appInfos",
            id: app_info_id
          }
          data[:attributes] = attributes unless attributes.empty?

          body = {
            data: data
          }

          tunes_request_client.patch("#{Version::V1}/appInfos/#{app_info_id}", body)
        end

        #
        # Adding the key will create/update (if value) or delete if nil
        # Not including a key will leave as is
        # category_id_map: {
        #   primary_category_id: "GAMES",
        #   primary_subcategory_one_id: "PUZZLE",
        #   primary_subcategory_two_id: "STRATEGY",
        #   secondary_category_id: nil,
        #   secondary_subcategory_one_id: nil,
        #   secondary_subcategory_two_id: nil
        # }
        #
        def patch_app_info_categories(app_info_id: nil, category_id_map: nil)
          category_id_map ||= {}
          primary_category_id = category_id_map[:primary_category_id]
          primary_subcategory_one_id = category_id_map[:primary_subcategory_one_id]
          primary_subcategory_two_id = category_id_map[:primary_subcategory_two_id]
          secondary_category_id = category_id_map[:secondary_category_id]
          secondary_subcategory_one_id = category_id_map[:secondary_subcategory_one_id]
          secondary_subcategory_two_id = category_id_map[:secondary_subcategory_two_id]

          relationships = {}

          # Only update if key is included (otherwise category will be removed)
          if category_id_map.include?(:primary_category_id)
            relationships[:primaryCategory] = {
              data: primary_category_id ? { type: "appCategories", id: primary_category_id } : nil
            }
          end

          # Only update if key is included (otherwise category will be removed)
          if category_id_map.include?(:primary_subcategory_one_id)
            relationships[:primarySubcategoryOne] = {
              data: primary_subcategory_one_id ? { type: "appCategories", id: primary_subcategory_one_id } : nil
            }
          end

          # Only update if key is included (otherwise category will be removed)
          if category_id_map.include?(:primary_subcategory_two_id)
            relationships[:primarySubcategoryTwo] = {
              data: primary_subcategory_two_id ? { type: "appCategories", id: primary_subcategory_two_id } : nil
            }
          end

          # Only update if key is included (otherwise category will be removed)
          if category_id_map.include?(:secondary_category_id)
            relationships[:secondaryCategory] = {
              data: secondary_category_id ? { type: "appCategories", id: secondary_category_id } : nil
            }
          end

          # Only update if key is included (otherwise category will be removed)
          if category_id_map.include?(:secondary_subcategory_one_id)
            relationships[:secondarySubcategoryOne] = {
              data: secondary_subcategory_one_id ? { type: "appCategories", id: secondary_subcategory_one_id } : nil
            }
          end

          # Only update if key is included (otherwise category will be removed)
          if category_id_map.include?(:secondary_subcategory_two_id)
            relationships[:secondarySubcategoryTwo] = {
              data: secondary_subcategory_two_id ? { type: "appCategories", id: secondary_subcategory_two_id } : nil
            }
          end

          data = {
            type: "appInfos",
            id: app_info_id
          }
          data[:relationships] = relationships unless relationships.empty?

          body = {
            data: data
          }

          tunes_request_client.patch("#{Version::V1}/appInfos/#{app_info_id}", body)
        end

        def delete_app_info(app_info_id: nil)
          params = tunes_request_client.build_params(filter: nil, includes: nil, limit: nil, sort: nil)
          tunes_request_client.delete("#{Version::V1}/appInfos/#{app_info_id}", params)
        end

        #
        # appInfoLocalizations
        #

        def get_app_info_localizations(app_info_id: nil, filter: {}, includes: nil, limit: nil, sort: nil)
          params = tunes_request_client.build_params(filter: filter, includes: includes, limit: limit, sort: sort)
          tunes_request_client.get("#{Version::V1}/appInfos/#{app_info_id}/appInfoLocalizations", params)
        end

        def post_app_info_localization(app_info_id: nil, attributes: {})
          body = {
            data: {
              type: "appInfoLocalizations",
              attributes: attributes,
              relationships: {
                appStoreVersion: {
                  data: {
                    type: "appStoreVersions",
                    id: app_info_id
                  }
                }
              }
            }
          }

          tunes_request_client.post("#{Version::V1}/appInfoLocalizations", body)
        end

        def patch_app_info_localization(app_info_localization_id: nil, attributes: {})
          body = {
            data: {
              type: "appInfoLocalizations",
              id: app_info_localization_id,
              attributes: attributes
            }
          }

          tunes_request_client.patch("#{Version::V1}/appInfoLocalizations/#{app_info_localization_id}", body)
        end

        #
        # appStoreReviewDetails
        #

        def get_app_store_review_detail(app_store_version_id: nil, filter: {}, includes: nil, limit: nil, sort: nil)
          params = tunes_request_client.build_params(filter: filter, includes: includes, limit: limit, sort: sort)
          tunes_request_client.get("#{Version::V1}/appStoreVersions/#{app_store_version_id}/appStoreReviewDetail", params)
        end

        def post_app_store_review_detail(app_store_version_id: nil, attributes: {})
          body = {
            data: {
              type: "appStoreReviewDetails",
              attributes: attributes,
              relationships: {
                appStoreVersion: {
                  data: {
                    type: "appStoreVersions",
                    id: app_store_version_id
                  }
                }
              }
            }
          }

          tunes_request_client.post("#{Version::V1}/appStoreReviewDetails", body)
        end

        def patch_app_store_review_detail(app_store_review_detail_id: nil, attributes: {})
          body = {
            data: {
              type: "appStoreReviewDetails",
              id: app_store_review_detail_id,
              attributes: attributes
            }
          }

          tunes_request_client.patch("#{Version::V1}/appStoreReviewDetails/#{app_store_review_detail_id}", body)
        end

        #
        # appStoreVersionLocalizations
        #

        def get_app_store_version_localizations(app_store_version_id: nil, filter: {}, includes: nil, limit: nil, sort: nil)
          params = tunes_request_client.build_params(filter: filter, includes: includes, limit: limit, sort: sort)
          tunes_request_client.get("#{Version::V1}/appStoreVersions/#{app_store_version_id}/appStoreVersionLocalizations", params)
        end

        def get_app_store_version_localization(app_store_version_localization_id: nil, filter: {}, includes: nil, limit: nil, sort: nil)
          params = tunes_request_client.build_params(filter: nil, includes: nil, limit: nil, sort: nil)
          tunes_request_client.get("#{Version::V1}/appStoreVersionLocalizations/#{app_store_version_localization_id}", params)
        end

        def post_app_store_version_localization(app_store_version_id: nil, attributes: {})
          body = {
            data: {
              type: "appStoreVersionLocalizations",
              attributes: attributes,
              relationships: {
                appStoreVersion: {
                  data: {
                    type: "appStoreVersions",
                    id: app_store_version_id
                  }
                }
              }
            }
          }

          tunes_request_client.post("#{Version::V1}/appStoreVersionLocalizations", body)
        end

        def patch_app_store_version_localization(app_store_version_localization_id: nil, attributes: {})
          body = {
            data: {
              type: "appStoreVersionLocalizations",
              id: app_store_version_localization_id,
              attributes: attributes
            }
          }

          tunes_request_client.patch("#{Version::V1}/appStoreVersionLocalizations/#{app_store_version_localization_id}", body)
        end

        def delete_app_store_version_localization(app_store_version_localization_id: nil)
          params = tunes_request_client.build_params(filter: nil, includes: nil, limit: nil, sort: nil)
          tunes_request_client.delete("#{Version::V1}/appStoreVersionLocalizations/#{app_store_version_localization_id}", params)
        end

        #
        # appStoreVersionPhasedReleases
        #

        def get_app_store_version_phased_release(app_store_version_id: nil)
          params = tunes_request_client.build_params(filter: nil, includes: nil, limit: nil, sort: nil)
          tunes_request_client.get("#{Version::V1}/appStoreVersions/#{app_store_version_id}/appStoreVersionPhasedRelease", params)
        end

        def post_app_store_version_phased_release(app_store_version_id: nil, attributes: {})
          body = {
            data: {
              type: "appStoreVersionPhasedReleases",
              attributes: attributes,
              relationships: {
                appStoreVersion: {
                  data: {
                    type: "appStoreVersions",
                    id: app_store_version_id
                  }
                }
              }
            }
          }

          tunes_request_client.post("#{Version::V1}/appStoreVersionPhasedReleases", body)
        end

        def patch_app_store_version_phased_release(app_store_version_phased_release_id: nil, attributes: {})
          body = {
            data: {
              type: "appStoreVersionPhasedReleases",
              attributes: attributes,
              id: app_store_version_phased_release_id
            }
          }

          tunes_request_client.patch("#{Version::V1}/appStoreVersionPhasedReleases/#{app_store_version_phased_release_id}", body)
        end

        def delete_app_store_version_phased_release(app_store_version_phased_release_id: nil)
          params = tunes_request_client.build_params(filter: nil, includes: nil, limit: nil, sort: nil)
          tunes_request_client.delete("#{Version::V1}/appStoreVersionPhasedReleases/#{app_store_version_phased_release_id}", params)
        end

        #
        # appStoreVersions
        #

        def get_app_store_versions(app_id: nil, filter: {}, includes: nil, limit: nil, sort: nil)
          params = tunes_request_client.build_params(filter: filter, includes: includes, limit: limit, sort: sort)
          tunes_request_client.get("#{Version::V1}/apps/#{app_id}/appStoreVersions", params)
        end

        def get_app_store_version(app_store_version_id: nil, includes: nil)
          params = tunes_request_client.build_params(filter: nil, includes: includes, limit: nil, sort: nil)
          tunes_request_client.get("#{Version::V1}/appStoreVersions/#{app_store_version_id}", params)
        end

        def post_app_store_version(app_id: nil, attributes: {})
          body = {
            data: {
              type: "appStoreVersions",
              attributes: attributes,
              relationships: {
                app: {
                  data: {
                    type: "apps",
                    id: app_id
                  }
                }
              }
            }
          }

          tunes_request_client.post("#{Version::V1}/appStoreVersions", body)
        end

        def patch_app_store_version(app_store_version_id: nil, attributes: {})
          body = {
            data: {
              type: "appStoreVersions",
              id: app_store_version_id,
              attributes: attributes
            }
          }

          tunes_request_client.patch("#{Version::V1}/appStoreVersions/#{app_store_version_id}", body)
        end

        def patch_app_store_version_with_build(app_store_version_id: nil, build_id: nil)
          data = nil
          if build_id
            data = {
              type: "builds",
              id: build_id
            }
          end

          body = {
            data: {
              type: "appStoreVersions",
              id: app_store_version_id,
              relationships: {
                build: {
                  data: data
                }
              }
            }
          }

          tunes_request_client.patch("#{Version::V1}/appStoreVersions/#{app_store_version_id}", body)
        end

        #
        # appStoreVersionPhasedReleases
        #

        def get_reset_ratings_request(app_store_version_id: nil)
          params = tunes_request_client.build_params(filter: nil, includes: nil, limit: nil, sort: nil)
          tunes_request_client.get("#{Version::V1}/appStoreVersions/#{app_store_version_id}/resetRatingsRequest", params)
        end

        def post_reset_ratings_request(app_store_version_id: nil)
          body = {
            data: {
              type: "resetRatingsRequests",
              relationships: {
                appStoreVersion: {
                  data: {
                    type: "appStoreVersions",
                    id: app_store_version_id
                  }
                }
              }
            }
          }

          tunes_request_client.post("#{Version::V1}/resetRatingsRequests", body)
        end

        def delete_reset_ratings_request(reset_ratings_request_id: nil)
          params = tunes_request_client.build_params(filter: nil, includes: nil, limit: nil, sort: nil)
          tunes_request_client.delete("#{Version::V1}/resetRatingsRequests/#{reset_ratings_request_id}", params)
        end

        #
        # appStoreVersionSubmissions
        #

        def get_app_store_version_submission(app_store_version_id: nil)
          params = tunes_request_client.build_params(filter: nil, includes: nil, limit: nil, sort: nil)
          tunes_request_client.get("#{Version::V1}/appStoreVersions/#{app_store_version_id}/appStoreVersionSubmission", params)
        end

        def post_app_store_version_submission(app_store_version_id: nil)
          body = {
            data: {
              type: "appStoreVersionSubmissions",
              relationships: {
                appStoreVersion: {
                  data: {
                    type: "appStoreVersions",
                    id: app_store_version_id
                  }
                }
              }
            }
          }

          tunes_request_client.post("#{Version::V1}/appStoreVersionSubmissions", body)
        end

        def delete_app_store_version_submission(app_store_version_submission_id: nil)
          params = tunes_request_client.build_params(filter: nil, includes: nil, limit: nil, sort: nil)
          tunes_request_client.delete("#{Version::V1}/appStoreVersionSubmissions/#{app_store_version_submission_id}", params)
        end

        #
        # appStoreVersionReleaseRequests
        #

        def post_app_store_version_release_request(app_store_version_id: nil)
          body = {
              data: {
                  type: "appStoreVersionReleaseRequests",
                  relationships: {
                      appStoreVersion: {
                          data: {
                              type: "appStoreVersions",
                              id: app_store_version_id
                          }
                      }
                  }
              }
          }

          tunes_request_client.post("#{Version::V1}/appStoreVersionReleaseRequests", body)
        end

        #
        # customAppUsers
        #

        def get_custom_app_users(app_id: nil, filter: nil, includes: nil, limit: nil, sort: nil)
          params = tunes_request_client.build_params(filter: filter, includes: includes, limit: limit, sort: sort)
          tunes_request_client.get("#{Version::V1}/apps/#{app_id}/customAppUsers", params)
        end

        def post_custom_app_user(app_id: nil, apple_id: nil)
          body = {
              data: {
                  type: "customAppUsers",
                  attributes: {
                    appleId: apple_id
                  },
                  relationships: {
                      app: {
                          data: {
                              type: "apps",
                              id: app_id
                          }
                      }
                  }
              }
          }

          tunes_request_client.post("#{Version::V1}/customAppUsers", body)
        end

        def delete_custom_app_user(custom_app_user_id: nil)
          params = tunes_request_client.build_params(filter: nil, includes: nil, limit: nil, sort: nil)
          tunes_request_client.delete("#{Version::V1}/customAppUsers/#{custom_app_user_id}", params)
        end

        #
        # customOrganizationUsers
        #

        def get_custom_app_organization(app_id: nil, filter: nil, includes: nil, limit: nil, sort: nil)
          params = tunes_request_client.build_params(filter: filter, includes: includes, limit: limit, sort: sort)
          tunes_request_client.get("#{Version::V1}/apps/#{app_id}/customAppOrganizations", params)
        end

        def post_custom_app_organization(app_id: nil, device_enrollment_program_id: nil, name: nil)
          body = {
              data: {
                  type: "customAppOrganizations",
                  attributes: {
                    deviceEnrollmentProgramId: device_enrollment_program_id,
                    name: name
                  },
                  relationships: {
                      app: {
                          data: {
                              type: "apps",
                              id: app_id
                          }
                      }
                  }
              }
          }

          tunes_request_client.post("#{Version::V1}/customAppOrganizations", body)
        end

        def delete_custom_app_organization(custom_app_organization_id: nil)
          params = tunes_request_client.build_params(filter: nil, includes: nil, limit: nil, sort: nil)
          tunes_request_client.delete("#{Version::V1}/customAppOrganizations/#{custom_app_organization_id}", params)
        end

        #
        # reviewSubmissions
        #

        def get_review_submissions(app_id:, filter: {}, includes: nil, limit: nil, sort: nil)
          params = tunes_request_client.build_params(filter: filter, includes: includes, limit: limit, sort: sort)
          tunes_request_client.get("#{Version::V1}/apps/#{app_id}/reviewSubmissions", params)
        end

        def get_review_submission(review_submission_id:, filter: {}, includes: nil, limit: nil, sort: nil)
          params = tunes_request_client.build_params(filter: filter, includes: includes, limit: limit, sort: sort)
          tunes_request_client.get("#{Version::V1}/reviewSubmissions/#{review_submission_id}", params)
        end

        def post_review_submission(app_id:, platform:)
          body = {
            data: {
              type: "reviewSubmissions",
              attributes: {
                platform: platform
              },
              relationships: {
                app: {
                  data: {
                    type: "apps",
                    id: app_id
                  }
                }
              }
            }
          }

          tunes_request_client.post("#{Version::V1}/reviewSubmissions", body)
        end

        def patch_review_submission(review_submission_id:, attributes: nil)
          body = {
            data: {
              type: "reviewSubmissions",
              id: review_submission_id,
              attributes: attributes,
            }
          }

          tunes_request_client.patch("#{Version::V1}/reviewSubmissions/#{review_submission_id}", body)
        end

        #
        # reviewSubmissionItems
        #

        def get_review_submission_items(review_submission_id:, filter: {}, includes: nil, limit: nil, sort: nil)
          params = tunes_request_client.build_params(filter: filter, includes: includes, limit: limit, sort: sort)
          tunes_request_client.get("#{Version::V1}/reviewSubmissions/#{review_submission_id}/items", params)
        end

        def post_review_submission_item(review_submission_id:, app_store_version_id: nil)
          body = {
            data: {
              type: "reviewSubmissionItems",
              relationships: {
                reviewSubmission: {
                  data: {
                    type: "reviewSubmissions",
                    id: review_submission_id
                  }
                }
              }
            }
          }

          unless app_store_version_id.nil?
            body[:data][:relationships][:appStoreVersion] = {
              data: {
                type: "appStoreVersions",
                id: app_store_version_id
              }
            }
          end

          tunes_request_client.post("#{Version::V1}/reviewSubmissionItems", body)
        end

        #
        # sandboxTesters
        #

        def get_sandbox_testers(filter: nil, includes: nil, limit: nil, sort: nil)
          params = tunes_request_client.build_params(filter: filter, includes: includes, limit: limit, sort: sort)
          tunes_request_client.get("#{Version::V1}/sandboxTesters", params)
        end

        def post_sandbox_tester(attributes: {})
          body = {
            data: {
              type: "sandboxTesters",
              attributes: attributes
            }
          }

          tunes_request_client.post("#{Version::V1}/sandboxTesters", body)
        end

        def delete_sandbox_tester(sandbox_tester_id: nil)
          params = tunes_request_client.build_params(filter: nil, includes: nil, limit: nil, sort: nil)
          tunes_request_client.delete("#{Version::V1}/sandboxTesters/#{sandbox_tester_id}", params)
        end

        #
        # territories
        #

        def get_territories(filter: {}, includes: nil, limit: nil, sort: nil)
          params = tunes_request_client.build_params(filter: filter, includes: includes, limit: limit, sort: sort)
          tunes_request_client.get("#{Version::V1}/territories", params)
        end

        #
        # resolutionCenter
        #
        # As of 2022-11-11:
        # This is not official available through the App Store Connect API using an API Key.
        # This is only works with Apple ID auth.
        #

        def get_resolution_center_threads(filter: {}, includes: nil)
          params = tunes_request_client.build_params(filter: filter, includes: includes)
          tunes_request_client.get("#{Version::V1}/resolutionCenterThreads", params)
        end

        def get_resolution_center_messages(thread_id:, filter: {}, includes: nil)
          params = tunes_request_client.build_params(filter: filter, includes: includes)
          tunes_request_client.get("#{Version::V1}/resolutionCenterThreads/#{thread_id}/resolutionCenterMessages", params)
        end

        def get_review_rejection(filter: {}, includes: nil)
          params = tunes_request_client.build_params(filter: filter, includes: includes)
          tunes_request_client.get("#{Version::V1}/reviewRejections", params)
        end
      end
    end
  end
end
