describe Spaceship::Portal::ProvisioningProfileTemplate do
  before { Spaceship.login }

  it "should factor a new provisioning profile template" do
    attrs = {
      "description" => "Template description",
      "purposeDisplayName" => "Template purpose display name",
      "purposeDescription" => "Template purpose description",
      "purposeName" => "Template purpose name",
      "version" => "1",
      "entitlements" => ["com.test.extended.entitlement"]
    }

    template = Spaceship::Portal::ProvisioningProfileTemplate.factory(attrs)

    expect(template.template_description).to eq("Template description")
    expect(template.purpose_description).to eq("Template purpose description")
    expect(template.purpose_display_name).to eq("Template purpose display name")
    expect(template.purpose_name).to eq("Template purpose name")
    expect(template.version).to eq("1")
    expect(template.entitlements).to eql(["com.test.extended.entitlement"])
  end
end
