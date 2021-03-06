####### Script to Plot Model vs. Observed Hydrographs and some other fancy spatial things #######
###### Created by Katie Markovich, January 2020 ########

##### install packages (you only have to do this once) #####
# install.packages('dplyr')
# install.packages('data.table')
# install.packages('sf')
# install.packages('openxlsx')
# install.packages('ggplot2')
# install.packages('rnaturalearth')
# install.packages('rgeos')
# install.packages('maps')
# install.packages('maptools')
# install.packages('ggspatial')
# install.packages('lubridate')
# install.packages('rmarkdown')
# install.packages('here')
# install.packages('viridis')
# install.packages('mapview')
# install.packages('USAboundaries')
# install.packages('GSODR')
# install.packages("devtools")
#install.packages('ggthemes')
#install.packages('cowplot')
#install.packages('tinytex')

##### load libraries (do this every time) #####
library(cowplot)
library(devtools)
library(data.table)
library(sf)
library(dplyr)
library(openxlsx)
library(ggplot2)
library(ggthemes)
library("rnaturalearth")
library(rgeos)
library("maps")
library(maptools)
library("ggspatial")
library('rmarkdown')
library(lubridate)
library(here)
library(viridis)
library(mapview)
library(USAboundaries)
library(GSODR)
library(grid)
library(gridExtra)
#devtools::install_github("ropensci/USAboundariesData")
library(USAboundariesData)

##### make map of observation locations #####
world <- ne_countries(scale = "medium", returnclass = "sf")

us <- us_boundaries(type="state", resolution = "low") %>% 
  filter(!state_abbr %in% c("PR", "AK", "HI"))

# get NM/TX boundary with high definition
nmtx <- USAboundaries::us_states(resolution = "high", states = c("NM","TX"))
nmtx_box=st_make_grid(nmtx, n=1)
                  

###read in watershd, stream, observation points
setwd('L:/projects/Mesilla_RG109K5/RGTIHM/Database/GIS_metadata_files/For_ScienceBase/GIS_Files/')
RGTIHM_boundary=st_read('RGTIHM_Geographic_Regions.shp')
obs_locations=st_read('RGTIHM_Surface_Water_Obs.shp')
SFR=st_read('RGTIHM_SFR_Segments.shp')
RGTIHM_box=st_make_grid(RGTIHM_boundary, n=1)

p1 <- ggplot(data=world) + 
  geom_sf()+
  geom_sf(data = nmtx, color = "black", fill = NA, alpha=0.6) +
  geom_sf(data=RGTIHM_box, fill='black', alpha=0.5)+
  coord_sf(xlim = c(-109.5, -93.5), ylim = c(25.5, 37.5), expand = FALSE)+
  theme(axis.text.x = element_blank(),
        axis.text.y = element_blank(),
        axis.ticks = element_blank(),
        panel.background = element_rect(fill = "aliceblue"))

p2=ggplot(data = world) +
  geom_sf() +
  geom_sf(data = nmtx) + 
  geom_sf(data=RGTIHM_boundary, aes(fill=Subregion), alpha=0.2)+
  geom_sf(data=obs_locations)+
  coord_sf(xlim = c(-107.6, -106.4), ylim = c(31.5, 33), expand = FALSE)+
  xlab("Longitude") + ylab("Latitude") +
  annotation_scale(location = "bl", width_hint = 0.4) +
  annotation_north_arrow(location = "bl", which_north = "true", 
                         pad_x = unit(0.5, "in"), pad_y = unit(0.3, "in"),
                         style = north_arrow_fancy_orienteering)+
  ggtitle("SW Observation Sites", subtitle = "(160 Sites in the RGTIHM Model Boundary)") +
  theme(panel.grid.major = element_line(color = gray(0.5), linetype = "dashed", 
                                        size = 0.5), panel.background = element_rect(fill = "aliceblue"))

p2+
  annotation_custom(grob=ggplotGrob(p1),
                    xmin = -106.9,
                      xmax = -106.4,
                      ymin = 32.5,
                      ymax = 33.15)


##### read in model output #####



#our shiniest and best RGTIHM model yet
for (i in 1:159){
new_mod=read.table('L:/projects/Mesilla_RG109K5/RGTIHM/Model_Versions/RGTIHM_TXCIR/TR_C_2_loose_newEXE/output/hyd_RGTIHM.otf', nrows = 1)
new_mod=new_mod[1,2:198]
names(new_mod) <- lapply(new_mod[1, ], as.character)
new_mod <- new_mod[-1,] 
new_mod_temp=read.table('L:/projects/Mesilla_RG109K5/RGTIHM/Model_Versions/RGTIHM_TXCIR/TR_C_2_loose_newEXE/output/hyd_RGTIHM.otf', skip = 1, stringsAsFactors = FALSE)
new_mod_temp=as.matrix(new_mod_temp)
new_mod[1:1797,]=new_mod_temp
new_mod=as.matrix(new_mod)
new_mod[1:1797,]=new_mod_temp
new_mod=as.data.frame(new_mod)
new_mod=apply(new_mod, 2, as.numeric)
new_mod=as.data.frame(new_mod)
 
#the RGTIHM model discussed in the OFR 
old_mod=read.table('L:/projects/Mesilla_RG109K5/RGTIHM/Model_Versions/Revised_Release_09242018/NMWSC_Review/RGTIHM/output/hyd_RGTIHM.otf', nrows = 1, stringsAsFactors = FALSE)
old_mod=old_mod[1,2:198]
names(old_mod) <- lapply(old_mod[1, ], as.character)
old_mod <- old_mod[-1,] 
old_mod_temp=read.table('L:/projects/Mesilla_RG109K5/RGTIHM/Model_Versions/Revised_Release_09242018/NMWSC_Review/RGTIHM/output/hyd_RGTIHM.otf', skip = 1, stringsAsFactors = FALSE)
old_mod_temp=as.matrix(old_mod_temp)
old_mod[1:1797,]=old_mod_temp
old_mod=as.matrix(old_mod)
old_mod[1:1797,]=old_mod_temp
old_mod=apply(old_mod, 2, as.numeric)
old_mod=as.data.frame(old_mod)

#observational data
obs_data=read.csv('L:/projects/Mesilla_RG109K5/RGTIHM/Database/Time_series_metadata_files/v2/RGTIHM_Surface-Water_Flow_Observations.csv', check.names = FALSE, stringsAsFactors = FALSE)
#need to reformat the date
dates=dmy(obs_data$Date)
obs_data$Date=decimal_date(dates)
obs_data=as.data.frame(obs_data)
site_names=gsub("[()]", " ", colnames(obs_data))
colnames(obs_data)=site_names

#fix parentheses in shapefile of obs
obs_locations=st_read('L:/projects/Mesilla_RG109K5/RGTIHM/Database/GIS_metadata_files/For_ScienceBase/GIS_Files/RGTIHM_Surface_Water_Obs.shp')
obs_location_names=gsub("[()]", " ", obs_locations$Site_Name)
obs_locations$Site_Name=obs_location_names
obs_locations=obs_locations[-c(45),] #### delete the Rio Grande at Tonuco/Hayner bridge because model results don't have it

  value=obs_locations[i,2]
  title=obs_locations[i,1]
  col=grep(value$Obs_ID, colnames(new_mod))
  col2=grep(paste("^",title$Site_Name,"$", sep=""), colnames(obs_data), useBytes = TRUE)
  point=obs_locations[i,]
  
  # new_mod[,col]=as.numeric(new_mod[,col])
  # new_mod[,1]=as.numeric(levels(new_mod[,1]))
  # new_mod[,1]=format(date_decimal(new_mod[,1]), "%Y-%m-%d")
  # new_mod[,1]=as.Date(new_mod[,1])
  # 
  # old_mod[,col]=as.numeric(old_mod[,col])
  # old_mod[,1]=as.numeric(levels(old_mod[,1]))
  # old_mod[,1]=format(date_decimal(old_mod[,1]), "%Y-%m-%d")
  # old_mod[,1]=as.Date(old_mod[,1])
  # 
  # obs_data$Date=format(date_decimal(obs_data$Date), "%Y-%m-%d")
  # obs_data$Date=as.Date(obs_data$Date)
  
  # plot(x=old_mod[,1], y=old_mod[,col], type='l', col='blue', main=title$Site_Name, ylab=c('Streamflow (cubic feet per day)'), xlab=c('Time'))
  #   lines(x=new_mod[,1], y=new_mod[,col], type='l', lty='dashed', col='red')
  #   points(x=obs_data$Date, y=obs_data[,col2], cex=.9, col='black', pch=19)
    
    
    
    p=ggplot(data=old_mod,aes(y=old_mod[,col], x=old_mod[,1], group=1, colour='blue'))+
    geom_line()+
    geom_line(data=new_mod, aes(y=new_mod[,col], x=new_mod[,1], colour='red'), linetype='dashed')
    
    p=p+geom_point(data=obs_data, aes(x=obs_data$Date, y=(obs_data[,col2]),colour='black'))+
    ggtitle(title$Site_Name)+ylab('Streamflow (cfs)')+xlab('Time')+theme_bw()+scale_y_log10()+
    scale_colour_manual(values=c("black", 'blue', 'red'), labels=c("Observations", "Old RGTIHM", "New RGTIHM"))+
    theme(legend.title=element_blank(), legend.position = "bottom")
 
  p3=ggplot(data = world) +
    geom_sf() +
    geom_sf(data = nmtx) + 
    geom_sf(data=RGTIHM_boundary, aes(fill=Subregion), alpha=0.2)+
    geom_sf(data=obs_locations, size=1)+
    geom_sf(data=point, size=3, col='red')+
    coord_sf(xlim = c(-107.6, -106.4), ylim = c(31.5, 33), expand = FALSE)+
    theme(legend.position = "none")+
    theme(plot.margin = unit(c(1,0,1,0), "in"))+
    theme(axis.text.x = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks = element_blank(),
          panel.background = element_rect(fill = "aliceblue", colour='black', size=2))  
 
 multiplot <- function(..., plotlist=NULL, file, cols=1, layout=NULL) {
   library(grid)
   
   # Make a list from the ... arguments and plotlist
   plots <- c(list(...), plotlist)
   
   numPlots = length(plots)
   
   # If layout is NULL, then use 'cols' to determine layout
   if (is.null(layout)) {
     # Make the panel
     # ncol: Number of columns of plots
     # nrow: Number of rows needed, calculated from # of cols
     layout <- matrix(seq(1, cols * ceiling(numPlots/cols)),
                      ncol = cols, nrow = ceiling(numPlots/cols))
   }
   
   if (numPlots==1) {
     print(plots[[1]])
     
   } else {
     # Set up the page
     grid.newpage()
     pushViewport(viewport(layout = grid.layout(nrow(layout), ncol(layout))))
     
     # Make each plot, in the correct location
     for (i in 1:numPlots) {
       # Get the i,j matrix positions of the regions that contain this subplot
       matchidx <- as.data.frame(which(layout == i, arr.ind = TRUE))
       
       print(plots[[i]], vp = viewport(layout.pos.row = matchidx$row,
                                       layout.pos.col = matchidx$col))
     }
   }
 }
 
 multiplot(cols=2, p,p3)
 
 
  }
    


  

  

