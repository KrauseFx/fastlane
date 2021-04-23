describe Spaceship::Tunes::IAPFamilyList do
  before { TunesStubbing.itc_stub_iap }
  before { Spaceship::Tunes.login }
  let(:client) { Spaceship::Application.client }
  let(:app) { Spaceship::Application.all.first }
  let(:purchase) { app.in_app_purchases }
  describe "IAP FamilyDetail" do
    it "Creates a Object" do
      element = app.in_app_purchases.families.all.first.edit
      expect(element.class).to eq(Spaceship::Tunes::IAPFamilyDetails)
      expect(element.name).to eq("Family Name")
      expect(element.versions[:"de-DE"][:name]).to eq("dasdsads")
    end
    it "can save version" do
      edit_version = app.in_app_purchases.families.all.first.edit
      edit_version.save!
      expect(edit_version.class).to eq(Spaceship::Tunes::IAPFamilyDetails)
      expect(edit_version.family_id).to eq("20373395")
    end
    it "can change versions" do
      edit_version = app.in_app_purchases.families.all.first.edit
      edit_version.versions = {
        "de-DE" => {
          subscription_name: "subscr name",
          name: "localized name",
          id: 12_345
        }
      }
      edit_version.save!
      expect(edit_version.class).to eq(Spaceship::Tunes::IAPFamilyDetails)
      expect(edit_version.family_id).to eq("20373395")
      expect(edit_version.versions).to eq({ "de-DE": { subscription_name: "subscr name", name: "localized name", id: 12_345, status: nil } })
    end
  end
end
