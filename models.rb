# Data models with intentionally seeded bugs for Bugboy Ruby

class User
  attr_accessor :id, :first_name, :last_name, :email, :preferences

  def initialize(id:, first_name:, last_name:, email:, preferences: {})
    @id = id
    @first_name = first_name
    @last_name = last_name
    @email = email
    @preferences = preferences
  end

  # Bug #1: TypeError — last_name is nil for some users, so string + nil raises TypeError
  def get_display_name
    full = first_name + " " + last_name
    full.strip
  end

  # Bug #2: KeyError — preferences hash missing 'notifications' key; fetch raises KeyError
  def get_notification_settings
    preferences.fetch("notifications")
  end
end

class Task
  attr_accessor :id, :title, :status, :assignee, :comments, :priority

  def initialize(id:, title:, status:, assignee: nil, comments: [], priority: 1)
    @id = id
    @title = title
    @status = status
    @assignee = assignee
    @comments = comments
    @priority = priority
  end

  # Bug #5: IndexError — calling fetch with out-of-range index on empty comments array
  def get_latest_comment
    comments.fetch(-1)
  end
end

class Project
  attr_accessor :id, :name, :settings, :tasks

  def initialize(id:, name:, settings: {}, tasks: [])
    @id = id
    @name = name
    @settings = settings
    @tasks = tasks
  end
end

class CategoryNode
  attr_accessor :name, :children

  def initialize(name:, children: [])
    @name = name
    @children = children
  end
end

# ── Seed Data ──

USERS = [
  User.new(
    id: "USR-001",
    first_name: "Alice",
    last_name: "Johnson",
    email: "alice@example.com",
    preferences: { "theme" => "dark", "language" => "en" }
  ),
  User.new(
    id: "USR-002",
    first_name: "Bob",
    last_name: nil,  # Bug seed: nil last_name triggers TypeError in get_display_name
    email: "bob@example.com",
    preferences: { "theme" => "light" }  # Bug seed: missing 'notifications' key
  ),
  User.new(
    id: "USR-003",
    first_name: "Carol",
    last_name: "Williams",
    email: "carol@example.com",
    preferences: { "theme" => "dark", "notifications" => { "email" => true, "sms" => false } }
  )
].freeze

TASKS = [
  Task.new(
    id: "TASK-101",
    title: "Set up CI pipeline",
    status: "in_progress",
    assignee: USERS[0],
    comments: []  # Bug seed: empty comments triggers IndexError in get_latest_comment
  ),
  Task.new(
    id: "TASK-102",
    title: "Write API documentation",
    status: "done",
    assignee: USERS[2],
    comments: ["Looks good!", "Merged."]
  ),
  Task.new(
    id: "TASK-103",
    title: "Fix login redirect",
    status: "open",
    assignee: nil,  # Bug seed: nil assignee triggers NoMethodError
    comments: ["Needs investigation"]
  )
].freeze

PROJECTS = [
  Project.new(
    id: "PROJ-001",
    name: "Alpha Release",
    settings: { "sprint_length_days" => 0 },  # Bug seed: zero sprint length for ZeroDivisionError
    tasks: TASKS
  )
].freeze
