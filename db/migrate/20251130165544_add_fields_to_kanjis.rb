class AddFieldsToKanjis < ActiveRecord::Migration[8.0]
  def change
    # Add new fields
    add_column :kanjis, :hanzi, :string, limit: 100
    add_column :kanjis, :story, :text
    add_column :kanjis, :grade, :integer
    add_column :kanjis, :taught_in, :string, limit: 20
    add_column :kanjis, :newspaper_frequency_rank, :integer
    add_column :kanjis, :meaning, :text
    add_column :kanjis, :radical_symbol, :string, limit: 10
    add_column :kanjis, :radical_meaning, :text
    add_column :kanjis, :stroke_order_diagram_uri, :text
    add_column :kanjis, :stroke_order_svg_uri, :text
    add_column :kanjis, :stroke_order_gif_uri, :text
    add_column :kanjis, :jisho_uri, :text
    add_column :kanjis, :kodansha_ref, :string, limit: 20
    add_column :kanjis, :classic_nelson_ref, :string, limit: 20

    # Add indexes
    add_index :kanjis, :grade
    add_index :kanjis, :newspaper_frequency_rank

    # Remove sino_vietnamese if you want to replace it with hanzi
    # remove_column :kanjis, :sino_vietnamese
  end
end
