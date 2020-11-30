class AddSurveyReservedToKeyword < ActiveRecord::Migration[5.2]
  def change
    add_column :keywords, :survey_reserved, :boolean, null: false, default: false
  end
end
