class ChangeLongCodeInPhoneNumbers < ActiveRecord::Migration[5.2]
  def change
    change_column :phone_numbers, :long_code, :boolean, null: false, default: true
  end
end
