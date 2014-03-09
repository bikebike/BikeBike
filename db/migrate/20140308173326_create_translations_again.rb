class CreateTranslationsAgain < ActiveRecord::Migration
	def change
      create_table :translations do |t|
        t.string :locale
        t.string :key
        t.text   :value
        t.text   :interpolations
        t.boolean :is_proc, :default => false

        t.timestamps
      end
    end
end
