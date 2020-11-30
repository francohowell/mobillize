class AddContactNumberToBlastContactRelationship < ActiveRecord::Migration[5.2]
  def change
    add_column :blast_contact_relationships, :contact_number, :string, null: false, default: "15555555555"
  end
end
