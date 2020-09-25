require "./core/shelves.rb"

class ShelfTester
  include Shelves
end

describe Shelves do
  let(:shelf_tester) { ShelfTester.new }
  describe "get_volume_from_shelf" do
    let(:current_shelf) { { :volumes => [{ :volume_id => "some_volume_id" }] } }
    it "returns nil when volume missing from shelf" do
      expect(shelf_tester.get_volume_from_shelf("some_other_volume_id", current_shelf)).to be_nil
    end
    it "returns volume when volume_id matches volume in shelf" do
      expect(shelf_tester.get_volume_from_shelf("some_volume_id", current_shelf)).not_to be_nil
    end
  end
  describe "get_currently_reading_from_shelf" do
    let(:volume_id) { "some_volume_id" }
    let(:volume) { { :volume_id => volume_id, :shelf => "currently_reading" } }
    let(:current_shelf) { { :volumes => [volume] } }
    it "returns volume if volume is currently_reading" do
      expect(shelf_tester.get_currently_reading_from_shelf(current_shelf)).to eq(volume)
    end
    it "returns nil when no volumes currently reading" do
      current_shelf = { :volumes => [{ :volume_id => volume_id, :shelf => "want_to_read" }] }
      expect(shelf_tester.get_currently_reading_from_shelf(current_shelf)).to be_nil
    end
    it "returns nil when volumes list is empty" do
      current_shelf = { :volumes => [] }
      expect(shelf_tester.get_currently_reading_from_shelf(current_shelf)).to be_nil
    end
  end
  describe "verify_shelf_operation_data" do
    it "raises error if operation is empty or nil" do
      expect { shelf_tester.verify_shelf_operation_data(nil, "some_volume_id", "some_shelf") }.to raise_error(BookclubErrors::ShelfOpError, "Missing `op` in request")
      expect { shelf_tester.verify_shelf_operation_data("", "some_volume_id", "some_shelf") }.to raise_error(BookclubErrors::ShelfOpError, "Missing `op` in request")
    end
    it "raises error if volume_id is empty or nil" do
      expect { shelf_tester.verify_shelf_operation_data("some_operation", nil, "some_shelf") }.to raise_error(BookclubErrors::ShelfOpError, "Missing `volume_id` in request")
      expect { shelf_tester.verify_shelf_operation_data("some_operation", "", "some_shelf") }.to raise_error(BookclubErrors::ShelfOpError, "Missing `volume_id` in request")
    end
    it "raises error if to_shelf is empty or nil, unless operation is `delete`" do
      expect { shelf_tester.verify_shelf_operation_data("some_operation", "some_volume_id", nil) }.to raise_error(BookclubErrors::ShelfOpError, "Missing `to_shelf` in request")
      expect { shelf_tester.verify_shelf_operation_data("some_operation", "some_volume_id", "") }.to raise_error(BookclubErrors::ShelfOpError, "Missing `to_shelf` in request")
      expect(shelf_tester.verify_shelf_operation_data("delete", "some_volume_id", nil)).to be_nil
      expect(shelf_tester.verify_shelf_operation_data("delete", "some_volume_id", "")).to be_nil
    end
  end
  describe "modify_exclusive_shelves" do
    let(:empty_shelf) { { :volumes => {} } }
    it "Handles an invalid operation" do
      expect_any_instance_of(Repository).to receive(:get_exclusive_shelf).and_return(empty_shelf)
      expect(shelf_tester).not_to receive(:initialize_shelf)
      expect { shelf_tester.modify_exclusive_shelves("some_user_id", "invalid_operation", "some_volume_id", "some_shelf") }.to raise_error(BookclubErrors::ShelfOpError, "Invalid operation provided")
    end
    it "Initializes shelf if shelf does not exist" do
      expect_any_instance_of(Repository).to receive(:get_exclusive_shelf).and_return(nil)
      expect(shelf_tester).to receive(:initialize_shelf).with("some_user_id").and_return(empty_shelf)
      expect { shelf_tester.modify_exclusive_shelves("some_user_id", "invalid_operation", "some_volume_id", "some_shelf") }.to raise_error(BookclubErrors::ShelfOpError, "Invalid operation provided")
    end
  end
  describe "handle_upsert_to_shelf" do
    # Also want to assert that bump_currently_reading is called
    let(:volume_id) { "some_volume_id" }
    let(:volume) { { :volume_id => volume_id, :shelf => "some_shelf" } }
    let(:current_shelf) { { :volumes => [volume] } }
    it "Stops early if trying to move a volume to its current shelf" do
      expect(shelf_tester).to receive(:get_volume_from_shelf).and_return(volume)
      expect { shelf_tester.handle_upsert_to_shelf("some_user_id", "some_volume_id", "some_shelf", true, current_shelf) }.to raise_error(BookclubErrors::ShelfOpError, "No modifications needed")
    end
    it "Stops early if invalid shelf provided" do
      expect(shelf_tester).to receive(:get_volume_from_shelf).and_return(volume)
      expect { shelf_tester.handle_upsert_to_shelf("some_user_id", "some_volume_id", "some_invalid_shelf", true, current_shelf) }.to raise_error(BookclubErrors::ShelfOpError, "Invalid shelf provided")
    end
    it "currently_reading - bumps out whatever being currently read" do
      expect(shelf_tester).to receive(:get_volume_from_shelf).and_return(volume)
      expect(shelf_tester).to receive(:get_currently_reading_from_shelf).and_return({ :volume_id => "some_other_volume_id", :shelf => "currently_reading" })
      expect(shelf_tester).to receive(:bump_currently_reading)
      expect_any_instance_of(Repository).to receive(:upsert_to_shelf).and_return(nil)
      expect(shelf_tester.handle_upsert_to_shelf("some_user_id", "some_volume_id", "currently_reading", true, current_shelf)).to be_nil
    end
  end
end
