class AddDetailToSurveyQuestion < ActiveRecord::Migration[5.2]
  def change
    add_column :survey_questions, :detail, :text
  end
end
