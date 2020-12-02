class CreateKeywords < ActiveRecord::Migration[5.2]
  def change
    create_table :keywords do |t|
      t.string :name, null: false
      t.string :help_text
      t.string :invitation_text
      t.string :description
      t.string :opt_in_text
      t.string :opt_out_text
      t.boolean :active, null: false, default: true
      t.belongs_to :organization, null: false, index: true
      t.integer :user_id, null: false, index: true

      t.timestamps
    end
    add_index :keywords, :name, unique: true

  end
end
