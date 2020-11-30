class RenameOrganizationPlan < ActiveRecord::Migration[5.2]
  def change
    rename_column :organizations, :plan_id, :previous_plan_id
  end
end
