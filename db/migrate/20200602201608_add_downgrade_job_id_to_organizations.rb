class AddDowngradeJobIdToOrganizations < ActiveRecord::Migration[5.2]
  def change
    add_column :organizations, :downgrade_job_id, :string
  end
end
