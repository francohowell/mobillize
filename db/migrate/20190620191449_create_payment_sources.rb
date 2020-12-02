class CreatePaymentSources < ActiveRecord::Migration[5.2]
  def change
    create_table :payment_sources do |t|
      t.string :card_id, null: false
      t.string :brand, null: false
      t.string :exp_month, null: false
      t.string :exp_year, null: false
      t.string :last4, null: false
      t.datetime :stripe_creation, null: false
      t.belongs_to :stripe_account, null: false

      t.timestamps
    end
  end
end
