class RemovePreviousPlanDetailsFromOrganization < ActiveRecord::Migration[5.2]
  def change
    remove_column :organizations, :plan_start_date, :datetime

  end
end
