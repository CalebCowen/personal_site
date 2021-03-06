class PaymentsController < ApplicationController

  def create
    project = Project.find_by(name: params[:project_name].downcase)
    amount = params[:amount]
    token = params[:stripeToken]

    unless project.customer_id
      customer = Stripe::Customer.create(
        :email => project.contact_email,
        :source => token
      )
      project.update_attributes(customer_id: customer.id)
    end

    charge = Stripe::Charge.create(
    :amount => amount,
    :currency => "usd",
    :description => "Payment for #{params[:project_name]}",
    :customer => project.customer_id
    )
    project.payments.create(amount: amount)
    project.update_attributes(amount_owed: project.amount_owed - amount)
    project.check_status

    rescue Stripe::CardError => e
      body = e.json_body
      error = body[:error]
      DeclineMailer.decline_email(project, error).deliver_later
  end
end
