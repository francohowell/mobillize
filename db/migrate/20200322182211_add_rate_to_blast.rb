class AddRateToBlast < ActiveRecord::Migration[5.2]
  def change
    add_column :blasts, :rate, :integer, default: 1, null: false
  end
end
