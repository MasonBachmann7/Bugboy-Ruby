require "sinatra"
require "json"
require_relative "models"
require_relative "services"
require_relative "utils"

set :port, (ENV["PORT"] || 4567).to_i
set :bind, "0.0.0.0"
set :show_exceptions, false
set :host_authorization, { permitted_hosts: [".onrender.com"] }

BUGS = [
  { id: 1,  route: "/trigger/type-error",           method: "GET",  error: "TypeError",                        description: "String concatenation with nil last_name in User#get_display_name" },
  { id: 2,  route: "/trigger/key-error",             method: "GET",  error: "KeyError",                         description: "Missing 'notifications' key in user preferences hash" },
  { id: 3,  route: "/trigger/no-method-error",       method: "GET",  error: "NoMethodError",                    description: "Calling .email on nil assignee for unassigned task" },
  { id: 4,  route: "/trigger/zero-division",         method: "GET",  error: "ZeroDivisionError",                description: "Sprint velocity divides by zero sprint_length_days" },
  { id: 5,  route: "/trigger/index-error",           method: "GET",  error: "IndexError",                       description: "Fetching latest comment from empty comments array" },
  { id: 6,  route: "/trigger/file-not-found",        method: "GET",  error: "Errno::ENOENT",                    description: "Loading project config from nonexistent file path" },
  { id: 7,  route: "/trigger/json-parse-error",      method: "GET",  error: "JSON::ParserError",                description: "Parsing malformed JSON from simulated webhook response" },
  { id: 8,  route: "/trigger/encoding-error",        method: "POST", error: "Encoding::UndefinedConversionError", description: "Processing webhook payload with invalid UTF-8 bytes" },
  { id: 9,  route: "/trigger/recursion-error",       method: "GET",  error: "SystemStackError",                 description: "Flattening category tree with circular parent-child reference" },
  { id: 10, route: "/trigger/connection-error",      method: "GET",  error: "Errno::ECONNREFUSED",              description: "Connecting to unreachable internal database host" },
  { id: 11, route: "/trigger/argument-error",        method: "POST", error: "ArgumentError",                    description: "Parsing 'high' as integer during CSV task import" },
  { id: 12, route: "/trigger/permission-error",      method: "GET",  error: "Errno::EACCES",                    description: "Writing to a read-only export file locked by backup job" },
  { id: 13, route: "/trigger/timeout-error",         method: "GET",  error: "Timeout::Error",                   description: "Slow aggregation query exceeds 2-second timeout" },
  { id: 14, route: "/trigger/thread-error",          method: "GET",  error: "NoMethodError (Thread)",           description: "Background notification thread crashes on nil template" },
  { id: 15, route: "/trigger/memory-error",          method: "POST", error: "NoMemoryError",                    description: "O(n²) cross-reference index exhausts available memory" },
].freeze

# ── Dashboard ──

get "/" do
  erb :dashboard
end

# ── API ──

get "/api/bugs" do
  content_type :json
  BUGS.to_json
end

get "/health" do
  content_type :json
  { status: "ok" }.to_json
end

# ── Bug Trigger Routes ──

# Bug #1: TypeError
get "/trigger/type-error" do
  user = USERS.find { |u| u.id == "USR-002" }
  result = user.get_display_name
  content_type :json
  { display_name: result }.to_json
end

# Bug #2: KeyError
get "/trigger/key-error" do
  user = USERS.find { |u| u.id == "USR-002" }
  settings = user.get_notification_settings
  content_type :json
  { settings: settings }.to_json
end

# Bug #3: NoMethodError
get "/trigger/no-method-error" do
  email = Services.get_task_assignee_email("TASK-103")
  content_type :json
  { email: email }.to_json
end

# Bug #4: ZeroDivisionError
get "/trigger/zero-division" do
  report = Services.generate_velocity_report("PROJ-001")
  content_type :json
  report.to_json
end

# Bug #5: IndexError
get "/trigger/index-error" do
  task = TASKS.find { |t| t.id == "TASK-101" }
  comment = task.get_latest_comment
  content_type :json
  { latest_comment: comment }.to_json
end

# Bug #6: Errno::ENOENT
get "/trigger/file-not-found" do
  config = Services.load_project_config("proj-1")
  content_type :json
  config.to_json
end

# Bug #7: JSON::ParserError
get "/trigger/json-parse-error" do
  data = Services.fetch_integration_data
  content_type :json
  data.to_json
end

# Bug #8: Encoding::UndefinedConversionError
post "/trigger/encoding-error" do
  decoded = Services.parse_incoming_webhook
  content_type :json
  { payload: decoded }.to_json
end

# Bug #9: SystemStackError
get "/trigger/recursion-error" do
  categories = Services.build_category_tree
  content_type :json
  { categories: categories }.to_json
end

# Bug #10: Errno::ECONNREFUSED
get "/trigger/connection-error" do
  result = Services.connect_to_database
  content_type :json
  result.to_json
end

# Bug #11: ArgumentError
post "/trigger/argument-error" do
  tasks = Services.import_tasks_from_csv
  content_type :json
  { imported: tasks.size }.to_json
end

# Bug #12: Errno::EACCES
get "/trigger/permission-error" do
  Services.write_export_file
  content_type :json
  { status: "exported" }.to_json
end

# Bug #13: Timeout::Error
get "/trigger/timeout-error" do
  result = Services.slow_aggregation_query
  content_type :json
  result.to_json
end

# Bug #14: NoMethodError from background thread
get "/trigger/thread-error" do
  Services.fire_background_notification
  content_type :json
  { status: "notification_sent" }.to_json
end

# Bug #15: NoMemoryError
post "/trigger/memory-error" do
  count = params[:count]
  result = Services.process_bulk_import(count)
  content_type :json
  { processed: result }.to_json
end

# ── Global Error Handler ──

error Exception do
  e = env["sinatra.error"]
  content_type :json
  status 500
  Utils.format_error_response(e).to_json
end
