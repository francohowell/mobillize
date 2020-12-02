class AddConfirmAnswerToSurveyQuestions < ActiveRecord::Migration[5.2]
  def change
    add_column :survey_questions, :confirm_answer, :boolean, :default => false
  end
end
