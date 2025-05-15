// ============================================================================
//  ArithmeticLogicUnit - full Table-8 implementation, combinational flags
//  FlagsOut = { Z , C , N , O }
// ============================================================================
`timescale 1ns/1ps
module ArithmeticLogicUnit (
    input  wire [31:0] A,
    input  wire [31:0] B,
    input  wire        CarryIn,   // comes from previous C flag for ADC / rotates
    input  wire [4:0]  FunSel,    // [4]=0 : 16-bit  |  [4]=1 : 32-bit
    output reg  [31:0] ALUOut,
    output reg  [3:0]  FlagsOut   // {Z,C,N,O}
);
    //--------------------------------------------------------------------
    // local helpers
    //--------------------------------------------------------------------
    wire         mode16 = ~FunSel[4];
    wire  [3:0]  op     =  FunSel[3:0];

    // upper halves, sign-extended to 32 bits
    wire [31:0]  AH = {{16{A[31]}}, A[31:16]};
    wire [31:0]  BH = {{16{B[31]}}, B[31:16]};

    reg  [3:0]   flagNext;          // {Z,C,N,O}
    reg          signA, signB, signR;

    //--------------------------------------------------------------------
    // comb ALU
    //--------------------------------------------------------------------
    always @* begin
        // default
        ALUOut   = 32'd0;
        flagNext = 4'd0;            // clear all flags at start of cycle

        if (mode16) begin
            //------------------   16-bit group  -------------------------
            case (op)
            // 0 0 0 0  : A_H      (pass)
            4'b0000 : ALUOut = AH;

            // 0 0 0 1  : B_H
            4'b0001 : ALUOut = BH;

            // 0 0 1 0  : NOT A_H
            4'b0010 : ALUOut = ~AH;

            // 0 0 1 1  : NOT B_H
            4'b0011 : ALUOut = ~BH;

            // 0 1 0 0  : A_H + B_H
            4'b0100 : begin
                {flagNext[2], ALUOut} = AH + BH;          // C
                signA = AH[15];  signB = BH[15];  signR = ALUOut[15];
                flagNext[0] = (signA==signB) && (signR!=signA); // O
            end

            // 0 1 0 1  : A_H + B_H + CarryIn
            4'b0101 : begin
                {flagNext[2], ALUOut} = AH + BH + CarryIn;
                signA = AH[15];  signB = BH[15];  signR = ALUOut[15];
                flagNext[0] = (signA==signB) && (signR!=signA);
            end

            // 0 1 1 0  : A_H - B_H
            4'b0110 : begin
                {flagNext[2], ALUOut} = AH + (~BH) + 1'b1; // C = ~borrow
                signA = AH[15];  signB = BH[15];  signR = ALUOut[15];
                flagNext[0] = (signA!=signB) && (signR!=signA); // O
            end

            // 0 1 1 1  : A_H AND B_H
            4'b0111 : ALUOut = AH & BH;

            // 1 0 0 0  : A_H OR  B_H
            4'b1000 : ALUOut = AH | BH;

            // 1 0 0 1  : A_H XOR B_H
            4'b1001 : ALUOut = AH ^ BH;

            // 1 0 1 0  : A_H NAND B_H
            4'b1010 : ALUOut = ~(AH & BH);

            // 1 0 1 1  : LSL A_H (<<1)
            4'b1011 : begin
                flagNext[2] = AH[15];          // old MSB ? Carry
                ALUOut      = {AH[30:0],1'b0};
            end

            // 1 1 0 0  : LSR A_H (>>1 logical)
            4'b1100 : begin
                flagNext[2] = AH[0];           // old LSB
                ALUOut      = {1'b0, AH[31:1]};
            end

            // 1 1 0 1  : ASR A_H (>>1 arithmetic)
            4'b1101 : begin
                flagNext[2] = AH[0];
                ALUOut      = {AH[31], AH[31:1]};  // replicate sign
            end

            // 1 1 1 0  : CSL A_H (rotate left through Carry)
            4'b1110 : begin
                flagNext[2] = AH[15];          // old MSB out
                ALUOut      = {AH[30:0], CarryIn};
            end

            // 1 1 1 1  : CSR A_H (rotate right through Carry)
            4'b1111 : begin
                flagNext[2] = AH[0];           // old LSB out
                ALUOut      = {CarryIn, AH[31:1]};
            end
            endcase

            // Z & N for 16-bit result
            flagNext[3] = (ALUOut[15:0] == 16'h0000);
            flagNext[1] = ALUOut[15];

        end else begin
            //------------------   32-bit group  -------------------------
            case (op)
            4'b0000 : ALUOut = A;                  // A
            4'b0001 : ALUOut = B;                  // B
            4'b0010 : ALUOut = ~A;                 // NOT A
            4'b0011 : ALUOut = ~B;                 // NOT B

            4'b0100 : begin                        // A + B
                {flagNext[2], ALUOut} = A + B;
                signA=A[31]; signB=B[31]; signR=ALUOut[31];
                flagNext[0] = (signA==signB)&&(signR!=signA);
            end
            4'b0101 : begin                        // A + B + Cin
                {flagNext[2], ALUOut} = A + B + CarryIn;
                signA=A[31]; signB=B[31]; signR=ALUOut[31];
                flagNext[0] = (signA==signB)&&(signR!=signA);
            end
            4'b0110 : begin                        // A - B
                {flagNext[2], ALUOut} = A + (~B) + 1'b1;
                signA=A[31]; signB=B[31]; signR=ALUOut[31];
                flagNext[0] = (signA!=signB)&&(signR!=signA);
            end
            4'b0111 : ALUOut = A & B;              // AND
            4'b1000 : ALUOut = A | B;              // OR
            4'b1001 : ALUOut = A ^ B;              // XOR
            4'b1010 : ALUOut = ~(A & B);           // NAND

            4'b1011 : begin                        // LSL A
                flagNext[2] = A[31];
                ALUOut      = {A[30:0],1'b0};
            end
            4'b1100 : begin                        // LSR A
                flagNext[2] = A[0];
                ALUOut      = {1'b0, A[31:1]};
            end
            4'b1101 : begin                        // ASR A
                flagNext[2] = A[0];
                ALUOut      = {A[31], A[31:1]};
            end
            4'b1110 : begin                        // CSL A
                flagNext[2] = A[31];
                ALUOut      = {A[30:0], CarryIn};
            end
            4'b1111 : begin                        // CSR A
                flagNext[2] = A[0];
                ALUOut      = {CarryIn, A[31:1]};
            end
            endcase

            // Z & N for 32-bit result
            flagNext[3] = (ALUOut == 32'h0000_0000);
            flagNext[1] = ALUOut[31];
        end

        //----------------------------------------------------------------
        // drive outputs
        //----------------------------------------------------------------
        FlagsOut = flagNext; // combinational - no clock
    end
endmodule
