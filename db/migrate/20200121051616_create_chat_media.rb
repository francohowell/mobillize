class CreateChatMedia < ActiveRecord::Migration[5.2]
  def change
    create_table :chat_media do |t|
      t.integer :media_number, null: false
      t.string :media_url, null: false
      t.belongs_to :chat, null: false

      t.timestamps
    end
  end
end
