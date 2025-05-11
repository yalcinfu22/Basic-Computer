`timescale 1ns / 1ps 

module CPUSystem_tb;
  // Clock & reset
  reg  Clock = 0;
  reg  Reset = 1;
  wire [11:0] T;

  // Instantiate your CPU System
  CPUSystem uut (
    .Clock (Clock),
    .Reset (Reset),
    .T     (T)
  );

  // 100 MHz clock
  initial begin
    forever #5 Clock = ~Clock;
  end

  // Reset pulse: hold for 20 ns, then release
  initial begin
    #20 Reset = 0;
  end

  // Memory initialization, stimulus, and monitors
  initial begin
    // wait for UUT to power up
    #1;

    // Preload little-endian BRA 0x18:
    // address 0x0000 ← low byte (0x18)
    // address 0x0001 ← high byte (0x00, since OPCODE=0x00 for BRA)
    uut.ALUSys.MEM.RAM_DATA[16'h0000] = 8'h18;
    uut.ALUSys.MEM.RAM_DATA[16'h0001] = 8'h00;
    $display("[INIT] M[0] = %02h, M[1] = %02h", 
             uut.ALUSys.MEM.RAM_DATA[16'h0000],
             uut.ALUSys.MEM.RAM_DATA[16'h0001]);

    // wait until after reset de-assertion
    #25;

    // Step through a few clock edges and print PC/IR
    repeat (4) @(posedge Clock) begin
      $display("Time %0t | T = %b | PC = 0x%04h | IR = 0x%04h",
               $time, T, uut.ALUSys.ARF.PC.Q, uut.ALUSys.IR.IROut);
    end

    // Also decode fields at T2
    $display("Decoded @ T2: OPCODE = 0x%02h, RegSel = 0x%01h, Addr = 0x%02h",
             uut.Opcode, uut.RegSel, uut.Address);

    #10;
    $finish;
  end
endmodule
