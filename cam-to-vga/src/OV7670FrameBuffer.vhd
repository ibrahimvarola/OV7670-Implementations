library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;

entity OV7670FrameBuffer is
	port(
		PIClock					:	in	std_logic;
		PIReset					:	in	std_logic;
		PIWriteClock			:	in	std_logic;
		PIWriteEnable			:	in	std_logic;
		PIWriteAddress			:	in	std_logic_vector(16 downto 0);
		PIWriteData				:	in	std_logic_vector(11 downto 0);
		PIReadClock				:	in	std_logic;
		PIReadAddress			:	in	std_logic_vector(16 downto 0);
		POReadData				:	out	std_logic_vector(11 downto 0)
	);
end entity;

architecture Behavioral of OV7670FrameBuffer is
	signal	SDataOutTOP			:	std_logic_vector(11 downto 0)	:=	(others => '0');
	signal	SDataOutBOTTOM		:	std_logic_vector(11 downto 0)	:=	(others => '0');
	
	signal	SWriteEnableTOP		:	std_logic	:=	'0';
	signal	SWriteEnableBOTTOM	:	std_logic	:=	'0';

	COMPONENT DualPortRAM IS
		PORT
		(
			data		: IN STD_LOGIC_VECTOR (11 DOWNTO 0);
			rdaddress	: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
			rdclock		: IN STD_LOGIC ;
			wraddress	: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
			wrclock		: IN STD_LOGIC  := '1';
			wren		: IN STD_LOGIC  := '0';
			q			: OUT STD_LOGIC_VECTOR (11 DOWNTO 0)
		);
	END COMPONENT;
begin
	
	INST_TOP :	DualPortRAM
		port map(
			data		=>	PIWriteData(11 downto 0),
			rdaddress	=>	PIReadAddress(15 downto 0),
			rdclock		=>	PIReadClock,
			wraddress	=> 	PIWriteAddress(15 downto 0),
			wrclock		=> 	PIWriteClock,
			wren		=> 	SWriteEnableTOP,
			q			=> 	SDataOutTOP
		);
	
	INST_BOTTOM :	DualPortRAM
		port map(
			data		=>	PIWriteData(11 downto 0),
			rdaddress	=>	PIReadAddress(15 downto 0),
			rdclock		=>	PIReadClock,
			wraddress	=> 	PIWriteAddress(15 downto 0),
			wrclock		=> 	PIWriteClock,
			wren		=> 	SWriteEnableBOTTOM,
			q			=> 	SDataOutBOTTOM
		);

	process(PIWriteAddress(16), PIWriteEnable)
		begin
			case PIWriteAddress(16) is
				when '0' =>
					SWriteEnableTOP		<=	PIWriteEnable;
					SWriteEnableBOTTOM	<= '0';
				when '1' =>
					SWriteEnableTOP		<= '0';
					SWriteEnableBOTTOM	<= PIWriteEnable;
				when others =>
					SWriteEnableTOP		<= '0';
					SWriteEnableBOTTOM	<= '0';
			end case;
			
	end process;

	process(PIReadAddress(16), SDataOutTOP, SDataOutBOTTOM)
	begin
		case PIReadAddress(16) is
			when '0' =>
				POReadData	<=	SDataOutTOP;
			when '1' =>
				POReadData	<=	SDataOutBOTTOM;
			when others =>
				POReadData	<=	(others => '0');
		end case;
	end process;
end architecture;







-- process(PIWriteAddress(16), PIWriteEnable)
-- begin
-- 	case PIWriteAddress(16) is
-- 		when '0' =>
-- 			SWriteEnableTOP		<= PIWriteEnable;
-- 			SWriteEnableTBOTTOM	<= '0';
-- 		when '1' =>
-- 			SWriteEnableTOP		<= '0';
-- 			SWriteEnableTBOTTOM	<= PIWriteEnable;
-- 		when others =>
-- 			SWriteEnableTOP		<= '0';
-- 			SWriteEnableTBOTTOM	<= '0';
-- 	end case;
-- end process;

-- process(PIReadAddress(16), SDataOutTOP, SDataOutBOTTOM)
-- begin
	
-- 	case PIReadAddress(16) is
-- 		when '0' =>
-- 			POReadData	<=	SDataOutTOP;
-- 		when '1' =>
-- 			POReadData	<=	SDataOutBOTTOM;
-- 		when others =>
-- 			POReadData	<=	(others => '0');
-- 	end case;
-- end process;
-- end architecture;