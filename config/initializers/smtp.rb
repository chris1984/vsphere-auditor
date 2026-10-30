Rails.application.config.action_mailer.delivery_method = :smtp
Rails.application.config.action_mailer.smtp_settings = {
  address: ENV.fetch("SMTP_ADDRESS", "localhost"),
  port: ENV.fetch("SMTP_PORT", 25).to_i,
  enable_starttls_auto: false,
  openssl_verify_mode: OpenSSL::SSL::VERIFY_NONE
}
