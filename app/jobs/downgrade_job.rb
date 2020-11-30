# app/jobs/hello_world_job.rb
# frozen_string_literal: true
class DowngradeJob
    include PaymentProcessor
    include Sidekiq::Worker
    sidekiq_options queue: 'low'

    def perform(organization_id, new_plan_id, period)

        organization = Organization.find_by_id(organization_id)
        new_plan = Plan.find_by_id(new_plan_id)
        user = organization.users.last
        keywords = organization.keywords.where(stripe_id: nil)

        if keywords.count <= new_plan.keywords_included

            # Deactivate Previous Plan 
            current_plan_subscription = organization.current_plan_subscription
            if current_plan_subscription
                current_plan_subscription.active = false 
                current_plan_subscription.plan_end_date = Time.now 
                if !current_plan_subscription.save 
                    Honeybadger.notify("Failed to update the existing organization plan relationship: Org Id #{organization.id}. | Org Plan Rel Id #{current_plan_subscription.id} | Error: #{current_plan_subscription.errors.full_messages}", class_name: "Downgrade Job")
                    SystemMailer.failed_plan_downgrade_email(user, new_plan,  "system_error")
                    return
                end 
            end

            # Stripe Create New Subscription 
            created_subscription_results = create_subscription(organization.stripe_account.stripe_id, period ? new_plan.stripe_id : new_plan.annual_stripe_id, nil)
            if created_subscription_results["success"] == false 
                Honeybadger.notify("Failed to process the new subscription in stripe. | Stripe Object: #{created_subscription_results}", class_name: "Downgrade Job")
                SystemMailer.failed_plan_downgrade_email(user, new_plan,  "system_error")
                return
            end

            # Activate New Plan
            new_subscription = OrganizationPlanRelationship.new(active: true, organization_id: organization.id, plan_id: new_plan_id, monthly: period, plan_start_date: Time.now, stripe_id: created_subscription_results["data"]["id"])
            if !new_subscription.save 
                Honeybadger.notify("Failed to create an organization plan relationship: Org Id #{organization.id}. | Error: #{new_subscription.errors.full_messages}", class_name: "Downgrade Job")
                SystemMailer.failed_plan_downgrade_email(user, new_plan,  "system_error")
                return
            end

            # Update Organization Details
            organization.downgrade_date = nil
            organization.downgrade_job_id = nil
            if !organization.save
                SystemMailer.failed_plan_downgrade_email(user, new_plan,  "system_error")
                return                
            end

        else
            SystemMailer.failed_plan_downgrade_email(user, new_plan,  "plan_limitations")
        end
    end

end
