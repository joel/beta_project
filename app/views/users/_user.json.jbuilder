json.extract! user, :id, :title, :created_at, :updated_at
json.url user_url(user, format: :json)
