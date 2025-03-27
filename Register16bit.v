`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/25/2025 05:34:57 PM
// Design Name: 
// Module Name: Register16bit
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


module Register16bit(I, E, FunSel,Q, Clock
    );
    input wire[15:0] I;
    input wire Clock; 
    input wire E;
    input wire[1:0] FunSel;
    output reg[15:0] Q;
    always@(posedge Clock)
    begin
    if(E) begin
    case(FunSel)
    2'b00 : Q <= Q - 1'b1;
    2'b01 : Q <= Q + 1'b1;
    2'b10 : Q <= I;
    2'b11 : Q <= 0;

    endcase
    end
    end 
endmodule
