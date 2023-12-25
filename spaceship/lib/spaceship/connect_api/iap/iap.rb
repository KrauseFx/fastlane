require 'spaceship/connect_api/iap/client'

module Spaceship
  class ConnectAPI
    module IAP
      module API
        def iap_request_client=(iap_request_client)
          @iap_request_client = iap_request_client
        end

        def iap_request_client
          return @iap_request_client if @iap_request_client
          raise TypeError, "You need to instantiate this module with iap_request_client"
        end

        #
        # inAppPurchases
        #

        def get_in_app_purchase(purchase_id:, includes: nil)
          params = iap_request_client.build_params(filter: nil, includes: includes, limit: nil, sort: nil)
          iap_request_client.get("https://api.appstoreconnect.apple.com/v2/inAppPurchases/#{purchase_id}", params)
        end

        def get_in_app_purchases(app_id:, filter: nil, includes: nil, limit: nil, sort: nil)
          params = iap_request_client.build_params(filter: filter, includes: includes, limit: limit, sort: sort)
          iap_request_client.get("apps/#{app_id}/inAppPurchasesV2", params)
        end

        def create_in_app_purchase(app_id:, name:, product_id:, in_app_purchase_type:, review_note: nil, family_sharable: nil, available_in_all_territories: nil)
          attributes = {
            name: name,
            productId: product_id,
            inAppPurchaseType: in_app_purchase_type
          }

          # Optional Params
          attributes[:availableInAllTerritories] = available_in_all_territories unless available_in_all_territories.nil?
          attributes[:familySharable] = family_sharable unless family_sharable.nil?
          attributes[:reviewNote] = review_note unless review_note.nil?

          params = {
            data: {
              type: 'inAppPurchases', # Hard coded value
              attributes: attributes,
              relationships: {
                app: {
                  data: {
                    id: app_id,
                    type: 'apps' # Hard coded value
                  }
                }
              }
            }
          }

          # This endpoint is on `v2`
          iap_request_client.post('https://api.appstoreconnect.apple.com/v2/inAppPurchases', params)
        end

        def update_in_app_purchase(purchase_id:, name: nil, review_note: nil, family_sharable: nil, available_in_all_territories: nil)
          attributes = {}

          # Optional attributes
          attributes[:name] = name unless name.nil?
          attributes[:reviewNote] = review_note unless review_note.nil?
          attributes[:familySharable] = family_sharable unless family_sharable.nil?
          attributes[:availableInAllTerritories] = available_in_all_territories unless available_in_all_territories.nil?

          params = {
            data: {
              id: purchase_id,
              type: 'inAppPurchases',
              attributes: attributes
            }
          }

          iap_request_client.patch("https://api.appstoreconnect.apple.com/v2/inAppPurchases/#{purchase_id}", params)
        end

        def submit_in_app_purchase(purchase_id:)
          params = {
            data: {
              type: 'inAppPurchaseSubmissions', # Hard coded value
              relationships: {
                inAppPurchaseV2: {
                  data: {
                    id: purchase_id,
                    type: 'inAppPurchases'
                  }
                }
              }
            }
          }

          iap_request_client.post("inAppPurchaseSubmissions", params)
        end

        #
        # inAppPurchaseLocalizations
        #

        def get_in_app_purchase_localizations(purchase_id:, includes: nil, limit: nil)
          params = iap_request_client.build_params(includes: includes, limit: limit)
          iap_request_client.get("https://api.appstoreconnect.apple.com/v2/inAppPurchases/#{purchase_id}/inAppPurchaseLocalizations", params)
        end

        def get_in_app_purchase_localization(localization_id:, includes: nil)
          params = iap_request_client.build_params(includes: includes)
          iap_request_client.get("inAppPurchaseLocalizations/#{localization_id}", params)
        end

        def create_in_app_purchase_localization(purchase_id:, locale:, name:, description: nil)
          attributes = {
            name: name,
            locale: locale
          }

          # Optional Attributes
          attributes[:description] = description unless description.nil?

          params = {
            data: {
              type: 'inAppPurchaseLocalizations',
              attributes: attributes,
              relationships: {
                inAppPurchaseV2: {
                  data: {
                    id: purchase_id,
                    type: 'inAppPurchases'
                  }
                }
              }
            }
          }

          iap_request_client.post('inAppPurchaseLocalizations', params)
        end

        def delete_in_app_purchase_localization(localization_id:)
          iap_request_client.delete("inAppPurchaseLocalizations/#{localization_id}")
        end

        #
        # inAppPurchasePricePoints
        #

        def get_in_app_purchase_price_points(purchase_id:, filter: nil, includes: nil, limit: nil)
          params = iap_request_client.build_params(filter: filter, includes: includes, limit: limit)
          iap_request_client.get("https://api.appstoreconnect.apple.com/v2/inAppPurchases/#{purchase_id}/pricePoints", params)
        end

        def get_in_app_purchase_price_schedules(purchase_id:, includes: nil, limit: nil, fields: nil)
          params = iap_request_client.build_params(includes: includes, limit: limit)
          params[:fields] = fields unless fields.nil?
          iap_request_client.get("inAppPurchasePriceSchedules/#{purchase_id}", params)
        end

        def get_in_app_purchase_prices(purchase_id:, filter: nil, includes: nil, limit: nil, fields: nil)
          params = iap_request_client.build_params(filter: filter, includes: includes, limit: limit)
          params[:fields] = fields unless fields.nil?
          iap_request_client.get("inAppPurchasePriceSchedules/#{purchase_id}/manualPrices", params)
        end

        def create_in_app_purchase_price_schedule(purchase_id:, in_app_purchase_price_point_id:, start_date: nil)
          params = {
            data: {
              type: 'inAppPurchasePriceSchedules',
              relationships: {
                inAppPurchase: {
                  data: {
                    id: purchase_id,
                    type: 'inAppPurchases'
                  }
                },

                manualPrices: {
                  data: [] # Filled with loop below
                }
              }
            },
            included: [] # Filled with loop below
          }

          entry_count = 1
          [in_app_purchase_price_point_id].each do |in_app_purchase_price_point_id|
            create_id = "${price#{entry_count}}"

            # Add to relationships
            params[:data][:relationships][:manualPrices][:data] << { id: create_id, type: 'inAppPurchasePrices' }

            # Add to included
            attributes = {}
            attributes[:startDate] = start_date unless start_date.nil? # Optional Attributes

            params[:included] << {
              id: create_id,
              type: 'inAppPurchasePrices',
              attributes: attributes,
              relationships: {
                inAppPurchaseV2: {
                  data: {
                    id: purchase_id,
                    type: 'inAppPurchases'
                  }
                },
                inAppPurchasePricePoint: {
                  data: {
                    id: in_app_purchase_price_point_id,
                    type: 'inAppPurchasePricePoints'
                  }
                }
              }
            }

            entry_count += 1
          end

          iap_request_client.post('inAppPurchasePriceSchedules', params)
        end

        #
        # inAppPurchaseAppStoreReviewScreenshots
        #

        def create_in_app_purchase_app_store_review_screenshot(purchase_id:, file_name:, file_size:)
          params = {
            data: {
              type: 'inAppPurchaseAppStoreReviewScreenshots',
              attributes: {
                fileName: file_name,
                fileSize: file_size
              },
              relationships: {
                inAppPurchaseV2: {
                  data: {
                    id: purchase_id,
                    type: 'inAppPurchases'
                  }
                }
              }
            }
          }

          iap_request_client.post('inAppPurchaseAppStoreReviewScreenshots', params)
        end

        def update_in_app_purchase_app_store_review_screenshot(screenshot_id:, source_file_checksum: nil, uploaded: nil)
          attributes = {}

          # Optional attributes
          attributes[:sourceFileChecksum] = source_file_checksum if source_file_checksum
          attributes[:uploaded] = uploaded if uploaded

          params = {
            data: {
              id: screenshot_id,
              type: 'inAppPurchaseAppStoreReviewScreenshots',
              attributes: attributes
            }
          }

          iap_request_client.patch("inAppPurchaseAppStoreReviewScreenshots/#{screenshot_id}", params)
        end

        def delete_in_app_purchase_app_store_review_screenshot(screenshot_id:)
          iap_request_client.delete("inAppPurchaseAppStoreReviewScreenshots/#{screenshot_id}")
        end

        def delete_in_app_purchase(purchase_id:)
          iap_request_client.delete("https://api.appstoreconnect.apple.com/v2/inAppPurchases/#{purchase_id}")
        end

        #
        # subscriptions
        #

        def get_subscription(purchase_id:, includes: nil)
          params = iap_request_client.build_params(filter: nil, includes: includes, limit: nil, sort: nil)
          iap_request_client.get("subscriptions/#{purchase_id}", params)
        end

        def get_subscriptions(family_id:, filter: nil, includes: nil, limit: nil, sort: nil)
          params = iap_request_client.build_params(filter: filter, includes: includes, limit: limit, sort: sort)
          iap_request_client.get("subscriptionGroups/#{family_id}/subscriptions", params)
        end

        def create_subscription(name:, product_id:, family_id:, available_in_all_territories: nil, family_sharable: nil, review_note: nil, subscription_period: nil, group_level: nil)
          attributes = {
            name: name,
            productId: product_id
          }

          # Optional Params
          attributes[:availableInAllTerritories] = available_in_all_territories unless available_in_all_territories.nil?
          attributes[:familySharable] = family_sharable unless family_sharable.nil?
          attributes[:reviewNote] = review_note unless review_note.nil?
          attributes[:subscriptionPeriod] = subscription_period unless subscription_period.nil?
          attributes[:groupLevel] = group_level unless group_level.nil?

          params = {
            data: {
              type: 'subscriptions', # Hard coded value
              attributes: attributes,
              relationships: {
                group: {
                  data: {
                    id: family_id,
                    type: 'subscriptionGroups' # Hard coded value
                  }
                }
              }
            }
          }

          iap_request_client.post('subscriptions', params)
        end

        def update_subscription(
              purchase_id:,
              name: nil,
              available_in_all_territories: nil,
              family_sharable: nil,
              review_note: nil,
              subscription_period: nil,
              group_level: nil
            )
          attributes = {}

          # Optional Params
          attributes[:name] = name unless name.nil?
          attributes[:availableInAllTerritories] = available_in_all_territories unless available_in_all_territories.nil?
          attributes[:familySharable] = family_sharable unless family_sharable.nil?
          attributes[:reviewNote] = review_note unless review_note.nil?
          attributes[:subscriptionPeriod] = subscription_period unless subscription_period.nil?
          attributes[:groupLevel] = group_level unless group_level.nil?

          params = {
            data: {
              id: purchase_id,
              type: 'subscriptions', # Hard coded value
              attributes: attributes
            }
          }

          iap_request_client.patch("subscriptions/#{purchase_id}", params)
        end

        def submit_subscription(purchase_id:)
          params = {
            data: {
              type: 'subscriptionSubmissions', # Hard coded value
              relationships: {
                subscription: {
                  data: {
                    id: purchase_id,
                    type: 'subscriptions'
                  }
                }
              }
            }
          }

          iap_request_client.post("subscriptionSubmissions", params)
        end

        def delete_subscription(purchase_id:)
          iap_request_client.delete("subscriptions/#{purchase_id}")
        end

        #
        # subscriptionGroups
        #

        def get_subscription_group(family_id:, includes: nil)
          params = iap_request_client.build_params(filter: nil, includes: includes, limit: nil, sort: nil)
          iap_request_client.get("subscriptionGroups/#{family_id}", params)
        end

        def get_subscription_groups(app_id:, filter: nil, includes: nil, limit: nil, sort: nil)
          params = iap_request_client.build_params(filter: filter, includes: includes, limit: limit, sort: sort)
          iap_request_client.get("apps/#{app_id}/subscriptionGroups", params)
        end

        def create_subscription_group(reference_name:, app_id:)
          params = {
            data: {
              type: 'subscriptionGroups', # Hard coded value
              attributes: {
                referenceName: reference_name
              },
              relationships: {
                app: {
                  data: {
                    id: app_id,
                    type: 'apps' # Hard coded value
                  }
                }
              },
            }
          }

          iap_request_client.post('subscriptionGroups', params)
        end

        def delete_subscription_group(family_id:)
          iap_request_client.delete("subscriptionGroups/#{family_id}")
        end

        #
        # subscriptionGroupLocalizations
        #

        def get_subscription_group_localization(localization_id:, includes: nil)
          params = iap_request_client.build_params(filter: nil, includes: includes, limit: nil, sort: nil)
          iap_request_client.get("subscriptionGroupLocalizations/#{localization_id}", params)
        end

        def get_subscription_group_localizations(family_id:, includes: nil, limit: nil)
          params = iap_request_client.build_params(filter: nil, includes: includes, limit: limit, sort: nil)
          iap_request_client.get("subscriptionGroups/#{family_id}/subscriptionGroupLocalizations", params)
        end

        def create_subscription_group_localization(custom_app_name:, locale:, name:, family_id:)
          params = {
            data: {
              type: 'subscriptionGroupLocalizations',
              attributes: {
                customAppName: custom_app_name,
                locale: locale,
                name: name
              },
              relationships: {
                subscriptionGroup: {
                  data: {
                    id: family_id,
                    type: 'subscriptionGroups'
                  }
                }
              }
            }
          }

          iap_request_client.post('subscriptionGroupLocalizations', params)
        end

        def update_subscription_group_localization(custom_app_name:, name:, localization_id:)
          params = {
            data: {
              id: localization_id,
              type: 'subscriptionGroupLocalizations',
              attributes: {
                customAppName: custom_app_name,
                name: name
              }
            }
          }

          iap_request_client.patch("subscriptionGroupLocalizations/#{localization_id}", params)
        end

        #
        # SubscriptionAvailability
        #

        def get_subscription_availabilities(purchase_id:, filter: nil, includes: nil, limit: nil)
          params = iap_request_client.build_params(filter: filter, includes: includes, limit: limit, sort: nil)
          iap_request_client.get("subscriptionAvailabilities/#{purchase_id}", params)
        end

        def create_subscription_availability(purchase_id:, available_in_new_territories:, available_territory_ids:)
          params = {
            data: {
              type: 'subscriptionAvailabilities',
              attributes: {
                availableInNewTerritories: available_in_new_territories
              },
              relationships: {
                subscription: {
                  data: {
                    id: purchase_id,
                    type: 'subscriptions'
                  }
                },
                availableTerritories: {
                  data: available_territory_ids.map do |id|
                    { id: id, type: 'territories' }
                  end
                }
              }
            }
          }

          iap_request_client.post('subscriptionAvailabilities', params)
        end

        #
        # subscriptionIntroductoryOffers
        #

        def get_subscription_introductory_offers(app_id:, filter: nil, includes: nil, limit: nil, sort: nil)
          params = iap_request_client.build_params(filter: filter, includes: includes, limit: limit, sort: sort)
          iap_request_client.get("subscriptions/#{app_id}/introductoryOffers", params)
        end

        def create_subscription_introductory_offer(purchase_id:, duration:, number_of_periods:, offer_mode:, start_date: nil, end_date: nil, territory_id: nil, subscription_price_point_id: nil)
          attributes = {
            duration: duration,
            numberOfPeriods: number_of_periods,
            offerMode: offer_mode
          }

          relationships = {
            subscription: {
              data: {
                id: purchase_id,
                type: 'subscriptions'
              }
            }
          }

          # Optional Relationships
          if territory_id
            relationships[:territory] = {
              data: {
                id: territory_id,
                type: 'territories'
              }
            }
          end

          if subscription_price_point_id
            relationships[:subscriptionPricePoint] = {
              data: {
                id: subscription_price_point_id,
                type: 'subscriptionPricePoints'
              }
            }
          end

          # Optional Attributes
          attributes[:startDate] = start_date unless start_date.nil?
          attributes[:endDate] = end_date unless end_date.nil?

          params = {
            data: {
              type: 'subscriptionIntroductoryOffers',
              attributes: attributes,
              relationships: relationships
            }
          }

          iap_request_client.post('subscriptionIntroductoryOffers', params)
        end

        def update_subscription_introductory_offer(introductory_offer_id:, end_date: nil)
          attributes = {}

          # Optional Attributes
          attributes[:endDate] = end_date unless end_date.nil?

          params = {
            data: {
              id: introductory_offer_id,
              type: 'subscriptionIntroductoryOffers',
              attributes: attributes
            }
          }

          iap_request_client.patch("subscriptionIntroductoryOffers/#{introductory_offer_id}", params)
        end

        def delete_subscription_introductory_offer(introductory_offer_id:)
          iap_request_client.delete("subscriptionIntroductoryOffers/#{introductory_offer_id}")
        end

        #
        # subscriptionPrices
        #

        def get_subscription_prices(app_id:, filter: nil, includes: nil, limit: nil, sort: nil)
          params = iap_request_client.build_params(filter: filter, includes: includes, limit: limit, sort: sort)
          iap_request_client.get("subscriptions/#{app_id}/prices", params)
        end

        def create_subscription_price(purchase_id:, price_point_id:, territory_id: nil, preserve_current_price: nil, start_date: nil)
          attributes = {}

          relationships = {
            subscription: {
              data: {
                id: purchase_id,
                type: 'subscriptions'
              }
            },
            subscriptionPricePoint: {
              data: {
                id: price_point_id,
                type: 'subscriptionPricePoints'
              }
            }
          }

          # Optional Relationships
          if territory_id
            relationships[:territory] = {
              data: {
                id: territory_id,
                type: 'territories'
              }
            }
          end

          # Optional Attributes
          attributes[:preserveCurrentPrice] = preserve_current_price unless preserve_current_price.nil?
          attributes[:startDate] = start_date unless start_date.nil?

          params = {
            data: {
              type: 'subscriptionPrices',
              attributes: attributes,
              relationships: relationships
            }
          }

          iap_request_client.post('subscriptionPrices', params)
        end

        def delete_subscription_price(subscription_price_id:)
          iap_request_client.delete("subscriptionPrices/#{subscription_price_id}")
        end

        #
        # subscriptionPricePoints
        #

        def get_subscription_price_points(purchase_id:, filter: nil, includes: nil, limit: nil)
          params = iap_request_client.build_params(filter: filter, includes: includes, limit: limit)
          iap_request_client.get("subscriptions/#{purchase_id}/pricePoints", params)
        end

        def get_subscription_price_point_equalizations(price_point_id:, filter: nil, includes: nil, limit: nil)
          params = iap_request_client.build_params(filter: filter, includes: includes, limit: limit)
          iap_request_client.get("subscriptionPricePoints/#{price_point_id}/equalizations", params)
        end

        #
        # subscriptionLocalizations
        #

        def get_subscription_localizations(purchase_id:, includes: nil, limit: nil)
          params = iap_request_client.build_params(includes: includes, limit: limit)
          iap_request_client.get("subscriptions/#{purchase_id}/subscriptionLocalizations", params)
        end

        def get_subscription_localization(localization_id:, includes: nil)
          params = iap_request_client.build_params(includes: includes)
          iap_request_client.get("subscriptionLocalizations/#{localization_id}", params)
        end

        def create_subscription_localization(purchase_id:, locale:, name:, description: nil)
          attributes = {
            name: name,
            locale: locale
          }

          # Optional Attributes
          attributes[:description] = description unless description.nil?

          params = {
            data: {
              type: 'subscriptionLocalizations',
              attributes: attributes,
              relationships: {
                subscription: {
                  data: {
                    id: purchase_id,
                    type: 'subscriptions'
                  }
                }
              }
            }
          }

          iap_request_client.post('subscriptionLocalizations', params)
        end

        def delete_subscription_localization(localization_id:)
          iap_request_client.delete("subscriptionLocalizations/#{localization_id}")
        end

        #
        # subscriptionAppStoreReviewScreenshots
        #

        def create_subscription_app_store_review_screenshot(purchase_id:, file_name:, file_size:)
          params = {
            data: {
              type: 'subscriptionAppStoreReviewScreenshots',
              attributes: {
                fileName: file_name,
                fileSize: file_size
              },
              relationships: {
                subscription: {
                  data: {
                    id: purchase_id,
                    type: 'subscriptions'
                  }
                }
              }
            }
          }

          iap_request_client.post('subscriptionAppStoreReviewScreenshots', params)
        end

        def update_subscription_app_store_review_screenshot(screenshot_id:, source_file_checksum: nil, uploaded: nil)
          attributes = {}

          # Optional attributes
          attributes[:sourceFileChecksum] = source_file_checksum if source_file_checksum
          attributes[:uploaded] = uploaded if uploaded

          params = {
            data: {
              id: screenshot_id,
              type: 'subscriptionAppStoreReviewScreenshots',
              attributes: attributes
            }
          }

          iap_request_client.patch("subscriptionAppStoreReviewScreenshots/#{screenshot_id}", params)
        end

        def delete_subscription_app_store_review_screenshot(screenshot_id:)
          iap_request_client.delete("subscriptionAppStoreReviewScreenshots/#{screenshot_id}")
        end

        # def patch_age_rating_declaration(age_rating_declaration_id: nil, attributes: nil)
        #   body = {
        #     data: {
        #       type: "ageRatingDeclarations",
        #       id: age_rating_declaration_id,
        #       attributes: attributes
        #     }
        #   }

        #   iap_request_client.patch("ageRatingDeclarations/#{age_rating_declaration_id}", body)
        # end

      end
    end
  end
end
