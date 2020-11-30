# app/jobs/hello_world_job.rb
# frozen_string_literal: true
class BlastJob
    include Sidekiq::Worker
    sidekiq_options queue: 'critical'

    def perform(organization_id, blast_id)
        organization = Organization.find_by_id(organization_id)
        blast = Blast.find_by_id(blast_id)
        if organization && blast
            mgage_manage = MgageMasterService.new()
            mgage_manage.process_message(organization, blast)
        end
    end

end
