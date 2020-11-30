class RemovePreviousPlanIdFromOrganizations < ActiveRecord::Migration[5.2]
  def change
    remove_column :organizations, :previous_plan_id, :bigint
  end
end
