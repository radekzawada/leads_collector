class AddUniqueIndexToLeadsPostUrl < ActiveRecord::Migration[8.0]
  def change
    add_index :leads, :post_url, unique: true, where: "post_url IS NOT NULL AND post_url <> ''"
  end
end
