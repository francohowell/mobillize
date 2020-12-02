namespace :datamigrate do

  desc "Determines Uniqueness of Users"
  task users_unique: :environment do
    user_hash = Hash.new
    i = 1
    csv = CSV.open("#{Rails.root}/MigrationFiles/users-10-21.csv", :headers => true)
    csv.each do |row|
      puts "Processing Row #{i}"
      key = row[0]
      username = row[1]
      type = row[2]
      status = row[3]
      secret = row[4]
      roles = row[5]
      plan_id = row[6]
      plan = row[7]
      password = row[8] # Used
      organization = row[9] # Used 
      mobile_number = row[10] # Used
      messages_sent = row[11]
      last_name = row[12] # Used
      keyword_max = row[13]
      first_name = row[14] # Used
      email = row[15] # Used
      date_joined = row[16]
      attributes_zip = row[17] # Used
      attributes_state = row[18] # Used
      attributes_city = row[19] # Used
      attributes_address2 = row[20] # Used
      attributes_address1 = row[21] # Used
      address1 = row[22] # Used
      address2 = row[23] # Used
      city = row[24] # Used
      state = row[25] # Used
      zip = row[26] # Used

      if status == "active"
        if user_hash[email]
          user_hash[email] = user_hash[email] + 1
        else
          user_hash[email] = 1
        end
      end

    end
    user_hash.each do |key, value|
      if value > 1
        puts "#{key} ---> #{value}"
      end
    end
  end
  
  ### -> Check & Redos 
  #### --> Time Zone 
  desc "Migrates Mongo CSV File Of Users To Postgres"
  task users: :environment do

    # Plan Setup
    demo_plan = Plan.find_by_name("Demo")
    bronze_plan = Plan.find_by_name("Bronze")
    silver_plan = Plan.find_by_name("Silver")
    gold_plan = Plan.find_by_name("Gold")
    diamond_plan = Plan.find_by_name("Diamond")
    platinum_plan = Plan.find_by_name("Platinum")
    premium_plan = Plan.find_by_name("Premium")
    payg_plan = Plan.find_by_name("Pay As You Go")
    custom1400_42_plan = Plan.find_by_name("Custom1400-42")
    custom1000_35_plan = Plan.find_by_name("Custom1000-35")
    custom1000_20_plan = Plan.find_by_name("Custom1000-20")
    custom200_15_plan = Plan.find_by_name("Custom200-15")
    custom800_37_plan = Plan.find_by_name("Custom800-37")

    i = 1
    csv = CSV.open("#{Rails.root}/MigrationFiles/users-10-21.csv", :headers => true)
    csv.each do |row|
      puts "Processing Row #{i}"
      key = row[0]
      username = row[1]
      type = row[2]
      status = row[3]
      secret = row[4]
      roles = row[5]
      plan_id = row[6]
      plan = row[7]
      password = row[8] # Used
      organization = row[9] # Used 
      mobile_number = row[10] # Used
      messages_sent = row[11]
      last_name = row[12] # Used
      keyword_max = row[13]
      first_name = row[14] # Used
      email = row[15] # Used
      date_joined = row[16]
      attributes_zip = row[17] # Used
      attributes_state = row[18] # Used
      attributes_city = row[19] # Used
      attributes_address2 = row[20] # Used
      attributes_address1 = row[21] # Used
      address1 = row[22] # Used
      address2 = row[23] # Used
      city = row[24] # Used
      state = row[25] # Used
      zip = row[26] # Used

      if status == "active"
        status = true 
      else
        status = false 
      end

      if email != "support@mobilizeus.com"
        if status
          # Preprocess some attributes
          if organization.nil?
            organization = "#{first_name} #{last_name}"
          end

          if !attributes_city.nil?
            city = attributes_city
          end
          
          if !attributes_state.nil?
            state = attributes_state
          end

          if !attributes_zip.nil?
            zip = attributes_zip
          end

          if !attributes_address1.nil?
            address1 = attributes_address1
          end

          if !attributes_address2.nil?
            address2 = attributes_address2
          end

          tz = "Eastern Time (US & Canada)"

          if password.nil? || password.length < 8
            password = "MUS2019-#{i}"
          end

          if mobile_number == nil 
            mobile_number = "5555555555"
          end

          if date_joined
            date_joined = Time.at(date_joined)
          else
            date_joined = DateTime.now
          end

          if last_name.blank? || last_name.length < 2
            last_name = "No Last Name"
          end 

          assigned_plan = demo_plan

          if status
            if plan_id == "acf59409-b80c-4cce-918a-922d5195405d" || plan_id == "921e8111-f0a4-44c7-a53b-7ad7bec9f1b1"
              assigned_plan = silver_plan
            elsif plan_id == "3ba45fcb-d3e5-427c-9726-c99da3098786"
              assigned_plan = custom1400_42_plan
            elsif plan_id == "67f62e2b-325f-4070-91cf-a2057c8ecbab"
              assigned_plan = custom1000_35_plan
            elsif plan_id == "01642a8f-d941-4abb-9453-0eb18050dc9c"
              assigned_plan = custom1000_20_plan
            elsif plan_id == "927f134b-356c-43c8-aca8-d509aad4d358"
              assigned_plan = custom200_15_plan
            elsif plan_id == "a009faf3-58a4-44d3-aad5-a9b6149f9027"
              assigned_plan = custom800_37_plan
            elsif plan_id == "c53c3cc7-3f91-4544-9ee6-30484b9cdac5" || plan_id == "650777cc-cce2-4853-8b06-e9b33f8686e5"
              assigned_plan = payg_plan
            end
          end

          # Create Organization 
          org = Organization.new(organization_active: status, city: city, country: "USA", industry: "Other", logo: nil, name: organization, postal_code: zip, size: "0-10", state_providence: state, street: address1, street2: address2, plan_start_date: date_joined, timezone: tz, plan_id: assigned_plan.id )

          if !org.save
            puts "Failed to create organization -> #{org.errors.full_messages}"
            exit
          end

          u = User.new(organization_id: org.id, active: status, cell_phone: mobile_number, city: city, country: "USA", email: email, first_name: first_name, last_name: last_name, password: password, state_providence: state, old_key: key)
          
          u.skip_confirmation!

          if !u.save 
            puts "Failed to create user -> #{u.errors.full_messages}"
            exit
          end

          i += 1
        else
          NonMigratedUser.create(key: key)
        end
      else
        NonMigratedUser.create(key: key)
      end
    end
  end

  desc "Migrates Mongo CSV File Of Contacts To Postgres"
  task contacts: :environment do
    i = 1
    csv = CSV.open("#{Rails.root}/MigrationFiles/contacts-10-21.csv", :headers => true)
    csv.each do |row|
      puts "Processing Contact Row #{i}"
      key = row[0]
      owner_id = row[1]
      mobile_number = row[2] # Used
      first_name = row[3] # Used
      last_name = row[4] # Used
      email = row[5] # Used
      active = row[6] # Used

      if !Contact.find_by_old_key(key)
        if !mobile_number.blank? 

          if mobile_number.length > 9 && mobile_number.length < 11

            inactive_user = NonMigratedUser.find_by_key(owner_id)

            if !inactive_user

              # Clean Up Attributes
              if active.nil? 
                active = false
              end

              # Find Organization
              user = User.find_by(old_key: owner_id)
              if !user
                puts "Failed to find user to connect contact. #{owner_id}"
                next
              end

              org_id = user.organization.id

              if !email.nil?
                if email.include? "@"
                  email = email.gsub(" ", "")
                  email = email.gsub(":", "")
                  email = email.gsub("..", "")
                  email = email.gsub("�", "")
                  email = email.gsub(">", "")
                else
                  email = ""
                end
              end

              # Create Contact

              con = Contact.new(active: active, primary_email: email, first_name: first_name, last_name: last_name, cell_phone: mobile_number, old_key: key, organization_id: org_id)

              if !Contact.find_by(organization_id: org_id, cell_phone: "1#{con.cell_phone}")

                if !con.save 
                  puts "Failed to created contact -> #{con.errors.full_messages}"
                  puts "Email: #{email}, Cell Phone: #{mobile_number}"
                  exit
                end
              end
            end
          end
        end
      end
    end
  end

  desc "Migrates Mongo CSV File Of Groups To Postgres"
  task groups: :environment do
    i = 1
    csv = CSV.open("#{Rails.root}/MigrationFiles/contact_groups-10-21.csv", :headers => true)
    csv.each do |row|
      puts "Processing Row #{i}"

      key = row[0] # Used
      owner_id = row[1] # Used
      name = row[2] # Used
      new_record = row[3]
      contacts = row[4] # Used

      inactive_user = NonMigratedUser.find_by_key(owner_id)

      if !inactive_user

        if contacts

          # Find User & Organization 
          user = User.find_by(old_key: owner_id)
          if !user
            puts "Could not find user to connect with groups: #{owner_id}"
            next
          end

          org_id = user.organization.id

          if name.length < 2 
            name = "#{name}-#{org_id}"
          end

          grp = Group.new(name: name, description: nil, user_id: user.id, organization_id: org_id, old_key: key)

          if !grp.save 
            puts "Failed to create group -> #{grp.errors.full_messages}"
            exit
          end

          # Create Contact & Group Relationship
          contacts = contacts.gsub("[", "")
          contacts = contacts.gsub("]", "")

          contact_array = contacts.split(",")

          for c_id in contact_array 
            c_id = c_id.gsub("\"", "")
            con = Contact.find_by_old_key(c_id)
            if !con
              puts "Failed to find contact #{c_id}"
              next
            end
            
            gcr = GroupContactRelationship.new(group_id: grp.id, contact_id: con.id)
            if !gcr.save
              puts "Failed to create group relationship with contact -> #{gcr.errors.full_messages}"
              exit
            end
          end
        end
      end

    end

  end

  desc "Migrates Mongo CSV File Of Keywords To Postgres"
  task keywords: :environment do
    i = 1
    csv = CSV.open("#{Rails.root}/MigrationFiles/keywords-10-21.csv", :headers => true)
    csv.each do |row|
      puts "Processing Row #{i}"

      key = row[0] # Used
      owner_id = row[1]
      keyword = row[2] # Used
      groups = row[3]
      authorized_contacts = row[4]
      help = row[5] # Used
      join = row[6]
      widget_join = row[7] # USed
      widget_join_response = row[8]

      inactive_user = NonMigratedUser.find_by_key(owner_id)

      if !inactive_user

        # Find User & Organization 
        user = User.find_by(old_key: owner_id)
        if !user
          puts "Could not find user to connect with groups: #{owner_id}"
          next
        end
  
        org_id = user.organization.id

        kwd = Keyword.new(active: true, description: "", help_text: help, invitation_text: widget_join, name: keyword.downcase, opt_in_text: join, opt_out_text: nil, purchase_date: nil, stripe_id: nil, user_id: user.id, organization_id: org_id, old_key: key)

        if !kwd.save
          puts "Failed to create the keyword -> #{kw.errors.full_messages}"
          exit
        end

        if authorized_contacts

          # Create Admins 
          authorized_contacts = authorized_contacts.gsub("[", "")
          authorized_contacts = authorized_contacts.gsub("]", "")

          admin_array = authorized_contacts.split(",")
          for a_id in admin_array
            a_id = a_id.gsub("\"", "")

            con = Contact.find_by_old_key(a_id)
            if !con 
              puts "Failed to find contact admin id #{a_id}"
              next
            end
            kwadmin = KeywordAdmin.new(keyword_id: kwd.id, contact_id: con.id)
            if !kwadmin.save
              puts "Failed to create contact admin -> #{kwadmin.errors.full_messages}"
              exit
            end
          end
        end

        if groups
          # Creat Groups 
          groups = groups.gsub("[", "")
          groups = groups.gsub("]", "")

          group_array = groups.split(",")
          for g_id in group_array
            g_id = g_id.gsub("\"", "")

            grp = Group.find_by_old_key(g_id)
            if !grp 
              puts "Failed to find group id #{g_id}"
              next
            end
            kwgr = KeywordGroupRelationship.new(keyword_id: kwd.id, group_id: grp.id)
            if !kwgr.save
              puts "Failed to create group relationship -> #{kwgr.errors.full_messages}"
              exit
            end
          end
        end
      end

    end
  end

  desc "Phone Clean Ups"
  task phone_scrub: :environment do 
    for con in Contact.all
        if con.cell_phone.match(/[^0-9]/)
            new_num = con.cell_phone.delete('^0-9')
            found_con = Contact.find_by_cell_phone(new_num)
            if found_con
                puts "----> Existing: #{found_con.id} MalFormated: #{con.id}" 
            else
                con.cell_phone = new_num
                con.save
            end
        end
    end
  end

  desc "Migrates Mongo CSV File Of Keywords To Postgres"
  task add_new_system_values: :environment do
    SystemValue.create(key: "empty_message_response", value: "Your message is blank, please retry your message with content.")

    SystemValue.create(key: "no_keyword_or_contact_response", value: "Sorry! We can't find a record of this number in our system. Please provide a keyword to opt-in.")

    SystemValue.create(key: "no_keyword_or_recent_blast_response", value: "Sorry! We can't find a record of any messages sent to you. Please provide a keyword to opt-in.")

    SystemValue.create(key: "failed_to_opt_out_all_accounts", value: "We are so sorry. We were not able to unsubscribe from all acccounts. Please contact MobilizeUS.")
    
    SystemValue.create(key: "failed_to_log_response_to_account", value: "We are so sorry. We were not able to log your reply. Please try again.")
    
    SystemValue.create(key: "logged_response_to_account", value: "Your message has been received. Thank you for replying.")

    SystemValue.create(key: "failed_keyword_admin_blast_create", value: "We are so sorry. We were not able to create your blast message. Please try again or log into the portal at messaging.mobilizeus.com")

    SystemValue.create(key: "successful_keyword_admin_blast_create", value: "Your blast has been created and is being processed now.")
    
    SystemValue.create(key: "failed_to_opt_in_keyword", value: "We're sorry but we could not opt you in. Please email support@mobilizeus.com with the keyword and your mobile number to opt-in or try again later.")

  end

  desc "Ensures existing data records are formatted to new validations and integrity."
  task prep_data_integrity: :environment do
    # Responses 
    null_contacts_in_responses = Response.where(contact_id: nil)
    for resp in null_contacts_in_responses
      resp.contact_id = 0
      resp.save
    end

    # Organization Phone Relationships
    null_mass_outgoing_in_phone_relationships = OrganizationPhoneRelationship.where(mass_outgoing: nil)
    for resp in null_mass_outgoing_in_phone_relationships
      resp.mass_outgoing = false
      resp.save
    end
  end

  desc "Ensures existing data records are updated with new fields."
  task post_data_integrity: :environment do
    # Blast Contact Relationships 
    null_contacts_in_responses = BlastContactRelationship.where(contact_number: "15555555555")
    for bc in null_contacts_in_responses
      con = Contact.find_by_id(bc.contact_id)
      if con 
        bc.contact_number = con.cell_phone
        bc.save
      end
    end

  end

  desc "Adds Previous Clients Back To The System"
  task previous_client_load: :environment do 
    ## Update These Before Executing ##
    client_key = "68dd0ef9-787c-4f33-9088-72bc8940ccef"
    new_organization_id = 248
    new_user_id = 138
    ##-------##

    org = Organization.find_by_id(new_organization_id)
    user = User.find_by_id(new_user_id)
    # Collect The Contacts 
    i = 1
    csv = CSV.open("#{Rails.root}/MigrationFiles/contacts-10-21.csv", :headers => true)
    csv.each do |row|
      puts "Processing Contact Row #{i}"
      key = row[0]
      owner_id = row[1]
      mobile_number = row[2] # Used
      first_name = row[3] # Used
      last_name = row[4] # Used
      email = row[5] # Used
      active = row[6] # Used

      if !Contact.find_by_old_key(key)
        if !mobile_number.blank? 
          if mobile_number.length > 9 && mobile_number.length < 11

            if owner_id == client_key

              # Clean Up Attributes
              if active.nil? 
                active = false
              end

              org_id = org.id

              if !email.nil?
                if email.include? "@"
                  email = email.gsub(" ", "")
                  email = email.gsub(":", "")
                  email = email.gsub("..", "")
                  email = email.gsub("�", "")
                  email = email.gsub(">", "")
                else
                  email = ""
                end
              end

              # Create Contact

              con = Contact.new(active: active, primary_email: email, first_name: first_name, last_name: last_name, cell_phone: mobile_number, old_key: key, organization_id: org_id)

              if !Contact.find_by(organization_id: org_id, cell_phone: "1#{con.cell_phone}")

                if !con.save 
                  puts "Failed to created contact -> #{con.errors.full_messages}"
                  puts "Email: #{email}, Cell Phone: #{mobile_number}"
                  exit
                end
              end
            end
          end
        end
      end
    end

    
  end

  desc "Ensures All Blast Have Contact Count, Rate, & Cost"
  task blast_count_update: :environment do
    for b in Blast.all
      b.contact_count = b.blast_contact_relationships.count 
      b.rate = 1
      if b.stripe_id
        b.cost = b.contact_count * b.rate * 0.05
        if b.cost < 0.5 
          b.cost = 0.5 
        end 
      else
        b.cost = b.contact_count * b.rate
      end
      b.save
    end
  end

end

