class AddRangeMinToSurveyQuestions < ActiveRecord::Migration[5.2]
  def change
    add_column :survey_questions, :range_min, :integer
  end
end
