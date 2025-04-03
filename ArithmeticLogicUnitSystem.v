`timescale 1ns / 1ps
module mux4to1#(
    parameter WIDTH = 32
)(
input wire[WIDTH-1:0] A,
input wire[WIDTH-1:0] B,
input wire[WIDTH-1:0] C,
input wire[WIDTH-1:0] D,
input wire[1:0]S,
output reg[WIDTH-1:0] Out
);
always@(*) begin
case(S)
2'b00: Out = A;
2'b01: Out = B;
2'b10: Out = C;
2'b11: Out = D;
endcase
end
endmodule
module mux2to1#(
    parameter WIDTH = 32
)(
input wire[WIDTH-1:0] A,
input wire[WIDTH-1:0] B,
input wire S,
output reg[WIDTH-1:0] Out
);
always@(*) begin
case(S)
1'b0: Out = A;
1'b1: Out = B;
endcase
end
endmodule
module ArithmeticLogicUnitSystem(
input wire [2:0]RF_OutASel, 
input wire [2:0] RF_OutBSel, 
input wire [2:0] RF_FunSel,  
input wire [3:0] RF_RegSel,
input wire [3:0]RF_ScrSel,
input wire [4:0]ALU_FunSel,
input wire ALU_WF,           
input wire [1:0]ARF_OutCSel, 
input wire [1:0]ARF_OutDSel,
input wire [1:0]ARF_FunSel,
input wire [2:0]ARF_RegSel,   
input wire IR_LH,
input wire IR_Write,       
input wire Mem_WR,
input wire Mem_CS,
input wire [1:0]MuxASel,
input wire [1:0]MuxBSel,
input wire [1:0]MuxCSel,
input wire Clock,
input wire [1:0]DR_FunSel,
input wire DR_E,
input wire MuxDSel
);
wire[31:0] MuxBOut; //A wire from MuxB to MuxB_AddresRegisterFile
wire[7:0] MuxCOut;
wire [31:0] OutA;
wire [31:0] OutB;
wire [15:0]OutC;
wire [15:0]Address;
wire [7:0] MemOut;
wire [15:0] IROut;
wire [31:0] DROut;
wire [31:0]ALUOut;
wire [31:0] MuxAOut; //From Mux to RF
wire[31:0] MuxDOut; //from mux D to ALU input A
wire [3:0] FlagOUt;
AddressRegisterFile ARF(
    .I(MuxBOut), 
    .RegSel(ARF_RegSel), 
    .FunSel(ARF_FunSel), 
    .OutCSel(ARF_OutCSel),
    .OutDSel(ARF_OutDSel), 
    .Clock(Clock),
    .OutC(OutC),
    .OutD(Address)
);
Memory MEM(
    .Address(Address),
    .Data(MuxCOut),
     .WR(Mem_WR), //Read = 0, Write = 1
     .CS(Mem_CS), //Chip is enable when cs = 0
     .Clock(Clock),
     .MemOut(MemOut) // Output
);
 InstructionRegister IR(
.LH(IR_LH),
.Write(IR_Write),
.Clock(Clock),
.I(MemOut),
.IROut(IROut)
    );
DataRegister DR(
.Clock(Clock),
.I(MemOut),
.DROut(DROut),
.E(DR_E),
.FunSel(DR_FunSel)
);
mux4to1 #() muxA(
.A(ALUOut),
.B({{16{OutC[15]}}, OutC}),//?? should I extend the input or output
.C(DROut),
.D({{24{IROut[7]}}, IROut[7:0]}),
.S(MuxASel),
.Out(MuxAOut));
mux4to1 #() muxB(
.A(ALUOut),
.B({{16{OutC[15]}}, OutC}),//?? should I extend the input or output
.C(DROut),
.D({{24{IROut[7]}}, IROut[7:0]}),
.S(MuxBSel),
.Out(MuxBOut));
mux4to1 #(
.WIDTH(8) 
)muxC(
.A(ALUOut[7:0]),
.B(ALUOut[15:8]),//?? should I extend the input or output
.C(ALUOut[23:16]),
.D(ALUOut[31:24]),
.S(MuxCSel),
.Out(MuxCOut));
RegisterFile RF(.I(MuxAOut),
 .RegSel(RF_RegSel),
  .ScrSel(RF_ScrSel),
   .FunSel(RF_FunSel),
   .OutASel(RF_OutASel),
    .OutBSel(RF_OutBSel), 
    .Clock(Clock), 
    .OutA(OutA), 
    .OutB(OutB));
 mux2to1#()D(
 .A(OutA),
 .B({{16{OutC[15]}}, OutC}),
.S(MuxDSel),
.Out(MuxDOut)
 );
 ArithmeticLogicUnit ALU(
 .A(MuxDOut),
  .B(OutB),
 .FunSel(ALU_FunSel),
 .WF(ALU_WF),
 .Clock(Clock),
 .FlagsOut(FlagOUt), // Flags are being modified in FlagRegister.v
 .ALUOut(ALUOut)
);
endmodule