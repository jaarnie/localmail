class DigestMailer < ApplicationMailer
  capture_in_localmail

  def weekly
    mail(to: "customer@example.com", subject: "Weekly digest", body: "This week")
  end
end
