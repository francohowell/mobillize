class AddYearlyPriceToPlans < ActiveRecord::Migration[5.2]
  def change
    add_column :plans, :yearly_price, :float
  end
end
