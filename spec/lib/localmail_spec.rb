require "rails_helper"

RSpec.describe Localmail do
  describe ".enabled?" do
    it "is false when CAPTURE_EMAILS is unset" do
      allow(ENV).to receive(:fetch).with("CAPTURE_EMAILS", nil).and_return(nil)

      expect(described_class.enabled?).to be false
    end

    it "is false when CAPTURE_EMAILS is falsey" do
      allow(ENV).to receive(:fetch).with("CAPTURE_EMAILS", nil).and_return("false")

      expect(described_class.enabled?).to be false
    end

    it "is true when CAPTURE_EMAILS is truthy" do
      allow(ENV).to receive(:fetch).with("CAPTURE_EMAILS", nil).and_return("true")

      expect(described_class.enabled?).to be true
    end

    it "prefers an explicit setting over the environment" do
      allow(ENV).to receive(:fetch).with("CAPTURE_EMAILS", nil).and_return("true")
      described_class.configure { |config| config.enabled = false }

      expect(described_class.enabled?).to be false
    end

    it "evaluates a callable setting each time it is asked" do
      flag = false
      described_class.configure { |config| config.enabled = -> { flag } }
      flag = true

      expect(described_class.enabled?).to be true
    end
  end

  describe ".capturing?" do
    it "is false in the test environment even when enabled" do
      described_class.configure { |config| config.enabled = true }

      expect(described_class.capturing?).to be false
    end

    it "is true in the test environment when capture_in_test is set" do
      described_class.configure do |config|
        config.enabled = true
        config.capture_in_test = true
      end

      expect(described_class.capturing?).to be true
    end

    it "is true when enabled outside the test environment" do
      described_class.configure { |config| config.enabled = true }
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("staging"))

      expect(described_class.capturing?).to be true
    end

    it "is false when not enabled" do
      described_class.configure { |config| config.enabled = false }
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("staging"))

      expect(described_class.capturing?).to be false
    end
  end

  describe ".config.namespace" do
    it "defaults to the app and environment" do
      expect(described_class.config.namespace).to eq("localmail:dummy:test")
    end
  end

  describe ".redis" do
    it "builds the client from a configured callable" do
      client = Redis.new
      described_class.configure { |config| config.redis = -> { client } }

      expect(described_class.redis.ping).to eq("PONG")
    end
  end
end
