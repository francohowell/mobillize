class CreateDirectMessages < ActiveRecord::Migration[5.2]
  def change
    create_table :direct_messages do |t|
      t.boolean :media, null: false, default: false
      t.text :message, null: false
      t.string :to, null: false
      t.string :from, null: false 
      t.string :message_id, null: false 
      t.belongs_to :organization_contact_relationship, null: false

      t.timestamps
    end
  end
end
