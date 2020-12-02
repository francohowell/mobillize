class CreatePhoneNumbers < ActiveRecord::Migration[5.2]
  def change
    create_table :phone_numbers do |t|
      t.string :pretty, null: false 
      t.string :real, null: false, unique: true
      t.string :service_id, null: false
      t.boolean :global, null: false, default: false
      t.boolean :demo, null: false, default: false
      t.timestamps
    end
  end
end
