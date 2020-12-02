class RemoveStateProvidenceFromUser < ActiveRecord::Migration[5.2]
  def change
    remove_column :users, :state_providence, :string
  end
end
