class DropOrganizationPlanRelationships < ActiveRecord::Migration[5.2]
  def up
    drop_table :organization_plan_relationships
  end
  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
