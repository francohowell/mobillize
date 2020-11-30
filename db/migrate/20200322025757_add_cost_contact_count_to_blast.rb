class AddCostContactCountToBlast < ActiveRecord::Migration[5.2]
  def change
    add_column :blasts, :contact_count, :integer, default: 0, nil: false
    add_column :blasts, :cost, :float, default: 0.0, nil: false
  end
end
