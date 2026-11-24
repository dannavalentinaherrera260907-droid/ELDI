// Codigo generado con asistencia de IA (Claude, Anthropic) y revisado por el grupo. Ver "Uso de IA" en el README.

module envelope (
    input  wire               clk,
    input  wire               rst_n,
    input  wire               in_valid,
    input  wire signed [16:0] b,
    output wire        [3:0]  level
);
    reg  [2:0]  v;
    reg  [16:0] m;
    reg         gt;
    reg  [26:0] dif, env;
    wire [26:0] m_ext = {m, 10'b0000000000};
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            v <= 3'd0; m <= 17'd0; gt <= 1'b0; dif <= 27'd0; env <= 27'd0;
        end else begin
            v <= {v[1:0], in_valid};
            if (in_valid) m <= b[16] ? (17'd0 - b) : b;
            if (v[0]) begin
                gt  <= (m_ext > env);
                dif <= m_ext - env;
            end
            if (v[1]) begin
                if (gt) env <= env + (dif >> 2);
                else    env <= env - (env >> 12);
            end
        end
    end
    level_enc u_lvl (.v(env[26:10]), .lvl(level));
endmodule
