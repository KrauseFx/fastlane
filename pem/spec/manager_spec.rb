describe PEM do
  describe PEM::Manager do
    before do
      pem_stub_spaceship
    end

    around do |example|
      FastlaneSpec::Env.with_env_values(
        DELIVER_USER: 'test@fastlane.tools',
        DELIVER_PASSWORD: '123'
      ) do
        example.run
      end
    end

    before :all do
      FileUtils.mkdir("tmp")
    end

    it "Successful run" do
      options = { app_identifier: "com.krausefx.app", generate_p12: false }
      PEM.config = FastlaneCore::Configuration.create(PEM::Options.available_options, options)
      PEM::Manager.start

      expect(File.exist?("production_com.krausefx.app.pem")).to eq(true)
      expect(File.exist?("production_com.krausefx.app.pkey")).to eq(true)
    end

    it "Successful run with output_path" do
      options = { app_identifier: "com.krausefx.app", generate_p12: false, output_path: "tmp/" }
      PEM.config = FastlaneCore::Configuration.create(PEM::Options.available_options, options)
      PEM::Manager.start

      expect(File.exist?("tmp/production_com.krausefx.app.pem")).to eq(true)
      expect(File.exist?("tmp/production_com.krausefx.app.pkey")).to eq(true)
      expect(File.exist?("tmp/production_com.krausefx.app.p12")).to eq(false)
    end

    after :all do
      FileUtils.rm_r("tmp")
      File.delete("production_com.krausefx.app.pem")
      File.delete("production_com.krausefx.app.pkey")

      ENV.delete("DELIVER_USER")
      ENV.delete("DELIVER_PASSWORD")
    end
  end
end
