; $ID:	SOE_TIMESERIES_ANIMATION.PRO,	2023-11-01-21,	USER-KJWH	$
  PRO SOE_TIMESERIES_ANIMATION, VERSION_STRUCT, PRODS=PRODS, BY_PERIOD=BY_PERIOD, BUFFER=BUFFER

;+
; NAME:
;   SOE_TIMESERIES_ANIMATION
;
; PURPOSE:
;   Create an animated timeseries plot
;
; PROJECT:
;   SOE_PHYTOPLANKTON
;
; CALLING SEQUENCE:
;   SOE_TIMESERIES_ANIMATION,$Parameter1$, $Parameter2$, $Keyword=Keyword$, ....
;
; REQUIRED INPUTS:
;   VERSION_STRUCT.......... The version structure for the SOE
;
; OPTIONAL INPUTS:
;   Parm2.......... Describe optional inputs here. If none, delete this section.
;
; KEYWORD PARAMETERS:
;   KEY1........... Document keyword parameters like this. Note that the keyword is shown in ALL CAPS!
;
; OUTPUTS:
;   OUTPUT.......... Describe the output of this program or function
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
; Copyright (C) 2023, Department of Commerce, National Oceanic and Atmospheric Administration, National Marine Fisheries Service,
;   Northeast Fisheries Science Center, Narragansett Laboratory.
;   This software may be used, copied, or redistributed as long as it is not sold and this copyright notice is reproduced on each copy made.
;   This routine is provided AS IS without any express or implied warranties whatsoever.
;
; AUTHOR:
;   This program was written on November 01, 2023 by Kimberly J. W. Hyde, Northeast Fisheries Science Center | NOAA Fisheries | U.S. Department of Commerce, 28 Tarzwell Dr, Narragansett, RI 02882
;    
; MODIFICATION HISTORY:
;   Nov 01, 2023 - KJWH: Initial code written
;-
; ****************************************************************************************************
  ROUTINE_NAME = 'SOE_TIMESERIES_ANIMATION'
  COMPILE_OPT IDL3
  SL = PATH_SEP()
  
  IF ~N_ELEMENTS(VERSION_STRUCT) THEN MESSAGE, 'ERROR: Must provide the SOE VERSION structure'
  IF ~N_ELEMENTS(BUFFER) THEN BUFFER=0
  IF ~N_ELEMENTS(PRODS) THEN PRODS = 'SST'
  IF ~N_ELEMENTS(PAL) THEN PAL = 'PAL_GRAY_REVERSE'
  IF ~N_ELEMENTS(YEAR_COLOR) THEN YCLR = 'RED' ELSE YCLR = YEAR_COLOR
  IF ~N_ELEMENTS(PERIODS) THEN PERIODS = ['W','M']
  
  TYPES = ['ANOMS','STATS']

  VERSTR = VERSION_STRUCT
  SHAPES = VERSTR.SHAPEFILES
  MP = VERSTR.INFO.MAP_OUT
  DR = VERSTR.INFO.DATERANGE
  YEARS = YEAR_RANGE(DR,/STRING)
  NYEARS = N_ELEMENTS(YEARS)

  MINDATE = '21000101000000'
  MAXDATE = '21010101000000'
  AX = DATE_AXIS([MINDATE,MAXDATE],/FYEAR,/MONTH,STEP=1)
  X2TICKNAME = REPLICATE(' ',N_ELEMENTS(AX.TICKNAME))
  YTICKNAMES=[' ',' ',' ']
  CHARSIZE = 11
  MARGIN = [0.03,0.0,0.11,0.0]
  
  STRPRODS = TAG_NAMES(VERSTR.PROD_INFO)
  OK = WHERE_MATCH(STRPRODS,PRODS,COUNT)
  IF COUNT EQ 0 THEN STOP
  PRODS = PRODS[OK]
  
  
  IF ~N_ELEMENTS(DIR_PLOTS) THEN DIR_MOV = VERSTR.DIRS.DIR_PLOTS+'TIMESERIES_ANIMATION'+SL ELSE DIR_MOV = DIR_PLOTS & DIR_TEST, DIR_MOV
  IF ~N_ELEMENTS(DATFILE) THEN DATFILE = VERSTR.INFO.DATAFILE
  FULLSTRUCT = IDL_RESTORE(DATFILE)
  FULLSTRUCT[WHERE(FULLSTRUCT.MATH EQ 'STACKED_STATS')].MATH = 'STATS'
  FULLSTRUCT[WHERE(FULLSTRUCT.MATH EQ 'STACKED_ANOMS')].MATH = 'ANOM'
  STRUCT = FULLSTRUCT[WHERE(FULLSTRUCT.MATH EQ 'STATS',/NULL)]
  ASTRUCT = FULLSTRUCT[WHERE(FULLSTRUCT.MATH EQ 'ANOM',/NULL)]
  
  FOR S=0, N_ELEMENTS(PRODS)-1 DO BEGIN
    APROD = PRODS[S]
    DIRPLT = DIR_MOV + APROD + '_PNGS' + SL & DIR_TEST, DIRPLT
    PSTR = VERSTR.PROD_INFO.(WHERE(TAG_NAMES(VERSTR.PROD_INFO) EQ APROD,/NULL))
    DSET = PSTR.DATASET
    TSET = PSTR.TEMP_DATASET
    
    CASE VALIDS('PRODS',APROD) OF
      'SST':     BEGIN & SYTITLE=UNITS('TEMP')    & SRNG=[0,30]    & AYTITLE=UNITS('TEMP',/NO_UNIT)+' Anomaly ' + UNITS('TEMP',/NO_NAME) & PSTATS='AMEAN' & ARNG=[-5,5]  & ALG=0 & AMID=0 & ASTATS='AMEAN' & AYTICKS=[] & END
      'CHLOR_A': BEGIN & SYTITLE=UNITS('CHLOR_A') & SRNG=[0.0,3.0] & AYTITLE=UNITS('CHLOR_A',/NO_UNIT) + ' Ratio Anomaly'                & PSTATS='MED'   & ARNG=[0.2,6] & ALG=1 & AMID=1 & ASTATS='AMEAN' & AYTICKS=[0.33,1,3.33] & END
      'PPD':     BEGIN & SYTITLE=UNITS('PPD')     & SRNG=[0.0,2.2] & AYTITLE=UNITS('PPD',/NO_UNIT) + ' Ratio Anomaly'                    & PSTATS='MED'   & ARNG=[0.3,3] & ALG=1 & AMID=1 & ASTATS='AMEAN' & AYTICKS=[] & END
    ENDCASE
    
    FOR H=0, N_ELEMENTS(SHAPES)-1 DO BEGIN
      SHAPE = VERSTR.SHAPEFILES.(H)
      NAMES = SHAPE.SUBAREA_NAMES
      TITLES = SHAPE.SUBAREA_TITLES
            
      FOR N=0, N_ELEMENTS(NAMES)-1 DO BEGIN
        ANAME = NAMES[N]
        CASE ANAME OF
          'MAB': PLT_TITLE = 'Mid-Atlantic Bight'
          'GOM': PLT_TITLE = 'Gulf of Maine'
          'GB':  PLT_TITLE = 'Georges Bank'
          'SS':  PLT_TITLE = 'Scotian Shelf'
        ENDCASE
        PSTR = STRUCT[WHERE(STRUCT.PROD EQ APROD AND STRUCT.SUBAREA EQ ANAME,/NULL)]
        ASTR = ASTRUCT[WHERE(ASTRUCT.PROD EQ APROD AND ASTRUCT.SUBAREA EQ ANAME,/NULL)]
        IF PSTR EQ [] THEN CONTINUE ; STOP
        
        FOR R=0, N_ELEMENTS(PERIODS)-1 DO BEGIN
          PER = PERIODS[R]
          CASE PER OF
            'W': BEGIN & NDATES = 52 & CPER = 'WEEK' & END
            'M': BEGIN & NDATES = 12 & CPER = 'MONTH' & END
          ENDCASE
          
          CSTR = PSTR[WHERE(PSTR.PERIOD_CODE EQ CPER,/NULL)]
          IF CSTR EQ [] THEN STOP ; CONTINUE
          
          FOR T=0, N_ELEMENTS(TYPES)-1 DO BEGIN
            ATYP = TYPES[T]
                  
            CPNGFILE = DIRPLT + PER + '_' + MIN(YEARS) + '_' + MAX(YEARS) + '-' + ANAME + '-' + APROD + '-' + ATYP + '-TIMESERIES.PNG'
            PNGFILES = DIRPLT + PER + '_' + YEARS + '-' + ANAME + '-' + APROD + '-' + ATYP + '-TIMESERIES.PNG'
            
            IF FILE_MAKE(DATFILE, [CPNGFILE,PNGFILES], OVERWRITE=OVERWRITE) EQ 0 THEN GOTO, MAKEMOVIE
          
            CDATE = DATE_2JD(YDOY_2DATE('2100',DATE_2DOY(PERIOD_2DATE(CSTR.PERIOD))))
            CASE ATYP OF
              'STATS': BEGIN & CDATA = GET_TAG(CSTR,PSTATS) & YRNG=SRNG & YTLE=SYTITLE & YLG=0 & YTICKNAMES=[] & YTICKS=[] & END
              'ANOMS': BEGIN & CDATA = REPLICATE(AMID,N_ELEMENTS(CSTR)) & YTLE=AYTITLE & YRNG=ARNG & YLG=ALG & IF AYTICKS NE [] THEN YTICKNAMES=NUM2STR(AYTICKS,DECIMALS=1) ELSE YTICKNAMES=[] & YTICKS=AYTICKS & END
            ENDCASE
          
            DIMS = [1000,600]
            THICK = 3
            FONT_SIZE = 12
            
            OUTFILES = []
            FOR Y=0, N_ELEMENTS(YEARS)-1 DO BEGIN
              PCLT = PLOT(CDATE,CDATA,THICK=THICK,FONT_SIZE=FONT_SIZE,TITLE=PLT_TITLE,YLOG=YLG,BUFFER=BUFFER,$
                XRANGE=AX.JD,YRANGE=YRNG,XTICKNAME=AX.TICKNAME,XTICKVALUES=AX.TICKV,XMINOR=0,XSTYLE=1,YMAJOR=YMAJOR,YTICKNAME=YTICKNAMES,YTICKV=YTICKS,YTITLE=YTLE,DIMENSIONS=DIMS,MARGIN=[0.08,0.08,0.08,0.08])
              IF Y EQ 0 and ATYP EQ 'STATS' THEN PCLT.SAVE, CPNGFILE
              
              YR = YEARS[Y]
              PNGFILE = PNGFILES[Y]
              
              CASE ATYP OF 
                'STATS': BEGIN & ISTR=PSTR & GET_STAT=PSTATS & END  
                'ANOMS': BEGIN & ISTR=ASTR & GET_STAT=ASTATS & END
              ENDCASE   
              
              YSTR = ISTR[WHERE(ISTR.PERIOD_CODE EQ PER AND DATE_2YEAR(PERIOD_2DATE(ISTR.PERIOD)) EQ YR AND ISTR.SENSOR EQ DSET,/NULL)]
              TSTR = ISTR[WHERE(ISTR.PERIOD_CODE EQ PER AND DATE_2YEAR(PERIOD_2DATE(ISTR.PERIOD)) EQ YR AND ISTR.SENSOR EQ TSET,/NULL)]
              
           ;   DSTR = ASTR[WHERE(ASTR.PERIOD_CODE EQ PER AND DATE_2YEAR(PERIOD_2DATE(ASTR.PERIOD)) EQ YR,/NULL)] 
              IF YSTR EQ [] THEN CONTINUE
              
              YDATE = DATE_2JD(YDOY_2DATE('2100',DATE_2DOY(PERIOD_2DATE(YSTR.PERIOD))))
              YDATA = GET_TAG(YSTR,GET_STAT)
                            
              IF N_ELEMENTS(YDATE) GT 1 THEN PY = PLOT(YDATE,YDATA,COLOR='RED',/CURRENT,/OVERPLOT,THICK=THICK);,XRANGE=AX.JD,YRANGE=[MR1(P),MR2(P)],XTICKNAME=AX.TICKNAME,XTICKVALUES=AX.TICKV,XMINOR=0,XSTYLE=1)
              IF TSTR NE [] THEN BEGIN
                TDATE = DATE_2JD(YDOY_2DATE('2100',DATE_2DOY(PERIOD_2DATE(TSTR.PERIOD))))
                TDATA = GET_TAG(TSTR,GET_STAT)
                IF N_ELEMENTS(TDATE) GT 1 THEN PT = PLOT(TDATE,TDATA,COLOR='RED',SYMBOL='CIRCLE',SYM_FILLED=0,LINESTYLE='DASHED',/CURRENT,/OVERPLOT,THICK=THICK)
              ENDIF
              TN = TEXT(0.85,0.85,YR,TARGET=PY,FONT_SIZE=14,FONT_COLOR='RED',FONT_STYLE='BOLD')
    
              FOR YRS=0, N_ELEMENTS(YEARS)-1 DO BEGIN
                AYR = YEARS[YRS]
                IF AYR EQ YR THEN CONTINUE
                
                YSTR = ISTR[WHERE(ISTR.PERIOD_CODE EQ PER AND DATE_2YEAR(PERIOD_2DATE(ISTR.PERIOD)) EQ AYR AND ISTR.SENSOR EQ DSET,/NULL)]
                IF YSTR EQ [] THEN CONTINUE
                YDATE = DATE_2JD(YDOY_2DATE('2100',DATE_2DOY(PERIOD_2DATE(YSTR.PERIOD))))
                YDATA = GET_TAG(YSTR,GET_STAT)
                IF N_ELEMENTS(YDATE) GT 1 THEN PY = PLOT(YDATE,YDATA,COLOR='LIGHT_GREY',/CURRENT,/OVERPLOT,THICK=1);,XRANGE=AX.JD,YRANGE=[MR1(P),MR2(P)],XTICKNAME=AX.TICKNAME,XTICKVALUES=AX.TICKV,XMINOR=0,XSTYLE=1)
              ENDFOR ; YRS
    
              PY.SAVE, PNGFILE
              PY.CLOSE
              OUTFILES = [OUTFILES,PNGFILE]
              
            ENDFOR ; YEARS
            
            
            MAKEMOVIE:
            FPS = 3
            MOVIE_FILE = DIR_MOV + PER + '_' + MIN(YEARS) + '_' + MAX(YEARS) + '-' + ANAME + '-' + APROD + '-' + ATYP + '-TIMESERIES.webm'
            IF FILE_MAKE(OUTFILES,MOVIE_FILE) THEN MAKE_MOVIE, OUTFILES, MOVIE_FILE=MOVIE_FILE, FRAME_SEC=FPS
            
          ENDFOR ; TYPES  
        ENDFOR ; PLOT_PERIODS  
      ENDFOR ; NAMES
    ENDFOR ; SHAPEFILES
  ENDFOR ; PRODS




END ; ***************** End of SOE_TIMESERIES_ANIMATION *****************
