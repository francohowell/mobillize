class AddTimezoneToOrganization < ActiveRecord::Migration[5.2]
  def change
    add_column(:organizations, :timezone, :string, null: false)
  end
end
