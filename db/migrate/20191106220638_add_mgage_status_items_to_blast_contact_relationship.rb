class AddMgageStatusItemsToBlastContactRelationship < ActiveRecord::Migration[5.2]
  def change
    add_column :blast_contact_relationships, :mgage_status, :string
    add_column :blast_contact_relationships, :mgage_status_code, :string
  end
end
