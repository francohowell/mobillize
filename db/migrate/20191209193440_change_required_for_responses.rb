class ChangeRequiredForResponses < ActiveRecord::Migration[5.2]
  def change
    change_column :responses, :contact_id, :bigint, null: false, default: 0
    change_column_null :responses, :cell_phone, false
    change_column_null :responses, :message_type, false
    change_column_null :responses, :message, false
    change_column_null :responses, :message_id, false
    change_column :responses, :opt_out, :boolean, null: false, default: false
  end
end
