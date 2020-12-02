class AddMassOutgoingToOrganizationPhoneRelationships < ActiveRecord::Migration[5.2]
  def change
    add_column :organization_phone_relationships, :mass_outgoing, :boolean
  end
end
