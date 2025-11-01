class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.references :account, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :number_of_licenses
      t.datetime :issued_at
      t.datetime :expires_at

      t.timestamps
    end
  end
end
