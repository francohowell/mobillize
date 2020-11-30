class Survey < ApplicationRecord

    # Relationships
    belongs_to :organization
    has_many :survey_questions, dependent: :destroy
    has_many :survey_responses, dependent: :destroy
    has_many :survey_answers, through: :survey_responses
    has_many :keyword_survey_relationships, dependent: :destroy
    has_many :keywords, through: :keyword_survey_relationships
    has_many :survey_queue_relationships, dependent: :destroy
    has_many :custom_queues, through: :survey_queue_relationships

    # Validations
    validates :name, presence: true, length: { minimum: 5 }
    validates :start_message, presence: true, length: { minimum: 5, maximum: 280 }
    validates :completion_message, presence: true, length: { minimum: 5 }
    validates :organization_id, presence: true
    validates :start_date_time, presence: true
    validates :end_date_time, presence: true
    validate :valid_start?
    validate :valid_end?
    validates :submit_button_text, length: { minimum: 5, maximum: 25 }, allow_blank: true

    # Methods

    def is_active?
        current_date_time = DateTime.now
        if current_date_time >= self.start_date_time && current_date_time <= self.end_date_time
            return true
        else
            return false
        end
    end

    def created_today?
        current_date_time = DateTime.now
        if current_date_time.to_date == self.created_at.to_date
            return true
        end
        return false
    end

    def response_csv
        csv_file = CSV.generate do |csv|
            header = ["Response Id", "Contact Id", "Contact Number", "Created At"]
            if self.ordered_questions
                survey_questions = self.survey_questions.order(:order).map do |q|
                  c = q.archive ? " (Hidden/Archived)" : ""
                  q.question + c
                end
                header = header + survey_questions
                ordered_questions = self.survey_questions.order(:order)
            else
                survey_questions = self.survey_questions.map do |q|
                  c = q.archive ? " (Hidden/Archived)" : ""
                  q.question + c
                end
                header = header + survey_questions
                ordered_questions = self.survey_questions.order(:id)
            end
            csv << header

            self.survey_responses.each do |resp|
                row = [resp.id, resp.contact_id, resp.contact_number, resp.created_at.in_time_zone(self.organization.timezone)]
                ordered_questions = self.survey_questions.order(:order)
                for question in ordered_questions
                    answer = resp.survey_answers.find_by(survey_question_id: question.id)
                    if answer
                        if question.is_mc?
                            if question.survey_multiple_choices.find_by_id(answer.answer)
                                row.push(question.survey_multiple_choices.find_by_id(answer.answer).choice_item)
                            else
                                row.push(answer.answer)
                            end
                        else
                            row.push(answer.answer)
                        end
                    else
                        row.push("")
                    end
                end
                csv << row
            end
        end
        return csv_file
    end

    def paginate_csv_results(paginate_value)
        csv_file = CSV.generate do |csv|

            paginate_value = (paginate_value - 1) * 20
            if paginate_value == 0
                header = ["Response Id", "Contact Id", "Contact Number", "Created At"]
                if self.ordered_questions
                    header = header + self.survey_questions.order(:order).pluck("question")
                    ordered_questions = self.survey_questions.order(:order)
                else
                    header = header + self.survey_questions.pluck("question")
                    ordered_questions = self.survey_questions.order(:id)
                end
                csv << header
            end

            response_array = self.survey_responses.order(:id).limit(20).offset(paginate_value)
            response_array.each do |resp|
                row = [resp.id, resp.contact_id, resp.contact_number, resp.created_at.in_time_zone(self.organization.timezone)]
                ordered_questions = self.survey_questions.order(:order)
                for question in ordered_questions
                    answer = resp.survey_answers.find_by(survey_question_id: question.id)
                    if answer
                        if question.is_mc?
                            if question.survey_multiple_choices.find_by_id(answer.answer)
                                row.push(question.survey_multiple_choices.find_by_id(answer.answer).choice_item)
                            else
                                row.push(answer.answer)
                            end
                        else
                            row.push(answer.answer)
                        end
                    else
                        row.push("")
                    end
                end
                csv << row
            end
        end
        return csv_file
    end

    private

    def valid_start?
        if self.start_date_time >= Time.now
            return true
        else
            return false
        end
    end

    def valid_end?
        if self.end_date_time >= Time.now
            if self.end_date_time > self.start_date_time
                return true
            else
                return false
            end
        else
            return false
        end
    end


end
