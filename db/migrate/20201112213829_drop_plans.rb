class DropPlans < ActiveRecord::Migration[5.2]
  def up
    drop_table :plans
  end
  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
