class CreateSurveyResponseQueueRelationships < ActiveRecord::Migration[5.2]
  def change
    create_table :survey_response_queue_relationships do |t|
      t.references :survey_response, foreign_key: true
      t.references :custom_queue, foreign_key: true
      
      t.timestamps
    end
  end
end
