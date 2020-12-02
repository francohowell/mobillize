class AddOldKeyToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :old_key, :string, unique: true
  end
end
