class CreatePreparedFacePhotos < ActiveRecord::Migration
  def self.up
    create_table :prepared_face_photos do |t|
      t.string :name
      t.string :image
      t.integer :position
    end
    add_index :prepared_face_photos, :position, :unique => true
  end

  def self.down
    drop_table :prepared_face_photos
  end
end
