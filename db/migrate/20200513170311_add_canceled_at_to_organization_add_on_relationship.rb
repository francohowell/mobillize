class AddCanceledAtToOrganizationAddOnRelationship < ActiveRecord::Migration[5.2]
  def change
    add_column :organization_add_on_relationships, :canceled_at, :datetime
  end
end
