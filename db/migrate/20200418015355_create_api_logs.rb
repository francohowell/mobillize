class CreateApiLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :api_logs do |t|
      t.string :api_method
      t.string :request
      t.text :header
      t.text :params
      t.string :error_source
      t.text :error

      t.timestamps
    end
  end
end
