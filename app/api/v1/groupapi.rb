module V1
    class GROUPAPI < Grape::API
        resource :groups do

            ##--> Retreaves All Groups <--##
            desc 'Retreaves All Groups.',
            success: [
                { code: 200, message: 'Groups have been returned.', model: Entities::Group },
            ],
            failure: [
                { code: 400, message: 'Bad request', model: Entities::ErrorResponse  },
                { code: 401, message: "Api Not Unauthorized", model: Entities::ErrorResponse  },
                { code: 404, message: 'Groups Were Not Found',  model: Entities::ErrorResponse }
            ]
            get do
                # Authenticate The Request
                authenticate!(request.headers["X-Api-Key"])


                existing_groups = @organization.groups
                if existing_groups
                    status 200 
                    return { status_code: 200, response_type: 'success', details: "Group was found.", data: existing_groups }
                else 
                    status 404 
                    return { status_code: 404, response_type: 'error', details: "No Groups Exist." }
                end
                
            end

            ##--> Create Groups <--##
            desc 'Creates Groups.',
            success: [
                { code: 200, message: 'Group(s) have been created.', model: Entities::Group },
            ],
            failure: [
                { code: 400, message: 'Bad request', model: Entities::ErrorResponse  },
                { code: 401, message: "Api Not Unauthorized", model: Entities::ErrorResponse  },
                { code: 404, message: 'Group Not Found',  model: Entities::ErrorResponse }
            ],
            is_array: true
            params do
                requires :groups, type: Array, documentation: { param_type: "body" } do
                    requires :name, type: String, desc: 'Name of the group.'
                    optional :description, type: String, desc: 'Description of the group.'
                    optional :contacts, type: Array, desc: 'Array of contact ids to be added to the group.' do
                        optional :id, type: Integer, desc: "Id of the contact."
                    end
                end
            end
            post do 
                # Items To Send Back 
                status_set = 200
                errors = nil 
                created_items = Array.new

                # Authenticate The Request
                authenticate!(request.headers["X-Api-Key"])

                # Begin The Transaction
                ApplicationRecord.transaction do

                    for group in params[:groups]

                        name = group[:name]
                        description = group[:description]
                        contact_ids = group[:contacts]
    
                        new_group = Group.new(name: name, description: description, user_id: 0, organization_id: @organization.id)
    
                        if !new_group.save 
                            status_set = 400 
                            errors = "Group could not be created. #{new_group.errors.full_messages.join(".")}" 
                            raise ActiveRecord::Rollback 
                        end

                        created_items.push(new_group)
                        if contact_ids
                            for id in contact_ids

                                group_contacts_relationship = GroupContactRelationship.new(group_id: new_group.id, contact_id: id[:id])

                                if !group_contacts_relationship.save 
                                    status_set = 400 
                                    errors = "Group and Contact relationship could not be created. #{group_contacts_relationship.errors.full_messages.join(".")}" 
                                    raise ActiveRecord::Rollback 
                                end
                            end
                        end
                    
                    end

                end

                

                # Return The Status & Results
                status status_set 
                if status_set == 200
                    return { status_code: status_set, response_type: "success", details: "Groups Created.", data:  created_items}
                else
                    return { status_code: status_set, response_type: "failure", details: errors,  data: nil}
                end
                
            end

            ##--> Delete Group <--##
            desc 'Deletes Groups by their ids.' do 
                success [
                    { code: 200, message: 'Groups have been deleted.', model: Entities::ErrorResponse },
                ]
                failure [
                    { code: 400, message: 'Bad request', model: Entities::ErrorResponse  },
                    { code: 401, message: "Api Not Unauthorized", model: Entities::ErrorResponse  },
                    { code: 404, message: 'Group Not Found',  model: Entities::ErrorResponse }
                ]
                is_array true
            end
            params do
                requires :groups, type: Array, documentation: { param_type: 'body' } do 
                    requires :id, type: Integer, desc: "Id of the group."
                end
            end
            post "delete" do 

                # Items To Send Back 
                status_set = 200
                errors = nil 


                # Authenticate The Request
                authenticate!(request.headers["X-Api-Key"])

                # Begin The Transaction
                ApplicationRecord.transaction do

                    for group_id in params[:groups]
                        id = group_id[:id]

                        if !id
                            status_set = 400 
                            errors = "Id is missing from group." 
                            raise ActiveRecord::Rollback 
                        end

                        existing_group = Group.find_by_id(id)
                        if existing_group

                            if existing_group.destroy!
                                status_set = 200 
                            else
                                status_set = 400 
                                errors = "Group could not be deleted. #{existing_group.errors.full_messages.join(".")}" 
                                raise ActiveRecord::Rollback 
                            end
                        else 
                            status_set = 404 
                            errors = "Group could not be found: #{id}" 
                            raise ActiveRecord::Rollback 
                        end 
                    end 
                end

                 # Return The Status & Results
                 status status_set 
                 if status_set == 200
                     return { status_code: status_set, response_type: "success", details: "Groups Were Deleted."}
                 else
                     return { status_code: status_set, response_type: "failure", details: errors,  data: nil}
                 end
            end
            ##--> Delete Groups <--##

        end

        resource :group do 

            ##--> Retreaves Group <--##
            desc 'Retreaves a Group.',
            success: [
                { code: 200, message: 'Group has been returned.', model: Entities::Group },
            ],
            failure: [
                { code: 400, message: 'Bad request', model: Entities::ErrorResponse  },
                { code: 401, message: "Api Not Unauthorized", model: Entities::ErrorResponse  },
                { code: 404, message: 'Group Not Found',  model: Entities::ErrorResponse }
            ]
            params do
                requires :id, type: Integer, desc: 'Group id number.'
            end
            get ":id" do
                # Authenticate The Request
                authenticate!(request.headers["X-Api-Key"])

                group_id = params[:id]

                if !group_id
                    status 400 
                    return { status_code: 400, response_type: 'error', details: "Group id is missing." }
                end

                existing_group = Group.find_by_id(group_id)
                if existing_group
                    status 200 
                    return { status_code: 200, response_type: 'success', details: "Group was found.", data: existing_group }
                else 
                    status 404 
                    return { status_code: 404, response_type: 'error', details: "Group does not exist." }
                end
                
            end

            ##--> Retreaves Group Contacts<--##
            desc 'Retreaves a Group Contacts.',
            success: [
                { code: 200, message: 'Group contacts have been returned.', model: Entities::Contact },
            ],
            failure: [
                { code: 400, message: 'Bad request', model: Entities::ErrorResponse  },
                { code: 401, message: "Api Not Unauthorized", model: Entities::ErrorResponse  },
                { code: 404, message: 'Group Not Found',  model: Entities::ErrorResponse }
            ]
            params do
                requires :id, type: Integer, desc: 'Group id number.'
            end
            get ":id/contacts" do

                # Authenticate The Request
                authenticate!(request.headers["X-Api-Key"])

                group_id = params[:id]

                if !group_id
                    status 400 
                    return { status_code: 400, response_type: 'error', details: "Group id is missing." }
                end

                existing_group = @organization.groups.find_by_id(group_id)
                if existing_group

                    status 200 
                    return { status_code: 200, response_type: 'success', details: "Group was found and contacts have been returned.", data: existing_group.contacts }
                else 
                    status 404 
                    return { status_code: 404, response_type: 'error', details: "Group does not exist." }
                end
                
            end

            ##--> Updates Group <--##
            desc 'Updates a Group.',
            success: [
                { code: 200, message: 'Group has been updated.', model: Entities::Group },
            ],
            failure: [
                { code: 400, message: 'Bad request', model: Entities::ErrorResponse  },
                { code: 401, message: "Api Not Unauthorized", model: Entities::ErrorResponse  },
                { code: 404, message: 'Group Not Found',  model: Entities::ErrorResponse }
            ]
            params do
                requires :id, type: Integer, desc: 'Group id number.'
                optional :name, type: String, desc: "Name of the group.", documentation: { param_type: "body" } 
                optional :description, type: String, desc: "Description of the group."
                optional :contacts, type: Array, desc: "Array of contact ids to be added to the group." do 
                    requires :id, type: Integer, desc: "Contact id."
                end
            end
            post ":id" do
                # Items To Send Back 
                status_set = 200
                errors = nil 
                created_items = Array.new

                # Authenticate The Request
                authenticate!(request.headers["X-Api-Key"])

                group_id = params[:id]

                if !group_id
                    status_set = 400 
                    errors = "Group id must be provided." 
                    raise ActiveRecord::Rollback 
                end

                existing_group = Group.find_by_id(group_id)
                if existing_group

                    if params[:name]
                        existing_group.name = params[:name]
                    end

                    if params[:description]
                        existing_group.description = params[:description]
                    end 

                    
                    # Begin The Transaction
                    ApplicationRecord.transaction do

                        if existing_group.save 

                            # Process Connections 
                            contact_ids = params[:contacts]
                            if contact_ids 
                                for contact_id in contact_ids
                                    existing_relationship = GroupContactRelationship.find_by(group_id: existing_group.id, contact_id: contact_id[:id])
                                    if !existing_relationship
                                        group_contacts_relationship = GroupContactRelationship.new(group_id: existing_group.id, contact_id: contact_id[:id])

                                        if !group_contacts_relationship.save 
                                            status_set = 400 
                                            errors = "Group and Contact relationship could not be created. #{group_contacts_relationship.errors.full_messages.join(".")}" 
                                            raise ActiveRecord::Rollback 
                                        end
                                    end
                                end
                            end

                            status_set = 200 
                            created_items = existing_group
                        else
                            status_set = 400 
                            errors = "Group could not be updated. #{existing_group.errors.full_messages.join(".")}" 
                            raise ActiveRecord::Rollback 
                        end

                    end
                else 
                    status_set = 400 
                    errors = "Group could not be found. #{group_id}" 
                    raise ActiveRecord::Rollback
                end

                # Return The Status & Results
                status status_set 
                if status_set == 200
                    return { status_code: status_set, response_type: "success", details: "Group was updated.", data:  created_items}
                else
                    return { status_code: status_set, response_type: "failure", details: errors,  data: nil}
                end
                
            end

            ##--> Removes Contacts From A Group <--##
            desc 'Removes contacts from a Group.',
            success: [
                { code: 200, message: 'Group Contact has been removed.', model: Entities::ErrorResponse },
            ],
            failure: [
                { code: 400, message: 'Bad request', model: Entities::ErrorResponse  },
                { code: 401, message: "Api Not Unauthorized", model: Entities::ErrorResponse  },
                { code: 404, message: 'Group Not Found',  model: Entities::ErrorResponse }
            ]
            params do
                requires :id, type: Integer, desc: 'Group id number.'
                optional :remove_all, type: Boolean, desc: "Removes all contacts from the group." , documentation: { param_type: "body" }
                optional :contacts, type: Array, desc: "Array of contact ids." do 
                    optional :id, type: Integer, desc: "Id of the contact."
                end
            end
            post ":id/contacts_remove" do
                # Items To Send Back 
                status_set = 200
                errors = nil 

                # Authenticate The Request
                authenticate!(request.headers["X-Api-Key"])

                group_id = params[:id]

                if !group_id
                    status_set = 400 
                    errors = "Group id must be provided." 
                    raise ActiveRecord::Rollback 
                end

                existing_group = Group.find_by_id(group_id)
                if existing_group

                    # Begin The Transaction
                    ApplicationRecord.transaction do

                        remove_all = params[:remove_all]
                        if remove_all
                            relationships = existing_group.group_contact_relationships 
                            for relationship in relationships
                                if !relationship.destroy
                                    status_set = 400 
                                    errors = "Group and Contact relationship could not be destroyed. #{relationship.errors.full_messages.join(".")}" 
                                    raise ActiveRecord::Rollback 
                                end
                            end
                        elsif params[:contacts]
                            contact_ids = params[:contacts]
                            for contact_id in contact_ids
                                existing_relationship = GroupContactRelationship.find_by(group_id: existing_group.id, contact_id: contact_id[:id])
                                if !existing_relationship
                                    status_set = 404 
                                    errors = "Group and Contact relationship could not be found. #{contact_id}" 
                                    raise ActiveRecord::Rollback 
                                else
                                    if !existing_relationship.destroy
                                        status_set = 400 
                                        errors = "Group and Contact relationship could not be destroyed. #{existing_relationship.errors.full_messages.join(".")}" 
                                        raise ActiveRecord::Rollback 
                                    end
                                end
                            end
                        end
                    end
                else 
                    status_set = 400 
                    errors = "Group could not be found. #{group_id}" 
                end

                # Return The Status & Results
                status status_set 
                if status_set == 200
                    return { status_code: status_set, response_type: "success", details: "Group Contacts were removed.", data: nil}
                else
                    return { status_code: status_set, response_type: "failure", details: errors,  data: nil}
                end
                
            end
            

            ##--> Delete Group <--##
            desc 'Deletes a Group.',
            success: [
                { code: 200, message: 'Group has been deleted.', model: Entities::ErrorResponse },
            ],
            failure: [
                { code: 400, message: 'Bad request', model: Entities::ErrorResponse  },
                { code: 401, message: "Api Not Unauthorized", model: Entities::ErrorResponse  },
                { code: 404, message: 'Group Not Found',  model: Entities::ErrorResponse }
            ]
            params do
                requires :id, type: Integer, desc: 'Group id number.'
            end
            delete ":id" do
                # Authenticate The Request
                authenticate!(request.headers["X-Api-Key"])

                group_id = params[:id]

                if !group_id
                    status 400 
                    return { status_code: 400, response_type: 'error', details: "Group id is missing." }
                end

                existing_group = Group.find_by_id(group_id)
                if existing_group

                    if existing_group.destroy
                        status 200 
                        return { status_code: 200, response_type: 'success', details: "Group was deleted." }
                    else
                        status 400 
                        return { status_code: 400, response_type: 'error', details: "Group could not be deleted. #{existing_group.errors.full_messages.join(".")}" }
                    end
                else 
                    status 404 
                    return { status_code: 404, response_type: 'error', details: "Group does not exist." }
                end
                
            end

        end
        
    end

end