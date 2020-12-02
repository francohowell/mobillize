class AddPreloadToSurveys < ActiveRecord::Migration[5.2]
  def change
    add_column :surveys, :preload, :boolean, :default => false
  end
end
