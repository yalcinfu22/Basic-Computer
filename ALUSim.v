`timescale 1ns / 1ps

module ALU_tb;
  // Testbench signals
  reg  [31:0] A;
  reg  [31:0] B;
  reg  [4:0]  FunSel;
  wire [31:0] ALUOut;
  
  // Instantiate the ALU
  ALU uut (
    .A(A),
    .B(B),
    .FunSel(FunSel),
    .ALUOut(ALUOut)
  );

  // Optional: Dump waveforms for simulation
  initial begin
    $dumpfile("ALU_tb.vcd");
    $dumpvars(0, ALU_tb);
  end

  // Stimulus: Apply test vectors
  initial begin
    // Wait 10 ns for global reset to finish.
    #10;
    
    // ----------------- 16-bit Operations (upper halves) -----------------
    // Test 1: Pass-through A_H (FunSel = 00000)
    A = 32'hF1234567; // A_H = F123
    B = 32'h00000000;
    FunSel = 5'b00000;
    #10;
    $display("Test 1 (Pass A_H): FunSel=%b, A=%h, ALUOut=%h, FlagsOut=%b, Cin=%b", 
             FunSel, A, ALUOut, uut.FlagsOut, uut.Cin);
    
    // Test 2: Pass-through B_H (FunSel = 00001)
    A = 32'h00000000;
    B = 32'h12345678; // B_H = 1234
    FunSel = 5'b00001;
    #10;
    $display("Test 2 (Pass B_H): FunSel=%b, B=%h, ALUOut=%h, FlagsOut=%b, Cin=%b", 
             FunSel, B, ALUOut, uut.FlagsOut, uut.Cin);
    
    // Test 3: 16-bit Addition (A_H + B_H, FunSel = 00100)
    A = 32'hABCD1234; // A_H = ABCD
    B = 32'h12345678; // B_H = 1234
    FunSel = 5'b00100;
    #10;
    $display("Test 3 (16-bit A_H+B_H): FunSel=%b, A=%h, B=%h, ALUOut=%h, FlagsOut=%b, Cin=%b", 
             FunSel, A, B, ALUOut, uut.FlagsOut, uut.Cin);
    
    // Test 4: 16-bit Subtraction (A_H - B_H, FunSel = 00110)
    A = 32'h80001234; // A_H = 8000 (negative)
    B = 32'h7FFF5678; // B_H = 7FFF (positive)
    FunSel = 5'b00110;
    #10;
    $display("Test 4 (16-bit A_H-B_H): FunSel=%b, A=%h, B=%h, ALUOut=%h, FlagsOut=%b, Cin=%b", 
             FunSel, A, B, ALUOut, uut.FlagsOut, uut.Cin);
    
    // Test 5: 16-bit Circular Left Shift using carry (FunSel = 01110)
    A = 32'hF1234567; // A_H = F123
    // Display old Cin before operation:
    #5;
    $display("Before 16-bit Circular Left Shift: Cin=%b", uut.Cin);
    FunSel = 5'b01110;
    #10;
    $display("Test 5 (16-bit Circular Left Shift): FunSel=%b, A=%h, ALUOut=%h, FlagsOut=%b, Cin=%b", 
             FunSel, A, ALUOut, uut.FlagsOut, uut.Cin);
    
    // Test 6: 16-bit Circular Right Shift using carry (FunSel = 01111)
    A = 32'h71234567; // A_H = 7123 (example value)
    // Display old Cin before operation:
    #5;
    $display("Before 16-bit Circular Right Shift: Cin=%b", uut.Cin);
    FunSel = 5'b01111;
    #10;
    $display("Test 6 (16-bit Circular Right Shift): FunSel=%b, A=%h, ALUOut=%h, FlagsOut=%b, Cin=%b", 
             FunSel, A, ALUOut, uut.FlagsOut, uut.Cin);
    
    // ----------------- 32-bit Operations -----------------
    // Test 7: 32-bit Pass-through A (FunSel = 10000)
    A = 32'h89ABCDEF;
    B = 32'h00000000;
    FunSel = 5'b10000;
    #10;
    $display("Test 7 (32-bit Pass A): FunSel=%b, A=%h, ALUOut=%h, FlagsOut=%b, Cin=%b", 
             FunSel, A, ALUOut, uut.FlagsOut, uut.Cin);
    
    // Test 8: 32-bit Bitwise NOT A (FunSel = 10010)
    A = 32'h0F0F0F0F;
    FunSel = 5'b10010;
    #10;
    $display("Test 8 (32-bit NOT A): FunSel=%b, A=%h, ALUOut=%h, FlagsOut=%b, Cin=%b", 
             FunSel, A, ALUOut, uut.FlagsOut, uut.Cin);
    
    // Test 9: 32-bit Addition A+B (FunSel = 10100)
    A = 32'h00000001;
    B = 32'h00000002;
    FunSel = 5'b10100;
    #10;
    $display("Test 9 (32-bit A+B): FunSel=%b, A=%h, B=%h, ALUOut=%h, FlagsOut=%b, Cin=%b", 
             FunSel, A, B, ALUOut, uut.FlagsOut, uut.Cin);
    
    // Test 10: 32-bit Subtraction (A - B, FunSel = 10110)
    A = 32'h00000000;
    B = 32'h00000001;
    FunSel = 5'b10110;
    #10;
    $display("Test 10 (32-bit A-B): FunSel=%b, A=%h, B=%h, ALUOut=%h, FlagsOut=%b, Cin=%b", 
             FunSel, A, B, ALUOut, uut.FlagsOut, uut.Cin);
    
    // Test 11: 32-bit Circular Rotate Left (FunSel = 11110)
    A = 32'h80000001; // Example: MSB is set
    // Display old Cin before operation:
    #5;
    $display("Before 32-bit Rotate Left: Cin=%b", uut.Cin);
    FunSel = 5'b11110;
    #10;
    $display("Test 11 (32-bit Rotate Left): FunSel=%b, A=%h, ALUOut=%h, FlagsOut=%b, Cin=%b", 
             FunSel, A, ALUOut, uut.FlagsOut, uut.Cin);
    
    // Test 12: 32-bit Circular Rotate Right (FunSel = 11111)
    A = 32'h00000001; // Example: LSB is set
    // Display old Cin before operation:
    #5;
    $display("Before 32-bit Rotate Right: Cin=%b", uut.Cin);
    FunSel = 5'b11111;
    #10;
    $display("Test 12 (32-bit Rotate Right): FunSel=%b, A=%h, ALUOut=%h, FlagsOut=%b, Cin=%b", 
             FunSel, A, ALUOut, uut.FlagsOut, uut.Cin);
    
    // End simulation
    $finish;
  end

endmodule
