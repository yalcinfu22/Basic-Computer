`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.03.2025 17:55:49
// Design Name: 
// Module Name: DataRegSim
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


module DataRegSim;
 reg [7:0] I;
 reg E;
 reg [1:0] FunSel;
 reg Clock;
 wire [31:0] DROut;
 
DataRegister DR1(
  .I(I),
  .E(E),
  .FunSel(FunSel),
  .Clock(Clock),
  .DROut(DROut)
);

initial begin
  Clock = 1'b0;
  forever #5
    Clock  = ~Clock;
end

initial begin
  E = 1'b1;
  I = 8'h55;
  FunSel = 2'b00;
  #10;
  FunSel = 2'b01;
  I = 8'hAA;
  #10;
  FunSel = 2'b10;
  I = 8'hFF;
  #10;
  E = 1'b0;
  FunSel = 2'b11;
  #10;
  E = 1'b1;
  #10;
  $finish;
end
endmodule

