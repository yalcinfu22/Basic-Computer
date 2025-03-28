`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.03.2025 10:33:45
// Design Name: 
// Module Name: Register16bitSim
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


module Register16bitSim;
  reg [1:0] FunSel;
  reg [15:0] I;
  reg E;
  reg clk;
  wire [15:0] Q;
 
 Register16bit reg1 ( 
 .FunSel(FunSel),
 .I(I),
 .E(E),
 .clk(clk),
 .Q(Q)
 );
 
 initial
 begin
   clk = 0;
   forever #5
     clk = ~clk;
 end
 
 initial
 begin
   I = 16'hF000;
   E = 1;
  
   FunSel = 2'b10;
   #10;
   FunSel = 2'b00;
   #10;
   FunSel = 2'b01;
   #10;
   FunSel = 2'b11;
   #10;
 $finish;
 end
endmodule
