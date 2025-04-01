`timescale 1ns / 1ps

module ALU_tb;
  // Testbench signals
  reg  [31:0] A;
  reg  [31:0] B;
  reg  [4:0]  FunSel;
  reg         WF;       // Write flag for updating FlagsOut on clock edge
  reg         Clock;    // Clock signal
  wire [3:0]  FlagsOut; // Output flags: {Zero, Carry, Negative, Overflow}
  wire [31:0] ALUOut;   // ALU result output

  // Instantiate the ALU (ArithmeticLogicUnit)
  // This is our updated ALU implementation with internal flag generation.
  ArithmeticLogicUnit uut (
    .A(A),
    .B(B),
    .FunSel(FunSel),
    .WF(WF),
    .Clock(Clock),
    .FlagsOut(FlagsOut),
    .ALUOut(ALUOut)
  );

  // Generate a clock: Toggle every 5 ns.
  initial begin
    Clock = 0;
    forever #5 Clock = ~Clock;
  end

  // Stimulus: Apply test vectors and display results.
  // For each test, we print ALUOut and the individual flags:
  //   Zero = FlagsOut[3], Carry = FlagsOut[2], Negative = FlagsOut[1], Overflow = FlagsOut[0]
  // We also display the current Cin (same as Carry) before circular operations.
  initial begin
    WF = 1;  // Enable flag update
    #10;     // Wait for global reset
    
    // =================== 16-bit Operations (Upper Halves) ===================
    
    // Test 1: Pass-through A_H (FunSel = 00000)
    A = 32'hF1234567;  // A_H = F123
    B = 32'h00000000;
    FunSel = 5'b00000;
    #10;
    $display("Test 1: FunSel=%b, A=%h, B=%h, ALUOut=%h", FunSel, A, B, ALUOut);
    $display("Flags: Z=%b, C=%b, N=%b, O=%b, Cin=%b", 
             FlagsOut[3], FlagsOut[2], FlagsOut[1], FlagsOut[0], FlagsOut[2]);

    #1; // Safety delay
    
    // Test 2: Pass-through B_H (FunSel = 00001)
    A = 32'h00000000;
    B = 32'h12345678;  // B_H = 1234
    FunSel = 5'b00001;
    #10;
    $display("Test 2: FunSel=%b, A=%h, B=%h, ALUOut=%h", FunSel, A, B, ALUOut);
    $display("Flags: Z=%b, C=%b, N=%b, O=%b, Cin=%b", 
             FlagsOut[3], FlagsOut[2], FlagsOut[1], FlagsOut[0], FlagsOut[2]);

    #1; // Safety delay

    // Test 3: 16-bit Addition: A_H + B_H (FunSel = 00100)
    A = 32'hABCD1234;  // A_H = ABCD
    B = 32'h12345678;  // B_H = 1234
    FunSel = 5'b00100;
    #10;
    $display("Test 3: FunSel=%b, A=%h, B=%h, ALUOut=%h", FunSel, A, B, ALUOut);
    $display("Flags: Z=%b, C=%b, N=%b, O=%b, Cin=%b", 
             FlagsOut[3], FlagsOut[2], FlagsOut[1], FlagsOut[0], FlagsOut[2]);

    #1; // Safety delay

    // Test 4: 16-bit Subtraction: A_H - B_H (FunSel = 00110)
    A = 32'h80001234;  // A_H = 8000 (negative)
    B = 32'h7FFF5678;  // B_H = 7FFF (positive)
    FunSel = 5'b00110;
    #10;
    $display("Test 4: FunSel=%b, A=%h, B=%h, ALUOut=%h", FunSel, A, B, ALUOut);
    $display("Flags: Z=%b, C=%b, N=%b, O=%b, Cin=%b", 
             FlagsOut[3], FlagsOut[2], FlagsOut[1], FlagsOut[0], FlagsOut[2]);

    #1; // Safety delay

    // Test 5: 16-bit Circular Rotate Left (FunSel = 01110)
    A = 32'hF1234567;  // A_H = F123
    #5;  // Allow time for previous operation's flags to settle
    $display("Before Test 5 (Rotate Left): Cin=%b", FlagsOut[2]);
    FunSel = 5'b01110;
    #10;
    $display("Test 5: FunSel=%b, A=%h, ALUOut=%h", FunSel, A, ALUOut);
    $display("Flags: Z=%b, C=%b, N=%b, O=%b, Cin=%b", 
             FlagsOut[3], FlagsOut[2], FlagsOut[1], FlagsOut[0], FlagsOut[2]);

    #1; // Safety delay

    // Test 6: 16-bit Circular Rotate Right (FunSel = 01111)
    #5;
    $display("Before Test 6 (Rotate Right): Cin=%b", FlagsOut[2]);
    #1;  // Delay before updating A for safe flag capture
    A = 32'h71234567;  // A_H = 7123
    FunSel = 5'b01111;
    #10;
    $display("Test 6: FunSel=%b, A=%h, ALUOut=%h", FunSel, A, ALUOut);
    $display("Flags: Z=%b, C=%b, N=%b, O=%b, Cin=%b", 
             FlagsOut[3], FlagsOut[2], FlagsOut[1], FlagsOut[0], FlagsOut[2]);

    #1; // Safety delay

    // =================== 32-bit Operations ===================
    
    // Test 7: 32-bit Pass-through A (FunSel = 10000)
    A = 32'h89ABCDEF;
    B = 32'h00000000;
    FunSel = 5'b10000;
    #10;
    $display("Test 7: FunSel=%b, A=%h, ALUOut=%h", FunSel, A, ALUOut);
    $display("Flags: Z=%b, C=%b, N=%b, O=%b, Cin=%b", 
             FlagsOut[3], FlagsOut[2], FlagsOut[1], FlagsOut[0], FlagsOut[2]);

    #1; // Safety delay

    // Test 8: 32-bit Bitwise NOT A (FunSel = 10010)
    A = 32'h0F0F0F0F;
    FunSel = 5'b10010;
    #10;
    $display("Test 8: FunSel=%b, A=%h, ALUOut=%h", FunSel, A, ALUOut);
    $display("Flags: Z=%b, C=%b, N=%b, O=%b, Cin=%b", 
             FlagsOut[3], FlagsOut[2], FlagsOut[1], FlagsOut[0], FlagsOut[2]);

    #1; // Safety delay

    // Test 9: 32-bit Addition: A + B (FunSel = 10100)
    A = 32'h00000001;
    B = 32'h00000002;
    FunSel = 5'b10100;
    #10;
    $display("Test 9: FunSel=%b, A=%h, B=%h, ALUOut=%h", FunSel, A, B, ALUOut);
    $display("Flags: Z=%b, C=%b, N=%b, O=%b, Cin=%b", 
             FlagsOut[3], FlagsOut[2], FlagsOut[1], FlagsOut[0], FlagsOut[2]);

    #1; // Safety delay

    // Test 10: 32-bit Subtraction: A - B (FunSel = 10110)
    A = 32'h00000000;
    B = 32'h00000001;
    FunSel = 5'b10110;
    #10;
    $display("Test 10: FunSel=%b, A=%h, B=%h, ALUOut=%h", FunSel, A, B, ALUOut);
    $display("Flags: Z=%b, C=%b, N=%b, O=%b, Cin=%b", 
             FlagsOut[3], FlagsOut[2], FlagsOut[1], FlagsOut[0], FlagsOut[2]);

    #1; // Safety delay

    // Test 11: 32-bit Circular Rotate Left (FunSel = 11110)
    A = 32'h80000001;
    #5;
    $display("Before Test 11 (Rotate Left): Cin=%b", FlagsOut[2]);
    FunSel = 5'b11110;
    #10;
    $display("Test 11: FunSel=%b, A=%h, ALUOut=%h", FunSel, A, ALUOut);
    $display("Flags: Z=%b, C=%b, N=%b, O=%b, Cin=%b", 
             FlagsOut[3], FlagsOut[2], FlagsOut[1], FlagsOut[0], FlagsOut[2]);

    #1; // Safety delay

    // Test 12: 32-bit Circular Rotate Right (FunSel = 11111)
    A = 32'h00000001;
    #5;
    $display("Before Test 12 (Rotate Right): Cin=%b", FlagsOut[2]);
    FunSel = 5'b11111;
    #10;
    $display("Test 12: FunSel=%b, A=%h, ALUOut=%h", FunSel, A, ALUOut);
    $display("Flags: Z=%b, C=%b, N=%b, O=%b, Cin=%b", 
             FlagsOut[3], FlagsOut[2], FlagsOut[1], FlagsOut[0], FlagsOut[2]);

    #1; // Safety delay

    // Test 13: 16-bit Bitwise AND on upper halves (FunSel = 00111)
    A = 32'hF1234567;
    B = 32'hE2345678;
    FunSel = 5'b00111;
    #10;
    $display("Test 13: FunSel=%b, A=%h, B=%h, ALUOut=%h", FunSel, A, B, ALUOut);
    $display("Flags: Z=%b, C=%b, N=%b, O=%b, Cin=%b", 
             FlagsOut[3], FlagsOut[2], FlagsOut[1], FlagsOut[0], FlagsOut[2]);

    #1; // Safety delay

    // Test 14: 32-bit Logical Left Shift (FunSel = 11011)
    #1; // Added safety delay before updating A
    A = 32'h12345678;
    FunSel = 5'b11011;
    #10;
    $display("Test 14: FunSel=%b, A=%h, ALUOut=%h", FunSel, A, ALUOut);
    $display("Flags: Z=%b, C=%b, N=%b, O=%b, Cin=%b", 
             FlagsOut[3], FlagsOut[2], FlagsOut[1], FlagsOut[0], FlagsOut[2]);

    #1; // Safety delay

    // Test 15: 32-bit Logical Right Shift (FunSel = 11100)
    #1; // Added safety delay before updating A
    A = 32'h12345678;
    FunSel = 5'b11100;
    #10;
    $display("Test 15: FunSel=%b, A=%h, ALUOut=%h", FunSel, A, ALUOut);
    $display("Flags: Z=%b, C=%b, N=%b, O=%b, Cin=%b", 
             FlagsOut[3], FlagsOut[2], FlagsOut[1], FlagsOut[0], FlagsOut[2]);

    #1; // Safety delay

    // Test 16: 32-bit Arithmetic Right Shift (FunSel = 11101)
    #1; // Added safety delay before updating A
    A = 32'hF2345678;
    FunSel = 5'b11101;
    #10;
    $display("Test 16: FunSel=%b, A=%h, ALUOut=%h", FunSel, A, ALUOut);
    $display("Flags: Z=%b, C=%b, N=%b, O=%b, Cin=%b", 
             FlagsOut[3], FlagsOut[2], FlagsOut[1], FlagsOut[0], FlagsOut[2]);

    $finish;
  end

endmodule
