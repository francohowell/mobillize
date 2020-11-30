class DropAddOnGalleries < ActiveRecord::Migration[5.2]
  def change
    drop_table :add_on_galleries
  end
end
