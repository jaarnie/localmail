require "rails_helper"

RSpec.describe Localmail::DeliveryMethod do
  let(:mail) { Mail.new(to: "qa@example.com", subject: "Magic link", body: "hi") }

  it "stores the message instead of sending it" do
    expect { described_class.new.deliver!(mail) }.to change { Localmail::Store.all.size }.by(1)
  end

  context "when the store fails" do
    before { allow(Localmail::Store).to receive(:save).and_raise(IOError, "store down") }

    it "re-raises so the delivery fails" do
      expect { described_class.new.deliver!(mail) }.to raise_error(IOError)
    end

    it "logs which message was lost" do
      allow(Rails.logger).to receive(:error)

      described_class.new.deliver!(mail) rescue nil

      expect(Rails.logger).to have_received(:error).with(/failed to capture "Magic link": IOError: store down/)
    end
  end
end
