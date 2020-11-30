class AddCustomerNotesToOrganization < ActiveRecord::Migration[5.2]
  def change
    add_column :organizations, :notes, :text
  end
end
