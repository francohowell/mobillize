class AddShowTakeAgainOptionOnSurveys < ActiveRecord::Migration[5.2]
  def change
    add_column :surveys, :show_take_again, :boolean, null: false, default: false
  end
end
