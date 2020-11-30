class CreateUserNotificationRelationships < ActiveRecord::Migration[5.2]
  def change
    create_table :user_notification_relationships do |t|
      t.boolean :acceptance, null: false, default: false
      t.belongs_to :user, null: false, index: true
      t.belongs_to :notification, null: false, index: true

      t.timestamps
    end
  end
end
