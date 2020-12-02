class AddOldKeyToKeywords < ActiveRecord::Migration[5.2]
  def change
    add_column :keywords, :old_key, :string, unique: true
  end
end
