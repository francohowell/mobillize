class AddAdvancedValidationToSurveyQuestions < ActiveRecord::Migration[5.2]
  def change
    add_column :survey_questions, :advanced_validation, :jsonb
  end
end
