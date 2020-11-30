class ModifyRangeMaxFromSurveyQuestions < ActiveRecord::Migration[5.2]
  def change
    rename_column :survey_questions, :range_max, :max_range
    change_column :survey_questions, :max_range, :string
  end
end
