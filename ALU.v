`timescale 1ns/1ps
// ======================================================================
//  ALU_tb  - exhaustive sweep over FunSel for several data patterns
//  Compatible with Xilinx Vivado 2017 (pure Verilog-2001)
// ======================================================================
module ALU_tb;

   // ------------------------------------------------------------------
   //  DUT I/O
   // ------------------------------------------------------------------
   reg  [31:0] A, B;
   reg         CarryIn;
   reg  [4:0]  FunSel;
   wire [31:0] ALUOut;
   wire [3:0]  FlagsOut;        // {Z,C,N,O}

   //  Device Under Test
   ArithmeticLogicUnit dut (
       .A       (A),
       .B       (B),
       .CarryIn (CarryIn),
       .FunSel  (FunSel),
       .ALUOut  (ALUOut),
       .FlagsOut(FlagsOut)
   );

   // ------------------------------------------------------------------
   //  Test vectors - five useful operand pairs
   // ------------------------------------------------------------------
   reg [31:0] testA [0:4];
   reg [31:0] testB [0:4];

   initial begin
       testA[0] = 32'h0000_0000;  testB[0] = 32'h0000_0000;  // both zero
       testA[1] = 32'hFFFF_FFFF;  testB[1] = 32'h0000_0001;  // carry-out & zero detect
       testA[2] = 32'h7FFF_FFFF;  testB[2] = 32'h0000_0001;  // signed overflow +
       testA[3] = 32'h8000_0000;  testB[3] = 32'h8000_0000;  // signed overflow -
       testA[4] = 32'h1234_5678;  testB[4] = 32'h8765_4321;  // random mix
   end

   // ------------------------------------------------------------------
   //  Stimulus: loop over vectors, Cin = 0 / 1, FunSel = 0 … 31
   // ------------------------------------------------------------------
   integer v, cinVal, fs;
   initial begin
       $display("time  FunSel  Cin |          A          |          B          |      ALUOut   Z C N O");
       $display("---------------------------------------------------------------------------------------");
       
       for (v = 0; v < 5; v = v + 1) begin
           A = testA[v];
           B = testB[v];
           
           for (cinVal = 0; cinVal <= 1; cinVal = cinVal + 1) begin
               CarryIn = cinVal;

               for (fs = 0; fs < 32; fs = fs + 1) begin
                   FunSel = fs[4:0];
                   
                   #5; // allow combinational paths to settle
                   
                   $display("%4t   %02d    %b  | %08h | %08h | %08h   %b %b %b %b",
                            $time,
                            FunSel,
                            CarryIn,
                            A,
                            B,
                            ALUOut,
                            FlagsOut[3],
                            FlagsOut[2],
                            FlagsOut[1],
                            FlagsOut[0]
                   );
               end
           end
           $display("---------------------------------------------------------------------------------------");
       end
       $finish;
   end

endmodule
