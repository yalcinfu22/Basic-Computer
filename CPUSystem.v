`timescale 1ns / 1ps
module CPUSystem (
input wire Clock,
input wire Reset,
output reg[11:0] T
);
// the registers we will need to control RF output and functions
reg [3:0]RF_RegSel;
reg [3:0]RF_ScrSel;
reg [2:0] RF_Fun_Sel;
reg [2:0] RF_Out_B_Sel;
reg [2:0] RF_Out_A_Sel;

// the registers we will need to controll mux
reg [1:0] Mux_A_Sel;
reg [1:0] Mux_B_Sel;
reg [1:0] Mux_C_Sel;
reg Mux_D_Sel;

// the register we will need to  to select function from Alu
reg[4:0] FunSel;
reg ALU_WF;
reg z;

//the registers we will need  to control DR
reg DR_E;
reg[1:0] DR_FunSel;

// register we need to control IR
reg IR_L_H;
reg IR_Write;

// register we need to controll ARF
reg[2:0] ARF_RegSel;
reg [1:0] ARF_FunSel;
reg [1:0] OutDSel;
reg [1:0] OutCSel;

//registers to control memory
reg Mem_WR;
reg Mem_CS;

 //reset T
 reg T_Reset;
 
 //required register for decoding parts
  reg[5:0] Opcode;
  reg[1:0] RegSel;
  reg[7:0] Address;
  reg[2:0] DestReg;
  reg[2:0] SrcReg1;
  reg[2:0] SrcReg2;
  task automatic reset_state;
begin
T = 0;
RF_RegSel = 4'b1111;
RF_ScrSel = 4'b1111;
ARF_RegSel = 3'b111;
ALUSys.RF.R1.Q = 32'h0;
ALUSys.RF.R2.Q = 32'h0;
ALUSys.RF.R3.Q = 32'h0;
ALUSys.RF.R4.Q = 32'h0;
ALUSys.RF.S1.Q = 32'h0;
ALUSys.RF.S2.Q = 32'h0;
ALUSys.RF.S3.Q = 32'h0;
ALUSys.RF.S4.Q = 32'h0;
ALUSys.ARF.PC.Q = 16'h0;
ALUSys.ARF.AR.Q = 16'h0;
ALUSys.ARF.SP.Q = 16'h00FF;
ALUSys.IR.IROut = 16'h0;
ALUSys.DR.DROut = 32'h0;
ALUSys.ALU.FlagsOut = 4'b0000;
Mem_CS = 1'b1;
end
endtask
task automatic disable_reg;
begin
ALU_WF = 1'b0;
RF_RegSel = 4'b0000;
RF_ScrSel = 4'b0000;
ALU_WF = 1'b0;
ARF_RegSel = 3'b000;
Mem_CS = 1'b1;
DR_E = 1'b0;
IR_Write = 1'b0;

end
endtask
// our ArithmeticLogicUnitSystem we are going to set the control value for it 
ArithmeticLogicUnitSystem ALUSys(.RF_OutASel(RF_Out_A_Sel), .RF_OutBSel(RF_Out_B_Sel), 
.RF_FunSel(RF_Fun_Sel),.RF_RegSel(RF_RegSel),.RF_ScrSel(RF_ScrSel),.ALU_FunSel(FunSel),
.ALU_WF(ALU_WF),.ARF_OutCSel(OutCSel), .ARF_OutDSel(OutDSel),.ARF_FunSel(ARF_FunSel),
.ARF_RegSel(ARF_RegSel),   
.IR_LH(IR_L_H),.IR_Write(IR_Write),.Mem_WR(Mem_WR),.Mem_CS(Mem_CS),.MuxASel(Mux_A_Sel),
.MuxBSel(Mux_B_Sel),.MuxCSel(Mux_C_Sel),
.Clock(Clock),
.DR_FunSel(DR_FunSel),.DR_E(DR_E),
.MuxDSel(Mux_D_Sel)
);
always @(negedge Reset) begin
reset_state();
end


// this will be used for counter
//t ->0000 >0001 > 10000
//T-> 1 -> 2 -> 3
always @(posedge Clock) begin
disable_reg();
if(T_Reset == 1) begin
 T <= 12'h001;
 T_Reset <= 1'b0; 
 end
 else begin 
 if (T == 0)
 T <= 12'h001;
 else 
  T <= T << 1;
end
end
always @(posedge T[0]) begin
// at T = 0 IR(0-7) <- M[PC], PC -> PC + 1
disable_reg();
ARF_RegSel = 3'b100; //enable pc
Mem_WR = 1'b0; // write 1 read 0 we need to read from memory(we need to read M[PC])
Mem_CS = 1'b0; // enable memory
IR_L_H = 1'b0;  // sleect LSB IR
IR_Write = 1'b1; // enable write in IR
OutDSel = 2'b00; // select pc to be output of D because output of D  coneected with memory Address
ARF_FunSel = 2'b01; // incremt pc by 1
end
always @(posedge T[1]) begin
// at T = 1 IR(8-15) <- M[PC], PC -> PC + 1
disable_reg();
ARF_RegSel = 3'b100; //enable pc
Mem_WR = 1'b0; // // write 1 read 0 we need to read from memory(we need to read M[PC])
Mem_CS = 1'b0; // enable memory
IR_L_H = 1'b1;  // sleect MSB IR
IR_Write = 1'b1; // enable write in IR
OutDSel = 2'b00; // select pc to be output of D coneected with memory Address
ARF_FunSel = 2'b01; // incremt pc by 1
end
always @(posedge T[2]) begin
//This step can be considered as decoding step
// we add Opcode to decoder and we set values of DestReg,SrcReg1, SrcReg2,RegSel,Address
disable_reg();
z = ALUSys.ALU.FlagsOut[3];
Opcode  = ALUSys.IR.IROut[15:10];
DestReg = ALUSys.IR.IROut[9:7];
SrcReg1 = ALUSys.IR.IROut[6:4]; 
SrcReg2 = ALUSys.IR.IROut[3:1]; 
RegSel = ALUSys.IR.IROut[9:8];
Address = ALUSys.IR.IROut[7:0];
case(Opcode)
6'h00: begin
//Instruction : PC <-  VALUE 
//T2: PC <- IR[0:7](Address value), T ? 0
ARF_FunSel = 2'b10; //load in ARF
ARF_RegSel = 3'b100; // pc enable
Mux_B_Sel = 2'b11; // select IRout(0-7) to be input for ARF
T_Reset = 1'b1; //Reset the sequence counter end of the construction
end
6'h01: begin
//Instruction : IF Z=0 THEN PC <-  VALUE 
// T2 : PC <-  IR[0:7](Address value) if Z = 0 , T ? 0
if (z == 1'b0) begin
ARF_FunSel = 2'b10; //load in ARF
ARF_RegSel = 3'b100; // pc enable
Mux_B_Sel = 2'b11; // select IRout(0-7) to be input for ARF
end
T_Reset = 1'b1; //Reset the sequence counter end of the construction
end
6'h02: begin
//Instruction : IF Z=1 THEN PC <- VALUE 
// T2 : PC ? IR[0:7](Address value) if Z = 0 , T ? 0
if (z == 1'b1) begin
ARF_FunSel = 2'b10; //load in ARF
ARF_RegSel = 3'b100; // pc enable
Mux_B_Sel = 2'b11; // select IRout(0-7) to be input for ARF
end
T_Reset = 1'b1; //Reset the sequence counter end of the construction
end
6'h03,6'h05: begin
//Instruction :SP ? SP + 1, Rx <-  M[SP] (16-bit) (03 opcode), (32-bit) (05 opcode)
//T2: sp <-  SP + 1
ARF_FunSel = 2'b01; //increment
ARF_RegSel = 3'b010; // sp enable
end

6'h04, 6'h06: begin
//Instruction : M[SP] <-  Rx, SP <-  SP - 1 (16-bit)
//T2: M[SP] <-  Rx[0:7], SP <-  SP -1
Mem_WR = 1'b1; // write 1 read 0 we need to wite on memory
Mem_CS = 1'b0; // enable memory
ALU_WF = 1;
case(RegSel) //chosse Rx to take output from it
2'b00: RF_Out_B_Sel = 3'b000;
2'b01: RF_Out_B_Sel = 3'b001;
2'b10: RF_Out_B_Sel = 3'b010;
2'b11: RF_Out_B_Sel = 3'b011;
endcase
FunSel = 5'b10001; // select 32 bit from b
Mux_C_Sel = 2'b00;//ALU[0:7]
ARF_RegSel = 3'b010; // sp enable
OutDSel = 2'b01; // select sp to be output of D which is the memory address input
ARF_FunSel = 2'b00; //decrment the enable ARF
end
6'h07: begin 
//Instruction: M[SP] <-  PC[7:0], SP <-  SP - 1, PC <-  VALUE (16 bit)
//T2: M[SP] <- pc[0:7], SP <- SP -1
Mem_WR = 1'b1; // write 1 read 0 we need to write
Mem_CS = 1'b0; // enable memory
FunSel = 5'b10000; // select 32 bit from A
ALU_WF = 1;
Mux_C_Sel = 2'b00;//ALU[0:7]
ARF_RegSel = 3'b010; // sp select
OutDSel = 2'b01; // select sp to be output of(memory address input)
OutCSel = 2'b00; // select pc so it will go to mux d
ARF_FunSel = 2'b00; //decrment
Mux_D_Sel = 1'b1; // ARF out(pc)
end
6'h08: begin
//SP <- SP + 1, PC <- M[SP] (16 bit)
//T2: SP <- SP + 1
ARF_FunSel = 2'b01; //increment
ARF_RegSel = 3'b010; // sp enable
end
6'h09,6'h0A,6'h18: begin
//T2 :DestReg ? SrcReg1
// if opcode = 18 T ? 0
ALU_WF = 1'b1;// enable flags updating
RF_Out_A_Sel = {1'b0,SrcReg1[1:0]}; // select between R1 and R4 s are not included
OutCSel = SrcReg1[1:0]; // select between PC AR SP
FunSel = 5'b10000; // select A output from ALU
Mux_A_Sel = 2'b00; // select ALU to go as input for RF
Mux_B_Sel = 2'b00; // select ALU to go as input for ARF
Mux_D_Sel = ~SrcReg1[2]; //select sender register if it is RF or ARF
if (DestReg[2] == 1) begin
RF_Fun_Sel = 3'b010;
case(DestReg[1:0]) // chosse the register to update its value 
2'b00: RF_RegSel = 4'b1000;
2'b01: RF_RegSel = 4'b0100;
2'b10: RF_RegSel = 4'b0010;
2'b11: RF_RegSel = 4'b0001;
endcase
end else begin
ARF_FunSel = 2'b10;
case(DestReg[1:0]) // chosse the register to update its value 
2'b00: ARF_RegSel = 3'b100;
2'b01: ARF_RegSel = 3'b010;
2'b10: ARF_RegSel = 3'b001;
2'b11: ARF_RegSel = 3'b001;
endcase
end
T_Reset = (Opcode == 6'h18);
end
6'h0B, 6'h0C, 6'h0D, 6'h0E, 6'h0F, 6'h10: begin
//T3:DSTREG ? LSL SREG1 opcode = 0B
//T3:DSTREG ? LSR SREG1 opcode = 0C
//T3:DSTREG ? ASR SREG1 opcode = 0D
//T3:DSTREG ? CSL SREG1 opcode = 0E
//T3:DSTREG ? CSR SREG1 opcode = 0F
//T3:DSTREG ? NOT SREG1 opcode = 10
//T3: T ? 0
ALU_WF = 1'b1;// enable flags updating
RF_Out_A_Sel = {1'b0,SrcReg1[1:0]}; // R1- R4
OutCSel = SrcReg1[1:0]; // AC or PC or SP
if(Opcode == 6'h0B)FunSel = 5'b11011;// select LSL output from ALU
else if(Opcode == 6'h0C) FunSel = 5'b11100;// select LSR output from ALU
else if(Opcode == 6'h0D) FunSel = 5'b11101;// select ASR output from ALU
else if(Opcode == 6'h0E) FunSel = 5'b11110;// select CSL output from ALU
else if(Opcode == 6'h0F) FunSel = 5'b11111;// select CSR output from ALU
else if(Opcode == 6'h10) FunSel = 5'b10010;// select NOT output from ALU
Mux_A_Sel = 2'b00; // select ALU to go as input for RF
Mux_B_Sel = 2'b00; // select ALU to go as input for ARF
Mux_D_Sel = ~SrcReg1[2]; //select sender register if it is RF or ARF
if (DestReg[2] == 1) begin
RF_Fun_Sel = 3'b010;
case(DestReg[1:0])
2'b00: RF_RegSel = 4'b1000;
2'b01: RF_RegSel = 4'b0100;
2'b10: RF_RegSel = 4'b0010;
2'b11: RF_RegSel = 4'b0001;
endcase
end else begin
ARF_FunSel = 2'b10;
case(DestReg[1:0]) 
2'b00: ARF_RegSel = 3'b100;
2'b01: ARF_RegSel = 3'b010;
2'b10: ARF_RegSel = 3'b001;
2'b11: ARF_RegSel = 3'b001;
endcase
end
T_Reset = 1'b1;
end
6'h11, 6'h12, 6'h13, 6'h14, 6'h15, 6'h16,6'h17: begin
//T3 :S1 <- SERG2
RF_ScrSel = 4'b1000;
FunSel = 5'b10000;
ALU_WF      = 1'b1;
RF_Fun_Sel = 3'b010;
if (SrcReg2[2]) begin                // source in RF
    RF_Out_A_Sel = {1'b0, SrcReg2[1:0]};
    Mux_D_Sel    = 1'b0;             // D/C not used
    Mux_A_Sel    = 2'b00;            // ALU-A = RF_OutA
end else begin                       // source in ARF
    OutCSel      =  SrcReg2[1:0];    // 00=PC, 01=AR, 1x=SP
    Mux_D_Sel    = 1'b1;             // put ARF on D/C bus
    Mux_A_Sel    = 2'b00;            // ALU-A = D/C bus  (use your ALU-A-mux code)
end
end
6'h19,6'h1A : begin
//Instruction : Rx[7:0] ? IMMEDIATE (8-bit) (opcode=19)
//Instruction : Rx[31-8] ? Rx[23-0] (8-bit Left Shift) Rx[7-0] ? IMMEDIATE (8-bit)  (opcode=1A)
// T2: Rx ? IR[7:0] if opcode=19
// T2 Rx[7:0] ? IR[7:0], Rx[31:8] ?Rx[23-0]
Mux_A_Sel = 2'b11;
case(RegSel) // chosse the register to update its value 
2'b00: RF_RegSel = 4'b1000;
2'b01: RF_RegSel = 4'b0100;
2'b10: RF_RegSel = 4'b0010;
2'b11: RF_RegSel = 4'b0001;
endcase
if(Opcode == 6'h19)
RF_Fun_Sel =3'b010;
else 
RF_Fun_Sel =3'b110;
end
6'h1B,6'h1C: begin
//Instruction: DSTREG ? M[AR] (16-bit) opcode = 1b
//Instruction: DSTREG ? M[AR] (32-bit) opcode = 1c
//DSERG <- M[AR], (16(1B) or 32(1C))
// T2:DR[0:7] <- M[AR], AR <- AR + 1
Mem_WR = 1'b0; // write 1 read 0 we need to read from memory
Mem_CS = 1'b0; // enable memory
DR_E = 1'b1; //enable DR so the output of the memory can be written in DR
DR_FunSel = 2'b01; //select dr load(0-7) + clear(8-31) so we will have only DR[0:7]<-M[sp]
ARF_FunSel = 2'b01;  //increment the enabled function(sp)
ARF_RegSel = 3'b001; // enable AR 
OutDSel = 2'b11; // select AR to be output of D so the memory take address from AR
end
6'h1E,6'h1F: begin
// Instruction Rx <- M[ADDRESS] (16-bit)(32-bit)
//T2: AR <-IR[7:0] 
ARF_FunSel = 2'b10;
ARF_RegSel = 3'b001;
Mux_B_Sel = 2'b11;
end
6'h1D: begin
//Instruction : M[AR] ? SREG1
//T2: M[AR] ? SREG1[31:24], AR ? AR + 1
Mux_C_Sel = 2'b11;
ALU_WF = 1'b1;
Mem_WR = 1'b1; // write 1 read 0 we need to write on memory
Mem_CS = 1'b0; // enable memory
ARF_FunSel = 2'b01;  //increment the enabled function(AR)
ARF_RegSel = 3'b001; // enable AR 
OutDSel = 2'b11; // select AR to be output of D so the memory take address from AR
RF_Out_A_Sel = {1'b0,SrcReg1[1:0]};
OutCSel = SrcReg1[1:0];
Mux_D_Sel = ~SrcReg1[2];
FunSel = 5'b10000;
end
6'h20 : begin 
// T2: AR <- IR[7:0],
ARF_RegSel  = 3'b001;    // select ARF.AR
ARF_FunSel  = 2'b10;     // "load" function
Mux_B_Sel   = 2'b11;     // Input is 32 bit we use 8 bits only remaining 24 bits may cause problems 
end
6'h21,6'h22 : begin 
// T2:DR <- M[AR], AR <- AR + 1
 ARF_RegSel = 3'b001; // select AR
 OutDSel = 2'b11; // Select AR for MemRef
 Mem_WR = 1'b0; // Read
 Mem_CS = 1'b0; 
 DR_E = 1'b1; // DR enable
 DR_FunSel = 2'b01; // push to DR[7:0] and clear rest
 ARF_FunSel = 2'b01; //increment AR
end
 6'h23 : begin
  //T2:DSTREG ? DR 
   Mux_A_Sel = 2'b10; // select DR to go as input for RF
   Mux_B_Sel = 2'b10; // select DR to go as input for ARF
   if (DestReg[2] == 1) begin
     RF_Fun_Sel = 3'b010; // select Load
     case(DestReg[1:0])
     2'b00: RF_RegSel = 4'b1000;
     2'b01: RF_RegSel = 4'b0100;
     2'b10: RF_RegSel = 4'b0010;
     2'b11: RF_RegSel = 4'b0001;
     endcase
     end else begin
     ARF_FunSel = 2'b10; // select Load
     case(DestReg[1:0]) 
     2'b00: ARF_RegSel = 3'b100;
     2'b01: ARF_RegSel = 3'b010;
     2'b10: ARF_RegSel = 3'b001;
     2'b11: ARF_RegSel = 3'b001;
     endcase
  end
  T_Reset = 1'b1;
end
6'h24 : begin
//Instruction : M[AR+OFFSET] ? Rx (AR is 16-bit register)(OFFSET defined in ADDRESS bits)
// S1 <- IR[7:0]
Mux_A_Sel = 2'b11;
RF_ScrSel = 4'b1000;
RF_Fun_Sel =3'b010;
end
endcase
end

always @(posedge T[3]) begin
disable_reg();
case(Opcode)
6'h03,6'h05: begin
//T3: DR[0:7] <- M[SP], SP <-  SP + 1
Mem_WR = 1'b0; // write 1 read 0 we need to read from memory
Mem_CS = 1'b0; // enable memory
DR_E = 1'b1; //enable DR so the output of the memory can be written in DR
DR_FunSel = 2'b01; //select dr load(0-7) + clear(8-31) so we will have only DR[0:7]<-M[sp]
ARF_FunSel = 2'b01;  //increment the enabled function(sp)
ARF_RegSel = 3'b010; // enable sp 
OutDSel = 2'b01; // select sp to be output of D so the memory take address from sp
end

6'h04,6'h06: begin
//T3:M[sp] <-  Rx[15:8], sp <-  sp -1
//If opcode == 04 T ? 0
Mem_WR = 1'b1; // write 1 read 0 we need to write on memory
Mem_CS = 1'b0; // enable memory
case(RegSel) //chosse Rx to take output from it
2'b00: RF_Out_B_Sel = 3'b000;
2'b01: RF_Out_B_Sel = 3'b001;
2'b10: RF_Out_B_Sel = 3'b010;
2'b11: RF_Out_B_Sel = 3'b011;
endcase
FunSel = 5'b10001; // select 32 bit from b
Mux_C_Sel = 2'b01;//Rx[8:15]
ARF_RegSel = 3'b010; // sp select
OutDSel = 2'b01; // select sp to be output of 
ARF_FunSel = 2'b00; //decrment
ALU_WF = 1'b1;
if(Opcode == 6'h04) // It will need only to load 16 bit in 04 instruction
T_Reset = 1'b1;
end
6'h07: begin 
//T3:M[sp] <- pc[15:8], sp <- sp -1
Mem_WR = 1'b1; // write 1 read 0 we need to write on memory
Mem_CS = 1'b0; // enable memory
FunSel = 5'b10000; // select 16 bit from A
ALU_WF = 1'b1;
Mux_C_Sel = 2'b01;//ALU[0:7]
ARF_RegSel = 3'b010; // sp select
OutDSel = 2'b01; // select sp to be output of
OutCSel = 2'b00; // select pc so it will go to mux d
ARF_FunSel = 2'b00; //decrment
Mux_D_Sel = 1;
end
6'h08: begin
//T3 : DR[0:7] <- M[SP], SP <- SP + 1
Mem_WR = 1'b0; // write 1 read 0 we need to read from memory
Mem_CS = 1'b0; // enable memory
OutDSel = 2'b01; // select sp to be output of D(Memory address input)
ARF_FunSel = 2'b01; //increment
ARF_RegSel = 3'b010; // sp enable
DR_E = 1'b1; //enable DR
DR_FunSel = 2'b01; //select dr load(0-7) + clear(8-31)
end
6'h09: begin
//T3 : DestReg <- DestReg+ 1
if (DestReg[2] == 1) begin
RF_Fun_Sel = 3'b001;
case(DestReg[1:0]) // chosse the register to update its value 
2'b00: RF_RegSel = 4'b1000;
2'b01: RF_RegSel = 4'b0100;
2'b10: RF_RegSel = 4'b0010;
2'b11: RF_RegSel = 4'b0001;
endcase
end else begin
ARF_FunSel = 2'b01;
case(DestReg[1:0]) // chosse the register to update its value 
2'b00: ARF_RegSel = 3'b100;
2'b01: ARF_RegSel = 3'b010;
2'b10: ARF_RegSel = 3'b001;
2'b11: ARF_RegSel = 3'b001;
endcase
end

end
6'h0A: begin
//T3:DestReg <- DestReg - 1
if (DestReg[2] == 1) begin
RF_Fun_Sel = 3'b000;
case(DestReg[1:0]) // chosse the register to update its value 
2'b00: RF_RegSel = 4'b1000;
2'b01: RF_RegSel = 4'b0100;
2'b10: RF_RegSel = 4'b0010;
2'b11: RF_RegSel = 4'b0001;
endcase
end else begin
ARF_FunSel = 2'b00;
case(DestReg[1:0]) // chosse the register to update its value 
2'b00: ARF_RegSel = 3'b100;
2'b01: ARF_RegSel = 3'b010;
2'b10: ARF_RegSel = 3'b001;
2'b11: ARF_RegSel = 3'b001;
endcase
end
end
6'h11, 6'h12, 6'h13, 6'h14, 6'h15, 6'h16,6'h17: begin
//DSEG <- (SERG1 ,SERG2) operation
ALU_WF = 1'b1; // enable flags
RF_Out_B_Sel = 3'b100; // s1
RF_Out_A_Sel = {1'b0,SrcReg1[1:0]};
OutCSel = SrcReg1[1:0];
if(Opcode == 6'h11)FunSel = 5'b10111;// select And output from ALU
else if(Opcode == 6'h12) FunSel = 5'b11000;// select OR output from ALU
else if(Opcode == 6'h13) FunSel = 5'b11001;// select XOR output from ALU
else if(Opcode == 6'h14) FunSel = 5'b11010;// select NAND output from ALU
else if(Opcode == 6'h15) FunSel = 5'b10100;// select ADD output from ALU
else if(Opcode == 6'h16) FunSel = 5'b10101;// select ADD + C output from ALU
else if(Opcode == 6'h17) FunSel = 5'b10110;// select SuB output from ALU
Mux_A_Sel = 2'b00; // select ALU to go as input for RF
Mux_B_Sel = 2'b00; // select ALU to go as input for ARF
Mux_D_Sel = ~SrcReg1[2]; //select sender register if it is RF or ARF
ARF_FunSel = 2'b10;
RF_Fun_Sel = 3'b010;
if (DestReg[2] == 1) begin
case(DestReg[1:0])
2'b00: RF_RegSel = 4'b1000;
2'b01: RF_RegSel = 4'b0100;
2'b10: RF_RegSel = 4'b0010;
2'b11: RF_RegSel = 4'b0001;
endcase
end else begin
case(DestReg[1:0]) 
2'b00: ARF_RegSel = 3'b100;
2'b01: ARF_RegSel = 3'b010;
2'b10: ARF_RegSel = 3'b001;
2'b11: ARF_RegSel = 3'b001;
endcase
end
T_Reset = 1'b1;
end

6'h1B,6'h1C: begin
//T3:DR[0:7] <- M[AR], DR[15:8] <- DR[0:7],  if opcode 6'h1C AR <- AR + 1 
Mem_WR = 1'b0; // write 1 read 0 we need to read from memory
Mem_CS = 1'b0; // enable memory
DR_E = 1'b1; //enable DR so the output of the memory can be written in DR
DR_FunSel = 2'b10; //select dr load(0-7) + shift(23-0) to (21-8) so we will have only DR[0:7]<-M[sp]
if(Opcode == 6'h1C) begin
ARF_FunSel = 2'b01;  //increment the enabled function(AR)
ARF_RegSel = 3'b001; // enable AR 
end
OutDSel = 2'b11; // select AR to be output of D so the memory take address from AR
end
  6'h19, 6'h1A: begin
    Mux_D_Sel = 0;
    FunSel = 5'b10000;
   ALU_WF = 1;
   case (RegSel)
    2'b00: RF_Out_A_Sel = 3'b000;
    2'b01: RF_Out_A_Sel = 3'b001;
     2'b10: RF_Out_A_Sel = 3'b010;
     2'b11: RF_Out_A_Sel = 3'b011;  
        endcase
        T_Reset = 1'b1;
      end
6'h1D: begin
//T3: M[AR] ? SREG1[23:16], AR ? AR + 1
Mux_C_Sel = 2'b10;
Mem_WR = 1'b1; // write 1 read 0 we need to write on memory
Mem_CS = 1'b0; // enable memory
ARF_FunSel = 2'b01;  //increment the enabled function(AR)
ARF_RegSel = 3'b001; // enable AR 
OutDSel = 2'b11; // select AR to be output of D so the memory take address from AR
RF_Out_A_Sel = {1'b0,SrcReg1[1:0]};
OutCSel = SrcReg1[1:0];
Mux_D_Sel = ~SrcReg1[2];
FunSel = 5'b10000;
ALU_WF = 1'b1;
end
6'h1E,6'h1F: begin
// T3:In this step DR[0:7] <- M[AR], AR <- AR + 1
Mem_WR = 1'b0; // write 1 read 0 we need to read from memory
Mem_CS = 1'b0; // enable memory
DR_E = 1'b1; //enable DR so the output of the memory can be written in DR
DR_FunSel = 2'b01; //select dr load(0-7) + clear(8-31) so we will have only DR[0:7]<-M[sp]
ARF_FunSel = 2'b01;  //increment the enabled function(sp)
ARF_RegSel = 3'b001; // enable AR 
OutDSel = 2'b11; // select AR to be output of D so the memory take address from AR
end
6'h20 : begin 
//T3: M[AR] <- Rx[31:24], AR <- AR + 1
 OutDSel = 2'b10; // use AR
 Mem_WR = 1'b1; // WRITE enabled
 Mem_CS = 1'b0; // enable memory
 case(RegSel) // choose the register to use
 2'b00: begin // selects which register to give ALU
   RF_Out_B_Sel = 3'b000;
 end
 2'b01: begin
   RF_Out_B_Sel = 3'b001;
 end
 2'b10: begin 
   RF_Out_B_Sel = 3'b010;
 end
 2'b11: begin 
   RF_Out_B_Sel = 3'b011;
 end
 endcase
 FunSel = 5'b10001; // decided to transfer whole 32 bits
 ALU_WF = 1'b1;
 Mux_C_Sel = 2'b11; // ALU[31:24]
 
 // STA update did not select before incrementing
 ARF_RegSel = 3'b001; // select AR
 ARF_FunSel = 2'b01; // increment AR
 end
 6'h21,6'h22 : begin 
 //T3: DR <- M[AR], AR+1 <- AR+1 + 1
 //if opcode = 21 T <-0
  ARF_RegSel = 3'b001; // select AR
  OutDSel = 2'b11; // Select AR for MemRef
  Mem_WR = 1'b0; // Read
  Mem_CS = 1'b0; // enable memory

  DR_E = 1'b1; // DR enable
  if(Opcode == 6'h22) begin
  DR_FunSel = 2'b10; // 8-bit left shift then push DR[7:0] <- M[AR+1]
  ARF_FunSel = 2'b01; //increment AR
  end
  if(Opcode == 6'h21)
  T_Reset = 1'b1;
 end
 6'h24: begin
//AR <- AR + offeset operation
ALU_WF = 1'b1; // enable flags
RF_Out_B_Sel = 3'b100; // s1
OutCSel = 2'b11; //sellect AR
FunSel = 5'b10100; //AD
ALU_WF = 1'b1;
Mux_B_Sel = 2'b00; // select ALU to go as input for ARF
Mux_D_Sel = 1'b1; //select sender register if it is RF or ARF
ARF_FunSel = 2'b10; // load
ARF_RegSel = 3'b001; // AR enable
end
endcase
end
always @(posedge T[4]) begin
disable_reg();
case(Opcode)
6'h03,6'h05: begin
// T4 : DR[15:8]<- DR[0:7], DR[0:7]<- M[sp]
// T4 : if opcode == 5 sp ? sp + 1
Mem_WR = 1'b0; // write 1 read 0 we need to read from memoru
Mem_CS = 1'b0; // enable memory
DR_E = 1'b1; //enable DR
DR_FunSel = 2'b10; //select dr load(0-7) + shift left(8bits)
if(Opcode == 6'h05) begin
ARF_FunSel = 2'b01; //increment
ARF_RegSel = 3'b010; // sp select
end
OutDSel = 2'b01; // select sp to be output of D
end


6'h06: begin
//T4: M[sp] <-  Rx[23:16], sp <-  sp -1
case(RegSel) //chosse Rx to take output from it
2'b00: RF_Out_B_Sel = 3'b000;
2'b01: RF_Out_B_Sel = 3'b001;
2'b10: RF_Out_B_Sel = 3'b010;
2'b11: RF_Out_B_Sel = 3'b011;
endcase
Mem_WR = 1'b1; // write 1 read 0 we need to write on memory
Mem_CS = 1'b0; // enable memory
FunSel = 5'b10001; // select 32 bit from b
ALU_WF = 1'b1;
Mux_C_Sel = 2'b10;//Rx[23:16]
ARF_RegSel = 3'b010; // sp select
OutDSel = 2'b01; // select sp to be output of 
ARF_FunSel = 2'b00; //decrment ARF enabled reg
end
6'h07: begin 
//T4:PC <- value
ARF_FunSel = 2'b10; //load
ARF_RegSel = 3'b100; // pc enable
Mux_B_Sel = 2'b11; // IR[0:7] value
T_Reset = 1'b1; //reset sequence counter
end
6'h08: begin
//T4 : DR[15:8]?DR[7:0] DR[0:7] ?M[sp]
Mem_WR = 1'b0; // write 1 read 0 we need to read from memoru
Mem_CS = 1'b0; // enable memory
OutDSel = 2'b01; // select sp to be output of 
DR_E = 1'b1;
DR_FunSel = 2'b10; //select dr load + shift left
end

6'h1B:begin
//T4: DSTREG <-  DR[15:0]
Mux_A_Sel = 2'b10;
Mux_B_Sel = 2'b10;
if (DestReg[2] == 1) begin
RF_Fun_Sel = 3'b010;
case(DestReg[1:0])
2'b00: RF_RegSel = 4'b1000;
2'b01: RF_RegSel = 4'b0100;
2'b10: RF_RegSel = 4'b0010;
2'b11: RF_RegSel = 4'b0001;
endcase
end else begin
ARF_FunSel = 2'b10;
case(DestReg[1:0]) 
2'b00: ARF_RegSel = 3'b100;
2'b01: ARF_RegSel = 3'b010;
2'b10: ARF_RegSel = 3'b001;
2'b11: ARF_RegSel = 3'b001;
endcase
end
T_Reset = 1'b1; //reset sequence counter
end
6'h1C: begin
// T4: DR[0:7] <- M[AR], DR[31:8] <- Dr[23:0],AR <- AR + 1
Mem_WR = 1'b0; // write 1 read 0 we need to read from memory
Mem_CS = 1'b0; // enable memory
DR_E = 1'b1; //enable DR so the output of the memory can be written in DR
DR_FunSel = 2'b10; //select dr load(0-7) + shift(23-0) to (21-8) so we will have only DR[0:7]<-M[sp]
ARF_FunSel = 2'b01;  //increment the enabled function(AR)
ARF_RegSel = 3'b001; // enable AR 
OutDSel = 2'b11; // select AR to be output of D so the memory take address from AR
end

6'h1D: begin
//T4: M[AR] ? SREG1[16:8], AR ? AR + 1
Mux_C_Sel = 2'b01;
Mem_WR = 1'b1; // write 1 read 0 we need to write on memory
Mem_CS = 1'b0; // enable memory
ARF_FunSel = 2'b01;  //increment the enabled function(AR)
ARF_RegSel = 3'b001; // enable AR 
OutDSel = 2'b11; // select AR to be output of D so the memory take address from AR
RF_Out_A_Sel = {1'b0,SrcReg1[1:0]};
OutCSel = SrcReg1[1:0];
Mux_D_Sel = ~SrcReg1[2];
FunSel = 5'b10000;
ALU_WF = 1'b1;
end
6'h1E,6'h1F: begin
// T4: DR[0:7] <- M[AR], DR[15:8] <- DR[0:7],
//T4 AR <- AR+ 1 if opcode == 1f
Mem_WR = 1'b0; // write 1 read 0 we need to read from memory
Mem_CS = 1'b0; // enable memory
DR_E = 1'b1; //enable DR so the output of the memory can be written in DR
DR_FunSel = 2'b10; //select dr load(0-7) + shift(23-0) to (21-8) so we will have only DR[0:7]<-M[sp]
if(Opcode == 6'h1F) begin
ARF_FunSel = 2'b01;  //increment the enabled function(AR)
ARF_RegSel = 3'b001; // enable AR 
end
end
6'h20 : begin 
// T4:M[AR+1] <- Rx[23:16], AR+2 <- AR+2 + 1
 OutDSel = 2'b10; // use AR
 Mem_WR = 1'b1; // WRITE enabled
 Mem_CS = 1'b0; // enable memory
 case(RegSel) // choose the register to use
 2'b00: begin // selects which register to give ALU
   RF_Out_B_Sel = 3'b000;
 end
 2'b01: begin
   RF_Out_B_Sel = 3'b001;
 end
 2'b10: begin 
   RF_Out_B_Sel = 3'b010;
 end
 2'b11: begin 
   RF_Out_B_Sel = 3'b011;
 end
 
 endcase
 FunSel = 5'b10001; // decided to transfer whole 32 bits
 ALU_WF = 1'b1;
 Mux_C_Sel = 2'b10; // ALU[24:16]
 // STA update did not select before incrementing
 ARF_RegSel = 3'b001; // select AR
 ARF_FunSel = 2'b01; // increment AR
end
6'h22 : begin 
//T4: DR <- M[AR], AR+2 <- AR+2 + 1
   ARF_RegSel = 3'b001; // select AR
   OutDSel = 2'b11; // Select AR for MemRef
   Mem_WR = 1'b0; // Read
   Mem_CS = 1'b0; 
   DR_E = 1'b1; // DR enable
   DR_FunSel = 2'b10; // 8-bit left shift then push DR[7:0] <- M[AR+2]
   ARF_FunSel = 2'b01; //increment AR
end
6'h09,6'h0A: begin
//T4:DestReg ? DestReg (the goal is update alu flags), T ? 0
ALU_WF = 1'b1;
RF_Out_A_Sel = {1'b0,DestReg[1:0]};
OutCSel = DestReg[1:0];
FunSel = 5'b10000; // select A output from ALU
Mux_A_Sel = 2'b00; // select ALU to go as input for RF
Mux_B_Sel = 2'b00; // select ALU to go as input for RF
Mux_D_Sel = ~DestReg[2]; //select sender register if it is RF or ARF
if (DestReg[2] == 1) begin
RF_Fun_Sel = 3'b010;
case(DestReg[1:0]) // chosse the register to update its value 
2'b00: RF_RegSel = 4'b1000;
2'b01: RF_RegSel = 4'b0100;
2'b10: RF_RegSel = 4'b0010;
2'b11: RF_RegSel = 4'b0001;
endcase
end else begin
ARF_FunSel = 2'b10;
case(DestReg[1:0]) // chosse the register to update its value 
2'b00: ARF_RegSel = 3'b100;
2'b01: ARF_RegSel = 3'b010;
2'b10: ARF_RegSel = 3'b001;
2'b11: ARF_RegSel = 3'b001;
endcase
end
T_Reset = 1'b1;
end
6'h24 : begin 
//T4: M[AR] <- Rx[31:24], AR <- AR + 1
 OutDSel = 2'b10; // use AR
 Mem_WR = 1'b1; // WRITE enabled
 Mem_CS = 1'b0; // enable memory
 ALU_WF = 1'b1;
 case(RegSel) // choose the register to use
 2'b00: begin // selects which register to give ALU
   RF_Out_B_Sel = 3'b000;
 end
 2'b01: begin
   RF_Out_B_Sel = 3'b001;
 end
 2'b10: begin 
   RF_Out_B_Sel = 3'b010;
 end
 2'b11: begin 
   RF_Out_B_Sel = 3'b011;
 end
 endcase
 FunSel = 5'b10001; // decided to transfer whole 32 bits
 Mux_C_Sel = 2'b11; // ALU[31:24]
 ALU_WF = 1'b1;
 // STA update did not select before incrementing
 ARF_RegSel = 3'b001; // select AR
 ARF_FunSel = 2'b01; // increment AR
 end
endcase
end
always @(posedge T[5]) begin
disable_reg();
case(Opcode)
6'h03: begin
//T5 : Rx[15:0] <- DR
Mux_A_Sel = 2'b10; // make DR as input of RF
RF_Fun_Sel = 3'b010; // load
case(RegSel) // chosse the register to update its value 
2'b00: RF_RegSel = 4'b1000;
2'b01: RF_RegSel = 4'b0100;
2'b10: RF_RegSel = 4'b0010;
2'b11: RF_RegSel = 4'b0001;
endcase
T_Reset = 1'b1; // instruction done reset counter
end
6'h05: begin
//T5: DR[23:7] <-  DR[15:0], DR[7:0] <-  M[SP], SP <-  SP + 1 
Mem_WR = 1'b0; // write 1 read 0 we need to read from memory
Mem_CS = 1'b0; // enable memory
DR_E = 1'b1; //enable DR
DR_FunSel = 2'b10; //select dr load(0-7) + shift left(8bits)
ARF_FunSel = 2'b01; // increment enabled ARF
ARF_RegSel = 3'b010; // sp enable
OutDSel = 2'b01; // select sp to be output of D(Memory Address Input)
end

6'h06: begin
//T5: M[sp] <-  Rx[31:24], SP <-  SP -1, T <-  0
Mem_WR = 1'b1; // write 1 read 0 we need to write on memory
Mem_CS = 1'b0; // enable memory
case(RegSel) //chosse Rx to take output from it
2'b00: RF_Out_B_Sel = 3'b000;
2'b01: RF_Out_B_Sel = 3'b001;
2'b10: RF_Out_B_Sel = 3'b010;
2'b11: RF_Out_B_Sel = 3'b011;
endcase
FunSel = 5'b10001; // select 32 bit from b
ALU_WF = 1'b1;
Mux_C_Sel = 2'b11;//(31-24)
ARF_RegSel = 3'b010; // sp select
OutDSel = 2'b01; // select sp to be output of 
ARF_FunSel = 2'b00; //decrment
T_Reset = 1'b1; //reset instruction finished
end
6'h08: begin
// PC <- DR[15:8], T <- 0
ARF_RegSel = 3'b100; // pc select
ARF_FunSel = 2'b10; //load
Mux_B_Sel = 2'b10; // DR <- pc
T_Reset = 1'b1; //reset sequence counter
end
6'h1C: begin
// T5: DR[0:7] <- M[AR], DR[31:8] <- DR[23:0]
Mem_WR = 1'b0; // write 1 read 0 we need to read from memory
Mem_CS = 1'b0; // enable memory
DR_E = 1'b1; //enable DR so the output of the memory can be written in DR
DR_FunSel = 2'b10; //select dr load(0-7) + shift(23-0) to (21-8) so we will have only DR[0:7]<-M[sp]
OutDSel = 2'b11; // select AR to be output of D so the memory take address from AR
end
6'h1D: begin
//T2: M[AR] ? SREG1[7:0], T ? 0
Mux_C_Sel = 2'b00;
Mem_WR = 1'b1; // write 1 read 0 we need to write on memory
Mem_CS = 1'b0; // enable memory
OutDSel = 2'b11; // select AR to be output of D so the memory take address from AR
RF_Out_A_Sel = {1'b0,SrcReg1[1:0]};
OutCSel = SrcReg1[1:0];
Mux_D_Sel = ~SrcReg1[2];
FunSel = 5'b10000;
ALU_WF = 1'b1;
T_Reset = 1'b1; //reset sequence counter
end
6'h1E: begin
//T5: RX <-  DR[15:8], T <- 0
Mux_A_Sel = 2'b10; //select DR to RF
RF_Fun_Sel = 3'b010;
case(RegSel) // chosse the register to update its value 
2'b00: RF_RegSel = 4'b1000;
2'b01: RF_RegSel = 4'b0100;
2'b10: RF_RegSel = 4'b0010;
2'b11: RF_RegSel = 4'b0001;
endcase
T_Reset = 1'b1; //reset sequence counter
end
6'h20 : begin 
// T5:M[AR+2] <- Rx[15:8], AR+3 <- AR+2 + 1
 disable_reg();
 OutDSel = 2'b10; // use AR
 Mem_WR = 1'b1; // WRITE enabled
 Mem_CS = 1'b0; // enable memory
 
 case(RegSel) // choose the register to use
 2'b00: begin // selects which register to give ALU
   RF_Out_B_Sel = 3'b000;
 end
 2'b01: begin
   RF_Out_B_Sel = 3'b001;
 end
 2'b10: begin 
   RF_Out_B_Sel = 3'b010;
 end
 2'b11: begin 
   RF_Out_B_Sel = 3'b011;
 end
 endcase
 FunSel = 5'b10001; // decided to transfer whole 32 bits
 ALU_WF = 1'b1;
 Mux_C_Sel = 2'b01; // ALU[15:8]
 // STA update did not select before incrementing
 ARF_RegSel = 3'b001; // select AR
 ARF_FunSel = 2'b01; // increment AR
end
6'h1F: begin
// T5: DR[0:7] <- M[AR],shift left, AR <- AR + 1
Mem_WR = 1'b0; // write 1 read 0 we need to read from memory
Mem_CS = 1'b0; // enable memory
DR_E = 1'b1; //enable DR so the output of the memory can be written in DR
DR_FunSel = 2'b10; //select dr load(0-7) + shift(23-0) to (21-8) so we will have only DR[0:7]<-M[sp]
ARF_FunSel = 2'b01;  //increment the enabled function(AR)
ARF_RegSel = 3'b001; // enable AR 
OutDSel = 2'b11; // select AR to be output of D so the memory take address from AR
end
6'h22 : begin //T5: DR <- M[AR],
   OutDSel = 2'b11; // Select AR for MemRef
   Mem_WR = 1'b0; // Read
   Mem_CS = 1'b0; 
   DR_E = 1'b1; // DR enable
   DR_FunSel = 2'b10; // 8-bit left shift then push DR[7:0] <- M[AR+3]
   T_Reset = 1'b1; //reset 
end
6'h24 : begin 
// T5:M[AR+1] <- Rx[23:16], AR+2 <- AR+2 + 1
 OutDSel = 2'b10; // use AR
 Mem_WR = 1'b1; // WRITE enabled
 Mem_CS = 1'b0; // enable memory
 case(RegSel) // choose the register to use
 2'b00: begin // selects which register to give ALU
   RF_Out_B_Sel = 3'b000;
 end
 2'b01: begin
   RF_Out_B_Sel = 3'b001;
 end
 2'b10: begin 
   RF_Out_B_Sel = 3'b010;
 end
 2'b11: begin 
   RF_Out_B_Sel = 3'b011;
 end
 
 endcase
 FunSel = 5'b10001; // decided to transfer whole 32 bits
 Mux_C_Sel = 2'b10; // ALU[24:16]
 // STA update did not select before incrementing
 ARF_RegSel = 3'b001; // select AR
 ARF_FunSel = 2'b01; // increment AR
end
endcase
end
always @(posedge T[6]) begin
disable_reg();
case(Opcode)
6'h05: begin
//T5 :DR[31:7] <- DR[23:0], DR[7:0] <- M[sp]
Mem_WR = 1'b0; // write 1 read 0 we need to read from memoru
Mem_CS = 1'b0; // enable memory
DR_E = 1'b1; //enable DR
DR_FunSel = 2'b10; //select dr load(0-7) + shift left(8bits)
OutDSel = 2'b01; // select sp to be output of D
end

6'h1C:begin
//T6: DSTERG <- DR, T <- 0
Mux_A_Sel = 2'b10;
Mux_B_Sel = 2'b10;
if (DestReg[2] == 1) begin
RF_Fun_Sel = 3'b010;
case(DestReg[1:0])
2'b00: RF_RegSel = 4'b1000;
2'b01: RF_RegSel = 4'b0100;
2'b10: RF_RegSel = 4'b0010;
2'b11: RF_RegSel = 4'b0001;
endcase
end else begin
ARF_FunSel = 2'b10;
case(DestReg[1:0]) 
2'b00: ARF_RegSel = 3'b100;
2'b01: ARF_RegSel = 3'b010;
2'b10: ARF_RegSel = 3'b001;
2'b11: ARF_RegSel = 3'b001;
endcase
end
T_Reset = 1'b1; //reset sequence counter
end
6'h1F: begin
// T6:In this step DR[0:7] <- M[AR], shift left dr
Mem_WR = 1'b0; // write 1 read 0 we need to read from memory
Mem_CS = 1'b0; // enable memory
DR_E = 1'b1; //enable DR so the output of the memory can be written in DR
DR_FunSel = 2'b10; //select dr load(0-7) + shift(23-0) to (21-8) so we will have only DR[0:7]<-M[sp]
OutDSel = 2'b11; // select AR to be output of D so the memory take address from AR
end
6'h20 : begin 
// M[AR+3] <- Rx[7:0], 
 OutDSel = 2'b10; // use AR
 Mem_WR = 1'b1; // WRITE enabled
 Mem_CS = 1'b0; // enable memory
 case(RegSel) // choose the register to use
 2'b00: begin // selects which register to give ALU
   RF_Out_B_Sel = 3'b000;
 end
 2'b01: begin
   RF_Out_B_Sel = 3'b001;
 end
 2'b10: begin 
   RF_Out_B_Sel = 3'b010;
 end
 2'b11: begin 
   RF_Out_B_Sel = 3'b011;
 end
 endcase
 FunSel = 5'b10001; // decided to transfer whole 32 bits
  ALU_WF = 1;
 Mux_C_Sel = 2'b00; // ALU[7:0]
 // STA update did not select before incrementing
 T_Reset = 1'b1; //reset 
end
6'h24 : begin 
// T6:M[AR+2] <- Rx[15:8], AR+3 <- AR+2 + 1
 disable_reg();
 OutDSel = 2'b10; // use AR
 Mem_WR = 1'b1; // WRITE enabled
 Mem_CS = 1'b0; // enable memory
 ALU_WF = 1;
 case(RegSel) // choose the register to use
 2'b00: begin // selects which register to give ALU
   RF_Out_B_Sel = 3'b000;
 end
 2'b01: begin
   RF_Out_B_Sel = 3'b001;
 end
 2'b10: begin 
   RF_Out_B_Sel = 3'b010;
 end
 2'b11: begin 
   RF_Out_B_Sel = 3'b011;
 end
 endcase
 FunSel = 5'b10001; // decided to transfer whole 32 bits
 Mux_C_Sel = 2'b01; // ALU[15:8]
 // STA update did not select before incrementing
 ARF_RegSel = 3'b001; // select AR
 ARF_FunSel = 2'b01; // increment AR
end
endcase
end
always@(posedge T[7]) begin
disable_reg();
case(Opcode)
6'h05: begin
//T7 : Rx <- DR
Mux_A_Sel = 2'b10; // Chosse Dr as input of RF
RF_Fun_Sel = 3'b010; // load
case(RegSel) // chosse the register to update its value 
2'b00: RF_RegSel = 4'b1000;
2'b01: RF_RegSel = 4'b0100;
2'b10: RF_RegSel = 4'b0010;
2'b11: RF_RegSel = 4'b0001;
endcase
T_Reset = 1'b1; //reset
end
6'h1F: begin
//T7: Rx <- DR
Mux_A_Sel = 2'b10; //select DR to RF
RF_Fun_Sel = 3'b010;
case(RegSel) // chosse the register to update its value 
2'b00: RF_RegSel = 4'b1000;
2'b01: RF_RegSel = 4'b0100;
2'b10: RF_RegSel = 4'b0010;
2'b11: RF_RegSel = 4'b0001;
endcase
T_Reset = 1'b1; //reset sequence counter
end
6'h24 : begin 
// M[AR+3] <- Rx[7:0], T <-0
 OutDSel = 2'b10; // use AR
 Mem_WR = 1'b1; // WRITE enabled
 Mem_CS = 1'b0; // enable memory
 case(RegSel) // choose the register to use
 2'b00: begin // selects which register to give ALU
   RF_Out_B_Sel = 3'b000;
 end
 2'b01: begin
   RF_Out_B_Sel = 3'b001;
 end
 2'b10: begin 
   RF_Out_B_Sel = 3'b010;
 end
 2'b11: begin 
   RF_Out_B_Sel = 3'b011;
 end
 endcase
 FunSel = 5'b10001; // decided to transfer whole 32 bits
 ALU_WF = 1;
 Mux_C_Sel = 2'b00; // ALU[7:0]
 // STA update did not select before incrementing
 T_Reset = 1'b1; //reset 
end
endcase
end
endmodule