class CreateContactUploads < ActiveRecord::Migration[5.2]
  def change
    create_table :contact_uploads do |t|
      t.string :file, null: false
      t.belongs_to :user
      t.belongs_to :organization

      t.timestamps
    end
  end
end
