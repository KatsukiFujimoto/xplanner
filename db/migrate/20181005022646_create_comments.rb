class CreateComments < ActiveRecord::Migration[5.1]
  def change
    create_table :comments do |t|
      t.references :commentable, polymorphic: true
      t.text :content
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
