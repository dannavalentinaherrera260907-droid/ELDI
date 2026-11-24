// Codigo generado con asistencia de IA (Claude, Anthropic) y revisado por el grupo. Ver "Uso de IA" en el README.

module salida_pwm (
    input  wire               clk,
    input  wire               in_valid,
    input  wire signed [11:0] x,
    input  wire        [7:0]  cnt8,
    output reg                pwm = 1'b0
);
    reg [7:0] duty = 8'd128;
    always @(posedge clk) begin
        if (in_valid) duty <= {~x[11], x[10:4]};
        pwm <= (cnt8 < duty);
    end
endmodule
