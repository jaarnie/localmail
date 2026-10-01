class CreateLocalmailMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :localmail_messages do |t|
      t.string :key, null: false, index: { unique: true }
      t.binary :raw, null: false, limit: 16.megabytes - 1
      t.datetime :created_at, null: false, index: true
    end
  end
end
