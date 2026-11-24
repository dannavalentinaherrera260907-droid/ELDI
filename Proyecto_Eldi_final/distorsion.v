// Codigo generado con asistencia de IA (Claude, Anthropic) y revisado por el grupo. Ver "Uso de IA" en el README.

module distorsion (
    input  wire               clk,
    input  wire               rst_n,
    input  wire               in_valid,
    input  wire signed [11:0] x,
    input  wire        [1:0]  sh,
    output reg                out_valid,
    output reg  signed [11:0] y
);
    wire signed [14:0] xs = $signed(x) <<< sh;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 1'b0; y <= 12'sd0;
        end else begin
            out_valid <= in_valid;
            if (in_valid) begin
                if (xs > 15'sd2047)       y <= 12'sh7FF;
                else if (xs < -15'sd2048) y <= 12'sh800;
                else                      y <= xs[11:0];
            end
        end
    end
endmodule
