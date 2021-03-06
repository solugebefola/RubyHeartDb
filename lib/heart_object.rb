require_relative 'db_connection'
require 'active_support/inflector'
require_relative 'searchable'
require_relative 'associatable'

class HeartObject
  extend Searchable
  extend Associatable

    #insures column methods are generated automatically on first call
  def method_missing(method_sym, arguments = nil)
    method_reader = method_sym.to_s.sub("=", "").to_sym
    if self.class.columns.include?(method_reader)
      self.class.finalize!
      arguments ? self.send(method_sym, arguments) : self.send(method_sym)
    else
      super
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name || self.to_s.tableize
  end

  def self.columns
    @col_names ||= DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
    @col_names.first.map { |col| col.to_sym }
  end

  def self.finalize!
    define_method(:attributes) do
      @attributes ||= {}
    end
    columns.each do |column|
      define_method(column) do
        attributes[column]
      end
      define_method("#{column}=".to_sym) do |value|
        attributes[column] = value
      end
    end
  end

  def attribute_values
    self.class.columns.map { |col| send(col) }
  end

  def self.all
    attr_collections = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
    parse_all(attr_collections)
  end

  def self.parse_all(results)
    results.map { |result| self.new(result) }
  end

  def self.find(id)
    attr_collection = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{self.table_name}.id = ?
      LIMIT
        1
    SQL
    parse_all(attr_collection).first
  end

  def initialize(params = {})
    params.each do |attr_name, param|

      unless self.class.columns.include?(attr_name.to_sym)
        raise "unknown attribute '#{attr_name}'"
      end

      send("#{attr_name}=".to_sym, param)
    end
  end


  def insert
    col_names = self.class.columns.join(", ")

    question_marks = (["?"] * attribute_values.length).join(", ")

    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update_items
    update_items = self.class.columns.map { |(col, _)| "#{col} = ?"}
    update_items.reject { |item| item == "id = ?" }.join(", ")
  end


  def update
    DBConnection.execute(<<-SQL, *attribute_values.rotate)
      UPDATE
        #{self.class.table_name}
      SET
        #{update_items}
      WHERE
        id = ?
    SQL
  end

  def save
    self.id.nil? ? insert : update
  end
end
