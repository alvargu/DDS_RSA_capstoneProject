library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity rsa_output_handler is
    generic(
        C_BLOCK_SIZE            :   integer := 256;
        C_STATUS_SIZE           :   integer := 32;
        C_CORE_CNT              :   integer := 16
    );
    
    port(
        c_core_is_done              : in    std_logic_vector(C_CORE_CNT-1 downto 0);
        c_core_extract              : out   std_logic_vector(C_CORE_CNT-1 downto 0);
        c_core_reset                : out   std_logic_vector(C_CORE_CNT-1 downto 0);
        c_core_last_msg             : in    std_logic_vector(C_CORE_CNT-1 downto 0);
        
        c_core_data                 : in    std_logic_vector(C_BLOCK_SIZE-1 downto 0);
        
        h_msgout_ready              : in    std_logic;
        h_msgout_data               : out   std_logic_vector(C_BLOCK_SIZE-1 downto 0);
        h_msgout_last               : out   std_logic;
        h_msgout_valid              : out   std_logic;
        
        h_output_rsa_status         : out   std_logic_vector(C_STATUS_SIZE/2-1 downto 0);
        clk                         : in    std_logic;
        reset_n                     : in    std_logic
    );
end rsa_output_handler;

architecture rtl of rsa_output_handler is
    -- Cursor to iterate over the cores
    signal core_cursor          : integer range 0 to C_CORE_CNT-1 := 0;

    -- Simple state machine to controll the output from the rsa_core
    type O_FSM is (
        READ_CORE,
        SEND_DATA
    );
    
    signal c_state, nx_state : O_FSM;

begin

    State_Transfer_And_Reset: process(clk, reset_n)
    begin
        if reset_n = '0' then
            core_cursor         <= 0;
            c_state             <= READ_CORE;
            h_output_rsa_status <= (others => '0');
        elsif rising_edge(clk) then
            c_state             <= nx_state;
            
        end if;
    end process;
    
    State_Code: process(all)
    begin
        -- If the transit case did not trigger stay in the same state
        nx_state <= c_state;
        
        -- Reset the registers for next iteration
        h_msgout_data   <= (others => '0');
        h_msgout_valid  <= '0';
        h_msgout_last   <= '0';
        
        -- In order to not interfere with other cores always reset these 2 registers
        c_core_extract  <= (others => '0');
        c_core_reset    <= (others => '0');
        
        case c_state is         -- Check if the core is done with processing data
            when READ_CORE  =>  if (c_core_is_done(core_cursor) = '1') then
                                    -- Set next state to DATA_SEND
                                    nx_state <= SEND_DATA; 
                                    -- Signal the core to output data to the bus
                                    c_core_extract(core_cursor) <= '1';
                                end if;
            
                                -- Check if it is possible to output the msg
            when SEND_DATA  =>  if (h_msgout_ready = '1') then
                                    -- Output data from the core
                                    h_msgout_data   <= c_core_data;
                                    
                                    -- Mark data as valid
                                    h_msgout_valid  <= '1';
                                    
                                    -- Signal the core to reset
                                    c_core_reset(core_cursor) <= '1';
                                    
                                    -- Increment or Reset the cursor
                                    if (core_cursor >= C_CORE_CNT-1) then
                                        core_cursor <= 0;
                                    else
                                        core_cursor <= core_cursor + 1;
                                    end if;
                                    
                                    -- Set next state to read next core
                                    nx_state <= READ_CORE;
                                end if;
        end case;
    end process;
end architecture;
