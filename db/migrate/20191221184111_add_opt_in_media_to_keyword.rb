class AddOptInMediaToKeyword < ActiveRecord::Migration[5.2]
  def change
    add_column :keywords, :opt_in_media, :string
  end
end
