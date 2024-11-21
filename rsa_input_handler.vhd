library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
-- use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--#############################################################################
-- Entity I/O Definition
--#############################################################################
entity rsa_input_handler is
     generic(
          C_BLOCK_SIZE : integer := 256;
		-- Not using status register ATM
          --C_STATUS_SIZE : integer := 32;
          C_CORE_ID_SIZE : integer := 4;
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
		-- Commented signals do not need to go through input handler
		-- Indicates boundary of last packet
		--msgin_last              :  in std_logic;

          -----------------------------------------------------------------------------
		-- Output handler communication
		-----------------------------------------------------------------------------
		-- ID number of core used for rsa arithmetic operations sent to outputhandler
          h_core_id 		    : out std_logic_vector(C_CORE_ID_SIZE-1 downto 0);
		-- Flag signal from outputhandler to indicate that core id was recieved and stored
		h_core_id_recieved	    : in std_logic;
		-- Signal indicating to output handler a core has been started
     	h_core_id_sent		    : out std_logic;
		-- Commented signals do not need to go through input handler
          -- Indicates boundary of last packet and is sent to 
		--h_msgin_last          : out std_logic;
		-----------------------------------------------------------------------------
		-- Core interface
		-----------------------------------------------------------------------------
		-- Message that will be sent out is valid 
		il_msgin_valid           : out std_logic_vector(C_CORE_CNT-1 downto 0); -- valid_in
		-- Slave ready to accept a new message
		il_msgin_ready           :  in std_logic_vector(C_CORE_CNT-1 downto 0); -- ready_in
		-- Message that will be sent out of the rsa_msgin module
		il_msgout_data           : out std_logic_vector(C_BLOCK_SIZE-1 downto 0) -- message
		-- Commented signals do not need to go through input handler
		-- key_e_d
		--key 					: out STD_LOGIC_VECTOR ( C_block_size-1 downto 0 );
		-- key_n
		--modulus 				: out STD_LOGIC_VECTOR(C_block_size-1 downto 0);

		-----------------------------------------------------------------------------
		-- Interface to the register block
		-----------------------------------------------------------------------------
		-- Commented signals do not need to go through input handler
		--key_e_d                  :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0); -- key
		--key_n                    :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0) -- modulus
          -- status register for input handler (if commented out it is not used) 
		-- Description...
		--input_handler_rsa_status : out std_logic_vector((C_status_size/2)-1 downto 0)
     );
end entity;

-- Functional code (not tested) (without com to out handler)
-- ######################################
architecture rtl of rsa_input_handler is
    	--########################################################################
    	-- Internal signal declaration
    	--########################################################################
	-- Signals for internal core logic:
    	-- internal_core_id should not be nessecary with internal signal for core id but is used for saftey: 
    	signal internal_core_id : std_logic_vector(C_CORE_ID_SIZE-1 downto 0) := (others => '0');
	-- Signal flag that indicates that the current core indicated by internal_core_id is ready to recieve
	signal curr_core_ready : std_logic := '0';
	-- constant to reset internal_core_id
	constant id_first_core : std_logic_vector(C_CORE_ID_SIZE-1 downto 0) := (0 => '1', others => '0');
	-- signal save_h_core_id_recieved : std_logic := '0';
	-- Register used to save value of msgin_data to load into cores
	signal msgin_data_register : std_logic_vector(C_BLOCK_SIZE-1 downto 0) := (others => '0');

	-- Initialization of state machine for input handler
	type state is (IDLE, CORE_FOUND, LOAD_CORE, OUT_H_COM);
	signal curr_state, next_state : state;

--#############################################################################
-- Begin architecture
--#############################################################################
begin

---------------------------------------------------------------------
-- Throughput signals to cores
---------------------------------------------------------------------
-- Commented signals do not need to go through input handler
--key <= key_e_d;
--modulus <= key_n;
il_msgout_data <= msgin_data_register;

---------------------------------------------------------------------
-- Throughput signals to output handler
---------------------------------------------------------------------
-- Commented signals do not need to go through input handler
--h_msgin_last <= msgin_last;
-- Core ID 
h_core_id <= internal_core_id;
p_core_id_outside_def : process (internal_core_id)
begin

end process;

--#############################################################################
-- Proces for handling actions in each state
--#############################################################################
p_core_handler : process (curr_state, il_msgin_ready, internal_core_id)
	--variable tmp_internal_core_id : std_logic_vector(C_CORE_ID_SIZE-1 downto 0) := (others)
begin
	-- Sett default values for h_core_id_sent, msgin_ready and il_msgin_valid
	h_core_id_sent <= '0';
	msgin_ready <= '0';
	il_msgin_valid <= (others => '0');
	-- Defining what actions to take in each state
	case (curr_state) is
		--###################################################################
		when IDLE =>
               --
			if (to_integer(unsigned(internal_core_id)) >= (C_CORE_CNT - 1)) then
				--tmp_internal_core_id := (others => '0');
				--tmp_internal_core_id(0) := '1';
				internal_core_id <= (0 => '1', others => '0');
			elsif (il_msgin_ready(to_integer(unsigned(internal_core_id))) = '1') then
				internal_core_id <= internal_core_id;
				curr_core_ready <= '1';
			else
				internal_core_id <= std_logic_vector(unsigned(internal_core_id) + 1);
				curr_core_ready <= '0';
			end if;
			msgin_ready <= '0';
			il_msgin_valid <= (others => '0');
		--###################################################################
		when CORE_FOUND =>
			-- no action needed just waiting for msgin valid from outside
			msgin_ready <= '1';
			il_msgin_valid <= (others => '0');
          --###################################################################
		when LOAD_CORE => 
               -- 
			msgin_ready <= '1';
			-- The line under this set msgin_valid for current core selected
			il_msgin_valid(to_integer(unsigned(internal_core_id))) <= '1';

		--###################################################################
		when OUT_H_COM =>
			-- indicate to output handler that core with current id sent out was loaded
			h_core_id_sent <= '1'; 	-- set h_core_id_sent high
          --###################################################################
		when others => null;
     end case;
end process;


--#############################################################################
-- State machine for core handling states
--#############################################################################
sm_core_handler : process 	(curr_state, 
						curr_core_ready, 
						msgin_valid, 
						il_msgin_ready, 
						h_core_id, 
						h_core_id_recieved)
begin
	-- default to same state as
	next_state <= curr_state;
	case (curr_state) is
		--###################################################################
		when IDLE =>
			-- 
               if ((curr_core_ready = '1')) then
			    	next_state <= CORE_FOUND;
               end if;
          --###################################################################
		when CORE_FOUND =>
			-- 
               if ((msgin_valid = '1')) then
                   	next_state <= LOAD_CORE;
				msgin_data_register <= msgin_data;
               end if;
		--###################################################################
		when LOAD_CORE =>
			-- 
			if (il_msgin_ready(to_integer(unsigned(h_core_id))) = '0') then
                   next_state <= OUT_H_COM;
               end if;
		--###################################################################
		when OUT_H_COM =>
			-- 
			if (h_core_id_recieved = '1') then
                   next_state <= IDLE;
               end if;
          --###################################################################
		when others =>
               next_state <= IDLE;
     end case;
end process;


--#############################################################################
-- Update state on rising edge
--#############################################################################
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

end architecture;
