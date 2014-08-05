require 'pg'
require 'active_support/inflector'

module ActiveRecordLite

  class Base < SQLObject
    finalize!
  end

  class SQLObject
    @@table_name
    def self.columns
      db.exec("SELECT * FROM #{sec.table_name}").fields.map &:to_sym
    end

    def self.finalize!
      self.columns.each do |field|
        define_method("#{field}") { @attributes[field] }
        define_method("#{field}=") { |val| @attributes[field] = val }
      end
    end

    def self.table_name=(table_name)
    end

    def self.table_name
    end

    def self.all
      parse_all(db.exec("SELECT * FROM #{self.table_name}"))
    end

    def self.parse_all(results)
      results.map { |result| self.new(result) }
    end

    def self.find(id)
      db.exec_params(<<-SQL, id)
        SELECT
          *
        FROM
          #{self.table_name}
        WHERE
          #{self.table_name}.id = $1
      SQL
    end

    def attributes
    end

    def insert
      db.prepare('ins', <<-SQL)
        INSERT INTO #{self.table_name}
          (#{@attributes.keys.join(', ')})
        VALUES
          ($#{(1..@attributes.length).to_a.join(', $')})
        RETURNING id
      SQL

      result = db.exec_prepared('ins', @attributes.values)
      @attributes[:id] = result[0]['id']
    end

    def initialize(params = {})
      @attributes = {}
      params.each do |key, val|
        raise "unknown attribute #{key}" unless columns.include?(key.to_sym)
        self.send("#{key}=", val)
      end
    end

    def save
      id.nil? ? self.insert : self.update
    end

    def update
      db.exec_params(<<-SQL, @attributes.values, self.id)
        UPDATE
          #{self.table_name}
        SET
          #{@attributes.keys.sql_placeholders(', )}
        WHERE
        id = $#{@attributes.length+1}
      SQL
    end

    def self.table_name
      @@table_name ||= self.name.tableize
    end

    def self.table_name=(table_name)
      @@table_name = table_table
    end

    def self.db
      PG::Connection.open(dbname: self.table_name)
    end

    private

    def self.
  end

end

module Enumerable
  def map_send(*args)
    map { |x| x.send(*args) }
  end

  def sql_placeholders(joiner)
    self.map.with_index(1).to_a.map_send(:join, ' = $').join(joiner)
  end
end