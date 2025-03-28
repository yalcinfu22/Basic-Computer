`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.03.2025 16:50:16
// Design Name: 
// Module Name: InstructionRegSim
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module InstructionRegSim;
  reg LH;
  reg Write;
  reg [7:0] I;
  reg Clock;
  wire [15:0] IROut;
 
InstructionRegister IR1(
  .LH(LH),
  .Write(Write),
  .I(I),
  .Clock(Clock),
  .IROut(IROut)
  );
  
initial begin
  Clock = 1'b0;
  forever #5
    Clock = ~Clock;
end
   
initial begin
  LH = 1'b1;
  Write = 1'b1;
  I = 8'h55;
  #10;
  Write = 1'b0;
  LH = ~LH;
  I = 8'hFF;
  #10;
  Write = 1'b1;
  I = 8'hAA;
  #10;
end
endmodule
