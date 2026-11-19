if Rails.application.credentials.active_record_encryption.blank?
  Rails.application.config.active_record.encryption.primary_key = ENV.fetch("AR_ENCRYPTION_PRIMARY_KEY", "test-primary-key-min-12-chars")
  Rails.application.config.active_record.encryption.deterministic_key = ENV.fetch("AR_ENCRYPTION_DETERMINISTIC_KEY", "test-deterministic-key-12ch")
  Rails.application.config.active_record.encryption.key_derivation_salt = ENV.fetch("AR_ENCRYPTION_KEY_DERIVATION_SALT", "test-key-derivation-salt-xx")
end
