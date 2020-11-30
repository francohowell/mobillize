class AddArchiveToSurveyQuestions < ActiveRecord::Migration[5.2]
  def change
    add_column :survey_questions, :archive, :boolean, :default => false
  end
end
