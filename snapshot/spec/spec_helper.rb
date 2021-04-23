# Loading the XCode Project is really slow (>1 second)
# fake it out for tests
def fake_out_xcode_project_loading
  fake_result = <<-EOS
Information about project "Example":
    Targets:
        Example
        ExampleUITests
        ExampleMacOS
        ExampleMacOSUITests
    Build Configurations:
        Debug
        Release
    If no build configuration is specified and -scheme is not passed then "Release" is used.
    Schemes:
        Example
        ExampleUITests
        ExampleMacOS
  EOS
  allow_any_instance_of(FastlaneCore::Project).to receive(:raw_info).and_return(fake_result)
end
