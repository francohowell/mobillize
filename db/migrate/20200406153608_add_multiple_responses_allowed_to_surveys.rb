class AddMultipleResponsesAllowedToSurveys < ActiveRecord::Migration[5.2]
  def change
    add_column :surveys, :multiple_responses_allowed, :boolean, default: false, null: false
  end
end
