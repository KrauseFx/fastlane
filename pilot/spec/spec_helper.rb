def around_each_pilot(current_test)
  FastlaneSpec::Env.with_env_values(
    DELIVER_USER: 'DELIVERUSER',
    DELIVER_PASSWORD: 'DELIVERPASS',
    DELIVER_HTML_EXPORT_PATH: "/tmp" # to not pollute the working directory
  ) do
    current_test.run
  end
end
