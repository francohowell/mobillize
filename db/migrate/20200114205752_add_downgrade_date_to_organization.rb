class AddDowngradeDateToOrganization < ActiveRecord::Migration[5.2]
  def change
    add_column :organizations, :downgrade_date, :datetime
  end
end
