class UploadContactsJob
  include Sidekiq::Worker
  sidekiq_options queue: 'low'

  def perform(user_id, contact_uploads_id)
    contacts_upload = process_uploads(contact_uploads_id)
    SystemMailer.upload_confirmation(contacts_upload, user_id)
    return
  end

  private

  def process_uploads(cu_id)
    cu = ContactUpload.find_by_id(cu_id)
    csv_text = open(cu.file.url).read.force_encoding("UTF-8")
    headers = eval(cu.headers)
    csv = CSV.parse(csv_text, :headers => true, encoding:'iso-8859-1:utf-8').map do |row|
      [
        row[headers[:cell_phone]],
        row[headers[:first_name]] || '',
        row[headers[:last_name]] || '',
        row[headers[:p_email]] || '',
        row[headers[:s_email]] || '',
        row[headers[:comp_name]] || '',
        row[headers[:group1]] || nil,
        row[headers[:group2]] || nil,
        row[headers[:group3]] || nil,
        row[headers[:group4]] || nil,
        row[headers[:group5]] || nil,
      ]
    end

    r = 1
    failures = Hash.new
    new_count = 0
    update_count = 0

    csv.each do |row|
      # 0-> Cell Phone, 1-> First Name, 2 -> Last Name, 3 -> Primary Email, 4 -> Secondary Email, Group(s)

      cell_phone = row[0]
      # Scrub tne cell phone
      if !cell_phone
        puts "----> Cell Phone blank #{r} | #{cell_phone}"
        failures[r] = "Cell Phone Cannot Be Blank"
        r += 1
        next
      end
      cell_phone = cell_phone.gsub(/[^0-9]/, '')
      if cell_phone.length == 10
        cell_phone = "1#{cell_phone}"
      else
        cell_phone = "#{cell_phone}"
      end

      first_name = row[1]
      last_name = row[2]
      p_email = row[3]
      s_email = row[4]
      comp_name = row[5]
      group1 = row[6]
      group2 = row[7]
      group3 = row[8]
      group4 = row[9]
      group5 = row[10]

      # Does the contact already exist?
      c = Contact.find_by(cell_phone: cell_phone, organization_id: cu.organization_id)

      if c
        # Update
        if first_name
          c.first_name = first_name
        end
        if last_name
          c.last_name = last_name
        end
        if p_email
          c.primary_email = p_email
        end
        if s_email
          c.secondary_email = s_email
        end
        if comp_name
          c.company_name = comp_name
        end

        if !c.save
          failures[r] = c.errors.full_messages.join(",")
          r += 1
          next
        end
        update_count += 1
      else
        c = Contact.new(cell_phone: cell_phone, first_name: first_name, last_name: last_name, primary_email: p_email, secondary_email: s_email, organization_id: cu.organization_id, active: true, company_name: comp_name)
        if !c.save
          failures[r] = c.errors.full_messages.join(",")
          r += 1
          next
        end
        new_count += 1
      end

      # Process Groups Additions
      if c

        if group1
          failures = group_contact(group1, c, failures, r)
        end
        if group2
          failures = group_contact(group2, c, failures, r)
        end
        if group3
          failures = group_contact(group3, c, failures, r)
        end
        if group4
          failures = group_contact(group4, c, failures, r)
        end
        if group5
          failures = group_contact(group5, c, failures, r)
        end

      end

      r += 1
    end

    return [new_count, update_count, failures]
    # if failures.nil? || failures.empty?
    #   # success
    #   puts 'success'
    #   return
    # else
    #   # failures
    #   puts 'failure'
    #   return
    # end
  end
end
