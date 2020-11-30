class AddPossibleOptOutToResponse < ActiveRecord::Migration[5.2]
  def change
    add_column :responses, :possible_opt_out, :boolean, null: false, default: false
  end
end
