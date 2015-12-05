require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name || self.to_s.tableize
  end

  def self.columns
    @cols_and_data ||= DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
    @cols_and_data.first.map { |col| col.to_sym }
  end

  def self.finalize!
    define_method(:attributes) do
      @attributes ||= {}
    end
    columns.each do |column|
      define_method(column) do
        # self.instance_variable_get("@#{column}")
        attributes[column]
      end
      define_method("#{column}=".to_sym) do |value|
        # self.instance_variable_set("@#{column}",value)
        attributes[column] = value
      end
    end
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

  def attributes
    # ...
  end

  def attribute_values
    self.class.columns.map { |col| send(col) }
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
    update_items = self.class.columns.map { |(col, val)| "#{col} = ?"}
    update_items.reject { |item| item == "id = ?" }.join(", ")
  end


  def update
    puts attribute_values
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
