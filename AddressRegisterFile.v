`timescale 1ns / 1ps
 //////////////////////////////////////////////////////////////////////////////////
 // Company: 
 // Engineer: 
 // 
 // Create Date: 29.03.2025 07:59:37
 // Design Name: 
 // Module Name: AddresRegisterFile
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
 
 
 `timescale 1ns / 1ps
 //////////////////////////////////////////////////////////////////////////////////
 // Company: 
 // Engineer: 
 // 
 // Create Date: 29.03.2025 07:59:37
 // Design Name: 
 // Module Name: AddresRegisterFile
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
 
 
 module AddressRegisterFile(I, RegSel, FunSel, 
                           OutCSel, OutDSel, Clock, OutC, OutD);
 input wire [31:0] I;
 input wire [2:0] RegSel;
 input wire [1:0] FunSel;
 input wire [1:0] OutCSel;
 input wire [1:0] OutDSel;
 input wire Clock;
 output reg [15:0] OutC;
 output reg [15:0] OutD;
 
 wire[15:0] AROut [1:3];
 Register16bit PC(
   .FunSel(FunSel),
   .I(I[15:0]),
   .E(RegSel[2]),
   .Clock(Clock),
   .Q(AROut[1])
 );
 
 Register16bit SP(
   .FunSel(FunSel),
   .I(I[15:0]),
   .E(RegSel[1]),
   .Clock(Clock),
   .Q(AROut[2])
 );
 
 Register16bit AR(
   .FunSel(FunSel),
   .I(I[15:0]),
   .E(RegSel[0]),
   .Clock(Clock),
   .Q(AROut[3])
 );
 
always@(*)
begin
  case(OutCSel)
    2'b00 : OutC = AROut[1];
    2'b01 : OutC = AROut[2];
    2'b10 : OutC = AROut[3];
    2'b11 : OutC = AROut[3];
  endcase
  case(OutDSel)
    2'b00 : OutD = AROut[1];
    2'b01 : OutD = AROut[2];
    2'b10 : OutD = AROut[3];
    2'b11: OutD = AROut[3];

  endcase
end
 
 endmodule