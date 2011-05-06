class Mars::UI::ElementSet

  class DuplicateElementNameError < StandardError; end
  class ElementNameNotFoundError < StandardError; end

  def initialize(id, default_element_class)
    @elements = []
    @sequences = []
    @default_element_class = default_element_class
    @element_set_id = id
  end

  attr_accessor :sequences

  def add(name, options = {})
    options.symbolize_keys!
    element_class = @default_element_class
    if self[name]
      raise DuplicateElementNameError.new("duplicate tab name `#{name}'")
    elsif type = options[:type]
      element_class = "Mars::UI::#{type.to_s.camelize}".constantize
    end
    options[:element_set_id] = @element_set_id
    @elements << element_class.new(name, options)
  end

  def [](index_or_name)
    if index_or_name.kind_of? Integer
      @elements[index_or_name]
    else
      @elements.find { |e| e.name == index_or_name }
    end
  end

  def remove(name)
    if self[name].nil?
      raise ElementNameNotFoundError, "#{name} element is not found, so it don't remove"
    end
    @elements.delete(self[name])
  end

  def each
    if @sequences.empty?
      @elements.each {|e| yield e }
    else
      @sequences.each {|name| yield self[name] if self[name] } 
    end
  end

  def sequences=(seqs)
    @sequences = seqs.map(&:to_sym)
  end

  def clear
    @elements.clear
  end

  def empty?
    @elements.empty?
  end

  include Enumerable
end
