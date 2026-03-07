require "json"

module Utils
  def self.format_error_response(error)
    {
      error: error.class.name,
      message: error.message,
      backtrace: error.backtrace&.first(15)
    }
  end
end
