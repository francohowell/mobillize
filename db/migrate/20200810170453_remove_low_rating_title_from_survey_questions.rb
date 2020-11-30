class RemoveLowRatingTitleFromSurveyQuestions < ActiveRecord::Migration[5.2]
  def change
    remove_column :survey_questions, :low_rating_title, :string
  end
end
