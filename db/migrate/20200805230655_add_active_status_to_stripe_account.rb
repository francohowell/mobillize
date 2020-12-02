class AddActiveStatusToStripeAccount < ActiveRecord::Migration[5.2]
  def change
    add_column :stripe_accounts, :active, :boolean, nill: false, default: true
  end
end
