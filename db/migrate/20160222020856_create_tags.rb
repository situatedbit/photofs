class CreateTags < ActiveRecord::Migration
  def change
    create_table :tags do |t|
      t.string :name

      t.timestamps null: false
    end

    create_join_table :tags, :images, table_name: :tag_bindings do |t|
      t.timestamps null: false
    end
  end
end
