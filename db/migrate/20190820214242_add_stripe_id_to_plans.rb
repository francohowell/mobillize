class AddStripeIdToPlans < ActiveRecord::Migration[5.2]
  def change
    add_column :plans, :stripe_id, :string 
    add_index :plans, :stripe_id, :unique => true
  end
end
