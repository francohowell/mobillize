class CreateSurveys < ActiveRecord::Migration[5.2]
  def change
    create_table :surveys do |t|
      t.string :name, null: false
      t.text :description
      t.datetime :start_date_time, null: false 
      t.datetime :end_date_time, null: false 
      t.string :stripe_id
      t.string :start_message, null: false
      t.string :completion_message, null: false
      t.bigint :keyword_id 
      t.string :keyword_name
      t.belongs_to :organization, null: false

      t.timestamps
    end
  end
end
