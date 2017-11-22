class RenameJpegFileColumn < ActiveRecord::Migration[4.2]
  def change
    rename_column :images, :jpeg_file_id, :image_file_id
  end
end
