class AddCanSendBlastsToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :can_send_blasts, :boolean, null: false, default: false
  end
end
