class AddLongCodeToPhoneNumber < ActiveRecord::Migration[5.2]
  def change
    add_column :phone_numbers, :long_code, :boolean
  end
end
