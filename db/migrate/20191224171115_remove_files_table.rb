class RemoveFilesTable < ActiveRecord::Migration[5.1]
  def change
    drop_table :files
    rename_column :images, :file_path, :path
  end
end
