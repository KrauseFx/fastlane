require_relative 'abstract_text_match_rule'

module Precheck
  class CopyrightDateRule < AbstractTextMatchRule
    def self.key
      :copyright_date
    end

    def self.env_name
      "RULE_COPYRIGHT_DATE"
    end

    def self.friendly_name
      "No incorrect or missing copyright date"
    end

    def self.description
      "using a copyright date that is any different from this current year, or missing a date"
    end

    def pass_if_empty?
      return false
    end

    def supported_fields_symbol_set
      [:copyright].to_set
    end

    def word_search_type
      WORD_SEARCH_TYPES[:fail_on_exclusion]
    end

    def lowercased_words_to_look_for
      [DateTime.now.year.to_s]
    end
  end
end
