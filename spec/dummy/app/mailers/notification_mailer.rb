class NotificationMailer < ApplicationMailer
  capture_in_localmail :sign_in_link

  def sign_in_link
    mail(to: "customer@example.com", subject: "Your sign-in link", body: "https://example.com/verify")
  end

  def receipt
    mail(to: "customer@example.com", subject: "Your receipt", body: "Thanks")
  end
end
