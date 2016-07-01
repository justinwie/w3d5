require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    return @columns if @columns
    all = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL

    result = all.first.map do |el|
      el.to_sym
    end

    @columns = result
  end

  def self.finalize!
    columns.each do |col|

      define_method(col) do
        self.attributes[col]
      end

      define_method("#{col}=") do |value|
        self.attributes[col] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= (self.name.downcase.pluralize)
  end

  def self.all
    attributes = DBConnection.execute(<<-SQL)
      SELECT
        #{self.table_name}.*
      FROM
        #{self.table_name}
    SQL
    parse_all(attributes)
  end

  def self.parse_all(results)
    results.map { |result| self.new(result) }
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL, id)
      SELECT
        #{self.table_name}.*
      FROM
        #{self.table_name}
      WHERE
        #{self.table_name}.id = ?
      LIMIT
        1
    SQL
    parse_all(result).first
  end

  def initialize(params = {})
    params.each do |attr_name, v|
      attr_name = attr_name.to_sym
      if !self.class.columns.include?(attr_name)
        raise "unknown attribute '#{attr_name}'"
      else
        self.send("#{attr_name}=", v)
      end
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    # @attributes.values
    self.class.columns.map do |col|
      self.send("#{col}")
    end
  end

  def insert

    length = attribute_values.length
    DBConnection.execute(<<-SQL, attribute_values, length)
    INSERT INTO
      #{self.table_name}(?)
    VALUES
      ["?"] * ?
    SQL

  end

  def update
    # ...
  end

  def save
    # ...
  end
end
