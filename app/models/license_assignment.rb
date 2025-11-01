class LicenseAssignment < ApplicationRecord
  belongs_to :account
  belongs_to :user
  belongs_to :product

  validates :user_id, uniqueness: { scope: [ :account_id, :product_id ],
                                     message: "already has a license for this product" }
  validate :user_belongs_to_account
  validate :subscription_exists_and_has_available_licenses

  private

  def user_belongs_to_account
    return if user.blank? || account.blank?

    unless user.account_id == account_id
      errors.add(:user, "must belong to the same account")
    end
  end

  def subscription_exists_and_has_available_licenses
    return if account.blank? || product.blank?

    subscription = Subscription.find_by(account: account, product: product)

    if subscription.blank?
      errors.add(:base, "No subscription exists for this product")
      return
    end

    if subscription.expired?
      errors.add(:base, "Subscription has expired")
      return
    end

    # When updating, don't count this assignment against the limit
    existing_assignments = if persisted?
      LicenseAssignment.where(account: account, product: product).where.not(id: id).count
    else
      LicenseAssignment.where(account: account, product: product).count
    end

    if existing_assignments >= subscription.number_of_licenses
      errors.add(:base, "No available licenses for this product")
    end
  end
end
