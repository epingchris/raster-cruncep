#tair ----
#input: "Temperature" in "K"
#output:
#/*Temperature in degree C*/	
#/*mean daily max temperature in degree C*/	
#/*Night mean temperature in degree C*/
datt = nc_open(paste0("cruncepv7_tair_", year, ".nc")) #open file

#get geographical variables
lon = ncvar_get(datt, "longitude") 
lat = ncvar_get(datt, "latitude")

#calculate the nearest point
x = which.min(abs(lon - ilon))
y = which.min(abs(lat - ilat))

#retrieve variable and calculate daily data
tair_var = ncvar_get(datt, "Temperature", start = c(x, y, 1), count = c(1, 1, -1)) - 273.15 #K to C
tair_mat = matrix(tair_var, 4, 365)
tair_moy_j = apply(tair_mat, 2, mean)
tair_max_j = apply(tair_mat, 2, max)

#calculate monthly data
tair_moy_m = rep(NA, 12)
tair_max_m = rep(NA, 12)
for(i in 1:12){
  tair_moy_m[i] = mean(tair_moy_j[m_start[i]:m_end[i]])
  tair_max_m[i] = mean(tair_max_j[m_start[i]:m_end[i]])
}

#rain ----
#input: "Total_Precipitation" in "mm/6h"
#output: /*Rainfall in mm*/
datr = nc_open(paste0("cruncepv7_rain_", year, ".nc")) #open file

#retrieve variable and calculate daily data
rain_var = ncvar_get(datr, "Total_Precipitation", start = c(x, y, 1), count = c(1, 1, -1))
rain_mat = matrix(rain_var, 4, 365)
rain_j = apply(rain_mat, 2, sum)

#calculate monthly data
rain_m = rep(NA, 12)
for(i in 1:12){
  rain_m[i] = sum(rain_j[m_start[i]:m_end[i]])
}

#wind ----
#input: "U_wind_component" & "V_wind_component" in "m/s"
#output:	/* Wind speed in m.s-1 */
datu = nc_open(paste0("cruncepv7_uwind_", year, ".nc")) #open file
datv = nc_open(paste0("cruncepv7_vwind_", year, ".nc")) #open file

#retrieve variables and calculate daily data
uwind = ncvar_get(datu, "U_wind_component", start = c(x, y, 1), count = c(1, 1, -1))
vwind = ncvar_get(datv, "V_wind_component", start = c(x, y, 1), count = c(1, 1, -1))
windspeed = sqrt(uwind ^ 2 + vwind ^ 2) #combining X-axis and Y-axis vector
wind_mat = matrix(windspeed, 4, 365)
wind_moy_j = apply(wind_mat, 2, mean)
#will we need wind angle?

#calculate monthly data
wind_moy_m = rep(NA, 12)
for(i in 1:12){
  wind_moy_m[i] = mean(wind_moy_j[m_start[i]:m_end[i]])
}

#irradiance ----
#input: "Incoming_Long_Wave_Radiation" & "Incoming_Short_Wave_Radiation" in "J/m2"
#output:
#	/* Daily max irradiance mean in W.m-2 */	
#	/* Irradiance mean in W.m-2 */	
datl = nc_open(paste0("cruncepv7_lwdown_", year, ".nc")) #open file
dats = nc_open(paste0("cruncepv7_swdown_", year, ".nc")) #open file

#retrieve variables and calculate daily data
lwdown = ncvar_get(datl, "Incoming_Long_Wave_Radiation", start = c(x, y, 1), count = c(1, 1, -1))
swdown = ncvar_get(dats, "Incoming_Short_Wave_Radiation", start = c(x, y, 1), count = c(1, 1, -1))
irrad = (lwdown + swdown) / (6 * 3600) #add two sources of radiation and convert J/m2 to W/m2
irr_mat = matrix(irrad, 4, 365)
irr_moy_j = apply(irr_mat, 2, mean)
irr_max_j = apply(irr_mat, 2, max)

#calculate monthly data
irr_moy_m = rep(NA, 12)
irr_max_m = rep(NA, 12)
for(i in 1:12){
  irr_moy_m[i] = mean(irr_moy_j[m_start[i]:m_end[i]])
  irr_max_m[i] = mean(irr_max_j[m_start[i]:m_end[i]])
}

#VPD ----
#input: "Air_Specific_Humidity" in "g/g" & "Pression" in "Pa" ("kPa"?)
#output:
#	/* Daily mean VPD in kPa */
#	/* daily max VPD in kPa */
datq = nc_open(paste0("cruncepv7_qair_", year, ".nc")) #open file
datp = nc_open(paste0("cruncepv7_press_", year, ".nc")) #open file

#retrieve variables and calculate VPD
qair = ncvar_get(datq, "Air_Specific_Humidity", start = c(x, y, 1), count = c(1, 1, -1))
press = ncvar_get(datp, "Pression", start = c(x, y, 1), count = c(1, 1, -1))
vpsat = 0.61121 * exp((18.678 - tair_var / 234.5) * (tair_var / (257.14 + tair_var))) #saturated vapor pressure by Buck equation
vpsat = vpsat * 1000 #convert kPa to Pa
qsat = vpsat / press #qsat * atmospheric pressure = saturated vapor pressure
th1 = 0.622
th2 = 0.378
vpd1 = vpsat / (th1 + qsat * th2) - qair * press / (th1 + qair * th2)
vpd1 = vpd1 / 1000 # convert Pa to kPa

#another simpler way to calculate VPD?
vpd2 = vpsat * (1 - qair) / 1000

#calculate daily data
vpd_mat = matrix(vpd1, 4, 365)
vpd_moy_j = apply(vpd_mat, 2, mean)
vpd_max_j = apply(vpd_mat, 2, max)

#calculate monthly data
vpd_moy_m = rep(NA, 12)
vpd_max_m = rep(NA, 12)
for(i in 1:12){
  vpd_moy_m[i] = mean(vpd_moy_j[m_start[i]:m_end[i]])
  vpd_max_m[i] = mean(vpd_max_j[m_start[i]:m_end[i]])
}