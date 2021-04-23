describe FastlaneCore do
  describe FastlaneCore::Configuration do
    describe "Create a new Configuration Manager" do
      it "raises an error if no hash is given" do
        expect do
          FastlaneCore::Configuration.create([], "string")
        end.to raise_error("values parameter must be a hash")
      end

      it "raises an error if no array is given" do
        expect do
          FastlaneCore::Configuration.create("string", {})
        end.to raise_error("available_options parameter must be an array of ConfigItems but is String")
      end

      it "raises an error if array contains invalid elements" do
        expect do
          FastlaneCore::Configuration.create(["string"], {})
        end.to raise_error("available_options parameter must be an array of ConfigItems. Found String.")
      end

      it "raises an error if the option of a given value is not available" do
        expect do
          FastlaneCore::Configuration.create([], { cert_name: "value" })
        end.to raise_error("Could not find option 'cert_name' in the list of available options: ")
      end

      it "raises an error if a description ends with a ." do
        expect do
          FastlaneCore::Configuration.create([FastlaneCore::ConfigItem.new(
            key: :cert_name,
       env_name: "asdf",
    description: "Set the profile name."
          )], {})
        end.to raise_error("Do not let descriptions end with a '.', since it's used for user inputs as well for key :cert_name")
      end

      describe "config conflicts" do
        it "raises an error if a key was used twice" do
          expect do
            FastlaneCore::Configuration.create([FastlaneCore::ConfigItem.new(
              key: :cert_name,
         env_name: "asdf"
            ),
                                                FastlaneCore::ConfigItem.new(
                                                  key: :cert_name,
                                             env_name: "asdf"
                                                )], {})
          end.to raise_error("Multiple entries for configuration key 'cert_name' found!")
        end

        it "raises an error if a short_option was used twice" do
          conflicting_options = [
            FastlaneCore::ConfigItem.new(key: :foo,
                                         short_option: "-f",
                                         description: "foo"),
            FastlaneCore::ConfigItem.new(key: :bar,
                                         short_option: "-f",
                                         description: "bar")
          ]

          expect do
            FastlaneCore::Configuration.create(conflicting_options, {})
          end.to raise_error("Multiple entries for short_option '-f' found!")
        end

        it "raises an error for unresolved conflict between options" do
          conflicting_options = [
            FastlaneCore::ConfigItem.new(key: :foo,
                                         conflicting_options: [:bar, :oof]),
            FastlaneCore::ConfigItem.new(key: :bar),
            FastlaneCore::ConfigItem.new(key: :oof)
          ]

          values = {
              foo: "",
              bar: ""
          }

          expect do
            FastlaneCore::Configuration.create(conflicting_options, values)
          end.to raise_error("Unresolved conflict between options: 'foo' and 'bar'")
        end

        it "calls custom conflict handler when conflict happens between two options" do
          conflicting_options = [
            FastlaneCore::ConfigItem.new(key: :foo,
                                         conflicting_options: [:bar, :oof],
                                         conflict_block: proc do |value|
                                           UI.user_error!("You can't use option '#{value.key}' along with 'foo'")
                                         end),
            FastlaneCore::ConfigItem.new(key: :bar),
            FastlaneCore::ConfigItem.new(key: :oof,
                                         conflict_block: proc do |value|
                                           UI.user_error!("You can't use option '#{value.key}' along with 'oof'")
                                         end)
          ]

          values = {
              foo: "",
              bar: ""
          }

          expect do
            FastlaneCore::Configuration.create(conflicting_options, values)
          end.to raise_error("You can't use option 'bar' along with 'foo'")
        end
      end

      describe "data_type" do
        it "sets the data type correctly if `is_string` is not set but type is specified" do
          config_item = FastlaneCore::ConfigItem.new(key: :foo,
                                                     description: 'foo',
                                                     type: Array)

          expect(config_item.data_type).to eq(Array)
        end

        it "sets the data type correctly if `is_string` is set but the type is specified" do
          config_item = FastlaneCore::ConfigItem.new(key: :foo,
                                                     description: 'foo',
                                                     is_string: true,
                                                     type: Array)

          expect(config_item.data_type).to eq(Array)
        end

        it "sets the data type correctly if `is_string` is set but the type is not specified" do
          config_item = FastlaneCore::ConfigItem.new(key: :foo,
                                                     description: 'foo',
                                                     is_string: true)

          expect(config_item.data_type).to eq(String)
        end
      end

      describe "#sensitive flag" do
        before(:each) do
          allow(FastlaneCore::Helper).to receive(:test?).and_return(false)
          allow(FastlaneCore::UI).to receive(:interactive?).and_return(true)
          allow(FastlaneCore::Helper).to receive(:ci?).and_return(false)
        end

        it "should set the sensitive flag" do
          config_item = FastlaneCore::ConfigItem.new(key: :foo,
                                                     description: 'foo',
                                                     type: Array,
                                                     optional: true,
                                                     sensitive: true,
                                                     default_value: ['5', '4', '3', '2', '1'])
          expect(config_item.sensitive).to eq(true)
        end

        it "should ask using asterisks" do
          config_item = FastlaneCore::ConfigItem.new(key: :foo,
                                                     description: 'foo',
                                                     type: String,
                                                     is_string: true,
                                                     optional: false,
                                                     sensitive: true)
          config = FastlaneCore::Configuration.create([config_item], {})
          expect(FastlaneCore::UI).to receive(:password).and_return("password")
          expect(config[:foo]).to eq("password")
        end
        it "should ask using plaintext" do
          config_item = FastlaneCore::ConfigItem.new(key: :foo,
                                                     description: 'foo',
                                                     type: String,
                                                     is_string: false,
                                                     optional: false,
                                                     sensitive: false)
          config = FastlaneCore::Configuration.create([config_item], {})
          expect(FastlaneCore::UI).to receive(:input).and_return("plaintext")
          expect(config[:foo]).to eq("plaintext")
        end
      end

      describe "arrays" do
        it "returns Array default values correctly" do
          config_item = FastlaneCore::ConfigItem.new(key: :foo,
                                                     description: 'foo',
                                                     type: Array,
                                                     optional: true,
                                                     default_value: ['5', '4', '3', '2', '1'])
          config = FastlaneCore::Configuration.create([config_item], {})

          expect(config[:foo]).to eq(['5', '4', '3', '2', '1'])
        end

        it "returns Array input values correctly" do
          config_item = FastlaneCore::ConfigItem.new(key: :foo,
                                                     description: 'foo',
                                                     type: Array)
          config = FastlaneCore::Configuration.create([config_item], { foo: ['5', '4', '3', '2', '1'] })

          expect(config[:foo]).to eq(['5', '4', '3', '2', '1'])
        end

        it "returns Array environment variable values correctly" do
          ENV["FOO"] = '5,4,3,2,1'
          config_item = FastlaneCore::ConfigItem.new(key: :foo,
                                                     description: 'foo',
                                                     env_name: 'FOO',
                                                     type: Array)
          config = FastlaneCore::Configuration.create([config_item], {})

          expect(config[:foo]).to eq(['5', '4', '3', '2', '1'])
          ENV.delete("FOO")
        end
      end

      describe "auto_convert_value" do
        it "auto converts string values to Integers" do
          config_item = FastlaneCore::ConfigItem.new(key: :foo,
                                                     description: 'foo',
                                                     type: Integer)

          value = config_item.auto_convert_value('987')

          expect(value).to eq(987)
        end

        it "auto converts string values to Floats" do
          config_item = FastlaneCore::ConfigItem.new(key: :foo,
                                                     description: 'foo',
                                                     type: Float)

          value = config_item.auto_convert_value('9.91')

          expect(value).to eq(9.91)
        end

        it "auto converts Array values to Strings if allowed" do
          config_item = FastlaneCore::ConfigItem.new(key: :xcargs,
                                                     description: 'xcargs',
                                                     type: :shell_string)

          array = ['a b', 'c d', :e]
          value = config_item.auto_convert_value(array)

          expect(value).to eq(array.shelljoin)
        end

        it "auto converts Hash values to Strings if allowed" do
          config_item = FastlaneCore::ConfigItem.new(key: :xcargs,
                                                     description: 'xcargs',
                                                     type: :shell_string)

          hash = { 'FOO BAR' => 'I\'m foo bar', :BAZ => 'And I\'m baz' }
          value = config_item.auto_convert_value(hash)

          expected = 'FOO\\ BAR=I\\\'m\\ foo\\ bar BAZ=And\\ I\\\'m\\ baz'
          expected = "\"FOO BAR\"=\"I'm foo bar\" BAZ=\"And I'm baz\"" if FastlaneCore::Helper.windows?
          expect(value).to eq(expected)
        end

        it "does not auto convert Array values to Strings if not allowed" do
          config_item = FastlaneCore::ConfigItem.new(key: :xcargs,
                                                     description: 'xcargs',
                                                     type: String)

          array = ['a b', 'c d', :e]
          value = config_item.auto_convert_value(array)

          expect(value).to eq(array)
        end

        it "does not auto convert Hash values to Strings if not allowed" do
          config_item = FastlaneCore::ConfigItem.new(key: :xcargs,
                                                     description: 'xcargs',
                                                     type: String)

          hash = { 'FOO BAR' => 'I\'m foo bar', :BAZ => 'And I\'m baz' }
          value = config_item.auto_convert_value(hash)

          expect(value).to eq(hash)
        end

        it "auto converts nil to nil when type is not specified" do
          config_item = FastlaneCore::ConfigItem.new(key: :foo,
                                                     description: 'foo')

          value = config_item.auto_convert_value(nil)

          expect(value).to eq(nil)
        end

        it "auto converts nil to nil when type is Integer" do
          config_item = FastlaneCore::ConfigItem.new(key: :foo,
                                                     description: 'foo',
                                                     type: Integer)

          value = config_item.auto_convert_value(nil)

          expect(value).to eq(nil)
        end

        it "auto converts nil to nil when type is Float" do
          config_item = FastlaneCore::ConfigItem.new(key: :foo,
                                                     description: 'foo',
                                                     type: Float)

          value = config_item.auto_convert_value(nil)

          expect(value).to eq(nil)
        end

        it "auto converts booleans as strings to booleans" do
          c = [
            FastlaneCore::ConfigItem.new(key: :true_value, is_string: false),
            FastlaneCore::ConfigItem.new(key: :true_value2, is_string: false),
            FastlaneCore::ConfigItem.new(key: :false_value, is_string: false),
            FastlaneCore::ConfigItem.new(key: :false_value2, is_string: false)
          ]

          config = FastlaneCore::Configuration.create(c, {
            true_value: "true",
            true_value2: "YES",
            false_value: "false",
            false_value2: "NO"
          })

          expect(config[:true_value]).to eq(true)
          expect(config[:true_value2]).to eq(true)
          expect(config[:false_value]).to eq(false)
          expect(config[:false_value2]).to eq(false)
        end

        it "doesn't auto convert booleans as strings to booleans if type is explicitly set to String" do
          c = [
            FastlaneCore::ConfigItem.new(key: :true_value, type: String),
            FastlaneCore::ConfigItem.new(key: :true_value2, type: String),
            FastlaneCore::ConfigItem.new(key: :false_value, type: String),
            FastlaneCore::ConfigItem.new(key: :false_value2, type: String)
          ]

          config = FastlaneCore::Configuration.create(c, {
            true_value: "true",
            true_value2: "YES",
            false_value: "false",
            false_value2: "NO"
          })

          expect(config[:true_value]).to eq("true")
          expect(config[:true_value2]).to eq("YES")
          expect(config[:false_value]).to eq("false")
          expect(config[:false_value2]).to eq("NO")
        end

        it "auto converts strings to integers" do
          c = [
            FastlaneCore::ConfigItem.new(key: :int_value,
                                         type: Integer)
          ]
          config = FastlaneCore::Configuration.create(c, {
            int_value: "10"
          })

          expect(config[:int_value]).to eq(10)
        end

        it "auto converts '0' to the integer 0" do
          c = [
            FastlaneCore::ConfigItem.new(key: :int_value,
                                         type: Integer)
          ]
          config = FastlaneCore::Configuration.create(c, {
            int_value: "0"
          })

          expect(config[:int_value]).to eq(0)
        end
      end

      describe "validation" do
        it "raises an exception if the data type is not as expected" do
          config_item = FastlaneCore::ConfigItem.new(key: :foo,
                                                     description: 'foo',
                                                     type: Float)

          expect do
            config_item.valid?('ABC')
          end.to raise_error(FastlaneCore::Interface::FastlaneError, "'foo' value must be a Float! Found String instead.")
        end

        it "verifies the default value as well" do
          c = FastlaneCore::ConfigItem.new(key: :output,
                                    env_name: "SIGH_OUTPUT_PATH",
                                 description: "Directory in which the profile should be stored",
                               default_value: "notExistent",
                                verify_block: proc do |value|
                                  UI.user_error!("Could not find output directory '#{value}'")
                                end)
          expect do
            @config = FastlaneCore::Configuration.create([c], {})
          end.to raise_error("Invalid default value for output, doesn't match verify_block")
        end

        it "calls verify_block for non nil values" do
          c = FastlaneCore::ConfigItem.new(key: :param,
                                      env_name: "PARAM",
                                   description: "Description",
                                          type: Object,
                                  verify_block: proc do |value|
                                    UI.user_error!("'#{value}' is not valid!")
                                  end)
          [true, false, '', 'a string', ['an array'], {}, :hash].each do |value|
            expect do
              c.valid?(value)
            end.to raise_error("'#{value}' is not valid!")
          end
        end

        it "passes for nil values" do
          c = FastlaneCore::ConfigItem.new(key: :param,
                                      env_name: "param",
                                   description: "Description",
                                  verify_block: proc do |value|
                                    UI.user_error!("'#{value}' is not valid!")
                                  end)

          expect(c.valid?(nil)).to eq(true)
        end

        it "verifies type" do
          c = FastlaneCore::ConfigItem.new(key: :param,
                                      env_name: "param",
                                          type: Float,
                                   description: "Description")
          expect do
            c.valid?('a string')
          end.to raise_error("'param' value must be a Float! Found String instead.")
        end

        it "skips type verification" do
          c = FastlaneCore::ConfigItem.new(key: :param,
                                      env_name: "param",
                                          type: Float,
                          skip_type_validation: true,
                                   description: "Description")
          expect(c.valid?('a string')).to eq(true)
        end

        it "fails verification for a improper value set as an environment variable" do
          c = FastlaneCore::ConfigItem.new(key: :test_key,
                                    env_name: "TEST_KEY",
                                 description: "A test key",
                                verify_block: proc do |value|
                                  UI.user_error!("Invalid value") unless value.start_with?('a')
                                end)
          expect do
            @config = FastlaneCore::Configuration.create([c], {})
            ENV["TEST_KEY"] = "does_not_start_with_a"
            @config[:test_key]
          end.to raise_error("Invalid value")
        end

        it "passes verification for a proper value set as an environment variable" do
          c = FastlaneCore::ConfigItem.new(key: :test_key,
                                    env_name: "TEST_KEY",
                                 description: "A test key",
                                verify_block: proc do |value|
                                  UI.user_error!("Invalid value") unless value.start_with?('a')
                                end)
          @config = FastlaneCore::Configuration.create([c], {})
          ENV["TEST_KEY"] = "a_good_value"
          expect(@config[:test_key]).to eq('a_good_value')
        end
      end

      describe "deprecation", focus: true do
        it "deprecated message changes the description" do
          config_item = FastlaneCore::ConfigItem.new(key: :foo,
                                                     description: 'foo',
                                                     deprecated: 'replaced by bar')
          expect(config_item.description).to eq("**DEPRECATED!** replaced by bar - foo")
        end

        it "deprecated boolean changes the description" do
          config_item = FastlaneCore::ConfigItem.new(key: :foo,
                                                     description: 'foo. use bar instead',
                                                     deprecated: true)
          expect(config_item.description).to eq("**DEPRECATED!** foo. use bar instead")
        end

        it "deprecated messages replaces empty description" do
          config_item = FastlaneCore::ConfigItem.new(key: :foo,
                                                     deprecated: 'replaced by bar')
          expect(config_item.description).to eq("**DEPRECATED!** replaced by bar")
        end

        it "deprecated makes it optional" do
          config_item = FastlaneCore::ConfigItem.new(key: :foo,
                                                     description: 'foo',
                                                     deprecated: 'replaced by bar')
          expect(config_item.optional).to eq(true)
        end

        it "raises an exception if a deprecated option is not optional" do
          expect do
            config_item = FastlaneCore::ConfigItem.new(key: :foo,
                                                       description: 'foo',
                                                       optional: false,
                                                       deprecated: 'replaced by bar')
          end.to raise_error(FastlaneCore::Interface::FastlaneCrash, 'Deprecated option must be optional')
        end

        it "doesn't display a deprecation message when loading a config if a deprecated option doesn't have a value" do
          c = FastlaneCore::ConfigItem.new(key: :foo,
                                           description: 'foo',
                                           deprecated: 'replaced by bar')
          values = {
            foo: "something"
          }
          expect(FastlaneCore::UI).to receive(:deprecated).with("Using deprecated option: '--foo' (replaced by bar)")
          config = FastlaneCore::Configuration.create([c], values)
        end

        it "displays a deprecation message when loading a config if a deprecated option has a value" do
          c = FastlaneCore::ConfigItem.new(key: :foo,
                                           description: 'foo',
                                           deprecated: 'replaced by bar')

          expect(FastlaneCore::UI).not_to(receive(:deprecated))
          config = FastlaneCore::Configuration.create([c], {})
        end
      end

      describe "misc features" do
        it "makes it non optional by default" do
          c = FastlaneCore::ConfigItem.new(key: :test,
                                 default_value: '123')
          expect(c.optional).to eq(false)
        end

        it "supports options without 'env_name'" do
          c = FastlaneCore::ConfigItem.new(key: :test,
                                 default_value: '123')
          config = FastlaneCore::Configuration.create([c], {})
          expect(config.values[:test]).to eq('123')
        end

        it "takes the values from the environment if available" do
          c = FastlaneCore::ConfigItem.new(key: :test,
                                      env_name: "FL_TEST")
          config = FastlaneCore::Configuration.create([c], {})
          ENV["FL_TEST"] = "123value"
          expect(config.values[:test]).to eq('123value')
          ENV.delete("FL_TEST")
        end

        it "supports modifying the value after taken from the environment" do
          c = FastlaneCore::ConfigItem.new(key: :test,
                                      env_name: "FL_TEST")
          config = FastlaneCore::Configuration.create([c], {})
          ENV["FL_TEST"] = "123value"
          config.values[:test].gsub!("123", "456")
          expect(config.values[:test]).to eq('456value')
          ENV.delete("FL_TEST")
        end

        it "can push and pop configuration values" do
          name = FastlaneCore::ConfigItem.new(key: :name)
          platform = FastlaneCore::ConfigItem.new(key: :platform)
          other = FastlaneCore::ConfigItem.new(key: :other)

          config = FastlaneCore::Configuration.create([name, other, platform], {})
          config.set(:name, "name1")
          config.set(:other, "other")
          config.push_values!

          expect(config._values).to be_empty

          config.set(:name, "name2")
          config.set(:platform, "platform")
          config.pop_values!

          expect(config.fetch(:name)).to eq("name2")
          expect(config.fetch(:other)).to eq("other")
          expect(config.fetch(:platform)).to eq("platform")
        end

        it "does nothing if you pop values with nothing pushed" do
          name = FastlaneCore::ConfigItem.new(key: :name)
          platform = FastlaneCore::ConfigItem.new(key: :platform)
          other = FastlaneCore::ConfigItem.new(key: :other)

          config = FastlaneCore::Configuration.create([name, other, platform], {})
          config.set(:name, "name1")
          config.set(:other, "other")
          config.pop_values!

          expect(config.fetch(:name)).to eq("name1")
          expect(config.fetch(:other)).to eq("other")
        end
      end

      describe "Automatically removes the --verbose flag" do
        it "removes --verbose if not an available options (e.g. a tool)" do
          config = FastlaneCore::Configuration.create([], { verbose: true })
          expect(config.values).to eq({})
        end

        it "doesn't remove --verbose if it's a valid option" do
          options = [
            FastlaneCore::ConfigItem.new(key: :verbose,
                                   is_string: false)
          ]
          config = FastlaneCore::Configuration.create(options, { verbose: true })
          expect(config[:verbose]).to eq(true)
        end
      end

      describe "Use a valid Configuration Manager" do
        before do
          @options = [
            FastlaneCore::ConfigItem.new(key: :cert_name,
                                    env_name: "SIGH_PROVISIONING_PROFILE_NAME",
                                 description: "Set the profile name",
                               default_value: "production_default",
                                verify_block: nil),
            FastlaneCore::ConfigItem.new(key: :output,
                                    env_name: "SIGH_OUTPUT_PATH",
                                 description: "Directory in which the profile should be stored",
                               default_value: ".",
                                verify_block: proc do |value|
                                  UI.user_error!("Could not find output directory '#{value}'") unless File.exist?(value)
                                end),
            FastlaneCore::ConfigItem.new(key: :wait_processing_interval,
                                short_option: "-k",
                                    env_name: "PILOT_WAIT_PROCESSING_INTERVAL",
                                 description: "Interval in seconds to wait for App Store Connect processing",
                               default_value: 30,
                                        type: Integer,
                                verify_block: proc do |value|
                                  UI.user_error!("Please enter a valid positive number of seconds") unless value.to_i > 0
                                end)
          ]
          @values = {
            cert_name: "asdf",
            output: "..",
            wait_processing_interval: 10
          }
          @config = FastlaneCore::Configuration.create(@options, @values)
        end

        describe "#keys" do
          it "returns all available keys" do
            expect(@config.all_keys).to eq([:cert_name, :output, :wait_processing_interval])
          end
        end

        describe "#values" do
          it "returns the user values" do
            values = @config.values
            expect(values[:output]).to eq('..')
            expect(values[:cert_name]).to eq('asdf')
            expect(values[:wait_processing_interval]).to eq(10)
          end

          it "returns the default values" do
            @config = FastlaneCore::Configuration.create(@options, {}) # no user inputs
            values = @config.values
            expect(values[:cert_name]).to eq('production_default')
            expect(values[:output]).to eq('.')
            expect(values[:wait_processing_interval]).to eq(30)
          end
        end

        describe "fetch" do
          it "raises an error if a non symbol was given" do
            expect do
              @config.fetch(123)
            end.to raise_error("Key '123' must be a symbol. Example :app_id.")
          end

          it "raises an error if this option does not exist" do
            expect do
              @config[:asdfasdf]
            end.to raise_error("Could not find option 'asdfasdf' in the list of available options: cert_name, output, wait_processing_interval")
          end

          it "returns the value for the given key if given" do
            expect(@config.fetch(:cert_name)).to eq(@values[:cert_name])
          end

          it "returns the value for the given key if given using []" do
            expect(@config[:cert_name]).to eq(@values[:cert_name])
          end

          it "returns the default value if nothing else was given" do
            @config.set(:cert_name, nil)
            expect(@config[:cert_name]).to eq("production_default")
          end

          describe "auto converting the value after asking the user for one" do
            before(:each) do
              allow(FastlaneCore::Helper).to receive(:test?).and_return(false)
              allow(FastlaneCore::UI).to receive(:interactive?).and_return(true)
              allow(FastlaneCore::Helper).to receive(:ci?).and_return(false)
            end

            it "doesn't show an error and converts the value if the input matches the item type" do
              config_item = FastlaneCore::ConfigItem.new(key: :item,
                                                         short_option: "-i",
                                                         env_name: "ITEM_ENV_VAR",
                                                         description: "a description",
                                                         is_string: false,
                                                         type: Integer,
                                                         # false is the default, but let's be explicit
                                                         skip_type_validation: false)
              config = FastlaneCore::Configuration.create([config_item], {})

              config.set(:item, nil)
              expect(FastlaneCore::UI).to receive(:input).once.and_return("123")
              expect(FastlaneCore::UI).not_to(receive(:error))
              expect(config[:item].class).to eq(Integer)
              expect(config[:item]).to eq(123)
            end

            it "shows an error after user inputs value that doesn't match type (the first time) and works the second time" do
              config_item = FastlaneCore::ConfigItem.new(key: :item,
                                                         short_option: "-i",
                                                         env_name: "ITEM_ENV_VAR",
                                                         description: "a description",
                                                         is_string: false,
                                                         type: Integer,
                                                         # false is the default, but let's be explicit
                                                         skip_type_validation: false)
              config = FastlaneCore::Configuration.create([config_item], {})

              config.set(:item, nil)
              expect(FastlaneCore::UI).to receive(:input).once.and_return("123abc")
              expect(FastlaneCore::UI).to receive(:input).once.and_return("123")
              expect(FastlaneCore::UI).to(receive(:error)).once
              expect(config[:item].class).to eq(Integer)
              expect(config[:item]).to eq(123)
            end

            it "doesn't show an error when skipping type validation" do
              # Taken from match/options.rb
              config_item = FastlaneCore::ConfigItem.new(key: :app_identifiers,
                                                         short_option: "-a",
                                                         env_name: "MATCH_APP_IDENTIFIER",
                                                         description: "The bundle identifier(s) of your app (comma-separated)",
                                                         is_string: false,
                                                         type: Array, # we actually allow String and Array here
                                                         skip_type_validation: true,
                                                         code_gen_sensitive: true,
                                                         default_value: CredentialsManager::AppfileConfig.try_fetch_value(:app_identifier),
                                                         default_value_dynamic: true)
              config = FastlaneCore::Configuration.create([config_item], {})

              config.set(:app_identifiers, nil)
              expect(FastlaneCore::UI).to receive(:input).once.and_return("app.identifier")
              expect(FastlaneCore::UI).not_to(receive(:error))
              expect(config[:app_identifiers].class).to eq(Array)
              expect(config[:app_identifiers]).to eq(["app.identifier"])
            end
          end
        end

        describe "verify_block" do
          it "throws an error if the key doesn't exist" do
            expect do
              @config.set(:non_existing, "value")
            end.to raise_error("Could not find option 'non_existing' in the list of available options: cert_name, output, wait_processing_interval")
          end

          it "throws an error if it's invalid" do
            expect do
              @config.set(:output, 132)
            end.to raise_error("'output' value must be a String! Found #{123.class} instead.")
            expect do
              @config.set(:wait_processing_interval, -1)
            end.to raise_error("Please enter a valid positive number of seconds")
          end

          it "allows valid updates" do
            new_val = "../../"
            expect(@config.set(:output, new_val)).to eq(true)
            expect(@config[:output]).to eq(new_val)
          end
        end

        describe "Parameter priority order" do
          it "prioritizes CLI values over everything else" do
            ENV["abc"] = "val env"
            config_item = FastlaneCore::ConfigItem.new(key: :item, env_name: "abc", default_value: "val default")
            config = FastlaneCore::Configuration.create([config_item], { item: "val cli" })
            config.config_file_options = { item: "val config" }

            expect(config[:item]).to eq("val cli")
            ENV.delete("abc")
          end

          it "prioritizes env_name after CLI" do
            ENV["abc"] = "val env"
            config_item = FastlaneCore::ConfigItem.new(key: :item, env_name: "abc", default_value: "val default")
            config = FastlaneCore::Configuration.create([config_item], {})
            config.config_file_options = { item: "val config" }

            expect(config[:item]).to eq("val env")
            ENV.delete("abc")
          end

          it "prioritizes env_names after CLI" do
            ENV["abc"] = "val env"
            config_item = FastlaneCore::ConfigItem.new(key: :item, env_names: ["abc"], default_value: "val default")
            config = FastlaneCore::Configuration.create([config_item], {})
            config.config_file_options = { item: "val config" }

            expect(config[:item]).to eq("val env")
            ENV.delete("abc")
          end

          it "prioritizes env_names after env_name" do
            ENV["abc"] = "val env"
            ENV["def"] = "val env wrong"
            config_item = FastlaneCore::ConfigItem.new(key: :item, env_name: "abc", env_names: ["def"], default_value: "val default")
            config = FastlaneCore::Configuration.create([config_item], {})
            config.config_file_options = { item: "val config" }

            expect(config[:item]).to eq("val env")
            ENV.delete("abc")
            ENV.delete("def")
          end

          it "prioritizes config file values after env_name" do
            config_item = FastlaneCore::ConfigItem.new(key: :item, env_name: "abc", default_value: "val default")
            config = FastlaneCore::Configuration.create([config_item], {})
            config.config_file_options = { item: "val config" }

            expect(config[:item]).to eq("val config")
          end

          it "prioritizes config file values after env_names" do
            config_item = FastlaneCore::ConfigItem.new(key: :item, env_names: ["abc"], default_value: "val default")
            config = FastlaneCore::Configuration.create([config_item], {})
            config.config_file_options = { item: "val config" }

            expect(config[:item]).to eq("val config")
          end

          it "prioritizes default values last" do
            config_item = FastlaneCore::ConfigItem.new(key: :item, env_name: "abc", default_value: "val default")
            config = FastlaneCore::Configuration.create([config_item], {})

            expect(config[:item]).to eq("val default")
          end

          it "asks if no other option" do
            allow(FastlaneCore::Helper).to receive(:test?).and_return(false)
            allow(FastlaneCore::UI).to receive(:interactive?).and_return(true)
            allow(FastlaneCore::Helper).to receive(:ci?).and_return(false)

            config_item = FastlaneCore::ConfigItem.new(key: :item, env_name: "abc", optional: false)
            config = FastlaneCore::Configuration.create([config_item], {})

            expect(FastlaneCore::UI).to receive(:input).and_return("val ask")
            expect(config[:item]).to eq("val ask")
          end
        end
      end
    end
  end
end
