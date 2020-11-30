class CreateOrganizationPhoneRelationships < ActiveRecord::Migration[5.2]
  def change
    create_table :organization_phone_relationships do |t|
      t.belongs_to :organization, index: true, null: false
      t.belongs_to :phone_number, index: true, null: false
      t.timestamps
    end
    add_index :organization_phone_relationships, [:organization_id, :phone_number_id], unique: true, name: 'opr_on_organization_id_and_phone_number_id'
  end
end
