class CreateLicenseAssignments < ActiveRecord::Migration[8.0]
  def change
    create_table :license_assignments do |t|
      t.references :account, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true

      t.timestamps
    end
  end
end
