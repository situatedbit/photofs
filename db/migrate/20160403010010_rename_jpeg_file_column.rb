class RenameJpegFileColumn < ActiveRecord::Migration
  def change
    rename_column :images, :jpeg_file_id, :image_file_id
  end
end
