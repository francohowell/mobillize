class CreateUserTermRelationships < ActiveRecord::Migration[5.2]
  def change
    create_table :user_term_relationships do |t|
      t.belongs_to :user, null: false, index: true
      t.belongs_to :term, null: false, index: true
      t.datetime :acceptance_date, null: false

      t.timestamps
    end
  end
end
