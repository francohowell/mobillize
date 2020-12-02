class CreateBlastContactRelationships < ActiveRecord::Migration[5.2]
  def change
    create_table :blast_contact_relationships do |t|
      t.string :status, null: false, default: "Pending"
      t.integer :contact_id, null: false
      t.belongs_to :blast, null: false 

      t.timestamps
    end
  end
end
