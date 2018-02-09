#
#!/bin/sh
# Create forcing file for TROLL from CRU-NCEP v7
# CRU-NCEP dir /home/surface3/maignan/ORCHIDEE/FORCAGES/CRUNCEP/V7/trendy
# Ouput dir /home/orchidee04/joetzjer/FRC/TROLL
# rundir 


if test $# -lt 2
then
echo " "
echo " Syntaxe : $0 LON LAT"
echo " "
exit
fi

lon=$1
lat=$2


cat << EOF > input.R
rm(list=ls())
library(ncdf) 

dirin="/home/surface3/maignan/ORCHIDEE/FORCAGES/CRUNCEP/V7/trendy/"
dirout="/home/orchidee04/joetzjer/FRC/TROLL/"

ilon=$1
ilat=$2

##################################################
# get lon lat indices in netcdf
##################################################
f=open.ncdf(paste0(dirin,"cruncepv7_tair_1901.nc"))
lon=get.var.ncdf(f,"longitude")
lat=get.var.ncdf(f,"latitude")

x=which.min(abs(lon - ilon))
y=which.min(abs(lat - ilat))

#check 
print(c(lon[x],lat[y]))

###########################################################
# load needed variables across years for the given location
###########################################################

var=c("tair","lwdown","swdown","uwind","vwind","rain","qair","press")
nomvar=c("Temperature","Incoming_Long_Wave_Radiation","Incoming_Short_Wave_Radiation","U_wind_component","V_wind_component","Total_Precipitation","Air_Specific_Humidity","Pression")
unit=c("K","W/m2","W/m2","J/m2","m/s","m/s","mm/6h","g/g","Pa")
nvar=length(var)

for (v in 1:nvar)
{
print(v)
storage=c()


for (year in 1901:2015)
{
#print(year)

f=open.ncdf(paste0(dirin,"cruncepv7_",var[v],"_",year,".nc"))
tmp=get.var.ncdf(f,nomvar[v],start=c(x,y,1),count=c(1,1,-1))
storage=c(storage,tmp)
}

print(length(storage))
write.table(storage,paste0(dirout,var[v],"_",ilon,"_",ilat,"_1901_2015.txt"),quote=F,col.names=list(paste0(var[v],"_",unit[v])))
}


EOF

# Execute
R CMD BATCH input.R output.R
cat output.R
exit
 



# Extract variables from 1901 to 2015 
# check nco & cdo commands
#ncrcat -h cruncepv7_rain_*.nc /home/orchidee04/joetzjer/FRC/TROLL/test.nc
#ncks -v X, -d lon, XX, -d lat,YY in.nc out.nc 









