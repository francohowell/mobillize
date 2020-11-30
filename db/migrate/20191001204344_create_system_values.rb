class CreateSystemValues < ActiveRecord::Migration[5.2]
  def change
    create_table :system_values do |t|
      t.string :key, null: false, unique: true
      t.string :value, null: false

      t.timestamps
    end
  end
end
