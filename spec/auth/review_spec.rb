require "./core/reviews.rb"

class ReviewTester
  include Reviews
end

describe Reviews do
  let(:review_tester) { ReviewTester.new }
  describe "remove_review" do
    it "fails when no review found in DB" do
      expect_any_instance_of(Repository).to receive(:delete_review).and_return(false)
      expect { review_tester.remove_review("some_id") }.to raise_error(BookclubErrors::ReviewError, "Could not delete review: No such review found in database")
    end
  end
  describe "verify_review_input" do
    it "fails on empty username" do
      expect { review_tester.verify_review_input(nil, "some_user_id", 5) }.to raise_error(BookclubErrors::ReviewError, "Missing `volume_id` in request")
      expect { review_tester.verify_review_input("", "some_user_id", 5) }.to raise_error(BookclubErrors::ReviewError, "Missing `volume_id` in request")
    end
    it "fails on empty password" do
      expect { review_tester.verify_review_input("some_volume_id", nil, 5) }.to raise_error(BookclubErrors::ReviewError, "Missing `user_id` in request")
      expect { review_tester.verify_review_input("some_volume_id", "", 5) }.to raise_error(BookclubErrors::ReviewError, "Missing `user_id` in request")
    end
    it "fails on empty password" do
      expect { review_tester.verify_review_input("some_volume_id", "some_user_id", nil) }.to raise_error(BookclubErrors::ReviewError, "Missing `rating` in request")
      expect { review_tester.verify_review_input("some_volume_id", "some_user_id", nil) }.to raise_error(BookclubErrors::ReviewError, "Missing `rating` in request")
    end
  end
  describe "add_review" do
    it "fails when review already exists for user and volume" do
      expect(review_tester).to receive(:get_user_volume_review).and_return("some_volume_id")
      expect { review_tester.add_review("some_volume_id", "some_user_id", 5) }.to raise_error(BookclubErrors::ReviewError, "Review for volume already exists for current user")
    end
    it "fails when review is an non-integer value" do
      expect(review_tester).to receive(:get_user_volume_review).and_return(nil)
      expect { review_tester.add_review("some_volume_id", "some_user_id", "cat") }.to raise_error(BookclubErrors::ReviewError, "Invalid rating provided in request")
      expect { review_tester.add_review("some_volume_id", "some_user_id", []) }.to raise_error(BookclubErrors::ReviewError, "Invalid rating provided in request")
      expect { review_tester.add_review("some_volume_id", "some_user_id", {}) }.to raise_error(BookclubErrors::ReviewError, "Invalid rating provided in request")
    end
  end
end
