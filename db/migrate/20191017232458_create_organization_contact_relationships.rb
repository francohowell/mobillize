class CreateOrganizationContactRelationships < ActiveRecord::Migration[5.2]
  def change
    create_table :organization_contact_relationships do |t|
      t.belongs_to :organization, null: false 
      t.belongs_to :contact, null: false

      t.timestamps
    end
  end
end
