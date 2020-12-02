class CreateOrganizationPlanRelationships < ActiveRecord::Migration[5.2]
  def change
    create_table :organization_plan_relationships do |t|
      t.belongs_to :organization, null: false, index: true
      t.belongs_to :plan, null: false, index: true
      t.boolean :monthly, null: false, default: true
      t.string :stripe_id
      
      t.timestamps
    end
  end
end
