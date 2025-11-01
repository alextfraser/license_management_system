class Subscription < ApplicationRecord
  belongs_to :account
  belongs_to :product
  has_many :license_assignments, foreign_key: [ :account_id, :product_id ], primary_key: [ :account_id, :product_id ]

  validates :number_of_licenses, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :issued_at, presence: true
  validates :expires_at, presence: true
  validate :expires_at_after_issued_at

  # Scope for active subscriptions
  scope :active, -> { where("expires_at > ?", Time.current) }

  # Check available licenses for this subscription
  def available_licenses
    return 0 if expired?
    number_of_licenses - used_licenses
  end

  def used_licenses
    LicenseAssignment.where(account: account, product: product).count
  end

  def expired?
    expires_at < Time.current
  end

  private

  def expires_at_after_issued_at
    return if issued_at.blank? || expires_at.blank?

    if expires_at <= issued_at
      errors.add(:expires_at, "must be after issued date")
    end
  end
end
