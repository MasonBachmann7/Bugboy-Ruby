require "json"
require "socket"
require "timeout"
require "fileutils"
require_relative "models"

module Services
  # Bug #3: NoMethodError — accessing .email on nil assignee
  def self.get_task_assignee_email(task_id)
    task = TASKS.find { |t| t.id == task_id }
    raise "Task not found: #{task_id}" unless task

    # TASK-103 has assignee = nil, so calling .email on nil raises NoMethodError
    assignee_email = task.assignee.email
    assignee_email
  end

  # Bug #4: ZeroDivisionError — sprint_length_days is 0
  def self.generate_velocity_report(project_id)
    project = PROJECTS.find { |p| p.id == project_id }
    raise "Project not found: #{project_id}" unless project

    total_points = project.tasks.sum { |t| t.priority }
    sprint_length = project.settings["sprint_length_days"]

    return { project: project.name, velocity: 0, total_points: total_points } if sprint_length.to_i == 0

    velocity = total_points / sprint_length
    { project: project.name, velocity: velocity, total_points: total_points }
  end

  # Bug #6: Errno::ENOENT — loading config from a path that doesn't exist
  def self.load_project_config(project_id)
    config_path = "config/projects/#{project_id}.json"
    raw = File.read(config_path)
    JSON.parse(raw)
  end

  # Bug #7: JSON::ParserError — parsing malformed JSON from a simulated webhook
  def self.fetch_integration_data
    # Simulated third-party webhook response with malformed JSON (unquoted key)
    raw_response = '{ status: "ok", timestamp: 1700000000 }'
    data = JSON.parse(raw_response)
    data
  end

  # Bug #8: Encoding::UndefinedConversionError — processing payload with invalid bytes
  def self.parse_incoming_webhook
    # Simulated incoming webhook payload with invalid UTF-8 bytes
    raw_payload = "user_id=42&name=Ren\xE9\xFC&action=update".b
    decoded = raw_payload.encode("UTF-8", "UTF-8", invalid: :raise, undef: :raise)
    decoded
  end

  # Bug #9: SystemStackError — circular category tree causes infinite recursion
  def self.build_category_tree
    root = CategoryNode.new(name: "Engineering")
    child = CategoryNode.new(name: "Backend")
    grandchild = CategoryNode.new(name: "APIs")

    root.children << child
    child.children << grandchild
    grandchild.children << root  # Circular reference!

    flatten_categories(root)
  end

  def self.flatten_categories(node, result = [])
    result << node.name
    node.children.each { |c| flatten_categories(c, result) }
    result
  end

  # Bug #10: Errno::ECONNREFUSED — connecting to an unreachable database host
  def self.connect_to_database
    socket = TCPSocket.new("db.internal.local", 5432)
    socket.close
    { status: "connected" }
  end

  # Bug #11: ArgumentError — invalid integer conversion from CSV data
  def self.import_tasks_from_csv
    csv_rows = [
      { "title" => "Design review", "priority" => "3" },
      { "title" => "Code audit", "priority" => "high" },  # "high" is not a valid integer
      { "title" => "Deploy staging", "priority" => "1" }
    ]

    csv_rows.map do |row|
      Task.new(
        id: "IMPORT-#{rand(1000)}",
        title: row["title"],
        status: "open",
        priority: Integer(row["priority"])
      )
    end
  end

  # Bug #12: Errno::EACCES — writing to a read-only file
  def self.write_export_file
    export_dir = "tmp/exports"
    FileUtils.mkdir_p(export_dir)
    export_path = File.join(export_dir, "project_export.json")

    # Create a read-only file simulating a previous backup lock
    File.write(export_path, '{"locked": true}')
    File.chmod(0o444, export_path)

    # Now try to overwrite it — raises Errno::EACCES
    File.write(export_path, '{"data": "new export"}')
  ensure
    # Clean up: restore write permission so the file can be deleted later
    File.chmod(0o644, export_path) if File.exist?(export_path)
  end

  # Bug #13: Timeout::Error — slow aggregation exceeds timeout
  def self.slow_aggregation_query
    Timeout.timeout(2) do
      # Simulate a slow database aggregation that takes 10 seconds
      sleep(10)
      { result: "aggregated_data" }
    end
  end

  # Bug #14: RuntimeError from background thread — notification handler crashes
  def self.fire_background_notification
    exception_holder = Queue.new

    thread = Thread.new do
      notification = { "type" => "alert", "user_id" => "USR-001" }
      # Bug: accessing missing 'template' key and calling .gsub on nil
      message = notification["template"].gsub("{{user}}", notification["user_id"])
      message
    end

    thread.join

    # If the thread raised, re-raise in the main thread
    if thread.status.nil?
      begin
        thread.value
      rescue => e
        raise e
      end
    end
  end

  # Bug #15: NoMemoryError — building an O(n^2) in-memory cross-reference index
  def self.process_bulk_import(count)
    count = (count || 500_000).to_i
    records = Array.new(count) { |i| { id: i, data: "x" * 100 } }

    # Build cross-reference index: each record references all others — O(n^2) memory
    cross_ref = {}
    records.each do |r|
      cross_ref[r[:id]] = records.map { |other| other[:data] }
    end

    cross_ref.size
  end
end
