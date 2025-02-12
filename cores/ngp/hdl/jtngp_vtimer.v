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
    Date: 22-3-2022 */

module jtngp_vtimer(
    input               clk,
    input         [1:0] video_cen,
    input               hint_en,
    input               vint_en,

    output reg          pxl_cen,
    output reg          pxl2_cen,
    output reg  [9:0]   hcnt,       // top 8 bits
    output reg  [8:0]   hdump,
    output reg  [7:0]   vdump, vrender,
    input       [7:0]   view_height, view_starty,
    output reg          LHBL,
    output reg          LVBL,
    output reg          HS,
    output reg          VS,

    output reg          hirq,
    output reg          virq
);

localparam HOFFSET= 48,
           HBSTART= 14, // 11->17
           HBEND  =HBSTART+35,
           HS_START = HBSTART+8,
           HS_END   = HS_START+4;

reg [2:0] three=1;
reg [7:0] virq_line;

initial begin
    hirq = 0;
    virq = 0;
end

always @(posedge clk) begin
    pxl_cen  <= video_cen[1] & three[2];
    pxl2_cen <= video_cen[1] & (three[2] | three[0]);
    virq_line <= view_height+view_starty;
    if( video_cen[1] ) begin
        three <= { three[1:0], three[2] };
        if( hcnt==6 ) begin
            hirq <= 0;
            virq <= 0;
        end
        if( hcnt==HBSTART ) begin
            LHBL <= 0;
        end
        if( hcnt==HBEND ) LHBL <= 1;
        if( hcnt==514 ) begin
            hdump    <= 0;
            hcnt     <= 0;
            three    <= 1;
            pxl_cen  <= 1;
            pxl2_cen <= 1;
        end else begin
            if( three[2] ) hdump <= hdump + 9'd1;
            hcnt  <= hcnt  +10'd1;
        end
        if( hcnt == HS_END   ) HS <= 0;
        if( hcnt == HS_START ) begin
            HS       <= 1;
            vrender  <= (vrender==198) ? 8'd0 : (vrender+8'd1);
            vdump    <= vrender;
            virq  <= vint_en && vdump==virq_line;
            hirq  <= hint_en && (vdump<150 || vdump==198 );
            if( vdump==151 )
                LVBL <= 0;
            else if( vdump==198 )
                LVBL <= 1;
            if( vdump==180 )
                VS <= 1;
            else if( vdump==183 )
                VS <= 0;
        end
    end
end

endmodule
