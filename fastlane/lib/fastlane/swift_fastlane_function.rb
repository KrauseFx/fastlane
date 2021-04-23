module Fastlane
  class SwiftFunction
    attr_accessor :function_name
    attr_accessor :function_description
    attr_accessor :function_details
    attr_accessor :return_type
    attr_accessor :return_value
    attr_accessor :sample_return_value
    attr_accessor :param_names
    attr_accessor :param_descriptions
    attr_accessor :param_default_values
    attr_accessor :param_optionality_values
    attr_accessor :param_type_overrides
    attr_accessor :param_is_strings
    attr_accessor :reserved_words
    attr_accessor :default_values_to_ignore

    def initialize(action_name: nil, action_description: nil, action_details: nil, keys: nil, key_descriptions: nil, key_default_values: nil, key_optionality_values: nil, key_type_overrides: nil, key_is_strings: nil, return_type: nil, return_value: nil, sample_return_value: nil)
      @function_name = action_name
      @function_description = action_description
      @function_details = action_details
      @param_names = keys
      @param_descriptions = key_descriptions
      @param_default_values = key_default_values
      @param_optionality_values = key_optionality_values
      @param_is_strings = key_is_strings
      @return_type = return_type
      @return_value = non_empty(string: return_value)
      @sample_return_value = non_empty(string: sample_return_value)
      @param_type_overrides = key_type_overrides

      # rubocop:disable Layout/LineLength
      # class instance?
      @reserved_words = %w[associativity break case catch class continue convenience default deinit didSet do else enum extension fallthrough false final for func guard if in infix init inout internal lazy let mutating nil operator override precedence private public repeat required return self static struct subscript super switch throws true try var weak where while willSet].to_set
      # rubocop:enable Layout/LineLength
    end

    def sanitize_reserved_word(word: nil)
      unless @reserved_words.include?(word)
        return word
      end
      return "`#{word}`"
    end

    def non_empty(string: nil)
      if string.nil? || string.to_s.empty?
        return nil
      else
        return string
      end
    end

    def return_declaration
      expected_type = swift_type_for_return_type
      unless expected_type.to_s.length > 0
        return ""
      end

      return " -> #{expected_type}"
    end

    def swift_type_for_return_type
      unless @return_type
        return ""
      end

      case @return_type
      when :string
        return "String"
      when :array_of_strings
        return "[String]"
      when :hash_of_strings
        return "[String : String]"
      when :hash
        return "[String : Any]"
      when :bool
        return "Bool"
      when :int
        return "Int"
      else
        return ""
      end
    end

    def camel_case_lower(string: nil)
      string.split('_').inject([]) { |buffer, e| buffer.push(buffer.empty? ? e : e.capitalize) }.join
    end

    def determine_type_from_override(type_override: nil, default_type: nil)
      if type_override == Array
        return "[String]"
      elsif type_override == Hash
        return "[String : Any]"
      elsif type_override == Integer
        return "Int"
      elsif type_override == Boolean
        return "Bool"
      elsif type_override == Float
        return "Float"
      elsif type_override == :string_callback
        # David Hart:
        # It doesn't make sense to add escaping annotations to optional closures because they aren't function types:
        # they are basically an enum (Optional) containing a function, the same way you would store a closure in any type:
        # it's implicitly escaping because it's owned by another type.
        return "((String) -> Void)?"
      else
        return default_type
      end
    end

    def override_default_value_if_not_correct_type(param_name: nil, param_type: nil, default_value: nil)
      return "[]" if param_type == "[String]" && default_value == ""
      return "nil" if param_type == "((String) -> Void)?"

      return default_value
    end

    def get_type(param: nil, default_value: nil, optional: nil, param_type_override: nil, is_string: true)
      require 'bigdecimal'
      unless param_type_override.nil?
        type = determine_type_from_override(type_override: param_type_override)
      end

      # defaulting type to Any if is_string is false so users are allowed to input all allowed types
      type ||= is_string ? "String" : "Any"

      optional_specifier = ""
      # if we are optional and don't have a default value, we'll need to use ?
      optional_specifier = "?" if (optional && default_value.nil?) && type != "((String) -> Void)?"

      # If we have a default value of true or false, we can infer it is a Bool
      if default_value.instance_of?(FalseClass)
        type = "Bool"
      elsif default_value.instance_of?(TrueClass)
        type = "Bool"
      elsif default_value.kind_of?(Array)
        type = "[String]"
      elsif default_value.kind_of?(Hash)
        type = "[String : Any]"
      # Although we can have a default value of Integer type, if param_type_override overridden that value, respect it.
      elsif default_value.kind_of?(Integer)
        if type == "Double" || type == "Float"
          begin
            # If we're not able to instantiate
            _ = BigDecimal(default_value)
          rescue
            # We set it as a Int
            type = "Int"
          end
        else
          type = "Int"
        end
      end
      return "#{type}#{optional_specifier}"
    end

    def parameters
      unless @param_names
        return ""
      end

      param_names_and_types = @param_names.zip(param_default_values, param_optionality_values, param_type_overrides, param_is_strings).map do |param, default_value, optional, param_type_override, is_string|
        type = get_type(param: param, default_value: default_value, optional: optional, param_type_override: param_type_override, is_string: is_string)

        unless default_value.nil?
          if type == "[String : Any]"
            # we can't handle default values for Hashes, yet
            # see method swift_default_implementations for similar behavior
            default_value = "[:]"
          elsif type != "Bool" && type != "[String]" && type != "Int" && type != "@escaping ((String) -> Void)" && type != "Float" && type != "Double"
            default_value = "\"#{default_value}\""
          elsif type == "Float" || type == "Double"
            require 'bigdecimal'
            default_value = BigDecimal(default_value).to_s
          end
        end

        # if we don't have a default value, but the param is optional, set a default value in Swift to be nil
        if optional && default_value.nil?
          default_value = "nil"
        end

        # sometimes we get to the point where we have a default value but its type is wrong
        # so we need to correct that because [String] = "" is not valid swift
        default_value = override_default_value_if_not_correct_type(param_type: type, param_name: param, default_value: default_value)

        param = camel_case_lower(string: param)
        param = sanitize_reserved_word(word: param)

        if default_value.nil?
          "#{param}: #{type}"
        else
          "#{param}: #{type} = #{default_value}"
        end
      end

      return param_names_and_types
    end
    # rubocop:enable Metrics/PerceivedComplexity

    def swift_code
      function_name = camel_case_lower(string: self.function_name)
      function_return_declaration = self.return_declaration
      discardable_result = function_return_declaration.length > 0 ? "@discardableResult " : ''

      # Calculate the necessary indent to line up parameter names on new lines
      # with the first parameter after the opening paren following the function name.
      # i.e.: @discardableResult func someFunctionName(firstParameter: T
      #                                                secondParameter: T)
      # This just creates a string with as many spaces are necessary given whether or not
      # the function has a 'discardableResult' annotation, the 'func' keyword, function name
      # and the opening paren.
      function_keyword_definition = 'public func '
      open_paren = '('
      closed_paren = ')'
      indent = ' ' * (discardable_result.length + function_name.length + function_keyword_definition.length + open_paren.length)
      params = self.parameters.join(",\n#{indent}")

      return "#{swift_documentation}#{discardable_result}#{function_keyword_definition}#{function_name}#{open_paren}#{params}#{closed_paren}#{function_return_declaration} {\n#{self.implementation}\n}\n"
    end

    def swift_documentation
      has_parameters = @param_names && @param_names.length > 0
      unless @function_description || @function_details || has_parameters
        return ''
      end

      description = " #{fix_documentation_indentation(string: @function_description)}" if @function_description
      details = " #{fix_documentation_indentation(string: @function_details)}" if @function_details
      separator = ''
      documentation_elements = [description, swift_parameter_documentation, swift_return_value_documentation, details].compact
      # Adds newlines between each documentation element.
      documentation = documentation_elements.flat_map { |element| [element, separator] }.tap(&:pop).join("\n")

      return "/**\n#{documentation}\n*/\n"
    end

    def swift_parameter_documentation
      unless @param_names && @param_names.length > 0
        return nil
      end

      names_and_descriptions = @param_names.zip(@param_descriptions)

      if @param_names.length == 1
        detail_strings = names_and_descriptions.map { |name, description| " - parameter #{camel_case_lower(string: name)}: #{description}" }
        return detail_strings.first
      else
        detail_strings = names_and_descriptions.map { |name, description| "   - #{camel_case_lower(string: name)}: #{description}" }
        return " - parameters:\n#{detail_strings.join("\n")}"
      end
    end

    def swift_return_value_documentation
      unless @return_value
        return nil
      end

      sample = ". Example: #{@sample_return_value}" if @sample_return_value

      return " - returns: #{return_value}#{sample}"
    end

    def fix_documentation_indentation(string: nil)
      indent = ' '
      string.gsub("\n", "\n#{indent}")
    end

    def build_argument_list
      unless @param_names
        return "[]" # return empty list for argument
      end

      argument_object_strings = @param_names.zip(param_type_overrides).map do |name, type_override|
        sanitized_name = camel_case_lower(string: name)
        sanitized_name = sanitize_reserved_word(word: sanitized_name)
        type_string = type_override == :string_callback ? ", type: .stringClosure" : nil

        "RubyCommand.Argument(name: \"#{name}\", value: #{sanitized_name}#{type_string})"
      end
      return argument_object_strings
    end

    def return_statement
      returned_object = "runner.executeCommand(command)"
      case @return_type
      when :array_of_strings
        returned_object = "parseArray(fromString: #{returned_object})"
      when :hash_of_strings
        returned_object = "parseDictionary(fromString: #{returned_object})"
      when :hash
        returned_object = "parseDictionary(fromString: #{returned_object})"
      when :bool
        returned_object = "parseBool(fromString: #{returned_object})"
      when :int
        returned_object = "parseInt(fromString: #{returned_object})"
      end

      expected_type = swift_type_for_return_type

      return_string = "_ = "
      if expected_type.length > 0
        return_string = "return "
      end
      return "#{return_string}#{returned_object}"
    end

    def implementation
      args = build_argument_list

      implm = "  let command = RubyCommand(commandID: \"\", methodName: \"#{@function_name}\", className: nil, args: ["
      # Get the indent of the first argument in the list to give each
      # subsequent argument it's own line with proper indenting
      indent = ' ' * implm.length
      implm += args.join(",\n#{indent}")
      implm += "])\n"
      return implm + "  #{return_statement}"
    end
  end

  class ToolSwiftFunction < SwiftFunction
    def protocol_name
      function_name = camel_case_lower(string: self.function_name)
      return function_name.capitalize + "fileProtocol"
    end

    def class_name
      function_name = camel_case_lower(string: self.function_name)
      return function_name.capitalize + "file"
    end

    def swift_vars
      unless @param_names
        return []
      end
      swift_vars = @param_names.zip(param_default_values, param_optionality_values, param_type_overrides, param_descriptions).map do |param, default_value, optional, param_type_override, param_description|
        type = get_type(param: param, default_value: default_value, optional: optional, param_type_override: param_type_override)

        param = camel_case_lower(string: param)
        param = sanitize_reserved_word(word: param)
        static_var_for_parameter_name = param

        if param_description
          documentation = "  /// #{param_description}\n"
        end

        "\n#{documentation}"\
        "  var #{static_var_for_parameter_name}: #{type} { get }"
      end

      return swift_vars
    end

    def swift_default_implementations
      unless @param_names
        return []
      end

      swift_implementations = @param_names.zip(param_default_values, param_optionality_values, param_type_overrides).map do |param, default_value, optional, param_type_override|
        type = get_type(param: param, default_value: default_value, optional: optional, param_type_override: param_type_override)
        param = camel_case_lower(string: param)
        param = sanitize_reserved_word(word: param)
        var_for_parameter_name = param

        unless default_value.nil?
          if type == "Bool" || type == "[String]" || type == "Int" || default_value.kind_of?(Array)
            default_value = default_value.to_s
          elsif default_value.kind_of?(Hash)
            # we can't handle default values for Hashes, yet
            # see method parameters for similar behavior
            default_value = "[:]"
          else
            default_value = "\"#{default_value}\""
          end
        end

        # if we don't have a default value, but the param is options, just set a default value to nil
        if optional && default_value.nil?
          default_value = "nil"
        end

        # if we don't have a default value still, we need to assign them based on type
        if type == "String"
          default_value ||= "\"\""
        end

        if type == "Bool"
          default_value ||= "false"
        end

        if type == "[String]"
          default_value ||= "[]"
        end

        if type == "[String : Any]"
          default_value ||= "[:]"
        end

        "  var #{var_for_parameter_name}: #{type} { return #{default_value} }"
      end

      return swift_implementations
    end

    def parameters
      unless @param_names
        return ""
      end

      param_names_and_types = @param_names.zip(param_default_values, param_optionality_values, param_type_overrides).map do |param, default_value, optional, param_type_override, is_string|
        type = get_type(param: param, default_value: default_value, optional: optional, param_type_override: param_type_override, is_string: is_string)

        param = camel_case_lower(string: param)
        param = sanitize_reserved_word(word: param)
        static_var_for_parameter_name = param

        "#{param}: #{type} = #{self.class_name.downcase}.#{static_var_for_parameter_name}"
      end

      return param_names_and_types
    end
  end
end
