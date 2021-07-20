class RemoveImageFileId < ActiveRecord::Migration[5.1]
  def change
    remove_column(:images, :image_file_id, type: :integer)
  end
end
