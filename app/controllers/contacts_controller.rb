require 'csv'

class ContactsController < ApplicationController
  include Pagy::Backend

  before_action :authenticate_user!

  def new
    @csv_uploads = current_user.organization.contact_uploads.order("created_at DESC").limit(3)
  end

  def delete
    if params[:all] == "true"
      if current_user.organization.contacts.destroy_all
        flash[:success] = "All Contacts Deleted."
      else
        flash[:alert] = "Failed to delete contacts."
      end
    elsif params[:id]
      c = Contact.find_by_id(params[:id])
      if c.destroy
        flash[:success] = "Contact Deleted."
      else
        flash[:alert] = "Failed to delete contact."
      end
    end
  end

  def download
    respond_to do |format|
      format.html { send_data current_user.organization.contacts.to_csv, filename: "MobilizeComms-Contacts-#{Date.today}.csv" }
    end
  end

  def show
    @c = Contact.find_by_id(params[:id])
    @groups = @c.groups
    @blasts_relationships = BlastContactRelationship.where(contact_id: @c.id)
  end

  def create
    c = Contact.new(cell_phone: params[:contact][:cell_phone], first_name: params[:contact][:first_name], last_name: params[:contact][:last_name], primary_email: params[:contact][:primary_email], secondary_email: params[:contact][:secondary_email], active: true, organization_id: current_user.organization.id, company_name: params[:contact][:company_name])
    if !c.save
      flash[:alert] = c.errors.full_messages.join("\n")
      render contacts_new_path
    else
      flash[:success] = "Contact has been created!"
      redirect_to contacts_overview_path
    end
  end

  def overview
    @cons_count = current_organization.contacts.count
    @cons_active_count = current_organization.contacts.where(active: true).count
    @cons_inactive_count = @cons_count - @cons_active_count

    if params[:search]
      search_text = params[:search]
      search_text = search_text.gsub(' ', '')
       @pagy, @cons = pagy(current_user.organization.contacts.where('first_name ILIKE :search OR last_name ILIKE :search OR cell_phone LIKE :search', search: "%#{search_text}%"))
    else
      @pagy, @cons = pagy(current_user.organization.contacts.order(:id), items: 25)
    end
  end

  def upload
    @cu = ContactUpload.new(file: params[:contact_upload][:file], organization: current_user.organization, user: current_user)
    if !@cu.save
      flash[:alert] = @cu.errors.full_messages.join("\n")
      redirect_to contacts_new_path
      return
    else
      # redirect_to contacts_upload_overview_path(upload_id: @cu.id)
      redirect_to contacts_upload_matching_path(upload_id: @cu.id)
      return
    end
  end

  def upload_matching
    @headers = ['Cell Phone', 'First Name', 'Last Name', 'Primary Email', 'Secondary Email', 'Company', 'Group 1', 'Group 2', 'Group 3', 'Group 4', 'Group 5']
    @cu = ContactUpload.find_by_id(params[:upload_id])
    @uploaded_headers = open(@cu.file.url) {|csv| csv.readline.gsub("\n",'').split(',')}
  end

  def upload_headers
    @cu = ContactUpload.find_by_id(params[:upload_id])
    if params['Cell Phone'] == ''
      flash[:alert] = "Cell Phone field is required to upload a contact"
      redirect_to contacts_upload_matching_path(upload_id: @cu.id)
      return
    end
    headers = {
      cell_phone: params['Cell Phone'],
      first_name: params['First Name'],
      last_name: params['Last Name'],
      name: params['Name'],
      p_email: params['Primary Email'],
      s_email: params['Secondary Email'],
      comp_name: params['Company'],
      group1: params['Group 1'],
      group2: params['Group 2'],
      group3: params['Group 3'],
      group4: params['Group 4'],
      group5: params['Group 5']
    }
    @cu.update(headers: headers, permission_to_text: true)
    # send to job
    UploadContactsJob.perform_at(Time.now, current_user.id, @cu.id)
    redirect_to contacts_upload_confirmation_path
    return
  end

  def upload_overview
    @cu = ContactUpload.find_by_id(params[:upload_id])
    csv_text = open(@cu.file.url)
    headers = eval(@cu.headers)
    @csv = CSV.parse(csv_text, :headers => true).map do |row|
      [
        ['Cell Phone', row[headers[:cell_phone]]],
        ['First Name', row[headers[:first_name]] || ''],
        ['Last Name', row[headers[:last_name]] || ''],
        ['Primary Email', row[headers[:p_email]] || ''],
        ['Secondary Email', row[headers[:s_email]] || ''],
        ['Company', row[headers[:comp_name]] || ''],
        ['Group 1', row[headers[:group1]] || ''],
        ['Group 2', row[headers[:group2]] || ''],
        ['Group 3', row[headers[:group3]] || ''],
        ['Group 4', row[headers[:group4]] || ''],
        ['Group 5', row[headers[:group5]] || ''],
      ]
    end
    @pagy_a, @items = pagy_array(@csv, limit: 30)
  end

  def process_upload
    @cu = ContactUpload.find_by_id(params[:upload_id])
    csv_text = open(@cu.file.url)
    headers = eval(@cu.headers)
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
      c = Contact.find_by(cell_phone: cell_phone, organization_id: current_user.organization_id)

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
      else
        c = Contact.new(cell_phone: cell_phone, first_name: first_name, last_name: last_name, primary_email: p_email, secondary_email: s_email, organization_id: current_user.organization.id, active: true, company_name: comp_name)
        if !c.save
          failures[r] = c.errors.full_messages.join(",")
          r += 1
          next
        end
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

    if failures.nil? || failures.empty?
      flash[:success] = "All Contacts Were Added!"
      redirect_to contacts_new_path
      return
    else
      redirect_to contacts_upload_failure_path(failures: failures, upload_id: params[:upload_id])
      return
    end
  end

  def upload_failure
    @failures = params[:failures]
    @cu = ContactUpload.find_by_id(params[:upload_id])
    csv_text = open(@cu.file.url)
    @csv = CSV.parse(csv_text, :headers => true)
  end

  def edit
    @c = Contact.find_by_id(params[:id])
  end

  def update
    c = Contact.find_by_id(params[:id])
    if c
      if !c.update(cell_phone: params[:contact][:cell_phone], first_name: params[:contact][:first_name], last_name: params[:contact][:last_name], primary_email: params[:contact][:primary_email], secondary_email: params[:contact][:secondary_email], company_name: params[:contact][:company_name])
        flash[:alert] = c.errors.full_messages.join(",")
        redirect_to contacts_edit_path(id: c.id)
        return
      else
        flash[:success] = "Contact Was Updated!"
        redirect_to contacts_edit_path(id: c.id)
        return
      end
    else
      flash[:alert] = "Failed to find the contact in which you are updating."
      redirect_to contacts_show_path(id: c.id)
      return
    end
  end

  private

  def group_contact(group_name, contact, failure_hash, row)
    g = Group.find_by(name: group_name, organization_id: current_user.organization_id)
    if g
      existing_gcr = GroupContactRelationship.find_by(contact_id: contact.id, group_id: g.id)
      if existing_gcr
        return failure_hash
      end
      gcr = GroupContactRelationship.new(contact_id: contact.id, group_id: g.id)
      if !gcr.save
        failure_hash[row] = gcr.errors.full_messages.join(",")
      end
    else
      failure_hash[row] = "Could not find group name #{group_name}"
    end
    return failure_hash
  end

end
