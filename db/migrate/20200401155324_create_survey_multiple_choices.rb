class CreateSurveyMultipleChoices < ActiveRecord::Migration[5.2]
  def change
    create_table :survey_multiple_choices do |t|
      t.string :choice_item, null: false 
      t.belongs_to :survey_question

      t.timestamps
    end
  end
end
