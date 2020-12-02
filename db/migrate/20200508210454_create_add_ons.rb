class CreateAddOns < ActiveRecord::Migration[5.2]
  def change
    create_table :add_ons do |t|
      t.string :name, null: false
      t.float :monthly_cost, null: false, default: 0
      t.string :icon
      t.string :stripe_id, null: false
      t.text :description, null: false      
      t.timestamps
    end
  end
end
