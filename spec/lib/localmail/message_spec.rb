require "rails_helper"

RSpec.describe Localmail::Message do
  subject(:message) { Localmail::Store.find(Localmail::Store.save(mail)) }

  let(:mail) do
    Mail.new(from: "noreply@example.com", to: "qa@example.com", subject: "Magic link") do
      text_part { body "Click https://example.com/verify?token=abc" }
      html_part { body "<p>Click <a href='https://example.com/verify?token=abc'>here</a></p>" }
    end
  end

  it "exposes the html part" do
    expect(message.html_body).to include("https://example.com/verify?token=abc")
  end

  it "retargets preview links so they escape the iframe" do
    expect(message.preview_html).to start_with(%(<base target="_blank">))
  end

  it "has no preview html when the message is text only" do
    text_only = Localmail::Store.find(Localmail::Store.save(Mail.new(to: "qa@example.com", body: "plain")))

    expect(text_only.preview_html).to be_nil
  end

  it "exposes the text part" do
    expect(message.text_body).to include("Click https://example.com/verify?token=abc")
  end

  it "exposes the recipients" do
    expect(message.to).to eq([ "qa@example.com" ])
  end

  context "with non-ASCII copy, which forces quoted-printable encoding" do
    let(:mail) do
      Mail.new(from: "noreply@example.com", to: "qa@example.com", subject: "Enquiry – café") do
        html_part do
          content_type "text/html; charset=UTF-8"
          body "<p>Prêt à rouler — <a href=\"https://example.com\">go</a></p>"
        end
      end
    end

    it "returns the body as UTF-8 rather than ASCII-8BIT" do
      expect(message.html_body.encoding).to eq(Encoding::UTF_8)
    end

    it "returns a body the view can safely concatenate" do
      expect(message.html_body).to be_valid_encoding
    end

    it "preserves the accented characters" do
      expect(message.html_body).to include("Prêt à rouler —")
    end

    it "returns the raw source as UTF-8 so the view can render it" do
      expect(message.raw.encoding).to eq(Encoding::UTF_8)
    end
  end
end
