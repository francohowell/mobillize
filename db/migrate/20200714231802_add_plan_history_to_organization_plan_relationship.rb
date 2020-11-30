class AddPlanHistoryToOrganizationPlanRelationship < ActiveRecord::Migration[5.2]
  def change
    add_column :organization_plan_relationships, :plan_start_date, :datetime
    add_column :organization_plan_relationships, :plan_canceled_date, :datetime
    add_column :organization_plan_relationships, :plan_end_date, :datetime
    add_column :organization_plan_relationships, :active, :boolean, nill: false, default: true
  end
end
