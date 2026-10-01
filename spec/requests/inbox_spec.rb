require "rails_helper"

RSpec.describe "Inbox" do
  let(:captured_mail) do
    Mail.new(from: "noreply@example.com", to: "customer@example.com", subject: "Menu – café") do
      html_part do
        content_type "text/html; charset=UTF-8"
        body "<p>Déjà vu — à bientôt</p>"
      end
    end
  end

  let(:text_only_mail) { Mail.new(to: "qa@example.com", subject: "Plain words", body: "no html here") }

  context "when enabled" do
    before { Localmail.configure { |config| config.enabled = true } }

    describe "GET /mail" do
      it "lists a captured message by subject" do
        Localmail::Store.save(captured_mail)

        get "/mail"

        expect(response.body).to include("Menu – café")
      end

      it "says when nothing has been captured" do
        get "/mail"

        expect(response.body).to include("Nothing held yet")
      end
    end

    describe "GET /mail/:id" do
      it "renders the body of a message whose transfer encoding is quoted-printable" do
        get "/mail/#{Localmail::Store.save(captured_mail)}"

        expect(response.body).to include("Déjà vu —")
      end

      it "redirects to the inbox when the message has expired" do
        get "/mail/#{SecureRandom.uuid}"

        expect(response).to redirect_to("/mail/")
      end
    end

    describe "GET /mail/:id for a message with an HTML part" do
      before { get "/mail/#{Localmail::Store.save(captured_mail)}" }

      it "offers a desktop viewport" do
        expect(response.parsed_body.at_css("label[for='vp-desktop']")).to be_present
      end

      it "offers a mobile viewport" do
        expect(response.parsed_body.at_css("label[for='vp-mobile']")).to be_present
      end

      it "starts on the desktop viewport" do
        expect(response.parsed_body.at_css("input#vp-desktop[name='viewport'][checked]")).to be_present
      end

      it "marks the preview as the thing the toggle resizes" do
        expect(response.parsed_body.at_css("div.lm-panels iframe.lm-frame")).to be_present
      end
    end

    describe "GET /mail/:id for a message with no HTML part" do
      before { get "/mail/#{Localmail::Store.save(text_only_mail)}" }

      it "offers no viewport toggle" do
        expect(response.parsed_body.at_css("div.lm-viewport")).to be_nil
      end
    end

    describe "DELETE /mail/:id" do
      it "removes just that message" do
        id = Localmail::Store.save(captured_mail)

        delete "/mail/#{id}"

        expect(Localmail::Store.find(id)).to be_nil
      end
    end

    describe "DELETE /mail" do
      it "empties the inbox" do
        Localmail::Store.save(captured_mail)

        delete "/mail"

        expect(Localmail::Store.all).to be_empty
      end
    end
  end

  context "when not enabled" do
    before { Localmail.configure { |config| config.enabled = false } }

    it "does not expose the inbox" do
      get "/mail"

      expect(response).to have_http_status(:not_found)
    end
  end

  context "with an authenticate hook" do
    before do
      Localmail.configure do |config|
        config.enabled = true
        config.authenticate = -> { head :unauthorized unless request.headers["X-Allowed"] }
      end
    end

    it "refuses a request the hook rejects" do
      get "/mail"

      expect(response).to have_http_status(:unauthorized)
    end

    it "serves a request the hook allows" do
      get "/mail", headers: { "X-Allowed" => "1" }

      expect(response).to have_http_status(:ok)
    end
  end
end
