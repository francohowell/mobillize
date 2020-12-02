class CreateTerms < ActiveRecord::Migration[5.2]
  def change
    create_table :terms do |t|
      t.string :title, null: false
      t.string :sub_title, null: false
      t.text :content, null: false
      t.datetime :publication_date, null: false

      t.timestamps
    end
  end
end
