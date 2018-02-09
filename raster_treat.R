rm(list = ls())
library(raster)
setwd("/Volumes/LaCie/CRU_NCEP/")

#initialization ----
#year(s) to retrieve data for
year = 2001

#coordinates
lon = 121.5578
lat = 24.7611

#preparation of necessary elements ----
#calculate monthly data: limits of each month in a year
#every year in CRU-NCEP database has 365 days (no leap years)
daymonth = c(31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
m_end = cumsum(daymonth)
m_start = c(1, m_end[1:11] + 1)

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
  vpsat = 0.61121 * exp((18.678 - t / 234.5) * (t / (257.14 + t))) #saturated vapor pressure by Buck equation
  vpd = vpsat - q * (p / 1000) / (0.622 + q * 0.378) #Monteith & Unsworth 3 e.d.
  return(vpd) # convert Pa to kPa
}

tp = list(4 * 1:365 - 3, 4 * 1:365 - 2, 4 * 1:365 - 1, 4 * 1:365) #set four time periods

#core ----
start.time = Sys.time()

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

for(i in 1:length(year)){
  #read files
  datt = stack(paste0("cruncepv7_tair_", year[i], ".nc")) #Temperature
  datr = stack(paste0("cruncepv7_rain_", year[i], ".nc")) #Total_Precipitation
  datu = stack(paste0("cruncepv7_uwind_", year[i], ".nc")) #U_wind_component
  datv = stack(paste0("cruncepv7_vwind_", year[i], ".nc")) #V_wind_component
  datl = stack(paste0("cruncepv7_lwdown_", year[i], ".nc")) #Incoming_Long_Wave_Radiation
  dats = stack(paste0("cruncepv7_swdown_", year[i], ".nc")) #Incoming_Short_Wave_Radiation
  datq = stack(paste0("cruncepv7_qair_", year[i], ".nc")) #Air_Specific_Humidity
  datp = stack(paste0("cruncepv7_press_", year[i], ".nc")) #Pression
  
  for(k in 1:4){
    tpi = tp[[k]]
    
    for(j in 1:12){
      d0 = m_start[j]
      d1 = m_end[j]
    
      #calculate values for each month
      tair_tmp[[j]] = mean(datt[[tpi]][[d0:d1]]) - 273.15 #mean process time: 1.281325
      rain_tmp[[j]] = sum(datr[[tpi]][[d0:d1]]) #mean process time: 1.190852
      wind_tmp[[j]] = mean(CalcSpeed(datu[[tpi]][[d0:d1]], datv[[tpi]][[d0:d1]])) #mean process time: 5.031271
      irr_tmp[[j]] = mean(datl[[tpi]][[d0:d1]] + dats[[tpi]][[d0:d1]] / (6 * 3600)) #mean process time: 3.707192
      vpd_tmp[[j]] = mean(CalcVPD(datq[[tpi]][[d0:d1]], datp[[tpi]][[d0:d1]], datt[[tpi]][[d0:d1]])) #mean process time: 19.58265
    }
    
    #stack all the months (of a year and a time period) together and add it to the list
    if(i == 1){
      tair[[k]] = do.call(stack, tair_tmp)
      rain[[k]] = do.call(stack, rain_tmp)
      wind[[k]] = do.call(stack, wind_tmp)
      irr[[k]] = do.call(stack, irr_tmp)
      vpd[[k]] = do.call(stack, vpd_tmp)
      
    } else {
      tair[[k]] = stack(tair[[k]], do.call(stack, tair_tmp))
      rain[[k]] = stack(rain[[k]], do.call(stack, rain_tmp))
      wind[[k]] = stack(wind[[k]], do.call(stack, wind_tmp))
      irr[[k]] = stack(irr[[k]], do.call(stack, irr_tmp))
      vpd[[k]] = stack(vpd[[k]], do.call(stack, vpd_tmp))
    }
  }
}
end.time = Sys.time()
time.diff = end.time - start.time
time.diff

#extraction of data from one point ----

#function to retrieve the data of a point on Earth and transform them into data frame format
RetrCoor = function(x, lon, lat){
  m = matrix(c(lon, lat), 1, 2)
  res = sapply(x, function(x) t(extract(x, m)))
  colnames(res) = paste0(deparse(substitute(x)), "_", 1:4 * 6)
  return(res)
}

DF_tair = RetrCoor(tair, lon, lat)
DF_rain = RetrCoor(rain, lon, lat)
DF_wind = RetrCoor(wind, lon, lat)
DF_irr = RetrCoor(irr, lon, lat)
DF_vpd = RetrCoor(vpd, lon, lat)

write.table(data.frame(DF_tair, DF_rain, DF_wind, DF_irr, DF_vpd, year = rep(year, each = 12), month = 1:12),
            "/Users/eprau/EPR/Toulouse/UPS/Stage_M2/troll_input_climat_raster.txt", 
            row.names = F, col.names = T, sep = "\t")