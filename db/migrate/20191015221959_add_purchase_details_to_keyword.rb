class AddPurchaseDetailsToKeyword < ActiveRecord::Migration[5.2]
  def change
    add_column :keywords, :stripe_id, :string
    add_column :keywords, :purchase_date, :datetime
  end
end
