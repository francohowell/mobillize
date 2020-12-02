class ColumnChangesForOrganization < ActiveRecord::Migration[5.2]
  def change
    rename_column :organizations, :organization_name, :name  # √√
    rename_column :organizations, :organization_city, :city # √√
    rename_column :organizations, :organization_country, :country # √√
    rename_column :organizations, :organization_industry, :industry # √√
    rename_column :organizations, :organization_logo, :logo # √√
    rename_column :organizations, :organization_postal_code, :postal_code # √√
    rename_column :organizations, :organization_size, :size # √√
    rename_column :organizations, :organization_state_providence, :state_providence # √√
    rename_column :organizations, :organization_street, :street # √√
    rename_column :organizations, :organization_street2, :street2 # √√


    remove_column :organizations, :organization_active
  end
end
