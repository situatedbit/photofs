class AddFilePathToImages < ActiveRecord::Migration[5.1]
  def change
    add_column :images, :file_path, :string
  end
end
