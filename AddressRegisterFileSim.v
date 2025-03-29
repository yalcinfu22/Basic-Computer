`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Testbench for Address Register File (ARF)
// This testbench applies several test cases to load values into PC, SP, and AR,
// and then selects the outputs using OutCSel and OutDSel.
//////////////////////////////////////////////////////////////////////////////////

module AddresRegisterFileSim;

  // Declare testbench signals.
  reg [31:0] I;
  reg [2:0] RegSel;
  reg [1:0] FunSel;
  reg [1:0] OutCSel;
  reg [1:0] OutDSel;
  reg Clock;
  wire [15:0] OutC;
  wire [15:0] OutD;

  // Instantiate the Address Register File
  AddresRegisterFile ARF (
    .I(I),
    .RegSel(RegSel),
    .FunSel(FunSel),
    .OutCSel(OutCSel),
    .OutDSel(OutDSel),
    .Clock(Clock),
    .OutC(OutC),
    .OutD(OutD)
  );

  // Generate a clock with a period of 10 ns.
  initial begin
    Clock = 1'b0;
    forever #5 Clock = ~Clock;
  end

  // Test sequence.
  initial begin
    // Initialize all signals.
    I        = 32'h0000_0000;
    RegSel   = 3'b000;
    FunSel   = 2'b00;
    OutCSel  = 2'b00;
    OutDSel  = 2'b00;
    #10;

    // Test Case 1: Load PC (Program Counter)
    // PC is enabled when RegSel[2] is active.
    // Set RegSel = 3'b100, so only bit 2 is active.
    RegSel = 3'b100;  
    FunSel = 2'b10;     // Load operation.
    I      = 32'h0000_AAAA; // Lower 16 bits = 0xAAAA.
    #10;  // Wait one clock edge for PC to update.

    // Test Case 2: Load SP (Stack Pointer)
    // SP is enabled when RegSel[1] is active.
    RegSel = 3'b010;  
    FunSel = 2'b10;     // Load operation.
    I      = 32'h0000_BBBB; // Lower 16 bits = 0xBBBB.
    #10;

    // Test Case 3: Load AR (Address Register)
    // AR is enabled when RegSel[0] is active.
    RegSel = 3'b001;  
    FunSel = 2'b10;     // Load operation.
    I      = 32'h0000_CCCC; // Lower 16 bits = 0xCCCC.
    #10;

    // Test Case 4: Select outputs via OutCSel and OutDSel.
    // OutCSel and OutDSel determine which register's 16-bit value is output.
    // According to your design:
    //  00 selects PC, 01 selects SP, and 10/11 select AR.
    OutCSel = 2'b00; // OutC = PC (should be 0xAAAA).
    OutDSel = 2'b01; // OutD = SP (should be 0xBBBB).
    #10;

    // Test Case 5: Change output selection to AR.
    OutCSel = 2'b10; // OutC = AR (should be 0xCCCC).
    OutDSel = 2'b10; // OutD = AR.
    #10;
    
    // Test Case 6: Use selection code '11' for both outputs (also selects AR).
    OutCSel = 2'b11; 
    OutDSel = 2'b11; 
    #10;

    $finish;
  end

endmodule
