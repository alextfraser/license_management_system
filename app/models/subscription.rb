class Subscription < ApplicationRecord
  belongs_to :account
  belongs_to :product
  has_many :license_assignments, foreign_key: [ :account_id, :product_id ], primary_key: [ :account_id, :product_id ]

  validates :number_of_licenses, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :issued_at, presence: true
  validates :expires_at, presence: true
  validate :expires_at_after_issued_at
  validate :no_overlapping_subscriptions

  scope :active, -> { where("issued_at <= ? AND expires_at > ?", Time.current, Time.current) }

  def available_licenses
    return 0 if expired?
    number_of_licenses - used_licenses
  end

  def used_licenses
    LicenseAssignment.where(account: account, product: product)
      .where("created_at >= ? AND created_at <= ?", issued_at, [ expires_at, Time.current ].min)
      .count
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

  def no_overlapping_subscriptions
    return if account.blank? || product.blank? || issued_at.blank? || expires_at.blank?

    existing = Subscription.where(account: account, product: product)
    existing = existing.where.not(id: id) if persisted?

    overlapping = existing.where(
      "(issued_at < ? AND expires_at > ?)",
      expires_at,
      issued_at
    )

    if overlapping.exists?
      errors.add(:base, "Date range overlaps with an existing subscription for this product")
    end
  end
end
