class AddJobIdToBlast < ActiveRecord::Migration[5.2]
  def change
    add_column :blasts, :job_id, :string, unique: true
  end
end
