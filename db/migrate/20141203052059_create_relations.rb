class CreateRelations < ActiveRecord::Migration
  def change
    create_table :relations do |t|
      t.integer 	:user_id
      t.integer		:friend_id
      t.integer		:status
      t.string		:alias_name

      t.timestamps
    end
    add_index	:relations, :user_id
    add_index	:relations, :friend_id
    add_index	:relations,	[:user_id, :friend_id], unique: true
  end
end
