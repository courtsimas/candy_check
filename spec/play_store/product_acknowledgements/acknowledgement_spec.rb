require "spec_helper"

describe CandyCheck::PlayStore::ProductAcknowledgements::Acknowledgement do
  subject do
    CandyCheck::PlayStore::ProductAcknowledgements::Acknowledgement.new(
      package_name: package_name,
      product_id: product_id,
      token: token,
      authorization: authorization,
    )
  end

  let(:package_name)  { "fake_package_name" }
  let(:product_id)    { "fake_product_id" }
  let(:token)         { "fake_token" }
  let(:json_key_file) { File.expand_path("../../fixtures/play_store/random_dummy_key.json", __dir__) }
  let(:authorization) { CandyCheck::PlayStore.authorization(json_key_file) }

  describe "#call!" do
    it "when acknowledgement succeeds" do
      VCR.use_cassette("play_store/product_acknowledgements/acknowledged") do
        result = subject.call!

        _(result).must_be_instance_of CandyCheck::PlayStore::ProductAcknowledgements::Response
        _(result.acknowledged?).must_be_true
        _(result.error).must_be_nil
      end
    end
    it "when already acknowledged" do
      error_body = "{\n  \"error\": {\n    \"code\": 400,\n    \"message\": \"The purchase is not in a valid state to perform the desired operation.\",\n    \"errors\": [\n      {\n        \"message\": \"The purchase is not in a valid state to perform the desired operation.\",\n        \"domain\": \"androidpublisher\",\n        \"reason\": \"invalidPurchaseState\",\n        \"location\": \"token\",\n        \"locationType\": \"parameter\"\n      }\n    ]\n  }\n}\n"

      VCR.use_cassette("play_store/product_acknowledgements/already_acknowledged") do
        result = subject.call!

        _(result).must_be_instance_of CandyCheck::PlayStore::ProductAcknowledgements::Response
        _(result.acknowledged?).must_be_false
        _(result.error[:body]).must_equal(error_body)
        _(result.error[:status_code]).must_equal(400)
      end
    end
    it "when it has been refunded" do
      error_body = "{\n  \"error\": {\n    \"code\": 400,\n    \"message\": \"The product purchase is not owned by the user.\",\n    \"errors\": [\n      {\n        \"message\": \"The product purchase is not owned by the user.\",\n        \"domain\": \"androidpublisher\",\n        \"reason\": \"productNotOwnedByUser\"\n      }\n    ]\n  }\n}\n"

      VCR.use_cassette("play_store/product_acknowledgements/refunded") do
        result = subject.call!

        _(result).must_be_instance_of CandyCheck::PlayStore::ProductAcknowledgements::Response
        _(result.acknowledged?).must_be_false
        _(result.error[:body]).must_equal(error_body)
        _(result.error[:status_code]).must_equal(400)
      end
    end
  end
end