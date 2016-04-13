class AddFilePathIndex < ActiveRecord::Migration
  def change
    add_index :files, :path
  end
end
