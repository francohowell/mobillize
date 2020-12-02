class CreateCustomQueues < ActiveRecord::Migration[5.2]
  def change
    create_table :custom_queues do |t|
      t.string :name,  null: false
      t.text :description
      t.date :start_date
      t.time :start_time
      t.date :end_date
      t.time :end_time
      t.integer :capacity
      t.boolean :adjust_capacity_on_completion
      t.references :organization, foreign_key: true

      t.timestamps
    end
  end
end
