/*  This file is part of JTFRAME.
    JTFRAME program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JTFRAME program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JTFRAME.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 8-5-2021 */

// ctrl+shift selects sys info
// alt+shift selects target info

module jtframe_debug #(
    parameter COLORW=4
) (
    input clk,
    input rst,

    input            shift,         // count step 16, instead of 1
    input            ctrl,          // reset debug_bus
    input            alt,
    input            debug_plus,
    input            debug_minus,
    input            debug_rst,
    input      [3:0] key_gfx,
    input      [7:0] key_digit,
    // overlay the value on video
    input              pxl_cen,
    input [COLORW-1:0] rin,
    input [COLORW-1:0] gin,
    input [COLORW-1:0] bin,
    input              lhbl,
    input              lvbl,
    input              dip_flip,

    // combinational output
    output reg [COLORW-1:0] rout,
    output reg [COLORW-1:0] gout,
    output reg [COLORW-1:0] bout,
    // debug features
    output reg [7:0] debug_bus,
    input      [7:0] debug_view, // an 8-bit signal that will be shown over the game image
    input      [7:0] sys_info,   // system information generated within JTFRAME, not the game
    input      [7:0] target_info,  // system information generated by the JTFRAME target, not the game
    output reg [3:0] gfx_en
);

reg        last_p, last_m;
integer    cnt;
reg  [3:0] last_gfx;
reg  [7:0] view_mux;
reg        last_digit, vtoggle_l;
reg  [1:0] view_sel;
wire       vtoggle;

wire [7:0] step = shift ? 8'd16 : 8'd1;

assign vtoggle = shift & ctrl;

localparam [1:0] SYS_INFO = 2'b01,
                 TARGET_INFO = 2'b10;

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        debug_bus  <= 0;
        gfx_en     <= 4'hf;
        last_digit <= 0;
        last_p     <= 0;
        last_m     <= 0;
        last_gfx   <= 0;
        view_sel   <= 0;
        view_mux   <= 0;
    end else begin
        last_p     <= debug_plus;
        last_m     <= debug_minus;
        last_gfx   <= key_gfx;
        last_digit <= |key_digit;
        vtoggle_l  <= vtoggle;

        if( vtoggle && !vtoggle_l ) begin
            view_sel <= view_sel==2 ? 2'd0 : view_sel+1'd1;
        end
        case( view_sel )
            default:     view_mux <= debug_view;
            SYS_INFO:    view_mux <= sys_info;
            TARGET_INFO: view_mux <= target_info;
        endcase

        if( ctrl && (debug_plus||debug_minus) ) begin
            debug_bus <= 0;
        end else begin
            if( debug_plus & ~last_p ) begin
                debug_bus <= debug_bus + step;
            end else if( debug_minus & ~last_m ) begin
                debug_bus <= debug_bus - step;
            end
            if( shift && key_digit!=0 && !last_digit ) begin
                debug_bus <= debug_bus ^ { key_digit[0],
                    key_digit[1],
                    key_digit[2],
                    key_digit[3],
                    key_digit[4],
                    key_digit[5],
                    key_digit[6],
                    key_digit[7] };
            end
        end
        for(cnt=0; cnt<4; cnt=cnt+1)
            if( key_gfx[cnt] && !last_gfx[cnt] ) gfx_en[cnt] <= ~gfx_en[cnt];
    end
end

// Video overlay
wire [8:0] HBIN=((`JTFRAME_WIDTH&9'h1f8)>>1)-9'h10,
                 HHEX=HBIN+9'h50,
                 VOSD=(`JTFRAME_HEIGHT & 9'h1f8)-8*4, // 4 rows above bottom
                 VVIEW=VOSD+8*2;

reg  [8:0] vcnt,hcnt;
reg        lhbl_l, osd_on, view_on, bus_hex_on, view_hex_on;
reg        show_view;
wire [8:0] veff, heff;

assign veff = vcnt ^ { 1'b0, {8{dip_flip}}};
assign heff = hcnt ^ { 1'b0, {8{dip_flip}}};

always @(posedge clk,posedge rst) begin
    if( rst ) begin
        lhbl_l      <= 0;
        vcnt        <= 0;
        hcnt        <= 0;
        osd_on      <= 0;
        bus_hex_on  <= 0;
        show_view   <= 0;
        view_on     <= 0;
        view_hex_on <= 0;
    end else if(pxl_cen) begin
        lhbl_l <= lhbl;
        if (!lvbl) begin
            vcnt <= 0;
        end else if( lhbl && !lhbl_l )
            vcnt <= vcnt + 9'd1;
        if (!lhbl)
            hcnt <= 0;
        else hcnt <= hcnt + 9'd1;
        // display of debug_bus
        osd_on     <= debug_bus!=0 && veff[8:3]==VOSD[8:3] && heff[8:6]==HBIN[8:6];
        bus_hex_on <= debug_bus!=0 && veff[8:3]==VOSD[8:3] && heff[8:4]==HHEX[8:4];

        // display of debug_view
        show_view   <= (view_mux!=0 || view_sel!=0 || debug_bus!=0) && veff[8:3]==VVIEW[8:3];
        view_on     <= show_view && heff[8:6] == HBIN[8:6];
        view_hex_on <= show_view && heff[8:4] == HHEX[8:4];
    end
end

reg [0:19] font [0:15]; // 4x5 font

// Inspired by TIC computer 6x6 font by nesbox
// https://fontstruct.com/fontstructions/show/1334143/tic-computer-6x6-font
initial begin
    font[4'd00] = 20'b0110_1001_1001_1001_0110;
    font[4'd01] = 20'b0010_0110_0010_0010_0111;
    font[4'd02] = 20'b1110_0001_0110_1000_1111;
    font[4'd03] = 20'b1111_0001_0110_0001_1110;
    font[4'd04] = 20'b0010_1010_1010_1111_0010;
    font[4'd05] = 20'b1111_1000_1110_0001_1110;
    font[4'd06] = 20'b0110_1000_1110_1001_0110;
    font[4'd07] = 20'b1111_0001_0010_0100_0100;
    font[4'd08] = 20'b0110_1001_0110_1001_0110;
    font[4'd09] = 20'b0110_1001_0111_0001_0110;
    font[4'd10] = 20'b0110_1001_1001_1111_1001;
    font[4'd11] = 20'b1110_1001_1110_1001_1110;
    font[4'd12] = 20'b0111_1000_1000_1000_0111;
    font[4'd13] = 20'b1110_1001_1001_1001_1110;
    font[4'd14] = 20'b1111_1000_1110_1000_1111;
    font[4'd15] = 20'b1111_1000_1110_1000_1000;
end


wire [3:0] display_bit_bus, display_bit_view, display_nibble_bus, display_nibble_view;
wire [4:0] font_pixel;

assign display_bit_bus     = { 3'h0, debug_bus[ ~heff[5:3] ] };
assign display_bit_view    = { 3'h0, view_mux[ ~heff[5:3] ] };
assign display_nibble_bus  = heff[3] ? debug_bus[3:0] : debug_bus[7:4];
assign display_nibble_view = heff[3] ? view_mux[3:0]  : view_mux[7:4];

assign font_pixel          = ( ( veff[2:0] - 3'd2 ) << 2 ) + ( heff[2:0] - 3'd3 );

always @* begin
    rout = rin;
    gout = gin;
    bout = bin;
    if( osd_on ) begin
        if( heff[2:0]!=0 ) begin
            rout = {COLORW{debug_bus[ ~heff[5:3] ]}};
            gout = {COLORW{debug_bus[ ~heff[5:3] ]}};
            bout = {COLORW{debug_bus[ ~heff[5:3] ]}};
        end
        if( heff[2:0] >= 3 && heff[2:0] < 7 && veff[2:0] >= 2 && veff[2:0] < 7 ) begin
            rout = {COLORW{ font[ display_bit_bus ][ font_pixel ] ^ display_bit_bus[0] }};
            gout = {COLORW{ font[ display_bit_bus ][ font_pixel ] ^ display_bit_bus[0] }};
            bout = {COLORW{ font[ display_bit_bus ][ font_pixel ] ^ display_bit_bus[0] }};
        end
    end

    if( view_on ) begin // binary view
        if( heff[2:0]!=0 ) begin
            rout[COLORW-1:COLORW-2] = {2{view_mux[ ~heff[5:3] ]}};
            gout[COLORW-1:COLORW-2] = {2{view_mux[ ~heff[5:3] ]}};
            bout[COLORW-1:COLORW-2] = {2{view_mux[ ~heff[5:3] ]}};
        end
        if( heff[2:0] >= 3 && heff[2:0] < 7 && veff[2:0] >= 2 && veff[2:0] < 7 ) begin
            rout[COLORW-1:COLORW-2] = {2{ font[ display_bit_view ][ font_pixel ] ^ display_bit_view[0] }};
            gout[COLORW-1:COLORW-2] = {2{ font[ display_bit_view ][ font_pixel ] ^ display_bit_view[0] }};
            bout[COLORW-1:COLORW-2] = {2{ font[ display_bit_view ][ font_pixel ] ^ display_bit_view[0] }};
        end
    end

    if( bus_hex_on ) begin // hex view
        if( heff[2:0] != 0 ) begin
            rout[COLORW-1:COLORW-2] = 2'b11;
            gout[COLORW-1:COLORW-2] = 2'b11;
            bout[COLORW-1:COLORW-2] = 2'b11;
        end
        if( heff[2:0] >= 3 && heff[2:0] < 7 && veff[2:0] >= 2 && veff[2:0] < 7 ) begin
            rout[COLORW-1:COLORW-2] = ~{2{ font[ display_nibble_bus ][ font_pixel ] }};
            gout[COLORW-1:COLORW-2] = ~{2{ font[ display_nibble_bus ][ font_pixel ] }};
            bout[COLORW-1:COLORW-2] = ~{2{ font[ display_nibble_bus ][ font_pixel ] }};
        end
    end

    if( view_hex_on ) begin
        if( heff[2:0] != 0 ) begin
            rout[COLORW-1:COLORW-2] = 2'b11;
            gout[COLORW-1:COLORW-2] = 2'b11;
            bout[COLORW-1:COLORW-2] = 2'b11;
        end
        if( heff[2:0] >= 3 && heff[2:0] < 7 && veff[2:0] >= 2 && veff[2:0] < 7 ) begin
            rout[COLORW-1:COLORW-2] = ~{2{ font[ display_nibble_view ][ font_pixel ] }};
            gout[COLORW-1:COLORW-2] = ~{2{ font[ display_nibble_view ][ font_pixel ] }};
            bout[COLORW-1:COLORW-2] = ~{2{ font[ display_nibble_view ][ font_pixel ] }};
        end
    end

    if( (view_on | view_hex_on) ) begin
        if( view_sel==SYS_INFO ) begin
            // system info is shown reddish
            gout[COLORW-1] = 0;
            bout[COLORW-1] = 0;
        end
        if( view_sel==TARGET_INFO ) begin
            // target info is shown blueish
            rout[COLORW-1] = 0;
            gout[COLORW-1] = 0;
        end
    end
end

endmodule