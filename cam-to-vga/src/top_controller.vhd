library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;

entity top_controller is
    port(
        PIClock         :   in  std_logic;
        PIReset         :   in  std_logic;
        PIResendCfg     :   in  std_logic;
        POCfgFinished   :   out std_logic;
        
        POVGAClock      :   out     std_logic;
        POVGAHSync      :   out     std_logic;
        POVGAVSync      :   out     std_logic;
        POVGARed        :   out     std_logic_vector(7 downto 0);
        POVGAGreen      :   out     std_logic_vector(7 downto 0);
        POVGABlue       :   out     std_logic_vector(7 downto 0);
        POVGABlank      :   out     std_logic;
        POVGASync       :   out     std_logic;

        PICamPCLK		:	in		std_logic;
        PICamVSYNC		:	in		std_logic;
        PICamHREF		:	in		std_logic;
        PICamData		:	in		std_logic_vector(7 downto 0);
        POCamXCLK		:	out     std_logic;
        POCamPWDN		:	out     std_logic;
        POCamReset		:	out     std_logic;
        POCamSIOC		:	out 	std_logic;
        PIOCamSIOD		:	inout	std_logic
    );
end entity;

architecture Behavioral of top_controller is
    signal  SClock          :   std_logic                       :=  '0';
    signal  SResendCfg      :   std_logic                       :=  '0';
    signal  SCfgFinished    :   std_logic                       :=  '0';

    signal  SVGAClock       :   std_logic                       :=  '0';
    signal  SVGAHSync       :   std_logic                       :=  '0';
    signal  SVGAVSync       :   std_logic                       :=  '0';
    signal  SVGARed         :   std_logic_vector(7 downto 0)    :=  (others => '0');
    signal  SVGAGreen       :   std_logic_vector(7 downto 0)    :=  (others => '0');
    signal  SVGABlue        :   std_logic_vector(7 downto 0)    :=  (others => '0');
    signal  SVGABlank       :   std_logic                       :=  '0';
    signal  SVGASync        :   std_logic                       :=  '0';

    signal  SCamPCLK        :   std_logic                       :=  '0';
    signal  SCamVSYNC       :   std_logic                       :=  '0';
    signal  SCamHREF        :   std_logic                       :=  '0';
    signal  SCamData        :   std_logic_vector(7 downto 0)    :=  (others => '0');
    signal  SCamXCLK        :   std_logic                       :=  '0';
    signal  SCamPWDN        :   std_logic                       :=  '0';
    signal  SCamReset       :   std_logic                       :=  '0';
    signal  SCamSIOC        :   std_logic                       :=  '0';
    signal  SCamSIOD        :   std_logic                       :=  '0';

    signal  S50MHzClk        :   std_logic                      :=  '0';
    signal  S25MHzClk        :   std_logic                      :=  '0';    

    signal  SDataOut         :   std_logic_vector(11 downto 0)  :=  (others => '0');
    signal  SWriteEnable     :   std_logic                      :=  '0';
    signal  SReadAddress     :   std_logic_vector(16 downto 0)  :=  (others => '0');
    signal  SWriteAddress    :   std_logic_vector(16 downto 0)  :=  (others => '0');
    signal  SRAMReadData     :   std_logic_vector(11 downto 0)  :=  (others => '0');
    signal  SDisplayEnable   :   std_logic                      :=  '0';

    component pll is
	    PORT
	    (
	    	inclk0		: IN STD_LOGIC  := '0';
	    	c0		: OUT STD_LOGIC ;
	    	c1		: OUT STD_LOGIC 
	    );
    end component;

    component OV7670Controller is
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
    end component;

    component OV7670Capture is
        port(
            PIPCLK          :   in  std_logic;
            PIReset         :   in  std_logic;
            PIVSYNC			:   in  std_logic;
            PIHREF          :   in  std_logic;
            PIData          :   in  std_logic_vector(7 downto 0);
            PODataOut       :   out std_logic_vector(11 downto 0);
            PORAMWriteAddr  :   out std_logic_vector(16 downto 0);
            POWriteEnable   :   out std_logic
        );
    
    end component;

    component OV7670FrameBuffer is
        port(
            PIWriteClock			:	in	std_logic;
            PIWriteEnable			:	in	std_logic;
            PIWriteAddress			:	in	std_logic_vector(16 downto 0);
            PIWriteData				:	in	std_logic_vector(11 downto 0);
            PIReadClock				:	in	std_logic;
            PIReadAddress			:	in	std_logic_vector(16 downto 0);
            POReadData				:	out	std_logic_vector(11 downto 0)
        );
    end component;
    
    
    component RAMReader is
        port(
            PIClock             :   in  std_logic;
            PIReset             :   in  std_logic;
            PIVSYNC             :   in  std_logic;
            PIDisplayEnable     :   in  std_logic;
            PIRAMReadData       :   in  std_logic_vector(11 downto 0);
            PORAMReadAddr       :   out std_logic_vector(16 downto 0);
            PORed               :   out std_logic_vector(7 downto 0);
            POGreen             :   out std_logic_vector(7 downto 0);
            POBlue              :   out std_logic_vector(7 downto 0)
        );
    
    end component;

    
    component VGA is
        Port ( 
            CLK25 : in  STD_LOGIC;         -- Horloge d'entre de 25 MHz              
            clkout : out  STD_LOGIC;       -- Horloge de sortie vers le ADV7123 et l'ecran TFT
            Hsync,Vsync : out  STD_LOGIC;  -- les deux signaux de synchronisation pour l'ecran VGA
            Nblank : out  STD_LOGIC;       -- signal de commande du convertisseur N/A ADV7123
            activeArea : out  STD_LOGIC;
            Nsync : out  STD_LOGIC         -- signaux de synchronisation et commande de l'ecran TFT
        );        
    end component;

    -- component VGAController is
    --     generic(
    --         GHPulse			: integer	:= 208;  
    --         GHBackPorch		: integer	:= 336;  
    --         GHPixels		: integer	:= 1920; 
    --         GHFrontPorch	: integer	:= 128;  
    --         GHPolarity		: std_logic	:= '0';
    --         GVPulse			: integer	:= 3;    
    --         GVBackPorch		: integer	:= 38;   
    --         GVPixels		: integer	:= 1200; 
    --         GVFrontPorch	: integer	:= 1;    
    --         GVPolarity		: std_logic := '1'
    --     );
    --     port(
    --         PIClock			:	in	std_logic;
    --         PIReset			:	in	std_logic;
    --         POHSync			:	out	std_logic;
    --         POVSync			:	out	std_logic;
    --         PODisplayEnable	:	out	std_logic;
    --         POColumn		:	out	integer;
    --         PORow			:	out	integer;
    --         POBlank			:	out	std_logic;
    --         POSync			:	out	std_logic
    --     );
    -- end component;

begin
    SClock          <=  PIClock;
    SResendCfg      <=  PIResendCfg;
    POCfgFinished   <=  SCfgFinished;
        
    POVGAClock      <=  SVGAClock;   
    POVGAHSync      <=  SVGAHSync;   
    POVGAVSync      <=  SVGAVSync;   
    POVGARed        <=  SVGARed;     
    POVGAGreen      <=  SVGAGreen;   
    POVGABlue       <=  SVGABlue;    
    POVGABlank      <=  SVGABlank;   
    POVGASync       <=  SVGASync;    

    SCamPCLK        <=  PICamPCLK;
    SCamVSYNC       <=  PICamVSYNC;
    SCamHREF	    <=  PICamHREF;
    SCamData	    <=  PICamData;
    POCamXCLK       <=  SCamXCLK;
    POCamPWDN       <=  SCamPWDN;
    POCamReset      <=  SCamReset;
    --POCamSIOC       <=  SCamSIOC;
    --PIOCamSIOD      <=  SCamSIOD;



    INST_PLL : pll 
        PORT MAP (
	        inclk0  => SClock,
	        c0      => S50MHzClk,
	        c1      => S25MHzClk
	    );

    INST_CONTROLLER : OV7670Controller
	    port map(
            PIClock         =>  S50MHzClk,
            PIReset         =>  PIReset,
            PITrig          =>  SResendCfg,
            POCfgFinished   =>  SCfgFinished,
            POCamReset      =>  SCamReset,
            POPWDN          =>  SCamPWDN,
            POXCLK          =>  SCamXCLK,
            PIOSIOD         =>  PIOCamSIOD,
            PIOSIOC         =>  POCamSIOC
        );

    INST_CAPTURE : OV7670Capture
        port map(
            PIPCLK          =>  SCamPCLK,
            PIReset         =>  PIReset,
            PIVSYNC		    =>  SCamVSYNC,
            PIHREF          =>  SCamHREF,
            PIData          =>  SCamData,
            PODataOut       =>  SDataOut,
            PORAMWriteAddr  =>  SWriteAddress,
            POWriteEnable   =>  SWriteEnable
        );

    INST_FRAMEBUFF : OV7670FrameBuffer
        port map(
            PIWriteClock    =>  SCamPCLK,
            PIWriteEnable   =>  SWriteEnable,
            PIWriteAddress  =>  SWriteAddress,
            PIWriteData	    =>  SDataOut,
            PIReadClock	    =>  S25MHzClk,
            PIReadAddress   =>  SReadAddress,
            POReadData      =>  SRAMReadData
        );
    


    INST_READER : RAMReader
        port map(
            PIClock         =>  S25MHzClk,
            PIReset         =>  PIReset,
            PIVSYNC         =>  SVGAVSync,
            PIDisplayEnable =>  SDisplayEnable,
            PIRAMReadData   =>  SRAMReadData,
            PORAMReadAddr   =>  SReadAddress,
            PORed           =>  SVGARed,  
            POGreen         =>  SVGAGreen,
            POBlue          =>  SVGABlue 
        );

    

    INST_VGA : VGA
        port map(
            CLK25      =>   S25MHzClk,
            clkout     =>   SVGAClock,
            Hsync      =>   SVGAHSync, 
            Vsync      =>   SVGAVSync, 
            Nblank     =>   SVGABlank,
            activeArea =>   SDisplayEnable,
            Nsync      =>   SVGASync            
        );

    -- INST_VGA : VGAController
    --     generic map(
    --         GHPulse		    =>  96,
    --         GHBackPorch	    =>  48,
    --         GHPixels	    =>  640,
    --         GHFrontPorch    =>  16,
    --         GHPolarity	    =>  '0',
    --         GVPulse		    =>  2,
    --         GVBackPorch	    =>  33,
    --         GVPixels	    =>  480,
    --         GVFrontPorch    =>  10,
    --         GVPolarity	    =>  '0'
    --     )
    --     port map(
    --         PIClock			=>  S25MHzClk,
    --         PIReset			=>  PIReset,
    --         POHSync			=>  SVGAHSync,
    --         POVSync			=>  SVGAVSync,
    --         PODisplayEnable	=>  SDisplayEnable,
    --         POColumn		=>  open,
    --         PORow			=>  open,
    --         POBlank			=>  SVGABlank,
    --         POSync			=>  SVGASync
    --     );        

end architecture;