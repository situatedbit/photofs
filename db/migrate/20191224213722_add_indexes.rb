class AddIndexes < ActiveRecord::Migration[5.1]
  def change
    add_index :images, :path
    add_index :tag_bindings, :image_id
    add_index :tag_bindings, :tag_id
  end
end
