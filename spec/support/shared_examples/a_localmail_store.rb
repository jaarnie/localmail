RSpec.shared_examples "a Localmail store" do
  let(:mail) { Mail.new(from: "noreply@example.com", to: "qa@example.com", subject: "Magic link", body: "hi") }

  def save_subject(subject)
    Localmail::Store.save(Mail.new(subject: subject, to: "qa@example.com"))
  end

  describe ".all" do
    it "returns the most recently captured message first" do
      Localmail::Store.save(mail)
      save_subject("Later")

      expect(Localmail::Store.all.map(&:subject)).to eq([ "Later", "Magic link" ])
    end

    it "caps the list at max_messages, keeping the newest" do
      Localmail.config.max_messages = 2

      3.times { |i| save_subject("Mail #{i}") }

      expect(Localmail::Store.all.map(&:subject)).to eq([ "Mail 2", "Mail 1" ])
    end

    it "forgets anything it rolls off the end" do
      Localmail.config.max_messages = 2
      oldest = save_subject("Mail 0")

      2.times { |i| save_subject("Mail #{i + 1}") }

      expect(Localmail::Store.find(oldest)).to be_nil
    end
  end

  describe ".find" do
    it "round-trips a stored message" do
      id = Localmail::Store.save(mail)

      expect(Localmail::Store.find(id).subject).to eq("Magic link")
    end

    it "round-trips non-ASCII copy" do
      accented = Mail.new(to: "qa@example.com", subject: "Café", charset: "UTF-8", body: "Déjà vu —")

      expect(Localmail::Store.find(Localmail::Store.save(accented)).text_body).to include("Déjà vu —")
    end

    it "returns nil for an unknown id" do
      expect(Localmail::Store.find("nope")).to be_nil
    end
  end

  describe ".delete" do
    it "removes the message from the list" do
      id = Localmail::Store.save(mail)

      expect { Localmail::Store.delete(id) }.to change { Localmail::Store.all.size }.by(-1)
    end

    it "removes the message so it cannot be found" do
      id = Localmail::Store.save(mail)
      Localmail::Store.delete(id)

      expect(Localmail::Store.find(id)).to be_nil
    end

    it "leaves the other messages alone" do
      kept = Localmail::Store.save(mail)
      Localmail::Store.delete(save_subject("Doomed"))

      expect(Localmail::Store.all.map(&:id)).to eq([ kept ])
    end
  end

  describe ".clear" do
    it "removes every captured message" do
      Localmail::Store.save(mail)

      expect { Localmail::Store.clear }.to change { Localmail::Store.all.size }.to(0)
    end
  end
end
