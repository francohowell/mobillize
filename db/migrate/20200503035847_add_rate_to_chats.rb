class AddRateToChats < ActiveRecord::Migration[5.2]
  def change
    add_column :chats, :rate, :integer, null: false, default: 1
  end
end
