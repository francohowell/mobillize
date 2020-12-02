class ChangeContactIdToBeBigintInResponses < ActiveRecord::Migration[5.2]
  def change
    change_column :responses, :contact_id, :bigint
  end
end
