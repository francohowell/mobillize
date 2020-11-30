class CreateOrganizations < ActiveRecord::Migration[5.2]
  def change
    create_table :organizations do |t|
      t.string :organization_name, null: false
      t.string :organization_street
      t.string :organization_street2
      t.string :organization_city
      t.string :organization_state_providence
      t.string :organization_country
      t.string :organization_postal_code
      t.string :organization_logo
      t.boolean :organization_active, null: false, default: true
      t.string :organization_industry, null: false 
      t.string :organization_size, null: false 
      t.integer :additional_messages, null: false, default: 0
      t.integer :additional_keywords, null: false, default: 0
      t.belongs_to :plan, null: false, index: true
      
      t.timestamps
    end
  end
end
