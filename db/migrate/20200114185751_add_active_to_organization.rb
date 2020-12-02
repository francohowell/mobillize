class AddActiveToOrganization < ActiveRecord::Migration[5.2]
  def change
    add_column :organizations, :active, :boolean, null: false, default: true
    add_column :organizations, :inactive_date, :datetime
  end
end
