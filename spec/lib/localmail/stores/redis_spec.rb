require "rails_helper"
require "localmail/stores/redis"

RSpec.describe Localmail::Stores::Redis, :redis do
  let(:mail) { Mail.new(to: "qa@example.com", subject: "Magic link", body: "hi") }

  it_behaves_like "a Localmail store"

  it "expires the message after the configured ttl" do
    Localmail.config.ttl = 60
    id = Localmail::Store.save(mail)

    expect(Localmail.store.redis.ttl("#{Localmail.config.namespace}:message:#{id}")).to be_between(1, 60)
  end

  it "keeps each namespace's messages apart" do
    Localmail::Store.save(mail)
    Localmail.config.namespace = "localmail:other"

    expect(Localmail::Store.all).to be_empty
  end

  it "deletes the message key of anything it rolls off the end" do
    Localmail.config.max_messages = 1
    oldest = Localmail::Store.save(mail)
    Localmail::Store.save(mail)

    expect(Localmail.store.redis.exists?("#{Localmail.config.namespace}:message:#{oldest}")).to be false
  end

  it "builds the client from a configured callable" do
    client = Redis.new
    Localmail.configure do |config|
      config.store = :redis
      config.redis = -> { client }
    end

    expect(Localmail.store.redis.ping).to eq("PONG")
  end
end
