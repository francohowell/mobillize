class CreateBlasts < ActiveRecord::Migration[5.2]
  def change
    create_table :blasts do |t|
      t.text :message, null: false 
      t.boolean :active, null: false, default: true 
      t.string :repeat
      t.date :repeat_end_date
      t.datetime :send_date_time
      t.boolean :sms, null: false, default: false 
      t.integer :keyword_id, null: false
      t.string :keyword_name, null: false
      t.belongs_to :organization, null: false 
      t.integer :user_id, null: false

      t.timestamps
    end
  end
end
