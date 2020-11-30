class DropOrganizationAddOnRelationships < ActiveRecord::Migration[5.2]
  def change
    drop_table :organization_add_on_relationships
  end
end
