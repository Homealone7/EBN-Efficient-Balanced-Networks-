`timescale 1ns/1ns
module EBN_tb;
    parameter N                 = 64;
    parameter Dims              = 2;
    parameter NzMemb            = 40'h 68DB8;
    parameter Gain_D            = 40'h 2000000;
    parameter K                 = 40'h 20C49B;
    parameter LambdaV           = 40'h 3200000000;
    parameter Lambda            = 40'h A00000000;
    parameter dyn               = 40'h 800000000;
    parameter One               = 40'h 100000000;
    parameter Three             = 40'h 300000000;
    parameter Eta_W             = 40'h 4CCCCCCC; //learning rate
    parameter dt                = 40'h 68DB8;
    parameter learn             = 1006;
    parameter learn_flg         = 1;
    parameter INTEGER_BITS      = 8;
    parameter FRACTIONAL_BITS   = 32;
    parameter A_ROWS            = 1;
    parameter B_COLS            = 1;

    integer counter = 0, l = 2, count_done = 0, count_it = 1;
    logic                                                 clk;
    logic                                                 reset;
    logic                                                 start_neuron;
    logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0]  x0;
    logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0]  x1;
    logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0]  x0est, x1est;
    logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0]  err0, err1;
    logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0]  i_dec      [Dims * N];
    logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0]  i_wf       [N * N];
    logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0]  i_cmd_tmp  [Dims * 15000];
    logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0]  pot_thr    [N];
    logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0]  randn      [N];
    logic                                                 done;
    logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] temp_weights [N * N]; // Temporary storage for weights
    integer i = 0;
    integer file0, file1, file2, file3, file4, file5, file6;
    
    EBN #(
        .N(N),
        .Dims(Dims),
        .dyn(dyn),
        .NzMemb(NzMemb),
        .Gain_D(Gain_D),
        .K(K),
        .LambdaV(LambdaV),
        .Lambda(Lambda),
        .One(One),
        .Three(Three),
        .Eta_W(Eta_W),
        .dt(dt),
        .learn(learn),
        .learn_flg(learn_flg),
        .INTEGER_BITS(INTEGER_BITS),
        .FRACTIONAL_BITS(FRACTIONAL_BITS),
        .A_ROWS(A_ROWS),
        .B_COLS(B_COLS)
    )EBN(
        .clk(clk),
        .start_neuron(start_neuron),
        .reset(reset),
        .i_dec(i_dec),
        .i_wf(i_wf),
        .pot_thr(pot_thr),
        .randn(randn),
        .done(done)
    );

    always begin
        #5 clk = ~clk; 
    end

    always_ff @(posedge clk) begin
        counter <= counter + 1;
        if (EBN.done_dyn) begin
            count_done <= count_done + 1;
            $display("Completed Cycles: %0d", count_done); // Display the counter
        end
        if (EBN.Neuron.done_spike) begin
            if (l >= 29998) begin
                l <= 0;
                count_it <= count_it + 1;
                $display("Iteration Count: %0d", count_it); // Display the counter
            end
            else begin 
                l <= l + 2; 
                EBN.i_cmd[0] <= i_cmd_tmp[l];
                EBN.i_cmd[1] <= i_cmd_tmp[l + 1];
            end
        end
    end

    initial begin
        clk = 0;
        start_neuron = 0;
        reset = 1;
        $readmemb("Wf_f.txt", i_wf);
        $readmemb("dec_f.txt", i_dec);
        $readmemb("cmd_f.txt", i_cmd_tmp);
        $readmemb("ran_f.txt", randn);
        $readmemb("thres_f.txt", pot_thr);              
        #10
        reset = 0;
        start_neuron = 1;   
        // Main loop for handling iterations and reset
        while (count_it <= 3) begin
            @(posedge EBN.Neuron.done_spike); // Wait for spike completion
            if (l >= 29998) begin
                // Store the current weights before reset
                for (int i = 0; i < N * N; i++) begin
                    temp_weights[i] = EBN.synaptic_core.Synaptic_Memory.mem[i];
                end
                $display("Weights Stored");
                // Assert reset
                reset = 1;
                $readmemb("Wf_f.txt", i_wf);
                $readmemb("dec_f.txt", i_dec);
                $readmemb("cmd_f.txt", i_cmd_tmp);
                $readmemb("ran_f.txt", randn);
                $readmemb("thres_f.txt", pot_thr);  
                #10;
                reset = 0;
                $display("Reset Complete");
                // Restore the weights after reset
                for (int i = 0; i < N * N; i++) begin
                    EBN.synaptic_core.Synaptic_Memory.mem[i] = temp_weights[i];
                end
                $display("Weights Retored");
            end 
        end
        $display("Simulation completed after 100 iterations.");
        $finish;
    end

endmodule

/*EBN.Dynamic.i_x[0] = -x0;
        EBN.Dynamic.i_x[1] = -x1;
        EBN.Dynamic.i_x_est[0] = -x0est;
        EBN.Dynamic.i_x_est[1] = -x1est;
        EBN.Dynamic.o_x[0] = -x0;
        EBN.Dynamic.o_x[1] = -x1;
        EBN.Dynamic.o_x_est[0] = -x0est;
        EBN.Dynamic.o_x_est[1] = -x1est;
        $readmemb("V_f.txt", EBN.Neuron.Neuron_Memory.mem);
        $readmemb("rO_f.txt", EBN.spike_f_data);


        $readmemb("W_S.txt", EBN.synaptic_core.Synaptic_Memory.mem);
        file0 = $fopen("Potential_G.txt", "w");
        file1 = $fopen("Spikes_G.txt", "w");
        file2 = $fopen("Spike_Filter_G.txt", "w");
        file3 = $fopen("Desired_X_G.txt", "w");
        file4 = $fopen("Est_X_G.txt", "w");
        file5 = $fopen("Error_G.txt", "w");
        #634050225
        $fclose(file0);
        $fclose(file1);
        $fclose(file2);
        $fclose(file3);
        $fclose(file4);
        $fclose(file5);
        */
        
        /*always_ff @(posedge clk) begin
        if (EBN.Neuron.done_lif_AU) begin
            $fwrite(file0, "%b\n", EBN.Neuron.o_pot);
        end
        if (EBN.Neuron.done_spike) begin
            for (i = 0; i < 64; i++) begin
                $fwrite(file1, "%b\n", EBN.Neuron.spike_tmp[i]);
            end
        end
        if (EBN.done_spike_f_buff) begin
            for (i = 0; i < 64; i++) begin
                $fwrite(file2, "%b\n", EBN.spike_f_data[i]);
            end
        end
        if (EBN.done_dyn) begin
            $fwrite(file3, "%b\n", EBN.Dynamic.o_x[0]);
            $fwrite(file3, "%b\n", EBN.Dynamic.o_x[1]);
        end
        if (EBN.done_dyn) begin
            $fwrite(file4, "%b\n", EBN.Dynamic.o_x_est[0]);
            $fwrite(file4, "%b\n", EBN.Dynamic.o_x_est[1]);
        end
        if (EBN.done_dyn) begin
            $fwrite(file5, "%b\n", EBN.Dynamic.o_err[0]);
            $fwrite(file5, "%b\n", EBN.Dynamic.o_err[1]);
        end
    end*/