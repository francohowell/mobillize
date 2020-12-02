class AddCarrierToContacts < ActiveRecord::Migration[5.2]
  def change
    add_column :contacts, :carrier, :string
  end
end
