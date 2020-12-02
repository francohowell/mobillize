class AddStripeIdToBlast < ActiveRecord::Migration[5.2]
  def change
    add_column :blasts, :stripe_id, :string
  end
end
