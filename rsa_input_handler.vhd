library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity rsa_input_handler is
     generic(
          C_block_size : integer := 256;
          C_status_size : integer := 32;
          C_msg_id_size : integer := 4;
          C_CORE_CNT : integer := 15
     );
     port(
        -----------------------------------------------------------------------------
		-- Clocks and reset
		-----------------------------------------------------------------------------
		clk                    :  in std_logic;
		reset_n                :  in std_logic;

		-----------------------------------------------------------------------------
		-- Slave msgin interface
		-----------------------------------------------------------------------------
		-- Message that will be sent out is valid
		msgin_valid             : in std_logic;
		-- Slave ready to accept a new message
		msgin_ready             : out std_logic;
		-- Message that will be sent out of the rsa_msgin module
		msgin_data              :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		-- Indicates boundary of last packet
		msgin_last              :  in std_logic;

          -----------------------------------------------------------------------------
		-- Output handler communication
		-----------------------------------------------------------------------------
          h_core_id 		    : out std_logic_vector(C_msg_id_size-1 downto 0);
          -- Indicates boundary of last packet
		h_msgin_last          : out std_logic;
		-- input
		core_id_recieved	    : in std_logic;
		-- Signal indicating to output handler a core has been started
     	core_id_sent		    : out std_logic;

		-----------------------------------------------------------------------------
		-- Core interface
		-----------------------------------------------------------------------------
		-- Message that will be sent out is valid 
		il_msgin_valid           : out std_logic_vector(C_CORE_CNT-1 downto 0); -- valid_in
		-- Slave ready to accept a new message
		il_msgin_ready           :  in std_logic_vector(C_CORE_CNT-1 downto 0); -- ready_in
		-- Message that will be sent out of the rsa_msgin module
		il_msgout_data           : out std_logic_vector(C_BLOCK_SIZE-1 downto 0); -- message
		-- key_e_d
		key 					: out STD_LOGIC_VECTOR ( C_block_size-1 downto 0 );
		-- key_n
		modulus 				: out STD_LOGIC_VECTOR(C_block_size-1 downto 0);

		-----------------------------------------------------------------------------
		-- Interface to the register block
		-----------------------------------------------------------------------------
		key_e_d                  :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0); -- key
		key_n                    :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0) -- modulus
          -- 
		-- Description...
		--input_handler_rsa_status : out std_logic_vector((C_status_size/2)-1 downto 0)
     );
end entity;

-- Functional code (not tested) (without com to out handler)
-- ######################################
architecture rtl of rsa_input_handler is
    -------------------------------------------------------------------------------
    -- Internal signal declaration
    -------------------------------------------------------------------------------
    -- should not be nessecary with internal signal for core id: 
    signal internal_core_id : std_logic_vector(C_msg_id_size-1 downto 0) := (others => '0');
	-- Used for several diff things. 
	signal curr_core_bm : std_logic_vector(C_CORE_CNT-1 downto 0) := '1' & (others => '0');
	signal curr_core_ready : std_logic := '0';

	signal save_core_id_recieved : std_logic := '0';

	signal msgin_data_register : std_logic_vector := (others => '0');

	-- Initialization of state machine for input handler
	type state is (IDLE, CORE_FOUND, LOAD_CORE, OUT_H_COM);
	signal curr_state, next_state : state;

---------------------------------------------------------------------
-- Begin architecture
---------------------------------------------------------------------
begin

---------------------------------------------------------------------
-- Throughput signals to cores
---------------------------------------------------------------------
key <= key_e_d;
modulus <= key_n;
il_msgout_data <= msgin_data_register;

---------------------------------------------------------------------
-- Throughput signals to output handler
---------------------------------------------------------------------
h_msgin_last <= msgin_last;

---------------------------------------------------------------------
-- Proces for handling actions in each state
---------------------------------------------------------------------
p_core_handler : process (curr_state)
begin
	case (curr_state) is
		when IDLE =>
               --
			if (il_msgin_ready(to_integer(internal_core_id)) = '1') then
				internal_core_id <= internal_core_id;
				curr_core_ready <= '1';
			else
				internal_core_id <= std_logic_vector(to_unsigned(internal_core_id) + 1);
				curr_core_ready <= '0';
			end if;
			msgin_ready <= '0';
			il_msgin_valid <= (others => '0');
		when CORE_FOUND =>
			-- no action needed just waiting for msgin valid from outside
			msgin_ready <= '1';
			il_msgin_valid <= (others => '0');
          when LOAD_CORE => 
               -- 
			msgin_ready <= '1';
			-- The line under this set msgin_valid for current core selected
			il_msgin_valid(to_integer(internal_core_id)) <= '1';

		when OUT_H_COM =>
			-- no longer loading into core when sending
			msgin_ready <= '0';
			il_msgin_valid <= (others => '0');
          when others => 
			msgin_ready <= '0';
               il_msgin_valid <= (others => '0');
     end case;
end process;


---------------------------------------------------------------------
-- State machine for core handling states
---------------------------------------------------------------------
sm_core_handler : process (all)
begin
	case (curr_state) is
		when IDLE =>
               if ((curr_core_ready = '1')) then
			    	next_state <= CORE_FOUND;
               else
               	next_state <= IDLE;
               end if;
          when CORE_FOUND => 
               if ((msgin_valid = '1')) then
                   	next_state <= LOAD_CORE;
				msgin_data_register <= msgin_data;
               else
                   next_state <= CORE_FOUND;
               end if;
		when LOAD_CORE => 
			if (il_msgin_ready(to_integer(h_core_id)) = '0') then
                   next_state <= OUT_H_COM;
               else
                   next_state <= LOAD_CORE;
               end if;
		when OUT_H_COM => 
			if (core_id_recieved = '1') then
                   next_state <= IDLE;
               else
                   next_state <= OUT_H_COM;
               end if;
          when others =>
               next_state <= IDLE;
     end case;
end process;


-------------------------------------------------------------------------------
-- Update state on rising edge
-------------------------------------------------------------------------------
process(clk, reset_n)
begin
    	if (reset_n = '0') then
        	curr_state <= IDLE;
    	else 
        	if (clk'event and clk = '1') then
            	curr_state <= next_state;
        	end if;
    	end if;
end process;
-- ###################################

p_core_ID_to_bm : process (h_core_id)
begin

end process;

end architecture;
