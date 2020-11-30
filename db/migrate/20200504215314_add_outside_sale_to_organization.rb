class AddOutsideSaleToOrganization < ActiveRecord::Migration[5.2]
  def change
    add_column :organizations, :outside_sale, :boolean, null: false, default: false
  end
end
