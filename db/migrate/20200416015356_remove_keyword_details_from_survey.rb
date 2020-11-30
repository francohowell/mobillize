class RemoveKeywordDetailsFromSurvey < ActiveRecord::Migration[5.2]
  def change
    remove_column :surveys, :keyword_id, :bigint
    remove_column :surveys, :keyword_name, :string
  end
end
