# frozen_string_literal: true

require 'rails_helper'

# F19: the invite page must tell a candidate whose session ended on an error that it failed,
# so the API has to say why the session ended — not only that it did.
RSpec.describe 'Candidate session info', type: :request do
  it 'includes why the session ended' do
    session = create(:session, status: 'ended', end_reason: 'error')

    get "/api/v1/sessions/#{session.invite_token}/candidate"

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include('session_status' => 'ended', 'end_reason' => 'error')
  end
end
