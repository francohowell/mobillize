class AddDynamicsToContacts < ActiveRecord::Migration[5.2]
  def change
    add_column :contacts, :dynamics, :jsonb, null: false, default: '{}'

    add_index  :contacts, :dynamics, using: :gin
  end
end
