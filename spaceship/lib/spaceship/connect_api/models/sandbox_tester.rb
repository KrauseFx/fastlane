require_relative '../model'
module Spaceship
  class ConnectAPI
    class SandboxTester
      include Spaceship::ConnectAPI::Model

      attr_accessor :first_name
      attr_accessor :last_name
      attr_accessor :email
      attr_accessor :password
      attr_accessor :confirm_password
      attr_accessor :secret_question
      attr_accessor :secret_answer
      attr_accessor :birth_date # 1980-03-01
      attr_accessor :app_store_territory
      attr_accessor :apple_pay_compatible

      attr_mapping({
        "firstName" => "first_name",
        "lastName" => "last_name",
        "email" => "email",
        "password" => "password",
        "confirmPassword" => "confirm_password",
        "secretQuestion" => "secret_question",
        "secretAnswer" => "secret_answer",
        "birthDate" => "birth_date",
        "appStoreTerritory" => "app_store_territory",
        "applePayCompatible" => "apple_pay_compatible"
      })

      def self.type
        return "sandboxTesters"
      end

      #
      # API
      #

      def self.all(client: nil, filter: {}, includes: nil, limit: 2000, sort: nil)
        client ||= Spaceship::ConnectAPI
        resps = client.get_sandbox_testers(filter: filter, includes: includes).all_pages
        return resps.flat_map(&:to_models)
      end

      def self.create(client: nil, first_name: nil, last_name: nil, email: nil, password: nil, confirm_password: nil, secret_question: nil, secret_answer: nil, birth_date: nil, app_store_territory: nil)
        client ||= Spaceship::ConnectAPI
        attributes = {
          firstName: first_name,
          lastName: last_name,
          email: email,
          password: password,
          confirmPassword: confirm_password,
          secretQuestion: secret_question,
          secretAnswer: secret_answer,
          birthDate: birth_date,
          appStoreTerritory: app_store_territory
        }
        return client.post_sandbox_tester(attributes: attributes).first
      end

      def delete!(client: nil)
        client ||= Spaceship::ConnectAPI
        client.delete_sandbox_tester(sandbox_tester_id: id)
      end

      def clear_purchase_history(client: nil)
        client ||= Spaceship::ConnectAPI
        client.clear_sandbox_tester_purchase_history(sandbox_tester_id: id)
      end
    end
  end
end
