; $ID:	SOE_MAIN.PRO,	2024-01-30-21,	USER-KJWH	$
  PRO SOE_MAIN, VERSION, SUBAREA=SUBAREA, BUFFER=BUFFER, VERBOSE=VERBOSE, OVERWRITE=OVERWRITE, $
                MAKE_NETCDFS        = MAKE_NETCDFS, $       ; Create NETCDF files
                DATA_EXTRACTS       = DATA_EXTRACTS, $      ; Extract data for the SOE report
                ANNUAL_COMPOSITE    = ANNUAL_COMPOSITE, $   ; Create maps and subarea extracted plots for each year
                PP_REQ_EXTRACTS     = PP_REQ_EXTRACTS, $    ; Extract and calculate the annual PP data for the Primary Production Required (or Fisheries Production Potential) model
                PHYSIZE_COMPOSITES  = PHYSIZE_COMPOSITES, $ ; Create composites and animations of the phytoplankton size class data
                PHYSIZE_PLOTS       = PHYSIZE_PLOTS,$       ; Create phytoplankton size specific plots, composites and moves
                WEEKLY_PLOTS        = WEEKLY_PLOTS, $       ; Create weekly plots of CHL and PP
                SEASONAL_COMPS      = SEASONAL_COMPS, $     ; Make seasonal composites
                MOVIES              = MOVIES,$              ; Create animations
                COMPARE_PRODS       = COMPARE_PRODS, $      ; Run COMPARE_SAT_PRODS and COMPARE_SAT_SENSORS to compare data
                ANNUAL_COMPARE      = ANNUAL_COMPARE, $     ; Create maps and subarea extracted plots to compare the annual data between sensors
                MONTHLY_TIMESERIES  = MONTHLY_TIMESERIES, $
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
  
  PROJECT = 'SOE_PHYTOPLANKTON'
  DIR_PROJECT = GET_PROJECT_DIR(PROJECT)
  
  IF ~N_ELEMENTS(VERSION)  THEN VERSION = 'V2024'
  IF ~N_ELEMENTS(BUFFER)   THEN BUFFER  = 1
  IF ~N_ELEMENTS(VERBSOE) THEN VERBOSE = 0
   
; ===> Manually adjust the SOE program steps as needed
  IF ~N_ELEMENTS(MAKE_EPU_MAPS)      THEN MAKE_EPU_MAPS      = ''
  IF ~N_ELEMENTS(MAKE_NETCDFS)       THEN MAKE_NETCDFS       = ''
  IF ~N_ELEMENTS(DATA_UPDATE)        THEN DATA_UPDATE        = ''
  IF ~N_ELEMENTS(DATA_EXTRACTS)      THEN DATA_EXTRACTS      = 'Y'
  IF ~N_ELEMENTS(PP_REQ_EXTRACTS)    THEN PP_REQ_EXTRACTS    = 'Y'
  IF ~N_ELEMENTS(PHYSIZE_PLOTS)      THEN PHYSIZE_PLOTS      = 'Y'
  IF ~N_ELEMENTS(PHYSIZE_COMPOSITES) THEN PHYSIZE_COMPOSITES = ''
  IF ~N_ELEMENTS(WEEKLY_PLOTS)       THEN WEEKLY_PLOTS       = 'Y'
  IF ~N_ELEMENTS(MONTHLY_TIMESERIES) THEN MONTHLY_TIMESERIES = 'Y'
  IF ~N_ELEMENTS(STACKED_TIMESERIES) THEN STACKED_TIMESERIES = 'Y'
  IF ~N_ELEMENTS(ANNUAL_COMPOSITES)  THEN ANNUAL_COMPOSITES  = ''
  IF ~N_ELEMENTS(SST_PNGS)           THEN SST_PNGS           = ''
  IF ~N_ELEMENTS(SEASONAL_COMPS)     THEN SEASONAL_COMPS     = ''
  IF ~N_ELEMENTS(MOVIES)             THEN MOVIES             = ''
  IF ~N_ELEMENTS(COMPARE_PRODUCTS)   THEN COMPARE_PRODUCTS   = ''
  
; ===> Loop through versions
  FOR V=0, N_ELEMENTS(VERSION)-1 DO BEGIN
    VER = VERSION[V]
    VERSTR = PROJECT_VERSION_DEFAULT(PROJECT,VERSION=VER)
      
    IF VERSTR.INFO.YEAR GE '2023' THEN BEGIN
      
      IF KEYWORD_SET(DATA_UPDATE) THEN BEGIN
        BATCH_DATASET, 'MUR',  /NC_2STACKED,/DOWNLOAD_FILES,/DO_STATS
        BATCH_DATASET, 'GLOBCOLOUR', /NC_2STACKED, /PSC,/PPD, STAT_PRODS=['CHLOR_A-GSM','PPD-VGPM2'],/DO_STATS, /DO_ANOMS, /DOWNLOAD_FILES, DOWNLOAD_DATERANGE=['20231201',DATE_NOW()]
        BATCH_DATASET, 'OCCCI',/NC_2STACKED, MAPS='L3B4', /PSC, /PPD, STAT_PRODS=['CHLOR_A-CCI','PPD-VGPM2'],/DO_STATS, /DO_ANOMS, /DOWNLOAD_FILES
        BATCH_DATASET, 'ACSPO',/DOWNLOAD_FILES, /NC_2STACKED, /DO_STATS, /DO_ANOMS
        BATCH_DATASET, 'ACSPO_NRT',/DOWNLOAD_FILES, /NC_2STACKED, /DO_STATS, /DO_ANOMS
      ENDIF
         
      IF KEYWORD_SET(MAKE_NETCDFS)       THEN STOP;SOE_NETCDFS, VER
      IF KEYWORD_SET(DATA_EXTRACTS)      THEN BEGIN & PROJECT_SUBAREA_EXTRACT, VERSTR & SOE_EXTRACTS_2LONGFORM, VERSTR, DIR_DATA=DIR_OUT & ENDIF
      IF KEYWORD_SET(PP_REQ_EXTRACTS)    THEN BEGIN & SOE_PP_REQUIRED, VERSTR & SOE_EXTRACTS_2LONGFORM, VERSTR, DIR_DATA=DIR_OUT,/PPREQUIRED & ENDIF
      IF KEYWORD_SET(PHYSIZE_PLOTS)      THEN SOE_PHYTOSIZE_PLOT, VER, BUFFER=1
      IF KEYWORD_SET(PHYSIZE_COMPOSITES) THEN STOP ;SOE_PHYTOSIZE_COMPOSITES, VER, BUFFER=1
      IF KEYWORD_SET(WEEKLY_PLOTS)       THEN SOE_WEEKLY_PLOTS, VER, BUFFER=BUFFER
      IF KEYWORD_SET(STACKED_TIMESERIES) THEN SOE_STACKED_TIMESERIES_PLOT, VERSTR, BUFFER=1
      IF KEYWORD_SET(ANNUAL_COMPOSITES)  THEN SOE_ANNUAL_COMPOSITE, VER, BUFFER=BUFFER
      IF KEYWORD_SET(SST_PNGS)           THEN STOP;SOE_SST,VER, BUFFER=BUFFER
      IF KEYWORD_SET(MONTHLY_TIMESERIES) THEN SOE_MONTHLY_TIMESERIES, VERSTR, BUFFER=0
    ENDIF ELSE BEGIN  
      VERSTR = SOE_VERSION_INFO(VER)
      IF KEYWORD_SET(MAKE_NETCDFS)       THEN SOE_NETCDFS, VER
      IF KEYWORD_SET(DATA_EXTRACTS)      THEN SOE_SUBAREA_EXTRACTS, VER
      IF KEYWORD_SET(PP_REQ_EXTRACTS)    THEN SOE_PP_REQUIRED, VER
      IF KEYWORD_SET(PHYSIZE_PLOTS)      THEN SOE_PHYTOSIZE_PLOT, VER, BUFFER=1
      IF KEYWORD_SET(PHYSIZE_COMPOSITES) THEN SOE_PHYTOSIZE_COMPOSITES, VER, BUFFER=1
      IF KEYWORD_SET(WEEKLY_PLOTS)       THEN SOE_WEEKLY_PLOTS, VER, BUFFER=BUFFER
      IF KEYWORD_SET(STACKED_TIMESERIES) THEN SOE_STACKED_TIMESERIES_PLOT, VER, BUFFER=1
      IF KEYWORD_SET(ANNUAL_COMPOSITES)  THEN SOE_ANNUAL_COMPOSITE, VER, BUFFER=BUFFER
      IF KEYWORD_SET(SST_PNGS)           THEN SOE_SST,VER, BUFFER=BUFFER
    ENDELSE
    
    ; CHL bloom
    MP = 'NES'
    SDR = ['20230101','20230930']
    MTHS = YEAR_MONTH_RANGE(SDR[0],SDR[1])
    BUFFER = 1
    OVERWRITE = 0
    SPAL = 'PAL_NAVY_GOLD'
    APAL = 'PAL_BLUEGREEN_ORANGE'
    
    LONS = [-76,-72,-68,-64] & LATS = [36, 40, 44]
    SFILE = GET_FILES('OCCCI', PRODS='CHLOR_A-CCI', PERIODS='M', DATERANGE='2023', MAPS='L3B2') & SFP = PARSE_IT(SFILE)
    AFILE = GET_FILES('OCCCI', PRODS='CHLOR_A-CCI', PERIODS='M', DATERANGE='2023', MAPS='L3B2', FILE_TYPE='STACKED_ANOMS') & AFP = PARSE_IT(AFILE)
    
    SPROD_SCALE = 'CHLOR_A_0.1_10' & STICKNAMES=['0.1','0.3','1','3','10'] & STICKVALS=[0.1,0.3,1,3,10] & STITLE=UNITS('CHLOROPHYLL')
    APROD_SCALE = 'RATIO_0.1_10'   & ATICKNAMES=['-10x','-3x','0','3x','10x'] & ATICKVALS=[0.1,0.3,1,3,10] & ATITLE='Chlorophyll Anomaly'
    
    TYPES = 'ANOMS';['STATS','ANOMS']
    FOR T=0, N_ELEMENTS(TYPES)-1 DO BEGIN
      DIR_PLOTS = VERSTR.DIRS.DIR_PLOTS+'CHLOR_A' + SL + 'GOM_' + TYPES[T] + SL
      CASE TYPES[T] OF
        'STATS': BEGIN & FILE=SFILE & PROD_SCALE=SPROD_SCALE & TICKNAMES=STICKNAMES & TICKVALS=STICKVALS & TITLE=STITLE & END
        'ANOMS': BEGIN & FILE=AFILE & PROD_SCALE=APROD_SCALE & TICKNAMES=ATICKNAMES & TICKVALS=ATICKVALS & TITLE=ATITLE & END
      ENDCASE
      FOR W=0, N_ELEMENTS(MTHS)-1 DO BEGIN
        MPER = PERIOD_2STRUCT('M_'+MTHS[W])
        MDR = GET_DATERANGE(MPER.DATE_START, MPER.DATE_END)
        PNGFILE = DIR_PLOTS + REPLACE(SFP.NAME,SFP.PERIOD,'M_'+STRMID(MPER.DATE_START,0,6)) + '.png'
        IF FILE_MAKE(FILE,PNGFILE,OVERWRITE=OVERWRITE) EQ 0 THEN CONTINUE
        
        IMG = PROJECT_MAKE_IMAGE(VERSTR, FILE=FILE, PAL=SPAL, DATERANGE=MDR,BUFFER=BUFFER, RESIZE=1, MAPP=MP, PROD_SCALE=PROD_SCALE, $
          /ADD_BATHY, BATHY_DEPTH=200, BATHY_COLOR=0, BATHY_THICK=2,   _EXTRA=EXTRA)
          ;/ADD_COLORBAR, CB_POS=CB_POS, CB_SIZE=14, CB_TICKVALUES=TICKVALS, CB_TICKNAMES=TICKNAMES, CB_TITLE=TITLE,
          ;/ADD_LONLAT, LONS=LONS, LATS=LATS, CB_TICKSN=CB_TICKSN, $
          ;/ADD_BORDER, BORDER_THICK=8,
        
        MR = MAPS_READ(MP)
        CB_POS = [0.075, 0.85, 0.55, 0.89]
        CBAR, PROD_SCALE, IMG=IMG, FONT_SIZE=16, CB_TYPE=1, CB_POS=CB_POS, CB_TITLE=TITLE, PAL=SPAL,CB_TICKVALUES=TICKVALS, CB_TICKNAMES=TICKNAMES,_EXTRA=_EXTRA,RELATIVE=CB_RELATIVE, CB_OBJ=CB_IMG

          
        IMG.SAVE, PNGFILE
        IMG.CLOSE
      ENDFOR  
    ENDFOR  

stop    
    
    ; SST-GS image
    MP = 'NES'
    SDR = ['20230201','20231201']
    WKS = YEAR_WEEK_RANGE(SDR[0],SDR[1])
    BUFFER = 1
    OVERWRITE = 1
    DIR_PLOTS = VERSTR.DIRS.DIR_PLOTS + 'SST' + SL + 'NO_GS' + SL
    PAL = 'PAL_BLUEYELLOWRED'
    LONS = [-76,-72,-68,-64] & LATS = [36, 40, 44]
    FILE = GET_FILES('ACSPO', PRODS='SST', PERIODS='W', DATERANGE='2023',VERSION='V2.1') & FP = PARSE_IT(FILE)
    GSFILE = FILE_SEARCH(!S.IDL_DATA + 'GSmeanpath.csv')
    GS = CSV_READ(GSFILE)
    
    CANYONS = ['BLOCK_CANYON','HYDROGRAPHER_CANYON']
    MAB_CANYONS = READ_SHPFILE('MAB_CANYONS',MAPP=MP)
    SCALLOPS = ['ET_OPEN','ET_CLOSE']
    MAB_SCALLOPS = READ_SHPFILE('MAB_SCALLOPS',MAPP=MP)
    OUTLINES = []
;    FOR M=0, N_ELEMENTS(CANYONS)-1 DO BEGIN
;      OK = WHERE(TAG_NAMES(MAB_CANYONS) EQ CANYONS[M],/NULL)
;      IF OK EQ [] THEN STOP
;      OUTLINES = [OUTLINES,MAB_CANYONS.(OK).OUTLINE]
;    ENDFOR
;    FOR M=0, N_ELEMENTS(SCALLOPS)-1 DO BEGIN
;      OK = WHERE(TAG_NAMES(MAB_SCALLOPS) EQ SCALLOPS[M],/NULL)
;      IF OK EQ [] THEN STOP
;      OUTLINES = [OUTLINES,MAB_SCALLOPS.(OK).OUTLINE]
;    ENDFOR
    
    FOR W=0, N_ELEMENTS(WKS)-1 DO BEGIN
      WPER = PERIOD_2STRUCT('W_'+WKS[W])
      WDR = GET_DATERANGE(WPER.DATE_START, WPER.DATE_END)
      PNGFILE = DIR_PLOTS + REPLACE(FP.NAME,FP.PERIOD,STRJOIN(['D',STRMID(WPER.DATE_START,0,8),STRMID(WPER.DATE_END,0,8)],'_')) + '.png'
      IF FILE_MAKE(FILE,PNGFILE,OVERWRITE=OVERWRITE) EQ 0 THEN CONTINUE
      PROD_SCALE = 'SST_15_30' & TICKNAMES=['15','18','21','24','27','30'] & TICKVALS=[15,18,21,24,27,30] & FTICKNAMES=['60','65','70','75','80','85'] & FTICKVALS=[15.556,18.333,21.111,23.889,26.667,29.444] & CONTOUR_TEMP=28

      IF WPER.JD_START LE DATE_2JD(20230620) THEN BEGIN & PROD_SCALE='SST_5_25' & TICKNAMES=['5','10','15','20','25'] & TICKVALS=[5,10,15,20,25] & FTICKNAMES=['45','55','65','75'] & FTICKVALS=[7.222,12.778,18.333,23.889] & CONTOUR_TEMP=27 & CB_TICKSN = 8 & ENDIF
      IF WPER.JD_START LE DATE_2JD(20230401) THEN BEGIN & PROD_SCALE='SST_0_25' & TICKNAMES=['0','5','10','15','20','25'] & TICKVALS=[0,5,10,15,20,25] & FTICKNAMES=['35','45','55','65','75'] & FTICKVALS=[1.667,7.222,12.778,18.333,23.889] & CONTOUR_TEMP=27 & CB_TICKSN = 8 & ENDIF
      IF WPER.JD_START GE DATE_2JD(20230915) THEN BEGIN & PROD_SCALE='SST_12_28' & TICKNAMES=['12','16','20','24','28'] & TICKVALS=[12,16,20,24,28] & FTICKNAMES=['55','60','65','70','75','80'] & FTICKVALS=[12.778,15.556,18.333,21.111,23.889,26.667] & CONTOUR_TEMP=27 & CB_TICKSN = 8 & ENDIF
      IF WPER.JD_START GE DATE_2JD(20230929) THEN BEGIN & PROD_SCALE='SST_12_28' & TICKNAMES=['12','16','20','24','28'] & TICKVALS=[12,16,20,24,28] & FTICKNAMES=['55','60','65','70','75','80'] & FTICKVALS=[12.778,15.556,18.333,21.111,23.889,26.667]& CONTOUR_TEMP=26 & CB_TICKSN = 8 & ENDIF
      IF WPER.JD_START GE DATE_2JD(20231028) THEN BEGIN & PROD_SCALE='SST_7_28'  & TICKNAMES=['7','14','21','28'] & TICKVALS=[7,14,21,28] & FTICKNAMES=['45','50','55','60','65','70','75','80'] & FTICKVALS=[7.222,10.0,12.778,15.556,18.333,21.111,23.889,26.667]& CONTOUR_TEMP=25 & CB_TICKSN = 6 & ENDIF
      IMG = PROJECT_MAKE_IMAGE(VERSTR, FILE=FILE, PAL=PAL, DATERANGE=WDR,BUFFER=BUFFER, RESIZE=1, MAPP=MP, PROD_SCALE=PROD_SCALE, $
        /ADD_BATHY, BATHY_DEPTH=200, BATHY_COLOR=0, BATHY_THICK=2,$
        /ADD_CONTOURS, C_LEVELS=CONTOUR_TEMP,$
        /ADD_OUTLINE, OUTLINE_IMG=OUTLINES, OUT_COLOR=0, OUT_THICK=3,$
        ;/ADD_BORDER, BORDER_THICK=8, $
        ;/ADD_LONLAT, LONS=LONS, LATS=LATS, CB_TICKSN=CB_TICKSN, $
        ;/ADD_LINE, LLONS=GS.LON, LLATS=GS.LAT,LSTYLE=0,LCOLOR='PALE_TURQUOISE',LTHICK=10,$
        _EXTRA=EXTRA) ; LTRANSPARENT=50,
      
      MR = MAPS_READ(MP)
      CB_POS = [0.065, 0.85, 0.525, 0.89]
      CBAR, PROD_SCALE, IMG=IMG, FONT_SIZE=15, CB_TYPE=1, CB_POS=CB_POS, CB_TITLE=UNITS('TEMP'), PAL=PAL,CB_TICKVALUES=TICKVALS, CB_TICKNAMES=TICKNAMES,_EXTRA=_EXTRA,RELATIVE=CB_RELATIVE, CB_OBJ=CB_IMG
      
      IMGBLK = (REPLICATE(255B,2,2))
      OBJ = IMAGE(IMGBLK,RGB_TABLE=RGB_TABLE,/NODATA,/HIDE,BACKGROUND_COLOR=BACKGROUND_COLOR,TRANSPARENCY=100,POSITION = [0,0,0.001,0.001],BUFFER=BUFFER,/CURRENT)
      CBAR, PROD_SCALE, IMG=OBJ, FONT_SIZE=15, CB_TYPE=3, CB_POS=CB_POS, CB_TITLE='(!Uo!NF)', PAL=PAL, CB_TICKVALUES=FTICKVALS, CB_TICKNAMES=FTICKNAMES,RELATIVE=CB_RELATIVE, CB_OBJ=CB_IMG2
      
      PFILE, PNGFILE     
      IMG.SAVE, PNGFILE
      IMG.CLOSE
    ENDFOR  
    
    FILES = FILE_SEARCH(DIR_PLOTS + 'D*.png')
    FPS = 3
    MOVIE_FILE = DIR_PLOTS + '2023_SST.mp4'
    IF FILE_MAKE(FILES,MOVIE_FILE) THEN MAKE_MOVIE, FILES[0:-2], MOVIE_FILE=MOVIE_FILE, FRAME_SEC=FPS
        ;  SOE_TIMESERIES_ANIMATION, VERSTR, PRODS=['CHLOR_A','PPD','SST'], BUFFER=0
 
 stop
        SOE_TIMESERIES_ANIMATION, VERSTR, PRODS=['CHLOR_A','PPD','SST'], BUFFER=0
 stop     
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
    
    
    IF KEYWORD_SET(SEASONAL_COMPS) THEN BEGIN
      
      VERSTR = SOE_VERSION_INFO(VER)
      EPU_OUTLINE = VERSTR.INFO.SUBAREA_OUTLINE
      DIR_OUT = VERSTR.DIRS.DIR_COMP + 'SEASONAL' + SL & DIR_TEST, DIR_OUT
      YR = VERSTR.INFO.SOE_YEAR
  ; YR = '2020'    
      SEASONS = LIST(YR+['0101','0331'],YR+['0401','0630'],YR+['0701','0930'],YR+['1001','1231'])
      
      PRODS = ['CHLOR_A','PPD']
      TYPES = ['ANOMS','STATS']
      MAPOUT = 'NES'
      BUFFER = 0
      OCOLOR = 0
      OTHICK = 8
      
      FOR R=0, N_ELEMENTS(PRODS)-1 DO BEGIN
        APROD = PRODS[R]
        TAG = WHERE(TAG_NAMES(VERSTR.PROD_INFO) EQ APROD,/NULL)
        STR = VERSTR.PROD_INFO.(TAG)
        DSET = STR.DATASET        & DPROD = STR.PROD
        TSET = STR.TEMP_DATASET   & TPROD = STR.TEMP_PROD 
 ; TSET=DSET & TPROD=DPROD
      
        
        FOR T=0, N_ELEMENTS(TYPES)-1 DO BEGIN
          ATYPE = TYPES[T]
          CASE ATYPE OF
            'STATS': BEGIN & OPROD=STR.PROD_SCALE & PAL = STR.PAL &    & CTITLE = STR.PROD_TITLE & END 
            'ANOMS': BEGIN & OPROD=STR.ANOM_SCALE & PAL = STR.ANOM_PAL & CTITLE = STR.ANOM_TITLE & END 
          ENDCASE  
                          
          FF =     GET_FILES(DSET,PRODS=DPROD, PERIODS='M3', FILE_TYPE=ATYPE, DATERANGE=SEASONS[0])
          FF = [FF,GET_FILES(TSET,PRODS=TPROD, PERIODS='M3', FILE_TYPE=ATYPE, DATERANGE=SEASONS[1])]
          FF = [FF,GET_FILES(TSET,PRODS=TPROD, PERIODS='M3', FILE_TYPE=ATYPE, DATERANGE=SEASONS[2])]
          FF = [FF,GET_FILES(TSET,PRODS=TPROD, PERIODS='M3', FILE_TYPE=ATYPE, DATERANGE=SEASONS[3])]
          IF TOTAL(FILE_TEST(FF)) NE 4 THEN CONTINUE 
          
          PNGFILE = DIR_OUT + 'M3_' + YR + '-' + DSET + '_' + TSET + '-' + APROD + '-SEASONAL-' + ATYPE + '.PNG'
          IF ~FILE_MAKE(FF,PNGFILE,OVERWRITE=OVERWRITE) THEN CONTINUE
          W = WINDOW(DIMENSIONS=[527,587],BUFFER=BUFFER)
          PRODS_2PNG,FF[0],PROD=OPROD,MAPP=MAPOUT,OUTLINE=EPU_OUTLINE,OUT_COLOR=OCOLOR,OUT_THICK=OTHICK,/CURRENT,IMG_POS=[5,321,261,577],  PAL=PAL, /DEVICE
          PRODS_2PNG,FF[1],PROD=OPROD,MAPP=MAPOUT,OUTLINE=EPU_OUTLINE,OUT_COLOR=OCOLOR,OUT_THICK=OTHICK,/CURRENT,IMG_POS=[266,321,522,577],PAL=PAL, /DEVICE
          PRODS_2PNG,FF[2],PROD=OPROD,MAPP=MAPOUT,OUTLINE=EPU_OUTLINE,OUT_COLOR=OCOLOR,OUT_THICK=OTHICK,/CURRENT,IMG_POS=[5,60,261,316],   PAL=PAL, /DEVICE
          PRODS_2PNG,FF[3],PROD=OPROD,MAPP=MAPOUT,OUTLINE=EPU_OUTLINE,OUT_COLOR=OCOLOR,OUT_THICK=OTHICK,/CURRENT,IMG_POS=[266,60,522,316], PAL=PAL, /DEVICE
    
         ; T  = TEXT(0.5,0.98, '2021',   FONT_SIZE=12, FONT_STYLE='BOLD', FONT_COLOR=DCOLOR, ALIGNMENT=0.5)
          S1 = TEXT(7,566, 'WINTER', FONT_SIZE=10, FONT_STYLE='BOLD', FONT_COLOR=DCOLOR, ALIGNMENT=0, /DEVICE)
          S2 = TEXT(268,566, 'SPRING', FONT_SIZE=10, FONT_STYLE='BOLD', FONT_COLOR=DCOLOR, ALIGNMENT=0,/DEVICE)
          S3 = TEXT(7,305, 'SUMMER', FONT_SIZE=10, FONT_STYLE='BOLD', FONT_COLOR=DCOLOR, ALIGNMENT=0,/DEVICE)
          S4 = TEXT(268,305, 'FALL',   FONT_SIZE=10, FONT_STYLE='BOLD', FONT_COLOR=DCOLOR, ALIGNMENT=0,/DEVICE)
          
          CBAR, OPROD, OBJ=W, FONT_SIZE=10, FONT_STYLE=FONT_STYLE, CB_TYPE=3, CB_POS=[0.1,0.06,0.9,0.09], CB_TITLE=CTITLE, PAL=PAL
    
          W.SAVE, PNGFILE
          W.CLOSE
          PFILE, PNGFILE
        ENDFOR ; FILETYPES
      ENDFOR ; PRODS
    ENDIF
       
    
    IF KEYWORD_SET(MOVIES) THEN BEGIN
      DIR_MOVIE = VERSTR.DIRS.DIR_MOVIE
      YR = VERSTR.INFO.SOE_YEAR
      
      
      F = GET_FILES('MUR',PRODS='SST',PERIOD='D',DATERANGE=YR, MAPS='L3B2')
      DIR_PNGS = DIR_MOVIE + 'SST' + SL & DIR_TEST, DIR_PNGS
      PRODS_2PNG, F, PROD='SST_0_30', MAPP='NES', /ADD_CB, DIR_OUT=DIR_PNGS, BUFFER=1, ADD_BATHY=200, /ADD_DB, CB_TYPE=3, PAL='PAL_ANOM_BGR'
      PNGFILES = FLS(DIR_PNGS+'*.*',DATERANGE=YR)
      FPS = 5
      MOVIE_FILE = DIR_MOVIE + YR + '-SST-MUR-NES-FPS_'+ROUNDS(FPS)+'.mp4'
      MAKE_MOVIE, PNGFILES, MOVIE_FILE=MOVIE_FILE, FRAME_SEC=FPS
      
;      F = GET_FILES('OCCCI',PRODS='CHLOR_A-CCI',PERIOD='W',DATERANGE=YR, MAPS='L3B2', FILE_TYPE='ANOM')
;      DIR_PNGS = DIR_MOVIE + 'OCCCI-CHLOR_A' + SL & DIR_TEST, DIR_PNGS
;      PRODS_2PNG, F, MAPP='NES',CB_TITLE='Chlorophyll Anomaly', PAL=VERSTR.PROD_INFO.CHLOR_A.ANOM_PAL, SPROD=VERSTR.PROD_INFO.CHLOR_A.ANOM_SCALE,/ADD_CB, DIR_OUT=DIR_PNGS, BUFFER=1, /ADD_DB, CB_TYPE=3
;      PNGFILES = FLS(DIR_PNGS+'*.*',DATERANGE=YR)
;      FPS = 15
;      MOVIE_FILE = DIR_MOVIE + 'W_' + YR + '-CHLOR_A-OCI-MODISA-NES-ANOMS-FPS_'+ROUNDS(FPS)+'.webm'
;      MAKE_MOVIE, PNGFILES, MOVIE_FILE=MOVIE_FILE, FRAME_SEC=FPS
      
    ENDIF
    
    IF KEYWORD_SET(COMPARE_PRODUCTS) THEN BEGIN
      DATERANGE = VERSTR.INFO.DATERANGE
      SHPFILES = ['NES_EPU_NOESTUARIES','LMES66']

      COMPARE_SAT_SENSORS, ['MODISA','GLOBCOLOUR'], PRODS='PAR', MPS=['L3B2','L3B4'], PERIODS='M', SHPFILES=SHPFILE, SUBAREAS=SUBAREAS,DIR_OUT=VERSTR.DIRS.DIR_COMPARE,DATERANGE=['2020','2021'],BUFFER=0
      COMPARE_SAT_SENSORS, ['MODISA','GLOBCOLOUR'], PRODS='PAR', MPS=['L3B2','L3B4'], PERIODS='W', SHPFILES=SHPFILE, SUBAREAS=SUBAREAS,DIR_OUT=VERSTR.DIRS.DIR_COMPARE,DATERANGE=['2020','2021'],BUFFER=0
      COMPARE_SAT_SENSORS, ['OCCCI','OCCCI'],PRODS='CHLOR_A-CCI', MPS=['L3B4','L3B2'], PERIODS='M', SHPFILES=SHPFILE,SUBAREAS=SUBAREAS,DIR_OUT=VERSTR.DIRS.DIR_COMPARE,DATERANGE=DATERANGE,BUFFER=0

      PRODS = ['CHLOR_A-OCI','PPD-VGPM2']
      FOR ITH=0, N_ELEMENTS(SHPFILES)-1 DO BEGIN
        SHPFILE = SHPFILES[ITH]
        IF SHPFILE EQ 'LMES66' THEN SUBAREAS = 'NORTHEAST_U_S_CONTINENTAL_SHELF' ELSE SUBAREAS = []
        FOR NTH=0, N_ELEMENTS(PRODS)-1 DO BEGIN
          APROD = PRODS[NTH]
          IF APROD EQ 'CHLOR_A-OCI' THEN OPROD = 'CHLOR_A-CCI' ELSE OPROD = APROD
          IF OPROD EQ 'CHLOR_A-CCI' THEN GPROD = 'CHLOR_A-GSM' ELSE GPROD = APROD
          SEAWIFS = ' ,SEAWIFS,'+APROD+', '
          MODISA  = ' ,MODISA,' +APROD+', '
          VIIRS   = ' ,VIIRS,'  +APROD+', '
          JPSS1   = ' ,JPSS1,'  +APROD+', '
          SA      = ' ,SA,'     +APROD+', '
          SAV     = ' ,SAV,'    +APROD+', '
          SAVJ    = ' ,SAVJ,'   +APROD+', '
          OCCCI4  = 'VERSION_4.2,OCCCI,'+OPROD+', '  ; 4KM
          OCCCI5  = 'VERSION_5.0,OCCCI,'+OPROD+', '  ; 1KM
          GLOB    = ' ,GLOBCOLOUR,'+GPROD+', '
          COMPARE_SAT_PRODS, COMBO=STRJOIN([OCCCI5,GLOB,MODISA],';'),PERIODS='M',SHPFILES=SHPFILE,SUBAREAS=SUBAREAS,DIR_OUT=VERSTR.DIRS.DIR_COMPARE,DATERANGE=['2020','2021'],BUFFER=0
          COMPARE_SAT_PRODS, COMBO=STRJOIN([OCCCI5,GLOB,MODISA],';'),PERIODS='W',SHPFILES=SHPFILE,SUBAREAS=SUBAREAS,DIR_OUT=VERSTR.DIRS.DIR_COMPARE,DATERANGE=['2020','2021'],BUFFER=0
          COMPARE_SAT_PRODS, COMBO=STRJOIN([OCCCI5,OCCCI4,MODISA,JPSS1,VIIRS],';'),PERIODS='W',SHPFILES=SHPFILE,SUBAREAS=SUBAREAS,DIR_OUT=VERSTR.DIRS.DIR_COMPARE,DATERANGE=DATERANGE,BUFFER=0
          COMPARE_SAT_PRODS, COMBO=STRJOIN([OCCCI5,OCCCI4,SEAWIFS,MODISA,VIIRS,JPSS1],';'),PERIODS=['M','W','A','MONTH'],SHPFILES=SHPFILE,SUBAREAS=SUBAREAS,DIR_OUT=VERSTR.DIRS.DIR_COMPARE,DATERANGE=DATERANGE,BUFFER=0    
          COMPARE_SAT_PRODS, COMBO=STRJOIN([OCCCI5,OCCCI4,SA],';'),PERIODS=['M','W','A','MONTH'],SHPFILES=SHPFILE,SUBAREAS=SUBAREAS,DIR_OUT=VERSTR.DIRS.DIR_COMPARE,DATERANGE=DATERANGE,BUFFER=0
          COMPARE_SAT_PRODS, COMBO=STRJOIN([OCCCI5,OCCCI4,SEAWIFS,MODISA],';'),PERIODS=['M','W','A','MONTH'],SHPFILES=SHPFILE,SUBAREAS=SUBAREAS,DIR_OUT=VERSTR.DIRS.DIR_COMPARE,DATERANGE=DATERANGE,BUFFER=0
          
        ENDFOR ; PRODS
      ENDFOR ; SHPFILES   
    ENDIF

  ENDFOR ; VERSION



END ; End of SOE_MAIN
