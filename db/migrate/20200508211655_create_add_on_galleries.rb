class CreateAddOnGalleries < ActiveRecord::Migration[5.2]
  def change
    create_table :add_on_galleries do |t|
      t.string :item, null: false
      t.belongs_to :add_on, null: false
      t.timestamps
    end
  end
end
