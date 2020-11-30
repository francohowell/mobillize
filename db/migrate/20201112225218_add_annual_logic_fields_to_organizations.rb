class AddAnnualLogicFieldsToOrganizations < ActiveRecord::Migration[5.2]
  def change
    add_column :organizations, :start_date, :datetime, null: false
    add_column :organizations, :annual_credits, :integer, null: false, default: 0
  end
end
