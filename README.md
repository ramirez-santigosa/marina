# MARINA #

A Tool for Solar Radiation Series Generation
--------------------------------------------

MARINA (Multi annual radiation information approach) is a package of MATLAB® M-files purpose to standardize the procedure for solar radiation series generation, starting from raw data and providing a clean and inter-comparable data bank. A brief summary of each module include in this tool is below: 

This README would normally document whatever steps are necessary to get your application up and running.

![Diagram](/other/marina-Files.png "Diagram of the MARINA package")

### Modules: ###

* To format: the input data are converted into an internal pre-defined structured format. The first part of this module has to be specifically developed for each input format (i.e. BSRN, PSA…).
* Quality Control (QC): a slightly modified version of the Quality Control (QC) process described in (Moreno-Tejera et al., 2015) is used for this module. A final fourth test was added, which is passed if the GHI measured value is between +/- 50 W/m2 of the GHI value calculated from its measured components.
* Validation and Gap Filling: based on the procedure indicated in the IEC TS 62862-1-2 standard, which is currently under development. The process has two stages: Daily and Monthly Validation. In the first one, a day is considered valid if it has a cumulated period of irradiance anomalous values (those values that do not pass the QC) less than one hour. The anomalies of a possible valid day are corrected coherently using linear interpolation. Later, a month is considered valid if it has less than four non-valid days. To find the monthly value corresponding to a month with anomalous days, the irradiation-measured values on these days is substituted by the values of the day with its irradiance value closest to the monthly mean value within a range of no more than ±5 days from the substituted day.
* Candidates Selection: the wanted typical year methodology could be chosen among the standard American TMY methodology (Wilcox and Marion, 2008), the Danish method (Lund, 1995), and the Festa-Ratto variation (Festa and Ratto, 1993). According to the selected methodology, the months that will make up the typical year are selected.
* Annual Series Generation: this module concatenates the selected months from the data delivered by the validation module to form the typical year. It also writes output files with the standard comma-separated value (CSV) format adopted by the SAM software or the IEC 62862-1-3 data format for meteorological data sets.
* Adding Meteorological Data: is a specific module useful to incorporate other input meteorological data (as temperatures, relative humidity, wind speed), which is usually required by the STE plants simulation software.
[comment]: <> (* Other: ...)

### What is this repository for? ###

* Quick summary
* Version
* [Learn Markdown](https://bitbucket.org/tutorials/markdowndemo)

### How do I get set up? ###

* Summary of set up
* Configuration
* Dependencies
* Database configuration
* How to run tests
* Deployment instructions

### Contribution guidelines ###

* Writing tests
* Code review
* Other guidelines

### Who do I talk to? ###

* Lourdes Ramírez Santigosa.

Solar Radiation Unit, Renewable Energy Division, CIEMAT, Spain
