class ModifyRangeMinFromSurveyQuestions < ActiveRecord::Migration[5.2]
  def change
    rename_column :survey_questions, :range_min, :min_range
    change_column :survey_questions, :min_range, :string
  end
end
