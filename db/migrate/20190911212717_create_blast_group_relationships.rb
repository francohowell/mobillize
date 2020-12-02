class CreateBlastGroupRelationships < ActiveRecord::Migration[5.2]
  def change
    create_table :blast_group_relationships do |t|
      t.belongs_to :blast, null: false 
      t.belongs_to :group, null: false

      t.timestamps
    end
  end
end
