class CreateChats < ActiveRecord::Migration[5.2]
  def change
    create_table :chats do |t|
      t.string :from, null: false
      t.string :to, null: false
      t.text :message, null: false
      t.string :message_id, null: false
      t.boolean :media, null: false, default: false
      t.bigint :contact_id
      t.belongs_to :organization, null: false
      
      t.timestamps
    end
  end
end
