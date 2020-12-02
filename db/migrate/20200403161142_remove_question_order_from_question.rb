class RemoveQuestionOrderFromQuestion < ActiveRecord::Migration[5.2]
  def change
    remove_column :survey_questions, :question_order, :integer
  end
end
