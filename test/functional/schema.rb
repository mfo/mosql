require File.join(File.dirname(__FILE__), '_lib.rb')

class MoSQL::Test::Functional::SchemaTest < MoSQL::Test::Functional
  TEST_MAP = <<EOF
---
db:
  collection:
    :meta:
      :table: sqltable
    :columns:
      - _id: TEXT
      - var: INTEGER
      - arry: INTEGER ARRAY
  with_extra_props:
    :meta:
      :table: sqltable2
      :extra_props: true
    :columns:
      - _id: TEXT
  with_dotted:
    :meta:
      :table: sqltable3
      :extra_props: true
    :columns:
      - _id: TEXT
      - var_a:
        :source: vars.a
        :type: TEXT
      - var_b:
        :source: vars.b
        :type: TEXT
  with_nested_association:
    :meta:
      :table: sqltable4
      :extra_props: false
    :columns:
      - id:
        :source: _id
        :type: TEXT
      - title:
        :source: title
        :type: TEXT

    :nested:
      with_nested_serial_pkey:
        :meta:
          :table: sqltable5
          :extra_props: false
        :columns:
          - id:
            :source: '$serial'
            :type: 'SERIAL'
          - with_nested_association_id:
            :source: $parent id
            :type: TEXT
          - nested_attribute:
            :source: '$nested with_nested_association[]._id'
            :type: TEXT

EOF

  before do
    @map = MoSQL::Schema.new(YAML.load(TEST_MAP))

    @sequel.drop_table?(:sqltable)
    @sequel.drop_table?(:sqltable2)
    @sequel.drop_table?(:sqltable3)
    @sequel.drop_table?(:sqltable4)
    @sequel.drop_table?(:sqltable5)
    @map.create_schema(@sequel)
  end

  def table; @sequel[:sqltable]; end
  def table2; @sequel[:sqltable2]; end
  def table3; @sequel[:sqltable3]; end
  def table4; @sequel[:sqltable4]; end
  def table5; @sequel[:sqltable5]; end

  it 'Creates the tables with the right columns' do
    assert_equal(Set.new([:_id, :var, :arry]),
                 Set.new(table.columns))
    assert_equal(Set.new([:_id, :_extra_props]),
                 Set.new(table2.columns))
    assert_equal(Set.new([:id, :title]),
                 Set.new(table4.columns))
    assert_equal(Set.new([:id, :with_nested_association_id, :nested_attribute]),
                 Set.new(table5.columns))
  end

  it 'Can COPY data' do
    objects = [
               {'_id' => "a", 'var' => 0},
               {'_id' => "b", 'var' => 1, 'arry' => "{1, 2, 3}"},
               {'_id' => "c"},
               {'_id' => "d", 'other_var' => "hello"}
              ]
    @map.copy_data(@sequel, 'db.collection', objects.map { |o| @map.transform('db.collection', o) } )
    assert_equal(4, table.count)
    rows = table.select.sort_by { |r| r[:_id] }
    assert_equal(%w[a b c d], rows.map { |r| r[:_id] })
    assert_equal(nil, rows[2][:var])
    assert_equal(nil, rows[3][:var])
    assert_equal([1 ,2, 3], rows[1][:arry])
  end

  it 'Can COPY dotted data' do
    objects = [
               {'_id' => "a", 'vars' => {'a' => 1, 'b' => 2}},
               {'_id' => "b", 'vars' => {}},
               {'_id' => "c", 'vars' => {'a' => 2, 'c' => 6}},
               {'_id' => "d", 'vars' => {'a' => 1, 'c' => 7}, 'extra' => 'moo'}
              ]
    @map.copy_data(@sequel, 'db.with_dotted', objects.map { |o| @map.transform('db.with_dotted', o) } )
    assert_equal(4, table3.count)
    o = table3.first(:_id => 'a')
    assert_equal("1", o[:var_a])
    assert_equal("2", o[:var_b])

    o = table3.first(:_id => 'b')
    assert_equal({}, JSON.parse(o[:_extra_props]))

    o = table3.first(:_id => 'c')
    assert_equal({'vars' => { 'c' => 6} }, JSON.parse(o[:_extra_props]))

    o = table3.first(:_id => 'd')
    assert_equal({'vars' => { 'c' => 7}, 'extra' => 'moo' }, JSON.parse(o[:_extra_props]))
    assert_equal(nil, o[:var_b])
  end

  it 'Can COPY nested data' do
    ns = 'db.with_nested_association'
    objects = [
                {
                  '_id' => "id_parent",
                  'title' => 'woot',
                  'with_nested_serial_pkey' => [ { '_id' => 'nested attribute' } ]
                }
              ]
    transformed_objects = objects.map { |o| @map.transform(ns, o) }

    @map.copy_data(@sequel, ns, transformed_objects)
    nested = transformed_objects.first.nested
    @map.copy_data(@sequel, nested.first.ns, nested)
    assert_equal(1, table4.count, "should have created one row for root")
    o = table4.first({})
    assert_equal('id_parent', o[:id])
    assert_equal('woot', o[:title])

    assert_equal(1, table5.count, "should have created one row for nested assoc 1")
    o = table5.first({})
    assert_equal(1, o[:id])
    assert_equal('id_parent', o[:with_nested_association_id])
    assert_equal('nested attribute', o[:nested_attribute])
  end

  it 'Can COPY BSON::ObjectIDs' do
    o = {'_id' => BSON::ObjectId.new, 'var' => 0}
    @map.copy_data(@sequel, 'db.collection', [ @map.transform('db.collection', o)] )
    assert_equal(o['_id'].to_s, table.select.first[:_id])
  end

  it 'Can transform BSON::ObjectIDs' do
    o = {'_id' => BSON::ObjectId.new, 'var' => 0}
    row = @map.transform('db.collection', o)
    table.insert(row.attributes)
    assert_equal(o['_id'].to_s, table.select.first[:_id])
  end

  describe 'special field $timestamp' do
    SPECIAL_MAP_TIMESTAMP = <<EOF
---
db:
  collection:
    :meta:
      :table: special
    :columns:
      - _id: TEXT
      - mosql_updated:
        :source: $timestamp
        :type: timestamp
EOF

    before do
      @specialmap = MoSQL::Schema.new(YAML.load(SPECIAL_MAP_TIMESTAMP))

      @sequel.drop_table?(:special)
      @specialmap.create_schema(@sequel)
    end

    it 'sets a default on the column' do
      @sequel[:special].insert({_id: 'a'})
      row = @sequel[:special].select.first
      assert_instance_of(Time, row[:mosql_updated])
    end

    it 'Can populate $timestamp on COPY' do
      objects = [
                 {'_id' => "a"},
                 {'_id' => "b"}
                ]
      before = @sequel.select(Sequel.function(:NOW)).first[:now]
      @specialmap.copy_data(@sequel, 'db.collection',
                            objects.map { |o| @specialmap.transform('db.collection', o) } )
      after = @sequel.select(Sequel.function(:NOW)).first[:now]
      rows = @sequel[:special].select.sort_by { |r| r[:_id] }

      assert_instance_of(Time, rows[0][:mosql_updated])
      assert_operator(rows[0][:mosql_updated], :>, before)
      assert_operator(rows[0][:mosql_updated], :<, after)
    end
  end

  describe '$serial' do
    SPECIAL_MAP_SERIAL = <<EOF
---
db:
  collection:
    :meta:
      :table: special
    :columns:
      - id:
        :source: '$serial'
        :type: 'SERIAL'
      - title:
        :source: title
        :type: TEXT

EOF
    before do
      @specialmap = MoSQL::Schema.new(YAML.load(SPECIAL_MAP_SERIAL))

      @sequel.drop_table?(:special)
      @specialmap.create_schema(@sequel)
    end

    it 'serial type auto increments' do
      @sequel[:special].insert({})
      row1 = @sequel[:special].select.first
      assert_equal(1, row1[:id], 'row 1 should have id at 1')
    end

    it 'populate $serial on COPY' do
      objects = [
                 {"title" => 'row1'},
                 {"title" => 'row2'}
                ]
      @specialmap.copy_data(@sequel, 'db.collection',
                            objects.map { |o| @specialmap.transform('db.collection', o) } )
      rows = @sequel[:special].select.sort_by { |r| r[:id] }

      assert_equal(1, rows[0][:id])
      assert_equal(2, rows[1][:id])
    end
  end
end
