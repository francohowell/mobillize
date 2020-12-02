class AddPermissionToTextToContactUploads < ActiveRecord::Migration[5.2]
  def change
    add_column :contact_uploads, :permission_to_text, :boolean, default: false
  end
end
