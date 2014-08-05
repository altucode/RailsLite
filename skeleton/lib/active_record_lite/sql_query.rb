class SQLQuery < Object

  def initialize(options = {})
    @objects = []
    @select = []
    @from = ''
    @where = []
  end

  def to_sql
    sql = <<-SQL
    SELECT
      #{@select.join(', ')}
    FROM
      #{@from.to_s}
    SQL
    unless @where.empty?
      sql.concat(<<-SQL)
      WHERE
        #{@where.map(&:to_s).join(' AND ')}
      SQL
    end
  end

  def to_s
    self.to_sql
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