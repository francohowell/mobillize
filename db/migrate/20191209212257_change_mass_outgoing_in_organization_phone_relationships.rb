class ChangeMassOutgoingInOrganizationPhoneRelationships < ActiveRecord::Migration[5.2]
  def change
    change_column :organization_phone_relationships, :mass_outgoing, :boolean, null: false, default: false
  end
end
