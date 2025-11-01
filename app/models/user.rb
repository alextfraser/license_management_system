class User < ApplicationRecord
  belongs_to :account
  has_many :license_assignments, dependent: :destroy
  has_many :products, through: :license_assignments

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end
