class CreateSurveyResponses < ActiveRecord::Migration[5.2]
  def change
    create_table :survey_responses do |t|
      t.belongs_to :survey, foreign_key: true
      t.bigint :contact_id, null: false 
      t.string :contact_number, null: false 
      
      t.timestamps
    end
  end
end
