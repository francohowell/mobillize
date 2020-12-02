class CreateContacts < ActiveRecord::Migration[5.2]
  def change
    create_table :contacts do |t|
      t.string :first_name
      t.string :last_name
      t.string :primary_email
      t.string :secondary_email
      t.string :cell_phone, null: false 
      t.boolean :active
      t.string :company_name
      t.belongs_to :organization, null: false, index: true 
      t.integer :user_id, null: false, default: 0 

      t.timestamps
    end
    add_index :contacts, [:organization_id, :cell_phone], unique: true
  end
end
