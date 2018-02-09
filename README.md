#raster-cruncep

This is a project which consists of processing CRU-NCEP meteorological data using raster package, and generating suitable data format that can be used in forest dyanmics simulation model TROLL.


#CRU-NCEP database

CRU-NCEP database is a database of globally re-analyzed meteorological data at a resolution of 0.5 x 0.5 degrees 
(on total 720 x 360 points on Earth), and at a 6-hour time interval (four time periods daily - 6:00, 12:00, 18:00, 24:00) from 1901 to 2015.
The data are stored in NetCDF format (.nc): each file contains of one year and the size of each file is around 1 GB. 

The variables available on external hard drive LaCie and on the cluster of Laboratoire EDB include:

．"tair": Temperature (K)

．"rain", Total Precipitation (mm)

．"uwind", U wind component (m/s)

．"vwind", V wind component (m/s)

．"lwdown", Incoming Long Wave Radiation (J/m2)

．"swdown", Incoming Short Wave Radiation (J/m2)

．"qair", Air Specific Humidity (g/g)

．"press", Pression (Atmosphere pressure) (Pa)


#input climate data for TROLL model

In the older versions of TROLL model, the input climate data include the following 9 variables:

．Mean daily temperature (°C)

．Maximum daily temperature (°C)

．Mean night temperature (°C) (not implemented)

．Total rainfall (mm)

．Wind speed (m/s)

．Mean irradiance (W/m2)

．Maximum irradiance (W/m2)

．Mean VPD (vapor pressure deficit) (kPa)

．Maximum VPD (kPa)

Each variable contains 12 monthly values, calculated by taking the arithmetic mean of daily values, 
except for rainfall, which is calculated by taking the sum. For climate data of multiple years, the monthly data are averaged over the year.
Older versions of TROLL contained additional parameters used to construct the daily profile of temperature, irradiance and VPD.

In the new version of TROLL, the daily profile of is constructed directly from the daily values of the four 6-hour time periods.
The new version of TROLL also allows input data from multiple years.
The input climate data for the new version of TROLL model thus include the following 5 variables:

．Daily temperature (°C)

．Total rainfall (mm)

．Wind speed (m/s)

．Irradiance (W/m2)

．VPD (kPa)

Each variable contains 12 monthly values for each of the time periods (48 values for each year), 
calculated by taking the arithmetic mean of values from each time period, except for rainfall, which is calculated by taking the sum.


#Calculation of input climate data

Daily temperature is calculated from "tair"; the unit is converted from K to °C.

Total rainfall is calculated from "rain".

Wind speed is calculated from "uwind" and "vwind", with the equation:

．(wind speed) = sqrt(uwind ^ 2 + vwind ^ 2)

Irradiance is calculated from "lwdown" and "swdown", with the equation:

．irradiance = (lwdown + swdown) / (6 * 3600).

The value in J is divided by the time period of 6 hours to be converted to W.

VPD is calculated from "tair", "qair" and "press".
VPD is defined to be the difference between the saturated vapor pressure (e_sat) and the actual atmospheric vapor pressure (e):

．VPD = e_sat - e

First, the saturated vapor pressure (vpsat, in kPa) at a given temperature is calculated by the Buck Equation (Buck 1998):

．e_sat = 0.61121 * exp((18.678 - tair / 234.5) * (tair / (257.14 + tair)))
  
Then, the actual atmospheric vapor pressure (e, in kPa) is calculated using the equation derived from the relation between vapor pressure,
specific humidty (qair), and atmospheric pressure (press), described in Monteith & Unsworth (2008):

．e = q * p / [ε + (1 - ε) * q]

Where ε is the ratio between the molecular weight of water vapor and that of dry air (0.622).


#Raster processing and parallel computing

Older versions of the script are run on local computers, while connecting to the hard drive containing the files.

"climate_treat.R" and "climate_function.R" uses ncdf4 package to extract the values from a specific location, and performs the calculation afterward.
While this is suitable for processing one location, it is too time-consuming to process the climate data over the entire globe.

"raster_treat.R" uses raster package to process climate data over the entire globe, and then extract the data for a certain location.
While faster then then the previous method, it still takes around 40 minutes to process the climate data for one year.

Parallel computing, employing Laboratoire EDB's calculation cluster, can greatly increase the computational speed.
Three scripts (two R scripts and one shell script) are uploaded to the personal space of the calculation cluster to be executed.

In "raster_args.R", we specify the year(s) for which we wish to use the climate data, 
and an option of whether we want to extract climate data for one specific location, and if so, the coordinates of the location.

In "raster_paral.R", the climate data is processed and the result is stored in an RData file: a list of 4 * 5 = 20 elements,
each containing a RasterStack object of 12 * (number of years) layers.
If it has been specified that we wish to extract data for a specific location, 
the script will also generate a text file containing 12 * (number of years) rows and 4 * 5 = 20 columns, which can be.

The shell script "raster_job.sh" is the script to be executed on the cluster using the command line:

gsub -V raster_job.sh

With the setting of 20 threads in mode MPI, without designating the node to used,
it takes around 30 minutes to process the climate data for two years,
which is a nearly three-fold decrease in time compared the previous method.
The computational time can be improved by using other parameters for the parallel computing.


#Future work
It is possible to integrate the arguments (years, coordinates...) directly in the shell script, eliminating the need to use "raster_args.R" script.


#References

．Buck (1996), Buck Research CR-1A User's Manual, Appendix 1.

．Monteith, J.L. and Unsworth, M.H. (2008) Principles of Environmental Physics. 3rd Edition, Academic Press, New York, 418. 
