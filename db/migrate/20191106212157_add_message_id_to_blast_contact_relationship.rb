class AddMessageIdToBlastContactRelationship < ActiveRecord::Migration[5.2]
  def change
    add_column :blast_contact_relationships, :message_id, :string
  end
end
