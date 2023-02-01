library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;

entity VGAController is
	generic(
		GHPulse			: integer	:= 208;  
    	GHBackPorch		: integer	:= 336;  
    	GHPixels		: integer	:= 1920; 
    	GHFrontPorch	: integer	:= 128;  
    	GHPolarity		: std_logic	:= '0';
    	GVPulse			: integer	:= 3;    
    	GVBackPorch		: integer	:= 38;   
    	GVPixels		: integer	:= 1200; 
    	GVFrontPorch	: integer	:= 1;    
    	GVPolarity		: std_logic := '1'
	);
	port(
		PIClock			:	in	std_logic;
		PIReset			:	in	std_logic;
		POHSync			:	out	std_logic;
		POVSync			:	out	std_logic;
		PODisplayEnable	:	out	std_logic;
		POColumn		:	out	integer;
		PORow			:	out	integer;
		POBlank			:	out	std_logic;
		POSync			:	out	std_logic
	);
end entity;

architecture Behavioral of VGAController is
	constant CHPeriod : INTEGER := GHPulse + GHBackPorch + GHPixels + GHFrontPorch; --total number of pixel clocks in a row
	constant CVPeriod : INTEGER := GVPulse + GVBackPorch + GVPixels + GVFrontPorch; --total number of rows in column
begin
	POBlank	<=	'1';
	POSync	<=	'0';

	process(PIClock, PIReset)
		variable VHCount : integer range 0 to CHPeriod - 1 := 0;  --horizontal counter (counts the columns)
    	variable VVCount : integer range 0 to CVPeriod - 1 := 0;  --vertical counter (counts the rows)
	begin
		if (PIReset = '0') then
			VHCount			:= 	0;
			VVCount			:= 	0;
			POHSync			<= 	not GHPolarity;
			POVSync			<= 	not GVPolarity;
			PODisplayEnable	<=	'0';
			POColumn		<=	0;
			PORow			<=	0;
		elsif rising_edge(PIClock) then
			-- COUNTER
			if(VHCount < CHPeriod - 1) then
				VHCount	:=	VHCount + 1;
			else
				VHCount	:=	0;
				if(VVCount < CVPeriod - 1) then
					VVCount	:=	VVCount + 1;
				else
					VVCount	:=	0;
				end if;
			end if;

			-- Horizontal Sync
			if(VHCount < GHPixels + GHFrontPorch or VHCount >= GHPixels + GHFrontPorch + GHPulse) then
				POHSync	<=	not	GHPolarity;
			else
				POHSync	<=	GHPolarity;
			end if;

			-- Vertical Sync
			if(VVCount < GVPixels + GVFrontPorch or VVCount >= GVPixels + GVFrontPorch + GVPulse) then
				POVSync	<=	not	GVPolarity;
			else
				POVSync	<=	GVPolarity;
			end if;
			
			-- Pixel Koordinatlarinin Ayarlanmasi
			if(VHCount < GHPixels) then
				POColumn	<=	VHCount;
			end if;
			
			if(VVCount < GVPixels) then
				PORow		<=	VVCount;
			end if;

			-- Display Enable Cikisinin Ayarlanmasi
			if(VHCount < GHPixels and VVCount < GVPixels) then
				PODisplayEnable	<=	'1';
			else
				PODisplayEnable	<=	'0';
			end if;

		end if;
	end process;

end architecture;