class CreatePlans < ActiveRecord::Migration[5.2]
  def change
    create_table :plans do |t|
      t.string :name, null: false
      t.string :tag_line, null: false
      t.string :description, null: false
      t.string :icon, null: false
      t.integer :messages_included, null: false
      t.integer :keywords_included, null: false
      t.integer :data_included, null: false
      t.float :monthly_price, null: false
      t.float :additional_message_cost, null: false
      t.float :additional_keyword_cost, null: false
      t.boolean :active, null: false, default: true
      t.datetime :inactive_date
      t.boolean :private, null: false, default: false
      t.boolean :long_code, null: false, default: true
      t.timestamps
    end
    
    add_index :plans, :name, unique: true

  end
end
