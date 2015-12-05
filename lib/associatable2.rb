require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    through_options = assoc_options[through_name]
    source_options = through_options.model_class.assoc_options[source_name]
    through_table = through_options.table_name.to_s
    source_table = source_options.table_name.to_s
    through_foreign = "#{through_table}.#{source_options.foreign_key}"
    source_primary = "#{source_table}.#{source_options.primary_key}"
    through_where = "#{through_options}"
    source_class = source_options.model_class


    define_method(name) do
      foreign = self.send(through_options.foreign_key)
      # bind = {through_options.primary_key => foreign}
      # debugger
      the_one = DBConnection.execute(<<-SQL, foreign)
        SELECT
          #{source_table}.*
        FROM
          #{source_table}
        JOIN
          #{through_table}
          ON #{through_foreign}=#{source_primary}
        WHERE
          #{through_table}.#{through_options.primary_key}= ?
      SQL
      the_one.map { |attributes| source_class.new(attributes)}.first
    end
  end

  # def through_name(through)
  #   assoc_options[through]
  # end
end
