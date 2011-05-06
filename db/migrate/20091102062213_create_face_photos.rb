class CreateFacePhotos < ActiveRecord::Migration
  def self.up
    create_table :face_photos do |t|
      t.string :image

      t.timestamps
    end
  end

  def self.down
    drop_table :face_photos
  end
end
