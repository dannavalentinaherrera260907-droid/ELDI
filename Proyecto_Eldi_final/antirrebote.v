// Codigo generado con asistencia de IA (Claude, Anthropic) y revisado por el grupo. Ver "Uso de IA" en el README.

module antirrebote #(
    parameter N = 19
)(
    input  wire clk,
    input  wire rst_n,
    input  wire btn_n,
    output reg  pressed,
    output wire press_pulse
);
    reg s0, s1, prev;
    reg [N-1:0] cnt;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s0 <= 1'b1; s1 <= 1'b1; prev <= 1'b0; pressed <= 1'b0; cnt <= {N{1'b0}};
        end else begin
            s0   <= btn_n;
            s1   <= s0;
            prev <= pressed;
            if ((~s1) == pressed) begin
                cnt <= {N{1'b0}};
            end else begin
                cnt <= cnt + 1'b1;
                if (&cnt) begin
                    pressed <= ~s1;
                    cnt     <= {N{1'b0}};
                end
            end
        end
    end
    assign press_pulse = pressed & ~prev;
endmodule
