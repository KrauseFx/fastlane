require 'precheck'

module Precheck
  class TestItemToCheck < ItemToCheck
    attr_accessor :data

    def initialize(data: nil, item_name: :a, friendly_name: "none", is_optional: false)
      @data = data
      super(item_name, friendly_name, is_optional)
    end

    def item_data
      return data
    end
  end

  class TestRule < Rule
    def self.key
      :test_rule
    end

    def self.env_name
      "TEST_RULE_ENV"
    end

    def self.friendly_name
      "This is a test only"
    end

    def self.description
      "test rule"
    end

    def handle_item?(item)
      item.kind_of?(TestItemToCheck) ? true : false
    end

    def supported_fields_symbol_set
      [:a, :b, :c].to_set
    end

    def rule_block
      return lambda { |item_data|
        if item_data == "fail"
          return RuleReturn.new(validation_state: VALIDATION_STATES[:failed], failure_data: "set failure")
        end

        if item_data == "success"
          return RuleReturn.new(validation_state: VALIDATION_STATES[:passed])
        end

        return RuleReturn.new(validation_state: VALIDATION_STATES[:failed], failure_data: "I was something else")
      }
    end
  end

  describe Precheck do
    describe Precheck::Rule do
      let(:rule) { TestRule.new }

      it "passes" do
        item = TestItemToCheck.new(data: "success")
        result = rule.check_item(item)
        expect(result.status).to eq(VALIDATION_STATES[:passed])
      end

      it "properly returns a RuleResult with failed_data" do
        item = TestItemToCheck.new(data: "fail")
        result = rule.check_item(item)
        expect(result.status).to eq(VALIDATION_STATES[:failed])
        expect(result.rule_return.failure_data).to eq("set failure")
      end

      it "skips items it is not explicitly support to handle via handle_item?" do
        # NOTE: TextItemToCheck not TestItemToCheck
        item = TextItemToCheck.new("nothing", :description, "description")
        result = rule.check_item(item)
        expect(result).to eq(nil)
      end

      it "skips item names not in supported_fields_symbol_set" do
        item = TestItemToCheck.new(data: "fail", item_name: :d)
        result = rule.check_item(item)
        expect(result).to eq(nil)
      end

      it "passes when items are set is_optional == true and they have nil content" do
        item = TestItemToCheck.new(data: nil, is_optional: true)
        result = rule.check_item(item)
        expect(result.status).to eq(VALIDATION_STATES[:passed])
      end

      it "passes when items are set is_optional == true and they have empty content" do
        item = TestItemToCheck.new(data: "", is_optional: true)
        result = rule.check_item(item)
        expect(result.status).to eq(VALIDATION_STATES[:passed])
      end

      it "includes fields from supported_fields_symbol_set" do
        item = TestItemToCheck.new(data: "success", item_name: :a)
        result = rule.check_item(item)
        expect(result.status).to eq(VALIDATION_STATES[:passed])

        item = TestItemToCheck.new(data: "success", item_name: :b)
        result = rule.check_item(item)
        expect(result.status).to eq(VALIDATION_STATES[:passed])

        item = TestItemToCheck.new(data: "success", item_name: :c)
        result = rule.check_item(item)
        expect(result.status).to eq(VALIDATION_STATES[:passed])
      end
    end
  end
end
