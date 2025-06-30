`timescale 1ns / 1ps
module ArithmeticLogicUnit (
    input wire [31:0] A,
    input wire [31:0] B,
    input wire [4:0] FunSel,
    input wire WF,
    input wire Clock,
    output reg [31:0] ALUOut,
    output reg [3:0] FlagsOut
);

  reg [32:0] carryChecker; 
  reg [31:0] signExtendedA, signExtendedB; 

  always @(*) begin
     
        signExtendedA <= {{16{A[15]}}, A[15:0]};
        signExtendedB <= {{16{B[15]}}, B[15:0]};
      case (FunSel)
        5'b00000: begin
          ALUOut <= signExtendedA;
        end
        5'b00001: begin
          ALUOut <= signExtendedB;
        end

        5'b00010: begin
          ALUOut <= ~signExtendedA;
        end
        5'b00011: begin
          ALUOut <= ~signExtendedB;
        end

        5'b00100: begin
          carryChecker <= signExtendedA + signExtendedB;
          ALUOut <= signExtendedA + signExtendedB;
        end
        5'b00101: begin
          carryChecker <= signExtendedA + signExtendedB + FlagsOut[2];
          ALUOut <= signExtendedA + signExtendedB + FlagsOut[2];
        end
        5'b00110: begin
          carryChecker <= signExtendedA - signExtendedB;
          ALUOut <= signExtendedA - signExtendedB;
        end

        5'b00111: ALUOut <= signExtendedA & signExtendedB;
        5'b01000: ALUOut <= signExtendedA | signExtendedB;
        5'b01001: ALUOut <= signExtendedA ^ signExtendedB;
        5'b01010: ALUOut <= ~(signExtendedA & signExtendedB);

        5'b01011: begin
          ALUOut <= signExtendedA << 1;
        end
        5'b01100: begin
          ALUOut <= signExtendedA >> 1;
        end
        5'b01101: begin
          ALUOut <= signExtendedA >>> 1;
        end
        5'b01110: begin
          ALUOut <= {signExtendedA[30:0], signExtendedA[31]};
        end
        5'b01111: begin
          ALUOut <= {signExtendedA[0], signExtendedA[31:1]};
        end

        // 32 bit operations
        5'b10000: begin
          ALUOut <= A;
        end
        5'b10001: begin
          ALUOut <= B;
        end
        5'b10010: begin
          ALUOut <= ~A;
        end
        5'b10011: begin
          ALUOut <= ~B;
        end
        5'b10100: begin
          carryChecker <= A + B;
          ALUOut <= A + B;
        end
        5'b10101: begin
          carryChecker <= A + B + FlagsOut[2]; 
          ALUOut <= carryChecker[31:0];
        end
        5'b10110: begin
          carryChecker <= A - B;
          ALUOut <= A - B;
        end

        5'b10111: ALUOut <= A & B;
        5'b11000: ALUOut <= A | B;
        5'b11001: ALUOut <= A ^ B;
        5'b11010: ALUOut <= ~(A & B);

        5'b11011: begin
          ALUOut <= A << 1;
        end
        5'b11100: begin
          ALUOut <= A >> 1;
        end
        5'b11101: begin
          ALUOut <= A >>> 1;
        end
        5'b11110: begin
          ALUOut <= {A[30:0], A[31]};
        end
        5'b11111: begin
          ALUOut <= {A[0], A[31:1]};
        end
        default: ALUOut <= ALUOut;
      endcase
    end


  always @(posedge Clock) begin
    if (WF) begin
      case (FunSel)
        5'b00000: begin end
        5'b00001: begin end
        5'b00010: begin end 
        5'b00011: begin end
        5'b00100: begin
          FlagsOut[2] <= carryChecker[32];
          FlagsOut[0] <= (signExtendedA[31] && signExtendedB[31] && ~ALUOut[15]) || (~signExtendedA[31] && ~signExtendedB[31] && ALUOut[15]);
        end
        5'b00101: begin
          FlagsOut[3] <= ALUOut == 0;
          FlagsOut[2] <= carryChecker[32];
          FlagsOut[0] <= (signExtendedA[31] && signExtendedB[31] && ~ALUOut[15]) || (~signExtendedA[31] && ~signExtendedB[31] && ALUOut[15]);
        end
        5'b00110: begin
          FlagsOut[2] <= carryChecker[32];
          FlagsOut[0] <= (~signExtendedA[31] && signExtendedB[31] && ALUOut[15]) || (signExtendedA[31] && ~signExtendedB[31] && ~ALUOut[15]);
        end
        5'b00111: begin end
        5'b01000: begin end
        5'b01001: begin end
        5'b01010: begin end
        5'b01011: begin
          FlagsOut[2] <= signExtendedA[31];  
        end
        5'b01100: begin
          FlagsOut[2] <= signExtendedA[0];  
        end
        5'b01101: begin
          FlagsOut[2] <= signExtendedA[0];  
        end
        5'b01110: begin
          FlagsOut[2] <= signExtendedA[31]; 
        end
        5'b01111: begin
          FlagsOut[2] <= signExtendedA[0];
        end

        // 32 bit operations
        5'b10000: begin end
        5'b10001: begin end
        5'b10010: begin end
        5'b10011: begin end
        5'b10100: begin
          FlagsOut[2] <= carryChecker[32];
          FlagsOut[0] <= (A[31] && B[31] && ~ALUOut[31]) || (~A[31] && ~B[31] && ALUOut[31]);
        end
        5'b10101: begin
          FlagsOut[3] <= ALUOut == 0;
          FlagsOut[2] <= carryChecker[32];
          FlagsOut[0] <= (A[31] && B[31] && ~ALUOut[31]) || (~A[31] && ~B[31] && ALUOut[31]);
        end
        5'b10110: begin
          FlagsOut[2] <= carryChecker[32];
          FlagsOut[0] <= (~A[31] && B[31] && ALUOut[31]) || (A[31] && ~B[31] && ~ALUOut[31]); 
        end

        5'b11011: begin
          FlagsOut[2] <= A[31];
        end
        5'b11100: begin
          FlagsOut[2] <= A[0];
        end
        5'b11101: begin
          FlagsOut[2] <= A[0];
        end
        5'b11110: begin
          FlagsOut[2] <= A[31]; 
        end
        5'b11111: begin
          FlagsOut[2] <= A[0];
        end
      endcase
      if (~(FunSel[3:0] == 4'b1101)) begin
      if (FunSel[4]) begin
        FlagsOut[1] <= ALUOut[31];
      end else begin
        FlagsOut[1] <= ALUOut[15];
      end
    end
    if (~(FunSel[3:0] == 4'b0101)) begin
      FlagsOut[3] <= ALUOut == 0;
    end
    end
  end
endmodule
