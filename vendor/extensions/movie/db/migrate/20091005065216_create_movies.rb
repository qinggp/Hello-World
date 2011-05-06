class CreateMovies < ActiveRecord::Migration
  def self.up
    create_table(:movies)do |t|
      t.column(:user_id, :integer)
      t.column(:title, :string)
      t.column(:body, :text)
      t.column(:created_at, :datetime)
      t.column(:visibility, :integer)
      t.column(:start_date, :date)
      t.column(:end_date, :date)
      t.column(:convert_status, :integer)
      t.column(:longitude, :string)
      t.column(:latitude, :string)
      t.column(:zoom, :integer)

      t.timestamps
    end
  end

  def self.down
    drop_table(:movies)
  end
end
