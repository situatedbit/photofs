class CreateFiles < ActiveRecord::Migration[4.2]
  def change
    create_table :files do |t|
      t.string :path

      t.timestamps null: false
    end

    add_column :images, :jpeg_file_id, :integer
  end
end
