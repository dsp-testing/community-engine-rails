module BetterTogether
  class SetupWizardStepsController < WizardStepsController
    skip_before_action :determine_wizard_outcome, only: [:create_host_platform, :create_admin] 

    def platform_details
      # Find or create the wizard step
      find_or_create_wizard_step

      # Build platform instance for the form
      @platform = BetterTogether::Platform.new(
        url: helpers.base_url, 
        privacy: 'public', 
        time_zone: Time.zone.name
      )

      # Initialize the form object
      @form = BetterTogether::HostPlatformDetailsForm.new(@platform)

      # Render the template from the step definition
      render wizard_step_definition.template
    end

    def create_host_platform
      @form = BetterTogether::HostPlatformDetailsForm.new(BetterTogether::Platform.new)
    
      if @form.validate(platform_params)
        ActiveRecord::Base.transaction do
          platform = BetterTogether::Platform.new(platform_params)
          platform.set_as_host
          platform.build_host_community
    
          if platform.save!
            mark_current_step_as_completed
            wizard.reload
            determine_wizard_outcome
          else
            flash.now[:alert] = 'Please address the errors below.'
            render wizard_step_definition.template
          end
        end
      else
        flash.now[:alert] = 'Please address the errors below.'
        render wizard_step_definition.template
      end
    rescue ActiveRecord::RecordInvalid => e
      flash.now[:alert] = e.record.errors.full_messages.to_sentence
      render wizard_step_definition.template
    end    

    def admin_creation
      # Find or create the wizard step
      find_or_create_wizard_step

      # Build a new user instance for the form
      @user = BetterTogether::User.new
      @user.build_person

      # Initialize the form object with nested person attributes
      @form = BetterTogether::HostPlatformAdminForm.new(@user)

      # Render the template from the step definition
      render wizard_step_definition.template
    end

    def create_admin
      @form = BetterTogether::HostPlatformAdminForm.new(BetterTogether::User.new)
    
      if @form.validate(user_params)
        ActiveRecord::Base.transaction do
          user = BetterTogether::User.new(user_params)
          user.build_person(user_params[:person_attributes])
          
          if user.save!
            # If Devise's :confirmable is enabled, this will send a confirmation email
            user.send_confirmation_instructions(confirmation_url: user_confirmation_path)
            mark_current_step_as_completed
            wizard.reload
            determine_wizard_outcome
          else
            # Handle the case where the user could not be saved
            flash.now[:alert] = user.errors.full_messages.to_sentence
            render wizard_step_definition.template
          end
        end
      else
        flash.now[:alert] = 'Please address the errors below.'
        render wizard_step_definition.template
      end
    rescue ActiveRecord::RecordInvalid => e
      flash.now[:alert] = e.record.errors.full_messages.to_sentence
      render wizard_step_definition.template
    end     

    # More steps can be added here...

    private

    def platform_params
      params.require(:platform).permit(:name, :description, :url, :time_zone, :privacy)
    end

    def person_params
      params.require(:user).permit(person_attributes: [:name, :description])[:person_attributes]
    end

    def user_params
      params.require(:user).permit(
        :username, :email, :password, :password_confirmation,
        person_attributes: [:name, :description]
      )
    end 

    def wizard_step_path(wizard = nil, step_definition)
      "/bt/setup_wizard/#{step_definition.identifier}"
    end
  end
end
