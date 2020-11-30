class CreateKeywordSurveyRelationships < ActiveRecord::Migration[5.2]
  def change
    create_table :keyword_survey_relationships do |t|
      t.belongs_to :survey, foreign_key: true
      t.belongs_to :keyword, foreign_key: true

      t.timestamps
    end
  end
end
