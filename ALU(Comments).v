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
  input  wire      WF,          // Write flag: enables updating of FlagsOut
  input  wire      Clock,       // Clock signal (for synchronous flag update)
  output reg  [3:0] FlagsOut,   // Status flags: {Zero, Carry, Negative, Overflow}
  output reg  [31:0] ALUOut    // 32-bit ALU result output
);

  //--------------------------------------------------------------------------
  // Internal flag register:
  // internalFlags holds the computed flag values.
  // Bit assignment:
  //   internalFlags[3] = Zero flag (Z)
  //   internalFlags[2] = Carry flag (C)
  //   internalFlags[1] = Negative flag (N)
  //   internalFlags[0] = Overflow flag (O)
  //--------------------------------------------------------------------------
  reg [3:0] internalFlags;

  //--------------------------------------------------------------------------
  // Splitting the 32-bit inputs and sign extension for 16-bit operations
  //--------------------------------------------------------------------------
  // Lower 16 bits (not used in our 16-bit ALU operations).
  wire [15:0] A_L, B_L;
  assign A_L = A[15:0];
  assign B_L = B[15:0];

  // For 16-bit operations on the upper half, we sign-extend A[31:16] and B[31:16]
  // into a full 32-bit word.
  wire [31:0] sign_extended_A_H, sign_extended_B_H;
  assign sign_extended_A_H = {{16{A[31]}}, A[31:16]};
  assign sign_extended_B_H = {{16{B[31]}}, B[31:16]};

  //--------------------------------------------------------------------------
  // Extracting key bits from A and B for flag calculations.
  //--------------------------------------------------------------------------
  wire MSB_A, MSB_B;      // Most Significant Bits (sign bits) of A and B.
  assign MSB_A = A[31];
  assign MSB_B = B[31];

  wire LSB_A;             // Least Significant Bit of full A.
  assign LSB_A = A[0];

  // For operations on the upper half, obtain the LSB of the sign-extended A_H.
  wire LSB_A_H;
  assign LSB_A_H = sign_extended_A_H[0];

  //--------------------------------------------------------------------------
  // Arithmetic intermediate signals:
  // Sum: A 33-bit register used for addition/subtraction to capture an extra
  //      carry-out bit (Sum[32]).
  // Res: A 32-bit register that holds intermediate results.
  //--------------------------------------------------------------------------
  reg [32:0] Sum;
  reg [31:0] Res;
  
  //--------------------------------------------------------------------------
  // Combinational logic: ALU Operation Cases
  //--------------------------------------------------------------------------
  // This always block computes the ALU output based on the function select (FunSel).
  // It also computes intermediate flag values in internalFlags.
  always @(*) begin
    // Clear intermediate signals
    Sum = 33'b0;
    Res = 32'b0;
    
    case(FunSel)
      ///////////// 16-bit Operations on Upper Halves (using sign_extended_A_H/B_H) /////////////

      5'b00000: begin
        // Pass-through: Output the sign-extended upper half of A.
        ALUOut = sign_extended_A_H;
      end

      5'b00001: begin
        // Pass-through: Output the sign-extended upper half of B.
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
        // 16-bit Addition: Add sign_extended_A_H and sign_extended_B_H.
        // The extra bit (flagInput[2]) is the carry-out.
        {internalFlags[2], ALUOut} = sign_extended_A_H + sign_extended_B_H;
      end

      5'b00101: begin
        // 16-bit Addition with Carry:
        // Add sign_extended_A_H, sign_extended_B_H, and the current carry (FlagsOut[2]).
        {internalFlags[2], ALUOut} = sign_extended_A_H + sign_extended_B_H + FlagsOut[2];
        // Detect overflow: if operands have the same sign but result's sign differs.
        internalFlags[0] = (MSB_A == MSB_B) && (ALUOut[31] != MSB_A);
      end

      5'b00110: begin
        // 16-bit Subtraction: A_H - B_H computed as A_H + ~B_H + 1.
        {internalFlags[2], ALUOut} = sign_extended_A_H + ~sign_extended_B_H + 1'b1;
        // Set overflow flag under specific sign conditions.
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
        // Shift sign_extended_A_H left by one bit. The new carry becomes the original MSB_A.
        internalFlags[2] = MSB_A;
        // Shift left and re-sign-extend (using bit 14 of sign_extended_A_H as the new sign bit).
        ALUOut = {{16{sign_extended_A_H[14]}}, sign_extended_A_H[14:0], 1'b0};
      end

      5'b01100: begin
        // Logical Right Shift on upper half:
        // Shift sign_extended_A_H right by one bit. The new carry becomes the original LSB of sign_extended_A_H.
        internalFlags[2] = LSB_A_H;
        // Right shift with zero-fill on the left.
        ALUOut = {17'b0, sign_extended_A_H[15:1]};
      end

      5'b01101: begin
        // Arithmetic Right Shift on upper half:
        // Shift right while preserving the sign (the MSB remains unchanged).
        ALUOut = {{17{MSB_A}}, sign_extended_A_H[15:1]};
      end

      5'b01110: begin
        // Circular (Rotate) Left Shift on upper half using carry:
        // Shift sign_extended_A_H left by one bit; the LSB becomes the current carry (FlagsOut[2]),
        // and the original MSB (A[31]) becomes the new carry.
        internalFlags[2] = MSB_A;
        ALUOut = {{16{sign_extended_A_H[14]}}, sign_extended_A_H[14:0], FlagsOut[2]};
      end

      5'b01111: begin
        // Circular (Rotate) Right Shift on upper half using carry:
        // Shift sign_extended_A_H right by one bit; insert the current carry (FlagsOut[2])
        // at the MSB. The original LSB of sign_extended_A_H becomes the new carry.
        internalFlags[2] = LSB_A_H;
        ALUOut = {{16{FlagsOut[2]}}, FlagsOut[2], sign_extended_A_H[15:1]};
      end

      ///////////// 32-bit Operations (Full A and B) /////////////

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
        // Optionally, additional flag handling may be done here.
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
        // 32-bit Subtraction: A - B computed as A + ~B + 1.
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
        // 32-bit Arithmetic Right Shift: Shift A right by one bit, preserving the sign.
        ALUOut = {MSB_A, A[31:1]};
      end

      5'b11110: begin
        // 32-bit Circular (Rotate) Left Shift:
        // Shift A left by one bit; insert the current carry (FlagsOut[2]) at LSB.
        // New carry becomes the original MSB of A.
        internalFlags[2] = MSB_A;
        ALUOut = {A[30:0], FlagsOut[2]};
      end

      5'b11111: begin
        // 32-bit Circular (Rotate) Right Shift:
        // Shift A right by one bit; insert the current carry (FlagsOut[2]) at MSB.
        // New carry becomes the original LSB of A.
        internalFlags[2] = LSB_A;
        ALUOut = {FlagsOut[2], A[31:1]};
      end

      default: begin
        // If no valid operation is selected, output zero.
        ALUOut = 32'b0;
      end
    endcase

    // Final flag assignments (common to all operations):
    // Zero flag: set if ALUOut equals zero.
    internalFlags[3] = (ALUOut == 32'b0);
    // Negative flag: derived from the MSB of ALUOut.
    internalFlags[1] = ALUOut[31];
  end

  //--------------------------------------------------------------------------
  // Synchronous flag update
  //--------------------------------------------------------------------------
  // On the rising edge of Clock, if WF (Write Flag) is high, update the output
  // FlagsOut with the internally computed flags.
  always @(posedge Clock) begin
    if (WF) begin
      FlagsOut[3] <= internalFlags[3]; // Zero flag
      FlagsOut[2] <= internalFlags[2]; // Carry flag
      FlagsOut[1] <= internalFlags[1]; // Negative flag
      FlagsOut[0] <= internalFlags[0]; // Overflow flag
    end
  end

endmodule
