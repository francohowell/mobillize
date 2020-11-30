module PaymentProcessor
    # All Methods Return A Hash: [ Success: (true/false), error_message: (String), data: (JSON)]

    ##--> Supporting Methods <--##

    # Checks the basic details of a credit card for accuracy
    def credit_card_check(number, month, year)
        response_hash= Hash.new 

        response_hash["success"] = true 

        detector = CreditCardValidations::Detector.new(number)
        if !detector.valid?
            response_hash["success"] = false 
            response_hash["error_message"] = "Credit Card Number Is Invalid"
        end

        # Check Credit Card Month
        if month <= 0 || month > 12
            response_hash["success"] = false 
            response_hash["error_message"] = "Expiration Month has must be 01 - 12 "
        end

        # Check Credit Card Year
        if (year + 2000) < Time.now.year
            response_hash["success"] = false 
            response_hash["error_message"] = "Expiration Year must be this year or greater "
        end

        # Check Expiration 
        if (year + 2000) == Time.now.year
            if month <= Time.now.month
                response_hash["success"] = false 
                response_hash["error_message"] = "This Card Has Expired"
            end
        end

        return response_hash
    end

    # Creates a payment token for stripe accounts
    def stripe_token_create(name, number, month, year, cvc)
        return execute(
            lambda {
                Stripe::Token.create({
                    card: {
                      number: number,
                      exp_month: month,
                      exp_year: year,
                      cvc: cvc,
                      name: name
                    }
                })
            }
        )
    end

    ##--> Account Methods <--##

    # Creates a new stripe customer account 
    def create_stripe_account(user, organization, payment_source)
        return execute(
            lambda {
                Stripe::Customer.create({
                    description: "Account for #{organization.name}",
                    email: user.email,
                    metadata: {
                      mobilizeus_id: organization.id,
                      mobilizeus_user: user.name, 
                    },
                    name: organization.name, 
                    phone: user.cell_phone, 
                    source: payment_source
                })
            }
        )
    end

    # Updates a customer's payment details 
    def update_payment_details(stripe_id, source)
        return execute(
            lambda {
                Stripe::Customer.update(
                    stripe_id,
                    {
                      source: source,
                    }
                )
            }
        )
    end

    ##--> Charging Methods <--##

    # Runs a default processing charge immediately
    def immediate_charge(total, description, organization)
        current_stripe_account = organization.stripe_account
        return execute(
            lambda {
                Stripe::Charge.create({
                    amount: (total.to_f*100).to_i, # Currency is in cents not dollars
                    currency: 'usd',
                    customer: current_stripe_account.stripe_id,
                    description: description,
                    source: current_stripe_account.payment_source_id,
                })
            }
        )
    end

    # Runs a default processing charge immediately
    def subscription_charge(plan, current_organization, billing_period = 'monthly')
        current_organization = current_organization.nil? ? current_user.organization : current_organization
        stripe_id = billing_period == 'monthly' ? plan.stripe_id : plan.annual_stripe_id
        return execute(
            lambda {
                Stripe::Subscription.create(
                    customer: current_organization.stripe_account.stripe_id,
                    items: [
                        {
                            plan: "#{stripe_id}",
                        }
                    ]
                )
            }
        )
    end

    # Restores A Subscriptions On Going Status
    def subscription_restore(subscription_id)
        return execute(
            lambda {
                Stripe::Subscription.update(subscription_id, {
                    cancel_at_period_end: false
                })
            }
        )
    end

    # Creates a subscription for a customer
    def create_subscription(customer_id, pricing_id, coupon_id)
        return execute(
            lambda {
                Stripe::Subscription.create({
                    customer: customer_id,
                    items: [
                        {price: pricing_id}
                    ],
                    coupon: coupon_id             
                })
            }
        )
    end


    ##--> Credit Methods <--##

    # Creates a credit line for a customer
    def create_credit_line(customer_id, amount)
        return execute( 
            lambda { 
                Stripe::InvoiceItem.create({
                    customer: customer_id,
                    amount: amount.to_i,
                    currency: "usd"
                })
            }
        )
    end

    # Creates a single use coupon 
    def create_single_use_coupon(amount)
        return execute( 
            lambda { 
                Stripe::Coupon.create({
                    amount_off: amount.to_i,
                    currency: "usd",
                    duration: 'once'
                })
            }
        )
    end

    ##--> Cancelation Methods <--##

    # Deletes An Existing Subscription
    def cancel_subscription_immediately(subscription_id)
        return execute(
            lambda {
                Stripe::Subscription.delete(subscription_id)
            }
        )
    end

    # Sets A Subscription To Cancel Itself At The End Of Its Billing Period
    def subscription_cancel_at_end_of_period(subscription_id)
        return execute(
            lambda {
                Stripe::Subscription.update(subscription_id, {
                    cancel_at_period_end: true
                })
            }
        )
    end

    # Deletes An Existing Credit Line
    def delete_credit_item(line_item)
        return execute(
            lambda {
                Stripe::InvoiceItem.delete(line_item)
            }
        )
    end


    ##--> Retreaval Methods <--##

    # Obtains a list of charges
    def charges_made(start_date, end_date)
        return execute(
            lambda {
                Stripe::Payout.list({
                    created: {
                        gte: start_date.to_i, 
                        lte: end_date.to_i
                    },
                    status: "paid",
                    limit: 100
                })
            }
        )
    end

    # Obtains a list of refunds
    def refunds_made(start_date, end_date)
        return execute(
            lambda {
                Stripe::Refund.list({
                    created: {
                        gte: start_date.to_i, 
                        lte: end_date.to_i
                    }
                })
            }
        )
    end

    # Obtains a most recent list of a customer's subscriptions
    # Statuses: actice, past_due, canceled
    def customer_subscriptions(customer_id, status)
        return execute(
            lambda {
                Stripe::Subscription.list({
                    customer: customer_id,
                    status: status,
                    limit: 25
                })
            }
        )
    end

    # Returns a most recent list of a customer's invoices
    def customer_invoices(customer_id)
        return execute(
            lambda {
                Stripe::Invoice.list({
                    customer: customer_id,
                    status: "open",
                    limit: 25
                })
            }
        )
    end

    # Returns a most recent list of a customer's charges
    def customer_charges(customer_id)
        return execute(
            lambda {
                Stripe::Charge.list({
                    customer: customer_id,
                    limit: 25
                })
            }
        )
    end

    # Returns a specific customer's subscription
    def customer_subscription_lookup(subscription_id)
        return execute(
            lambda {
                Stripe::Subscription.retrieve(subscription_id)
            }
        )
    end
    

    private 

    # Executor Method
    def execute(stripe_method)
        response_hash = Hash.new
        begin
            stripe_transaction = stripe_method.call()
            response_hash["success"] = true 
            response_hash["data"] = stripe_transaction
            return response_hash
        rescue Stripe::CardError => e
            # Since it's a decline, Stripe::CardError will be caught
            body = e.json_body
            err  = body[:error]
            logger.error("Stripe Card Error Catch #{err[:message]}")
            error_message = err[:message].nil? ? "Your Card Has Failed. Please Update And Try Again." : err[:message]
            response_hash["success"] = false 
            response_hash["error_message"] = error_message
            return response_hash
        rescue Stripe::RateLimitError => e
            # Too many requests made to the API too quickly
            body = e.json_body
            err  = body[:error]
            logger.error("Stripe Rate Limit Error Catch #{err[:message]}")
            error_message = "Our Payment Process Is A Little Busy At The Moment, Please Try Again."
            response_hash["success"] = false 
            response_hash["error_message"] = error_message
            return response_hash
        rescue Stripe::InvalidRequestError => e
            # Invalid parameters were supplied to Stripe's API
            body = e.json_body
            puts e
            err  = body[:error]
            logger.error("Stripe Invalid Parameters Error Catch #{err[:message]}")
            error_message = "Looks Like An Error On Our Part, Please Feel Free To Contact support@mobilizecomms.com."
            response_hash["success"] = false 
            response_hash["error_message"] = error_message
            return response_hash
        rescue Stripe::AuthenticationError => e
            # Authentication with Stripe's API failed
            # (maybe you changed API keys recently)
            body = e.json_body
            err  = body[:error]
            logger.error("Stripe Authentication Error Catch #{err[:message]}")
            error_message = "Looks Like An Error On Our Part, Please Feel Free To Contact support@mobilizecomms.com."
            response_hash["success"] = false 
            response_hash["error_message"] = error_message
            return response_hash
        rescue Stripe::APIConnectionError => e
            # Network communication with Stripe failed
            body = e.json_body
            err  = body[:error]
            logger.error("Stripe Network Error Catch #{err[:message]}")
            error_message = "Looks Like A Network Error Occured. Please Try Again."
            response_hash["success"] = false 
            response_hash["error_message"] = error_message
            return response_hash
        rescue Stripe::StripeError => e
            # Display a very generic error to the user, and maybe send
            # yourself an email
            body = e.json_body
            err  = body[:error]
            logger.error("Stripe Generic Error Catch #{err[:message]}")
            error_message = err[:message]
            response_hash["success"] = false 
            response_hash["error_message"] = error_message
            return response_hash
        rescue => e
            # Something else happened, completely unrelated to Stripe
            logger.error("Stripe Catch-All Error Catch #{e}")
            error_message = "Looks Like An Error On Our Part, Please Feel Free To Contact support@mobilizecomms.com."
            response_hash["success"] = false 
            response_hash["error_message"] = error_message
            return response_hash
        end 
    end
    
end
