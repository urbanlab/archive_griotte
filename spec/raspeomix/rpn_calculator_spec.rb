require_relative '../spec_helper'
require 'raspeomix/rpn_calculator'

describe "RPNCalculator with dual operands" do
  before(:each) do
    @a,@b = rand(100)+1.to_f, rand(100)+1.to_f
#    puts "#{@a} #{@b}"
  end

  it "should add two numbers" do
    RPNCalculator.evaluate("#{@a} #{@b} +").should eq(@a + @b)
  end

  it "should substract two numbers" do
    RPNCalculator.evaluate("#{@a} #{@b} -").should eq(@a - @b)
  end

  it "should divide two numbers" do
    RPNCalculator.evaluate("#{@a} #{@b} /").should eq(@a / @b)
  end

  it "should multiply two numbers" do
    RPNCalculator.evaluate("#{@a} #{@b} *").should eq(@a * @b)
  end
  
  it "should square two numbers" do
    RPNCalculator.evaluate("#{@a} #{@b} **").should eq(@a ** @b)
  end

  it "should compare two numbers with >" do
    RPNCalculator.evaluate("#{@a} #{@b} >").should eq(@a > @b)
  end 

  it "should compare two numbers with <" do
    RPNCalculator.evaluate("#{@a} #{@b} <").should eq(@a < @b)
  end 
  
  it "should compare two numbers with >=" do
    RPNCalculator.evaluate("#{@a} #{@b} >=").should eq(@a >= @b)
  end 

  it "should compare two numbers with <=" do
    RPNCalculator.evaluate("#{@a} #{@b} <=").should eq(@a <= @b)
  end 

  it "should compare two equal numbers with >=" do
    RPNCalculator.evaluate("#{@a} #{@a} >=").should eq(true)
  end 

  it "should compare two equal numbers with <=" do
    RPNCalculator.evaluate("#{@a} #{@a} <=").should eq(true)
  end 

  it "should 'or' booleans" do
    RPNCalculator.evaluate("true true |").should eq(true)
    RPNCalculator.evaluate("true false |").should eq(true)
    RPNCalculator.evaluate("false true |").should eq(true)
    RPNCalculator.evaluate("false false |").should eq(false)
  end 

  it "should 'and' booleans" do
    RPNCalculator.evaluate("true true &").should eq(true)
    RPNCalculator.evaluate("true false &").should eq(false)
    RPNCalculator.evaluate("false true &").should eq(false)
    RPNCalculator.evaluate("false false &").should eq(false)
  end

  it "should return modulo" do
    RPNCalculator.evaluate("#{@a} #{@b} modulo").should eq(@a.modulo(@b))
  end

  it "should round" do
    @a = rand(100)+rand
    RPNCalculator.evaluate("#{@a} 5 round").should eq(@a.round(5))
  end
end

describe "RPNCalculator with single operand" do
  before(:each) do
    @a = rand(100)+rand.to_f
  end

  it "should return absolute value" do
    RPNCalculator.evaluate("#{@a} abs").should eq(@a.abs)
    @a = -@a
    RPNCalculator.evaluate("#{@a} abs").should eq(@a.abs)
  end

  it "should return floor value" do
    RPNCalculator.evaluate("#{@a} floor").should eq(@a.floor)
  end

  it "should return ceiling value" do
    RPNCalculator.evaluate("#{@a} ceil").should eq(@a.ceil)
  end
end

