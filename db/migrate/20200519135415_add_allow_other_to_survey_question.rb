class AddAllowOtherToSurveyQuestion < ActiveRecord::Migration[5.2]
  def change
    add_column :survey_questions, :allow_other, :boolean, null: false, default: false
  end
end
