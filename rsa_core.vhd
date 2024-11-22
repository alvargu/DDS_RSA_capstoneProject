library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity rsa_core is
     generic(
          C_BLOCK_SIZE            : integer := 256;
          C_STATUS_SIZE           : integer := 32;
          C_CORE_CNT              : integer := 16
     );
     port(
        -----------------------------------------------------------------------------
		-- Clocks and reset
		-----------------------------------------------------------------------------
		clk                       :   in  std_logic;
		reset_n                   :   in  std_logic;

		-----------------------------------------------------------------------------
		-- Slave msgin interface
		-----------------------------------------------------------------------------
		-- Message that will be sent out is valid
		msgin_valid               :   in  std_logic;
		-- Slave ready to accept a new message
		msgin_ready               :   out std_logic;
		-- Message that will be sent out of the rsa_msgin module
		msgin_data                :   in  std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		-- Indicates boundary of last packet
		msgin_last                :   in  std_logic;

		-----------------------------------------------------------------------------
		-- Master msgout interface
		-----------------------------------------------------------------------------
		-- Message that will be sent out is valid
		msgout_valid              :   out std_logic;
		-- Slave ready to accept a new message
		msgout_ready              :   in  std_logic;
		-- Message that will be sent out of the rsa_msgin module
		msgout_data               :   out std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		-- Indicates boundary of last packet
		msgout_last               :   out std_logic;

		-----------------------------------------------------------------------------
		-- Interface to the register block
		-----------------------------------------------------------------------------
		key_e_d                   :   in  std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		key_n                     :   in  std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		rsa_status                :   out std_logic_vector(31 downto 0)
     );
end entity;

architecture rtl of rsa_core is

	component exponentiation
		port (
			start        : in    std_logic;
			done         : out   std_logic;
	
			--input data
			message 	: in     STD_LOGIC_VECTOR (C_BLOCK_SIZE-1 downto 0 );
			key 		: in     STD_LOGIC_VECTOR (C_BLOCK_SIZE-1 downto 0 );
	
			--output data
			result 		: out    STD_LOGIC_VECTOR(C_BLOCK_SIZE-1 downto 0);
	
			--modulus
			modulus 	: in     STD_LOGIC_VECTOR(C_BLOCK_SIZE-1 downto 0);
	
			--utility
			clk 		: in     STD_LOGIC;
			reset_n 	: in     STD_LOGIC
		);
	end component;

    --Register for when its possible to send the data to the core and when its done with processing
    signal il_core_busy         : std_logic_vector(C_CORE_CNT-1     downto 0);
    signal il_core_done         : std_logic_vector(C_CORE_CNT-1     downto 0);
    signal il_core_extract      : std_logic_vector(C_CORE_CNT-1     downto 0);
    signal il_core_start        : std_logic_vector(C_CORE_CNT-1     downto 0);
    signal il_core_last_msg     : std_logic_vector(C_CORE_CNT-1     downto 0);
    
    signal c_core_last_msg      : integer range 0 to C_CORE_CNT-1;
    
    signal il_core_reset        : std_logic_vector(C_CORE_CNT-1     downto 0);
    
    type O_FSM is (READ_CORE, SEND_DATA, RESET_CORE);
    signal output_c_state, nx_output_state: O_FSM;
    
    type I_FSM is (IDLE, CORE_RDY, LOAD_CORE);
    signal input_c_state, nx_input_state: I_FSM;
    
    signal output_cursor, nx_cursor: integer range 0 to C_CORE_CNT-1;
    signal input_cursor,  nx_i_cursor: integer range 0 to C_CORE_CNT-1;
    
    type core_handler is array (C_CORE_CNT-1 downto 0) of std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    signal core_out : core_handler;
    
begin

    core_gen: for core_nr in 0 to C_CORE_CNT-1 generate --15 for max
        MULTI_EXPO: entity work.exponentiation
            generic map (
                C_BLOCK_SIZE            => C_BLOCK_SIZE
            )
            port map (
                -- MAPPING of INPUT HANDLER
                
                message                 => msgin_data,
                key                     => key_e_d,
                modulus                 => key_n,
                start                   => il_core_start(core_nr),
                
                -- MAPPING OF OUTPUT HANDLER
                
                c_core_reset            => il_core_reset(core_nr),
                c_core_done             => il_core_done(core_nr),
                c_core_is_busy          => il_core_busy(core_nr),
                c_core_extract          => il_core_extract(core_nr),
                result                  => core_out(core_nr),
                
                -- MAPPING OF MISC.
                clk                     => clk,
                reset_n                 => reset_n
            );
    end generate;

    OUTPUT_FSM_UPDATE: process(clk, reset_n)
    begin
        if reset_n = '0' then
            output_c_state     <= READ_CORE;
            output_cursor      <= 0;
        elsif rising_edge(clk) then
            output_c_state     <= nx_output_state;
            output_cursor      <= nx_cursor;
        end if;
    end process;
    
    OUTPUT_LOGIC: process(all)
    begin
    
        msgout_valid <= '0';
        msgout_last <= '0';
        msgout_data <= (others => '0');
        
        nx_output_state <= output_c_state;
        nx_cursor <= output_cursor;
        
        il_core_reset <= (others => '0');
    
        case output_c_state is
            when READ_CORE  =>  if(il_core_done(output_cursor)) then
                                    nx_output_state <= SEND_DATA;
                                end if;
            
            when SEND_DATA  =>  if(msgout_ready = '1') then
                                    msgout_data <= core_out(output_cursor);
                                    msgout_last <= il_core_last_msg(output_cursor);
                                    msgout_valid <= '1'; 
            
                                    if(output_cursor >= (C_CORE_CNT-1)) then
                                        nx_cursor <= 0;
                                    else
                                        nx_cursor <= output_cursor + 1;
                                    end if;
                                
                                    il_core_reset(output_cursor) <= '1'; 
                                    
                                    nx_output_state <= READ_CORE;
                                end if;
            
            when RESET_CORE =>  null;
                                
            
            when OTHERS     => nx_output_state <= READ_CORE;
        end case;
    end process;

/*
    RSA_OUTPUT_HANDLER: entity work.rsa_output_handler
        generic map (
            C_BLOCK_SIZE    => C_BLOCK_SIZE,
            C_CORE_CNT      => C_CORE_CNT
        )
        port map (
            c_core_is_done              => il_core_done,
            c_core_extract              => il_core_extract,
            c_core_data                 => il_core_data,
            c_core_last_msg             => il_core_last_msg,
            
            h_msgout_ready              => msgout_ready,
            h_msgout_valid              => msgout_valid,
            h_msgout_last               => msgout_last,
            h_msgout_data               => msgout_data,
            
            -- Status Register
            h_output_rsa_status         => rsa_status(15 downto 0),
            
            -- Misc.
            clk                         => clk,
            reset_n                     => reset_n
        );
*/

    INPUT_STATE: process(clk, reset_n)
    begin
        if reset_n = '0' then
            input_c_state       <= IDLE;
            input_cursor <= 0;
        elsif rising_edge(clk) then
            input_cursor        <= nx_i_cursor;
            input_c_state       <= nx_input_state;
        end if;
    end process;


    INPUT_LOGIC: process(all)
    begin
        nx_input_state <= input_c_state;
        msgin_ready <= '0';
        il_core_start <= (others => '0');
        
        
        case input_c_state is
            when IDLE       =>  if (msgin_valid = '1') then
                                    nx_input_state <= CORE_RDY;
                                end if;
                                
            
            when CORE_RDY   =>  if (il_core_busy(input_cursor) = '0') then
                                    il_core_start(input_cursor) <= '1';
                                end if;
                                
                                il_core_last_msg(input_cursor) <= msgin_last;
                                
                                nx_input_state <= LOAD_CORE;
                                
                                --Deal with core cursor
                                if(input_cursor >= (C_CORE_CNT-1)) then
                                    nx_i_cursor <= 0;
                                else
                                    nx_i_cursor <= input_cursor + 1;
                                end if;
            
            when LOAD_CORE  =>  if(il_core_busy(input_cursor) = '0') then
                                    msgin_ready <= '1';
                                    nx_input_state <= IDLE;
                                end if;
                                
            when OTHERS => nx_input_state <= IDLE;
        end case;
    
    end process;

/*
    RSA_INPUT_HANDLER: entity work.rsa_input_handler
        generic map(
            C_CORE_CNT    => C_CORE_CNT
        )
        port map (
            msgin_valid                 => msgin_valid,
            msgin_ready                 => msgin_ready,
            msgin_last                  => msgin_last,
            
            il_msgin_valid              => il_core_start,
            il_msgin_ready              => il_core_busy,
            h_last_msg                  => il_core_last_msg,
        
            clk                         => clk,
            reset_n                     => reset_n
        );
*/
end;
