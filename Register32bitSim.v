`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.03.2025 13:38:41
// Design Name: 
// Module Name: Register32bitSim
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


module Register32bitSim;
  reg [2:0] FunSel;
  reg [31:0] I;
  reg E;
  reg Clock;
  wire [31:0] Q;

Register32bit reg1(
  .FunSel(FunSel),
  .I(I),
  .E(E),
  .Clock(Clock),
  .Q(Q)
);

initial begin
  Clock = 0;
  forever #5
    Clock = ~Clock;
end

initial begin
  E = 1'b1;
  I = 32'h55555555;
  
  FunSel = 010;
  #10;
  FunSel = 000;
  #10;
  FunSel = 001;
  #10;
  FunSel = 100;
  #10;
  FunSel = 101;
  #10;
  FunSel = 110;
  #10;
  FunSel = 111;
  #10;
  E = 1'b0;
  FunSel = 011;
  #10;
  E = 1;
  #10;
  $finish;
end
endmodule
