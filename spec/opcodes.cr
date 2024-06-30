require "./spec_helper"

describe Tchipi8 do
  context :extract_operand1 do
    it "extracts first operand from instruction" do
      Tchipi8.extract_operand1(0x8A69).should eq(0x0008)
      Tchipi8.extract_operand1(0x1042).should eq(0)
    end
  end

  context :extract_op2 do
    it "extracts second operand from instruction" do
      Tchipi8.extract_operand2(0x6969).should eq(0x0006)
      Tchipi8.extract_operand2(0x4209).should eq(0)
    end
  end

  context :extract_long_operand do
    it "extracts long operand from instruction" do
      Tchipi8.extract_long_operand(0x8426).should eq(0x0426)
      Tchipi8.extract_long_operand(0xF10F).should eq(0x010F)
      Tchipi8.extract_long_operand(0x1000).should eq(0)
      Tchipi8.extract_long_operand(0x0000).should eq(0)
    end
  end
end
