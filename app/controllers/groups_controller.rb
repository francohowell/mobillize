class GroupsController < ApplicationController
  include Pagy::Backend

  before_action :authenticate_user!

  def show
    @group = Group.find_by_id(params[:id])
    if !@group 
      flash["alert"] = "We could not find the group you were looking for."
      redirect_to groups_overview_path
      return
    end
    @created_by_user = User.find_by_id(@group.user_id)
    @pagy_con, @group_contacts = pagy(@group.contacts, items: 25)
  end

  def overview 
    @group_count = current_organization.groups.count 
    
    if params[:search]
      @pagy, @group_search = pagy(current_user.organization.groups.where("name ILIKE :search", search: "%#{params[:search]}%"), items: 25)
    else
      @pagy, @group_search = pagy(current_user.organization.groups, items: 25)
    end
  end

  def new 
    @other_groups = current_user.organization.groups
    @gname = params[:gname]
    @gdescription = params[:gdescription]
    if params[:selectedgroups]
      @selectedgroups = params[:selectedgroups].split(",")
    else
      @selectedgroups = nil
    end
    @group_all = params[:groups_all]
    if params[:cell_check]
      @cell_check = params[:cell_check].split(",")
    else
      @cell_check = nil 
    end
    @row_limit = 25
    @offset = 0
    @current_page = 0
    if params[:new_page]
      @offset = params[:new_page].to_i * @row_limit 
      @current_page = params[:new_page].to_i
    end
    @count = current_user.organization.contacts.where(active: true).count
    if params[:search]
      search_value =  params[:search]
      @pagy, @your_contacts = pagy(current_user.organization.contacts.where("active = true AND (cell_phone ILIKE ? OR first_name ILIKE ? OR last_name ILIKE ?)", "%#{search_value}%", "%#{search_value}%", "%#{search_value}%"), limit: 25)
    else
      @pagy, @your_contacts = pagy(current_user.organization.contacts.where(active: true), limit: 25)
    end
  end

  def create 

    success = true

    ## Create The Group
    g = Group.new(name: params[:group][:name].strip, description: params[:group][:description], organization_id: current_user.organization_id, user_id: current_user.id)
    if !g.save
      success = false
      flash[:alert] = g.errors.full_messages.join("\n")
      redirect_to groups_new_path
    end


    # Create Contact Relationships
    if params[:contacts_all]
      for c in current_user.organization.contacts
        group_contact_relation  = GroupContactRelationship.create(group_id: g.id, contact_id: c.id)
        if !group_contact_relation
          success = false
          flash[:alert] = group_contact_relation.errors.full_messages.join("\n")
          g.delete
          redirect_to groups_new_path
        end
      end
    else
      if params[:all_contact_ids]
        for c_id in params[:all_contact_ids]
          contact = current_user.organization.contacts.find_by_id(c_id)
          if contact 
            group_contact_relation  = GroupContactRelationship.create(group_id: g.id, contact_id: c_id)
            if !group_contact_relation
              success = false
              flash[:alert] = group_contact_relation.errors.full_messages.join("\n")
              g.delete
              redirect_to groups_new_path
            end
          else
            success = false
            flash[:alert] = "Could not find contact. Please refresh."
            g.delete
            redirect_to groups_new_path
          end
        end
      end
    end

    if success
      flash[:success] = "Group has been created!"
      redirect_to groups_overview_path
    end

  end

  def remove_individual_contact
    relationship = GroupContactRelationship.find_by(group_id: params[:group_id], contact_id: params[:contact_id])
    @group = Group.find_by_id(params[:group_id])
    @created_by_user = User.find_by_id(@group.user_id)
    @group_contacts = @group.contacts
    if relationship
      if relationship.delete
        flash[:success] = "Contact has been removed from the group!"
      else
        flash[:alert] = "Could not remove contact from the group."
      end
    else
      flash[:alert] = "Could not find contact in the group."
    end
    redirect_to groups_show_path(id: @group.id)
  end

  def reset
    @group = Group.find_by_id(params[:group_id])
    @created_by_user = User.find_by_id(@group.user_id)
    @group_contacts = @group.contacts
    if !@group.reset
      flash[:alert] = "Could not do reset the group."
      render :show
    else
      flash[:success] = "Group contacts have been reset."
      render :show
    end
  end

  def contacts_export 
    @group = Group.find_by_id(params[:group_id])
    send_data @group.contacts_data, filename: "#{@group.name}-Contacts-#{Date.today}.csv"
  end

  def delete_contacts 
    @group = Group.find_by_id(params[:group_id])
    if !@group.contacts_destroy
      flash[:alert] = "Could not do delete the contacts in this group."
      render :show
    else
      flash[:success] = "Contacts in this group have been deleted."
      render :show
    end
  end

  def edit
    @group = Group.find_by_id(params[:group_id])
    @cell_check = @group.get_all_contacts_ids
    @gname = params[:gname]
    @gdescription = params[:gdescription]
    @count = current_user.organization.contacts.where(active: true).count
    if params[:search]
      search_value =  params[:search]
      @pagy, @your_contacts = pagy(current_user.organization.contacts.where("active = true AND (cell_phone ILIKE ? OR first_name ILIKE ? OR last_name ILIKE ?)", "%#{search_value}%", "%#{search_value}%", "%#{search_value}%"), limit: 25)
    else
      @pagy, @your_contacts = pagy(current_user.organization.contacts.where(active: true), limit: 25)
    end
  end

  def update
    success = true

    @group = Group.find_by_id(params[:group_id])
    if params[:group][:name]
      @group.name = params[:group][:name].strip
    end
    @group.description = params[:group][:description]


    if !@group.save
      success = false
      flash[:alert] = @group.errors.full_messages
      redirect_to groups_edit_path(group_id: params[:group_id], name: params[:name], description: params[:description], groups_all: params[:groups_all], othergroups: params[:othergroups], contacts_all: params[:contacts_all], contacts: params[:contacts])
    end

    # Create Contact Relationships
    if params[:contacts_all]
      for c in current_user.organization.contacts
        if !@group.contacts.ids.include?(c.id)
          group_contact_relation  = GroupContactRelationship.create(group_id: @group.id, contact_id: c.id)
          if !group_contact_relation
            success = false
            flash[:alert] = group_contact_relation.errors.full_messages.join("\n")
            redirect_to groups_edit_path(group_id: params[:group_id], name: params[:name], description: params[:description], groups_all: params[:groups_all], othergroups: params[:othergroups], contacts_all: params[:contacts_all], contacts: params[:contacts])
          end
        end
      end
    else
      if params[:all_contact_ids]
        # Adding Groups When There Are Existing SubGroups
        passed_contact_ids = params[:all_contact_ids]
        passed_contact_ids = passed_contact_ids.map(&:to_i)
        contact_ids = @group.get_all_contacts_ids

        new_passed_contact_ids = passed_contact_ids - contact_ids
        contact_ids = contact_ids - passed_contact_ids

        # Any values left over from the sub_group_ids need to be deleted as these were removed by the user. 
        for remaining_id in contact_ids
            x = @group.group_contact_relationships.find_by(group_id: @group.id, contact_id: remaining_id)
            if x
              GroupContactRelationship.destroy(x.id) 
            end
        end

        for c_id in new_passed_contact_ids
          contact = current_user.organization.contacts.find_by_id(c_id)
          if contact 
            group_contact_relation  = GroupContactRelationship.create(group_id: @group.id, contact_id: c_id)
            if !group_contact_relation
              success = false
              flash[:alert] = group_contact_relation.errors.full_messages.join("\n")
              redirect_to groups_edit_path(group_id: params[:group_id], name: params[:name], description: params[:description], groups_all: params[:groups_all], othergroups: params[:othergroups], contacts_all: params[:contacts_all], contacts: params[:all_contact_ids])
            end
          else
            success = false
            flash[:alert] = "Could not find contact. Please refresh."
            redirect_to groups_edit_path(group_id: params[:group_id], name: params[:name], description: params[:description], groups_all: params[:groups_all], othergroups: params[:othergroups], contacts_all: params[:contacts_all], contacts: params[:all_contact_ids])
          end
        end
      else
        puts '---------> NO CONTACTS <---------'
        # Removing Contacts That Exist If None Were Supplied
        @group.group_contact_relationships.destroy_all
      end

    end

    if success
      flash[:success] = "Group #{@group.name} has been updated!"
      redirect_to groups_overview_path
    end

  end

  def delete
    @group = Group.find_by_id(params[:group_id])
    if @group.destroy 
      flash[:success] = "Group has been deleted!"
    else
      flash[:alert] = "Could not delete group!"
    end
  end

end
