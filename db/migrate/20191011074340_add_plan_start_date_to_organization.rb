class AddPlanStartDateToOrganization < ActiveRecord::Migration[5.2]
  def change
    add_column :organizations, :plan_start_date, :datetime, null: false
  end
end
