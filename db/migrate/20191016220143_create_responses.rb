class CreateResponses < ActiveRecord::Migration[5.2]
  def change
    create_table :responses do |t|
      t.string :cell_phone
      t.integer :contact_id
      t.string :keyword
      t.boolean :opt_out
      t.string :message_type
      t.text :message
      t.string :message_id
      t.string :sub_id

      t.timestamps
    end
  end
end
