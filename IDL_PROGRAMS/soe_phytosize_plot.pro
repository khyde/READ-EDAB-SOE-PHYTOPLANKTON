; $ID:	SOE_PHYTOSIZE_PLOT.PRO,	2020-12-31-15,	USER-KJWH	$
  PRO SOE_PHYTOSIZE_PLOT, VERSION, DIR_PLOTS=DIR_PLOTS, DATFILE=DATFILE, BUFFER=BUFFER

;+
; NAME:
;   SOE_PHYTOSIZE_PLOT
;
; PURPOSE:
;   $PURPOSE$
;
; CATEGORY:
;   $CATEGORY$
;
; CALLING SEQUENCE:
;   Result = SOE_PHYTOSIZE_PLOT($Parameter1$, $Parameter2$, $Keyword=Keyword$, ...)
;
; REQUIRED INPUTS:
;   Parm1.......... Describe the positional input parameters here. 
;
; OPTIONAL INPUTS:
;   Parm2.......... Describe optional inputs here. If none, delete this section.
;
; KEYWORD PARAMETERS:
;   KEY1........... Document keyword parameters like this. Note that the keyword is shown in ALL CAPS!
;
; OUTPUTS:
;   OUTPUT.......... Decribe the output of this program or function
;
; OPTIONAL OUTPUTS:
;   None
;
; COMMON BLOCKS: 
;   None
;
; SIDE EFFECTS:  
;   None
;
; RESTRICTIONS:  
;   None
;
; EXAMPLE:
; 
;
; NOTES:
;   $Citations or any other useful notes$
;   
; COPYRIGHT: 
; Copyright (C) 2020, Department of Commerce, National Oceanic and Atmospheric Administration, National Marine Fisheries Service,
;   Northeast Fisheries Science Center, Narragansett Laboratory.
;   This software may be used, copied, or redistributed as long as it is not sold and this copyright notice is reproduced on each copy made.
;   This routine is provided AS IS without any express or implied warranties whatsoever.
;
; AUTHOR:
;   This program was written on December 31, 2020 by Kimberly J. W. Hyde, Northeast Fisheries Science Center | NOAA Fisheries | U.S. Department of Commerce, 28 Tarzwell Dr, Narragansett, RI 02882
;    
; MODIFICATION HISTORY:
;   Dec 31, 2020 - KJWH: Initial code written
;-
; ****************************************************************************************************
  ROUTINE_NAME = 'SOE_PHYTOSIZE_PLOT'
  COMPILE_OPT IDL2
  SL = PATH_SEP()

  IF ~N_ELEMENTS(VERSION) THEN MESSAGE, 'ERROR: Must provide the SOE VERSION'
  IF ~N_ELEMENTS(BUFFER) THEN BUFFER=0
  
  CLRS = LIST([217,241,253],[193,232,251],[0,173,238],[0,83,159],[37,64,143],[255,255,255])
  CLRS  = LIST([0,70,127],[147,213,0],[255,131,0],[0,147,208],[30,202,211],[127,127,255],[0,121,52],[76,156,35])
  CLRS = ['BLACK','MEDIUM_SEA_GREEN','CORAL','DEEP_SKY_BLUE']

  
  
  FOR V=0, N_ELEMENTS(VERSION)-1 DO BEGIN
    VER = VERSION[V]
    VERSTR = SOE_VERSION_INFO(VER)
    IF ~N_ELEMENTS(DATFILE) THEN DATFILE = VERSTR.INFO.DATAFILE
    STRUCT = IDL_RESTORE(DATFILE)
    IF ~N_ELEMENTS(DIR_PLOTS) THEN DIR_PLT = VERSTR.DIRS.DIR_PLOTS+'PSC'+SL ELSE DIR_PLT = DIR_PLOTS & DIR_TEST, DIR_PLT
    NAMES = VERSTR.INFO.SUBAREA_NAMES
    TITLES = VERSTR.INFO.SUBAREA_TITLES
    MP = VERSTR.INFO.MAP_OUT
    
    
    

    CASE VER OF
      'V2021': BEGIN & COMP_PERIOD='ANNUAL' & PLOT_PERIOD=['WEEK','MONTH'] & MOV_PERIOD = ['WEEK','MONTH'] & END
      'V2022': BEGIN & COMP_PERIOD=['ANNUAL'] & PLOT_PERIOD=['WEEK','W','M'] & MOV_PERIOD = ['WEEK','MONTH'] & END
    ENDCASE
    
    FOR R=0, N_ELEMENTS(PLOT_PERIOD)-1 DO BEGIN
      PER = PLOT_PERIOD[R]
      DR = VERSTR.INFO.DATERANGE
      CASE PER OF
        'WEEK':  BEGIN & NDATES = 52 & CLIM = 1 & END
        'MONTH': BEGIN & NDATES = 12 & CLIM = 1 & END
        'W':     BEGIN & NDATES = 52 & CLIM = 0 & END
        'M':     BEGIN & NDATES = 12 & CLIM = 0 & END
      ENDCASE

      PER_STRUCT = STRUCT[WHERE(STRUCT.PERIOD_CODE EQ PER AND STRUCT.MATH EQ 'STATS',/NULL)]
      DP = PERIOD_2STRUCT(PER_STRUCT.PERIOD)
      
      IF KEYWORD_SET(CLIM) THEN YRS = '2100' ELSE YRS = YEAR_RANGE(DR,/STRING)
      FOR Y=0, N_ELEMENTS(YRS)-1 DO BEGIN
        YR = YRS[Y]
        
        IF KEYWORD_SET(CLIM) THEN PNGFILE = DIR_PLT + PER + '-' + VERSTR.INFO.SHAPEFILE + '-' + 'PHYTOSIZE-CLIMATOLOGY.png' $
                             ELSE PNGFILE = DIR_PLT + PER + '_' + YR + '-' + VERSTR.INFO.SHAPEFILE + '-' + 'PHYTOSIZE.png'
        IF FILE_MAKE(DATFILE,PNGFILE,OVERWRITE=OVERWRITE) EQ 0 THEN CONTINUE
        
        IF KEYWORD_SET(CLIM) THEN YSET = PER_STRUCT ELSE YSET = PER_STRUCT[WHERE(DP.YEAR_START EQ YR)]
        
        NPLOTS = N_ELEMENTS(NAMES)
        FONTSIZE = 12
        YTITLE = 'Phytoplankton Size Fraction'
        CRANGE = [0,2]
        SP = 0.03
        X1 = 0.08
        X2 = 0.9
        YS = (0.98-(SP*(NPLOTS+2)))/NPLOTS
        BT = 0.08
        IF N_ELEMENTS(NAMES) EQ 1 THEN Y1 = 0.1 ELSE Y1 = BT
        IF N_ELEMENTS(NAMES) EQ 1 THEN Y2 = 0.9 ELSE Y2 = BT+YS
        IF NONE(XDIM)      THEN XDIM = 850
        IF NONE(YDIM)      THEN YDIM = 300 * N_ELEMENTS(NAMES) < 256*6
    
        W = WINDOW(DIMENSIONS=[XDIM,YDIM],BUFFER=BUFFER)
        IF KEYWORD_SET(CLIM) THEN TITLE = 'Climatology' ELSE TITLE = YR
        T = TEXT(0.5,0.98,TITLE,ALIGNMENT=0.5,FONT_SIZE=14,FONT_STYLE='BOLD',/NORMAL)      
        FOR N=0, N_ELEMENTS(NAMES)-1 DO BEGIN ; Subareas
          ANAME = NAMES[N]
          TITLE = TITLES[N]        
        
          MST = YSET[WHERE(YSET.PROD EQ 'MICRO_PERCENTAGE' AND YSET.SUBAREA EQ ANAME,/NULL)] 
          NST = YSET[WHERE(YSET.PROD EQ 'NANO_PERCENTAGE'  AND YSET.SUBAREA EQ ANAME,/NULL)]
          PST = YSET[WHERE(YSET.PROD EQ 'PICO_PERCENTAGE'  AND YSET.SUBAREA EQ ANAME,/NULL)]
          CHL = YSET[WHERE(YSET.PROD EQ 'CHLOR_A'          AND YSET.SUBAREA EQ ANAME,/NULL)]
          
          MST = STRUCT_SORT(MST, TAGNAMES='PERIOD')
          NST = STRUCT_SORT(NST, TAGNAMES='PERIOD')
          PST = STRUCT_SORT(PST, TAGNAMES='PERIOD')
          CHL = STRUCT_SORT(CHL, TAGNAMES='PERIOD') & UN = UNIQ(CHL.NAME) & CHL = CHL[UN]
          
          MDT = PERIOD_2STRUCT(MST.PERIOD) & IF N_ELEMENTS(MDT) GT NDATES THEN MESSAGE, 'ERROR: The number of dates is incorrect...'
          NDT = PERIOD_2STRUCT(NST.PERIOD) & IF N_ELEMENTS(NDT) GT NDATES THEN MESSAGE, 'ERROR: The number of dates is incorrect...'
          PDT = PERIOD_2STRUCT(PST.PERIOD) & IF N_ELEMENTS(PDT) GT NDATES THEN MESSAGE, 'ERROR: The number of dates is incorrect...'
          CDT = PERIOD_2STRUCT(CHL.PERIOD) & IF N_ELEMENTS(CDT) GT NDATES THEN MESSAGE, 'ERROR: The number of dates is incorrect...'
          
          IF PER EQ 'MONTH' THEN FDT = '2100'+MDT.MONTH_START+'15' ELSE FDT = '2100'+MDT.MONTH_START+MDT.DAY_START
          XX  = [DATE_2JD(FDT),REVERSE(DATE_2JD(FDT))]
          AX = DATE_AXIS([FDT[0],FDT[-1]],/FYEAR,/MID)
          XTICKNAMES = REPLICATE(' ',N_ELEMENTS(AX.TICKNAME))
          
          BOT = REPLICATE(0.0,N_ELEMENTS(MDT))
          MY = [BOT,REVERSE(MST.MED)]
          NY = [MST.MED,REVERSE(MST.MED+NST.MED)]
          PY = [MST.MED+NST.MED,REPLICATE(1.0,N_ELEMENTS(MDT))]    
          YRANGE = NICE_RANGE([0,1])
          
          IF N GT 0 THEN Y1 = Y1 + YS + SP
          IF N GT 0 THEN Y2 = Y2 + YS + SP
          POSITION = [X1,Y1,X2,Y2]
          
          IF N EQ 0 THEN XTICKNAME=AX.TICKNAME ELSE XTICKNAME=XTICKNAMES     
          PD = PLOT(AX.JD,YRANGE,YTITLE=YTITLE,AXIS_STYLE=1,FONT_SIZE=FONTSIZE,YMINOR=YMINOR,XRANGE=AX.JD,XMAJOR=AX.TICKS,XMINOR=3,XTICKNAME=XTICKNAME,XTICKVALUES=AX.TICKV,POSITION=POSITION,/NODATA,/CURRENT)
          POS = PD.POSITION
          XTICKV = PD.XTICKVALUES & OK = WHERE(JD_2MONTH(XTICKV) EQ '01',COUNT)
          POLYM = POLYGON(XX,MY,FILL_COLOR=CLRS[1],/FILL_BACKGROUND,TARGET=PD,/DATA,LINESTYLE=6)
          POLYN = POLYGON(XX,NY,FILL_COLOR=CLRS[2],/FILL_BACKGROUND,TARGET=PD,/DATA,LINESTYLE=6)
          POLYN = POLYGON(XX,PY,FILL_COLOR=CLRS[3],/FILL_BACKGROUND,TARGET=PD,/DATA,LINESTYLE=6)
          
          P3 = PLOT(DATE_2JD(FDT),CHL.GSTATS_MED,YRANGE=CRANGE,COLOR='BLACK',THICK=3,LINESTYLE=0,/CURRENT,AXIS_STYLE=0,XSTYLE=1,POSITION=POS,XSHOWTEXT=1)
          A1 = AXIS('Y',TARGET=P3,LOCATION=[MAX(DATE_2JD(FDT)),0,0],TEXTPOS=1,TITLE=UNITS('CHLOR_A'),TICKFONT_SIZE=11,TEXT_COLOR='BLACK',COLOR='BLACK',TICKLEN=0.02,YRANGE=CRANGE) ;AXIS,YAXIS=1,YRANGE=[0,300],/SAVE, YTITLE=YTITLE2,CHARSIZE=CHARSIZE,COLOR=0
          A2 = AXIS('X',TARGET=PD,LOCATION=[MIN(XX),1,0],MAJOR=0,MINOR=0);,COLOR=PL(252))  
          TA = TEXT(POS[0]+.02,POS[3]-0.03,ANAME,FONT_COLOR='BLACK',FONT_SIZE=FONTSIZE+4,FONT_STYLE='BOLD')
        ENDFOR ; DATASETS
        S = SYMBOL(0.21,0.03,'SQUARE',SYM_SIZE=1.5,SYM_COLOR='WHITE',SYM_FILL_COLOR=CLRS[1],/SYM_FILLED,LABEL_STRING='Microplankton',LABEL_FONT_SIZE=FONTSIZE,LABEL_POSITION='R',/NORMAL)
        S = SYMBOL(0.42, 0.03,'SQUARE',SYM_SIZE=1.5,SYM_COLOR='WHITE',SYM_FILL_COLOR=CLRS[2],/SYM_FILLED,LABEL_STRING='Nanoplankton',LABEL_FONT_SIZE=FONTSIZE,LABEL_POSITION='R',/NORMAL)
        S = SYMBOL(0.64,0.03,'SQUARE',SYM_SIZE=1.5,SYM_COLOR='WHITE',SYM_FILL_COLOR=CLRS[3],/SYM_FILLED,LABEL_STRING='Picoplankton',LABEL_FONT_SIZE=FONTSIZE,LABEL_POSITION='R',/NORMAL)
        PRINT, 'Writing: ' + PNGFILE
        W.SAVE,PNGFILE,RESOLUTION=600
        W.CLOSE
      ENDFOR ; YEARS
    ENDFOR ; PLOT_PERIOD     
  ENDFOR ; VERSION    

END ; ***************** End of SOE_PHYTOSIZE_PLOT *****************
