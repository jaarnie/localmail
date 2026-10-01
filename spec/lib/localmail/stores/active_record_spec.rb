require "rails_helper"
require "localmail/stores/active_record"

RSpec.describe Localmail::Stores::ActiveRecord do
  let(:mail) { Mail.new(to: "qa@example.com", subject: "Magic link", body: "hi") }

  it_behaves_like "a Localmail store"

  it "is the default store" do
    expect(Localmail.store).to be_a(described_class)
  end

  it "hides a message older than the ttl" do
    id = Localmail::Store.save(mail)

    travel_to(Localmail.config.ttl.from_now + 1.minute) do
      expect(Localmail::Store.find(id)).to be_nil
    end
  end

  it "deletes expired rows on the next save" do
    Localmail::Store.save(mail)

    travel_to(Localmail.config.ttl.from_now + 1.minute) do
      expect { Localmail::Store.save(mail) }.not_to change(described_class::Record, :count)
    end
  end

  it "deletes the rows it rolls off the end" do
    Localmail.config.max_messages = 2

    3.times { Localmail::Store.save(mail) }

    expect(described_class::Record.count).to eq(2)
  end
end
