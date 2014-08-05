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