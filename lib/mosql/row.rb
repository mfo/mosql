# identify a Row... no a grape, maybe a batch, something like nested_row, associative_rows, dependentrow
# TODO: spec Row modeling
module MoSQL
  class Row
    attr_reader :attributes,
                :nested,
                :ns,
                :schema,
                :parent

    def initialize(ns, schema, parent = nil)
      @ns = ns
      @schema = schema

      if parent
        @parent = parent
        @parent.add_nested(self)
      end

      @attributes = []
      @nested = []

      self
    end

    def as_upsert(_schema)
      h = {}
      cols = _schema.all_columns(_schema.find_ns(ns))
      cols.zip(attributes).each { |k,v| h[k] = v }
      h
    end
    # row sql
    # nested sql
    # FIXME: safe loopup for pkey
    def parent_pkey
      @parent.attributes.first
    end

    def <<(val)
      @attributes.push(val)
    end

    def add_nested(val)
      @nested.push(val)
    end

    def size
      1 + nested.size
    end

    def to_s
      attributes.join(', ')
    end
  end
end