require 'sqlite3'
require 'pg'

module Connection
  def connection
    if @database_platform == :sqlite3
      @connection ||= SQLite3::Database.new(BlocRecord.database_filename)
    elsif @database_platform == :pg
      @connection ||= PostgreSQL::Database.new(BlocRecord.database_filename)
    else
      raise "Error has occurred in Connection."
    end
  end
end