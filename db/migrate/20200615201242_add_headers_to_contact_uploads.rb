class AddHeadersToContactUploads < ActiveRecord::Migration[5.2]
  def change
    add_column :contact_uploads, :headers, :text
  end
end
