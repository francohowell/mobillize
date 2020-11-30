class AddJobIdToOrganizationAddOnRelationship < ActiveRecord::Migration[5.2]
  def change
    add_column :organization_add_on_relationships, :job_id, :string
  end
end
