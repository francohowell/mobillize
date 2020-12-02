class AddInboundToChats < ActiveRecord::Migration[5.2]
  def change
    add_column :chats, :inbound, :boolean, null: false, default: false
    add_column :chats, :inbound_read, :boolean, null: false, default: false
  end
end
