class AddRangeMaxToSurveyQuestions < ActiveRecord::Migration[5.2]
  def change
    add_column :survey_questions, :range_max, :integer
  end
end
