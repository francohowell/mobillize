class RemoveHighRatingTitleFromSurveyQuestions < ActiveRecord::Migration[5.2]
  def change
    remove_column :survey_questions, :high_rating_title, :string
  end
end
