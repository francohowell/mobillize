class CreateApiAuthorizations < ActiveRecord::Migration[5.2]
  def change
    create_table :api_authorizations do |t|
      t.string :key, null: false, unique: true
      t.belongs_to :organization, null: false 
      t.text :note
      t.string :auth_environment, null: false, default: "testing"
      
      t.timestamps
    end
  end
end
