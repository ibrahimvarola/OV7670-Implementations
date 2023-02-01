library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;

entity OV7670Controller is
    port (
        PIClock       : in std_logic; --  FPGA SYS CLOCK (50 MHz)
        PIReset       : in std_logic;
        PITrig        : in std_logic;
        POCfgFinished : out std_logic;
        POCamReset    : out std_logic;
        POPWDN        : out std_logic;
        POXCLK        : out std_logic; --  OV7670 MAIN CLOCK (25 MHz)
        PIOSIOD       : inout std_logic;
        PIOSIOC       : out std_logic
    );
end OV7670Controller;

architecture Behavioral of OV7670Controller is

    signal SClock       : std_logic                    := '0';
    signal SReset       : std_logic                    := '0';
    signal STrig        : std_logic                    := '0';
    signal SDone        : std_logic                    := '0';
    signal SReady       : std_logic                    := '0';
    signal SCfgFinished : std_logic                    := '0';
    signal SStart       : std_logic                    := '0';
    signal SEnable      : std_logic                    := '0';
    signal SAddress     : std_logic_vector(6 downto 0) := (others => '0');
    signal SRegister    : std_logic_vector(7 downto 0) := (others => '0');
    signal SWriteData   : std_logic_vector(7 downto 0) := (others => '0');


    signal SSIOD         : std_logic                    := '0';
    signal SSIOC         : std_logic                    := '0';
	 

    signal SCamReset    : std_logic                    := '0';
    signal SPWDN        : std_logic                    := '0';
    signal SXCLK        : std_logic                    := '0';


    component SCCBRegisterTable is
        port (
            PIClock       : in std_logic;
            PIReset       : in std_logic;
            PITrig        : in std_logic;
            PIDone        : in std_logic;
            PIReady       : in std_logic;
            POCfgFinished : out std_logic;
            POStart       : out std_logic;
            POEnable      : out std_logic;
            POAddress     : out std_logic_vector(6 downto 0);
            PORegister    : out std_logic_vector(7 downto 0);
            POWriteData   : out std_logic_vector(7 downto 0)
        );

    end component;

    component SCCBMaster is
        generic(
            GInputClock :   integer := 50_000_000;                  --  FPGA' nin ana clock hizi
            GBusClock   :   integer := 400_000                      --  SCCB hattinin calistirilmasi icin belirlenecek hiz (400 kHz SCCB fast mode)
        );          
	    port(       
	    	PIClock     :   in      std_logic;                      --  Sistem clock girisi
            PIReset     :   in      std_logic;                      --  Reset(active low) girisi
            PIEnable    :   in      std_logic;                      --  SCCB hattini aktif edecek enable girisi
            PIAddress   :   in      std_logic_vector(6 downto 0);   --  SCCB hattina bagli olan slave cihazlarinin ana adreslerini isaret eden giris
            PIRegister  :   in      std_logic_vector(7 downto 0);   --  Slave birimin islem yapilacak register adresini belirten giris
            PIWriteData :   in      std_logic_vector(7 downto 0);   --  Master -> Slave yonunde yazilacak data
            --PIMode      :   in      std_logic;                      --  SCCB mod secenegi girisi
            PIStart     :   in      std_logic;                      --  SCCB master backend calistirma girisi
            PODone      :   out     std_logic;                      --  SCCB arayuzunun yazma islemini bitirdigini belirten cikis
            POReady     :   out     std_logic;                      --  SCCB arayuzunun islem yapmaya hazir oldugunu belirten cikis
            PIOSIOD     :   inout   std_logic;                      --  SCCB seri data cikisi - girisi
            POSIOC      :   out     std_logic                       --  SCCB seri clock cikisi
	    );

    end component;

begin
    SClock        <= PIClock;
    SReset        <= PIReset;
    STrig         <= PITrig;
    POCfgFinished <= SCfgFinished;
    POCamReset    <= SCamReset;
    POPWDN        <= SPWDN;
    POXCLK        <= SXCLK;
    PIOSIOD       <= SSIOD;
    PIOSIOC       <= SSIOC;
	
	 
	 
    INST_REG : SCCBRegisterTable
    port map(
        PIClock       => SClock,
        PIReset       => SReset,
        PITrig        => STrig,
        PIDone        => SDone,
        PIReady       => SReady,
        POCfgFinished => SCfgFinished,
        POStart       => SStart,
        POEnable      => SEnable,
        POAddress     => SAddress,
        PORegister    => SRegister,
        POWriteData   => SWriteData
    );

    INST_I2C : SCCBMaster
    generic map (
            GInputClock => 50_000_000,
            GBusClock   => 400_000
        )
    port map(

        PIClock     =>  SClock,
        PIReset     =>  SReset,
        PIEnable    =>  SEnable,
        PIAddress   =>  SAddress,
        PIRegister  =>  SRegister,
        PIWriteData =>  SWriteData,
        --PIMode      =>  '0',
        PIStart     =>  SStart,
        PODone      =>  SDone,
        POReady     =>  SReady,
        PIOSIOD     =>  SSIOD,
        POSIOC      =>  SSIOC
    );
    
    -- INST_I2C : SCCBMaster
    -- generic map (
    --         GInputClock => 50_000_000,
    --         GBusClock   => 400_000
    --     )
    -- port map(
    --     PIClock     =>  SClock,
    --     PIReset     =>  SReset,
    --     PIEnable    =>  SEnable,
    --     PIAddress   =>  SAddress,
    --     PIRegister  =>  SRegister,
    --     PIWriteData =>  SWriteData,
    --     PIStart     =>  SStart,
    --     PODone      =>  SDone,
    --     POReady     =>  SReady,
    --     PIOSIOD     =>  SSIOD,
    --     POSIOC      =>  SSIOC
    -- );

    SPWDN        <= '0';
    SCamReset    <= '1';


    process (PIClock)
    begin
        if rising_edge(PIClock) then
             SXCLK        <= not SXCLK;
        end if;
    end process;

end Behavioral;