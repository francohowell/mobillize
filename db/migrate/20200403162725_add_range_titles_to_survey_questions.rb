class AddRangeTitlesToSurveyQuestions < ActiveRecord::Migration[5.2]
  def change
    add_column :survey_questions, :low_rating_title, :string
    add_column :survey_questions, :high_rating_title, :string
  end
end
