/*  This file is part of JTCORES.
    JTCORES program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JTCORES program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JTCORES.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. https://patreon.com/jotego
    Version: 1.0
    Date: 23-3-2022 */

module jtngp_colmix #( parameter
    SIMFILE_LO = "pal_lo.bin",
    SIMFILE_HI = "pal_hi.bin"
)(
    input             rst,
    input             clk,
    input             pxl_cen,
    input             lcd_neg,

    input             scr_order,

    // CPU access
    input      [ 8:1] cpu_addr,
    output reg [15:0] cpu_din,
    input      [15:0] cpu_dout,
    input      [ 1:0] we,
    input             pal_cs,
    input             palrgb_cs,

    input             LHBL,
    input             LVBL,

    input       [2:0] scr1_pxl,
    input       [2:0] scr2_pxl,
    input       [4:0] obj_pxl,

    output      [3:0] red,
    output      [3:0] green,
    output      [3:0] blue
    // gfx_en is handled at the scroll and obj modules
);

reg  [ 2:0] pxl;
wire [ 1:0] prio = obj_pxl[4:3];
reg  [ 1:0] lyr;
wire [ 3:0] raw, scr_eff;
// wire [15:0] pal_dout;
wire [ 7:0] pal_addr;
wire [ 2:0] obj_palout, scr1_palout, scr2_palout;
wire        scr1_blank, scr2_blank, obj_blank;

// monochrome palette
reg [2:0]  obj_pal0 [1:3];
reg [2:0]  obj_pal1 [1:3];
reg [2:0] scr1_pal0 [1:3];
reg [2:0] scr1_pal1 [1:3];
reg [2:0] scr2_pal0 [1:3];
reg [2:0] scr2_pal1 [1:3];
reg [2:0] bg_pal;

assign  scr1_blank = scr1_pxl[1:0]==0,
        scr2_blank = scr2_pxl[1:0]==0,
        obj_blank  = obj_pxl[1:0]==0 || prio==0,
        scr_eff    = scr_order ?
            ( !scr2_blank ? {1'b0,scr2_palout} : {1'b1,scr1_palout} ) :
            ( !scr1_blank ? {1'b0,scr1_palout} : {1'b1,scr2_palout} ),
        pal_addr   = 0,
        raw        = { pxl[2:0], pxl[2] }^{4{~lcd_neg}},
        obj_palout = obj_pxl[2] ? obj_pal1[obj_pxl[1:0]] : obj_pal0[obj_pxl[1:0]],
        scr1_palout= scr1_pxl[2] ? scr1_pal1[scr1_pxl[1:0]] : scr1_pal0[scr1_pxl[1:0]],
        scr2_palout= scr2_pxl[2] ? scr2_pal1[scr2_pxl[1:0]] : scr2_pal0[scr2_pxl[1:0]];

// to do: connect to actual palette RAM
assign  red        = raw,
        blue       = raw,
        green      = raw;

always @(posedge clk) begin
    // layer mixing
    pxl <= scr_eff[2:0];
    lyr[1] <= 0;
    lyr[0] <= scr_eff[3] ^ scr_order;
    if( !obj_blank ) begin
        lyr[1] <= 1;
        case( prio )
            3: pxl <= obj_palout;
            2: if( scr_eff[3] ) pxl <= obj_palout;
            1: if( scr_eff[1:0]==0) pxl <= obj_palout;
            default: lyr[1] <= 0;
        endcase
    end
end

`ifdef SIMULATION
reg [7:0] zeroval[0:24];
integer f,cnt;

initial begin
    f = $fopen("pal.bin","rb");
    if( f!=0 ) begin
        cnt = $fread(zeroval,f);
        $display("Read %d from pal.bin",cnt);
        $fclose(f);
    end else begin
        $display("Could not open pal.bin");
    end
end
`endif

// palette writes
always @(posedge clk, posedge rst) begin
    if( rst ) begin
         obj_pal0[1] <= 7;  obj_pal0[2] <= 7;  obj_pal0[3] <= 7;
         obj_pal1[1] <= 7;  obj_pal1[2] <= 7;  obj_pal1[3] <= 7;
        scr1_pal0[1] <= 7; scr1_pal0[2] <= 7; scr1_pal0[3] <= 7;
        scr1_pal1[1] <= 7; scr1_pal1[2] <= 7; scr1_pal1[3] <= 7;
        scr2_pal0[1] <= 7; scr2_pal0[2] <= 7; scr2_pal0[3] <= 7;
        scr2_pal1[1] <= 7; scr2_pal1[2] <= 7; scr2_pal1[3] <= 7;
          bg_pal     <= 7;
`ifdef SIMULATION
        if( cnt==25 ) begin
             obj_pal0[1] <= zeroval[   1][2:0];
             obj_pal0[2] <= zeroval[   2][2:0];
             obj_pal0[3] <= zeroval[   3][2:0];
             obj_pal1[1] <= zeroval[ 4+1][2:0];
             obj_pal1[2] <= zeroval[ 4+2][2:0];
             obj_pal1[3] <= zeroval[ 4+3][2:0];
            scr1_pal0[1] <= zeroval[ 8+1][2:0];
            scr1_pal0[2] <= zeroval[ 8+2][2:0];
            scr1_pal0[3] <= zeroval[ 8+3][2:0];
            scr1_pal1[1] <= zeroval[12+1][2:0];
            scr1_pal1[2] <= zeroval[12+2][2:0];
            scr1_pal1[3] <= zeroval[12+3][2:0];
            scr2_pal0[1] <= zeroval[16+1][2:0];
            scr2_pal0[2] <= zeroval[16+2][2:0];
            scr2_pal0[3] <= zeroval[16+3][2:0];
            scr2_pal1[1] <= zeroval[20+1][2:0];
            scr2_pal1[2] <= zeroval[20+2][2:0];
            scr2_pal1[3] <= zeroval[20+3][2:0];
              bg_pal     <= zeroval[20+4][2:0];
        end
`endif
    end else begin
        cpu_din <= 0;
        case( cpu_addr[4:1] )
            4'b0_000: cpu_din[10:8] <= obj_pal0[1];
            4'b0_001: begin
                cpu_din[ 2:0] <= obj_pal0[2];
                cpu_din[10:8] <= obj_pal0[3];
            end
            4'b0_010: cpu_din[10:8] <= obj_pal1[1];
            4'b0_011: begin
                cpu_din[ 2:0] <= obj_pal1[2];
                cpu_din[10:8] <= obj_pal1[3];
            end
            // Scroll 1
            4'b0_100: cpu_din[10:8] <= scr1_pal0[1];
            4'b0_101: begin
                cpu_din[ 2:0] <= scr1_pal0[2];
                cpu_din[10:8] <= scr1_pal0[3];
            end
            4'b0_110: cpu_din[10:8] <= scr1_pal1[1];
            4'b0_111: begin
                cpu_din[ 2:0] <= scr1_pal1[2];
                cpu_din[10:8] <= scr1_pal1[3];
            end
            // Scroll 2
            4'b1_000: cpu_din[10:8] <= scr2_pal0[1];
            4'b1_001: begin
                cpu_din[ 2:0] <= scr2_pal0[2];
                cpu_din[10:8] <= scr2_pal0[3];
            end
            4'b1_010: cpu_din[10:8] <= scr2_pal1[1];
            4'b1_011: begin
                cpu_din[ 2:0] <= scr2_pal1[2];
                cpu_din[10:8] <= scr2_pal1[3];
            end
            // Background
            4'b1_100: cpu_din[2:0] <= bg_pal;
            default:;
        endcase

        if( pal_cs ) case( cpu_addr[4:1] )
            4'b0_000: if( we[1] ) obj_pal0[1] <= cpu_dout[10:8];
            4'b0_001: begin
                if( we[0] ) obj_pal0[2] <= cpu_dout[ 2:0];
                if( we[1] ) obj_pal0[3] <= cpu_dout[10:8];
            end
            4'b0_010: if( we[1] ) obj_pal1[1] <= cpu_dout[10:8];
            4'b0_011: begin
                if( we[0] ) obj_pal1[2] <= cpu_dout[ 2:0];
                if( we[1] ) obj_pal1[3] <= cpu_dout[10:8];
            end
            // Scroll 1
            4'b0_100: if( we[1] ) scr1_pal0[1] <= cpu_dout[10:8];
            4'b0_101: begin
                if( we[0] ) scr1_pal0[2] <= cpu_dout[ 2:0];
                if( we[1] ) scr1_pal0[3] <= cpu_dout[10:8];
            end
            4'b0_110: if( we[1] ) scr1_pal1[1] <= cpu_dout[10:8];
            4'b0_111: begin
                if( we[0] ) scr1_pal1[2] <= cpu_dout[ 2:0];
                if( we[1] ) scr1_pal1[3] <= cpu_dout[10:8];
            end
            // Scroll 2
            4'b1_000: if( we[1] ) scr2_pal0[1] <= cpu_dout[10:8];
            4'b1_001: begin
                if( we[0] ) scr2_pal0[2] <= cpu_dout[ 2:0];
                if( we[1] ) scr2_pal0[3] <= cpu_dout[10:8];
            end
            4'b1_010: if( we[1] ) scr2_pal1[1] <= cpu_dout[10:8];
            4'b1_011: begin
                if( we[0] ) scr2_pal1[2] <= cpu_dout[ 2:0];
                if( we[1] ) scr2_pal1[3] <= cpu_dout[10:8];
            end
            // Background
            4'b1_100: if( we[0] ) bg_pal <= cpu_dout[2:0];
            default:;
        endcase
    end
end

// 256 entries, each is 16 bits
// jtframe_dual_ram16 #(
//     .AW         (  8          ),
//     .SIMFILE_LO ( SIMFILE_LO  ),
//     .SIMFILE_HI ( SIMFILE_HI  )
// ) u_pal(
//     // Port 0
//     .clk0   ( clk       ),
//     .data0  ( cpu_dout  ),
//     .addr0  ( cpu_addr  ),
//     .we0    ( we        ),
//     .q0     ( cpu_din   ),
//     // Port 1
//     .clk1   ( clk       ),
//     .data1  (           ),
//     .addr1  ( pal_addr  ),
//     .we1    ( 2'b0      ),
//     .q1     ( pal_dout  )
// );

endmodule