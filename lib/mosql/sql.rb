module MoSQL
  class SQLAdapter
    include MoSQL::Logging

    attr_reader :db

    def initialize(schema, uri, pgschema=nil)
      @schema = schema
      connect_db(uri, pgschema)
      @db.extension :pg_array
    end

    def connect_db(uri, pgschema)
      @db = Sequel.connect(uri, :after_connect => proc do |conn|
                             if pgschema
                               begin
                                 conn.execute("CREATE SCHEMA \"#{pgschema}\"")
                               rescue PG::Error
                               end
                               conn.execute("SET search_path TO \"#{pgschema}\"")
                             end
                           end)
    end

    def table_for_ns(ns)
      @db[@schema.table_for_ns(ns).intern]
    end

    # TODO: spec table for row
    def table_for_row(row)
      @db[@schema.table_for_ns(row.ns).intern]
    end

    # TODO: spec extract row extract is done with a Row
    def transform_one_ns(ns, obj)
      @schema.transform(ns, obj)
    end

    # TODO: spec upsert nested rows
    def upsert_ns(ns, obj)
      row = transform_one_ns(ns, obj)
      h = row.as_upsert(@schema)
      upsert!(table_for_ns(ns), @schema.primary_sql_key_for_ns(ns), h)

      row.nested.each do |nested_row|
        nested_ns = nested_row.ns
        h_nested = nested_row.as_upsert(@schema)
        upsert!(table_for_ns(nested_ns), @schema.primary_sql_key_for_ns(ns), h_nested)
      end
    end

    def delete_ns(ns, obj)
      primary_sql_keys = @schema.primary_sql_key_for_ns(ns)
      row = transform_one_ns(ns, obj)
      h = row.as_upsert(@schema)
      query = {}
      primary_sql_keys.each do |key|
        raise "No #{primary_sql_keys} found in transform of #{obj.inspect}" if h[key].nil?
        query[key.to_sym] = h[key]
      end

      table_for_ns(ns).where(query).delete
    end

    def upsert!(table, table_primary_keys, item)
      query = {}
      table_primary_keys.each do |key|
        query[key.to_sym] = item[key]
      end
      rows = table.where(query).update(item)
      if rows == 0
        begin
          table.insert(item)
        rescue Sequel::DatabaseError => e
          raise e unless self.class.duplicate_key_error?(e)
          log.info("RACE during upsert: Upserting #{item} into #{table}: #{e}")
        end
      elsif rows > 1
        log.warn("Huh? Updated #{rows} > 1 rows: upsert(#{table}, #{item})")
      end
    end

    def self.duplicate_key_error?(e)
      # c.f. http://www.postgresql.org/docs/9.2/static/errcodes-appendix.html
      # for the list of error codes.
      #
      # No thanks to Sequel and pg for making it easy to figure out
      # how to get at this error code....
      e.wrapped_exception.result.error_field(PG::Result::PG_DIAG_SQLSTATE) == "23505"
    end

    def self.duplicate_column_error?(e)
      e.wrapped_exception.result.error_field(PG::Result::PG_DIAG_SQLSTATE) == "42701"
    end
  end
end

