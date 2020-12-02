class CreateGroupContactRelationships < ActiveRecord::Migration[5.2]
  def change
    create_table :group_contact_relationships do |t|
      t.belongs_to :group, index: true, null: false
      t.belongs_to :contact, index: true, null: false
      t.timestamps
    end
    add_index :group_contact_relationships, [:group_id, :contact_id], unique: true
  end
end
