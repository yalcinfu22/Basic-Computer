`timescale 1ns / 1ps
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
    2'b11 : Q <= 16'b0;

    endcase
    end
    end 
endmodule