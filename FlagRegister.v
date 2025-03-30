`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.03.2025 15:57:35
// Design Name: 
// Module Name: FlagRegister
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


module FlagRegister(I,Z,C,N,O);
 input wire [3:0] I;
 output reg Z;
 output reg C;
 output reg N;
 output reg O;
 
 always @(*) begin
  Z = I[3]; // Zero flag (MSB)
  C = I[2]; // Carry flag
  N = I[1]; // Negative flag
  O = I[0]; // Overflow flag (LSB)
 end
endmodule
