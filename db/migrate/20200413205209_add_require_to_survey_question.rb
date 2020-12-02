class AddRequireToSurveyQuestion < ActiveRecord::Migration[5.2]
  def change
    add_column :survey_questions, :required, :boolean, null: false, default: true
  end
end
