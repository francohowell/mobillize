namespace :cleanup do

  desc "Transitions Organizations + Plans"
  task transition_organization_plans: :environment do 
    current_row = 1
    csv = CSV.open("#{Rails.root}/MigrationFiles/contacts-10-21.csv", :headers => true)
    csv.each do |row|
      puts "Working On Row: #{current_row}"

      organization = Organization.find_by_id(row[0])
      if !organization 
        puts "=====> ERROR: Failed to find organization with id: #{row[0]}"
        next
      end

      plan_rel = OrganizationPlanRelationship.new(organization_id: organization.id, active: row[3], plan_start_date: row[11], stripe_id: row[10], monthly: row[10] == "sub_GdJ3dBgJH3xNZH" ? false : true, plan_id: organization.plan_id)

      if !plan_rel.save
        puts "=====> ERRORs: Failed to create organization plan relationship: #{plan_rel.errors.full_messages}"
        next
      end

      current_row += 1
    end

  end

  desc "Removes records that are orphaned."
  task orphaned_blast_contact_relationships: :environment do
    puts "**Starting Orphaned Blast Contact Relationships**"

    # Iterate Through The Blast Contact Relationships 
    clean_up_array = []
    for bcr in BlastContactRelationship.all 
      # Check to see if the blast still exists 
      if !bcr.blast
        puts "---<> BCR #{bcr.id} has no Blast #{bcr.blast_id}"
        clean_up_array.push(bcr)
        bcr.delete
      end
    end

    puts "--> Final Clean Up Result: #{clean_up_array.count}"

  end

end
