class VcenterConnection < ApplicationRecord
  has_many :audit_events, dependent: :nullify

  validates :name, presence: true
  validates :host, presence: true, uniqueness: true
  validates :username, presence: true

  scope :active, -> { where(enabled: true) }

  encrypts :encrypted_password

  def password
    encrypted_password
  end

  def password=(value)
    self.encrypted_password = value
  end

  def display_name
    "#{name} (#{host})"
  end

  def record_success!
    update!(last_collection_at: Time.current, last_error: nil)
  end

  def record_failure!(error_message)
    update!(last_error: error_message.truncate(500))
  end

  def status
    return :disabled unless enabled?
    return :error if last_error.present?
    return :ok if last_collection_at.present?
    :pending
  end
end
