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


module ArithmeticLogicUnit (
 input wire [31:0] A,
 input wire [31:0] B,
 input wire [4:0] FunSel,
 input wire WF,
 input wire Clock,
 output reg[3:0] FlagsOut, // Flags are being modified in FlagRegister.v
 output reg [31:0] ALUOut
);

reg [3:0] flagInput;

initial flagInput = 4'b0000;

wire Cin;
// Note: Driving inputs internally (FlagsOut and Cin) is non-standard.
// Consider revising the port directions or using internal wires.
assign Cin = FlagsOut[2];
wire MSB_A, MSB_B, LSB_A_H, LSB_A;
wire [31:0] sign_extended_A_H, sign_extended_B_H;
wire [15:0] A_L, B_L;
assign A_L = A[15:0];        // Lower 16 bits of A
assign sign_extended_A_H = {{16{A[31]}}, A[31:16]}; // Upper 16 bits of A with sign extension
assign B_L = B[15:0];        // Lower 16 bits of B
assign sign_extended_B_H = {{16{B[31]}}, B[31:16]};       // Upper 16 bits of B
assign MSB_A = A[31];        // MSB of A
assign MSB_B = B[31];        // MSB of B
assign LSB_A = A[0];         // LSB of full A
assign LSB_A_H =sign_extended_A_H[0];     // LSB of A's upper half

always @(*) begin
flagInput[0] = 0;
   case(FunSel)
     // ---------------- 16-bit Operations on Upper Half (A_H, B_H) ----------------
     5'b00000: begin  //Shift A_H with sign extension
       ALUOut = sign_extended_A_H;
     end
     5'b00001: begin //Shift sign_extended_B_H with sign extension
       ALUOut = sign_extended_B_H;
     end
     5'b00010: begin // Not on sign_extended_A_H
       ALUOut = ~sign_extended_A_H;
     end
     5'b00011: begin // Not on sign_extended_B_H
       ALUOut = ~sign_extended_B_H;
     end
     5'b00100: begin // 16-bit Addition: Add sign_extended_A_H and sign_extended_B_H  
       {flagInput[2], ALUOut} = sign_extended_A_H + sign_extended_B_H; 
     end
     5'b00101: begin // 16-bit Addition with Carry: A_H + B_H + Cin.
     //(first sign_extension then sum) and assigin Carry to flagInput[1]
     {flagInput[2], ALUOut} = sign_extended_A_H + sign_extended_B_H  + Cin; 
      flagInput[0] = (MSB_A == MSB_B) && (ALUOut[31] != MSB_A);
     end
     5'b00110: begin  // 16-bit Subtraction: A_H - B_H using two's complement:
       // Compute A_H + ~B_H + Cin.
       {flagInput[2], ALUOut} = sign_extended_A_H + ~sign_extended_B_H + 1'b1; 
       // Set overflow flag under specific sign conditions.
       if((MSB_A == 1'b0 && MSB_B == 1'b1 && ALUOut[31] == 1'b1) || 
       (MSB_A == 1'b1 && MSB_B == 1'b0 && ALUOut[31] == 1'b0))
       begin
         flagInput[0] = 1;
         end
     end
     5'b00111: begin // Bitwise AND on upper halves: A_H & B_H.
       ALUOut = sign_extended_B_H & sign_extended_A_H;
     end
     5'b01000: begin // Bitwise OR on upper halves: A_H | B_H.
       ALUOut = sign_extended_B_H | sign_extended_A_H;
     end
     5'b01001: begin // Bitwise XOR on upper halves: A_H ^ B_H.
       ALUOut = sign_extended_B_H ^ sign_extended_A_H;;  
     end
     5'b01010: begin // Bitwise NAND on upper halves: ~(A_H & B_H).
       ALUOut = ~(sign_extended_B_H & sign_extended_A_H);
     end
     5'b01011: begin // Logical Left Shift on upper half:
       // Shift A_H left by one bit. New carry comes from original A[31],
       flagInput[2] = MSB_A; // Carry becomes original A[31] (A_H[15]).
       ALUOut = {{16{sign_extended_A_H[14]}},
       sign_extended_A_H[14:0], 1'b0}; // Left shift A_H by one.Then sign extension
     end
     5'b01100: begin
       // Logical Right Shift on upper half:
       // Shift A_H right by one bit. New carry is the original LSB of A_H.
       flagInput[2] = LSB_A_H; // Carry becomes the LSB of A_H.
       ALUOut = {17'b0, sign_extended_A_H[15:1]}; // Right shift A_H by one.
     end
     5'b01101: begin
       // Arithmetic Right Shift on upper half:
       // Shift right while preserving the sign (MSB_A remains).
       ALUOut = {{17{MSB_A}},  sign_extended_A_H[15:1]};
     end
     5'b01110: begin
       // Circular (Rotate) Left Shift on upper half using carry:
       // Shift A_H left by one bit; insert Cin into the LSB.
       // The original MSB (A[31]) is output as the new carry.
       flagInput[2] = MSB_A;   // Carry becomes the original A[31].
       ALUOut = {{16{sign_extended_A_H[14]}}, sign_extended_A_H[14:0], Cin};
     end
     5'b01111: begin
       // Circular (Rotate) Right Shift on upper half using carry:
       // Shift A_H right by one bit; insert Cin as new MSB.
       // The original LSB of A_H becomes the new carry.
       flagInput[2] = LSB_A_H;  // Carry becomes the original LSB of A_H.
       ALUOut = {{16{Cin}}, Cin, sign_extended_A_H[15:1]};
     end

     // ------------------- 32-bit Operations -------------------
     5'b10000: begin // Pass-through: Output full 32-bit A.
       ALUOut = A;
     end
     5'b10001: begin // Pass-through: Output full 32-bit B.
       ALUOut = B;
     end
     5'b10010: begin // Bitwise NOT (32-bit) on A.
       ALUOut = ~A;
     end
     5'b10011: begin // Bitwise NOT (32-bit) on B.
       flagInput[1] = ~MSB_B;
       flagInput[3] = (~B == 32'b0);
       ALUOut = ~B;
     end
     5'b10100: begin // 32-bit Addition: A + B.
      {flagInput[2],ALUOut} = A + B;
       flagInput[0] = (MSB_A == MSB_B) && (ALUOut[31] != MSB_A); // Overflow.
     end
     5'b10101: begin // 32-bit Addition with Carry: A + B + Cin.
     {flagInput[2],ALUOut} = A + B + Cin;
       flagInput[0] = (MSB_A == MSB_B) && (ALUOut[31] != MSB_A);
     end
     5'b10110: begin // 32-bit Subtraction: A - B as A + ~B + Cin.
        {flagInput[2],ALUOut} = A + ~B + 1;

       if((MSB_A == 1'b0 && MSB_B == 1'b1 && ALUOut[31] == 1'b1) ||
       (MSB_A == 1'b1 && MSB_B == 1'b0 && ALUOut[31] == 1'b0)) begin
         flagInput[0] = 1;
         end
     end
     5'b10111: begin // Bitwise AND (32-bit): A & B.
       ALUOut = A & B;
     end
     5'b11000: begin // Bitwise OR (32-bit): A | B.
       ALUOut = A | B;
     end
     5'b11001: begin // Bitwise XOR (32-bit): A ^ B.
       ALUOut = A ^ B;
     end
     5'b11010: begin // Bitwise NAND (32-bit): ~(A & B).
       ALUOut = ~(A & B);
     end
     5'b11011: begin // Logical Left Shift (32-bit): A << 1.
       flagInput[2] = MSB_A; // Carry becomes original MSB.     
       ALUOut = {A[30:0], 1'b0};
     end
     5'b11100: begin // Logical Right Shift (32-bit): A >> 1.
       flagInput[2] = LSB_A; // Carry becomes original LSB.
       ALUOut = {1'b0, A[31:1]};
     end
     5'b11101: begin // Arithmetic Right Shift (32-bit): Preserves sign.
       ALUOut = {MSB_A, A[31:1]};
     end
     5'b11110: begin // Circular (Rotate) Left Shift (32-bit): Shift left and insert Cin.

       flagInput[2] = MSB_A;   // Carry is original MSB.
       ALUOut = {A[30:0], Cin};
     end
     5'b11111: begin // Circular (Rotate) Right Shift (32-bit): Shift right and insert Cin.
       flagInput[2] = LSB_A;   // Carry becomes original LSB.
       ALUOut = {Cin, A[31:1]};
     end
     default: begin
       ALUOut = 32'b0;
     end
   endcase
        flagInput[3] = (ALUOut == 32'b0);  // Zero flag.
         flagInput[1] = ALUOut[31];            // Sign flag from ALUOut MSB.
 end
  always @(posedge Clock) begin
 if(WF) begin
  FlagsOut[3] <= flagInput[3]; // Zero flag (MSB)
  FlagsOut[2] <= flagInput[2]; // Carry flag
  FlagsOut[1] <= flagInput[1]; // Negative flag
  FlagsOut[0] <= flagInput[0]; // Overflow flag (LSB)
 end
 end
endmodule