; $ID:	SOE_MAIN.PRO,	2020-09-01-14,	USER-KJWH	$
  PRO SOE_MAIN, VERSION, SUBAREA=SUBAREA, BUFFER=BUFFER, VERBOSE=VERBOSE, OVERWRITE=OVERWRITE, $
                MAKE_NETCDFS        = MAKE_NETCDFS, $     ; Create NETCDF files
                DATA_EXTRACTS       = DATA_EXTRACTS, $    ; Extract data for the SOE report
                ANNUAL_COMPOSITE    = ANNUAL_COMPOSITE, $ ; Create maps and subarea extracted plots for each year
                PP_REQ_EXTRACTS     = PP_REQ_EXTRACTS, $  ; Extract and calculate the annual PP data for the Primary Production Required (or Fisheries Production Potential) model
                PHYSIZE_PLOTS       = PHYSIZE_PLOTS,$     ; Create phytoplankton size specific plots, composites and moves
                WEEKLY_PLOTS        = WEEKLY_PLOTS, $     ; Create weekly plots of CHL and PP
                MOVIES              = MOVIES,$            ; Create animations
                COMPARE_PRODS       = COMPARE_PRODS, $    ; Run COMPARE_SAT_PRODS and COMPARE_SAT_SENSORS to compare data
                ANNUAL_COMPARE      = ANNUAL_COMPARE, $   ; Create maps and subarea extracted plots to compare the annual data between sensors
                
                
                MONTHLY_TIMESERIES  = MONTHLY_TIMESERIES, $
                
                SEASONAL_COMPS      = SEASONAL_COMPS, $
                PFT_COMPS           = PFT_COMPS, $
                ANOMALY_MAP         = ANOMALY_MAP, $
                PERCENT_PRODUCTION  = PERCENT_PRODUCTION
                

;+
; NAME:
;   SOE_MAIN
;
; PURPOSE:
;   Main program for generating data and plots for the annual State of the Ecosystem reports
;
; CATEGORY:
;   MAIN
;
; CALLING SEQUENCE:
;   SOE_MAIN, VERSION, [SWITCHES for various steps]
;
; REQUIRED INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   VERSION...... The name of the version 
;   OUTPUT_MAP... The name of the output map for plots etc [default=NES]
;   SUBAREA...... The name of the SUBAREA for data extractions [default=NES_EPU_NOESTUARIES]
;   MAKE_NETCDFS. Run SOE_NETCDF program
;
; KEYWORD PARAMETERS:
;   BUFFER....... Buffer the plotting steps
;   VERBOSE...... Print steps
;   OVERWRITE.... Overwrite existing files
;
; OUTPUTS:
;   Data and plots for the State of the Ecosystem reports
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
;   For previous versions, see EDAB_SOE
;   
;   
; COPYRIGHT: 
; Copyright (C) 2020, Department of Commerce, National Oceanic and Atmospheric Administration, National Marine Fisheries Service,
;   Northeast Fisheries Science Center, Narragansett Laboratory.
;   This software may be used, copied, or redistributed as long as it is not sold and this copyright notice is reproduced on each copy made.
;   This routine is provided AS IS without any express or implied warranties whatsoever.
;
; AUTHOR:
;   This program was written on September 01, 2020 by Kimberly J. W. Hyde, Northeast Fisheries Science Center | NOAA Fisheries | U.S. Department of Commerce, 28 Tarzwell Dr, Narragansett, RI 02882
;    
; MODIFICATION HISTORY:
;   Sep 01, 2020 - KJWH: Initial code written - adapted from EDAB_SOE
;-
; ****************************************************************************************************
  ROUTINE_NAME = 'SOE_MAIN'
  COMPILE_OPT IDL2
  SL = PATH_SEP()
  
  DIR_PROJECT = !S.SOE
  
  IF NONE(VERSION)    THEN VERSION = 'V2022'
  IF NONE(BUFFER)     THEN BUFFER  = 0
  IF NONE(VERBSOE)    THEN VERBOSE = 0
   

; ===> Manually adjust the SOE program steps as needed
  IF NONE(MAKE_EPU_MAPS)          THEN MAKE_EPU_MAPS     = ''
  IF NONE(MAKE_NETCDFS)           THEN MAKE_NETCDFS      = ''
  IF NONE(DATA_EXTRACTS)          THEN DATA_EXTRACTS     = ''
  IF NONE(PP_REQ_EXTRACTS)        THEN PP_REQ_EXTRACTS   = ''
  IF NONE(PHYSIZE_PLOTS)          THEN PHYSIZE_PLOTS     = ''
  IF NONE(WEEKLY_PLOTS)           THEN WEEKLY_PLOTS      = ''
  IF NONE(ANNUAL_COMPOSITES)      THEN ANNUAL_COMPOSITES = ''
  IF NONE(SST_PNGS)               THEN SST_PNGS          = 'Y'
  IF NONE(MOVIES)                 THEN MOVIES            = 'Y'
  IF NONE(COMPARE_PRODUCTS)       THEN COMPARE_PRODUCTS  = ''
  
; ===> Loop through versions
  FOR V=0, N_ELEMENTS(VERSION)-1 DO BEGIN
    VER = VERSION[V]
    VERSTR = SOE_VERSION_INFO(VER)
  
    IF KEYWORD_SET(MAKE_NETCDFS)      THEN SOE_NETCDFS, VER  
    IF KEYWORD_SET(DATA_EXTRACTS)     THEN SOE_SUBAREA_EXTRACTS, VER
    IF KEYWORD_SET(PP_REQ_EXTRACTS)   THEN SOE_PP_REQUIRED, VER
    IF KEYWORD_SET(PHYSIZE_PLOTS)     THEN SOE_PHYTOSIZE_PLOT, VER, BUFFER=1
    IF KEYWORD_SET(WEEKLY_PLOTS)      THEN SOE_WEEKLY_PLOTS, VER, BUFFER=BUFFER
    IF KEYWORD_SET(ANNUAL_COMPOSITES) THEN SOE_ANNUAL_COMPOSITE, VER  
    IF KEYWORD_SET(SST_PNGS)          THEN SOE_SST, ['V2021','V2022'], BUFFER=BUFFER
       
    IF KEYWORD_SET(MAKE_EPU_MAPS) THEN BEGIN
      MAP_OUT   = ['GOM','NEC']
      EPUS      = 'NES_EPU_EXTENDED'
      NAMES     = ['MAB','GOM','GB']
      SUBTITLES = ['Mid-Atlantic Bight','Gulf of Maine','Georges Bank']
      CLRS      = LIST([217,241,253],[193,232,251],[0,173,238],[37,64,143],[0,104,181],[0,83,159])

      DIR_MAPS = VERSTR.DIRS.DIR_EPU_MAPS
      LOGO = !S.PROJECTS + 'EDAB' + SL + 'IEA_WEBSITE' + SL + 'NOAA2.png'
      LG = READ_PNG(LOGO) & LG = LG[*,*,380:999]
      BATHY = 400

      BUFFER = 0
      ADD_LOGO = 0
      ADD_LABELS = 1
      PAL_LANDMASK,RR,GG,BB
      FOR N=0, N_ELEMENTS(CLRS)-1 DO BEGIN
        CLR = CLRS[N]
        RR[N+10] = CLR[0]
        GG[N+10] = CLR[1]
        BB[N+10] = CLR[2]
      ENDFOR
      ARR = BYTARR(3,N_ELEMENTS(RR))
      ARR[0,*] = RR
      ARR[1,*] = GG
      ARR[2,*] = BB
      SCOLORS = [10,11,12,13,14]

      FOR M=0, N_ELEMENTS(MAP_OUT)-1 DO BEGIN
        AMAP = MAP_OUT[M]
        MS = MAPS_SIZE(AMAP,PX=PX,PY=PY)
        EXT = READ_SHPFILE(EPUS, MAPP=AMAP, COLOR=COLORS, VERBOSE=VERBOSE)
        MAPS_SET,AMAP
          GB  = CONVERT_COORD(EXT.GB.OUTLINE_LONS,EXT.GB.OUTLINE_LATS,/TO_DEVICE)   & GBX  = REFORM(GB[0,*])  & GBY  = REFORM(GB[1,*])
          GOM = CONVERT_COORD(EXT.GOM.OUTLINE_LONS,EXT.GOM.OUTLINE_LATS,/TO_DEVICE) & GOMX = REFORM(GOM[0,*]) & GOMY = REFORM(GOM[1,*])
          MAB = CONVERT_COORD(EXT.MAB.OUTLINE_LONS,EXT.MAB.OUTLINE_LATS,/TO_DEVICE) & MABX = REFORM(MAB[0,*]) & MABY = REFORM(MAB[1,*])
        ZWIN

        LAND = READ_LANDMASK(AMAP)
        LSTR = READ_LANDMASK(AMAP,/STRUCT)
        TOPO = READ_BATHY(AMAP)
        LTB  = WHERE(TOPO LT BATHY AND TOPO NE MISSINGS(0.0))
        GTB  = WHERE(TOPO GE BATHY AND TOPO NE MISSINGS(0.0))
        TBLK = MAPS_BLANK(AMAP,FILL=254)
        TBLK[LTB] = SCOLORS[0]
        TBLK[GTB] = SCOLORS[1]
        TBLK[LSTR.LAND] = 254
        TBLK[LSTR.LAKE] = 0
        TBLK[LSTR.COAST]= 254
        TBLK[EXT.GOM.SUBS] = SCOLORS[3]
        TBLK[EXT.GB.SUBS]  = SCOLORS[2]
        IF AMAP EQ 'NEC' THEN TBLK[EXT.MAB.SUBS] = SCOLORS[4]
        T = IMAGE(TBLK,RGB_TABLE=ARR,DIMENSIONS=[MS.PX,MS.PY],MARGIN=0)
    ;    T = IMAGE(LG, RGB_TABLE=ARR,DIMENSIONS=[50,50], POSITION=[5,90,55,140],/CURRENT,/DEVICE)
        ; P1 = POLYGON(GBX,GBY, /FILL_BACKGROUND,FILL_TRANSPARENCY=10,FILL_COLOR=CLRS(2),/DEVICE)
        ; P2 = POLYGON(GOMX,GOMY, /FILL_BACKGROUND,FILL_TRANSPARENCY=90,FILL_COLOR=CLRS(3),/DEVICE)
        ; P3 = POLYGON(MABX,MABY, /FILL_BACKGROUND,FILL_TRANSPARENCY=50,FILL_COLOR=CLRS(4),/DEVICE)
  ;      T1 = TEXT(6,  70, 'NOAA', FONT_COLOR=CLRS[3], FONT_SIZE=10,/DEVICE)
  ;      T2 = TEXT(55, 70, 'FISHERIES', FONT_COLOR=CLRS[2], FONT_SIZE=10,/DEVICE)
  ;      T3 = TEXT(6,  40, 'Northeast Fisheries !CScience Center', FONT_COLOR=CLRS(2), FONT_SIZE=8,/DEVICE)
        T.SAVE,DIR_MAPS+AMAP+'_EPU_PLAIN.PNG',RESOLUTION=600

        BD = POLYGON([0,MS.PX,MS.PX,0,0],[0,0,MS.PY,MS.PY,0],COLOR='BLACK',THICK=3,/DEVICE,TARGET=T,FILL_BACKGROUND=0)
        T.SAVE,DIR_MAPS+AMAP+'_EPU_BORDER.PNG',RESOLUTION=600

        FSZ = 24 & FC = 'WHITE'
        IF AMAP EQ 'NEC' THEN BEGIN
          A = TEXT(210,370,'Mid-Atlantic',FONT_SIZE=FSZ,FONT_STYLE='BOLD',COLOR=FC,/DEVICE,ORIENTATION=45) ; TM = TEXT(310,540,'MAB',FONT_SIZE=FSZ,FONT_STYLE='BOLD',COLOR=FC,/DEVICE)
          B = TEXT(620,565,'Georges!CBank', FONT_SIZE=FSZ,FONT_STYLE='BOLD',COLOR=FC,/DEVICE,ALIGNMENT=0.5) ; TB = TEXT(650,650,'GB', FONT_SIZE=FSZ,FONT_STYLE='BOLD',COLOR=FC,/DEVICE)
          C = TEXT(565,730,'Gulf of!CMaine',FONT_SIZE=FSZ,FONT_STYLE='BOLD',COLOR=FC,/DEVICE,ALIGNMENT=0.5) ; TM = TEXT(590,810,'GOM',FONT_SIZE=FSZ,FONT_STYLE='BOLD',COLOR=FC,/DEVICE)
        ENDIF ELSE BEGIN
          B = TEXT(225,85,'Georges!CBank', FONT_SIZE=FSZ,FONT_STYLE='BOLD',COLOR=FC,/DEVICE,ALIGNMENT=0.5) ; TB = TEXT(650,650,'GB', FONT_SIZE=FSZ,FONT_STYLE='BOLD',COLOR=FC,/DEVICE)
          C = TEXT(190,310,'Gulf of!CMaine',FONT_SIZE=FSZ,FONT_STYLE='BOLD',COLOR=FC,/DEVICE,ALIGNMENT=0.5) ; TM = TEXT(590,810,'GOM',FONT_SIZE=FSZ,FONT_STYLE='BOLD',COLOR=FC,/DEVICE)
        ENDELSE
        T.SAVE,DIR_MAPS+AMAP+'_EPU-LABELS.PNG'
        T.CLOSE

      ENDFOR
      STOP
    ENDIF ; DO_EPU_MAP
    
    
    
    
    
    
    IF KEYWORD_SET(MOVIES) THEN BEGIN
      DIR_MOVIE = VERSTR.DIRS.DIR_MOVIE
      YR = VERSTR.INFO.SOE_YEAR
      
      
      F = GET_FILES('MUR',PRODS='SST',PERIOD='D',DATERANGE=YR, MAPS='L3B2')
      DIR_PNGS = DIR_MOVIE + 'SST' + SL & DIR_TEST, DIR_PNGS
      PRODS_2PNG, F, PROD='SST_0_30', MAPP='NES', /ADD_CB, DIR_OUT=DIR_PNGS, BUFFER=1, ADD_BATHY=200, /ADD_DB, CB_TYPE=3, PAL='PAL_ANOM_BGR'
      PNGFILES = FLS(DIR_PNGS+'*.*',DATERANGE=YR)
      FPS = 15
      MOVIE_FILE = DIR_MOVIE + YR + '-SST-MUR-NES-FPS_'+ROUNDS(FPS)+'.mp4'
      MAKE_MOVIE, PNGFILES, MOVIE_FILE=MOVIE_FILE, FRAME_SEC=FPS
      
      F = GET_FILES('OCCCI',PRODS='CHLOR_A-CCI',PERIOD='W',DATERANGE=YR, MAPS='L3B2', FILE_TYPE='ANOM')
      DIR_PNGS = DIR_MOVIE + 'OCCCI-CHLOR_A' + SL & DIR_TEST, DIR_PNGS
      PRODS_2PNG, F, MAPP='NES',CB_TITLE='Chlorophyll Anomaly', PAL=VERSTR.PROD_INFO.CHLOR_A.ANOM_PAL, SPROD=VERSTR.PROD_INFO.CHLOR_A.ANOM_SCALE,/ADD_CB, DIR_OUT=DIR_PNGS, BUFFER=1, /ADD_DB, CB_TYPE=3
      PNGFILES = FLS(DIR_PNGS+'*.*',DATERANGE=YR)
      FPS = 15
      MOVIE_FILE = DIR_MOVIE + 'W_' + YR + '-CHLOR_A-OCI-MODISA-NES-ANOMS-FPS_'+ROUNDS(FPS)+'.webm'
      MAKE_MOVIE, PNGFILES, MOVIE_FILE=MOVIE_FILE, FRAME_SEC=FPS




      
      
      
    ENDIF
    
    IF KEYWORD_SET(COMPARE_PRODUCTS) THEN BEGIN
      DATERANGE = VERSTR.INFO.DATERANGE
      SHPFILES = ['NES_EPU_NOESTUARIES','LMES66']
      PRODS = ['CHLOR_A-OCI','CHLOR_A-PAN','PPD-VGPM2']
      FOR ITH=0, N_ELEMENTS(SHPFILES)-1 DO BEGIN
        SHPFILE = SHPFILES[ITH]
        IF SHPFILE EQ 'LMES66' THEN SUBAREAS = 'NORTHEAST_U_S_CONTINENTAL_SHELF' ELSE SUBAREAS = []
        FOR NTH=0, N_ELEMENTS(PRODS)-1 DO BEGIN
          APROD = PRODS[NTH]
          IF APROD EQ 'CHLOR_A-OCI' THEN OPROD = 'CHLOR_A-CCI' ELSE OPROD = APROD
          SEAWIFS = ' ,SEAWIFS,'+APROD+', '
          MODISA  = ' ,MODISA,' +APROD+', '
          VIIRS   = ' ,VIIRS,'  +APROD+', '
          JPSS1   = ' ,JPSS1,'  +APROD+', '
          SA      = ' ,SA,'     +APROD+', '
          SAV     = ' ,SAV,'    +APROD+', '
          SAVJ    = ' ,SAVJ,'   +APROD+', '
          OCCCI   = ' ,OCCCI,'  +OPROD+', '
          OCCCI5  = 'VERSION_5.0,OCCCI,'+OPROD+', '    
          COMPARE_SAT_PRODS, COMBO=STRJOIN([OCCCI5,OCCCI,MODISA,JPSS1,VIIRS],';'),PERIODS='W',SHPFILES=SHPFILE,SUBAREAS=SUBAREAS,DIR_OUT=VERSTR.DIRS.DIR_COMPARE,DATERANGE=['2017','2020'],BUFFER=0
          COMPARE_SAT_PRODS, COMBO=STRJOIN([OCCCI5,OCCCI,SEAWIFS,MODISA,VIIRS,JPSS1],';'),PERIODS=['M','W','A','MONTH'],SHPFILES=SHPFILE,SUBAREAS=SUBAREAS,DIR_OUT=VERSTR.DIRS.DIR_COMPARE,DATERANGE=DATERANGE,BUFFER=0    
          COMPARE_SAT_PRODS, COMBO=STRJOIN([OCCCI5,OCCCI,SA],';'),PERIODS=['M','W','A','MONTH'],SHPFILES=SHPFILE,SUBAREAS=SUBAREAS,DIR_OUT=VERSTR.DIRS.DIR_COMPARE,DATERANGE=DATERANGE,BUFFER=0
          COMPARE_SAT_PRODS, COMBO=STRJOIN([OCCCI5,OCCCI,SEAWIFS,MODISA],';'),PERIODS=['M','W','A','MONTH'],SHPFILES=SHPFILE,SUBAREAS=SUBAREAS,DIR_OUT=VERSTR.DIRS.DIR_COMPARE,DATERANGE=DATERANGE,BUFFER=0
          
        ENDFOR ; PRODS
      ENDFOR ; SHPFILES   
    ENDIF

  ENDFOR ; VERSION



END ; End of SOE_MAIN
