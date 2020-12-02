class CreateSurveyAnswers < ActiveRecord::Migration[5.2]
  def change
    create_table :survey_answers do |t|
      t.string :answer, null: false 
      t.belongs_to :survey_response
      t.belongs_to :survey_question

      t.timestamps
    end
  end
end
