# frozen_string_literal: true

require 'json'
require 'jwt'
require 'pp'

def main(event:, context:)
  puts event
  # You shouldn't need to use context, but its fields are explained here:
  # https://docs.aws.amazon.com/lambda/latest/dg/ruby-context.html
  # response(body: event, status: 200)
  if event['path'] == '/'
    return logged_response(nil, 405, event, "wrong method (only accepts GET)") unless event['httpMethod'] == 'GET'
    return logged_response(nil, 403, event, "no header 'authorization'") unless event['headers'] && event['headers'].transform_keys(&:downcase)['authorization']
    #puts "info @/: " + event['headers'].transform_keys(&:downcase)['authorization']
    return logged_response(nil, 403, event, "improperly formed JWT token") unless (token = event['headers'].transform_keys(&:downcase)['authorization'][/Bearer (\S+\.\S+\.\S+)/,1])
    #puts "info @/: " + token
    begin
      decoded_token = JWT.decode token, ENV['JWT_SECRET'], true, { algorithm: 'HS256' }

    rescue JWT::ImmatureSignature, JWT::ExpiredSignature => e
      return logged_response(nil, 401, event, "JWT Exception (" + e.message + ")")
    rescue JWT::DecodeError => e
      return logged_response(nil, 403, event, "unable to decode (" + e.message + ")")
    rescue JWT::VerificationError => e
      return logged_response(nil, 403, event, "unable to verify (" + e.message + ")")
    end
    # turns out JWT is already handling this
    # return logged_response(nil, 401, event, "token has expired or not usable yet") unless Time.now.to_i > decoded_token[0]['nbf'] && Time.now.to_i < decoded_token[0]['exp']
    logged_response(decoded_token[0]['data'], 200, event, "success")

  elsif event['path'] == '/token'
    return logged_response(nil, 405, event, "wrong method (only accepts POST)") unless event['httpMethod'] == 'POST'
    return logged_response(nil, 415, event, "no header 'Content-Type'") unless event['headers']
    return logged_response(nil, 415, event, "header 'Content-Type' is not 'application/json'") unless event['headers'].transform_keys(&:downcase)['content-type'] == 'application/json'
    return logged_response(nil, 422, event, "no body") unless event['body']
    begin
      body_hash = JSON.parse(event['body'])
    rescue JSON::ParserError => e
      return logged_response(nil, 422, event, "invalid body (not JSON)")
    end
    # all valid; generate token
    payload = {
      data: body_hash,
      exp: Time.now.to_i + 5,
      nbf: Time.now.to_i + 2
    }
    token = JWT.encode payload, ENV['JWT_SECRET'], 'HS256'
    #puts "info @/token: " + token
    logged_response({ 'token' => token }, 201, event, "success")

  else
    # invalid endpoints
    logged_response(nil, 404, event, "invalid endpoint")
  end
end

def logged_response(body, status, event, message)
  path = event && event['path'] ? event['path'] : "no specific endpoint"
  if status != 200
    puts "info @" + path + ": status " + status.to_s + ", " + message + "."
  end
  response(body: body, status: status)
end

def response(body: nil, status: 200)
  {
    body: body ? body.to_json + "\n" : '',
    statusCode: status
  }
end

if $PROGRAM_NAME == __FILE__
  # If you run this file directly via `ruby function.rb` the following code
  # will execute. You can use the code below to help you test your functions
  # without needing to deploy first.
  ENV['JWT_SECRET'] = 'NOTASECRET'

  # Call /token
  PP.pp main(context: {}, event: {
               'body' => '{"name": "bboe"}',
               'headers' => { 'Content-Type' => 'application/json' },
               'httpMethod' => 'POST',
               'path' => '/token'
             })

  # Generate a token
  payload = {
    data: { user_id: 128 },
    exp: Time.now.to_i + 1,
    nbf: Time.now.to_i
  }
  token = JWT.encode payload, ENV['JWT_SECRET'], 'HS256'
  puts "info @test: " + token
  # Call /
  PP.pp main(context: {}, event: {
               'headers' => { 'Authorization' => "Bearer #{token}",
                              'Content-Type' => 'application/json' },
               'httpMethod' => 'GET',
               'path' => '/'
             })
end
