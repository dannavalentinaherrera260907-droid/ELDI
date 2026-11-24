// Codigo generado con asistencia de IA (Claude, Anthropic) y revisado por el grupo. Ver "Uso de IA" en el README.

module barras_matriz #(
    parameter FLIP_X = 0,
    parameter FLIP_Y = 0
)(
    input  wire [3:0]  lvl0, lvl1, lvl2, lvl3,
    output wire [63:0] cols
);
    genvar c, r;
    generate
        for (c = 0; c < 8; c = c + 1) begin : g_col
            for (r = 0; r < 8; r = r + 1) begin : g_row
                wire [3:0] lvl = (r < 2) ? lvl0 : (r < 4) ? lvl1 : (r < 6) ? lvl2 : lvl3;
                wire       on  = (lvl > c);
                localparam DC  = FLIP_X ? 7 - c : c;
                localparam BR  = FLIP_Y ? 7 - r : r;
                assign cols[8*DC + BR] = on;
            end
        end
    endgenerate
endmodule
