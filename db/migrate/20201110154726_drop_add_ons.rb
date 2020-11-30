class DropAddOns < ActiveRecord::Migration[5.2]
  def change
    drop_table :add_ons
  end
end
