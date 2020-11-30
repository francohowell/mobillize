class AddValidationArrayToSurveyQuestions < ActiveRecord::Migration[5.2]
  def change
    add_column :survey_questions, :validation_array, :text,  array: true, default: []
  end
end
