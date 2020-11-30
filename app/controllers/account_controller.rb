class AccountController < ApplicationController
    before_action :authenticate_user!

    layout 'empty'

    def new 
        @user = User.new 
        @organization = Organization.new 
    end

    def create
    end

end
