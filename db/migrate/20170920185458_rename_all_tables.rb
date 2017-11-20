class RenameAllTables < ActiveRecord::Migration[5.1]
  def change
    rename_table :files, :photofs_image_files
    rename_table :images, :photofs_images
    rename_table :tag_bindings, :photofs_tag_bindings
    rename_table :tags, :photofs_tags
  end 
end


