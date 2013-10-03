module IRuby
  class IRubyObject
    attr_reader :data, :mime

    def initialize(mime, data)
      @mime, @data = mime, data
    end

    def to_iruby
      [@mime, @data]
    end
  end

  def self.display(obj, options={})
    Kernel.instance.display(obj, options)
  end

  def self.table(obj)
    return obj unless Enumerable === obj
    keys = nil
    size = 0
    rows = []
    obj.each do |row|
      row = row.flatten(1) if obj.respond_to?(:keys)
      if row.respond_to?(:keys)
        # Array of Hashes
        keys ||= Set.new
        keys.merge(row.keys)
      elsif row.respond_to?(:size)
        # Array of Arrays
        size = row.size if size > row.size
      end
      rows << row
    end
    table = '<table>'
    if keys
      keys.merge(0...size)
      table << '<tr>' << keys.map {|k| "<th>#{k}</th>"}.join << '</tr>'
      rows.each do |row|
        if row.respond_to?(:map)
          table << '<tr>' << keys.map {|k| "<td>#{row[k] rescue nil}</td>" }.join << '</tr>'
        else
          table << "<tr><td colspan='#{keys.size}'>#{row}</td></tr>"
        end
      end
    else
      rows.each do |row|
        if row.respond_to?(:map)
          table << '<tr>' << row.map {|i| "<td>#{i}</td>" }.join << '</tr>'
        else
          table << "<tr><td colspan='#{size}'>#{row}</td></tr>"
        end
      end
    end
    html(table << '</table>')
  end

  def self.latex(s)
    IRubyObject.new('text/latex', s)
  end

  def self.math(s)
    IRubyObject.new('text/latex', "$$#{s}$$")
  end

  def self.html(s)
    IRubyObject.new('text/html', s)
  end
end
