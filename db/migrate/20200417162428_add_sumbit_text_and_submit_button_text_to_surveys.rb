class AddSumbitTextAndSubmitButtonTextToSurveys < ActiveRecord::Migration[5.2]
  def change
    add_column :surveys, :submit_button_text, :string
    add_column :surveys, :submit_text, :text
  end
end
