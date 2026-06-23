class CreateLeads < ActiveRecord::Migration[8.0]
  def change
    create_table :leads do |t|
      t.string :source
      t.string :group_name
      t.string :post_url
      t.text :post_text, null: false
      t.datetime :posted_at
      t.boolean :is_lead, default: false, null: false
      t.date :date_from
      t.date :date_to
      t.integer :adults
      t.integer :children
      t.integer :guests_total
      t.string :location
      t.decimal :confidence, precision: 5, scale: 4
      t.string :availability_status, default: "unknown", null: false
      t.datetime :notification_sent_at
      t.jsonb :raw_extraction, default: {}, null: false

      t.timestamps
    end

    add_index :leads, :posted_at
  end
end
