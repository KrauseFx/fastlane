require 'fastlane/erb_template_helper'

module Fastlane
  module Actions
    class MailgunAction < Action
      def self.is_supported?(platform)
        true
      end

      def self.run(options)
        Actions.verify_gem!('faraday')
        Actions.verify_gem!('mime-types')
        require 'faraday'
        begin
          # Use mime/types/columnar if available, for reduced memory usage
          require 'mime/types/columnar'
        rescue LoadError
          require 'mime/types'
        end
        handle_params_transition(options)
        mailgunit(options)
      end

      def self.description
        "Send a success/error message to an email group"
      end

      def self.available_options
        [
          # This is here just for while due to the transition, not needed anymore
          FastlaneCore::ConfigItem.new(key: :mailgun_sandbox_domain,
                                       env_name: "MAILGUN_SANDBOX_POSTMASTER",
                                       optional: true,
                                       description: "Mailgun sandbox domain postmaster for your mail. Please use postmaster instead"),
          # This is here just for while due to the transition, should use postmaster instead
          FastlaneCore::ConfigItem.new(key: :mailgun_sandbox_postmaster,
                                       env_name: "MAILGUN_SANDBOX_POSTMASTER",
                                       optional: true,
                                       description: "Mailgun sandbox domain postmaster for your mail. Please use postmaster instead"),
          # This is here just for while due to the transition, should use apikey instead
          FastlaneCore::ConfigItem.new(key: :mailgun_apikey,
                                       env_name: "MAILGUN_APIKEY",
                                       sensitive: true,
                                       optional: true,
                                       description: "Mailgun apikey for your mail. Please use postmaster instead"),

          FastlaneCore::ConfigItem.new(key: :postmaster,
                                       env_name: "MAILGUN_SANDBOX_POSTMASTER",
                                       description: "Mailgun sandbox domain postmaster for your mail"),
          FastlaneCore::ConfigItem.new(key: :apikey,
                                       env_name: "MAILGUN_APIKEY",
                                       sensitive: true,
                                       description: "Mailgun apikey for your mail"),
          FastlaneCore::ConfigItem.new(key: :to,
                                       env_name: "MAILGUN_TO",
                                       description: "Destination of your mail"),
          FastlaneCore::ConfigItem.new(key: :from,
                                       env_name: "MAILGUN_FROM",
                                       optional: true,
                                       description: "Mailgun sender name",
                                       default_value: "Mailgun Sandbox"),
          FastlaneCore::ConfigItem.new(key: :message,
                                       env_name: "MAILGUN_MESSAGE",
                                       description: "Message of your mail"),
          FastlaneCore::ConfigItem.new(key: :subject,
                                       env_name: "MAILGUN_SUBJECT",
                                       description: "Subject of your mail",
                                       optional: true,
                                       default_value: "fastlane build"),
          FastlaneCore::ConfigItem.new(key: :success,
                                       env_name: "MAILGUN_SUCCESS",
                                       description: "Was this build successful? (true/false)",
                                       optional: true,
                                       default_value: true,
                                       type: Boolean),
          FastlaneCore::ConfigItem.new(key: :app_link,
                                       env_name: "MAILGUN_APP_LINK",
                                       description: "App Release link",
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :ci_build_link,
                                       env_name: "MAILGUN_CI_BUILD_LINK",
                                       description: "CI Build Link",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :template_path,
                                       env_name: "MAILGUN_TEMPLATE_PATH",
                                       description: "Mail HTML template",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :reply_to,
                                       env_name: "MAILGUN_REPLY_TO",
                                       description: "Mail Reply to",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :attachment,
                                       env_name: "MAILGUN_ATTACHMENT",
                                       description: "Mail Attachment filenames, either an array or just one string",
                                       optional: true,
                                       type: Array),
          FastlaneCore::ConfigItem.new(key: :custom_placeholders,
                                       short_option: "-p",
                                       env_name: "MAILGUN_CUSTOM_PLACEHOLDERS",
                                       description: "Placeholders for template given as a hash",
                                       default_value: {},
                                       type: Hash)
        ]
      end

      def self.author
        "thiagolioy"
      end

      def self.handle_params_transition(options)
        if options[:mailgun_sandbox_postmaster] && !options[:postmaster]
          options[:postmaster] = options[:mailgun_sandbox_postmaster]
          puts("\nUsing :mailgun_sandbox_postmaster is deprecated, please change to :postmaster".yellow)
        end

        if options[:mailgun_apikey] && !options[:apikey]
          options[:apikey] = options[:mailgun_apikey]
          puts("\nUsing :mailgun_apikey is deprecated, please change to :apikey".yellow)
        end
      end

      def self.mailgunit(options)
        sandbox_domain = options[:postmaster].split("@").last
        params = {
          from: "#{options[:from]} <#{options[:postmaster]}>",
          to: (options[:to]).to_s,
          subject: options[:subject],
          html: mail_template(options)
        }
        unless options[:reply_to].nil?
          params.store(:"h:Reply-To", options[:reply_to])
        end

        unless options[:attachment].nil?
          attachment_filenames = [*options[:attachment]]
          attachments = attachment_filenames.map { |filename| Faraday::UploadIO.new(filename, mime_for(filename), filename) }
          params.store(:attachment, attachments)
        end

        conn = Faraday.new(url: "https://api:#{options[:apikey]}@api.mailgun.net") do |f|
          f.request(:multipart)
          f.request(:url_encoded)
          f.adapter(:net_http)
        end
        response = conn.post("/v3/#{sandbox_domain}/messages", params)
        UI.user_error!("Failed to send message via Mailgun, response: #{response.status}: #{response.body}.") if response.status != 200
        mail_template(options)
      end

      def self.mime_for(path)
        mime = MIME::Types.type_for(path)
        mime.empty? ? 'text/plain' : mime[0].content_type
      end

      def self.mail_template(options)
        hash = {
          author: Actions.git_author_email,
          last_commit: Actions.last_git_commit_message,
          message: options[:message],
          app_link: options[:app_link]
        }
        hash[:success] = options[:success]
        hash[:ci_build_link] = options[:ci_build_link]

        # concatenate with custom placeholders passed by user
        hash = hash.merge(options[:custom_placeholders])

        # grabs module
        eth = Fastlane::ErbTemplateHelper

        # create html from template
        html_template_path = options[:template_path]
        if html_template_path && File.exist?(html_template_path)
          html_template = eth.load_from_path(html_template_path)
        else
          html_template = eth.load("mailgun_html_template")
        end
        eth.render(html_template, hash)
      end

      def self.example_code
        [
          'mailgun(
            to: "fastlane@krausefx.com",
            success: true,
            message: "This is the mail\'s content"
          )',
          'mailgun(
            postmaster: "MY_POSTMASTER",
            apikey: "MY_API_KEY",
            to: "DESTINATION_EMAIL",
            from: "EMAIL_FROM_NAME",
            reply_to: "EMAIL_REPLY_TO",
            success: true,
            message: "Mail Body",
            app_link: "http://www.myapplink.com",
            ci_build_link: "http://www.mycibuildlink.com",
            template_path: "HTML_TEMPLATE_PATH",
            custom_placeholders: {
              :var1 => 123,
              :var2 => "string"
            },
            attachment: "dirname/filename.ext"
          )'
        ]
      end

      def self.category
        :notifications
      end
    end
  end
end
