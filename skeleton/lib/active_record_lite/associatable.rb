require_relative 'searchable'
require 'active_support/inflector'

class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def initialize(name, options = {})
    options.each do |key, val|
      self.instance_variable_set(key, val)
    end
    @foreign_key ||= "#{name}_id".to_sym
    @primary_key ||= :id
    @class_name ||= name.to_s.camel_case
  end

  def model_class
    class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})

  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
  end
end

module Associatable
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    define_method(name) do
      options.model_class.where(
        options.primary_key => self.send(options.foreign_key)
      ).first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, options)
    define_method(name) do
      options.model_class.where(
        options.foreign_key => self.send(options.primary_key)
      )
    end
  end

  def has_one(name, options = {})

  end

  def has_one_through(name, options = {})
    options = HasManyOptions.new(name, options)
    <<-SQL
    SELECT
      #{options.}
    SQL
    define_method(name) do
      self.send(options.class_name).send(options.primary_key)
      ).first
    end
  end

  def assoc_options
  end
end
