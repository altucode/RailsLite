module SQL

  class Query < Object

    def initialize(options = {})

      @objects = []
      @alias = nil
      @parts = {}
    end

    def to_sql
      sql = <<-SQL
      SELECT #{@parts[:select].empty? ? '*' : @parts[:select].join(', ')}
      FROM #{@parts[:from]}
      #{'WHERE ' + @parts[:where].join(' AND ') unless @parts[:where].empty?}
      #{'GROUP BY ' + @parts[:group].join(', ') unless @parts[:group].empty?}
      #{'HAVING ' + @parts[:having].join(' AND ') unless @parts[:having].empty?}
      #{'ORDER BY ' + @parts[:order].join(', ') unless @parts[:order].empty?}
      ;
      SQL
    end

    def [](part)
      @parts[part] ||= Array.new
    end

    def nest_id
      self[:from].max {}
    end

    def select(*params)
      if params.first.is_a?(String)
        query = Query.new
        query[:from] << self

        query
      else
        params = params.map { |p| Expression.new(p.ensure_flat_array)}
        self[:select].concat(params)
        self[:select].uniq!.keep_if { |p| params.include?(p) || p.has_alias? }

        self
      end
    end

    def joins(*params)
      internal_joins(@table, params)
    end

    def where(*params)
      self[:where].concat(params.map { |p| Condition.new(p.ensure_flat_array) })

      self
    end

    def group(*params)
      self[:group].concat(params)
    end

    def having(*params)
      self[:having].concat(params.map { |p| Condition.new(p.ensure_flat_array)} )

      self
    end

    def order(*params)
      self[:order] = params.map { |p| p.ensure_flat_array.join(' ') }.concat(self[:order])

      self
    end

    private
    def self.internal_joins(table, *params)
      params.each_with_object('') do |param, str|
        if param.is_a?(Hash)
          str << internal_joins(param.first[0], param.first[1])
        else
          str << "JOIN #{param}"
        end
      end
    end
    def self.convert_to_sql(obj, prefix = false)
      case obj
      when Hash
        "(#{obj.first[0]} #{convert_to_sql(obj.first[1], true)})"
      when Range
        "BETWEEN #{obj.min} AND #{obj.max}"
      when Array
        "#{'IN ' if prefix}#{obj}"
      when String
        "#{'= ' if prefix}'#{obj}'"
      else
        "#{'= ' if prefix}#{obj}"
      end
    end


  end

  class Expression
    attr_reader :expression
    def initialize(*params)
      i = 0
      @expression = params[0].to_s.gsub(/\?/) { |match| params[i+=1] }
      @alias = params[i+=1]
    end

    def ==(other)
      other.expression = self.expression
    end

    def has_alias?
      !!@alias
    end

    def to_s
      "#{@expression.to_s}#{' AS ' + @alias if @alias}"
    end
  end

  class Condition
    attr_reader :field, :condition
    def initialize(*params)
      @field = params[0]
      @condition = params[1]
    end

    def ==(other)
      other.field == self.field && other.condition = self.condition
    end

    def eval_condition
      case @condition
      when Range
        return " BETWEEN #{@condition.min} AND #{@condition.max}"
      when Array, Query
        return " IN #{@condition}"
      when String
        return "LIKE #{@condition}" if @condition.include?('%')
      end

      " = #{obj}"
    end

    def to_s
      "(#{@field}#{eval_condition})"
    end
  end

  class Order
    def initialize(*params)
      @field = params[0]
      @dir = params[1]
    end

    def to_str
      "#{@field} #{@dir}"
    end
  end

  class Table
    def initialize(*params)
      @target = params[0]
    end
  end

end

def sql_placeholders(joiner)
  self.map.with_index(1).to_a.map_send(:join, ' = $').join(joiner)
end

class Hash
  def map_send(m, params*)
    self.map do |key, value|

    end
  end
end

class Object
  def ensure_flat_array
    Array(self).flatten
  end
end

module Searchable
  def self.where(params*)
    db.exec_params(<<-SQL, params.values)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        params.keys.sql_placeholders(' AND ')
    SQL
  end
end