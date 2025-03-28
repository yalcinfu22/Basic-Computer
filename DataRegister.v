`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/28/2025 03:56:57 PM
// Design Name: 
// Module Name: DataRegister
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


module DataRegister(
input wire Clock,
input wire[7:0] I,
output reg [31:0]DROut,
input wire E,
input wire [1:0]FunSel
    );
    always@ (posedge Clock) begin
    if(E) begin 
    case(FunSel)
    2'b00: DROut <= {{24{I[7]}}, I};
    2'b01: DROut <= {24'b0, I};
    2'b10: DROut <= {DROut[23:0], I};
    2'b11: DROut <= {I,DROut[31:8]};
    endcase
    end
    end
endmodule
