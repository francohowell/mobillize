class ChangeSendDateTimeOnBlasts < ActiveRecord::Migration[5.2]
  def change
    change_column :blasts, :send_date_time, :datetime, null: false
  end
end
