module reciprocal_unit_tb;

    reg  [31:0] x;
    wire [31:0] reciprocal;

    real x_real;
    real dut_real;
    real expected_real;
    real abs_error;
    real rel_error;

    real max_error;
    real max_error_input;

    integer pass_count;
    integer fail_count;


    // ============================================================
    // DEVICE UNDER TEST
    // ============================================================

    reciprocal_unit dut (
        .x          (x),
        .reciprocal (reciprocal)
    );


    // ============================================================
    // FP32 -> REAL
    // ============================================================

    function real fp32_to_real;
        input [31:0] value;

        reg        s;
        reg [7:0]  e;
        reg [22:0] f;

        real mantissa;
        real weight;

        integer unbiased_exp;
        integer i;
        integer j;

        begin

            s = value[31];
            e = value[30:23];
            f = value[22:0];

            // ----------------------------------------------------
            // ZERO
            // ----------------------------------------------------

            if ((e == 0) && (f == 0))
            begin
                fp32_to_real = 0.0;
            end

            // ----------------------------------------------------
            // NORMAL NUMBER
            // ----------------------------------------------------

            else if (e != 0)
            begin

                // Start with implicit 1
                mantissa = 1.0;

                // First fraction bit = 1/2
                weight = 0.5;

                for (i = 22; i >= 0; i = i - 1)
                begin

                    if (f[i])
                        mantissa = mantissa + weight;

                    weight = weight / 2.0;

                end

                // Remove FP32 bias
                unbiased_exp = e - 127;

                // ------------------------------------------------
                // Apply 2^unbiased_exp WITHOUT **
                // ------------------------------------------------

                if (unbiased_exp > 0)
                begin

                    for (j = 0; j < unbiased_exp; j = j + 1)
                        mantissa = mantissa * 2.0;

                end
                else if (unbiased_exp < 0)
                begin

                    for (j = 0; j > unbiased_exp; j = j - 1)
                        mantissa = mantissa / 2.0;

                end

                // Apply sign
                if (s)
                    mantissa = -mantissa;

                fp32_to_real = mantissa;

            end

            // ----------------------------------------------------
            // SUBNORMAL
            // ----------------------------------------------------

            else
            begin

                mantissa = 0.0;

                weight = 0.5;

                for (i = 22; i >= 0; i = i - 1)
                begin

                    if (f[i])
                        mantissa = mantissa + weight;

                    weight = weight / 2.0;

                end

                // 2^-126

                for (j = 0; j < 126; j = j + 1)
                    mantissa = mantissa / 2.0;

                if (s)
                    mantissa = -mantissa;

                fp32_to_real = mantissa;

            end

        end

    endfunction


    // ============================================================
    // RECIPROCAL TEST
    // ============================================================

    task test_reciprocal;

        input [31:0] input_value;
        input real tolerance;

        begin

            x = input_value;

            #10;

            // ----------------------------------------------------
            // Convert FP32 values
            // ----------------------------------------------------

            x_real = fp32_to_real(x);

            dut_real = fp32_to_real(reciprocal);

            expected_real = 1.0 / x_real;


            // ----------------------------------------------------
            // Calculate absolute error
            // ----------------------------------------------------

            abs_error = dut_real - expected_real;

            if (abs_error < 0.0)
                abs_error = -abs_error;


            // ----------------------------------------------------
            // Calculate relative error
            // ----------------------------------------------------

            rel_error = abs_error / expected_real;

            if (rel_error < 0.0)
                rel_error = -rel_error;


            // ----------------------------------------------------
            // Track worst case
            // ----------------------------------------------------

            if (rel_error > max_error)
            begin
                max_error = rel_error;
                max_error_input = x_real;
            end


            // ----------------------------------------------------
            // PASS / FAIL
            // ----------------------------------------------------

            if (rel_error <= tolerance)
            begin

                pass_count = pass_count + 1;

                $display(
                    "PASS : x = %10.6f | expected = %12.8f | DUT = %12.8f | error = %8.4f%%",
                    x_real,
                    expected_real,
                    dut_real,
                    rel_error * 100.0
                );

            end

            else
            begin

                fail_count = fail_count + 1;

                $display(
                    "FAIL : x = %10.6f | expected = %12.8f | DUT = %12.8f | error = %8.4f%%",
                    x_real,
                    expected_real,
                    dut_real,
                    rel_error * 100.0
                );

            end

        end

    endtask


    // ============================================================
    // MAIN TEST
    // ============================================================

    initial
    begin

        pass_count = 0;
        fail_count = 0;

        max_error = 0.0;
        max_error_input = 0.0;


        $display("");
        $display("==============================================");
        $display("     RECIPROCAL UNIT - ACCURACY TESTBENCH");
        $display("==============================================");
        $display("");

        $display("Tolerance = 0.5%%");
        $display("");


        // ========================================================
        // POWERS OF TWO
        // ========================================================

        test_reciprocal(32'h3F000000, 0.005); // 0.5
        test_reciprocal(32'h3F800000, 0.005); // 1
        test_reciprocal(32'h40000000, 0.005); // 2
        test_reciprocal(32'h40800000, 0.005); // 4
        test_reciprocal(32'h41000000, 0.005); // 8
        test_reciprocal(32'h41800000, 0.005); // 16
        test_reciprocal(32'h42000000, 0.005); // 32


        // ========================================================
        // NON-POWER-OF-TWO
        // ========================================================

        test_reciprocal(32'h40400000, 0.005); // 3
        test_reciprocal(32'h40A00000, 0.005); // 5
        test_reciprocal(32'h40E00000, 0.005); // 7
        test_reciprocal(32'h41200000, 0.005); // 10
        test_reciprocal(32'h41400000, 0.005); // 12
        test_reciprocal(32'h41C80000, 0.005); // 25
        test_reciprocal(32'h42200000, 0.005); // 40


        // ========================================================
        // FRACTIONAL VALUES
        // ========================================================

        test_reciprocal(32'h3F400000, 0.005); // 0.75
        test_reciprocal(32'h3F600000, 0.005); // 0.875
        test_reciprocal(32'h3FC00000, 0.005); // 1.5
        test_reciprocal(32'h3FE00000, 0.005); // 1.75


        // ========================================================
        // SUMMARY
        // ========================================================

        $display("");
        $display("==============================================");
        $display("                TEST SUMMARY");
        $display("==============================================");

        $display("PASS COUNT       = %0d", pass_count);
        $display("FAIL COUNT       = %0d", fail_count);

        $display(
            "MAX RELATIVE ERR = %f%%",
            max_error * 100.0
        );

        $display(
            "WORST INPUT      = %f",
            max_error_input
        );

        $display("");

        if (fail_count == 0)
            $display("OVERALL RESULT : PASS");
        else
            $display("OVERALL RESULT : FAIL");

        $display("");

        $display("==============================================");
        $display("       RECIPROCAL ACCURACY TEST COMPLETE");
        $display("==============================================");

        $finish;

    end

endmodule