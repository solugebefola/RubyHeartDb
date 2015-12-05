require_relative 'searchable'
require 'active_support/inflector'

class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    model_class.table_name || class_name.tableize
  end

end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    name_id = "#{name.to_s.underscore}_id".to_sym
    classy_name = "#{name}".camelize

    defaults = {
      foreign_key: name_id,
      primary_key: :id,
      class_name: classy_name
    }
    new_keys = defaults.merge(options)

    @name = name
    @foreign_key = new_keys[:foreign_key]
    @class_name = new_keys[:class_name]
    @primary_key = new_keys[:primary_key]

  end

end

class HasManyOptions < AssocOptions
  def initialize(name, self_name, options = {})
    self_name_id = "#{self_name.underscore}_id".to_sym
    classy_name = "#{name}".camelize.singularize

    defaults = {
      foreign_key: self_name_id,
      primary_key: :id,
      class_name: classy_name
    }

    new_keys = defaults.merge(options)

    @name = name
    @foreign_key = new_keys[:foreign_key]
    @class_name = new_keys[:class_name]
    @primary_key = new_keys[:primary_key]
  end
end

module Associatable
  def belongs_to(name, options = {})
    opts = BelongsToOptions.new(name, options)
    self.assoc_options[name] = opts

    define_method(name) do
      foreign = self.send(opts.foreign_key)
      bind = {opts.primary_key => foreign}

      opts.model_class.where(bind).first
    end
  end

  def has_many(name, options = {})
    opts = HasManyOptions.new(name, self.to_s, options)
    model_class = opts.class_name.constantize

    define_method(name) do
      model_class = opts.class_name.constantize
      foreign = self.send(opts.primary_key)

      model_class.where({opts.foreign_key => foreign})
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end

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

end
