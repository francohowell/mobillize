class AddOrderedQuestionsToSurveys < ActiveRecord::Migration[5.2]
  def change
    add_column :surveys, :ordered_questions, :boolean, default: false, null: false
  end
end
