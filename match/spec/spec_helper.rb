RSpec::Matchers.define(:a_configuration_matching) do |expected|
  match do |actual|
    actual.values == expected.values
  end
end

def around_each_match(example)
  FastlaneSpec::Env.with_env_values(
    DELIVER_USER: 'flapple@krausefx.com',
    DELIVER_PASSWORD: 'so_secret'
  ) do
    example.run
  end
end
