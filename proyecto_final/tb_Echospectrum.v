// =====================================================================================
// DECLARACION DE USO DE IA (Regla 8)
// Este archivo fue GENERADO CON ASISTENCIA DE IA (Claude, de Anthropic) a partir de los
// requisitos, la arquitectura y las decisiones de diseno del grupo, y de los datasheets
// del PCM1808, MCP3008 y MAX7219. El grupo lo reviso, lo ajusto y es responsable de
// explicarlo linea por linea. Ver la seccion "Declaracion de uso de IA" del informe.
// =====================================================================================
// =====================================================================================
// tb_Echospectrum.v - Banco de pruebas de EchoSpectrum (simulacion pura, Icarus Verilog).
//
//   iverilog -g2012 -o sim.vvp Echospectrum.v tb_Echospectrum.v
//   vvp sim.vvp
//   gtkwave echospectrum.vcd        (opcional: ver las ondas)
//
// Modelos incluidos:
//   - PCM1808 (esclavo I2S): saca cada bit por DOUT en el flanco de bajada de BCK.
//   - MCP3008: responde por SPI con un valor fijo por canal (las "perillas").
//   - MAX7219: recibe las palabras de 16 bits y guarda la imagen de la matriz.
// Pruebas (cada una imprime PASA o FALLA):
//   1. fs = 27 MHz / periodo de LRCK  >= 40 kHz
//   2. La muestra mono que calcula la FPGA es (L + R) / 2 de lo que envio el PCM1808
//   3. En silencio el PWM queda en duty = 128 (50 %)
//   4. Tono de 100 Hz -> la barra de graves es la mas alta
//   5. Tono de 6 kHz  -> la barra de agudos es la mas alta
//   6. Eco: un golpe vuelve a aparecer D = 1025 muestras despues, y otra vez a 2D mas debil
//   7. Boton A cambia de eco a directo
// =====================================================================================
`timescale 1ns / 1ps

module tb_Echospectrum;
    // ---------------- reloj de 27 MHz ----------------
    reg clk = 1'b0;
    always #18.5185 clk = ~clk;

    // ---------------- senales de la placa ----------------
    reg  btn_a_n = 1'b1, btn_b_n = 1'b1;
    wire [5:0] led_n;
    wire scki, bck, lrck, pwm_out, mat_din, mat_clk, mat_cs, mcp_cs_n, mcp_clk, mcp_din;
    reg  dout = 1'b0;
    reg  mcp_dout = 1'b0;

    Echospectrum #(.DB_N(4), .REFRESH_BITS(14)) dut (
        .clk(clk), .btn_a_n(btn_a_n), .btn_b_n(btn_b_n), .led_n(led_n),
        .scki(scki), .bck(bck), .lrck(lrck), .dout(dout), .pwm_out(pwm_out),
        .mat_din(mat_din), .mat_clk(mat_clk), .mat_cs(mat_cs),
        .mcp_cs_n(mcp_cs_n), .mcp_clk(mcp_clk), .mcp_din(mcp_din), .mcp_dout(mcp_dout));

    // =================================================================================
    // Modelo del PCM1808
    // =================================================================================
    // modo de la senal: 0 = silencio, 1 = tono, 2 = golpe en la trama 'golpe_en'
    integer modo_senal = 0;
    real    f_tono     = 100.0;
    real    amp        = 3000000.0;          // amplitud en cuentas de 24 bits
    integer golpe_en   = -1;
    integer frame      = 0;                  // numero de trama (sube cuando LRCK baja)
    reg [23:0] Lw = 24'd0, Rw = 24'd0;       // muestra que se esta enviando
    reg [23:0] Lprev = 24'd0, Rprev = 24'd0; // muestra de la trama anterior
    integer pos = 0;
    reg lr_prev = 1'b0;
    real PI = 3.14159265358979;
    real FS;
    initial FS = 27000000.0 / 512.0;

    function [23:0] a24;                     // real -> 24 bits con signo
        input real v;
        integer k;
        begin
            k = $rtoi(v);
            a24 = k[23:0];
        end
    endfunction

    always @(negedge bck) begin
        #5;                                  // el PCM1808 cambia DOUT un poco despues del flanco
        if (lrck !== lr_prev) begin
            lr_prev = lrck;
            pos = 0;
            if (lrck == 1'b0) begin          // empieza una trama nueva (canal izquierdo)
                Lprev = Lw; Rprev = Rw;
                frame = frame + 1;
                case (modo_senal)
                    1: begin
                        Lw = a24(amp * $sin(2.0 * PI * f_tono * frame / FS));
                        Rw = a24(0.9 * amp * $sin(2.0 * PI * f_tono * frame / FS));
                    end
                    2: begin
                        if (frame == golpe_en) begin Lw = 24'h400000; Rw = 24'h400000; end
                        else begin Lw = 24'd0; Rw = 24'd0; end
                    end
                    default: begin Lw = 24'd0; Rw = 24'd0; end
                endcase
            end
        end else begin
            pos = pos + 1;
        end
        if (pos >= 1 && pos <= 24) dout = lrck ? Rw[24 - pos] : Lw[24 - pos];   // MSB primero
        else                       dout = 1'b0;
    end

    // =================================================================================
    // Modelo del MCP3008 (las perillas)
    // =================================================================================
    reg [9:0] potval [0:7];
    integer   rcount = 0;
    reg [2:0] cmd = 3'd0;
    reg [2:0] chsel = 3'd0;
    initial begin
        potval[0] = 10'd64;     // RV1 retardo:        D = 16 x 64 + 1 = 1025 muestras (19,4 ms)
        potval[1] = 10'd512;    // RV2 realimentacion: k = 512 >> 7 = 4  -> 4/8 = 0,5
        potval[2] = 10'd896;    // RV3 mezcla:         k = 896 >> 7 = 7  -> 7/8 = 0,875
        potval[3] = 10'd1023;   // RV4 volumen:        15/16
        potval[4] = 0; potval[5] = 0; potval[6] = 0; potval[7] = 0;
    end
    always @(negedge mcp_cs_n) begin rcount = 0; mcp_dout = 1'b0; end
    always @(posedge mcp_clk) if (!mcp_cs_n) begin
        rcount = rcount + 1;
        cmd = {cmd[1:0], mcp_din};
        if (rcount == 12) chsel = cmd;     // D2 D1 D0 recibidos
    end
    always @(negedge mcp_clk) if (!mcp_cs_n) begin
        #5;
        if (rcount == 13)                         mcp_dout = 1'b0;                          // bit nulo
        else if (rcount >= 14 && rcount <= 23)    mcp_dout = potval[chsel][9 - (rcount - 14)];
        else                                      mcp_dout = 1'b0;
    end

    // =================================================================================
    // Modelo del MAX7219: guarda las 8 columnas que llegan
    // =================================================================================
    reg [15:0] msh = 16'd0;
    reg [7:0]  dig [0:7];
    reg [3:0]  brillo = 4'd0;
    integer    palabras = 0;
    integer k2;
    initial for (k2 = 0; k2 < 8; k2 = k2 + 1) dig[k2] = 8'd0;
    always @(posedge mat_clk) if (!mat_cs) msh <= {msh[14:0], mat_din};
    always @(posedge mat_cs) begin
        palabras = palabras + 1;
        if (msh[11:8] >= 4'd1 && msh[11:8] <= 4'd8) dig[msh[11:8] - 1] = msh[7:0];
        if (msh[11:8] == 4'hA) brillo = msh[3:0];
    end

    task mostrar_matriz;
        integer r, c;
        reg [8*8-1:0] linea;
        begin
            $display("      matriz 8x8 (filas 0-1 graves ... filas 6-7 agudos):");
            for (r = 0; r < 8; r = r + 1) begin
                for (c = 0; c < 8; c = c + 1) linea[8*(7-c) +: 8] = dig[c][r] ? "#" : ".";
                $display("        %s", linea);
            end
        end
    endtask

    // =================================================================================
    // Prueba 2: la mezcla. Se revisa cada muestra mono contra (L + R) / 2.
    // =================================================================================
    integer muestras = 0, errores_mezcla = 0, revisadas = 0;
    integer s_exp;
    reg signed [11:0] mono_exp;
    always @(negedge clk) if (dut.mono_valid) begin
        muestras = muestras + 1;
        if (muestras > 4) begin
            s_exp    = $signed(Lprev) + $signed(Rprev);
            mono_exp = s_exp >>> 13;
            revisadas = revisadas + 1;
            if (dut.mono !== mono_exp) begin
                errores_mezcla = errores_mezcla + 1;
                if (errores_mezcla < 5)
                    $display("  [mezcla] trama %0d: mono = %0d, esperado %0d", frame - 1, dut.mono, mono_exp);
            end
        end
    end

    // =================================================================================
    // Prueba 6: el eco. Se anota cada salida del motor de eco.
    // =================================================================================
    integer n_eco = 0;                    // numero de muestra a la salida del eco
    integer i_golpe = -1, i_eco1 = -1, i_eco2 = -1;
    integer a_golpe = 0, a_eco1 = 0, a_eco2 = 0;
    reg     midiendo_eco = 1'b0;
    always @(negedge clk) if (dut.e_valid && midiendo_eco) begin
        n_eco = n_eco + 1;
        if (i_golpe < 0 && dut.e_y > 500) begin i_golpe = n_eco; a_golpe = dut.e_y; end
        else if (i_golpe >= 0 && i_eco1 < 0 && n_eco > i_golpe + 10 && dut.e_y > 200) begin i_eco1 = n_eco; a_eco1 = dut.e_y; end
        else if (i_eco1 >= 0 && i_eco2 < 0 && n_eco > i_eco1 + 10 && dut.e_y > 100) begin i_eco2 = n_eco; a_eco2 = dut.e_y; end
    end

    // =================================================================================
    // Ondas para GTKWave (solo senales lentas, para que el archivo no sea enorme)
    // =================================================================================
    reg win = 1'b0;                        // ventana corta para ver el I2S ciclo a ciclo
    reg [8:0] w_cnt; reg w_bck, w_lrck, w_dout, w_en_sh, w_load_L, w_load_R, w_tick, w_pwm;
    reg [23:0] w_sh;
    always @(posedge clk) if (win) begin
        w_cnt <= dut.cnt; w_bck <= bck; w_lrck <= lrck; w_dout <= dout;
        w_en_sh <= dut.u_rx.en_sh; w_load_L <= dut.u_rx.load_L; w_load_R <= dut.u_rx.load_R;
        w_tick <= dut.tick; w_sh <= dut.u_rx.sh; w_pwm <= pwm_out;
    end
    initial begin
        $dumpfile("echospectrum.vcd");
        // (no se guarda clk ni BCK: cambian millones de veces y el archivo seria enorme)
        $dumpvars(1, w_cnt, w_bck, w_lrck, w_dout, w_en_sh, w_load_L, w_load_R, w_tick, w_sh, w_pwm, frame, modo_senal);
        $dumpvars(1, dut.mono, dut.e_y, dut.o_y, dut.u_pwm.duty, dut.lvl0, dut.lvl1, dut.lvl2, dut.lvl3,
                     dut.mode, dut.page, dut.p_delay, dut.p_fb, dut.p_mix, dut.p_vol, dut.u_echo.ds);
    end

    // =================================================================================
    // Guion de la prueba
    // =================================================================================
    integer t0, t1, periodo, pasa = 0, falla = 0;
    integer l0, l1, l2, l3;
    task esperar_tramas; input integer n; integer m; begin for (m = 0; m < n; m = m + 1) @(negedge lrck); end endtask
    task resultado; input ok; input [8*48-1:0] nombre; begin
        if (ok) begin pasa = pasa + 1;  $display("  PASA  %0s", nombre); end
        else    begin falla = falla + 1; $display("  FALLA %0s", nombre); end
    end endtask

    initial begin
        $display("\n=== Simulacion de EchoSpectrum ===");
        wait (dut.rst_n === 1'b1);
        $display("Reset terminado a los %0t ns", $time);

        // ---- Prueba 1: frecuencia de muestreo ----
        @(posedge lrck); t0 = $time; @(posedge lrck); t1 = $time;
        periodo = (t1 - t0);
        $display("\n[1] Periodo de LRCK = %0d ns  ->  fs = %0d Hz", periodo, 1000000000 / periodo);
        resultado((1000000000 / periodo) >= 40000, "fs >= 40 kHz");

        // ventana para ver el I2S en GTKWave
        win = 1'b1; esperar_tramas(3); win = 1'b0;

        // ---- Prueba 3: PWM en silencio ----
        esperar_tramas(50);
        $display("\n[3] En silencio: duty = %0d", dut.u_pwm.duty);
        resultado(dut.u_pwm.duty == 8'd128, "PWM en silencio = 128 (50 %)");

        // ---- Prueba 6: eco (primero, con la memoria del eco limpia) ----
        $display("\n[6] Perillas: retardo D = %0d muestras, realimentacion k = %0d/8, mezcla k = %0d/8",
                 {dut.p_delay, 4'b0001}, dut.p_fb[9:7], dut.p_mix[9:7]);
        modo_senal = 2; esperar_tramas(1100);   // D sube de 1 a 1025 de a una muestra: hay que esperar
        midiendo_eco = 1'b1;
        golpe_en = frame + 50;
        esperar_tramas(50 + 2 * 1025 + 100);
        midiendo_eco = 1'b0;
        $display("    golpe en la muestra %0d (amplitud %0d)", i_golpe, a_golpe);
        $display("    1er eco en la muestra %0d (amplitud %0d)  -> retardo %0d", i_eco1, a_eco1, i_eco1 - i_golpe);
        $display("    2do eco en la muestra %0d (amplitud %0d)  -> retardo %0d", i_eco2, a_eco2, i_eco2 - i_eco1);
        resultado(i_golpe > 0 && (i_eco1 - i_golpe) == 1025, "el eco llega 1025 muestras despues (19,4 ms)");
        resultado(a_eco1 >= 880 && a_eco1 <= 900, "1er eco = 0,875 x golpe (mezcla 7/8)");
        resultado((i_eco2 - i_eco1) == 1025 && a_eco2 >= 440 && a_eco2 <= 456, "2do eco = la mitad (realimentacion 4/8)");

        // ---- Prueba 4: tono grave ----
        modo_senal = 1; f_tono = 100.0;
        esperar_tramas(1500);
        l0 = dut.lvl0; l1 = dut.lvl1; l2 = dut.lvl2; l3 = dut.lvl3;
        $display("\n[4] Tono de 100 Hz -> niveles: graves %0d | medios-bajos %0d | medios %0d | agudos %0d", l0, l1, l2, l3);
        mostrar_matriz;
        resultado(l0 >= l1 && l0 >= l2 && l0 > l3, "100 Hz: la barra de graves es la mas alta");
        // segunda ventana para GTKWave: el receptor I2S recibiendo el tono (DOUT con datos reales)
        $display("    (ventana I2S con tono para GTKWave desde %0t ps)", $time);
        win = 1'b1; esperar_tramas(3); win = 1'b0;

        // ---- Prueba 5: tono agudo ----
        f_tono = 6000.0;
        esperar_tramas(2500);           // la barra de graves tarda en bajar (caida lenta)
        l0 = dut.lvl0; l1 = dut.lvl1; l2 = dut.lvl2; l3 = dut.lvl3;
        $display("\n[5] Tono de 6 kHz -> niveles: graves %0d | medios-bajos %0d | medios %0d | agudos %0d", l0, l1, l2, l3);
        mostrar_matriz;
        resultado(l3 >= l2 && l3 > l1 && l3 > l0, "6 kHz: la barra de agudos es la mas alta");

        // ---- Prueba 2: mezcla (se revisaron todas las muestras hasta aqui) ----
        $display("\n[2] Muestras mono revisadas: %0d, errores: %0d", revisadas, errores_mezcla);
        resultado(revisadas > 1000 && errores_mezcla == 0, "mono = (L + R) / 2 en todas las muestras");

        // ---- Prueba 7: boton A ----
        btn_a_n = 1'b0; repeat (200) @(posedge clk); btn_a_n = 1'b1; repeat (200) @(posedge clk);
        $display("\n[7] Despues de oprimir A: modo = %0d (0 = directo), LED0 = %0d (1 = apagado)", dut.mode, led_n[0]);
        resultado(dut.mode == 1'b0 && led_n[0] == 1'b1, "boton A cambia a directo");

        $display("\n=== Resultado: %0d pruebas pasan, %0d fallan ===", pasa, falla);
        $display("    MAX7219: %0d palabras recibidas, brillo = %0d\n", palabras, brillo);
        $finish;
    end
endmodule
