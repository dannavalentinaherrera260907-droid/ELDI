// Codigo generado con asistencia de IA (Claude, Anthropic) y revisado por el grupo. Ver "Uso de IA" en el README.

module mezcla (
    input  wire               clk,
    input  wire               tick,
    input  wire        [23:0] left,
    input  wire        [23:0] right,
    output reg                mono_valid = 1'b0,
    output reg  signed [11:0] mono = 12'sd0
);
    wire signed [24:0] suma = $signed({left[23], left}) + $signed({right[23], right});
    always @(posedge clk) begin
        mono_valid <= tick;
        if (tick) mono <= suma[24:13];
    end
endmodule
