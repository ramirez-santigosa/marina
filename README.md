# MARINA #

A Tool for Solar Radiation Series Generation
--------------------------------------------

MARINA (Multi annual radiation information approach) is a package of MATLAB® M-files purpose to standardize the procedure for solar radiation series generation, starting from raw data and providing a clean and inter-comparable data bank. A brief summary of each module included in this tool is below: 

![Diagram](/other/marina-Files.jpeg "Diagram of the MARINA package")

### Modules: ###

* To format: translate the input data set from its original format to a pre-defined MATLAB structure. The first part of this module has to be specifically developed for each input data set format (BSRN, PSA…) because of the wide variety of the input formats. Input data of each year are saved in a separate standard structure. The standard structure has six main fields (or data containers). This module just saves the input data set in the standard structure without applying any correction or other modifications.
* Quality Control (QC): a slightly modified version of the Quality Control (QC) process described in (Moreno-Tejera et al., 2015) is used for this module. A final fourth test was added, which is passed if the GHI measured value is between +/- 50 W/m2 of the GHI value calculated from its measured components.
* Validation and Gap Filling: based on the procedure indicated in the (IEC/TS 62862-1-2, 2017) standard, which is expected to be published soon. The process has two stages: Daily and Monthly Validation. In the first one, a day is considered valid if it has a cumulated period of irradiance anomalous values (those values that do not pass the QC) less than one hour. The anomalies of a possible valid day are corrected coherently using linear interpolation. The daily validation process can be applied to each irradiance variable independently. Later, a month is considered valid if it has less than four non-valid days. To find the monthly irradiance value of a valid month with anomalous days, the measured values on these days are substituted by the values of the day with its irradiance value closest to the monthly mean value within a range of no more than ±5 days from the substituted day.
* Selection of Typical Meteorological Months (TMM): This module implements the selected TMY methodologies. To avoid possible misunderstandings, ‘TMY’ will be used to refer the Typical Meteorological Year methodologies in general, while ‘ASR’ will be used to refer the Annual Solar Radiation series produced after the execution of a specific TMY methodology. The TMY methodologies included in this tool are:
  * IEC 62862-1-2 Option 1 (IEC1/SNL): Referred as “One source�? in (IEC/TS 62862-1-2, 2017). It is an adaptation of the well-known SNL method (Hall et al., 1978).
  * Alternative “Less Missing Records�? (IEC1/LMR): It is an alternative to the previous procedure with a change in the final selection criterion.
  * IEC 62862-1-2 Option 2 (IEC2): Referred as “Several sources�? in (IEC/TS 62862-1-2, 2017).
  * Danish method (DRY): Adaptation of the Danish method as described in (Lund, 1995).
  * Festa and Ratto (F-R): Adaptation of the Festa and Ratto procedure as described in (Festa and Ratto, 1993)
* Annual Series Generation: this module concatenates the selected TMM from the whole data set delivered by the validation module to form the final ASR series. This module also performs the day’s substitutions required for the option 2 (IEC/TS 62862-1-2, 2017) standard.
* Adding Meteorological Data: incorporate other input meteorological data, like the dry bulb, dew point and wet bulb temperatures, atmospheric pressure, relative humidity and, wind speed, when are not included with the input measured database. These variables are usually required by the STE plants simulation software. This module also writes the output files with the standard comma-separated values (CSV) format adopted by the SAM software or the data format for meteorological data sets purposed by the standard (IEC/TS 62862-1-3, 2017). A sampling frequency for the output files can be defined (minute, 10-minutes… hourly). Functions for interpolation or reduce intra-hourly frequency are executed when required in order to match the frequency.

There are two transversal files to all the modules of MARINA. One is the main file that is used simply to gather all the modules in a central file and execute it in a specified order. Nevertheless, each module can be executed independently if the required inputs are available. The other one is the configuration file, which is a specific file for each input data set (i.e. BSRN, PSA...) or study case. The configuration file saves the main variables, defines the options wanted for each module, and the data input and output paths. Other transversal files are general functions for plotting

### What is this repository for? ###

* Generation of solar radiation series for STE simulation (CSV SAM format available). Several Typical Meteorological Methodologies are implemented, including the recent standardization purposes (IEC 62862-1-2).
* Version 1.0

### How do I get set up? ###

1. Create a configuration file (Configuration_xxxx.m) specific for your input data set or study case. The ease way for creation is copying from one of the included configuration files (i.e Configuration_PSA.m).
2. All the variables and paths defined in the configuration file must correspond with your input data set. Especially, to start to use this package your raw input radiation data must be located in the input path (path_in) declared in the configuration file. Relative paths are recommended.
3. Define the configuration file in the main file (MARINA.m). If you execute the main file all the modules will be executed in a specific order until the printing of the series for simulation. You can also execute each module independently.
4. This package was developed and tested using MATLAB version 9.1.0.441655 (R2016b).

### Who do I talk to? ###

* [Lourdes Ramírez Santigosa](mailto:lourdes.ramirez@ciemat.es)

Solar Radiation Unit, Renewable Energy Division, CIEMAT, Spain
