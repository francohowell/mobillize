class CreateGroups < ActiveRecord::Migration[5.2]
  def change
    create_table :groups do |t|
      t.string :name, null: false
      t.string :description
      t.belongs_to :organization, null: false, index: true
      t.integer :user_id, null: false, index: true
      t.timestamps
    end
  end
end
