class AddNotNullToOrganizationPlanRelationships < ActiveRecord::Migration[5.2]
  def change
    change_column_default(:organization_plan_relationships, :plan_start_date, Time.now)
    change_column :organization_plan_relationships, :plan_start_date, :datetime, null: false,  default: -> { 'CURRENT_TIMESTAMP' }
  end
end
