class ChangeNullAnswerOnSurveyAnswer < ActiveRecord::Migration[5.2]
  def change
    change_column :survey_answers, :answer, :string, null: true
  end
end
