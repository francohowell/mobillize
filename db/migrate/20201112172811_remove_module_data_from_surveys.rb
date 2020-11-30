class RemoveModuleDataFromSurveys < ActiveRecord::Migration[5.2]
  def change
    remove_column :surveys, :module_data, :jsonb
  end
end
