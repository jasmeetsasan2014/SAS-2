/users/d33/jf97633/sas_y2k/macros/aestat.sas                                                        0100664 0045717 0002024 00000127447 06634221377 0021536 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ PROGRAM NAME:     AESTAT.SAS
/
/ PROGRAM VERSION:  1.2
/
/ PROGRAM PURPOSE:  AESTAT summarizes AE type data.  It supports a number of
/                   statistical test and other features.
/
/ SAS VERSION:      6.12
/
/ CREATED BY:       John Henry King
/
/ DATE:             1993
/
/ INPUT PARAMETERS: See detailed description below.
/
/ OUTPUT CREATED:   Creates a SAS data set that can be used as input to AETAB.
/
/ MACROS CALLED:    JKPVAL05 - Compute p-value for discrete values.
/                   JKCHKDAT - Check input data for proper variables and types.
/                   JKPAIRED - Produces a dataset for pairwise analysis.
/
/ EXAMPLE CALL:     %aestat(  denom = denom,
/                           adverse = adverse,
/                               tmt = tmt,
/                           uspatno = ptcd subject,
/                           p_value = cmhrms,
/                           control = xptcd,
/                            subgrp = aerel,
/                            level1 = bodytx,
/                            level2 = grptx,
/                          pairwise = yes,
/                             print = 1);
/
/=====================================================================================
/ CHANGE LOG:
/
/    MODIFIED BY: John Henry King
/    DATE:        26FEB1997
/    MODID:       JHK001
/    DESCRIPTION: Fixed type in check list when P_VALUE=CMHCOR and a controlling
/                 variable is used.  CONTROL=
/    ------------------------------------------------------------------------------
/    MODIFIED BY: John Henry King
/    DATE:        27FEB1997
/    MODID:       JHK002
/    DESCRIPTION: Added option to pass PROC FREQ options to JKPVAL05.
/    ------------------------------------------------------------------------------
/    MODIFIED BY: John Henry King
/    DATE:        28FEB1997
/    MODID:       JHK003
/    DESCRIPTION: Enhance error messages to make them more noticable.
/    ------------------------------------------------------------------------------
/    MODIFIED BY: John Henry King
/    DATE:        10NOV1997
/    MODID:       JHK004
/    DESCRIPTION: Added Total option and checking for blank LEVEL1 or LEVEL2
/                 values. Also added OUTSUBJ option to output a subject list
/                 with the summary statistics attached.
/    ------------------------------------------------------------------------------
/    MODIFIED BY: Jonathan Fry
/    DATE:        09DEC1998
/    MODID:       JMF005
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Version Number changed to 1.2.
/    ------------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX006
/    DESCRIPTION:
/    ------------------------------------------------------------------------------
/======================================================================================*/

/*
/ Macro AESTAT
/
/ Use macro AESTAT to count adverse events.
/
/ Parameter=default   Description
/ -----------------   ----------------------------------------------------------
/
/ ADVERSE=            Names the data set of adverse events.  This data set
/                     should have one observation for each adverse event, and
/                     should not include observations for patients who did not
/                     have adverse events.
/
/ DENOM=              Names the data set of denominator patients.  This data set
/                     should have one observation for each patient who is in the
/                     populations defined by the PAGEBY variables.  The macro
/                     will verify that DENOM has only one patient in each
/                     population by treatment combination.
/
/ OUTSTAT=AESTAT      Names the summary data set created by the macro.  See
/                     description of OUTSTAT data set below.
/
/ OUTSUBJ=            Names a data set of subject numbers merged with the summary
/                     stats to be used to produce the listing of subjects with
/                     each ae.  If this parameter is blank, the default, then no
/                     subject list is produced.  Note this option is only available
/                     when LEVEL2 group is used.
/
/ UNIQUEID=           Names the variable(s) used to uniquely identify each patient
/                     in the DENOM and ADVERSE data sets.  Please note that older
/                     versions on AESTAT did not support more that one variable in
/                     this parameter.  You may now specify as may variables as are
/                     needed to uniquely identify the patients.
/
/ PAGEBY=             Names variables used to group the analysis.  The variables
/                     must be in BOTH the DENOM and ADVERSE data sets.
/                     Typically PAGEBY could represent "STUDY PERIOD", PROTOCOL
/                     or some similar grouping of the analysis.
/
/ TMT=                Names the variable that defines the treatment groups.
/                     This variable must be integer numeric. For example
/                     1, 2, 3, 4, 5.
/
/ TOTAL=NO            Use this options to cause AESTAT to include a total across all
/                     treatment groups.
/
/ TOTALTMT=99         This parameter used in conjunction with TOTAL to give a treatment
/                     value to the total group.
/
/ SUBGRP=             The SUBGRP parameter can be used with AESTAT to produce
/                     a summary of an AE subset and also provide the totals
/                     for
/                        Number of patients with any AE
/                     and
/                        Number of patients with any subgroup
/
/                     For example you want to produce an AE table of drug related
/                     AE.  You also want the display to include the total number of
/                     patients with any AE.  To accomplish this create character
/                     variable with a value of '1' for the AEs in the subgroup and
/                     a missing value for the others.  The tell AESTAT the name of
/                     this variable with the SUBGRP= parameter and AESTAT will
/                     produce a dataset that also contains
/
/                        Number of patients with any AE.
/
/ TMTEXCL = (1)       This parameter is use to exclude from the analysis of
/                     one or more of the treatment groups.
/
/ SEX=                Names the variable that contains the patients sex code.
/                     If the user wants a sex specific denominator for adverse
/                     events that can only occur in one sex then this parameter
/                     should be specified and the DEMOM and ADVERSE data sets
/                     should be structured as follows.
/
/                     In the DEMOM data set this variable should be associated
/                     with EVERY patient and repeated in all PAGEBY groups.
/
/                     In the ADVERSE data set this variable should be blank for
/                     all but ADVERSE events that can only occur in males or females.
/
/                     For example DISS codes that begin with T are Genitalia (Female)
/                     therefore the proper denominator for these events would include
/                     only female patients.
/
/ LEVEL1=             This parameter names the first level of adverse event
/                     classification, typically some type of body system
/                     grouping.  SYMPCLASS or DISS code first letter.
/
/ ORDER1=_ORDER1_     Names the variable in the output data that orders the values
/                     of the LEVEL1= variable.
/
/ LEVEL2=             This paremeter names the second level of adverse event
/                     classification, typically DISS code, or SYMPGP.  This
/                     parameter may be left blank if the summary is to only have
/                     one level of classification.
/
/ ORDER2=_ORDER2_     Names the variable in the output data that orders the values of
/                     then LEVEL2= variable.
/
/ CUTOFF=0            This parameter is used to specify an occurance percentage cutoff.
/                     The user would use this parameter to subset the summary to
/                     events that have a mimimum percent occurance.  For example a
/                     summary of events in 5% or greater of the patients would be
/                     specified by CUTOFF=.05.
/                     The cutoff is compared to the smallest percent of the various
/                     treatments included in the CUTWHERE= parameter.
/
/ CUTWHERE=1          This parameter is used to specify a where clause to direct
/                     the CUTOFF to a specific subset of TREATMENTS.  For example
/                     to restrict the analysis to 5% of treatment 1 patients use,
/                     CUTOFF=.05, CUTWHERE=%str(TMT=1).  CUTWHERE can be used with
/                     both CUTOFF= and CUTSTMT=.
/
/ CUTSTMT=            The cut statement parameter provideds similar functionality
/                     to that provided by the CUTOFF= parameter.  While CUTOFF
/                     allows the user to subset to events that are larger than
/                     the cutoff the CUTSTMT allows the use to specify a
/                     subsetting SAS statement.  This way the user is allowed to
/                     do the subsetting based on what ever criteria he wishes.
/                     The CUTSTMT= should be a valid sas IF statement including
/                     the simicolon.  ex.
/                         CUTSTMT=%STR(if 0.01 <= CUTOFF <= 0.05;),
/                     Note that variable CUTOFF is the variable created by
/                     AESTAT that will contain the cutoff value.  Do not use
/                     CUTOFF= when using CUTSTMT=.
/
/ CUTMNX = MIN        The parameter is used to control how AETAT creates the
/                     the CUTOFF value.  By default the MIN percent across
/                     treatment is used in the comparision.  You may want to
/                     use MAX for some types of cuts.
/ ORDER1BY=1
/ ORDER2BY=1          The orderby parameter is used to specify the subset of
/                     treatments used to order the adverse events by frequency.
/                     The default is to sum the frequency of events for all
/                     treatments and order the events by decending frequency of
/                     that sum.  The user may request that only some of the
/                     treatments be used to order the events by using a VALID
/                     where expression in the orderby parameter.  The user will
/                     need to surround the expression with the %STR macro
/                     function.  For example to order the events by the sum of
/                     treatments 2, 3, and 4 use.
/
/                        ORDER2BY = %STR(tmt in(2,3,4))
/
/                     The macro will create a variable in the output dataset named
/                     _ORDER2_.  This variable is then used in a by statement in
/                     proc sort.  The values of _order_ have their sign reversed
/                     so that the sort will be descending without having to use
/                     the descending option in the by statement.
/
/ STLEVEL=2           Use this parameter to control which of the LEVEL groupings
/                     p-values will be computed for.  For example the default is
/                     to compute pvalues for all levels of the LEVEL1 and LEVEL2
/                     variables.  If a user only wanted the p-values for the
/                     LEVEL2 groupings, the body system grouping, then STLEVEL=1
/                     would need to be specified.
/
/ P_VALUE=NONE        This parameter is used to specify the type of p-values to
/                     compute and include in the output data set.  The user may
/                     request CHISQ, EXACT, CMHRMS, CMHGA, CMHCOR, or LGOR.
/                     When LGOR is specifed then the upper and lower confidence
/                     limits are also output.
/
/ SCORES=TABLE        The SCORES= parameter is used to control the SCORES= option
/                     in PROC FREQ.  You may request TABLE, RANK, RIDIT or MODRIDIT
/                     scores.  See documentation for PROC FREQ for details.  If no
/                     P_VALUE is requested then the parameter has no effect.
/
/ PAIRWISE=NO         Use this parameter to request pairwise p-values.
/                     PAIRWISE=YES must be specified when requesting P_VALUE=LGOR
/                     this will insure 2x2 table for the odds ratios.
/
/ CONTROL=            A variable used to produce a stratified analysis (p values)
/                     This is typically study center or perhaps protocol in
/                     an ISS AE table.  This parameter does NOT cause the macro
/                     to produce the AE counts by each level of the controlling
/                     variable.
/
/ PRINT=YES           Use this parameter to request a proc contents and proc
/                     print of the OUTSTAT data set produced by the macro.
/
/ -----------------   ----------------------------------------------------------
/
/===============================================================================
/
/ The OUTSTAT data set.
/
/ The OUTSTAT data set contains one observation for each of the various levels
/ of classifications defined by PAGEBY, TMT, LEVEL1, and LEVEL2.  If you made a
/ table of this data each observation would make up one cell of that table.
/ Where a table cell would include counts, denominator, and percent.
/
/ OUTSTAT is sorted as follows:
/   When LEVEL1 and LEVEL2 are both specifed.
/      BY   PAGEBY _ORDER1_ LEVEL1 _ORDER2_ LEVEL2 TMT
/
/   When LEVEL2 is not specified.
/      BY   PAGEBY _ORDER1_ LEVEL1 TMT
/
/
/
/ The OUTSTAT data set contains the following variables.
/
/ pageby variables:
/   The variables named in the PAGEBY= parameter.
/
/ level1 variable
/   The variable named in the LEVEL1= parameter.
/
/ level2 variable
/   The variable named in the LEVEL2= parameter.  This variable will not appear
/   in the outstat data set if this parameter was not specified.
/
/ sex variable
/   The variable named in the SEX= parameter.  Does not appear if this parameter
/   is not specified.
/
/ tmt variable
/   The variable named in the TMT= parameter.
/
/ _AETYPE_
/   This variable is used to describe the type of summary that has been
/   applied to a particular observation in OUTSTAT.
/     _AETYPE_ = 0 for patients with ANY event
/     _AETYPE_ = 1 for patients with any LEVEL1 event
/     _AETYPE_ = 2 for LEVEL2 events.
/
/ _ORDER1_ _ORDER2_
/   This is the sort order variable.
/
/ N_PATS
/   The number of patients with a particular event.
/
/ N_EVTS
/   The number of occurances of a particular event.
/
/ DENOM
/   The denominator for an event.
/
/ PCT
/   proportion of patients experiencing an event, N_PATS / DENOM
/
/ _PTYPE_
/   The type of p-value if requested in the P_VALUE= parameter. CHISQ or EXACT
/
/ PROB
/   The p-value identified by _PTYPE_.
/
/ P1_2, P1_3, P1_4 ...
/    If PAIRWISE=YES then variables of this form are produced to hold the
/    pairwise p-values.
/
/-----------------------------------------------------------------------------*/

%macro AESTAT(adverse = ,
                denom = ,
              outstat = AESTAT,
              outsubj = ,
             uniqueid = ,
              uspatno = ,
                  sex = ,
               pageby = ,

                  tmt = ,
                total = N,
             totaltmt = 99,

              tmtexcl = (1),

               subgrp = ,

               level1 = ,
               order1 = _order1_,
             order1by = 1,

               level2 = ,
               order2 = _order2_,
             order2by = 1,

               cutoff = 0,
             cutwhere = 1,
              cutstmt = ,
               cutmnx = MIN,

              p_value = NONE,
              control = ,
               scores = TABLE,
               recall = 0,
             pairwise = NO,
              stlevel = 2,
                print = YES,
              sasopts = NOSYMBOLGEN NOMLOGIC,
                debug = 0,
             freqopts = NOPRINT  /* JHK002 */);

   options &sasopts;
   %global vaestat;
   %let    vaestat = 1.0;

   /*
   / JMF005
   / Display Macro Name and Version Number in LOG.
   /------------------------------------------------------------------------*/

   %put ------------------------------------------------------;
   %put NOTE: Macro called: AESTAT.SAS     Version Number: 1.2;
   %put ------------------------------------------------------;


   /*
   / JHK003
   / New macro variable added to make error message more noticable.
   / All ! mark removed from old error messages.
   /--------------------------------------------------------------------------*/

   %local erdash;
   %let erdash = ERROR: _+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_;


   %if "&denom"="" %then %do;
      %put &erdash;
      %put ERROR: There is no DEMOMinator data set.;
      %put &erdash;
      %goto exit;
      %end;

   %if "&adverse"="" %then %do;
      %put &erdash;
      %put ERROR: There is no ADVERSE data set.;
      %put &erdash;
      %goto exit;
      %end;

   %if "&uspatno"^="" & "&uniqueid"="" %then %do;
      %let uniqueid=&uspatno;
      %let uspatno=;
      %end;

   %if "&uniqueid"="" %then %do;
      %put &erdash;
      %put ERROR: The macro parameter UNIQUEID must not be blank.;
      %put &erdash;
      %goto exit;
      %end;

   %if "&tmt"="" %then %do;
      %put &erdash;
      %put ERROR: The macro parameter TMT must not be blank.;
      %put &erdash;
      %goto exit;
      %end;

   %if "&level1"="" %then %do;
      %put &erdash;
      %put ERROR: The macro parameter LEVEL1 must not be blank.;
      %put &erdash;
      %goto exit;
      %end;

   %if %bquote(&level2)= & %bquote(&outsubj)^= %then %do;
      %put &erdash;
      %put ERROR: You cannot request a subject list without a LEVEL2 variable.;
      %put &erdash;
      %goto exit;
      %end;


   %if "&scores"="" %then %do;
      %put &erdash;
      %put ERROR: The macro parameter SCORES must not be blank.;
      %put &erdash;
      %goto exit;
      %end;

   %if %index(&uniqueid,&control) %then %do;
      %put &erdash;
      %put ERROR: Your CONTROLling variable is also in UNIQUEID,;
      %put ERROR: this could cause problems for AESTAT.;
      %put ERROR: Rename the CONTROLling variable and try again.;
      %put &erdash;
      %goto exit;
      %end;

   /*
   / check that the user is not trying to use the older CUTOFF and
   / CUTWHERE parameters with the newer CUTSTMT and CUTMX parameters
   /------------------------------------------------------------------*/
   %if ^%index(MIN MAX,&cutmnx) %then %do;
      %put &erdash;
      %put ERROR: CUTMN must have the value MIN or MAX;
      %put &erdash;
      %goto exit;
      %end;

   %if "&cutstmt"^="" & "&cutoff"^="0"  %then %do;
      %put &erdash;
      %put ERROR: You are try to use the CUTSTMT with CUTOFF.;
      %put ERROR: These are incompatable options use either a CUTSTMT, the preferred method,;
      %put ERROR: or the older CUTOFF parameter.;
      %put &erdash;
      %goto exit;
      %end;


   %if "&p_value"="" %then %let p_value=NONE;
   %let p_value = %upcase(&p_value);

   %if ^%index(CHISQ EXACT CMH CMHCOR CMHRMS CMHGA NONE LGOR,&p_value) %then %do;
      %put &erdash;
      %put ERROR: p-value requested "&p_value" is not valid.;
      %put &erdash;
      %goto exit;
      %end;

   %if "&control" > "" & %index(CHISQ EXACT,&p_value) %then %do;
      %put &erdash;
      %put ERROR: You cannot request Fishers EXACT or Chi Square test with a controlling variable.;
      %put &erdash;
      %goto EXIT;
      %end;


   %let pairwise = %upcase(&pairwise);

   %if "&pairwise"="YES"
      %then %let pairwise = 1;
      %else %let pairwise = 0;


   %if ^&pairwise & "&p_value"="LGOR" %then %do;
      %put &erdash;
      %put ERROR: You MUST specify PAIRWISE=YES when requesting Odds Ratios (P_VALUE=LGOR).;
      %put &erdash;
      %goto EXIT;
      %end;


   %jkchkdat(data=&denom,
             vars=&pageby &control &uniqueid &sex,
            nvars=&tmt,
           return=rc_d)

   %if &rc_d %then %goto exit;


   %jkchkdat(data=&adverse,
             vars=&pageby &control &uniqueid &sex &level1 &level2,
            nvars=&tmt,
            cvars=&subgrp,
           return=rc_a)

   %if &rc_a %then %goto exit;


   %if "&outstat" = "" %then %let outstat = AESTAT;
   %let outstat = %upcase(&outstat);


   %if "&print"="" %then %let print = NO;
   %let print = %upcase(&print);
   %if "&print" = "YES" | "&print"="1"
      %then %let print = 1;
      %else %let print = 0;

   %let order1 = %upcase(&order1);
   %let order2 = %upcase(&order2);

   %if "&order1"="NONE" %then %let order1=;

   %if "&order2"="NONE" %then %let order2=;
   %if "&level2"=""     %then %let order2=;

   %if "&order1by"="" %then %let order1by = 1;
   %if "&order2by"="" %then %let order2by = 1;

   %if "&cutwhere"="" %then %let cutwhere = 1;


   %local subgrp_f;

   %if %length(&subgrp) > 0
      %then %let subgrp_f = 1;
      %else %let subgrp_f = 0;

   %let recall = %upcase(&recall);

   %if ^%index(0 1,&recall) %then %do;
      %put &erdash;
      %put ERROR: The macro parameter RECALL must be either 0 or 1.;
      %put &erdash;
      %goto exit;
      %end;

   %let control = %upcase(&control);

   %local tcontrol;
   %if &recall & "&control" > ""
      %then %let tcontrol = &control;
      %else %let tcontrol = ;

   %let total = %upcase(&total);
   %if %bquote(&total)=YES | %bquote(&total)=Y | %bquote(&total)=1
      %then %let total = 1;
      %else %let total = 0;


   %local setlist aetype;

   %local adv all pop pop2 advm1 adv0 adv1 adv2 zero ztmt
          freq pval order cutd dups xadvr tdenom subj;

   %let all    = _1_&sysindex;
   %let pop    = _2_&sysindex;
   %let pop2   = _3_&sysindex;
   %let adv0   = _4_&sysindex;
   %let adv1   = _5_&sysindex;
   %let adv2   = _6_&sysindex;
   %let zero   = _7_&sysindex;
   %let ztmt   = _8_&sysindex;
   %let freq   = _9_&sysindex;
   %let pval   = _A_&sysindex;
   %let order  = _B_&sysindex;
   %let cutd   = _C_&sysindex;
   %let dups   = _D_&sysindex;
   %let advm1  = _E_&sysindex;
   %let xadvr  = _F_&sysindex;
   %let tdenom = _G_&sysindex;
   %let adv    = _H_&sysindex;
   %let subj   = _I_&sysindex;

   /*
   / Verify that the DEMOMinator data has unique observations for each patient.
   /--------------------------------------------------------------------------*/

   %local dupflag;
   %let dupflag = 0;

   proc sort data=&denom out=&tdenom;
      by &pageby &tcontrol &uniqueid &tmt;
      run;

   data &dups;
      set &tdenom;
      by &pageby &tcontrol &uniqueid &tmt;
      if ^(first.&tmt & last.&tmt) then do;
         output &dups;
         call symput('DUPFLAG','1');
         end;
      format _all_;
      run;

   %if &dupflag %then %do;
      title5 'Duplicates found in input data, correct and resubmit';
      proc print data=&dups;
         run;
      title5;
      %put &erdash;
      %put ERROR: Duplicates found in input data correct and resubmit.;
      %put ERROR: Please check the listing for a list of duplicate data.;
      %put &erdash;
      %goto EXIT;
      %end;


   %if &total %then %do;
      data &tdenom;
         set &tdenom;
         output;
         &tmt = &totaltmt;
         output &tdenom;
         run;
      %end;


   /*
   / check ADVERSE for missing values of LEVEL1 or LEVEL2 and create
   / total variable is TOTAL=YES.
   /--------------------------------------------------------------------*/

   data &adv &dups;
      set &adverse;

      if &level1=' ' %if %bquote(&level2)^= %then | &level2=' '; then do;
         output &dups;
         call symput('DUPFLAG','1');
         end;


      output &adv;

      %if &total %then %do;
         &tmt = &totaltmt;
         output &adv;
         %end;

      run;

   %let adverse = &adv;

   %if &dupflag %then %do;
      title5 'Missing value for LEVEL1 | LEVEL2 variables found in input data, correct and resubmit';
      proc print data=&dups;
         run;
      title5;
      %put &erdash;
      %put ERROR: Missing values for LEVEL1 | LEVEL2 variables found in input data correct and resubmit.;
      %put ERROR: Please check the listing for a list of missing data.;
      %put &erdash;
      %goto EXIT;
      %end;



   /*
   / If we are doing a subgroup analysis then this step
   / will creat a new data set with only the subgroup in
   / it.  Otherwise the adverse data will be used.
   /------------------------------------------------------*/

   %if &subgrp_f %then %do;

      data &xadvr;
         set &adverse;
         if &subgrp > ' ';
         run;

      %end;
   %else %let xadvr = &adverse;



   /*
   / Use the denominator data to compute counts for the various levels of &TMT.
   / POP will be the number of patients for each treatment and if used sex.
   /--------------------------------------------------------------------------*/

   proc summary data=&tdenom nway missing;
      class &pageby &tcontrol &tmt &sex;
      output out=&pop(drop=_type_ rename=(_freq_=denom));
      run;


   /*
   / Depending on if the user specified a value for SEX the macro needs to
   / create a POP2 data set that has patient counts that do not include sex.
   /--------------------------------------------------------------------------*/

   %if "&sex" = "" %then %do;
      data &pop2;
         set &pop;
         run;
      %end;
   %else %do;
      /*
      / POP will include the totals for each tmt and for each tmt and sex
      /-----------------------------------------------------------------------*/
      proc summary data=&tdenom nway missing;
         class &pageby &tcontrol &tmt;
         output out=&pop2(drop=_type_ rename=(_freq_=denom));
         run;

      data &pop;
         set &pop2 &pop;
         by &pageby &tcontrol &tmt;
         run;
      %end;


   %if &subgrp_f %then %do;
      /*
      / Now find the total number of patients with ANY adverse event.
      / _AETYPE_ = -1.  This is for all subgrp values.
      /--------------------------------------------------------------------------*/
      proc summary
            nway missing
            data=&adverse;

         class &uniqueid &tcontrol &pageby &tmt;
         output out = &advm1(drop=_type_);
         run;
      proc summary data=&advm1 nway missing;
         class &pageby &tcontrol &tmt;
         var _freq_;
         output out = &advm1(drop=_type_ _freq_)
                  n = n_pats
                sum = n_evts;
         run;
      %let setlist = &advm1(in=inm1);
      %let aetype  = inm1*-1;

      %end;


   /*
   / Now find the total number of patients with ANY adverse event.
   / _AETYPE_ = 0
   /--------------------------------------------------------------------------*/
   proc summary data=&xadvr nway missing;
      class &uniqueid &tcontrol &pageby &tmt;
      output out = &adv0(drop=_type_);
      run;
   proc summary data=&adv0 nway missing;
      class &tcontrol &pageby &tmt;
      var _freq_;
      output out = &adv0(drop=_type_ _freq_)
               n = n_pats
             sum = n_evts;
      run;

   %let setlist = &setlist &adv0(in=in0);
   %let aetype  = &aetype + in0*0;

   /*
   / If LEVEL1 is not blank find the total number of patients for each level
   / of the variable specified in LEVEL1.  This would typically be body system.
   /--------------------------------------------------------------------------*/
   %if "&level1" ^= "" %then %do;
      proc summary data=&xadvr nway missing;
         class &uniqueid &tcontrol &pageby &tmt &sex &level1;
         output out = &adv1(drop=_type_);
         run;
      proc summary data=&adv1 nway missing;
         class &pageby &tcontrol &tmt &sex &level1;
         var _freq_;
         output out = &adv1(drop=_type_ _freq_)
                  n = n_pats
                sum = n_evts;
         run;
      %let setlist = &setlist &adv1(in=in1);
      %let aetype  = &aetype + in1*1;
      %end;
   %else %do;
      %let adv1 = ;
      %end;

   /*
   / If LEVEL2 is not blank find the total number of patients for each level
   / of this variable.
   /--------------------------------------------------------------------------*/
   %if "&level2" ^= "" %then %do;
      proc summary data=&xadvr nway missing;
         class &uniqueid &tcontrol &pageby &tmt &sex &level1 &level2;
         output out = &adv2(drop=_type_);
         run;

      %if %bquote(&outsubj)^= %then %do;
         proc sort data=&adv2 out=&subj;
            by &pageby &level1 &level2 &tmt;
            run;
         %end;
      %else %let subj =;

      proc summary data=&adv2 nway missing;
         class &pageby &tcontrol &tmt &sex &level1 &level2;
         var _freq_;
         output out = &adv2(drop=_type_ _freq_)
                  n = n_pats
                sum = n_evts;
         run;
      %let setlist = &setlist &adv2(in=in2);
      %let aetype  = &aetype + in2*2;
      %end;
   %else %do;
      %let adv2 = ;
      %let subj = ;
      %end;


   /*
   / Put the data created above together and sort.
   /--------------------------------------------------------------------------*/
   data &all;
      set &setlist;
      _aetype_ = &aetype;
      run;

   proc sort data=&all;
      by &pageby &level1 &level2 &sex _aetype_ &tcontrol &tmt;
      run;

   /*
   / Some adverse events may not have occured in all treatments.  In the next
   / few steps create a FRAME of zeros using data from above and update
   / the FRAME with that data.
   /--------------------------------------------------------------------------*/

   /*
   / Using ALL, the adverse event counts, create a data set with one
   / observation for each event.
   /--------------------------------------------------------------------------*/
   proc summary data=&all nway missing;
      class &pageby &level1 &level2 &tcontrol &sex _aetype_;
      output out=&zero(drop=_type_ _freq_);
      run;

   /*
   / Now using the POP data create ZTMT a data set with one observation for
   / each treatment.
   /--------------------------------------------------------------------------*/
   proc summary data=&pop nway missing;
      class &tmt;
      output out=&ztmt(drop=_type_ _freq_);
      run;

   /*
   / Create the FRAME of zeros.
   /--------------------------------------------------------------------------*/
   data &zero;
      set &zero end=eof;
      do point = 1 to nobs;
         set &ztmt point=point nobs=nobs;
         output;
         end;
      retain n_pats 0;
      run;

   proc sort data=&zero;
      by &pageby &level1 &level2 &sex _aetype_ &tcontrol &tmt;
      run;


   /*
   / Use UPDATE to add the non-zero values calculated above to the FRAME of
   / zeros.
   /--------------------------------------------------------------------------*/

   data &all;
      update &zero &all;
      by &pageby &level1 &level2 &sex _aetype_ &tcontrol &tmt;
      run;



   /*
   / Create an the ORDER 1 variable
   /--------------------------------------------------------------------------*/
   %if "&order1" ^= "" %then %do;
      proc summary nway missing data=&all(where=((&order1by) & (_aetype_<=1)));
         class &pageby &level1;
         var n_pats;
         output out=&order(drop=_type_ _freq_)
                sum=_xorder_;
         run;


      %if &debug %then %do;
         title5 "DATA=ORDER1(&order)";
         proc print data=&order;
            run;
         title5;
         %end;



      /*
      / Merge the order variable with the counts.  A new variable is created by
      / changing the sign of the original variable created above.  By changing the
      / sign the AEs will sort in descending order without using the DESCENDING
      / by statement option.  This will make it easier as the descending option
      / will not be needed.
      /--------------------------------------------------------------------------*/

      data &all;
         merge &all &order;
         by &pageby &level1;
         &order1 = _xorder_ * -1;
         drop _xorder_;
         run;

      %end;


   /*
   / Create an the ORDER 2 variable
   /--------------------------------------------------------------------------*/
   %if "&order2" ^= "" %then %do;
      proc summary nway missing data=&all(where=(&order2by));
         class &pageby &level1 &level2;
         var n_pats;
         output out=&order(drop=_type_ _freq_)
                sum=_xorder_;
         run;

      /*
      / Merge the order variable with the counts.  A new variable is created by
      / changing the sign of the original variable created above.  By changing the
      / sign the AEs will sort in descending order without using the DESCENDING
      / by statement option.  This will make it easier as the descending option
      / will not be needed.
      /--------------------------------------------------------------------------*/

      data &all;
         merge &all &order;
         by &pageby &level1 &level2;
         &order2  = _xorder_ * -1;
         drop _xorder_;
         run;

      %end;



   /*
   / Now sort the counts and merge on the denominator
   /--------------------------------------------------------------------------*/
   proc sort data=&all;
      by &pageby &tcontrol &tmt &sex;
      run;

   data &all;

      retain &pageby &order1 &level1 &order2 &level2 _aetype_ &tmt &sex;

      merge &all(in=in1) &pop(in=in2);
      by &pageby &tcontrol &tmt &sex;
      if in1;

      pct = round(n_pats / denom,1e-6);

      label
         denom    = 'Denominator'
         pct      = 'Proportion of patients reporting an AE'
         n_pats   = 'Number of patients reporting an AE'
         n_evts   = 'Number of AEs reported'
         _aetype_ = 'Type of classification'
           cutoff = 'Value used in CUTSTMT comparison.'

      %if "&order1" > "" %then %do;
         &order1  = 'Level 1 sort order variable'
         %end;
      %if "&order2" > "" %then %do;
         &order2  = 'Level 2 sort order variable'
         %end;

         ;
      run;

   proc sort data=&all;
      by &pageby &level1 &level2 _aetype_;
      run;


   /*
   / If the user specified a non-zero cutoff then subset the adverse events
   / by removing events with a percentage occurance less that the cutoff.
   /--------------------------------------------------------------------------*/

   %if "&cutoff" ^= "0" %then %do;
      proc summary nway missing data=&all(where=(%unquote(&cutwhere)));
         class &pageby &level1 &level2 _aetype_;
         var pct;
         output out=&cutd(drop=_freq_ _type_)
            &cutmnx=cutoff;
         run;
      %if &debug %then %do;
         title5 "DATA=CUTD(&cutd)";
         Proc print data=&cutd;
            run;
         title5;
         %end;
      data &all;
         merge &all(in=in1) &cutd(in=in2);
         by &pageby &level1 &level2 _aetype_;
         if cutoff < &cutoff then delete;
         run;
      %end;
   %else %if "&cutstmt" ^= "" %then %do;
      proc summary nway missing data=&all(where=(%unquote(&cutwhere)));
         class &pageby &level1 &level2 _aetype_;
         var pct;
         output out=&cutd(drop=_freq_ _type_)
            &cutmnx=cutoff;
         run;
      %if &debug %then %do;
         title5 "DATA=CUTD(&cutd)";
         Proc print data=&cutd;
            run;
         title5;
         %end;
      data &all;
         merge &all(in=in1) &cutd(in=in2);
         by &pageby &level1 &level2 _aetype_;
         %unquote(&cutstmt);
         run;
      %end;
   %else %let cutdata = ;

   /*
   / If the user asked for p-values then create a dataset for use by jkpval05.
   /--------------------------------------------------------------------------------*/

   /*
   / JHK001, Change reference
   / change CMHOR to CMHCOR
   /-----------------------------*/
   %if "&control"="" & %index(CHISQ EXACT CMH CMHGA CMHRMS CMHCOR LGOR,&p_value) %then %do;

      %local id;

      data &freq(keep=&pageby &level1 &level2 _aetype_ &tmt response weight _one_);

         set
            &all
               (
                keep  = &pageby &tmt &level1 &level2 n_pats denom _aetype_
                where = &tmtexcl
               )
            ;

         if _aetype_ <= &stlevel;

         retain _one_ 1;
         response = 1;
         weight   = n_pats;
         output;

         response = 2;
         weight   = denom - n_pats;
         output;

         run;

      %put NOTE: PAIRWISE=&pairwise;

      %local overall;

      %if "&p_value"="LGOR"
         %then %let overall = NO;
         %else %let overall = YES;


      %if &pairwise %then %do;
         %jkpaired(chkdata = NO,
                     print = NO,
                      data = &freq,
                     where = ,
                   overall = &overall,
                       out = &freq,
                        by = &pageby &level1 &level2 _aetype_,
                      pair = &tmt,
                    sortby = ,
                      sort = NO,
                    idname = _id_,
                        id = %str(compress(put(_1,3.)||'_'||put(_2,3.),' ')) )
         %let id = _id_;
         %end;
      %else %let id = ;

      %jkpval05(data = &freq,
                 out = &pval,
                  by = &pageby &level1 &level2 _aetype_,
                  id = &id,
             control = _one_,
                 tmt = &tmt,
              weight = weight,
            response = response,
             vartype = discrete,
             p_value = &p_value,
            pairwise = &pairwise,
               print = NO,
            freqopts = &freqopts)  /* JHK002 */

      data &all;
         merge &all(in=in1) &pval(in=in2);
         by &pageby &level1 &level2 _aetype_;
         if in1;


         label
            _ptype_ = 'Statistical test used for PROB'
             _cntl_ = 'The controlling variable name if used'
           _scores_ = 'Type of scores used in PROC FREQ'
               prob = 'p-values'
            ;


      %if "&p_value"="LGOR" %then %do;

         if pct > 0 then do;
            _p     = pct;
            _n     = denom;
            _q     = 1 - _p;

            retain zalpha 1.96;

            _a     = (2*_n*_p + zalpha**2 +1);
            _b     = zalpha*(zalpha**2 + 2 -(1/_n) +4*_p*(_n*_q -1))**0.5;
            _c     = 2*(_n+zalpha**2);

            ucb    = (_a+_b)/_c;
            drop _p _n zalpha _a _b _c _q;
            end;

         label ucb = '95% UCB';

         %end;



         run;

      %end;
   /*
   / JHK001, change reference
   / changed CMHOR to CMHCOR
   /------------------------------*/
   %else %if "&control" > "" & %index(LGOR CMH CMHRMS CMHGA CMHCOR,&p_value) %then %do;

      %local id;
      %local xaestat;
      %let xaestat = _X_&sysindex;

      %put NOTE: Tcontrol=&tcontrol, Control=&control;

      %AESTAT(  adverse = &adverse,
                  denom = &denom,
                outstat = &xaestat,
               uniqueid = &uniqueid,
                    sex = &sex,
                 pageby = &pageby,
                    tmt = &tmt,
                tmtexcl = &tmtexcl,

                 subgrp = &subgrp,

                 level1 = &level1,

                 level2 = &level2,

                p_value = NONE,
                control = &control,
                 recall = 1,
               pairwise = NO,
                stlevel = &stlevel,
                  print = NO,
                sasopts = &sasopts,
                  debug = 0)


      %put NOTE: Tcontrol=&tcontrol, Control=&control;

      data &freq(keep=&pageby &level1 &level2 _aetype_ &control &tmt response weight);

         set
            &xaestat
               (
                keep  = &pageby &tmt &control &level1 &level2 n_pats denom _aetype_
                where = &tmtexcl
               )
            ;

         if _aetype_ <= &stlevel;

         retain _one_ 1;

         response = 1;
         weight = n_pats;
         output;

         response = 2;
         weight = denom - n_pats;
         output;

         run;

      %put NOTE: PAIRWISE=&pairwise;

      %if &pairwise %then %do;

         %local overall;

         %if "&p_value"="LGOR"
            %then %let overall = NO;
            %else %let overall = YES;

         %jkpaired(chkdata = NO,
                     print = NO,
                      data = &freq,
                     where = ,
                       out = &freq,
                        by = &pageby &level1 &level2 _aetype_,
                      pair = &tmt,
                   overall = &overall,
                    sortby = ,
                      sort = NO,
                    idname = _id_,
                        id = %str(compress(put(_1,3.)||'_'||put(_2,3.),' ')) )

         %let id = _id_;
         %end;
      %else %let id = ;

      %if 0 %then %do;
         title5 "DATA=FREQ(&freq) just before call to jkpval05";
         proc print data=&freq;
            run;
         %end;

      %jkpval05(data = &freq,
                 out = &pval,
                  by = &pageby &level1 &level2 _aetype_,
                  id = &id,
             control = &control,
                 tmt = &tmt,
              weight = weight,
            response = response,
             vartype = discrete,
             p_value = &p_value,
            pairwise = &pairwise,
               print = no,
            freqopts = &freqopts)  /* JHK002 */


      data &all;
         merge
            &all
               (
                in = in1
               )
            &pval
               (
                in = in2
               )
            ;
         by &pageby &level1 &level2 _aetype_;

         if in1;

         length _cntl_ $8;
         retain _cntl_ "&control";

         label
            _ptype_ = 'Statistical test used for PROB'
             _cntl_ = 'The controlling variable name if used'
           _scores_ = 'Type of scores used in PROC FREQ'
               prob = 'p-values'
            ;

      %if "&p_value"="LGOR" %then %do;

         if pct > 0 then do;
            _p     = pct;
            _n     = denom;
            _q     = 1 - _p;

            retain zalpha 1.96;

            _a     = (2*_n*_p + zalpha**2 +1);
            _b     = zalpha*(zalpha**2 + 2 -(1/_n) +4*_p*(_n*_q -1))**0.5;
            _c     = 2*(_n+zalpha**2);

            ucb    = (_a+_b)/_c;
            drop _p _n zalpha _a _b _c _q;
            end;

         label ucb = '95% UCB';

         %end;

         run;
      %end;

   %else %do;
      %let pval = ;
      %let freq = ;
      %end;


   %if %bquote(&outsubj)^= %then %do;
      data &subj;
         merge
            &all
               (
                in=in1
               )
            &subj
               (
                in     = in2
                rename = (_freq_ = subj_frq)
               )
            ;

         by &pageby &level1 &level2 &tmt;
         if in1;

         label subj_frq = 'Subject events';
         run;

      proc sort data=&subj out=&outsubj;
         by &pageby &order1 &level1 &order2 &level2 _aetype_ &tcontrol &tmt;
         run;

      %if &print %then %do;
         title5 "DATA=OUTSUBJ(&outsubj) The subject list";
         proc contents data=&outsubj;
            run;
         proc print data=&outsubj;
            run;
         title5;
         %end;
      %end;


   /*
   / Sort the data by the ORDER variable within the PAGEBY variables.
   /--------------------------------------------------------------------------*/

   proc sort data=&all out=&outstat;
      by &pageby &order1 &level1 &order2 &level2 _aetype_ &tcontrol &tmt;
      run;



   /*
   / Delete the temporary data sets created by the macro
   /--------------------------------------------------------------------------*/
   proc delete
      data=&all &pop &pop2 &adv0 &adv1 &adv2 &zero
            &ztmt &freq &pval &order &subj &adv &tdenom &dups;
      run;


   proc datasets library=work;
      run;
      quit;

   %if &print %then %do;
      title5 "DATA=&outstat";
      proc contents data=&outstat;
         run;
      proc print data=&outstat;
         run;
      title5;
      %end;

 %EXIT:
   %put NOTE: ------------------------------------------------;
   %put NOTE: MACRO AESTAT Ending execution, Recall=&recall.;
   %put NOTE: ------------------------------------------------;
   %mend AESTAT;
&pageby &level1 &level2 _aetype_;
      run;


   /*
   / If the user specified a non-zero cutoff then subset the adverse events
   / by removing events with a percentage occurance less that the cutoff.
   /----------/users/d33/jf97633/sas_y2k/macros/aetab.sas                                                         0100664 0045717 0002024 00000157102 06634221437 0021315 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ PROGRAM NAME: aetab.sas
/
/ PROGRAM VERSION: 2.2
/
/ PROGRAM PURPOSE: Produce tables of adverse events using data from AESTAT.
/                  IDSG conforming.
/
/ SAS VERSION: 6.12
/
/ CREATED BY: John Henry King
/
/ DATE: 1993
/
/ INPUT PARAMETERS: see detailed description below.
/
/ OUTPUT CREATED: A SAS print file.
/
/ MACROS CALLED:
/
/   JKCHKDAT  Check input data for correct vars and type
/   JKCTCHR   Count characters in a string
/   JKXWORDS  Count words and create an array of the words.
/   JKPREFIX  Parse a list of words and add jkprefix constant text
/   JKRENLST  Create a "RENAME" list
/   JKLY0T01  Setup the page layout macro variables.
/   JKFLSZ2   Flow text, into 2 dimensional array
/   JKFLOWX   Flow text, into 1 dimensional array.
/   JKHPPCL   My version of HPPCL, to setup printer.
/
/ EXAMPLE CALL:
/
/   %aetab(  data = aestat,
/         outfile = ae1,
/          layout = port,
/         pagenum = pageof,
/          target = %sysget(LOGNAME),
/          level1 = bodytx,
/          style1 = 2,
/          level2 = grptx,
/         indent2 = 1,
/             tmt = tmt,
/          label2 = %str(Number of patients with any drug related event),
/          label3 = %str(Number of patients with any event),
/            swid = 20,
/            cwid = 13,
/        sbetween = 10,
/        pbetween = 10)
/
/=====================================================================================
/ CHANGE LOG:
/
/    MODIFIED BY: John Henry King
/    DATE:        28FEB1997
/    MODID:       JHK001
/    DESCRIPTION: Enhance error messages to make them more noticable.
/    ------------------------------------------------------------------------------
/    MODIFIED BY:  John Henry King
/    DATE:        28FEB1997
/    MODID:       JHK002
/    DESCRIPTION: Fixed bug on last.level2 printing when the report has more than
/                 one panel.  Also fixed problem with p-value printing in header
/                 with more than one panel.
/    ------------------------------------------------------------------------------
/    MODIFIED BY: John Henry King
/    DATE:        16JUL1997
/    MODID:       JHK003
/    DESCRIPTION: Add option CONTMSG=YES|NO to suppress the message
/                 continued...
/                 that the macro places at the bottom of the page.
/    ------------------------------------------------------------------------------
/    MODIFIED BY: John Henry King
/    DATE:        16JUL1997
/    MODID:       JHK004
/    DESCRIPTION: Increased dimension of column label array to accommodate
/                 more column label rows.
/    ------------------------------------------------------------------------------
/    MODIFIED BY: John Henry King
/    DATE:        08SEP1997
/    MODID:       JHK005
/    DESCRIPTION: Fixed bug in dim2 of JKFLSZ2 that I overlooked when I increased
/                 the column label rows.
/
/                 was
/                    %jkflsz2(in=_tl,out=_xl,size=&cwid,sizeAR=_tw,dim1=&cols,dim2=5)
/
/                 became
/                    %jkflsz2(in=_tl,out=_xl,size=&cwid,sizeAR=_tw,dim1=&cols,dim2=10)
/    ------------------------------------------------------------------------------
/    MODIFIED BY: John Henry King
/    DATE:        NOV1997
/    MODID:       JHK006
/    DESCRIPTION: Changes to make macro conform to IDSG standards.
/
/                 1) changed default PVALUE to NO.
/                 2) changed format of STYLE1=1
/                 3) added (N=XXX) to column headers.
/                 4) removed All events and number of patients from the header
/                 5) added default outfile value, user program name.
/                 6) changed defaults for CONTMSG and JOBID.
/                 7) added TOTAL= option
/                 8) added label text for columns when STYLE=2, LABEL3=
/    ------------------------------------------------------------------------------
/    MODIFIED BY: Margo S. Walden
/    DATE:        06FEB1998
/    MODID:       JHK007
/    DESCRIPTION: Correction of spelling and grammar in comments.
/    ------------------------------------------------------------------------------
/    MODIFIED BY: John Henry King
/    DATE:        17FEB1998
/    MODID:       JHK008
/    DESCRIPTION: Corrected problem with macro printing extra continued message.
/                 Added sort to sort after the formats are applied to LEVEL1 and
/                 LEVEL2.
/    ------------------------------------------------------------------------------
/    MODIFIED BY: Jonathan Fry
/    DATE:        09DEC1998
/    MODID:       JMF009
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 2.2
/    -----------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX010
/    DESCRIPTION:
/    -----------------------------------------------------------------------------
/======================================================================================*/

/*
/-------------------------------------------------------------------------------
/ Macro AETAB
/
/ Use this macro to produce a table of adverse events, with two levels of
/ grouping in the body of the table.  With further grouping on PAGEBY
/ variables.
/
/ The macro will fit the columns on the page using as many PANELS, or logical
/ pages, as needed to display all the columns.
/
/-------------------------------------------------------------------------------
/ Parameter=Default    Description
/ -----------------    ---------------------------------------------------------
/ DATA=                Names the input data set.  This data set must be output
/                      from macro AESTAT or a data set with that same structure.
/
/ OUTFILE=             Names the ASCII file that will receive the table.  Do NOT
/                      include an extension for this file the macro will use
/                      PCL or Pnn or Lnn for HPPCL(postscript portrait &
/                      postscript landscape, respectively).
/
/ DISP=                Use DISP=MOD to cause AETAB to append its output to the
/                      file named in the OUTFILE= option.  You should not change
/                      the layout of the file that is being appended to.
/
/ PAGENUM=             The PAGENUM=PAGEOF option allows the output from AETAB to
/                      be numbered in the style "Page n of  p".
/                      If you use the DISP=MOD option in your AETAB, then you should
/                      request PAGENUM=PAGEOF on the LAST call to AETAB only.
/                      When AETAB is running with DISP=MOD, a cumulative total of
/                      pages is kept so that they can be numbered inclusively.
/
/ TARGET=              This option is used in association with the PAGENUM= option.
/                      TARGET= specifies a character string that will be searched
/                      for when the macro is numbering pages.  The target is used
/                      to locate the "Page n of p" text.  The default value for
/                      target is the value of OUTFILE=.
/
/ CONTMSG = YES        This parameter turns on or off the continued message that the
/                      macro writes at the bottom of the page.  Use CONTMSG=OFF when
/                      you use PAGENUM= or if you are using MACPAGE to number the pages.
/
/
/ TMT=                 An INTEGER NUMERIC variable that defines the columns.
/                      If you used AESTAT to create the input data for AETAB,
/                      then TMT would be the same variable used in TMT in that
/                      macro call.
/
/ TMTFMT =             This parameter is used to specify the format for the treatment
/                      variable named in the TMT= parameter.  When this parameter is
/                      left blank, the macro uses a format with the same name as the
/                      TMT= parameter.
/
/
/ PAGEBY=              List the variable(s) that were used the in PAGEBY option
/                      of AESTAT.  When the value of the BY group changes, AETAB
/                      will start a new page.  The values of the PAGEBY variables
/                      are written on each page after the titles are printed.
/                      You can use the PUTBY option described below to control
/                      the printing of the BY variables.  The default action is
/                      to print the PAGEBY variables in the style of a SAS by line.
/
/                      pageby_var1=pageby_var1_value pageby_var2=pageby_var2_value...
/
/ PUTBY=               The PUTBY parameter allows the user to change the way
/                      the PAGEBY variables are printed.  Use put statement
/                      specifications as the value of the PUTBY parameter.
/                      For example:  If
/                         PAGEBY=PTCD STDYPHZ
/
/                      then PUTBY might look like this
/                         PUTBY='Protocol: ' ptcd :$ptcdfmt. / 'Study Phase: ' stdyphz :$phzfmt.
/
/                      and would produce the following PAGEBY line.
/                         Protocol: S2CT89
/                         Study Phase: Treatment
/
/                      You can use almost any PUT statement specifcation in the
/                      PUTBY parameter.  Do not use
/                         Line Pointer controls(#, OVERPRINT, or _PAGE_)
/                                          OR
/                         Line-hold specifiers(@ or @@)
/
/                      The macro determines the number of lines that PUTBY will
/                      produce by counting the number of "/", pointer controls.
/
/                      The default PUTBY is
/                         (&pageby) (=)
/
/
/ LEVEL1=              This parameter names the first level of adverse event
/                      classification, typically some type of body system
/                      grouping(SYMPCLASS or the first letter of a DISS code).
/
/ FINDENT1=0           Specifies the number of spaces to indent the second line
/                      of LEVEL1 text that is produced by flowing.
/
/ FMTLVL1=             Names the format used to print the values of LEVEL1.
/                      This can be a value labeling format, or if the values of
/                      LEVEL1 are not codes, then this could be left blank.
/
/ DISPLVL1=YES         This parameter turns off the number displays for the
/                      LEVEL1 rows.
/
/ ORDER1=_ORDER1_      Names the variable in the input data set that orders
/                      the values of LEVEL1
/
/ STYLE1=1             Use this parameter to control the look of the LEVEL1 rows
/
/                      1=   level1 value
/                           &label3        ee nn(pp)  ee nn(pp)
/
/                      2=   level1 value   ee nn(pp)  ee nn(pp)
/
/ SKIP1=1              Use this parameter to control the number of lines that are
/                      skipped at the end of a LEVEL1 group.
/
/ LEVEL2=              This parameter names the second level of adverse event
/                      classification(DISS code or SYMPGP).
/
/ INDENT2=0            Specifies the number of spaces to indent LEVEL2 text.
/
/ FINDENT2=1           Specifies the number of spaces to indent the second line
/                      of LEVEL2 text that is produced by flowing.  This is in
/                      addition to INDENT2 indentation.
/
/ FMTLVL2=             Names the format used to print the values of LEVEL2.
/                      This can be a value labeling format, or if the values of
/                      LEVEL2 are not codes, then this could be left blank.
/
/ ORDER2=_ORDER2_      Names the variable in the input data set that orders the
/                      levels of LEVEL2
/
/
/ LABEL1='ANY EVENT'   This parameter provides the label text for the overall
/                      number of subjects with any adverse event.
/
/
/ LABEL2='Any Event'   This parameter provides the label text for the counts
/                      associated with the LEVEL1= variable, when STYLE1=1.
/
/ LABEL3='No.!!!n!!!!%'
/                      This parameter provides the label text for the columns
/                      of the report when STYLE=2 is used.
/
/ STYLE=1              Specifies the printing style of counts and percents.
/
/                      1 = nn (pp)
/                      2 = EE nn (pp)
/                      where nn=number of patients
/                            pp=percent
/                            EE=number of events
/                      3 = nn/NN (pp)
/                      where nn=number of patients
/                            NN=population
/                            pp=percent
/
/ IFMT=3.              The format for printing the counts.
/
/ PCTFMT=JKPCT5.       The format for printing percents.  The default, JKPCT5.,
/                      is an internally created picture format.
/
/ PCTSIGN=NO           Used to include a percent sign (nn%) for printing the
/                      percents when using the PCTFMT.
/
/ PCTSTYLE=1           This parameter is used to modify the way percents are
/                      rounded when being print with the JKPCTn. format.
/
/                      PCTSTYLE=1 rounds and prints as follows:
/
/
/                             values
/                      ------------------------
/                      internal       formated
/
/                       >0 to <1        (<1)
/                        1 to 99        (pp)   rounded to integer
/                      >99 to <100     (>99)
/                         100          (100)
/                           0          blank
/                        missing       blank
/
/                      While PCTSTYLE=2 round and print as follows:
/
/                             values
/                      ------------------------
/                      internal       formated
/
/                       >0.5 to <1        (<1)
/                        1 to 99.5        (pp)   rounded to integer
/                      >99.5 to <100     (>99)
/                           100          (100)
/                             0          blank
/                          missing       blank
/
/
/
/
/ L1SIZE=10            This parameter determines maximum size of a LEVEL1 group that
/                      will be kept together on a page.  Any LEVEL1 group, including
/                      the LEVEL2 values associated with it, will be kept together
/                      if the total number lines needed to print them is less than
/                      L1SIZE.
/
/ L1PCT=.40            For LEVEL1 groups that are larger than L1SIZE, the parameter
/                      specifies the percent of the group to keep together on a page.
/
/ L1PCTMIN=5           If the value of L1PCT is smaller than L1PCT, then L1PCTMIN lines
/                      of a LEVEL1 group are kept together.
/
/
/ PVALUE = YES         Print p-value on the table?
/
/ PLABEL = 'p-value [1]'
/                      Plabel specifies the label for the p-value column.
/
/ INDENTF = 4          This parameter controls the number of columns that a continued
/                      footnote line is indented.  The footnotes are flowed into the
/                      linesize with the first line left justified and subsequent lines
/                      indented the number of columns specified by this parameter.
/
/                      Footnote lines may also have individual indenting controlled by
/                      the FINDTn macro variables.  For example:
/
/                      %let fnote2 = this is the footnote.
/                      %let findt2 = 6;
/
/                      In this example, if footnote 2 was flowed onto a second line, then
/                      that line would be indented 6 spaces.
/
/ HRDSPC = !           This is the hard space parameter.  This parameter specifies which
/                      character in a FOOTNOTE line will represent a hard space.
/                      By default, footnote text will have the occurrences of multiple
/                      spaces removed by flow macro.  You would need to use this
/                      parameter to indent the first line of a footnote.
/
/ LAYOUT = DEFAULT     This is the arrangement of the table on the printed
/                      page.  This parameter works the same as in the HPPCL
/                      macro developed by J.COMER.
/
/ CPI = 17             The number of characters per inch on the printed page.
/                      Possible values are 12 and 17.
/
/ LPI = 8              The number of lines per inch. Possible values are
/                      6, 8, and 10.
/
/ SWID = 20            The width of the table STUB in number of characters.
/                      The STUB is the part of the table that identifies the table
/                      rows.
/
/ CWID = 10            The number of characters to allow for each treatment
/                      column in the table.
/
/ PWID = 8             The number of characters to allow for each P-value
/                      column.
/
/ BETWEEN = 0          The number of characters to place between each column.
/                      When this parameter is 0, the columns are spaced
/                      to fill out the linesize of the table.
/
/ SBETWEEN = 2         Specifies extra spaces between the table stub and the
/                      first treatment column.
/
/ PBETWEEN = 3         Specifies the number of spaces between the last treatment
/                      column and the first p-value column.
/
/ BETWEENP = 2         Specifies the number of spaces between the p-value columns.
/
/
/ SMIN = 20            Minimum values for each of the column width parameters
/ CMIN = 8
/ PMIN = 6
/
/-----------------------------------------------------------------------------*/


%macro AETAB(  data=,
            outfile=,
               disp=,
            pagenum=NONE,
             target=,
            contmsg=NO,
              jobid=NO,

             pageby=,
              putby=,

             level1=,
            fmtlvl1=$200.,
           displvl1=YES,

             order1=_ORDER1_,
             style1=1,
              skip1=0,
           findent1=0,

             l1size=10,
              l1pct=.40,
           l1pctmin=5,

             level2=,
            fmtlvl2=$200.,
            indent2=3,
           findent2=1,
             order2=_ORDER2_,

                tmt=,
             tmtfmt=,

             pvalue=NO,
              pvars=PROB,
             plabel='p-value [1]',

                box='BODY SYSTEM \ !!!Event',
             label1='ANY EVENT',
             label2='Any Event',
             label3='No.!!!n!!!!%',

              style=1,
               ifmt=3.,

             pctfmt=jkpct6.,
            pctsign=YES,
           pctstyle=1,

            indentf=4,
             hrdspc=!,

             layout=DEFAULT,
                cpi=17,
                lpi=8,
               swid=30,
               cwid=10,
               pwid=8,
            between=0,
           sbetween=5,
           pbetween=3,
           betweenp=2,
               smin=20,
               cmin=8,
               pmin=6,
              ruler=NO,
            sasopts=NOSYMBOLGEN NOMLOGIC,
              debug=0,
              rbit1=0);

   options &sasopts;

   %if %substr(&sysscp%str(   ),1,3) = VMS %then %do;
      options cc=cr;
      %end;

      /*
      / JMF009
      / Display Macro Name and Version Number in LOG
      /-------------------------------------------------------------------*/

      %put ------------------------------------------------------ ;
      %put NOTE: Macro called: AETAB.SAS      Version Number: 2.2 ;
      %put ------------------------------------------------------ ;


   %global vaestat vaetab jkpg0;
   %let    vaetab = 1.0;

   /*
   / Assign default value to OUTFILE and create GLOBAL macro variable
   / to use in INFILE= parameter in MACAPGE.
   /-------------------------------------------------------------------*/
   %global _outfile;

   %if %bquote(&outfile)= %then %let outfile = %fn;

   /*
   / JHK001
   / New macro variable added to make error message more noticable.
   / All ! mark removed from old error messages.
   /--------------------------------------------------------------------------*/

   %local erdash;
   %let erdash = ERROR: _+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_;

   %if "&data"="" %then %do;
      %put &erdash;
      %put ERROR: There is no DATA= data set.;
      %put &erdash;
      %goto exit;
      %end;

   %if "&level1"="" %then %do;
      %put &erdash;
      %put ERROR: The macro parameter LEVEL1 must not be blank.;
      %put &erdash;
      %goto exit;
      %end;



   /*
   / Set up local macro variables to hold temporary data set names.
   /-----------------------------------------------------------------*/

   %local panel cnst header footer bign dclrows fprint lines
          panel2 flowed;
   %let panel    = _1_&sysindex;
   %let cnst     = _2_&sysindex;
   %let clabels  = _3_&sysindex;
   %let headfoot = _4_&sysindex;
   %let bign     = _5_&sysindex;
   %let dclrows  = _6_&sysindex;
   %let fprint   = _A_&sysindex;
   %let lines    = _B_&sysindex;
   %let panel2   = _E_&sysindex;
   %let flowed   = _F_&sysindex;



   /*
   / Upper case various input parameters as needed.
   /-------------------------------------------------------------------------*/

   %let outfile = &outfile;
   %let pvalue  = %upcase(&pvalue);
   %let pvars   = %upcase(&pvars);
   %let layout  = %upcase(&layout);
   %let pageby  = %upcase(&pageby);
   %let level1  = %upcase(&level1);
   %let order1  = %upcase(&order1);
   %let level2  = %upcase(&level2);
   %let order2  = %upcase(&order2);
   %let contmsg = %upcase(&contmsg);

   %let pctfmt  = %upcase(&pctfmt);
   %let pctsign = %upcase(&pctsign);
   %let style   = %upcase(&style);

   %let ruler   = %upcase(&ruler);
   %let disp    = %upcase(&disp);
   %let pagenum = %upcase(&pagenum);

   %let jobid   = %upcase(&jobid);
   %let displvl1= %upcase(&displvl1);

   %if %bquote(&tmt)= %then %do;
      %put &erdash;
      %put ERROR: The macro parameter TMT must not be blank.;
      %put &erdash;
      %goto exit;
      %end;

   %if %bquote(&tmtfmt)= %then %do;
      %let tmtfmt = %str(&tmt).;
      %end;


   %if %bquote(&contmsg)=YES | %bquote(&contmsg)=1
      %then %let contmsg = 1;
      %else %let contmsg = 0;

   %if "&pvalue"="YES" | "&pvalue"="1"
      %then %let pvalue=1;
      %else %let pvalue=0;


   %if "&displvl1"="NO" | "&displvl1"="0" | "&displvl1"="N"
      %then %let displvl1=0;
      %else %let displvl1=1;

   %if "&ruler"="YES" | "&ruler"="1"
      %then %let ruler=1;
      %else %let ruler=0;

   %if "&jobid"="YES" | "&jobid"="1"
      %then %let jobid = 1;
      %else %let jobid = 0;

   %if %length(&target)=0
      %then %let target = "&outfile";
      %else %let target = "&target";

   %if "&disp"^="MOD" %then %do;
      %let disp=;
      %let jkpg0 = 0;
      %end;


   %if "&pctsign"="YES" %then %do;
      %let pctsign = %str(%%);
      %if "&pctfmt" = "JKPCT5." %then %let pctfmt = JKPCT6.;
      %end;
   %else %do;
      %let pctsign = ;
      %end;

   %if ^("&pctstyle"="1" | "&pctstyle"="2") %then %let pctstyle=1;

   %put NOTE: PCTSIGN=&pctsign, PCTFMT=&pctfmt, PCTSTYLE=&pctstyle;



   %if "&order1" = "NONE" %then %let order1 = ;

   %if "&order2" = "NONE" %then %let order2 = ;
   %if "&level2"= ""      %then %let order2 = ;


   /*
   / Run the check data utility macro CHKDATA to verify the existence
   / of the input data and variable names.
   /-------------------------------------------------------------------------*/

   %jkchkdat(data=&data,
            nvars=&tmt _aetype_ n_pats n_evts denom pct,
            cvars=,
             vars=&pageby &level1 &order2 &level2 &order2)

   %if &RC %then %goto EXIT;



   /*
   / Global all the macro variables supplied by the user outside
   / the macro.  This insures that these variables are all defined
   / even if the user does not supply them all.
   /-----------------------------------------------------------------*/

   %global hl0 hl1 hl2 hl3 hl4 hl5 hl6 hl7 hl8 hl9 hl10
           hl11 hl12 hl13 hl14 hl15;

   %global hlright hlleft hlcont;

   %global fnote0  fnote1  fnote2  fnote3  fnote4  fnote5
           fnote6  fnote7  fnote8  fnote9  fnote10 fnote11
           fnote12 fnote13 fnote14 fnote15;

   %global findt0  findt1  findt2  findt3  findt4  findt5
           findt6  findt7  findt8  findt9  findt10 findt11
           findt12 findt13 findt14 findt15;

   %global enote0 enote1 enote2 enote3 enote4 enote5
                  enote6 enote7 enote8 enote9 enote10;

   %if %bquote(&fnote0) = %then %let fnote0 = 0;
   %if %bquote(&enote0) = %then %let enote0 = 0;

   /*
   / Process the pvars
   /----------------------------------------------------------------*/

   %local p_var0;

   %if ^&pvalue %then %let p_var0  = 0;
   %else              %let p_var0  = %jkxwords(list=&pvars,root=p_var);





   /*
   /
   / COLS      The maximum number of columns in the panels.
   / _PGBY0    The number of PAGEBY variables.
   / _PGBYLST  The last PAGEBY variable.
   / _PBYLINES The number of lines required to print the PAGEBY line(s).
   /----------------------------------------------------------------------*/

   %local cols colsplus maxwid _pgby0 _pgbylst pbylines idx;

   %if %bquote(&pageby) > %then %do;

      %let _pgby0   = %jkxwords(list=&pageby ,root=_pgby,delm=%str( ));
      %let _pgbylst = &&&_pgby&_pgby0;

      %if %length(&putby) = 0 %then %let putby = (&pageby) (=);

      %let pbylines = %eval(%jkctchr(&putby,%str(/)) + 1);

      %put NOTE: _PGBY0=&_pgby0, _PGBYLST=&_pgbylst PBYLINES=&pbylines;

      %let idx      = panpage;

      %end;

   %else %do;
      %let _pgby0   = 0;
      %let pbylines = 0;
      %let idx      = panel;
      %end;


   /*
   / Set up flags used to control printing of the appendix note,
   / the jobname information, and the table continued notes.
   /-----------------------------------------------------------------*/

   %local xcont;

   %if %bquote(&hl0)=  %then %let    hl0=10;

   %if %bquote(&hlcont)=
      %then %let xcont=0;
      %else %let xcont=1;


   %local flev1;

   %if %bquote(&style1) = %then %let style1 = 1;
   %if %bquote(&skip1)  = %then %let skip1  = 1;
   %if %bquote(&level2) > %then %let skip1  = 1;

   %if %bquote(&level2)= %then %let style1 = 2;

   %if       %bquote(&style1) = 1 %then %let flev1 = 2;
   %else %if %bquote(&style1) = 2 %then %let flev1 = 1;



   /*
   / Set up the page size based on user input.  The macro will try to
   / fit the table into the linesize implied by the user's selection
   / of LAYOUT, CPI, and LPI
   /----------------------------------------------------------------------*/

   %local ls ps dashchr file_ext file_dsp hppcl;

   %jklyot01

   %put NOTE: LAYOUT=&layout, CPI=&cpi, LPI=&lpi, LS=&ls, PS=&ps;


   /*
   / In this step, the values of the LEVELn variables are FLOWED
   / into the stub width.
   /------------------------------------------------------------------*/
   data &flowed;
      set &data;

      /*
      / JHK008 Changing temporary array to perminant.
      /------------------------------------------------*/

      /*
      / LEVEL1 variable
      /---------------------------------------------------*/
      array _y[1] $200;

      select(_aetype_);
         when(0)    _y[1] = &label1;
         otherwise  _y[1] = put(&level1,&fmtlvl1);
         end;


      %jkflowx(in=_y,out=_1lv,dim=10,size=%eval(&swid-&findent1))

      _1lv0 = max(1,_1lv0);


      /*
      / LEVEL2 variable
      /---------------------------------------------------*/
   %if %bquote(&level2) > %then %do;
      array _x[1] $200;

      select(_aetype_);
         when(0);
         when(1)   _x[1] = &label2;
         otherwise _x[1] = put(&level2,&fmtlvl2);
         end;

      %jkflowx(in=_x,out=_2lv,dim=10,size=%eval(&swid-&indent2-&findent2))

      %end;

   %else %do;
      retain _2lv0 0;
      %end;
      run;

   %let data = &flowed;
   /*
   / JHK008
   / Change level1 and level2 variable to Y1 and X1 respecively
   / and sort.
   /---------------------------------------------------------------*/


   %let level1 = _y1;
   %if %bquote(&level2) > %then %do;
      %let level2 = _x1;
      %end;

   proc sort data=&flowed out=&flowed;
      by &pageby &order1 &level1 &order2 &level2 _aetype_ &tmt;
      run;

   %if &debug %then %do;
      title5 "DATA=FLOWED(&flowed) with flowed text";
      proc print data=&flowed;
         run;
      %end;


   /*
   / Compute PANELS based on the number of treatments, the presence
   / of p-values, and the width of the various column components of the
   / table.
   /--------------------------------------------------------------------------*/

   options nofmterr;


   proc summary data=&data(where=(_aetype_=0)) nway missing;
      class &pageby &tmt;
      var denom;
      output out=&panel(drop=_type_ _freq_) sum=N_N_N;
      run;




   %if &debug %then %do;
      title5 "DATA=PANEL(panel) WITH BIG N for (N=xxx) in column headers";
      proc contents data=&panel;
         run;
      proc print data=&panel;
         run;
      %end;

   proc summary data=&data(where=(_aetype_=0)) nway missing;
      class &tmt;
      output out=&panel2(drop=_type_ _freq_);
      run;

   /*
   / This data set will contain column location constants.  This data
   / will be SET into the FILE PRINT data step below.
   /--------------------------------------------------------------------------*/

   %local candoit;
   %let cantdoit = 0;

   data &cnst;

      if 0 then set &panel2(drop=_all_) nobs=nobs;

      retain style "&style" pvalue &pvalue p_var0 &p_var0;

      retain ps &ps l1size &l1size l1pct &l1pct l1pctmin &l1pctmin pbylines &pbylines;

      drop i;

      tmt0 = nobs;

      iwid = int(&ifmt);

      pctwid = int(input(compress("&pctfmt",'ABCDEFGHIJKLMNOPQRSTUVWXYZ'),8.));

      /*
      / Compute CCWID-the width taken up by the contents of the columns.
      /----------------------------------------------------------------------*/

      select(style);
         when('1') ccwid = iwid + pctwid;
         when('2') ccwid = 1 + iwid * 2 + pctwid;
         when('3') ccwid = 1 + iwid * 2 + pctwid;
         otherwise do;
            ccwid = iwid + pwid;
            call symput('STYLE','1');
            style = '1';
            end;
         end;


      swid     = max(&swid,&smin);
      cwid     = max(&cwid,ccwid,&cmin);
      pwid     = max(&pwid,&pmin);

      btwn     = max(&between,1);
      between  = max(&between,0);
      pbetween = max(&pbetween,1);
      sbetween = max(&sbetween,0);
      betweenp = max(&betweenp,0);

      ls      = &ls;

      /*
      / Compute SPWID-the total number of columns occupied by the table stub
      / and p-values if requested.
      /-----------------------------------------------------------------------*/

      spwid = swid + sbetween;
      if pvalue then spwid = spwid + (pwid*p_var0)+(betweenp*(p_var0-1))+pbetween;

      /*
      / Now see how many TREATMENT columns will fit in the space left after
      / the stub and p-values.
      /-----------------------------------------------------------------------*/

      req = spwid;

      do tcols = 1 to tmt0;
         req = req + (cwid + btwn);
         if req > &ls then leave;
         end;


      /*
      / Tcols is the number of TREATMENT columns that will fit in 1 panel
      /-----------------------------------------------------------------------*/
      tcols = tcols - 1;

      if tcols=0 then do;
         call symput('CANTDOIT','1');
         stop;
         end;

      cols    = tcols + p_var0;

      /*
      / COFF is the column offset for the statistics printed in a treatment
      / column.  This centers the statistics under the column heading.
      / PCOFF is similar to COFF but is for the p-value column.
      /-----------------------------------------------------------------------*/

      coff  = max(floor((cwid-ccwid) / 2),0);
      pcoff = max(floor((pwid-6) / 2),0);


      /*
      / When no between value is specified, BETWEEN=0, the macro computes
      / BETWEEN to space the columns so that they fill up the available space.
      /-----------------------------------------------------------------------*/


      if between = 0 then do;

         between = floor( (ls - spwid - tcols*cwid) / max(tcols-1,1) );

         xxx = between;

         between = between - floor(between / tcols);

         between = max(between,1);

         end;



      /*
      / The array _TC will hold the column locations for each treatment column
      / and the p-value column.
      / The array _TW hold the width of each of these columns.  This is used by
      / the flow macro JKFLSZ2 to vary the size of the columns of flowed text.
      /-----------------------------------------------------------------------*/
      array _tc[40];
      array _tw[40];

      tmtreq = (tcols  * cwid) + (between  * (tcols-1));
      prbreq = (p_var0 * pwid) + (betweenp * (p_var0-1));

      _tc[1] = 1 + swid + sbetween;
      _tw[1] = cwid;

      do i = 2 to tcols;
         _tc[i] = _tc[i-1] + cwid + between;
         _tw[i] = cwid;
         end;

      do i = tcols+1 to cols;
         if i = tcols+1
            then _tc[i] = _tc[i-1] + _tw[i-1] + pbetween;
            else _tc[i] = _tc[i-1] + pwid     + betweenp;
         _tw[i] = pwid;
         end;


      /*
      / Create macro variable to hold COLS the number of columns, to use
      / in array declarations.
      /-----------------------------------------------------------------------*/

      call symput('COLS',    trim(left(put(cols,8.))));
      call symput('COLSPLUS',trim(left(put(1+cols,8.))));
      call symput('CWID',    trim(left(put(cwid,8.))));
      call symput('PWID',    trim(left(put(pwid,8.))));
      call symput('MAXWID',  trim(left(put(max(cwid,pwid,swid),8.))));

      output;
      stop;
      run;




   %if &cantdoit %then %do;
      %put ERROR: &erdash;
      %put ERROR: Your choices of    STUB: SWID=&swid, SBETWEEN=&sbetween;
      %put ERROR:              TX COLUMNS: CWID=&cwid, BETWEEN=&between;
      %put ERROR:           P-VAL COLUMNS: PWID=&pwid, PBETWEEN=&pbetween, BETWEENP=&betweenp;
      %put ERROR: will not allow the display of any treatment columns.;
      %put ERROR: Please choose smaller values for one or more of these parameters and resubmit.;
      %put ERROR: &erdash;
      %goto exit;
      %end;

   %if &debug | &rbit1 %then %do;
      title5 "DATA=CNST(&cnst) various constants associated with column and header placement";
      proc print data=&cnst;
         run;
      %end;


   /*
   / Using the data set of treatment values divide the treatments into panels
   / using TCOLS from above.  This data will be merged with the input data
   / below.
   /--------------------------------------------------------------------------*/

   data &panel;
      set &panel;
      by &pageby;
      if _n_ = 1 then set &cnst(keep=tcols);
      drop tcols n;

      retain panel n;

   %if %bquote(&pageby) > %then %do;
      if first.&_pgbylst then do;
         panel = 0;
         n     = 0;
         end;
      %end;
   %else %do;
      if _n_ = 1 then do;
         panel = 0;
         n     = 0;
         end;
      %end;

      n = n + 1;

      if mod(n , tcols) = 1 then panel = panel + 1;

      run;

   %if &debug %then %do;
      title5 "DATA=PANEL(&panel)";
      proc print data=&panel;
         run;
      title5;
      %end;


   /*
   / Now using the treatment data set that has been divided up into panels,
   / flow the column header text into the space provided by the column width
   / array.
   /--------------------------------------------------------------------------*/

   proc summary data=&panel nway missing;
      class &pageby panel &tmt;
      var n_n_n;
      output out=&clabels(drop=_type_ _freq_) sum=;
      run;
   %if &debug %then %do;
      title5 "DATA=CLABELS(&clabels) with BIG N. for N=xxx";
      proc print data=&clabels;
         run;
      %end;

   proc transpose data=&clabels out=&bigN prefix=bn;
      by &pageby panel;
      var n_n_n;
      run;

   proc transpose data=&clabels out=&clabels prefix=tc;
      by &pageby panel;
      var &tmt;
      run;

   %if &debug %then %do;
      title5 "DATA=CLABELS(&clabels) the transpose column labels before flowing.";
      proc print data=&clabels;
         run;
      title5 "DATA=BIGN(&bign) the transpose column big Ns";
      proc print data=&bign;
         run;
      %end;


   data &clabels(keep=&pageby panel max _xl:);

      merge
         &clabels
         &bign
         ;

      by &pageby panel;

      array _tc[*] tc:;
      array _bn[*] bn:;

      if _n_ = 1 then set &cnst(keep=_tw1-_tw&cols tcols swid style);

      array _tw[&colsplus] _tw1-_tw&cols swid;

      array _tl[&colsplus] $100;

      /*
      / Assign TL[cols+1] the value of the BOX parameter
      /-----------------------------------------------------------------*/

      _tl[&colsplus] = &box;
      if _tl[&colsplus] = ' ' then _tl[&colsplus] = '!';


      /*
      / Create the format labels using the TMT format
      /------------------------------------------------*/

      ntmts = n(of _tc[*]);

      do i = 1 to dim(_tc);
         if _tc[i] <= .Z then continue;
         _tl[i] = put(_tc[i],&tmtfmt) || ' \ (N=' || trim(left(put(_bn[i],best8.))) ||')';
         if style=2 then do;
            _tl[i] = trim(_tl[i])||' \ '||repeat(&dashchr,&cwid-1)||' \ '||&label3;
            end;
         if &ruler then _tl[i] = trim(_tl[i])||' '|| substr(repeat('....+',10),1,&cwid);
         end;

      %if &pvalue %then %do;
         j = 0;
         if &p_var0=1 & "&p_var1"='PROB' then do;
            _tl[&cols]= &plabel;
            if &ruler  then _tl[&cols]= trim(_tl[&cols])||' '||substr('....+....+....+....+',1,&pwid);
            end;
         else do i = tcols+1 to &cols;
            j = j + 1;
            VAR = SYMGET('P_VAR'||left(put(j,4.)));
            _tl[i] = put(var,$pvars.);
            if &ruler then _tl[i]= trim(_tl[i])||' '||substr('....+....+....+....+',1,&pwid);
            end;
         %end;


      /*
      / Flow the labels into the columns based on the column
      / width. CWID may be different for treatments and
      / p-values.
      /------------------------------------------------------*/

      /*
      / JHK005
      /--------*/
      %jkflsz2(in=_tl,
              out=_xl,
             size=&maxwid,
           sizeAR=_tw,
             dim1=&colsplus,
             dim2=10);

      max = max(of _xl0_[*],0);
      run;

   %if &debug %then %do;
      title5 "DATA=CLABELS(&clabels) after flowing";
      proc print data=&clabels;
         run;
      %end;


   proc summary data=&clabels nway missing;
      var max;
      output out=&dclrows(drop=_type_ _freq_)
             max=clrows;
      run;

   data &clabels
         (
         keep  = &pageby panel clrows _cl:
         index = (&idx=(&pageby panel) / unique)
         );

      set &clabels(drop=max);

      if _n_ = 1 then set &dclrows;

      /*
      / JHK004
      / changed 5 to 10 in _xl array
      / and in _cl array below
      /---------------------------------*/
      array   _xl[&colsplus,10];
      array _xl0_[&colsplus];


      /*
      / Move the labels down so that they will look pushed up
      / rather that hung down.
      /------------------------------------------------------*/
      array   _cl[&colsplus,10] $&maxwid;
      array _cl0_[&colsplus];

      _cl0 = _xl0;

      do i = 1 to _cl0;
         _cl0_[i] = clrows;
         offset = clrows - _xl0_[i];
         do k = 1 to _xl0_[i];
            _cl[i,k+offset] = _xl[i,k];
            end;
         end;
      run;
   %if &debug %then %do;
      title5 "DATA=CLABELS(&clabels)";
      proc contents data=&clabels;
         run;
      proc print data=&clabels;
         run;
      %end;


   /*
   / Flow the footnote data so that the footnotes will fit in
   / the linesize chosen for the table.
   /---------------------------------------------------------*/

   data
      &headfoot
         (
          keep = _fn: _fi:  _en:  tfnlines hlleft hlright
                 _hl:
         )
      ;

      retain _hl0 &hl0 _hl1-_hl15;
      retain hlleft "&hlleft" hlright "&hlright";

      array _hl[15] $&ls
         ("&hl1","&hl2","&hl3","&hl4","&hl5","&hl6","&hl7","&hl8","&hl9","&hl10",
          "&hl11","&hl12","&hl13","&hl14","&hl15");


      array _xn[15] $200 _temporary_
         ("&fnote1",  "&fnote2",  "&fnote3",  "&fnote4",  "&fnote5",
          "&fnote6",  "&fnote7",  "&fnote8",  "&fnote9",  "&fnote10",
          "&fnote11", "&fnote12", "&fnote13", "&fnote14", "&fnote15");

      array _xi[15] $2 _temporary_
         ("&findt1",  "&findt2",  "&findt3",  "&findt4",  "&findt5",
          "&findt6",  "&findt7",  "&findt8",  "&findt9",  "&findt10",
          "&findt11", "&findt12", "&findt13", "&findt14", "&findt15");

      array _fi[15];
      array _sz[15];

      do i = 1 to dim(_xi);
         if _xi[i]=' '
            then _fi[i] = max(&indentf,0);
            else _fi[i] = input(_xi[i],2.);
         _sz[i] = &ls - _fi[i];
         end;


      do i = 1 to dim(_xn);
         _xn[i] = compbl(_xn[i]);
         end;


      %jkflsz2(in=_xn,out=_fn,size=&ls,sizear=_sz,dim1=15,dim2=5)

      do i = 1 to dim1(_fn);
         do j = 1 to dim2(_fn);
            _fn[i,j] = translate(_fn[i,j],' ',"&hrdspc");
            end;
         end;

      tfnlines = sum(of _fn0_[*]);

      _en0 = min(&enote0, 10);
      array _en[10] $200
         ("&enote1","&enote2","&enote3","&enote4","&enote5",
          "&enote6","&enote7","&enote8","&enote9","&enote10");


      output;
      run;

   %if &debug %then %do;
      title5 "DATA=HEADFOOT(&headfoot) The titles footnotes and endnotes data";
      proc print data=&headfoot;
         run;
      %end;


   /*
   / Reduce the data to one observation per AE.
   / This dataset will be used to pre-print the table
   /----------------------------------------------------------*/

   proc summary data=&data nway missing;
      class &pageby &order1 &level1 &order2 &level2;
      var _1lv0 _2lv0;
      output out = &fprint(drop=_type_ _freq_)
             max = ;
      run;

   %if &debug %then %do;
      title5 "DATA=FPRINT(&fprint) created by PROC SUMMARY";
      proc print data=&fprint;
         run;
      %end;


   proc summary data=&fprint nway missing;
      class &pageby &order1 &level1;
      var _2lv0;
      output out=&lines(drop=_type_ rename=(_freq_=_lines_))
             sum=sum_2lv0;
      run;

   %if &debug %then %do;
      title5 "DATA=LINES(&lines)";
      proc print data=&lines;
         run;
      %end;




   data &fprint;
      merge
         &fprint
         &lines;

      by &pageby &order1 &level1;

      if _n_ = 1 then do;
         set     &cnst(keep=ps ls l1size l1pct l1pctmin pbylines);
         set  &clabels(keep=clrows);
         set &headfoot(keep=tfnlines _en0 _hl0);

         retain fline0 hline0;

         retain flev1 &flev1 skip1 &skip1;

         hline0 = _hl0 + clrows + 3 + pbylines;

         /*
         / JHK003
         / Changed +2 to +1 + &contmsg
         /----------------------------------------------*/
         fline0 = tfnlines + _en0 + &contmsg + 1;

      %if ^&rbit1 %then %do;
         drop ps ls l1size l1pct l1pctmin clrows _hl0
              tfnlines _en0 pbylines cll need1 need2  l1flag
               _1lv0  _2lv0  _lines_  sum_2lv0  fline0  hline0
               ll  effps used flev1 skip1;
         %end;

         end;

      retain ll effps l1flag;

   %if %bquote(&pageby) > %then %do;
      if first.&_pgbylst then link header;
      %end;
   %else %do;
      if _n_=1 then link header;
      %end;

      cll = ll;

      if first.&level1 then do;
         l1flag = 0;
         need1 = sum_2lv0 + (_1lv0-1) + &flev1 + &skip1;
         need2 = max(ceil(need1 * l1pct),l1pctmin);
         link level1;
         end;
      else if ^l1flag then do;
         link ll;
         end;

      select;
         when(first.&level1 & last.&level1) used = (&flev1 + &skip1 + (_1lv0-1));
         when(first.&level1)                used = (&flev1 + (_1lv0-1));
         when(last.&level1)                 used = (max(1,_2lv0) + &skip1);
         otherwise                          used =  _2lv0;
         end;

      ll = ll - used;

      return;

    Header:
      /*
      / Subtract the lines taken up by the header
      / and footer.
      /------------------------------------------------------*/
      page + 1;
      ll    = ps - (hline0 + fline0 + ^first.&level1);
      effps = ll;
      return;

    LL:

      if ll < (first.&level1*&flev1 + (_1lv0-1))
            + (last.&level1*&skip1) + _2lv0 + 1 then do;
         link header;
         end;

      return;

    Level1:

      if need1 < l1size then do;
         l1flag = 1;
         if ll < need1 then do;
            link header;
            end;
         end;
      else if need1 <= ll then do;
         l1flag = 1;
         end;
      else do;
         if ll < need2 then link header;
         end;

      return;

      run;

   data &fprint;
      /*
      / JHK008
      / Added end=eof and IF EOF statement
      / And last.&_pgbylst
      /----------------------------------------------------------*/
      set &fprint end=eof;
      by &pageby &order1 &level1 page;
      if last.page  & ^(last.&level1)  then cont=1;
      if first.page & ^(first.&level1) then cont=1;
      if eof then cont = 0;

      %if %bquote(&pageby) > %then %do;
         if last.&_pgbylst then cont=0;
         %end;

      run;


   %if &debug | &rbit1 %then %do;
      title5 "DATA=FPRINT(&fprint) before sort and merge";
      proc contents data=&fprint;
         run;
      proc print data=&fprint;
         format &level1 &level2 $8.;
         run;
      %end;


   proc sort data=&fprint;
      by &pageby &order1 &level1 &order2 &level2;
      run;

   %if &debug %then %do;
      title5 "DATA=FPRINT(&fprint) after sorting, before merge to AEdata";
      proc print data=&fprint;
         run;
      %end;

   data &fprint;
      merge &fprint &data;
      by &pageby &order1 &level1 &order2 &level2;
      run;


   %if &debug %then %do;
      title5 "DATA=FPRINT(&fprint) after merge to FLOWED AEdata";
      proc print data=&fprint;
         run;
      %end;


   /*
   / Sort the input data by TREATMENT and merge with the data set of
   / treatments and panels.
   /--------------------------------------------------------------------------*/

   proc sort data=&fprint;
      by &pageby &tmt;
      run;

   data &fprint;

      retain &pageby page panel &order1 &level1 &order2 &level2 &tmt;
      merge &fprint &panel;
      by &pageby &tmt;


   %if %index(&pctfmt,JKPCT) %then %do;

      %if &pctstyle=1 %then %do;
         if pct > .Z  then do;
            pct = pct * 1E2;
            select;
               when(0 <  pct < 1)   pct=.A;
               when(99 < pct < 100) pct=.B;
               otherwise            pct=round(pct,1);
               end;
            end;
         %end;
      %else %if &pctstyle=2 %then %do;
         if pct > .Z then do;
            pct = pct * 1e2;
            select;
               when(0    < pct < 0.5) pct=.A;
               when(99.5 < pct < 100) pct=.B;
               otherwise              pct=round(pct,1);
               end;
            end;
         %end;
      %end;

      run;

   proc sort data=&fprint;
      by &pageby page panel &order1 &level1 &order2 &level2 &tmt;
      run;

   %if &debug %then %do;
      title5 "DATA=FPRINT(&fprint) Ready to be printed by data _null_";
      proc contents data=&fprint;
         run;
      proc print data=&fprint;
         format _character_ $8.;
         run;
      %end;

   proc format;
      picture jkpct
           1-99,100 = " 009&pctsign)" (prefix='(')
                  0 = "     "         (noedit)
                 .A = " (<1&pctsign)" (noedit)
                 .B = "(>99&pctsign)" (noedit);
      run;


   %if &hppcl %then %do;
      /*
      / Call JKHPPCL to setup printing environment
      /-------------------------------------------*/
      %jkhppcl(cpi=&cpi,lpi=&lpi,layout=&layout)

      data _null_;
         file "&outfile..PCL" print notitles ls=200;
         &setup
         run;
      %end;

   %let _outfile = &outfile%str(.)&file_ext;

   options missing=' ';

   data _null_;
      file "&outfile%str(.)&file_ext"
            &file_dsp
            print
            notitles
            ls   = 200
            ps   = &ps
            n    = ps
            line = putline;

      set &fprint end=eof;
      by &pageby page panel &order1 &level1 &order2 &level2 &tmt;

      retain xcont &xcont style1 "&style1" skip1 &skip1 _one_ 1;

      if _n_ = 1 then do;
         set
            &cnst
               (
                keep = _tc1-_tc&cols _tw1-_tw&cols cols coff pcoff tcols
                       style pvalue between iwid swid
               )
            ;

         array _tc[&colsplus] _tc1-_tc&cols _one_;
         array _tw[&colsplus] _tw1-_tw&cols swid;

         set &headfoot;
         array _fn0_[15];
         array   _fn[15,5];
         array   _fi[15];

         array _en[10];
         array _hl[15];

         end;


      array _1lv[10];
      array _2lv[10];


      if first.panel then do;
         set &clabels(keep=&pageby panel clrows _cl:) key=&idx / unique;

         array _cl0_[&colsplus];

         /*
         / JHK004
         / changed 5 to 10
         /---------------------------*/
         array   _cl[&colsplus,10];

         put _page_ @;
         link header;
         end;

      if first.&level1 | _top_ then do;
         if cont then put '... continuing ' &level1:&fmtlvl1;
         else do;
            if style1='2' then do;
               select(_1lv0);
                  when(1) put _1lv[1] @;
                  otherwise do;
                     put _1lv[1];
                     do i = 2 to _1lv0-1;
                        put +(&findent1) _1lv[i];
                        end;
                     put +(&findent1) _1lv[_1lv0] @;

                     end;
                  end;
               end;

            else if style1='1' then do;
               select(_aetype_);
                  when(0) select(_1lv0);
                     when(1) put _1lv[1] @;
                     otherwise do;
                        put _1lv[1];
                        do i = 2 to _1lv0-1;
                           put +(&findent1) _1lv[i];
                           end;
                        put +(&findent1) _1lv[_1lv0] @;
                        end;
                     end;
                  otherwise do;
                     put _1lv[1];
                     do i = 2 to _1lv0;
                        put +(&findent1) _1lv[i];
                        end;
                     end;
                  end;
               end;

            end;
         end;


   %if %bquote(&level2) > %then %do;

      if first.&level2 then do;
         ncol = 0;
         select(style1);
            when('1')                      put +(&indent2) _2lv[1] @;
            when('2') if _aetype_ > 1 then put +(&indent2) _2lv[1] @;
            otherwise;
            end;
         end;

      %end;
   %else %do;
      if first.&level1 then ncol = 0;
      %end;

      if first.&tmt then ncol + 1;

   %if ^(&displvl1) %then %do;
      if _aetype_ > 1 then do;
         select(style);
            when('1') put @(_tc[ncol]+coff) n_pats &ifmt pct &pctfmt @;
            when('2') put @(_tc[ncol]+coff) n_evts &ifmt +1 n_pats &ifmt pct &pctfmt @;
            when('3') put @(_tc[ncol]+coff) n_pats &ifmt "/" denom &ifmt pct &pctfmt @;
            end;
         end;
      %end;
   %else %do;
      select(style);
         when('1') put @(_tc[ncol]+coff) n_pats &ifmt pct &pctfmt @;
         when('2') put @(_tc[ncol]+coff) n_evts &ifmt +1 n_pats &ifmt pct &pctfmt @;
         when('3') put @(_tc[ncol]+coff) n_pats &ifmt "/" denom &ifmt pct &pctfmt @;
         end;
      %end;

   %if %bquote(&level2) > %then %do;
      if last.&level2 then do;
      %end;
   %else %do;
      if last.&level1 then do;
      %end;

      /*
      / If the user requested PVALUE=YES
      /----------------------------------------------------------*/
      %if &pvalue %then %do;
         array _pvars[*] &pvars;
         j = tcols;
         do i = 1 to dim(_pvars);
            j = j + 1;
            if .Z < _pvars[i] < 0.001 then do;
               cprob = '<0.001';
               put   @(_tc[j]+pcoff) cprob $6. @;
               end;
            else do;
               put @(_tc[j]+pcoff) _pvars[i] 6.3 @;
               end;
            end;
         %end;

         put;

         do i = 2 to _2lv0;
            put +(&findent2+&indent2) _2lv[i];
            end;

         end;



   %if %bquote(&level2) > %then %do;

      if style1 = '1' then do;
         if last.&level1 & ^last.panel then put;
         end;
      else do;
         if last.&level1 & ^last.panel then put;
         end;
      %end;

   %else %do;
      if style1 = '1'  | style1='2' then do;
         if last.&level1 & ^last.panel then do i = 1 to skip1;
            put;
            end;
         end;
      %end;

      if last.panel then link footer;

      if eof then do;
         call symput('JKPG0',trim(left(put(realpage+&jkpg0,8.))));
         end;

      return;

    Header:

      realpage + 1;

      _top_ = 1;

      length _tempvar $&ls;

      do i = 1 to _hl0;
         select;
            when(indexw(hlright,put(i,2.))) do;
               _tempvar = _hl[i];
               _tempvar = right(_tempvar);
               _tempvar = translate(_tempvar,' ',"&hrdspc");
               put #(i) _tempvar $char&ls..;
               end;
            when(indexw(hlleft, put(i,2.))) do;
               _tempvar = _hl[i];
               _tempvar = left(_tempvar);
               _tempvar = translate(_tempvar,' ',"&hrdspc");
               put #(i) _tempvar $char&ls..;
               end;
            otherwise do;
               _tempvar = left(_hl[i]);
               _tempvar = repeat(' ',floor((&ls-length(_tempvar))/2)-1)||_tempvar;
               _tempvar = translate(_tempvar,' ',"&hrdspc");
               put #(i) _tempvar $char&ls..;
               end;
            end;
         end;

   %if %bquote(&pageby) > %then %do;
      put %unquote(&putby);
      %end;

      put;

      do i = 1 to max(of _cl0_[*],0);
         do j = _cl0;
            _wid     = _tw[j];
            _cl[j,i] = translate(_cl[j,i],' ',"&hrdspc");
            put @(1) _cl[j,i] $varying100. _wid @;
            end;

         do j = 1 to _cl0-1;
            _wid     = _tw[j];
            _offset  = floor( (_tw[j]-length(_cl[j,i])) / 2 );
            _cl[j,i] = translate(_cl[j,i],' ',"&hrdspc");
            put @(_tc[j]+_offset) _cl[j,i] $varying100. _wid @;
            end;
         put;
         end;





      put &ls*&dashchr;
      put;

      return;

    Footer:

      if cont then put &level1:&fmtlvl1 'continues ...';
      put;

   /*
   / JHK003
   / CONTMSG, added macro if statement
   /-------------------------------------------------------*/
   %if &contmsg %then %do;
      if ^eof then do;
         length xnote $&ls;
         retain xnote 'Continued...';
         put xnote $&ls..-r;
         end;
      %end;

      do i = 1 to _fn0;
         do k = 1 to _fn0_[i];
            if k = 1
               then put    _fn[i,k] $char&ls..;
               else put +(_fi[i]+0) _fn[i,k] $char&ls..;
            end;
         end;

      k = _en0;
      do i = 1 to _en0;
         put #(&ps-k+1) _en[i] $&ls..-l;
         k = k - 1;
         end;
      return;
      run;

   proc delete
      data = &panel &bign &cnst &header &footer &dclrows &fprint &lines
             &panel2 &flowed
         ;
      run;


   %put NOTE: JKPG0=&jkpg0;

   %if %bquote(&pagenum) = PAGEOF %then %do;
      data _null_;

         infile "&outfile%str(.)&file_ext" sharebuffers n=1 length=l;
         file   "&outfile%str(.)&file_ext";

         input line $varying200. L;

         if index(line,&target) then do;
            page + 1;

            text = Compbl('Page '||put(page,8.)||" of &jkpg0");
            tlen = length (text);

            substr(line,1+&ls-tlen,tlen) = text;

            put line $varying200. L;

            end;

         run;
      %end;

   %GOTO EXIT;

 %EXIT:
   %PUT NOTE: Macro AETAB ending execution.;

   %mend AETAB;
5 "DATA=FPRINT(&fprint) after merge to FLOWED AEdata";
      proc print data=&fprint;
         run;
      %end;


   /*
   / Sort the input data by TREATMENT and merge with the data set of
   / treatments and panels.
   /--------------------------------------------------------------------------*/

   proc sort data=&fprint;
      by &pageby &tmt;
      run;

   data &fprint;

      retain &pageby page panel &order1 &level1 &order2 &level2 &tm/users/d33/jf97633/sas_y2k/macros/age.sas                                                           0100664 0045717 0002024 00000004035 06634221466 0020773 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/
/ Program Name:     AGE.SAS
/
/ Program Version:  2.1
/
/ Program purpose:  To return an age value at a specific date, relative to a date of birth (i.e.
/                   numbers of elapsed years, rounding down).
/
/ SAS Version:      6.12
/
/ Created By:       John H. King
/ Date:
/
/ Input Parameters: FROM - A SAS date value, representing the baseline date (date of birth)
/                   TO   - A SAS date value, representing the date at which age is calculated.
/
/ Output Created:   Numbers of whole elapsed years (rounding down).
/
/ Macros Called:    None.
/
/ Example Call:     bthdt = '13AUG65'd;
/                   today = '20FEB97'd;
/                   age = %age(bthdt,today);
/
/================================================================================================
/ Change Log:
/
/   MODIFIED BY: Jonathan Fry
/   DATE:        09DEC1998
/   MODID:       JMF001
/   DESCRIPTION: Tested for Y2K compliance.
/                Add %PUT statement for Macro Name and Version Number.
/                Change Version Number to 2.1.
/   -----------------------------------------------------------------------------
/   MODIFIED BY:
/   DATE:
/   MODID:       XXX002
/   DESCRIPTION:
/   -----------------------------------------------------------------------------
/================================================================================================*/

%macro age(from,to);

/*-------------------------------------------------------------------------/
/ JMF001                                                                   /
/ Display Macro Name and Version Number in LOG                             /
/-------------------------------------------------------------------------*/

   %put ------------------------------------------------------;
   %put NOTE: Macro called: AGE.SAS        Version Number: 2.1;
   %put ------------------------------------------------------;

   (
      ( year(&to)   - year(&from) )
    - ( month(&to) <= month(&from) )
    + ( month(&to)  = month(&from) & day (&to) >= day (&from) )
   )
   %mend;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   /users/d33/jf97633/sas_y2k/macros/bwcont.sas                                                        0100664 0045717 0002024 00000040125 06634222136 0021526 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ Program Name:     BWCONT.SAS
/
/ Program Version:  3.1
/
/ Program purpose:  An enhanced version of PROC CONTENTS
/
/ SAS Version:      6.12
/
/ Created By:       John H. King
/ Date:
/
/ Input Parameters: DATA     - name of dataset being processed
/                   OUT      - name of dataset containing information on the DATA
/                              dataset
/                   ROUND    - parameter for defining level of rounding for numeric
                               variables (optional)
/                   REPORT   - (Y/N) option specifying whether to produce a report
/                   ALLMISSC - list of character variables with all values missing
/                   ALLMISSN - list of numeric variables with all values missing
/
/ Output Created:   Standard dataset information is obtained using PROC CONTENTS.
/                   The following addition information is obtained:
/
/                       - Number of observations with missing values for each variable
/                       - Number of variables where all values are missing
/                       - Length of format required for printing
/
/                   The extra information is stored in a set of macro variables. If the REPORT
/                   option is specified, output is produced in a format similar to PROC CONTENTS,
/                   with the extra information printed on the report.
/
/ Macros Called:    BWGETTF
/
/ Example Call:
/
/================================================================================================
/ Change Log
/
/    MODIFIED BY: KK
/    DATE:        31.3.95
/    MODID:       001
/    DESCRIPTION: Changed NUM -> CHAR conversion method.
/    --------------------------------------------------------------------------------
/    MODIFIED BY: Jonathan Fry
/    DATE:        09DEC1998
/    MODID:       JMF002
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 3.1.
/    --------------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    --------------------------------------------------------------------------------
/================================================================================================*/

%macro bwcont(data=,
              out=_OUT_,
            round=,
           report=Y,
         allmissC=MISSC,
         allmissN=MISSN);
   %let data   =%upcase(&data);

      /*
      / JMF002
      / Display Macro Name and Version Number in LOG.
      /------------------------------------------------------------------*/

      %put ------------------------------------------------------;
      %put NOTE: Macro called: BWCONT.SAS     Version Number: 3.1;
      %put ------------------------------------------------------;


   /*
   / declare macro variables
   /
   /------------------------------------------------------------------*/
   %if %length(&report)>0 %then
     %let report=%upcase(%substr(&report,1,1)) ;
   %let allmissC=%upcase(&allmissC);
   %let allmissN=%upcase(&allmissN);
   %local rv l type1 type2 linesize
      vnum1 vnum2 vnum3 vnum4 vnum5 vnum6 vnum7 vnum8 vnum9 vnum10
      vchr1 vchr2 vchr3 vchr4 vchr5 vchr6 vchr7 vchr8 vchr9 vchr10;
   %global &allmissn.0 &allmissn &allmissc.0 &allmissc;
   %local ___n1 ___n2 ___n3 ___n4 ___n5 ___n6 ___n7 ___n8 ___n9 ___n10;
   %local ___c1 ___c2 ___c3 ___c4 ___c5 ___c6 ___c7 ___c8 ___c9 ___c10;
   %if %substr(&sysver,1,1)=6
      %then %let rv=varnum=var0;
      %else %let rv=;
   proc contents data=&data out=&out(rename=(&rv)) noprint;
      run;
   %if &syserr>0 %then %do;
      %put NOTE: SYSERR=&syserr SYSINFO=&sysinfo;
      %put NOTE: Program terminated by invoked macro BWCONT.;
      ;endsas;
      %end;
   proc format;
      value __f__ 0 = '      ';
      value __t__ 1 = 'NUM' 2 = 'CHAR';
      run;
   proc sort data=&out;
      by name;
      run;
   /*
   / create character variables from proc contents format and infromat
   / variables this will be used for printing later on.
   /------------------------------------------------------------------*/
   /*
   / in this next step create macro variable arrays of all the numeric
   / and character variables in the input data set. this is done by
   / processing the output from proc cotents
   /------------------------------------------------------------------*/
   %let l = 200;
   data _null_;
      array _n(n0)  $&l n1-n10;
      array _c(c0)  $&l c1-c10;
      n0=1; c0=1;
      do until(eof);
         set &out end=eof;
         nvars + 1;
         type1 + type=1;
         type2 + type=2;
         if type = 1 then do;
            if length(_N) + length(name) + 3 > &l then n0=n0+1;
            _N = trim(_N)||' '||name;
            end;
         else if type = 2 then do;
            if length(_C) + length(name) + 3 > &l then c0=c0+1;
            _C = trim(_C)||' '||name;
            end;
         end;
      call symput('NVARS',left(put(nvars,8.)));
      call symput('TYPE1',left(put(type1,8.)));
      call symput('TYPE2',left(put(type2,8.)));
      call symput('VNUM1',left(trim(n1)));
      call symput('VNUM2',left(trim(n2)));
      call symput('VNUM3',left(trim(n3)));
      call symput('VNUM4',left(trim(n4)));
      call symput('VNUM5',left(trim(n5)));
      call symput('VNUM6',left(trim(n5)));
      call symput('VNUM7',left(trim(n5)));
      call symput('VNUM8',left(trim(n5)));
      call symput('VNUM9',left(trim(n5)));
      call symput('VNUM10',left(trim(n5)));
      call symput('VCHR1',left(trim(c1)));
      call symput('VCHR2',left(trim(c2)));
      call symput('VCHR3',left(trim(c3)));
      call symput('VCHR4',left(trim(c4)));
      call symput('VCHR5',left(trim(c5)));
      call symput('VCHR6',left(trim(c5)));
      call symput('VCHR7',left(trim(c5)));
      call symput('VCHR8',left(trim(c5)));
      call symput('VCHR9',left(trim(c5)));
      call symput('VCHR10',left(trim(c5)));
      run;
   /*
   / now read the input data and calculate the added information to
   / include in the new proc contents output.
   / 1) number of missing values per variable
   / 2) calculated length for character and numeric vars
   / 3) calculated formats for each var
   /------------------------------------------------------------------*/
   data _out2_(rename=(__NAME__=name));
      keep _format_ __name__ _length_ _MISS_;
      length __name__ $8. _format_ $8;
      format __name__ _format_ $char8.;
      do until(eof);
         set &data end=eof;
      %if &type1^=0 %then %do;
         array __N &vnum1 &vnum2 &vnum3 &vnum4 &vnum5
                   &vnum6 &vnum7 &vnum8 &vnum9 &vnum10;
         array __NA __na1-__na&type1;
         array __NB __nb1-__nb&type1;
         array __NMIN __m1-__m&type1;
         array __NMAX __x1-__x&type1;
         array __NMIS __y1-__y&type1;
         length __best __dig1-__dig2 $32;
         do over __N;
         %if "&round"="" %then %do;
*        KK 31/3/95 Change num -> char method due to rounding error;
*            __best = put(__N,best32.);
             __best = compress(__N||' ');
            %end;
         %else %do;
            if __N > .Z
               then __best = put(round(__N,&round),best32.);
               else __best = ' . ';
            %end;
            __dig1 = left(scan(__best,1,'.'));
            __dig2 = left(scan(__best,2,'.'));
            __NA   = max(1,__NA,length(__dig1)-(__dig1=' '));
            __NB   = max(__NB,length(__dig2)-(__dig2=' '));
            __NMAX = max(__NMAX,__N);
            __NMIN = max(__NMIN,__N);
            __NMIS + .Z >= __N;
            end;
         %end;
      %if &type2^=0 %then %do;
         array __C &vchr1 &vchr2 &vchr3 &vchr4 &vchr5
                   &vchr6 &vchr7 &vchr8 &vchr9 &vchr10;
         array __CL __cl1-__cl&type2;
         array __CMIS __cy1-__cy&type2;
         do over __C;
            __CL    = max(__CL,length(__C)-(__C=' '));
            __CMIS + __C=' ';
            end;
         %end;
         end;
      %if &type1^=0 %then %do;
         do over __N;
            _format_ = put((__NB>0) + __NB + __NA,4.)||'.'||
                       left(put(__NB,__F__.));
            if __NB=0 then select;
               when(__NMIN>=-255             & __NMAX<=255)
                  _length_=2;
               when(__NMIN>=-65535           & __NMAX<=65535)
                  _length_=3;
               when(__NMIN>=-16777215        & __NMAX<=16777215)
                  _length_=4;
               when(__NMIN>=-4294967295      & __NMAX<=4294967295)
                  _length_=5;
               when(__NMIN>=-1099511627775   & __NMAX<=1099511627775)
                  _length_=6;
               when(__NMIN>=-281474946710655 & __NMAX<=281474946710655)
                  _length_=7;
               otherwise _Length_=8;
               end;
            else _length_ = 8;
            _MISS_ = __NMIS;
            call vname(__N,__name__);
            output;
            end;
         __name__=' '; _format_=' ';
         %end;
      %if &type2^=0 %then %do;
         length _length_ 8;
         do over __C;
            _length_ = __CL;
            _format_ = put(max(_length_,1),4.)||'.';
            substr(_format_,verify(_format_,' ')-1,1)='$';
            _miss_ = __CMIS;
            call vname(__C,__name__);
            output;
            end;
         %end;
      run;
   /*
   / sort and merge the original proc contents output dataset to the
   / added information calculated in the step above
   /------------------------------------------------------------------*/
   proc sort data=_out2_;
      by name;
      run;
   data &out;
      merge &out _out2_;
      by name;
      retain nvars &nvars;
      length fmt  ifmt $16.;
      fmt  = input(compress(trim(format)||
             put(formatl,__F__.)||'.'||put(formatd,__F__.)),$16.);
      ifmt = input(compress(trim(informat)||
             put(informl,__F__.)||'.'||put(informd,__F__.)),$16.);
      run;
   proc sort data=&out;
      by var0;
      run;
   /*
   / now process the enhanced proc contents output data set to provide
   / information on variables with all missing values. this info will
   / be displayed in the printed output and provided as variables lists
   / in two macro variables.
   /------------------------------------------------------------------*/
   data _null_;
      retain ___cidx ___nidx 1;
      array __C(___cidx) $200 ___c1-___c10;
      array __N(___nidx) $200 ___n1-___n10;
      retain ___c1-___c10 ___n1-___n10;
      set &out(keep=name type nobs _miss_) end=eof;
      retain nvars &nvars;
      if nobs=_miss_ then do;
         if type=1 then do;
            ___mn0 + 1;
            if length(__n) + length(name) + 1 > 200 then ___nidx + 1;
            __n = trim(__n)||' '||name;
            end;
         else if type=2 then do;
            ___mc0 + 1;
            if length(__c) + length(name) + 1 > 200 then ___cidx + 1;
            __c = trim(__c)||' '||name;
            end;
         end;
      if eof then do;
         call symput("&allmissn"||'0',left(put(___mn0,8.)));
         call symput('___N1' ,trim(___n1));
         call symput('___N2' ,trim(___n2));
         call symput('___N3' ,trim(___n3));
         call symput('___N4' ,trim(___n4));
         call symput('___N5' ,trim(___n5));
         call symput('___N6' ,trim(___n6));
         call symput('___N7' ,trim(___n7));
         call symput('___N8' ,trim(___n8));
         call symput('___N9' ,trim(___n9));
         call symput('___N10',trim(___n10));

         call symput("&allmissc"||'0',left(put(___mc0,8.)));
         call symput('___C1' ,trim(___c1));
         call symput('___C2' ,trim(___c2));
         call symput('___C3' ,trim(___c3));
         call symput('___C4' ,trim(___c4));
         call symput('___C5' ,trim(___c5));
         call symput('___C6' ,trim(___c6));
         call symput('___C7' ,trim(___c7));
         call symput('___C8' ,trim(___c8));
         call symput('___C9' ,trim(___c9));
         call symput('___C10',trim(___c10));
         end;
      run;
   %let &allmissn=&___n1 &___n2 &___n3 &___n4 &___n5 &___n6 &___n7 &___n8 &___n9
 &___n10;
   %let &allmissc=&___c1 &___c2 &___c3 &___c4 &___c5 &___c6 &___c7 &___c8 &___c9
 &___c10;

%if &report=Y %then %do ;
   /*
   / Call macro bwgettf to get the current titles and footnotes so
   / they can be printed in the report just like a sas proc would do
   /------------------------------------------------------------------*/
   %bwgettf(dump=NO)
   %let linesize=&_bwls;

   /*
   / if the linesize is less than 125 then set it to 125 because the
   / report need at least that large of a linesize. not exactly like
   / a sas proc now is it.
   /------------------------------------------------------------------*/
   %if &_bwls<125 %then %do;
      %let linesize=&_bwls;
      options ls=125;
      %bwgettf(dump=NO)
      %end;

   data _null_;
      file print notitles ls=&_bwls ps=&_bwps ll=ll header=header;
      retain missc &missc0 missn &missn0;
      retain ps &_bwps ls &_bwls _f0 &_bwf0 _t0 &_bwt0;
      retain adjust 0 center &_bwct;
      if _n_=1 & center then adjust=int((ls-125)/2);
      set &out end=eof;
      link ll;
      put + adjust
          +0  VAR0            4.
          +1  NAME       $CHAR8.
          +1  _MISS_          7.
          +2  TYPE        __T__.
          +1  _length_        5.
          +1  length          5.
          +1  NPOS            7.
          +2  _FORMAT_       $7.
          +3  FMT       $CHAR11.
          +2  IFMT      $CHAR11.
          +2  label     $CHAR40. ;
      if eof then link footer;
      return;
    LL:
      if ll < (2 + _f0) then do;
         link footer;
         put _page_ @;
         end;
      return;
    Footer:
      put +adjust 125*'-';
      array _f{10} $200 _temporary_
         ("&_bwf1","&_bwf2","&_bwf3","&_bwf4","&_bwf5",
          "&_bwf6","&_bwf7","&_bwf8","&_bwf9","&_bwf10");
      if _f0 > 0 then do;
         line = ps - _f0 + 1;
         do i = 1 to _f0;
            put #line _f{i} $varying200. ls;
            line = line + 1;
            end;
         end;
      return;
    Header:
      array _t{10} $200 _temporary_
         ("&_bwt1","&_bwt2","&_bwt3","&_bwt4","&_bwt5",
          "&_bwt6","&_bwt7","&_bwt8","&_bwt9","&_bwt10");
      do line = 1 to _t0;
         put #line _t{line} $varying200. ls;
         end;

      length __h $ 200;
      __h = 'Burroughs Wellcome Co. Contents Procedure';
      link cprint;

      __h = 'Contents of Sas Member '
             ||trim(libname)||'.'||trim(memname);
      link cprint;
      put //;
      if memlabel^='' then do;
         __h = 'Data Set Label: '||trim(memlabel);
         link lprint;
         end;

      __h = 'Number of Observations: '||trim(left(put(nobs,16.)))||
             '   Number of Variables: '||left(put(nvars,16.));
      link lprint;
      if missn>0 then do;
         __h=put(missn,5.)||
             ' Numeric variables have all missing values';
         link lprint;
         end;
      if missc>0 then do;
         __h=put(missc,5.)||
             ' Character variables have all missing values';
         link lprint;
         end;

      __h = '----List of Variables and Attributes by Position----';
      __h=repeat(' ',round((125-length(__h))/2)-1) || trim(left(__h));
      __hl = length(__h);
      put // +adjust __h $varying200. __hl;

      put +adjust +17 '# of';
      put +adjust +5
     'Variable Missing        ---Length--         ------Format------';
      put +adjust +3
         '# Name      Values  Type  Calc Actual    Pos  Calc'
         '      Actual       Informat     Label';
      put +adjust 125*'-';
      return;
    Lprint:
      __hl = length(__h);
      put +adjust __h $varying200. __hl;
      return;
    Cprint:
     if center then
         __h=repeat(' ',round((ls-length(__h))/2)-1) || trim(left(__h));
      __hl = length(__h);
      put @1 __h $varying200. __hl;
      return;
      run;
   options _last_=&data linesize=&linesize;
   %put ---------------------------------------------------------------;
   %put List of variables with all missing values.;
   %put -  Numeric &allmissn.0=&&&allmissn.0;
   %put -  &allmissn=&&&allmissn;
   %put -  Character &allmissc.0=&&&allmissc.0;
   %put -  &allmissc=&&&allmissc;
   %put ---------------------------------------------------------------;
%end ;
   %mend bwcont;
ated length for character and numeric vars
   / 3) calculated formats for each var
   /------------------------------------------------------------------*/
   data _out2_(rename=(__NAME__=name));
      keep _format_ __name__ _length_ _MISS_;
      length __name__ $8. _format_ $8;
      format __name__ _format_ $char8.;
      do until(eof);
         set &data end=eof;
      %if &type1^=0 %then %do;
         array __N &vnum1 /users/d33/jf97633/sas_y2k/macros/bwgettf.sas                                                       0100664 0045717 0002024 00000013115 06634221614 0021673 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ Program Name:     BWGETTF.SAS
/
/ Program Version:  2.2
/
/ Program purpose:  Use this utility macro to access the currently defined SAS
/                   TITLES and FOOTNOTES, and the current values of the LS PS
/                   and CENTER options.  The values are returned in macro variables
/                   whose names can be changed with the macro options T F LS PS and
/                   CENTER.
/
/                   This macro must be called at a step boundry because it calls
/                   PROC DISPLAY and will produce a step boundry anyway.
/
/                   See macro BWCONT for an example of how this macro can be used.
/
/ SAS Version:      6.12
/
/ Created By:
/ Date:
/
/ Input Parameters: T      - Name of variable for storing title information.
/                   F      - Name of variable for storing footnote information.
/                   LS     - Name of variable for storing linesize information.
/                   PS     - Name of variable for storing pagesize information.
/                   CENTER - Name of variable for storing CENTER/NOCENTER option status.
/                   DUMP   - Option enables the above information to be dumped to the SAS log.
/
/ Output Created:   Title, footnote, linesize, pagesize and CENTER/NOCENTER information output to
/                   SAS log if option DUMP=YES specified.
/
/ Macros Called:    None.
/
/ Example Call:     %bwgettf();
/
/===================================================================================================
/ Change Log
/
/    MODIFIED BY: ABR
/    DATE:        10.2.93
/    MODID:       Ver 1.5
/    DESCRIPTION: Remove commented LIBNAME statement.
/    -------------------------------------------------------------------------------------------
/    MODIFIED BY: Steve Mallett
/    DATE:        28.2.97
/    MODID:       Ver 2
/    DESCRIPTION: Added keyword parameter to allow libname to be specified at macro call time.
/    -------------------------------------------------------------------------------------------
/    MODIFIED BY: John Henry King
/    DATE:        11NOV1997
/    MODID:       Ver 2.1
/    DESCRIPTION: Changed the macro to use SYSFUNC and GETOPTION and SASHELP.VTITLE. The macro no
/                 longer needs the the SCL program to operate.
/    -------------------------------------------------------------------------------------------
/    MODIFIED BY: Jonathan Fry
/    DATE:        09DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 2.2.
/    -------------------------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    -------------------------------------------------------------------------------------------
/====================================================================================================*/

%macro bwgettf(t = _BWT,
               f = _BWF,
              ls = _BWLS,
              ps = _BWPS,
          center = _BWCT,
            dump = YES,
          catlib = UTILSCL);

      /*
      / JMF001
      / Display Macro Name and Version Number in LOG
      /-----------------------------------------------------------------*/

      %put ------------------------------------------------------;
      %put NOTE: Macro called: BWGETTF.SAS    Version Number: 2.2;
      %put ------------------------------------------------------;


   %if "&sysscp"="SUN 4" %then %do;
      %if &sysver<6.09 %then %do;
         %put ERROR: You must use version 6.09 or higher with SUMTAB.;
         %if &sysenv=BACK %then %str(;ENDSAS;);
         %end;
      %end;

   %local i;
   %let dump=%upcase(&dump);
   %let tl=&t.L;
   %let fl=&f.L;

   %global &t.0;
   %let    &t.0 = 0;

   %global &t.1 &t.2 &t.3 &t.4 &t.5 &t.6 &t.7 &t.8 &t.9 &t.10;
   %global &tl.1 &tl.2 &tl.3 &tl.4 &tl.5 &tl.6 &tl.7 &tl.8 &tl.9 &tl.10;

   %global &f.0;
   %let    &f.0 = 0;
   %global &f.1 &f.2 &f.3 &f.4 &f.5 &f.6 &f.7 &f.8 &f.9 &f.10;
   %global &fl.1 &fl.2 &fl.3 &fl.4 &fl.5 &fl.6 &fl.7 &fl.8 &fl.9 &fl.10;
   %global &ls &ps &center;
   %let &ls     = 0;
   %let &ps     = 0;
   %let &center = 0;

   %do;
      %let &ls     = %sysfunc(getoption(LINESIZE));
      %let &ps     = %sysfunc(getoption(PAGESIZE));
      %let &center = %sysfunc(getoption(CENTER));

      data _null_;
         set
            sashelp.vtitle
            end = eof;

         select(type);
            when('T') do;
               hl0 + 1;
               call symput("&t" || left(put(number,f2.)) , text);
               end;
            when('F') do;
               fnote0 + 1;
               call symput("&f" || left(put(number,f2.)) , text);
               end;
            otherwise;
            end;

         if eof then do;
            call symput("&t.0" , trim(left(put(hl0   ,f2.))));
            call symput("&f.0" , trim(left(put(fnote0,f2.))));
            end;
         run;

      %end;

   %if &dump=YES %then %do;
      %put Macro Variable Dump From Macro BWGETTF;
      %put %str(   ) Linesize(&ls=&&&ls) Pagesize(&ps=&&&ps);
      %put %str(   ) Center(&center=&&&center);
      %put Titles -----------------------------------------------------;
      %put %str(   ) Defined &t.0=&&&t.0;
      %do i = 1 %to &&&t.0;
         %put %str(     ) &tl.&i=&&&tl.&i &t.&i=&&&t.&i;
         %end;
      %put Footnotes --------------------------------------------------;
      %put %str(  ) Defined &f.0=&&&f.0;
      %do i = 1 %to &&&f.0;
         %put %str(     ) &fl.&i=&&&fl.&i &f.&i=&&&f.&i;
         %end;
      %end;
   %mend;
                                                                                                                                                                                                                                                                                                                                                                                                                                                   /users/d33/jf97633/sas_y2k/macros/bwwords.sas                                                       0100664 0045717 0002024 00000005440 06634222330 0021716 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ Program Name:     BWWORDS.SAS
/
/ Program Version:  2.1
/
/ Program purpose:  Takes a character string and splits it into a series of words, based on a defined
/                   delimiter. Each word is stored in a seperate macro variable, and the total number
/                   of words is returned to the calling program.
/
/                   Macro BWWORDS is a slight modification of the WORDS macro described in the SAS
/                   Guide to Macro Processing.
/
/ SAS Version:      6.12
/
/ Created By:
/ Date:
/
/ Input Parameters: STRING - The name of the variable containing the character string.
/                   ROOT   - A prefix for the series of variables containing the separated words (default = W).
/                   DELM   - A delimiter character, used for separating words (default = a space).
/
/ Output Created:   A series of macros variables containing the separated words, and the total
/                   number of words.
/
/ Macros Called:    None.
/
/ Example Call:
/                   string = "This is a string containing seven words";
/                   %bwwords(string);
/
/=============================================================================================================
/ Change Log
/
/   MODIFIED BY: Jonathan Fry
/   DATE:        09DEC1998
/   MODID:       JMF001
/   DESCRIPTION: Tested for Y2K compliance.
/                Add %PUT statement for Macro Name and Version Number.
/                Change Version Number to 2.1.
/   ----------------------------------------------------------------------------
/   MODIFIED BY:
/   DATE:
/   MODID:       XXX002
/   DESCRIPTION:
/   ----------------------------------------------------------------------------
/   MODIFIED BY:
/   DATE:
/   MODID:       XXX003
/   DESCRIPTION:
/   ----------------------------------------------------------------------------
/=============================================================================================================*/

%MACRO BWWORDS(STRING,ROOT=W,DELM=%STR( ));

/*--------------------------------------------------------------------------/
/ JMF001                                                                    /
/ Display Macro Name and Version Number in LOG                              /
/--------------------------------------------------------------------------*/

   %put ------------------------------------------------------;
   %put NOTE: Macro called: BWWORDS.SAS    Version Number: 2.1;
   %put ------------------------------------------------------;

   %local count word;
   %let count = 1;
   %let word = %scan(&string,&count,&delm);
   %do %while(%quote(&word)~=);
      %global &root&count;
      %let &root&count = &word;
      %let count = %eval(&count + 1);
      %let word = %scan(&string,&count,&delm);
      %end;
   %eval(&count - 1)
   %mend bwwords;
ing words (default = a space).
/
/ Output Created:   A series of macros variables containing the separated words, and the total
/                   number of words.
/
/ Macros Called:    None.
/
/ Example Call:
/            /users/d33/jf97633/sas_y2k/macros/c_to_n.sas                                                        0100664 0045717 0002024 00000005443 06634222606 0021501 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ Program Name:     C_TO_N.sas (Macro)
/
/ Program Version:  1.1
/
/ MDP/Protocol id:  N/A
/
/ Program Purpose:  Convert character variables to numeric, drop the character
/                   variables, and rename the new numeric variables using the old
/                   names.  All in one data step.
/
/ SAS Version:      Unix 6.12
/
/ Created By:       M. Foxwell.
/ Date:             05NOV97
/
/ Input Parameters:
/
/ Output Created:
/
/ Macros Called:    None
/
/ Example Call:     Suppose you have a data set with 10 character variables
/                   that you need to convert to numeric for analysis.
/
/                      data nums;
/                      set chars;
/
/                         %c_to_n(varlist = A B C D E F G H I J)
/
/                      run;
/
/====================================================================================
/ Change Log:
/
/    MODIFIED BY: M Foxwell
/    DATE:        05NOV97
/    MODID:
/    DESCRIPTION: Changed informat in input function from 8. to best12..
/                 This leaves numeric variables unchanged if inadvertently
/                 put through the macro.
/    -------------------------------------------------------------------
/    MODIFIED BY: Jonathan Fry
/    DATE:        09DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2k compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change the Version Number to 1.1.
/    -------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    -------------------------------------------------------------------
/=====================================================================================*/

%macro c_to_n(varlist=);

/*------------------------------------------------------------------------/
/ JMF001                                                                  /
/ Display Macro Name and Version Number in LOG                            /
/------------------------------------------------------------------------*/

   %put ------------------------------------------------------;
   %put NOTE: Macro called: C_TO_N.SAS     Version Number: 1.1;
   %put ------------------------------------------------------;

/*------------------------------------------------------------------------/
/ This macro uses the same list scanning logic as %WORDS                  /
/------------------------------------------------------------------------*/

   %local i word delm;
   %let delm = %str( );
   %let i    = 1;
   %let word = %scan(&varlist,&i,&delm);

   %do %while("&word"^="");

      _&i = input(&word,best12.);
      drop &word;
      rename _&i = &word;

      %let i = %eval(&i + 1);
      %let word = %scan(&varlist,&i,&delm);

      %end;

   %mend c_to_n;
                                                                                                                                                                                                                             /users/d33/jf97633/sas_y2k/macros/chkvar.sas                                                        0100664 0045717 0002024 00000006675 06634223007 0021522 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ Program Name:     CHKVAR.SAS
/
/ Program Version:  2.1
/
/ Program purpose:  Check if variables are in a data set.
/
/ SAS Version:      6.12
/
/ Created By:       Carl P. Arneson
/ Date:             26 Mar 1993
/
/ Input Parameters: VAR  - List of variables to be processed.
/                   FLAG - List of corresponding flag variables.
/
/ Output Created:   Flag variables are assigned a value 1 if the corresponding variable
/                   is initialized.
/
/ Macros Called:    None.
/
/ Example Call:     %chkvar(var=name age var1 var3,flag=fname fage fvar1 fvar3);
/
/================================================================================================
/ Change Log
/
/    MODIFIED BY: Jonathan Fry
/    DATE:        09DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 2.1.
/    ---------------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    ---------------------------------------------------------------------------------
/=================================================================================================*/

%macro chkvar(var=,flag=) ;

/*------------------------------------------------------------------------/
/ JMF001                                                                  /
/ Display Macro Name and Version Number in LOG                            /
/------------------------------------------------------------------------*/

      %put ------------------------------------------------------;
      %put NOTE: Macro called: CHKVAR.SAS     Version Number: 2.1;
      %put ------------------------------------------------------;


  %local vcnt v fcnt f ;
  %let vcnt = 1 ;
  %let v = %upcase(%scan(&var,&vcnt,%str( ))) ;
  %do %while(&v~= ) ;
    %local v&vcnt ;
    %let v&vcnt = &v ;
    %let vcnt = %eval(&vcnt + 1) ;
    %let v = %upcase(%scan(&var,&vcnt,%str( ))) ;
  %end ;
  %let vcnt = %eval(&vcnt - 1) ;

  %let fcnt = 1 ;
  %let f = %upcase(%scan(&flag,&fcnt,%str( ))) ;
  %do %while(&f~= ) ;
    %local f&fcnt ;
    %let f&fcnt = &f ;
    %let fcnt = %eval(&fcnt + 1) ;
    %let f = %upcase(%scan(&flag,&fcnt,%str( ))) ;
  %end ;
  %let fcnt = %eval(&fcnt - 1) ;

  %local mincnt ;
  %if &fcnt ~= &vcnt %then %do ;
    %put WARNING: Number of flags does not equal number of variables. ;
    %if &fcnt<&vcnt %then %let mincnt = &fcnt ;
    %else %let mincnt = &vcnt ;
  %end ;
  %else %let mincnt = &fcnt ;

  %if &mincnt=0 %then %do ;
    %put WARNING:  No VAR= or FLAG= has been specified, macro will end.;
    %goto finish ;
  %end ;

  array _c_v_a_r {*} _character_ _c_d_u_m ;
  array _n_v_a_r {*} _numeric_ _n_d_u_m ;
  drop _c_n_t_ _f_l_a_g _v_n_a_m _n_d_u_m _c_d_u_m ;
  length _v_n_a_m $8 ;
  retain _f_l_a_g 1 &flag 0 ;
  if _f_l_a_g then do ;
    do _c_n_t_ = 1 to (dim(_c_v_a_r)-1) ;
       call vname(_c_v_a_r{_c_n_t_},_v_n_a_m) ;
       select (_v_n_a_m) ;
         %do i = 1 %to &mincnt ;
           when ("&&v&i") &&f&i = 1 ;
         %end ;
         otherwise ;
       end ;
    end ;
    do _c_n_t_ = 1 to (dim(_n_v_a_r)-1) ;
       call vname(_n_v_a_r{_c_n_t_},_v_n_a_m) ;
       select (_v_n_a_m) ;
         %do i = 1 %to &mincnt ;
           when ("&&v&i") &&f&i = 1 ;
         %end ;
         otherwise ;
       end ;
    end ;
    _f_l_a_g = 0 ;
  end ;

  %finish :
%mend chkvar ;
                                                                   /users/d33/jf97633/sas_y2k/macros/dsobs.sas                                                         0100664 0045717 0002024 00000004257 06634223126 0021352 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ Program Name:     DSOBS.SAS
/
/ Program Version:  2.1
/
/ Program purpose:  This macro stores the number of observations in a data set in
/                   a specified macro variable (modified version of %NUMOBS, shown
/                   on p. 263 of "SAS Guide to Macro Processing" for Version 6)
/
/ SAS Version:      6.12
/
/ Created By:
/ Date:
/
/ Input Parameters: DATA - Name of dataset (default is last dataset referenced).
/                   MV   - Name of variable to store result (default = _NOBS).
/
/ Output Created:   Number of observations in dataset.
/
/ Macros Called:    None.
/
/ Example Call:     %DSOBS(data=data.ae, mv=nae);
/
/================================================================================================
/ Change Log
/
/    MODIFIED BY: Jonathan Fry
/    DATE:        09DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 2.1.
/    -------------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    -------------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    -------------------------------------------------------------------------------
/================================================================================================*/

%macro DSOBS(data=_LAST_,mv=_nobs) ;

/*-----------------------------------------------------------------------------/
/ JMF001                                                                       /
/ Display Macro Name and Version Number in LOG                                 /
/-----------------------------------------------------------------------------*/

     %put ---------------------------------------------------;
     %put NOTE: Macro called: DSOBS.SAS   Version Number: 2.1;
     %put ---------------------------------------------------;


  %global &mv ;
  data _null_ ;
    if 0 then set &data nobs=count ;
    call symput("&mv",left(put(count,8.))) ;
    stop ;
    run ;
%mend DSOBS ;
                                                                                                                                                                                                                                                                                                                                                 /users/d33/jf97633/sas_y2k/macros/dtab.sas                                                          0100664 0045717 0002024 00000234412 06634223324 0021150 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ PROGRAM NAME:     DTAB.SAS
/
/ PROGRAM VERSION:  3.1
/
/ PROGRAM PURPOSE:  Creates tables using a special data set that has
/                   the same structure as a SIMSTAT outstat data set.
/
/ SAS VERSION:      6.12 (UNIX)
/
/ CREATED BY:       John Henry King
/
/ DATE:             FEB1997
/
/ INPUT PARAMETERS: See details below.
/
/ OUTPUT CREATED:   A SAS print file.
/
/ MACROS CALLED:    JKCHKDAT - check input data for correct vars and type
/                   JKXWORDS - count words and create an array of the words.
/                   JKLY0T01 - setup the page layout macro variables.
/                   JKFLSZ2  - Flow text, into 2 dimensional array
/                   JKFLOWX  - Flow text, into 1 dimensional array.
/                   JKHPPCL  - My version of HPPCL, to setup printer.
/                   JKSTPR01 - Process STATS= and STATSFMT=
/                   JKRORD   - Used to order output as specified in ROWS=
/                   JKDASH   - Process dashes in ROWS=
/                   JKRLBL   - Process row labels in ROWS=
/                   JKRFMT   - Process row variable formats in ROWSFMT=
/
/ EXAMPLE CALL:     %DTAB(data=example,
/                      outfile=example,
/                          tmt=NTMT,
/                         rows=SEX AGE WGT HGT ETHORIG);
/
/====================================================================================
/ CHANGE LOG:
/
/    MODIFIED BY: John Henry King
/    DATE:        OCT1997
/    MODID:       JHK001
/    DESCRIPTION: Changes need to make macro conform to IDSG standards
/                 1) changed FOOTDASH default to NO.
/                 2) changed JOBID default to NO.
/                 3) changed PVALUE default to NO.
/                 4) removed _PATNO_ from default addition to ROWS list.
/                 5) changed presendation style of DISCrete variable to make the
/                    first row the n for that variable.
/                 6) removed the dashed line after the titles and before the
/                    column headers.
/    ---------------------------------------------------------------------------
/    MODIFIED BY: Jonathan Fry
/    DATE:        09DEC1998
/    MODID:       JMF002
/    DESCRIPTION: Tested For Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 3.1.
/    ---------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    ---------------------------------------------------------------------------
/==================================================================================*/
/*
/
/ Macro DTAB
/
/ -----------------------------------------------------------------------------
/
/ Example programs located in:
/
/
/ -----------------------------------------------------------------------------
/
/ Use this macro to produce a demographic table, with demographic variables
/ down the left side, SEX, AGE, WEIGHT, HEIGHT and ETHORIG for example.
/ Where a treatment variable forms the columns of the table.  The macro
/ will fit the columns onto the page using as may PANELS, logical pages, as
/ needed to display all the columns.  The table may also include a p-value
/ column for an overall test of the treatments.  If the table needs more than
/ one panel then the p-value column is repeated on each panel.
/
/ -----------------------------------------------------------------------------
/
/ USING VALUE LABELING FORMATS with DTAB.........
/
/ The macro uses value labeling formats provided by the user to label various
/ parts of the table.
/
/ For each ROW variable named in the ROWS= parameter the
/ user would provide labels through a value labeling format name $_VNAME_.
/
/ For example:
/     where ROWS=SEX AGE WEIGHT, you might use.
/ value $_vname_
/    'SEX'     = 'Sex'
/    'AGE'     = 'Age (years)'
/    'WEIGHT'  = 'Weight (pounds)'
/    '_PATNO_' = 'Number of patients';
/
/ The values for _PATNO_ label the patient number row that is automatically
/ created by macro SIMSTAT.
/
/ For each discrete variable the user would need to provide a value labeling
/ format to label the coded values of the discrete variable.
/ For example the if variable SEX has values M and F.
/ The use would then provide a $SEX format.  The user
/ should be carefull to use variable names for discrete variables that can
/ also produce valid format names.  For example format names cannot end with
/ a number.  Also some commonly used variable names like DAY or DATE are
/ format names provided by SAS.  If you try to create a user format with
/ one of these
/ names you will receive an error message, however the macro will still run
/ using the SAS provided format.  This could produce very strange results.
/
/ Using the SEX variable the user would write something like the following.
/ value $sex
/    'M' = 'Male'  'F' = 'Female';
/
/ Note that the macro will print the values of the discrete variables in collating
/ sequence, alphabetical order in most cases.  If you want a different order
/ you will need to recode your discrete variables.  One character discrete
/ variables can easily be recoded with the translate function.  For example
/ to have males printed before females use:
/
/    sex = translate(sex,'12','MF');
/
/ Missing values for discrete variables are counted and given the value underscore "_".
/ If your discrete values contain missing values then you should provide an
/ approiate label, data not available, for example.
/
/
/ The uses must also provide column labels for the columns associated with the
/ levels of the TMT= variable, see TMT= below.  This value labeling format
/ must have the same name as the name of the treatment variable used in the
/ TMT= parameter.  For example.
/
/  value ntmt
/     1 = 'Placebo'
/     2 = 'Ond 25ug bid'
/     3 = 'Ond 1mg bid'
/     4 = 'Ond 4mg bid'
/     5 = 'Diazepam 5mg bid'
/     ;
/
/
/ If the user needs to print more than one p-value through the PVARS=
/ parameter the labels for there columns are given by the $PVARS value labeling
/ format.  For example.
/
/   value $pvars
/     'P1_2' = 'Pla vs 25ug'
/     'P1_3' = 'Pla vs 1mg'
/     'P1_4' = 'Pla vs 4mg'
/     'P1_5' = 'Pla vs Diaz'
/     ;
/
/ -----------------------------------------------------------------------------
/
/ USING TITLES, FOOTNOTES, ENOTES, AND RLABELS with DTAB...........
/
/ TITLES:
/ The user may specify up to 15 titles lines for the table.  These title lines
/ are centered by default.  The user may request that one or more of these
/ lines be right justified, by assigning the title line numbers to HLRIGHT a
/ global macro variable.  The user may also specify which title line will
/ contain the text (Continued), if the table has more than one panel.  See
/ example below and or the example programs referred to above.
/
/
/ FOOTNOTES:
/ Footnote lines are printed and the bottom of the table just below the dashed
/ line drawn after the last ROWS= variable.  Footnote lines that are longer
/ than the linesize are flowed to fit.  You may have up to 15 footnotes.
/
/ ENOTES:
/ End note lines are printed at the bottom of the page, starting at the last line
/ on the page and working upward.  You may have up to 10 end notes.  End notes
/ are truncated to the line size of the table.  Typically end notes are used for
/ the JOBID line.
/
/ RLABELS:
/ Row label lines are used to further annotate the rows.
/
/
/ -----------------------------------------------------------------------------
/
/ Parameter=Default    Description
/ -----------------    --------------------------------------------------------
/
/
/ DATA =               The input data set, this data set must be output from
/                      macro SIMSTAT, or data that has that same structure.
/
/ OUTFILE =            Specifies the name of the file that will receive the
/                      table.  Do NOT include an extension for the file.
/                      The default when OUTFILE is left blank is to use
/                      the named returned by %FN.
/
/ DISP =               Use DISP=MOD to cause DTAB to append its output to the
/                      file named in the OUTFILE= option.  You should not change
/                      the layout of the file that is being appended to.
/
/ TMT =                An INTEGER NUMERIC variable that represents the levels
/                      of treatments.  This is the same variable used in the
/                      TMT= parameter in SIMSTAT.
/
/ TMTFMT =             This parameter is used to specify the format for the treatment
/                      variable named in the TMT= parameter.  When this parameter is
/                      left blank the macro uses a format with the same name as the
/                      TMT= parameter.
/
/ ROWS =               This parameter specifies the names of the variables
/                      that are to be displayed in the rows of the table.
/                      For example for a DEMOGRAPHICS table you might use
/
/                      ROWS = SEX AGE WEIGHT HEIGHT ETHORIG
/
/                      The macro will produce the table with the rows ordered
/                      according to the order they appear in the ROWS =
/                      parameter.
/
/                      The user may also call for dashed lines and extra row
/                      labeling.  Dashed lines between the rows are requested
/                      by placing a dash, or minus sign, "-" in the ROWS=
/                      parameter between the variables names where a dashed line
/                      is desired.
/
/                      The user may also request extra row labels through the
/                      RLABEL global variables.  These lables are positioned by
/                      using a plus sign "+" in the ROWS= parameter where the
/                      row label text is desired.  See the discussion of RLABELS
/                      for more details.
/
/                      Use a data step to delete the observations from the SIMSTAT
/                      data if you do not want DTAB to display the _PATNO_ data.
/
/ ROWSFMT=             Specifies expliciate formats for variables named in the ROWS=
/                      parameter.  The default is to use formats with the same names
/                      as the ROWS= variables.  The option is particularly useful when
/                      the many row variables have the same format.
/
/
/ YNLABEL=NO           This parameter causes DTAB to translate DISCRETE variables
/                      with Y|N as their value to Yes|No, without giving the variables
/                      a format.  This parameter is usefull when DTAB is used to display
/                      many YES|NO variables.
/
/ ROW_OF_N=YES         This parameter causes DTAB to print the N for DISCRETE variables
/                      in a seperate row labeled 'n'.
/
/ STBSTYL=COLUMN       This parameter causes DTAB to print the table stub in a two column
/                      style as opposed to the older one column style.  Use STBSTYL=ROW
/                      to get DTAB to operate in the older column style.
/
/ MISSING=NO           This parameter causes DTAB NOT to display the missing values for
/                      discrete variables.
/
/ BOX = '!'            This parameter specifies a text string that is printed above
/                      the table stub in the row associated with the column labels.
/                      It is somewhat analogus to the BOX= parameter in PROC TABULATE.
/                      Box text is flowed into SWID and can include the new line '\'
/                      character or the HRDSPC character to control spacing.
/
/
/ STYLE = 1            Specifies the style for printing discrete variables
/                      counts and percents.
/
/                      1 = nn (pp)
/                      2 = nn/NN (pp)
/                      3 = nn
/                      4 = nn/NN
/                      0 = no adjustment
/
/                      Normally DTAB tries to center the values under the column
/                      labels.  This is done by calculating the width based on
/                      the STYLE and adding spaces until the values are centered.
/                      Some times this action is not desired.  The user can then
/                      use STYLE=0 to suppress this adjustment.  The user can
/                      then use COFF=(column offset) to adjust the values if
/                      needed.
/
/
/
/ STATS = MEAN STD MIN-MAX N
/
/                      This parameter list the statistics, to print for each
/                      _VTYPE_=CONT variable in the input data.  The order of the
/                      statistic names, specifies the order that the statistics
/                      are printed down the page.  If the user specifies MIN-MAX
/                      the macro prints min and max on the same line with a dash
/                      between them.  If the use specifies MIN space MAX then the
/                      min and max are printed on different lines.
/
/ STATHOLD = 0         Use this yes|no, 0|1 parameter to cause DTAB print a
/                      statistic on the same line as the variable that it is
/                      associated with.  You should only use this parameter when
/                      ONE statistic is requested.
/
/ STATSFMT =           This parameter is used to associate formats to the statistics
/                      named in the STATS= parameter. The format for this parameter is
/
/                      var_name(stats_list format_specification ...) ...
/
/                      where:
/                        var_name is a continuous variable named in ROWS=
/                        stats_list is a list of statistics to be printed, MEAN STD etc.
/                        format_specification if a SAS format say F6.2 perhaps.
/
/                      The list can be repeated for each continuous variable.  And the
/                      special name _ALL_ can be used to effect all continuous variables.
/
/                      Example:
/
/                         ROWS=AGE RACE SEX WT HT BSA BDMSIX,
/                         STATSFMT=wt(min max 5.1 mean median std 6.2)
/                                 bsa(min max 6.2 mean median std 7.3)
/                              bdmsix(min max 5.1 mean median std 6.2),
/
/
/ JOBID = NO           Use this parameter to control the dispay of source program
/                      tracking information.  The default is to display the JOBID
/                      data as an ENOTE.
/
/ SKIP = 0             Use this parameter to put blank lines between the values of
/                      _LEVEL_s for discrete variables.
/
/ VSKIP = 0            Controls the number of blank lines that appear between the last line
/                      of the label text associated with a variable and the statistics
/                      that are printed for that variable.
/
/ VSKIPA = 1           Controls the number of blank lines that appear after the statistics
/                      for a variable and before the label text for the next variable.
/
/ INDENT = 2           Use this parameter to indent the formatted values of discrete
/                      variables.
/
/ INDENTC = 2          This is the number of columns that the statistics labels for
/                      continious variables are indented.
/
/ INDENTF = 4          This parameter controls the number of columns that a continued
/                      footnote line is indented.  The footnotes are flowed into the
/                      linesize with the first line left justified and subsequent lines
/                      indented the number of columns specified by this parameter.
/
/                      Footnote lines may also have individual indenting controled by
/                      the FINDTn macro variables.  For example:
/
/                      %let fnote2 = this is the footnote.
/                      %let findt2 = 6;
/
/                      In this example if footnote 2 was flowed onto a second then that
/                      second line would be indented 6 spaces.
/
/ INDENTV = 0          Use this parameter to indent the formatted values of the
/                      values of _VNAME_.
/
/ INDENTVC = 0         Use this parameter to control the number of columns that
/                      the 2nd, 3rd, ... flowed values of the formatted values
/                      of the _VNAME_ variable are indented.
/
/ INDENTLC = 1         Use this parameter to control the number of columns that
/                      the 2nd, 3rd, ... flowed value of _LEVEL_ variables are
/                      indented when FLOW=_LEVEL_.
/
/ HRDSPC = !           This is the hard space parameter.  A hard or significant space
/                      is a space that holds it significance even when to text is flowed
/                      or justified, right, left, centered.  You can use the hardspace
/                      in titles, footnotes, formats associated with _VNAME_ and _LEVEL_
/                      values, and rlabels.
/
/ FLOW =               This parameter can be used to have the macro flow the
/                      text associated with the formated values of _LEVEL_ for
/                      discrete variables.  The user would specify FLOW=_LEVEL_.
/                      Use flow when the formated values of the _LEVEL_ values
/                      associated with a discrete variable are longer than the
/                      values specified by SWID.  This parameter can also be used
/                      to have the macro flow the text associated with RLABELs.
/                      The user could have the text associated with RLABEL2 flowed
/                      into the linesize of the table with FLOW=RLABEL2.
/                      The user can have the text split at a specific place by
/                      placing a backslash character at the point where the
/                      split is desired.
/
/
/ IFMT = 3.            Specifies the format for printing integer variables.
/                      Counts and totals.
/
/ RTMT = 5.1           Specifies the format for printing continious variables, if
/                      no format is specified on the STATS= parameter.
/
/ PCTFMT = JKPCT5.     Specifies the format for printing percents associated
/                      with discrete variables.  The default JKPCT5.
/
/ PCTSTYLE = 1         This parameter is used to modify the way percents are
/                      rounded when being print with the JKPCTn. format.
/
/                      PCTSTYLE=1 rounds and prints as follows.
/
/
/                             values
/                      ------------------------
/                      internal       formated
/
/                       >0 to <1        (<1)
/                        1 to 99        (pp)   rounded to integer
/                      >99 to <100     (>99)
/                         100          (100)
/                           0          blank
/                        missing       blank
/
/                      While PCTSTYLE=2 rounds and prints as follows.
/
/                             values
/                      ------------------------
/                      internal       formated
/
/                       >0.5 to <1        (<1)
/                        1 to 99.5        (pp)   rounded to integer
/                      >99.5 to <100     (>99)
/                           100          (100)
/                             0          blank
/                          missing       blank
/
/
/
/ PCTSIGN = NO         This parameter controls the inclusion of a percent sign in
/                      printing of percents
/
/ PVALUE = NO          Print p-value on the table?
/
/ PVARS  = PROB        A list of p-values to print at the right side of the table.
/                      This can be useful for printing pairwise p-values on a table.
/                      This list of p-values appears in ALL panels.
/
/ CPVARS1 =            Use CPVARS to specify extra PVARS like data that is printed
/ CPVARS2 =            below the PVARS rows.  These variable must be character.
/ CPVARS3 =            Currently CPVARSn are printed with a $char format equal to
/ CPVARS4 =            value of PWID=.
/ CPVARS5 =
/
/ PLABEL = 'p-value [1]'
/                      Plabel specifies the label for the p-value column.
/                      This is used when there is only one p-value.  If pairwise
/                      p-values are displayed then the user should supply a
/                      values labeling format $PVARS to label the p-value columns.
/
/
/ PFLAG = 0            Use the PFLAG parameter have DTAB label a p-value with
/                      and asterick when the CONTROLling variable is less than
/                      the value specified in PLEVEL.
/
/ PLEVEL = .05         The plevel parameter determines the level of significance
/                      for the controlling variable p-value to flag a treatment
/                      pvalue.
/
/
/ LAYOUT = PORT        This is the arrangement of the table on the printed
/                      page.  This parameter works the same as in the HPPCL
/                      macro developed by J.COMER.
/
/ CPI = 17             The number of characters per inch on the printed page.
/                      Possible values are 12 and 17.
/
/ LPI = 8              The number of lines per inch. Possible values are
/                      6, 8, and 10.
/
/ SWID = 20            The width of the table STUB, in number of characters.
/                      The part of the table that identifies the table rows.
/
/ RLWID=SWID           This parameter defines the width of flowed rlabel text.
/                      The default RLWID=SWID uses the same value specified by
/                      the SWID parameter.  Otherwise the value can be a positive
/                      integer less that or equal to the linesize for the table.
/                      RLWID=LS can be used to have the macro use the current
/                      linesize for the table as the value of RLWID.
/
/ RLOCATE=LAST         This parameter is used tell the macro where to place
/                      RLABEL text.  The default is to print the RLABEL text
/                      after printing the variable it is assocated.  RLOCATE=FIRST
/                      prints the RLABEL text before the variable.
/
/ CWID = 10            The number characters to allow for each treatment
/                      column in the table.
/
/ COFF =               Use this parameter to override the column offset that is
/                      calculated based on the value of the STYLE= parameter.
/                      Valid values are positive intergers less than CWID.
/
/ PWID = 8             The number of characters to allow for each P-value
/                      column.
/
/ PCOFF =              This parameter controls the number spaces printed to the
/                      left of the PVAR and CPVARSn parameters.  This parameter
/                      is especially useful when CPVARSn is specified.
/
/ BETWEEN = 0          The number of characters to place between each column.
/                      When this parameter is 0 then the columns are spaced
/                      to fill out the linesize of the table.
/
/ SBETWEEN = 2         The number of spaces between the table stub and the first
/                      treatment column.
/
/ PBETWEEN = 3         The number of spaces between the last treatment column and the first
/                      p-value column.
/
/ BETWEENP = 2         Specifies the number of spaces to put between the p-value columns.
/
/ SMIN = 20            Minimum values for each of the column width parameters
/ CMIN = 8
/ PMIN = 6
/
/ PAGENUM =            The PAGENUM=PAGEOF option allows the output from DTAB to
/                      be numbered in the style "Page n of p".  Currently this text
/                      is displayed only on the JOBID line that is printed by DTAB.
/                      If you use the DISP=MOD option in your DTAB then you should
/                      request PAGENUM=PAGEOF on the LAST call to DTAB only.
/                      When DTAB is running with DISP=DISP a cumulative total of
/                      pages and kept so that the pages can be number inclusively.
/
/ TARGET=              This option is used in association with the PAGENUM= option.
/                      TARGET= specifies a character string that will be searched
/                      for when the macro is numbering pages.  The target is used
/                      to locate the "Page n of p" text.  The default value for
/                      target is the value of OUTFILE=.
/
/ CONTMSG = NO         The contmsg parameter is used to cause DTAB to write a continued
/                      message in the footnote area.  This is useful when you are
/                      producing a table with more than one page, using two or more
/                      calls to DTAB.
/
/ FOOTDASH = NO        This parameter turns on and off the dashed line that is
/                      drawn before the footnotes are produced.
/
/-------------------------------------------------------------------------------------------------
/ EXAMPLE:
/
/ The following is an example program and output from macro DTAB.  This example uses
/ a dataset produced by macro SIMSTAT.
/
/ proc format;
/    value ntmt
/       1 = 'Placebo'
/       2 = 'Ond 25ug bid'
/       3 = 'Ond 1mg bid'
/       4 = 'Ond 4mg bid'
/       5 = 'Diazepam 5mg bid'
/       ;
/    value $ethorig
/       'A','4' = 'Asian'
/       'C','1' = 'Caucasian'
/       'H','5' = 'Hispanic'
/       'M','7' = 'Mongoloid'
/       'N','2' = 'Negroid/Black'
/       'O','6' = 'Other'
/       'U','8' = 'Unanswered'
/       'Z','3' = 'Oriental'
/       '_'     = 'Data not available';
/       ;
/    value $sex
/       'F' = '  Female'
/       'M' = '  Male'
/       '_' = '  Data not available'
/       ;
/    value $_vname_
/       '_PATNO_' = 'Number of patients who received at least one dose of the study drug'
/       'SEX'     = 'Sex, n(%)'
/       'AGE'     = 'Age (y)'
/       'WGT'     = 'Weight (lb)'
/       'HGT'     = 'Height (in)'
/       'ETHORIG' = 'Ethnic origin, n(%)'
/       ;
/    run;
/
/
/ %let  hlright = 1 2 3;
/ %let  hlcont  = 4;
/
/ %let  hl0 = 6;
/ %let  hl1 = Drug: Ondansetron;
/ %let  hl2 = Protocol: S3A210;
/ %let  hl3 = Population: Safety;
/ %let  hl4 = TABLE 4;
/ %let  hl5 = Demography;
/ %let  hl6 = Number (%) of Patients and Summary Statistics;
/
/ %let fnote0=2;
/ %let fnote1=The p-values for sex and ethnic origin based on the chi-square test and for
/ age, height, and weight on the vanElteren test.;
/ %let fnote2=This table produced with macro SIMSTAT and DTAB.;
/
/ %let enote0=3;
/ %let enote1=Supporting data listing in Appendix DL-xx, Vol ___, Page ___;
/ %let enote3=%quote(&jobid);
/
/
/ %DTAB(data=example,
/      outfile=example,
/         tmt=NTMT,
/        rows=SEX AGE WGT HGT ETHORIG)
/
/
/-------------------------------------------------------------------------------------------------
/-------------------------------------------------------------------------------------------------

                                                                                 Drug: Ondansetron
                                                                                  Protocol: S3A210
                                                                                Population: Safety
                                             TABLE 4
                                            Demography
                          Number (%) of Patients and Summary Statistics
--------------------------------------------------------------------------------------------------

                                       Ond 25ug     Ond 1mg      Ond 4mg      Diazepam    p-value
                          Placebo        bid          bid          bid        5mg bid       [1]
--------------------------------------------------------------------------------------------------

Number of patients
 who received at
 least one dose of
 the study drug            98           92           97           97           92
--------------------------------------------------------------------------------------------------

Sex, n(%)                                                                                   0.606
  Female                   45 (46)      34 (37)      46 (47)      43 (44)      43 (47)
  Male                     53 (54)      58 (63)      51 (53)      54 (56)      49 (53)

Age (y)                                                                                     0.790
  Mean                     41.4         41.8         43.5         42.4         41.8
  sd                       10.68        10.54        12.22        12.99        11.59
  Min-Max                  21-71        21-68        19-68        21-73        19-69
  n                        98           92           97           97           92

Weight (lb)                                                                                 0.892
  Mean                    172.6        173.2        170.9        168.7        171.0
  sd                       35.49        35.21        33.64        35.54        38.41
  Min-Max                 108-297      110-292      107-268       98-264       96-333
  n                        97           92           95           96           92

Height (in)                                                                                 0.462
  Mean                     67.3         67.8         67.4         67.0         67.8
  sd                        4.00         4.17         3.30         3.60         4.22
  Min-Max                  58-76        59-81        58-75        60-74        57-74
  n                        98           92           97           96           92

Ethnic origin, n(%)                                                                         0.804
Caucasian                  80 (82)      76 (84)      84 (87)      87 (90)      77 (84)
Negroid/Black               9  (9)       8  (9)       8  (8)       5  (5)      10 (11)
Oriental                    0            0            1  (1)       0            0
Asian                       0            1  (1)       1  (1)       2  (2)       0
Hispanic                    6  (6)       4  (4)       2  (2)       2  (2)       3  (3)
Other                       3  (3)       2  (2)       1  (1)       1  (1)       2  (2)
Data not available          0            1            0            0            0

--------------------------------------------------------------------------------------------------
The p-values for sex and ethnic origin based on the chi-square test and for age, height, and
     weight on the vanElteren test.
This table produced with macro SIMSTAT and DTAB.






Supporting data listing in Appendix DL-xx, Vol ___, Page ___

D:\STDMACRO\JHK27056\DT00.SAS  22DEC93:10:13:48

/ End of example:
/------------------------------------------------------------------------------*/

%macro dtab(  data=,
           outfile=,
              disp=,

               tmt=,
            tmtfmt=,

              rows=,
           rowsfmt=,

           ynlabel=NO,
          row_of_n=YES,
           stbstyl=COLUMN,
           missing=NO,

              ifmt=3.,
              rfmt=5.1,
            pctfmt=jkpct5.,
          pctstyle=1,
           pctsign=YES,
              flow=,
             style=1,
             stats=n mean std median min max,
          stathold=0,
          statsfmt=,
            pvalue=NO,
             pvars=,
           pvalfmt=,
             pflag=0,
            plevel=.05,
            pvcomp=_pvars[i],
            pfltxt='#',
            plabel='p-value [1]',

           cpvars1=,
           cpvars2=,
           cpvars3=,
           cpvars4=,
           cpvars5=,
               box='!',
              skip=0,
             vskip=0,
            vskipa=1,
            indent=,
           indentc=,
           indentf=4,
           indentv=0,
          indentvc=0,
          indentlc=1,
            hrdspc=!,
              swid=,
             rlwid=swid,
           rlocate=LAST,
              smin=8,
              cwid=10,
              cmin=8,
              pwid=8,
              pmin=6,
              coff=,
             pcoff=,
           between=0,
          sbetween=2,
          pbetween=3,
          betweenp=2,
            layout=DEFAULT,
               cpi=17,
               lpi=10,
          footdash=NO,
           contmsg=NO,
             jobid=NO,
             ruler=NO,

           pagenum=NONE,
            target=,
             debug=0,
           sasopts=NOSYMBOLGEN NOMLOGIC);

   /*
   / Issue SAS system options specified in the SASOPTS parameter
   /-------------------------------------------------------------------------*/

   options &SASOPTS;

   /*
   / JMF002
   / Display Macro Name and Version Number in LOG
   /-------------------------------------------------------------------------*/

      %put ------------------------------------------------------;
      %put NOTE: Macro called: DTAB.SAS       Version Number: 3.1;
      %put ------------------------------------------------------;


   /*
   / If DATA= was not specified then use _LAST_
   /-------------------------------------------------------------------------*/

   %if &sysscp=VMS %then %do;
      options cc=cr;
      %end;

   %global vdtab vsimstat jkpg0;
   %let    vdtab = 3.1;



   %let data = %upcase(&data);
   %if &data=_LAST_ | %length(&data)=0 %then %let &data=&syslast;
   %if &data=_NULL_ %then %do;
      %put ER!ROR: There is no data to be processed;
      %goto EXIT;
      %end;


   /*
   / Run the check data utility macro CHKDATA to verify the existance
   / of the input data and variable names.
   /-------------------------------------------------------------------------*/

   %jkchkdat(data=&data,
            nvars=&tmt,
            cvars=_vname_ _vtype_)

   %if &RC %then %goto EXIT;



   /*
   / Set up local macro variables to hold temporary data set names.
   /-----------------------------------------------------------------*/

   %local i temp0 temp1 constant temp3 temp4 temp5;
   %let temp0    = _0_&sysindex;
   %let temp1    = _1_&sysindex;
   %let constant = _2_&sysindex;
   %let temp3    = _3_&sysindex;
   %let temp4    = _4_&sysindex;
   %let temp5    = _5_&sysindex;

   /*
   / Upper case various input parameters as needed.
   /-------------------------------------------------------------------------*/

   %let row_of_n = %upcase(&row_of_n);
   %let stbstyl  = %upcase(&stbstyl);
   %let missing  = %upcase(&missing);
   %let ynlabel  = %upcase(&ynlabel);
   %let pvalue   = %upcase(&pvalue);
   %let layout   = %upcase(&layout);
   %let rows     = %upcase(&rows);
   %let pctfmt   = %upcase(&pctfmt);
   %let pctsign  = %upcase(&pctsign);
   %let style    = %upcase(&style);
   %let flow     = %upcase(&flow);
   %let ruler    = %upcase(&ruler);
   %let footdash = %upcase(&footdash);
   %let contmsg  = %upcase(&contmsg);
   %let stats    = %upcase(&stats);
   %let stathold = %upcase(&stathold);
   %let statsfmt = %upcase(&statsfmt);
   %let jobid    = %upcase(&jobid);
   %let disp     = %upcase(&disp);
   %let pagenum  = %upcase(&pagenum);
   %let rlwid    = %upcase(&rlwid);
   %let rlocate  = %upcase(&rlocate);
   %let pflag    = %upcase(&pflag);


   /*
   / Assign default value to OUTFILE and create GLOBAL macro variable
   / to use in INFILE= parameter in MACAPGE.
   /-------------------------------------------------------------------*/
   %global _outfile;

   %if %bquote(&outfile)=
      %then %let outfile = %fn;

   %put NOTE: outfile = &outfile;

   %if %bquote(&row_of_n)=YES | %bquote(&row_of_n)=1
      %then %let row_of_n = 1;
      %else %let row_of_n = 0;

   %if %bquote(&missing)=YES  | %bquote(&missing)=1
      %then %let missing = 1;
      %else %let missing = 0;

   %if %bquote(&ynlabel)=YES | %bquote(&ynlabel)=1
      %then %let ynlabel = 1;
      %else %let ynlabel = 0;


   %if %bquote(&tmtfmt)= %then %do;
      %let tmtfmt = &tmt%str(.);
      %end;



   /*
   / Set up for IDSG column style.
   /--------------------------------------------------*/

   %if %bquote(&stbstyl)=COLUMN %then %do;
      %if %bquote(&swid)=    %then %let swid    = 50;
      %if %bquote(&indent)=  %then %let indent  = 30;
      %if %bquote(&indentc)= %then %let indentc = 30;
      %end;
   %else %do;
      %if %bquote(&swid)=    %then %let swid    = 20;
      %if %bquote(&indent)=  %then %let indent  = 3;
      %if %bquote(&indentc)= %then %let indentc = 3;
      %end;

   %if "&debug"="YES" | "&debug"="1"
      %then %let debug=1;
      %else %let debug=0;

   %if "&stathold"="YES" | "&stathold"="1"
      %then %let stathold=1;
      %else %let stathold=0;

   %if "&pvalue"="YES"
      %then %let pvalue=1;
      %else %let pvalue=0;

   %if "&ruler"="YES"
      %then %let ruler=1;
      %else %let ruler=0;

   %if "&jobid"="YES"
      %then %let jobid=1;
      %else %let jobid=0;

   %if %length(&target)=0
      %then %let target = "&outfile";
      %else %let target = "&target";

   %if %length(&pflag)=0
      %then %let pflag=0;

   %if "&pflag"="YES" | "&pflag"="1"
      %then %let pflag = 1;
      %else %let pflag = 0;

   %if %length(&plevel)=0
      %then %let plevel=.05;

   %if "&rlocate"^="FIRST" %then %let rlocate = LAST;


   %if "&disp"^="MOD" %then %do;
      %let disp=;
      %let jkpg0 = 0;
      %end;

   %if "&pctsign"="YES" %then %do;
      %let pctsign = %str(%%);
      %if "&pctfmt"="JKPCT5." %then %let pctfmt = JKPCT6.;
      %end;
   %else %let pctsign = ;

   %if ^("&pctstyle"="1" | "&pctstyle"="2") %then %let pctstyle=1;

   %put NOTE: PCTSIGN=&pctsign, PCTFMT=&pctfmt, PCTSTYLE=&pctstyle;


   /*
   / Prepare the STATS= parameter for use in the final data step
   /-----------------------------------------------------------------*/

   %jkstpr01(stats=&stats,
          statsfmt=&statsfmt,
                at=@(_tc[ncol]) +(coff) )


   /*
   / Global all the macro variables supplied by the user outside
   / the macro.  This insures that these variables are all defined
   / even if the user does not supply them all.
   /-----------------------------------------------------------------*/

   %global hl0 hl1 hl2 hl3 hl4 hl5 hl6 hl7 hl8 hl9 hl10
           hl11 hl12 hl13 hl14 hl15;

   %global hlright hlleft hlcont;

   %global fnote0  fnote1  fnote2  fnote3  fnote4  fnote5
           fnote6  fnote7  fnote8  fnote9  fnote10 fnote11
           fnote12 fnote13 fnote14 fnote15
           fnote16 fnote17 fnote18 fnote19 fnote20;


   %global findt0  findt1  findt2  findt3  findt4  findt5
           findt6  findt7  findt8  findt9  findt10 findt11
           findt12 findt13 findt14 findt15
           findt16 findt17 findt18 findt19 findt20;

   %global enote0 enote1 enote2 enote3 enote4 enote5
                  enote6 enote7 enote8 enote9 enote10;

   %if "&enote0"="" %then %let enote0 = 0;
   %if "&fnote0"="" %then %let fnote0 = 0;


   /*
   / Process Pvars;
   / I have added (22FEB96) the option for aditional varaiables to
   / be displayed in the PVAR area.  These CPVARSn are character
   / variables that are in multiple rows.  I am adding this and
   / trying to keep the functionality that exist in DTAB.
   / This action has caused this portion of code to become more
   / obscure than before, so I will try to document in more detail.
   /----------------------------------------------------------------*/

   %let  pvars  = %upcase(&pvars);
   %let cpvars1 = %upcase(&cpvars1);
   %let cpvars2 = %upcase(&cpvars2);
   %let cpvars3 = %upcase(&cpvars3);
   %let cpvars4 = %upcase(&cpvars4);
   %let cpvars5 = %upcase(&cpvars5);

   %local cpvars0;
   %let cpvars0 = 0;
   %do i = 1 %to 5;
      %if "&&cpvars&i" ^= "" %then %let cpvars0 = %eval(&cpvars0 + 1);
      %end;

   %put NOTE: There are &cpvars0 CPVARS lines to be printed.;

   %local pvarflag;
   %let   pvarflag = 1;

   /*
   / If the user specifies only CPVARS then assign the value of CPVARS1
   / to PVARS so that the label routine will work and generate labels
   / for the PVAR columns in the table.
   /-------------------------------------------------------------------*/
   %if       "&cpvars1"^="" & "&pvars"="" %then %do;
      %let pvars    = &cpvars1;
      %let pvarflag = 0;
      %end;
   %else %if &pvalue & "&pvars"=""        %then %do;
      %let pvars    = PROB;
      %let pvarflag = 1;
      %end;

   %local p_var0;

   %if ^&pvalue
      %then %let p_var0 = 0;
      %else %let p_var0 = %jkxwords(list=&pvars,root=p_var);


   /*
   / Declare some macro variables
   /
   / COLS    The maximum number of columns in the panels.
   /-----------------------------------------------------------------*/

   %local cols colsplus maxwid;

   /*
   / Set up flags to use to control printing of the appendix note,
   / the jobname information, and the table continued notes.
   /-----------------------------------------------------------------*/

   %local cont;

   %if    "&hl0"="" %then %let    hl0=10;

   %if "&hlcont"="" %then %do;
      %let cont   = 0;
      %let hlcont = 1;
      %end;
   %else %let cont=1;

   %local ls ps dashchr file_ext file_dsp hppcl;

   %jklyot01

   %put NOTE: LS=&ls PS=&ps DASHCHR=&dashchr FILE_EXT=&file_ext;

   %local jkrlwid;
   %if "&rlwid"="LS" | "&rlwid"="SWID"
      %then %let jkrlwid = &&&rlwid;
      %else %let jkrlwid = &rlwid;


   /*
   / Compute PANELS based on the number of treatments, the presence
   / of p-values and the width of the various column components of the
   / table.
   /--------------------------------------------------------------------------*/


   options nofmterr;

   /*
   / Create new LEVEL for DISC variable that for N row.
   /-------------------------------------------------------*/

   %if &row_of_n %then %do;
      data &temp0;
         set
            &data
               (
                %if ^&missing %then %do;
                  where = (_level_^='_')
                  %end;
               )
            ;



         by _vname_ _level_;

         output;

         retain _flag_ 0;

         if first._vname_ & first._level_ & _vtype_='DISC' then _flag_ = 1;

         if _flag_ then do;
            _level_ = '01'x;
            count   = n;
            n       = .;
            pct     = .;
            output;
            end;

         if _flag_ & last._level_ then _flag_ = 0;

         run;

      %let data = &temp0;
      %end;

   proc summary data=&data nway missing;
      class &tmt;
      output out=&temp1(drop=_type_ _freq_);
      run;


   %local cantdoit;
   %let cantdoit = 0;

   /*
   / This data set will contain various column location constants.  This data
   / will be SET into the FILE PRINT data step below.
   /--------------------------------------------------------------------------*/
   data &constant;

      if 0 then set &temp1(drop=_all_) nobs=nobs;

      retain style "&style" pvalue &pvalue p_var0 &p_var0;

      drop i;

      p_var0 = max(p_var0,0);

      skip     = max(0,&skip     + 0);
      vskip    = max(0,&vskip    + 0);
      vskipa   = max(0,&vskipa   + 0);
      indent   = max(0,&indent   + 0);
      indentc  = max(0,&indentc  + 0);
      indentv  = max(0,&indentv  + 0);
      indentvc = max(0,&indentvc + 0);
      indentlc = max(0,&indentlc + 0);

      tmt0 = nobs;

      iwid = int(&ifmt);
      rwid = int(&rfmt);

      pctwid = int(input(compress("&pctfmt",'_ABCDEFGHIJKLMNOPQRSTUVWXYZ'),8.));

      /*
      / Compute CCWID the width taken up by the contents of the columns.
      /----------------------------------------------------------------------*/

      select(style);
         when('0') ccwid = &cwid;
         when('1') ccwid = iwid + pctwid;
         when('2') ccwid = 1 + iwid * 2 + pctwid;
         when('3') ccwid = iwid;
         when('4') ccwid = 1 + iwid * 2;
         otherwise do;
            ccwid = iwid + pctwid;
            call symput('STYLE','1');
            style = '1';
            end;
         end;


      swid     = max(&swid,&smin);

      cwid     = max(&cwid,ccwid,&cmin);

      pwid     = max(&pwid,&pmin);

      btwn     = max(&between,1);

      between  = &between;
      pbetween = max(&pbetween,1);
      sbetween = max(&sbetween,0);
      betweenp = max(&betweenp,1);

      ls       = &ls;

      /*
      / Compute SPWID the total number of columns occupied by the table stub
      / and p-values if requested by the user.
      /-------------------------------------------------------------------------*/
      spwid = swid + sbetween;

      if pvalue then spwid = spwid + ((pwid*p_var0)+(betweenp*(p_var0-1))+pbetween);

      /*
      / Now see how many TREATMENT columns will fit in the space left after
      / the stub and p-values.
      /-------------------------------------------------------------------------*/

      req = spwid;

      do tcols = 1 to tmt0;

         req = req + (cwid + btwn);

         if req > &ls then leave;

         end;


      /*
      / Tcols is the number of TREATMENT columns that will fit in 1 panel
      /-----------------------------------------------------------------------*/
      tcols = tcols - 1;

      if tcols=0 then do;
         call symput('CANTDOIT','1');
         stop;
         end;

      cols    = tcols + p_var0;

      /*
      / COFF is the column ofset for the statistics printed in a treatment
      / column.  This centers the statistics under the column heading.
      / PCOFF is similar to COFF but is for the p-value column.
      /-----------------------------------------------------------------------*/

   %if "&coff"= "" %then %do;
      coff  = max(floor((cwid-ccwid) / 2),0);
      %end;
   %else %do;
      coff  = &coff;
      %end;

   %if "&pcoff"="" %then %do;
      pcoff = max(floor((pwid-6) / 2),0);
      %end;
   %else %do;
      pcoff = &pcoff;
      %end;


      /*
      / When no between value is specified, BETWEEN=0, the macro computes
      / between to space the columns so that they fill up the available space.
      /-----------------------------------------------------------------------*/


      if between = 0 then do;

         between = floor( (ls - spwid - tcols*cwid) / max(tcols-1,1) );

         xxx     = between;

         between = between - floor(between / tcols);

         between = max(between,1);

         end;


      /*
      / The array _TC will hold the column locations for each treatment column
      / and the p-value column.
      / The array _TW hold the width of each of these columns.  This is used by
      / the flow macro JKFLSZ2 to vary the size of the columns of flowed text.
      /-----------------------------------------------------------------------*/
      array _tc[40];
      array _tw[40];

      tmtreq = (tcols * cwid)  + (between * (tcols-1));
      prbreq = (p_var0 * pwid) + (betweenp * (p_var0-1));

      _tc[1] = 1 + swid + sbetween;
      _tw[1] = cwid;

      do i = 2 to tcols;
         _tc[i] = _tc[i-1] + cwid + between;
         _tw[i] = cwid;
         end;


      do i = tcols+1 to cols;
         if i = tcols+1
            then _tc[i] = _tc[i-1] + _tw[i-1] + pbetween;
            else _tc[i] = _tc[i-1] + pwid     + betweenp;
         _tw[i] = pwid;
         end;

      /*
      / Create macro variable to hold COLS the number of columns, to use
      / in array declareations.
      /-----------------------------------------------------------------------*/

      call symput('COLS',    trim(left(put(cols,8.))));
      call symput('COLSPLUS',trim(left(put(1+cols,8.))));
      call symput('CWID',    trim(left(put(cwid,8.))));
      call symput('PWID',    trim(left(put(pwid,8.))));
      call symput('MAXWID',  trim(left(put(max(cwid,pwid,swid),8.))));
      output;
      stop;
      run;

   %if &cantdoit %then %do;
      %put ER!ROR: Your choices of    STUB: SWID=&swid, SBETWEEN=&sbetween;
      %put ER!ROR:              TX COLUMNS: CWID=&cwid, BETWEEN=&between;
      %put ER!ROR            P-VAL COLUMNS: PWID=&pwid, PBETWEEN=&pbetween, BETWEENP=&betweenp;
      %put ER!ROR: will not allow the display of any treatment columns.;
      %put ER!ROR: Please choose smaller values for one or more of these parameters and resubmit.;
      %goto exit;
      %end;

   %if &debug %then %do;
      title4 'DATA=CONSTANT';
      proc print data=&constant;
         run;
      %end;


   /*
   / Using the data set of treatment values divide the treatments into panels
   / using TCOLS from above.  This data will be merged with the input data
   / below.
   /--------------------------------------------------------------------------*/

   data &temp1;
      set &temp1;
      if _n_ = 1 then set &constant(keep=tcols);
      drop tcols;
      retain panel 0;
      if                tcols  = 1 then panel = panel + 1;
      else if mod(_n_ , tcols) = 1 then panel = panel + 1;
      run;

   %if &debug %then %do;
      title4 'DATA=TEMP1';
      proc print data=&temp1;
         run;
      %end;


   /*
   / Now using the treatment data set that has been divided up into panels
   / flow the column header text into the space provided by the column width
   / array.
   /--------------------------------------------------------------------------*/

   proc summary data=&temp1 nway missing;
      class panel &tmt;
      output out=&temp3(drop=_type_ _freq_);
      run;

   proc transpose data=&temp3 out=&temp3 prefix=tc;
      by panel;
      var &tmt;
      run;

   /*
   / create value label format with _PATNO_ information
   /-------------------------------------------------------*/
   data _for;
      set
         &data
            (
             keep = _vname_ &tmt n
            )
         ;

      if _vname_ = '_PATNO_';

      fmtname  = 'tmtnnn';
      start    = &tmt;
      length label $40;
      label    = compress('(N='||put(n,8.)||')');
      run;
   proc format cntlin=_for;
      run;

   data &temp3(keep=panel _cl:);

      set &temp3;
      by panel;

      array _tc[*] tc:;

      if _n_ = 1 then set &constant(keep=_tw1-_tw&cols tcols swid);
      array _tw[&colsplus] _tw1-_tw&cols swid;

      array _tl[&colsplus] $200;

      /*
      / Assign TL[cols+1] the value of the BOX parameter
      /-----------------------------------------------------------------*/

      _tl[&colsplus] = &box;
      if _tl[&colsplus] = ' ' then _tl[&colsplus] = '!';

      /*
      / Create the format labels using the TMT format
      /------------------------------------------------*/

      ntmts = n(of _tc[*]);

      do i = 1 to dim(_tc);
         if _tc[i] <= .Z then continue;
         _tl[i] = put(_tc[i],%unquote(&tmtfmt))||' \ '||put(_tc[i],tmtnnn.);
         if &ruler then _tl[i] = trim(_tl[i])||' '|| substr('....+....+....+....+',1,&cwid);
         end;

      %if &pvalue %then %do;
         j = 0;
         if &p_var0=1 & "&p_var1"='PROB' then do;
            _tl[&cols]= &plabel;
            if &ruler  then _tl[&cols]= trim(_tl[&cols])||' '||substr('....+....+....+....+',1,&pwid);
            end;
         else do i = tcols+1 to &cols;
            j = j + 1;
            VAR = SYMGET('P_VAR'||left(put(j,4.)));
            _tl[i] = put(var,$pvars.);
            if &ruler then _tl[i]= trim(_tl[i])||' '||substr('....+....+....+....+',1,&pwid);
            end;
         %end;

      /*
      / flow the labels into the columns based on the column
      / width. CWID may be different for treatments and
      / p-values.
      /------------------------------------------------------*/

      %jkflsz2(in = _tl,
              out = _xl,
             size = &maxwid,
           sizeAR = _tw,
             dim1 = &colsplus,
             dim2 = 10,
          newline = '\');


      /*
      / Move the labels down so that they will look pushed up
      / rather that hung down.
      /------------------------------------------------------*/
      array   _cl[&colsplus,10] $&maxwid;
      array _cl0_[&colsplus];

      _cl0 = _xl0;
      max = max(of _xl0_[*],0);

      do i = 1 to _cl0;
         _cl0_[i] = max;
         offset = max - _xl0_[i];
         do k = 1 to _xl0_[i];
            _cl[i,k+offset] = _xl[i,k];
            end;
         end;
      run;

   %if &debug %then %do;
      title4 "DATA=TEMP3 the formatted column labels";
      proc contents data=&temp3;
         run;
      proc print data=&temp3;
         run;
      title4;
      %end;


   /*
   / Flow the footnote data so that the footnotes will fit in
   / the linesize chosen for the table.
   /---------------------------------------------------------*/

   data &temp5(keep=_fn: _en: _fi:);
      array _xn[20] $200 _temporary_
         ("&fnote1",  "&fnote2",  "&fnote3",  "&fnote4",  "&fnote5",
          "&fnote6",  "&fnote7",  "&fnote8",  "&fnote9",  "&fnote10",
          "&fnote11", "&fnote12", "&fnote13", "&fnote14", "&fnote15",
          "&fnote16", "&fnote17", "&fnote18", "&fnote19", "&fnote20");

      array _xi[20] $2 _temporary_
         ("&findt1",  "&findt2",  "&findt3",  "&findt4",  "&findt5",
          "&findt6",  "&findt7",  "&findt8",  "&findt9",  "&findt10",
          "&findt11", "&findt12", "&findt13", "&findt14", "&findt15",
          "&findt16", "&findt17", "&findt18", "&findt19", "&findt20");

      array _fi[20];
      array _sz[20];

      do i = 1 to dim(_xi);
         if _xi[i]=' '
            then _fi[i] = max(&indentf,0);
            else _fi[i] = input(_xi[i],2.);
         _sz[i] = &ls - _fi[i];
         end;


      do i = 1 to dim(_xn);
         _xn[i] = compbl(_xn[i]);
         end;


      %jkflsz2(in=_xn,out=_fn,size=&ls,sizear=_sz,dim1=20,dim2=5,newline='\')

      do i = 1 to dim1(_fn);
         do j = 1 to dim2(_fn);
            _fn[i,j] = translate(_fn[i,j],' ',"&hrdspc");
            end;
         end;


      _en0 = min(&enote0 + &jobid, 10);

      array _en[10] $200
         ("&enote1","&enote2","&enote3","&enote4","&enote5",
          "&enote6","&enote7","&enote8","&enote9","&enote10");


   %if &jobid %then %do;
      %if &sysscp = SUN 4 %then %do;
         set
            sashelp.vextfl
               (
                keep  = xpath fileref
                where = (fileref='_TMP0002')
               );

         /*
         / I am not sure if I want LOGNAME or USER environment variable
         /----------------------------------------------------------------*/
         login = sysget('USER');
         _en[_en0] = trim(login)||' '
                     ||trim(xpath)
                     ||" SMBv:(&vsimstat,&vdtab) &sysdate:&systime";

         %end;
      %else %if &sysscp=VMS | &sysscp=VMS_AXP %then %do;
         login    = getjpi('USERNAME');

         _en[_en0] = trim(login)||' '
                     ||compress(tranwrd("&vmssasin",'000000.',' '),' ')
                     ||" SMBv:(&vsimstat,&vdtab) &sysdate:&systime";
         %end;


      %else %do;
         login    = 'NOT VAX';
         _en[_en0] = trim(login)||' '
                     ||compress(tranwrd("&vmssasin",'000000.',' '),' ')
                     ||" SMBv:(&vsimstat,&vdtab) &sysdate:&systime";

         %end;

      %end;


      run;

   %if &debug %then %do;
      title4 'DATA=TEMP5 titles and footnotes';
      proc print data=&temp5;
         run;
      %end;



   /*
   / Sort the input data by TREATMENT and merge with the data set of
   / treatments and panels.
   /--------------------------------------------------------------------------*/

   proc sort data=&data out=&temp4;
      by &tmt;
      run;

   data &temp4;
      merge &temp4 &temp1;
      by &tmt;

      /*
      / Compute an ORDER variable for the row variables based on the order
      / of the ROW= macro parameter.
      /-----------------------------------------------------------------------*/

      %jkrord(rowvars=&rows,_name_=_VNAME_,_row_=_ROW_)

      %jkdash(rowvars=&rows,_name_=_VNAME_,_dash_=_DASH_)

      %jkrlbl(rowvars=&rows,_name_=_VNAME_,_rlbl_=_RLBL_)

      %jkrfmt(rowsfmt=&rowsfmt,_name_=_VNAME_,_fmt_=_VFMT_)

   /*
   / The percents will be printed with a PICTURE format.  Due to
   / limitations of PICTURE and specilized rounding requriements
   / the value of PCT is recalculated in this step.
   /--------------------------------------------------------------*/

   %if %index(&pctfmt,JKPCT) %then %do;

      %if &pctstyle=1 %then %do;
         if pct > .Z  then do;
            pct = pct * 1E2;
            select;
               when(0 <  pct < 1)   pct=.A;
               when(99 < pct < 100) pct=.B;
               otherwise            pct=round(pct,1);
               end;
            end;
         %end;
      %else %if &pctstyle=2 %then %do;
         if pct > .Z then do;
            pct = pct * 1e2;
            select;
               when(0    < pct < 0.5) pct=.A;
               when(99.5 < pct < 100) pct=.B;
               otherwise              pct=round(pct,1);
               end;
            end;
         %end;
      %end;

      run;


   proc sort data=&temp4;
      by panel _row_ _vname_ _order_ _level_ &tmt;
      run;

   %if &debug %then %do;
      title4 'DATA=TEMP4 The modified input data';
      proc contents data=&temp4;
         run;
      proc print data=&temp4;
         run;
      %end;


   proc format;
      picture jkpct
           1-99,100 = " 009&pctsign)" (prefix='(')
                  0 = "     "         (noedit)
                 .A = " (<1&pctsign)" (noedit)
                 .B = "(>99&pctsign)" (noedit);
      run;


   %if &hppcl %then %do;

      /*
      / Call JKHPPCL to setup printing environment
      /-------------------------------------------*/
      %jkhppcl(cpi=&cpi,lpi=&lpi,layout=&layout)

      data _null_;
         file "&outfile..PCL" print notitles ls=200;
         &setup
         run;
      %end;


   %let _outfile = &outfile%str(.)&file_ext;

   options missing =' ';

   data _null_;

      file "&outfile%str(.)&file_ext" &file_dsp print
           notitles n=ps ll=ll ls=200 ps=&ps line=line col=col;


      /*
      / Note this where INDEXW clause may cause a problem and needs to
      / be rewritten.
      /-----------------------------------------------------------------*/

      set
         &temp4(where=(indexw("&rows",_vname_)))
         end=eof;

      by panel _row_ _vname_ _order_ _level_ &tmt;

      /*
      / Declare arrays.
      / _CL is the column labels.
      / _FN is the footnotes
      / _TC is print positions for the table columns
      /------------------------------------------------*/

      retain _one_ 1;

      if _n_=1 then do;
         set
            &temp5
               (
                keep = _en: _fn: _fi:
               )
            ;
         array _fn0_[20];
         array _fn[20,5];
         array _fi[20];
         array _en[10];

         set
            &constant
               (
                keep = _tc1-_tc&cols _tw1-_tw&cols skip vskip vskipa
                       indent indentc indentv indentvc indentlc
                       tcols cols coff pcoff style pvalue between swid
               )
            ;

         array _tc[&colsplus] _tc1-_tc&cols _one_;
         array _tw[&colsplus] _tw1-_tw&cols swid;
         end;


      if first.panel then set &temp3(keep=_cl:);

      array _cl0_[&colsplus];
      array _cl[&colsplus,10];

      /*
      / Declare and initialize various constants
      /-------------------------------------------*/
      retain thisline homeline;
      retain flow "&flow" stats "&stats";
      retain ls &ls cont &cont;

      length cnted $&ls;
      retain cnted 'Continued...';

      length xlblx $40;

      /*
      / Start a new page when the value of panel changes
      /---------------------------------------------------*/

      if first.panel then do;
         put _page_ @;
         link header;
         end;


   %if "&rlocate" = "FIRST" %then %do;
      if first._vname_ then do;
         if _rlbl_ > ' ' then do;
            rlbl_i + 1;
            array _rlbl[1] _rlbl_;
            if indexw(flow,'RLABEL'||left(put(rlbl_i,5.))) then do;

               %jkflowx(in=_rlbl,out=_frlbl,dim=10,size=&jkrlwid,delm=' ',newline='\')

               do k = 1 to _frlbl0;

                  _frlbl[k] = translate(_frlbl[k],' ',"&hrdspc");
                  put _frlbl[k] $&ls..;

                  end;
               end;
            else do;
               _rlbl_ = translate(_rlbl_,' ',"&hrdspc");
               put _rlbl_ $&ls..;
               end;
            end;
         end;
      %end;




      /*
      / When the value of _VNAME_ changes we need to print the
      / print the table stub information.
      /-------------------------------------------------------*/

      if first._vname_ then do;
         /*
         / THISLINE is used to remember where to started printing.
         /---------------------------------------------------------*/
         thisline = line;
         homeline = line;

         /*
         / print the group heading for each _VNAME_ using the
         / $_VNAME_ format that was supplied by the user.  This text
         / is then flowed into to space provided by SWID=.  The
         / _VNAME_ labels are indented 1 space on lines 2 on up.
         /---------------------------------------------------------*/

         array _stb[1] $200. _temporary_;
         _stb[1] = put(_vname_,$_vname_.);

         %jkflowx(in=_stb,out=_fstb,dim=10,size=&swid,delm=' ',newline='\')

         _fstb[1] = translate(_fstb[1],' ',"&hrdspc");
         put #(thisline) +(indentv) _fstb[1] $char&swid..;
         do i = 2 to _fstb0;
            thisline = thisline + 1;

            _fstb[i] = translate(_fstb[i],' ',"&hrdspc");
            put #(thisline) +(indentv+indentvc) _fstb[i] $char&swid..;
            end;


         if (_vtype_='DISC')
            | (_vtype_='CONT'
            &
             ^(
                 index(upcase(stats),'N-MEAN(STD)')
               | index(upcase(stats),'N-MEAN(STDMEAN)')
               | index(upcase(stats),'N-LSM(LSMSE)')
              )
            )
            then do;
            do i = 1 to vskip;
               put;
               thisline = thisline + 1;
               end;
            end;

         /*
         / if the user requested PVALUE=YES
         /----------------------------------------------------------*/
         %if &pvalue %then %do;
            if pvalue & _vtype_ ^in('PTNO','PVALUE') then do;

               if _vtype_='CONT' then do;
                  if index(upcase(stats),'N-MEAN(STD)')
                   | index(upcase(stats),'N-MEAN(STDMEAN)')
                   | index(upcase(stats),'N-LSM(LSMSE)')
                     then pv_adj=0;
                     else pv_adj=1;
                  end;
               else if _vtype_ in('YESNO','DISC') then pv_adj = -1 * vskip;



            %if &pvarflag %then %do;
               array _pvars[*] &pvars;
               j = tcols;
               do i = 1 to dim(_pvars);
               j = j + 1;

               /*
               / flag pvalue with asterics if pr_cntl < &plevel
               /--------------------------------------------------*/

               %if &pflag %then %do;
                  if _pvars[i] > .Z then do;
                     if .Z < &pvcomp <= &plevel then pfltxt = &pfltxt;
                     end;
                  else pfltxt = ' ';
                  %end;
               %else %do;
                  retain pfltxt ' ';
                  %end;
                  %if "&pvalfmt" = "" %then %do;
                     if .Z < _pvars[i] < 0.001 then do;
                        cprob = '<0.001';
                        put   #(thisline+pv_adj) @(_tc[j]+pcoff) cprob $6. pfltxt $1. #(thisline);
                        end;
                     else put #(thisline+pv_adj) @(_tc[j]+pcoff) _pvars[i] 6.3 pfltxt $1. #(thisline);
                     %end;
                  %else %do;
                     put #(thisline+pv_adj) @(_tc[j]+pcoff) _pvars[i] &pvalfmt pfltxt $1. #(thisline);
                     %end;
                  end;
               %end;


            %do i = 1 %to &cpvars0;
               array _cpv&i[*] &&cpvars&i;

               j = tcols;
               do i = 1 to min(dim(_cpv&i),&p_var0);
                  j = j + 1;
                  put   #(&i+thisline+pv_adj-(^&pvarflag))
                        @(_tc[j]+pcoff) _cpv&i[i] $char&pwid..
                        #(thisline);
                  end;
               %end;
            end /*if pvalue & _vtype_^='PTNO' then do; */;
            %end;


         /*
         / For continuious variables the table stub labels will also
         / include the ROW labels for the statistics associated with
         / them.  So print them now.
         /------------------------------------------------------------------*/
         thisline = line;
      /*
      / Move back to the home line for this _VNAME_
      /----------------------------------------------*/
      %if %bquote(&stbstyl)=COLUMN %then %do;
         thisline = homeline;
         %end;

         if _vtype_ = 'CONT' then do;
            stats = upcase(stats);
            i = 1;
            thestat = scan(stats,i,' ');
            do while(thestat^=' ');
               select(thestat);
                  when('MEAN')          call label(mean,xlblx);
                  when('STD' )          call label(std,xlblx);
                  when('MIN-MAX')       xlblx = 'Min-Max';
                  when('MIN')           call label(min,xlblx);
                  when('MAX')           call label(max,xlblx);
                  when('N')             call label(n,xlblx);
                  when('MEDIAN')        call label(median,xlblx);
                  when('STDMEAN')       call label(stdmean,xlblx);
                  when('MODE')          call label(mode,xlblx);
                  when('LSM')           call label(lsm,xlblx);
                  when('LSMSE')         call label(lsmse,xlblx);
                  when('ROOTMSE')       call label(rootmse,xlblx);
                  when('MEAN(STD)')     xlblx = 'Mean(STD)';
                  when('MEAN(STDMEAN)') xlblx = 'Mean(SEM)';
                  when('LSM(LSMSE)')    xlblx = 'Mean adj(se)';
                  when('L95-U95')       xlblx = '95% C.I.';
                  when('L90-U90')       xlblx = '90% C.I.';
                  when('L99-U99')       xlblx = '99% C.I.';
                  when('SSE')           call label(sse     ,xlblx);
                  when('DFE')           call label(def     ,xlblx);
                  when('MSE')           call label(mse     ,xlblx);
                  when('ROOTMSE')       call label(rootmse ,xlblx);
                  when('CSS')           call label(css     ,xlblx);
                  when('CV')            call label(cv      ,xlblx);
                  when('KURTOSIS')      call label(kurtosis,xlblx);
                  when('MSIGN')         call label(msign   ,xlblx);
                  when('NMISS')         call label(nmiss   ,xlblx);
                  when('NOBS')          call label(nobs    ,xlblx);
                  when('NORMAL')        call label(normal  ,xlblx);
                  when('P1')            call label(p1      ,xlblx);
                  when('P10')           call label(p10     ,xlblx);
                  when('P5')            call label(p5      ,xlblx);
                  when('P90')           call label(p90     ,xlblx);
                  when('P95')           call label(p95     ,xlblx);
                  when('P99')           call label(p99     ,xlblx);
                  when('PROBM')         call label(probm   ,xlblx);
                  when('PROBN')         call label(probn   ,xlblx);
                  when('PROBS')         call label(probs   ,xlblx);
                  when('PROBT')         call label(probt   ,xlblx);
                  when('Q1')            call label(q1      ,xlblx);
                  when('Q3')            call label(q3      ,xlblx);
                  when('QRANGE')        call label(qrange  ,xlblx);
                  when('RANGE')         call label(range   ,xlblx);
                  when('SIGNRANK')      call label(signrank,xlblx);
                  when('SKEWNESS')      call label(skewness,xlblx);
                  when('SUM')           call label(sum     ,xlblx);
                  when('SUMWGT')        call label(sumwgt  ,xlblx);
                  when('T')             call label(t       ,xlblx);
                  when('USS')           call label(uss     ,xlblx);
                  when('VAR')           call label(var     ,xlblx);
                  when('L95')           call label(l95     ,xlblx);
                  when('U95')           call label(u95     ,xlblx);
                  when('L90')           call label(l90     ,xlblx);
                  when('U90')           call label(u90     ,xlblx);
                  when('L99')           call label(l99     ,xlblx);
                  when('U99')           call label(u99     ,xlblx);
                  otherwise             xlblx = thestat;
                  end;
               if thestat in('N-MEAN(STD)'  , 'N-MEAN(STDMEAN)',
                             'N-LSM(LSMSE)' , 'N-MEAN(STD)-MIN+MAX' ,
                             'N-MEAN-STD-MIN-MAX')
                          | (&stathold)
                  then thisline=thisline-1;
               else if "COLUMN"="&stbstyl" then put #(thisline+i-1) +(indentc) xlblx;
               else put +(indentc) xlblx;
               i = i + 1;
               thestat = scan(stats,i,' ');
               end;
            end;
         end;


      /*
      / When the value of level changes a new row in the table will start.
      / The data is arranged with TMT within _LEVEL_.  So at each new value
      / of _LEVEL_ we need to reset the column pointer.
      /----------------------------------------------------------------------*/
      if first._level_ then ncol=0;

      /*
      / Each time the value of TMT changes increment the column pointer.
      /----------------------------------------------------------------------*/
      if first.&tmt then ncol+1;


      /*
      / Now depending on the type of variable DISC CONT YESNO PTNO print
      / the various statistics associated with them.
      /----------------------------------------------------------------------*/
      if _vtype_ = 'CONT' then do;

         put #(thisline) @;

         select(_vname_);
            when('0');
            %do i = 1 %to &jku0_0-1;
               when("&&jku&i._v") do;
               %do j = 1 %to &&jku&i._0;
                  if &&jku&i._&j; else put @(_tc[ncol]) ' ';
                  %end;
               end;
               %end;
            otherwise do;
               %let i = &jku0_0;
               %do j = 1 %to &&jku&i._0;
                  if &&jku&i._&j; else put @(_tc[ncol]) ' ';
                  %end;
               end;
            end;


         end;

      else if _vtype_ = 'PVALUE' then do;
         put #(thisline-1) @;
         if .Z < prob < 0.001 then do;
            cprob = '<0.001';
            put @(_tc[ncol]+pcoff) cprob $6.;
            end;
         else put @(_tc[ncol]+pcoff) prob 6.3;
         end;

      else if _vtype_ in('DISC','YESNO') then do;
         /*
         / For DISC variables we need to print stub labels.  These labels are
         / supplied by the user in the formats with the same name as the
         / discrete variables.  That is to format SEX the user creates $SEX
         / value labeling format.
         /
         / If the user has labels that are longer than the SWID then he may
         / specify that they be flowed.  This is done by using FLOW=_LEVEL_.
         / The _LEVEL_ labels are not flowed by default because flowing removes
         / leading spaces that the user way want to use to achive indending.
         /-------------------------------------------------------------------*/
         if _vtype_ = 'DISC' then do;

            if first._level_ then do;
               array _slbl[1] $200 _temporary_;

               %if &ynlabel %then %do;
                  select(_level_);
                     when('N') _slbl[1] = 'No';
                     when('Y') _slbl[1] = 'Yes';
                     otherwise _slbl[1] = _level_;
                     end;
                  %end;
               %else %do;
                  _slbl[1] = putc(_level_,_vfmt_);
                  %end;

               if      _slbl[1] = '01'x then _slbl[1] = 'n';
               else if _slbl[1] = '_'   then _slbl[1] = 'Data not available';
               else if _slbl[1] = ' '   then _slbl[1] = _level_;


               if index(flow,'_LEVEL_') then do;
                  %jkflowx(in=_slbl,out=_fslbl,dim=10,size=&swid,delm=' ',newline='\')
                  do k = 1 to _fslbl0;

                     _fslbl[k] = translate(_fslbl[k],' ',"&hrdspc");

                     if k=1
                        then put #(thisline) +(indent)          _fslbl[k] $char&swid..;
                        else put #(thisline) +(indent+indentlc) _fslbl[k] $char&swid..;
                     if k < _fslbl0 then thisline = thisline + 1;

                     end;
                  end;
               else do;

                  _slbl[1] = translate(_slbl[1],' ',"&hrdspc");
                  put #(thisline) +(indent) _slbl[1] $char&swid..;

                  end;
               end;
            end;
         else if _vtype_ = 'YESNO' & first._level_ then thisline=thisline-1;

         /*
         / Print the counts and percents according to the value of style
         /--------------------------------------------------------------------*/
         select(style);
            when('1','0') do;
               if _level_='_'
                  then put #(thisline) @(_tc[ncol]+coff) count &ifmt;
                  else put #(thisline) @(_tc[ncol]+coff) count &ifmt pct &pctfmt;
               end;
            when('2') do;
               if _level_='_'
                  then put #(thisline) @(_tc[ncol]+coff) count &ifmt;
                  else put #(thisline) @(_tc[ncol]+coff) count &ifmt '/' n &ifmt-l pct &pctfmt;
               end;
            when('3') put #(thisline) @(_tc[ncol]+coff) count &ifmt;
            when('4') do;
               if _level_='_'
                  then put #(thisline) @(_tc[ncol]+coff) count &ifmt;
                  else put #(thisline) @(_tc[ncol]+coff) count &ifmt '/' n &ifmt-l;
               end;
            end;

         /*
         / After printing all the columns for a given _LEVEL_ increment the
         / line pointer to setup for the next row.
         /--------------------------------------------------------------------*/
         if last._level_ then thisline = thisline + 1 + skip;
         end;

      /*
      / For the special case of the patient numbers print them on the same
      / line as the table stub label. i.e. THISLINE-1.  Also print a dashed
      / line under this data.
      /---------------------------------------------------------------------*/
      else if _vtype_='PTNO' then do;
         put #(thisline-1)  @(_tc[ncol]+coff) n &ifmt;
         end;


      /*
      / Put a blank line between each section (row name)  of the table.
      /----------------------------------------------------------------------*/
      if last._vname_ then do;
         if _DASH_ then put &ls*&dashchr;
         do i = 1 to vskipa;
            put;
            end;
         end;

   %if "&rlocate" = "LAST" %then %do;
      if last._vname_ then do;
         if _rlbl_ > ' ' then do;
            rlbl_i + 1;
            array _rlbl[1] _rlbl_;
            if indexw(flow,'RLABEL'||left(put(rlbl_i,5.))) then do;

               %jkflowx(in=_rlbl,out=_frlbl,dim=10,size=&jkrlwid,delm=' ',newline='\')

               do k = 1 to _frlbl0;

                  _frlbl[k] = translate(_frlbl[k],' ',"&hrdspc");
                  put _frlbl[k] $&ls..;

                  end;
               end;
            else do;
               _rlbl_ = translate(_rlbl_,' ',"&hrdspc");
               put _rlbl_ $&ls..;
               end;
            end;
         end;
      %end;


      /*
      / Print the table footer text at the end of the panels.
      /----------------------------------------------------------------------*/
      if last.panel then link footer;
      if eof then do;
         call symput('JKPG0',trim(left(put(page+&jkpg0,8.))));
         end;
      return;

    Header:
      Page + 1;

      /*
      / Print the TITLE lines. centering where need and adding
      / continued messages.
      /----------------------------------------------------------------------*/


      retain _hl0 &hl0;
      array _hl[15] $&ls _temporary_
         ("&hl1","&hl2","&hl3","&hl4","&hl5","&hl6","&hl7","&hl8","&hl9","&hl10",
          "&hl11","&hl12","&hl13","&hl14","&hl15");

      if page > 1 & cont then do;
         _hl[&hlcont] = trim(_hl[&hlcont])||' (Continued)';
         cont = 0;
         end;

      length _tempvar $&ls;
      do i = 1 to _hl0;
         select;
            when(indexw("&hlright",put(i,2.))) do;
               _tempvar = _hl[i];
               _tempvar = right(_tempvar);
               _tempvar = translate(_tempvar,' ',"&hrdspc");
               put #(i) _tempvar $char&ls..;
               end;
            when(indexw("&hlleft", put(i,2.))) do;
               _tempvar = _hl[i];
               _tempvar = left(_tempvar);
               _tempvar = translate(_tempvar,' ',"&hrdspc");
               put #(i) _tempvar $char&ls..;
               end;
            otherwise do;
               _tempvar = left(_hl[i]);
               _tempvar = repeat(' ',floor((&ls-length(_tempvar))/2)-1)||_tempvar;
               _tempvar = translate(_tempvar,' ',"&hrdspc");
               put #(i) _tempvar $char&ls..;
               end;
            end;
         end;


      %if 0 %then %do;
         put &ls*&dashchr;
         %end;

         put;

      /*
      / Print the column headers
      /------------------------------------------------------------------*/

      do i = 1 to max(of _cl0_[*],0);

         do j = _cl0;

            _wid     = _tw[j];

            _cl[j,i] = translate(_cl[j,i],' ',"&hrdspc");

            put @(1) _cl[j,i] $varying100. _wid @;

            end;

         do j = 1 to _cl0-1;

            _wid     = _tw[j];

            _offset  = floor( (_tw[j]-length(_cl[j,i])) / 2 );

            _cl[j,i] = translate(_cl[j,i],' ',"&hrdspc");

            put @(_tc[j]+_offset) _cl[j,i] $varying100. _wid @;

            end;
         put;
         end;

      put &ls*&dashchr;
      put;
      return;

    Footer:
      %if "&footdash"="YES" %then %do;
         put &ls*&dashchr;
         %end;

      %if "&contmsg"="YES" %then %do;
         put cnted $char&ls..-r;
         %end;

      if cont & ^eof then put cnted $char&ls..-r;

      do i = 1 to _fn0;
         do k = 1 to _fn0_[i];
            if k = 1
               then put    _fn[i,k] $char&ls..;
               else put +(_fi[i]+0) _fn[i,k] $char&ls..;
            end;
         end;

      k = _en0;
      do i = 1 to _en0;
         put #(&ps-k+1) _en[i] $&ls..-l;
         k = k - 1;
         end;

      return;
      run;

   proc delete data=&temp1 &constant &temp3 &temp4 &temp5;
      run;

   %put NOTE: JKPG0=&jkpg0;

   %if "&pagenum"="PAGEOF" %then %do;
      data _null_;

         infile "&outfile%str(.)&file_ext" sharebuffers n=1 length=l;
         file   "&outfile%str(.)&file_ext";

         input line $varying200. L;

         if index(line,&target) then do;
            page + 1;

            text = Compbl('Page '||put(page,8.)||" of &jkpg0");
            tlen = length (text);

            substr(line,1+&ls-tlen,tlen) = text;

            put line $varying200. L;

            end;

         run;
      %end;


 %EXIT:
   %PUT NOTE: Macro DTAB ending execution.;
   %mend dtab;
n the table will start.
      / The data is arranged with TMT within _LEVEL_.  So at each new value
      / of _LEVEL_ we need to reset the column pointer.
      /----------------------------------------------------------------------*/
      if f/users/d33/jf97633/sas_y2k/macros/dtime.sas                                                         0100775 0045717 0002024 00000003302 06635174212 0021335 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ Program name:     DTIME.SAS
/
/ Program version:  2.1
/
/ Program purpose:  Converts a SAS date & time value to a SAS Datetime value
/
/ SAS version:      6.12 TS020
/
/ Created by:
/ Date:
/
/ Input parameters: DATE - SAS date value
/                   TIME - SAS time value
/
/ Output created:
/
/ Macros called:    None.
/
/ Example call:     dt1=%dtime(d1,t1);
/
/===========================================================================
/ Change log:
/
/    MODIFIED BY: Jonathan Fry
/    DATE:        09DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 2.1.
/    ------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    ------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    ------------------------------------------------------------------
/===========================================================================*/

%macro dtime(date,time);

/*---------------------------------------------------------------------------/
/ JMF001                                                                     /
/ Display Macro Name and Version Number in LOG                               /
/---------------------------------------------------------------------------*/

   %put ------------------------------------------------------;
   %put NOTE: Macro called: DTIME.SAS      Version Number: 2.1;
   %put ------------------------------------------------------;

   (&date * 86400 + &time)
%mend dtime;
                                                                                                                                                                                                                                                                                                                              /users/d33/jf97633/sas_y2k/macros/fmtinfo.sas                                                       0100664 0045717 0002024 00000010570 06634223673 0021704 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ Program Name:     FMTINFO.SAS
/
/ Program Version:  2.1
/
/ Program purpose:  Return Information About the Formats in the Specified
/                   Version 6 Format Library
/
/ SAS Version:      6.12
/
/ Created By:       Carl P. Arneson
/ Date:             06 Jan 1993
/
/ Input Parameters: LIB     - library name used for format catalog
/                   FMTOUT  - name of dataset for storing format catalog details
/                   SELECT  - list of catalog entries to be selected (optional)
/                   EXCLUDE - list of catalog entries to be excluded (optional)
/                             (either SELECT or EXCLUDE can be specified, but not both)
/                   REPORT  - (Y/N) option for producing a report
/
/ Output Created:   Format details are output to the dataset specified in the parameter
/                   FMTOUT. A report is produced if hte value of the parameter REPORT is
/                   set to Y.
/
/ Macros Called:    INFIX.SAS
/
/ Example Call:
/
/===========================================================================================
/ Change Log
/
/    MODIFIED BY: Jonathan Fry
/    DATE:        09DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 2.1.
/    ---------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    ---------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    ---------------------------------------------------------------------
/==========================================================================================*/

%macro FMTINFO(lib=,
               out=FMTOUT,
               select=,
               exclude=,
               report=Yes);

/*-------------------------------------------------------------------------/
/ JMF001                                                                   /
/ Display Macro Name and Version Number in LOG                             /
/-------------------------------------------------------------------------*/

   %put -----------------------------------------------------;
   %put NOTE: Macro called: FMTINFO.SAS   Version Number: 2.1;
   %put -----------------------------------------------------;

%local where;

%if %length(&report)  %then %let report=%substr(%upcase(&report),1,1);
%if %length(&select)  %then %let select=%left(%trim(%upcase(&select)));
%if %length(&exclude) %then %let exclude=%left(%trim(%upcase(&exclude)));

%if %length(&select) %then
  %let where=%infix(list=&select,operator=%str(,),quote=Yes);

%else %if %length(&exclude) %then
  %let where=%infix(list=&exclude,operator=%str(,),quote=Yes);

%if %length(&select) %then
  %let where=(where=(fmtname in(&where)));

%else %if %length(&exclude) %then
  %let where=(where=(fmtname ~in(&where)));

proc format lib=&lib cntlout=&out ;
  run ;

data &out ;
  set &out &where ;
  length idname $20 ;
  if type in('C','J') then idname = '$' !! fmtname ;
  else idname = fmtname ;
  run ;

%if &report=Y %then %do ;
  proc report nowd data=&out headline headskip missing ;
    column idname length start end sexcl eexcl hlo
           range label ;
    define idname / order width=12 center 'Format Name';
    define length / order width=6 center 'Length' ;
    define start / noprint spacing=0 ;
    define end / noprint spacing=0 ;
    define sexcl / noprint spacing=0 ;
    define eexcl / noprint spacing=0 ;
    define hlo / noprint spacing=0 ;
    define range / computed center 'Range' ;
    define label / display left 'Label' ;
    break after length / skip ;
    compute range / char length=30 ;
      if hlo='O' then do ;
        start='OTHER' ;
        end='OTHER' ;
      end ;
      if index(hlo,'L') then do ;
        start='LOW' ;
        sexcl='Y' ;
      end ;
      if index(hlo,'H') then do ;
        end='HIGH' ;
        eexcl='Y' ;
      end ;
      if start=end then
         range = '<' !! left(trim(start)) !! '>' ;
      else do ;
        if sexcl='Y' then range = '<' !! left(start) ;
        else range = '(' !! start ;
        range = trim(range) !! ',' !! left(end) ;
        if eexcl='Y' then range = trim(range) !! '>' ;
        else range = trim(range) !! ')' ;
      end ;
    endcomp ;
    run ;
%end ;

%mend FMTINFO ;
                                                                                                                                        /users/d33/jf97633/sas_y2k/macros/fn.sas                                                            0100775 0045717 0002024 00000004267 06634224045 0020650 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ Program name:     FN.SAS
/
/ Program version:  2.1
/
/ Program purpose:  Creates macro variable with name of current SAS program
/                   (or INTERACTIVE if run interactively)
/
/ SAS version:      6.12 TS020
/
/ Created by:
/ Date:
/
/ Input parameters: None
/
/ Output created:   Macro Variable FN - See Purpose
/
/ Macros called:    None
/
/ Example call:     %fn;
/                   title "output for program &fn";
/
/====================================================================================
/ Change log:
/
/    MODIFIED BY: Jonathan Fry
/    DATE:        09DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 2.1.
/    ------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    ------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    ------------------------------------------------------------------
/====================================================================================*/

%macro fn;

/*------------------------------------------------------------------------/
/ JMF001                                                                  /
/ Display Macro Name and Version Number in LOG                            /
/------------------------------------------------------------------------*/

   %put ------------------------------------------------------;
   %put NOTE: Macro called: FN.SAS         Version Number: 2.1;
   %put ------------------------------------------------------;

%if "&sysscp"="SUN 4" %then %do ;
  %local fn i ;
  %let fn = %substr(&sysparm,%eval(%index(&sysparm,%str(:))+1));
  %let i = %index(&fn,%str(/)) ;
  %do %while(&i) ;
    %let fn = %substr(&fn,%eval(&i + 1)) ;
    %let i = %index(&fn,%str(/)) ;
  %end ;
  %let fn = %scan(&fn,1,%str(.)) ;
%end ;
%else %if "&sysscp"="VMS" %then %do ;
   %local fn ;
   %let fn=3;
   %let fn=%eval(%index(&sysparm,%str(])) + 1);
   %let fn=%scan(%substr(&sysparm,&fn),1,%str(.));
%end;
&fn
%mend fn ;
 statement for Macro Name and Version Number.
/                 Change Version Number to 2.1.
/    ------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    ------------------------------------------------------------------
/    MODIFIED BY:
//users/d33/jf97633/sas_y2k/macros/getopts.sas                                                       0100775 0045717 0002024 00000007053 06634224606 0021731 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ Program Name:     GETOPTS.SAS
/
/ Program Version:  2.1
/
/ Program purpose:  Read your current system options and put the settings in
/                   macro variables.
/
/ SAS Version:      6.12
/
/ Created By:       Carl P. Arneson
/ Date:             14 Jul 1992
/
/ Input Parameters: OPT    - List of SAS options to be read.
/                   MV     - List of macro variables corresponding to the options specified
/                            in OPT.
/                   DUMP   - Y/N flag for defining whether to output option details to the
/                            log.
/                   CATLIB - Libname used for referencing catalog containing SCL code.
/
/ Output Created:   SAS option details are output to a set of macro variables. These details
/                   are dumped to the log if option DUMP=Y is specified.
/
/ Macros Called:    %bwwords
/
/ Example Call:     %getopts(opt=number missing date,mv=numb miss dat);
/
/=============================================================================================
/ Change Log
/
/   MODIFIED BY: ABR
/   DATE:        10.2.93
/   MODID:       Ver 1.5
/   DESCRIPTION: Remove commented LIBNAME statement.
/   ----------------------------------------------------------------------------
/   MODIFIED BY: Jonathan Fry
/   DATE:        09DEC1998
/   MODID:       JMF001
/   DESCRIPTION: Tested for Y2K compliance.
/                Add %PUT statement for Macro Name and Version Number.
/                Change Version Number to 2.1.
/   ----------------------------------------------------------------------------
/   MODIFIED BY:
/   DATE:
/   MODID:       XXX002
/   DESCRIPTION:
/   ----------------------------------------------------------------------------
/=============================================================================================*/

%macro GETOPTS(opt   =,
               mv    =,
               dump  =Y,
               catlib=utilscl);

/*------------------------------------------------------------------------/
/ JMF001                                                                  /
/ Display Macro Name and Version Number in LOG                            /
/------------------------------------------------------------------------*/

   %put ------------------------------------------------------;
   %put NOTE: Macro called: GETOPTS.SAS    Version Number: 2.1;
   %put ------------------------------------------------------;

   %if &sysver<6.09 %then %do ;
      %put ERROR: You must use version 6.09 or higher with SUMTAB. ;
      %if &sysenv=BACK %then %str(;ENDSAS;) ;
   %end ;

   %local numopt nummv num i ;
   %let dump = %upcase(%substr(&dump,1,1)) ;
   %let opt = %upcase(&opt) ;
   %let mv = %upcase(&mv) ;
   %let numopt = %bwwords(&opt,root=___opt) ;
   %let nummv = %bwwords(&mv,root=___mv) ;
   %if &numopt ~= &nummv %then %do ;
      %let msg1=%str(The number of options specified (&numopt) does not) ;
      %let msg2=%str(equal the number of variables specified (&nummv)) ;
      %put WARNING: &msg1 &msg2 ;
      %let num=%eval((&numopt<&nummv)*&numopt + (&numopt>&nummv)*&nummv) ;
   %end ;
   %else %let num = &numopt ;
   %do i = 1 %to &num ;
      %global &&___mv&i ;
   %end ;

   proc display c=&catlib..sclutl.getopts.scl batch ;
   run ;

   %if &dump=Y %then %do ;
      %put Options --------------------------------------------------------;
      %do i = 1 %to &num ;
         %local val ;
         %let val = &&___mv&i;
         %put &&___opt&i is set to &&&val. ;
      %end ;
      %put ----------------------------------------------------------------;
   %end ;
%mend GETOPTS;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     /users/d33/jf97633/sas_y2k/macros/hexit.sas                                                         0100775 0045717 0002024 00000011741 06634224645 0021367 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ Program name:     HEXIT.SAS
/
/ Program version:  2.1
/
/ Program purpose:  Use this macro to create macro variables that contain hex
/                   characters 40 through 255. The names have the following form
/                   &root.two digit hex char (ie. hex B1 variable name is XB1).
/
/ SAS version:      6.12 TS020
/
/ Created by:
/ Date:
/
/ Input parameters: ROOT - user defined name
/                   macro name e.g. NAMExx (max 6 chars long)
/                   (xx hex identifier)
/
/ Output created:
/
/ Macros called:    None
/
/ Example call:     %hexit(root=name);
/
/=====================================================================================
/ Change log:
/
/    MODIFIED BY: Jonathan Fry
/    DATE:        09DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 2.1.
/    --------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    --------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    --------------------------------------------------------------------
/=====================================================================================*/

%macro hexit(root=X);

/*-------------------------------------------------------------------------/
/ JMF001                                                                   /
/ Display Macro Name and Version Number in LOG                             /
/-------------------------------------------------------------------------*/

   %put -----------------------------------------------------;
   %put NOTE: Macro called: HEXIT.SAS      Version Number 2.1;
   %put -----------------------------------------------------;

   %global &root.00 &root.01 &root.02 &root.03
           &root.04 &root.05 &root.06 &root.07
           &root.08 &root.09 &root.0A &root.0B
           &root.0C &root.0D &root.0E &root.0F;
   %global &root.10 &root.11 &root.12 &root.13
           &root.14 &root.15 &root.16 &root.17
           &root.18 &root.19 &root.1A &root.1B
           &root.1C &root.1D &root.1E &root.1F;
   %global &root.20 &root.21 &root.22 &root.23
           &root.24 &root.25 &root.26 &root.27
           &root.28 &root.29 &root.2A &root.2B
           &root.2C &root.2D &root.2E &root.2F;
   %global &root.30 &root.31 &root.32 &root.33
           &root.34 &root.35 &root.36 &root.37
           &root.38 &root.39 &root.3A &root.3B
           &root.3C &root.3D &root.3E &root.3F;
   %global &root.40 &root.41 &root.42 &root.43
           &root.44 &root.45 &root.46 &root.47
           &root.48 &root.49 &root.4A &root.4B
           &root.4C &root.4D &root.4E &root.4F;
   %global &root.50 &root.51 &root.52 &root.53
           &root.54 &root.55 &root.56 &root.57
           &root.58 &root.59 &root.5A &root.5B
           &root.5C &root.5D &root.5E &root.5F;
   %global &root.60 &root.61 &root.62 &root.63
           &root.64 &root.65 &root.66 &root.67
           &root.68 &root.69 &root.6A &root.6B
           &root.6C &root.6D &root.6E &root.6F;
   %global &root.70 &root.71 &root.72 &root.73
           &root.74 &root.75 &root.76 &root.77
           &root.78 &root.79 &root.7A &root.7B
           &root.7C &root.7D &root.7E &root.7F;
   %global &root.80 &root.81 &root.82 &root.83
           &root.84 &root.85 &root.86 &root.87
           &root.88 &root.89 &root.8A &root.8B
           &root.8C &root.8D &root.8E &root.8F;
   %global &root.90 &root.91 &root.92 &root.93
           &root.94 &root.95 &root.96 &root.97
           &root.98 &root.99 &root.9A &root.9B
           &root.9C &root.9D &root.9E &root.9F;
   %global &root.A0 &root.A1 &root.A2 &root.A3
           &root.A4 &root.A5 &root.A6 &root.A7
           &root.A8 &root.A9 &root.AA &root.AB
           &root.AC &root.AD &root.AE &root.AF;
   %global &root.B0 &root.B1 &root.B2 &root.B3
           &root.B4 &root.B5 &root.B6 &root.B7
           &root.B8 &root.B9 &root.BA &root.BB
           &root.BC &root.BD &root.BE &root.BF;
   %global &root.C0 &root.C1 &root.C2 &root.C3
           &root.C4 &root.C5 &root.C6 &root.C7
           &root.C8 &root.C9 &root.CA &root.CB
           &root.CC &root.CD &root.CE &root.CF;
   %global &root.D0 &root.D1 &root.D2 &root.D3
           &root.D4 &root.D5 &root.D6 &root.D7
           &root.D8 &root.D9 &root.DA &root.DB
           &root.DC &root.DD &root.DE &root.DF;
   %global &root.E0 &root.E1 &root.E2 &root.E3
           &root.E4 &root.E5 &root.E6 &root.E7
           &root.E8 &root.E9 &root.EA &root.EB
           &root.EC &root.ED &root.EE &root.EF;
   %global &root.F0 &root.F1 &root.F2 &root.F3
           &root.F4 &root.F5 &root.F6 &root.F7
           &root.F8 &root.F9 &root.FA &root.FB
           &root.FC &root.FD &root.FE &root.FF;
   data _null_;
      do i = 0 to 255;
         call symput("&root"!!put(i,hex2.),collate(i,,1));
         end;
      run;
   %mend hexit;
----------------------------
/ /users/d33/jf97633/sas_y2k/macros/import.sas                                                        0100775 0045717 0002024 00000006165 06634225154 0021560 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ Program name:     IMPORT.SAS
/
/ Program version:  2.1
/
/ Program purpose:  Makes SAS transport files with the XPORT engine.
/
/ SAS version:      6.12 TS020
/
/ Created by:
/ Date:
/
/ Input parameters: IN      - Input filename & path
/                   OUT     - Output location
/                   SELECT  - PROC COPY select option
/                   EXCLUDE - PROC COPY exclude option
/                   ENGINE  - Libname engine option
/                   OUTDD   - Default output libname
/                   INDD    - Default input libname
/
/ Output created:
/
/ Macros called:    None
/
/ Example call:     %import(in =/projects/p999/sas/data/raw/data.xpt,
/                           out=/home/d86/test);
/
/==================================================================================
/ Change log:
/
/    MODIFIED BY: Jonathan Fry
/    DATE:        09DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 2.1.
/    ------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    ------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    ------------------------------------------------------------------
/=================================================================================*/

%macro import(in = ,
             out = WORK,
          select = ,
         exclude = ,
          engine = saseb,
           outdd = _ZOUTZ_,
            indd = _XINX_);

/*-----------------------------------------------------------------------/
/ JMF001                                                                 /
/ Display Macro Name and Version Number in LOG                           /
/-----------------------------------------------------------------------*/

   %put ------------------------------------------------------;
   %put NOTE: Macro called: IMPORT.SAS     Version Number: 2.1;
   %put ------------------------------------------------------;

   %if %substr(&sysver,1,1)<6 %then %do;
      %put ERROR: Macro IMPORT requires Version 6 or higher;
      %put NOTE: Your are using version &sysver;
      %if &sysenv=BACK %then %do ;
        endsas;
      %end ;
   %else %goto macexit ;
   %end;
   %if "&in"="" %then %do;
      %put ERROR: You must specify an input transport filename;
      endsas;
   %end;
   %if "&out"="" %then %do;
      %put ERROR: You must specify a valid output data library;
      endsas;
   %end;

   %if "&select" ~=""    %then %let select  = SELECT &select %str(;);
   %if "&exclude"~=""    %then %let exclude = EXCLUDE &exclude %str(;);

   filename &indd DISK "&in";
   libname  &indd xport;

   %if "&out"~="WORK" %then %do;
      libname &outdd &engine "&out";
   %end ;
   %else %let outdd=WORK;

   proc copy in=&indd out=&outdd;
      &select
      &exclude
   run;

   filename &indd clear;
   libname  &indd clear;

   %if "&out"~="WORK" %then %do;
      libname &outdd clear;
   %end;
   %macexit:
%mend import;
                                                                                                                                                                                                                                                                                                                                                                                                           /users/d33/jf97633/sas_y2k/macros/infix.sas                                                         0100775 0045717 0002024 00000006727 06634225544 0021372 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ Program Name:     INFIX.SAS
/
/ Program Version:  2.1
/
/ Program purpose:  Use this macro to generate a new list from LIST seperated by
/                   OPERATORs.  The new list may be quoted with the QUOTE option.
/
/                   Ex.
/                       %INFIX(list=A B C,operator=%str(,),quote=YES)
/
/                       Produces: "A","B","C"
/
/ SAS Version:      6.12
/
/ Created By:
/ Date:
/
/ Input Parameters: LIST     - A character string containing a string of words to be
/                              processed, separated by a delimiter (default = a space).
/                   OPERATOR - An optional character which is inserted between each word
/                              in the output string.
/                   QUOTE    - When this option is set to YES, QUOTE or 1, the macro will
/                              place quotes around each word in the output string.
/                   DELM     - This defines the character to be used as a delimiter in
/                              the input string (default is a space character).
/
/ Output Created:   The words parsed from the input character string and suitably
/                   processed according to the options described above are output to
/                   macro variable OUTPUT.
/
/ Macros Called:    None.
/
/ Example Call:     %let var1=%quote(software,product,services);
/                   %let var2=%infix(list=&var1,delm=%str(,));
/
/==========================================================================================
/ Change Log:
/
/    MODIFIED BY: Jonathan Fry
/    DATE:        09DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 2.1.
/    ------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    ------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    ------------------------------------------------------------------------
/=========================================================================================*/

%macro infix(list=,operator=,quote=NO,delm=%str( ));

/*--------------------------------------------------------------------------/
/ JMF001                                                                    /
/ Display Macro Name and Version Number in LOG                              /
/--------------------------------------------------------------------------*/

   %put ------------------------------------------------------;
   %put NOTE: Macro called: INFIX.SAS      Version Number: 2.1;
   %put ------------------------------------------------------;

   %if "&list"~="" %then %do;
      %let quote = %upcase(&quote);
      %local i w w0 output;
      %let i = 1;
      %let w = %scan(&list,&i,&delm);
      %do %while("&w"~="");
         %local w&i;
         %let w&i = &w;
         %let i = %eval(&i+1);
         %let w = %scan(&list,&i,&delm);
         %end;
      %let w0=%eval(&i-1);
      %do i = 1 %to &w0-1;
         %if %index(QUOTE YES 1,&quote)
            %then %let output = &output."&&w&i"&operator;
            %else %let output = &output.&&w&i.&operator;
         %end;
      %if %index(QUOTE YES 1,&quote)
         %then %let output = &output."&&w&w0";
         %else %let output = &output.&&w&w0;
      &output%str( )
   %end;
%mend infix;
                                         /users/d33/jf97633/sas_y2k/macros/jkchkdat.sas                                                      0100664 0045717 0002024 00000015322 06325705460 0022021 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ PROGRAM NAME: jkchkdat.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE: Used internally by standard macros to check input
/    datasets for correct variables and variable type.  This macro can
/    be used by other macros or in user programs.
/
/ SAS VERSION: 6.12
/
/ CREATED BY: John Henry King
/ DATE: 1992
/
/ INPUT PARAMETERS:
/  data   = data set to be checked
/  cvars  = list of variables that must exist and are character
/  nvars  = list of variables that must exist and are numeric
/  vars   = list of variables that must exist of either type
/  return = name of global macro created by the macro, this is how the
/           macro communicates with the user.
/
/ OUTPUT CREATED:
/   a global macro variable named in return=
/
/ MACROS CALLED:
/   none
/
/ EXAMPLE CALL:
/    This example call is from AESTAT.  The parameter values are macro
/    variables that are parameters for AESTAT.  The %if shows
/    how AESTAT is directed to exit when &RC_A is not zero.
/
/  %jkchkdat(data=&adverse,
/            vars=&pageby &control &uniqueid &sex &level1 &level2,
/           nvars=&tmt,
/           cvars=&subgrp,
/          return=rc_a)
/
/   %if &rc_a %then %goto exit;
/
/==============================================================================
/ CHANGE LOG:
/
/ MODIFIED BY: John Henry King
/ DATE: 28FEB1997
/ MODID: JHK001
/ DESCRIPTION: Change the way the macro writes error messages. 
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK002
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK003
/ DESCRIPTION:
/============================================================================*/

/*
/ JKCHKDAT Macro
/
/ JKCHKDAT provides verification of the existence of a SAS data
/ set. JKCHKDAT also verifies the existance of variables on a
/ data set and can also verify that variables are numeric or
/ character.
/
/ To verify that variables of either type are on the data set
/ include their names in the VARS= parameter.
/
/ To verify that variables exist and are character include their
/ names in the CVARS= parameter.
/
/ To verify that variables exist and are numeric include their
/ name in the NVARS= parameter.
/
/ The macro provides error messages revealing the problems
/ identified by the macro, data set not found, variable not
/ found, or variable is the wrong type.
/
/ The macro also sets the macro variable named in the RETURN
/ parameter to 1 if any error is found.  The default name for
/ this macro variable is RC.  The user can change this through
/ the use of RETURN= if needed.
/
/ The user should provide appropriate logic in calling macro for
/ stopping execution of the calling macro when an error is found.
/-------------------------------------------------------------------*/

%macro JKCHKDAT(data=_last_, /* The dataset           */
               cvars=,       /* Character variables   */
               nvars=,       /* Numeric variables     */
                vars=,       /* Variables of any type */
             return=RC);

   %let data   = %upcase(&data);
   %let return = %upcase(&return);

   %global &return;
   %let &return = 0;


   /*
   / JHK001
   / Remove the ! from ERROR message.
   /---------------------------------------*/
   %local err dash;
   %let err  = ERROR: MACRO JKCHKDAT ERROR:;
   %let dash = _+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_; 

   /*
   / Create unique names for the temporary sas datasets used
   / in this macro
   /---------------------------------------------------------*/

   %local contents vlist;
   %let contents  = _1_&sysindex;
   %let vlist     = _2_&sysindex;

   /*
   / Call proc contents to find out if the data set exists
   / and if so to produce a data set of variable names with
   / their types.
   /-------------------------------------------------------*/
   proc contents noprint
         data = &data
         out  = &contents(keep=memname name type);
      run;

   /*
   / If the data set does not exist then SAS sets the automatic
   / macro variable SYSERR to 3000.  At any rate syserr is not
   / 0 assume that the data set does not exist.
   /------------------------------------------------------------*/

   %if &syserr^=0 %then %do;
      %put &dash;
      %put &err Data set, &data, not found.;
      %put &dash;
      %let &return=1;
      %end;

   %else %do;
      proc sort data=&contents;
         by name;
         run;

      /*
      / Now process the var lists into a data set that has the same
      / structure as that from proc contents.  The variable TYPE2
      / will be compared to TYPE from the proc contents output
      /--------------------------------------------------------------*/

      data &vlist;
         length name $8;
         retain delm ' -';
         array _v[0:2] $200 _temporary_ ("&vars","&nvars","&cvars");
         do i = 0 to 2;
            j = 1;
            name = scan(_v[i],j,delm);
            do while(name^=' ');
               name = upcase(name);
               output;
               j = j + 1;
               name = scan(_v[i],j,delm);
               end;
            end;
         stop;
         drop j;
         rename i=type2;
         run;

      proc sort data=&vlist;
         by name;
         run;

      /*
      / Now merge the proc contents output and the data from the step
      / above to ferret out the problems.
      /---------------------------------------------------------------*/


      /*
      / JHK001
      / The error message text in the section is being change to mask the 
      / message when this code is MPRINTed.
      /-----------------------------------------------------------------------*/
      data _null_;
         merge &contents(in=in1) &vlist(in=in2);
         by name;
         if _n_ = 1 then do;
            length err $28 dash $80;
            retain err dash;
            err = left(reverse('RORRE TADKHCKJ ORCAM :RORRE'));
            dash = repeat('_+',39);
            end;
            
         if ^in1 then do;
            put / dash / err "Variable " name "not found in data &data" '.' / dash / ' ';
            call symput("&return",'1');
            end;
         else if in2 then do;
            if type2^=0 & type^=type2 then do;
               if type2=1 then do;
                  put / dash / err "Variable " name 'must be numeric.' / dash / ' ';
                  end;
               else if type2=2 then do;
                  put / dash / err "Variable " name 'must be character.' / dash / ' ';
                  end;
               call symput("&return",'1');
               end;
            end;
         run;

      proc delete data=&contents &vlist;
         run;

      %end;
   %put NOTE: &return=&&&return;
   %mend JKCHKDAT;
                                                                                                                                                                                                                                                                                                              /users/d33/jf97633/sas_y2k/macros/jkchklst.sas                                                      0100664 0045717 0002024 00000005203 06325705464 0022054 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ PROGRAM NAME: jkchklst.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE: Uses this utility to check a user specified value (list)
/  against a list of possible values.
/
/ SAS VERSION: 6.12 (UNIX)
/
/ CREATED BY: John Henry King
/
/ DATE: FEB1997
/
/ INPUT PARAMETERS:
/
/ LIST=               The list of words to be compared.                             
/                                                                                   
/ AGAINST=UNISTATS    The list to compare to.  The default is the statistics        
/                     computed by PROC univariate.                                  
/                                                                                   
/ RETURN=RC           A macro variable set to 0 if no errors were found,            
/                     1 otherwise.                                                  
/
/ OUTPUT CREATED: The macro variable named in RETURN= is modified.
/ 
/ MACROS CALLED:
/
/   
/
/==============================================================================
/ CHANGE LOG:
/
/ MODIFIED BY:
/ DATE:
/ MODID: JHK001
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK002
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK003
/ DESCRIPTION:
/============================================================================*/


%macro jkchklst(list = ,
             against = UNISTATS,
              return = RC);

   %let return = %upcase(&return);

   %global &return;
   %let &return = 0;

   %if %length(&list)=0 %then %goto EXIT;

   %let list    = %upcase(&list);
   %let against = %upcase(&against);

   %if "&against" = "UNISTATS" %then %let against=
CSS CV KURTOSIS MAX MEAN MEDIAN MIN MODE MSIGN N NMISS NOBS NORMAL 
P1 P10 P5 P90 P95 P99 PROBM PROBN PROBS PROBT Q1 Q3 QRANGE RANGE 
SIGNRANK SKEWNESS STD STDMEAN SUM SUMWGT T USS VAR;

   data _null_;

      if _n_ = 1 then do;
         length err $28 dash $80;
         retain err dash;
         err = left(reverse('RORRE TSLKHCKJ ORCAM :RORRE'));
         dash = repeat('_+',39);
         end;

      length list against $200 w $20;
      retain list "&list";
      retain against "&against";
 
      i = 1;
      w = scan(list,i,' ');

      do while(w ^= ' ');
         if ^indexw(against,w) then do;
            put / dash / err ' The requested statistic ' w 'is not valid, Check your spelling.' / dash / ' ';
            call symput("&return",'1');
            end;
         i = i + 1;
         w = scan(list,i,' ');
         end;

      stop;
      run;

 %EXIT:
   %mend jkchklst;
                                                                                                                                                                                                                                                                                                                                                                                             /users/d33/jf97633/sas_y2k/macros/jkcont01.sas                                                      0100664 0045717 0002024 00000006552 06325705476 0021703 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ PROGRAM NAME: jkcont01.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE: This utility macro is called by SIMSTAT to produce 
/   descriptive statistisc for continious variables.  Do not use this 
/   macro outside the context of macro SIMSTAT.
/
/ SAS VERSION: 6.12 (UNIX)
/
/ CREATED BY: John Henry King
/ DATE: FEB1997
/
/ INPUT PARAMETERS:
/
/   data=               Names the data set to be analyzed.
/
/   out=                The output dataset.
/
/   by=                 List by variables
/
/   uniqueid=           Unique patient identifier
/
/   tmt=                Treatment variable name
/
/   var=                List of varaibles to be processed
/
/   stats=              List of statistics to be computed
/
/   print=NO            Print the OUT= dataset.
/
/ OUTPUT CREATED: sas data set
/
/ MACROS CALLED:  none
/
/ EXAMPLE CALL:
/
/   %jkcont01(data=&temp1,
/              out=&_cont_,
/               by=&by,
/              tmt=&tmt,
/         uniqueid=&uniqueid,
/              var=&continue,
/            stats=&stats,
/            print=NO)
/
/==============================================================================
/ CHANGE LOG:
/
/ MODIFIED BY:			    
/ DATE:
/ MODID: JHK001
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK002
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK003
/ DESCRIPTION:
/============================================================================*/

%macro jkcont01(data=,
                 out=,
                  by=,
                 tmt=,
            uniqueid=,
                 var=,
               stats=,
               print=NO);

      %local i temp1; 

      %let temp1 = _1_&sysindex;
 
      %let print = %upcase(&print);

      /*
      / Sort the data for proc transpose. Keep only the variables that are
      / needed for this analysis.
      /----------------------------------------------------------------------*/
      proc sort 
            data=&data(keep=&by &tmt &uniqueid &var)
            out=&temp1;
         by &by &tmt &uniqueid;
         run;

      /*
      / Transpose the ANALYSIS variables so they can be run through 
      / PROC UNIVARIATE by _NAME_.
      /-----------------------------------------------------------------------*/

      proc transpose
            data   = &temp1(keep=&by &tmt &uniqueid &continue)
            out    = &temp1(rename=(_name_=_vname_))
            prefix = xxxxxxx;
         by &by &tmt &uniqueid;
         var &var;
         run;

      proc sort data=&temp1;
         by &by _vname_ &tmt;
         run;


      /*
      / Call UNIVARIATE and request only the statistics requested by the user.
      / The statistics will be named using the statistic name.
      /---------------------------------------------------------------------*/

      %let stat0 = %jkxwords(list=&stats,root=stat);

      proc univariate data=&temp1 noprint;
         by &by _vname_ &tmt;
         var xxxxxxx1;
         output out= &out
         %do i = 1 %to &stat0;
            &&stat&i=&&stat&i
            %end;
            ;
         run;

      proc delete data=&temp1; 
         run;

   %if "&print"="YES" %then %do;
      title4 "DATA=&out, Created by MACRO JKCONT01";
      proc print data=&out;
         run;
      title4;
      %end;
 
   %mend jkcont01;
                                                                                                                                                      /users/d33/jf97633/sas_y2k/macros/jkctchr.sas                                                       0100664 0045717 0002024 00000003115 06325705505 0021663 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ PROGRAM NAME: jkctchr.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE: Macro function used to count the occurrences of a 
/  particular character in a macro variable.     
/
/ SAS VERSION: 6.12
/
/ CREATED BY: John Henry King
/
/ DATE: 1996
/
/ INPUT PARAMETERS:
/  string    A string of characters.
/  target    The character to count.
/
/ OUTPUT CREATED: Returns an positive integer value, or zero.
/
/ MACROS CALLED: none
/
/ EXAMPLE CALL: 
/    %let count = %jkctchr(The quick brown fox,o);
/ 
/  Returns 2 to count.
/==============================================================================
/ CHANGE LOG:
/
/ MODIFIED BY:
/ DATE:
/ MODID: JHK001
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK001
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK003
/ DESCRIPTION:
/============================================================================*/

/*
/ JKCTCHR (FUNCTION)
/ Count the occurrences of a character in a string.
/
/ Returns a value.
/
/ Parameters:
/ STRING         the string of character to search and count
/ TARGET         the character to look for and count
/
/--------------------------------------------------------------------*/
%macro jkctchr(string,target);
 
 
   %local count word newlist delm;
   %local i count;

   %let count = 0;

   %do i = 1 %to %length(&string);
      %if %qsubstr(&string,&i,1) = %quote(&target) 
         %then %let count = %eval(&count + 1);
      %end;

   &count

   %mend jkctchr;
                                                                                                                                                                                                                                                                                                                                                                                                                                                   /users/d33/jf97633/sas_y2k/macros/jkdash.sas                                                        0100664 0045717 0002024 00000004040 06325705512 0021473 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ PROGRAM NAME: jkdash.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE: Used by standard macros to process the dash line placement
/   in the ROWS parameter of DTAB.
/
/ SAS VERSION: 6.12 (UNIX)
/
/ CREATED BY: John Henry King
/ DATE: FEB1997
/
/ INPUT PARAMETERS:
/
/   rowvars=        The list of words to process.
/ 
/   _name_=_vname_  The name of _VNAME_ special variable from SIMSTAT.
/ 
/   _dash_=_dash_   The name of the variable created by this macro.
/
/   delm=%str( +)   The delimiter list for the scan function.
/
/
/ OUTPUT CREATED:
/
/   Add _dash_ to a data set.
/
/ MACROS CALLED: none
/
/ EXAMPLE CALL:
/
/   %jkdash(rowvars=&rows,_name_=_VNAME_,_dash_=_DASH_);
/
/==============================================================================
/ CHANGE LOG:
/
/ MODIFIED BY:
/ DATE:
/ MODID: JHK001
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK002
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK003
/ DESCRIPTION:
/============================================================================*/

%macro jkdash(rowvars=,
               _name_=_VNAME_,
               _dash_=_DASH_,
                 delm=%str( +));
   %local i w w2;
   %let rowvars = %upcase(&rowvars);
   %let i = 1;
   %let w  = %scan(&rowvars,&i,  &delm);
   %let w2 = %scan(&rowvars,&i+1,&delm);

   %if %index("&rowvars",-) | %index("&rowvars",_PATNO_) %then %do;
      select(&_name_);
         when(' '); 
      %do %while("&w"^="");
         %let w2 = %substr(&w2%str( ),1,1);
         %if "&w2" = "-" %then %do;
            when("&w") &_dash_ = 1;
            %end;
         %let i = %eval(&i + 1);
         %let w  = %scan(&rowvars,&i,&delm);
         %let w2 = %scan(&rowvars,&i+1,&delm);
         %end;

      otherwise &_dash_ = 0;
      end;
      %end;
   %else %do;
      select(&_name_);
         when('_PATNO_') &_dash_ = 1;
         otherwise       &_dash_ = 0;
         end;
      %end;
   %mend jkdash;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                /users/d33/jf97633/sas_y2k/macros/jkdisc01.sas                                                      0100664 0045717 0002024 00000026647 06325705520 0021657 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ PROGRAM NAME: jkdisc01.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE: This utility macro is called by SIMSTAT to compute
/ frequency counts for discrete variables.  Do not use this macro outside
/ the context of macro SIMSTAT.
/		     
/ SAS VERSION: 6.12 (UNIX)
/
/ CREATED BY: John Henry King
/ DATE: FEB1997
/
/ INPUT PARAMETERS:
/
/ by=                 List by variables
/
/ uniqueid=           Unique patient identifier
/
/ tmt=                Treatment variable name
/
/ discrete=           List of 1 byte character discrete variables to be 
/                     analyzed.
/
/ dlevels=            List of possible values that the discrete variables may
/                     have.  This is need if one or more of the levels is not
/                     found in the data.
/
/ dexcl=              A single value, for a discrete variable, that should be
/                     excluded by the macro when counting.
/
/ out=                Names the output data set created by the macro.
/
/ print=NO            Print the output data set?
/
/ OUTPUT CREATED: A SAS data set.
/
/ MACROS CALLED:
/
/   jkxwords  parse a list of words
/   jkprefix  add prefix to a list of words
/
/ EXAMPLE CALL:
/
/   %jkdisc01(data=&subset, 
/              out=&_disc2_,
/               by=&by &control,
/              var=_one_,
/         uniqueid=&uniqueid,
/              tmt=&tmt,
/            print=NO,
/         discrete=&discrete,
/          dlevels=&dlevels,
/            dexcl=&dexcl)
/
/==============================================================================
/ CHANGE LOG:
/
/ MODIFIED BY:
/ DATE:
/ MODID: JHK001
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK002
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK003
/ DESCRIPTION:
/============================================================================*/

%macro jkdisc01(data=,
                  by=,
                 var=,
             uniqueid=,
                 tmt=,
            discrete=,
             dlevels=,
               dexcl=,
                 out=,
               print=NO);


   /*
   / Create a unique name for the temporary dataset.
   /-------------------------------------------------*/

   %local temp1; 
   %let temp1 = _1_&sysindex;


   /*
   / Description of LOCAL macro variables.
   /
   / I        = do loop counter
   / J        = holds temporary variables names
   /
   / DATALIST = list of temporary datasets created by PROCs
   /            TRANSPOSE, ANOVA, or FREQ that are need to later
   /            be combined, by MERGEing or SETting.
   /            Includes in= dataset option. This variable is reused
   /            in different sections of the macro.
   /
   / TVARLIST = List of variable names created by PROC TRANPOSE,
   /            in the form _A: _B: etc.
   /
   / DELLIST  = List of temporary datasets created by PROC TRANSPOSE
   /            to use in PROC DELETE.  This list contains the same
   /            names as MRGLIST but without the in= dataset option.
   /
   / DDISCLST = This variable contains a list of discrete variables to
   /            be dropped.  The macros creates variables to count the
   /            missing values of the discrete variables.  These variables
   /            are created by the macro even if there are no missing
   /            values for a particular discrete.  This list provides a way
   /            to DROP this variable from the data. The variables have
   /            names in the form X_A_ X_B_ etc.
   /
   / DDISCn   = need to explain
   /
   / ABC      = The letters of the alphabet.  Used to construct temporary
   /            name for the discrete variables.  The temporary names have
   /            the form X_Ax X_Ay X_Az.
   /            Where X_A is the value of the PREFIX option used in PROC
   /            TRANSPOSE, and z,y,z are the values of the discrete
   /            variable.  This method of naming limits the number of
   /            discrete variables the macro can accept to 36.
   /
   /------------------------------------------------------------------------*/


      %let print = %upcase(&print);

      %local disc0 dlev0;
      %local datalist dellist tvarlist i j abc w levels;

      %let abc = ABCDEFGHIJKLMNOPQRSTUVWXYZ;

      %let datalist = ;
      %let dellist  = ;
      %let tvarlist = ;

     
      %let disc0 = %jkxwords(list=&discrete,root=disc);



      /*
      / Check to see if dlevels is delimited properly
      /------------------------------------------------*/
      %if %length(&dlevels) > 0 %then %do;
         %let dlev0 = 1;

         %if %index("&dlevels",\) = 0 %then %do;
            %let dlev0 = 0;
            %put ER!ROR: MACRO JKDISC01 ER!ROR, You need to delimit DLEVELS= with a backslash \;
            %end;

         %end;

      /*
      / Call PROC TRANSPOSE once for each DISCRETE variable creating a
      / seperate transposed data set for each variable
      /------------------------------------------------------------------*/
      %do i = 1 %to &disc0;
         %let j = %substr(&abc,&i,1);



         /*
         / Scan out the values of DLEVELS and and store them in a macro
         / variable array.  The values of these arrays will be used to
         / create data step array statements below.
         /
         / If the user supplies a DLEVELS list that does not have the same
         / number of elements at the number of variables in DISCRETE the
         / then the macro just uses the LAST value from the list.
         /-------------------------------------------------------------------*/
         %if &dlev0 > 0 %then %do;
            %let w = %scan(&dlevels,&i,%str(\));
            %if "&w" ^= "" %then  %then %let levels = &w;
            %local dlev&i;
            %let dlev&i = %jkprefix(&levels,X_&j);
            %put NOTE: DLEV&i = &&dlev&i;
            %end;

         proc transpose
               data   = &data
               out    = _&j(drop=_name_) 
               prefix = X_&j;
            by &by &uniqueid &tmt;
            id &&disc&i;
            var &var;
            run;

         /*
         / DATALIST will be used in the MERGE statement below
         /-------------------------------------------------------*/
         %let datalist = &datalist _&j;

         /*
         / TVARLIST holds the names of the NEW variables created
         / by PROC TRANSPOSE.
         /--------------------------------------------------------*/
         %let tvarlist = &tvarlist X_&j:;

         /*
         / DELLIST is the list data set names that will be used by
         / PROC DELETE to delete the data set created by transpose
         / after they have been merged.
         /--------------------------------------------------------*/
         %let dellist  = &dellist _&j;
         %end;

      %put NOTE: datalist = &datalist;

      data &temp1;
         merge &datalist;
         by &by &uniqueid &tmt;

         /*
         / For each DISCRETE variable do the following.
         / 1. See of there are any all missing observations.
         /    If so create a variable _A_ and set it to 1.
         /    This variable will be DATA NOT AVAIL counts.
         /
         / 2. Propagate ZERO values for the transposed variables
         /    that are set to missing by PROC TRANSPOSE.  Uses the
         /    MAX library function.
         /
         /----------------------------------------------------------*/


         %do i = 1 %to &disc0;

            %let j = %substr(&abc,&i,1);

            %local ddisc&i;
            %let ddisc&i = x_&j._;

            %if "&dexcl" ^= "" %then %do;
               drop x_&j.&dexcl;
               %end;

            %if (&dlev0 > 0) %then %do;
               array A_&j[*] &&dlev&i;
               %end;

            %else %do;
               array A_&j[*] x_&j:;
               %end;

            /*
            / If all the elements of the an array are missing, then
            / the discrete variable was missing in the input dataset.
            / The macro will create _A_ to count these
            / missing values.
            /
            / Otherwise do over the array and set the missing values
            / to 0.
            /----------------------------------------------------------*/

            %if "&dexcl" ^= "" %then %do;
               if x_&J.&dexcl ^= 1 then do;
                  if nmiss(of A_&j[*])=dim(A_&j)then do;
                     x_&j._ = 1;
                     call symput("DDISC&i",' ');
                     end;
                  else do _i_ = 1 to dim(A_&j);
                     A_&j[_i_] = max(0,A_&j[_i_]);
                     end;
                  end;
               %end;
            %else %do;
               if nmiss(of A_&j[*])=dim(A_&j)then do;
                  x_&j._ = 1;
                  call symput("DDISC&i",' ');
                  end;
               else do _i_ = 1 to dim(A_&j);
                  A_&j[_i_] = max(0,A_&j[_i_]);
                  end;
               %end;

            %end;

         drop _i_;
         run;


      %let ddisclst=;
      %do i = 1 %to &disc0;
         %put NOTE: i=&i DDISC&I=&&ddisc&i;
         %let ddisclst = &ddisclst &&ddisc&i;
         %end;

      %put NOTE: DDISCLST=&ddisclst;

      /*
      / Delete the temporary data sets created by proc transpose
      /------------------------------------------------------------*/
      proc delete data=&dellist;
         run;

      /*
      / Transpose the merged, transposed, data the merge step above.
      / This will string out the data into a form that can easily be
      / processed by proc summary
      /--------------------------------------------------------------*/
      proc transpose
            data   = &temp1(drop=&ddisclst)
            out    = &temp1
            prefix = xxxxxxx;
         by &by &uniqueid &tmt;
         var &tvarlist;
         run;

      /*
      / Call proc summary to get the counts and percents of the 0,1
      / variables created above.
      /--------------------------------------------------------------*/
      proc summary nway missing data=&temp1; 
         by &by;
         class _name_ &tmt;
         var xxxxxxx1;
         output out = &out(drop=_type_ _freq_)
                sum = count
                  n = n
               mean = pct;
         run;


      /*
      / Delete the temporary dataset being use to this point
      /--------------------------------------------------------------*/
      proc delete data=&temp1; 
         run;


      /*
      / Process the proc summary data to
      /
      / 1. Remove the value of the discrete variable from _VNAME_
      /    and assign them to the variable _LEVEL_
      / 2. Create proper values for _VNAME_ from the list of discrete
      /    variables.
      / 3. Create _VTYPE_.
      / 4. Fix up the values of N PCT and COUNT when _LEVEL_ is _
      /--------------------------------------------------------------*/
 
      data &out;

         length _vname_ _level_ _vtype_ $8;
         retain _vtype_ 'DISC';

         set &out;

         _i_      = indexc("&abc",substr(_name_,3,1));
         _vname_  = symget('DISC'||left(put(_i_,2.)));
         _level_  = substr(_name_,4);

         drop _name_ _i_;

         if _level_='_' then do;
            n     = .;
            pct   = .;
            count = max(0,count);
            end;
         run;

   %if "&print"="YES" %then %do;
      title4 "DATA=&out from JKDISC01";
      proc print data=&out;
         run;
      title4;
      %end;

   %mend jkdisc01;
ls=&dlevels,
/            dexcl=&dexcl)
/
/==============================================/users/d33/jf97633/sas_y2k/macros/jkflowx.sas                                                       0100664 0045717 0002024 00000006213 06325705530 0021717 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ PROGRAM NAME: jhflowx.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE:
/   Used to flow text.  The macro will flow text into array elements that 
/   are wider or narrower that the original array.
/
/ SAS VERSION: 6.12
/
/ CREATED BY: John Henry King
/
/ DATE: 1992
/
/ INPUT PARAMETERS:
/
/  in   = names the array to be re-formated.  Use only expliciatly 
/         subscripted arrays.  Give only the array name, as used in the 
/         DIM function.
/
/  out  = names the array created by the macro.  The default is _FLOW.
/
/  dim  = define the dimension of the output array.  The default is 20.
/         This value should be large enought to hold all the newly flowed
/         text but small enough to not waste too much space in your data
/         set.
/
/  size = specifies the length of each OUT array element.  The default
/         is 40.
/
/  newline = specifies a character imbedded in the input array to force the 
/            start of a new array element.
/
/  delm = specifies the delimiter for the words in the input array.
/
/ OUTPUT CREATED:
/   An array.
/
/ MACROS CALLED: none
/
/ EXAMPLE CALL:
/
/     array _y[1] $200 _temporary_;
/     _y[1] = put(&level1,&fmtlvl1);
/
/     %jkflowx(in=_y,out=_1lv,dim=10,size=&swid)
/
/==============================================================================
/ CHANGE LOG:
/
/ MODIFIED BY:
/ DATE:
/ MODID: JHK001
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK002
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK003
/ DESCRIPTION:
/============================================================================*/

%macro jkflowX(in = ,
              out = _flow,
             size = 40,
              dim = 20,
          newline = '\',
             delm = ' ');

   %local x;
   %let x = JKFLOX;
   retain &x.L &newline;

   &out.0 = 1;
   array &out[&dim] $&size;
   
   do &x.I = 1 to dim(&in);
      if &in[&x.I] = ' ' then continue;
      &x.K = 1;
      &x.W = scan(&in[&x.I] , &x.K , &delm);
      do while( &x.W ^= ' ');
         select;
            when( left(&x.W) = &x.L) do;
               &out.0 + 1;
               end;
            when( length(&x.W) > &size ) do;
               if &out[&out.0] ^= ' ' then &out.0 + 1;
               &out[&out.0] = substr( &x.W , 1 , &size-1 ) || '-';
               &out.0 + 1;
               &out[&out.0] = substr( &x.W , &size );
               end;
            when( length(&x.W) = &size & &out[&out.0] = ' ' ) do;
               &out[&out.0] = left(&x.W);
               end;
            when((length(&out[&out.0])*(&out[&out.0]^=' ')) + length(&x.W)+1 <= &size ) do;
               &out[&out.0] = left(trim(&out[&out.0])||' '||&x.W);
               end;
            otherwise do;
               &out.0 + 1;
               &out[&out.0] = left(&x.W);
               end;
            end;
         &x.K + 1;
         &x.W = scan(&in[&x.I] , &x.K , &delm);
         end;
      if &out[&out.0] = ' ' then &out.0 + -1;
      end;
   if (&out[1] = ' ') & (&out.0 = 1) then &out.0 = 0;
  
   drop &x:;
   
   %mend jkflowX;
                                                                                                                                                                                                                                                                                                                                                                                     /users/d33/jf97633/sas_y2k/macros/jkflsz2.sas                                                       0100664 0045717 0002024 00000006771 06325705544 0021636 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ PROGRAM NAME: jkflsz2.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE: Flows text array elements into a 2 dimensional array. This
/   macro is an extension of JKFLOWX and was written specifically for the
/   standard macros.  It can be used outside the the standard macros but 
/   JKFLOWX is more generally useful.
/
/ SAS VERSION: 6.12
/
/ CREATED BY: John Henry King
/
/ DATE: 1993
/
/ INPUT PARAMETERS:
/
/  in   = names the array to be re-formated.  Use only expliciatly 
/         subscripted arrays.  Give only the array name, as used in the 
/         DIM function.
/
/  out  = names the array created by the macro.  The default is _FL.
/
/  dim1 = Defines dimension one of the output array.
/
/  dim2 = Defines dimension two of the output array.
/
/  size = specifies the length of each OUT array element.  The default
/         is 40.
/
/  sizear = names and array to pass the size of each flowed field. 
/
/  newline = specifies a character imbedded in the input array to force the 
/            start of a new array element.
/
/  delm = specifies the delimiter for the words in the input array.
/
/ OUTPUT CREATED:
/   An array
/
/ MACROS CALLED: none
/
/ EXAMPLE CALL: 
/   Taken from AETAB.
/
/   %jkflsz2(in=_tl,out=_xl,size=&cwid,sizeAR=_tw,dim1=&cols,dim2=5);
/
/==============================================================================
/ CHANGE LOG:
/
/ MODIFIED BY:
/ DATE:
/ MODID: JHK001
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK002
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK003
/ DESCRIPTION:
/============================================================================*/
  
%macro jkflsz2(in = ,
              out = _fl,
             size = 40,
           sizeAR = _xx,
             dim1 = 5,
             dim2 = 5,
          newline = '\',
             delm = ' ');

   %local x;
   %let x = JKFLOW;

   retain &x.L &newline;

   &out.0 = 0;
   array &out.0_[&dim1];

   array &out[&dim1,&dim2] $&size;
   
   do &x.I = 1 to dim(&in);
      &out.0_[&x.I] = 0;
      if &in[&x.I] = ' ' then continue; 
      &out.0 = &x.i;
      &out.0_[&x.I] = 1;
      &x.K = 1;
      &x.W = scan(&in[&x.I] , &x.K , &delm);
      do while( &x.W ^= ' ');
         select;
            when( left(&x.W) = &x.L ) do;
               &out.0_[&x.i] + 1;
               end;
            when( length(&x.W) > &sizeAR[&x.I] ) do;
               if &out[&x.I,&out.0_[&x.i]] ^= ' ' then &out.0_[&x.i] + 1;
               &out[&x.I,&out.0_[&x.i]] = substr( &x.W , 1 , &sizeAR[&x.I]-1 ) || '-';
               &out.0_[&x.i] + 1;
               &out[&x.I,&out.0_[&x.i]] = substr( &x.W , &sizeAR[&x.I] );
               end;
            when( length(&x.W) = &sizeAR[&x.I] & &out[&x.I,&out.0_[&x.i]] = ' ' ) do;
               &out[&x.I,&out.0_[&x.i]] = left(&x.W);
               end;
            when((length(&out[&x.I,&out.0_[&x.i]])*(&out[&x.I,&out.0_[&x.i]]^=' ')) 
                  + length(&x.W)+1 <= &sizeAR[&x.I] ) do;
               &out[&x.I,&out.0_[&x.i]] = left(trim(&out[&x.I,&out.0_[&x.i]])||' '||&x.W);
               end;
            otherwise do;
               &out.0_[&x.i] + 1;
               &out[&x.I,&out.0_[&x.i]] = left(&x.W);
               end;
            end;
         &x.K = &x.K + 1;
         &x.W = scan(&in[&x.I] , &x.K , &delm);
         end;
      if &out[&x.I,&out.0_[&x.i]] = ' ' then &out.0_[&x.i] + -1;
      end;
   
  
   drop &x:;
   
   %mend jkflsz2;
       /users/d33/jf97633/sas_y2k/macros/jkfn.sas                                                          0100664 0045717 0002024 00000007177 06325713751 0021201 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ PROGRAM NAME: jkfn.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE: This macro is used to determine the filename and userid
/   of the executing program.  This information was previously supplied by
/   a modified SAS script.  The default for this macro are to assign this
/   data to SYSPARM in the format that was supplied by the SAS script method.
/   This macro is used in MACPAGE.  If the user needs to use %FN before
/   macpage is called then this macro should be called first, perhaps in INIT.
/
/ SAS VERSION: 6.12 (UNIX)
/
/ CREATED BY: John Henry King
/
/ DATE: 04MAR1997
/
/ INPUT PARAMETERS:
/
/   mvar=   specifies the name of the macro variable assigned.  Use just the 
/           name with no &.  The default is SYSPARM.
/
/   style=  specifies the style of the output.  
/           Valid values are:
/              SYSPARM          ==> userid:\fullpathtofile
/              FULLPATH         ==> fullpath
/              FULLPATH_NO_EXT  ==> fullpath with the extension removed
/              NAME_ONLY        ==> name only
/              NAME_ONLY_NO_ENT ==> name only with the extension removed
/           
/
/    
/ OUTPUT CREATED: Assigns a value to a EXISTING macro variable.  You must be 
/   sure that the variable exists, probably makeing a GLOBAL macro variable 
/   is the easiest.
/ 
/ MACROS CALLED: none
/
/ EXAMPLE CALL:
/  in open code
/  
/  %global pgmpath;
/  %jkfn(mvar=pgmpath,style=fullpath)
/
/   
/==============================================================================
/ CHANGE LOG:
/
/ MODIFIED BY:
/ DATE:
/ MODID: JHK001
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK002
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK003
/ DESCRIPTION:
/============================================================================*/
%macro jkfn(mvar = SYSPARM,
           style = SYSPARM);


   %let style = %upcase(&style);
   %let mvar  = %upcase(&mvar);

   %local _j_k_t_m;
   %global syssesid;

   /*
   / It appears that when a display manages sessing is running
   / the GLOBAL macro variables SYSSESID has the value SAS. When
   / display manager is not running the this variable does not
   / exist.  I will using this to determine if the program is running
   / INTERACTIVE, or non-interactive, i.e dropped on the SAS icon or
   / run from the command line in a terminal session.
   /------------------------------------------------------------------*/

   %if &syssesid^= %then %do;
      %let _j_k_t_m = INTERACTIVE;
      %end;
   %else %do;
      proc sql noprint;
         select xpath
            into :_j_k_t_m
            from dictionary.extfiles
            where fileref='_TMP0002';
         quit;
      %end;


   %if &style = SYSPARM %then %do;
      %let &mvar = %sysget(LOGNAME):&_j_k_t_m;
      %end;
   %else %if &style = FULLPATH %then %do;
      %let &mvar = &_j_k_t_m;
      %end;
   %else %if &style = FULLPATH_NO_EXT %then %do;
      %let &mvar = %substr(&_j_k_t_m,1,%index(&_j_k_t_m,.)-1);
      %end;
   %else %if &style = NAME_ONLY %then %do;
      %let _j_k_t_m = %sysfunc(reverse(&_j_k_t_m));
      %let _j_k_t_m = %substr(&_j_k_t_m,1,%index(&_j_k_t_m,/)-1);
      %let &mvar   = %sysfunc(reverse(&_j_k_t_m));
      %end;
   %else %if &style = NAME_ONLY_NO_EXT %then %do;
      %let _j_k_t_m = %sysfunc(reverse(&_j_k_t_m));
      %let _j_k_t_m = %substr(&_j_k_t_m,1,%index(&_j_k_t_m,/)-1);
      %let _j_k_t_m = %sysfunc(reverse(&_j_k_t_m));
      %let &mvar    = %substr(&_j_k_t_m,1,%index(&_j_k_t_m,.)-1);
      %end;
   
   %put NOTE: &mvar = &&&mvar;

   %mend;
                                                                                                                                                                                                                                                                                                                                                                                                 /users/d33/jf97633/sas_y2k/macros/jkgettf.sas                                                       0100664 0045717 0002024 00000006007 06463421127 0021672 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ PROGRAM NAME: jkgettf.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE: Used to prepare titles and footnotes, extracted from
/   the TITLES system, for use with the standard macros %DTAB and %AETAB
/
/
/ SAS VERSION: 6.12 (UNIX)
/
/ CREATED BY: John Henry King
/
/ DATE: SEP1997
/
/ INPUT PARAMETERS:
/
/   _left = 1 2  This parameter is used to provide a way to assign the HLLEFT
/                global macro variable that is used by DTAB and AETAB.
/ 
/
/
/ OUTPUT CREATED:
/   global macro variables
/
/ MACROS CALLED:
/
/
/==============================================================================
/ CHANGE LOG:
/
/ MODIFIED BY:
/ DATE:
/ MODID: JHK001
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK002
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK003
/ DESCRIPTION:
/============================================================================*/

%macro jkgettf(_left=1 2);

   %global hl0 hl1 hl2 hl3 hl4 hl5 hl6 hl7 hl8 hl9 hl10
           hl11 hl12 hl13 hl14 hl15;

   %global hlright hlleft hlcont;

   %global fnote0  fnote1  fnote2  fnote3  fnote4  fnote5
           fnote6  fnote7  fnote8  fnote9  fnote10 fnote11
           fnote12 fnote13 fnote14 fnote15;

   %global findt0  findt1  findt2  findt3  findt4  findt5
           findt6  findt7  findt8  findt9  findt10 findt11
           findt12 findt13 findt14 findt15;

   %global enote0 enote1 enote2 enote3 enote4 enote5
                  enote6 enote7 enote8 enote9 enote10;


   %let hlleft = &_left;
   %let hl0    = 0;
   %let fnote0 = 0;
   %let enote0 = 0;

   data _null_;

      set
         sashelp.vtitle
         end = eof;

      select(type);
         when('T') do;
            hl0 + 1;
            call symput('hl'   ||left(put(number,f2.)) , text);
            end;
         when('F') do;
            if index(text,'ff'x) then do;
               enote0 + 1;
               call symput('enote'||left(put(enote0,f2.)) , trim(text));
               end;
            else do;
               fnote0 + 1;
               call symput('fnote'||left(put(number,f2.)) , trim(text));
               end;
            end;
         otherwise;
         end;

      if eof then do;
         call symput('enote0' , trim(left(put(enote0,f2.))));
         call symput('hl0'    , trim(left(put(hl0   ,f2.))));
         call symput('fnote0' , trim(left(put(fnote0,f2.))));
         end;

      run;

   %local i;

   %put NOTE: --------------------------------------------------------;
   %put NOTE: The following macro variables have been set.;
   %put %str(     ) HLLEFT = &hlleft;

   %do i = 0 %to &hl0;
      %put %str(     ) HL&i = %bquote(&&hl&i);
      %end;
   %do i = 0 %to &fnote0;
      %put %str(     ) FNOTE&i = %bquote(&&fnote&i);
      %end;
   %do i = 0 %to &enote0;
      %put %str(     ) ENOTE&i = %bquote(&&enote&i);
      %end;;
   %put NOTE: --------------------------------------------------------;

   %mend jkgettf;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         /users/d33/jf97633/sas_y2k/macros/jkhppcl.sas                                                       0100664 0045717 0002024 00000026026 06325705561 0021676 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ PROGRAM NAME: jkhppcl.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE: HPPCL printer driver for SAS.
/
/ SAS VERSION: 6.12
/
/ CREATED BY: Jim Comer.
/
/ DATE: 1992 perhaps.
/
/ INPUT PARAMETERS:
/
/   cpi     = characters per inch
/   lpi     = lines per inch
/   margins = margin definition
/   layout  = page orientation LANDSCAPE or PORTRAITE
/   mode    = used to turn off macro variables for testing purposes.
/
/ Jim wrote paper documention for the that may still be available.
/ 
/ OUTPUT CREATED: Global macro variables.
/
/    FORMCHAR HOME BS ULON ULOFF ITALIC UPRIGHT NOBOLD BOLD
/    SUBON SUBOFF SUPON SUPOFF SETUP XLPI
/
/ MACROS CALLED: NONE
/
/ EXAMPLE CALL:
/
/   %jkhppcl(cpi=12,lpi=6,layout=portrait)
/
/==============================================================================
/ CHANGE LOG:
/
/ MODIFIED BY: John Henry King
/ DATE: 1992
/ MODID: 
/ DESCRIPTION: Changed the name and copied to standard macro library for use
/   with standard macros.
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK002
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK003
/ DESCRIPTION:
/============================================================================*/

%MACRO JKHPPCL(PAGEDEF =,
                   CPI =,
                   LPI =,
               MARGINS =,
                LAYOUT =,
                  MODE =);

   %GLOBAL FORMCHAR HOME BS ULON ULOFF ITALIC UPRIGHT NOBOLD BOLD
           SUBON SUBOFF SUPON SUPOFF SETUP XLPI;

   /*
   / establish default values 
   /----------------------------------*/

   %LET NCPI   = 12;
   %LET NLPI   = 6;
   %LET CMAR   = A;
   %LET ORIENT = PORTRAIT;

   /*
   / parse pagedef specification to get lpi, margins and layout 
   /---------------------------------------------------------------*/

   %IF %LENGTH(&PAGEDEF) > 0 %THEN %DO;
      %LET PAGEDEF = %UPCASE(&PAGEDEF);

      %LET CHEK1   = %SUBSTR(&PAGEDEF,1,1);
      %IF       &CHEK1 = X OR &CHEK1 = Y %THEN %LET CMAR = B;
      %ELSE %IF &CHEK1 = Z               %THEN %LET CMAR = C;

      %LET CHEK1 = %SUBSTR(&PAGEDEF,2,1);
      %IF       &CHEK1 = P %THEN %LET ORIENT = PORTRAIT;
      %ELSE %IF &CHEK1 = L %THEN %LET ORIENT = LANDSCAPE;

      %LET TLPI = %SUBSTR(&PAGEDEF,4,2);
      %IF &TLPI = 6 OR &TLPI = 8 OR &TLPI = 9 OR &TLPI = 10
         %THEN %LET NLPI = &TLPI;

      %END;

   %IF %LENGTH(&CPI) > 0 %THEN %DO;
      %IF &CPI = 10 OR &CPI = 12 OR &CPI = 17 %THEN %LET NCPI = &CPI;
      %ELSE %PUT INVALID CPI SPECIFICATION - USING DEFAULT VALUES;
      %END;

   %IF %LENGTH(&LPI) > 0 %THEN %DO;
      %IF &LPI = 6 OR &LPI=8 OR &LPI=9 OR &LPI=10 %THEN %LET NLPI = &LPI;
      %ELSE %PUT INVALID LPI SPECIFICATION - USING DEFAULT VALUES;
      %END;

   %IF %LENGTH(&MARGINS) > 0 %THEN %DO;
      %LET MARGINS = %UPCASE(&MARGINS);
      %IF &MARGINS = A OR &MARGINS = B OR &MARGINS = C OR &MARGINS = D 
         %THEN %LET CMAR = &MARGINS;
      %ELSE %PUT INVALID MARGINS SPECIFICATION - USING DEFAULT VALUES;
      %END;

   %IF %LENGTH(&LAYOUT)  > 0 %THEN %DO;
      %LET LAYOUT = %UPCASE(&LAYOUT);
      %IF &LAYOUT = LANDSCAPE OR &LAYOUT = PORTRAIT 
         %THEN %LET ORIENT = &LAYOUT;
      %ELSE %PUT INVALID LAYOUT SPECIFICATION - USING DEFAULT VALUES;
      %END;

   %LET FORMCHAR='B3C4DAC2BFC3C5B4C0C1D9BACD7CC42F5C1B1A01'x;
   %LET BS      = %STR('1B26'x 'a-1C');
   %LET ULON    = %STR('1B26'x 'dD');
   %LET ULOFF   = %STR('1B26'x 'd@');
   %LET ITALIC  = %STR('1B'x '(s1S' '1B'x ')s1S');
   %LET UPRIGHT = %STR('1B'x '(s0S' '1B'x ')s0S');
   %LET NOBOLD  = %STR('1B'x '(s0B' '1B'x ')s0B');
   %LET BOLD    = %STR('1B'x '(s3B' '1B'x ')s3B');

   %IF       &NLPI =  6 %THEN %LET XLPI = %STR('1B26'x 'l8C');
   %ELSE %IF &NLPI =  8 %THEN %LET XLPI = %STR('1B26'x 'l6C');
   %ELSE %IF &NLPI = 10 %THEN %LET XLPI = %STR('1B26'x 'l5C');  * ACTUALLY 9.6 LPI ;

   %LET SUPON  = %STR('0E1B2A'x 'p' '2D'x '15Y');
   %LET SUBON  = %STR('0E1B2A'x 'p' '2B'x '15Y');
   %LET SUPOFF = %STR('1B2A'x 'p' '2B'x '15Y' '0F'x);
   %LET SUBOFF = %STR('1B2A'x 'p' '2D'x '15Y' '0F'x);

   %IF       &ORIENT = PORTRAIT  %THEN %LET XLAYOUT = %STR('1B26'x 'l0O');
   %ELSE %IF &ORIENT = LANDSCAPE %THEN %LET XLAYOUT = %STR('1B26'x 'l1O');

   %IF       &NCPI = 10 %THEN %LET PITCH = %STR('1B'x '(s10H' '1B'x ')s16.66H');
   %ELSE %IF &NCPI = 12 %THEN %LET PITCH = %STR('1B'x '(s12H' '1B'x ')s16.66H'); 
   %ELSE %IF &NCPI = 17 %THEN %LET PITCH = %STR('1B'x '(s16.66H' '1B'x ')s16.66H');

   /*
   / set margins 
   /---------------------------*/

   %LET LNUM =; 
   %LET RNUM =; 
   %LET TNUM =; 
   %LET BNUM =;

   %if "&ORIENT"="PORTRAIT" %then %do;

      %IF &CMAR = A AND &ORIENT=PORTRAIT %THEN %DO;
         %IF       &NLPI =  6 %THEN %DO; %LET TNUM = 4; %LET BNUM = 55; %END;
         %ELSE %IF &NLPI =  8 %THEN %DO; %LET TNUM = 7; %LET BNUM = 73; %END;
         %ELSE %IF &NLPI = 10 %THEN %DO; %LET TNUM = 7; %LET BNUM = 86; %END;
 
         %IF       &NCPI = 10 %THEN %DO; %LET RNUM =  72; %LET LNUM = 11; %END;
         %ELSE %IF &NCPI = 12 %THEN %DO; %LET RNUM =  86; %LET LNUM = 15; %END;
         %ELSE %IF &NCPI = 17 %THEN %DO; %LET RNUM = 119; %LET LNUM = 22; %END;
         %END;
   
      %else %IF &CMAR = B %THEN %DO;
         %IF       &NLPI =  6 %THEN %DO; %LET TNUM = 1; %LET BNUM =  61; %END;
         %ELSE %IF &NLPI =  8 %THEN %DO; %LET TNUM = 3; %LET BNUM =  80; %END;
         %ELSE %IF &NLPI = 10 %THEN %DO; %LET TNUM = 2; %LET BNUM =  96; %END;
 
         %IF       &NCPI = 10 %THEN %DO; %LET RNUM =  76; %LET LNUM = 5; %END;
         %ELSE %IF &NCPI = 12 %THEN %DO; %LET RNUM =  93; %LET LNUM = 7; %END;
         %ELSE %IF &NCPI = 17 %THEN %DO; %LET RNUM = 128; %LET LNUM = 8; %END;
         %END;
   
      %else %IF &CMAR = C %THEN %DO;
         %IF       &NLPI =  6 %THEN %DO; %LET TNUM = 6; %LET BNUM = 59; %END;
         %ELSE %IF &NLPI =  8 %THEN %DO; %LET TNUM = 9; %LET BNUM = 77; %END;
         %ELSE %IF &NLPI = 10 %THEN %DO; %LET TNUM = 9; %LET BNUM =108; %END;
 
         %IF       &NCPI = 10 %THEN %DO; %LET RNUM =  80; %LET LNUM = 10; %END;
         %ELSE %IF &NCPI = 12 %THEN %DO; %LET RNUM =  96; %LET LNUM = 12; %END;
         %ELSE %IF &NCPI = 17 %THEN %DO; %LET RNUM = 133; %LET LNUM = 18; %END;
         %END;
   
      %else %IF &CMAR = D %THEN %DO;
         %IF       &NLPI =  6 %THEN %DO; %LET TNUM = 1; %LET BNUM =  61; %END;
         %ELSE %IF &NLPI =  8 %THEN %DO; %LET TNUM = 1; %LET BNUM =  88; %END;
         %ELSE %IF &NLPI = 10 %THEN %DO; %LET TNUM = 1; %LET BNUM = 120; %END;
   
         %IF       &NCPI = 10 %THEN %DO; %LET RNUM =  80; %LET LNUM =  0; %END;
         %ELSE %IF &NCPI = 12 %THEN %DO; %LET RNUM =  96; %LET LNUM =  0; %END;
         %ELSE %IF &NCPI = 17 %THEN %DO; %LET RNUM = 133; %LET LNUM =  0; %END;
         %END;
      %end;
 
   %else %if "&orient"="LANDSCAPE" %then %do;
   
      %IF &CMAR = A %THEN %DO;
         %IF       &NLPI =  6 %THEN %DO; %LET TNUM =  8; %LET BNUM = 37; %END;
         %ELSE %IF &NLPI =  8 %THEN %DO; %LET TNUM = 11; %LET BNUM = 50; %END;
         %ELSE %IF &NLPI = 10 %THEN %DO; %LET TNUM = 14; %LET BNUM = 58; %END;
   
         %IF       &NCPI = 10 %THEN %DO; %LET RNUM = 100; %LET LNUM = 10; %END;
         %ELSE %IF &NCPI = 12 %THEN %DO; %LET RNUM = 115; %LET LNUM =  9; %END;
         %ELSE %IF &NCPI = 17 %THEN %DO; %LET RNUM = 167; %LET LNUM = 18; %END;
         %END;
   
      %else %IF &CMAR = B %THEN %DO;
         %IF       &NLPI =  6 %THEN %DO; %LET TNUM = 2; %LET BNUM = 46; %END;
         %ELSE %IF &NLPI =  8 %THEN %DO; %LET TNUM = 5; %LET BNUM = 57; %END;
         %ELSE %IF &NLPI = 10 %THEN %DO; %LET TNUM = 6; %LET BNUM = 71; %END;
   
         %IF       &NCPI = 10 %THEN %DO; %LET RNUM = 103; %LET LNUM = 7; %END;
         %ELSE %IF &NCPI = 12 %THEN %DO; %LET RNUM = 123; %LET LNUM = 5; %END;
         %ELSE %IF &NCPI = 17 %THEN %DO; %LET RNUM = 174; %LET LNUM = 9; %END;
         %END;
   
      %else %IF &CMAR = C %THEN %DO;
         %IF       &NLPI =  6 %THEN %DO; %LET TNUM = 7; %LET BNUM = 42; %END;
         %ELSE %IF &NLPI =  8 %THEN %DO; %LET TNUM = 9; %LET BNUM = 57; %END;
         %ELSE %IF &NLPI = 10 %THEN %DO; %LET TNUM =11; %LET BNUM = 74; %END;
   
         %IF       &NCPI = 10 %THEN %DO; %LET RNUM = 110; %LET LNUM = 12; %END;
         %ELSE %IF &NCPI = 12 %THEN %DO; %LET RNUM = 132; %LET LNUM = 14; %END;
         %ELSE %IF &NCPI = 17 %THEN %DO; %LET RNUM = 183; %LET LNUM = 22; %END;
         %END;
   
      %else %IF &CMAR = D %THEN %DO;
         %IF       &NLPI =  6 %THEN %DO; %LET TNUM = 0; %LET BNUM = 49; %END;
         %ELSE %IF &NLPI =  8 %THEN %DO; %LET TNUM = 0; %LET BNUM = 66; %END;
         %ELSE %IF &NLPI = 10 %THEN %DO; %LET TNUM = 0; %LET BNUM = 85; %END;
   
         %IF       &NCPI = 10 %THEN %DO; %LET RNUM = 110; %LET LNUM = 1; %END;
         %ELSE %IF &NCPI = 12 %THEN %DO; %LET RNUM = 132; %LET LNUM = 1; %END;
         %ELSE %IF &NCPI = 17 %THEN %DO; %LET RNUM = 183; %LET LNUM = 1; %END;
         %END;
      %end;
   

   %LET LMAR =;
   %LET RMAR =;
   %LET TMAR =;
   %LET BMAR =;

   %IF %LENGTH(&LNUM) > 0 %THEN %LET LMAR = %STR('1B26'x "a&LNUM.L");
   %IF %LENGTH(&RNUM) > 0 %THEN %LET RMAR = %STR('1B26'x "a&RNUM.M");
   %IF %LENGTH(&TNUM) > 0 %THEN %LET TMAR = %STR('1B26'x "l&TNUM.E");
   %IF %LENGTH(&BNUM) > 0 %THEN %LET BMAR = %STR('1B26'x "l&BNUM.F");

   %let hrow = 1;
   %let hcol = &lnum;
   %LET HOME    = %STR('1B26'x "a&hrow.R" '1B26'x "a&hcol.C");

   %local martxt;
   %if       &CMAR = A %THEN %let martxt = 1.5  inches binding edge, 1 inch on all others;
   %else %if &CMAR = B %THEN %let martxt = .75 inches binding edge, .5 inches on all others;
   %else %if &CMAR = C %THEN %let martxt = 1.25 inches on top and left sides;
   %else %if &CMAR = D %THEN %let martxt = None;


   %LET SETUP = %STR(
      RETAIN _INIT_ 0;
      IF ^_INIT_ THEN DO;
         _INIT_ = 1;
         PUT +1 &XLAYOUT '1B'x '(10U' '1B'x ')10U'
                      '1B'x '(s0P' '1B'x ')s0P'
             &PITCH
                      '1B'x '(s3T' '1B'x ')s3T'
             &XLPI '1B'x '9'
             &LMAR &RMAR &TMAR &BMAR;

         PUT +5 'This output file contains HPPCL escape sequences';
         put +5 "LAYOUT=&LAYOUT";
         put +5 "CPI=&cpi";
         put +5 "LPI=&lpi";
         put +5 "Margins=&cmar";
         put +5 "&martxt";

         PUT _PAGE_@;
         END;
);


   %PUT;
   %PUT;
   %PUT %str(HPPCL macro variables are now available);
   %PUT;
   %PUT %str(   CPI     = ) &NCPI;
   %PUT %str(   LPI     = ) &NLPI;
   %PUT %str(   Margins = ) &CMAR;
   %IF &CMAR = A %THEN %PUT %STR(   1.5  inches binding edge, 1 inch on all others);
   %IF &CMAR = B %THEN %PUT %STR(    .75 inches binding edge, .5 inches on all others);
   %IF &CMAR = C %THEN %PUT %STR(   1.25 inches on top and left sides);
   %IF &CMAR = D %THEN %PUT %STR(   None);
   %PUT %STR(   Layout  = ) &ORIENT;
   %PUT;
   %PUT;

   %IF %UPCASE(&MODE)=TEST %THEN %DO;
      %LET HOME=;
      %LET BS=;
      %LET ULON=;
      %LET ULOFF=;
      %LET ITALIC=;
      %LET UPRIGHT=;
      %LET NOBOLD=;
      %LET BOLD=;
      %LET SUBON=;
      %LET SUBOFF=;
      %LET SUPON=;
      %LET SUPOFF=;
      %END;
   %MEND JKHPPCL;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          /users/d33/jf97633/sas_y2k/macros/jklyot01.sas                                                      0100664 0045717 0002024 00000015372 06325705571 0021723 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ PROGRAM NAME: jklyot01.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE: Used by standard macros to set macro variables associated
/   with the page layout.  Not useful outside the context of the standard 
/   macros.
/
/ SAS VERSION: 6.12
/
/ CREATED BY: John Henry King
/ DATE: 1994
/
/ INPUT PARAMETERS: This macro has no parameters.  The macro uses macro
/   variables that are know to be available within the standard macros
/   when the macro is called.
/   
/   LAYOUT
/   DISP
/
/ OUTPUT CREATED: The following global macro variables have their values
/   altered.
/   
/   LS
/   PS
/   FILE_EXT
/   FILE_DSP
/   HPPCL
/   DASHCHR
/
/
/ MACROS CALLED: none
/
/ EXAMPLE CALL: %jklyot01;
/==============================================================================
/ CHANGE LOG:
/
/ MODIFIED BY:
/ DATE:
/ MODID: JHK001
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK002
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK003
/ DESCRIPTION:
/============================================================================*/

%macro jklyot01;
   /*
   / Set up the page size based on user input.  
   /-------------------------------------------------------------------*/

   %if "&layout" = "DEFAULT" %then %do;
      %let dashchr  = '-';
      %let file_ext = LIS;
      %let file_dsp = &disp;
      %let hppcl    = 0;
      %let ls       = 132;
      %let ps       = 60;       
      %end;

 
   %else %if %index(&layout,USP) %then %do;

      /*
      / Portrait
      / options for use with US PSPRINT postscript command.
      /-----------------------------------------------------*/

      %let dashchr  = '_';;
      %let file_ext = %substr(&layout,3,3);
      %let file_dsp = &disp;
      %let hppcl    = 0;

      %if       "&layout"="USP09" %then %do;
         %let ls = 80;
         %let ps = 56;
         %end;
      %else %if "&layout"="USP08" %then %do;
         %let ls = 90;
         %let ps = 61;
         %end;
      %else %if "&layout"="USP07" %then %do;
         %let ls = 103;
         %let ps = 77;
         %end;
      %else %if "&layout"="USP06" %then %do;
         %let ls = 121;
         %let ps = 89;
         %end;
      %else %if "&layout"="USP10" %then %do;
         %let ls = 72;
         %let ps = 50;
         %end;
      %end;

   %else %if %index(&layout,USL) %then %do;

      /*
      / Landscape
      / options for use with US PSPRINT postscript command.
      /-----------------------------------------------------*/

      %let dashchr = '_';
      %let file_ext = %substr(&layout,3,3);
      %let file_dsp = &disp;
      %let hppcl    = 0;

      %if       "&layout"="USL09" %then %do;
         %let ls = 120;
         %let ps = 36;
         %end;
      %else %if "&layout"="USL08" %then %do;
         %let ls = 135;
         %let ps = 40;
         %end;
      %else %if "&layout"="USL07" %then %do;
         %let ls = 153;
         %let ps = 50;
         %end;
      %else %if "&layout"="USL06" %then %do;
         %let ls = 179;
         %let ps = 59;
         %end;
      %else %if "&layout"="USL10" %then %do;
         %let ls = 108;
         %let ps = 33;
         %end;
      %end;

   %else %if %index(&layout,UKP) %then %do;

      %let dashchr  = '_';
      %let file_ext = %substr(&layout,3,3);
      %let file_dsp = &disp;
      %let hppcl    = 0;

      %if       "&layout"="UKP09" %then %do;
         %let ls = 81;
         %let ps = 59;
         %end;
      %else %if "&layout"="UKP08" %then %do;
         %let ls = 93;
         %let ps = 67;
         %end;
      %else %if "&layout"="UKP07" %then %do;
         %let ls = 109;
         %let ps = 77;
         %end;
      %else %if "&layout"="UKP06" %then %do;
         %let ls = 124;
         %let ps = 89;
         %end;
      %else %if "&layout"="UKP10" %then %do;
         %let ls = 73;
         %let ps = 53;
         %end;
      %end;

   %else %if %index(&layout,UKL) %then %do;

      %let dashchr = '_';
      %let file_ext = %substr(&layout,3,3);
      %let file_dsp = &disp;
      %let hppcl    = 0;

      %if       "&layout"="UKL09" %then %do;
         %let ls = 119;
         %let ps = 39;
         %end;
      %else %if "&layout"="UKL08" %then %do;
         %let ls = 137;
         %let ps = 45;
         %end;
      %else %if "&layout"="UKL07" %then %do;
         %let ls = 161; 
         %let ps = 52;
         %end;
      %else %if "&layout"="UKL06" %then %do;
         %let ls = 183; 
         %let ps = 59;
         %end;
      %else %if "&layout"="UKL10" %then %do;
         %let ls = 109;
         %let ps = 35;
         %end;
      %end;

   %else %if %index(&layout,PORT) %then %do;
      /* 
      / CPI=10 LPI=06 PS=60 LS=53 
      / CPI=12 LPI=08 PS=71 LS=72 
      / CPI=12 LPI=10 PS=84 LS=72 
      / CPI=17 LPI=08 PS=71 LS=98 
      / CPI=17 LPI=10 PS=85 LS=98 
      /---------------------------------------------*/

      %let dashchr  = 'c4'x;
      %let layout   = PORTRAIT;
      %let file_ext = PCL;

      %if "&disp"="MOD" %then %do;
         %let hppcl    = 0;
         %let file_dsp = MOD;
         %end;
      %else %do;
         %let hppcl    = 1;
         %let file_dsp = MOD;
         %end;

      %if       &cpi=17 %then %let ls=98;
      %else %if &cpi=12 %then %let ls=72;
      %else %if &cpi=10 %then %let ls=60;
      %else %do;
         %let cpi = 17;
         %let  ls = 98;
         %end;
      %if       &lpi=6  %then %let ps=53;
      %else %if &lpi=8  %then %let ps=71;
      %else %if &lpi=10 %then %let ps=85;
      %else %do;
         %let lpi = 10;
         %let ps  = 85;
         %end;
      %end;

   %else %if %index(&layout,LAND) %then %do;
      /* 
      / CPI=12 LPI=10 PS=56 LS=107 
      / CPI=17 LPI=10 PS=56 LS=144
      /-----------------------------------------*/
      
      %let dashchr  = 'C4'x;
      %let layout   = LANDSCAPE;
      %let file_ext = PCL;

      %if "&disp"="MOD" %then %do;
         %let hppcl    = 0;
         %let file_dsp = MOD;
         %end;
      %else %do;
         %let hppcl    = 1;
         %let file_dsp = MOD;
         %end;


      %if       &cpi=17 %then %let ls=144;
      %else %if &cpi=12 %then %let ls=107;
      %else %do;
         %let cpi = 17;
         %let  ls = 144;
         %end;

      %if       &lpi=10 %then %let ps=56;
      %else %do;
         %let lpi = 10;
         %let  ps = 56;
         %end;
      %end;

   %put NOTE: --------------------------------------------------------;
   %put NOTE: JKLYOT01 has assigned the following macro variables.;
   %put NOTE: For LAYOUT=&layout;
   %put NOTE: PS=&ps LS=&ls;
   %put NOTE: DASHCHR=&dashchr;
   %put NOTE: FILE_EXT=&file_ext;
   %put NOTE: HPPCL=&hppcl;
   %put NOTE: --------------------------------------------------------;

   %mend jklyot01;
                                                                                                                                                                                                                                                                      /users/d33/jf97633/sas_y2k/macros/jkpaired.sas                                                      0100664 0045717 0002024 00000015716 06325705577 0022047 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ PROGRAM NAME: jkpaired.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE:
/
/ Use macro JKPAIRED to prepare data for a paired analysis.
/ A paired analysis is one where the treatments are tested 2 at a time.
/ For example for 3 treatments.
/
/   1 vs 2
/   1 vs 3
/   2 vs 3
/
/ This macro was written for the standard macros but can be used in any 
/ program where a paired data set is needed.
/
/ SAS VERSION: 6.12
/
/ CREATED BY: John Henry King
/
/ DATE: 1993
/
/ INPUT PARAMETERS:
/
/ data      = _LAST_
/             Names the input dataset.            
/
/ out       = _PAIRED_
/             Names the output data set.
/
/ by        = <list of variables>
/             BY variables. 
/
/ overall   = YES
/             Specifies that the OUT= data set will have the overall (unpaired)
/             data included also.  For some types of anlalysis, odds rations,
/             from proc freq for example are only approaite for 2x2 tables.  
/             In that case OVERALL=NO should be specified.
/
/ pair      = <numeric treatment variable>
/             Names the variable to pair the data by.  
/
/ _1        = _1
/             Specifies the name of the variable to contain the first paired
/             group variable.
/
/ _2        = _2
/             Specifies the name of the variable to contain the first paired
/             group variable.
/
/ root      = _
/             Provides root name for macro variable arrays used internally
/             by the macro.  This parameter would rarely need to be changed.
/
/ print     = NO 
/             Print the out= data set.
/
/ chkdata   = YES
/             Call macro CHKDATA to verify input to the macro?
/
/ 
/ idname    = Variable name for ID variable.
/
/ id        = Character expression used to assign ID variable.
/
/ sortby    = &_1 &_2
/             By variable list to sort the out= data on.
/
/ sort      = YES
/             Control sorting of out= data set.  By default the data is
/             sorted by &_1 and &_2.
/            
/
/
/ OUTPUT CREATED: The paired dataset.  All variable from original plus
/  the special variables created by the macro.
/
/ MACROS CALLED:
/  May call JKCHKDAT if CHKDATA=YES is specified.
/
/ EXAMPLE CALL:
/
/==============================================================================
/ CHANGE LOG:
/
/ MODIFIED BY:
/ DATE:
/ MODID: JHK001
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK002
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK003
/ DESCRIPTION:
/============================================================================*/

%macro JKPAIRED(data = _LAST_,
               where = ,
                 out = _PAIRED_,
                  by = ,
                pair = ,
                root = _,
                  _1 = _1,
                  _2 = _2,
             overall = YES,
               print = NO,
             chkdata = YES,
              idname = ,
                  id = ,
              sortby = ,
                sort = YES);

   %local temp1;
   %let temp1 = _1_&sysindex;

   %local i j k;

   %let chkdata = %upcase(&chkdata);
   %let print   = %upcase(&print);

   %let data    = %upcase(&data);
   %let out     = %upcase(&out);
   %let by      = %upcase(&by);
   %let pair    = %upcase(&pair);
   %let sortby  = %upcase(&sortby);
   %let sort    = %upcase(&sort);
   %let overall = %upcase(&overall);
 
   %if %length(&pair)=0 %then %do;
      %put ER!ROR: Macro parameter PAIR must not be null.;
      %goto EXIT;
      %end;


   %if "&chkdata" = "YES" %then %do;
      %jkchkdat(data=&data,vars=&by &pair,return=xrc)

      %if &xrc %then %do;
         %put ER!ROR: Macro JKPAIRED ending due to ER!RORs;
         %goto EXIT;
         %end;

      %end;

   %if %length(&sortby)=0 %then %do;
      %let sortby = &_1 &_2;
      %end;

   %if "&sort"="YES"
      %then %let sort = 1;
      %else %let sort = 0;

   %if "&overall"="YES"
      %then %let overall = 1;
      %else %let overall = 0;

   %if "&print"="YES"
      %then %let print = 1;
      %else %let print = 0;


   /*
   / Sort the input data
   /------------------------------------------------*/
   proc sort 
         data=&data
         (
      %if %length(%nrquote(&where))> 0 %then %do;
         where = (&where)
         %end;
         )
         out=&out;
      by &by &pair;
      run;



   /*
   / Find the unique WAYs of the data.
   /-----------------------------------------------*/

   proc summary data=&data nway;
      by &by;
      class &pair;
      output out=&temp1(drop=_type_ _freq_);
      run;

   /*
   / Transpose the summary output data to have one observation
   / per BY group with the levels of PAIR stored in an array '_CLn'
   /---------------------------------------------------------------*/

   proc transpose data=&temp1 out=&temp1(drop=_name_) prefix=_CL;
      by &by;
      var &pair;
      run;

   /*
   / Now using the values of each observations PAIR variable
   / and the PAIR values array create the pairwise data set.
   /----------------------------------------------------------*/

   data &out;

   /*
   / If there are no BY variables then we need to SET &temp1
   / on _n_=1.  If there are by variables then we need to do
   / a match merge.
   /----------------------------------------------------------*/

   %if %length(&by)=0 %then %do;
      set &out;
      if _n_ = 1 then set &temp1;
      %end;

   %else %do;
      merge &out(in=in1) &temp1(in=in2);
      by &by;
      %end;

      drop _cl: _i_; 

      array _cl[*] _cl:;

      &_1 = 0;
      &_2 = 0;

      %if %length(&idname) > 0 %then %do;
         length &idname $8;
         %end;
 

      /*
      / This link to OUT will output the unpaired data into the data set also.
      / If the desired statistic from proc freq is not approiate for for RxC
      / tables then OVERALL= can be used to restrict that activity.
      /-----------------------------------------------------------------------*/

      %if &overall %then %do;
         link out;
         %end;

      do _i_ = 1 to dim(_cl); 

         if _cl[_i_] = . then continue;

         select;
            when(_cl[_i_] > &pair) do;
               &_1 = &pair;
               &_2 = _cl[_i_];
               link out; 
               end;
            when(_cl[_i_] < &pair) do; 
               &_1 = _cl[_i_];
               &_2 = &pair;
               link out;
               end;
            otherwise;
            end;

         end;
      return;

    OUT:
      %if %length(&idname)>0 %then %do;
         &idname = &id;
         %end;
      output;
      return;
      run;

   proc delete data=&temp1;
      run;

   %if &sort %then %do;
      %if %length(&sortby)>0 %then %do;
         proc sort data=&out;
            by &by &sortby;
            run;
         %end;
      %end;

   %if &print %then %do;
      title5 "DATA=&out OUT from macro JKPAIRED";
      proc print data=&out;
         run;
      title5;
      %end;
 
 %EXIT: 

   %mend JKPAIRED;
                                                  /users/d33/jf97633/sas_y2k/macros/jkprefix.sas                                                      0100664 0045717 0002024 00000003547 06325705604 0022066 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ PROGRAM NAME: jkprefix.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE: Parse the words in a macro variable and add a specified
/   prefix string the each word.
/
/ SAS VERSION: 6.12
/
/ CREATED BY: John Henry King
/
/ DATE: 1992 perhaps.
/
/ INPUT PARAMETERS:
/   string    The string to parse and prefix.
/   
/   prefix    The character to prefix to each word.
/
/   delm =    Specifies the word delimiter.
/
/ OUTPUT CREATED: Returns the new string.
/
/ MACROS CALLED: none
/
/ EXAMPLE CALL: 
/
/   %let new = %prefix(A B C D E, PRE_);
/    
/   Assigns NEW the value: PRE_A PRE_B PRE_C PRE_D PRE_E
/==============================================================================
/ CHANGE LOG:
/
/ MODIFIED BY:
/ DATE:
/ MODID: JHK001
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK002
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK003
/ DESCRIPTION:
/============================================================================*/

%macro jkprefix(string,prefix,delm=%str( ));                     
   %local count word newlist;
   %if "&delm"="" %then %let delm = %str( );
   %let count = 1;                                                     
   %let word  = %scan(&string,&count,&delm);                           
   %do %while("&word"^="");                                        
      %let newlist = &newlist &prefix.&word;                           
      %let count   = %eval(&count + 1);                                
      %let word    = %scan(&string,&count,&delm);                      
      %end;                                                            
   &newlist                                                            
   %mend jkprefix;                                                       
                                                                                                                                                         /users/d33/jf97633/sas_y2k/macros/jkpval04.sas                                                      0100664 0045717 0002024 00000030615 06325705616 0021676 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ PROGRAM NAME: jkpval04.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE: This utility macro is called by SIMSTAT to perform ANOVA
/   on continious variables.  It retrieves the F statistics associated with
/   the analysis.
/
/ SAS VERSION: 6.12 (UNIX)
/
/ CREATED BY: John Henry King
/
/ DATE: FEB1997
/
/ INPUT PARAMETERS:
/
/   data=               Names the data set to be analyzed.
/
/   by=                 List by variables
/
/   tmt=                Treatment variable name
/
/   control=            The stratification variables produces a two way.  
/ 
/   interact=NO         Will the anova include an interaction term.
/                       e.g. INVCD * TMT
/
/   covars=             List of covariables 
/
/   ss=SS3              The sum of square type as per SAS PROC GLM.
/
/   continue=           Names the analysis variables.
/
/   pairwise=0          Boolean, 0=no pairwise 1=pairwise.
/
/   out=                Names the output data set created by the macro.
/
/   print=NO            Print the output data set?
/
/ OUTPUT CREATED: A SAS data set.
/
/ MACROS CALLED:
/
/
/ EXAMPLE CALL:
/==============================================================================
/ CHANGE LOG:
/
/ MODIFIED BY:
/ DATE:
/ MODID: JHK001
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK002
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK003
/ DESCRIPTION:
/============================================================================*/
/*
/
/ Macro JKpval04
/
/ / 
/ If the user requests a pairwise analysis then the macro generates CONTRAST
/ statements, to generate 1 degree of freedom F statistics that are equal to
/ the T test that would be produced by the LSMEANS statement with the PDIFF
/ options.  This is done because the PDIFF p-values are not output into a SAS
/ dataset by the OUT= option on the LSMEANS statement.
/ 
/ Do not use this macro outside the context of macro SIMSTAT.
/
/ Parameter=Default   Description
/ -----------------   ---------------------------------------------------------
/
/
/----------------------------------------------------------------------------*/



%macro jkpval04(data=,
                 out=,
                  by=,
             control=,
                 tmt=,
            interact=NO,
                  ss=SS3,
            continue=,
              covars=,
            pairwise=0,
               print=YES);

   %local anova glm lsm pdf EMS CTL stats tmtlist i j k l _x ptype;
   %let anova   = _1&sysindex;
   %let glm     = _2&sysindex;
   %let lsm     = _3&sysindex;
   %let tmtlist = _4&sysindex;
   %let pdf     = _5&sysindex;
   %let stats   = _6&sysindex;
   %let ems     = _7&sysindex;
   %let ctl     = _8&sysindex;

 
   %let print    = %upcase(&print);
   %let interact = %upcase(&interact);
   %if "&interact"="YES" 
      %then %let interact=|;
      %else %let interact=;

   %let control = %upcase(&control);
   %if "&control"="_ONE_" %then %let control=;

   %if "&covars"="" %then %do;
      %let _x = ;
      %let ptype = ANOVA;
      data &anova;
         set &data(keep=&by &uspatno &tmt &control &continue);
 
         array _1[*] &continue;
         length _vname_ _covar_ $8;
         do _i_ = 1 to dim(_1);
            call vname(_1[_i_],_vname_);
            _y = _1[_i_];

            if _y>.Z then output;

            end;
         drop &continue;
         run;
      %end;
   %else %do;
      %let _x = _x;
      %let ptype = ANCOVA;
      data &anova;
         set &data(keep=&by &uspatno &tmt &control &continue &covars);

         array _1[*] &continue;
         array _2[*] &covars;
         length _vname_ _covar_ $8;
         do _i_ = 1 to dim(_1);
            call vname(_1[_i_],_vname_);
            call vname(_2[_i_],_covar_);
            _y = _1[_i_];
            _x = _2[_i_];
 
            if n(_y,_x)=2 then output;
            end;
         drop &continue &covars;
         run;
      %end;
 
   proc sort data=&anova;
      by &by _vname_ _covar_;
      run;

   data &anova;
      set &anova;
      by &by _vname_ _covar_;

      if first._covar_ then _byid_ + 1;

      run;

   /*
   / We need to know two things for this to work.  One is the total
   / number of treatments in each BY group.  And two the value of TMT=
   / for each of these group.
   /
   / This information is needed to construct the CONTRAST statements and
   / to get them labled properly in the output dataset created by SIMSTAT.
   /
   /------------------------------------------------------------------------*/


   /*
   / This proc summary will return the TMT= values for each BY group.
   /------------------------------------------------------------------------*/
  
   proc summary data=&anova nway missing;
      class _byid_ &by &tmt;
      output out=&tmtlist(drop=_type_ _freq_);
      run;


   /*
   / This data null step is used to creat macro variable array to hold to
   / total number of TMTs per BY group and the values of the TMTs in each.
   /
   /
   / The macro variables are named as follows.
   /
   / _0 The number of unique BY groups.
   /
   / _1_1 ... _1_n
   / _2_1 ... _2_n
   / ...
   / _k_1 ... _k_n
   /
   / Where n is the number of TMTs in each BY group.
   / Where k is the number of BY groups.
   /---------------------------------------------------------------------------*/

   %local _0;
   %let _0 = 0;

   /*
   / Make the array variables LOCAL, I hope this is enough.
   /---------------------------------------------------------------------------*/
   
   %do k = 1 %to 20;
      %do i = 0 %to 20;
         %local _&k._&i; 
         %end;
      %end;

   /*
   / Using the output from PROC SUMMARY above create the macro variable arrays
   /---------------------------------------------------------------------------*/

   data _null_;
      set &tmtlist end=eof;
      by _byid_ &by;

      if first._byid_ then do;
         _1_ = 0;
         end;

      _1_ + 1;

      length _name_ $8;
      _name_ = '_'||trim(left(put(_byid_,8.)))||'_'||left(put(_1_,8.));
      
      call symput(_name_,trim(left(put(&tmt,8.))));

      if last._byid_ then do;
         _name_ = '_'||trim(left(put(_byid_,8.)))||'_0';

         call symput(_name_,trim(left(put(_1_,8.))));
         end;

      if eof then do;
         call symput('_0',trim(left(put(_byid_,8.))));
         end;
      run;

   /*
   / Look at the values of the variables just created.
   /-----------------------------------------------------------*/

   /*
   %do k = 1 %to &_0;
      %do i = 0 %to &&_&k._0;
         %put NOTE: _&k._&i = &&_&k._&i;
         %end;
      %end;
   */


   /*
   / Now call GLM once for each BY group, using the macro variable
   / arrays to generate the CONTRAST statements.
   /----------------------------------------------------------------*/

   %do k = 1 %to &_0;
      proc glm 
            noprint 
            order   = internal
            data    = &anova
               (
                where=(_byid_=&k)
               ) 
            outstat = &GLM
            ;

         by &by _vname_ _covar_;

         class &control &tmt;
         model _y = &control &interact &tmt  &_x / &ss;

      /*
      / If the pairwise analysis was requested then this bit of code
      / will generate the contrast statements needed to produce the same
      / p-values as the PDIFF option on the LSMEANS statement.
      /
      / The array variables that were created above are used to determine
      / the number of coefients and the label for the contrast.
      /--------------------------------------------------------------------*/

      %if &pairwise %then %do;
         %do i = 1 %to &&_&k._0 -1;
            %do j = &i+1 %to &&_&k._0;
 
               contrast "%str(P)&&_&k._&i%str(_)&&_&k._&j" &tmt
 
               %do l = 1 %to &i-1;
                  0
                  %end;
               1
               %do l = &i+1 %to &j-1;
                  0
                  %end;
               -1;
               %end;
            %end;
         %end;
 
         lsmeans &tmt / out=&LSM;
         run;
         quit;

      %if "&print"="YES" %then %do;
         title5 "DATA=GLM(&glm) the outstat data set";
         proc print data=&glm;
            run;
         title5;
         %end;

 
      /*
      / Use transpose to arrange the CONTROLing variable p-value
      /---------------------------------------------------------------*/
      %if "&control" ^= "" %then %do;
         proc transpose
               data = &GLM
                  (
                   where  = (_source_ = "&control")
                  )
               out  = &CTL
                  (
                   rename = (_x_x1 = PR_CNTL)
                  )

               prefix = _x_x
               ;

            by &by _vname_ _covar_;
            var prob;
            run;

         %if "&print"="YES" %then %do;
            title5 "DATA=CTL(&ctl) the pvalue for the controlling variable";
            proc print data=&ctl;
               run;
            title5;
            %end;
         %end;


      /*
      / Use transpose to arrange the ERROR Sum of square and DF
      /---------------------------------------------------------------*/

      proc transpose 
            data = &GLM
               (
                where  = (_type_ = 'ERROR')
               )
            out  = &EMS 
            ;
         by &by _vname_ _covar_;
         id _source_;
         var df ss;  
         run;

      %if "&print"="YES" %then %do;
         title5 "DATA=EMS(&EMS) the transposed outstat dataset";
         proc print data=&ems;
            run;
         title5;
         %end;      

      proc transpose data=&ems out=&ems(drop=_name_);
         by &by _vname_ _covar_;
         id _name_;
         var error;
         run;

      %if "&print"="YES" %then %do;
         title5 "DATA=EMS(&EMS) the transposed outstat dataset";
         proc print data=&ems;
            run;
         title5;
         %end;




      /*
      / Use transpose to arrange the p-values for the SIMSTAT output 
      / dataset.
      /---------------------------------------------------------------*/

      proc transpose 
            data = &GLM
               (
                where  = (_type_ = 'CONTRAST' | _source_="&tmt")
               )
            out  = &PDF 
               (
                drop   = _name_
                rename = (&tmt = PROB)
               );

         by &by _vname_ _covar_;
         id _source_;
         var prob;
         run;


      %if "&print"="YES" %then %do;
         title5 "DATA=PDF(&pdf) the transpose outstat dataset";
         proc print data=&pdf;
            run;
         title5;
         %end;

      /*
      / Now merge the LSMEANS with the p-values
      /----------------------------------------------------------------*/

      data &stats&k;
         merge 
            &PDF
            &EMS
               (
                rename=(df=dfe ss=sse)
               )

         %if "&control" ^= "" %then %do;
            &CTL
               (
                keep = &by _vname_ _covar_ pr_cntl
               )
            %end;

            &LSM
               (
                drop   = _name_
                rename = (lsmean=LSM stderr=LSMSE)
               );

         by &by _vname_ _covar_;

         mse     = sse / dfe;
         rootmse = sqrt(mse);

         length _ptype_ $8;
         retain _ptype_ "&ptype"; 
         run;

      %if "&print"="YES" %then %do;
         title5 "DATA=STATS&k(&stats&k) the processed stats and lsm data";
         proc print data=&stats&k;
            run;
         title5;
         %end;

      %end;


   /*
   / Delete the temporary datasets
   /---------------------------------------------------------------*/

   proc delete data=&glm &lsm &ems &pdf &anova &tmtlist;
      run;

   /*
   / Put the individual datasets together
   /---------------------------------------------------------------*/

   data &out; 
      set
      %do k = 1 %to &_0;
         &stats.&k
         %end;
      ;
      by &by _vname_ _covar_;
      run;

   proc sort data=&out;
      by &by _vname_ &tmt;
      run;


   /*
   / Delete those temporary datasets
   /---------------------------------------------------------------*/

   proc delete data=
      %do k = 1 %to &_0;
         &stats.&k
         %end;
      ;
      run;


   %if "&print"="YES" %then %do;
      title5 "DATA=&out ANOVA Pvalues";
      proc contents data=&out;
         run;
      proc print data=&out;
         run;
      title5;
      %end; 

   %mend jkpval04;
 continue=,
              covars=,
            pairwise=0,
               print=YES);

   %local anova glm lsm pdf /users/d33/jf97633/sas_y2k/macros/jkpval05.sas                                                      0100664 0045717 0002024 00000025642 06325705626 0021704 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ PROGRAM NAME: jkpval05.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE: Macro used internally by standard macros to do various
/   statistical analysis using PROC FREQ.
/
/ SAS VERSION: 6.12
/
/ CREATED BY: John Henry King
/
/ DATE: FEB1997
/
/ INPUT PARAMETERS:
/
/ DATA=               Names the input data set.
/
/ OUT=                Names the output data set created by the macro.
/
/ BY=                 List of by variables
/
/ UNIQUEID=           UNIQUEID
/
/ ID=                 Names the variable that defines the pair groups when a
/                     pairwise analysis is requested.
/
/ CONTROL=            Names the stratification variable.
/
/ SCORES=             Specifies SCORES option for PROC FREQ.
/
/ TMT=                Treatment variable name.
/
/ RESPONSE=           Names the response variable that will form the COLUMNS of
/                     the frequency table.
/
/ WEIGHT=             Names the variable that contains the frequency counts
/                     needed to form the table. Used in WEIGHT statement in
/                     PROC FREQ.
/
/ DISCRETE=           List of 1 byte character discrete variables to be
/                     analyzed.
/
/ P_VALUE=            Specifices the type of p-value requested by the user.
/
/ VARTYPE=            Identifies the type of response variable. Discrete vs
/                     continious.
/
/ PAIRWISE=0          Boolean for pairwise analysis. 0=not 1=pairwise.
/
/ PRINT=NO            Print the output data set?
/
/ TMTDIFF=            Specifies the which value of TMT is the differences for a
/                     paired t-test. Used only when P_VALUE=PAIRED.
/
/ OUTPUT CREATED:
/ MACROS CALLED:
/ EXAMPLE CALL:
/==============================================================================
/ CHANGE LOG:
/
/ MODIFIED BY: John Henry King
/ DATE: 27FEB1997
/ MODID: JHK001
/ DESCRIPTION: Added option to allow PROC FREQ statement options  
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK002
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK003
/ DESCRIPTION:
/============================================================================*/

%macro jkpval05(data=,
                 out=,
                  by=,
                  id=,
            uniqueid=,
             control=,
                 tmt=,
             tmtdiff=,
            response=,
              weight=,
              scores=TABLE,
             p_value=,
             vartype=,
            pairwise=0,
               print=NO,
            freqopts=NOPRINT); /* JHK001 */

      %local temp1 temp2;
      %let temp1 = _1_&sysindex;
      %let temp2 = _2_&sysindex;

      %let p_value = %upcase(&p_value);
      %let vartype = %upcase(&vartype);
      %let control = %upcase(&control);
      %let print   = %upcase(&print);

      %if "&print"="YES" | "&print"="1"
         %then %let print = 1;
         %else %let print = 0;

      /*
      / Set up PROC FREQ table statement options and output statement
      / options.  If the controlling variable is specified then the
      / pvalue will be CMH
      /------------------------------------------------------------------*/

      %local outopt probvr tblopt ptype l_var u_var onlypvar;


      %if "&vartype"="DISCRETE" %then %do;
         %if "&p_value"="CMH" | "&p_value"="CMHGA" %then %do;
            %let ptype    = CMHGA;
            %let tblopt   = CMH SCORES=&scores;
            %let outopt   = CMHGA;
            %let probvr   = P_CMHGA;
            %let onlypvar = 1;
            %end;
         %else %if "&p_value"="CMHRMS" %then %do;
            %let ptype    = CMHRMS;
            %let tblopt   = CMH2 SCORES=&scores;
            %let outopt   = CMHRMS;
            %let probvr   = P_CMHRMS;
            %let onlypvar = 1;
            %end;
         %else %if "&p_value"="CMHCOR" %then %do;
            %let ptype    = CMHCOR;
            %let tblopt   = CMH1 SCORES=&scores;
            %let outopt   = CMHCOR;
            %let probvr   = P_CMHCOR;
            %let onlypvar = 1;
            %end;
         %else %if "&p_value"="LGOR" %then %do;
            %let ptype    = LGOR;
            %let tblopt   = CMH;
            %let outopt   = LGOR;
            %let probvr   = _LGOR_;
            %let u_var    = U_LGOR;
            %let l_var    = L_LGOR;
            %let onlypvar = 0;
            %end;
         %else %if "&p_value"="CHISQ" %then %do;
            %let ptype    = CHISQ;
            %let tblopt   = CHISQ;
            %let outopt   = PCHI;
            %let probvr   = P_PCHI;
            %let onlypvar = 1;
            %end;
         %else %if "&p_value"="EXACT" %then %do;
            %let ptype    = EXACT;
            %let tblopt   = EXACT;
            %let outopt   = EXACT;
            %let probvr   = _EXACT_;
            %let onlypvar = 1;
            %if &sysver >= 6.10 %then %do;
               %let probvr = P_EXACT2;
               %end;
            %end;


         proc sort data=&data;
            by &by &id;
            run;

         /*
         %if 0 %then %do;
            title4 "DATA=DATA(&data) used by PROC FREQ";
            proc print data=&data;
               run;
            %end;
         */

         proc freq
               &freqopts   /* JHK001 */
               data = &data;
            by &by &id;
            tables &control * &tmt * &response / &tblopt;
            weight &weight;
            output out=&out &outopt;
            run;


         %if &print %then %do;
            title4 "DATA=OUT(&out)";
            proc print data=&out;
               run;
            %end;


         /*
         / Create _PTYPE_ and PROB from output dataset produced
         / by PROC FREQ.
         /----------------------------------------------------------------*/

         data &out;
            set &out;
            length _ptype_ _scores_ $8 prob 8;
            retain _ptype_ "&ptype" _scores_ "&scores";
            prob = &probvr;
            keep &by &id _ptype_ _scores_ prob &u_var &l_var;
            run;

         /*
         / Transpose again to get the paired Pvalues into one observation,
         / only if the pairwise options was used.
         /-----------------------------------------------------------------*/

         %if &pairwise %then %do;
            %if &onlypvar %then %do;
               proc transpose
                     prefix = P
                     data   = &out
                     out    = &out
                        (
                         drop   = _name_ _label_
                         rename = (P0_0 = PROB)
                        )
                     ;
                  by &by _ptype_ _scores_;
                  id &id;
                  var prob;
                  run;
               %end;

            %else %do;

               %local trn1 trn2 trn3;
               %let trn1 = TRN1_&sysindex;
               %let trn2 = TRN2_&sysindex;
               %let trn3 = TRN3_&sysindex;

               proc transpose
                     prefix = P
                     data   = &out
                     out    = trn1(drop=_name_ _label_)
                     ;
                  by &by _ptype_ _scores_;
                  id &id;
                  var prob;
                  run;

               proc transpose
                     prefix = L
                     data = &out
                     out  = trn2(drop=_name_ _label_)
                     ;
                  by &by _ptype_ _scores_;
                  id &id;
                  var &l_var;
                  run;

               proc transpose
                     prefix = U
                     data = &out
                     out  = trn3(drop=_name_ _label_)
                     ;
                  by &by _ptype_ _scores_;
                  id &id;
                  var &u_var;
                  run;


               data &out;
                  merge
                     trn1 trn2 trn3;
                  by &by _ptype_ _scores_;
                  run;

               /*
               title4 'DATA=MERGED TRN1 TRN2 TRN3';
               proc contents data=&out;
                  run;
               proc print data=&out;
                  run;
               */

               %end;
            %end;
         %end;

      %else %if "&vartype"="CONTINUE" %then %do;
         %if "&p_value" = "PAIRED" %then %do;

            %let ptype  = PAIRED;

            proc sort
                  data=&data(keep=&by &id &uniqueid &tmt &continue &control)
                  out =&temp1;
               by &by &id &uniqueid &tmt;
               run;
            proc transpose data=&temp1 out=&temp1 prefix=xxxxxx;
               by &by &id &uniqueid &control &tmt;
               var &continue;
               run;

            proc summary data=&temp1(where=(&tmt=&tmtdiff)) nway missing;
               class &by _name_ &id;
               var xxxxxx1;
               output out=&out(drop=_type_ _freq_)
                      prt=prob;
               run;

            data &out;
               set &out(rename=(_name_=_vname_));
               length _ptype_ _scores_ $8;
               retain _ptype_ "&ptype" _scores_ ' ';
               keep &by &id _vname_ _ptype_ _scores_ prob;
               run;

            proc delete data=&temp1;
               run;

            %end;

         %else %do;
            %let ptype  = VANELT;
            %let tblopt = CMH2 SCORES=MODRIDIT ;
            %let outopt = CMHRMS;
            %let probvr = P_CMHRMS;

            proc sort
                  data=&data(keep=&by &id &uniqueid &tmt &continue &control)
                  out =&temp1;
               by &by &id &uniqueid &control &tmt;
               run;
            proc transpose data=&temp1 out=&temp1 prefix=xxxxxx;
               by &by &id &uniqueid &control &tmt;
               var &continue;
               run;
            proc sort data=&temp1;
               by &by _name_ &id;
               run;

            proc freq &freqopts data=&temp1; /* JHK001 */
               by &by _name_ &id;
               tables &control * &tmt * xxxxxx1 / &tblopt;
               output out=&out &outopt;
               run;

            data &out;
               set &out(rename=(_name_=_vname_));
               length _ptype_ _scores_ $8 prob 8;
               retain _ptype_ "&ptype" _scores_ 'MODRIDIT';
               prob = &probvr;
               keep &by &id _vname_ _ptype_ _scores_ prob;
               run;

            %if &pairwise %then %do;
               proc transpose
                     prefix = P
                     data   = &out
                     out    = &out
                        (
                         drop   = _name_
                         rename = (p0_0=prob)
                        )
                     ;
                  by &by _vname_ _ptype_ _scores_;
                  id &id;
                  var prob;
                  run;
               %end;

            proc delete data=&temp1;
               run;
            %end;
         %end;

   %mend jkpval05;
-------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: /users/d33/jf97633/sas_y2k/macros/jkrenlst.sas                                                      0100664 0045717 0002024 00000003262 06325705646 0022100 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ PROGRAM NAME: jkrenlst.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE: Used parse two lists and return a new list where each 
/   word in the original lists are joined by an user specified character.
/
/ SAS VERSION: 6.12
/
/ CREATED BY: John Henry King
/
/ DATE: 1992, actually wrote this in the 80s probably.
/
/ INPUT PARAMETERS:
/   old =       specifies a list of blank delimited words.
/
/   new =       specifies a list of blank delimited workds.
/
/   between =   The string of characters to place between the lists.
/               Equal sign (=) is the default.
/
/ OUTPUT CREATED: Returns a macro string.
/
/ MACROS CALLED: none
/
/ EXAMPLE CALL:
/   
/   %let list = %jkrenlst(old = A B C, new = X Y Z);
/
/   Assigns LIST the value: A = X B = Y C = Z
/==============================================================================
/ CHANGE LOG:
/
/ MODIFIED BY:
/ DATE:
/ MODID: JHK001
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK002
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK003
/ DESCRIPTION:
/============================================================================*/

%macro JKrenlst(old=,new=,between=%str(=));

   %local i oldword newword return;
   %let i = 1;
   %let oldword = %scan(&old,&i,%str( ));
   %let newword = %scan(&new,&i,%str( ));

   %do %while("&oldword" ^= "");
      
      %let return = &return &oldword &between &newword;

      %let i = %eval(&i + 1);
      %let oldword = %scan(&old,&i,%str( ));
      %let newword = %scan(&new,&i,%str( ));
 
      %end;

   &return

   %mend JKrenlst;
                                                                                                                                                                                                                                                                                                                                              /users/d33/jf97633/sas_y2k/macros/jkrfmt.sas                                                        0100664 0045717 0002024 00000007737 06466343033 0021546 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ PROGRAM NAME: jkrfmt.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE: Used by standard macros to process the ROWSFMT parameter
/                  in DTAB.
/  
/
/ SAS VERSION: 6.12 (UNIX)
/
/ CREATED BY: John Henry King
/ DATE: OCT1997
/
/ INPUT PARAMETERS:
/
/   rowsfmt=        The list of words to process.
/ 
/   _name_=_vname_  The name of _VNAME_ special variable from SIMSTAT.
/ 
/   _fmt_=_vfmt_    The name of the variable created by this macro.
/
/   delm=%str( -)   The delimiter list for the scan function.
/
/
/ OUTPUT CREATED:
/
/   A select statement for processing the ROWSFMT statement in DTAB.
/
/ MACROS CALLED: none
/
/ EXAMPLE CALL:
/
/   %jkrfmt(rowsfmt=&rowsfmt,_name_=_VNAME_,_fmt_=_vfmt_);
/
/==============================================================================
/ CHANGE LOG:
/
/ MODIFIED BY:
/ DATE:
/ MODID: JHK001
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK002
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK003
/ DESCRIPTION:
/============================================================================*/

%macro jkrfmt(rowsfmt = ,
               _name_ = _VNAME_,
               _fmt_  = _VFMT_,
                delm  = %str( ));


   %let rowsfmt = %upcase(&rowsfmt);

   %local i j w c lroot lastword;

   %let lroot = _X_;

   /*                                                                                  
   / Parse the format list part of STATSFMT                                            
   /------------------------------------------*/                                      
   %let j = 1;                                                                         
   %let i = 1;                                                                         
   %let w = %scan(&rowsfmt,&i,&delm);                                                     
   %let lastword = ;                                                                   

   %do %while(%bquote(&w)^=);                                                             
      %if %index("&w",.) & ^%index("&lastword",.) %then %do;                           
         %local &lroot.F&j;                                                            
         %let &lroot.F&j = &w;                                                         
         %let j = %eval(&j + 1);                                                       
         %end;                                                                         
      %else %if ^%index("&w",.) %then %do;                                             
         %local &lroot.v&j;                                                            
         %if %bquote(&&&lroot.v&j) = 
            %then %let c = ;
            %else %let c = ,;
         %let &lroot.V&j = &&&lroot.v&j &c "&w";                                            
         %end;                                                                         
      %let lastword = &w;                                                              
      %let i        = %eval(&i + 1);                                                   
      %let w        = %scan(&rowsfmt,&i,%str( ));                                           
      %end;                                                                            

   %local &lroot.V0;                                                                   
   %let   &lroot.V0 = %eval(&j -1);                                                    
   

   length &_fmt_ $20.;
   
   select(_vname_);
      when('0');
                                                                                   
      %do i = 1 %to &&&lroot.v0;                                                          
         
         when(&&&lroot.v&i) &_fmt_ = "&&&lroot.f&i";
         
         %end;
                                                                     
      otherwise &_fmt_ = '$'||trim(_vname_)||'.';
      end;

   %mend jkrfmt;
                                 /users/d33/jf97633/sas_y2k/macros/jkrlbl.sas                                                        0100664 0045717 0002024 00000004055 06325705653 0021523 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ PROGRAM NAME: jkrlbl.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE: Used by standard macros to process the row label
/   placement in the ROWS parameter of DTAB.
/
/ SAS VERSION: 6.12 (UNIX)
/
/ CREATED BY: John Henry King
/ DATE: FEB1997
/
/ INPUT PARAMETERS:
/
/   rowvars=        The list of words to process.
/ 
/   _name_=_vname_  The name of _VNAME_ special variable from SIMSTAT.
/ 
/   _rlbl_=_rlbl_   The name of the variable created by this macro.
/
/   delm=%str( -)   The delimiter list for the scan function.
/
/
/ OUTPUT CREATED:
/
/   Add _dash_ to a data set.
/
/ MACROS CALLED: none
/
/ EXAMPLE CALL:
/
/   %jkrlbl(rowvars=&rows,_name_=_VNAME_,_rlbl_=_RLBL_);
/
/==============================================================================
/ CHANGE LOG:
/
/ MODIFIED BY:
/ DATE:
/ MODID: JHK001
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK002
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK003
/ DESCRIPTION:
/============================================================================*/


%macro jkrlbl(rowvars=,
               _name_=_VNAME_,
               _rlbl_=_RLBL_,
                 delm=%str( -));

   %global rlabel1 rlabel2 rlabel3 rlabel4 rlabel5
           rlabel6 rlabel7 rlabel8 rlabel9 rlabel10;

   %local i j w w2;
   %let rowvars = %upcase(&rowvars);
   %let i = 1;
   %let w  = %scan(&rowvars,&i,  &delm);
   %let w2 = %scan(&rowvars,&i+1,&delm);

   length &_rlbl_ $200;

   %if %index("&rowvars",+) %then %do;
      select(&_name_);
 
      %do %while("&w"^="");
         %let w2 = %substr(&w2%str( ),1,1);
         %if "&w2" = "+" %then %do;
            %let j = %eval(&j + 1);
            when("&w") &_rlbl_ = "&&rlabel&j";
            %end;
         %let i = %eval(&i + 1);
         %let w  = %scan(&rowvars,&i,&delm);
         %let w2 = %scan(&rowvars,&i+1,&delm);
         
         %end;

         otherwise &_rlbl_ = ' ';
         end;
      %end;

   %mend jkrlbl;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   /users/d33/jf97633/sas_y2k/macros/jkrord.sas                                                        0100664 0045717 0002024 00000003505 06325705664 0021537 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ PROGRAM NAME: jkrord.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE: Used by standard macros to assign a sort order variable
/   to a list of words.  Specifically to order SIMSTAT output data according 
/   to the order given in ROWS= in DTAB.
/
/ SAS VERSION: 6.12 (UNIX)
/
/ CREATED BY: John Henry King
/ DATE: FEB1997
/
/ INPUT PARAMETERS:
/
/   rowvars=        The list of words to process.
/ 
/   _name_=_vname_  The name of _VNAME_ special variable from SIMSTAT.
/ 
/   _row_=_row_     The name of the variable created by this macro.
/
/   delm=%str( -+)  The delimiter list for the scan function.
/
/
/ OUTPUT CREATED:
/
/   Add _dash_ to a data set.
/
/ MACROS CALLED: none
/
/ EXAMPLE CALL:
/   
/  %jkrord(rowvars=&rows,_name_=_VNAME_,_row_=_ROW_);
/
/==============================================================================
/ CHANGE LOG:
/
/ MODIFIED BY:
/ DATE:
/ MODID: JHK001
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK002
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK003
/ DESCRIPTION:
/============================================================================*/

/*
/ This macro is used to assign a sort order variable to
/ a list of words.
/----------------------------------------------------------------------*/

%macro jkrord(rowvars=,
               _name_=_VNAME_,
                _row_=_ROW_,
                 delm=%str( -+));
   %local i w;
   %let rowvars = %upcase(&rowvars);
   %let i = 1;
   %let w = %scan(&rowvars,&i,&delm);

   select(&_name_);

   %do %while("&w"^="");

      when("&w") &_row_ = &i;
      %let i = %eval(&i + 1);
      %let w = %scan(&rowvars,&i,&delm);
      %end;

      otherwise &_row_ = .;
      end;
   %mend jkrord;
                                                                                                                                                                                           /users/d33/jf97633/sas_y2k/macros/jkstpr01.sas                                                      0100664 0045717 0002024 00000022743 06457475401 0021726 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ PROGRAM NAME: jkstpr01.sas
/
/ PROGRAM VERSION: 2.0
/
/ PROGRAM PURPOSE: This macro is use by DTAB to parse the STATS= and
/   STATSFMT=.
/
/ SAS VERSION: 6.12 (UNIX)
/
/ CREATED BY: John Henry King
/ DATE: FEB1997
/
/ INPUT PARAMETERS:
/   stats=              The stats parameter passed to DTAB.
/
/   statsfmt=           The statsfmt parameter passed to DTAB.
/
/   at=                 The @ put statement pointer.
/
/ OUTPUT CREATED:  A macro variable array of put statement parts.
/
/ MACROS CALLED: none
/
/ EXAMPLE CALL:
/   %jkstpr01(stats=&stats,
/          statsfmt=&statsfmt,
/                at=@(_tc[ncol]) +(coff) )
/
/==============================================================================
/ CHANGE LOG:
/
/ MODIFIED BY: John Henry King
/ DATE: 21OCT1997
/ MODID: JHK001
/ DESCRIPTION: This macro was re-written to allow each continious variable to 
/              use a different set of formats.  IDSG conforming.
/              
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK002
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK003
/ DESCRIPTION:
/============================================================================*/




%macro jkstpr01(
                stats=,
             statsfmt=,
                   at=@(_tc[ncol]) +(coff)
               );




   %local w ww g h i j k lastword lroot;
   %let lroot = _&sysindex._;

   %let statsfmt = %qupcase(&statsfmt);
   %let stats    = %qupcase(&stats);

   %local
      SSE DFE MSE ROOTMSE
      LSM LSMSE
      CSS CV KURTOSIS MAX MEAN MEDIAN MIN MODE MSIGN N NMISS NOBS NORMAL
      P1 P10 P5 P90 P95 P99 PROBM PROBN PROBS PROBT Q1 Q3 QRANGE RANGE
      SIGNRANK SKEWNESS STD STDMEAN SUM SUMWGT T USS VAR
      L95 U95 L90 U90 L99 U99
      ;



   /*
   / Scan the format lists from &STATSFMT and pull out _ALL_ if found.
   /-----------------------------------------------------------------------------*/

   %local vl0 vlall vlallx;
   %let i = 1;
   %let w = %scan(&statsfmt,&i,%str(%)));
   %do %while(%bquote(&w) ^= );
      %if %substr(%bquote(&w),1,5)=_ALL_ %then %do;
         %let vlall  = %bquote(&w%str(%)));
         %let vlallx = %scan(&vlall,2,%str(%(%)));
         %end;
      %else %do;
         %let vl0 = %eval(&vl0 + 1);
         %local vl&vl0;
         %let vl&vl0 = %bquote(&w%str(%)));
         %end;
      %let i = %eval(&i + 1);
      %let w = %scan(&statsfmt,&i,%str(%)));
      %end;

   %if %bquote(&vlall)^= %then %do;
      %let vl0 = %eval(&vl0 + 1);
      %let vl&vl0 = &vlall;
      %end;
   %else %do;
      %let vl0 = %eval(&vl0 + 1);
      %let vl&vl0 = _all_();
      %end;

   %global jku0_0;
   %let jku0_0 = 0;

   /*
   / Loop through macro variable STATSFMT to get the pieces for each variable.
   /
   /--------------------------------------------------------------------------------*/

   %do h = 1 %to &vl0;


      /*
      / reinitialize the default formats and update with all if available.
      /------------------------------------------------------------------------------*/
      %let dfe       = 3.0;
      %let rootmse   = 5.1;
      %let mse       = 5.1;
      %let sse       = 5.1;
      %let LSM       = 5.1;
      %let LSMSE     = 5.1;
      %let CSS       = 5.1;
      %let CV        = 5.1;
      %let KURTOSIS  = 5.1;
      %let MAX       = 3.0;
      %let MEAN      = 5.1;
      %let MEDIAN    = 5.1;
      %let MIN       = 3.0;
      %let MODE      = 5.1;
      %let MSIGN     = 5.1;
      %let N         = 3.0;
      %let NMISS     = 3.0;
      %let NOBS      = 3.0;
      %let NORMAL    = 5.1;
      %let P1        = 5.1;
      %let P10       = 5.1;
      %let P5        = 5.1;
      %let P90       = 5.1;
      %let P95       = 5.1;
      %let P99       = 5.1;
      %let PROBM     = 6.4;
      %let PROBN     = 6.4;
      %let PROBS     = 6.4;
      %let PROBT     = 6.4;
      %let Q1        = 5.1;
      %let Q3        = 5.1;
      %let QRANGE    = 5.1;
      %let RANGE     = 5.1;
      %let SIGNRANK  = 5.1;
      %let SKEWNESS  = 5.1;
      %let STD       = 5.1;
      %let STDMEAN   = 5.1;
      %let SUM       = 5.1;
      %let SUMWGT    = 5.1;
      %let T         = 6.1;
      %let USS       = 6.1;
      %let VAR       = 6.1;
      %let L95       = 5.1;
      %let U95       = 5.1;
      %let L90       = 5.1;
      %let U90       = 5.1;
      %let L99       = 5.1;
      %let U99       = 5.1;

      /*
      / Scan &VLALLX and update the defaults formats.
      /---------------------------------------------------------------------------*/
      %let j = 1;
      %let i = 1;
      %let w = %scan(&vlallx,&i,%str( ));
      %let lastword   = ;
      %do %while("&w" ^= "");
         %if %index("&w",.) & ^%index("&lastword",.) %then %do;
            %local &lroot.F&j;
            %let &lroot.F&j = &w;
            %let j = %eval(&j + 1);
            %end;
         %else %if ^%index("&w",.) %then %do;
            %local &lroot.v&j;
            %let &lroot.V&j = &&&lroot.v&j &w;
            %end;
         %let lastword = &w;
         %let i = %eval(&i + 1);
         %let w = %scan(&vlallx,&i,%str( ));
         %end;
      %local &lroot.V0;
      %let   &lroot.V0 = %eval(&j -1);


      %let k = 0;
      %do i = 1 %to &&&lroot.v0;
         %let j = 1;
         %let w = %scan(&&&lroot.v&i,1,%str( ));
         %do %while("&w"^="");
            %let k = %eval(&k + 1);
            %let &w = &&&lroot.f&i;

            %let j  = %eval(&j + 1);
            %let w  = %scan(&&&lroot.v&i,&j,%str( ));
            %end;

         %let &lroot.v&i = ;
         %let &lroot.f&i = ;
         %end;


      /*
      / Now process the individual format lists for each variable.
      / X is the variable name
      / WW is the statsfmt sub list.
      /----------------------------------------------------------------------------*/

      %let x =  %scan(&&vl&h,1,%str(%());
      %let ww = %scan(&&vl&h,2,%str(%(%)));

      /*
      / Parse the format list part of STATSFMT
      /-------------------------------------------*/
      %let j = 1;
      %let i = 1;
      %let w = %scan(&ww,&i,%str( ));
      %let lastword = ;
      %do %while("&w" ^= "");
         %if %index("&w",.) & ^%index("&lastword",.) %then %do;
            %local &lroot.F&j;
            %let &lroot.F&j = &w;
            %let j = %eval(&j + 1);
            %end;
         %else %if ^%index("&w",.) %then %do;
            %local &lroot.v&j;
            %let &lroot.V&j = &&&lroot.v&j &w;
            %end;
         %let lastword = &w;
         %let i        = %eval(&i + 1);
         %let w        = %scan(&ww,&i,%str( ));
         %end;
      %local &lroot.V0;
      %let   &lroot.V0 = %eval(&j -1);


      %let k = 0;
      %do i = 1 %to &&&lroot.v0;
         %let j = 1;
         %let w = %scan(&&&lroot.v&i,1,%str( ));
         %do %while("&w"^="");
            %let k = %eval(&k + 1);
            %let &w = &&&lroot.f&i;

            %let j  = %eval(&j + 1);
            %let w  = %scan(&&&lroot.v&i,&j,%str( ));
            %end;

         %let &lroot.v&i = ;
         %let &lroot.f&i = ;
         %end;



      %let i = 1;
      %let w = %qscan(&stats,&i,%str( ));

      %global jku&h._0 jku&h._v;
      %let    jku&h._0 = 0;
      %let    jku&h._v = &x;

      %do %while("&w"^="");

         %global jku&h._&i;

         %if "&w"="MIN-MAX" %then %do;
            %let jku&h._&i = n(min,max)>0 then put &at MIN &min '-' MAX &max-l;
            %end;
         %else %if "&w"="N-MEAN(STD)" %then %do;
            %let jku&h._&i = n(n,mean,std)>0 then put &at N &n +1 MEAN &mean '(' STD :&std +(-1) ')';
            %end;
         %else %if "&w"="N-MEAN(STD)-MIN+MAX" %then %do;
            %let jku&h._&i = n>0 then put &at N &n +1 MEAN &mean '(' STD  &std ')' MIN &min ',' MAX &max;
            %end;
         %else %if "&w"="N-MEAN-STD-MIN-MAX" %then %do;
            %let jku&h._&i = n>0 then put &at N &n +1 MEAN &mean  STD  &std MIN &min ',' MAX &max;
            %end;
         %else %if "&w"="N-MEAN(STDMEAN)" %then %do;
            %let jku&h._&i = n(n,mean,stdmean)>0 then put &at N &n +1 MEAN &mean '(' STDMEAN :&stdmean +(-1) ')';
            %end;
         %else %if "&w"="MEAN(STD)" %then %do;
            %let jku&h._&i = n(mean,std)>0 then put &at MEAN &mean '(' STD :&std +(-1) ')';
            %end;
         %else %if "&w"="MEAN(STDMEAN)" %then %do;
            %let jku&h._&i = n(mean,stdmean)>0 then put &at MEAN &mean '(' STDMEAN :&stdmean +(-1) ')';
            %end;
         %else %if "&w"="LSM(LSMSE)" %then %do;
            %let jku&h._&i = n(lsm,lsmse)>0 then put &at lsm &lsm '(' LSMSE :&lsmse +(-1) ')';
            %end;
         %else %if "&w"="N-LSM(LSMSE)" %then %do;
            %let jku&h._&i = n(lsm,lsmse,n)>0 then put &at N &n +1 LSM &lsm '(' LSMSE :&lsmse +(-1) ')';
            %end;
         %else %if "&w"="L95-U95" %then %do;
            %let jku&h._&i = n(l95,u95)>0 then put &at L95 &l95 '-' U95 &u95-l;
            %end;
         %else %if "&w"="L90-U90" %then %do;
            %let jku&h._&i = n(l90,u90)>0 then put &at L90 &l90 '-' U90 &u90-l;
            %end;
         %else %if "&w"="L99-U99" %then %do;
            %let jku&h._&i = n(l99,u99)>0 then put &at L99 &l99 '-' U99 &u99-l;
            %end;
         %else %do;
            %let jku&h._&i = %unquote(&w > . then put &at &w &&&w);
            %end;

         %*put NOTE: JKU&h._&i = &&jku&h._&i;

         %let i = %eval(&i + 1);
         %let w = %qscan(&stats,&i,%str( ));

         %end;

      %let jku&h._0 = %eval(&i - 1);
      %end;


   %let jkU0_0 = %eval(&h-1);

   %mend jkstpr01;
-----------------------------/users/d33/jf97633/sas_y2k/macros/jkxwords.sas                                                      0100775 0045717 0002024 00000003672 06320447440 0022115 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ PROGRAM NAME: jkxwords.sas
/
/ PROGRAM VERSION: 1.0
/
/ PROGRAM PURPOSE: Parse a list count the words.  The individual words are
/   optionally added stored in a macro variable array.
/
/ SAS VERSION: 6.12
/
/ CREATED BY: John Henry King
/
/ DATE: sometime in the 80s
/
/ INPUT PARAMETERS:
/
/ LIST=             A list to be processed
/
/ ROOT=_W           The root of the macro variable array created to hold the
/                   individual words.  If root is given a NULL value then
/                   the macro only counts the words and does not create the
/                   macro variable array.
/
/ DELM=%str( )      The delimiters for the list.
/
/
/ OUTPUT CREATED: Return the number of words in the list.  And by default
/   created GLOBAL macro variable one for each word.
/
/ MACROS CALLED: none
/
/ EXAMPLE CALL:
/
/   %let wordlist = this is a list of words;
/
/   %let list0 = %words(&wordlist,root=list);
/
/ Assigns LIST0 the value: 6
/ Creates global macro variables as follows.
/
/ list1 = this
/ list2 = is
/ list3 = a
/ list4 = list
/ list5 = of
/ list6 = words
/
/==============================================================================
/ CHANGE LOG:
/
/ MODIFIED BY:
/ DATE:
/ MODID: JHK001
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK002
/ DESCRIPTION:
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK003
/ DESCRIPTION:
/============================================================================*/

%MACRO JKXWORDS(LIST=,ROOT=_w,DELM=%str( ));
   %local i word;
   %let i = 1;
   %let word = %scan(&list,&i,&delm);
   %do %while("&word"^="");
      %if "&root" > "" %then %do;
         %global &root&i;
         %let &root&i = &word;
         %end;
      %let i = %eval(&i + 1);
      %let word = %scan(&list,&i,&delm);
      %end;
   %let i = %eval(&i - 1);
   &i
   %mend jkxwords;
                                                                      /users/d33/jf97633/sas_y2k/macros/jobid.sas                                                         0100775 0045717 0002024 00000016721 06635173613 0021337 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ Program name:     JOBID.SAS
/
/ Program version:  3.0
/
/ Program purpose:  Creates jobid information in various titles, footnotes
/                   etc. (username, program name etc.).
/
/ SAS version:      6.12 TS020
/
/ Created by:
/ Date:
/
/ Input parameters: ARG     - Area to print jobid info
/                   INFO    - Information to print
/                   DATEFMT - Date format
/                   TIME    - Include time of day
/                   BEFORE  - Text to print before jobid string
/                   AFTER   - Text to print after jobid string
/                   FONT    - Graphics font
/                   HEIGHT  - Font height
/                   COLOUR  - Font colour
/                   PREMOVE - Starting point for relative moves
/                   MOVE    - Location of id string
/
/ Output created:   None
/
/ Macros called:    None
/
/ Example call:     %jobid(title);
/
/==============================================================================
/ Change Log:
/
/    MODIFIED BY: Jonathan Fry
/    DATE:        08DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Output all year values as 'YYYY'.
/                 Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 3.0.
/    ----------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    ----------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    ----------------------------------------------------------------------
/==============================================================================*/

%macro jobid(
       arg,                  /* FOOTNOTE, TITLE, GRAPHICS, NOQUOTE, PLATE      */
                             /*   pointer control                              */
      info=USERID,           /* or PATH for /path/file.ext                     */
                             /*   or LONG for userid(/path/file.ext)           */
                             /*   NOTE: exact form depends on operating system */
   datefmt=DATE,             /* date style MDY, DMY, YMD, DATE9.               */
      time=YES,              /* include time of day?                           */
    before=,                 /* character constant "before" jobid string       */
     after=,                 /* character constant "after"  jobid string       */

              /* Options for Graphics only */

      font=SIMPLEX,          /* graphics font                                  */
    height=0.5,              /* font height                                    */
     color=BLACK,            /* font color                                     */
   premove=,                 /* Starting point for relative moves              */
      move=(0.0 IN, 0.01 IN) /* location of id string                          */
          );

/*------------------------------------------------------------------------------/
/ JMF001                                                                        /
/ Display Macro Name and Version Number in LOG                                  /
/------------------------------------------------------------------------------*/

   %put ------------------------------------------------------;
   %put NOTE: Macro called: JOBID.SAS      Version Number: 3.0;
   %put ------------------------------------------------------;

/*------------------------------------------------------------------------------/
/ Note:  This version runs on VMS and UNIX systems only                         /
/------------------------------------------------------------------------------*/

   %if %index(%str( VMS SUN 4 ),%str( &sysscp ))=0 %then %do;
      %put ERROR: Unsuported platform for current version of JOBID.;
      %goto endtag;
   %end;

   %let arg = %upcase(&arg);
   %if "&arg"="" %then %let arg=FOOTNOTE1;
   %let info = %upcase(&info);
   %local date time yy;
   %let datefmt=%upcase(&datefmt);

/*------------------------------------------------------------------------------/
/ JMF001                                                                        /
/ Set variable 'YY' to be length 4                                              /
/------------------------------------------------------------------------------*/

   %let start=%substr(&sysdate,1,5);
   data _null_;
      year=year(today());
      yy=put(year,4.);
      call symput('yy',yy);
   run;
   %let yy=%trim(&yy);
   %if %index(&datefmt,DATE) %then %let date=%trim(&start)&yy;

   %else %do;
      %local mm dd ml;
      %let mm=%scan(&sysdate,1,0123456789);
      %let dd=%substr(&sysdate,1,%index(&sysdate,&mm)-1);
      %let ml=%str(XX JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC);
      %let mm=%eval(%index(&ml,&mm)/4);
      %let mm=%substr(0&mm,%length(&mm),2);
      %let dd=%substr(0&dd,%length(&dd),2);
      %if       "&datefmt"="YMD" %then %let date=&yy/&mm/&dd;
      %else %if "&datefmt"="DMY" %then %let date=&dd..&mm..&yy;
      %else                            %let date=&mm/&dd/&yy;
   %end;
   %local jobid;
   %if "&info" = "USERID" %then %do;
      %local userid filen;
      %if "&sysscp"="VMS" %then %do;
         %let userid=%scan(&sysparm,1,%str( ()));
         %let filen=%scan(&sysparm,2,%str(]));
         %let filen=%scan(&filen,1,%str(.));
      %end;
      %else %if "&sysscp"="SUN 4" %then %do;
         %local cnt;
         %let userid=%scan(&sysparm,1,%str(:));
         %let filen=%substr(&sysparm,%eval(%index(&sysparm,%str(:))+1));
         %let cnt=%index(&filen,%str(/));
         %do %while(&cnt);
            %let filen=%substr(&filen,%eval(&cnt+1));
            %let cnt=%index(&filen,%str(/));
         %end;
         %if %substr(&filen,%eval(%length(&filen)-3))=.sas %then
            %let filen=%scan(&filen,1,%str(.));
      %end;
      %let jobid=%str(&userid(&filen));
      %end;
   %else %if "&info" = "PATH" %then %do;
      %if "&sysscp"="VMS" %then %let jobid=%scan(&sysparm,2,%str( ()));
      %else %if "&sysscp"="SUN 4" %then %let jobid=%scan(&sysparm,2,%str(:));
   %end;
   %else %do;
      %if "&sysscp"="VMS" %then %let jobid=&sysparm;
      %else %if "&sysscp"="SUN 4" %then %do;
         %local filen userid;
         %let filen=%scan(&sysparm,2,%str(:));
         %let userid=%scan(&sysparm,1,%str(:));
         %let jobid=%str(&userid(&filen));
      %end;
   %end;
   %let time = %upcase(&time);
   %if %substr(&time,1,1)=Y %then %let time=%str( )&systime;
   %else                          %let time=;

   %local pad;
   %let pad='                                                      ';
   %if %index(&arg,FOOTNOTE) | %index(&arg,TITLE) %then %do;
      &arg &before "&jobid &date&time" &after &pad &pad &pad;
   %end;
   %else %if %index(GRAPHICS,&arg) %then %do;
      %if %length(&font)   =0 %then %let font   =SIMPLEX;
      %if %length(&height) =0 %then %let height =0.5;
      %if %length(&color)  =0 %then %let color  =BLACK;
      %if %length(&move)   =0 %then %let move   =(0.0 IN, 0.01 IN);
      %if %length(&premove)>0 %then
          %let premove=%str(MOVE=&premove ' ') ;
      NOTE &premove MOVE=&move F=&font H=&height  C=&color
           &before "&jobid &date&time" &after;
      %end;
   %else %if %index(NOQUOTE,&arg) %then %do;
      &before &jobid &date&time &after %str( )
      %end;
   %else %if %index(PLATE,&arg) %then %do;
      "&jobid"!!' '!!"&date&time" %str( )
   %end;
   %else %do;
      &arg &before "&jobid &date&time" &after %str( )
   %end;
   %endtag:
%mend jobid;
                                               /users/d33/jf97633/sas_y2k/macros/jobid2.sas                                                        0100775 0045717 0002024 00000005030 06635174044 0021407 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ Program name:     JOBID2.SAS
/
/ Program version:  2.1
/
/ Program purpose:  Creates jobid information in various titles footnotes
/                   etc. (username, program name etc.).
/
/ SAS version:      6.12 TS020
/
/ Created by:
/ Date:
/
/ Input parameters: ARG     - Area to print jobid info
/                   INFO    - Information to print
/                   DATEFMT - Date format
/                   TIME    - Include time of day
/                   BEFORE  - Text to print before jobid string
/                   AFTER   - Text to print after jobid string
/                   FONT    - Graphics font
/                   HEIGHT  - Font height
/                   COLOUR  - Font colour
/                   PREMOVE - Starting point for relative moves
/                   MOVE    - Location of id string
/
/ Output created:
/
/ Macros called:    %jobid.sas
/
/ Example call:     %jobid2(title);
/
/=========================================================================
/ Change Log:
/
/   MODIFIED BY: Jonathan Fry
/   DATE:        09DEC1998
/   MODID:       JMF001
/   DESCRIPTION: Tested for Y2K compliance.
/                Add %PUT statement for Macro Name and Version Number.
/                Change Version Number to 2.1.
/   ------------------------------------------------------------------
/   MODIFIED BY:
/   DATE:
/   MODID:       XXX002
/   DESCRIPTION:
/   ------------------------------------------------------------------
/   MODIFIED BY:
/   DATE:
/   MODID:       XXX003
/   DESCRIPTION:
/   ------------------------------------------------------------------
/=========================================================================*/

%macro jobid2(arg,
             info=USERID,
          datefmt=DATE9.,
             time=YES,
           before=,
            after=,
             font=SIMPLEX,
           height=0.5,
            color=BLACK,
             move=(0.0 IN, 0.01 IN));

/*-------------------------------------------------------------------------/
/ JMF001                                                                   /
/ Display Macro Name and Version Number in LOG                             /
/-------------------------------------------------------------------------*/

   %put ------------------------------------------------------;
   %put NOTE: Macro called: JOBID2.SAS     Version Number: 2.1;
   %put ------------------------------------------------------;

   %jobid(&arg,info=&info,datefmt=&datefmt,time=&time,before=&before,
          after=&after,font=&font,height=&height,color=&color,move=&move);

%mend jobid2;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        /users/d33/jf97633/sas_y2k/macros/jobinfo.sas                                                       0100664 0045717 0002024 00000007072 06633723476 0021700 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ Program Name : jobinfo.sas
/
/ Program Version : 4.1
/
/ Program Purpose :
/
/ SAS Version : 6.12
/
/ Created By : (A.G.Walduck)
/ Date :       (25th April 1997)
/
/ Input Parameters :
/
/ Output Created :
/
/ Macros Called :
/
/ Example Call :
/
/=============================================================================================
/ Change Log
/
/    MODIFIED BY: Ian Amaranayake
/    DATE:        04/07/97
/    MODID:       001
/    DESCRIPTION: Standard program header added.
/    -----------------------------------------------------------------------------
/    MODIFIED BY: Tony Walduck
/    DATE:        28/05/97
/    MODID:       002
/    DESCRIPTION: Truncated file names in /GW/u?medstat/ environment.
/                 Modified (ucb) ps command with wrap-around option.
/    -----------------------------------------------------------------------------
/    MODIFIED BY: Hedy Weissinger
/    DATE:        01/09/97
/    MODID:       003
/    DESCRIPTION: File names and paths not returned correctly when submitting
/                 jobs to SAS from CRISP.  Added x switch to ps command.
/    -----------------------------------------------------------------------------
/    MODIFIED BY: Jonathan Fry
/    DATE:        09DEC1998
/    MODID:       JMF004
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 4.1.
/    -----------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX005
/    DESCRIPTION:
/    -----------------------------------------------------------------------------
/=============================================================================================*/;

%macro JOBINFO ;

      /*
      / JMF004
      / Display Macro Name and Version Number in LOG
      /--------------------------------------------------------*/

      %put -----------------------------------------------------;
      %put NOTE: Macro called: JOBINFO.SAS   Version Number: 4.1;
      %put -----------------------------------------------------;


%if %nrbquote(&sysparm)~= %then %goto exit ;

%if "&sysscp" ~= "SUN 4" %then %do ;
  %put NOTE: JOBINFO does not work with &sysscp..;
  %goto exit;
  %end;
options nonotes ;

%local user dir arg ext ;

%if &sysenv=BACK %then %do ;

  filename sasarg pipe "/usr/ucb/ps -wx | awk '/^ *&sysjobid/{print $6}' ;
        pwd ; whoami" ;

  data _null_ ;
    infile sasarg length=len ;
    input card $varying200. len ;
    select (_n_) ;
      when  (1)    call symput('arg' ,trim(card)) ;
      when  (2)    call symput('dir' ,trim(card) !! '/' ) ;
      when  (3)    call symput('user',trim(card)) ;
      otherwise    put 'WARNING: Unexpected line from pipe in %JOBINFO.' ;
    end ;
    run ;

  %if %index(&arg,%str(/))=1 %then %let dir= ;

  %local i file ;
  %let file = &arg ;
  %let i = %index(&file,%str(/)) ;
  %do %while(&i) ;
    %let file = %substr(&file,%eval(&i + 1)) ;
    %let i = %index(&file,%str(/)) ;
  %end ;

  %if %index(&file,%str(.)) %then %let ext= ;
  %else %let ext=.sas ;

%end ;

%else %do ;

  filename sasarg pipe "pwd ; whoami" ;

  data _null_ ;
    infile sasarg length=len ;
    input card $varying200. len ;
    select (_n_) ;
      when  (1)    call symput('dir' ,trim(card) !! '/') ;
      when  (2)    call symput('user',trim(card)) ;
      otherwise    put 'WARNING: Unexpected line from pipe in %JOBINFO.' ;
    end ;
    run ;

  %let arg=INTERACTIVE ;

%end ;

filename sasarg clear ;

options sysparm="&user:&dir.&arg.&ext" notes ;

%exit:

%mend JOBINFO ;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                      /users/d33/jf97633/sas_y2k/macros/labels.sas                                                        0100775 0045717 0002024 00000016367 06651572352 0021521 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ Program name: labels.sas
/
/ Program version: 2.1
/
/ Program purpose: Apply labels to variables with recognised names.
/
/ SAS version: 6.12 TS020
/
/ Created by: Andrew Ratcliffe, SPS Limited
/ Date: ?
/
/ Input parameters: data     - input library & file
/                   out      - output library & file
/                   override - replace existing labels?
/                   length   - length of labels(short, long, shortest, longest)
/                   fmtlib   - format library which holds $labels macro
/                   tidy     - delete temporary datasets?
/                   pfx      - prefix of temporary work files
/                   verbose  - verbosity of messages
/
/ Output created:
/
/ Macros called: None
/
/ Example call:
/
/                   %labels(data=g123.ld01);
/
/=============================================================================
/ Change log:
/
/    MODIFIED BY: ABR
/    DATE:        23SEP1992
/    MODID:       Ver 1.1
/    DESCRIPTION: Original Version
/    --------------------------------------------------------------------
/    MODIFIED BY: ABR
/    DATE:        28SEP1992
/    MODID:       Ver 1.2
/    DESCRIPTION: Put labels in external table to improve speed.
/                 Provide larger table.
/                 Add TABLE option.
/    --------------------------------------------------------------------
/    MODIFIED BY: ABR
/    DATE:        12OCT1992
/    MODID:       Ver 1.3
/    DESCRIPTION: Change TABLE option to FMTLIB to improve speed.
/    --------------------------------------------------------------------
/    MODIFIED BY: ABR
/    DATE:        02DEC1992
/    MODID:       Ver 1.4
/    DESCRIPTION: Remove default for FMTLIB.
/    --------------------------------------------------------------------
/    MODIFIED BY: ABR
/    DATE:        09FEB1993
/    MODID:       Ver 1.5
/    DESCRIPTION: Add LENGTH parameter.
/    --------------------------------------------------------------------
/    MODIFIED BY: Jonathan Fry
/    DATE:        09DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 2.1.
/    --------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    --------------------------------------------------------------------
/=============================================================================*/

 %macro labels(data     = ,
               out      = ,
               override = n,
               length   = longest,
               fmtlib   = ,
               pfx      = lbl_,
               tidy     = y,
               verbose  = 2);

     /*
     / JMF001
     / Display Macro Name and Version Number in LOG
     /--------------------------------------------------------*/

     %put ----------------------------------------------------;
     %put NOTE: Macro called: LABELS.SAS   Version Number: 2.1;
     %put ----------------------------------------------------;


 %let tidy = %upcase(&tidy);
 %let length = %upcase(&length);
 %let fmtlib = %upcase(&fmtlib);
 %let override = %upcase(&override);

 %if &override ne Y and &override ne N %then %do;
   %put WARNING: LABELS: "&override" is an invalid value for OVERRIDE.;
   %let override = N;
   %put WARNING: LABELS: OVERRIDE has been set to "&override".;
   %end;
 %if &length ne SHORT    and &length ne LONG    and
     &length ne SHORTEST and &length ne LONGEST %then %do;
   %put WARNING: LABELS: "&length" is an invalid value for LENGTH.;
   %let length = LONGEST;
   %put WARNING: LABELS: LENGTH has been set to "&length".;
   %end;
 %if %length(&pfx) gt 4 %then %do;
   %put WARNING: LABELS: "&pfx" exceeds maximum length for PFX.;
   %let pfx = %substr(&pfx,1,4);
   %put WARNING: LABELS: PFX has been truncated to "&pfx".;
   %end;
 %if %index(0123456789,&verbose) eq 0 %then %do;
   %put WARNING: LABELS: "&verbose" is an invalid value for VERBOSE.;
   %let verbose = 2;
   %put WARNING: LABELS: VERBOSE has been set to "&verbose".;
   %end;
 %if %length(&out) eq 0 %then %do;
   %let out = &data;
   %if &verbose ge 3 %then %do;
     %put NOTE: LABELS: No output file specified.;
     %put               Input file will be used for output.;
     %end;
   %end;

   %if %length(&fmtlib) gt 0 %then %do;
     LIBNAME library "&fmtlib";
     %end;
   libname library "/usr/local/medstat/sas/formats";

   proc contents data=&data out=&pfx.0010 noprint;

   %let lvnum = 0;

   data _null_;
     set &pfx.0010;
     retain tot 0;
     length msg $80;
     length labelt $40;
     msg = '';  /* Avoid messages about msg being uninitialised */
     %if &override eq N %then %do;
       if label ne '' then do;
         %if &verbose ge 3 %then %do;
           msg = 'NOTE: LABELS: Label already exists for '
                 || compress(name)
                 || '. No over-ride requested.'
                 ;
           put msg;
           %end;
         delete;
         end;
       %end;
                            /* Let's go get a label */
     if "%substr(&length,1,1)" eq 'S' then do;
       labelt = put(name,$labels.);
       if labelt = '' and
          "%substr(&length,%eval(%length(&length)-2),3)" eq 'EST' then do;
         %if &verbose ge 3 %then %do;
           msg = 'NOTE: LABELS: No known short label for '
                 || compress(name)
                 || '.'
                 ;
           put msg;
           %end;
         labelt = put(name,$labell.);
         end;
       end;
     else do; /* Must be an L */
       %if &verbose ge 9 %then %do;
         put 'DEBUG: LABELS: Looking for a long(est) label. ' name=;
         %end;
       labelt = put(name,$labell.);
       if labelt = '' and
          "%substr(&length,%eval(%length(&length)-2),3)" eq 'EST' then do;
         %if &verbose ge 3 %then %do;
           msg = 'NOTE: LABELS: No known long label for '
                 || compress(name)
                 || '.'
                 ;
           put msg;
           %end;
         labelt = put(name,$labels.);
         end;
       end;

     if labelt = '' then do;
       %if &verbose ge 3 %then %do;
         msg = 'NOTE: LABELS: No known label for '
               || compress(name)
               || '. None supplied.'
               ;
         put msg;
         %end;
       delete;
       end;
     tot = tot + 1;
     call symput('lvn'||compress(put(tot,best.)),name);  /* Name  */
     call symput('lv'||compress(put(tot,best.)),labelt); /* Label */
     call symput('lvnum',put(tot,best.));

 %if &data ne &out %then %do;
   data &out;
     set &data;
   %end;

 %let dotpos = %index(&out,.);
 %if &dotpos eq 0 %then %do;
   %let olib =;
   %let ofile = &out;
   %end;
 %else %do;
   %let olib = %substr(&out,1,&dotpos-1);
   %let ofile = %substr(&out,&dotpos+1,%length(&out)-&dotpos);
   %end;

   proc datasets nolist
     %if %length(&olib) gt 0 %then %do;
       lib=&olib
       %end;
     ;
     modify &ofile;
     %do i = 1 %to &lvnum;
       label &&lvn&i = "&&lv&i";
       %end;
     quit;

 %if &tidy eq Y %then %do;
    proc datasets lib=work nolist;
      delete &pfx.0010;
      quit;
    %end;
  %else %do;
    %if &verbose ge 3 %then %do;
      %put NOTE: LABELS: As requested, temporary datasets not deleted.;
      %end;
    %end;

   run;

   %mend labels;
/
/                   %labels(data=g123.ld01);
/
/=============================================================================
/ Change log:
/
/    MODIFIED BY: ABR
/    DATE:        23SEP1992
/    MODID:       Ver 1.1
/    DESCRIPTION: Original Version
/    -----/users/d33/jf97633/sas_y2k/macros/linemup.sas                                                       0100664 0045717 0002024 00000007544 06633723711 0021717 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ Program Name: LINEMUP.SAS
/
/ Program Version: 2.1
/
/ Program purpose: Lines up the decimal place of numbers that are stored as characters
/                  and preserves the number of decimal places that were entered.
/
/ SAS Version: 6.12
/
/ Created By: Hedy Weissinger
/ Date:
/
/ Input Parameters:
/
/           DATA   - is the name of the dataset to be used (the final dataset will also
/                    have this name)
/           VAR    - list of variables that need to be aligned
/           OUTVAR - new variables created by the macro that are the aligned versions of
/                    the VAR list.
/
/ Output Created:
/
/           A set of variables are created which correpsond to the original set of variables
/           but which have been processed by the macro to align decimal points.
/
/ Macros Called: BWWORDS.SAS
/
/ Example Call:
/
/===============================================================================================
/ Change Log:
/
/   MODIFIED BY: Jonathan Fry
/   DATE:        09DEC1998
/   MODID:       JMF001
/   DESCRIPTION: Tested for Y2K compliance.
/                Add %PUT Statement for Macro Name and Version Number.
/                Change Version Number to 2.1.
/   ---------------------------------------------------------------------------
/   MODIFIED BY:
/   DATE:
/   MODID:       XXX002
/   DESCRIPTION:
/   ---------------------------------------------------------------------------
/   MODIFIED BY:
/   DATE:
/   MODID:       XXX003
/   DESCRIPTION:
/   ---------------------------------------------------------------------------
/===============================================================================================*/

%macro linemup(data=,var=,outvar=);

   /*
   / JMF001
   / Display Macro Name and Version Number in LOG
   /--------------------------------------------------------*/

   %put -----------------------------------------------------;
   %put NOTE: Macro called: LINEMUP.SAS   Version Number: 2.1;
   %put -----------------------------------------------------;


   %let _vr0 = %bwwords(&var,root=_vr0);
   data _1_;
      do until(eof);
         set &data end=eof;
         array _v{&_vr0} &var;
         array _i{&_vr0};
         array _iI{&_vr0};
         array _ij{&_vr0};
         array _d{&_vr0};
         do _j = 1 to dim(_v);
            if ^verify(_v{_j},'0123456789. ') then do;
               _i{_j} = max(((index(_v{_j},'.')-1)>0) *
                              index(_v{_j},'.')-1, 0)
                        +((index(_v{_j},'.')=0)*length(_v{_j}));
               _II{_j} = ((index(_v{_j},'.')=0)*length(_v{_j}));
               _ij{_j} = max(((index(_v{_j},'.')-1)>0) *
                              index(_v{_j},'.')-1, 0);
               _d{_j} = max(0,index(left(reverse(_v{_j})),'.')-1);
               end;
            else do;
               _i{_j}=.; _ii{_j}=.; _ij{_j}=.; _d{_j}=.;
               end;
            end;
         output;
         end;
      drop _j;
      run;
   proc summary data=_1_ nway missing;
      var _i1-_i&_vr0 _d1-_d&_vr0;
      output out=_2_(drop=_type_ _freq_)
         max=_mi1-_mi&_vr0 _md1-_md&_vr0;
      run;
   data &data;
      set _2_;
      array _mi{&_vr0};
      array _md{&_vr0};
      do until(eof);
         set _1_ end=eof;
         array _v{&_vr0} &var;
         array _nv{&_vr0} $10 &outvar;
         array _i{&_vr0};
         array _d{&_vr0};
         do _j = 1 to dim(_v);
            if verify(_v{_j},'0123456789. ')=0
               then do;
                  _nv{_j} = putn(input(_v{_j},30.),
                              'F' ,
                             _mi{_j} + _d{_j} + (_d{_j}>0) ,
                             _d{_j});
               end;
            else _nv{_j} = _v{_j};
            end;
         output;
         drop _d1-_d&_vr0 _mi1-_mi&_vr0 _md1-_md&_vr0 _j _i1-_i&_vr0
              _ii1-_ii&_vr0 _ij1-_ij&_vr0 ;
         end;
      run;
   %mend;
                                                                                                                                                            /users/d33/jf97633/sas_y2k/macros/macfoot.sas                                                       0100775 0045717 0002024 00000005513 06633724004 0021667 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ Program name: macfoot.sas
/
/ Program version: 2.1
/
/ Program purpose: generates footnotes, adds special char for macpage macro.
/
/ SAS version: 6.12 TS020
/
/ Created by: Randall Austin
/ Date:       7/9/94
/
/ Input parameters: foot1-foot10 - footnotes
/                   target       - 'FF'x macpage trigger
/
/ Output created:
/
/ Macros called:
/
/ Example call:
/
/                   %macfoot(footnote1,footnote2);
/
/================================================================================
/ Change log:
/
/    MODIFIED BY: SRA
/    DATE:        15SEP94
/    MODID:
/    DESCRIPTION: If footnote does not have quotes, puts them in.
/    ------------------------------------------------------------------
/    MODIFIED BY: SRA
/    DATE:        13DEC94
/    MODID:
/    DESCRIPTION: Fixed bug relating to null footnotes.
/    ------------------------------------------------------------------
/    MODIFIED BY: SRA
/    DATE:        13FEB95
/    MODID:
/    DESCRIPTION: Fixed another strange macro.
/    ------------------------------------------------------------------
/    MODIFIED BY: Julian Heritage
/    DATE:        24.02.97
/    MODID:
/    DESCRIPTION: Standard header added
/    ------------------------------------------------------------------
/    MODIFIED BY: Jonathan Fry
/    DATE:        09DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 2.1.
/    ------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    ------------------------------------------------------------------
/=================================================================================*/

%macro macfoot(foot1,foot2,foot3,foot4,foot5,foot6,foot7,foot8,foot9,foot10,
               target='FF'x);

     /*
     / JMF001
     / Display Macro Name and Version Number in LOG
     /---------------------------------------------------------*/

     %put -----------------------------------------------------;
     %put NOTE: Macro called: MACFOOT.SAS   Version Number: 2.1;
     %put -----------------------------------------------------;


%local z __x pad;
%let pad='                                                                ';
%let z=1;
%* Count the nonblank footnotes;
%do __x=1 %to 10;
%if %length(&&foot&__x.)=0 %then %let z=&z;%else %let z=&__x;
%end;
%do q=1 %to %eval(&z-1);
%if %index(&&foot&q,%str(%")) ne 1 and %index(&&foot&q,%str(%')) ne 1
%then %let foot&q="&&foot&q"; %if &&foot&q="" %then %let foot&q=;
footnote&q &&foot&q &pad &pad;
%end;
%if %index(&&foot&z,%str(%")) ne 1 and %index(&&foot&z,%str(%')) ne 1
%then %let foot&z="&&foot&z"; %if &&foot&z="" %then %let foot&z=;
footnote&z &&foot&z. &target. &pad &pad ;
%mend macfoot;
                                                                                                                                                                                     /users/d33/jf97633/sas_y2k/macros/macpage.sas                                                       0100664 0045717 0002024 00000100330 06645355157 0021636 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ PROGRAM NAME: macpage.sas, DOCMAN version
/
/ PROGRAM VERSION: 5.1
/
/ PROGRAM PURPOSE: The MACPAGE macro generates page numbers on SAS output and
/                  can perform some page formatting.
/
/                  The macro has two basic operating modes. Capture mode causes the
/                  SAS system to capture output normally written to the SAS .LST file.
/                  The macro is call twice in capture mode once to start capture and once
/                  to end capture and process the captured output.
/
/                  The macro may also be directed to process a specific file, via the
/                  INFILE=parameter.  In this mode the macro is called only once.
/
/ SAS VERSION: 6.12 (UNIX)
/
/ CREATED BY: John Henry King
/
/ DATE: JUN1997.
/
/ INPUT PARAMETERS:
/
/ capture=  The capture parameter causes MACPAGE to enter capture mode.
/           Use CAPTURE=ON as the only parameter in the first call to
/           macpage.  In your second call use CAPTURE=OFF along with any
/           other parameters that you may need.  The default setting is
/           null.
/
/ unit=     The UNIT parameter has been replace by CAPTURE.  Unit still
/           functions as always for compatability with older versions of
/           macpage.
/
/           The unit paramter causes MACPAGE to enter capture mode.  Specify
/           a two-digit number for this parameter.
/           Use UNIT=nn as the only parameter in the first call
/           to %MACPAGE to initiate redirection of the SAS system printed
/           output.  The other parameters will be ignored.  The default
/           setting is null.
/
/ file=     Specifies the physical file specification for the output file.
/           When this is left blank, the file name of the job will be used,
/           and the filetype will be "OUn".  Where n is indexed from the
/           string, 0123456789abcdefghiklmnopqrstuvwxyz.  Therefore the first
/           call to macpage uses the filetype OU0, the second OU1 and so on
/           for a total of 36 seperate filetypes that can be generated by
/           one program. The default setting is null, which invokes automatic
/           nameing.
/
/ infile=   Specifies a file name to use as input for macpage.  This parameter
/           causes macpage to process the file named in INFILE= instead of
/           using file capture mode.
/
/ disp=     Specifies whether you want to append the output from the current
/           macpage call to the contents of the output file from a previous
/           macpage call.
/           When this parameter is left blank, the contents of the output file
/           will be re-written, DISP=OLD.  The default setting is null.
/
/ target=   Specifies a single character or character string target which
/           %MACPAGE will look for when positioning the numbers on the
/           output pages.  The target must be specified in either double or
/           single quotes.  If target is not specified then page numbers will
/           not apear on the output.  The default setting is hex FF.
/
/ fnquery=  Specifies whether the macro operates in the old style where SYSPARM
/           is set by a modified SAS script, or the new style where the
/           value of SYSPARM is set internally by the macro.  See %JKFN macro
/           for details on this feature. The default setting is no.
/
/
/ jobid=    Specifies a target for the "JOBID" string (i.e. "userid(filename) date time").
/           Valid values are:
/              UR upper right (the default)
/              UL upper left
/              UC upper centered.
/
/
/ jobinfo=  Specifies the format used int the jobid string.
/           Valid values are:
/              USERID            userid(filename)
/              PATH              full path no userid
/              LONG              the value of sysparm
/
/ justify=  Specifies whether page number text will be right, left, or
/           center justified.  The default setting is Right.
/
/
/ ls=       Specifies the linesize used in determining the placement of the page
/           numbers for right justified and centered page numbers.  The default
/           is 132.
/
/ style=    Specifies the style used for page numbering.  The default is PAGEOF.
/
/ sigspace= Specifies the hex codes for characters that %MACPAGE will translate
/           into blank spaces.  These characters can then be used as "hard" spaces
/           in SAS output.  The default string is '00373f41ff'x
/
/ fcc=      specifies whether to use Fortran-style carraige-controll characters in
/           the output file.  When FCC=N, the UNDER=, JOBID=, and ZEROES= parameters
/           are disabled.  The default setting is yes.
/
/ fpage=    Specifies the starging page number.  The default is 1.
/
/ adjust=   Specifies that number of columns to skip on the left margin before printing
/           out each line the report.  The default is 0.
/
/ skip=     Specifies the number of lines to skip on the top margin before printing
/           each page. The default is 0.
/
/ zeros=    Overstriking zeros with a slash is not supported in this version of
/           macpage.  This parameter has no effect.
/
/ under=    Hiking up underscores is not supported in this version of macpage.
/
/ underlen=8 This parameter has no effect on this version of macpage.
/
/ pluses=Y  This parameter causes macpage to change all occurances of ++ to
/           dashdash using the proper dash character as specified by DASHES=
/
/ dashes=_DEFAULT_
/           Specifies the dash character to use the default for SUN UNIX is
/           hex C4
/
/ pub=      Use pub=NO to overide the macros actions when _docman_=1. If you have
/           some output that is not to be included in the DONELIST and prepared
/           for the document center use pub=no.
/
/ proj=     Used to name the DONELIST.  When this variable is blank, the usual case,
/           the macro uses the value of $PROJ environment variable.
/
/ type=     Specifies the output type.  Use T for table, A for appendix, and
/           F for figure.  This data is used to write the donelist.
/
/ num=      Specifies the output table number.  This is a read number and my be
/           preceded by a single uppercase letter.  This will order the output
/           within types of output.
/
/ toc=      Specifies the output table of contents text entry.  Normally, this should
/           match the output title.  Use standard ASCII characters ONLY.
/
/ NOTE: If you use the TITLES system, &TYPE, &NUM, and &TOC global macro variables
/       will be created and contain the appropraite information to use in TYPE=,
/       NUM=, and TOC=.  For example, the following is a typical call to the DOCMAN
/       version of MACPAGE.
/
/        %macpage(capture = on)
/
/           proc report ......;
/              ...
/              run;
/
/        %macpage(capture = off)
/
/
/ OUTPUT CREATED: A file specified in the FILE= parameter.
/
/ MACROS CALLED:
/
/      %JKFN - a macro to assign the file name, and userid to &SYSPARM without
/              using a modifed SAS script
/      %FN   - a macro to parse &SYSPARM
/
/===================================================================================
/ CHANGE LOG:
/
/    MODIFIED BY: SRA
/    DATE:        09DEC94
/    MODID:
/    DESCRIPTION: Added skip-execution routine if operating interactively
/    --------------------------------------------------------------------------
/    MODIFIED BY: SRA
/    DATE:        11APR95
/    MODID:
/    DESCRIPTION: Default jobid=UR
/    --------------------------------------------------------------------------
/    MODIFIED BY: John Henry King.
/    DATE:        04MAR1997
/    MODID:       JHK001
/    DESCRIPTION: Added FNQUERY parameter to allow the macro to operate without
/                 depending on the filename and USERID information comming from
/                 &SYSPARM.
/    --------------------------------------------------------------------------
/    MODIFIED BY: John Henry King
/    DATE:        05JUN1997
/    MODID:       JHK002
/    DESCRIPTION: Changed %TRIM to %SYSFUNC(TRIM.  This changes allows to macro
/                 to run with output the SAS supplied autocall library.
/    --------------------------------------------------------------------------
/    MODIFIED BY: John Henry King
/    DATE:        05JUN1997
/    MODID:       JHK003
/    DESCRIPTION: Changed sysget('USER') to sysget('LOGNAME')
/    --------------------------------------------------------------------------
/    MODIFIED BY: John Henry King
/    DATE:        13JUN1997
/    MODID:       JHK004
/    DESCRIPTION: Changed call to %getopts to use %sysfunc(GETOPTION
/    --------------------------------------------------------------------------
/    MODIFIED BY: John Henry King
/    DATE:        29AUG1997
/    MODID:       JHK005
/    DESCRIPTION: Changed default file extension nameing to start at 0
/                 instead of 1.
/    --------------------------------------------------------------------------
/    MODIFIED BY: John Henry King
/    DATE:        29AUG1997
/    MODID:       JHK006
/    DESCRIPTION: Added PROC PRINTTO to suppress WARNING messages from SYSGET
/                 function when system variables are not defined.
/    --------------------------------------------------------------------------
/    MODIFIED BY: John Henry King
/    DATE:        17oct1997
/    MODID:       JHK007
/    DESCRIPTION: Added code to allow TYPE, NUM and TOC to use the value of
/                 __TYPE__, __NUM__ and __TOC__ as defaults to these parameters.
/    --------------------------------------------------------------------------
/    MODIFIED BY: John Henry King
/    DATE:        20oct1997
/    MODID:       JHK008
/    DESCRIPTION: Added S,L,D,C to allowed document types.
/    --------------------------------------------------------------------------
/    MODIFIED BY: John Henry King
/    DATE:        11Nov1997
/    MODID:       JHK009
/    DESCRIPTION: Added code to make MACPAGE work on PC SAS
/    --------------------------------------------------------------------------
/    MODIFIED BY: John Henry King
/    DATE:        22JAN1998
/    MODID:       JHK010
/    DESCRIPTION: Fixed bug where SUN 4 was coded as SUN4.
/    --------------------------------------------------------------------------
/    MODIFIED BY: Jonathan Fry
/    DATE:        09DEC1998
/    MODID:       JMF011
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 5.1.
/    --------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX012
/    DESCRIPTION:
/    --------------------------------------------------------------------------
/================================================================================*/

%macro MacPage(unit = ,
               file = ,
             infile = ,
               disp = ,
            capture = ,
             target = 'FF'x,
                 ls = 132,
            justify = Right,
              style = Pageof,
           sigspace = 'FEFF'x,
              fpage = 1,
             adjust = 0,
               skip = 0,
              under = Y,
           underlen = 8,
              zeros = ,
             pluses = Y,
              jobid = TL,
            jobinfo = LONG,
             dashes = _DEFAULT_,
                fcc = Y,
            fnquery = 0,
                pub = YES,
               proj = ,
               type = ,
                num = ,
                toc = );

/*  MOD: 11APR95 SRA Default jobid=UR instead of null */

      /*
      / JMF011
      / Display Macro Name and Version Number in LOG
      /--------------------------------------------------------------------*/

      %put -----------------------------------------------------;
      %put NOTE: Macro called: MACPAGE.SAS   Version Number: 5.1;
      %put -----------------------------------------------------;

     /*
     / JMF011
     / Convert SYSDATE variable to have 4 character date.
     /-----------------------------------------------------*/

     data date;
        y=year(today());
        yy=put(y,4.);
        call symput('yy',yy);
     run;
     %let yyyy=%trim(&yy);
     %let ddmmm=%substr(&sysdate,1,5);
     %let date=&ddmmm &yyyy;
     title1 '    ';


   /*
   / JHK001
   / Change if statement that uses SAS supplied autocall macro
   /--------------------------------------------------------------------*/
   %if ^%index(SUN 4!WIN!OS2,%bquote(&sysscp)) %then %do;
      %put ERROR: MACPAGE: Unknown operating system (&sysscp);
      %goto mpexit;
      %end;

   /*
   / ON PC set PUB=NO.  I will try to get this working on the PC later.
   /---------------------------------------------------------------------*/
   %if %index(WIN!OS2,%bquote(&sysscp)) %then %do;
      %let pub = NO;
      %end;


   /*
   / If operating interactively, dont execute MacPage
   /----------------------------------------------------------*/
   %if &sysenv^=BACK & %index(SUN 4,%bquote(sysscp)) %then %do;
      %put WARNING:  MACPAGE will not execute because you are running interactively.;
      %put           Use a noninteractive submission method to get production-quality output.;
      %put SYSENV=&sysenv;
      %goto mpexit ;
      %end;

   %if %qupcase(&capture)=YES | %bquote(&capture)=1 | %qupcase(&capture)=ON
      %then %let capture = 1;
      %else %let capture = 0;



   /*
   / First call to MACPAGE, UNIT is supplied, this section
   / is executed to issue needed filename statement to create
   / filerefs.
   /----------------------------------------------------------*/
   %if (%bquote(&unit)^= | &capture) & %bquote(&infile)= %then %do;

      %global _mcpunit;
      %if &capture
         %then %let _mcpunit = 99;
         %else %let _mcpunit = &unit;

      FILENAME FT&_mcpunit.F001 DISK "FT&sysjobid.F001.LISTING";

      PROC PRINTTO PRINT=FT&_mcpunit.F001 NEW;
         RUN;

      %end;

   /*
   / Second call no UNIT or CAPTURE=OFF then do this section.
   /-----------------------------------------------------------*/
   %else %do;

      /*
      / if INFILE= is not blank issue fileref for that file.
      /--------------------------------------------------------*/
      %if %bquote(&infile)^= %then %do;
         %local _mcpunit;
         %let _mcpunit = 99;
         FILENAME FT&_mcpunit.F001 DISK "&infile";
         %end;
      %else %do;
         PROC PRINTTO;
             RUN;
         %end;

      /*
      / JHK001
      / Added this call to JKFN to allow macro to work without a special
      / script to supply the filename and userid info in SYSPARM
      /--------------------------------------------------------------------*/
      %let fnquery = %upcase(&fnquery);
      %if "&fnquery"="1" | "&fnquery"="YES"
         %then %let fnquery = 1;
         %else %let fnquery = 0;

      %if &fnquery %then %do;
         %jkfn(mvar=sysparm,style=sysparm)
         %end;

      %local plus;
      %let plus = 2B;

      %if &dashes=_DEFAULT_ %then %do;
         %let dashes='C4'x;
         %let dashes='2d'x;
         %end;

      %if %index(SUN 4!WIN!OS2,%bquote(&sysscp)) %then %do;
         %let fcc = N;
         %end;

      %local xfs xfm;
      %let xfs=%str(.);
      %let xfm=;

      /*
      / JHK004
      / Changed to use %SYSFUNC instead of %getops macro
      /----------------------------------------------------*/
      %if %quote(&ls)= %then %do;
         %let ls=%sysfunc(getoption(LINESIZE));
         %end;

      %if &ls > 132 %then %do;
         %put ERROR: Linesize must not exceed 132 characters.;
         %goto mpexit;
         %end;

      %local __proj__  __pub__ __outd__;

      %if       %quote(&pub)=                %then %let __pub__ = YES;
      %else %if %upcase(%substr(&pub,1,1))=N %then %let __pub__ = NO;
      %else                                        %let __pub__ = YES;

      /*
      / JHK006
      /
      / Added proc printto to suppress WARNING message from SYSGET
      / when environment variables are not defined.
      /--------------------------------------------------------------*/

      filename dummy dummy 'dummy';
      proc printto log=dummy;
         run;

      %if  %quote(&proj)= %then %let __proj__ = %sysget(PROJ);
      %else                     %let __proj__ = %quote(&proj);

      %let __outd__ = %sysget(OUTPUT);

      proc printto;
         run;

      filename dummy clear;
      /*
      / if _docman_=0 then we dont need this section
      /--------------------------------------------------*/

      %if &_docman_ %then %do;
         %if %quote(&__pub__)=YES %then %do;
            /*
            / JHK007
            /---------------------------------------------------------------------*/
            %if %bquote(&type)= & %bquote(&__type__)^= %then %do;
               %let type = %bquote(&__type__);
               %end;
            %if %bquote(&num)= & %bquote(&__num__)^=   %then %do;
               %let num  = %bquote(&__num__);
               %end;
            %if %bquote(&toc)= & %bquote(&__toc__)^=   %then %do;
               %let toc = %bquote(&__toc__);
               %end;


            %if %quote(&type)= | %quote(&num)= %then %do;
               %put ERROR:  TYPE and NUM parameters required for DOCMAN MacPage.;
               %goto mpexit;
               %end;

            %if %quote(&__proj__)= | %quote(&__outd__)= %then %do;
               %put ERROR:  PROJ and OUTPUT enviromental variables must be set.;
               %goto mpexit;
               %end;

            %if %nrbquote(&toc)= %then
               %put NOTE:  Assumed continuation of multipart FSP element.;

            %if %index(TFASLDC,&type)=0 %then %do;
               %put ERROR:  DOCMAN MacPage TYPE parameter must be T, F, A, S, L, D, or C.;
               %goto mpexit;
               %end;

            FILENAME DONELIST DISK "%sysfunc(trim(&__outd__))/%sysfunc(trim(&__proj__)).donelist" MOD;
            %end;
         %end;

      %let jobid = %upcase(&jobid);
      %if "&jobid"="CC" %then %let jobid=UR;

      %let jobinfo = %upcase(&jobinfo);

      %if %bquote(&pluses)^= %then %let pluses = %upcase(%substr(&pluses,1,1));

      %if %bquote(&fcc)^=   %then %let fcc    = %upcase(%substr(&fcc,1,1));


      /*
      / Construct a FILE name to name the output file
      /---------------------------------------------------*/

      %global mcpginc;
      %if &mcpginc=
         %then %let mcpginc=001;
         %else %let mcpginc=%eval(&mcpginc+1);

      %if %bquote(&file)= %then %do;

         /*
         / Extract just the filename part of sysparm
         / using %FN.
         /-------------------------------------------*/
         %let file = %fn;

         /*
         / JHK005
         / changed %substr string to start with 0
         / instead of 1.
         /---------------------------------------------*/
         %if  %bquote(&file)=
            %then %let file=macpop&_mcpunit&xfs.list&mcpginc;
            %else %let file=&file&xfs.ou%substr(0123456789abcdefghijklmnopqrstuvwxyz,&mcpginc,1);

         %end;


      /*
      / This sections constructs the FILE variable depending on OS
      / and the value of __PUB__.  When __PUB__ is yes the file
      / is written to the directory described in __OUTD__.
      / You may recall that __OUTD__ is assigned the value of the
      / OUTPUT environment variable.
      /--------------------------------------------------------------*/

      %if %bquote(&__outd__)^= %then %do;
         /*
         / If the file parameter contains a "directory part"
         / remove it an use __OUTD__
         /-----------------------------------------------------------------*/
         %if %quote(&__pub__) = YES %then %do;
            %local root;
            %let file = %sysfunc(reverse(&file));
            %let file = %scan(&file,1,%str(/));
            %let root = %sysfunc(reverse(&file));
            %let file = %sysfunc(trim(&__outd__))/%sysfunc(reverse(&file));
            %end;
         %else %if %index(&file,%str(/))=0 %then %do;
            %let file=%sysfunc(trim(&__outd__))/&file;
            %end;
         %end;


      %if &fcc^=Y %then %do;
         %local msg1 msg2;
         %let msg1=NOTE: The following MacPage Options are not available;
         %let msg2=without FORTRAN Carriage Controls:;
         %put %str(&msg1 &msg2);
         %if %index(SUN 4!WIN!OS2,%bquote(&sysscp)) %then %do;
            %put NOTE:  UNDER= and ZEROS=;
            %let under=N;
            %let zeros=;
            %end;
         %else %do;
            %put NOTE:  JOBID, JOBINFO, SKIP, UNDER and ZEROS;
            %let jobid=;
            %let skip=0;
            %let under=N;
            %let zeros=;
            %end;
         %end;

      /*
      / This section is used in conjunction with DISP=.
      / Each time macpage is called this bit of code checks to see
      / if the FILE= is the same as the last time macpage was called.
      / If not the macro array subscript is incremented and the
      / new file name is added to the list of file names.
      /
      / If the file is one that was used before then macpage will
      / know if is the same and can adjust the file disposition
      / to append the output to the existing file.
      /-------------------------------------------------------------*/

      %global _mcpf0;
      %if &_mcpf0 = %then %do;
         %let _mcpf0  = %eval(&_mcpf0 + 1);
         %global _mcpf1 _mcpfn1;
         %let _mcpf1  = &file;
         %let _mcpfn1 = 1;
         %let f       = 1;
         %end;
      %else %do;
         %do f=1 %to &_mcpf0;
            %if "&file"="&&_mcpf&f" %then %do;
               %let _mcpfn&f = %eval(&&_mcpfn&f + 1);
               %goto exit;
               %end;
            %end;
         %let _mcpf0 = &f;
         %global _mcpfn&f _mcpf&f;
         %let _mcpf&f = &file;
         %let _mcpfn&f = 1;
         %end;
    %exit:



      /*
      / If DISP= is blank then the macro uses disp=OLD,
      / if it is the first call in the program.  If it
      / is the second call or greater call with the same
      / file name the macro uses disp=MOD.
      /---------------------------------------------------*/
      %let disp = %upcase(&disp);
      %if "&disp"="" %then %do;
         %if &&_mcpfn&f = 1
            %then %let disp=;
            %else %let disp=MOD;
         %end;


      /*
      / Issue file name for various operating systems.
      /----------------------------------------------------*/

      %if %index(SUN 4!WIN!OS2,%bquote(&sysscp)) %then %do;
         %if %bquote(&infile)^= %then %do;
            FILENAME FTXXF001 DISK "&infile";
            %end;
         %else %do;
            FILENAME FTXXF001 DISK "FT&sysjobid.F001.LISTING";
            %end;
         %end;

      FILENAME XXXPAGE DISK "&file";

      %if "&pluses"="Y" %then %do;
        %local dh;
        %let dh = %substr(%upcase(&dashes),2,2);
        %end;

      %let justify = %substr(%upcase(&justify),1,1);
      %if ^%index(%quote(&style),%str(.))
         %then %let style = %upcase(&style);

      %let under   = %substr(%upcase(&under),1,1);

      %if       %quote(&justify)=L %then %let at=1;
      %else %if %quote(&justify)=C %then %let at=ROUND((LS2-LEN)/2);
      %else                              %let at=(LS2 - LEN);

      %local tof count txt format chapter;

      %if       %qupcase(&target)=CC  %then %let tof = SUBSTR(LINE,1,1)='1';
      %else %if %quote(&target)=      %then %let tof = 0;
      %else                                 %let tof = INDEX(LINE,&TARGET);

      %if %quote("&style") = "PAGE" %then %do;
         %let txt=%str('Page '||COMPRESS(PUT(PAGE,8.)));
         %let count = 0;
         %end;
      %else %if %index(%quote(&style),%str(.)) %then %do;
         %let chapter = %scan(&style,1,%str(.));
         %let format  = %scan(&style,2,%str(.));
         %let txt=%str("&chapter"||'.'||LEFT(PUT(PAGE,&format..)));
         %let count = 0;
         %end;
      %else %if %quote("&style") = "SAS" %then %do;
         %let txt=%str(left(PUT(PAGE,8.)));
         %let count = 0;
         %end;
      %else %if %quote("&style") = "PAGEOF" %then %do;
         %let txt=%str('Page '||COMPRESS(PUT(PAGE,8.))||' of '||
              COMPRESS(PUT(PAGES,8.)));
         %let count = 1;
         %end;
      %else %if %quote("&style") = "BRIEF" %then %do;
         %let txt=%str(compress(PUT(PAGE,8.))||' of '||
              COMPRESS(PUT(PAGES,8.)));
         %let count = 1;
         %end;

      %if %bquote(&jobid)^= %then %do;
         %local jobtxt;
         %if &jobinfo=USERID %then %do;
            %if %index(SUN 4!WIN!OS2,%bquote(&sysscp)) %then %do;
               %local jiid jifn;
               %let jiid = %scan(&sysparm,1,%str(:));
               %let jifn = %sysfunc(reverse(&sysparm));
               %let jifn = %scan(&jifn,1,%str(/\));
               %let jifn = %sysfunc(reverse(&jifn));
               %let jifn = %scan(&jifn,1,%str(.));
               %let jobtxt=%str(&jiid(&jifn));
               %end;
            %end;
         %else %if &jobinfo=PATH %then %do;
            %if &sysscp=SUN 4 %then
               %let jobtxt = %scan(&sysparm,2,%str(:));
            %else %let jobtxt = %str(&sysparm);
            %end;

         %else %let jobtxt = &sysparm;

         %local jobcond jobjust;
         %if %substr(&jobid,1,1)=U %then %do;
            /*
            / JHK010, changed SUN4 to SUN 4 in the following if
            /---------------------------------------------------------*/
            %if %index(SUN 4!WIN!OS2,%bquote(&sysscp))
               %then %let jobcond=(LINECNT=1 OR SUBSTR(SUBLINE,1,1)='0C'X);
            %end;
         %else %if %substr(&jobid,1,1)=T %then %let jobcond=(TARG);
         %else %let jobid=;

         %if       %substr(&jobid,2,1)=L %then %let jobjust=SUBSTR(SUBLINE,1,LEN);
         %else %if %substr(&jobid,2,1)=R %then %let jobjust=SUBSTR(SUBLINE,LS2-LEN,LEN);
         %else %if %substr(&jobid,2,1)=C %then %let jobjust=SUBSTR(SUBLINE,ROUND((LS2-LEN)/2),LEN);
         %else                                 %let jobid=;

         %end;

      DATA _NULL_;

         %if &_docman_ & %bquote(&__pub__)=YES %then %do;
            LENGTH PART $1 STYPE $1 NUM $13;
            PART = ' ';

            %if %index(ABCDEFGHIJKLMNOPQRSTUVWXYZ,%substr(&num,1,1))=0
            %then %do;
               NUM = "&num";
               %end;
            %else %do;
               PART = "%qsubstr(&num,1,1)";
               NUM  = "%substr(&num,2)";
               %end;


            %if       %quote(&type)=T %then %do; STYPE = "X"; %end;
            %else %if %quote(&type)=F %then %do; STYPE = "Y"; %end;
            %else %if %quote(&type)=A %then %do; STYPE = "Z"; %end;
            %else %if %quote(&type)=S %then %do;
               STYPE = 'X';
               part  = 'S';
               %end;
            %else %if %quote(&type)=L %then %do; STYPE = 'Y'; %end;
            %else %if %quote(&type)=D %then %do;
               STYPE = 'Z';
               part  = '3';
               %end;
            %else %if %quote(&type)=C %then %do;
               STYPE = 'Z';
               part  = '4';
               %end;
            %else                           %do; STYPE = "-"; %end;

            %end;


         LS2      = &LS + 1;
         PAGES    = MAX(&fpage  + 0 - 1 , 0);
         PAGE     = MAX(&fpage  + 0 - 1 , 0);
         ADJUST   = MAX(&adjust + 0 , 0);
         SKIP     = MAX(&skip   + 0 , 0);
         MINUS    = -1;
         LINECNT  = 0;
         LINES    = 0;
         TOOLONG  = 0;
         __MAXL__ = 60;


      /*
      / if TARGET is not blank read the file once and count the
      / number of times the target is found.
      /-----------------------------------------------------------*/
      %if %quote(&target)^=  & &count %then %do;
         INFILE FT&_mcpunit.F001 NOPRINT EOF=EOF1 LENGTH=LENGTH1;
         DO WHILE(1);
            INPUT @1 LINE $VARYING200. LENGTH1;
            IF &tof THEN PAGES + 1;
            END;
       EOF1:
         %end;

         /*
         / read the file a second time and process filter
         / actions.
         /-------------------------------------------------*/


         INFILE FTXXF001 NOPRINT EOF=EOF2 LENGTH=LENGTH2;
         FILE XXXPAGE  noprint notitles &disp;

         DO WHILE(1);
            LENGTH SUBLINE $200 TXT $200;
            INPUT @1 LINE $VARYING200. LENGTH2;
            LINECNT + 1;
            SUBLINE = LINE;
            IF LINECNT=1 AND &&_mcpfn&f>1 AND "&SYSSCP"="SUN 4" THEN
               SUBLINE='0C'X || SUBLINE;
            IF &tof THEN TARG=1;
            ELSE           TARG=0;
            %if %quote(&jobid)^= & %index(SUN 4|WIN|OS2,%bquote(&sysscp)) %then %do;
              IF &jobcond THEN DO;
                 LENGTH JOBID $200;
                 JOBID="&JOBTXT &DATE &SYSTIME";
                 LEN = LENGTH(JOBID);
                 LENGTH CC $1;
                 IF SUBSTR(SUBLINE,1,1)='0C'X THEN DO;
                    SUBLINE=SUBSTR(SUBLINE,2);
                    CC='0C'X;
                    END;
                 ELSE CC=' ';
                 &jobjust=JOBID;
                 IF CC^=' ' THEN SUBLINE=TRIM(CC) || SUBLINE;
                 END;
              %end;
            LENGTH3 = LENGTH(SUBLINE);
            IF TARG THEN DO;
               PAGE + 1;
               LINES = 1;
               TOOLONG = 0;
               TXT = &txt;
               LEN = LENGTH(TXT);
               SUBSTR( SUBLINE , &at , LEN ) = TXT;
               LENGTH3 = LENGTH(SUBLINE);
               END;
            IF LINES>__MAXL__ THEN DO;
               LENTRIM = LENGTH(TRIM('X' || SUBLINE));
               IF LENTRIM>1 THEN DO;
                  IF ^TOOLONG THEN DO;
                    PAGE1 = PAGE + 1;
                    FILE LOG;
                    PUT / "WARNING: Maximum lines exceeded on page"
                        +1 PAGE1;
                    FILE XXXPAGE;
                    END;
                  TOOLONG = 1;
                  END;
               END;

            subline = translate(subline,' ',&sigspace);
            %if %quote(&pluses)=Y %then %do;
                IF INDEX(SUBLINE,'++') THEN DO;
                   SUBLINE = TRANWRD(SUBLINE,'++',"&dh.&dh"X);
                   SUBLINE = TRANWRD(SUBLINE,"&dh&plus"X,"&dh.&dh"X);
                   END;
                %end;
            %if &skip>0 & %index(SUN 4!WIN!OS2,%bquote(&sysscp)) %then %do;
                IF LINECNT=1 THEN DO I=1 TO SKIP;
                   PUT / @1 ' ' @;
                   END;
                ELSE IF SUBSTR(SUBLINE,1,1)='0C'X THEN DO;
                   PUT @1 '0C'X @;
                   SUBLINE=SUBSTR(SUBLINE,2);
                   LENGTH3=LENGTH(SUBLINE);
                   DO I = 1 TO SKIP;
                      PUT / @1 ' ' @;
                      END;
                   END;
                %end;
            %if %index(SUN 4!WIN!OS2,%bquote(&sysscp)) %then %do;
                IF SUBSTR(SUBLINE,1,1)='0C'X THEN DO;
                   IF LENGTH(SUBLINE)>1 THEN SUBLINE=SUBSTR(SUBLINE,2);
                   ELSE SUBLINE=' ';
                   LENGTH3=LENGTH(SUBLINE);
                   PUT @1 '0C'X +ADJUST SUBLINE $VARYING200. LENGTH3;
                   END;
                ELSE PUT @1 +ADJUST SUBLINE $VARYING200. LENGTH3;
                %end;
            %else %do;
                PUT @1 +ADJUST SUBLINE $VARYING200. LENGTH3;
                %end;
            END;

          EOF2:

            /*
            / write the info in the DONELIST.
            /-------------------------------------*/
            %if %quote(&__pub__)=YES & &_docman_ %then %do;
               LENGTH __FN__ $18 __USER__ $8;
               /*
               / JHK003
               / Changed sysget('USER') to SYSGET('LOGNAME')
               /---------------------------------------------*/
               __USER__ = SYSGET('LOGNAME');
               __FN__ = "&root";
               IF INDEX(NUM,".")=0 THEN NUM=TRIM(NUM) || ".0";
               NUM=PUT(INPUT(SCAN(NUM,1,"."),4.),4.) || "." ||
                   LEFT(PUT(INPUT(SCAN(NUM,2,"."),8.),8.));
               FILE DONELIST;
               PUT STYPE $1. PART $1. NUM $13. @;
               PUT ' ' @;
               PUT __USER__ $9. __FN__ $18. @;
               PUT "&toc";
               %end;

            CALL SYMPUT('___LC___',LEFT(put(LINECNT,8.)));
            FILE LOG;
            PUT / "NOTE: MACPAGE numbered pages &fpage to " PAGE
                / '      ' skip= adjust=;
            STOP;

         RUN;

      %local rc;
      %let rc = %sysfunc(fdelete(FT&_mcpunit.F001));

      FILENAME FT&_mcpunit.F001 CLEAR;
      FILENAME FTXXF001         CLEAR;
      FILENAME XXXPAGE          CLEAR;
      %end;

%mpexit:
   %mend MacPage;
 %bquote(&infile)^= %then %do;
            FILENAME FTXXF001 DISK "&infile";
            %end;
         %else %do;
            FILENAME FTXXF001 DISK "FT&sysjobid.F001.LISTING";
            %end;
         %end;

      FILENAME XXXPAGE DISK "&file";

      %if "&pluses"="Y" %then %do;
        %lo/users/d33/jf97633/sas_y2k/macros/makerun.sas                                                       0100664 0045717 0002024 00000005007 06645403703 0021677 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ Program Name: MAKERUN.SAS
/
/ Program Version: 2.1
/
/ Program purpose: Used to run a multi-protocol program enclosed within a macro, for a given
/                  protocol or list of protocols.
/
/ SAS Version: 6.12
/
/ Created By:
/ Date:
/
/ Input Parameters:
/
/      GROUP -
/      VAR   - Name of operating system environment variable containing list of protocols.
/      PARAM - Parameter to pass to the macro MAIN, used for specifying protocol number.
/      EXTRA - Additional parameters to be passed to macro MAIN.
/
/ Output Created: None.
/
/ Macros Called: BWWORDS
/
/ Example Call:  %makerun(var=proto,param=prot);
/
/==============================================================================================
/ Change Log
/
/    MODIFIED BY: Jonathan Fry
/    DATE:        09DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 2.1.
/    ------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    ------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    ------------------------------------------------------------------
/==============================================================================================*/

%macro MAKERUN(group=,
               var=,
               param=,
               extra=) ;

   /*
   / JMF001
   / Display Macro Name and Version Number in LOG
   /---------------------------------------------------------------*/

   %put -----------------------------------------------------;
   %put NOTE: Macro called: MAKERUN.SAS   Version Number: 2.1;
   %put -----------------------------------------------------;


  %local protlist ;
  %let group = %upcase(&group) ;
  %let var = %upcase(&var) ;
  %let protlist = %sysget(&var) ;
  %if &protlist= %then %do ;
    %local msg1 msg2 ;
      %let msg1 = %str(NOTE: No protocols were read from the environmental);
      %let msg2 = %str(variable &var);
    %put &msg1 &msg2 ;
  %end ;
  %else %do ;
    %put NOTE: Processing protocol(s): &protlist ;
    %local __num ;
    %let __num = %bwwords(&protlist,root=__pr) ;
    %local i ;
    %if %quote(&param)~= %then %let param = &param= ;
    %if %bquote(&extra)~= %then %let extra = ,&extra ;
    %do i = 1 %to &__num ;
      %main(&param &&__pr&i &extra) ;
    %end ;
    %endsas ;
  %end ;
%mend MAKERUN ;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         /users/d33/jf97633/sas_y2k/macros/meanci.sas                                                        0100775 0045717 0002024 00000012655 06633724330 0021502 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ Program name: meanci.sas
/
/ Program version: 2.1
/
/ Program purpose: Macro to compute mean values for two groups of data,
/                  estimate of difference between means, and 95% confidence
/                  interval for difference between means
/
/
/ SAS version: 6.12 TS020
/
/ Created by: Les Huson, CSDH Clinical Statistics Section
/ Date:       03/9/92
/
/ Input parameters: data    - name of SAS dataset containing AT LEAST a group variable
/                             and a variable containing data values
/                   group   - name of the group variable in the input data set
/                   level1  - value of level1 in the group variable
/                   level2  - value of level2 in the group variable
/                   var     - name of the variable containing data values
/                   datid   - an id for the particular data set being processed - this
/                             appears in the output data set, and identifies particular
/                             sets of results in cases where this macro might be called
/                             several times
/                   out     - the name of an output data set contining the key results
/                             generated by the macro
/                   pfx     - Prefix for temporary data set names
/                   tidy    - Delete temporary data sets?
/                   verbose - Verbosity of macro messages
/
/
/ Output created:
/
/ Macros called:
/
/ Example call:
/
/                 %meanci(data=datad01,group=groupid,var=value);
/
/===========================================================================================
/ Change log:
/
/    MODIFIED BY: ABR
/    DATE:        22/ 9/92
/    MODID:       Ver 1.1
/    DESCRIPTION: Improve efficiency.
/    -----------------------------------------------------------------------
/    MODIFIED BY: ABR
/    DATE:        02/11/92
/    MODID:       Ver 1.3
/    DESCRIPTION: Use NUM_A/B instead of NA/B to avoid conflicts with names
/                 of measurement variables.
/                 Add PFX, TIDY, and VERBOSE options.
/    -----------------------------------------------------------------------
/    MODIFIED BY: Jonathan Fry
/    DATE:        10DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 2.1.
/    -----------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    -----------------------------------------------------------------------
/============================================================================================*/

%MACRO meanci (data=temp1
              ,group=trtseq
              ,level1=A,level2=B
              ,var=
              ,datid=results
              ,out=temp2
              ,pfx=MEN_
              ,tidy=y
              ,verbose=2
              );

      /*
      / JMF001
      / Display Macro Name and Version Number in LOG
      /-----------------------------------------------------------------*/

      %put ----------------------------------------------------;
      %put NOTE: Macro called: MEANCI.SAS   Version Number: 2.1;
      %put ----------------------------------------------------;


*
     First, check-out parameters.
;
 %if &tidy ne Y and &tidy ne N %then %do;
   %put WARNING: MEANCI: "&tidy" is not a valid value for TIDY.;
   %let tidy = Y;
   %put WARNING: MEANCI: TIDY has been set to "&tidy".;
   %end;
 %if %length(&pfx) gt 4 %then %do;
   %put WARNING: MEANCI: "&pfx" exceeds maximum length for PFX.;
   %let pfx = %substr(&pfx,1,4);
   %put WARNING: MEANCI: PFX has been truncated to "&pfx".;
   %end;
 %if %index(0123456789,&verbose) eq 0 %then %do;
   %put WARNING: MEANCI: "&verbose" is an invalid value for VERBOSE.;
   %let verbose = 2;
   %put WARNING: MEANCI: VERBOSE has been set to &verbose.;
   %end;


*
     Pick out just level 1 data values, finding the mean etc.
     etc.
;
PROC UNIVARIATE DATA=&data (WHERE=(&var NE . and
                                   &group EQ "&level1"
                                  )
                           )
                NOPRINT
                ;
     VAR &var;
     OUTPUT OUT=&pfx.a010 mean=meana var=vara nobs=num_a;
     RUN;


*
     Pick out level 2 data values, finding the mean etc.
;
PROC UNIVARIATE DATA=&data (WHERE=(&var NE . and
                                   &group EQ "&level2"
                                  )
                           )
                NOPRINT
                ;
     VAR &var;
     OUTPUT OUT=&pfx.b010 mean=meanb var=varb nobs=num_b;
     RUN;


*
    Get the means etc. back from seperate data sets and
    put the results into the output data set
;
DATA &out   (keep = label meana meanb num_a num_b diff lower upper);
     LENGTH label $20;
     MERGE &pfx.a010 &pfx.b010;
     label = "&datid";
     diff   = meana - meanb;
     sediff = SQRT((vara/num_a)+(varb/num_b));
     lower  = diff - (1.96*sediff);
     upper  = diff + (1.96*sediff);
     IF lower = . THEN upper = .;
     ELSE IF upper = . THEN lower = .;
     IF ( (num_a < 5) AND (num_b < 5) ) THEN DO;
         diff = .;
         lower = .;
         upper = .;
     END;
     RUN;


*
     Get rid of all the working data sets
;
%if &tidy eq Y %then %do;
  PROC DATASETS LIBRARY=WORK NOLIST;
       DELETE &pfx.a010 &pfx.b010;
       RUN;
  %end;


*
     end of macro
;
%MEND meanci;
/ Output created:
/
/ Macros called:
/
/ Example call:
/
/                 %meanci(/users/d33/jf97633/sas_y2k/macros/outltr.sas                                                        0100664 0045717 0002024 00000003426 06633724415 0021574 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ Program Name: OUTLTR.SAS
/
/ Program Version: 3.1
/
/ Program Purpose: Assigns an output suffix letter (e.g., ou&outltr)
/
/ SAS Version: 6.12
/
/ Created By: SR Austin
/ Date: Sep 1994  (upper and lower case alphabetics)
/
/ Input Parameters:
/
/ Output Created:
/
/ Macros Called:
/
/ Example Call:   %outltr
/
/====================================================================================
/ Change Log
/
/    MODIFIED BY: H Weissinger
/    DATE:        30Oct1997
/    MODID:       001
/    DESCRIPTION: Remove extraneous ; from code
/    -------------------------------------------------------------------
/    MODIFIED BY: Jonathan Fry
/    DATE:        10DEC1998
/    MODID:       JMF002
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 3.1.
/    -------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    -------------------------------------------------------------------
/====================================================================================*/

%macro outltr;

      /*
      / JMF002
      / Display Macro Name and Version Number in LOG
      /------------------------------------------------------------------*/

      %put ----------------------------------------------------;
      %put NOTE: Macro called: OUTLTR.SAS   Version Number: 3.1;
      %put ----------------------------------------------------;


   %global _ITR_N  ;
   %let avail=a b c d e f g h i j k l m n o p q r s t u v w z y z 1 2 3 4 5
              6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z;
   %let _ITR_N=%eval(&_ITR_N + 1);
   %let outltr=%scan(&avail,&_ITR_N);
   &outltr
%mend outltr;
                                                                                                                                                                                                                                          /users/d33/jf97633/sas_y2k/macros/pop_n.sas                                                         0100664 0045717 0002024 00000022441 06633724464 0021360 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ PROGRAM NAME: pop_n.sas
/
/ PROGRAM VERSION: 1.1
/
/ PROGRAM PURPOSE: Figure out population size for each treatment group and
/                  put this info into a format for treatment and global mvs
/                  The new format can then be used by SUMTAB or in other
/                  programming.  This macro is usually called in the PROJECT
/                  init macro.
/
/ SAS VERSION: 6.12 (UNIX)
/
/ CREATED BY: Carl P. Arneson
/
/ DATE: 20 Oct 1997
/
/ INPUT PARAMETERS:
/        data=           Data set with population specifier & tmt
/        pop=            Population indicator variable in data set
/        tmtvar=         Treatment variable in data set
/        tmtfmt=         Format for treatment variable
/        outfmt=         Output format name (default: &outfmt.n)
/        outmv=          Output mac. vars (def: level1-leveln, total)
/        split=%str(*)   Split character to use in OUTFMT
/
/ OUTPUT CREATED:
/        A sas user defined format. And global macro variables named in OUTMV.
/
/ MACROS CALLED:
/
/ EXAMPLE CALL:
/
/==============================================================================
/ CHANGE LOG:
/
/ MODIFIED BY: Jonathan Fry
/ DATE:        10DEC1998
/ MODID:       JMF001
/ DESCRIPTION: Tested for Y2K compliance.
/              Add %PUT statement for Macro Name and Version Number.
/              Change Version Number to 1.1.
/----------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID:       XXX002
/ DESCRIPTION:
/----------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID:       XXX003
/ DESCRIPTION:
/----------------------------------------------------------------------
/============================================================================*/

%macro pop_N(
             data=,         /* Data set with population specifier & tmt       */
             pop=,          /* Population indicator variable in data set      */
             tmtvar=,       /* Treatment variable in data set                 */
             tmtfmt=,       /* Format for treatment variable                  */
             outfmt=,       /* Output format name (default: &outfmt.n)        */
             outmv=,        /* Output mac. vars (def: level1-leveln, total)   */
             split=%str(*)  /* Split character to use in OUTFMT               */
            ) ;

    /*
    / JMF001
    / Display Macro Name and Version Number in LOG
    /----------------------------------------------------------------*/

    %put ---------------------------------------------------;
    %put NOTE: Macro called: POP_N.SAS   Version Number: 1.1;
    %put ---------------------------------------------------;


%*******************************************************************************
%*
%*                            Glaxo Wellcome Inc.
%*
%*   STUDY: L-NMMA (546C88)
%* PURPOSE: Figure out population size for each treatment group and
%*          put this info into a format for treatment and global mvs
%*  AUTHOR: Carl P. Arneson
%*    DATE: 20 Oct 1997
%*
%******************************************************************************;

%* Check for required parameters ;
%if %quote(&data)= | %quote(&pop)= | %quote(&tmtvar)= %then %do ;
  %put ERROR: (POP_N) Must specify DATA=, POP=, TMTVAR=. ;
  %goto leave ;
%end ;
%* Make sure data set exists ;
%else %if %sysfunc(exist(&data))=0 %then %do ;
  %put ERROR: (POP_N) DATA=&data does not exist. ;
  %goto leave ;
%end ;
%* Make sure variables are on data set and pull their numbers ;
%else %do ;
  %local i dsid rc _tmtnum_ _tmttyp_ _tmtlev_ _tmttot_ _popnum_ _fmtsrc_ w;
  %let dsid = %sysfunc(open(&data,i)) ;
  %let _popnum_=%sysfunc(varnum(&dsid,&pop)) ;
  %if ~&_popnum_ %then %do ;
    %put ERROR: (POP_N) POP=&pop not found on DATA=&data.. ;
    %goto leave ;
  %end ;
  %else %if %sysfunc(vartype(&dsid,&_popnum_))=C %then %do ;
    %put ERROR: (POP_N) POP=&pop must be a numeric indicator variable. ;
    %goto leave ;
  %end ;
  %let _tmtnum_=%sysfunc(varnum(&dsid,&tmtvar)) ;
  %if ~&_tmtnum_ %then %do ;
    %put ERROR: (POP_N) TMTVAR=&tmtvar not found on DATA=&data.. ;
    %goto leave ;
  %end ;
  %let _tmttyp_ = %sysfunc(vartype(&dsid,&_tmtnum_)) ;
%end ;

%* If TMTFMT is not specified, use a logical default ;
%if %quote(&tmtfmt)= %then %do ;

  %* First, check if one is already attached to treatment variable ;
  %let tmtfmt = %sysfunc(varfmt(&dsid,&_tmtnum_)) ;

  %* If not, assume it matches the name of the variable ;
  %if %quote(&tmtfmt)= %then %do ;
    %if &_tmttyp_=C %then %let tmtfmt = $&tmtvar.. ;
    %else                 %let tmtfmt = &tmtvar.. ;
  %end ;

%end ;
%else %do ;

  %let tmtfmt = %upcase(%trim(&tmtfmt)) ;
  %if %substr(&tmtfmt,%length(&tmtfmt),1)~=. %then %let tmtfmt= &tmtfmt.. ;

  %* Make sure type of specified format matches variable ;
  %if (&_tmttyp_=C & %substr(&tmtfmt,1,1)~=$) |
      (&_tmttyp_=N &
       %index(ABCDEFGHIJKLMNOPQRSTUVWXYZ_,%substr(&tmtfmt,1,1))=0)
      %then %do ;
    %put ERROR: (POP_N) Type of TMTFMT=&tmtfmt does not match type of TMTVAR=&tmtvar.. ;
    %goto leave ;
  %end ;

%end ;

%* Set an output format name if its not set ;
%if %quote(&outfmt)= %then %do ;

  %if %length(&tmtfmt)<=8 %then
    %let outfmt=%substr(&tmtfmt,1,%eval(%length(&tmtfmt)-1))N. ;
  %else
    %let outfmt=%substr(&tmtfmt,1,7)N. ;

%end ;
%else %do ;

  %let outfmt = %upcase(%trim(&outfmt)) ;
  %if %substr(&outfmt,%length(&outfmt),1)~=. %then %let outfmt= &outfmt.. ;

  %* Make sure type of format matches variable ;
  %if (&_tmttyp_=C & %substr(&outfmt,1,1)~=$) |
      (&_tmttyp_=N &
       %index(ABCDEFGHIJKLMNOPQRSTUVWXYZ_,%substr(&outfmt,1,1))=0)
      %then %do ;
    %put ERROR: (POP_N) Type of OUTFMT=&outfmt does not match type of TMTVAR=&tmtvar.. ;
    %goto leave ;
  %end ;

%end ;

%let dsid=%sysfunc(close(&dsid)) ;

%* Make sure population variable is a (0,1) variable ;
data _p_o_p_n ;
  set &data (keep=&tmtvar &pop) ;
  pop = (&pop>0) ;
  run ;

%* Count observations in each level of treatment variables ;
proc summary data=_p_o_p_n nway ;
  class &tmtvar pop ;
  output out=_p_o_p_n(keep=&tmtvar pop _freq_) ;
  run ;

data _p_o_p_n;
   set _p_o_p_n;
   length start $200;
   %if &_tmttyp_ = C %then %do;
      start = &tmtvar;
      %end;
   %else %if &_tmttyp_ = N %then %do;
      start = put(&tmtvar,16.);
      %end;
   run;

%* Only keep track of count for population of interest, but do it
%* this way to make sure _ALL_ levels of TMTVAR are accounted for,
%* even if they dont occur in this particular population ;
proc transpose data=_p_o_p_n
               out=_p_o_p_n(keep=start _1 rename=(_1=N)) ;
  by start ;
  var _freq_ ;
  id pop ;
  run ;


%* Count the number of levels of treatment ;
%let dsid=%sysfunc(open(_p_o_p_n,i)) ;
%let _tmtlev_ = %sysfunc(attrn(&dsid,NOBS)) ;
%let _tmtnum_ = %sysfunc(varnum(&dsid,N)) ;

%* Create a local array of variables for output MV names assigning
%* any specified variables to the first levels, and filling in missing
%* levels with a default of "LEVEL#", and fill their values with the
%* counts ;
%let _tmttot_ = 0 ;
%do i = 1 %to &_tmtlev_ ;
  %local __mv&i ;
  %let __mv&i = %scan(&outmv,&i,%str( )) ;
  %if %quote(&&__mv&i)= %then %let __mv&i = LEVEL&i ;
  %global &&__mv&i ;
  %let rc = %sysfunc(fetchobs(&dsid,&i)) ;
  %let rc = %sysfunc(getvarn(&dsid,&_tmtnum_)) ;
  %if &rc=. %then %let &&__mv&i = 0 ;
  %else %do ;
    %let &&__mv&i = &rc ;
    %let _tmttot_ = %eval(&_tmttot_ + &rc) ;
  %end ;
%end ;

%* Do the same thing for total across all levels ;
%local __mvt ;
%let __mvt = %scan(&outmv,&i,%str( )) ;
%if %quote(&__mvt)= %then %let __mvt = TOTAL ;
%global &__mvt ;
%let &__mvt = &_tmttot_ ;

%let rc = %sysfunc(close(&dsid)) ;

%* Now figure out where the treatment format is ;
%let _fmtsrc_ = %sysfunc(getoption(fmtsearch)) ;
%put ------ _fmtsrc_ = *&_fmtsrc_*;

%if %quote(&_fmtsrc_)~= %then
  %let _fmtsrc_ = %substr(&_fmtsrc_,2,%eval(%length(&_fmtsrc_)-2)) ;

%let _fmtsrc_ = WORK &_fmtsrc_ LIBRARY ;


%let i = 1 ;
%let rc = 0 ;
%let w = %scan(&_fmtsrc_,&i,%str( ));

%do %while(%bquote(&w)^= & &rc=0) ;
  %* See if it has a format matching the specified TMTFMT ;
  %if %sysfunc(cexist(&w..FORMATS))>0 %then %do;
    proc format lib=&w..FORMATS cntlout=p_o_p_n_ ;
      select %substr(&tmtfmt,1,%eval(%length(&tmtfmt)-1));
      run ;

    %let dsid = %sysfunc(open(p_o_p_n_,i)) ;
    %let rc = %sysfunc(attrn(&dsid,NOBS)) ;
    %let dsid = %sysfunc(close(&dsid)) ;
    %end;

  %let i = %eval(&i + 1);
  %let w = %scan(&_fmtsrc_,&i,%str( ));

  %if &i > 3 %then %goto leave;
%end ;

%if &rc=0 %then %do ;
  %put WARNING: (POP_N) Cannot find TMTFMT=&tmtfmt.... will not make format. ;
  %goto leave ;
%end ;

%* Build a new format based on existing format, just tacking on Ns ;

data _p_o_p_n ;
  length label start end $200 ;
  merge  p_o_p_n_(keep=start label)
        _p_o_p_n (keep=start n) ;
  by start ;
  length fmtname $8 extra $15 type $1 ;

  %if &_tmttyp_=C %then %do ;
    fmtname = "%substr(&outfmt,2,%eval(%length(&outfmt)-2))" ;
    type = "C" ;
  %end ;
  %else %do ;
    fmtname = "%substr(&outfmt,1,%eval(%length(&outfmt)-1))" ;
    type = "N" ;
  %end ;

  end = start ;

  if n>.Z then extra = "&split.(N=" || compress(put(n,8.)) || ')' ;
  else extra = "&split.(N=0)" ;

  if label=' ' then label='???' || extra ;
  else label = trim(label) || extra ;

  run ;

proc format cntlin=_p_o_p_n;
  run;


%leave:

%mend pop_N;
 %else %if %sysfunc(vartype(&dsid,&_popnum_))=C %then %do ;
    %put ERROR: (POP_N) POP=&pop must be a numeric indicator variable. ;
    %goto leave ;
  %end ;
  %let _tmtnum_=%sysfunc(varnum(&dsid,&tmtvar)) ;
  %if ~&_tmtn/users/d33/jf97633/sas_y2k/macros/prefix.sas                                                        0100664 0045717 0002024 00000004221 06633724507 0021534 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ Program Name: PREFIX.SAS
/
/ Program Version: 2.1
/
/ Program purpose: Concatenates a common prefix to a list of variables.
/
/ SAS Version: 6.12
/
/ Created By: John H. King
/ Date:
/
/ Input Parameters:
/
/            STRING - List of variables.
/            PREFIX - Character(s) to be added to variables listed in STRING.
/
/ Output Created:
/
/            A list of variables corresponding to those listed in STRING, with the character(s)
/            specified in PREFIX added to each word.
/
/ Macros Called: None.
/
/ Example Call:
/
/            %let varlist = age sex height;
/            %let newlist = %prefix(&varlist, new);
/
/================================================================================================
/ Change Log
/
/    MODIFIED BY: Jonathan Fry
/    DATE:        10DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 2.1.
/    ----------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    ----------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    ----------------------------------------------------------------------
/================================================================================================*/

%MACRO PREFIX(STRING,PREFIX);

      /*
      / JMF001
      / Display Macro Name and Version Number in LOG
      /-----------------------------------------------------------------*/

      %put ----------------------------------------------------;
      %put NOTE: Macro called: PREFIX.SAS   Version Number: 2.1;
      %put ----------------------------------------------------;


   %LOCAL COUNT WORD NEWLIST DELM;
   %LET DELM  = %STR( );
   %LET COUNT = 1;
   %LET WORD  = %SCAN(&STRING,&COUNT,&DELM);
   %DO %WHILE(%QUOTE(&WORD)~=);
      %LET NEWLIST = &NEWLIST &PREFIX.&WORD;
      %LET COUNT   = %EVAL(&COUNT + 1);
      %LET WORD    = %SCAN(&STRING,&COUNT,&DELM);
      %END;
   &NEWLIST
   %MEND prefix;
                                                                                                                                                                                                                                                                                                                                                                               /users/d33/jf97633/sas_y2k/macros/pvlst.sas                                                         0100775 0045717 0002024 00000013526 06633725247 0021424 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ Program name: pvlst.sas
/
/ Program version: 2.1
/
/ Program purpose: Takes a list of variables and creates arrays of macro
/                  variables containing the variable names and also the
/                  variable labels.
/
/ SAS version: 6.12 TS020
/
/ Created by:
/ Date:
/
/ Input parameters: list - list of variables
/                   exclude -
/                   data - dataset to use
/                   root - root name for all variables
/                   croot - root name character variables
/                   nroot - root name numeric variables
/
/ Output created:
/
/ Macros called:
/
/ Example call:
/
/                %pvlst(data=test,list=_character_,root=b);
/
/============================================================================
/ Change log:
/
/     MODIFIED BY: Jonathan Fry
/     DATE:        10DEC1998
/     MODID:       JMF001
/     DESCRIPTION: Tested for Y2K compliance.
/                  Add %PUT statement for Macro Name and Version Number.
/                  Change Version Number to 2.1.
/     -------------------------------------------------------------------
/     MODIFIED BY:
/     DATE:
/     MODID:       XXX002
/     DESCRIPTION:
/     -------------------------------------------------------------------
/     MODIFIED BY:
/     DATE:
/     MODID:       XXX003
/     DESCRIPTION:
/     -------------------------------------------------------------------
/============================================================================*/

%macro pvlst(list = ,
          exclude = ,
             data = _LAST_,
             root = _PVL,
            croot = _CRV,
            nroot = _NMV);

   /*
   / JMF001
   / Display Macro Name and Version Number in LOG
   /------------------------------------------------------------*/

   %put ---------------------------------------------------;
   %put NOTE: Macro called: PVLST.SAS   Version Number: 2.1;
   %put ---------------------------------------------------;


   %if &sysver<6.07 %then %do;
      %put NOTE: SYSVER=&sysver;
      %put NOTE: Macro PVLST requires version 6.07;
      %if &sysenv=BACK %then %do;
         %put NOTE: Ending SAS session due to errors;
         ;endsas;
         %end;
      %end;

   %local i;
   %if "&list"="" %then %do;
      %global &croot.0 &croot &nroot.0 &nroot;
      %let &croot.0 = 0;
      %let &nroot.0 = 0;
      data _null_;
         set &data;
         array _ary{*} _numeric_;
         array _bry{*} _character_;
         _xcl_ = upcase("&exclude");
         length _vname_ $8 _root_ $20 _label_ $40;
         _jj_ = 0;
         do _II_ = 1 to dim(_ary);
            call vname(_ary{_ii_},_vname_);
            if indexw(_xcl_,trim(_vname_)) then continue;
            _jj_ + 1;
            _root_ = "__pvn"!!left(put(_jj_,8.));
            call symput(_root_,trim(_vname_));

            call label(_ary{_ii_},_label_);
            _root_ = "__pvnl"!!left(put(_jj_,8.));
            call symput(_root_,trim(_label_));
            end;
         call symput("__pvn0",left(put(_jj_,8.)));
         _jj_ = 0;
         do _II_ = 1 to dim(_bry);
            call vname(_bry{_ii_},_vname_);
            if indexw(_xcl_,trim(_vname_)) then continue;
            _jj_ + 1;
            _root_ = "__pvc"!!left(put(_jj_,8.));
            call symput(_root_,trim(_vname_));

            call label(_bry{_ii_},_label_);
            _root_ = "__pvcl"!!left(put(_jj_,8.));
            call symput(_root_,trim(_label_));
            end;
         call symput("__pvc0",left(put(_jj_,8.)));
         stop;
         run;
      %if &syserr>0 %then %do;
         %put NOTE: SYSERR=&syserr;
         %put NOTE: Data step ERRORS in macro PVLST;
         %if &sysenv=BACK %then %do;
            %put NOTE: Ending SAS session due to errors;
            ;endsas;
            %end;
         %end;
      %let &nroot.0 = &__pvn0;
      %do i = 1 %to &__pvn0;
         %global &nroot&i &nroot.L&i;
         %let    &nroot&i   = &&&__pvn&i;
         %let    &nroot.L&i = &&&__pvnl&i;
         %let    &nroot = &&&nroot &&&__pvn&i;
         %end;
      %put NOTE: Numeric variables: &nroot=&&&nroot;
      %put NOTE: Macro variable array &nroot has &&&nroot.0 elements.;
      %let &croot.0 = &__pvc0;
      %do i = 1 %to &__pvc0;
         %global &croot&i &croot.L&i;
         %let    &croot&i   = &&&__pvc&i;
         %let    &croot.L&i = &&&__pvcl&i;
         %let    &croot = &&&croot &&&__pvc&i;
         %end;
      %put NOTE: Character variables: &croot=&&&croot;
      %put NOTE: Macro variable array &croot has &&&croot.0 elements.;
      %end;
   %else %do;
      %global &root.0 &root;
      %let &root.0 = 0;
      data _null_;
         set &data;
         array _ary{*} &list;
         _xcl_ = upcase("&exclude");
         length _vname_ $8 _root_ $20 _label_ $40;
         _jj_ + 0;
         do _II_ = 1 to dim(_ary);
            call vname(_ary{_ii_},_vname_);
            if indexw(_xcl_,trim(_vname_)) then continue;
            _jj_ + 1;
            _root_ = "__pvt"!!left(put(_jj_,8.));
            call symput(_root_,trim(_vname_));

            call label(_ary{_ii_},_label_);
            _root_ = "__pvtl"!!left(put(_jj_,8.));
            call symput(_root_,trim(_label_));
            end;
         call symput("__pvt0",left(put(_jj_,8.)));
         stop;
         run;
      %if &syserr>0 %then %do;
         %put NOTE: SYSERR=&syserr;
         %put NOTE: Data step ERRORS in macro PVLST;
         %if &sysenv=BACK %then %do;
            %put NOTE: Ending SAS session due to errors;
            ;endsas;
            %end;
         %end;
      %let &root.0 = &__pvt0;
      %do i = 1 %to &__pvt0;
         %global &root&i &root.L&i;
         %let    &root&i   = &&&__pvt&i;
         %let    &root.L&i = &&&__pvtl&i;
         %let    &root = &&&root &&&__pvt&i;
         %end;
      %put NOTE: Expanded varlist: &root=&&&root;
      %put NOTE: Macro variable array &root has &&&root.0 elements.;
      %end;
   %mend pvlst;
                                                                                                                                                                          /users/d33/jf97633/sas_y2k/macros/ranksum.sas                                                       0100775 0045717 0002024 00000042655 06633726174 0021741 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ PROGRAM NAME: ranksum.sas
/
/ PROGRAM VERSION: 1.1
/
/ PROGRAM PURPOSE: The ranksum macro performs the rank sum test for differences
/   in two independent populations, and calculates the analagous confidence
/   interval on the (median difference).  It creates an output dataset
/   containing the results of these caculations.
/
/   At first glance this macro may seem to work in a rather strange way.
/   The reason for this design is mostly due to the fact that depending on the
/   size of the data this macro can compute literally thousands of
/   observations in the intermediate statges.  This data is then sorted and
/   the values of interest are extracted.  Therefore each level of the
/   by variable is processed as an independent data set in the hopes that
/   each of these units will be small enought not to exceed the size of
/   the work library.
/
/
/ SAS VERSION: 6.12 (UNIX)
/
/ CREATED BY: John Henry King
/
/ DATE: 1992.
/
/ INPUT PARAMETERS:
/
/   data=       specifies the input data set name.  The default is _LAST_.
/
/   out=        specifies the name of the output data set.  See
/               (Output Data Set Variables( for a descriptions of the variables
/               The default is _WRSTOUT.
/
/   by=         specifies a list of by variables. A value must be specified.
/               The default is null.  I will try to find some time later to
/               allow the macro to have no by values.  I originally wrote it
/               this was because I invisioned that the user would almost
/               always have more that one VISIT, LAB parameter, whatever.
/
/   basis=      specifies a value of the class-variable which should be used
/               as the basis of comparison.  A value must be specified.
/               The default setting is null.
/
/   class=      specifies the name of the class variable which identifies
/               the groups (e.g. treatments) that you would like to compare.
/               There must be only 2 levels of this variable, and the macro
/               currently does no check this.
/
/   var=        Specifies the name of the variable that you are testing.
/               The default is Y.
/
/   maxdec=     specifies the number of decimal places to use in the confidence
/               intervals in the output data set.  This parameter affects the
/               value of _CI, see output details below, and not the actual
/               values of the CI.
/
/   alpha=      specifies the alpha level at which to perform the test and
/               construct the confidence intervals.  The default is .05.
/               Producing 95% CIs.
/
/   drop=       specifies the variables you would like to drop from the output
/               data set.  The default list is: _sum _nn _cf _w _a _exp _rmax
/               _z _var0 _ca _ul _uu _ml _mu _ru.
/
/   debug=      used in the development stages to turn on debug print.
/               It currently has no effect.  The default setting is YES.
/
/
/ OUTPUT CREATED: The output data set contains both the results of the
/   hypothesis test and confidence interval calculations and some intermediate
/   calculations.  Many of the intermediate calculations are dropped by
/   default, but may be left in the data set by changing DROP=.  The variables
/   described below are those that are not dropped by default.
/   The value for each of the following variables applies to its corresponding
/   by-group.
/
/ The by variables listed in the BY= parameter.
/
/ _an   is the number of observations in the (basis( class group.
/ _a0   is minimum of the variable specified by VAR= in the (basis( class-group.
/ _a25  is the low quartile
/ _a50  is the median
/ _a75  is the upper quartile
/ _a100 is the maximum
/ _bn   is the number of observations in the other class-group.
/ _b0   is minimum of the variable specified by VAR= in the other class group.
/ _b25  is the lower quartile
/ _b50  is the median
/ _b75  is the upper quartile
/ _100  is the maximum
/
/ _ties is the total number of tied observations.
/ _gties is the number of ranks whose frequency if greater than 1.
/ _sec  is either the value of the class variable for the smaller of the two
/       class-groups if the class-groups are of unequal size, or the value
/       of the class-variable if the class-groups are the same size.
/ _n    is the number of observations in the class-group indicated by _sec.
/ _m    is the number of observations in the class-group not indicated by
/       _sec.
/ _tiesp is the percentage of tied observations.
/ _gtiesp is the percentage of tied rand out of all observations.
/ _ws   is the test statistic used to test the equality of the distributions
/       of the tow populations.  It is spproximately normally distributed for
/       large samples.
/ _probw is the 2-tailed probability of a larger _ws given that the population
/       distributions are equivalent (based on the normal distribution).
/ _norma is equivalent to _probw.
/ _probit is the standard normal value associated with the specified
/       alpha level.
/ _delta is the (median difference( of all possible ordered pairs.
/ _sdelta is and adjusted version of _delta (=(_upper-_lower) / (2*_probit)).
/ _lower is the lower confidence limit on _delta.
/ _upper is the upper confidence limit on _delta.
/ _ci   is the confidence interval represented as a character string:
/       (ll.llll,uu.uuuu).
/ _int  is the true confidence level of the confidence interval.  This
/       variable exsits only in small sample situations in the the confidence
/       level is not exactly 1-alpha/2.
/
/
/
/ MACROS CALLED:
/               %jkxwords
/
/ EXAMPLE CALL:
/
/           %ranksum(data = glob,
/                     out = stats,
/                      by = visit,
/                   basis = 1,
/                   class = group,
/                     var = glob)
/
/====================================================================================
/ CHANGE LOG:
/
/    MODIFIED BY: John Henry King
/    DATE:        03MAR1997
/    MODID:       JHK001
/    DESCRIPTION: Add standard header and other internal documentation.
/    ------------------------------------------------------------------------------
/    MODIFIED BY: John Henry King
/    DATE:        03MAR1997
/    MODID:       JHK002
/    DESCRIPTION: Change error handeling to be more standard and remove the
/                 ENDSAS.  This could be very annoying to someone trying to use
/                 this macro in interactive sas.
/    ------------------------------------------------------------------------------
/    MODIFIED BY: Jonathan Fry
/    DATE:        10DEC1998
/    MODID:       JMF003
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 1.1.
/    ------------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX004
/    DESCRIPTION:
/    ------------------------------------------------------------------------------
/===================================================================================*/

%macro ranksum(data = _last_,
                out = _WRSTOUT,
                 by = ,
              basis = ,
              class = TMT,
                var = y,
             maxdec = 4,
              alpha = .05,
               drop = _sum _nn _cf _w _a _exp _rmax _z _var0
                      _ca _ul _uu _ml _mu _ru,
              debug = YES);

   /*
   / JMF003
   / Display Macro Name and Version Number in LOG
   /------------------------------------------------------------*/

   %put -----------------------------------------------------;
   %put NOTE: Macro called: RANKSUM.SAS   Version Number: 1.1;
   %put -----------------------------------------------------;


   %let debug  = %upcase(&debug);
   %local j _by0 _byw0 _lstby _table _set;
   %let _by0   = 0;
   %let _byw0  = %jkxwords(list=&by,root=_BYW,delm=%str( ));
   %let _lstby = &&_byw&_byw0;

   /* JHK002 */
   %local edash;
   %let edash = _+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+;

   %if &basis= %then %do;
      %put ERROR: &edash;
      %put ERROR: You have not specified a BASIS variable! RANKSUM will not work!;
      %put ERROR: &edash;
      %goto endmac;
      %end;
   %if &by= %then %do;
      %put ERROR: &edash;
      %put ERROR: You have not specified a BY variable! RANKSUM will not work!;
      %put ERROR: &edash;
      %goto endmac;
      %end;

 /*%sysdump(_lstby) */

   /*
   / JHK001
   /
   / For each level of the by group find the first observation and last
   / observation.  These value are written to a macro variable array in
   / the from of a data set option.
   /   FIRSTOBS=value OBS=value.
   / The macro variables _BY1 to _BYn hold the code fragements.
   / Macro variable _BY0 gives the dimension of this array.
   /
   /-------------------------------------------------------------------------*/

   data _null_;
      set &data(keep=&by) end=eof;
      by &by;
      retain firstobs 0;
      if first.&_lstby then firstobs=_n_;
      if last.&_lstby then do;
         _BY_ + 1;
         length str $60;
         str = 'FIRSTOBS='!!trim(left(put(firstobs,8.)))
                          !!' OBS='!!trim(left(put(_n_,8.)));
         call symput('_BY'!!left(_by_),trim(str));
         end;
      if eof then call symput('_BY0',left(_by_));
      run;
   /*
   / JHK001
   /
   / Start processing from 1 to &_by0 each level of the by groups.
   /--------------------------------------------------------------------*/

   %do J = 1 %to &_by0;

      %put ------------------------------------------------;
      %put NOTE: Processing Started for _BY&j=&&_by&j ;
      %put ------------------------------------------------;

      /*
      / JHK001
      / Read the data as specified by the values of FIRSTOBS and OBS
      / given in the ith value of _BYi.
      / Remove any missing values.  Now we have a "working subset" of
      / the data.
      /-----------------------------------------------------------------*/
      data _wrst;
         do until(eof);
            set &data(&&_by&j keep=&by &class &var) end=eof;
            &var = round(&var,1e-12);
            if &class=' ' then delete;
            if &var  =' ' then delete;
            _N + 1;
            output;
            end;
         drop _n;
         run;

      /*
      / JHK001
      / Rank the values of VAR save ranks in _R
      /------------------------------------------*/
      proc rank data=_wrst out=_wrst ties=mean;
         by &by;
         var &var;
         ranks _r;
         run;

      /*
      / JHK001
      / Find the sum of the ranks and N for each level of CLASS
      /-----------------------------------------------------------*/
      proc summary data=_wrst nway;
         class &by &class;
         var _r;
         output out=_wrst2(drop=_type_ _freq_)
                  n=_nn
                sum=_sum;
         run;
      /*
      / JHK001
      / Compute descriptive statistics to be added to the output
      / data set.
      /-----------------------------------------------------------*/
      proc univariate data=_wrst noprint pctldef=5;
         by &by &class;
         var &var;
         output out=_median
                   n=_n
                 min=_0
                  q1=_25
              median=_50
                  q3=_75
                 max=_100;
         run;
      /*
      / JHK001
      / Transpose the stats from above,
      / this produces observations from variables.
      /----------------------------------------------------------*/
      proc transpose data=_median out=_median(drop=_label_);
         by &by &class;
         var _n _0 _25 _50 _75 _100;
         run;
      /*
      / JHK001
      / Compute and ID variable for the next transpose based on the
      / value of BASIS.
      /------------------------------------------------------------------*/
      data _median;
         set _median;
         by &by &class;
         length _id $8;
         if &class=&basis
            then _id='_A'!!substr(_name_,2);
            else _id='_B'!!substr(_name_,2);
         run;
      /*
      / JHK001
      / Using the ID variable from above transpose back to variables.
      /-------------------------------------------------------------------*/
      proc transpose data=_median out=_median(drop=_name_ /* _label_*/);
         by &by;
         var col1;
         id _id;
         run;

      /*
      / JHK001
      / Now the fun starts.
      / I think I will need Hollander and Wolf again to make any comments
      / on how this next few steps works.
      /-------------------------------------------------------------------*/

      /*
      / JHK001
      / Compute the number of observations for each RANK.
      /-------------------------------------------------------------------*/
      proc summary data=_wrst nway;
         class &by _r;
         output out=_cf(drop=_type_);
         run;
      /*
      / JHK001
      / From the above data compute
      /  _cf    SUM(Ri(Ri**2-1)
      /  _ties  the total number of tied observations.
      /  _gties the number of ranks whos frequency is greater than one
      /-------------------------------------------------------------------*/
      data _cf;
         _cf=0;
         do until(eof);
            set _cf end=eof;
            _cf    + _freq_*(_freq_**2-1);
            _ties  + (_freq_>1) * _freq_;
            _gties + (_freq_>1);
            end;
         drop _freq_ _r;
         run;

      /*
      / JHK001
      / Merge the three data sets from above
      /  _wrst2  the sum of the ranks
      /  _cf     the correction factor data.
      /  _median the descrptive statistics for VAR=
      /--------------------------------------------------------------------*/

      data _wrst2;
         drop &class;
         do until(eof);
            merge _wrst2 _cf _median end=eof;
            by &by;
            _n = min(_n,_nn);
            _m = max(_m,_nn);
            if _nn=_n then do;
               _ssc = &class;
               _w = _sum;
               end;
            end;
         _a      = _n*(_m+_n+1);
         _exp    = _a / 2;
         _rmax   = _n*(2*_m + _n + 1) / 2;
         _z      = _w - _exp;
         _var0   = (_m*_n/12)*((_m+_n+1)-((_cf/((_m+_n)*(_m+_n-1)))));
         _tiesp  = _ties /(_n+_m);
         _gtiesp = _gties/(_n+_m);
         _ws     = (_z - sign(_z)*.5) / sqrt(_var0);
         _probw  = min(1,2*(1-probnorm(abs(_ws))));
         _norma  = _probw;
         _probit = probit(1-&alpha/2);
         _ca     = (_m*_n/2)-_probit*sqrt(_var0);
         _Ul     = _ca;
         _Uu     = (_m * _n + 1) - _ca;
         _Ml     = floor((_m * _n + 1) / 2);
         _Mu     = ceil ((_m * _n + 1) / 2);

         call symput('_N',trim(left(put(_n,8.))));
         call symput('_M',trim(left(put(_m,8.))));
         if ((1<=_n<=10) & (1<=_m<=20))
            then call symput('_TABLE','1');
            else call symput('_TABLE','0');
         run;
      %if &_table %then %do;
         data _wrst2;
            set _wrst2;
            do point = 1 to _rmax until(.Z < _value <= (&alpha/2));
               link set;
               end;
            _UL   = _rmax - _x + 1;
            _UU   = (_m * _n + 1) - _UL;
            _int  = 1 - _value*2;
            if (_a-_x) < _w < _x
               then h0='Accept';
               else h0='Reject';
            output;
            stop;
            format _value _int 6.4;
            drop _value _x;
            return;
          Set:
            set utildata.N&_n.TO20
                  (keep=x _&_m rename=(_&_m=_value x=_x))
                point=point nobs=nobs;
            return;
            run;
         %end;
      data _u;
         array _y{&_n};
         array _x{&_m};
         set _wrst2(keep=_ssc);
         do until(eof);
            set _wrst end=eof;
            if &class=_ssc then do;
               _j + 1; _y{_j} = &var;
               end;
            else do;
               _i + 1; _x{_i} = &var;
               end;
            end;
         do _i = 1 to dim(_x);
            do _j = 1 to dim(_y);
               _U = _y{_j} - _x{_i};
               output;
               end;
            end;
         stop;
         keep _u;
         run;
      proc sort data=_u;
         by _u;
         run;
    /*proc print;*/
         run;
      data _wrst2;
         set _wrst2;
         point = round(_ul); link setu; _lower  = _u;
         point = _ml; link setu; _delta = _u;
         point = _mu; link setu; _delta = (_delta + _u) / 2;
         point = round(_uu); link setu; _upper  = _u;
         if upcase(_ssc)~=upcase(&basis) then do;
            _temp   = _lower;
            _lower  = _upper  * -1;
            _upper  = _temp   * -1;
            _delta  = _delta * -1;
            end;
         _sdelta = (_upper-_lower)/(2*_probit);
         length _CI $30;
         if &maxdec<1
            then _ru = 1;
            else _ru = input('.'!!repeat('0',&maxdec-2)!!'1',16.);

         _ci = compress('('!!put(round(_lower,_ru),16.&maxdec)!!','
                           !!put(round(_upper,_ru),16.&maxdec)!!')');
         output;
         stop;
         return;
       Setu:
         set _u point=point;
         drop _u _temp;
         run;
      data &out;
         set &_set _wrst2(drop=&drop);
         by &by;
         run;
      %let _set=&out;
      %let apprc=&syserr;
      proc delete data=_wrst _wrst2 _cf _u _median;
         run;
      %end;

  %endmac:
   %put NOTE: -----------------------------------------------------------------;
   %put NOTE: Macro RANKSUM ending execution.;
   %put NOTE: -----------------------------------------------------------------;

   %mend ranksum;
umber in LOG
   /------------------------------------------------------------*/

  /users/d33/jf97633/sas_y2k/macros/refmt.sas                                                         0100644 0045717 0002024 00000004060 06646400120 0021335 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ Program name:     REFMT.SAS
/
/ Program version:  1.1
/
/ MDP/Protocol ID:  N/A
/
/ Program Purpose:  Renames variables' corresponding valid value list formats
/                   to fit in DTAB's variable formatting scheme for the ROWS
/                   statement.
/
/                   Assumes: the valid value list format library has been
/                   assigned to a LIBREF of LIBRARY. Also that the macro PREFIX
/                   is on your SASAUTOS macro library.
/
/ SAS version:      Unix 6.12
/
/ Created by:       Scott Burroughs
/ Date:             08JAN91
/
/ Input parameters:
/
/ Output Created:
/
/ Macros called:    PREFIX.SAS
/
/ Example call:
/
/===============================================================================
/ Change Log:
/
/    MODIFIED BY: Jonathan Fry
/    DATE:        10DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 1.1.
/    -------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    -------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    -------------------------------------------------------------------
/===============================================================================*/

%MACRO refmt(varlist);

   /*
   / JMF001
   / Display Macro Name and Version number in LOG
   /-------------------------------------------------------*/

   %put ---------------------------------------------------;
   %put NOTE: Macro called: REFMT.SAS   Version Number: 1.1;
   %put ---------------------------------------------------;


   %let fmtvrlst=%prefix(&varlist,$v);

   proc format
      library = library
      cntlout = fmtlist
      ;
      select &fmtvrlst;
   run;

   data fmtlist2;
      set fmtlist;
      fmtname=substr(fmtname,2);
   run;

   proc format
      cntlin = fmtlist2
      ;
   run;

%MEND;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                /users/d33/jf97633/sas_y2k/macros/remove.sas                                                        0100664 0045717 0002024 00000004316 06633727742 0021545 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ Program Name: REMOVE.SAS
/
/ Program Version: 2.1
/
/ Program purpose: Remove all occurrences of a target from a string.
/
/ SAS Version: 6.12
/
/ Created By: Carl P. Arneson
/ Date:       25 Aug 1992
/
/ Input Parameters:
/
/              STRING - Character string to be processed by the macro.
/              TARG   - Target string to be removed from STRING by the macro.
/
/ Output Created:
/
/              A copy of STRING, with occurrences of TARG removed.
/
/ Macros Called: None.
/
/ Example Call:
/
/              %let tmt1 = Ondansetron 1000mg daily;
/              %let tmt2 = %remove(&tmt, daily);
/
/======================================================================================
/ Change Log
/
/    MODIFIED BY: Jonathan Fry
/    DATE:        10DEC1998
/    MODID:�������JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 2.1.
/    ------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:�������XXX002
/    DESCRIPTION:
/    ------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:�������XXX003
/    DESCRIPTION:
/    ------------------------------------------------------------------------
/=====================================================================================*/

%macro REMOVE(string,targ) ;

     /*
     / JMF001
     / Display Macro Name and Version Number in LOG
     /-----------------------------------------------------------*/

     %put ----------------------------------------------------;
     %put NOTE: Macro called: REMOVE.SAS   Version Number: 2.1;
     %put ----------------------------------------------------;


  %local return pos len ;
  %let len=%length(&targ);
  %let return=;
  %let pos=%index(&string,&targ);

  %do %while(&pos) ;
     %if &pos>1 %then
        %let return=&return.%qsubstr(&string,1,%eval(&pos-1));
     %if %eval(&pos + &len)<=%length(&string) %then
        %let string=%qsubstr(&string,%eval(&pos + &len));
     %else %let string=;
     %let pos=%index(&string,&targ);
  %end ;

  %let return=&return.&string;

  &return

%mend REMOVE ;
                                                                                                                                                                                                                                                                                                                  /users/d33/jf97633/sas_y2k/macros/renlst.sas                                                        0100664 0045717 0002024 00000004657 06633730736 0021564 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ Program name:      RENLST.sas
/
/ Program version:   1.1
/
/ MDP/Protocol id:   N/A
/
/ Program purpose:   Compares two strings of characters and pairs off
/                    space delimited terms.
/                    E.G If &a = 1 2 3? 5 6 and &b = a be cj d  , then
/                    %renlst(old=&a, new=&b) is
/                    1=a 2=be 3?=cj 5=d
/                    The macro iterates until there are no terms in one string.
/
/                    The macro generates a string suitable for the
/                    rename function.
/
/                    Be careful not to use the macro with unquoted
/                    strings containing the comma (parameter delimiter) or
/                    macro triggers.
/                    These will produce errors or warnings.
/
/ SAS Version:       UNIX 6.12
/
/ Created by:        M. Foxwell
/
/ Date:              31 OCT 97
/
/ Input Parameters:
/
/ Output Created:
/
/ Macros called:
/
/ Example call:
/
/===================================================================================
/ Change Log.
/
/    MODIFIED BY: Jonathan Fry
/    DATE:        10DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change version Number to 1.1.
/    -------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    -------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    -------------------------------------------------------------------
/===================================================================================*/

%macro renlst(old=,new=);

   /*
   / JMF001
   / Display Macro Name and Version Number in LOG
   /---------------------------------------------------------*/

   %put ----------------------------------------------------;
   %put NOTE: Macro called: RENLST.SAS   Version Number: 1.1;
   %put ----------------------------------------------------;


   %local i w1 w2 delm arg;
   %let delm = %str( );
   %let i = 1;
   %let w1 = %scan(&old,&i,&delm);
   %let w2 = %scan(&new,&i,&delm);
   %do %while(%quote(&w1)^= & %quote(&w2)^=);
      %let arg = &arg &w1=&w2;
      %let i = %eval(&i + 1);
      %let w1 = %scan(&old,&i,&delm);
      %let w2 = %scan(&new,&i,&delm);
      %end;
   &arg
   %mend renlst;
 one string.
/
/                    The macro generates a string suitable for the/users/d33/jf97633/sas_y2k/macros/report.sas                                                        0100775 0045717 0002024 00000046106 06633731601 0021556 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ Program name: report.sas
/
/ Program version: 2.1
/
/ Program purpose: This MACRO generates a PROC REPORT with DEFINE statements.
/                  Output is either a user-specified file or code that is
/                  immediately executed within the current SAS run.
/
/ SAS version: 6.12 TS020
/
/ Created by: Randall Austin
/ Date:       06/08/92
/
/ Input parameters: All options are optional (redundant, but true):
*                   DATA=    Input dataset (default is _last_)
*                   VARLIST= Variables (default is total dataset)
*                   LS=      Maximum number of characters per line
*                            (default is 132)
*                   SPLIT=   Split character (default is !)
*                   OUT=     Output FN. FT is REPORT. (Default is pgm name)
*                   MISSING= Turns on MISSING option in PROC REPORT.Options are
*                            MISSING (default) or anything else (becomes BLANK)
*                   MOD=     MOD=MOD or Y lets you add a number of PROC REPORT
*                            set-ups to the same output file.  Anything else
*                            is read as BLANK. (The default is BLANK.)
*                   REPOPT=  Allows user to enter special report options (e.g.,
*                            SPACING=, PANELS=, etc) in text format.  Anything
*                            entered here follows the PROC REPORT statement.
*                            (The default is BLANK).
*                   DEFOPT=  Allows user to enter special DEFINE options (e.g.,
*                   SPACING=, NOPRINT, etc) in text format.  Anything
*                            entered here follows the DEFINE statement on every
*                            record. (The default is BLANK).
*                   USAGE=   Allows user to change USAGE variable in DEFINE
*                            statement for each or all variables. Slash (/)
*                            separates VARIABLE from USAGE.  Example:
*                            USAGE=PATNO/ORDER DRUG/ACROSS
*                            To change the default for all variables omit the
*                            variable name and the slash. Example:  USAGE=ORDER
*                            (The default is DISPLAY).
*                   FLOW=    Defines FLOW variable(s) in DEFINE statement.
*                            Provide a list of variables to flow or input FLOW
*                            or Y to flow all. FLOW is automatically enabled if
*                            length of a variable exceeds 30 characters.
*                            Default is blank.
*                   JUSTIFY= Allows user to change JUSTIFY variable in DEFINE
*                            statement for each or all variables. Slash (/)
*                            separates VARIABLE from JUSTIFY.  (Default is CENTER
*                            for numeric and short character, LEFT for long
*                            character.)
*                   WIDTH=   Allows user to change WIDTH in DEFINE statement for
*                            each or all variables. Slash (/) separates VARIABLE
*                            from WIDTH.
*                   COLUMN=  Allows user input a COLUMN statement. If you input
*                            COLUMN but not VARLIST, macro will use COLUMN to
*                            guess at VARLIST.
*                            IMPORTANT: If COLUMN statement contains commas,
*                               you must enclose it in %STR().
*                   BOTLINE= BOTLINE=Y lets you add a solid underline at the
*                            bottom of the report, length calculated internally.
*                            Specify length with BOTLINE= num, where num is
*                            length. Default is BOTLINE=N.
*                   BOTCHAR= Character for BOTLINE. Default is _ .
*                   FLOWLEN= Width of column when FLOW is turned on. Default=30.
*                   CLRFMT=  CLRFMT=Y clears existing formats that
*                            begin with blank, $, or F.  Default is N.
*
*  Input Datasets:     _LAST_ (or user specified)
*  Internal Datasets:  _M_R_O_1  _M_R_O_2 _M_R_O_3 _M_R_O_C _M_R_O_N
*  Output Datasets:    REPORT.fn   (or user specified FN)
*
*  Note: The self-executing form of this macro is open-ended, i.e., you
*        may include other statements such as COMPUTE and JOBID2 after
*        the macro call and they will be included in the run.
/

/
/ Output created:
/
/ Macros called:
/
/ Example call:
/
/====================================================================================
/ Change log:
/
/    MODIFIED BY: Jonathan Fry
/    DATE:        10DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 2.1.
/    -------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    -------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    -------------------------------------------------------------------
/====================================================================================*/

%macro report(data=_LAST_,varlist=,ls=132,split=!,out=,missing=MISSING,
              mod=,repopt=,defopt=,usage=DISPLAY,justify=,clrfmt=N,
              column=,botline=N,botchar=_,flow=,width=,flowlen=30);

    /*
    / JMF001
    / Display Macro Name and Version Number in LOG
    /----------------------------------------------------------*/

    %put ----------------------------------------------------;
    %put NOTE: Macro called: REPORT.SAS   Version Number: 2.1;
    %put ----------------------------------------------------;


/*   Liberalize some option choices (allow for Y)              */
   %if %upcase(&MISSING)=Y !
       %upcase(&MISSING)=MISSING %then %let MISSING=MISSING ;
           %else %let MISSING=;
   %if %upcase(&MOD)=Y! %upcase(&MOD)=MOD %then %let MOD=MOD;
           %else %let MOD=;

   %if &out= %then %let out=%fn;
;
   %if &botline=N %then %let BOTLEN=0;

   %let CHARLST= ; %let NUMLST= ; %let S=;
   proc format;
      value __f__ 0 = '      ';
   proc contents data=&data out=_M_R_O_1 noprint;

   data _M_R_O_C _M_R_O_N; SET _M_R_O_1 end=eof;
      retain _x _z 0 ;
       %if %scan(&varlist,1)= &
         %scan(%bquote(&column),1)= %then %do;
       * If no VARLIST or COLUMN given, then use all variables ;
           _x+1;
           IF type=1 then output _M_R_O_N ;   else
           IF type=2 then output _M_R_O_C ;
       %end;

       %else %if %scan(&varlist,1)~= %then %do;
       * If a VARLIST is given, then only use specified variables ;
         _x=1;
         do while(scan("&varlist",_x)~=' ');
           choice=upcase(compress(scan("&varlist",_x)));
           if NAME= choice and type=1 then output _M_R_O_N ; else
           if NAME= choice and type=2 then output _M_R_O_C ;
           _x=_x+1;
         end;

           _x=_x-1;
       %end;

       %else %do;
       * If only COLUMN is given, then guess at desired variables ;
         _x=1;
         do while(scan("%bquote(&column)",_x)~=' ');
           choice=upcase(compress(scan("%bquote(&column)",_x)));
           if NAME= choice and type=1 then do;
              _z=_z+1;
              output _M_R_O_N ;
           end;else
           if NAME= choice and type=2 then do;
              _z=_z+1;
              output _M_R_O_C ;
           end;
           _x=_x+1;
         end;
           _x = _z ;*  Record the number of 'hits' ;
       %end;

         if eof then do;
           call symput("NWANT",_x);
           if "&data"="_LAST_" then
              call symput("DATA",compress(libname !! "." !! memname));
         end;
run;

    data _NULL_ ; set _M_R_O_N ; by libname;
         length numlst $200;
         retain numlst;
         numlst = left(trim(numlst)) !! ' ' !! NAME ;
            if last.libname then do;
              call symput("NUMLST",left(trim(NUMLST)));
            END;

    data _NULL_ ; set _M_R_O_C;by libname;
         length numlst $200;
         retain numlst;
         numlst = left(trim(numlst)) !! ' ' !! NAME ;
            if last.libname then do;
              call symput("CHARLST",left(trim(NUMLST)));
            END;
   run;
   /*-----------------------------------------------------------------
   / now read the input data and calculate
   / 1) calculated length for character and numeric vars
   / 2) calculated formats for each var
   /-----------------------------------------------------------------*/
   data _M_R_O_3 ;
         set &data(keep=&CHARLST &NUMLST) end=eof;
         length name $8 ;
         keep _format_ name _length_ ;
    %if &NUMLST ~= %then %do;
         retain NA1-NA200 NB1-NB200;
         array __N {*} &NUMLST ;
         array NA  {*} NA1 - NA200 ;
         array NB  {*} NB1 - NB200 ;
         length __best __dig1-__dig2 $32;

         do _x=1 to dim(__N) ;
            __best = put(__N(_x),best32.);
            __dig1 = left(scan(__best,1,'.'));
            __dig2 = left(scan(__best,2,'.'));
            NA(_x)=max(1,length(__dig1)-(__dig1=' '),NA(_x));
            NB(_x)=max(length(__dig2)-(__dig2=' '),NB(_x));

            if eof then do;
              _format_=put( (NB(_x)>0) + NB(_x) + NA(_x),4.)!!'.'!!
                       left(put(NB(_x),__F__.));
              _length_=NB(_x)+NA(_x)+min(1,NB(_x)*1);
              call vname(__N{_x},NAME);
                output;
            end;
         end;
    %end;
    %if &CHARLST ~= %then %do;
         retain CL1-CL200 ;
         array __C {*} $200 &CHARLST ;
         array __CL {*} cl1-cl200;
         do _z=1 to dim(__C) ;
            __CL{_z} = max(__CL{_z},length(__C{_z})-(__C{_z}=' '));
            CFM= put(max(__CL{_z},1),4.)!!'.';
            if eof then do;
             substr(CFM,verify(CFM,' ')-1,1)='$';
              _format_=CFM;
              _length_=__CL{_z};
              call vname(__C{_z},NAME);
                output;
            end;
         end;
    %end;
   *-------------------------------------------------------------------*
   ! Find desired print-order of requested variables
   *-------------------------------------------------------------------;
   proc sort data=_M_R_O_3 out=_M_R_O_3 ;  by NAME ;
   proc sort data=_M_R_O_1 out=_M_R_O_1 ;  by NAME ;

%IF &varlist= %THEN %DO;
   data _NULL_ ;
      merge _M_R_O_1 _M_R_O_3(in=WANTED) end=eof;by NAME ;
        _var_cnt= VARNUM ;

     /*     (This data step code joins up with more down below)   */

%END; %ELSE %DO;

   data _M_R_O_2 ;
     _x=1;
     do while(scan("&varlist",_x)~=' ');
        NAME = upcase(compress(scan("&varlist",_x)))  ;
        _var_cnt= _x ;
        output;
        _x=_x+1;
     end;
   proc sort data=_M_R_O_2 out=_M_R_O_2 ; by NAME;

   *-------------------------------------------------------------------*
   ! Select from the dataset only those variables requested
   *-------------------------------------------------------------------;
   data _null_ ;
     merge _M_R_O_1 _M_R_O_3 _M_R_O_2(in=WANTED);
       by NAME ;
%END;
       IF WANTED;

     *-----------------------------------------------------------------*
     ! If we already have a specified format (e.g., DATE7.), we want to
     ! use that length instead of the calculated length.
     *-----------------------------------------------------------------;
     if formatl > 0 then _length_=formatl;

          length fmt $16 ;
          fmt = input(compress(trim(format)!!
                put(formatl,__F__.)!!'.'!!put(formatd,__F__.)),$16.);
          if fmt='.' ! fmt=' ' !
            (upcase("&CLRFMT")="Y" &
              (format=' ' ! format='$' ! format='F'))
                then fmt=_format_;

          if fmt='...' then do;
               put "ERROR:  You have specified a variable in VARLIST"
                   " called " NAME    ;
               put "        that is not in %upcase(&data)." ;
               put "        This program will terminate.";
               call symput("S","ENDSAS");
           end;

          if label~=' ' then lab=label;  else lab=NAME;

   ***********************************************************;
   ** if we have split-delimiters in our labels, find the ****;
   ** longest segment for WIDTH parameter                 ****;
   ***********************************************************;

   if index(lab,"&split") then do;
          * find the length of the longest delimited segment ;
            _comp_  = lab ;
            _labcnt = 1 ;
          do while(index(_comp_,"&split")>0);
             _wordpos=index(_comp_,"&split");
              if _labcnt=1 then
                 _wordlen=_wordpos-1;
              _oldpos =_wordpos;
             substr(_comp_,index(_comp_,"&split"),1)=' ';
             _labcnt+1 ;
          end;*   now find the length of the tail-end segment ;
             _wordlen=max(_wordlen,length(_comp_) - _oldpos);
   end; else _wordlen=length(lab);
   ***********************************************************;

          width=max(_wordlen,_length_);

     call symput("NAME"!!compress(_var_cnt),NAME);
     if fmt ne ' ' then
        call symput("FMT"!!compress(_var_cnt),compress("FORMAT="!!FMT));
     else
        call symput("FMT"!!compress(_var_cnt),compress(" "));

     length usage $8. jst $8. flow $8. ;
    *------------------------------------------------------------------*
    ! Set FLOW parameter and change individual values or global default
    *------------------------------------------------------------------;
    if type = 2 & _length_ > &FLOWLEN
      then FLOW='FLOW'; * AutoFlow if > &FLOWLEN chars;
    *****  User-Defined FLOW for DEFINE statement                ;
             _zz=1;
            do while (scan("&FLOW",_zz) ne ' ');
             if upcase(scan("&FLOW",_zz))=upcase(NAME) then FLOW="FLOW";
             _zz+1;
            end;
    *****  User is allowed to set FLOW as default for all ;
   if upcase("&FLOW") = "FLOW" ! upcase("&FLOW") = "Y"
      then flow="FLOW" ;
      if flow ne 'FLOW' then flow=' ';

      if flow="FLOW" & _length_ > &FLOWLEN
        then width=max(_wordlen,&FLOWLEN);

    *------------------------------------------------------------------*
    ! Set USAGE parameter and change individual values or global default
    *------------------------------------------------------------------;
    usage='DISPLAY';
    *****  User-Defined USAGE for DEFINE statement                ;
    if index("&USAGE","/") then do;
            _xx=1;
            do while (scan("&USAGE",_xx) ne ' ');
              if upcase(scan("&USAGE",_xx))=upcase(NAME) then
                 USAGE=scan("&USAGE",_xx+1);
              _xx+2;
            end;
    end;

    *****  User is allowed to provide a new default USAGE for all ;
   if scan("&USAGE",1) ~= ' ' & scan("&USAGE",2) = ' '
    then usage="&USAGE"     ;
    usage=upcase(USAGE)     ;
    *****  CHECK for VALID USAGE                               ;
    IF usage ne 'ACROSS' &     usage ne 'ANALYSIS' &
       usage ne 'COMPUTED' &   usage ne 'DISPLAY' &
       usage ne 'GROUP' &      usage ne 'ORDER' then usage=' ' ;

    *------------------------------------------------------------------*
    ! Set JUSTIFY parameter and change individual values or default
    *------------------------------------------------------------------;
    if type = 2 & _length_ > 5 then JST='LEFT'; else JST='CENTER';
    *****  User-Defined JUSTIFY for DEFINE statement                ;
    if index("&JUSTIFY","/") then do;
            _xx=1;
            do while (scan("&JUSTIFY",_xx) ne ' ');
              if upcase(scan("&JUSTIFY",_xx))=upcase(NAME) then
                 JST=scan("&JUSTIFY",_xx+1);
              _xx+2;
            end;
    end;

    *****  User is allowed to provide a new default JUSTIFY for all ;
   if scan("&JUSTIFY",1) ne ' ' & scan("&JUSTIFY",2) = ' '
    then jst="&JUSTIFY"  ;
    jst=upcase(jst);
    *****  CHECK for VALID JUSTIFY                                ;
    IF JST ne 'CENTER' &  JST ne 'RIGHT' &
       JST ne 'LEFT'   then JST=' ';

    *------------------------------------------------------------------*
    ! Set WIDTH parameter and change individual values or default
    *------------------------------------------------------------------;
    *****  User-Defined WIDTH for DEFINE statement                ;
    if index("&WIDTH","/") then do;
            _xz=1;
            do while (scan("&WIDTH",_xz) ne ' ');
              if upcase(scan("&WIDTH",_xz))=upcase(NAME) then
                 width=scan("&WIDTH",_xz+1)*1;
              _xz+2;
            end;
    end;

    *****  User is allowed to provide a new default WIDTH for all ;
   if scan("&WIDTH",1) ne ' ' & scan("&WIDTH",2) = ' '
    then width="&WIDTH"*1;

     if LABEL=' ' then LABEL=compress(NAME);

     *-----------------------------------------------------------------*
     ! Calculate the length of the headline so we can add a footline
     ! to match.  Assume the default spacing = 2.
     *-----------------------------------------------------------------;
      retain botlen 0 ;
      botlen= width + 2 + botlen ;
      botput= put(botlen-2,3.0);

     if upcase("&botline") = "Y" then
       call symput("BOTLEN",compress(botput));
     else
     if indexc("&botline","1234567890") then
       call symput("BOTLEN",compress("&botline"));

     call symput("TITLE"!!compress(_var_cnt),left(trim(LABEL)));
     call symput("WIDTH"!!compress(_var_cnt),compress("WIDTH="!!WIDTH));
     call symput("USG"!!compress(_var_cnt),compress(USAGE));
     call symput("JST"!!compress(_var_cnt),compress(JST));
     call symput("FLOW"!!compress(_var_cnt),compress(FLOW));
run;
&S;

   %if %upcase(&out) ~= N %then %do;
/**********************************************************************
 * Produce a PROC REPORT setup and save to an ASCII file
 *********************************************************************/
       data _null_ ;
          file "&out..report" &mod ;
PUT "PROC REPORT NOWD DATA=&data CENTER HEADLINE HEADSKIP LS=&ls COLWIDTH=8";
PUT "            &MISSING SPLIT=""&SPLIT"" &REPOPT.;"  ;
%if %scan(%bquote(&COLUMN),1)= %then %do;
PUT "COLUMN ";
        %do _x=1 %to &NWANT ;
PUT " &&NAME&_X ";
        %end;
PUT ";";
%end; %else
PUT "COLUMN %bquote(&COLUMN);";;
        %do _x=1 %to &NWANT ;
PUT
"DEFINE &&NAME&_X / &&USG&_X &&FMT&_X &&WIDTH&_X "
 "&&JST&_X &&FLOW&_X &DEFOPT"
 /  "                  %str(%")&&TITLE&_X.%str(%");";
        %end;
%if &BOTLEN~=0 %then %do;
PUT "COMPUTE AFTER;";
PUT "LINE &BOTLEN*%str(%')&BOTCHAR.%str(%');";
PUT "ENDCOMP;";
%end;

PUT "RUN;";

   %end;  %else %do;
/**********************************************************************
 * Produce a PROC REPORT setup and run PROC REPORT
 *********************************************************************/

PROC REPORT NOWD DATA=&data CENTER HEADLINE LS=&ls COLWIDTH=8 SPLIT="&SPLIT"
                 HEADSKIP &repopt ;
COLUMN
%if %scan(%bquote(&COLUMN),1)= %then %do;
        %do _x=1 %to &NWANT ;
 &&NAME&_X
        %end;
%end; %else &COLUMN ;
;
        %do _x=1 %to &NWANT ;
DEFINE &&NAME&_X / &&USG&_X &&FMT&_X &&WIDTH&_X &&JST&_X &&FLOW&_X
       &DEFOPT "&&TITLE&_X";
        %end;
%if &BOTLEN~=0 %then %do;
compute after ;
line &BOTLEN * "&BOTCHAR" ;
endcomp;
%put "Bottom Line Length= &BOTLEN";
%end;
   %end;
%mend report;
ig1=' '),NA(_x));
            NB(_x)=max(length(__dig2)-(__dig2=' '),NB(_x));

            if eof then do;
              _format_=put( (NB(_x)>0) + NB(_x) + NA(_x),4.)!!'.'!!
                       left(put(NB(_x),__F__.));
              _length_=NB(_x)+NA(_x)+min(1,NB(_x)*1);
              call vname(__N{_x},NAME);
                output;
            end;
         end;
    %end;
    %if &CHARLST ~= %then %do;
         retain CL1-CL200 ;
/users/d33/jf97633/sas_y2k/macros/report_macros.sas                                                 0100664 0045717 0002024 00000034132 06411436663 0023117 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ PROGRAM NAME: title.sas
/  Generic listing program using PROC REPORT
/
/ PROGRAM VERSION: 1.01
/
/ PROGRAM PURPOSE: Assemble components of title lines into valid title
/   statements. For use with proc report applications.
/
/
/ SAS VERSION: 6.12 (UNIX)
/
/ CREATED BY: John Henry King, from the original by Bill Stanish.
/
/ DATE: 1997
/
/ INPUT PARAMETERS: NONE, the macro uses the global macro variables 
/    title1l-title10l 
/    title1r-title10r
/    title1c-title10c
/ 
/ OUTPUT CREATED:
/
/ MACROS CALLED:
/
/ EXAMPLE CALL: %dotitle
/
/==============================================================================
/ CHANGE LOG:
/
/ MODIFIED BY: John Henry King
/ DATE: 22MAY1997
/ MODID: 
/ DESCRIPTION: This macro was rewritten to use a more efficient method of 
/   creating the titles.  The old version used %QTRIM and was very slow.
/   
/------------------------------------------------------------------------------
/ MODIFIED BY: John Henry King
/ DATE: 19AUG1997
/ MODID: JHK001
/ DESCRIPTION: Fixed bug in DEVLINE section that I caused when I convert the 
/              macro for UNIX.
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK002
/ DESCRIPTION:
/============================================================================*/

*---------------------------------------------------------------
*  Project:    Generic listing program using PROC REPORT
*  Purpose:    Assemble components of title lines into valid title
*              statements. For use with proc report applications.
*  File Name:  bio$stat_utl:[sasmacros]title.sas
*  Created by: Bill Stanish, Statistical Insight
*  Date:       January 5, 1995
*  NOTES:      For use with the generic listing program
*                bio$stat_utl:[sasmacros]report.sas
*  History:    4/19/95  wms  Fixed centering bug when #byval used
*---------------------------------------------------------------;

%*---Initialize title macro variables---;

%let lastloc  = ;      
%let lastword = ;      
%let divline  = ;   
%let lachar   = ;

%let title1l = ' ';   %let title1c = ' ';   %let title1r = ' ';   
%let title2l = ' ';   %let title2c = ' ';   %let title2r = ' ';   
%let title3l = ' ';   %let title3c = ' ';   %let title3r = ' ';   
%let title4l = ' ';   %let title4c = ' ';   %let title4r = ' ';   
%let title5l = ' ';   %let title5c = ' ';   %let title5r = ' ';   
%let title6l = ' ';   %let title6c = ' ';   %let title6r = ' ';   
%let title7l = ' ';   %let title7c = ' ';   %let title7r = ' ';   
%let title8l = ' ';   %let title8c = ' ';   %let title8r = ' ';   
%let title9l = ' ';   %let title9c = ' ';   %let title9r = ' ';   
%let title10l= ' ';   %let title10c= ' ';   %let title10r= ' ';   

/*
/ ---Define some options and macro variables---
/--------------------------------------------------------*/

%macro div;

   /*
   / ---Set up line-across character and divider line---
   /-------------------------------------------------------*/


   /*
   / JHK001
   /----------*/

   %if %upcase(&linetype) = SOLID %then %do;
      data _null_;
         lachar   = 'd0'x;
         formchar = '|----|+|---+=|-/\<>*';
         substr(formchar,2,1) = lachar;
         call symput('formchar', formchar);
         call symput('lachar'  , lachar);
         run;
      options formchar = "&formchar";
      %end;

   %else %let lachar = %str(-);

   %let divline = %str(%')%sysfunc(repeat(&lachar, &linesize-1))%str(%');
   %put NOTE: divline=&divline;

   /*
   / ---Set up byline option, linesize, and pagesize---
   /-------------------------------------------------------------*/

   %let byln = %upcase(&bylines);
   %if &byln = SUPPRESS or &byln = SUPRESS %then %do;
      %if &sysver = 6.07 %then %do;  %* Because of a bug in SAS 6.07;
         %let newps = %eval(&pagesize+2);
         options noovp nodate nonumber ls=&linesize ps=&newps nobyline;
         %end;
      %else %do;
         options noovp nodate nonumber ls=&linesize ps=&pagesize nobyline;
         %end;
      %end;
   %else %do;
      options noovp nodate nonumber ls=&linesize ps=&pagesize byline;
      %end;
   %mend div;

%div;


/* 
/ ---The title macro---
/---------------------------------*/
%macro dotitles;


   %if &sysver >= 6.12 %then %do;
      /*
      / Construct the titles
      /------------------------*/

      data _null_;

         length emsg $6;
         emsg = reverse(':RORRE');

         array title[10] $&linesize _temporary_;

         %unquote(array tl[10] $&linesize _temporary_ 
            ( &title1l , &title2l , &title3l , &title4l , &title5l ,
              &title6l , &title7l , &title8l , &title9l , &title10l );)

         %unquote(array tr[10] $&linesize _temporary_ 
            ( &title1r , &title2r , &title3r , &title4r , &title5r ,
              &title6r , &title7r , &title8r , &title9r , &title10r );)

         %unquote(array tc[10] $&linesize _temporary_ 
            ( &title1c , &title2c , &title3c , &title4c , &title5c ,
              &title6c , &title7c , &title8c , &title9c , &title10c );)



         do i = 1 to dim(title);
            bvalflag = 0;

            /*
            / check for use of #BY and issue error message if there is 
            / a problem
            /-----------------------------------------------------------*/

            if index(upcase(tr[i]),'#BY') then do;
               put emsg 'Title lines containing BY values may be formed from'
                        ' the left or center component, but not the right component.';
               end;

            if ((index(upcase(tl[i]),'#BY')>0) + (index(upcase(tc[i]),'#BY')>0)) > 1 then do;
               put emsg 'Title lines containing BY values may have '
                        'only one component: left or center.  You have specified '
                        '> 1 components for title' i;
               end;

            if tl[i] > ' ' then title[i] = tl[i];

            if tc[i] > ' ' then do;
               if index(upcase(tc[i]),'#BY') then bvalflag = 1;
               substr
                  (
                     title[i],
                     floor( (&linesize-length(tc[i]) ) / 2 ),
                     length(tc[i])
                  ) = tc[i];
               end;

            if tr[i] > ' ' then do;
               substr
                  (
                     title[i],
                     &linesize - length(tr[i]) + 1,
                     length(tr[i])
                  ) = tr[i];
               end;
   


            if title[i] > ' ' then do;
               if bvalflag then do;
                  call 
                     execute
                        (
                           'TITLE'||trim(left(put(i,2.)))
                           ||
                           ' "'
                           ||
                           trim(left(title[i]))
                           ||
                           '";'
                        );
                  end;
               else do;
                  call 
                     execute
                        (
                           'TITLE'||trim(left(put(i,2.)))
                           ||
                           ' "'
                           ||
                           title[i]
                           ||
                           '";'
                        );
                  end;
               end;
            end; 
         run;

      %end;
   %else %do;
      %put ERROR: this version of dotitles is only for SAS 6.12 or higher.;
      %end;

   %mend dotitles;

/*
/ PROGRAM NAME: footnote.sas, 
/  Generic listing program using PROC REPORT
/
/ PROGRAM VERSION: 1.01
/
/ PROGRAM PURPOSE: Left-justify the footnote lines, preserving leading
/  blanks. For use with proc report applications.
/
/ SAS VERSION: 6.12 (UNIX)
/
/ CREATED BY: John Henry King, from the original by Bill Stanish.
/
/ DATE: 1997
/
/ INPUT PARAMETERS: NONE, the macro uses the global macro variables 
/    foot1-foot10 to create left justified footnotes.
/ 
/ OUTPUT CREATED:
/
/ MACROS CALLED:
/
/ EXAMPLE CALL: %footnote
/
/==============================================================================
/ CHANGE LOG:
/
/ MODIFIED BY: John Henry King
/ DATE: 22MAY1997
/ MODID: 
/ DESCRIPTION: This macro was rewritten to use a more efficient method of 
/   creating the titles.  The old version used %QTRIM and was very slow.
/   
/------------------------------------------------------------------------------
/ MODIFIED BY: 
/ DATE: 
/ MODID: JHK001
/ DESCRIPTION: 
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK002
/ DESCRIPTION:
/============================================================================*/

*---------------------------------------------------------------
*  Project:    Generic listing program using PROC REPORT
*  Purpose:    Left-justify the footnote lines, preserving leading
*              blanks. For use with proc report applications.
*  File Name:  bio$stat_utl:[sasmacros]footnote.sas
*  Created by: Bill Stanish, Statistical Insight
*  Date:       January 5, 1995
*  NOTES:      For use with the generic listing program
*                bio$stat_utl:[sasmacros]report.sas
*---------------------------------------------------------------;

/*
/ ---Initialize foot macro variables---
/--------------------------------------------*/

%let foot1 = ' ';   %let foot6 = ' ';
%let foot2 = ' ';   %let foot7 = ' ';
%let foot3 = ' ';   %let foot8 = ' ';
%let foot4 = ' ';   %let foot9 = ' ';
%let foot5 = ' ';   %let foot10= ' ';

/*
/ ---Define the footnote lines---
/--------------------------------------------*/

%macro footnote;

   %if &sysver >= 6.12 %then %do;

      data _null_;
         %unquote(array foot[10] $&linesize _temporary_
                     ( &foot1 , &foot2 , &foot3 , &foot4 , &foot5 ,
                       &foot6 , &foot7 , &foot8 , &foot9 , &foot10 );)

         do i = 1 to dim(foot);
            if foot[i] > ' ' then do;
               call 
                  execute
                     (
                        'FOOTNOTE'||trim(left(put(i,2.)))
                        ||
                        ' "'
                        ||
                        foot[i]
                        ||
                        '";'
                     );
               end;
            end;
         run;
     %end;
   %else %do;
      %put ERROR: this macro is for SAS 6.12 or higher.;
      %end;
   %mend footnote;

/*
/ PROGRAM NAME: page2.sas
/  Generic listing program using PROC REPORT
/
/ PROGRAM VERSION: 1.01
/
/ PROGRAM PURPOSE: Read a data listing from temporary file, insert  
/   page numbers and total number of pages.          
/   Write to permanent file.                         
/
/ SAS VERSION: 6.12 (UNIX)
/
/ CREATED BY: Bill Stanish.
/
/ DATE: 1995
/
/ INPUT PARAMETERS: NONE, the macro uses the global macro variables 
/    foot1-foot10 to create left justified footnotes.
/ 
/ OUTPUT CREATED: Writes to &outfile the contents of temp&time with the pages
/   numbered. 
/
/ MACROS CALLED: none
/
/ EXAMPLE CALL: %page2
/
/==============================================================================
/ CHANGE LOG:
/
/ MODIFIED BY: John Henry King
/ DATE: 22MAY1997
/ MODID: 
/ DESCRIPTION: Modified for use on UNIX.
/   
/------------------------------------------------------------------------------
/ MODIFIED BY: 
/ DATE: 
/ MODID: JHK001
/ DESCRIPTION: 
/------------------------------------------------------------------------------
/ MODIFIED BY:
/ DATE:
/ MODID: JHK002
/ DESCRIPTION:
/============================================================================*/

/*---------------------------------------------------------------
*  Project:    Generic listing program using PROC REPORT
*  Purpose:    Read a data listing from temporary file, insert
*              page numbers and total number of pages.
*              Write to permanent file.
*  File Name:  bio$stat_utl:[sasmacros]page2.sas
*  Created by: Bill Stanish, Statistical Insight
*  Date:       January 5, 1995
*  NOTES:      For use with the generic listing program
*                bio$stat_utl:[sasmacros]report.sas
*---------------------------------------------------------------*/

/*
/ ---Initialize global variable outside of macro---
/---------------------------------------------------------*/
%let page = ;

/*
/ Macro that reads in an appendix, inserts page numbers  
/ and the total number of pages.                         
/---------------------------------------------------------------*/

%macro page2;

   /*
   / ---Compute number of pages in the file---
   /-----------------------------------------------*/

   data _null_;
      infile "temp&time" length=len missover end=lastrec;
      input;
      retain nrec 0;  


      nrec = nrec + 1;
      if lastrec then do;
         numpage = ceil(nrec / &pagesize);
         call symput('numpage', trim(left(put(numpage,6.))));
         end;
      run;

   /*
   / ---Fill in the page number info---
   /--------------------------------------------------------*/

   data _null_;
      file   "&outfile"  notitles noprint ll=ll n=ps;
      infile "temp&time" length=len missover end=lastrec;

      input line $varying200. len @1 @;
      length string $ 20;
      retain pg firstlin 0;

      /*
      / ---Insert page numbers at top of each page---
      / '0c'x  vms new page character 
      / ascii 12 or hex '0c' is the UNIX new page character.
      /-----------------------------------------------------*/
      if substr(line,1,1) = byte(12) then do;  
         firstlin = 1;
         end;

      ind = index(line, 'Page of');
      rp  = index(line, 'Page of)');

      if ind then do;
         pg + 1;
         if rp 
            then string = "Page " || trim(left(put(pg,4.))) || " of &numpage)";
            else string = "Page " || trim(left(put(pg,4.))) || " of &numpage";
         j = length(string);
         substr(line,ind,j) = string;
         end;
   
      put @1 line $varying200. len;
      run;

   /*
   / ---Delete the temporary file---
   /---------------------------------------------*/

   data _null_; 
      rc  = filename('_temp_',"temp&time"); 
      rc  = fdelete('_temp_'); 
      run;


   /*
   / ---Reset titles and footnotes to blank---
   /---------------------------------------------*/
   title ' ';
   footnote ' ';

   %mend page2;
e if there is 
            / a problem
            /-----------------------------------------------------------*/

            if index(upcase(tr[i]),'#BY') then do;
               put emsg 'Title lines containing BY values may be formed from'
                        ' the left or center component, but not the right component.';
               end;

            if ((index(upcase(tl[i]),'#BY')>0) + (index(upcase(tc[i]),/users/d33/jf97633/sas_y2k/macros/report_shell.sas                                                  0100664 0045717 0002024 00000037164 06411436653 0022751 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        options noovp mprint;
/*--------------------------------------------------------------------
*  Project:
*  Purpose:
*  File Name:
*  Created by:
*  Date:
*  -----------------------------------------------------
*  Original File Information
*  Purpose:    Generic listing program using PROC REPORT
*  File Name:  bio$stat_utl:[sasmacros]report.sas
*  Created by: Bill Stanish, Statistical Insight
*  Date:       January 5, 1995
*-------------------------------------------------------------------*/

/*-------------------------------------------------------------------*
*  Specify a name to identify the output file.                       *
*                                                                    *
*  Examples: %let outfile = demog.l08;                               *
*            %let outfile = bio$stat_ran:[ranXXX.appendices]aa.l08;  *
*-------------------------------------------------------------------*/
%let outfile = report_shell.l08;

/*-------------------------------------------------------------------*
*  Specify the linesize and pagesize.                                *
*                                                                    *
*  Example: For landscape orientation, point size 8, use             *
*           %let linesize = 135;   %let pagesize = 43;               *
*                                                                    *
*  NOTE: Do not specify linesize or pagesize in an options           *
*        statement. This is done in one of the macros.               *
*-------------------------------------------------------------------*/
%let linesize = 135;
%let pagesize =  43;

/*-------------------------------------------------------------------*
*  Specify the type of line that should be used to separate header   *
*  lines from data lines, data lines from footnote lines, etc.       *
*  The default is dashed lines.                                      *
*                                                                    *
*  Examples: %let linetype = solid;    * To use solid lines;         *
*            %let linetype = dashed;   * To use dashed lines;        *
*                                                                    *
*  NOTE: To have these                                               *
*  lines appear ...             Specify                              *
*  --------------------------   -----------------------------------  *
*  below the page headers       &divline as the last title line      *
*                                                                    *
*  between the column headers   the HEADLINE option on the PROC      *
*    and the data lines           REPORT statement                   *
*                                                                    *
*  above the footnotes          &divline as the first footnote line  *
*-------------------------------------------------------------------*/
%let linetype = dashed;
%let linetype = solid;

/*-------------------------------------------------------------------*
*  Indicate whether the bylines (if any) should be suppressed.       *
*                                                                    *
*  Statement                 Meaning                                 *
*  ------------------------  ------------------------------------    *
*  %let bylines = ;          1. No BY statement will be used in      *
*                               the PROC REPORT step,  or            *
*                            2. Print the usual bylines generated    *
*                               by the procedure.                    *
*                                                                    *
*  %let bylines = suppress;  The usual bylines will be suppressed.   *
*                            Choose this if you prefer to print the  *
*                            by-values in the title lines. See the   *
*                            title instructions below for details.   *
*                                                                    *
*  NOTE: If the value of this macro variable is set incorrectly,     *
*        it may result in the wrong pagesize for the output file.    *
*-------------------------------------------------------------------*/
%let bylines = suppress;


*================ Custom Data Preparation Step ====================;

*---Print numeric missing values as '*'---;
options missing='*' nonumber;

*---Define libnames as needed---;
libname sasdata xport '../ran492/ran492.xpt';



*---Get the data, and sort it---;
data work;
  set sasdata.cmed;

  *---Restrict population for this example so output file is small---;
  if substr(patient,3,1) = '2';

  *---Create some new variables---;
  if medpre  ^= ' ' then dstart = 'Pre-trial';  else dstart = medstdt;
  if medpost ^= ' ' then dstop  = 'Post-trial'; else dstop  = medspdt;

  *---Print character missing values as '*'---;
  if meddos = ' ' then meddos = '*';
  if medut  = ' ' then medut  = '*';
  if medfq  = ' ' then medfq  = '*';
  if medrt  = ' ' then medrt  = '*';
  if dstart = ' ' then dstart = '*';
  if dstop  = ' ' then dstop  = '*';
run;
proc sort; by l_tmt invcd patient visit; run;


*============= Title and Footnote Preparation Step =============;

*------------------Include the needed macros------------------;

%inc 'report_macros.sas'; 

/*------------------------------------------------------------------*
*                       Set up titles                               *
*                                                                   *
*  You can specify up to 10 title lines by specifying text strings  *
*  that will be either left-justified, centered, or right-justified *
*  on the indicated lines.                                          *
*                                                                   *
*  To left-justify    Use macro variable names that end in 'l'.     *
*  some text on ..    For example, ...                              *
*  ---------------   ---------------------------------------------  *
*      Line 1        %let title1l = 'Protocol RAN-123';             *
*      Line 2        %let title2l = 'Ranitidine Tablets';           *
*      Line 3        %let title3l = 'Population: All Patients';     *
*       etc.                                                        *
*                                                                   *
*  To center          Use macro variable names that end in 'c'.     *
*  some text on ..    For example, ...                              *
*  ---------------   ---------------------------------------------  *
*      Line 1        %let title1c = 'Protocol RAN-123';             *
*      Line 2        %let title2c = 'Ranitidine Tablets';           *
*      Line 3        %let title3c = 'Population: All Patients';     *
*       etc.                                                        *
*                                                                   *
*  To right-justify   Use macro variable names that end in 'r'.     *
*  some text on ..    For example, ...                              *
*  ----------------  ---------------------------------------------  *
*      Line 1        %let title1r = 'Protocol RAN-123';             *
*      Line 2        %let title2r = 'Ranitidine Tablets';           *
*      Line 3        %let title3r = 'Population: All Patients';     *
*       etc.                                                        *
*                                                                   *
*                                                                   *
*  EXAMPLE: To create the following 3 titles:                       *
*  ------------------------------------------                       *
*  Appendix 8.3                                  Ranitidine Study   *
*                                                    All Patients   *
*                           DEMOGRAPHICS                            *
*                                                                   *
*  you would specify the following statements:                      *
*                                                                   *
*    %let title1l = 'APPENDIX 8.3';                                 *
*    %let title1r = 'Ranitidine Study';                             *
*    %let title2r = 'All Patients';                                 *
*    %let title3c = 'DEMOGRAPHICS';                                 *
*                                                                   *
*  Special Features Available                                       *
*  --------------------------                                       *
*  1. You can use macro variable references in the titles, provided *
*     that you use double quotes (") rather than single quotes (')  *
*     to enclose the title string.                                  *
*                                                                   *
*  2. You can use the macro variable reference &divline to specify  *
*     a divider line that stretches across the entire width of the  *
*     page. Do not enclose it in quotes: %let title4l = &divline;   *
*                                                                   *
*  3. You can number the pages in one of three ways.                *
*     a. For page numbers in the upper right-hand corner of each    *
*        page, specify the statement: %let page = upper right;      *
*        Be careful not to right-justify a title on line 1 in this  *
*        case, since the page number will over-write the last word. *
*        However, you could use a statement like the following:     *
*            %let title1r = 'Protocol S2B-353   X';                 *
*        since only the X would be overwritten by the page number.  *
*     b. For the form '(Page 1 of 57)', specify the string          *
*        '(Page of)' at the end of a left-justified or centered     *
*        title text string.                                         *
*     c. For the form 'Page 1 of 57', specify the string            *
*        'Page of' at the end of a left-justified or centered       *
*        title text string.                                         *
*                                                                   *
*  4. If you want the titles to contain data values that correspond *
*     to the records on that page, then you need to use a BY        *
*     statement in the PROC REPORT step.  In that case, you can     *
*     insert the by-values into a title line in one of 2 ways:      *
*                                                                   *
*     Suppose the BY statement is:  by ptcd invcd;                  *
*                                                                   *
*     a. You can use:                                               *
*        #byval1 to refer to values of first  by-variable (ptcd)    *
*        #byval2 to refer to values of second by-variable (invcd)   *
*                                                                   *
*     b. You can use:                                               *
*        #byval(ptcd) to refer to values of ptcd                    *
*        #byval(invcd) to refer to values of invcd                  *
*                                                                   *
*     There is 1 restriction for inserting by-values. For any title *
*     line in which you insert by-values, you may specify only      *
*     one text component: either the left-justified text string or  *
*     the centered text string (but not the right-justified one).   *
*                                                                   *
*  EXAMPLES                                                         *
*  ------------------------------------------------                 *
*  %let page = ;                                                    *
*  %let title1l = "APPENDIX &appnum  (Page of)";                    *
*  %let title1r = 'DEMOGRAPHICS';                                   *
*  %let title2r = 'Patient Listing:  All Patients';                 *
*  %let title3l = 'Investigator: #byval(invid)';                    *
*  %let title4l = &divline;                                         *
*-------------------------------------------------------------------*/
%let page = upper right;

%let title1l = "APPENDIX 8.7  (Page of)";
%let title3l = 'Protocol RAN-492';
%let title5l = 'Randomized Treatment: #byval(l_tmt)';

%let title1r = 'CONCURRENT MEDICATION';
%let title2r = 'Patient Listing:  All Patients';
%let title3r = '      with Numbers Ending in 2';
%let title6l = &divline;

/*------------------------------------------------------------------*
*                       Set up footnotes                            *
*                                                                   *
*  You can specify up to 10 footnotes by defining macro variables   *
*  foot1-foot10 as text strings (or as data step expressions that   *
*  result in text strings). As with title definitions, macro        *
*  variable references may be used inside the strings, provided     *
*  that the strings are enclosed in double quotes (").              *
*                                                                   *
*  You can use the macro variable reference &divline to specify     *
*  a divider line that stretches across the entire width of the     *
*  page. Do not enclose it in quotes: %let foot1 = &divline;        *
*                                                                   *
*  EXAMPLES                                                         *
*  --------                                                         *
*  %let foot1 = &divline;                                           *
*  %let foot2 = '* Indicates missing data.';                        *
*  %let foot3 = 'A blocking factor of 6 was used in ' ||            *
*               'generating all random codes.';                     *
*  %let foot4 = '[1] This footnote illustrates that the second';    *
*  %let foot5 = '    line of a footnote may be indented easily.';   *
*  %let foot6 = &divline;                                           *
*  %let foot7 = "&vmssasin : &sysdate";                             *
*-------------------------------------------------------------------*/
%let foot1 = &divline;
%let foot2 = '* Indicates missing data.';
%let foot3 = "    This footnote has leading blanks and an unmatched single' quote"; 
%let foot4 = &divline;
%let foot5 = "m:\utl\sasmacro\report02.sas: &sysdate";

*---Call the title and footnote macros---;

%dotitles;

%footnote;


*======================= Proc Report Step =========================;

*---Generate macro variable containing current time---;
data _null_; 
   call symput('time', trim(left(put(time(),12.))) ); 
   run;

*---Send the proc report output to a temporary file---;
proc printto file="temp&time" new;  run;

%*---Produce the report---;
proc report data=work headline nowindows split='~' missing;
  by l_tmt;
  column invcd patient medtx meddos medut medfq medrt dstart dstop
    medindtx;
  break after patient / skip;
  define invcd    / order                   'Inv.';
  define patient  / order                   'Patient'
                    center  width=7;
  define medtx    / display                 'Drug Name'
                            width=20  flow;
  define meddos   / display                 'Unit Dose';
  define medut    / display                 'Units';
  define medfq    / display                 'Freq';
  define medrt    / display                 'Route';
  define dstart   / display                 'Date~Started';
  define dstop    / display                 'Date~Stopped';
  define medindtx / display                 'Indication'
                            width=30  flow;
run;

*---Close the temporary output file---;
proc printto;  run;

*==================== Output File Modification =====================;
options mprint;

*---Read temp file, & insert page numbers and total no. of pages---;
%page2;
   *
*                                                                   *
*  To left-justify    Use macro variable names that end in 'l'.     *
*  some text on ..    For example, ...                              *
*  ---------------   ---------------------------------------------  *
*      Line 1        %let title1l = 'Protocol RAN-123';             *
*      Line 2        %let title2l = 'Rani/users/d33/jf97633/sas_y2k/macros/reverse.sas                                                       0100775 0045717 0002024 00000003122 06633747245 0021720 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ Program name: reverse.sas
/
/ Program version: 2.1
/
/ Program purpose: Reverse the value of a SAS macro variable
/
/ SAS version: 6.12 TS020
/
/ Created by:
/ Date:
/
/ Input parameters: ARG - SAS macro variable
/
/ Output created:
/
/ Macros called: None
/
/ Example call:
/
/              %let revname=%reverse(&name);
/
/==========================================================================
/ Change log:
/
/    MODIFIED BY: Jonathan Fry
/    DATE:        10DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 2.1.
/    -------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    -------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    -------------------------------------------------------------------
/==========================================================================*/

%MACRO REVERSE(ARG);

   /*
   / JMF001
   / Display Macro Name and Version Number in LOG
   /------------------------------------------------------------*/

   %put -----------------------------------------------------;
   %put NOTE: Macro called: REVERSE.SAS   Version Number: 2.1;
   %put -----------------------------------------------------;


   %local i reverse;
   %do i = %length(&arg) %to 1 %by -1;
      %let reverse = %quote(&reverse)%qsubstr(&arg,&i,1);
      %end;
   &reverse
%mend Reverse;
                                                                                                                                                                                                                                                                                                                                                                                                                                              /users/d33/jf97633/sas_y2k/macros/sasautos.sas                                                      0100664 0045717 0002024 00000007034 06633750671 0022107 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ Program Name: SASAUTOS.SAS
/
/ Program Version: 4.1
/
/ Program purpose: Include a standard SASAUTOS statment in an OPTIONS statement
/
/ SAS Version: 6.12
/
/ Created By: Carl Arneson
/ Date:       6 Feb 1995
/
/ Input Parameters: PROJ = MDP name (GOLD studies)
/                          Project ID number (ex-Wellcome studies)
/
/ Output Created:
/
/ Macros Called: %datatyp (provided by SAS)
/
/ Example Call:  %sasautos(proj=S3A);
/
/============================================================================================
/ Change Log
/
/    MODIFIED BY: SR Austin
/    DATE:        19SEP95
/    MODID:       001
/    DESCRIPTION: If proj num starts with a number, put P in front, otherwise assume
/                 its a GLAXO-type name and take as given.
/    --------------------------------------------------------------------------------
/    MODIFIED BY: S Mallett
/    DATE:        18MAR97
/    MODID:       002
/    DESCRIPTION: Pathnames changed in accordance with the subdirectory
/                 structure on UNIX (UKWSV17) platform.
/    --------------------------------------------------------------------------------
/    MODIFIED BY: S Mallett
/    DATE:        11APR97
/    MODID:       003
/    DESCRIPTION: Pathnames changed in accordance with the revised subdirectory
/                 structures on UNIX (UKWSV17/USSUN9A) platforms.
/    --------------------------------------------------------------------------------
/    MODIFIED BY: John Henry King
/    DATE:        18Janurary1998
/    MODID:       JHK004
/    DESCRIPTION: Parameter to add the PRE-IDSG macro to the search order.
/    --------------------------------------------------------------------------------
/    MODIFIED BY: Jonathan Fry
/    DATE:        10DEC1998
/    MODID:       JMF005
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 4.1.
/    --------------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX006
/    DESCRIPTION:
/    --------------------------------------------------------------------------------
/=============================================================================================*/

%macro SASAUTOS (proj = ,
                 use  = IDSG,
                );

   /*
   / JMF005
   / Display Macro Name and Version Number in LOG
   /--------------------------------------------------------------*/

   %put ------------------------------------------------------;
   %put NOTE: Macro called: SASAUTOS.SAS   Version Number: 4.1;
   %put ------------------------------------------------------;


sasautos=(

%let projdir = %sysget(PD);
%let use     = %upcase(&use);

%* Docman reference not needed at present;
%* %if &_docman_ = 1 %then %do ;
%*            "/export/opt/wellcome/csd/sas/macros/docman",
%* %end ;

%* Users'' personal macros;
"~/sas/macros",

%* Project area macros;
%if %length(&proj)>0 %then %do ;
  %if %datatyp(%substr(&proj,1,1))=NUMERIC %then %do;
    "&projdir/p&proj/utility/macros",
  %end;
  %else %do;
    "&projdir/&proj/utility/macros",
  %end;
%end ;

   /*
   / JHK004
   / Adding %IF for USE= parmater.
   /--------------------------------------------------------------*/

   %if (%index(PREIDSG PRE_IDSG PRE-IDSG PRE IDSG,%bquote(&use)) & %length(%bquote(&use))>=7) %then %do;
      "/usr/local/medstat/sas/macros/pre_idsg",
      %end;


%* Departmental macros;
    "/usr/local/medstat/sas/macros",

%* SAS supplied macros;
    "!SASROOT/sasautos")

%mend SASAUTOS;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    /users/d33/jf97633/sas_y2k/macros/setsys.sas                                                        0100664 0045717 0002024 00000022061 06633753611 0021571 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ Program name: setsys.sas
/
/ Program version: 4.1
/
/ Program purpose: This is the macro called in the AUTOEXEC.SAS.
/
/    1) Uses SYSGET to make global macro variables from various
/       unix environment variables.
/
/    2) Determine the pathname of the program that is being executed.
/
/    3) Issue LIBNAME and FILENAME statements for system level data libraries
/       and catalogs.
/
/    4) Print a little information about what was done.
/
/
/
/ SAS version: 6.12
/
/ Created by: John Henry King
/
/ Date: 12MAR1998
/
/ Input parameters:
/   utildata = /usr/local/medstat/sas/data,
/              Gives the directory name from utility data.  This includes
/              data from gold AEs grouping etc. and data used by RANKSUM and SIGNRNK
/              for table lookup.
/
/   utilfmt  = /usr/local/medstat/sas/formats,
/              Gives the directory for GOLD format library.
/
/   utilgdev = /usr/local/medstat/sas/gdevice,
/              Gives the directory for SAS/GRAPH device drivers.
/
/   gdevnum  = 0,
/              Gives number for GDEVICE libname.
/
/   utiltmpl = /usr/local/medstat/sas/template,
/              Gives directory of SAS/GRAPH template catalog.
/
/   utilscl  = /usr/local/medstat/sas/scl,
/              Gives directory of SCL catalog.  These SCL programs are used by
/              macros GETOPTS and BWGETTF.
/
/   utiliml  = /usr/local/medstat/sas/iml,
/              Gives directory of SAS/IML catalog.  Currently this directory is empty.
/
/   debug    = 0
/              Debug switch.
/
/
/ Output created: The macro creates a number of global macro variables and issues
/    libname and filename statements.
/
/
/ Macros called: NONE:
/
/ Example call: %setsys()
/
/==========================================================================================
/ Change log:
/
/    MODIFIED BY: John Henry King
/    DATE:        20APR1998
/    MODID:       JHK001
/    DESCRIPTION: The macro was completely rewritten to remove UNIX system
/                 commands and include the functions that were being done by
/                 STATINIT and JOBINFO macros.
/    ------------------------------------------------------------------------------
/    MODIFIED BY: Jonathan Fry
/    DATE:        10DEC1998
/    MODID:       JMF002
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 4.1.
/    ------------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    ------------------------------------------------------------------------------
/==========================================================================================*/

%macro setsys (
               utildata = /usr/local/medstat/sas/data,
               utilfmt  = /usr/local/medstat/sas/formats,
               utilgdev = /usr/local/medstat/sas/gdevice,
               gdevnum  = 0,
               utiltmpl = /usr/local/medstat/sas/template,
               utilscl  = /usr/local/medstat/sas/scl,
               utiliml  = /usr/local/medstat/sas/iml,
               debug    = 0
              );

   /*
   / JMF002
   / Display Macro Name and Version Number in LOG
   /--------------------------------------------------------------------*/

   %put ----------------------------------------------------;
   %put NOTE: Macro called: SETSYS.SAS   Version Number: 4.1;
   %put ----------------------------------------------------;


   /*
   / Use PRINTTO to suppress messages to the SAS log
   /--------------------------------------------------------------------*/
   %if ^&debug %then %do;
      filename dummy dummy;
      proc printto log=dummy;
         run;
      %end;


   /*
   / define global and local macro variables
   /----------------------------------------------------------------------*/

   %global _docman_  projdir sasin logname;
   %local
      output proj temp sassysin fn
      rc1  rc2  rc3  rc4  rc5  rc6
      msg1 msg2 msg3 msg4 msg5 msg6
      ;


   /*
   / Define macro variables that come from system environment variables.
   / OUTPUT and PROJ are usually blank until set in a MAKE file.
   /----------------------------------------------------------------------*/

   %if %bquote(&sysscp)=%str(SUN 4) %then %do;
      %let projdir = %sysget(PD);
      %let output  = %sysget(OUTPUT);
      %let proj    = %sysget(PROJ);
      %let logname = %sysget(LOGNAME);
      %end;


   %else %if %bquote(&sysscp)=%str(WIN) %then %do;
      %let projdir = %sysget(PD);
      %let output  = %sysget(OUTPUT);
      %let proj    = %sysget(PROJ);
      %let logname = %sysget(USERNAME);
      %end;

   /*
   / Set DOCMAN switch if output directory, or proj directory is specified
   / The DOCMAN switch is used by MACPAGE to control various actions
   / associated with the publishing system.
   /-----------------------------------------------------------------------*/
   %if %bquote(&output)= | %bquote(&proj)=
      %then %let _docman_ = 0;
      %else %let _docman_ = 1;

   /*
   / Get the sas program name that is currently being executed.
   / I am trying to keep this within SAS, i.e. no unix pipes etc.
   /
   / The value of SYSIN may not always be the fully qualified name.
   / Therefore I will issue a FILEREF using the value of SYSIN and then
   / use the PATHNAME function to return the full path name.
   /-----------------------------------------------------------------------*/

   %let sassysin = %sysfunc(getoption(sysin));

   %if %bquote(&sassysin)= %then %do;
      %let sasin = INTERACT.IVE;
      %end;
   %else %do;
      filename autotemp "&sassysin";
      %let sasin = %sysfunc(pathname(autotemp));
      filename autotemp clear;
      %end;

   /*
   / SYSPARM is used by MACPAGE for the JOBID information.
   /-----------------------------------------------------------------------*/
   %let sysparm  = &logname:&sasin;

   /*
   / Get just the filename part of SASIN to use in the FILENAME statement below.
   /-------------------------------------------------------------------------------*/
   %let fn = %sysfunc(reverse(%substr(%sysfunc(reverse(&sasin)),1+%index(%sysfunc(reverse(&sasin)),.)) ));

   /*
   / Issue system level libnames
   /-------------------------------------------------------------------------*/
   %let rc1      = %sysfunc(libname(utildata,&utildata,,access=readonly));
   %let msg1     = %sysfunc(sysmsg());
   %let utildata = %sysfunc(pathname(utildata));

   %let rc2      = %sysfunc(libname(library,&utilfmt,,access=readonly));
   %let msg2     = %sysfunc(sysmsg());
   %let utilfmt  = %sysfunc(pathname(library));

   %let rc3      = %sysfunc(libname(utilscl,&utilscl,,access=readonly));
   %let msg3     = %sysfunc(sysmsg());
   %let utilscl  = %sysfunc(pathname(utilscl));

   %let rc4      = %sysfunc(libname(utiliml,&utiliml,,access=readonly));
   %let msg4     = %sysfunc(sysmsg());
   %let utiliml  = %sysfunc(pathname(utiliml));

   %let rc5      = %sysfunc(libname(gdevice&gdevnum,&utilgdev,,access=readonly));
   %let msg5     = %sysfunc(sysmsg());
   %let utilgdev = %sysfunc(pathname(gdevice&gdevnum));

   %let rc6      = %sysfunc(libname(utiltmpl,&utiltmpl,,access=readonly));
   %let msg6     = %sysfunc(sysmsg());
   %let utiltmpl = %sysfunc(pathname(utiltmpl));



   /*
   / Issue filename for UTILGSF.
   / If a fn.gsf file exists delete it.  We want to start the program with
   / no GSF from the last time it was executed.
   /--------------------------------------------------------------------------*/
   filename utilgsf "&fn..gsf";
   %if %sysfunc(fexist(utilgsf)) %then %let rc = %sysfunc(fdelete(utilgsf));

   %if ^&debug %then %do;
      proc printto;
         run;
      filename dummy clear;
      %end;

   %put NOTE: ----------------------------------------------------------------------------------;
   %put NOTE: The following global macro variables have been created or altered:;
   %put NOTE:   PROJDIR  = *&projdir*;
   %put NOTE:   _DOCMAN_ = *&_docman_*;
   %put NOTE:   SYSPARM  = *&sysparm*;
   %put NOTE:   SASIN    = *&sasin*;
   %put NOTE:   LOGNAME  = *&logname*;
   %put NOTE:;
   %put NOTE: The following LIBREFS have been created.;
   %if &rc1=0
      %then %put NOTE:   UTILDATA = &utildata (dat_dict dis_dict grpvw ingvw invcnty invest stdunits);
      %else %put &msg1;

   %if &rc2=0
      %then %put NOTE:   LIBRARY = &utilfmt (Gold FORMATS, valid value formats, $MIDAS., etc.);
      %else %put &msg2;

   %if &rc3=0
      %then %put NOTE:   UTILSCL  = &utilscl (SCL Catalogs sclutl and topslog);
      %else %put &msg3;


   %if &rc4=0
      %then %put NOTE:   UTILIML  = &utiliml (IML Catalog currently this catalog is empty);
      %else %put &msg4;

   %if &rc5=0
      %then %put NOTE:   GDEVICE&gdevnum = &utilgdev (SAS/GRAPH device driver catalog);
      %else %put &msg5;

   %if &rc6=0
      %then %put NOTE:   UTILTMPL = &utiltmpl (SAS/GRAPH template catalog);
      %else %put &msg6;

   %put NOTE: ;
   %put NOTE: The following FILEREF has been created.;
   %put NOTE:   UTILGSF  = &fn..gsf;
   %put NOTE: ----------------------------------------------------------------------------------;

   %mend;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                               /users/d33/jf97633/sas_y2k/macros/settitle.sas                                                      0100664 0045717 0002024 00000021330 06661047643 0022074 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ Program Name:     SETTITLE.SAS
/
/ Program Version:  2.2
/
/ Program Purpose:  Place the titles for the current program from the titles
/                   data set into global macro variables
/
/ SAS Version:      6.12 TS020
/
/ Created by:       Carl 'Shifty' Arneson
/ Date:
/
/ Input Parameters:
/
/ Output Created:
/
/ Macros Called:
/
/ Example Call:
/
/============================================================================================
/ Change Log:
/
/    MODIFIED BY: SR Austin
/    DATE:        13Dec1994
/    MODID:
/    DESCRIPTION: Added LABEL macro variable
/    ----------------------------------------------------------------------------------
/    MODIFIED BY: SR Austin
/    DATE:        17Jan1995
/    MODID:
/    DESCRIPTION: Added Old-Style section in case macro is inadvertantly called by an
/                 old-style project. Old-style is recognized by lack of LABEL variable
/                 in titles dataset.
/    ----------------------------------------------------------------------------------
/    MODIFIED BY: SR Austin
/    DATE:        27Mar1995
/    MODID:
/    DESCRIPTION: If table number is missing, add a mock number
/    ----------------------------------------------------------------------------------
/    MODIFIED BY: SR Austin
/    DATE:        16May1995
/    MODID:
/    DESCRIPTION: DOCMAN Types must be T, F, or A
/    ----------------------------------------------------------------------------------
/    MODIFIED BY: SR Austin
/    DATE:        25Oct1995
/    MODID:
/    DESCRIPTION: Allow 5-digit protocol identifiers.
/    ----------------------------------------------------------------------------------
/    MODIFIED BY: SR Austin
/    DATE:        04Oct1996
/    MODID:
/    DESCRIPTION: Allow DATA LISTING to be a valid TYPE indicating an Appendix.
/    ----------------------------------------------------------------------------------
/    MODIFIED BY: SR Austin
/    DATE:        13May1996
/    MODID:
/    DESCRIPTION: Fixed bug whereby missing table nums were not being assigned.
/    ----------------------------------------------------------------------------------
/    MODIFIED BY: John 'Dufus' King
/    DATE:        20oct1997
/    MODID:       JHK001
/    DESCRIPTION: Change section that created MACTYPE to allow for the 5 SWIFT table
/                 types and retain APPENDIX one of the old types.
/    ---------------------------------------------------------------------------------
/    MODIFIED BY: Jonathan Fry
/    DATE:        10DEC1998
/    MODID:       JMF002
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 2.2.
/    ---------------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    ---------------------------------------------------------------------------------
/============================================================================================*/

%macro SETTITLE(
                fn=%fn,              /* File name of current program (e.g., %fn)  */
                number=tabnum,       /* Numbering field to use (TABNUM or REFNUM) */
                dset=in.title&prot.  /* TITLES data set to use                    */
               ) ;

      /*
      / JMF002
      / Display Macro Name and Version Number in LOG
      /-----------------------------------------------------*/

      %put ------------------------------------------------------;
      %put NOTE: Macro called: SETTITLE.SAS   Version Number: 2.2;
      %put ------------------------------------------------------;

      %put NOTE: Using PROTOTYPE version of the SETTITLE macro.;
      %put Contact Carl Arneson if you experience problems.    ;

%* see if we have a title file name that is too long ;
%if "&dset."="in.title&prot." & %length(&prot) > 3 %then
   %let dset=in.t&prot.;
%*---------------------------------------------------------------------*;
%* check to see if we are using old-style or new-style titles system   *;
%local style; %let style=OLD;
options nodsnferr ;
proc contents data=&dset noprint out=___c_out(keep=name);
data _null_; set ___c_out(where=(name="LABEL"));
  call symput("style","NEW");
run;
options dsnferr;
%* if default dataset is specified, then use the old-style default;
%if &style=OLD & &dset=in.title&prot %then %let dset=in.titles;

%*---------------------------------------------------------------------*
|  Reset the %TITLE macro counter:
*----------------------------------------------------------------------;
%global __tmcnt _t_____n;
%let __tmcnt = 0 ;%let _t_____n=0;

%*---------------------------------------------------------------------*
|  Get only observations for the current program from the
|  titles data set:
*----------------------------------------------------------------------;
data t_e_m_p ;
  set &dset (where=(upcase(program)="%upcase(&fn)")) ;
  run ;

%*---------------------------------------------------------------------*
|  Count the number of title entries for the current program:
*----------------------------------------------------------------------;
%local _nobs ;
data _null_ ;
  if 0 then set t_e_m_p nobs=count ;
  call symput('_nobs',left(put(count,8.))) ;
  stop ;
  run ;


%if &style=NEW %then %do;
%*---------------------------------------------------------------------*
|  Initialize and globalize the macro variables:
|
|    TNSTR1-TNSTRn, __TYPE1-__TYPEn, __NUM1-__NUMn, TTL1_1-TTL8_n
|
|    where n is the number of observations in the titles data set
|    for the current program.
*----------------------------------------------------------------------;
%local i j ;
%do i = 1 %to &_nobs ;
  %global tnstr&i __type&i __num&i __LBL_&i. ;
  %do j = 1 %to 8 ;
    %global ttl&j._&i ;
  %end ;
  %do j = 1 %to 10 ;
    %global fnt&j._&i ;
  %end ;
%end ;

%*---------------------------------------------------------------------*
|  Read the titles data set and use CALL SYMPUT to put the titles and
|  table numbers into the appropriate macro variables:
*----------------------------------------------------------------------;
%let _t_____n = &_nobs;
%if &_nobs>0 %then %do ;
  data _null_ ; length mactype $1 &number. $8;
    set t_e_m_p ;
    array _t {8} title1-title8 ;
    array _f {10} fn1-fn10 ;

    dumcnt+1;

    if indexc(upcase(&number.),"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ")=0
      then &number=compress('M' !! put(dumcnt,3.0));

    if type<=" " then type='Mock';


/*
    %* Define TYPES for MACPAGE (Only T, F, and A are allowed) ;
     if upcase(type) in("T","TABLE","DATA SUMMARY","E","EXHIBIT") then mactype="T";
     else if
     upcase(type) in("A","APPENDIX","X","XA","X-APPENDIX","XAPPENDIX","DATA LISTING")
      then mactype="A";
     else if upcase(type) in("F","FIGURE","G","GRAPH") then mactype="F";
     else mactype=' ';
 */

      /*
      / JHK001
      / Define TYPES for MACPAGE using new SWIFT classes.
      /-----------------------------------------------------*/

      uptype = upcase(type);
      select(uptype);
         when('T','TABLE','DATA SUMMARY','E','EXIBIT')          mactype = 'T';
         when('A','APPENDIX','X','XA','X-APPENDIX','XAPPENDIX') mactype = 'A';
         when('SUPPORTING TABLE','SUPPORTING TAB')              mactype = 'S';
         when('LISTING')                                        mactype = 'L';
         when('DATA LISTING')                                   mactype = 'D';
         when('CRF TABULATION','TABULATION')                    mactype = 'C';
         when('F','FIGURE','G','GRAPH')                         mactype = 'F';
         otherwise                                              mactype = 'U';
         end;

    call symput(compress('tnstr'||left(_n_)),trim(type)||' '||trim(&number)) ;
    call symput(compress('__type'||left(_n_)),substr(mactype,1,1)) ;
    call symput(compress('__num'||left(_n_)),trim(&number)) ;
    call symput(compress('__LBL_'||left(_n_)),upcase(label)) ;
    do i = 1 to dim(_t) ;
      call symput(compress('ttl'||left(i)||'_'||left(_n_)),trim(_t{i})) ;
    end ;
    do i = 1 to dim(_f) ;
      call symput(compress('fnt'||left(i)||'_'||left(_n_)),trim(_f{i})) ;
    end ;
    run ;
%end ;

%end;
%else %if &style=OLD %then %do;

%do i = 1 %to &_nobs ;
  %global tabnum&i type&i num&i ;
  %do j = 1 %to 9 ;
    %global ttl&j._&i ;
  %end ;
%end ;

%if &_nobs>0 %then %do ;
  data _null_ ;
    set t_e_m_p ;
    array _t {9} title1-title9 ;
    call symput(compress('tabnum'!!left(_n_)),trim(type)!!' '!!trim(tabnum)) ;
    call symput(compress('type'!!left(_n_)),substr(type,1,1)) ;
    call symput(compress('num'!!left(_n_)),trim(tabnum)) ;
    do i = 1 to dim(_t) ;
      call symput(compress('ttl'!!left(i)!!'_'!!left(_n_)),trim(_t{i})) ;
    end ;
    run ;
%end ;

%end; %*** End old-style code ***;

%mend SETTITLE ;
                                                                                                                                                                                                                                                                                                        /users/d33/jf97633/sas_y2k/macros/signrnk.sas                                                       0100664 0045717 0002024 00000045125 06633761432 0021720 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ PROGRAM NAME: signrnk
/
/ PROGRAM VERSION: 1.2
/
/ PROGRAM PURPOSE: The SIGNRNK macro calculates a nonparametric confidence interval on
/                  medians, which is often applied to differences in paired samples (e.g.,
/                  changes from baseline).  It creates an output data set containing the
/                  results of these calculations.  Later versions may perform an analagous
/                  hypothesis test (i.e., the Wilcoxon Signed Rank Test).
/
/ SAS VERSION: 6.12 (UNIX)
/
/ CREATED BY: John Henry King
/
/ DATE:       1992
/
/ INPUT PARAMETERS:
/
/       data=     specifies the input data set name.  The default setting is _LAST_.
/
/       out=      specifies the name of the output data set.  See "OUTPUT CREATED:"
/                 for a description of the variables in this data set.  The default
/                 setting is _WSRTOUT.
/
/       by=       specifies a list of stratification variables.  A value must be
/                 specified.  The default setting is null.
/
/       change=   specifies the name of the variable for which the confidence
/                 interval is being calculated (e.g., change from baseline).  The
/                 default setting is CHANGE.
/
/       maxdec=   specifies the number of decimal places to use in the confidence
/                 intervals in the output data set.  The default setting is 4.
/
/       alpha=    specifies the alpha-level at which to construct the confidence
/                 intervals.  The default setting is .05 (for a 95% confidence
/                 interval).
/
/       tails=    presently has no effect.  In future versions, it may be used to
/                 perform a one-tailed or two-tailed WSRT.  The default is 2.
/
/       exact=    specifies the number of observations in each by-group below which
/                 the Signed Rank Tables is used for the quantile calculations.
/                 The default setting 18.
/
/ OUTPUT CREATED: In addition to the following list of variables, the output data set
/                 contains all of the variables specified with BY=, and the following
/                 variables taken form PROC UNIVARIATE.
/
/                    mean = _mean
/                 stdmean = _stdmean
/                skewness = _skew
/                kurtosis = _kurt
/                  median = _median
/                      q1 = _q1
/                      q3 = _q3
/                     min = _min
/                     max = _max
/
/ _nmiss    is the number of missing observations in each by-group.
/
/ _n0       is the number of zero differences in each by-group.
/
/ _n        is the number of non-missing observations in the by-group.
/
/ _nup      is the number of positive values in each by-group.
/
/ _dn       is the number of negative values in each by-group.
/
/ _seq2     is a standard error associated with skewness for each by-group.
/
/ _q        is the p-value resulting from a test of skewness on each by-group.
/           This test is sometimes used as a test of non-normality.
/
/ _see2     is a standard error associated with kurtosis for each by-group.
/
/ _k        is a p-value resulting from a test of kurtosis on each by-group.
/           This test is also used as a test of non-normality.
/
/ _m        is the number of possible pairings within each by-group
/           (Di,Dj) fro ij=1, ... , _n where i <=j.
/
/ _exp      is _m/2.  Note that _exp is also the number of possible pairings
/           within each by-group (Di,Dj) for ij=1, ... , _n when i<j.
/
/ _var0     is a variable used for intermediate calculations
/           (= _n*(_n+1)*(2*_n+1)/24).
/
/ _probit   is the standard normal value associated with the specified
/           alpha-level.
/
/ _int      is the actual confidence level of the calculated confidence
/           interval.  This value will get adjusted if _n<=EXACT (i.e., when a
/           table look up is performed).
/
/ _ca       is the approximate alpha/2-level quantile value of all possible
/           pairs (_m).  The value is not updated if _n<=EXACT.
/
/ _ln       is equivalent to _ca if _n>EXACT, and is the result of a table
/           look up if _n<=EXACT.  The ordered pairwise mean ([Di + Dj]/2
/           for i,j=1, ... ,_n when i<=j)  associated with this observation
/           defines the lower confidence limit.
/
/ _hn       is the 1-alpha/2-level quantile value of all the possible pairs
/           (_m).  This value is the result of a table look up if _n<=EXACT.
/           The ordered pairwise mean associated with this observation defines
/           the upper confidence limit.
/
/ _lmed,    are the middele most value(s) of all the possible pairs(_m).  The
/ _hmed     mean of the ordered pairwise means associated with these
/           observations defines _theta.
/
/ _theta    is the median of all the possible pairwise means.
/
/ _lower    is the lower confidence limit on _theta.
/
/ _upper    is the upper confidence limit on _theta.
/
/ _ci       is the confidence interval represented as a character string:
/           (ll.llll,uu.uuuu)
/
/ _ru       is the value to which the numbers in _ci were rouned.
/
/ MACROS CALLED:
/
/                %jkxworks  to parse the by list into words.
/
/ SAS DATA SETS USED:
/
/                For small (_n<=EXACT) samples this macro will use tables for the upper
/                tail probabilites for the null distribution of Wilcoxon's signed rank T+
/                statistic.
/
/                /usr/local/medstat/sas/data
/
/                 n3.ssd01
/                 n4.ssd01
/                 n5.ssd01
/                 n6.ssd01
/                 n7.ssd01
/                 n8.ssd01
/                 n9.ssd01
/                n10.ssd01
/                n11.ssd01
/                n12.ssd01
/                n13.ssd01
/                n14.ssd01
/                n15.ssd01
/                n16.ssd01
/                n17.ssd01
/                n18.ssd01
/
/ EXAMPLE CALL:
/
/           Data taken from Statistics with Confidence
/              by Gardner and Altman, pages 77-78
/           ------------------------------------------
/
/           data beta;
/              retain group 1; * by variable;
/              input subj before after;
/              change = after - before;
/              cards;
/            1 10.6 14.6
/            2  5.2 15.6
/            3  8.4 20.2
/            4  9.0 20.9
/            5  6.6 24.0
/            6  4.6 25.0
/            7 14.1 35.2
/            8  5.2 30.2
/            9  4.4 30.0
/           10 17.4 46.2
/           11  7.2 37.0
/           ;;;;
/           run;
/
/           %signrnk(data = beta,
/                     out = stats,
/                      by = group,
/                  change = change)
/
/===================================================================================
/ CHANGE LOG:
/
/     MODIFIED BY: John Henry King
/     DATE:        09Jan1997
/     MODID:       JHK001
/     DESCRIPTION: Added SIGNRANK and PROBS to PROC UNIVARIATE output.
/     -------------------------------------------------------------------------
/     MODIFIED BY: John Henry King
/     DATE:
/     MODID:       JHK002
/     DESCRIPTION: Assign Value of SYSLAST.
/     -------------------------------------------------------------------------
/     MODIFIED BY: Jonathan Fry
/     DATE:        10DEC1998
/     MODID:       JMF003
/     DESCRIPTION: Tested for Y2K compliance.
/                  Add %PUT statement for Macro Name and Version Number.
/                  Change Version Number to 1.2.
/     -------------------------------------------------------------------------
/     MODIFIED BY:
/     DATE:
/     MODID:       XXX004
/     DESCRIPTION:
/     -------------------------------------------------------------------------
/===================================================================================*/

%macro signrnk(data = _last_,
                out = _WSRTOUT,
                 by = ,
             change = change,
             maxdec = 4,
              alpha = .05,
              tails = 2,
              exact = 18);

   /*
   / JMF003
   / Display Macro Name and Version Number in LOG
   /-----------------------------------------------------------------*/

   %put -----------------------------------------------------;
   %put NOTE: Macro called: SIGNRNK.SAS   Version Number: 1.2;
   %put -----------------------------------------------------;


   %local j _by0 vname l u apprc loopj lastby by0 _table _set _n _n0;

   %let _by0  = 0;
   %let apprc = 0;

   /*
   / JHK002
   / Check for DATA=_LAST_ and assign value of SYSLAST.
   /----------------------------------------------------------------------*/

   %let data = %upcase(&data);
   %if "&data" = "_LAST_" %then %let data = &syslast;

   /*
   / break by list into words so lastby can be found
   /------------------------------------------------------------------*/
   %let by0    = %jkxwords(list=&by,root=by);
   %let lastby = &&by&by0;

   %put NOTE: LASTBY=*&lastby*;
   /*
   / pass through the data to find firstobs and obs for each by group
   /------------------------------------------------------------------*/
   data _null_;
      set &data(keep=&by) end=eof;
      by &by;
      retain firstobs 0;
      if first.&lastby then firstobs=_n_;
      if last.&lastby then do;
         _BY_ + 1;
         length str $60;
         str = 'FIRSTOBS='!!trim(left(put(firstobs,8.)))
                          !!' OBS='!!trim(left(put(_n_,8.)));
         /*
         / these macro vars _BYn contain firstobs and obs info
         / for each by group in the input dataset
         /------------------------------------------------------------*/
         call symput('_BY'!!left(_by_),trim(str));
         end;
      if eof then call symput('_BY0',left(_by_));
      run;
   /*
   / Now loop through the input dataset for each by group as if it
   / were a seperate dataset
   /-----------------------------------------------------------------*/
   %do J = 1 %to &_by0;
      %if &apprc~=0 %then %goto stopit;
      %put ----------------------------------------------------------;
      %put NOTE: Processing Started for _BY&j=&&_by&j;
      %put ----------------------------------------------------------;


      /*
      / Data _WRST contains _n observations and the following variables.
      /   the by variables and &change
      /
      /   _ABS the absolute differences |Zi|, ... , |Zn|.
      /
      /           1 if Zi > 0
      /   _psi <  0 if Zi = 0
      /          -1 if Zi < 0
      /
      / Data _NS contains one observation.
      /  _n     the number of non-missing differences.
      /  _nmiss the number of missing values.
      /  _n0    the number of ZERO differences.
      /  _nup   the number of positive differences.
      /  _ndn   the number of negative differences.
      /-------------------------------------------------------------------*/

      data
           _wsrt(keep = &by &change _abs _psi)
           _ns  (keep = &by _n _nmiss _n0 _nup _ndn);

         do until(eof);
            set
               &data
                  (
                   &&_by&j
                   keep=&by &change
                  )
               end=eof;

            &change = round(&change,1E-12);

            if &change <= .Z then do;
               _nmiss + 1;
               goto loop;
               end;

            if &change = 0 then _n0 + 1;
            _n   + 1;
            _psi = sign(&change);
            _nup = sum(_nup,(_psi>0));
            _ndn = sum(_ndn,(_psi<0));
            _abs = abs(&change);
            output _wsrt;

          Loop: end;

         output _ns;
         /*
         / If there are less than 3 non-missing values for this by-group
         / assign a macro variable so the processing can be skipped.
         /----------------------------------------------------------------*/
         if _n < 3
            then call symput('LOOPJ','1');
            else call symput('LOOPJ','0');
         run;

      %if &loopj %then %do;
         %put -------------------------------------------------------;
         %put NOTE: Processing Skipped For _BY&j=&&_by&j, N<3;
         %put -------------------------------------------------------;
         %goto LOOPJ;
         %end;

      /*
      / Rank the |Zi| computed above.
      /-------------------------------------------------------------------*/
      proc rank data=_wsrt out=_wsrt ties=mean;
         by &by;
         var _abs;
         ranks _rd;
         run;

      proc contents data=_wsrt;
         run;
      /*
      / compute a number of usefull statistics for the Zi
      /-----------------------------------------------------*/
      proc univariate data=_wsrt noprint;
         by &by;
         var &change;
         output out = _uni
               mean = _mean
            stdmean = _stdmean
             median = _median
                 q1 = _q1
                 q3 = _q3
                min = _min
                max = _max
           skewness = _skew
           kurtosis = _kurt
            /*
            / JHK001
            /-------------------*/
           signrank = _sgnrnk
           probs    = _probs;
         run;

      /*
      / Using data _NS and the univariate statistics from above _UNI compute
      / 1. The standard error and pvalues for the test on skewness and kurtosis.
      / 2. Also compute the observation numbers needed to look up the values for
      /    for the upper and lower confidence limist.
      / 3. For small samples _n<=EXACT lookup assign _TABLE=1 macro variable
      /    to cause to macro to use the tables.
      /--------------------------------------------------------------------------*/

      data _wsrt2;
         retain &by;
         merge _uni _ns end=eof;
         by &by;
         _seq2   = sqrt( (6*_n*(_n-1)) / ((_n-2)*(_n+1)*(_n+3)) );
         _q      = 1-probnorm(abs(_skew/_seq2));
         _see2   = sqrt((24*_n*(_n-1)**2)/((_n-2)*(_n-3)*(_n+3)*(_n+5)));
         _k      = 1-probnorm(abs(_kurt/_see2));
         _m      = _n*(_n+1) / 2;
         _exp    = _n*(_n+1) / 4;
         _var0   = ( _n*(_n+1)*(2*_n+1) ) / 24;
         _probit = probit(1-&alpha/2);
         _int    = 1 - &alpha;
         _ca     = _exp - _probit * sqrt(_var0);
         _ln     = _ca;
         _hn     = _m + 1 - _ca;
         _lmed   = floor((_m+1)/2);
         _hmed   = ceil ((_m+1)/2);
         if  _n <= &exact
            then call symput('_TABLE','1');
            else call symput('_TABLE','0');
         call symput('_N',left(put(_n,8.)));
         call symput('_N0',left(put(_n0,8.)));
         output;
         run;

      %put NOTE: _TABLE=&_table _N=&_n _N0=&_n0;

      /*
      / If the sample is small do a table lookup.
      /------------------------------------------------*/
      %if &_table %then %do;
         %put NOTE: N<=&exact using Signed Rank Table For P-Values.;

         data _wsrt2;
            set _wsrt2;
            /*
            / search the table until a value is found that is less
            / than or equal to alpha/2
            /-------------------------------------------------------*/

            do point = 1 to nobs  until(_value <= (&alpha/2));
               set
                  utildata.N&_n
                     (
                      keep   = t p
                      rename = (t = _x p = _value)
                     )
                  point = point
                  nobs  = nobs;
               end;

            _ln   = _m - _x + 1;
            _hn   = _m + 1 - _ln;
            _int  = 1 - _value*2;
            output;
            stop;
            format _value _int 6.4;
            return;
            run;

         %end;

      /*
      / Form the M = n(n + 1) / 2 averages (Zi + Zi)/2, i<=j = 1, ... , n.
      /
      / As each change is read it is placed in array _x, so that each
      / pairwise difference can be fromed by referencing the array from
      / 1 to n, for each successive observation.
      /
      / To conserve space only the differences are keep in the data set,
      / we do not even need the by values at this point.
      /-------------------------------------------------------------------*/
      data _ws(keep=_w);
         do until(eof);
            set _wsrt(keep=&change) end=eof;
            array _x{&_n} _temporary_;
            _place + 1;
            _x{_place} = &change;
            do _i = 1 to _place;
               _w = (&change + _x{_i}) / 2;
               output;
               end;
            end;
         run;

      /*
      / Form the ordered pairwise differences.
      / W(1) <= ... <= W(M)
      /----------------------------------------------*/
      proc sort data=_ws;
         by _w;
         run;



      /*
      / Using the values of _LN, _LMED, _HMED, and _HN computed above,
      / as observations numbers for the SET statement POINT= option
      / pick out the 4 values needed to compute _LOWER, _THETA, and _UPPER
      /------------------------------------------------------------------------*/

      data _wsrt2;
         set _wsrt2;

         /*
         / look up the lower confidence limit on theta
         /----------------------------------------------------------------------*/
         _place = floor(_ln); link setws; _lower = _w;

         /*
         / look up the values needed to compute the Hodges-Lehmann estimate
         / theta.
         /-----------------------------------------------------------------------*/
         _place = _lmed;      link setws;      _theta = _w;
         _place = _hmed;      link setws;      _theta = (_theta+_w)/2;

         /*
         / look up the upper confidence limit on theta
         /-----------------------------------------------------------------------*/
         _place =  ceil(_hn); link setws; _upper = _w;

         /*
         / Format the CI into a character variable.
         /-----------------------------------------------------------------------*/
         length _CI $30;
         if &maxdec<1
            then _ru = 1;
            else _ru = input('.'!!repeat('0',&maxdec-2)!!'1',16.);

         _ci = compress('('!!put(round(_lower,_ru),16.&maxdec)!!','
                           !!put(round(_upper,_ru),16.&maxdec)!!')');
         return;
       /*

       / Link to this set statement for look up values.
       /--------------------------------------------------*/
       Setws:
         set _ws(keep=_w) point=_place;
         drop _w;
         return;
         run;

      /*
      / combine the current by-group with any previous by-groups.
      /----------------------------------------------------------------------*/
      data &out;
         set &_set _wsrt2;
         by &by;
         run;

      %let _set  = &out;
      %let apprc = &syserr;

      /*
      / delete intermediate data sets
      /--------------------------------------------------*/
      proc delete data=_wsrt _wsrt2 _ns _ws;
         run;

      %loopj: %end;

  %stopit:

   %mend signrnk;
last;

   /*
   / break by list into words so lastby can be found
   /------------------------------------------------------------------*/
   %let by0    = %jkxwords(list=&by,root=by);
   %let lastby = &&by&by0;

   %put NOTE: LASTBY=*&lastby*;
   /*
   / pass through the data to find firstobs and obs for each by group
   /------------------------------------------------------------------*/
   data _null_;
      set &data(k/users/d33/jf97633/sas_y2k/macros/simstat.sas                                                       0100664 0045717 0002024 00000116254 06634203752 0021730 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ PROGRAM NAME:     SIMSTAT.SAS
/
/ PROGRAM VERSION:  1.2
/
/ PROGRAM PURPOSE:  Summaries of discrete and continious variables. Also
/                   provides a number of statistical test.
/
/ SAS VERSION:      6.12 (UNIX)
/
/ CREATED BY:       John Henry King
/
/ DATE:             FEB1997
/
/ INPUT PARAMETERS: See details below.
/
/ OUTPUT CREATED:   A SAS data set.
/
/ MACROS CALLED:    JKXWORDS - Creates macro variable arrays.
/                   JKCHKDAT - Checks that data set variables exist and are the correct type.
/                   JKCHKLST - Checks the STATS= parameter for valid statistics.
/                   JKPAIRED - Produces a dataset for pairwise analysis.
/                   JKPREFIX - Append characters to the beginning of words in a list.
/                   JKDISC01 - Compute frequencies for discrete variables.
/                   JKCONT01 - Compute summary statistics for continuous variables.
/                   JKPVAL05 - Compute p-values using PROC FREQ.
/                   JKPVAL04 - Compute p-values using GLM.
/
/ EXAMPLE CALL:     %simstat(data = demo,
/                              by = ptcd,
/                             tmt = ntmt,
/                        pairwise = yes,
/                           stats = n mean sum std min max,
/                        discrete = sex,
/                          p_disc = exact,
/                        continue = age,
/                          p_cont = anova);
/
/===================================================================================
/ CHANGE LOG:
/
/    MODIFIED BY: John Henry King
/    DATE:        OCT1997
/    MODID:       JHK001
/    DESCRIPTION: Changed defaults to come to IDSG compliance.
/                 1) default for STATS= changed by adding the MEDIAN to the list.
/                 2) changed defaults for P_CONT and P_DISC to NONE.
/    -----------------------------------------------------------------------------
/    MODIFIED BY: Jonathan Fry
/    DATE:        10DEC1998
/    MODID:       JMF002
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 1.2.
/    -----------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    -----------------------------------------------------------------------------
/=================================================================================*/
/*
/ Macro SIMSTA01,
/
/ Parameter=Default    Description
/ -----------------    --------------------------------------------------------
/
/ DATA = _LAST_        The input data set
/
/ OUTSTAT = SIMSTAT    The output data set.  See description of the OUTSTAT data
/                      set below.
/
/ BY =                 By variables for processing the data in groups.
/                      Not to be confused with treatment groups defined by TMT=
/                      below.
/
/ UNIQUEID =            A list of variables that uniquely identifies each record
/                      i.e. patient.  The records must be unique for each treatment
/                      combination that is contained with each of the BY groups
/                      defined by the BY= option, if used.
/
/ TMT =                An INTEGER NUMERIC variable that represents the levels
/                      of treatments.
/
/ TMTEXCL = (1)        This parameter is use to exclude from the analysis of
/                      one or more of the treatment groups.  This options is useful
/                      when you want a analysis with a total column but you do no
/                      want to include those
/
/ CONTROL = _ONE_      A variable used to stratify the analysis, in proc
/                      freq or proc glm.  This variable does NOT cause the
/                      macro to produce summary statistics for each level of
/                      the controlling variable.
/
/--------------------  OPTIONS USED WITH DISCRETE VARIABLES -----------------------------
/
/ DISCRETE =           List the names of descrete variables to be analyzed.
/                      The variables must be CHARACTER, and should have one
/                      character codes. e.g. SEX = M,F or RACE = C,B,O,M,X.
/                      Leave this list blank if there are no discrete
/                      variables.
/
/ YESNO =              This parameter is use to list dicotomus discrete variables for
/                      which only one observation in the output data set is required.
/                      For example a group of YES/NO question might be listed where
/                      only the YES side of the question is to be displayed in a table.
/                      The macro treats YESNO variables as if they were listed in the
/                      DISCRETE= option.  The only special action is that only the YES
/                      observations are kept in the output data set. See the YES=
/                      parameter below.  DO NOT list YESNO variables in the DISCRETE
/                      statement.
/
/ YN_ORDER=            This parameter can be used to have macro SIMSTAT produce an
/                      ordered list of YESNO variables.  The list can then be used
/                      in the ROWS= parameter of macro DTAB.  To have the YESNO
/                      variable ordered by descending frequency, totaled across
/                      treatments use YN_ORDER=DESCENDING.  Use ASCENDING to have
/                      the YESNO variables sorted in ascending order.  The global
/                      macro variable YN_OLIST will be created by SIMSTAT for you
/                      to use as you see fit.
/
/ YES = Y              Use this parameter to specify the value of the YESNO variables
/                      that is to be used for YES.
/
/ DLEVELS =            In many applications some levels of discrete variables are not
/                      all present in the input data set.  For example a table with
/                      age groups as a classification may have one or more groups
/                      that are not represented in the data.
/                      However the user may want the table to include lines in the table
/                      for those values.
/                      This is where dlevels comes into the picture.
/                      In the dlevels parameter list
/                      the values that each of the discrete variables can have seperated
/                      by spaces.  Enclose each discrete variables value list in backslash
/                      characters.  For example \ M F \ 1 2 3 4 5 \.
/                      If you use this parameter then you must supply values for each
/                      discrete variable in the DISCRETE= parameter, and the must be in
/                      the same order as the variables in that list.
/
/ DEXCL =              In some cases discrete variables may have observations in the data
/                      that do not relate to that variable.  For example in a table where
/                      age is grouped by sex the values of age group when the observation is
/                      male do no apply to values of age group for females.  The parameter
/                      DEXCL provides the user a way to tell the macro not to use the
/                      observations with this value as a classification level.  These values
/                      are excluded.
/
/ P_DISC = NONE        P-Value options for discrete variables.
/                      The current options for an unstratified analysis are
/                      CHISQ and EXACT.  For Pearsons chi square and Fishers
/                      exact test respectively.  The EXACT option can burn
/                      up LARGE amounts of CPU so be carefull.
/
/                      For a statified analysis a CMH test is produced.
/                      You can request any one of the following.
/
/                      CMH or CMHGA for General Association.
/                      CMHRMS for Row Mean Scores Differ
/                      CMHCOR for Nonzero Correlation
/
/
/ SCORES=TABLE         The SCORES= parameter is used to control the SCORES= option
/                      in PROC FREQ.  You may request TABLE, RANK, RIDIT or MODRIDIT
/                      scores.  See documentation for PROC FREQ for details.  If no
/                      P_VALUE is requested then the parameter has no effect.
/
/--------------------  OPTIONS USED WITH CONTINUOUS VARIABLES ---------------------------
/
/ CONTINUE =           List of continuous variables.
/                      The variables must be numeric.  Leave this list blank if
/                      there are no continuous variables.
/
/ P_CONT = NONE        P-Value options for continuous variables.  The current
/                      options are VANELT, ANOVA, PAIRED, and ANCOVA.
/
/                      The VANELT and ANOVA tests can be statified, through the
/                      CONTROL= option.
/
/                      The ANCOVA options used in conjuction with the COVARS=
/                      parameter can be used to request an analysis of covariance.
/
/                      The PAIRED test is a t-test for HO: mean=0.  See the
/                      TMTDIFF option when using PAIRED.  DO NOT USE THE PAIRED
/                      option with the PAIRWISE option below.  Note that PAIRED is
/                      a special case and this statistic may also be requested in
/                      the STATS= option.
/
/ TMTDIFF =            Use this option with P_CONT=PAIRED to tell SIMSTAT which level
/                      of the TMT variable contains the differences to be tested by
/                      the PAIRED test.
/
/ COVARS =             Use this option to tell the macro which variables to use as the
/                      covariates in an analysis of covariance.  The number of variables
/                      in this list must match exactly the number of variables in the
/                      CONTINUE= paramter. The following models are avaliable.
/
/                          y = tmt_var covar
/                          y = tmt_var control_var covar => when CONTROL= is used
/                          y = tmt_var|control_var covar => when CONTROL= and INTERACT
/
/
/ SS = SS3             The sum of squares type.
/
/ INTERACT = NO        Include interaction term in the ANOVA model.  This options requires
/                      the CONTROL= option.
/
/
/ STATS = N MEAN STD MEDIAN MIN MAX
/                      Use this parameter to request the calculation of summary
/                      statistics.  This list can include any statistic
/                      computed by PROC UNIVARIATE.  See documentation for that
/                      procedure for details.
/
/                      For continuous variables, the variables that contain the
/                      statistics in the output dataset are named using the option
/                      name. e.g. N=N MEAN=MEAN STD=STD etc.
/
/                      For discrete variables the only statistics computed are
/                      COUNT, N and PCT, and are so named.
/
/ PAIRWISE = NO        Use this option to control the production of pairwise
/                      tests.  If the levels of the TMT= variable are 1,2,3
/                      the macro produces p-values for the three levels of TMT
/                      combined plus 1vs2, 1vs3 and 2vs3.  The macro will name
/                      the variables as follows.
/
/                          PROB P1_2 P1_3 P2_3
/
/                      For all tests except ANOVA the pairwise p-values are
/                      produced by pairwise grouping the data and calling
/                      the procedure for each of these groups.
/                      For ANOVA tests the pairwise p-values are those produced
/                      by the LSMEANS statement using the PDIFF option.
/                      The overall test is an F test for TMT.
/
/ ORDER = INTERNAL     The order parameter can be use to change to ordering of
/                      values of DISCRETE variables to have them ordered by
/                      frequency.  Use DESCENDING or ASCENDING as you see fit.
/                      DTAB will then display the values using the frequency
/                      ordering.
/
/ PRINT = YES          Print the output data set?
/
/ ROW_ORDR =           Use the row ordering parameter to order the values of
/                      _VNAME_ in the output data set.
/                      Using this parameter causes the creation of a new
/                      numeric variable _ROW_.
/                      The output data set is then sorted by the BY variables
/                      and _ROW_.
/                      This parameter is not need if the output from SIMSTAT
/                      is to be displayed with DTABxx.  The row order
/                      in DTABxx is controlled in that macro call.
/ -----------------    --------------------------------------------------------
/
/==============================================================================
/
/ OUTSTAT Data Set
/
/ The OUTSTAT data set is a specially structured sas data set.  It contains
/ the followin variables.
/
/ BY
/   Variables specified in the BY= parameter.  These variables if any have the
/   same attributes as in the original data set.
/
/ TMT
/   The numeric treatment variable specified in the TMT= parameter.
/   This variable has the same name as specified in the TMT= parameter.
/
/ _NAME_
/   Contains the names of the analysis variables from the input data set.
/
/ _LEVEL_
/   Contains the values of the discrete variables from the input data.
/   This character variable is missing for continuous variables.
/
/ _VTYPE_
/   Identifies the analysis variables type. CONT, DISC, PTNO, 01.
/
/ _PTYPE_
/   Identifies the type of p-values computed for each variable. CHISQ,
/   EXACT, CMH, VANELT, ANOVA.
/
/ _CNTL_
/   If a controlling variable is used then this variable contains the
/   name name of that variable.
/
/ PROB
/   The overall p-value identified by _PTYPE_.
/
/ P1_2, P1_3, P2_3, ... Pn_n+1 chose two.
/   The pariwise p-values identified by _PTYPE_.
/
/ PR_CNTL
/   The pr>F when a ANCOVA with CONTROL= is used.
/
/ COUNT
/   The counts for each level of discrete variables.
/
/ PCT
/   The proportions (COUNT/N) for each level of discrete variables.
/
/ N
/   The number of observations.
/
/ MEAN
/   The mean.
/
/ Other requested statistics as per STATS= parameter.
/
/ NOTES:
/
/ If a discrete variable has missing (blank) values the macro produces
/ observations to hold the counts for these missing values.  The macro uses
/ values of _LEVEL_='_' for these counts.
/
/
/ EXAMPLE OUTPUT DATA SET:
/
/ The following macro call,
/
/
/   %simstat(data = demo,
/              by = ptcd,
/             tmt = ntmt,
/        pairwise = yes,
/           stats = n mean sum std min max,
/        discrete = sex,
/          p_disc = exact,
/        continue = age,
/          p_cont = anova)
/
/ produced the output shown below.
/
/ DATA=SIMSTAT
/
/ OBS  PTCD      _NAME_  NTMT  _LEVEL_  _VTYPE_  _PTYPE_   N     MEAN    SUM
/
/   1  S3A258     AGE      1             CONT     ANOVA   120  61.1250  7335
/   2  S3A258     AGE      2             CONT     ANOVA   120  61.0833  7330
/   3  S3A258     AGE      3             CONT     ANOVA   120  61.6417  7397
/   4  S3A258     SEX      1      F      DISC     EXACT   120    .         .
/   5  S3A258     SEX      2      F      DISC     EXACT   119    .         .
/   6  S3A258     SEX      3      F      DISC     EXACT   120    .         .
/   7  S3A258     SEX      1      M      DISC     EXACT   120    .         .
/   8  S3A258     SEX      2      M      DISC     EXACT   119    .         .
/   9  S3A258     SEX      3      M      DISC     EXACT   120    .         .
/  10  S3A258     SEX      1      _      DISC     EXACT     .    .         .
/  11  S3A258     SEX      2      _      DISC     EXACT     .    .         .
/  12  S3A258     SEX      3      _      DISC     EXACT     .    .         .
/
/ OBS    STD    MAX  MIN  COUNT    PCT      PROB     P1_2     P1_3     P2_3
/
/   1  7.30093   76   50     .    .       0.81358  0.96569  0.59389  0.56449
/   2  7.25940   78   50     .    .       0.81358  0.96569  0.59389  0.56449
/   3  7.91849   79   50     .    .       0.81358  0.96569  0.59389  0.56449
/   4   .         .    .    64   0.53333  0.33527  0.24516  1.00000  0.19659
/   5   .         .    .    54   0.45378  0.33527  0.24516  1.00000  0.19659
/   6   .         .    .    65   0.54167  0.33527  0.24516  1.00000  0.19659
/   7   .         .    .    56   0.46667  0.33527  0.24516  1.00000  0.19659
/   8   .         .    .    65   0.54622  0.33527  0.24516  1.00000  0.19659
/   9   .         .    .    55   0.45833  0.33527  0.24516  1.00000  0.19659
/  10   .         .    .     0    .       0.33527  0.24516  1.00000  0.19659
/  11   .         .    .     1    .       0.33527  0.24516  1.00000  0.19659
/  12   .         .    .     0    .       0.33527  0.24516  1.00000  0.19659
/
/
/
/
/----------------------------------------------------------------------------*/

%macro simstat(data = _LAST_,
            outstat = SIMSTAT,
           uniqueid = ,
            uspatno = ,
                tmt = ,
            tmtexcl = (1),
                 by = ,
            control = ,
             scores = TABLE,
                 ss = SS3,
           interact = NO,
             covars = ,
              stats = ,
           discrete = ,
             p_disc = NONE,
            dlevels = ,
              dexcl = ,
           continue = ,
             p_cont = NONE,
            tmtdiff = ,
              yesno = ,
                yes = Y,
           yn_order = DEFAULT,
           orderval = COUNT,
              print = YES,
           pairwise = NO,
           row_ordr = ,
              order = INTERNAL,
            sasopts = NOSYMBOLGEN NOMLOGIC);

   options &sasopts;

   /*
   / JMF002
   / Display Macro Name and Version Number in LOG
   /-------------------------------------------------------------*/

   %put -----------------------------------------------------;
   %put NOTE: Macro called: SIMSTAT.SAS   Version Number: 1.2;
   %put -----------------------------------------------------;


   %global vsimstat;
   %let vsimstat=1.1;

   /*
   / Uppercase macro parameters and setup default values
   / for parms that must not be missing
   /-------------------------------------------------------------*/

   %let discrete = %upcase(&discrete);
   %let yesno    = %upcase(&yesno);

   %let discrete = &discrete &yesno;
   %let scores   = %upcase(&scores);

   %let dlevels  = %upcase(&dlevels);
   %let continue = %upcase(&continue);

   %let print    = %upcase(&print);
   %let data     = %upcase(&data);
   %let order    = %upcase(&order);
   %let yn_order = %upcase(&yn_order);

   %local erdash;
   %let erdash = ERROR: _+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_;

   %if &data=_LAST_ | %length(&data)=0 %then %let data=&syslast;
   %if &data=_NULL_ %then %do;
      %put &erdash;
      %put ERROR: There is no DATA= data set;
      %put &erdash;
      %goto EXIT;
      %end;

   %if "&uspatno"^="" & "&uniqueid"="" %then %do;
      %let uniqueid=&uspatno;
      %let uspatno=;
      %end;

   %if "&uniqueid"="" %then %do;
      %put &erdash;
      %put ERROR: The macro parameter UNIQUEID must not be blank.;
      %put &erdash;
      %goto exit;
      %end;

   %if %length(&tmt)=0 %then %do;
      %put &erdash;
      %put ERROR: TMT Must not be blank;
      %put &erdash;
      %goto EXIT;
      %end;

   %if %index(&uniqueid,&control) %then %do;
      %put &erdash;
      %put ERROR: Your CONTROLling variable is also in UNIQUEID,;
      %put ERROR: this could cause problems for SIMSTAT.;
      %put ERROR: Rename the CONTROLling variable and try again.;
      %put &erdash;
      %goto exit;
      %end;

   %if &row_ordr^= %then %do;
      %if &yn_order^=DEFAULT %then %do;
         %put &erdash;
         %put ERROR: YN_ORDER and ROW_ORDR are incompatable options;
         %put &erdash;
         %goto exit;
         %end;
      %end;

   %let pairwise = %upcase(&pairwise);
   %if "&pairwise"="YES"
      %then %let pairwise=1;
      %else %let pairwise=0;

   %if "&discrete" > "" %then %do;
      %local xdn0;
      %let   xdn0 = %jkxwords(list=&discrete,root=);
      %if &xdn0 > 26 %then %do;
         %put &erdash;
         %put ERROR: You may not use more than 26 YESNO and DISCRETE variables;
         %put ERROR: Use two or more calls to SIMSTAT with 26 or less variables;
         %put &erdash;
         %goto EXIT;
         %end;

      %if %length(&dlevels)>0 & %index("&dlevels",\) = 0 %then %do;
         %put &erdash;
         %put ERROR: You need to delimit DLEVELS= with a backslash \;
         %put &erdash;
         %goto EXIT;
         %end;

      /*
      / Check p-value request for discrete variables
      /------------------------------------------------*/

      %let p_disc   = %upcase(&p_disc);

      %if "&p_disc"="" %then %let p_disc=NONE;

      %if ^%index(CHISQ CMH CMHCOR CMHRMS CMHGA EXACT NONE,&p_disc) %then %do;
         %put &erdash;
         %put ERROR: The type of p-values requested for discrete variables is invalid.;
         %put &erdash;
         %goto EXIT;
         %end;

      %if "&control" > "" & %index(CHISQ EXACT,&p_disc) %then %do;
         %put &erdash;
         %put ERROR: You cannot request Fishers EXACT or Chi Square test with a controlling variable.;
         %put &erdash;
         %goto EXIT;
         %end;

      %end;

   %if "&continue" > "" %then %do;

      /*
      / Check p-value requests for continue variables
      /------------------------------------------------*/

      %let p_cont   = %upcase(&p_cont);
      %let interact = %upcase(&interact);
      %let covars   = %upcase(&covars);

      %if "&p_cont" = "" %then %let p_cont=NONE;

      %if ^%index(ANOVA ANCOVA CMHRMS VANELT NONE PAIRED,&p_cont) %then %do;
         %put &erdash;
         %put ERROR: The type of p-values requested for continue variables is invalid.;
         %put &erdash;
         %goto EXIT;
         %end;

      %if "&interact" = "YES" & "&control"="" %then %do;
         %put &erdash;
         %put ERROR: You have specified INTERACT=YES but CONTROL= is blank.;
         %put &erdash;
         %goto EXIT;
         %end;

      %if "&covars" = "" & "&p_cont"="ANCOVA" %then %do;
         %put &erdash;
         %put ERROR: You MUST have COVARS= when you specify P_CONT=ANCOVA.;
         %put &erdash;
         %goto EXIT;
         %end;

      %if &pairwise & "&p_cont"="PAIRED" %then %do;
         %put &erdash;
         %put ERROR: The Paired test for continuous variables is not valid with PAIRWISE=YES.;
         %put &erdash;
         %goto EXIT;
         %end;

      %if "&covars" > "" %then %do;
         %local _xcv0 _xvv0;
         %let _xcv0 = %jkxwords(list=&covars,root=);
         %let _xvv0 = %jkxwords(list=&continue,root=);
         %if &_xcv0 ^= &_xvv0 %then %do;
            %put &erdash;
            %put ERROR: You must have an EQUAL number of COVARiateS and CONTINUE variables.;
            %put &erdash;
            %goto EXIT;
            %end;
         %end;

      %if "&covars" > "" & "&p_cont"^="ANCOVA" %then %do;
         %put &erdash;
         %put ERROR: You MUST have P_CONT=ANCOVA when you specify Covariates.;
         %put &erdash;
         %goto EXIT;
         %end;
      %end;

   /*
   / Call CHKDATA macro.  This is used to verify the existance of the input data
   / and variables.
   /---------------------------------------------------------------------------*/

   %jkchkdat(data=&data,
             vars=&by &uniqueid &control,
            nvars=&continue &tmt &covars,
            cvars=&discrete)

   %if &RC %then %goto EXIT;

   /*
   / Create macro variables to hold the names of temporary data sets.  Use
   / SYSINDEX to return a unique number to name the data sets.
   /-------------------------------------------------------------------------*/

   %local subset temp1 temp2 _disc_ _cont_ _disc2_ _cont2_ _pdisc_ _pcont_ _patno_;

   %let subset  = _0_&sysindex;
   %let temp1   = _1_&sysindex;
   %let temp2   = _2_&sysindex;
   %let _patno_ = _3_&sysindex;
   %let _disc_  = _5_&sysindex;
   %let _disc2_ = _6_&sysindex;
   %let _pdisc_ = _7_&sysindex;
   %let _cont_  = _8_&sysindex;
   %let _cont2_ = _9_&sysindex;
   %let _pcont_ = _A_&sysindex;
   %let dups    = _B_&sysindex;
   %let _lsm_   = _C_&sysindex;
   %let _pairt_ = _D_&sysindex;

   %local id;

   /*
   / Set up default STATS, if stats is blank then assign it.
   / If STATS is provided by the user then add N MEAN and SUM to the
   / list just in case the user left it off.  If the user did include
   / N MEAN and SUM these will then be in the list twice, however
   / PROC UNIVARIATE doesn't mind if you ask for a statistic more than
   / once.
   / If the user requested statistics then we need to check their
   / validity against what can be done by proc univariate.
   /--------------------------------------------------------------------*/

   %if "&stats" = "" %then %let stats = N MEAN STD MEDIAN MIN MAX;
   %else %do;
      %jkchklst(list=&stats,against=UNISTATS,return=RC2)
      %if &rc2 %then %goto EXIT;
      %end;

   %let stats    = %upcase(&stats);

   %let tmt      = %upcase(&tmt);

   %if %index(&p_cont,CMH) | %index(&p_cont,VAN) %then %let p_cont=CMHRMS;

   %if "&control"="" %then %let control=_ONE_;
   %let control  = %upcase(&control);

   %local kontrol;
   %if "&control"="_ONE_" %then %do;
      %let kontrol = ;
      %end;
   %else %do;
      %let kontrol = &control;
      %end;

   %let data    = %upcase(&data);
   %let outstat = %upcase(&outstat);

   %let _by0=%jkxwords(list=&by,root=_by);

   /*
   / Create a temporary dataset subsetting the variables
   / to only include those variables nessary for the
   / analysis to be performed.
   /------------------------------------------------------*/

   proc sort
      data = &data
         (
         keep=&by &uniqueid &tmt &kontrol &discrete &continue &covars
         )
      out  = &temp1;

      by &by &uniqueid &tmt;
      format _all_;
      run;

   %put NOTE: PROC SORT SYSINFO=&sysinfo, SYSRC=&SYSRC, SYSERR=&SYSERR;

   /*
   / Create variable _ONE_ and check that the data is unique for each patient
   / number.  If not stop the macro.
   /-------------------------------------------------------------------------*/

   %local dupflag;
   %let dupflag = 0;

   data &temp1 &dups;
      set &temp1;
      by &by &uniqueid &tmt;

   %if &_by0 > 0 %then %do;
      if first.&&_by&_by0 then _BYID_ + 1;
      %end;
   %else %do;
      retain _byid_ 1;
      %end;

      if ^(first.&tmt & last.&tmt) then do;
         output &dups;
         call symput('DUPFLAG','1');
         end;

      output &temp1;

      retain _one_ 1;
      format _all_;
      run;

   %if &dupflag %then %do;
      title5 'Duplicates found in input data, correct and resubmit';
      proc print data=&dups;
         run;
      title5;
      %put &erdash;
      %put ERROR: MACRO simstat, Duplicates found in input data.;
      %put &erdash;
      %goto EXIT;
      %end;

   data &subset;
      set &temp1(where=(&tmtexcl));
      run;

   proc sort data=&subset;
      by &by &kontrol &uniqueid &tmt;
      run;

   /*
   / Compute the frequency counts for the NUMBER of patients
   / variable.  This is a count of the observations in each
   / level of treatment.
   /-----------------------------------------------------------*/

   proc summary data=&temp1 nway;
      by &by;
      class &tmt;
      output out=&_patno_(drop=_type_ rename=(_freq_=n));
      run;

   data &_patno_;
      set &_patno_;
      length _vname_ $8 _vtype_ $8;
      retain _vname_ '_PATNO_' _vtype_ 'PTNO';
      run;

   %if %length(&discrete) > 0 %then %do;

      %jkdisc01(data=&temp1,
                 out=&_disc_,
                  by=&by,
                 var=_one_,
             uniqueid=&uniqueid,
                 tmt=&tmt,
               print=NO,
            discrete=&discrete,
             dlevels=&dlevels,
               dexcl=&dexcl)

      proc sort data=&_disc_;
         by &by _vname_ _vtype_;
         run;

      %if %index(CMHRMS CMHGA CMHCOR CHISQ EXACT CMH,&p_disc) %then %do;

         %if "&control"="_ONE_" %then %do;

            %jkdisc01(data=&subset,
                       out=&_disc2_,
                        by=&by,
                       var=_one_,
                   uniqueid=&uniqueid,
                       tmt=&tmt,
                     print=NO,
                  discrete=&discrete,
                   dlevels=&dlevels,
                     dexcl=&dexcl)

            proc sort data=&_disc2_;
               by &by _vname_ _vtype_;
               run;

            data &_disc2_;
               set &_disc2_;
               if _level_ = '_' then delete;
               retain _one_ 1;
               run;
            %let id = ;
            %end;

         %else %do;
            %jkdisc01(data=&subset,
                       out=&_disc2_,
                        by=&by &control,
                       var=_one_,
                   uniqueid=&uniqueid,
                       tmt=&tmt,
                     print=NO,
                  discrete=&discrete,
                   dlevels=&dlevels,
                     dexcl=&dexcl)

            data &_disc2_;
               set &_disc2_;
               if _level_ = '_' then delete;
               retain _one_ 1;
               run;
            %let id = ;
            %end;

         %if &pairwise %then %do;
            %jkpaired(chkdata = NO,
                         data = &_disc2_,
                        where = _level_^='_',
                          out = &_disc2_,
                           by = &by _vname_ _vtype_,
                         pair = &tmt,
                       sortby = ,
                       idname = _id_,
                           id = %str(compress(put(_1,3.)||'_'||put(_2,3.),' ')) )

            %let id = _id_;
            %end;

         %jkpval05(data=&_disc2_,
                    out=&_pdisc_,
                     by=&by _vname_ _vtype_,
                     id=&id,
               uniqueid=&uniqueid,
                control=&control,
                 scores=&scores,
                    tmt=&tmt,
               response=_level_,
                 weight=count,
                p_value=&p_disc,
                vartype=discrete,
               pairwise=&pairwise)

         proc delete data=&_disc2_;
            run;

         data &_disc_;
            merge &_disc_ &_pdisc_;
            by &by _vname_ _vtype_;
            run;

         %end /* endif for p_values were requested */;

      /*
      title5 "DATA=&_disc_ _DISC_ the discrete variables";
      proc print data=&_disc_;
         run;
      title5;
      */

      %end /* endif discrete variables exist */;

   %else %do;
      %let _disc_ =;
      %end;

   /*
   / P value processing for the continuous variables, if no pvalues
   / are requested then this section of the macro is skipped
   /------------------------------------------------------------------*/

   %if %length(&continue) > 0 %then %do;

      %jkcont01(data=&temp1,
                 out=&_cont_,
                  by=&by,
                 tmt=&tmt,
            uniqueid=&uniqueid,
                 var=&continue,
               stats=&stats,
               print=NO)

      %if "&p_cont" = "CMHRMS" %then %do;

         %if &pairwise %then %do;
            %jkpaired(chkdata = NO,
                         data = &subset,
                        where = ,
                          out = &_cont2_,
                           by = &by,
                         pair = &tmt,
                       sortby = ,
                       idname = _id_,
                           id = %str(compress(put(_1,3.)||'_'||put(_2,3.),' ')) )

            %let id = _id_;
            %end;
         %else %do;
            %let id = ;
            %let _cont2_ = &subset;
            %end;

         %jkpval05(data=&_cont2_,
                    out=&_pcont_,
                     by=&by,
                     id=&id,
               uniqueid=&uniqueid,
                control=&control,
                    tmt=&tmt,
               response=,
                p_value=&p_cont,
                vartype=CONTINUE,
               pairwise=&pairwise);

         data &_cont_;
            merge &_cont_ &_pcont_;
            by &by _vname_;
            length _vtype_ $8;
            retain _vtype_ 'CONT';
            run;

         proc delete data=&_pcont_;
            run;
         %end;

      %else %if "&p_cont" = "ANOVA" %then %do;

         %jkpval04(data=&subset,
                   out=&_pcont_,
                    by=&by,
               control=&control,
              interact=&interact,
                    ss=&ss,
                   tmt=&tmt,
              continue=&continue,
              pairwise=&pairwise,
                 print=NO)

         data &_cont_;
            merge &_cont_ &_pcont_;
            by &by _vname_ &tmt;
            length _vtype_ $8;
            retain _vtype_ 'CONT';
            run;

         proc delete data=&_pcont_;
            run;

         %end;

      %else %if "&p_cont" = "ANCOVA"  & "&covars" > "" %then %do;

         %jkpval04(data=&subset,
                   out=&_pcont_,
                    by=&by,
                covars=&covars,
               control=&control,
              interact=&interact,
                    ss=&ss,
                   tmt=&tmt,
              continue=&continue,
              pairwise=&pairwise,
                 print=NO)

         data &_cont_;
            merge &_cont_ &_pcont_;
            by &by _vname_ &tmt;
            length _vtype_ $8;
            retain _vtype_ 'CONT';
            run;

         proc delete data=&_pcont_;
            run;
         %end;

      %else %if "&p_cont" = "PAIRED" %then %do;
         %jkpval05(data=&subset,
                    out=&_pcont_,
                     by=&by,
                     id=&id,
               uniqueid=&uniqueid,
                control=,
                    tmt=&tmt,
                tmtdiff=&tmtdiff,
               response=,
                p_value=&p_cont,
                vartype=CONTINUE,
               pairwise=&pairwise)

         data &_cont_;
            merge &_cont_ &_pcont_;
            by &by _vname_;
            length _vtype_ $8;
            retain _vtype_ 'CONT';
            run;

         proc delete data=&_pcont_;
            run;

         %end;

      %else %do;

         data &_cont_;
            set &_cont_;
            length _vtype_ $8;
            retain _vtype_ 'CONT';
            run;

         %end;

      /*
      title5 "DATA=&_cont_ _CONT_  The continuous variables";
      proc print data=&_cont_;
         run;
      title5;
      */

      %end /* if continue variables exist 0 */;

   %else %do;
      %let _cont_ = ;
      %end;

   data &outstat;
      retain &by _vname_ &tmt _order_ _level_ _vtype_
            _ptype_ _covar_ _cntl_;

      length _order_ 8 _cntl_ $8 _level_ $8;

   %if %length(&kontrol) > 0 %then %do;
      retain _cntl_ "&kontrol";
      %end;

      set &_disc_ &_cont_ &_patno_;
      by &by _vname_;

   %if %length(&yesno)>0 %then %do;
      if indexw("&yesno",trim(_vname_)) then do;
         if _level_ ^= "&yes" then delete;
         _vtype_ = 'YESNO';
         end;
      %end;

   %local _row_;
   %if "&row_ordr"^="" %then %do;
      %jkrord(rowvars=&row_ordr)
      %end;

      label
         _row_   = 'Order variable for _VNAME_ variables'
         _vname_ = 'Analysis variables original name'
         _order_ = 'Order variable for _LEVEL_'
         _level_ = 'Values of original discrete variables'
         _vtype_ = 'Analysis variable type'
         _ptype_ = 'Statistical test used for PROB'
         _covar_ = 'The covariate'
         _cntl_  = 'The controlling variable'
         _scores_= 'Value used in PROC FREQ scores option'
         n       = 'n'
         nmiss   = 'n Missing'
         max     = 'Max.'
         min     = 'Min.'
         mean    = 'Mean'
         median  = 'Median'
         q1      = '25th percentile'
         q3      = '75th percentile'
         mode    = 'Mode'
         std     = 'SD'
         stdmean = 'Std Error'
         sum     = 'Sum'
         count   = 'Frequency'
         pct     = 'Proportions'
         prob    = 'P-values'
         lsm     = 'Mean (adj)'
         lsmse   = 'se'
         sse     = 'Error SS'
         dfe     = 'Error df'
         mse     = 'MSE'
         rootmse = 'Root MSE'
         pr_cntl = 'P-value for controlling variable'
         ;
      run;

   %if "&row_ordr"^="" %then %do;
      %let _row_ = _row_;
      proc sort data=&outstat;
         by &by &_row_;
         run;
      %end;

   /*
   / Process the data for the ORDER= option
   /-------------------------------------------------------*/

   %local rs_order;
   %if %index(&order,DESCEND) | %index(&order,ASCEND) %then %do;

      %let rs_order = _&sysindex._A;

      /*
      / Compute the row totals for use in _ORDER_ variable
      /-----------------------------------------------------*/

      proc summary data=&outstat nway missing;
         class &by &_row_ _vname_ _level_;
         var &orderval;
         output
            out=&rs_order(drop=_type_ _freq_)
            sum=_order_;
         run;

      data &outstat;
         merge
            &outstat
               (
                drop=_order_
               )
            &rs_order
               (
                keep = &by &_row_ _vname_ _level_ _order_
               )
            ;

         by &by &_row_ _vname_ _level_;

         %if %index(&order,DESCEND) %then %do;
            _t__ = _order_ * -1;
            drop _order_;
            rename _t__ = _order_;
            %end;
         run;

      proc sort data=&outstat;
         by &by &_row_ _vname_ _order_ _level_;
         run;

      %end;

   /*
   / Process the data for the YN_ORDER= option
   /--------------------------------------------------------*/

   %local yn_data;
   %if %index(&YN_order,DESCEND) | %index(&YN_order,ASCEND) %then %do;

      %let yn_data = _&sysindex._A;

      /*
      / Compute the row totals for use in _ORDER_ variable
      /-----------------------------------------------------*/

      proc summary
            nway missing
            data=&outstat(where=(_vtype_='YESNO'));

         class &by _vname_ _vtype_;
         var &orderval;
         output
            out=&yn_data(drop=_type_ _freq_)
            sum=_order_;
         run;

      %local YN_SORT;
      %if %index(&yn_order,DESCEND) %then %let yn_sort = DESCENDING;

      proc sort data=&yn_data;
         by &by &yn_sort _order_;
         run;

      %local _YNO_0 YNI;

      %let _yno_0 = 0;

      %global YN_OLIST;
      %let    yn_olist = ;

      data _null_;
         set &yn_data end=eof;

         length ci $8;
         ci = left(put(_n_,8.));

         call symput('_YNO_'||ci , trim(_vname_));

         if eof then do;
            call symput('_YNO_0' , trim(ci));
            end;

         run;

      %do YNI = 1 %to &_yno_0;
         %let yn_olist = &yn_olist &&_yno_&yni;
         %end;

      %put NOTE: You have specified YN_ORDER=&yn_order, SIMSTAT has created YN_OLIST as follows:;
      %put NOTE: YN_OLIST=&yn_olist;

      %end;

   proc delete
      data=&subset &temp1 &temp2 &dups &_patno_ &_cont_ &_cont2_
           &_disc_ &_disc2_ &_pcont_ &_pdisc_ &rs_order yn_data;
      run;

   %if "&print"="YES" %then %do;
      title5 "DATA=&outstat";
      proc contents data=&outstat;
         run;
      proc print data=&outstat;
         by &by;
         run;
      %end;

 %EXIT:
   %put NOTE: MACRO simstat Ending execution.;
   %mend simstat;

            %jkpaired(chkdata = NO,
                         data = &_disc2_,
                        where = _level_^='_',
                          out = &_disc2_,
                           by = &by _vname_ _vtype_,
                         pair = &tmt,
                       sortby = ,
                       idname = _id_,
          /users/d33/jf97633/sas_y2k/macros/stackvar.sas                                                      0100664 0045717 0002024 00000012272 06634202504 0022047 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ PROGRAM NAME:     STACKVAR>SAS
/
/ PROGRAM VERSION:  1.1
/
/ PROGRAM PURPOSE:  Utility to use with PROC REPORT listings that will
/                   take the values of a number of variables and create
/                   a new variable that can be used by REPORT with the FLOW
/                   option.  Examples of stacked variables can be found in the
/                   IDSG document "Reports and General Formatting".
/
/ SAS VERSION:      6.12 (UNIX)
/
/ CREATED BY:       John Henry King
/ DATE:             OCT1997
/
/ INPUT PARAMETERS: NEWVAR=   Names the variable created by the concatination operation.
/
/                   STACK=    List the variable names and optionally the SAS format to
/                             use in the concatination operation.  If a variable name
/                             is followed by a SAS format, a word with a dot(.) in it,
/                             the macro uses that format to PUT the values of the
/                             preceeding variable.  If the variable name is NOT followed
/                             by a SAS format then the value is use unformated.  If a
/                             numeric variable is not formated then SAS will perform
/                             a numeric to character conversion.
/
/                   SPLIT=*   Names the split character to include in the new variable
/                             for explicit splitting.
/
/                   SLASH=/   Names the character to place between the values of the
/                             individual variables.
/
/
/ OUTPUT CREATED:   A SAS variable.
/
/ MACROS CALLED:    None
/
/ EXAMPLE CALL:     %stackvar(newvar = new,
/                             stack  = var1 var2 date9. var3 date9.)
/
/                   This example call would produce the following 3 lines of code:
/
/                   LENGTH NEW $200.;
/
/                   NEW = TRIM(LEFT(VAR1)) ||"/*"|| TRIM(LEFT(PUT(VAR2,DATE9.)))
/                      ||"/*"|| TRIM(LEFT(PUT(VAR3,DATE9.))) ;
/
/                   IF LENGTH(NEW)=200 THEN
/                      PUT "NOTE: Length of new equals 200 the values may be truncated.";
/
/========================================================================================
/ CHANGE LOG:
/
/    MODIFIED BY: Jonathan Fry
/    DATE:        10DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 1.1.
/    ------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    ------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    ------------------------------------------------------------------------
/=======================================================================================*/

%macro stackvar( newvar = _NEWVAR_,
                 stack  = ,
                 split  = *,
                 slash  = /
                );

/*-------------------------------------------------------------------------/
/ JMF001                                                                   /
/ Display Macro Name and Version Number in LOG                             /
/-------------------------------------------------------------------------*/

   %put ------------------------------------------------------;
   %put NOTE: Macro called: STACKVAR.SAS   Version Number: 1.1;
   %put ------------------------------------------------------;

   %local i j w nw;

   %let j  = 0;
   %let i  = 1;

   %let w  = %scan(&stack,&i,%str( ));
   %let nw = %scan(&stack,&i+1,%str( ));

   %do %while(%bquote(&w)^=);

/*-------------------------------------------------------------------------/
/ If current word is a name with no dot assume a sas name and process      /
/-------------------------------------------------------------------------*/

      %if %index(&w,.)=0 %then %do;
         %let j = %eval(&j +1);
         %local v&j;

/*-------------------------------------------------------------------------/
/ If the next word is a format (has a dot) them process variable name      /
/ with format                                                              /
/-------------------------------------------------------------------------*/

         %if %index(&nw,.)>0 %then %do;
            %let v&j = trim(left(put(&w,&nw)));
            %end;

/*-------------------------------------------------------------------------/
/ Otherwise process variable name without format                           /
/-------------------------------------------------------------------------*/

         %else %do;
            %let v&j = trim(left(&w));
            %end;

         %end;

      %let i  = %eval(&i + 1);
      %let w  = %scan(&stack,&i,%str( ));
      %let nw = %scan(&stack,&i+1,%str( ));

      %end;

   %if &j > 0 %then %do;

      length &newvar $200;

      &newvar = &&v1

      %do i = 2 %to &j;
         ||"&slash&split"|| &&v&i
         %end;
      ;

      if length(&newvar)=200 then
         put "W A R N I N G: Length of &newvar equals 200 the values may be truncated.";

      %end;

   %mend stackvar;
                                                                                                                                                                                                                                                                                                                                      /users/d33/jf97633/sas_y2k/macros/statinit.sas                                                      0100664 0045717 0002024 00000017544 06634201706 0022102 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ Program Name:     STATINIT.SAS
/
/ Program Version:  3.1
/
/ Program purpose:  Initialise the environment in preparation for the statistical
/                   macros. In practice, this means allocating a few libraries.
/
/ SAS Version:      6.12
/
/ Created By:       Andrew Ratcliffe, SPS Limited
/ Date:             January 1993
/
/ Input Parameters: UTILDATA = Physical name of library containing data and tables.
/                   UTILFMT  = Physical name of library containing format.
/                   UTILGDEV = Physical name of library containing user-written
/                              graphical devices.
/                   GDEVNUM  = Numeric suffix of libname to which UTILGDEV is to be
/                              allocated, ie. GDEVICEn.
/                   UTILSCL  = Physical name of library containing SCL code.
/                   UTILIML  = Physical name of library containing IML code.
/                   TIDY     = Delete temporary datasets?
/                   PFX      = Prefix of temporary work files. Provided for compatibility
/                              only - %STATINIT does not use any temp files.
/                   VERBOSE  = Verbosity of messages
/
/ Output Created:
/
/ Macros Called:    %FN
/
/ Example Call:     %statinit;
/
/============================================================================================
/Change Log
/
/    MODIFIED BY: ABR      (Original version)
/    DATE:        Jan93
/    MODID:       1
/    DESCRIPTION: Avoid UTILFMT being added to FMTSEARCH more than once.
/    ---------------------------------------------------------------------------------
/    MODIFIED BY: ABR
/    DATE:        10Feb93
/    MODID:       2
/    DESCRIPTION: Add dump=n to %getopts.
/    ---------------------------------------------------------------------------------
/    MODIFIED BY: ABR
/    DATE:        06Apr93
/    MODID:       3
/    DESCRIPTION: Add OS/2.
/    ---------------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:        14Jun93
/    MODID:       4
/    DESCRIPTION: Add SUN 4.
/    ---------------------------------------------------------------------------------
/    MODIFIED BY: AGW
/    DATE:        20Mar97
/    MODID:       5
/    DESCRIPTION: Only SUN 4, for SPLASH project.
/                 No need for %GETOPTS, %BWSYSIN.
/    ---------------------------------------------------------------------------------
/    MODIFIED BY: AGW
/    DATE:        20Jun97
/    MODID:       6
/    DESCRIPTION: Correction of &utilgdev (GDEVICEn) error.
/    ---------------------------------------------------------------------------------
/    MODIFIED BY: Jonathan Fry
/    DATE:        10DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 3.1.
/    ---------------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    ---------------------------------------------------------------------------------
/============================================================================================*/

   %macro statinit(utildata = _DEFAULT_
                  ,utilgdev = _DEFAULT_
                  ,gdevnum  = 0
                  ,utilfmt  = _DEFAULT_
                  ,utilscl  = _DEFAULT_
                  ,utiliml  = _DEFAULT_
                  ,tidy=y
                  ,pfx=sti_
                  ,verbose=2
                  );

/*------------------------------------------------------------------------------/
/ JMF001                                                                        /
/ Display Macro Name and Version Number in LOG                                  /
/------------------------------------------------------------------------------*/

   %put ------------------------------------------------------;
   %put NOTE: Macro called: STATINIT.SAS   Version Number: 3.1;
   %put ------------------------------------------------------;

     %let tidy = %upcase(&tidy);

     %if %length(&pfx) gt 4 %then %do;
       %put WARNING: STATINIT: "&pfx" exceeds maximum length for PFX.;
       %let pfx = %substr(&pfx,1,4);
       %put .                  PFX has been truncated to "&pfx".;
       %end;

     %if %index(0123456789,&verbose) eq 0 %then %do;
       %put WARNING: STATINIT: "&verbose" is an invalid value for VERBOSE.;
       %let verbose = 2;
       %put .                  VERBOSE has been set to &verbose.;
       %end;

/*------------------------------------------------------------------------------/
/ For SUN 4                                                                     /
/------------------------------------------------------------------------------*/

     %if "&sysscp" eq "SUN 4" %then %do;

       %if %length(&utilscl) eq 0 %then %do;
         %if &verbose ge 3 %then
           %put NOTE: STATINIT: As requested, SCL library not allocated.;
         %end;
       %else %if %nrbquote(&utilscl) eq _DEFAULT_ %then %do;
         libname utilscl "/usr/local/medstat/sas/scl";
         %end;
       %else %do;
         libname utilscl "&utilscl";
         %end;

       %if %length(&utiliml) eq 0 %then %do;
         %if &verbose ge 3 %then
           %put NOTE: STATINIT: As requested, IML library not allocated.;
         %end;
       %else %if %nrbquote(&utiliml) eq _DEFAULT_ %then %do;
         libname utiliml "/usr/local/medstat/sas/iml";
         %end;
       %else %do;
         libname utiliml "&utiliml";
         %end;

       %if %length(&utilfmt) eq 0 %then %do;
         %if &verbose ge 3 %then
           %put NOTE: STATINIT: As requested, format library not allocated.;
         %end;
       %else %do;
         %if %nrbquote(&utilfmt) eq _DEFAULT_ %then %do;
           libname library "/usr/local/medstat/sas/formats";
           %end;
         %else %do;
           libname library "&utilfmt";
           %end;
       /* options fmtsearch=(&opt_fmts); */
         %end;

       %if %length(&utildata) eq 0 %then %do;
         %if &verbose ge 3 %then
           %put NOTE: STATINIT: As requested, DATA library not allocated.;
         %end;
       %else %if %nrbquote(&utildata) eq _DEFAULT_ %then %do;
         libname utildata "/usr/local/medstat/sas/data";
         %end;
       %else %do;
         libname utildata "&utildata";
         %end;

      %if %length(&utilgdev) eq 0 %then %do;
         %if &verbose ge 3 %then
           %put NOTE: STATINIT: As requested, graph device lib not allocated.;
         %end;
       %else %if %nrbquote(&utilgdev) eq _DEFAULT_ %then %do;
         libname gdevice&gdevnum "/usr/local/medstat/sas/gdevice";
         %end;
       %else %do;
         libname gdevice&gdevnum "&utilgdev";
         %end;

       %local fn shell;
       %let fn=%fn;
       %let shell=%sysget(SHELL);
       %if "&shell"="/bin/csh" %then %do ;
         %sysexec if (-w &fn..gsf) rm &fn..gsf ;
       %end ;
       %else %if "&shell"="/bin/sh" %then %do ;
         %sysexec rm &fn..gsf 2> /dev/null ;
       %end ;
       %else %if "&shell"="/bin/bash" %then %do ;
         %sysexec rm &fn..gsf 2> /dev/null ;
       %end ;

       filename utilgsf "&fn..gsf" new ;

   %end;

/*------------------------------------------------------------------------------/
/ End of SUN 4 processing                                                       /
/------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------/
/ Unsupported OS.                                                               /
/------------------------------------------------------------------------------*/

   %else %do;
      %if &verbose ge 1 %then %do;
         %put ERROR: STATINIT: Unknown operating system (&sysscp);
         %put .                Libraries cannot be allocated;
      %end;
   %end;
%mend statinit;
--------------------------------------------------
/    MODIFIED BY: AGW
/    DATE:        20Jun97
/    MODID:       6
/    DESCRIPTION: Correction of &util/users/d33/jf97633/sas_y2k/macros/suffix.sas                                                        0100664 0045717 0002024 00000004453 06634200363 0021540 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ Program Name:     SUFFIX.SAS
/
/ Program Version:  2.1
/
/ Program purpose:  The macro takes a list of words separated by blanks and adds a common
/                   suffix to each word in turn, thus creating a new list.
/
/ SAS Version:      6.12
/
/ Created By:       John H. King
/ Date:
/
/ Input Parameters: STRING - A list of variables to be processed by the macro.
/                   SUFFIX - A string of character(s) to be added to the end of every
/
/ Output Created:   List of variables specified in STRING, with SUUFIX added after every word.
/
/ Macros Called:    None.
/
/ Example Call:
/
/================================================================================================
/Change Log
/
/    MODIFIED BY: Jonathan Fry
/    DATE:        10DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 2.1.
/    ----------------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    ----------------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    ----------------------------------------------------------------------------------
/================================================================================================*/

%macro suffix(string,suffix);

/*----------------------------------------------------------------------------/
/ JMF001                                                                      /
/ Display Macro Name and Version Number in LOG                                /
/----------------------------------------------------------------------------*/

   %put ----------------------------------------------------;
   %put NOTE: Macro called: SUFFIX.SAS   Version Number: 2.1;
   %put ----------------------------------------------------;

   %local count word newlist delm;
   %let delm  = %str( );
   %let count = 1;
   %let word  = %scan(&string,&count,&delm);
   %do %while(%quote(&word)~=);
      %let newlist = &newlist &word.&suffix;
      %let count   = %eval(&count + 1);
      %let word    = %scan(&string,&count,&delm);
      %end;
   &newlist
%mend suffix;
                                                                                                                                                                                                                     /users/d33/jf97633/sas_y2k/macros/sumtab.sas                                                        0100664 0045717 0002024 00000221456 06644435654 0021551 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ PROGRAM NAME:     SUMTAB.SAS
/
/ PROGRAM VERSION:  1.3
/
/ PROGRAM PURPOSE:  This program created a summary table including summary
/                   statistics for numeric variables and frequencies and relative frequencies
/                   for categorical variables.  It was designed to memic the output of %SUMSTAT
/                   without depending on the VLBES data set.  Instead, It uses the labels and
/                   formats associated with each varaible assigned by FORMAT, LABEL, or ATTRIB
/                   statements.  By default, numeric variables are analysed numerically and
/                   character variables are analysed as categorical variables.  However you may
/                   specify any numeric variables be analysed as categorical variables.
/                   Several optional parameters are provided to allow you to control the
/                   appearance of the output.
/
/ SAS VERSION:      6.12 (UNIX)
/
/ CREATED BY:       Carl P. Arneson
/
/ DATE:             12 Aug 1992
/
/ INPUT PARAMETERS:
/
/ data=        names the SAS data set to be analyzed.  The default is _LAST_.
/
/ out=         name the output data set created by the macro.  The default is
/              SUMOUT.
/
/ var=         specifies the variables in the input data set which you would
/              like analysed.  You may also force numeric variables to be
/              analysed as categorical variables by followin the variables
/              name with {c} (e.g., VAR=NUMVAR1 NUMVAR2 {c} NUMVAR2 would
/              force NUMVAR2 to be analysed as a categorical variable).
/              Variables will be ordered as they are listed.  This parameter
/              must be specifed.  The default setting is null.
/
/ across=      specifies a single variable in the input data set (if any) to be
/              used as an "across-style" statification variable.  Levels will
/              be ordered by their pre-formatted values. This is an optional
/              parameter.  The default setting is null.
/
/ by=          specifies a list of variables in the input data set to use as
/              "column-style" stratification variables.  Levels will be ordered
/              by their pre-formatted values.  This is an optional parameter.
/              The default setting is null.
/
/ pageby=      specifies a list of variables in the input data set to use as
/              "pageby-style" stratification variables.  Levels will be ordered
/              by their pre-formatted values.  This is an optional parameter.
/              The default setting is null.
/
/ stats=       list the PROC UNIVARIATE key words for statistics that you would
/              like to appear in the report for numeric variables.  The
/              statistics are displayed in the order that you list them.  The
/              default setting is
/
/                 N {INT} MEAN {+1} STD {+1} MEDIAN {+1} MIN MAX
/
/
/ varstyle=    specifies the style to be used for the variable labels.  In the
/              column-style format, the variables labels will be placed in the
/              first column of the report.  In the row-style format, each
/              variable label is placed in its own row, preceding the summary
/              statistics, left justified with the left edge of the report.
/              The row-style format can be used to avoid wasting space when the
/              the variables labels are long, or there are too many columns.
/              The default setting is COLUMN.
/
/ total=       specifies whether you would additionally like a summary acros
/              levels of the "across variable".  The default setting is no.
/
/ fillzero=    specifies whether or not to fill in levels of categorical
/              variables with zeros for strata with no observations for those
/              levels.  The default setting is YES.
/
/ pgblock=     specifies whether or not to begin a new page whenever an entire
/              block or by-group will not fit on the current page.  The default
/              setting is NO.
/
/ missing=     specifies how you would like to treat observations where the
/              value of a categorical variable is missing.  Valid settings are
/              YES, NO or a list of variables numbers (e.g., MISSING=1 4 5
/              refers to the first, fourth and fifth variables in the VAR=
/              list).  "YES" indicates that you would like frequencies to be
/              provided for the missing levels of all categorical variables
/              and that these observations should be used in the calculation
/              of relative frequencies.  "NO" indicates that you do not want
/              these observations used for any of the variables.  A list of
/              variable numbers indicates for which variables you woul like to
/              include missing observation if you do not want missing values
/              to be used for all variables.  The default setting is YES.
/
/ missord=     specifies where you would like missing levels of categorical
/              variables to be placed in the list of levels.  The default
/              setting is LAST.
/
/ misslbl=     specifies a label fro missing levels of categorical variables.
/              If the format associated with a variable does not specify a
/              label for missing values, this label is used.  The default
/              setting is Missing.
/
/ varlbl=      specifies a label for the "variable" column of the report.  The
/              default setting is variable.
/
/ statlbl=     specifies a label for the "statistic/category" column of the
/              report.  The default setting is Statistic*or*Category, which
/              will automatically be adjusted for the split character being
/              used.
/
/ totlbl=      specifies a label for the "total" column of the report (if any).
/              The default setting is Total.
/
/ uline=       specifies a character to be used for underlining in spanning
/              titles in the report.  This character be one of the repeatable
/              characters used by PROC REPORT (i.e., valid values are -,=,_,.
/              *, or +).  To be safe, you should enclose the split character
/              in the %STR function.  The default setting is %STR(+) (which
/              can be turned into a solid horizontal bar for IBM printers by
/              %MAPAGEs PLUSES= option).
/
/ split=       specifies the split-character to be used in PROC REPORT.
/              Again, when specified, this character should be enclosed in the
/              %STR function.  The default setting is %STR(*).
/
/ dec=         specifies the number of decimal places to use in summary
/              statistics when there is not a format associates with a numeric
/              variable.  If there is a format associated with a numeric
/              variable, it will use the number of decimal places specified
/              with it.  The default setting is 2.
/
/ spacing=     can be used to force a specified column spacin to use in PROC
/              REPORT.  By default this is null, and the best spacing is
/              calculated automatically.
/
/ pctzero=     specifies the print of zero percents.  The default N is to print
/              zero percents as blank.  Specify Y to cause SUMTAB to print zero
/              percents as (0%).
/
/ skipby=      directs SUMTAB to print a blank line between By-groups.  The
/              default is Y.
/
/ catnlbl=     specifies the label for catagorical variable N.  The default is
/              n (lowercase n).
/
/ outof=       specifies the number of digits in denom for ##/## (##%)
/
/ resolve=     causes SUMTAB to resolve macro expressions in labels.  This
/              parameter is useful when the labels for summary variables are
/              longer than 40 characters, the SAS maximum for labels.
/
/ OUTPUT CREATED: Creates a TABLE and a data set.  Or just a data set.
/
/ MACROS CALLED:
/               from the SAS supplied AUTOCALL library
/                  %CMPRES
/                  %LEFT
/                  %TRIM
/                  %LOWCASE
/               from the GlaxoWellcome AUTOCALL library
/                  %GETOPTS
/                  %BWGETTF
/                  %TRANSLAT
/                  %INFIX
/
/ EXAMPLE CALL:
/
/   data getrdy;
/     set in.dd01(keep=trt age race sex height weight);
/     attrib
/        trt    label='Dose cohort' format=$trt101_.
/        age    label='Age (years)' foramt=5.2
/        race   label='Race'        format=race.
/        sex    label='Sex'         format=$sex.
/        height label='Height (cm)' format=6.2
/        weight label='Weight (kg)' format=6.3
/        ;
/     run;
/
/
/   %sumtab(var = age race {c} sex height weight,
/        across = trt,
/         total = yes,
/        totlbl = All IV*Cohorts)
/
/==========================================================================================
/ CHANGE LOG:
/
/    MODIFIED BY: John Henry King
/    DATE:        05MAR1997
/    MODID:       JHK001
/    DESCRIPTION: Added standard header.
/    -----------------------------------------------------------------------------
/    MODIFIED BY: John Henry King.
/    DATE:        06MAR1997
/    MODID:       JHK002
/    DESCRIPTION: Added fix for DATA=_LAST.
/    -----------------------------------------------------------------------------
/    MODIFIED BY: Carl Arneson documented by John King
/    DATE:        OCT1997
/    MODID:       JHK003
/    DESCRIPTION: Modifications needed to make the macro IDSG compliant.
/                 These are changes to defaults.
/    ---------------------------------------------------------------------------
/    MODIFIED BY: John King
/    DATE:        16FEB1998
/    MODID:       JHK004
/    DESCRIPTION: The macro is having trouble with VARLBL strings, that
/                 include the word 'AND'. I am adding %QUPCASE() in a couple
/                 of places where it was not used.
/    ---------------------------------------------------------------------------
/    MODIFIED BY: Jonathan Fry
/    DATE:        10DEC1998
/    MODID:       JMF005
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 1.3.
/    ---------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX006
/    DESCRIPTION:
/    ---------------------------------------------------------------------------
/========================================================================================*/

%macro SUMTAB(data=_LAST_,          /* Input data set                      */
              var=,                 /* Analysis variable list (required)   */
              across=,              /* Across variable name                */
              by=,                  /* Column style BY-variable list       */
              pageby=,              /* PAGEBY-variable list                */
              varstyle=Column,      /* Style for listing the variable name */
              varuline=%str( ),     /* Underline char. for varstyle=Row    */
              out=SUMOUT,           /* Output data set name                */
              append=,              /* Data set to add to current summary  */
              print=Y,              /* Print out a report?                 */
              total=N,              /* Include total for across variable?  */
              nozero=N,             /* Suppress N=0?                       */
              fillzero=Y,           /* Fill in levels of cat vars with 0's?*/
              pctzero=N,            /* Include "(0%)" string with 0's?     */
              printn=Y,             /* Print N's for categorical variables?*/
              hideacn=N,            /* Hide across level counts?(=> blind) */
              hideacp=N,            /* Hide across level pcts?  (=> blind) */
              pgblock=N,            /* Fit variable blocks on a page?      */
              skipby=Y,             /* Skip a line between By-groups?      */
              missing=Y,            /* Include missing levels of cat vars ?*/
              missord=Last,         /* Put missing levs of cat vars last?  */
              misslbl=Missing,      /* Def label for miss vals of cat vars */
              varlbl=Variable,                    /* Variable column label */
              statlbl=Statistic*or*Category,      /* Statistic column label*/
              totlbl=Total,                       /* Total column label    */
              vallbl=Value,         /* Label for "Value" when no acr. var. */
              catnlbl=n,            /* Label for Categorical N             */
              uline=%str(+),        /* Underline character for span titles */
              split=%str(*),        /* Split character for PROC REPORT     */
              dec=2,                /* Def dec places used in statistics   */
              pctdec=0,             /* # dec places used for percents      */
              spacing=,             /* Force column spacing in PROC REPORT */
              width=,               /* Width to use for value columns      */
              maxdig=,              /* Maximum # digits to use before dec. */
              outof=0,              /* # digits in denom for ##/## (##%)   */
              resolve=N,            /* Resolve macro expressions in labels?*/
              statfmt=_DEFAULT_,    /* Format used for summary statistics  */
              stats=N {INT} MEAN {+1} STD {+1} MEDIAN {+1} MIN MAX) ;
                                                      /* PROC UNIVARIATE   */
                                                      /* key words list    */

/*----------------------------------------------------------------------/
/ JMF005                                                                /
/ Display Macro Name and Version Number in LOG                          /
/----------------------------------------------------------------------*/

   %put ----------------------------------------------------;
   %put NOTE: Macro called: SUMTAB.SAS   Version Number: 1.3;
   %put ----------------------------------------------------;

   %if "&sysscp"="SUN 4" %then %do ;
      %if &sysver<6.09 %then %do ;
         %put ERROR: You must use version 6.09 or higher with SUMTAB. ;
         %if &sysenv=BACK %then %str(;ENDSAS;) ;
      %end ;
   %end ;

/*----------------------------------------------------------------------/
/ Find out about previous SUMTAB calls:                                 /
/----------------------------------------------------------------------*/

   %global __sumtab ;
   %if &__sumtab= %then %let __sumtab=1 ;
   %else %let __sumtab=%eval(&__sumtab + 1) ;

/*----------------------------------------------------------------------/
/ Make sure input data set is not empty:                                /
/----------------------------------------------------------------------*/

   %local _nobs_ ;

/*----------------------------------------------------------------------/
/ JHK002                                                                /
/ Check for DATA=_LAST_ and assign value of SYSLAST.                    /
/----------------------------------------------------------------------*/

   %let data = %upcase(&data);
   %if "&data" = "_LAST_" %then %let data = &syslast;

   proc contents data=&data noprint out=__core1(keep=nobs) ;
   run ;

   data _null_ ;
      set __core1(obs=1) ;
      call symput('_nobs_',left(nobs)) ;
   run ;

   %if ~(&_nobs_) %then %do ;
      %put WARNING: Input data set has 0 observations ;
      %goto leave ;
   %end ;

/*----------------------------------------------------------------------/
/ Parse up variable list into variables and variable type               /
/ specifications:                                                       /
/----------------------------------------------------------------------*/

   %local piece cnt1 cnt2 vopt0 i j k cb ncb ;

   %let ncb=0 ;
   %let cnt1 = %index(&var,%str(<)) ;
   %do %while(&cnt1) ;
      %let cnt2 = %eval(%index(&var,%str(>)) + 1) ;
      %let ncb = %eval(&ncb + 1) ;
      %let cb = &cb %substr(&var,&cnt1,%index(%substr(&var,&cnt1),%str(>)));
      %if &cnt1=1 and %length(&var)=%eval(&cnt2-1) %then %let var = #&ncb ;
      %else %if &cnt1=1 %then %let var = #&ncb %substr(&var,&cnt2) ;
      %else %if %length(&var)>%eval(&cnt2-1) %then
         %let var = %substr(&var,1,%eval(&cnt1-1)) #&ncb %substr(&var,&cnt2) ;
      %else %let var = %substr(&var,1,%eval(&cnt1-1)) #&ncb ;
      %let cnt1 = %index(&var,%str(<)) ;
   %end ;

   %local go check ;
   %let go = 1 ;
   %let check = 0 ;
   %let cnt1 = 1 ;
   %let cnt2 = 0 ;

   %do %while (&go) ;
      %let piece = %scan(&cb,&cnt1,%str(<>)) ;
      %if %length(&piece)>0 %then %do ;
         %let check = 0 ;
         %let cnt2 = %eval(&cnt2 + 1) ;
         %local cb&cnt2 ;
         %let cb&cnt2 = &piece ;
      %end ;
      %else %if &check=1 %then %let go = 0 ;
      %else %let check = 1 ;
      %let cnt1 = %eval(&cnt1 + 1) ;
   %end ;

   %local cbvars ;
   %do i = 1 %to &ncb ;
      %let cbvars = &cbvars %upcase(&&cb&i) ;
      %let cnt1 = 1 ;
      %let piece = %scan(&&cb&i,&cnt1,%str( )) ;
      %do %while (&piece~=) ;
         %local cb&i._%eval(&cnt1-1) ;
         %let cb&i._%eval(&cnt1-1) = %upcase(&piece) ;
         %let cnt1 = %eval(&cnt1 + 1) ;
         %let piece = %scan(&&cb&i,&cnt1,%str( )) ;
      %end ;
      %local ncb&i ;
      %let ncb&i = %eval(&cnt1 - 2) ;
   %end ;

   %let cnt1=0 ;
   %let cnt2=1 ;
   %let piece = %qscan(&var,&cnt2,%str( )) ;
   %do %while(&piece~=) ;
      %let cnt2 = %eval(&cnt2 + 1) ;
      %if %substr(&piece,1,1)={ %then
         %let vopt&cnt1 = %upcase(%substr(&piece,2,1)) ;
      %else %if %substr(&piece,1,1)=# %then %do ;
         %let cnt1 = %eval(&cnt1 + 1) ;
         %let i = %substr(&piece,2) ;
         %let var&cnt1 = &&cb&i._0 ;
         %let vopt&cnt1 = B ;
      %end ;
      %else %do ;
         %local var&cnt1 vopt&cnt1 ;
         %let cnt1 = %eval(&cnt1 + 1) ;
         %let var&cnt1 = %upcase(&piece) ;
         %let vopt&cnt1 = ;
      %end ;
      %let piece = %qscan(&var,&cnt2,%str( )) ;
   %end ;
   %local nvar ;
   %let nvar = &cnt1 ;
   %local varlst ;
   %let varlst = ;
   %do i = 1 %to &nvar ;
      %if &&vopt&i ~= B %then %let varlst = &varlst &&var&i ;
   %end ;

/*----------------------------------------------------------------------/
/ Parse up Summary Statistic list:                                      /
/----------------------------------------------------------------------*/

   %let cnt1 = 0 ;
   %let cnt2 = 1 ;
   %let piece = %qscan(&stats,&cnt2,%str( )) ;
   %do %while(&piece~=) ;
      %if %substr(&piece,1,1)~={ %then %do ;
         %let cnt1 = %eval(&cnt1 + 1) ;
         %local stat&cnt1 stat2&cnt1 statadj&cnt1;
         %let statadj&cnt1 = 0 ;
         %let stat&cnt1 = %upcase(&piece) ;
         %if %length(&&stat&cnt1)>=7 %then
            %let stat2&cnt1 = %substr(&&stat&cnt1,1,6) ;
         %else %let stat2&cnt1 = &&stat&cnt1 ;
      %end ;
      %else %do ;
         %local statadj&cnt1 ;
         %let statadj&cnt1 = %upcase(%substr(&piece,2,%eval(%length(&piece)-2))) ;
      %end ;
      %let cnt2 = %eval(&cnt2 + 1) ;
      %let piece = %qscan(&stats,&cnt2,%str( )) ;
   %end ;
   %local nstat ;
   %let nstat = &cnt1 ;

   %if &nstat>9 %then
      %put WARNING: More than 9 summary statistics specified with STATS=. ;

/*----------------------------------------------------------------------/
/ Parse up BY and PAGEBY variable lists:                                /
/----------------------------------------------------------------------*/

%local lstby nby ;
%let lstby= ;
%let cnt1=1 ;
%let piece=%scan(&by,&cnt1,%str( )) ;
%do %while(%quote(&piece)~=) ;
  %local by&cnt1 ;
  %let by&cnt1=%upcase(&piece) ;
  %let lstby=&piece ;
  %let cnt1=%eval(&cnt1+1) ;
  %let piece=%scan(&by,&cnt1,%str( )) ;
%end ;
%let nby=%eval(&cnt1-1) ;

%local lstpby npby ;
%let lstpby= ;
%let cnt1=1 ;
%let piece=%scan(&pageby,&cnt1,%str( )) ;
%do %while(%quote(&piece)~=) ;
  %local pby&cnt1 lpby&cnt1 ;
  %let pby&cnt1=%upcase(&piece) ;
  %let lstpby=&piece ;
  %let cnt1=%eval(&cnt1+1) ;
  %let piece=%scan(&pageby,&cnt1,%str( )) ;
%end ;
%let npby=%eval(&cnt1-1) ;

/*----------------------------------------------------------------------/
/ Figure out how to set width and maxdig for value columns:             /
/----------------------------------------------------------------------*/

%if &width= & &maxdig= %then %do ;
  %let maxdig = 4 ;
  %let width = %eval(11 + (&pctdec>0) + &pctdec) ;
  %if &outof>0 %then %let width=%eval(&width + &outof + 1) ;
%end ;
%else %if &width= %then %do ;
  %let width = %eval(&maxdig + 7 + (&pctdec>0) + &pctdec) ;
  %if &outof>0 %then %let width=%eval(&width + &outof + 1) ;
%end ;
%else %if &maxdig= %then %do ;
  %if &outof>0 %then %let maxdig = &outof ;
  %else %do ;
    %local maxdadj ;
    %let maxdig = 4 ;
    %let maxdadj = %eval(&width - (11 + (&pctdec>0) + &pctdec)) ;
    %if &maxdadj>1 %then %do ;
      %let maxdadj = %eval(&maxdadj/2) ;
      %let maxdig = %eval(&maxdig + &maxdadj) ;
    %end ;
  %end ;
%end ;

/*----------------------------------------------------------------------/
/ Figure out what format to use for percentages:                        /
/----------------------------------------------------------------------*/

%if %quote(&hideacn)~= %then
  %let printn = %upcase(%substr(&printn,1,1)) ;

%if %quote(&hideacp)~= %then
  %let printn = %upcase(%substr(&printn,1,1)) ;

%if "&hideacn"="Y" & "&hideacp"="Y" %then %do ;
  %put WARNING: Cannot hide both Ns and Percents. ;
  %let hideacp=N ;
%end ;
%else %if ("&hideacn"="Y" | "&hideacp"="Y") & &outof>0 %then %do ;
  %put WARNING: Cannot use OUTOF>0 with HIDEACN=Y or HIDEACP=Y. ;
  %goto leave ;
%end ;

%local pctfmt pctstrl maxpsl ;
%let maxpsl = %eval(&width - (&maxdig + 1)) ;
%let pctstrl = %eval(6 + (&pctdec>0) + &pctdec) ;
%if &pctstrl>&maxpsl %then %do ;
  %let pctstrl = &maxpsl ;
  %put NOTE: Some percentage strings may be truncated in the report. ;
%end ;
%let pctfmt = %eval(3 + (&pctdec>0) + &pctdec) ;
%let pctfmt = %str(&pctfmt).&pctdec ;
%if &hideacp=Y %then %do ;
  %local hidepct ;
  %do i = 1 %to &pctdec ;
    %let hidepct=%trim(&hidepct)* ;
  %end ;
  %if &pctdec>0 %then %let hidepct=%str(.)&hidepct ;
  %let hidepct=(***&hidepct.%) ;
%end ;

/*----------------------------------------------------------------------/
/ Format TOTLBL:                                                        /
/----------------------------------------------------------------------*/

%local totpad ntpc ;
%let totpad='            ';
%let cnt1 = 1 ;
%let piece=%left(%trim(%scan(&totlbl,&cnt1,%str(&split))));
%do %while(&piece~=) ;
  %local tpc&cnt1 ;
  %let cnt2=%length(&piece) ;
  %if &cnt2<%eval(&width - 1) %then %do ;
    %let cnt2=%eval(%eval((&width-&cnt2)/2)+1) ;
    %let piece=%qsubstr(&totpad,1,&cnt2)%str(&piece.%') ;
    %let tpc&cnt1=%unquote(&piece);
  %end ;
  %else %do ;
    %let piece=%str(%')&piece.%str(%') ;
    %let tpc&cnt1=%unquote(&piece) ;
  %end ;
  %let cnt1=%eval(&cnt1 + 1) ;
  %let piece=%left(%trim(%scan(&totlbl,&cnt1,%str(&split))));
%end ;
%let ntpc=%eval(&cnt1 - 1);
%let totlbl= ;
%do i = 1 %to &ntpc ;
  %let totlbl=&totlbl &&tpc&i ;
%end ;

/*----------------------------------------------------------------------/
/ Start keeping track of maximum # of header levels and widths:         /
/----------------------------------------------------------------------*/

%local maxvarl maxstatl ;
%let maxvarl=0 ;
%let maxstatl=0;
%if %quote(&split)~=%str(*) and %index(&statlbl,%str(*)) %then
  %let statlbl=%translat(&statlbl,%str(*),%str(&split)) ;
%local heads ;
%let heads = &ntpc ;
%let cnt1 = 1 ;
%let piece = %scan(&varlbl,&cnt1,%str(&split)) ;

/*----------------------------------------------------------------------/
/ JHK004 changing %quote to %NRQUOTE in the following %DO %WHILE        /
/ this change should allow VARLBL to include the value &                /
/----------------------------------------------------------------------*/

%do %while(%nrquote(&piece)~=) ;
  %if %length(&piece)>&maxvarl %then %let maxvarl=%length(&piece) ;
  %let cnt1 = %eval(&cnt1 + 1) ;
  %let piece = %scan(&varlbl,&cnt1,%str(&split)) ;
%end ;
%let cnt1 = %eval(&cnt1 - 1) ;
%if &cnt1>&heads %then %let heads = &cnt1 ;
%let cnt1 = 1 ;
%let piece = %scan(&statlbl,&cnt1,%str(&split)) ;
%do %while(%quote(&piece)~=) ;
  %if %length(&piece)>&maxstatl %then %let maxstatl=%length(&piece) ;
  %let cnt1 = %eval(&cnt1 + 1) ;
  %let piece = %scan(&statlbl,&cnt1,%str(&split)) ;
%end ;
%let cnt1 = %eval(&cnt1 - 1) ;
%if &cnt1>&heads %then %let heads = &cnt1 ;

/*----------------------------------------------------------------------/
/ Process MISSING= statement:                                           /
/----------------------------------------------------------------------*/

%if %quote(&missing)= %then %let missing=N ;
%if ~%index(YN,%upcase(%substr(&missing,1,1))) %then
  %let missing=%infix(list=%cmpres(&missing),operator=%str(,));
%else %let missing=%upcase(%substr(&missing,1,1));
%if %quote(&missing)=N %then %let missing=(where=(__val__>.Z));
%else %if %quote(&missing)=Y %then %let missing=;
%else %let missing=(where=(__val__>.Z or __var__ in(&missing)));

/*----------------------------------------------------------------------/
/ Initialize the remaining parameters:                                  /
/----------------------------------------------------------------------*/

%let data = %upcase(&data) ;

%let across = %upcase(&across) ;

%let statfmt = %upcase(&statfmt) ;

%if %quote(&varstyle)~= %then
  %let varstyle = %upcase(%substr(&varstyle,1,1)) ;

%if %quote(&print)~= %then
  %let print = %upcase(%substr(&print,1,1)) ;

%if %quote(&total)~= %then
  %let total = %upcase(%substr(&total,1,1)) ;

%if %quote(&pgblock)~= %then
  %let pgblock = %upcase(%substr(&pgblock,1,1)) ;

%if %quote(&missord)~= %then
  %let missord = %upcase(%substr(&missord,1,1)) ;

%if %quote(&fillzero)~= %then
  %let fillzero = %upcase(%substr(&fillzero,1,1)) ;

%if %quote(&pctzero)~= %then
  %let pctzero = %upcase(%substr(&pctzero,1,1)) ;

%if %quote(&nozero)~= %then
  %let nozero = %upcase(%substr(&nozero,1,1)) ;

%if %quote(&printn)~= %then
  %let printn = %upcase(%substr(&printn,1,1)) ;

%if %quote(&skipby)~= %then
  %let skipby = %upcase(%substr(&skipby,1,1)) ;

%if %quote(&resolve)~= %then
  %let resolve = %upcase(%substr(&resolve,1,1)) ;

/*----------------------------------------------------------------------/
/ Initialize the input data set:                                        /
/----------------------------------------------------------------------*/

data __core1 ;
  set &data ;
  __sort__ = 1 ;
  keep &varlst &across &pageby &by &cbvars __sort__;
  run ;

%if %quote(&across.&pageby.&by)~= %then %do ;
  proc sort data=__core1 ;
    by &across &pageby &by ;
    run ;
%end ;

/*----------------------------------------------------------------------/
/ Get formats, labels, etc., from the input data set:                   /
/----------------------------------------------------------------------*/

proc contents data=__core1(keep=&by &varlst &across &cbvars)
              noprint out=__core2 ;
  run ;
data _null_ ;
  length label $200 ;
  set __core2(keep=format label formatd formatl length type name) ;
  length format2 $20 ;
  retain maxlen &maxvarl heads &heads
         %do i = 1 %to &nby ; maxby&i 0 %end ; ;
  if formatl then format2 = trim(format)
                            !!compress(formatl)!!'.' ;
  else if format~=' ' then format2 = trim(format)!!'.' ;
  if formatd then format2 = trim(format2)!!left(formatd) ;
  select(trim(name)) ;
    when ("&across") do ;
      if type=1 then call symput('cbtac','N') ;
      else call symput('cbtac','C') ;
      call symput('cblac',left(length)) ;
      call symput('fac',trim(format2)) ;
      %if %quote(&resolve)=Y %then %do ;
        label=resolve(label) ;
      %end ;
      call symput('lac',trim(label)) ;
      i = 1 ;
      piece = scan(label,i,"&split") ;
      do while(piece~=' ') ;
        i = i + 1 ;
        piece = scan(label,i,"&split") ;
      end ;
      call symput('spanlev',left(i)) ;
    end ;
    %do i = 1 %to &nvar ;
      when ("&&var&i") do ;
        %if %quote(&resolve)=Y %then %do ;
          label = resolve(label) ;
        %end ;
        if length(label)>maxlen then maxlen=length(label) ;
        call symput("fvar&i",trim(format2)) ;
        call symput("lvar&i",trim(label)) ;
        call symput("tvar&i",trim(left(type))) ;
        call symput('maxvarl',trim(left(maxlen))) ;
      end ;
    %end ;
    %do i = 1 %to &nby ;
      when ("&&by&i") do ;
        call symput("fby&i",trim(format2)) ;
        i = 1 ;
        %if %quote(&resolve)=Y %then %do ;
          label = resolve(label) ;
        %end ;
        piece = scan(label,i,"&split") ;
        do while (piece~=' ') ;
          if length(piece)>maxby&i then maxby&i = length(piece) ;
          i + 1 ;
          piece = scan(label,i,"&split") ;
        end ;
        call symput("maxby&i",left(put(maxby&i,2.))) ;
        i = i - 1 ;
        if i>heads and %index(&&by&i,NOPRINT)~=1 then do ;
          heads = i ;
          call symput('heads',left(heads)) ;
        end ;
      end ;
    %end ;
    otherwise ;
  end ;
  run ;

%if %quote(&across)~= %then %do ;
  %if &fac= %then
    %put ERROR: No format specified for the across variable (&across) ;
  %if %nrbquote(&lac)= %then
    %let lac=%substr(&across,1,1)%substr(%lowcase(&across),2) ;
%end ;

/*----------------------------------------------------------------------/
/ Get levels of the across variable:                                    /
/----------------------------------------------------------------------*/

%if %quote(&across&by)~= %then %do ;
  data _null_ ;
    do until (eof) ;
      set __core1(keep=&across &by) end=eof ;
      retain i 0 ;
      %if %quote(&across)~= %then %do ;
        by &across ;
        retain heads &heads ;
        if first.&across then do ;
          i + 1 ;
          length piece $&width whole $80 ;
          call symput('faclev'!!left(i),trim(left(put(&across,&fac)))) ;
          j = 1 ;
          whole = ' ' ;
          piece = left(scan(put(&across,&fac),j,"&split")) ;
          do until(piece=' ') ;
            j = j + 1 ;
            if length(piece)<(&width - 1) then do ;
              pad = int((&width-length(piece))/2) ;
              piece = repeat(' ',pad) !! trim(piece) ;
            end ;
            whole = trim(whole) !! " '" !! trim(piece) !! "'" ;
            piece = left(scan(put(&across,&fac),j,"&split")) ;
          end ;
          if whole=' ' then whole="' '" ;
          call symput('achead'!!left(i),trim(whole)) ;
          j = j + &spanlev - 1 ;
          if j>heads then do ;
            heads = j ;
            call symput('heads',left(heads)) ;
          end ;
        end ;
      %end ;
      %do i = 1 %to &nby ;
        retain maxby&i &&maxby&i ;
        x&i = length(put(&&by&i,&&fby&i)) ;
        if x&i>maxby&i then maxby&i = x&i ;
      %end ;
    end ;
    if i then call symput('naclev',left(i)) ;
    %do i = 1 %to &nby ;
      call symput("maxby&i",left(put(maxby&i,2.))) ;
    %end ;
    run ;
%end ;

/*----------------------------------------------------------------------/
/ Set the variable type for variables for which it was not              /
/ specified, issue a warning for invalid variable types:                /
/----------------------------------------------------------------------*/

%do i = 1 %to &nvar ;
  %if ~%index( C N B ,&&vopt&i) & %quote(&&vopt&i)~= %then %do ;
   %put WARNING: Invalid variable type (&&vopt&i) specified for &&var&i;
   %put WARNING: The default variable type is being used instead. ;
    %let vopt&i = ;
  %end ;
  %if &&vopt&i = %then %let vopt&i = %substr(NC,&&tvar&i,1) ;
  %else %if &&tvar&i=2 & &&vopt&i=N %then %do ;
   %put WARNING: Invalid variable type (&&vopt&i) specified for &&var&i;
   %put WARNING: The variable type "C" is being used instead. ;
    %let vopt&i=C ;
  %end ;
  %else %if &&tvar&i=1 & &&vopt&i=B %then %do ;
    %put ERROR: Invalid variable type (Numeric) for variable &&var&i ;
    %put ERROR: Errors may result. ;
  %end ;
%end ;

/*----------------------------------------------------------------------/
/ Make lists of just the Numeric and Categorical variables:             /
/----------------------------------------------------------------------*/

%local ncat nnum catlst numlst ;
%let ncat = 0 ;
%let nnum = 0 ;
%let catlst = ;
%let numlst = ;
%do i = 1 %to &nvar ;
  %if &&vopt&i=C %then %do ;
    %let ncat = %eval(&ncat + 1) ;
    %local cat&ncat fcat&ncat tcat&ncat ;
    %let cat&ncat = &&var&i ;
    %let fcat&ncat = &&fvar&i ;
    %let tcat&ncat = &&tvar&i ;
    %let catlst = &catlst &&var&i ;
  %end ;
  %else %if &&vopt&i=N %then %do ;
    %let nnum = %eval(&nnum + 1) ;
    %local num&nnum ;
    %let num&nnum = &&var&i ;
    %let numlst = &numlst &&var&i ;
  %end ;
%end ;

/*----------------------------------------------------------------------/
/ Read the levels of each of the categorical variables:                 /
/----------------------------------------------------------------------*/

%let maxcatl=10 ;
%do i = 1 %to &ncat ;
  %local nc&i.lev ;
  %let nc&i.lev = 0 ;
  proc sort data=__core1(keep=&&cat&i) out=__core2 ;
    by &&cat&i ;
    run ;
  data _null_ ;
    retain maxl &maxcatl ;
    %if &&tcat&i=1 %then %let cnt1=.;
    %else %let cnt1=' ';
    if left(put(&cnt1,&&fcat&i)) in(' ','.') then do ;
      call symput("misslb&i","&misslbl") ;
      if length("&misslbl")>maxl then maxl=length("&misslbl") ;
    end ;
    else do ;
      call symput("misslb&i",trim(put(&cnt1,&&fcat&i))) ;
      x = length(trim(put(&cnt1,&&fcat&i))) ;
      if x>maxl then maxl = x ;
    end ;
    call symput('maxcatl',left(maxl)) ;
    do until (eof) ;
      set __core2(
                   where=(%if &&tcat&i=1 %then %do ;
                            &&cat&i>.Z
                          %end ;
                          %else %do ;
                            &&cat&i~=' '
                          %end ;
                         )
                  ) end=eof ;
      by &&cat&i ;
      if first.&&cat&i then do ;
        i + 1 ;
        call symput("c&i.lev"!!left(i),
                   trim(put(&&cat&i,&&fcat&i)));
        x = length(trim(put(&&cat&i,&&fcat&i))) ;
        if x > maxl then maxl = x ;
      end ;
    end ;
    call symput("nc&i.lev",left(i)) ;
    call symput('maxcatl',left(maxl)) ;
    run ;
%end ;
%if &maxcatl>&maxstatl %then %let maxstatl=&maxcatl ;

/*----------------------------------------------------------------------/
/ Process check-box variables:                                          /
/----------------------------------------------------------------------*/

%if &ncb>0 %then %do ;
  %local cblby maxcbl ;
  %let cnt1 = 1 ;
  %let cnt2 = %scan(__sort__ &across &pageby &by,&cnt1,%str( )) ;
  %do %while (&cnt2~=) ;
    %let cblby = &cnt2 ;
    %let cnt1 = %eval(&cnt1 + 1) ;
    %let cnt2 = %scan(__sort__ &across &pageby &by,&cnt1,%str( )) ;
  %end ;

  %local cbindat __sort__;
  %if %quote(&across)~= & &total=Y %then %do ;
    %let cbindat = __corex ;
    data __corex ;
      set __core1(keep=__sort__ &across &pageby &by &cbvars) ;
      output ;
      %if &cbtac=C %then %do ;
        &across = repeat('FE'x,&cblac - 1) ;
      %end ;
      %else %do ;
        &across = 99999999 ;
      %end ;
      output ;
      run ;

    proc sort data=__corex ;
      by &across &pageby &by ;
      run ;
  %end ;
  %else %do ;
    %let cbindat = __core1 ;
  %end ;
  %if %quote(&across&pageby&by)= %then %let __sort__=__sort__;

  data __corex ;
    set &cbindat(keep=&__sort__ &across &pageby &by &cbvars) end=eof ;
    %if %quote(&across&pageby&by)~= %then %do ;
      by &across &pageby &by ;
    %end ;
    %else %do ;
      by __sort__ ;
    %end ;
    %do i = 1 %to &ncb ;
      array __cb_&i {0:&&ncb&i} &&cb&i ;
      array __n__&i {0:&&ncb&i} _temporary_ ;
      array __p__&i {1:&&ncb&i} $&pctstrl _temporary_ ;
      array __t__&i {1:&&ncb&i} $&width __t&i._1-__t&i._&&ncb&i ;
      %if %quote(&cblby)~= %then %do ;
        if first.&cblby then __n__&i.{0} = 0 ;
      %end ;
      if __cb_&i.{0}~=' ' then __n__&i.{0} + 1 ;
      drop j ;
      do j = 1 to &&ncb&i ;
        %if %quote(&cblby)~= %then %do ;
          if first.&cblby then do ;
            __n__&i.{j} = 0 ;
            __p__&i.{j} = ' ' ;
            __t__&i.{j} = ' ' ;
          end ;
        %end ;
        if __cb_&i.{0}~=' ' and __cb_&i.{j}~=' ' then __n__&i.{j} + 1 ;
          %if %quote(&cblby)~= %then %do ;
        if last.&cblby then do ;
          %end ;
          %else %do ;
        if eof then do ;
          %end ;
          if __n__&i.{0} then do ;
            if 0 < __n__&i.{j}/__n__&i.{0}*100 < (10**-&pctdec) then
              __p__&i.{j} = '(<' || compress(put(10**-&pctdec,&pctfmt)) || '%)' ;
            else if 100-(10**-&pctdec) < __n__&i.{j}/__n__&i.{0}*100 < 100 then
              __p__&i.{j} = '(>' || compress(put(100-(10**-&pctdec),&pctfmt)) || '%)' ;
            %if %quote(&pctzero)=N %then %do ;
              else if __n__&i.{j} = 0 then
                __p__&i.{j} = ' ' ;
            %end ;
            else
              __p__&i.{j} = '(' !!
                            compress(put((__n__&i.{j}/__n__&i.{0})*100,&pctfmt))
                            !! '%)' ;
          end ;
          else
          %if %quote(&pctzero)=Y %then %do;
            __p__&i.{j} = '(' !! compress(put(0,&pctfmt)) !! '%)' ;
          %end ;
          %else %do ;
            __p__&i.{j} = ' ' ;
          %end ;
          %if %quote(&across)~= & %index(%str(&hideacn&hideacp),Y) %then %do ;
            %if &cbtac=C %then %do ;
              if &across ~= repeat('FE'x,&cblac - 1) then
            %end ;
            %else %do ;
              if &across ~= 99999999 then
            %end ;
            %if &hideacn=Y %then %do ;
            __t__&i.{j} = repeat(' ',&maxdig - 2)!!'* '!!right(__p__&i.{j}) ;
            %end ;
            %else %do ;
            __t__&i.{j} = put(__n__&i.{j},&maxdig..)
                          !!repeat(' ',max(0,&pctstrl - length("&hidepct")))
                          !!"&hidepct" ;
            %end ;
            else
          %end ;
          __t__&i.{j} = put(__n__&i.{j},&maxdig..)!!' '!!right(__p__&i.{j}) ;
          %if &outof>0 %then %do ;
            __t__&i.{j} = put(__n__&i.{j},&maxdig..) || '/' ||
                          left(put(__n__&i.{0},&outof..)) ;
            __t__&i.{j} = put(__t__&i.{j},$%eval(&maxdig+&outof+1).)
                          || ' ' || right(__p__&i.{j}) ;
          %end ;
        end ;
      end ;
      length ____n&i $&maxdig ;
      %if %quote(&across)~= & %index(%str(&hideacn&hideacp),Y) %then %do ;
        %if &cbtac=C %then %do ;
          if &across ~= repeat('FE'x,&cblac - 1) then
        %end ;
        %else %do ;
          if &across ~= 99999999 then
        %end ;
        ____n&i = repeat(' ',&maxdig - 2)!!'*' ;
        else
      %end ;
      ____n&i = put(__n__&i.{0},&maxdig..) ;
    %end ;
    %if %quote(&cblby)~= %then %do ;
      if last.&cblby then output ;
    %end ;
    %else %do ;
      if eof then output ;
    %end ;
    if eof then do ;
      drop tmp maxlen ;
      length tmp $200 ;
      maxlen = 0 ;
      %do i = 1 %to &ncb ;
        do j = 1 to &&ncb&i ;
          call label(__cb_&i.{j},tmp) ;
          %if %quote(&resolve)=Y %then %do ;
            tmp = resolve(tmp) ;
          %end ;
          call symput("cb&i.l" !! left(j),trim(tmp)) ;
          if length(trim(tmp))>maxlen then maxlen = length(trim(tmp)) ;
        end ;
      %end ;
      call symput('maxcbl',left(maxlen)) ;
    end ;
    drop &cbvars ;
    run ;

  %if &maxcbl>&maxstatl %then %let maxstatl=&maxcbl ;

  proc transpose data=__corex out=__corex ;
    %if %quote(&across.&pageby.&by)~= %then %do ;
      by &across &pageby &by ;
    %end ;
    var %do i = 1 %to &ncb ;
          ____n&i %do j = 1 %to &&ncb&i ; __t&i._&j %end ;
        %end ; ;
    run ;

  data __corex ;
    set __corex(keep=&across &pageby &by _name_ col1
                rename=(col1=__cval__)) ;
    drop _name_ _cbvn_ ;
    length __stat__ $&maxstatl __name__ $8 _cbvn_ $3 ;
    retain __name__ _cbvn_ ;
    if index(_name_,'____N')=1 then do ;
      _statsrt = ._ ;
      __stat__ = "&catnlbl" ;
      _cbvn_ = substr(_name_,6) ;
      __name__ = symget('CB'!!trim(substr(_name_,6))!!'_0') ;
    end ;
    else do ;
      _statsrt = input(substr(_name_,index(substr(_name_,3),'_')+3),3.);
      __stat__ = symget('CB'!!trim(_cbvn_)!!'L'!!left(_statsrt)) ;
    end ;
    run ;

%end ;

/*----------------------------------------------------------------------/
/ Convert levels of the class variables to their numeric                /
/ counterparts (based on pre-formatted sort):                           /
/----------------------------------------------------------------------*/

data __core1 ;
  set __core1(rename=(
                     %do i = 1 %to &ncat ;
                       &&cat&i=__tmp&i
                     %end ;
                    )
            ) ;
  %do i = 1 %to &ncat ;
    select(trim(put(__tmp&i,&&fcat&i))) ;
      %do j = 1 %to &&nc&i.lev ;
        when("&&c&i.lev&j") &&cat&i = &j ;
      %end ;
      when('xxx Arbitrary Dummy Value xxx') ;
      otherwise &&cat&i = . ;
    end ;
    drop __tmp&i ;
  %end ;
  run ;

/*----------------------------------------------------------------------/
/ Stack the variables on top of one another and separate the            /
/ categorical variables from the numeric:                               /
/----------------------------------------------------------------------*/

data __core1(drop=__name__) __core2(drop=__name__)
     __corex2(keep=&pageby &by __var__ __name__) ;
  set
  %do i = 1 %to &nvar ;
    %if &&vopt&i=B %then %do ;
      __core1(keep=&across &pageby &by in=__n&i)
    %end ;
    %else %do ;
      __core1(
              keep=&across &pageby &by &&var&i
              rename=(&&var&i=__val__)
              in=__n&i
             )
    %end ;
  %end ;
  ;
  length __name__ $8 ;
  select ;
    %do i = 1 %to &nvar ;
      when(__n&i) do ;
        __var__ = &i ;
        __name__ = "&&var&i" ;
      end ;
    %end ;
    otherwise ;
  end ;
  if symget('vopt' !! left(__var__))='C' then output __core2 ;
  else if symget('vopt' !! left(__var__))='N' then output __core1 ;
  else output __corex2 ;
  run ;

/*----------------------------------------------------------------------/
/ Complete check-box variable processing:                               /
/----------------------------------------------------------------------*/

%if &ncb>0 %then %do ;
  proc sort data=__corex ;
    by &pageby &by __name__ _statsrt __stat__ &across ;
    run ;

  proc sort data=__corex2 nodupkey ;
    by &pageby &by __name__ ;
    run ;

  data __corex ;
    merge __corex(in=n1) __corex2 ;
    by &pageby &by __name__ ;
    if n1 ;
    %if %quote(&across)~= %then %do ;
      drop _a_c_lev __l_stat ;
      retain _a_c_lev __l_stat ;
      length ___id___ $8 __l_stat $&maxstatl ;
      if __stat__~=__l_stat then _a_c_lev = 0 ;
      _a_c_lev + 1 ;
      ___id___ = '__C' !! trim(left(_a_c_lev)) !! '__' ;
      %if &total=Y %then %do ;
        %if &cbtac=C %then %do ;
          if &across=repeat('FE'x,&cblac - 1) then ___id___ = '__CT__' ;
        %end ;
        %else %do ;
          if &across=99999999 then ___id___ = '__CT__' ;
        %end ;
      %end ;
      __l_stat = __stat__ ;
    %end ;
    run ;

  proc datasets library=work nolist ;
    delete __corex2 ;
    run ;

  %if %quote(&across)~= %then %do ;
    proc transpose data=__corex out=__corex(drop=_name_ __name__) ;
      by &pageby &by __name__ __var__ _statsrt __stat__ ;
      var __cval__ ;
      id  ___id___ ;
      run ;

  %end ;

%end ;

/*----------------------------------------------------------------------/
/ Process numeric variables:                                            /
/----------------------------------------------------------------------*/

%if &nnum>0 %then %do ;
  proc univariate data=__core1&missing noprint ;
    by __var__ &across &pageby &by ;
    var __val__ ;
    output out=__core3
           %do i = 1 %to &nstat ;
             &&stat&i=_&i.&&stat2&i
           %end ;
           ;
    run ;

  proc transpose data=__core3 %if &nozero=Y %then %do ; (where=(_1n>0)) %end ;
                  out=__core3(drop=_label_ rename=(col1=__val__))
                  name=__stat__ ;
    by __var__ &across &pageby &by ;
    run ;

  %if &total=Y & %quote(&across)~= %then %do ;
    %if %quote(&by&pageby)= %then %do ;
      proc univariate data=__core1 noprint ;
        by __var__ ;
        var __val__ ;
        output out=__core1
               %do i = 1 %to &nstat ;
                 &&stat&i=_&i.&&stat2&i
               %end ;
               ;
        run ;

      proc transpose data=__core1 %if &nozero=Y %then %do ; (where=(_1n>0)) %end ;
                      out=__core1(drop=_label_ rename=(col1=__val__))
                      name=__stat__ ;
        by __var__ ;
        run ;
    %end ;
    %else %do ;
      proc sort data=__core1 ;
        by __var__ &pageby &by ;
        run ;

      proc univariate data=__core1 noprint ;
        by __var__ &pageby &by ;
        var __val__ ;
        output out=__core1
               %do i = 1 %to &nstat ;
                 &&stat&i=_&i.&&stat2&i
               %end ;
               ;
        run ;

      proc transpose data=__core1 %if &nozero=Y %then %do ; (where=(_1n>0)) %end ;
                      out=__core1(drop=_label_ rename=(col1=__val__))
                      name=__stat__ ;
        by __var__ &pageby &by ;
        run ;
    %end ;
  %end ;

/*----------------------------------------------------------------------/
/ Get correct numeric formats:                                          /
/----------------------------------------------------------------------*/

  %do i = 1 %to &nvar ;
    %if &&vopt&i=N %then %do ;
      %local dec&i ;
      %if &&fvar&i= %then %let dec&i = %eval(&dec + &maxdig + 1).&dec ;
      %else %if %scan(&&fvar&i,2,%str(.))= %then %let dec&i = &maxdig.. ;
      %else %do ;
        %let cnt1=%scan(&&fvar&i,2,%str(.));
        %let dec&i = %eval(&cnt1 + &maxdig + 1).&cnt1 ;
      %end ;
      %do j = 1 %to &nstat ;
        %local dec&i._&j ;
        %if &&statadj&j = INT %then %let dec&i._&j = &maxdig.. ;
        %else %if %index(0123456789,%substr(&&fvar&i,1,1))=0 %then
          %let dec&i._&j = &&fvar&i ;
        %else %if &&statadj&j = 0 %then %let dec&i._&j = &&dec&i ;
        %else %do ;
          %let dec = %eval(%scan(&&dec&i,2,%str(.)) &&statadj&j) ;
          %if &dec<0 %then %let dec=0 ;
          %let dec&i._&j = %eval(&maxdig + (&dec>0) + &dec).&dec ;
        %end ;
      %end ;
    %end ;
  %end ;

  %if %quote(&across)~= %then %do ;
    proc sort data=__core3 ;
      by &across __var__ &pageby &by __stat__ ;
      run ;
    %if &total=Y %then %do ;
      proc sort data=__core1 ;
        by __var__ &pageby &by __stat__ ;
        run ;
    %end ;

    data __core1 ;
      merge %do i = 1 %to &naclev ;
              __core3(
                      where=(
                             left(trim("&&faclev&i")) =
                                   trim(left(put(&across,&fac)))
                             %if "&&faclev&i"~=" " %then %do ;
                               and put(&across,&fac)~=' '
                             %end ;
                            )
                      rename=(__val__=__AC&i.__ __stat__=__tmp___)
                     )
            %end ;
            %if &total=Y %then %do ;
              __core1(rename=(__val__=__ACT__ __stat__=__tmp___))
            %end ;
      ;
      by __var__ &pageby &by __tmp___ ;
      length __stat__ $&maxstatl ;
      __stat__ = __tmp___ ;
      _statsrt = input(substr(__stat__,2,1),1.) ;
      %do i = 1 %to &naclev ;
        length __c&i.__ $&width ;
        if __ac&i.__<=.Z then __c&i.__=' ' ;
        else if substr(__stat__,3) in('N','NMISS','NOBS') then
          %if %length(&across)=0 or %index(%str(&hideacn&hideacp),Y)=0 %then %do ;
            __c&i.__=put(__ac&i.__,&maxdig..) ;
          %end ;
          %else %do ;
            __c&i.__=repeat(' ',&maxdig - 2) !! '*' ;
          %end ;
        else select ;
          %do j = 1 %to &nvar ;
            %do k = 1 %to &nstat ;
              %if &&vopt&j=N %then %do ;
                %if %index(0123456789,%substr(&&dec&j._&k,1,1)) %then %do ;
                  when(__var__=&j & _statsrt=&k) __c&i.__=put(__ac&i.__,&&dec&j._&k) ;
                %end ;
                %else %do ;
                  when(__var__=&j & _statsrt=&k) do ;
                    __c&i.__ = left(put(__ac&i.__,&&dec&j._&k)) ;
                    if length(trim(__c&i.__))+1>=&maxdig then
                      __c&i.__ = repeat(' ',floor((&width-length(trim(__c&i.__)))/2)-1)
                                 || __c&i.__ ;
                  end ;
                %end ;
              %end ;
            %end ;
          %end ;
          otherwise ;
        end ;
        drop __ac&i.__ ;
      %end ;
      %if &total=Y %then %do ;
        length __ct__ $&width ;
        if __act__<=.Z then __ct__=' ' ;
        else if substr(__stat__,3) in('N','NMISS','NOBS') then
          __ct__ = put(__act__,&maxdig..) ;
        else select ;
          %do j = 1 %to &nvar ;
            %do k = 1 %to &nstat ;
              %if &&vopt&j=N %then %do ;
                %if %index(0123456789,%substr(&&dec&j._&k,1,1)) %then %do ;
                  when(__var__=&j & _statsrt=&k) __ct__=put(__act__,&&dec&j._&k) ;
                %end ;
                %else %do ;
                  when(__var__=&j & _statsrt=&k) do ;
                    __ct__ = left(put(__act__,&&dec&j._&k)) ;
                    if length(trim(__ct__))+1>=&maxdig then
                      __ct__ = repeat(' ',floor((&width-length(trim(__ct__)))/2)-1)
                               || __ct__ ;
                  end ;
                %end ;
              %end ;
            %end ;
          %end ;
          otherwise ;
        end ;
        drop __act__ ;
      %end ;
      __stat__ = substr(__stat__,2) ;
      substr(__stat__,1,1)='_' ;
      drop &across __tmp___;
      run ;
  %end ;
  %else %do ;
    data __core1 ;
      set __core3(rename=(__stat__=__tmp___)) ;
      length __cval__ $&width __stat__ $&maxstatl ;
      drop __tmp___ ;
      __stat__ = __tmp___ ;
      _statsrt = input(substr(__stat__,2,1),1.) ;
      if __val__<=.Z then __cval__=' ' ;
      else if substr(__stat__,3) in('N','NMISS','NOBS') then
        __cval__ = put(__val__,&maxdig..) ;
      else select ;
        %do j = 1 %to &nvar ;
          %if &&vopt&j=N %then %do ;
            %do k = 1 %to &nstat ;
              when(__var__=&j & _statsrt=&k) __cval__=put(__val__,&&dec&j._&k) ;
            %end ;
          %end ;
        %end ;
        otherwise ;
      end ;
      __stat__ = substr(__stat__,2) ;
      substr(__stat__,1,1)='_' ;
      drop __val__ ;
      run ;
  %end ;
  proc datasets library=work nolist ;
    delete __core3 ;
    run ;
%end ;

/*----------------------------------------------------------------------/
/ Process categorical variables:                                        /
/----------------------------------------------------------------------*/

%if &ncat>0 %then  %do ;
  proc sort data=__core2&missing ;
    by __var__ &pageby &by ;
    run ;

  proc summary data=__core2 missing ;
    by __var__ &pageby &by ;
    class &across __val__ ;
    output out=__core2 ;
    run ;

  %local lstsrt1 lstsrt2 ;

  %if %quote(&across)~= %then %let lstsrt1=&across ;
  %else %if %quote(&lstby)~= %then %let lstsrt1=&lstby ;
  %else %if %quote(&lstpby)~= %then %let lstsrt1=&lstpby ;
  %else %let lstsrt1=__var__ ;

  %if %quote(&lstby)~= %then %let lstsrt2=&lstby ;
  %else %if %quote(&lstpby)~= %then %let lstsrt2=&lstpby ;
  %else %let lstsrt2=__var__ ;

  %if &total=Y & %quote(&across)~= %then %do ;
    data __core3 ;
      merge __core2(where=(_type_=1) rename=(__val__=_statsrt))
            __core2(
                    keep=__var__ &pageby &by _freq_ _type_
                    rename=(_freq_=_n)
                    where=(_type_=0)
                   ) ;
      by __var__ &pageby &by ;
      drop _type_ _freq_ _n &across i pct ;
      length __ct__ $&width __stat__ $&maxstatl pct $&pctstrl ;
      if 0 < _freq_/_n*100 < 10**-&pctdec then
        pct = '(<' || compress(put(10**-&pctdec,&pctfmt)) || '%)' ;
      else if 100-(10**-&pctdec)< _freq_/_n*100 < 100 then
        pct = '(>' || compress(put(100-(10**-&pctdec),&pctfmt)) || '%)' ;
      %if %quote(&pctzero)=N %then %do ;
        else if _freq_=0 then pct = ' ' ;
      %end ;
      else
        pct = '('!!compress(put((_freq_/_n)*100,&pctfmt))!!'%)' ;
      __ct__ = put(_freq_,&maxdig..)!!' '!!right(pct) ;
      %if &outof>0 %then %do ;
        __ct__ = put(_freq_,&maxdig..) || '/' || left(put(_n,&outof..)) ;
        __ct__ = put(__ct__,$%eval(&maxdig+&outof+1).) || ' ' || right(pct) ;
      %end ;
      if first.__var__ then i+1 ;
      select(i) ;
        %do i = 1 %to &ncat ;
          when(&i) do ;
            select(_statsrt) ;
              %do j = 1 %to &&nc&i.lev ;
                when(&j) __stat__ = "&&c&i.lev&j" ;
              %end ;
              when(%eval(&&nc&i.lev + 1)) ;
              otherwise do ;
                __stat__ = "&&misslb&i";
                %if %quote(&missord)=L %then %do ;
                  _statsrt=99999999 ;
                %end ;
              end ;
            end ;
          end ;
        %end ;
        otherwise ;
      end ;
      if first.&lstsrt2 then do ;
        output ;
        __ct__=put(_n,&maxdig..) ;
        _statsrt=._ ;
        __stat__="&catnlbl" ;
        output ;
      end ;
      else output ;
      run ;
  %end ;

  %if %quote(&across)~= %then %let cnt1 = 3 ;
  %else %let cnt1 = 1 ;
  %let cnt2 = %eval(&cnt1 - 1) ;

  data __core2 ;
    merge __core2(where=(_type_=&cnt1) rename=(__val__=_statsrt))
          __core2(
                  keep=__var__ &pageby &by &across _type_ _freq_
                  rename=(_freq_=_n)
                  where=(_type_=&cnt2)
                 ) ;
    by __var__ &pageby &by &across ;
    drop _type_ _freq_ _n i pct ;
    length __cval__ $&width __stat__ $&maxstatl pct $&pctstrl ;
    if 0 < _freq_/_n*100 < 10**-&pctdec then
      pct = '(<' || compress(put(10**-&pctdec,&pctfmt)) || '%)' ;
    else if 100-(10**-&pctdec)< _freq_/_n*100 < 100 then
      pct = '(>' || compress(put(100-(10**-&pctdec),&pctfmt)) || '%)' ;
    %if %quote(&pctzero)=N %then %do ;
      else if _freq_=0 then pct = ' ' ;
    %end ;
    else
      pct = '('!!compress(put((_freq_/_n)*100,&pctfmt))!!'%)' ;
    %if %length(&across)>0 and &hideacn=Y %then %do ;
      __cval__ = repeat(' ',&maxdig - 2)!!'* '!!right(pct) ;
    %end ;
    %else %if %length(&across)>0 and &hideacp=Y %then %do ;
      __cval__ = put(_freq_,&maxdig..)
                 !!repeat(' ',max(0,&pctstrl - length("&hidepct")))
                 !!"&hidepct" ;
    %end ;
    %else %do ;
      __cval__ = put(_freq_,&maxdig..)!!' '!!right(pct) ;
      %if &outof>0 %then %do ;
        __cval__ = put(_freq_,&maxdig..) || '/' || left(put(_n,&outof..)) ;
        __cval__ = put(__cval__,$%eval(&maxdig+&outof+1).) || ' ' || right(pct) ;
      %end ;
    %end ;
    if first.__var__ then i+1 ;
    select(i) ;
      %do i = 1 %to &ncat ;
        when(&i) do ;
          select(_statsrt) ;
            %do j = 1 %to &&nc&i.lev ;
              when(&j) __stat__ = "&&c&i.lev&j" ;
            %end ;
            when(%eval(&&nc&i.lev + 1)) ;
            otherwise do ;
              __stat__ = "&&misslb&i";
              %if %quote(&missord)=L %then %do ;
                _statsrt=99999999 ;
              %end ;
            end ;
          end ;
        end ;
      %end ;
      otherwise ;
    end ;
    if first.&lstsrt1 then do ;
      output ;
      %if %length(&across)=0 or %index(%str(&hideacn&hideacp),Y)=0 %then %do ;
        __cval__=put(_n,&maxdig..) ;
      %end ;
      %else %do ;
        __cval__=repeat(' ',&maxdig - 2)!!'*' ;
      %end ;
      _statsrt=._ ;
      __stat__="&catnlbl" ;
      output ;
    end ;
    else output ;
    run ;

  %if %quote(&across)~= %then %do ;
    proc sort data=__core2 ;
      by &across __var__ &pageby &by _statsrt ;
      run ;
    %if &total=Y %then %do ;
      proc sort data=__core3 ;
        by __var__ &pageby &by _statsrt ;
        run ;
    %end ;

    data __core2 ;
      merge %do i = 1 %to &naclev ;
              __core2(
                      where=(
                             left(trim("&&faclev&i")) =
                                   trim(left(put(&across,&fac)))
                             %if "&&faclev&i"~=" " %then %do ;
                               and put(&across,&fac)~=' '
                             %end ;
                            )
                      rename=(__cval__=__c&i.__)
                     )
            %end ;
            %if &total=Y %then %do ;
              __core3
            %end ;
            ;
      by __var__ &pageby &by _statsrt ;
      %if &fillzero=Y %then %do ;
        retain fill1-fill&naclev ;
        array cac {&naclev} %do i = 1 %to &naclev ; __c&i.__ %end ; ;
        array fill {&naclev} fill1-fill&naclev ;
        if first.&lstsrt2 then do i = 1 to &naclev ;
          if cac{i}=' ' then fill{i}=0 ;
          else fill{i}=1 ;
        end ;
        else do i = 1 to &naclev ;
          if cac{i}=' ' and fill{i} then do ;
            drop _t_m_p_ ;
            length _t_m_p_ $&pctstrl ;
            %if %length(&across)>0 and &hideacn=Y %then %do ;
              %if %quote(&pctzero)=Y %then %do ;
                _t_m_p_ = '(' !! compress(put(0,&pctfmt)) !! '%)' ;
              %end ;
              %else %do ;
                _t_m_p_ = ' ' ;
              %end ;
              cac{i}=repeat(' ',&maxdig - 2)!!'* ' !! right(_t_m_p_) ;
            %end ;
            %else %if %length(&across)>0 and &hideacp=Y %then %do ;
              %if %quote(&pctzero)=Y %then %do ;
                _t_m_p_ = "&hidepct" ;
              %end ;
              %else %do ;
                _t_m_p_ = ' ' ;
              %end ;
              cac{i}=put(0,&maxdig..) !! ' ' !! right(_t_m_p_)  ;
            %end ;
            %else %do ;
              %if %quote(&pctzero)=Y %then %do ;
                _t_m_p_ = '(' !! compress(put(0,&pctfmt)) !! '%)' ;
              %end ;
              %else %do ;
                _t_m_p_ = ' ' ;
              %end ;
              cac{i}=put(0,&maxdig..) !! ' ' !! right(_t_m_p_)  ;
            %end ;
          end ;
        end ;
        drop fill1-fill&naclev ;
      %end ;
      drop &across ;
      run ;
    %if &total=Y %then %do ;
      proc datasets library=work nolist ;
        delete __core3 ;
        run ;
    %end ;
  %end ;
%end ;

/*----------------------------------------------------------------------/
/ Get formats ready for the report:                                     /
/----------------------------------------------------------------------*/

%global __sumfmt ;
%if &__sumfmt= %then %let __sumfmt = 1 ;

proc format ;
  %if &__sumfmt=1 and %quote(&statfmt)=_DEFAULT_ %then %do ;
    %let __sumfmt = 0 ;
    value $unistat '_N'='n'
                   '_NMISS'='# Missing'
                   '_NOBS'='# Obs'
                   '_MEAN'='Mean'
                   "_STDMEA"='SE'
                   '_SUM'='Sum'
                   '_STD'='SD'
                   '_VAR'='Variance'
                   '_CV'='Coef.Var.'
                   '_USS'='Uncor.SS'
                   '_CSS'='Corr.SS'
                   '_SKEWNE'='Skewness'
                   '_KURTOS'='Kurtosis'
                   '_SUMWGT'='Sum Wghts'
                   '_MAX'='Max.'
                   '_MIN'='Min.'
                   '_RANGE'='Range'
                   '_Q3'='Upper Qrtl'
                   '_Q1'='Lower Qrtl'
                   '_MEDIAN'='Median'
                   '_QRANGE'='IQR'
                   '_P1'='1st Pctl'
                   '_P5'='5th Pctl'
                   '_P10'='10th Pctl'
                   '_P90'='90th Pctl'
                   '_P95'='95th Pctl'
                   '_P99'='99th Pctl'
                   '_MODE'='Mode'
                   '_T'='T (Mean=0)'
                   '_PROBT'='Prob>T'
                   '_MSIGN'='M(Sign St)'
                   '_PROBM'='Prob>M'
                   '_SIGNRA'='S(SgnRnk)'
                   '_PROBS'='Prob>S'
                   '_NORMAL'='Norm Stat'
                   '_PROBN'='P (Normal)'
                   ;
  %end ;
  %if %quote(&statfmt)=_DEFAULT_ %then %let statfmt = $UNISTAT. ;

  value int&__sumtab._ %do i = 1 %to &nvar ;
                           &i="&&lvar&i"
                         %end ;
               ;
  run ;

/*----------------------------------------------------------------------/
/ Put the categorical and numeric data together:                        /
/----------------------------------------------------------------------*/

data __core1 ;
  set  %if &nnum %then %do ; __core1(in=num rename=(__stat__=__tmp___)) %end ;
       %if &ncat %then %do ; __core2(in=cat rename=(__stat__=__tmp___)) %end ;
       %if &ncb  %then %do ; __corex(in=cb  rename=(__stat__=__tmp___)) %end ; ;
  drop __tmp___ ;
  length __stat__ $&maxstatl ;
  __stat__ = __tmp___ ;
  %if &ncat>0 & &printn=N %then %do ;
    if cat and _statsrt=._ then delete ;
  %end ;
  %if  &ncb>0 & &printn=N %then %do ;
    if cb  and _statsrt=._ then delete ;
  %end ;
  %if &nnum>0 %then %do ;
    if num then __stat__ = put(__stat__,&statfmt) ;
  %end ;
  %* See if there is a null label for any pageby variable ;
  %if &npby>0 %then %do ;
    if _n_=1 then do ;
      drop __tmplab ;
      length __tmplab $200 ;
      %do i = 1 %to &npby ;
        call label(&&pby&i,__tmplab) ;
        %if %quote(&resolve)=Y %then %do ;
          __tmplab = resolve(__tmplab) ;
        %end ;
        if trim(left(__tmplab))="&split" then call symput("lpby&i",'0') ;
        else                                  call symput("lpby&i",'1') ;
      %end ;
    end ;
  %end ;
  %if "&across"~="" %then %do ;
    %do i = 1 %to &naclev ;
      attrib __c&i.__ label="&&faclev&i" ;
    %end ;
    %if "&total"="Y" %then %do ;
      attrib __ct__ label="&totlbl" ;
    %end ;
  %end ;
  length dummy $1 variable $132 ;
  dummy = ' ' ;
  variable = put(__var__,int&__sumtab._.) ;
  run = &__sumtab ;
  run ;
%if &ncat>0 %then %do ;
  proc datasets library=work nolist ;
    delete __core2 ;
    run ;
%end ;
%if  &ncb>0 %then %do ;
  proc datasets library=work nolist ;
    delete __corex ;
    run ;
%end ;

%if %quote(&append)~= %then %do ;
  %local oldstatl dsetord ;
  data _null_ ;
    set &append end=eof ;
    retain maxstatl &maxstatl maxvarl &maxvarl ;
    if length(trim(__stat__))>maxstatl then maxstatl = length(trim(__stat__)) ;
    if length(trim(variable))>maxvarl  then maxvarl  = length(trim(variable)) ;
    if eof then do ;
      call symput('oldstatl',trim(left(put(maxstatl,8.)))) ;
      call symput('maxvarl' ,trim(left(put(maxvarl, 8.)))) ;
    end ;
    run ;

  %if &oldstatl>&maxstatl %then %do ;
    %let maxstatl=&oldstatl ;
    %let dsetord=&append __core1 ;
  %end ;
  %else %let dsetord=__core1 &append ;

  data &out ;
    set &dsetord ;
    array tmp {1} _pageno ;
    tmp{1} = . ;
    drop _pageno ;
    run ;

  proc sort data=&out ;
    by &pageby run __var__ &by _statsrt ;
    run ;
%end ;
%else %do ;
proc sort data=__core1 out=&out ;
  by &pageby __var__ &by _statsrt ;
  run ;
%end ;

%bwgettf(t=currt,f=currf,ps=currps,ls=currls,dump=N) ;

%if &print=Y %then %do ;

/*----------------------------------------------------------------------/
/ Calculate the total space (width) being used:                         /
/----------------------------------------------------------------------*/

  %local ncol coltotw reptotw avsp stcol ;
  %let ncol=1 ;
  %let coltotw=&maxstatl ;
  %if &varstyle~=R & %qupcase(&varlbl)~=_NONE_ %then %do ;
    %let ncol = %eval(&ncol + 1) ;
    %let coltotw = %eval(&coltotw + &maxvarl) ;
  %end ;
  %do i = 1 %to &nby ;
    %if %index(&&by&i,NOPRINT)~=1 %then %do ;
      %let ncol = %eval(&ncol + 1) ;
      %let coltotw = %eval(&coltotw + &&maxby&i) ;
    %end ;
  %end ;
  %if %quote(&across)~= %then %do ;
    %do i = 1 %to &naclev ;
      %let ncol = %eval(&ncol + 1) ;
      %let coltotw = %eval(&coltotw + &width) ;
    %end ;
    %if &total=Y %then %do ;
      %let ncol = %eval(&ncol + 1) ;
      %let coltotw = %eval(&coltotw + &width) ;
    %end ;
  %end ;
  %else %do ;
    %let ncol = %eval(&ncol + 1) ;
    %let coltotw = %eval(&coltotw + &width) ;
  %end ;

/*----------------------------------------------------------------------/
/ Calculate an appropriate spacing to use, based on the total           /
/ width being used:                                                     /
/----------------------------------------------------------------------*/

  %let avsp = %eval(%eval(&currls - &coltotw)/&ncol) ;
  %if %quote(&spacing)= %then %do ;
    %if &avsp<=1 %then %let spacing=1 ;
    %else %if &avsp>4 %then %let spacing=4 ;
    %else %let spacing=&avsp ;
  %end ;

/*----------------------------------------------------------------------/
/ Make sure report is not too wide, and calculate the first             /
/ column of the report:                                                 /
/----------------------------------------------------------------------*/

  %local dummy ;
  %let reptotw = %eval(&coltotw + (&spacing*(&ncol-1))) ;

/*----------------------------------------------------------------------/
/ JHK004 adding %qupcase() to &varlbl                                   /
/----------------------------------------------------------------------*/

  %if &varstyle=R & %qupcase(&varlbl)~=_NONE_ %then %do ;
    %let dummy=dummy ;
    %let reptotw=%eval(&reptotw + 2) ;
  %end ;
  %if &reptotw>&currls %then %do ;
    %put WARNING: Report width exceeds the current LINESIZE;
    %put SUGGESTION: Try using VARSTYLE=ROW or reducing WIDTH or MAXDIG;
    %let stcol = 1 ;
  %end ;
  %else %let stcol=%eval(%eval((&currls - &reptotw)/2) + 1) ;
%end ;

%if &print=Y & %quote(&pageby)~= %then %do ;

/*----------------------------------------------------------------------/
/ Find out what titles can be used for by-line:                         /
/----------------------------------------------------------------------*/

  %local usetitle ;
  %if &currt0<8 %then %let usetitle=%eval(&currt0 + 2) ;
  %else %let usetitle=10 ;

  /* a fix for the nobyline option screwing up pagesize */
  %let currps = %eval(&currps - 2);

/*----------------------------------------------------------------------/
/ Set the by-line option off and store original setting:                /
/----------------------------------------------------------------------*/

   %local byline;
   %let byline = %sysfunc(getoption(BYLINE));
   options nobyline ;
%end ;

/*----------------------------------------------------------------------/
/ Figure out what blocks can fit on a page:                             /
/----------------------------------------------------------------------*/

%local _pgblk bkvar ;
%let _pgblk= ;
%if %quote(&lstby)= %then %let lstby = __var__ ;
%if &nby>0 & &skipby=Y %then %let bkvar=&lstby ;
%else %let bkvar=__var__ ;

%if &pgblock=Y %then %do ;
  %let _pgblk=_pageno ;

/*----------------------------------------------------------------------/
/ Count the number of titles and footnotes used and the pagesize:       /
/----------------------------------------------------------------------*/

  %local titles foots ;
  %let titles = %eval(&currt0 + 2) ;
  %if &currf0 %then %let foots = %eval(&currf0 + 1) ;
  %if &print=Y and &npby>0 %then %let titles = &usetitle ;

/*----------------------------------------------------------------------/
/ Find out the current skip:                                            /
/----------------------------------------------------------------------*/

   %local currsk;
   %let currsk = %sysfunc(getoption(SKIP));

  %local totlines ;
  %let totlines = %eval(&currsk + &titles + &foots + &heads + 2) ;
  %let totlines = %eval(&currps - &totlines) ;
  %let cnt1 = %eval(&totlines + 1) ;

  data __core1 ;
    set &out ;
    by &pageby run __var__ &by ;
    retain _blksize ;
    if first.&lstby then _blksize=0 ;
    _blksize = _blksize + 1 ;
    %if &varstyle=R %then %do ;
      if first.__var__ then _blksize = _blksize + 2 ;
    %end ;
    if last.&lstby ;
    keep &pageby run __var__  &by _blksize ;
    run ;

  data &out ;
    merge &out __core1 ;
    by &pageby run __var__ &by ;
    retain _ll &cnt1 _pageno 1 ;
    _ll = _ll - 1 ;
    %if &npby>0 %then %do ;
      if first.&lstpby then do ;
        _ll = &totlines ;
        _pageno = 1 ;
      end ;
    %end ;
    if first.&lstby then do ;
      if first.&bkvar then _ll = _ll - 1 ;
      %if &varstyle=R & %qupcase(&varlbl)~=_NONE_ %then %do ;
        %if %qupcase(&varuline)=_NONE_ %then %do ;
          if first.__var__ then _ll = _ll - 1 ;
        %end ;
        %else %do ;
          if first.__var__ then _ll = _ll - 2 ;
        %end ;
      %end ;
      if _ll<_blksize then do ;
        _pageno = _pageno + 1 ;
        _ll = &totlines - 1 ;
        %if &varstyle=R %then %do ;
          if first.__var__ then _ll = _ll - 2 ;
        %end ;
      end ;
    end ;
    drop _ll _blksize ;
    run ;
%end ;

proc datasets library=work nolist ;
  delete __core1 ;
  run ;

/*----------------------------------------------------------------------/
/ Print out a report:                                                   /
/----------------------------------------------------------------------*/

%if &print=Y %then %do ;

  proc report data=&out nowd headline headskip missing split="&split"
              spacing=&spacing ;
    column &_pgblk &dummy run __var__ variable &by __stat__
           %if %quote(&across)~= %then %do ;
             ("&lac" "&uline.&uline"
             %do i = 1 %to &naclev ;
               __c&i.__
             %end ;
             )
             %if &total=Y %then %do ;
               __ct__
             %end ;
           %end ;
           %else %do ;
             __cval__
           %end ;
           ;
    %if %quote(&pageby)~= %then %do ;
      by &pageby ;
    %end ;
    break after &bkvar / skip ;
    %if &pgblock=Y %then %do ;
      break after _pageno / page ;
      define _pageno / order noprint spacing=0 ;
    %end ;
    %if &varstyle~=R %then %do ;
      define run     / order order=internal noprint spacing=0 ;
      define __var__ / order order=internal noprint spacing=0 ;

/*----------------------------------------------------------------------/
/ JHK004 adding %qupcase() to &varlbl                                   /
/----------------------------------------------------------------------*/

      %if %qupcase(&varlbl)~=_NONE_ %then %do ;
        define variable / order f=$&maxvarl.. left "&varlbl" ;
      %end ;
      %else %do ;
        define variable/ order order=internal noprint spacing=0 ;
      %end ;
    %end ;
    %else %do ;

/*----------------------------------------------------------------------/
/ JHK004 adding %qupcase() to &varlbl                                   /
/----------------------------------------------------------------------*/

      %if %qupcase(&varlbl)~=_NONE_ %then %do ;
        define dummy / order width=2 spacing=0 "&split" ;
        define run     / order order=internal noprint spacing=0 ;
        define __var__ / order order=internal noprint spacing=0 ;
        define variable/ order order=internal noprint spacing=0 ;
        compute before variable ;
          line @&stcol variable $&maxvarl.. ;
          %if %qupcase(&varuline)~=_NONE_ %then %do ;
            length _uline_ $&reptotw ;
            _uline_ = repeat("&varuline",length(trim(variable))-1);
            line @&stcol _uline_ $&reptotw.. ;
          %end ;
        endcomp ;
      %end ;
      %else %do ;
        define run     / order order=internal noprint spacing=0 ;
        define __var__ / order order=internal noprint spacing=0 ;
        define variable/ order order=internal noprint spacing=0 ;
      %end ;
    %end ;
    %do i = 1 %to &nby ;
      %if %index(&&by&i,NOPRINT)=1 %then %do ;
        define &&by&i / order order=internal noprint spacing=0 "&split" ;
      %end ;
      %else %do ;
        %if &i=1 & &varstyle=R %then %do ;
          define &&by&i / order order=internal width=&&maxby&i spacing=0 ;
        %end ;
        %else %do ;
          define &&by&i / order order=internal width=&&maxby&i ;
        %end ;
      %end ;
    %end ;
    %if &nby=0 & &varstyle=R %then %do ;
      define __stat__ / display width=&maxstatl "&statlbl" spacing=0 ;
    %end ;
    %else %do ;
      define __stat__ / display width=&maxstatl "&statlbl" ;
    %end ;
    %if %quote(&across)~= %then %do ;
      %do i = 1 %to &naclev ;
        define __c&i.__ / display f=$&width.. &&achead&i ;
      %end ;
      %if &total=Y %then %do ;
        define __ct__ / display f=$&width.. &totlbl ;
      %end ;
    %end ;
    %else %do ;
      %let cnt2 = %length(%bquote(&vallbl)) ;
      %if &cnt2<&width %then %let cnt2 = &width ;
      define __cval__ / display f=$&width.. width=&cnt2 "&vallbl" ;
    %end ;
    %if %quote(&pageby)~= %then %do ;
      title&usetitle %do i = 1 %to &npby ;
                       %if &&lpby&i=1 %then %do ;
                         "  #BYVAR&i = #BYVAL&i "
                       %end ;
                       %else %do ;
                         " #BYVAL&i "
                       %end ;
                     %end ;
                     ;
    %end ;
    run ;

/*----------------------------------------------------------------------/
/ Restore original options and titles:                                  /
/----------------------------------------------------------------------*/

  %if %quote(&pageby)~= %then %do ;
    options &byline ;
    title&usetitle "&&currt&usetitle" ;
  %end ;
%end ;

%leave:
%mend SUMTAB ;
----------------------*/

  %local ncol coltotw reptotw avsp stcol ;
  %let ncol=1 ;
  %let coltotw=&maxstatl ;
  %if &varstyle~=R & %qupcase(&varlbl)~=_NONE_ %then %do ;
    %let ncol = %eval(&ncol + 1) ;
    /users/d33/jf97633/sas_y2k/macros/template.sas                                                      0100664 0045717 0002024 00000001516 06633767447 0022070 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ Program Name:
/
/ Program Version:
/
/ Program Purpose:
/
/ SAS Version:
/
/ Created By:
/ Date:
/
/ Input Parameters:
/
/ Output Created:
/
/ Macros Called:
/
/ Example Call:
/
/===========================================================================================
/ Change Log:
/
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX001
/    DESCRIPTION:
/    ---------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    ---------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    ---------------------------------------------------------------------------
/===========================================================================================*/
     XXX001
/    DESCRIPTION:
/    ---------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPT/users/d33/jf97633/sas_y2k/macros/testinit.sas                                                      0100664 0045717 0002024 00000007601 06662316074 0022105 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ PROGRAM: TESTINIT.SAS 
/
/ PURPOSE: To test and validate TITLES.SAS, SETTITLE.SAS and TOC.SAS.
/
/ AUTHOR:  Jonathan Fry (based on program by Carl P. Arneson)
/ DATE:    16Feb1999
/
/ Macros Called: VSTOP.SAS
/                FN.SAS
/                SETTITLES.SAS
/
/ ===========================================================================
/ Change Log:
/
/    Modified By:
/    Date:
/    Reason:
/    ----------------------------------------------------------------   
/ ===========================================================================*/

   %macro testinit(__POP__,       
                   _ls     = 132,    
                   _ps     = 60,    
                   _skip   = 5,     
                   vstop   = N,      
                   final   = );     

   %local i j ml dd mm yy _st ind ind2 date hexlist ;
   %global prot;

/*----------------------------------------------------------------------------/
/   Get protocol number from DIRECTORY NAME                                   /
/----------------------------------------------------------------------------*/

   data _null_;
      protocol=reverse(scan(reverse("&sysparm"),2,'/'));
      call symput('prot',compress(protocol));
   run;

/*----------------------------------------------------------------------------/
/   Hexlist is used to set up allowable hex codes (superscripts) that can be  /
/   used by any program. The hexlist is transformed into appropriate macro    /
/   variables later in the code                                               /
/----------------------------------------------------------------------------*/

   %let hexlist=xa1 xa2 xa3 xa4 xa5 xa6 xa7 xa8 xa9 xa0 xf3 xf2 xc4 xf8;

   %global &hexlist pad head1 head2 ;

/*----------------------------------------------------------------------------/
/   Pad is the standard space-filler, used to left-justify footnotes          /
/----------------------------------------------------------------------------*/

   %let pad='                                                                  ';

   %if %upcase(&vstop)~=N %then %vstop(6.12);
   
/*----------------------------------------------------------------------------/
/   Define LIBREFS                                                            /
/----------------------------------------------------------------------------*/

   libname in  "/users/d33/jf97633/sas/valid/data/titles" ;  
   libname out "/users/d33/jf97633/sas/valid" ;
   libname ids "/users/d33/jf97633/sas/valid" ;

/*----------------------------------------------------------------------------/
/   Find the date of the current data version                                 /
/----------------------------------------------------------------------------*/

   %let date = Unknown ;

   data _null_ ;
      i = 1 ;
      w = scan("&hexlist",i,' ') ;
      do while(w~=' ') ;
         hexc = input(substr(w,2,2),$hex2.) ;
         call symput(w,hexc) ;
         i = i + 1 ;
         w = scan("&hexlist",i,' ') ;
      end;
   run;

/*----------------------------------------------------------------------------/
/   Define headers as macro variables (used by titles system)                 /
/----------------------------------------------------------------------------*/

   %let __hc__=2;
   %let head1 = Naratriptan Tablets - Protocol S2W%upcase(&prot.);
   %if %length(&__POP__.) gt 1 %then %do;
      %let head2 = &__POP__. Population;
      %let __hc__=3;
   %end;
   %else;
   %let head&__hc__. = (Data as of: &date.) ;

/*----------------------------------------------------------------------------/
/   Define default SAS options                                                /
/----------------------------------------------------------------------------*/

   options nodate nonumber ls=&_ls skip=&_skip pagesize=&_ps missing=' ' 
      formchar='B3C4DAC2BFC3C5B4C0C1D92B3D7C2D2F5C3C3E2A'X;

   %settitle(fn=%fn,number=tabnum,dset=in.tmacros);

%mend testinit ;
                                                                                                                               /users/d33/jf97633/sas_y2k/macros/title.sas                                                         0100664 0045717 0002024 00000045171 06634176171 0021370 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ Program name:     TITLE.SAS
/
/ Program version:  2.2
/
/ Program purpose:  When used in conjuction with SETTITLE, will generate
/                   appropriate TITLE statements for given table or appendix
/                   for the current program
/
/
/ SAS version:      6.12 TS020
/
/ Created by:       Carl Arneson
/ Date:
/
/ Input parameters: REPEAT  - Repeat last set of titles?
/                   SET     - Specific set of titles to use (#)
/                   MOCK    - Use mock titles if none are set?
/                   GRAPHIC - Is this a graphics title?
/                   FONT    - Font to use for graphics titles
/                   HEIGHT  - Height to use for graphics titles
/                   FOOT    - Print footnotes?
/                   LABEL   - Use title set identified by this label
/
/ Output created:
/
/ Macros called:    %jkgettf
/
/ Example call:
/
/===========================================================================================
/ Change Log:
/
/    MODIFIED BY: SR Austin
/    DATE:        13Dec94
/    MODID:
/    DESCRIPTION: Added LABEL variable to select title set.
/    ----------------------------------------------------------------------------
/    MODIFIED BY: SR Austin
/    DATE:        27Mar95
/    MODID:
/    DESCRIPTION: Made foot option work.
/    ----------------------------------------------------------------------------
/    MODIFIED BY: SR Austin
/    DATE:        20Jul95
/    MODID:
/    DESCRIPTION: Graphics jobid offset varies by length of user name.
/    ----------------------------------------------------------------------------
/    MODIFIED BY: SR Austin
/    DATE:        03Aug95
/    MODID:
/    DESCRIPTION: Offset graphics jobid a little more at request of R Toorawa.
/    ----------------------------------------------------------------------------
/    MODIFIED BY: A Ratcliffe
/    DATE:        21Nov95
/    MODID:
/    DESCRIPTION: Make sure REPEAT, MOCK, GRAPHIC, and FOOT are converted to
/                 upcase even if only 1 char long.
/    ----------------------------------------------------------------------------
/    MODIFIED BY: C Arneson
/    DATE:        15May97
/    MODID:
/    DESCRIPTION: Handled justification of header titles in a cleaner way and
/                 created some global macro variables that people can stick in
/                 their inits to set default graphics fonts and heights.
/    ----------------------------------------------------------------------------
/    MODIFIED BY: C Arneson
/    DATE:        12SEP1997
/    MODID:
/    DESCRIPTION: Changed placement of JOBID in graphics and the  placement of
/                 the FF character in footnotes to make things IDSG compliant.
/    ----------------------------------------------------------------------------
/    MODIFIED BY: John H King
/    DATE:        17OCT1997
/    MODID:       JHK001
/    DESCRIPTION: Added companion global macro variables for TYPE NUM and TOC
/                 __type__ __num__ __toc__.  These will be used by MACPAGE if
/                 the macpage parameters TYPE= NUM= TOC= are left blank.
/    ----------------------------------------------------------------------------
/    MODIFIED BY: John H King
/    DATE:        12NOV1997
/    MODID:       JHK002
/    DESCRIPTION: Added a call to JKGETTF to allow %TITLE to create the
/                 titles as needed by macros DTAB and AETAB.  Also added STDMAC=
/                 parameter to turn on or off the call to JKGETTF.
/    ----------------------------------------------------------------------------
/    MODIFIED BY: Jonathan Fry
/    DATE:        10DEC1998
/    MODID:       JMF003
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 2.2.
/    ----------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX004
/    DESCRIPTION:
/    ----------------------------------------------------------------------------
/============================================================================================*/

%macro TITLE(
             stdmac  = YES,
             repeat  = N,
             set     = ,
             mock    = Y,
             graphic = N,
             font    = _DEFAULT_,
             height  = _DEFAULT_,
             foot    = Y,
             label   = ,
             dump    = 1
             ) ;

/*------------------------------------------------------------------------------/
/ JMF003                                                                        /
/ Display Macro Name and Version Number in LOG.                                 /
/------------------------------------------------------------------------------*/

   %put ---------------------------------------------------;
   %put NOTE: Macro called: TITLE.SAS   Version Number: 2.2;
   %put ---------------------------------------------------;

   %local pad lab_mtch;
   %let pad='                                                            ';

/*------------------------------------------------------------------------------/
/ Process arguments:                                                            /
/------------------------------------------------------------------------------*/

   %if %length(&repeat)>=1  %then %let repeat  = %upcase(%substr(&repeat,1,1)) ;
   %if %length(&mock)>=1    %then %let mock    = %upcase(%substr(&mock,1,1)) ;
   %if %length(&graphic)>=1 %then %let graphic = %upcase(%substr(&graphic,1,1)) ;
   %if %length(&foot)>=1    %then %let foot    = %upcase(%substr(&foot,1,1)) ;

   %let label=%upcase(%scan(&label,1)) ;

/*------------------------------------------------------------------------------/
/ If font and height is set to _DEFAULT_, look for global specs in some         /
/ macro variable, otherwise set them to something standard.                     /
/------------------------------------------------------------------------------*/

   %if %quote(&font)=_DEFAULT_ %then %do ;
      %global _GTFONT_ ;
      %if "&_GTFONT_"~="" %then %let font=&_GTFONT_ ;
      %else %let font=DUPLEX ;
   %end;

   %if %quote(&height)=_DEFAULT_ %then %do ;
      %global _GTHT_ ;
      %if "&_GTHT_"~="" %then %let height=&_GTHT_ ;
      %else %let height=0.6 ;
   %end;

/*------------------------------------------------------------------------------/
/ Process STDMAC parameter                                                      /
/------------------------------------------------------------------------------*/

   %let stdmac = %substr(%qupcase(&stdmac)%str( ),1,1);
   %if %index(Y1,&stdmac) %then %let stdmac = 1;
   %else %let stdmac = 0;

/*------------------------------------------------------------------------------/
/ Update or create a global macro variable to act as a counter for the          /
/ number of times this macro has been called in the current program:            /
/------------------------------------------------------------------------------*/

   %global __tmcnt ;
   %if %quote(&set)= & &__tmcnt= %then %let __tmcnt = 1 ;
   %else %if %quote(&repeat)~=Y & %quote(&set)=  %then %let __tmcnt = %eval(&__tmcnt + 1) ;

   %if %quote(&set)= %then %let set=&__tmcnt ;

/*------------------------------------------------------------------------------/
/ If user has specified a LABEL, find the matching title set and use it         /
/------------------------------------------------------------------------------*/

   %let lab_mtch=0;
   %if " &label." ne " " %then %do sc=1 %to &_t_____n;
      %if %quote(&label)=%quote(&&__LBL_&sc) %then %do;
         %let set=&sc;
         %let lab_mtch=1;
         %end;
      %end;
   %else %let lab_mtch=2;

   %if &lab_mtch=0 %then
      %put WARNING: Label "&label" was not found on the titles dataset.  The next available title set will be used.;

/*------------------------------------------------------------------------------/
/ For graphics, build a strings that contain the graphics options:              /
/------------------------------------------------------------------------------*/

   %local gopt ;
   %if %quote(&graphic)=Y %then %do ;
      %if %quote(&font)~= %then %let gopt = &gopt F=&font ;
      %if %quote(&height)~= %then %let gopt = &gopt H=&height ;
   %end ;

/*------------------------------------------------------------------------------/
/ Put in %JOBID stamp for graphics:                                             /
/------------------------------------------------------------------------------*/

   %if &graphic=Y %then %do ;
      %local jobid ;
      %let jobid=%jobid(NOQUOTE) ;
   %end ;

/*------------------------------------------------------------------------------/
/ Figure out what the deal is with header titles by searching for HEADn global  /
/ macro variables, then generate TITLE statments for the headers and set a      /
/ variable for the next available title line:                                   /
/------------------------------------------------------------------------------*/

   %global head1 head2 head3 head4 head5 head6 head7 head8 head9 head10 ;
   %local i startn _left;
   %let startn=1 ;

   %do %while (%quote(&&head&startn)~=) ;
      %if %quote(&graphic)=Y %then %do ;

/*------------------------------------------------------------------------------/
/ Look for padding in header titles                                             /
/------------------------------------------------------------------------------*/

         %let i=%index(%quote(&&head&startn),%str(               )) ;

/*------------------------------------------------------------------------------/
/ if it at front, assume right justified title                                  /
/------------------------------------------------------------------------------*/

         %if &i=1 %then %do ;
            TITLE&startn
            %if &startn=1 %then %do ;
               &gopt J=L "%trim(%nrbquote(&jobid))"
               %end ;
               &gopt J=R
               "%left(%nrbquote(&&head&startn))"
              ;
            %end ;

/*------------------------------------------------------------------------------/
/ if it is in the middle, assume a left AND right justified piece               /
/------------------------------------------------------------------------------*/

         %else %if &i>1 %then %do ;
            TITLE&startn &gopt J=L
            "%trim(%qsubstr(&&head&startn,1,&i))"
            %if &startn=1 %then %do ;
               &gopt J=C "%trim(%nrbquote(&jobid))"
               %end ;
            &gopt J=R
            "%left(%qsubstr(&&head&startn,&i))"
            ;
            %end ;

/*------------------------------------------------------------------------------/
/ otherwise, assume it should be left justified                                 /
/------------------------------------------------------------------------------*/

         %else %do ;
            TITLE&startn &gopt J=L
            "%trim(%nrbquote(&&head&startn))"
            %if &startn=1 %then %do ;
               &gopt J=R "%trim(%nrbquote(&jobid))"
               %end ;
            ;
            %end ;
         %end ;

      %else %do ;
         TITLE&startn "&&head&startn" &pad &pad &pad ;
         %end ;
      %let _left  = &_left &startn;
      %let startn = %eval(&startn + 1) ;
   %end                                         /* end for do while */;


/*------------------------------------------------------------------------------/
/ Calculate the maximum number of title lines left after headers:               /
/------------------------------------------------------------------------------*/

   %local titles ;
   %let titles = %eval(10 - &startn) ;

/*------------------------------------------------------------------------------/
/ If no titles have been established for the current piece of                   /
/ output, create dummy value for the table numbers and titles:                  /
/------------------------------------------------------------------------------*/

   %local check ;
   %let check = 1 ;
   %do i = 1 %to &titles ;
      %global ttl&i._&set ;
      %if %nrbquote(&&ttl&i._&set)~= %then %let check = 0 ;
   %end ;

   %if &check & %quote(&mock)=Y %then %do;
      %do i = 1 %to 3 ;
         %let ttl&i._&set = Sample title line number &i ;
      %end;
   %end;

   %global tnstr&set __type&set __num&set ;
   %if %quote(&mock)=Y & %nrbquote(&&tnstr&set)= %then %do ;
      %let tnstr&set = Appendix/Table # ;
      %let __type&set   = A ;
      %let __num&set    = 0 ;
      %let foot=N;
   %end ;

/*------------------------------------------------------------------------------/
/ Count the non-null titles and footnotes:                                      /
/------------------------------------------------------------------------------*/

   %local ntitle nfoot;
   %let ntitle = 0 ;
   %do i = 1 %to &titles ;
      %if %nrbquote(&&ttl&i._&set)~= %then %let ntitle = &i ;
      %end ;

   %if &ntitle=0 & %quote(&&tnstr&set)= %then %do ;
      %let startn = %eval(&startn - 1) ;
      %goto texit ;
      %end ;

/*------------------------------------------------------------------------------/
/ Generate FOOTNOTE statements:                                                 /
/------------------------------------------------------------------------------*/

   %if &foot=Y %then %do;

      %let nfoot = 0 ;

      %do i = 1 %to 10 ;
         %if %length(%nrbquote(&&fnt&i._&set)) gt 1 %then %let nfoot = &i ;
         %end ;

      %do i = 1 %to &nfoot ;
         %if &graphic~=Y %then %do ;
            footnote&i "&&fnt&i._&set" &pad &pad &pad ;
            %end ;
         %else %do ;
            footnote&i j=l "&&fnt&i._&set" ;
         %end ;
      %end ;

      %if &nfoot=0 %then %let i=1 ;
      %else              %let i=%eval(&nfoot + 1) ;

      %if &i > 10 %then %let i = 10;

      footnote&i 'FF'x ;

   %end;

   %else %if &graphic~=Y %then %do;
      footnote1 'FF'x  &pad &pad &pad;
   %end;

/*------------------------------------------------------------------------------/
/ End footnote segment                                                          /
/------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------/
/ Generate TITLE statement for table number:                                    /
/------------------------------------------------------------------------------*/

   %if &graphic=Y %then %let gopt=&gopt J=C ;

   %if %quote(&&tnstr&set)~= %then %do ;
      title&startn &gopt
      %if &startn=1 & &graphic=Y %then %do ;
          ' ' move=(+0.0 in, -0.4 in)
         %end ;
      "&&tnstr&set" ;
      %end ;

   %else %do ;
      %let startn = %eval(&startn - 1) ;
      %end ;

/*------------------------------------------------------------------------------/
/ Set the global macro variables TYPE and NUM and initialize the global         /
/ macro variable TOC:                                                           /
/-------------------------------------------------------------------------------/
/ Changed in JHK001 to include __type__ __num__ __toc__;                        /
/ These global macro variable will be used by MACPAGE the MACPAGE               /
/ parameters with the same name are not specified.                              /
/------------------------------------------------------------------------------*/

   %global type num toc __type__ __num__ __toc__;
   %let type = &&__type&set ;
   %let num = &&__num&set ;
   %let toc = ;
   %let __type__ = &type;
   %let __num__  = &num;
   %let __toc__  = &toc;

   %do i = 1 %to &ntitle ;
      %let startn = %eval(&startn + 1) ;

/*------------------------------------------------------------------------------/
/ Generate TITLE statements for each title line of the current for              /
/ the current set of titles:                                                    /
/------------------------------------------------------------------------------*/

      title&startn &gopt
         %if &startn=1 & &graphic=Y %then %do ;
            ' ' move=(+0.0 in, -0.4 in)
            %end ;
         "&&ttl&i._&set" ;

/*------------------------------------------------------------------------------/
/ Build the TOC macro variable by concatenating each title line, excluding:     /
/     1. lines beginning with "(Part"                                           /
/     2. lines containing #BYVAR, #BYVAL, #BYLINE                               /
/     3. null lines                                                             /
/     4. ??? anything else ????                                                 /
/------------------------------------------------------------------------------*/

      %local key ;
      %let key = (PART ;
      %if %index(%upcase("%nrbquote(&&ttl&i._&set)"),%nrbquote(&key))=0
         and %index(%upcase("%nrbquote(&&ttl&i._&set)"),#BYVAR)=0
         and %index(%upcase("%nrbquote(&&ttl&i._&set)"),#BYVAL)=0
         and %index(%upcase("%nrbquote(&&ttl&i._&set)"),#BYLINE)=0
         and %nrbquote(&&ttl&i._&set)~= %then %do;
         %let toc = %nrbquote(&toc) %nrbquote(&&ttl&i._&set) ;

/*------------------------------------------------------------------------------/
/ Added in JHK001.                                                              /
/ Im not sure what, if any, kind of quoting I needed here,                      /
/ so I just nrbquoted it.                                                       /
/------------------------------------------------------------------------------*/

         %let __toc__ = %nrbquote(&toc);
      %end;

   %end ;

 %texit:

/*------------------------------------------------------------------------------/
/ Set the global macro variable NEXTT:                                          /
/------------------------------------------------------------------------------*/

   %global nextt _set_ ;
   %let nextt = %eval(&startn + 1) ;
   %let _set_ = &set ;

   %if &dump %then %do;
      %put -----------------------------------------------------------------------------;
      %put NOTE: The following Global macro variables have been set.;
      %put NOTE: NEXTT    = *&NEXTT*;
      %put NOTE: _SET_    = *&_set_*;
      %put NOTE: __TYPE__ = *&__type__*;
      %put NOTE: TYPE     = *&type*;
      %put NOTE: __NUM__  = *&__num__*;
      %put NOTE: NUM      = *&num*;
      %put NOTE: __TOC__  = %bquote(*&__toc__*);
      %put NOTE: TOC      = %bquote(*&toc*);
      %put -----------------------------------------------------------------------------;
   %end;

/*------------------------------------------------------------------------------/
/ Added in JHK002                                                               /
/------------------------------------------------------------------------------*/

   %if &stdmac %then %do;
      %jkgettf(_left=&_left)
   %end;

%mend TITLE;
 for HEADn global  /
/ macro variables, then generate TITLE statments for the headers and set a      /
/ variable for the next available title line:                                   /
/------------------------------------------------------------------------------*/

   %global head1 head2 head3 head4 head5 head6 head7 head8 head9 head10 ;
   %local i startn _left;
   %let startn=1 ;

   /users/d33/jf97633/sas_y2k/macros/toc.sas                                                           0100775 0045717 0002024 00000011766 06634173665 0021047 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ Program name:     TOC.SAS
/
/ Program version:  2.1
/
/ Program purpose:  Table of Contents from TITLES System
/
/                   MACPAGE and TITLES call must surround this macro.
/                   datasets=Y prints contents of data library.  Default is N
/
/
/ SAS version:      6.12 TS020
/
/ Created by:       SR Austin
/ Date:             09/06/95
/
/ Input parameters: DATSETS
/
/ Output created:
/
/ Macros called:    None
/
/ Example call:
/
/===============================================================================
/ Change Log:
/
/     MODIFIED BY: SR Austin
/     DATE:        07Nov95
/     MODID:
/     DESCRIPTION: Fixed so will accept GOLD-style protocol names.
/     -------------------------------------------------------------------
/     MODIFIED BY: Jonathan Fry
/     DATE:        10DEC1998
/     MODID:       JMF001
/     DESCRIPTION: Tested for Y2K compliance.
/                  Add %PUT statement for Macro Name and Version Number.
/                  Change Version Number to 2.1.
/     -------------------------------------------------------------------
/     MODIFIED BY:
/     DATE:
/     MODID:       XXX002
/     DESCRIPTION:
/     -------------------------------------------------------------------
/===============================================================================*/

%macro toc(datasets=N);

/*--------------------------------------------------------------------------/
/ JMF001                                                                    /
/ Display Macro Name and Version Number in LOG                              /
/--------------------------------------------------------------------------*/

   %put -------------------------------------------------;
   %put NOTE: Macro called: TOC.SAS   Version Number: 2.1;
   %put -------------------------------------------------;


   %local longest;
   proc format;
      value typesort 1='Tables'
                     2='Figures'
                     3='Appendices'
                     4='X-Appendices'
                     5='Data Preparation Programs'
                     6='Other'
                     1.25='Data Summary'
                     1.50='Exhibit' ;
   run;

   %if %length(&prot) > 3 %then %let dset=in.t&prot.;
   %else %let dset=in.title&prot.;

   data temp;length splittle $200;
      set &dset.(where=(type ne ' ')) end=eof;

      retain longtitl 0;

      if type='Table' then typesort=1;
      else if type='Data Summary' then typesort=1.25;
      else if type='Exhibit' then typesort=1.50;
      else if type='Figure' then typesort=2;
      else if type='Appendix' then typesort=3;
      else if type='Dataprep' then typesort=5;
      else typesort=6;
      if indexc(tabnum,'X') > 0 then typesort=4;

/*--------------------------------------------------------------------------/
/  Fix the sort-order so B1...Bx, C1...Cx are in proper order.              /
/--------------------------------------------------------------------------*/

      length t_1 $1;
      t_0=compress(tabnum,'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz') * 1;
      t_00= left(tabnum);
      t_1 = substr(t_00,1,1);
      t_2 = index('ABCDEFGHIJKLMNOPQRSTUVWXYZ',t_1);
      tabord= (t_2 * 1000) + t_0 ;

/*--------------------------------------------------------------------------/
/ Make titles 1 - 10 one long title with split-characters                   /
/ Title lines that would make the total exceed 200 are not included.        /
/--------------------------------------------------------------------------*/

      array _title {10} $132 title1-title10 ;
      do x=1 to 10;
         if _title{x} ne ' ' &  x=1 then splittle= left(trim(_title{x}));
         else if _title{x} ne ' ' &
            (length(trim(splittle))+length(trim(_title{x})) <199)  then
            splittle= left(trim(splittle)) !! '*' !! left(trim(_title{x}));;

         longtitl=max(longtitl,length(_title{x}));
      end;
      format typesort typesort.;

      if eof then call symput("longest",longtitl);
   run;

   proc sort data=temp out=temp;
     by typesort tabord ;
   run;

   TITLE&nextt. '#byval1';
   OPTIONS nobyline ;

   proc report data=temp headline headskip ls=132
      nowindows split='*' colwidth=8 center missing;
      by typesort;
      column tabord tabnum program splittle ;
      define tabord /order order=internal noprint;
      define tabnum / order width=8 f=$8. 'Number' center;
      define program / display f=$8. 'Program' ;
      define splittle /display flow 'Title' width=&longest.;
      break after tabord / skip ;
   run;

   %if &datasets=Y %then %do;

      proc contents data=in._ALL_ out=contout noprint ;

      data contout; set contout(keep=libname memname);
         by memname;
         if first.memname;

      TITLE&nextt. 'SAS Datasets';

      proc report data=contout headline headskip ls=132 panels=4
         nowindows split='*' colwidth=8 center missing;
         column memname libname ;
         define memname / display 'File Name' width=9;
         define libname / display 'File Type' width=9;
      run;

   %end;

   run;

%mend toc;
          /users/d33/jf97633/sas_y2k/macros/translat.sas                                                      0100775 0045717 0002024 00000004422 06634172527 0022075 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ Program Name:     TRANSLAT.SAS
/
/ Program Version:  2.1
/
/ Program Purpose:  Replaces all occurances of a string with a replacement
/                   string in a macro variable
/
/ SAS Version:      6.12 TS020
/
/ Created By:       Carl Arneson
/ Date:             25/08/92
/
/ Input Parameters: STRING - String value
/                   TARG   - Target string
/                   REPL   - Replacement string
/
/ Output Created:
/
/ Macros Called:    None
/
/ Example Call:     %let char=%translat(&string,hello,bye);
/
/===============================================================================
/ Change Log:
/
/    MODIFIED BY: Jonathan Fry
/    DATE:        10DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 2.1.
/    ------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    ------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    ------------------------------------------------------------------
/===============================================================================*/

%macro TRANSLAT(string,targ,repl) ;

/*------------------------------------------------------------------/
/ JMF001                                                            /
/ Display Macro Name and Version Number in LOG                      /
/------------------------------------------------------------------*/

  %put ------------------------------------------------------;
  %put NOTE: Macro called: TRANSLAT.SAS   Version Number: 2.1;
  %put ------------------------------------------------------;

  %local return pos len ;
  %let len=%length(&targ);
  %let return=;
  %let pos=%index(&string,&targ);

  %do %while(&pos) ;
     %if &pos>1 %then
        %let return=&return.%qsubstr(&string,1,%eval(&pos-1))&repl;
     %else %let return=&return.&repl;
     %if %eval(&pos + &len)<=%length(&string) %then
        %let string=%qsubstr(&string,%eval(&pos + &len));
     %else %let string=;
     %let pos=%index(&string,&targ);
  %end ;

  %let return=&return.&string;

  &return

%mend TRANSLAT ;
                                                                                                                                                                                                                                              /users/d33/jf97633/sas_y2k/macros/vstop.sas                                                         0100664 0045717 0002024 00000004127 06634172214 0021410 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ Program Name:     VSTOP.SAS
/
/ Program Version:  2.1
/
/ Program purpose:  The macro compares the version of SAS on which the current program is
/                   running with the version specified in the macro call. If the two differ,
/                   processing stops.
/
/ SAS Version:      6.12
/
/ Created By:       Randall Austin
/ Date:
/
/ Input Parameters: ARG - The intended SAS version for the program.
/
/ Output Created:   None.
/
/ Macros Called:    None.
/
/ Example Call:     %vstop(6.12);
/
/===============================================================================================
/Change Log
/
/    MODIFIED BY: Jonathan Fry
/    DATE:        10DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version number.
/                 Change Version Number to 2.1.
/    ----------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    ----------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    ----------------------------------------------------------------------------
/================================================================================================*/

%macro vstop(arg);

/*------------------------------------------------------------------------/
/ JMF001                                                                  /
/ Display Macro Name and Version Number in LOG                            /
/------------------------------------------------------------------------*/

   %put ---------------------------------------------------;
   %put NOTE: Macro called: VSTOP.SAS   Version Number: 2.1;
   %put ---------------------------------------------------;

   %local v;
   %let v=%substr(&sysver%str(     ),1,%length(&arg));
   %if "&v"~="&arg" %then %do;
      %put ERROR: You are using the WRONG version of SAS, use &arg..;
      %if &sysenv eq BACK %then %do;
         endsas;
      %end;
   %end;
%mend vstop;
                                                                                                                                                                                                                                                                                                                                                                                                                                         /users/d33/jf97633/sas_y2k/macros/words.sas                                                         0100664 0045717 0002024 00000005167 06634172056 0021404 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ Program Name:     WORDS.SAS
/
/ Program Version:  2.1
/
/ Program purpose:  Takes a character string and splits it into a series of words, based on a defined
/                   delimiter. Each word is stored in a seperate macro variable, and the total number
/                   of words is returned to the calling program.
/
/ SAS Version:      6.12
/
/ Created By:
/ Date:
/
/ Input Parameters: STRING - The name of the variable containing the character string.
/                   ROOT   - A prefix for the series of variables containing the separated
/                            words (default = W).
/                   DELM   - A delimiter character, used for separating words (default = a space).
/
/ Output Created:   A series of macros variables containing the separated words, and the total
/                   number of words.
/
/ Macros Called:    None.
/
/ Example Call:     string = "This is a string containing seven words";
/                   %words(string);
/
/=====================================================================================================
/ Change Log:
/
/    MODIFIED BY: Jonathan Fry
/    DATE:        10DEC1998
/    MODID:       JMF001
/    DESCRIPTION: Tested for Y2K compliance.
/                 Add %PUT statement for Macro Name and Version Number.
/                 Change Version Number to 2.1.
/    --------------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX002
/    DESCRIPTION:
/    --------------------------------------------------------------------------------
/    MODIFIED BY:
/    DATE:
/    MODID:       XXX003
/    DESCRIPTION:
/    --------------------------------------------------------------------------------
/=====================================================================================================*/

%MACRO WORDS(STRING,ROOT=W,DELM=%STR( ));

/*-------------------------------------------------------------------/
/ JMF001                                                             /
/ Display Macro Name and Version Number in LOG                       /
/-------------------------------------------------------------------*/

   %put ---------------------------------------------------;
   %put NOTE: Macro called: WORDS.SAS   Version Number: 2.1;
   %put ---------------------------------------------------;

   %Local Count Word;
   %Let Count = 1;
   %Let Word = %Scan(&String,&Count,&Delm);
   %Do %While(%Quote(&Word)~=);
      %Global &Root&Count;
      %Let &Root&Count = &Word;
      %Let Count = %Eval(&Count + 1);
      %Let Word = %Scan(&String,&Count,&Delm);
      %End;
   %Eval(&Count - 1)
%Mend Words;
                                                                                                                                                                                                                                                                                                                                                                                                         /users/d33/jf97633/sas_y2k/macros/wrap.sas                                                          0100664 0045717 0002024 00000011233 06634171577 0021215 0                                                                                                    ustar 00jf97633                         ukmedsta                        0000245 0020326                                                                                                                                                                        /*
/ Program Name:     WRAP.SAS
/
/ Program Version:  2.1
/
/ MDP/Protocol ID:  N/A
/
/ Program Purpose:  Variable &IN is scanned toward the left, beginning at &WLENGTH,
/                   for any of the delimeters contained in &PUNCT.  If a delimiter
/                   is found, the portion of &IN from the start of &IN to the
/                   delimiter is moved to &OUT.  If a delimiter is not found, the
/                   first &WLENGTH characters are moved from &IN to &OUT.
/
/ SAS Version:      6.12
/
/ Created By:       JIM COMER
/ Date:             08JAN91
/
/ Input Parameters: IN      = Input character string.
/                   OUT     = Output character string.
/                   WLENGTH = Wrap length (default 30).
/                   PUNCT   = Valid delimiter list (default .<(+|''!$*:^-/,')).
/
/ Output Created:   OUT     = Output character string
/
/ Macros Called:    None
/
/ Example Call:
/
/==========================================================================================
/ Change Log:
/
/     MODIFIED BY: Mark Foxwell
/     DATE:        08SEP97
/     MODID:       001
/     DESCRIPTION: 1) DO WHILE loop substituted with a DO UNTIL loop as the DO WHILE
/                     loop will drop the value of __i to 0 if a punctuation mark
/                     falls at position 1 (this causes an error in the substr function
/                     later on.).
/                  2) In the penultimate ELSE DO loop, the start position for &in
/                     changed from &wlength to &wlength+1 otherwise the first
/                     character of &in is the same as the last of &out.
/     --------------------------------------------------------------------------------
/     MODIFIED BY: Jonathan Fry
/     DATE:        10DEC1998
/     MODID:       JMF002
/     DESCRIPTION: Tested for Y2K compliance.
/                  Add %PUT statement for Macro Name and Version Number.
/                  Change Version Number to 2.1.
/     --------------------------------------------------------------------------------
/     MODIFIED BY:
/     DATE:
/     MODID:       XXX003
/     DESCRIPTION:
/     --------------------------------------------------------------------------------
/==========================================================================================*/

%MACRO WRAP (IN      = ,                       /* Input character string  */
             OUT     = ,                       /* Output character string */
             WLENGTH = 30,                     /* Wrap length             */
             PUNCT   = ' .<(+|''!$*:^-/,');    /* Valid delimiter list    */

/*--------------------------------------------------------------------/
/ JMF002                                                              /
/ Display Macro Name and Version Number in LOG.                       /
/--------------------------------------------------------------------*/

   %put --------------------------------------------------;
   %put NOTE: Macro called: WRAP.SAS   Version Number: 2.1;
   %put --------------------------------------------------;

/*--------------------------------------------------------------------/
/ Left align input string and check length.                           /
/--------------------------------------------------------------------*/

   &IN=LEFT(&IN);
   __LEN = LENGTH(TRIM(&IN));

/*--------------------------------------------------------------------/
/ If length of string > wrap length, look for punctuation character.  /
/--------------------------------------------------------------------*/

   IF __LEN GT &WLENGTH THEN DO;
      __FOUND = 0;
      DO __I = &WLENGTH TO 1 BY -1  UNTIL(__FOUND=1);
         __I2 = INDEX(&PUNCT,SUBSTR(&IN,__I,1));
         IF __I2 NE 0 THEN __FOUND=1;
      END;

/*--------------------------------------------------------------------/
/ If punctuation character is found, wrap at that position.           /
/--------------------------------------------------------------------*/

      IF __FOUND = 1 THEN DO;
         &OUT = SUBSTR(&IN,1,__I);
         &IN  = SUBSTR(&IN,__I+1);
      END;

/*--------------------------------------------------------------------/
/ If punctuation character is not found, wrap at &wlength.            /
/--------------------------------------------------------------------*/

      ELSE DO;
         &OUT = SUBSTR(&IN,1,&WLENGTH);
         &IN  = SUBSTR(&IN,&WLENGTH+1);
      END;
   END;

/*--------------------------------------------------------------------/
/ If length of input string < wrap length, move to output string.     /
/--------------------------------------------------------------------*/

   ELSE DO;
      &OUT = &IN;
      &IN  = ' ';
   END;

   DROP __LEN __FOUND __I __I2 ;

%MEND;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     