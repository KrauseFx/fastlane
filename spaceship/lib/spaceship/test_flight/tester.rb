module Spaceship::TestFlight
  class Tester < Base
    # @return (String) The identifier of this tester, provided by iTunes Connect
    # @example
    #   "60f858b4-60a8-428a-963a-f943a3d68d17"
    attr_accessor :tester_id

    # @return (String) The email of this tester
    # @example
    #   "tester@spaceship.com"
    attr_accessor :email

    attr_mapping(
      'id' => :tester_id,
      'email' => :email
    )

    # @return (Array) Returns all beta testers available for this account
    def self.all(app_id: nil)
      client.testers_for_app(app_id: app_id).map { |data| self.new(data) }
    end

    # @return (Spaceship::TestFlight::Tester) Returns the testers matching the parameter.
    # ITC searchs all fields, and is full text. The search results are the union of all words in the search text
    # @param text (String) (required): Value used to filter the tester, case insensitive
    def self.search(app_id: nil, text: nil)
      testers_matching_email = client.search_for_tester_in_app(app_id: app_id, text: text).map { |data| self.new(data) }
      testers_matching_email ||= []
      return testers_matching_email
    end

    def self.create_app_level_tester(app_id: nil, first_name: nil, last_name: nil, email: nil)
      client.create_app_level_tester(app_id: app_id,
                                 first_name: first_name,
                                  last_name: last_name,
                                      email: email)
    end

    def remove_from_app!(app_id: nil)
      client.delete_tester_from_app(app_id: app_id, tester_id: self.tester_id)
    end

    def resend_invite(app_id: nil)
      client.resend_invite_to_external_tester(app_id: app_id, tester_id: self.tester_id)
    end
  end
end
