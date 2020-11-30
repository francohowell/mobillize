# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
SurveyResponseQueueRelationship.destroy_all
SurveyResponse.destroy_all
SurveyQueueRelationship.destroy_all
CustomQueue.destroy_all
Survey.destroy_all
Contact.destroy_all
User.destroy_all
Organization.destroy_all
PhoneNumber.destroy_all
SystemValue.destroy_all
Term.destroy_all

t = Time.now.utc

# Terms
Term.create!(title: "Terms & Conditions", sub_title: "Welcome to Blueprint 108's Mobilize Comms", content: "This is our staging environment terms and conditions. The real terms and conditions can be found at mobilizecomms.com", publication_date: t)

picture = File.open(File.join(Rails.root,'app/assets/images/MUS_Plan_Sizes_Diamond.png'))
# Phone Numbers
PhoneNumber.create!(pretty: "+1 (606) 685 9517", real: "16066859517", service_id: "PNf09acbe679c2cba5ebedcf4363a7e220", global: true, demo: true )
PhoneNumber.create!(pretty: "66978", real: "66978", service_id: "mgage", global: true, demo: false, long_code: false)
# System Values
SystemValue.create!(key: "default_opt_in_text", value: "Thank you for opting in. You may text STOP at any time to end messages.")
SystemValue.create!(key: "default_opt_out_text", value: "You have been opted out. You will no longer receive messages from this number.")
SystemValue.create!(key: "default_help_text", value: "Please text in your help request to this number.")
SystemValue.create!(key: "additional_opt_out_text", value: "You can text STOP or END at any time to stop receiving messages.")
SystemValue.create!(key: "keyword_subscription_stripe_id", value: "plan_FzwXljU5ExfmQx")
# user and organizations
org = Organization.create!(name: "Mockingbird agency", industry: "hunger games", timezone: "UTC", size: 10, annual_credits: 1000, start_date: Time.now)
org.users.create!(first_name: "test", last_name: "test", cell_phone: "5555555555", email: "test@test.com", password: "testtest")
org.users.create!(first_name: "kyle", last_name: "corn", cell_phone: "5715943614", email: "kyle@mobilizeyourtech.com", password: "testtest")
org.users.create!(first_name: "rebecca", last_name: "schneider", cell_phone: "3037771883", email: "rebecca@mobilizeyourtech.com", password: "testtest")
org.users.create!(first_name: "ion", last_name: "gorincioi", cell_phone: "3054070772", email: "ion@mobilizeyourtech.com", password: "testtest")

# create contacts
10.times do |i|
  Contact.create!(cell_phone: "555555123#{i}", first_name: "Contact #{i}", organization: org)
end

# surveys (no questions)
5.times do |i|
  Survey.create!(
    name: "survey #{i}", description: nil, start_date_time: t, end_date_time: t, stripe_id: nil,
    start_message: "Take the survey...", completion_message: "Thanks for taking the survey!",
    organization_id: org.id, multiple_responses_allowed: true,
    submit_button_text: nil, submit_text: nil, ordered_questions: true,
    confirmation_text: nil, preload: false, show_take_again: true
  )
  
end

# create custom queues
28.times do |i|
  random_num = [*0..10].sample

  cq = CustomQueue.create!(
    name: "queue #{i}", start_date: t - random_num.day, start_time: t - random_num.day,
    end_date: t + random_num.day, end_time: t + random_num.day, capacity: 1000,
    adjust_capacity_on_completion: true, organization_id: org.id,
    created_at: t - random_num.day, updated_at: t
  )
  
  SurveyQueueRelationship.create!(custom_queue: cq, survey: Survey.all.sample)  
end

survey1 = Survey.all.sample
survey2 = Survey.all.sample
survey3 = Survey.all.sample
survey4 = Survey.all.sample
survey5 = Survey.all.sample
survey6 = Survey.all.sample
survey7 = Survey.all.sample
queue1 = survey1.custom_queues.sample
queue2 = survey2.custom_queues.sample
queue3 = survey3.custom_queues.sample
queue4 = survey4.custom_queues.sample
queue5 = survey5.custom_queues.sample
queue6 = survey6.custom_queues.sample
queue7 = survey7.custom_queues.sample

11.times do |i|
  contact1 = Contact.all.sample
  survey_res = SurveyResponse.create!(survey: survey1, contact_id: contact1.id, contact_number: contact1.cell_phone)
  
  # place response into queue
  SurveyResponseQueueRelationship.create!(survey_response: survey_res, custom_queue: queue1)
end

14.times do |i|
  contact2 = Contact.all.sample
  survey_res = SurveyResponse.create!(survey: survey2, contact_id: contact2.id, contact_number: contact2.cell_phone)

  # place response into queue
  SurveyResponseQueueRelationship.create!(survey_response: survey_res, custom_queue: queue2)
end

22.times do |i|
  contact3 = Contact.all.sample
  survey_res = SurveyResponse.create!(survey: survey3, contact_id: contact3.id, contact_number: contact3.cell_phone)

  # place response into queue
  SurveyResponseQueueRelationship.create!(survey_response: survey_res, custom_queue: queue3)
end

9.times do |i|
  contact4 = Contact.all.sample
  survey_res = SurveyResponse.create!(survey: survey4, contact_id: contact4.id, contact_number: contact4.cell_phone)

  # place response into queue
  SurveyResponseQueueRelationship.create!(survey_response: survey_res, custom_queue: queue4)
end

11.times do |i|
  contact5 = Contact.all.sample
  survey_res = SurveyResponse.create!(survey: survey5, contact_id: contact5.id, contact_number: contact5.cell_phone)

  # place response into queue
  SurveyResponseQueueRelationship.create!(survey_response: survey_res, custom_queue: queue5)
end

10.times do |i|
  contact6 = Contact.all.sample
  survey_res = SurveyResponse.create!(survey: survey6, contact_id: contact6.id, contact_number: contact6.cell_phone)

  # place response into queue
  SurveyResponseQueueRelationship.create!(survey_response: survey_res, custom_queue: queue6)
end

17.times do |i|
  contact7 = Contact.all.sample
  survey_res = SurveyResponse.create!(survey: survey7, contact_id: contact7.id, contact_number: contact7.cell_phone)

  # place response into queue
  SurveyResponseQueueRelationship.create!(survey_response: survey_res, custom_queue: queue7)
end