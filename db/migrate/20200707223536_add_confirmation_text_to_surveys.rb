class AddConfirmationTextToSurveys < ActiveRecord::Migration[5.2]
  def change
    add_column :surveys, :confirmation_text, :text, :default => nil
  end
end
