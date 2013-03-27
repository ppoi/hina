require 'spec_helper'

module Hina
  module Test
    class TestEntity < Hina::Models::Base
      define_attributes :col1, :col2, :col3
      define_attribute :col4, :writable=>false
    end
  end
end

describe 'Hina::Models' do

  describe 'Base' do

    it 'can access attributes' do
      e = Hina::Test::TestEntity.new(id:123)
      e.col1 = 39
      e.col2 = 3939
      e.col3 = 'miku'
      e.id.should eq 123
      e.col1.should eq 39
      e.col2.should eq 3939
      e.col3.should eq 'miku'
    end

    it 'can access attributes using [] operator' do
      e = Hina::Test::TestEntity.new
      e[:col1] = 39
      e[:col2] = 'miku'
      e.col1.should eq 39
      e[:col1].should eq 39
      e.col2.should eq 'miku'
      e[:col2].should eq 'miku'
    end

    it 'cannot write readonly attribute' do
      e = Hina::Test::TestEntity.new({:col1=>'miku',:col4=>39})
      e.col4.should eq 39
      expect {
        e.col4 = 3939
      }.to raise_error NoMethodError
      expect {
        e[:col4] = 3939
      }.to raise_error NoMethodError
    end

    it 'can set default values' do
      e = Hina::Test::TestEntity.new({:col1=>'miku',:col2=>39,:col3=>'39'})
      e.col1.should eq 'miku'
      e.col2.should eq 39
      e.col3.should eq '39'
    end
  end

end
