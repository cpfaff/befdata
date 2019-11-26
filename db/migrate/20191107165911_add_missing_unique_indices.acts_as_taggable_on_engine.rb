# This migration comes from acts_as_taggable_on_engine (originally 2)
class AddMissingUniqueIndices < ActiveRecord::Migration
  def self.up
    unless index_exists? :tags, :name, unique: true
      add_index :tags, :name, unique: true
    end

    if index_exists? :taggings, :tag_id
      remove_index :taggings, :tag_id
    end

    if index_exists? :taggings, [:taggable_id, :taggable_type, :context]
      remove_index :taggings, [:taggable_id, :taggable_type, :context]
    end

    unless index_exists? :taggings, [:tag_id, :taggable_id, :taggable_type, :context, :tagger_id, :tagger_type], unique: true, name: 'taggings_idx'
    add_index :taggings,
              [:tag_id, :taggable_id, :taggable_type, :context, :tagger_id, :tagger_type],
              unique: true, name: 'taggings_idx'
    end
  end

  def self.down
    remove_index :tags, :name

    remove_index :taggings, name: 'taggings_idx'
    add_index :taggings, :tag_id
    add_index :taggings, [:taggable_id, :taggable_type, :context]
  end
end
