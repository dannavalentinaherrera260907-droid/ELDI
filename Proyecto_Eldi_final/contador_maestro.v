// Codigo generado con asistencia de IA (Claude, Anthropic) y revisado por el grupo. Ver "Uso de IA" en el README.

module contador_maestro (
    input  wire       clk,
    output reg  [8:0] cnt = 9'd0,
    output wire       scki,
    output wire       bck,
    output wire       lrck
);
    always @(posedge clk) cnt <= cnt + 9'd1;
    assign scki = cnt[0];
    assign bck  = cnt[2];
    assign lrck = cnt[8];
endmodule
