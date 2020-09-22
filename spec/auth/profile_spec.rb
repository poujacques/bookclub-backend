require "./core/profiles.rb"

class ProfileTester
  include Profiles
end

describe Profiles do
  let(:profile_tester) { ProfileTester.new }
  describe "get_profile" do
    it "fails when user_id not found in DB" do
      expect_any_instance_of(Repository).to receive(:get_user_profile).and_return(nil)
      expect { profile_tester.get_profile("some_id") }.to raise_error(BookclubErrors::ProfileError, "User does not exist or no profile data exists")
    end
  end
  describe "update_profile_fields" do
    it "fails when profile_updates are empty" do
      expect { profile_tester.update_profile_fields("some_id", {}) }.to raise_error(BookclubErrors::ProfileError, "Empty or invalid update request")
    end
  end
end
