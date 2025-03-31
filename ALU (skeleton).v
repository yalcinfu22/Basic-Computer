`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.03.2025 15:57:11
// Design Name: 
// Module Name: ALU
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


module ALU(
 input wire [31:0] A,
 input wire [31:0] B,
 input wire [4:0] FunSel,
 input wire Cin,
 input wire [3:0] FlagsOut, // Flags are being modified in FlagRegister.v
 output reg [31:0] ALUOut
);

reg [3:0] flagInput;
wire flagZ, flagC, flagN, flagO;

FlagRegister FR1(
  .I(flagInput),
  .Z(flagZ),
  .C(flagC),
  .N(flagN),
  .O(flagO)
);

assign FlagsOut = {flagZ, flagC, flagN, flagO};
assign Cin = flagC;

reg [32:0] Sum;
reg [31:0] Res;
reg [15:0] Res_L, Res_H;

wire MSB_A, MSB_B;
wire [15:0] A_L, A_H, B_L, B_H;
assign A_L = A[15:0];
assign A_H = A[31:16];
assign B_L = B[15:0];
assign B_H = B[31:16];
assign MSB_A = A[31];
assign MSB_B = B[31];
wire MSB_Sum = Sum[32];
wire MSB_Res = Res[31];
always @(*) begin
  // Clear default values
  Res = 32'b0;
  Sum = 33'b0;
   
   case(FunSel)
     // Cases where MSB is 0 (from 00000 to 01111)
     5'b00000: begin
     ALUOut = {{16{MSB_A}}, A_H};
     flagInput[1] = MSB_A;
     flagInput[3] = (ALUOut == 32'b0);
     end
     5'b00001: begin
     ALUOut = {{16{MSB_B}}, B_H};
     flagInput[1] = MSB_B;
     flagInput[3] = (ALUOut == 32'b0);
     end
     5'b00010: begin
     ALUOut = {{16{~MSB_A}}, ~A_H};
     flagInput[1] = ~MSB_A;
     flagInput[3] = (ALUOut == 32'b0);
     end
     5'b00011: begin
     ALUOut = {{16{~MSB_B}}, ~B_H};
     flagInput[1] = ~MSB_B;
     flagInput[3] = (ALUOut == 32'b0);
     end
     5'b00100: begin
      Sum[32:16] = A_H + B_H; 
      Res = {{16{Sum[31]}}, Sum[31:16]};
      flagInput[0] = (MSB_A == MSB_B) && (MSB_Res != MSB_A);
      flagInput[1] = MSB_Res;
      flagInput[2] = MSB_Sum;
      flagInput[3] = (Res == 32'b0);
      ALUOut = Res;
     end
     5'b00101: begin
     Sum[32:16] = A_H + B_H + Cin; 
     Res = {{16{Sum[31]}}, Sum[31:16]};
     flagInput[0] = (MSB_A == MSB_B) && (MSB_Res != MSB_A);
     flagInput[1] = MSB_Res;
     flagInput[2] = MSB_Sum;
     flagInput[3] = (Res == 32'b0);
     ALUOut = Res;
     end
     5'b00110: begin
     Sum[32:16] = A_H + ~B_H + Cin; 
     Res = {{16{Sum[31]}}, Sum[31:16]};
     if(MSB_A == 1'b0 && MSB_B == 1'b1 && MSB_Res == 1'b1)
      flagInput[0] = 1;
     else if(MSB_A == 1'b1 && MSB_B == 1'b0 && MSB_Res == 1'b0)
      flagInput[0] = 1;
     flagInput[1] = MSB_Res;
     flagInput[2] = MSB_Sum;
     flagInput[3] = (Res == 32'b0);
     ALUOut = Res;
     end
     5'b00111: begin
     Res_L = A_H & B_H;
     Res = {{16{Res_L[15]}}, Res_L};
     flagInput[1] = MSB_Res;
     flagInput[3] = (Res == 32'b0);
     ALUOut = Res;
     end
     5'b01000: begin
     Res_L = A_H | B_H;
     Res = {{16{Res_L[15]}}, Res_L};
     flagInput[1] = MSB_Res;
     flagInput[3] = (Res == 32'b0);
     ALUOut = Res;  
     end
     5'b01001: begin
     Res_L = A_H ^ B_H;
     Res = {{16{Res_L[15]}}, Res_L};
     flagInput[1] = MSB_Res;
     flagInput[3] = (Res == 32'b0);
     ALUOut = Res;  
     end
     5'b01010: begin
     Res_L = ~(A_H & B_H);
     Res = {{16{Res_L[15]}}, Res_L};
     flagInput[1] = MSB_Res;
     flagInput[3] = (Res == 32'b0);
     ALUOut = Res;  
     end
     5'b01011: begin
       // Logic for 01011
     end
     5'b01100: begin
       // Logic for 01100
     end
     5'b01101: begin
       // Logic for 01101
     end
     5'b01110: begin
       // Logic for 01110
     end
     5'b01111: begin
       // Logic for 01111
     end
     // Cases where MSB is 1 (from 10000 to 11111)
     5'b10000: begin
       // Logic for 10000
     end
     5'b10001: begin
       // Logic for 10001
     end
     5'b10010: begin
       // Logic for 10010
     end
     5'b10011: begin
       // Logic for 10011
     end
     5'b10100: begin
       // Logic for 10100
     end
     5'b10101: begin
       // Logic for 10101
     end
     5'b10110: begin
       // Logic for 10110
     end
     5'b10111: begin
       // Logic for 10111
     end
     5'b11000: begin
       // Logic for 11000
     end
     5'b11001: begin
       // Logic for 11001
     end
     5'b11010: begin
       // Logic for 11010
     end
     5'b11011: begin
       // Logic for 11011
     end
     5'b11100: begin
       // Logic for 11100
     end
     5'b11101: begin
       // Logic for 11101
     end
     5'b11110: begin
       // Logic for 11110
     end
     5'b11111: begin
       // Logic for 11111
     end
 
     default: begin
      // Optional default case logic
     end
   endcase
 end
      
endmodule
