class AddOldKeyToGroups < ActiveRecord::Migration[5.2]
  def change
    add_column :groups, :old_key, :string, unique: true
  end
end
