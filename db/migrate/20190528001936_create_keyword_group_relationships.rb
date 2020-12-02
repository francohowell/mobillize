class CreateKeywordGroupRelationships < ActiveRecord::Migration[5.2]
  def change
    create_table :keyword_group_relationships do |t|
      t.belongs_to :keyword, index: true, null: false
      t.belongs_to :group, index: true, null: false

      t.timestamps
    end

    add_index :keyword_group_relationships, [:keyword_id, :group_id], unique: true

  end
end
