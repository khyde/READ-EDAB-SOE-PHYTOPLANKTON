; $ID:	SOE_PP_REQUIRED.PRO,	2023-09-19-09,	USER-KJWH	$
  PRO SOE_PP_REQUIRED, VERSION_STRUCT, DIR_DATA=DIR_DATA, PRODUCTS=PRODUCTS, SHAPEFILE=SHAPEFILE

;+
; NAME:
;   SOE_PP_REQUIRED
;
; PURPOSE:
;   Extract the CHL and PP data for the PP Required SOE analyses (for Andy Beet)
;
; CATEGORY:
;   $CATEGORY$
;
; CALLING SEQUENCE:
;   SOE_PP_REQUIRED, VERSION_STRUCT
;
; REQUIRED INPUTS:
;   VERSION_STRUCT........ The SOE version information structure
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
; Copyright (C) 2021, Department of Commerce, National Oceanic and Atmospheric Administration, National Marine Fisheries Service,
;   Northeast Fisheries Science Center, Narragansett Laboratory.
;   This software may be used, copied, or redistributed as long as it is not sold and this copyright notice is reproduced on each copy made.
;   This routine is provided AS IS without any express or implied warranties whatsoever.
;
; AUTHOR:
;   This program was written on January 05, 2021 by Kimberly J. W. Hyde, Northeast Fisheries Science Center | NOAA Fisheries | U.S. Department of Commerce, 28 Tarzwell Dr, Narragansett, RI 02882
;    
; MODIFICATION HISTORY:
;   Jan 05, 2021 - KJWH: Initial code written
;   Oct 25, 2023 - KJWH: Removed the version loop and now passing in the version structures
;   Jan 23, 2024 - KJWH: Now adding the "temp" data to the primary dataset - should be tested and verified
;-
; ****************************************************************************************************
  ROUTINE_NAME = 'SOE_PP_REQUIRED'
  COMPILE_OPT IDL2
  SL = PATH_SEP()
  
  IF ~N_ELEMENTS(VERSION_STRUCT) THEN MESSAGE, 'ERROR: Must provide the SOE VERSION'
  
  VERSTR = VERSION_STRUCT
  VPRODS = TAG_NAMES(VERSTR.PROD_INFO)
  VYEAR = VERSTR.INFO.YEAR
  VER = VERSTR.INFO.PROJECT_VERSION
    
  IF ~N_ELEMENTS(DIR_DATA) THEN DIR_OUT = VERSTR.DIRS.DIR_PPREQ_EXTRACTS ELSE DIR_OUT = DIR_DATA
  PROD_DATASETS = []
  IF ANY(PRODUCTS)  THEN BEGIN
    PRODS    = PRODUCTS
    IF N_ELEMENTS(DATASETS) EQ N_ELEMENTS(PRODUCTS) THEN PROD_DATASETS = DATASETS
  ENDIF ELSE PRODS = VERSTR.INFO.PPREQ_PRODS
  IF ANY(DATERANGE) THEN DR       = DATERANGE ELSE DR = VERSTR.INFO.DATERANGE
  YEARS = YEAR_RANGE(DR,/STRING)

  ; ===> Get the SHAPEFILE information for the subarea extracts
  IF ~N_ELEMENTS(SHAPEFILE)  THEN SHPFILES  = VERSTR.INFO.PPREQ_SHPFILE ELSE SHPFILES = SHAPEFILE      
  MP = VERSTR.INFO.MAP_OUT
  PPRODS = VERSTR.INFO.PPREQ_PRODS 
  PPERIODS = VERSTR.INFO.PPREQ_PERIODS 
  
  FOR SA=0, N_ELEMENTS(SHPFILES)-1 DO BEGIN ; LOOP THROUGH SUBAREA SHAPE FILES
    SHPFILE = SHPFILES[SA]
    DIR_PPSUB = DIR_OUT + SHPFILE + SL
    
    IF ~N_ELEMENTS(SUBAREAS) THEN BEGIN
      SHP = READ_SHPFILE(SHPFILE,MAPP=MP)
      STAGS = TAG_NAMES(SHP)
      STAGS = STAGS[WHERE(STAGS NE 'OUTLINE' AND STAGS NE  'MAPPED_IMAGE')]
      CASE SHPFILE OF
        'NES_BOTTOM_TRAWL_STRATA': SUBNAMES = '_'+['01030', '01040', '01070', '01080', '01110', '01120', '01140', '01150', '01670', '01680', '01710', '01720', '01750', '01760']
        ELSE: SUBNAMES = ['GOM','GB','MAB']
      ENDCASE
      OK = WHERE_MATCH(STAGS,SUBNAMES,COUNT,COMPLEMENT=COMP,NCOMPLEMENT=NCOMP, INVALID=INVALID, NINVALID=NINVALID)
      IF NINVALID GT 0 THEN MESSAGE, 'ERROR: ' + SUBAREAS[INVALID] + ' not found in the shape file: ' + SHPFILE
      IF COUNT EQ 0 THEN MESSAGE, 'ERROR: None of the requested input subareas (' + SUBNAMES + ') where found in the shape file: ' + SHPFILE
      NAMES = STAGS[OK]
    ENDIF ELSE NAMES = SUBAREAS
    
    SHPSTR = []
    PFILES = []
    FOR PP=0, N_ELEMENTS(PPRODS)-1 DO BEGIN ; LOOP THROUGH PRODS
      PROD = PPRODS[PP]
      VPROD = VALIDS('PRODS',PROD)
      OK = WHERE(VPRODS EQ VPROD,COUNT)
      IF COUNT NE 1 THEN MESSAGE, 'ERROR: ' + GPR + ' not found in the SOE Version structure'
      DTSET = VERSTR.PROD_INFO.(OK).DATASET
      DVERSION = VERSTR.PROD_INFO.(OK).VERSION
      TMPSET = VERSTR.PROD_INFO.(OK).TEMP_DATASET
      CASE VPROD OF
        'PPD': BEGIN & RTAG = 'GMEAN' & RNGE = '0.001_50.0' & SUM_STATS=1 & END
        'CHLOR_A': BEGIN & RTAG = 'GMEAN' & RNGE = '0.001_80.0' & SUM_STATS=0 & END
      ENDCASE
      
      SOE_PP_REQUIRED_STACKED, VERSTR, DIR_DATA=DIR_OUT, SHAPEFILE=SHPFILE, PRODUCTS=PPRODS[PP],SAVEFILES=SAVEFILES, SUBAREAS=NAMES  ; Run the version that reads in the "stacked" files
    
      
      MERGE_DATA:
    ; ===> MERGE THE YEARLY FILES INTO INDIVIDUAL SUBAREA FILES
      DIR_MERGE = DIR_PPSUB + 'MONTHLY_MERGED-' + PROD + SL & DIR_TEST, DIR_MERGE
      MSAVEFILES = []
      FOR A=0, N_ELEMENTS(NAMES)-1 DO BEGIN
        ANAME = NAMES[A]
        IF STRPOS(ANAME,'_') EQ 0 THEN SNAME = STRMID(ANAME,1) ELSE SNAME = ANAME
        FP = FILE_PARSE(SAVEFILES)
        MPIN = VALIDS('MAPS',FP[0].NAME)
        PERIOD = STRSPLIT(FP[0].NAME,'-',/EXTRACT) & PERIOD = PERIOD[0]
        MSAVEFILE = DIR_MERGE + REPLACE(FP[0].NAME_EXT,[PERIOD,SHPFILE],['ALL_YEARS',SHPFILE+'-'+SNAME])
        MSAVEFILES = [MSAVEFILES,MSAVEFILE]

        IF FILE_MAKE(SAVEFILES,MSAVEFILE,OVERWRITE=OVERWRITE) EQ 0 THEN CONTINUE
        OUTSTRUCT = []
        INFILES = []
        TIME_START = []
        TIME_END = []
        META = [] 
        METASTR = []
        FOR V=0, N_ELEMENTS(SAVEFILES)-1 DO BEGIN
          PERIOD = STRSPLIT(FP[V].NAME,'-',/EXTRACT)
          YR = STRSPLIT(PERIOD[0],'_',/EXTRACT)
          IF WHERE(YR[1] EQ YEARS) LT 0 THEN CONTINUE
          SAV = IDL_RESTORE(SAVEFILES[V])

          ; ===> MERGE THE METADATA
          METADATA = SAV.FILE_METADATA
          METATAGS = TAG_NAMES(METADATA)
          REMOVETAGS = []
    ;      METATEMP = []
          FOR T=0, N_TAGS(METADATA)-1 DO BEGIN
            CASE METATAGS[T] OF 
              'FILE': INFILES = [INFILES,METADATA.FILE]
              'TIME_START': TIME_START = MIN([TIME_START,METADATA.TIME_START])
              'TIME_END': TIME_END = MAX([TIME_END,METADATA.TIME_END])
              ELSE: BEGIN
                IF ~SAME(METADATA.(T)) THEN MESSAGE, 'ERROR: Metadata is not the same'
                IF METADATA.(T) EQ MISSINGS(METADATA.(T)) THEN REMOVETAGS = [REMOVETAGS,METATAGS[T]]
              END  
            ENDCASE  
          ENDFOR
          METADATA = STRUCT_COPY(METADATA[0],TAGNAMES=['TIME_START','TIME_END','FILE','PERIOD_CODE','TIME'],/REMOVE) 
          METADATA = STRUCT_RENAME(METADATA, 'FILE', 'NAME')
          METADATA.ALG_REFERENCE = REPLACE(METADATA.ALG_REFERENCE,', ','_')
          IF HAS(METADATA.ALG_REFERENCE,',') THEN MESSAGE, 'ERROR: Commas found in the reference name'
          MTAGS = TAG_NAMES(METADATA)
          IF META EQ [] THEN META = METADATA ; First metadata structure
          FOR M=0, N_TAGS(META)-1 DO IF META.(M) NE METADATA.(M) THEN META = CREATE_STRUCT(META, MTAGS[M] + '_' + TMPSET, METADATA.(M))         
          
         ; ===> MERGE THE DATA
          OK = WHERE(TAG_NAMES(SAV) EQ ANAME,COUNTSAV)
          IF COUNTSAV EQ 0 THEN STOP
          MSAV = STRUCT_RENAME(SAV.(OK),TAG_NAMES(SAV.(OK)),  TAG_NAMES(SAV.(OK))+'_'+STRJOIN([SAV.SENSOR,REPLACE(SAV.PROD,'_',''),SAV.ALG],'_'),/STRUCT_ARRAYS)
          IF OUTSTRUCT EQ [] THEN OUTSTRUCT = MSAV ELSE OUTSTRUCT = STRUCT_MERGE(OUTSTRUCT,MSAV)
          
        ENDFOR ; SAVEFILES
        
        META = CREATE_STRUCT('INPUT_FILES',INFILES,'TIME_START',TIME_START,'TIME_END',TIME_END,META) ; Add the file names and minmax times to the metadata structure
        OUTSTRUCT = CREATE_STRUCT('METADATA',META,OUTSTRUCT)
        
        PRINT, 'Writing ' + MSAVEFILE
        SAVE,FILENAME=MSAVEFILE,OUTSTRUCT,/COMPRESS
   ;     GONE, OUTSTRUCT
      ENDFOR ; NAMES

      ; ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
      ; ===> CALCULATE MONTHLY & ANNUAL SUMS

      DIR_SUM = DIR_PPSUB + 'SUMS-' + PROD + SL & DIR_TEST, DIR_SUM
      PIXAREA = MAPS_PIXAREA(MPIN)  ; Average pixel area of the map
      FP = FILE_PARSE(MSAVEFILES)
      IF SHPSTR EQ [] THEN SHPSTR = READ_SHPFILE(SHPFILE, MAPP=MPIN, ATT_TAG=ATT_TAG, COLOR=COLOR, VERBOSE=VERBOSE, NORMAL=NORMAL, AROUND=AROUND)

      AFILES = []
      FOR N=0, N_ELEMENTS(NAMES)-1 DO BEGIN
        ANAME = NAMES[N]
        IF STRPOS(ANAME, '_') EQ 0 THEN SNAME = STRMID(ANAME,1) ELSE SNAME = ANAME
        AREA_SUBS = SHPSTR.(WHERE(TAG_NAMES(SHPSTR) EQ ANAME)).SUBS
        TOTAL_AREA = PIXAREA[AREA_SUBS]
        MSAVE = MSAVEFILES[WHERE(STRPOS(FP.NAME,'-'+SNAME+'-') GT 0, COUNTF, /NULL)]
        IF COUNTF NE 1 THEN STOP

        MSAVEFILE = DIR_SUM + 'MONTHLY_SUM-' + SHPFILE + '-' + SNAME + '-' + PROD +'-STATS.SAV'
        MCSVFILE  = DIR_SUM + 'MONTHLY_SUM-' + SHPFILE + '-' + SNAME + '-' + PROD +'-STATS.CSV'
        ASAVEFILE = DIR_SUM + 'ANNUAL_SUM-'  + SHPFILE + '-' + SNAME + '-' + PROD +'-STATS.SAV'
        ACSVFILE  = DIR_SUM + 'ANNUAL_SUM-'  + SHPFILE + '-' + SNAME + '-' + PROD +'-STATS.CSV'
        AFILES = [AFILES,ASAVEFILE]
        IF FILE_MAKE(MSAVE,[MSAVEFILE,ASAVEFILE,MCSVFILE,ACSVFILE],OVERWRITE=OVERWRITE) EQ 0 THEN CONTINUE

        PRINT, 'Calculating stats for: ' + SNAME + ' - ' + PROD
        MDATA = IDL_RESTORE(MSAVE)
        META = MDATA.METADATA
        TAGS = TAG_NAMES(MDATA)
        ITAGS = STR_BREAK(TAGS,'_')
        OK = WHERE(ITAGS EQ 'CHLORA',COUNT)
        IF COUNT GT 0 THEN ITAGS[OK] = 'CHLOR_A'

        STRUCT = CREATE_STRUCT('SENSOR','','PROD','','ALG','','PERIOD','','YEAR','','MONTH','','REGION','','SUBAREA','','EXTRACT_TAG','','N_SUBAREA_PIXELS',0L,'TOTAL_PIXEL_AREA_KM2',0.0D,'N_PIXELS',0L,'N_PIXELS_AREA',0.0D,'SPATIAL_MEAN',0.0,'SPATIAL_VARIANCE',0.0)
        IF KEY(SUM_STATS) THEN STRUCT = CREATE_STRUCT(STRUCT,'SPATIAL_SUM',0.0D,'MONTHLY_SUM',0.0D)
        MONTHS = ['01','02','03','04','05','06','07','08','09','10','11','12']
        STRUCT = REPLICATE(STRUCT_2MISSINGS(STRUCT),N_ELEMENTS(YEARS)*12)

        YSTRUCT = CREATE_STRUCT('SENSOR','','PROD','','ALG','','PERIOD','','YEAR','','REGION','','SUBAREA','','EXTRACT_TAG','','TOTAL_PIXEL_AREA_KM2','0.0D','N_MONTHS',0L,'ANNUAL_MEAN',0.0)
        IF KEY(SUM_STATS) THEN YSTRUCT = CREATE_STRUCT(YSTRUCT,'ANNUAL_SUM',0.0D,'ANNUAL_MTON',0.0D,'ANNUAL_TTON',0.0D)
        YSTRUCT = REPLICATE(STRUCT_2MISSINGS(YSTRUCT),N_ELEMENTS(YEARS))
        YSTRUCT.N_MONTHS = 0 ; Initialize to zero

        I = 0
        FOR Y=0, N_ELEMENTS(YEARS)-1 DO BEGIN
          FOR MTH=0, N_ELEMENTS(MONTHS)-1 DO BEGIN
            STRUCT[I].YEAR = YEARS[Y]
            STRUCT[I].MONTH = MONTHS[MTH]
            STRUCT[I].PERIOD = 'M_' + YEARS[Y] + MONTHS[MTH]
            STRUCT[I].REGION = SHPFILE
            STRUCT[I].SUBAREA = SNAME
            STRUCT[I].N_SUBAREA_PIXELS = N_ELEMENTS(MDATA.(0))
            STRUCT[I].TOTAL_PIXEL_AREA_KM2 = TOTAL(PIXAREA[AREA_SUBS],/NAN)

            ATAG = 'M_' + YEARS[Y] + MONTHS[MTH] + '_' + SNAME
            CTPOS = WHERE(ITAGS[*,1] EQ YEARS[Y]+MONTHS[MTH] AND ITAGS[*,2] EQ SNAME,COUNTTAG)  
            IF COUNTTAG EQ 0 THEN CONTINUE
            IF COUNTTAG GT 2 THEN MESSAGE, 'ERROR: More than 2 tags match ' + ATAG

            MTAGS = ITAGS[CTPOS,*]
            FOR C=0, COUNTTAG-1 DO BEGIN
              MTAG = MTAGS[C,*]
              IF MTAG[3] NE DTSET AND C EQ 0 AND COUNTTAG GT 1 THEN MESSAGE, 'ERROR: Assumes the first option is the primary dataset, need to fix code.'
              STRUCT[I].SENSOR = MTAG[3]
              STRUCT[I].PROD = MTAG[4]
              STRUCT[I].ALG = MTAG[5]

              MSAV = MDATA.(CTPOS[C])
              VDAT = VALID_DATA(MSAV,PROD=PROD,RANGE=RNGE,SUBS=OKVDAT,COUNT=COUNTVDAT,COMPLEMENT=COMPVDAT)
              IF COUNTVDAT NE 0 THEN BREAK       
            ENDFOR ; Counttags
            STRUCT[I].N_PIXELS = COUNTVDAT
            STRUCT[I].N_PIXELS_AREA = TOTAL(PIXAREA[OKVDAT],/NAN)
            STRUCT[I].SPATIAL_MEAN = GEOMEAN(VDAT[OKVDAT])
            STRUCT[I].SPATIAL_VARIANCE = VARIANCE(VDAT[OKVDAT])
            IF KEYWORD_SET(SUM_STATS) THEN BEGIN
              VDAT[COMPVDAT] = STRUCT[I].SPATIAL_MEAN ; FILL IN MISSING PP DATA WITH THE MEAN PRIOR TO CALCULATING THE TOTAL
              STRUCT[I].SPATIAL_SUM  = TOTAL(VDAT*1000000*PIXAREA[AREA_SUBS])  ; Convert /m^2 to /km^2 and multiple by the pixel area (km^2) to get gC/day/EPU
              STRUCT[I].MONTHLY_SUM  = STRUCT[I].SPATIAL_SUM*DAYS_MONTH(MONTHS[MTH],YEAR=YEARS[Y]) ; Multiple by the number of days in the month to get gC/[month]/EPU
            ENDIF
            I = I+1
          ENDFOR ; MONTHS

          OKY = WHERE(STRUCT.YEAR EQ YEARS[Y])
          YSTRUCT[Y].YEAR = YEARS[Y]
          YSTRUCT[Y].PERIOD = 'A_' + YEARS[Y]
          YSTRUCT[Y].REGION = SHPFILE
          YSTRUCT[Y].SUBAREA = SNAME
          YSTRUCT[Y].SENSOR = STRUCT[OKY[0]].SENSOR
          YSTRUCT[Y].PROD = STRUCT[OKY[0]].PROD
          YSTRUCT[Y].ALG = STRUCT[OKY[0]].ALG
          YSTRUCT[Y].TOTAL_PIXEL_AREA_KM2 = TOTAL(PIXAREA[AREA_SUBS])
          YSTRUCT[Y].ANNUAL_MEAN = MEAN(STRUCT[OKY].SPATIAL_MEAN,/NAN)

          IF KEYWORD_SET(SUM_STATS) THEN BEGIN
            YSTRUCT[Y].N_MONTHS = N_ELEMENTS(WHERE(STRUCT[OKY].MONTHLY_SUM NE MISSINGS(STRUCT.MONTHLY_SUM)))
            YSTRUCT[Y].ANNUAL_SUM = TOTAL(STRUCT[OKY].MONTHLY_SUM,/NAN) ; Get the annual total by summing the 12 monthly gC/[month]/EPU
            YSTRUCT[Y].ANNUAL_MTON = YSTRUCT[Y].ANNUAL_SUM * 1E-6       ; Convert grams Carbon to metric tons Carbon
            YSTRUCT[Y].ANNUAL_TTON = YSTRUCT[Y].ANNUAL_MTON/1000        ; Convert metric tons Carbon to thousand metric tons Carbon
          ENDIF
        ENDFOR ; YEARS
        
        META = STRUCT_RENAME(META,['SENSOR'],['SENSOR_NAME'],/STRUCT_ARRAYS)
        MMETA = REPLICATE(STRUCT_COPY(META,TAGNAMES=['INPUT_FILES'],/REMOVE),N_ELEMENTS(STRUCT))
        YMETA = REPLICATE(STRUCT_COPY(META,TAGNAMES=['INPUT_FILES'],/REMOVE),N_ELEMENTS(YSTRUCT))
        
        STRUCT = STRUCT_MERGE(STRUCT,MMETA)
        YSTRUCT = STRUCT_MERGE(YSTRUCT,YMETA)
        
        MDP = PERIOD_2STRUCT(STRUCT.PERIOD)
        YDP = PERIOD_2STRUCT(YSTRUCT.PERIOD)
        
        MMETA.TIME_START = DATE_FORMAT(MDP.DATE_START,/STANDARD) & MMETA.TIME_END = DATE_FORMAT(MDP.DATE_END,/STANDARD)  
        YMETA.TIME_START = DATE_FORMAT(YDP.DATE_START,/STANDARD) & YMETA.TIME_END = DATE_FORMAT(YDP.DATE_END,/STANDARD) 
        
        FOR M=0, N_ELEMENTS(MMETA)-1 DO MMETA[M].DURATION = NUM2STR(N_ELEMENTS(CREATE_DATE(MDP[M].DATE_START,MDP[M].DATE_END))) + ' days'
        FOR M=0, N_ELEMENTS(YMETA)-1 DO YMETA[M].DURATION = NUM2STR(N_ELEMENTS(CREATE_DATE(YDP[M].DATE_START,YDP[M].DATE_END))) + ' days'
        
        MMETA.TITLE = ''
        YMETA.TITLE = '' 
        
        PFILE, MSAVEFILE & SAVE,FILENAME=MSAVEFILE,STRUCT,/COMPRESS & STRUCT_2CSV,MCSVFILE,STRUCT
        PFILE, ASAVEFILE & SAVE,FILENAME=ASAVEFILE,YSTRUCT,/COMPRESS & STRUCT_2CSV,ACSVFILE,YSTRUCT
        SKIP_FILE:
      ENDFOR ; NAMES

      ; ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
      ; ===> MERGE FILES

      PSAVEFILE = DIR_SUM + 'ANNUAL_SUM-'+SHPFILE+'-'+PROD+'-STATS.SAV'
      PCSVFILE  = DIR_SUM + 'ANNUAL_SUM-'+SHPFILE+'-'+PROD+'-STATS.CSV'
      PFILES = [PFILES,PSAVEFILE]
      IF FILE_MAKE(AFILES,[PSAVEFILE,PCSVFILE],OVERWRITE=OVERWRITE) EQ 0 THEN CONTINUE
      FOR F=0, N_ELEMENTS(AFILES)-1 DO BEGIN
        IF F EQ 0 THEN SUBSTRUCT = IDL_RESTORE(AFILES[F]) ELSE SUBSTRUCT = STRUCT_CONCAT(IDL_RESTORE(AFILES[F]),SUBSTRUCT)
      ENDFOR
      SUBSTRUCT = SUBSTRUCT[SORT(STRING(SUBSTRUCT.SUBAREA)+'_'+STRING(SUBSTRUCT.YEAR))]
      PFILE, PSAVEFILE & SAVE, FILENAME=PSAVEFILE,SUBSTRUCT,/COMPRESS & STRUCT_2CSV,PCSVFILE,SUBSTRUCT

    ENDFOR ; PRODS

    DIR_MERGE = DIR_PPSUB + 'FINAL_MERGED_SUMS'  + SL & DIR_TEST, DIR_MERGE
    CSAVEFILE = DIR_MERGE + 'MERGED_ANNUAL_SUM-'+SHPFILE+'-'+STRJOIN(PPRODS,'_')+'-STATS-'+VER+'.SAV'
    CCSVFILE  = DIR_MERGE + 'MERGED_ANNUAL_SUM-'+SHPFILE+'-'+STRJOIN(PPRODS,'_')+'-STATS-'+VER+'.CSV'
    IF FILE_MAKE(PFILES,[CSAVEFILE,CCSVFILE],OVERWRITE=OVERWRITE) EQ 0 THEN CONTINUE
    FOR F=0, N_ELEMENTS(PFILES)-1 DO BEGIN
      IF F EQ 0 THEN SUBSTRUCT = IDL_RESTORE(PFILES[F]) ELSE SUBSTRUCT = STRUCT_CONCAT(SUBSTRUCT,IDL_RESTORE(PFILES[F]))
    ENDFOR
    SUBSTRUCT = SUBSTRUCT[SORT(STRING(SUBSTRUCT.SUBAREA)+'_'+SUBSTRUCT.PROD+'_'+SUBSTRUCT.PROD+'_'+STRING(SUBSTRUCT.YEAR))]
    PFILE, CSAVEFILE & SAVE, FILENAME=CSAVEFILE,SUBSTRUCT,/COMPRESS & STRUCT_2CSV,CCSVFILE,SUBSTRUCT
   
  ENDFOR ; SUBAREA SHAPEFILES   
     

END ; ***************** End of SOE_PP_REQUIRED *****************
