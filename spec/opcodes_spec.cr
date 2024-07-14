require "./spec_helper"

module Tchipi8
  describe Tchipi8::Opcodes do
    describe :extract_operand1 do
      it "extracts first operand from instruction" do
        Opcodes.extract_operand1(0x8A69).should eq(0x000A)
        Opcodes.extract_operand1(0x1042).should eq(0)
      end
    end

    describe :extract_op2 do
      it "extracts second operand from instruction" do
        Opcodes.extract_operand2(0x6969).should eq(0x0006)
        Opcodes.extract_operand2(0x4209).should eq(0)
      end
    end

    describe :extract_long_operand do
      it "extracts long operand from instruction" do
        Opcodes.extract_long_operand(0x8426).should eq(0x0426)
        Opcodes.extract_long_operand(0xF10F).should eq(0x010F)
        Opcodes.extract_long_operand(0x1000).should eq(0)
        Opcodes.extract_long_operand(0x0000).should eq(0)
      end
    end
  end
end
