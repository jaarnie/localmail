require "rails_helper"

RSpec.describe Localmail::Capture do
  before { ActionMailer::Base.deliveries.clear }

  context "when capturing" do
    before { allow(Localmail).to receive(:capturing?).and_return(true) }

    it "captures a declared action" do
      NotificationMailer.sign_in_link.deliver_now

      expect(Localmail::Store.all.map(&:subject)).to eq([ "Your sign-in link" ])
    end

    it "does not deliver a declared action" do
      NotificationMailer.sign_in_link.deliver_now

      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it "delivers an undeclared action normally" do
      expect { NotificationMailer.receipt.deliver_now }.to change { ActionMailer::Base.deliveries.size }.by(1)
    end

    it "captures nothing for an undeclared action" do
      NotificationMailer.receipt.deliver_now

      expect(Localmail::Store.all).to be_empty
    end

    it "captures every action when declared bare" do
      DigestMailer.weekly.deliver_now

      expect(Localmail::Store.all.map(&:subject)).to eq([ "Weekly digest" ])
    end
  end

  context "when not capturing" do
    before { allow(Localmail).to receive(:capturing?).and_return(false) }

    it "delivers a declared action normally" do
      expect { NotificationMailer.sign_in_link.deliver_now }.to change { ActionMailer::Base.deliveries.size }.by(1)
    end
  end

  it "registers the :localmail delivery method" do
    expect(ActionMailer::Base.delivery_methods[:localmail]).to eq(Localmail::DeliveryMethod)
  end

  it "keeps the capture callback out of every mailer's actions" do
    expect(NotificationMailer.action_methods).not_to include("localmail_capture")
  end

  it "records which actions a mailer declared" do
    expect(NotificationMailer.localmail_captured_actions).to eq([ :sign_in_link ])
  end
end
