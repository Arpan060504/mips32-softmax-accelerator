`timescale 1ns/1ps

module reciprocal_lut_tb;

    reg  [3:0]  lut_index;
    wire [31:0] reciprocal_estimate;

    // DUT
    reciprocal_lut dut (
        .lut_index(lut_index),
        .reciprocal_estimate(reciprocal_estimate)
    );

    task check_lut;
        input [3:0] index;
        input [31:0] expected;
        begin

            lut_index = index;
            #10;

            if (reciprocal_estimate === expected)
            begin
                $display("PASS : LUT[%0d] = %h", 
                         index, reciprocal_estimate);
            end
            else
            begin
                $display("FAIL : LUT[%0d] = %h | Expected = %h",
                         index,
                         reciprocal_estimate,
                         expected);
            end

        end
    endtask

    initial
    begin

        $display("==============================================");
        $display("       RECIPROCAL LUT TESTBENCH");
        $display("==============================================");
        $display("");

        check_lut(4'd0,  32'h3F783E10);
        check_lut(4'd1,  32'h3F6A0EA1);
        check_lut(4'd2,  32'h3F5D67C9);
        check_lut(4'd3,  32'h3F520D21);

        check_lut(4'd4,  32'h3F47CE0C);
        check_lut(4'd5,  32'h3F3E82FA);
        check_lut(4'd6,  32'h3F360B61);
        check_lut(4'd7,  32'h3F2E4C41);

        check_lut(4'd8,  32'h3F272F05);
        check_lut(4'd9,  32'h3F20A0A1);
        check_lut(4'd10, 32'h3F1A90E8);
        check_lut(4'd11, 32'h3F14F209);

        check_lut(4'd12, 32'h3F0FB824);
        check_lut(4'd13, 32'h3F0AD8F3);
        check_lut(4'd14, 32'h3F064B8A);
        check_lut(4'd15, 32'h3F020821);

        $display("");
        $display("==============================================");
        $display("       RECIPROCAL LUT TEST COMPLETE");
        $display("==============================================");

        $finish;
    end

endmodule