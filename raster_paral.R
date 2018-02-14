library(raster)

#Set the year(s) and the location to retrieve data for ----
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
  }
  return(list(tair, rain, wind, irr, vpd))
}

#Execute ----
res0 = lapply(years, RasterTreat) #results (tair, wind, vpd, ...) stored as a list within the list res

#Save as list of rasters ----
len_y = length(years)
res = array(unlist(res0), dim = c(20, len_y))

tair1 = do.call(stack, res[1, ])
tair2 = do.call(stack, res[2, ])
tair3 = do.call(stack, res[3, ])
tair4 = do.call(stack, res[4, ])

rain1 = do.call(stack, res[5, ])
rain2 = do.call(stack, res[6, ])
rain3 = do.call(stack, res[7, ])
rain4 = do.call(stack, res[8, ])

wind1 = do.call(stack, res[9, ])
wind2 = do.call(stack, res[10, ])
wind3 = do.call(stack, res[11, ])
wind4 = do.call(stack, res[12, ])

irr1 = do.call(stack, res[13, ])
irr2 = do.call(stack, res[14, ])
irr3 = do.call(stack, res[15, ])
irr4 = do.call(stack, res[16, ])

vpd1 = do.call(stack, res[17, ])
vpd2 = do.call(stack, res[18, ])
vpd3 = do.call(stack, res[19, ])
vpd4 = do.call(stack, res[20, ])

res1 = list(tair1, tair2, tair3, tair4,
     rain1, rain2, rain3, rain4,
     wind1, wind2, wind3, wind4,
     irr1, irr2, irr3, irr4,
     vpd1, vpd2, vpd3, vpd4)

save(res1, file = "res.RData")

if(retr.coor){
  #Retrieve point data ----
  m = matrix(c(lon, lat), 1, 2)
  DF = as.data.frame(sapply(res1, function(x) t(extract(x, m))))
  colnames(DF) = paste0(rep(c("tair", "rain", "wind", "irr", "vpd"), each = 4), 0:3 * 6)
  DF$year = rep(years, each = 12)
  DF$month = 1:12
  
  write.table(DF, "troll_input_climat_raster.txt", row.names = F, col.names = T, sep = "\t")

  #Calculate monthly climate data, averaged over years ----
  DF_ave = as.data.frame(aggregate(DF[, 1:20], by = list(DF$month), mean))
  colnames(DF_ave)[1] = "month"
  write.table(DF_ave, "troll_input_climat_raster_average.txt", row.names = F, col.names = T, sep = "\t")
}