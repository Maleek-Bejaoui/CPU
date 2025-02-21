

module boot_loader #(  
    parameter RAM_ADR_WIDTH = 6,  
    parameter RAM_SIZE = 64  
)(  
    input wire rst,  
    input wire clk,  
    input wire ce,  
    input wire rx,  
    output wire tx,  
    output reg boot,  
    input wire scan_memory,  
    input wire [15:0] ram_out,  
    output reg ram_rw,  
    output reg ram_enable,  
    output reg [RAM_ADR_WIDTH-1:0] ram_adr,  
    output reg [15:0] ram_in  
);

// Internal signals
wire [7:0] rx_byte, tx_byte;
reg rx_data_valid, tx_data_valid, tx_word_valid, rx_word_valid;
reg [1:0] byte_count;
reg [RAM_ADR_WIDTH-1:0] rx_byte_count;
reg enable_rx_byte_counter, init_byte_counter;
reg [14:0] tx_cycle_count;
reg init_tx_cycle_count, tx_cycle_count_over;

// State machine states
/*typedef enum logic [3:0] {
    INIT, WAIT_RX_BYTE, INCR_RX_BYTE_COUNTER, WRITE_RX_BYTE,
    WAIT_SCAN_MEM, READ_TX_BYTE, INCR_TX_BYTE_COUNTER,
    ENABLE_TX, WAIT_8K_CYCLE, OVER
} state_t;

state_t current_state, future_state; */
// Define state encoding

parameter [3:0] 
    INIT = 4'b0000,
    WAIT_RX_BYTE = 4'b0001,
    INCR_RX_BYTE_COUNTER = 4'b0010,
    WRITE_RX_BYTE = 4'b0011,
    WAIT_SCAN_MEM = 4'b0100,
    READ_TX_BYTE = 4'b0101,
    INCR_TX_BYTE_COUNTER = 4'b0110,
    ENABLE_TX = 4'b0111,
    WAIT_8K_CYCLE = 4'b1000,
    OVER = 4'b1001;

// Declare state registers
reg [3:0] current_state, future_state;


/* verilator lint_off PINMISSING */

// Instantiating UART receiver
UART_recv uart_recv_inst (
    .clk(clk), .reset(rst), .rx(rx), .dat(rx_byte), .dat_en(rx_data_valid)
);

// Instantiating byte to word converter
byte_2_word b2w_inst (
    .rst(rst), .clk(clk), .ce(ce),
    .byte_dv(rx_data_valid), .byteee(rx_byte),
    .word_dv(rx_word_valid), .word(ram_in)
);

// Instantiating word to byteee converter
word_2_byte w2b_inst (
    .rst(rst), .clk(clk), .ce(ce),
    .word_dv(tx_data_valid), .word(ram_out),
    .byte_dv(tx_word_valid), .byteee(tx_byte)
);

// Instantiating UART transmitter
UART_fifoed_send uart_send_inst (
    .clk_100MHz(clk), .reset(rst),
    .dat_en(tx_word_valid), .dat(tx_byte),
    .TX(tx)
);

// RX Byte Counter Process
always @(posedge clk or posedge rst) begin
    if (rst) 
        rx_byte_count <= 0;
    else if (ce) begin
        if (init_byte_counter)
            rx_byte_count <= 0;
        else if (enable_rx_byte_counter)
            rx_byte_count <= (rx_byte_count == RAM_SIZE - 1) ? 0 : rx_byte_count + 1;
    end
end

// TX Cycle Counter Process
always @(posedge clk or posedge rst) begin
    if (rst) begin
        tx_cycle_count <= 0;
        tx_cycle_count_over <= 0;
    end else if (ce) begin
        if (init_tx_cycle_count) begin
            tx_cycle_count <= 0;
            tx_cycle_count_over <= 0;
        end else if (tx_cycle_count == 18000) begin
            tx_cycle_count_over <= 1;
            tx_cycle_count <= 0;
        end else begin
            tx_cycle_count <= tx_cycle_count + 1;
            tx_cycle_count_over <= 0;
        end
    end
end

// FSM State Register
always @(posedge clk or posedge rst) begin
    if (rst)
        current_state <= INIT;
    else if (ce)
        current_state <= future_state;
end

// FSM Next State Logic
always @* begin
    case (current_state)
        INIT: future_state = WAIT_RX_BYTE;
        WAIT_RX_BYTE: future_state = (rx_word_valid) ? WRITE_RX_BYTE : WAIT_RX_BYTE;
        WRITE_RX_BYTE: future_state = (rx_byte_count == RAM_SIZE - 1) ? WAIT_SCAN_MEM : INCR_RX_BYTE_COUNTER;
        INCR_RX_BYTE_COUNTER: future_state = WAIT_RX_BYTE;
        WAIT_SCAN_MEM: future_state = (scan_memory) ? READ_TX_BYTE : WAIT_SCAN_MEM;
        READ_TX_BYTE: future_state = ENABLE_TX;
        ENABLE_TX: future_state = (rx_byte_count == RAM_SIZE - 1) ? OVER : INCR_TX_BYTE_COUNTER;
        INCR_TX_BYTE_COUNTER: future_state = WAIT_8K_CYCLE;
        WAIT_8K_CYCLE: future_state = (tx_cycle_count_over) ? READ_TX_BYTE : WAIT_8K_CYCLE;
        OVER: future_state = OVER;
    endcase
end

// FSM Output Logic
always @* begin
    case (current_state)
        INIT: begin
         ram_rw = 0;
          ram_enable = 1;
           tx_data_valid = 0;
            enable_rx_byte_counter = 0;
             boot = 1; init_byte_counter = 1; init_tx_cycle_count = 1; 
         end
        WAIT_RX_BYTE: begin ram_rw = 0; ram_enable = 1; tx_data_valid = 0; enable_rx_byte_counter = 0; boot = 1; init_byte_counter = 0; init_tx_cycle_count = 1; end
        WRITE_RX_BYTE: begin ram_rw = 1; ram_enable = 1; tx_data_valid = 0; enable_rx_byte_counter = 0; boot = 1; init_byte_counter = 0; init_tx_cycle_count = 1; end
        INCR_RX_BYTE_COUNTER: begin ram_rw = 0; ram_enable = 1; tx_data_valid = 0; enable_rx_byte_counter = 1; boot = 1; init_byte_counter = 0; init_tx_cycle_count = 1; end
        WAIT_SCAN_MEM: begin ram_rw = 0; ram_enable = 1; tx_data_valid = 0; enable_rx_byte_counter = 0; boot = 0; init_byte_counter = 1; init_tx_cycle_count = 1; end
        READ_TX_BYTE: begin ram_rw = 0; ram_enable = 1; tx_data_valid = 0; enable_rx_byte_counter = 0; boot = 1; init_byte_counter = 0; init_tx_cycle_count = 1; end
        ENABLE_TX: begin ram_rw = 0; ram_enable = 1; tx_data_valid = 1; enable_rx_byte_counter = 0; boot = 1; init_byte_counter = 0; init_tx_cycle_count = 1; end
        INCR_TX_BYTE_COUNTER: begin ram_rw = 0; ram_enable = 1; tx_data_valid = 0; enable_rx_byte_counter = 1; boot = 1; init_byte_counter = 0; init_tx_cycle_count = 1; end
        WAIT_8K_CYCLE: begin ram_rw = 0; ram_enable = 1; tx_data_valid = 0; enable_rx_byte_counter = 0; boot = 1; init_byte_counter = 0; init_tx_cycle_count = 0; end
        OVER: begin ram_rw = 0; ram_enable = 1; tx_data_valid = 0; enable_rx_byte_counter = 0; boot = 0; init_byte_counter = 0; init_tx_cycle_count = 1; end
    endcase
end

endmodule
