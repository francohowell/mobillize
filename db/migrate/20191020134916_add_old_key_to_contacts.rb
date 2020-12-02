class AddOldKeyToContacts < ActiveRecord::Migration[5.2]
  def change
    add_column :contacts, :old_key, :string, unique: true
  end
end
