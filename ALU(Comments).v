`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.03.2025 15:57:11
// Design Name: 
// Module Name: ArithmeticLogicUnit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//   This ALU performs a wide range of operations on 32-bit inputs. For some 
//   operations only the upper 16 bits (with sign extension) are used; for others, 
//   the full 32-bit operands are processed. Supported operations include pass-
//   through, bitwise logic (NOT, AND, OR, XOR, NAND), arithmetic (addition and 
//   subtraction with overflow and carry detection), logical/arithmetic shifts, and
//   circular (rotate) shifts that incorporate a carry bit. The status flags are 
//   generated internally and updated synchronously.
// 
// Flags (output FlagsOut) are defined as follows (bit order from MSB to LSB):
//   FlagsOut[3] = Zero flag (Z)
//   FlagsOut[2] = Carry flag (C)
//   FlagsOut[1] = Negative flag (N)
//   FlagsOut[0] = Overflow flag (O)
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//   Detailed inline documentation is provided below.
//////////////////////////////////////////////////////////////////////////////////

module ArithmeticLogicUnit (
  input  wire [31:0] A,         // 32-bit input A
  input  wire [31:0] B,         // 32-bit input B
  input  wire [4:0]  FunSel,    // 5-bit function select signal
  input  wire       WF,         // Write flag: enables updating of FlagsOut
  input  wire       Clock,      // Clock signal (for synchronous flag update)
  output reg  [3:0] FlagsOut,   // Status flags: {Zero, Carry, Negative, Overflow}
  output reg  [31:0] ALUOut    // 32-bit ALU result output
);

  // Internal flag register: internalFlags holds computed flag values.
  // Bit assignment: [3]=Zero, [2]=Carry, [1]=Negative, [0]=Overflow.
  reg [3:0] internalFlags;

  //--------------------------------------------------------------------------
  // Input Splitting and Sign Extension for 16-bit Operations
  //--------------------------------------------------------------------------

  // Lower 16 bits (unused for 16-bit upper-half operations).
  wire [15:0] A_L, B_L;
  assign A_L = A[15:0];
  assign B_L = B[15:0];

  // Sign-extend the upper 16 bits of A and B to full 32 bits.
  wire [31:0] sign_extended_A_H, sign_extended_B_H;
  assign sign_extended_A_H = {{16{A[31]}}, A[31:16]};
  assign sign_extended_B_H = {{16{B[31]}}, B[31:16]};

  //--------------------------------------------------------------------------
  // Key Bit Extraction for Flag Calculations
  //--------------------------------------------------------------------------

  // Most significant bits (MSB) and least significant bits (LSB) of full A and B.
  wire MSB_A, MSB_B, LSB_A;
  assign MSB_A = A[31];
  assign MSB_B = B[31];
  assign LSB_A = A[0];

  // LSB of the sign-extended upper half of A.
  wire LSB_A_H;
  assign LSB_A_H = sign_extended_A_H[0];

  //--------------------------------------------------------------------------
  // Intermediate Signals for Arithmetic Operations
  //--------------------------------------------------------------------------

  // Sum is a 33-bit register to capture carry-out; Res holds the 32-bit result.
  reg [32:0] Sum;
  reg [31:0] Res;
  
  //--------------------------------------------------------------------------
  // Combinational Logic: Compute ALUOut and internalFlags Based on FunSel
  //--------------------------------------------------------------------------

  always @(*) begin
    // Reset intermediate values.
    Sum = 33'b0;
    Res = 32'b0;
    
    case (FunSel)
      //////////// 16-bit Operations on Upper Halves (using sign_extended_A_H/B_H) ////////////

      5'b00000: begin
        // Pass-through: Output sign-extended upper half of A.
        ALUOut = sign_extended_A_H;
      end

      5'b00001: begin
        // Pass-through: Output sign-extended upper half of B.
        ALUOut = sign_extended_B_H;
      end

      5'b00010: begin
        // Bitwise NOT on sign_extended_A_H.
        ALUOut = ~sign_extended_A_H;
      end

      5'b00011: begin
        // Bitwise NOT on sign_extended_B_H.
        ALUOut = ~sign_extended_B_H;
      end

      5'b00100: begin
        // 16-bit Addition: sign_extended_A_H + sign_extended_B_H.
        {internalFlags[2], ALUOut} = sign_extended_A_H + sign_extended_B_H;
      end

      5'b00101: begin
        // 16-bit Addition with Carry: Add sign-extended halves and current carry.
        {internalFlags[2], ALUOut} = sign_extended_A_H + sign_extended_B_H + FlagsOut[2];
        internalFlags[0] = (MSB_A == MSB_B) && (ALUOut[31] != MSB_A);
      end

      5'b00110: begin
        // 16-bit Subtraction: Compute A_H - B_H as A_H + ~B_H + 1.
        {internalFlags[2], ALUOut} = sign_extended_A_H + ~sign_extended_B_H + 1'b1;
        if ((MSB_A == 1'b0 && MSB_B == 1'b1 && ALUOut[31] == 1'b1) ||
            (MSB_A == 1'b1 && MSB_B == 1'b0 && ALUOut[31] == 1'b0))
          internalFlags[0] = 1;
      end

      5'b00111: begin
        // Bitwise AND on upper halves.
        ALUOut = sign_extended_A_H & sign_extended_B_H;
      end

      5'b01000: begin
        // Bitwise OR on upper halves.
        ALUOut = sign_extended_A_H | sign_extended_B_H;
      end

      5'b01001: begin
        // Bitwise XOR on upper halves.
        ALUOut = sign_extended_A_H ^ sign_extended_B_H;
      end

      5'b01010: begin
        // Bitwise NAND on upper halves.
        ALUOut = ~(sign_extended_A_H & sign_extended_B_H);
      end

      5'b01011: begin
        // Logical Left Shift on upper half:
        // Shift sign_extended_A_H left by one bit; new carry is original MSB_A.
        internalFlags[2] = MSB_A;
        ALUOut = {{16{sign_extended_A_H[14]}}, sign_extended_A_H[14:0], 1'b0};
      end

      5'b01100: begin
        // Logical Right Shift on upper half:
        // Shift sign_extended_A_H right by one bit; new carry is LSB_A_H.
        internalFlags[2] = LSB_A_H;
        ALUOut = {17'b0, sign_extended_A_H[15:1]};
      end

      5'b01101: begin
        // Arithmetic Right Shift on upper half:
        // Preserve sign by replicating MSB_A.
        ALUOut = {{17{MSB_A}}, sign_extended_A_H[15:1]};
      end

      5'b01110: begin
        // Circular (Rotate) Left Shift on upper half using carry:
        // Shift left by one bit, insert current carry (FlagsOut[2]) as LSB,
        // and the original MSB (A[31]) becomes the new carry.
        internalFlags[2] = MSB_A;
        ALUOut = {{16{sign_extended_A_H[14]}}, sign_extended_A_H[14:0], FlagsOut[2]};
      end

      5'b01111: begin
        // Circular (Rotate) Right Shift on upper half using carry:
        // Shift right by one bit, insert current carry (FlagsOut[2]) at MSB,
        // and the original LSB of sign_extended_A_H becomes the new carry.
        internalFlags[2] = LSB_A_H;
        ALUOut = {{16{FlagsOut[2]}}, FlagsOut[2], sign_extended_A_H[15:1]};
      end

      //////////// 32-bit Operations (Full A and B) ////////////

      5'b10000: begin
        // 32-bit Pass-through: Output full A.
        ALUOut = A;
      end

      5'b10001: begin
        // 32-bit Pass-through: Output full B.
        ALUOut = B;
      end

      5'b10010: begin
        // 32-bit Bitwise NOT on A.
        ALUOut = ~A;
      end

      5'b10011: begin
        // 32-bit Bitwise NOT on B.
        ALUOut = ~B;
      end

      5'b10100: begin
        // 32-bit Addition: A + B.
        {internalFlags[2], ALUOut} = A + B;
        internalFlags[0] = (MSB_A == MSB_B) && (ALUOut[31] != MSB_A);
      end

      5'b10101: begin
        // 32-bit Addition with Carry: A + B + Cin.
        {internalFlags[2], ALUOut} = A + B + FlagsOut[2];
        internalFlags[0] = (MSB_A == MSB_B) && (ALUOut[31] != MSB_A);
      end

      5'b10110: begin
        // 32-bit Subtraction: A - B as A + ~B + 1.
        {internalFlags[2], ALUOut} = A + ~B + 1;
        if ((MSB_A == 1'b0 && MSB_B == 1'b1 && ALUOut[31] == 1'b1) ||
            (MSB_A == 1'b1 && MSB_B == 1'b0 && ALUOut[31] == 1'b0))
          internalFlags[0] = 1;
      end

      5'b10111: begin
        // 32-bit Bitwise AND: A & B.
        ALUOut = A & B;
      end

      5'b11000: begin
        // 32-bit Bitwise OR: A | B.
        ALUOut = A | B;
      end

      5'b11001: begin
        // 32-bit Bitwise XOR: A ^ B.
        ALUOut = A ^ B;
      end

      5'b11010: begin
        // 32-bit Bitwise NAND: ~(A & B).
        ALUOut = ~(A & B);
      end

      5'b11011: begin
        // 32-bit Logical Left Shift: Shift A left by one bit.
        internalFlags[2] = MSB_A;
        ALUOut = {A[30:0], 1'b0};
      end

      5'b11100: begin
        // 32-bit Logical Right Shift: Shift A right by one bit.
        internalFlags[2] = LSB_A;
        ALUOut = {1'b0, A[31:1]};
      end

      5'b11101: begin
        // 32-bit Arithmetic Right Shift: Shift A right by one bit (preserve sign).
        ALUOut = {MSB_A, A[31:1]};
      end

      5'b11110: begin
        // 32-bit Circular (Rotate) Left Shift:
        // Shift A left by one bit; insert current carry (FlagsOut[2]) at LSB.
        // The original MSB becomes the new carry.
        internalFlags[2] = MSB_A;
        ALUOut = {A[30:0], FlagsOut[2]};
      end

      5'b11111: begin
        // 32-bit Circular (Rotate) Right Shift:
        // Shift A right by one bit; insert current carry (FlagsOut[2]) at MSB.
        // The original LSB becomes the new carry.
        internalFlags[2] = LSB_A;
        ALUOut = {FlagsOut[2], A[31:1]};
      end

      default: begin
        // Default operation: output zero.
        ALUOut = 32'b0;
      end
    endcase

    // Common flag assignments:
    // Zero flag: 1 if ALUOut is zero.
    internalFlags[3] = (ALUOut == 32'b0);
    // Negative flag: taken from the MSB of ALUOut.
    internalFlags[1] = ALUOut[31];
  end

  //--------------------------------------------------------------------------
  // Synchronous Update of FlagsOut
  //--------------------------------------------------------------------------
  // On the rising edge of Clock, if WF is asserted, update the external flag output.
  // Flag bit order: {Zero, Carry, Negative, Overflow} (MSB to LSB).
  always @(posedge Clock) begin
    if (WF) begin
      FlagsOut[3] <= internalFlags[3]; // Zero flag
      FlagsOut[2] <= internalFlags[2]; // Carry flag
      FlagsOut[1] <= internalFlags[1]; // Negative flag
      FlagsOut[0] <= internalFlags[0]; // Overflow flag
    end
  end

endmodule
