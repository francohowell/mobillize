class AddAnnualStripeIdToPlans < ActiveRecord::Migration[5.2]
  def change
    add_column :plans, :annual_stripe_id, :string
  end
end
