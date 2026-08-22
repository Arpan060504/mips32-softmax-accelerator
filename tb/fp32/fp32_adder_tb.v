module fp32_adder_tb;

reg  [31:0] a;
reg  [31:0] b;
wire [31:0] result;

fp32_adder dut ( .a(a), .b(b), .result(result));

integer error_count;

task check;
    input [31:0] A;
    input [31:0] B;
    input [31:0] expected;
    begin
        a = A;
        b = B;
        #1;

        if (result == expected)
            $display("PASS | A=%h B=%h RESULT=%h",A, B, result);
        else
            begin
            error_count = error_count + 1;
            $display("FAIL | A=%h B=%h EXPECTED=%h OBSERVED=%h",A, B, expected, result);
            end
    end
endtask

initial 
begin
    error_count = 0;
    $display("--------------------------------");
    $display("FP32 ADDER TEST");
    $display("--------------------------------");

    check(32'h3FC00000, 32'h40100000, 32'h40700000); // 1.5 + 2.25
    check(32'h3F800000, 32'h3F800000, 32'h40000000); // 1.0 + 1.0
    check(32'h40000000, 32'h40400000, 32'h40A00000); // 2.0 + 3.0

    check(32'h40100000, 32'hBFC00000, 32'h3F400000); // 2.25 - 1.5
    check(32'h3FC00000, 32'hC0100000, 32'hBF400000); // 1.5 - 2.25

    // 1.0 + (-1.0)
    check(32'h3F800000, 32'hBF800000, 32'h00000000);
    // 2.5 + (-2.5)
    check(32'h40200000, 32'hC0200000, 32'h00000000);
    
    $display("--------------------------------");
    if (error_count == 0)
        $display("ALL FP32 ADD/SUB TESTS PASSED");
    else
        $display("FP32 ADD/SUB FAILED: %0d errors", error_count);

    $display("--------------------------------");
    $finish;
end

initial
    begin
        $dumpfile("dut.vcd");
        $dumpvars(0 , fp32_adder_tb);
        $monitor("Time = %0t | A : %h  , B : %h  , Result : %h" , $time  , a , b  , result);
    end
endmodule