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

wire MSB_A, MSB_B, LSB_A_H, LSB_A;
wire [15:0] A_L, A_H, B_L, B_H;
assign A_L = A[15:0];
assign A_H = A[31:16];
assign B_L = B[15:0];
assign B_H = B[31:16];
assign MSB_A = A[31];
assign MSB_B = B[31];
assign LSB_A = A[0];
assign LSB_A_H = A_H[0];
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
     flagInput[2] = MSB_A; // MSB_A == A[31] == A_H[15]
     flagInput[1] = A[30]; // One bit before MSB becomes the sign bit
     Res_L = {A_H[14:0], 1'b0}; // equivalent to left shift
     Res = {{16{Res_L[15]}}, Res_L};
     flagInput[3] = (Res == 32'b0);
     ALUOut = Res;
     end
     5'b01100: begin
     flagInput[2] = LSB_A_H; // lowest bit will be the carry after shift
     flagInput[1] = 0; // sign bit is always zero
     Res_L = {1'b0, A_H[15:1]}; // equivalent to right shift
     Res = {{16{Res_L[15]}}, Res_L};
     flagInput[3] = (Res == 32'b0);
     ALUOut = Res;
     end
     5'b01101: begin
     Res_L = {MSB_A, A_H[15:1]}; // MSB_A == A_H[15] == A[31]
     Res = {{16{MSB_A}}, Res_L};
     flagInput[3] = (Res == 32'b0);
     ALUOut = Res;
     end
     5'b01110: begin
     Res_L = {A_H[14:0], Cin}; // Using Res to circular shift LSB becomes Cin
     Res = {{16{Res_L[15]}}, Res_L}; // extend the result to 32 bit
     flagInput[1] = MSB_Res; // sign is MSB_Res
     flagInput[2] = MSB_A; // The carry for CLR is the MSB_A. A is unchanged so it is usable.
     flagInput[3] = (Res == 32'b0);
     ALUOut = Res;
     end
     5'b01111: begin
     Res_L = {Cin, A_H[15:1]}; 
     Res = {{16{Res_L[15]}}, Res_L};
     flagInput[1] = MSB_Res;
     flagInput[2] = LSB_A_H; 
     flagInput[3] = (Res == 32'b0);
     ALUOut = Res;
     end
     // Cases where MSB is 1 (from 10000 to 11111)
     5'b10000: begin
     flagInput[1] = MSB_A;
     flagInput[3] = (A == 32'b0);
     ALUOut = A;
     end
     5'b10001: begin
     flagInput[1] = MSB_B;
     flagInput[3] = (B == 32'b0);
     ALUOut = B;
     end
     5'b10010: begin
     flagInput[1] = ~MSB_A;
     flagInput[3] = (~A == 32'b0);
     ALUOut = ~A;
     end
     5'b10011: begin
     flagInput[1] = ~MSB_B;
     flagInput[3] = (~B == 32'b0);
     ALUOut = ~B;
     end
     5'b10100: begin
     Sum = A + B; 
     Res = Sum[31:0]; // discard 33th bit
     flagInput[0] = (MSB_A == MSB_B) && (MSB_Res != MSB_A);
     flagInput[1] = MSB_Res;
     flagInput[2] = MSB_Sum;
     flagInput[3] = (Res == 32'b0);
     ALUOut = Res;
     end
     5'b10101: begin
     Sum = A + B + Cin;
     Res = Sum[31:0]; // discard 33th bit
     flagInput[0] = (MSB_A == MSB_B) && (MSB_Res != MSB_A);
     flagInput[1] = MSB_Res;
     flagInput[2] = MSB_Sum;
     flagInput[3] = (Res == 32'b0);
     ALUOut = Res;
     end
     5'b10110: begin
     Sum = A + ~B + Cin; 
     Res = Sum[31:0]; // discard 33th bit
     if(MSB_A == 1'b0 && MSB_B == 1'b1 && MSB_Res == 1'b1)
      flagInput[0] = 1;
     else if(MSB_A == 1'b1 && MSB_B == 1'b0 && MSB_Res == 1'b0)
      flagInput[0] = 1;
     flagInput[1] = MSB_Res;
     flagInput[2] = MSB_Sum;
     flagInput[3] = (Res == 32'b0);
     ALUOut = Res;
     end
     5'b10111: begin
     Res = A & B;
     flagInput[1] = MSB_Res;
     flagInput[3] = (Res == 32'b0);
     ALUOut = Res;
     end
     5'b11000: begin
     Res = A | B;
     flagInput[1] = MSB_Res;
     flagInput[3] = (Res == 32'b0);
     ALUOut = Res;
     end
     5'b11001: begin
     Res = A ^ B;
     flagInput[1] = MSB_Res;
     flagInput[3] = (Res == 32'b0);
     ALUOut = Res;
     end
     5'b11010: begin
     Res = ~(A & B);
     flagInput[1] = MSB_Res;
     flagInput[3] = (Res == 32'b0);
     ALUOut = Res;
     end
     5'b11011: begin
     flagInput[2] = MSB_A; // MSB_A == A[31] == A_H[15]
     flagInput[1] = A[30]; // One bit before MSB becomes the sign bit
     Res = {A[30:0], 1'b0}; // equivalent to left shift
     flagInput[3] = (Res == 32'b0);
     ALUOut = Res;
     end
     5'b11100: begin
     flagInput[2] = LSB_A; // lowest bit will be the carry after shift
     flagInput[1] = 0; // sign bit is always zero
     Res = {1'b0, A[31:1]}; // equivalent to right shift
     flagInput[3] = (Res == 32'b0);
     ALUOut = Res;
     end
     5'b11101: begin
     Res = {MSB_A, A[31:1]}; // MSB_A == A_H[15] == A[31]
     flagInput[3] = (Res == 32'b0);
     ALUOut = Res;
     end
     5'b11110: begin
     Res = {A[30:0], Cin}; // Using Res to circular shift LSB becomes Cin
     flagInput[1] = MSB_Res; // sign is MSB_Res
     flagInput[2] = MSB_A; // The carry for CLR is the MSB_A. A is unchanged so it is usable.
     flagInput[3] = (Res == 32'b0);
     ALUOut = Res;
     end
     5'b11111: begin
     Res = {Cin, A[31:1]};
     flagInput[1] = MSB_Res;
     flagInput[2] = LSB_A; 
     flagInput[3] = (Res == 32'b0);
     ALUOut = Res;
     end
     default: begin
      // What can be put here?
     end
   endcase
 end
endmodule
