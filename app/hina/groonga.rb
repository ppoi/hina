require 'json'

module Hina

  class Model

    module ModelExtensionMethods
      def entity_map
        @@entity_map ||= {}
      end

      def inherited(subclass)
        super
        table_name = subclass.name.split('::')[-1].to_sym
        table = Groonga[table_name]
        subclass.setup_model(table)
        entity_map[table_name] = subclass
      end

      protected
      def setup_model(table)
        @table = table
        @attributes = table.columns.map do |column|
          attr_name = column.local_name.to_sym
          define_attribute(attr_name)
          attr_name
        end
        extend ClassMethods
        include InstanceMethods
      end

      def define_attribute(name)
        define_method name do
          @values[name]
        end
        define_method "#{name}=" do |value|
          @modified_attributes << name unless @modified_attributes.nil? or @modified_attributes.include? name
          @values[name] = value
        end
      end
    end

    module ClassMethods
      attr_reader :table, :attributes

      def [](key, options={})
        record = table[key]
        record.nil? ? nil : new(record, options)
      end

      def select(options={}, &block)
        groonga_options = options.reject {|k,v| k.to_s.start_with?('model_')}
        table.select(groonga_options, &block).map do |record|
          new(record, options)
        end
      end
    end

    module InstanceMethods
      attr_reader :key

      def initialize(*args)
        if args.first.is_a? Groonga::Record
          sync(*args)
        else
          @key = args.first
          @values = args[1]
          @storead = false
        end
      end

      def sync(record=nil, options={})
        if @stored and record.nil?
          record = self.class.table[key]
        end
        unless record.nil?
          @key = record._key
          @values = {}
          target_attributes = options[:model_includes] || self.class.attributes
          target_attributes -= options[:model_excludes] if options.has_key?(:model_excludes)
          target_attributes.each do |attr|
            column = self.class.table.column(attr)
            next if column.index?
            value = record[attr]
            if column.reference?
              entity_class = self.class.entity_map[column.range.name.to_sym]
              if column.vector?
                value = value.map {|subrecord| entity_class.new(subrecord) }
              else
                value = entity_class.new(value)
              end
            end
            @values[attr] = value
          end
          @stored = true
          @modified_attribtues = []
        end
      end

      def save
        @stored ? update : create
      end

      def create
        values = {}
        @values.each do |key, value|
          next if value.nil?
          column = self.class.table.column key
          if column.reference?
            if column.vector?
              value = value.map {|item| item.key}
            else
              value = value.key
            end
          end
          values[key] = value
        end
        self.class.table.add @key, values
        @stored = true
      end

      def update
        unless @modified_attributes.nil? or @modified_attributes.empty?
          record = self.class.table[key]
          @modified_attributes.each do |attr|
            value = @values[attr]
            column = self.class.table.column attr
            if not value.nil? and column.reference?
              if column.vector?
                value = value.map {|item| item.key }
              else
                value = value.key
              end
            end
            record[attr] = value
          end
        end
      end

      def delete
        self.class.delete(key)
      end

      def to_json(*a)
        values = @values.dup
        values[:key] = key
        values.to_json
      end
    end

    extend ModelExtensionMethods
  end

end


class Time

  def to_json(*a)
    "\"#{strftime('%Y/%m/%d %H:%M:%S.%-2L')}\""
  end

end


