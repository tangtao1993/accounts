class SendContactInfoConfirmation

  include Lev::Routine

protected

  def exec(contact_info)
    return if contact_info.verified

    fatal_error(code: :no_confirmation_code, data: contact_info) if contact_info.confirmation_code.blank?

    case contact_info.type
    when 'EmailAddress'
      ConfirmationMailer.instructions(contact_info).deliver  
    else
      fatal_error(code: not_yet_implemented, data: contact_info)
    end
    
    contact_info.confirmation_sent_at = Time.now
    contact_info.save
  end

end
