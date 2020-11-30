class SurveyQuestion < ApplicationRecord

    # Relationships
    belongs_to :survey
    has_many :survey_multiple_choices, dependent: :destroy
    has_many :survey_answers

    # Validations
    validates :question, presence: true, length: { minimum: 2 }
    validates :question_type, presence: true
    validates :survey_id, presence: true
		validates :min_range, :max_range, :presence => true, length: { minimum: 2 }, :if => :is_rating?

    # Methods

    def question_type_text
        categories = ["Short Answer", "Yes/No", "Drop Down", "Rating", "Number", "Date", "Address", "Phone Number", "Signature"]
        type = categories[self.question_type]
        return type
    end

    def format_validation
        # returns validation question ids with question format
        validation = self.validation_array

        if !validation.nil?
          validation = validation.split(',').map do |v|
            if v[0..2] == 'id:'
              question_id = v[3..v.length-1]
              question = SurveyQuestion.find_by_id(question_id).question.gsub(",","")
              question = question.length > 28 ? "#{question[0..25]}..." : question
              v = "(id:#{question_id}) #{question}"
            end
            v
          end.join(',')
          validation
        end
        validation
    end

    def is_rating?
        return self.question_type == 3 ? true : false
    end

    def is_yes_no?
        return self.question_type == 1 ? true : false
    end

    def is_mc?
        return self.question_type == 2 ? true : false
    end

    def is_text?
        return self.question_type == 0 ? true : false
    end

    def is_number?
        return self.question_type == 4 ? true : false
    end

    def is_date?
        return self.question_type == 5 ? true : false
    end

    def is_location?
        return self.question_type == 6 ? true : false
    end

    def is_phone_number?
        return self.question_type == 7 ? true : false
    end

    def is_signature?
        return self.question_type == 8 ? true : false
    end

    def rating_average
        if is_rating?
            cumulative_rating = 0
            for survey_answer in self.survey_answers.pluck(:answer)
                cumulative_rating += survey_answer.to_i
            end
            if self.survey_answers.count > 0
                return (cumulative_rating / self.survey_answers.count).round(2)
            else
                return 0
            end
        else
            return nil
        end
    end

    def yes_no_result
        if is_yes_no?
            yes = self.survey_answers.where(answer: "yes").count
            no = self.survey_answers.count - yes
            return [yes, no]
        else
            return nil
        end
    end

    def mc_result
        if is_mc?
            result_hash = Hash.new
            # Set The Other Option
            result_hash["Other"] = 0
            for mc_choice in self.survey_multiple_choices
                result_hash["#{mc_choice.id}"] = self.survey_answers.where(answer: mc_choice.id).count
            end
            result_hash["Other"] = self.survey_answers.where.not(answer: self.survey_multiple_choices.ids).count
            puts "Setting Hash: #{result_hash}"
            # for survey_answer in self.survey_answers
            #     if result_hash.key?(survey_answer.answer)
            #         if result_hash[survey_answer.answer]
            #             result_hash[survey_answer.answer] = result_hash[survey_answer.answer] + 1
            #         else
            #             result_hash[survey_answer.answer] = 1
            #         end
            #     else
            #         result_hash["Other"] = result_hash["Other"] + 1
            #     end
            # end
            return result_hash
        else
            return nil
        end
    end

    def mc_labels
        if is_mc?
            choice_items = ["Other"]
            choice_items += self.survey_multiple_choices.pluck("choice_item")
            return choice_items
        else
            return nil
        end
    end

    def text_result
        if is_text?
            return self.survey_answers.pluck[:answer]
        else
            return nil
        end
    end

    def check_validations(answer_json)
        puts "Answer JSON: #{answer_json}"
        puts "SELF VALIDATION: #{self.validation_array}"
        if !self.validation_array.nil? && !self.validation_array.empty?
            new_validation_array = []
            for validation_item in self.validation_array
                if validation_item.match("Id:")
                    item_split = validation_item.split(" - ")
                    question_id = item_split[0]
                    question_id = question_id.gsub("Id: ", "")
                    question_type = SurveyQuestion.find_by_id(question_id).question_type
                    puts "Gathering Answer: #{answer_json[question_id]}"
                    if answer_json[question_id] =~ /.*[a-zA-Z].*/
                        new_validation_array.push("'#{answer_json[question_id]}'")
                    elsif question_type == 2
                        answer = SurveyMultipleChoice.find_by_id(answer_json[question_id]).choice_item
                        new_validation_array.push("'#{answer}'")
                    else
                        new_validation_array.push(answer_json[question_id])
                    end
                else
                    # Check for the operators 
                    case validation_item
                    when "="
                        new_validation_array.push("==")
                    when "not ="
                        new_validation_array.push("!=")
                    when '<', '>', '>=', '<=', '+', '-', '*', '/'
                        new_validation_array.push(validation_item)
                    when "AND"
                        new_validation_array.push("&&")
                    when "OR"
                        new_validation_array.push("||")
                    else
                        if validation_item =~ /.*[a-zA-Z].*/
                            new_validation_array.push("'#{validation_item}'")
                        else
                            new_validation_array.push(validation_item)
                        end
                    end
                end
            end

            puts "======> Evaluation Array: #{new_validation_array}"
            
            eval_results = eval(new_validation_array.join(' '))

            puts "Evaluation Value: #{eval_results}"
            
            return eval_results
        else
            return true
        end
    end

    def find_answer(contact_id)
        response = SurveyResponse.where(survey: self.survey_id, contact_id: contact_id).last
        answer = SurveyAnswer.find_by(survey_question: self.id, survey_response: response)
        if !answer || contact_id == "0"
            return nil
        end
        self.question_type == 2 || self.question_type == 4 ? answer.answer.to_i : answer.answer
    end

    def self.search_terms(search)
        self.where("lower(question) like ?", "%#{search.downcase}%")
    end

    def validate_date_string
        min_date = Date.strptime(self.min_range, '%m/%d/%Y') rescue false
        max_date = Date.strptime(self.max_range, '%m/%d/%Y') rescue false
        if !self.min_range.empty? && min_date == false 
            errors[:base] << "Invalid Date."
            return false
        end
        if !self.max_range.empty? && max_date == false 
            errors[:base] << "Invalid Date." 
            return false
        end
        if !self.min_range.empty? && !self.max_range.empty? && min_date > max_date
            errors[:base] << "Invalid Date Range."
            return false
        end
        return true
    end
		
    def self.search_category(search)
        categories = ["Short Answer", "Yes/No", "Drop Down", "Rating", "Number", "Date", "Address", "Phone Number", "Signature"]
        category_num = categories.find_index(search)
        self.where("question_type" => category_num)
    end

end
