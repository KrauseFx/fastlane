module Spaceship
  module Tunes
    # Defines the different states of an in-app purchase
    #
    # As specified by Apple: https://developer.apple.com/library/content/documentation/LanguagesUtilities/Conceptual/iTunesConnectInAppPurchase_Guide/Chapters/WorkingWithYourProductsStatus.html
    module IAPStatus
      # IAP created, but missing screenshot/metadata
      MISSING_METADATA = "Missing Metadata"

      # You can edit the metadata, change screenshot and more. Need to submit.
      READY_TO_SUBMIT = "Ready to Submit"

      # Waiting for Apple's Review
      WAITING_FOR_REVIEW = "Waiting For Review"

      # Currently in Review
      IN_REVIEW = "In Review"

      # Approved (and currently available)
      APPROVED = "Approved"

      # Developer deleted
      DELETED = "Deleted"

      # In-app purchase rejected for whatever reason
      REJECTED = "Rejected"

      # Get the iap status matching based on a string (given by iTunes Connect)
      def self.get_from_string(text)
        mapping = {
          'missingMetadata' => MISSING_METADATA,
          'readyToSubmit' => READY_TO_SUBMIT,
          'waitingForReview' => WAITING_FOR_REVIEW,
          'inReview' => IN_REVIEW,
          'readyForSale' => APPROVED,
          'deleted' => DELETED,
          'rejected' => REJECTED
        }

        mapping.each do |k, v|
          return v if k == text
        end

        return nil
      end
    end
  end
end
