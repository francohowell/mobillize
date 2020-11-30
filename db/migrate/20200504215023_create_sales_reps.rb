class CreateSalesReps < ActiveRecord::Migration[5.2]
  def change
    create_table :sales_reps do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email, null: false
      t.string :phone, null: false 

      t.timestamps
    end
  end
end
