class CreateStripeAccounts < ActiveRecord::Migration[5.2]
  def change
    create_table :stripe_accounts do |t|
      t.string :stripe_id, null: false
      t.datetime :stripe_creation, null: false
      t.string :payment_source_id, null: false
      t.integer :payment_source_exp_month, null: false 
      t.integer :payment_source_exp_year, null: false 
      t.string :payment_source_type, null: false
      t.string :payment_source_last4, null: false
      t.string :payment_source_name, null: false 

      t.belongs_to :organization, null: false, unique: true
      t.timestamps
    end
  end
end