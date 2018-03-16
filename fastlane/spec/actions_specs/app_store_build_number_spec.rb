describe Fastlane do
  describe Fastlane::FastFile do
    describe "app_store_build_number" do
      it "orders versions array of integers" do
        versions = [3,5,1,0,4]
        result = Fastlane::Actions::AppStoreBuildNumberAction.order_versions(versions)

        expect(result).to eq(['0','1','3','4','5'])
      end

      it "orders versions array of integers and string integers" do
        versions = [3,5,'1',0,'4']
        result = Fastlane::Actions::AppStoreBuildNumberAction.order_versions(versions)

        expect(result).to eq(['0','1','3','4','5'])
      end

      it "orders versions array of integers, string integers, floats, and semantic versions string" do
        versions = [3,'1','2.3',9,'6.5.4','11.4.6',5.6]
        result = Fastlane::Actions::AppStoreBuildNumberAction.order_versions(versions)

        expect(result).to eq(['1','2.3','3','5.6','6.5.4','9','11.4.6'])
      end
    end
  end
end
