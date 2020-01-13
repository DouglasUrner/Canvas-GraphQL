#!/usr/bin/env ruby

require "graphql"
require "graphql/client"
require "graphql/client/http"
require "json"

module CGQL
  # Configure GraphQL endpoint using the basic HTTP network adapter.
  HTTP = GraphQL::Client::HTTP.new("https://canvas.instructure.com/api/graphql") do
    def headers(context)
      # Optionally set any HTTP headers
      {
        "Accept": "application/json",
        "Authorization": "Bearer #{ENV['ACCESS_TOKEN']}",
        "Content-Type": "application/json",
        "User-Agent": "Ruby/graphql-client"
      }
    end
  end

  # Fetch latest schema on init, this will make a network request
  Schema = GraphQL::Client.load_schema(HTTP)

  # However, it's smart to dump this to a JSON file and load from disk
  #
  # Run it from a script or rake task
  #   GraphQL::Client.dump_schema(SWAPI::HTTP, "path/to/schema.json")
  #
  # Schema = GraphQL::Client.load_schema("path/to/schema.json")

  Client = GraphQL::Client.new(schema: Schema, execute: HTTP)
end

CourseListQuery = CGQL::Client.parse <<-'GRAPHQL'
query {
  allCourses {
    name
    courseCode
    state
    _id
    id
    account {
      _id
      id
      name
    }
    permissions {
      manageGrades
    }
  }
}
GRAPHQL

CourseQuery = CGQL::Client.parse <<-'GRAPHQL'
query {
  course(id: "1692944") {
    name
    modulesConnection {
      nodes {
        name
      }
    }
  }
}
GRAPHQL

def query(definition, variables = {})
  response = CGQL::Client.query(
    definition,
    variables: variables,
    context: client_context
  )

  case response
  when GraphQL::Client::Response
    response.data
  when GraphQL::Client::FailedResponse
    raise response.errors
  end
end

def client_context
  { access_token: ENV['ACCESS_TOKEN'] }
end

data = query(CourseListQuery)
data.all_courses.each do |course|
  if (course.permissions.manage_grades == true && course.state == 'available')
    puts course.name
  end
end
