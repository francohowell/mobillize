class AddCompletedToSurveyResponseQueueRelationship < ActiveRecord::Migration[5.2]
  def change
    add_column :survey_response_queue_relationships, :completed, :boolean, :default => false
  end
end
