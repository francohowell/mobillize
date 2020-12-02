class CreateSurveyQuestions < ActiveRecord::Migration[5.2]
  def change
    create_table :survey_questions do |t|
      t.string :question, null: false 
      t.integer :question_type, null: false, default: 0 
      t.integer :question_order, null: false
      t.belongs_to :survey 

      t.timestamps
    end
  end
end
