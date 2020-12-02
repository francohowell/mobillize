class ApiAuthorization < ApplicationRecord
    belongs_to :organization

    # validates :key, presence: true

    # before_create :assign_key

    private

    # def assign_key
    #     generated_key = rand(36**256).to_s(36)
    #     while(ApiAuthorization.find_by_key(generated_key))
    #         generated_key = rand(36**256).to_s(36)
    #     end
    #
    #     self.key = generated_key
    # end
end
