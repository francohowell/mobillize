class CreateBlastAttachments < ActiveRecord::Migration[5.2]
  def change
    create_table :blast_attachments do |t|
      t.string :attachment, null: false
      t.belongs_to :blast, null: false 

      t.timestamps
    end
  end
end
