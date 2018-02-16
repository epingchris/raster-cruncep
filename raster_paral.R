library(raster)

#Set the year(s) to retrieve data for ----
source("raster_args.R")

#Set chronological constants ----
#calculate monthly data: limits of each month in a year
#every year in CRU-NCEP database has 365 days (no leap years)
daymonth = c(31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
m_end = cumsum(daymonth)
m_start = c(1, m_end[1:11] + 1)
tp = list(4 * 1:365 - 3, 4 * 1:365 - 2, 4 * 1:365 - 1, 4 * 1:365) #set four time periods

#Set functions ----
#function to calculate wind speed
CalcSpeed = function(u, v){
  sqrt(u ^ 2 + v ^ 2)
}

#function to calculate VPD
CalcVPD = function(q, p, t){
  #q: fraction
  #p: Pa
  #T: C
  t = t - 273.15
  e_sat = 0.61121 * exp((18.678 - t / 234.5) * (t / (257.14 + t))) #saturated vapor pressure in kPa by Buck equation
  vpd = e_sat - q * (p / 1000) / (0.622 + q * 0.378) #Monteith & Unsworth 3 e.d.
  return(vpd)
}

#Set core ----
RasterTreat = function(year){
  #create lists to store (stack) variables for each of the four time periods
  tair = vector("list", 4)
  rain = vector("list", 4)
  wind = vector("list", 4)
  irr = vector("list", 4)
  vpd = vector("list", 4)
  
  #create lists to store (stack) variables for each month of the year
  tair_tmp = vector("list", 12)
  rain_tmp = vector("list", 12)
  wind_tmp = vector("list", 12)
  irr_tmp = vector("list", 12)
  vpd_tmp = vector("list", 12)
  
  #read files
  datt = stack(paste0("/share/apps/climat/CRU_NCEP/cruncepv7_tair_", year, ".nc")) #Temperature
  datr = stack(paste0("/share/apps/climat/CRU_NCEP/cruncepv7_rain_", year, ".nc")) #Total_Precipitation
  datu = stack(paste0("/share/apps/climat/CRU_NCEP/cruncepv7_uwind_", year, ".nc")) #U_wind_component
  datv = stack(paste0("/share/apps/climat/CRU_NCEP/cruncepv7_vwind_", year, ".nc")) #V_wind_component
  datl = stack(paste0("/share/apps/climat/CRU_NCEP/cruncepv7_lwdown_", year, ".nc")) #Incoming_Long_Wave_Radiation
  dats = stack(paste0("/share/apps/climat/CRU_NCEP/cruncepv7_swdown_", year, ".nc")) #Incoming_Short_Wave_Radiation
  datq = stack(paste0("/share/apps/climat/CRU_NCEP/cruncepv7_qair_", year, ".nc")) #Air_Specific_Humidity
  datp = stack(paste0("/share/apps/climat/CRU_NCEP/cruncepv7_press_", year, ".nc")) #Pression
  
  for(k in 1:4){
    tpi = tp[[k]]
    
    for(m in 1:12){
      d0 = m_start[m]
      d1 = m_end[m]
      
      #calculate values for each month
      tair_tmp[[m]] = mean(datt[[tpi]][[d0:d1]]) - 273.15 #mean process time: 1.281325
      rain_tmp[[m]] = sum(datr[[tpi]][[d0:d1]]) #mean process time: 1.190852
      wind_tmp[[m]] = mean(CalcSpeed(datu[[tpi]][[d0:d1]], datv[[tpi]][[d0:d1]])) #mean process time: 5.031271
      irr_tmp[[m]] = mean(datl[[tpi]][[d0:d1]] + dats[[tpi]][[d0:d1]] / (6 * 3600)) #mean process time: 3.707192
      vpd_tmp[[m]] = mean(CalcVPD(datq[[tpi]][[d0:d1]], datp[[tpi]][[d0:d1]], datt[[tpi]][[d0:d1]])) #mean process time: 19.58265
    }
    
    #stack all the months (of a year and a time period) together
    tair[[k]] = do.call(stack, tair_tmp)
    rain[[k]] = do.call(stack, rain_tmp)
    wind[[k]] = do.call(stack, wind_tmp)
    irr[[k]] = do.call(stack, irr_tmp)
    vpd[[k]] = do.call(stack, vpd_tmp)
    
    #Save as native raster package format files to be used subsequently in RconTroll package
    #One file for each year and each variable (12 x 4 x 5 x number of years in total)
    #the raster grid format consists of the binary .gri file and the .grd header file.
    writeRaster(tair[[k]], paste0("/results/tair", k, "_", year, ".grd"), format = "raster")
    writeRaster(rain[[k]], paste0("/results/rain", k, "_", year, ".grd"), format = "raster")
    writeRaster(wind[[k]], paste0("/results/wind", k, "_", year, ".grd"), format = "raster")
    writeRaster(irr[[k]], paste0("/results/irr", k, "_", year, ".grd"), format = "raster")
    writeRaster(vpd[[k]], paste0("/results/vpd", k, "_", year, ".grd"), format = "raster")
  }
}

#Execute ----
lapply(years, RasterTreat) #results (tair, wind, vpd, ...) saved in grd files