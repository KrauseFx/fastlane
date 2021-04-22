require_relative 'globals'

module Spaceship
  ##
  # Spaceship::Base is the superclass for models in Apple Developer Portal.
  # It's mainly responsible for mapping responses to objects.
  #
  # A class-level attribute `client` is used to maintain the spaceship which we
  # are using to talk to ADP.
  #
  # Example of creating a new ADP model:
  #
  #   class Widget < Spaceship::Base
  #     attr_accessor :id, :name, :foo_bar, :wiz_baz
  #     attr_mapping({
  #       'name' => :name,
  #       'fooBar' => :foo_bar,
  #       'wizBaz' => :wiz_baz
  #     })
  #   end
  #
  # When you want to instantiate a model pass in the parsed response: `Widget.new(widget_json)`
  class Base
    class DataHash
      include Enumerable

      def initialize(hash)
        @hash = hash || {}
      end

      def key?(key)
        @hash.key?(key)
      end

      def get(*keys)
        lookup(keys)
      end

      alias [] get

      def set(keys, value)
        raise "'keys' must be an array, got #{keys.class} instead" unless keys.kind_of?(Array)
        last = keys.pop
        ref = lookup(keys) || @hash
        ref[last] = value
      end

      def delete(key)
        @hash.delete(key)
      end

      def lookup(keys)
        head, *tail = *keys
        if tail.empty?
          @hash[head]
        else
          DataHash.new(@hash[head]).lookup(tail)
        end
      end

      def each(&block)
        @hash.each(&block)
      end

      def to_json(*a)
        h = @hash.dup
        h.delete(:application)
        h.to_json(*a)
      rescue JSON::GeneratorError => e
        puts("Failed to jsonify #{h} (#{a})") if Spaceship::Globals.verbose?
        raise e
      end

      def to_h
        @hash.dup
      end
    end

    class << self
      # @return (Array<Class>) The list of subclasses of this including nested subclasses
      attr_reader :subclasses

      # This is to list all the subclasses and it helps unit tests to clean up the cache of `client` in each class
      def inherited(subclass)
        super
        @subclasses ||= []
        @subclasses << subclass
      end

      attr_accessor :client

      ##
      # The client used to make requests.
      # @return (Spaceship::Client) Defaults to the singleton
      def client
        raise "`client` must be implemented in subclasses"
      end

      ##
      # Sets client and returns self for chaining.
      # @return (Spaceship::Base)
      # rubocop:disable Style/AccessorMethodName
      def set_client(client)
        self.client = client
        self
      end
      # rubocop:enable Style/AccessorMethodName

      ##
      # Binds attributes getters and setters to underlying data returned from the API.
      # Setting any properties will alter the `raw_data` hash.
      #
      # @return (Module) with the mapped getters and setters defined. Can be `include`, `extend`, or `prepend` into a class or object
      def mapping_module(attr_mapping)
        Module.new do
          attr_mapping.each do |source, dest|
            getter = dest.to_sym
            setter = "#{dest}=".to_sym

            define_method(getter) do
              raw_data.get(*source.split('.'))
            end

            define_method(setter) do |value|
              self.raw_data ||= DataHash.new({})
              raw_data.set(source.split('.'), value)
            end
          end
        end
      end

      ##
      # Defines the attribute mapping between the response from Apple and our model objects.
      # Keys are to match keys in the response and the values are to match attributes on the model.
      #
      # Example of using `attr_mapping`
      #
      #   class Widget < Spaceship::Base
      #     attr_accessor :id, :name, :foo_bar, :wiz_baz
      #     attr_mapping({
      #       'name' => :name,
      #       'fooBar' => :foo_bar,
      #       'wizBaz' => :wiz_baz
      #     })
      #   end
      def attr_mapping(attr_map = nil)
        if attr_map
          @attr_mapping = attr_map
          @attr_mapping.values.each do |method_name|
            getter = method_name.to_sym
            setter = "#{method_name}=".to_sym

            # Seems like the `public_instance_methods.include?` doesn't always work
            # More context https://github.com/fastlane/fastlane/issues/11481
            # That's why we have the `begin` `rescue` code here
            begin
              remove_method(getter) if public_instance_methods.include?(getter)
            rescue NameError
            end
            begin
              remove_method(setter) if public_instance_methods.include?(setter)
            rescue NameError
            end
          end
          include(mapping_module(@attr_mapping))
        else
          begin
            @attr_mapping ||= ancestors[1].attr_mapping
          rescue NoMethodError
          rescue NameError
          end
        end
        return @attr_mapping
      end

      ##
      # Call a method to return a subclass constant.
      #
      # If `method_sym` is an underscored name of a class,
      # return the class with the current client passed into it.
      # If the method does not match, NoMethodError is raised.
      #
      # Example:
      #
      #   Certificate.production_push
      #   #=> Certificate::ProductionPush
      #
      #   ProvisioningProfile.ad_hoc
      #   #=> ProvisioningProfile::AdHoc
      #
      #   ProvisioningProfile.some_other_method
      #   #=> NoMethodError: undefined method `some_other_method' for ProvisioningProfile
      def method_missing(method_sym, *args, &block)
        module_name = method_sym.to_s
        module_name.sub!(/^[a-z\d]/) { $&.upcase }
        module_name.gsub!(%r{(?:_|(/))([a-z\d])}) { $2.upcase }
        if const_defined?(module_name)
          klass = const_get(module_name)
          klass.set_client(@client)
        else
          super
        end
      end

      ##
      # The factory class-method. This should only be used or overridden in very specific use-cases
      #
      # The only time it makes sense to use or override this method is when we want a base class
      # to return a sub-class based on attributes.
      #
      # Here, we define the method to be the same as `Spaceship::Base.new(attrs)`, be it should
      # be used only by classes that override it.
      #
      # Example:
      #
      #   Certificate.factory(attrs)
      #   #=> #<PushCertificate ... >
      #
      def factory(attrs, existing_client = nil)
        self.new(attrs, existing_client)
      end
    end

    ##
    # @return (Spaceship::Client) The current spaceship client used by the model to make requests.
    attr_reader :client

    ##
    # @return (Hash/Array) Holds the raw data we got from Apple's
    #   server to use it later
    attr_accessor :raw_data

    ##
    # The initialize method accepts a parsed response from Apple and sets all
    # attributes that are defined by `attr_mapping`
    #
    # Do not override `initialize` in your own models.
    def initialize(attrs = {}, existing_client = nil)
      attrs.each do |key, val|
        self.send("#{key}=", val) if respond_to?("#{key}=")
      end
      self.raw_data = DataHash.new(attrs)
      @client = existing_client || self.class.client
      self.setup
    end

    # This method can be used by subclasses to do additional initialisation
    # using the `raw_data`
    def setup; end

    #####################################################
    # @!group Storing the `attr_accessor`
    #####################################################

    # From https://stackoverflow.com/questions/2487333/fastest-one-liner-way-to-list-attr-accessors-in-ruby
    # This will store a list of defined attr_accessors to easily access them when inspecting the values
    def self.attr_accessor(*vars)
      @attributes ||= []
      @attributes.concat(vars)
      super(*vars)
    end

    def self.attributes
      @attributes ||= []
      par = []

      par = (self.superclass.attributes || []) unless self == Base

      @attributes + par
    end

    def attributes
      self.class.attributes
    end

    #####################################################
    # @!group Inspect related code
    #####################################################

    def inspect
      # To avoid circular references, we keep track of the references
      # of all objects already inspected from the first call to inspect
      # in this call stack
      # We use a Thread local storage for multi-thread friendliness
      thread = Thread.current
      tree_root = thread[:inspected_objects].nil?
      thread[:inspected_objects] = Set.new if tree_root

      if thread[:inspected_objects].include?(self)
        # already inspected objects have a default value,
        # let's follow Ruby's convention for circular references
        value = "#<Object ...>"
      else
        thread[:inspected_objects].add(self)
        begin
          value = inspect_value
        ensure
          thread[:inspected_objects] = nil if tree_root
        end
      end

      "<#{self.class.name} \n#{value}>"
    end

    def inspect_value
      self.attributes.map do |k|
        v = self.send(k).inspect
        v = v.gsub("\n", "\n\t") # to align nested elements

        "\t#{k}=#{v}"
      end.join(", \n")
    end

    def to_s
      self.inspect
    end

    private :inspect_value
  end
end
