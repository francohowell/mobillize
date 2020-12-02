module V1
    class KEYWORDAPI < Grape::API

        resource :keyword do 

            ##--> Retreaves Keyword <--##
            desc 'Retreaves a Keyword.',
            success: [
                { code: 200, message: 'Keyword has been returned.', model: Entities::Keyword },
            ],
            failure: [
                { code: 400, message: 'Bad request', model: Entities::ErrorResponse  },
                { code: 401, message: "Api Not Unauthorized", model: Entities::ErrorResponse  },
                { code: 404, message: 'Keyword Not Found',  model: Entities::ErrorResponse }
            ]
            params do
                requires :id, type: Integer, desc: 'Keyword id number.'
            end
            get ":id" do
                # Authenticate The Request
                authenticate!(request.headers["X-Api-Key"])

                keyword_id = params[:id]

                if !keyword_id
                    status 400 
                    return { status_code: 400, response_type: 'error', details: "Keyword id is missing." }
                end

                existing_keyword = Keyword.find_by_id(keyword_id)
                if existing_keyword
                    status 200 
                    return { status_code: 200, response_type: 'success', details: "Keyword was found.", data: existing_keyword }
                else 
                    status 404 
                    return { status_code: 404, response_type: 'error', details: "Keyword does not exist." }
                end
                
            end

            ##--> Retreaves Keyword <--##
            desc 'Retreaves a Keywords Groups.',
            success: [
                { code: 200, message: 'Keyword groups have been returned.', model: Entities::Group },
            ],
            failure: [
                { code: 400, message: 'Bad request', model: Entities::ErrorResponse  },
                { code: 401, message: "Api Not Unauthorized", model: Entities::ErrorResponse  },
                { code: 404, message: 'Keyword Not Found',  model: Entities::ErrorResponse }
            ]
            params do
                requires :id, type: Integer, desc: 'Keyword id number.'
            end
            get ":id/groups" do
                # Authenticate The Request
                authenticate!(request.headers["X-Api-Key"])

                keyword_id = params[:id]

                if !keyword_id
                    status 400 
                    return { status_code: 400, response_type: 'error', details: "Keyword id is missing." }
                end

                existing_keyword = Keyword.find_by_id(keyword_id)
                if existing_keyword
                    status 200 
                    return { status_code: 200, response_type: 'success', details: "Keyword was found.", data: existing_keyword.groups }
                else 
                    status 404 
                    return { status_code: 404, response_type: 'error', details: "Keyword does not exist." }
                end
                
            end

            ##--> Creates A Keyword <--##
            desc 'Creates a Keyword.',
            success: [
                { code: 200, message: 'Keyword has been created.', model: Entities::Keyword },
            ],
            failure: [
                { code: 400, message: 'Bad request', model: Entities::ErrorResponse  },
                { code: 401, message: "Api Not Unauthorized", model: Entities::ErrorResponse  },
                { code: 404, message: 'Keyword Not Found',  model: Entities::ErrorResponse }
            ]
            params do
                requires :name, type: String, desc: 'Keyword name.', documentation: { param_type: "body" }
                optional :description, type: String, desc: "Description of the keyword." 
                optional :help_text, type: String, desc: "Help text sent on response HELP."
                optional :invitation_text, type: String, desc: "Invitation text see on opt-in widgets."
                optional :opt_in_text, type: String, desc: "Opt In text sent on initial optin."
                optional :groups, type: Array, desc: "Array of group ids to be added to the keyword." do 
                    requires :id, type: Integer, desc: "Group id."
                end
            end
            post do
                # Items To Send Back 
                status_set = 200
                errors = nil 
                created_items = Array.new

                # Authenticate The Request
                authenticate!(request.headers["X-Api-Key"])

                name = params[:name]
                description = params[:description]
                help_text = params[:help_text]
                invitation_text = params[:invitation_text]
                opt_in_text = params[:opt_in_text]
                group_ids = params[:groups]

                new_keyword = Keyword.new(name: name, description: description, help_text: help_text, invitation_text: invitation_text, opt_in_text: opt_in_text, user_id: 0, organization_id: @organization.id, active: true)
                
                # Begin The Transaction
                ApplicationRecord.transaction do

                    if new_keyword.save 

                        # Process Connections 
                        if group_ids 
                            for group_id in group_ids
                                keyword_group_relationship = KeywordGroupRelationship.new(group_id: group_id[:id], keyword_id: new_keyword.id)

                                if !keyword_group_relationship.save 
                                    status_set = 400 
                                    errors = "Keyword and Group relationship could not be created. #{keyword_group_relationship.errors.full_messages.join(".")}" 
                                    raise ActiveRecord::Rollback 
                                end
                            end
                        end

                        status_set = 200 
                        created_items = new_keyword
                    else
                        status_set = 400 
                        errors = "Keyword could not be updated. #{new_keyword.errors.full_messages.join(".")}" 
                        raise ActiveRecord::Rollback 
                    end

                end

                # Return The Status & Results
                status status_set 
                if status_set == 200
                    return { status_code: status_set, response_type: "success", details: "Keyword was created.", data:  created_items}
                else
                    return { status_code: status_set, response_type: "failure", details: errors,  data: nil}
                end
                
            end

            ##--> Updates Group <--##
            desc 'Updates a Keyword.',
            success: [
                { code: 200, message: 'Keyword has been updated.', model: Entities::Keyword },
            ],
            failure: [
                { code: 400, message: 'Bad request', model: Entities::ErrorResponse  },
                { code: 401, message: "Api Not Unauthorized", model: Entities::ErrorResponse  },
                { code: 404, message: 'Keyword Not Found',  model: Entities::ErrorResponse }
            ]
            params do
                requires :id, type: Integer, desc: 'Group id number.'
                optional :description, type: String, desc: "Description of the keyword.", documentation: { param_type: "body" } 
                optional :help_text, type: String, desc: "Help text sent on response HELP."
                optional :invitation_text, type: String, desc: "Invitation text see on opt-in widgets."
                optional :opt_in_text, type: String, desc: "Opt In text sent on initial optin."
                optional :groups, type: Array, desc: "Array of group ids to be added to the keyword." do 
                    requires :id, type: Integer, desc: "Group id."
                end
            end
            post ":id" do
                # Items To Send Back 
                status_set = 200
                errors = nil 
                created_items = Array.new

                # Authenticate The Request
                authenticate!(request.headers["X-Api-Key"])

                keyword_id = params[:id]

                if !keyword_id
                    status_set = 400 
                    errors = "Keyword id must be provided." 
                    raise ActiveRecord::Rollback 
                end

                existing_keyword = Keyword.find_by_id(keyword_id)
                if existing_keyword

                    if params[:name]
                        existing_keyword.name = params[:name]
                    end

                    if params[:description]
                        existing_keyword.description = params[:description]
                    end 

                    if params[:help_text]
                        existing_keyword.help_text = params[:description]
                    end 

                    if params[:invitation_text]
                        existing_keyword.invitation_text = params[:description]
                    end 

                    if params[:opt_in_text]
                        existing_keyword.opt_in_text = params[:description]
                    end 
                    
                    # Begin The Transaction
                    ApplicationRecord.transaction do

                        if existing_keyword.save 

                            # Process Connections 
                            group_ids = params[:groups]
                            if group_ids 
                                for group_id in group_ids
                                    existing_relationship = KeywordGroupRelationship.find_by(keyword_id: existing_keyword.id, group_id: group_id[:id])
                                    if !existing_relationship
                                        keyword_group_relationship = KeywordGroupRelationship.new(keyword_id: existing_keyword.id, group_id: group_id[:id])

                                        if !keyword_group_relationship.save 
                                            status_set = 400 
                                            errors = "Keyword and Group relationship could not be created. #{keyword_group_relationship.errors.full_messages.join(".")}" 
                                            raise ActiveRecord::Rollback 
                                        end
                                    end
                                end
                            end

                            status_set = 200 
                            created_items = existing_keyword
                        else
                            status_set = 400 
                            errors = "Keyword could not be updated. #{existing_keyword.errors.full_messages.join(".")}" 
                            raise ActiveRecord::Rollback 
                        end

                    end
                else 
                    status_set = 400 
                    errors = "Group could not be found. #{keyword_id}" 
                    raise ActiveRecord::Rollback
                end

                # Return The Status & Results
                status status_set 
                if status_set == 200
                    return { status_code: status_set, response_type: "success", details: "Keyword was updated.", data:  created_items}
                else
                    return { status_code: status_set, response_type: "failure", details: errors,  data: nil}
                end
                
            end

            ##--> Delete Keyword <--##
            desc 'Deletes a Keyword.',
            success: [
                { code: 200, message: 'Keyword has been deleted.', model: Entities::ErrorResponse },
            ],
            failure: [
                { code: 400, message: 'Bad request', model: Entities::ErrorResponse  },
                { code: 401, message: "Api Not Unauthorized", model: Entities::ErrorResponse  },
                { code: 404, message: 'Keyword Not Found',  model: Entities::ErrorResponse }
            ]
            params do
                requires :id, type: Integer, desc: 'Keyword id number.'
            end
            delete ":id" do
                # Authenticate The Request
                authenticate!(request.headers["X-Api-Key"])

                keyword_id = params[:id]

                if !keyword_id
                    status 400 
                    return { status_code: 400, response_type: 'error', details: "Keyword id is missing." }
                end

                existing_keyword = Keyword.find_by_id(keyword_id)
                if existing_keyword

                    if existing_keyword.destroy
                        status 200 
                        return { status_code: 200, response_type: 'success', details: "Keyword was deleted." }
                    else
                        status 400 
                        return { status_code: 400, response_type: 'error', details: "Keyword could not be deleted. #{existing_keyword.errors.full_messages.join(".")}" }
                    end
                else 
                    status 404 
                    return { status_code: 404, response_type: 'error', details: "Keyword does not exist." }
                end
                
            end

        end

        resource :keywords do 
              ##--> Retreaves All Keywords <--##
              desc 'Retreaves All Keywords.',
              success: [
                  { code: 200, message: 'Keywords have been returned.', model: Entities::Keyword },
              ],
              failure: [
                  { code: 400, message: 'Bad request', model: Entities::ErrorResponse  },
                  { code: 401, message: "Api Not Unauthorized", model: Entities::ErrorResponse  },
                  { code: 404, message: "Keywords Not Found", model: Entities::ErrorResponse  }
              ]
              get do
                  # Authenticate The Request
                  authenticate!(request.headers["X-Api-Key"])
  
                  existing_keywords = @organization.keywords
                  if existing_keywords
                      status 200 
                      return { status_code: 200, response_type: 'success', details: "Keywords were found.", data: existing_keywords }
                  else 
                      status 404 
                      return { status_code: 404, response_type: 'error', details: "No keywords were found." }
                  end
                  
              end
        end
        
    end

end