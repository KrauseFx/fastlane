require File.expand_path('../spec_helper', __FILE__)

module XcodeInstall
  describe JSON do
    it 'can parse Xcode JSON' do
      fixture = Pathname.new('spec/fixtures/xcode.json').read
      xcode = Xcode.new(JSON.parse(fixture))

      expect(xcode.date_modified).to be == 1_413_472_373_000
      expect(xcode.name).to be == 'Command Line Tools (OS X 10.9) for Xcode - Xcode 6.1'
      expect(xcode.url).to be == 'https://developer.apple.com/devcenter/download.action?path=/Developer_Tools/command_line_tools_os_x_10.9_for_xcode__xcode_6.1/command_line_tools_for_osx_10.9_for_xcode_6.1.dmg'
    end

    it 'can parse list of all Xcodes' do
      fixture = Pathname.new('spec/fixtures/yolo.json').read
      installer = Installer.new

      seedlist = installer.send(:parse_seedlist, JSON.parse(fixture))
      installer.stub(:installed_versions).and_return([])
      installer.stub(:xcodes).and_return(seedlist)

      expect(installer.list).to be == "6.1\n6.1.1\n6.2"
    end
  end
end
