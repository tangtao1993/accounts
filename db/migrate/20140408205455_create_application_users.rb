class CreateApplicationUsers < ActiveRecord::Migration
  def change
    create_table :application_users do |t|
      t.integer :application_id
      t.integer :user_id
      t.integer :default_contact_info_id

      t.timestamps
    end

    add_index :application_users, [:user_id, :application_id]
    add_index :application_users, [:application_id]
  end
end
