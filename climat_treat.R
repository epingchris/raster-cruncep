rm(list = ls())
library(ncdf4)
setwd("/Volumes/LaCie/CRU_NCEP/")

#parameters needed in "climat.func.R": limits of each month in a year
daymonth = c(31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
m_end = cumsum(daymonth)
m_start = c(1, m_end[1:11] + 1)

#define the coordinates and the years
ilon = 121.5578
ilat = 24.7611
yr = 2001

start.time <- Sys.time() #calculate run time

#create empty file with column (variable) names
write.table(cbind("tair_moy_m", "tair_max_m", "rain_m", "wind_moy_m", "irr_moy_m", "irr_max_m", "vpd_moy_m", "vpd_max_m", "year", "month"),
            "/Users/eprau/EPR/Toulouse/UPS/Stage_M2/troll_input_climat.txt", row.names = F, col.names = T, sep = "\t")

res_old = vector("list", length(yr))
for(k in 1:length(yr)){
  year = yr[k]
  source("/Users/eprau/EPR/Toulouse/UPS/Stage_M2/climat_func.R") #run "climat_func.R", the core

  #store the result for each year
  res_old[[k]] = data.frame(tair_moy_m, tair_max_m, rain_m, wind_moy_m, 
                        irr_moy_m, irr_max_m, vpd_moy_m, vpd_max_m, year = year, month = 1:12)
  
  #write the result into the file previously created
  write.table(res_old[[k]], "/Users/eprau/EPR/Toulouse/UPS/Stage_M2/troll_input_climat.txt", append = T, row.names = F, col.names = F, sep = "\t")
}

#calculate run time
end.time <- Sys.time()
time.taken <- end.time - start.time
time.taken

#Next step: revise light course, VPD course, T course (use the four intervals from CRU-NCEP in the entry data directly)