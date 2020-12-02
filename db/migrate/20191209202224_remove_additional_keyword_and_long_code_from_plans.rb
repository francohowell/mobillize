class RemoveAdditionalKeywordAndLongCodeFromPlans < ActiveRecord::Migration[5.2]
  def change
    remove_column :plans, :long_code, :boolean
    remove_column :plans, :additional_keyword_cost, :float
  end
end
