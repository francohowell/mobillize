class CreateOrganizationAddOnRelationships < ActiveRecord::Migration[5.2]
  def change
    create_table :organization_add_on_relationships do |t|
      t.string :status, null: false, default: "active"
      t.string :subscription_id, null: false
      t.belongs_to :organization, null: false
      t.belongs_to :add_on, null: false
      t.timestamps
    end
  end
end
