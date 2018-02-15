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