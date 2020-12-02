class AddPrivateToAddOns < ActiveRecord::Migration[5.2]
  def change
    add_column :add_ons, :private, :boolean, nill: false, default: false
  end
end
