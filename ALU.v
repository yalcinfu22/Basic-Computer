// ============================================================================
//  ArithmeticLogicUnit - Table-8 implementation with proper carry-out width
//  FlagsOut = { Z , C , N , O }
// ============================================================================
`timescale 1ns/1ps
module ArithmeticLogicUnit (
    input  wire [31:0] A,
    input  wire [31:0] B,
    input  wire        CarryIn,   // previous C flag
    input  wire [4:0]  FunSel,    // [4]=0 : 16-bit  |  [4]=1 : 32-bit
    output reg  [31:0] ALUOut,
    output reg  [3:0]  FlagsOut   // {Z,C,N,O}
);

    // --------------------------------------------------------------------
    // local signals
    // --------------------------------------------------------------------
    wire         mode16 = ~FunSel[4];
    wire  [3:0]  op     =  FunSel[3:0];

    // 16-bit upper halves
    wire [15:0]  AH16   = A[31:16];
    wire [15:0]  BH16   = B[31:16];

    // sign-extended to 32 bits
    wire [31:0]  AH     = {{16{AH16[15]}}, AH16};
    wire [31:0]  BH     = {{16{BH16[15]}}, BH16};

    // precompute 16-bit logic results
    wire [15:0]  and16  = AH16 &  BH16;
    wire [15:0]  or16   = AH16 |  BH16;
    wire [15:0]  xor16  = AH16 ^  BH16;
    wire [15:0]  nand16 = ~and16;

    // flags and temporaries
    reg  [3:0]   flagNext;     // {Z,C,N,O}
    reg          signA, signB, signR;
    reg  [16:0]  sum17;        // for 16-bit adds
    reg  [32:0]  sum33;        // for 32-bit adds

    // --------------------------------------------------------------------
    // combinational ALU
    // --------------------------------------------------------------------
    always @* begin
        ALUOut   = 32'd0;
        flagNext = 4'd0;        // clear all flags each cycle

        if (mode16) begin
            //------------------   16-bit group  -------------------------
            case (op)
                4'b0000: ALUOut = {{16{AH16[15]}}, AH16};   // A_H
                4'b0001: ALUOut = {{16{BH16[15]}}, BH16};   // B_H
                4'b0010: ALUOut = ~AH;                     // NOT A_H
                4'b0011: ALUOut = ~BH;                     // NOT B_H

                // A_H + B_H
                4'b0100: begin
                    sum17 = {1'b0, AH16} + {1'b0, BH16};
                    flagNext[2] = sum17[16];
                    ALUOut = {{16{sum17[15]}}, sum17[15:0]};
                    signA = AH16[15]; signB = BH16[15]; signR = sum17[15];
                    flagNext[0] = (signA==signB) && (signR!=signA);
                end

                // A_H + B_H + CarryIn
                4'b0101: begin
                    sum17 = {1'b0, AH16} + {1'b0, BH16} + {16'd0, CarryIn};
                    flagNext[2] = sum17[16];
                    ALUOut = {{16{sum17[15]}}, sum17[15:0]};
                    signA = AH16[15]; signB = BH16[15]; signR = sum17[15];
                    flagNext[0] = (signA==signB) && (signR!=signA);
                end

                // A_H - B_H
                4'b0110: begin
                    sum17 = {1'b0, AH16} + {1'b0, ~BH16} + 17'd1;
                    flagNext[2] = sum17[16];
                    ALUOut = {{16{sum17[15]}}, sum17[15:0]};
                    signA = AH16[15]; signB = BH16[15]; signR = sum17[15];
                    flagNext[0] = (signA!=signB) && (signR!=signA);
                end

                4'b0111: ALUOut = {{16{and16[15]}},  and16};   // AND
                4'b1000: ALUOut = {{16{or16[15]}},   or16};    // OR
                4'b1001: ALUOut = {{16{xor16[15]}},  xor16};   // XOR
                4'b1010: ALUOut = {{16{nand16[15]}}, nand16};  // NAND

                // your shift/rotate code (unchanged)
                4'b1011: begin
                    flagNext[2] = AH[15];
                    ALUOut      = {AH[30:0],1'b0};
                end
                4'b1100: begin
                    flagNext[2] = AH[0];
                    ALUOut      = {1'b0, AH[31:1]};
                end
                4'b1101: begin
                    flagNext[2] = AH[0];
                    ALUOut      = {AH[31], AH[31:1]};
                end
                4'b1110: begin
                    flagNext[2] = AH[15];
                    ALUOut      = {AH[30:0], CarryIn};
                end
                4'b1111: begin
                    flagNext[2] = AH[0];
                    ALUOut      = {CarryIn, AH[31:1]};
                end
            endcase

            // Zero & Negative for 16 bits
            flagNext[3] = (ALUOut[15:0] == 16'h0000);
            flagNext[1] = ALUOut[15];

        end else begin
            //------------------   32-bit group  -------------------------
            case (op)
                4'b0000: ALUOut = A;      // PASS A
                4'b0001: ALUOut = B;      // PASS B
                4'b0010: ALUOut = ~A;     // NOT A
                4'b0011: ALUOut = ~B;     // NOT B

                // A + B
                4'b0100: begin
                    sum33 = {1'b0, A} + {1'b0, B};
                    flagNext[2] = sum33[32];
                    ALUOut      = sum33[31:0];
                    signA=A[31]; signB=B[31]; signR=ALUOut[31];
                    flagNext[0] = (signA==signB) && (signR!=signA);
                end

                // A + B + CarryIn
                4'b0101: begin
                    sum33 = {1'b0, A} + {1'b0, B} + {{32{1'b0}}, CarryIn};
                    flagNext[2] = sum33[32];
                    ALUOut      = sum33[31:0];
                    signA=A[31]; signB=B[31]; signR=ALUOut[31];
                    flagNext[0] = (signA==signB) && (signR!=signA);
                end

                // A - B
                4'b0110: begin
                    sum33 = {1'b0, A} + {1'b0, ~B} + 33'd1;
                    flagNext[2] = sum33[32];
                    ALUOut      = sum33[31:0];
                    signA=A[31]; signB=B[31]; signR=ALUOut[31];
                    flagNext[0] = (signA!=signB) && (signR!=signA);
                end

                4'b0111: ALUOut = A & B;      // AND
                4'b1000: ALUOut = A | B;      // OR
                4'b1001: ALUOut = A ^ B;      // XOR
                4'b1010: ALUOut = ~(A & B);   // NAND

                // your 32-bit shift/rotate code (unchanged)
                4'b1011: begin
                    flagNext[2] = A[31];
                    ALUOut      = {A[30:0],1'b0};
                end
                4'b1100: begin
                    flagNext[2] = A[0];
                    ALUOut      = {1'b0, A[31:1]};
                end
                4'b1101: begin
                    flagNext[2] = A[0];
                    ALUOut      = {A[31], A[31:1]};
                end
                4'b1110: begin
                    flagNext[2] = A[31];
                    ALUOut      = {A[30:0], CarryIn};
                end
                4'b1111: begin
                    flagNext[2] = A[0];
                    ALUOut      = {CarryIn, A[31:1]};
                end
            endcase

            // Zero & Negative for 32 bits
            flagNext[3] = (ALUOut == 32'h0000_0000);
            flagNext[1] = ALUOut[31];
        end

        // drive flags
        FlagsOut = flagNext;
    end

endmodule
