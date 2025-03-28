`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/28/2025 03:40:28 PM
// Design Name: 
// Module Name: InstructionRegister
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module InstructionRegister(
input wire LH,
input wire Write,
input wire Clock,
input wire[7:0] I,
output reg[15:0]IROut

    );
    always@ (posedge Clock) begin
    if(Write) begin
    case(LH)
    1'b0: IROut <= {IROut[15:8], I};
    1'b1: IROut <= {I, IROut[7:0]};
    endcase
    end
    end
endmodule
