; $ID:	SOE_WEEKLY_PLOTS.PRO,	2020-12-31-15,	USER-KJWH	$
  PRO SOE_WEEKLY_PLOTS, VERSION, DATFILE=DATFILE, DIR_PLOTS=DIR_PLOTS, OVERWRITE=OVERWRITE, BUFFER=BUFFER

;+
; NAME:
;   SOE_WEEKLY_PLOTS
;
; PURPOSE:
;   To create annual CHL and PP plots for the SOE reports
;
; PROJECT:
;   READ=EDAB-SOE-PHYTOPLANKTON
;
; CALLING SEQUENCE:
;   SOE_WEEKLY_PLOTS, VERSION
;
; REQUIRED INPUTS:
;   VERSION.......... The annual version of the report
;
; OPTIONAL INPUTS:
;   DATFILE.......... The data file containing the data for the plots
;   DIR_PLOTS........ The output director for the plots
;   
; KEYWORD PARAMETERS:
;   OVERWRITE........ Overwrite files if they alredy exist
;   BUFFER........... Turns on [0] or off [1] the plotting screen
;
; OUTPUTS:
;   OUTPUT........... A series of annual CHL and PP plots and an animation of the plots
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
;   
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
;   Dec 20, 2021 - KJWH: Updated documentation
;                        Restructed the steps to find the data for each plot to speed it up by avoiding parsing unnecessary files
;                        Added V2022 info
;-
; ****************************************************************************************************
  ROUTINE_NAME = 'SOE_WEEKLY_PLOTS'
  COMPILE_OPT IDL2
  SL = PATH_SEP()
  
  IF NONE(VERSION) THEN MESSAGE, 'ERROR: Must provide the SOE VERSION'
  IF NONE(BUFFER) THEN BUFFER=0

  CLRS = LIST([217,241,253],[193,232,251],[0,173,238],[0,83,159],[37,64,143],[255,255,255])
  CLRS  = LIST([0,70,127],[147,213,0],[255,131,0],[0,147,208],[30,202,211],[127,127,255],[0,121,52],[76,156,35])
  CLRS = ['BLACK','MEDIUM_SEA_GREEN','CORAL','DEEP_SKY_BLUE']


  FOR V=0, N_ELEMENTS(VERSION)-1 DO BEGIN
    VER = VERSION[V]
    VERSTR = SOE_VERSION_INFO(VER)
    IF NONE(DIR_PLOTS) THEN DIR_PLT = VERSTR.DIRS.DIR_PLOTS+'WEEKLY_TIMESERIES'+SL ELSE DIR_PLT = DIR_PLOTS & DIR_TEST, DIR_PLT
    DIR_MOVIE = VERSTR.DIRS.DIR_MOVIE
    NAMES = VERSTR.INFO.SUBAREA_NAMES
    TITLES = VERSTR.INFO.SUBAREA_TITLES
    MP = VERSTR.INFO.MAP_OUT
    DR = VERSTR.INFO.DATERANGE
    YEARS = YEAR_RANGE(DR[0],DR[1],/STRING)
    TEMP_DR = VERSTR.INFO.TEMP_DATERANGE
    TDP = DATE_PARSE(TEMP_DR[0])
    AX = DATE_AXIS([210001,210012],/MONTH,/FYEAR,STEP=1,/MID)
    PRODS = TAG_NAMES(VERSTR.PROD_INFO)
    IF NONE(DATFILE) THEN DATFILE = VERSTR.INFO.DATAFILE
    STRUCT = IDL_RESTORE(DATFILE)
    
    MTHICK = 3


    CASE VER OF
      'V2021': BEGIN & PLOT_PERIOD=['W','M'] & PLOT_PRODS = ['CHLOR_A','PPD'] & END
      'V2022': BEGIN & PLOT_PERIOD=['W','M'] & PLOT_PRODS = ['CHLOR_A','PPD'] & END
    ENDCASE
    
    OK = WHERE_MATCH(PRODS,PLOT_PRODS,COUNT)
    IF COUNT EQ 0 THEN CONTINUE
    PRODS = PRODS[OK]
    
    FOR R=0, N_ELEMENTS(PLOT_PERIOD)-1 DO BEGIN
      PER = PLOT_PERIOD[R]
      CASE PER OF
        'W': BEGIN & NDATES = 52 & CPER = 'WEEK' & END
        'M': BEGIN & NDATES = 12 & CPER = 'MONTH' & END
      ENDCASE
    
        PNGS = []
        FOR Y=0, N_ELEMENTS(YEARS)-1 DO BEGIN
          YR = YEARS[Y]
          PNGFILE = DIR_PLT + PER +'_'+YR + '-' + VERSTR.INFO.SHAPEFILE + '-' + STRJOIN(PRODS,'_') + '-TIMESERIES.png'
          PNGS = [PNGS,PNGFILE]
          IF FILE_MAKE(DATFILE,PNGFILE,OVERWRITE=OVERWRITE) EQ 0 THEN CONTINUE
          
          W = WINDOW(DIMENSIONS=[800,1200],BUFFER=BUFFER)
          T = TEXT(0.5,0.98,YR,ALIGNMENT=0.5,FONT_SIZE=14,FONT_STYLE='BOLD',/NORMAL)
          LO = 0
          FOR FTH=0L, N_ELEMENTS(NAMES)-1 DO BEGIN
            FOR PTH=0, N_ELEMENTS(PRODS)-1 DO BEGIN
              LO = LO+1
              PROD = PRODS[PTH]           
              PSTR = VERSTR.PROD_INFO.(WHERE(TAG_NAMES(VERSTR.PROD_INFO) EQ PROD))
              ALG = VALIDS('ALGS',PSTR.PROD) & TALG = VALIDS('ALGS',PSTR.TEMP_PROD)
              CASE VALIDS('PRODS',PROD) OF
                'CHLOR_A': BEGIN & TITLE=UNITS('CHLOROPHYLL')        & YRNG=[0.0,1.6] & PSTATS='GSTATS_MED' & END
                'PPD':     BEGIN & TITLE=UNITS('PRIMARY_PRODUCTION') & YRNG=[0.0,2.2] & PSTATS='GSTATS_MED' & END
              ENDCASE             
              
              IF YR EQ TDP.YEAR THEN BEGIN ; Merge the temporary dataset with the primary dataset
                SET = STRUCT[WHERE(STRUCT.SENSOR EQ PSTR.DATASET AND STRUCT.MATH EQ 'STATS',COUNT)]
                FP = PARSE_IT(SET.NAME)
                YSTR = SET[WHERE(SET.SUBAREA EQ NAMES[FTH] AND SET.PROD EQ PROD AND SET.ALG EQ ALG AND SET.PERIOD_CODE EQ PER  AND FP.YEAR_START EQ YR,/NULL)]
                CSTR = SET[WHERE(SET.SUBAREA EQ NAMES[FTH] AND SET.PROD EQ PROD AND SET.ALG EQ ALG AND SET.PERIOD_CODE EQ CPER,/NULL)]

                TSET = STRUCT[WHERE(STRUCT.SENSOR EQ PSTR.TEMP_DATASET AND STRUCT.MATH EQ 'STATS' AND STRUCT.SUBAREA EQ NAMES[FTH] AND STRUCT.PROD EQ VALIDS('PRODS',PSTR.TEMP_PROD) AND STRUCT.ALG EQ VALIDS('ALGS',PSTR.TEMP_PROD) AND STRUCT.PERIOD_CODE EQ PER,COUNT)]
                TFP = PARSE_IT(TSET.NAME)
                TYSTR = TSET[WHERE(TFP.YEAR_START EQ YR,/NULL)]

                IF N_ELEMENTS(YSTR)+N_ELEMENTS(TYSTR) NE NDATES THEN MESSAGE, 'ERROR: Number of files does not equal ' + NUM2STR(NDATES),/CONTINUE
                YSTR = [YSTR,TYSTR]
                B = WHERE_SETS(YSTR.PERIOD)
                IF MAX(B.N) GT 1 THEN MESSAGE, 'ERROR: Duplicate periods found in the combined structure.'
                YSTR = STRUCT_SORT(YSTR,TAGNAMES='PERIOD')
                
              ENDIF ELSE BEGIN
                CSTR = STRUCT[WHERE(STRUCT.SENSOR EQ PSTR.DATASET AND STRUCT.MATH EQ 'STATS' AND STRUCT.SUBAREA EQ NAMES[FTH] AND STRUCT.PROD EQ PROD AND STRUCT.ALG EQ ALG AND STRUCT.PERIOD_CODE EQ CPER,/NULL,COUNT)]
                YSTR = STRUCT[WHERE(STRUCT.SENSOR EQ PSTR.DATASET AND STRUCT.MATH EQ 'STATS' AND STRUCT.SUBAREA EQ NAMES[FTH] AND STRUCT.PROD EQ PROD AND STRUCT.ALG EQ ALG AND STRUCT.PERIOD_CODE EQ PER, /NULL,COUNT)]
                DP = PERIOD_2STRUCT(YSTR.PERIOD)
                YSTR = YSTR[WHERE(DP.YEAR_START EQ YR,/NULL)]
              ENDELSE  
              

              YDATE = DATE_2JD(YDOY_2DATE('2100',DATE_2DOY(PERIOD_2DATE(YSTR.PERIOD))))
              YDATA = GET_TAG(YSTR,PSTATS)

              CDATE = DATE_2JD(YDOY_2DATE('2100',DATE_2DOY(PERIOD_2DATE(CSTR.PERIOD))))
              CDATA = GET_TAG(CSTR,PSTATS) & ADATA = CDATA & BDATA = CDATA
              CSTD  = GET_TAG(CSTR,'GSTATS_STD')

              OKA = WHERE(YDATA GE CDATA,COUNTA) & OKB = WHERE(YDATA LE CDATA,COUNTB)
              ADATA[OKA] = YDATA[OKA] & BDATA[OKB] = YDATA[OKB]

              P0 = PLOT(YDATE,YDATA,/NODATA,/CURRENT,LAYOUT=[2,3,LO],XRANGE=AX.JD,YRANGE=YRNG,XTICKNAME=AX.TICKNAME,XTICKVALUES=AX.TICKV,XMINOR=0,XSTYLE=1,YMAJOR=YMAJOR,YTICKV=YTICKS,YTITLE=TITLES[PTH],MARGIN=[0.13,0.05,0.05,0.07])
              ; P1 = POLYGON([KDATE,REVERSE(KDATE)],[KDATA+KSTD,  REVERSE(KDATA-KSTD)],  FILL_COLOR='LIGHT_GREY',FILL_TRANSPARENCY=65,LINESTYLE=6,/OVERPLOT,/DATA,TARGET=P0)
              ; P2 = POLYGON([KDATE,REVERSE(KDATE)],[KDATA+KSTD*2,REVERSE(KDATA-KSTD*2)],FILL_COLOR='LIGHT_GREY',FILL_TRANSPARENCY=75,LINESTYLE=6,/OVERPLOT,/DATA,TARGET=P0)
              PA = POLYGON([CDATE,REVERSE(CDATE)],[CDATA,REVERSE(ADATA)],FILL_COLOR='SPRING_GREEN',FILL_TRANSPARENCY=50,LINESTYLE=6,/OVERPLOT,/DATA,TARGET=P0)
              PB = POLYGON([CDATE,REVERSE(CDATE)],[CDATA,REVERSE(BDATA)],FILL_COLOR='MEDIUM_BLUE', FILL_TRANSPARENCY=50,LINESTYLE=6,/OVERPLOT,/DATA,TARGET=P0)
              PM = PLOT(CDATE,CDATA,COLOR='BLACK',/CURRENT,/OVERPLOT,THICK=MTHICK);,XRANGE=AX.JD,YRANGE=[MR1(P),MR2(P)],XTICKNAME=AX.TICKNAME,XTICKVALUES=AX.TICKV,XMINOR=0,XSTYLE=1)
              TN = TEXT(CDATE[2],MAX(YRNG)*.9,NAMES[FTH],TARGET=PM,FONT_SIZE=12,/DATA)
            ENDFOR ; PRODS
          ENDFOR ; NAMES
          W.SAVE, PNGFILE
          W.CLOSE
          PFILE, PNGFILE
        ENDFOR ; YEARS

        FPS = 15
        MOVIE_FILE = DIR_MOVIE + 'SOE_'+VER + '-' + VERSTR.INFO.SHAPEFILE + '-' + STRJOIN(PRODS,'_') + '-' + CPER + '_TIMESERIES-FPS_'+ROUNDS(FPS)+'.webm'
        IF FILE_MAKE(PNGS,MOVIE_FILE,OVERWRITE=OVERWRITE) EQ 0 THEN CONTINUE
        MOVIE, PNGS, MOVIE_FILE=MOVIE_FILE, FRAME_SEC=FPS
        
      ENDFOR ; PLOT_PERIODS
  ENDFOR ; VERSION 


END ; ***************** End of SOE_WEEKLY_PLOTS *****************
