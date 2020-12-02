class CreateDirectMessageMedia < ActiveRecord::Migration[5.2]
  def change
    create_table :direct_message_media do |t|
      t.integer :media_number, null: false
      t.string :media_url, null: false
      t.belongs_to :direct_message, null: false

      t.timestamps
    end
  end
end
