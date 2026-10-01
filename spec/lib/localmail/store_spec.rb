require "rails_helper"

RSpec.describe Localmail::Store do
  let(:mail) { Mail.new(from: "noreply@example.com", to: "qa@example.com", subject: "Magic link", body: "hi") }

  def save_subject(subject)
    described_class.save(Mail.new(subject: subject, to: "qa@example.com"))
  end

  describe ".all" do
    it "returns the most recently captured message first" do
      described_class.save(mail)
      save_subject("Later")

      expect(described_class.all.map(&:subject)).to eq([ "Later", "Magic link" ])
    end

    it "caps the list at max_messages, keeping the newest" do
      Localmail.configure { |config| config.max_messages = 2 }

      3.times { |i| save_subject("Mail #{i}") }

      expect(described_class.all.map(&:subject)).to eq([ "Mail 2", "Mail 1" ])
    end

    it "deletes the message key of anything it rolls off the end" do
      Localmail.configure { |config| config.max_messages = 2 }
      oldest = save_subject("Mail 0")

      2.times { |i| save_subject("Mail #{i + 1}") }

      expect(described_class.find(oldest)).to be_nil
    end
  end

  describe ".find" do
    it "round-trips a stored message" do
      id = described_class.save(mail)

      expect(described_class.find(id).subject).to eq("Magic link")
    end

    it "returns nil for an unknown id" do
      expect(described_class.find("nope")).to be_nil
    end
  end

  describe ".save" do
    it "expires the message after the configured ttl" do
      Localmail.configure { |config| config.ttl = 60 }
      id = described_class.save(mail)

      expect(Localmail.redis.ttl("#{Localmail.config.namespace}:message:#{id}")).to be_between(1, 60)
    end

    it "keeps each namespace's messages apart" do
      described_class.save(mail)
      Localmail.configure { |config| config.namespace = "localmail:other" }

      expect(described_class.all).to be_empty
    end
  end

  describe ".delete" do
    it "removes the message from the list" do
      id = described_class.save(mail)

      expect { described_class.delete(id) }.to change { described_class.all.size }.by(-1)
    end

    it "removes the message key so nothing is orphaned" do
      id = described_class.save(mail)
      described_class.delete(id)

      expect(described_class.find(id)).to be_nil
    end

    it "leaves the other messages alone" do
      kept = described_class.save(mail)
      described_class.delete(save_subject("Doomed"))

      expect(described_class.all.map(&:id)).to eq([ kept ])
    end
  end

  describe ".clear" do
    it "removes every captured message" do
      described_class.save(mail)

      expect { described_class.clear }.to change { described_class.all.size }.to(0)
    end
  end
end
