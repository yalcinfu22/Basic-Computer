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
//   This ALU supports a variety of operations on both the upper 16-bit halves
//   of inputs (A_H and B_H) and on the full 32-bit words. Operations include
//   pass-through, bitwise logic, arithmetic (with overflow/carry detection),
//   shifts, and circular shifts. Flags (Z, C, N, O) are produced via a
//   separate FlagRegister module.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//   Detailed inline documentation added to each case.
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

// Note: Driving inputs internally (FlagsOut and Cin) is non-standard.
// Consider revising the port directions or using internal wires.
assign FlagsOut = {flagZ, flagC, flagN, flagO};
assign Cin = flagC;

reg [32:0] Sum;       // 33-bit sum to capture overflow/carry (bit 32)
reg [31:0] Res;       // 32-bit result output
reg [15:0] Res_L, Res_H;  // Intermediate 16-bit results

wire MSB_A, MSB_B, LSB_A_H, LSB_A;
wire [15:0] A_L, A_H, B_L, B_H;
assign A_L = A[15:0];        // Lower 16 bits of A
assign A_H = A[31:16];       // Upper 16 bits of A
assign B_L = B[15:0];        // Lower 16 bits of B
assign B_H = B[31:16];       // Upper 16 bits of B
assign MSB_A = A[31];        // MSB of A
assign MSB_B = B[31];        // MSB of B
assign LSB_A = A[0];         // LSB of full A
assign LSB_A_H = A_H[0];     // LSB of A's upper half
wire MSB_Sum = Sum[32];      // Carry-out from Sum (33rd bit)
wire MSB_Res = Res[31];      // MSB of the computed result

always @(*) begin
  // Clear default values
  Res = 32'b0;
  Sum = 33'b0;
   
   case(FunSel)
     // ---------------- 16-bit Operations on Upper Half (A_H, B_H) ----------------
     5'b00000: begin
       // Pass-through: Output A_H sign-extended to 32 bits.
       ALUOut = {{16{MSB_A}}, A_H};
       flagInput[1] = MSB_A;            // Sign flag from A's MSB.
       flagInput[3] = (ALUOut == 32'b0);  // Zero flag.
     end
     5'b00001: begin
       // Pass-through: Output B_H sign-extended to 32 bits.
       ALUOut = {{16{MSB_B}}, B_H};
       flagInput[1] = MSB_B;            // Sign flag from B's MSB.
       flagInput[3] = (ALUOut == 32'b0);  // Zero flag.
     end
     5'b00010: begin
       // Bitwise NOT on A_H: Invert A_H then sign-extend.
       ALUOut = {{16{~MSB_A}}, ~A_H};
       flagInput[1] = ~MSB_A;           // Sign flag is inverted A's MSB.
       flagInput[3] = (ALUOut == 32'b0);  // Zero flag.
     end
     5'b00011: begin
       // Bitwise NOT on B_H: Invert B_H then sign-extend.
       ALUOut = {{16{~MSB_B}}, ~B_H};
       flagInput[1] = ~MSB_B;           // Sign flag is inverted B's MSB.
       flagInput[3] = (ALUOut == 32'b0);  // Zero flag.
     end
     5'b00100: begin
       // 16-bit Addition: Add A_H and B_H.
       Sum[32:16] = A_H + B_H; 
       Res = {{16{Sum[31]}}, Sum[31:16]};  // Sign-extend the 16-bit sum.
       flagInput[0] = (MSB_A == MSB_B) && (MSB_Res != MSB_A); // Overflow detection.
       flagInput[1] = MSB_Res;            // Sign flag from result.
       flagInput[2] = MSB_Sum;            // Carry flag.
       flagInput[3] = (Res == 32'b0);     // Zero flag.
       ALUOut = Res;
     end
     5'b00101: begin
       // 16-bit Addition with Carry: A_H + B_H + Cin.
       Sum[32:16] = A_H + B_H + Cin; 
       Res = {{16{Sum[31]}}, Sum[31:16]};
       flagInput[0] = (MSB_A == MSB_B) && (MSB_Res != MSB_A);
       flagInput[1] = MSB_Res;
       flagInput[2] = MSB_Sum;
       flagInput[3] = (Res == 32'b0);
       ALUOut = Res;
     end
     5'b00110: begin
       // 16-bit Subtraction: A_H - B_H using two's complement:
       // Compute A_H + ~B_H + Cin.
       Sum[32:16] = A_H + ~B_H + Cin; 
       Res = {{16{Sum[31]}}, Sum[31:16]};
       // Set overflow flag under specific sign conditions.
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
       // Bitwise AND on upper halves: A_H & B_H.
       Res_L = A_H & B_H;
       Res = {{16{Res_L[15]}}, Res_L};
       flagInput[1] = MSB_Res;
       flagInput[3] = (Res == 32'b0);
       ALUOut = Res;
     end
     5'b01000: begin
       // Bitwise OR on upper halves: A_H | B_H.
       Res_L = A_H | B_H;
       Res = {{16{Res_L[15]}}, Res_L};
       flagInput[1] = MSB_Res;
       flagInput[3] = (Res == 32'b0);
       ALUOut = Res;  
     end
     5'b01001: begin
       // Bitwise XOR on upper halves: A_H ^ B_H.
       Res_L = A_H ^ B_H;
       Res = {{16{Res_L[15]}}, Res_L};
       flagInput[1] = MSB_Res;
       flagInput[3] = (Res == 32'b0);
       ALUOut = Res;  
     end
     5'b01010: begin
       // Bitwise NAND on upper halves: ~(A_H & B_H).
       Res_L = ~(A_H & B_H);
       Res = {{16{Res_L[15]}}, Res_L};
       flagInput[1] = MSB_Res;
       flagInput[3] = (Res == 32'b0);
       ALUOut = Res;  
     end
     5'b01011: begin
       // Logical Left Shift on upper half:
       // Shift A_H left by one bit. New carry comes from original A[31],
       // and A[30] becomes the new sign bit.
       flagInput[2] = MSB_A; // Carry becomes original A[31] (A_H[15]).
       flagInput[1] = A[30]; // New sign bit is A[30].
       Res_L = {A_H[14:0], 1'b0}; // Left shift A_H by one.
       Res = {{16{Res_L[15]}}, Res_L};
       flagInput[3] = (Res == 32'b0);
       ALUOut = Res;
     end
     5'b01100: begin
       // Logical Right Shift on upper half:
       // Shift A_H right by one bit. New carry is the original LSB of A_H.
       flagInput[2] = LSB_A_H; // Carry becomes the LSB of A_H.
       flagInput[1] = 0;       // Force sign flag to zero.
       Res_L = {1'b0, A_H[15:1]}; // Right shift A_H by one.
       Res = {{16{Res_L[15]}}, Res_L};
       flagInput[3] = (Res == 32'b0);
       ALUOut = Res;
     end
     5'b01101: begin
       // Arithmetic Right Shift on upper half:
       // Shift right while preserving the sign (MSB_A remains).
       Res_L = {MSB_A, A_H[15:1]};
       Res = {{16{MSB_A}}, Res_L};
       flagInput[3] = (Res == 32'b0);
       ALUOut = Res;
     end
     5'b01110: begin
       // Circular (Rotate) Left Shift on upper half using carry:
       // Shift A_H left by one bit; insert Cin into the LSB.
       // The original MSB (A[31]) is output as the new carry.
       Res_L = {A_H[14:0], Cin};
       Res = {{16{Res_L[15]}}, Res_L};
       flagInput[1] = MSB_Res; // New sign from result.
       flagInput[2] = MSB_A;   // Carry becomes the original A[31].
       flagInput[3] = (Res == 32'b0);
       ALUOut = Res;
     end
     5'b01111: begin
       // Circular (Rotate) Right Shift on upper half using carry:
       // Shift A_H right by one bit; insert Cin as new MSB.
       // The original LSB of A_H becomes the new carry.
       Res_L = {Cin, A_H[15:1]};
       Res = {{16{Res_L[15]}}, Res_L};
       flagInput[1] = MSB_Res;
       flagInput[2] = LSB_A_H;  // Carry becomes the original LSB of A_H.
       flagInput[3] = (Res == 32'b0);
       ALUOut = Res;
     end

     // ------------------- 32-bit Operations -------------------
     5'b10000: begin // Pass-through: Output full 32-bit A.
       flagInput[1] = MSB_A;
       flagInput[3] = (A == 32'b0);
       ALUOut = A;
     end
     5'b10001: begin // Pass-through: Output full 32-bit B.
       flagInput[1] = MSB_B;
       flagInput[3] = (B == 32'b0);
       ALUOut = B;
     end
     5'b10010: begin // Bitwise NOT (32-bit) on A.
       flagInput[1] = ~MSB_A;
       flagInput[3] = (~A == 32'b0);
       ALUOut = ~A;
     end
     5'b10011: begin // Bitwise NOT (32-bit) on B.
       flagInput[1] = ~MSB_B;
       flagInput[3] = (~B == 32'b0);
       ALUOut = ~B;
     end
     5'b10100: begin // 32-bit Addition: A + B.
       Sum = A + B; 
       Res = Sum[31:0]; // Discard the 33rd bit.
       flagInput[0] = (MSB_A == MSB_B) && (MSB_Res != MSB_A); // Overflow.
       flagInput[1] = MSB_Res;   // Sign flag.
       flagInput[2] = MSB_Sum;   // Carry flag.
       flagInput[3] = (Res == 32'b0);
       ALUOut = Res;
     end
     5'b10101: begin // 32-bit Addition with Carry: A + B + Cin.
       Sum = A + B + Cin; 
       Res = Sum[31:0];
       flagInput[0] = (MSB_A == MSB_B) && (MSB_Res != MSB_A);
       flagInput[1] = MSB_Res;
       flagInput[2] = MSB_Sum;
       flagInput[3] = (Res == 32'b0);
       ALUOut = Res;
     end
     5'b10110: begin // 32-bit Subtraction: A - B as A + ~B + Cin.
       Sum = A + ~B + Cin; 
       Res = Sum[31:0];
       if(MSB_A == 1'b0 && MSB_B == 1'b1 && MSB_Res == 1'b1)
         flagInput[0] = 1;
       else if(MSB_A == 1'b1 && MSB_B == 1'b0 && MSB_Res == 1'b0)
         flagInput[0] = 1;
       flagInput[1] = MSB_Res;
       flagInput[2] = MSB_Sum;
       flagInput[3] = (Res == 32'b0);
       ALUOut = Res;
     end
     5'b10111: begin // Bitwise AND (32-bit): A & B.
       Res = A & B;
       flagInput[1] = MSB_Res;
       flagInput[3] = (Res == 32'b0);
       ALUOut = Res;
     end
     5'b11000: begin // Bitwise OR (32-bit): A | B.
       Res = A | B;
       flagInput[1] = MSB_Res;
       flagInput[3] = (Res == 32'b0);
       ALUOut = Res;
     end
     5'b11001: begin // Bitwise XOR (32-bit): A ^ B.
       Res = A ^ B;
       flagInput[1] = MSB_Res;
       flagInput[3] = (Res == 32'b0);
       ALUOut = Res;
     end
     5'b11010: begin // Bitwise NAND (32-bit): ~(A & B).
       Res = ~(A & B);
       flagInput[1] = MSB_Res;
       flagInput[3] = (Res == 32'b0);
       ALUOut = Res;
     end
     5'b11011: begin // Logical Left Shift (32-bit): A << 1.
       flagInput[2] = MSB_A; // Carry becomes original MSB.
       flagInput[1] = A[30]; // New sign is from one bit before MSB.
       Res = {A[30:0], 1'b0};
       flagInput[3] = (Res == 32'b0);
       ALUOut = Res;
     end
     5'b11100: begin // Logical Right Shift (32-bit): A >> 1.
       flagInput[2] = LSB_A; // Carry becomes original LSB.
       flagInput[1] = 0;      // Sign is forced to zero.
       Res = {1'b0, A[31:1]};
       flagInput[3] = (Res == 32'b0);
       ALUOut = Res;
     end
     5'b11101: begin // Arithmetic Right Shift (32-bit): Preserves sign.
       Res = {MSB_A, A[31:1]};
       flagInput[3] = (Res == 32'b0);
       ALUOut = Res;
     end
     5'b11110: begin // Circular (Rotate) Left Shift (32-bit): Shift left and insert Cin.
       Res = {A[30:0], Cin};
       flagInput[1] = MSB_Res; // New sign from result.
       flagInput[2] = MSB_A;   // Carry is original MSB.
       flagInput[3] = (Res == 32'b0);
       ALUOut = Res;
     end
     5'b11111: begin // Circular (Rotate) Right Shift (32-bit): Shift right and insert Cin.
       Res = {Cin, A[31:1]};
       flagInput[1] = MSB_Res;
       flagInput[2] = LSB_A;   // Carry becomes original LSB.
       flagInput[3] = (Res == 32'b0);
       ALUOut = Res;
     end
     default: begin
       ALUOut = 32'b0;
     end
   endcase
 end
endmodule
