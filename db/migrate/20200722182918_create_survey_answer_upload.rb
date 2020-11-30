class CreateSurveyAnswerUpload < ActiveRecord::Migration[5.2]
  def change
    create_table :survey_answer_uploads do |t|
      t.string :file
      t.belongs_to :user
      t.belongs_to :organization

      t.timestamps
    end
  end
end
