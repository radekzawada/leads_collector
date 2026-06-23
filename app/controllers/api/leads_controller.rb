class Api::LeadsController < ApplicationController
  def create
    result = ProcessLead.call(lead_params)

    render json: lead_json(result.lead), status: result.created ? :created : :ok
  end

  private

  def lead_params
    params.permit(:source, :group_name, :post_url, :post_text, :posted_at, :date_from, :date_to)
  end

  def lead_json(lead)
    {
      id: lead.id,
      source: lead.source,
      group_name: lead.group_name,
      post_url: lead.post_url,
      post_text: lead.post_text,
      posted_at: lead.posted_at,
      is_lead: lead.is_lead,
      date_from: lead.date_from,
      date_to: lead.date_to,
      adults: lead.adults,
      children: lead.children,
      guests_total: lead.guests_total,
      location: lead.location,
      confidence: lead.confidence,
      availability_status: lead.availability_status,
      notification_sent_at: lead.notification_sent_at
    }
  end
end
