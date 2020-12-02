class AddModuleDataToSurveys < ActiveRecord::Migration[5.2]
  def change
    add_column :surveys, :module_data, :jsonb, null: false, default: '{}'
    add_index  :surveys, :module_data, using: :gin
  end
end
