// Codigo generado con asistencia de IA (Claude, Anthropic) y revisado por el grupo. Ver "Uso de IA" en el README.

module level_enc (
    input  wire [16:0] v,
    output reg  [3:0]  lvl
);
    always @(*) begin
        if      (v[16] | v[15]) lvl = 4'd8;
        else if (v[14])         lvl = 4'd7;
        else if (v[13])         lvl = 4'd6;
        else if (v[12])         lvl = 4'd5;
        else if (v[11])         lvl = 4'd4;
        else if (v[10])         lvl = 4'd3;
        else if (v[9])          lvl = 4'd2;
        else if (v[8])          lvl = 4'd1;
        else                    lvl = 4'd0;
    end
endmodule
