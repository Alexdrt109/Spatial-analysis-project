######## mapas instalar paquetes 
install.packages("pacman")
library(pacman)
install.packages("raster","rgdal", "rgeos", "tidyverse", "stringr", "sf", "ggplot2", 
                 "maptools", "ggmap", "RColorBrewer")
pacman::p_load(raster,rgdal, rgeos, tidyverse, stringr, sf, ggplot2, maptools, ggmap, RColorBrewer)
getwd()
setwd("C:/Users/DELL/OneDrive/Escritorio/Proyec CUN/Proyecto Cundinamarca/Scrip modelo")

#rm (list = ls ()) ###limpiar datos anteriores

# cargar shape file 

muni <- readShapePoly("MGN_MPIO_POLITICO.shp")
plot (muni)
View(prue@data)
View (muni@data)
## quitar departamentos para trabajr con cun y bog
prue <- muni
prue2 <- prue[prue$DPTO_CCDGO == c(25),]
prueB <- prue[prue$DPTO_CCDGO == c(11),]

mp <- rbind(prue2,prueB)
# prolemas con municipio de ubala
mp <- mp[mp$MPIO_CCDGO != 839, ]
uba <- prue2[prue2$MPIO_CCDGO == 839,]
uba2 <- uba[1,]
view(uba2)

mp <- rbind(mp,uba2)

view(prueB@data)
plot(mp)
view(mp@data)


library(spdep)
library(maptools)
library(RColorBrewer)
library(leaflet)
library(dplyr)
library(ggplot2)
library(tmap)
library(tmaptools)
class (mp)
# graficar bonito
leaflet(mp) %>%
  addPolygons(stroke = FALSE, fillOpacity = 0.5, smoothFactor = 0.5) %>%
  addTiles() #adds a map title, the default is OpenStreetMap


# solucionando el probema de los codigos
#mp$cod <- merge(mp$DPTO_CCDGO,mp$MPIO_CCDGO)
cod <- c(1:117)
names (cod) <- "cod"
mpp <- cbind(mp,cod)
View(mpp@data)
names (mpp) <- c("DPTO_CCDGO", "MPIO_CCDGO", "MPIO_CNMBR", "MPIO_CRSLC", "MPIO_NAREA", "MPIO_CCNCT",
                 "MPIO_NANO", "DPTO_CNMBR", "SHAPE_AREA", "SHAPE_LEN", "ORIG_FID","COD")

names (mpp)
View (mpp@data)
# encontrando vecinos 
#mppb <- mpp[mpp$MPIO_CCNCT != c(11001),]

rook.cu <- poly2nb(mpp, row.names = mpp$COD, queen = FALSE)
summary(rook.cu)
plot(mpp, border="black") + 
  plot(rook.cu,  coordinates(mpp),  add=TRUE,  col="red")


## ajustar la base de datos 
setwd("C:/Users/DELL/OneDrive/Escritorio/Proyec CUN/Proyecto Cundinamarca/Scrip modelo")
getwd()
list.files()


library(readxl)
d11 <- read_excel("datos pobla.xlsx", sheet = "2011")
d18 <- read_excel("datos pobla.xlsx", sheet = "2018")
summary (d11)
summary(d18)
#d11 <- d11[d11$COD != c(11001),]
#d18 <- d18[d18$COD != c(11001),]
names (d18)
View (d18)
names (mpp) <- c("DPTO_CCDGO", "MPIO_CCDGO" ,"COD", "MPIO_CRSLC",
                  "MPIO_NAREA" ,"MPIO_CNMBR", "MPIO_NANO", "DPTO_CNMBR" ,
                  "SHAPE_AREA", "SHAPE_LEN",  "ORIG_FID", "COD" )   
names (mpp)
View (mpp@data)
maps18 <- merge(mpp,d18, by = "COD")
View(maps18@data)

names (maps18)
library(spdep)
## calculo indice de Mora
queen.v2 <-  nb2listw(poly2nb(maps18, row.names = maps18$COD, 
                              queen = TRUE),style ="W",zero.policy = TRUE)
summary(queen.v2)
queen.v2$weights[1]

var<-scale(maps18$`% 65 a 69`, center = TRUE, scale = FALSE)
var


var.lag<-lag.listw(queen.v2, var)
var.lag
mor<-lm(var.lag ~ var)
summary(mor)

plot(var.lag ~ var,  pch=20, asp=1, las=1)
abline(mor, lwd=2)
abline(h=mean(var), lt=2)
abline(v=mean(var.lag), lt=2)

plot_mor<-moran.plot(maps18$`% 65 a 69`, listw = queen.v2, xlab="olds", ylab = "Lag.olds", pch=19, labels = FALSE)

moran.test(maps18$`% 65 a 69`, listw = queen.v2,randomisation = FALSE)
moran.test(maps18$`% 65 a 69`, listw = queen.v2,  randomisation = TRUE)

mc<-moran.mc(maps18$`% 65 a 69`, queen.v2, nsim=599)

local.lisa<-localmoran(maps18$`% 65 a 69`, listw = queen.v2, zero.policy= TRUE)
local.lisa

i_moran<-mean(local.lisa[,1])
i_moran
## Índice LISA (índice de moran local)

install.packages("tmap")
library(tmap)
moran.map <- cbind(maps18, local.lisa) #agregamos la variable a la base de datos
tm_shape(moran.map) +
  tm_fill(col = "Ii",
          style = "quantile",
          title = "Local Moran Statistic") 


#### Identificación de Clusters Espaciales
quadrant <- vector(mode="numeric",length=nrow(local.lisa))
old <- maps18$`% 65 a 69` - mean(maps18$`% 65 a 69`)  
m.local <- local.lisa[,1] - mean(local.lisa[,1])  
signif <- 0.1
quadrant[old >0 & m.local>0] <- 4  
quadrant[old <0 & m.local<0] <- 1      
quadrant[old <0 & m.local>0] <- 2
quadrant[old >0 & m.local<0] <- 3
quadrant[local.lisa[,5]>signif] <- 0  

brks <- c(0,1,2,3,4)
colors <- c("white","blue",rgb(0,0,1,alpha=0.4),rgb(1,0,0,alpha=0.4),"red")
plot(maps18,border="lightgray",col=colors[findInterval(quadrant,brks,all.inside=FALSE)])
box()
legend("bottomleft", legend = c("insignificant","low-low","low-high","high-low","high-high"),
       fill=colors,bty="n")

###############
####### 2011 
###############
names (d11)
names (mpp)
maps11 <- merge(mpp,d11, by = "COD")
View(maps11@data)

names (maps11)
library(spdep)
queen.v2 <-  nb2listw(poly2nb(maps11, row.names = maps11$COD, 
                              queen = TRUE),style ="W",zero.policy = TRUE)
summary(queen.v2)
queen.v2$weights[1]

var<-scale(maps11$`% 65 a 69`, center = TRUE, scale = FALSE)
var


var.lag<-lag.listw(queen.v2, var)
var.lag
mor<-lm(var.lag ~ var)
summary(mor)

plot(var.lag ~ var,  pch=20, asp=1, las=1)
abline(mor, lwd=2)
abline(h=mean(var), lt=2)
abline(v=mean(var.lag), lt=2)

plot_mor<-moran.plot(maps11$`% 65 a 69`, listw = queen.v2, xlab="olds",
                     ylab = "Lag.olds", pch=19, labels = FALSE)

moran.test(maps11$`% 65 a 69`, listw = queen.v2,randomisation = FALSE)
moran.test(maps11$`% 65 a 69`, listw = queen.v2,  randomisation = TRUE)

mc<-moran.mc(maps11$`% 65 a 69`, queen.v2, nsim=599)

local.lisa<-localmoran(maps11$`% 65 a 69`, listw = queen.v2, zero.policy= TRUE)
local.lisa

i_moran<-mean(local.lisa[,1])
i_moran
## Índice LISA (índice de moran local)
moran.map <- cbind(maps11, local.lisa) #agregamos la variable a la base de datos
tm_shape(moran.map) +
  tm_fill(col = "Ii",
          style = "quantile",
          title = "Local Moran Statistic") 



#### Identificación de Clusters Espaciales
quadrant <- vector(mode="numeric",length=nrow(local.lisa))
old <- maps11$`% 65 a 69` - mean(maps11$`% 65 a 69`)  
m.local <- local.lisa[,1] - mean(local.lisa[,1])  
signif <- 0.1
quadrant[old >0 & m.local>0] <- 4  
quadrant[old <0 & m.local<0] <- 1      
quadrant[old <0 & m.local>0] <- 2
quadrant[old >0 & m.local<0] <- 3
quadrant[local.lisa[,5]>signif] <- 0  

brks <- c(0,1,2,3,4)
colors <- c("white","blue",rgb(0,0,1,alpha=0.4),rgb(1,0,0,alpha=0.4),"red")
plot(maps11,border="lightgray",col=colors[findInterval(quadrant,brks,all.inside=FALSE)])
box()
legend("bottomleft", legend = c("insignificant","low-low","low-high","high-low","high-high"),
       fill=colors,bty="n")
#################
############

## jugar con los dattos 



##############
# Construir lista de vecinos tipo Queen de poligonos
pr.nb <- poly2nb(mpp,row.names = mpp$COD, queen=TRUE)
#En segundo lugar, la matriz se estandariza y transforma en una lista
# Matriz de ponderaci??n W estandarizada
wqueen <- nb2listw(pr.nb, style="W")
#Para revisar las características de la matriz se aplica el summary
# Características de la Matriz W tipo Queen
summary(wqueen)

#Para poder visualizar las conexiones geográficas identificadas se muestra en la
#siguiente gráfica la red que se construye con los centroides de cada municipio
#con sus vecinos, de acuerdo a la matriz W tipo Queen.
# Grafica con la conexicion espacial
cent <- coordinates(mpp)
plot(mpp, border="grey", lwd=1.5)
plot(pr.nb,cent, add=T, col="darkred")

#Para probar si el empleo y el capital humano tienen dependencia espacial, se
#aplica la prueba de correlación espacial de Moran al logaritmo del empleo y al
#capital humano y su logaritmo. La hipótesis nula es que la correlación sea cero, lo
#cual implica que el indicador que se esta analizando este aleatoriamente
#distribuido en la región de estudio30; contra la hipótesis alternativa de correlación
#espacial diferente de cero. 

# Estadistico de Moran
moran_1865 <- moran.test(maps18$`% 65 a 69`, wqueen,randomisation=TRUE,
                              alternative="two.sided", na.action=na.exclude)
moran_1880 <- moran.test(maps18$`% 80 a 99`, wqueen,randomisation=TRUE,
                         alternative="two.sided", na.action=na.exclude)
moran_1800<- moran.test(maps18$`< 100 *100 mil`, wqueen,randomisation=TRUE,
                          alternative="two.sided", na.action=na.exclude)
#Ver resultados
print(moran_1865)
print(moran_1880)
print(moran_1800)

#El diagrama de dispersión se utiliza para visualizar la correlación entre el
#indicador de interés -por ejemplo la poblacion entre 65 y 79- y el rezago espacial
#multiplicado por el mismo indicador (65 < p < 79)- que se calcula en el coeficiente
#de Moran. Para generar el diagrama de dispersión, se señalan las medias del
#logaritmo del poblacion y de su rezago espacial (65 < p < 79), que divide a los
#municipios en cuatro grupo (cuadrantes) y que se identifican por un movimiento
#contrario a la manecillas del reloj, en: Cuadrante I (Hign-Hign), superior derecho
#del diagrama de dispersión, con municipios que se caracterizan por presentar
#valores numéricos por arriba de la media del indicador y tener vecinos con la
#misma característica (arriba de la media);En el cuadrante II (Low-Hign), superior 
#izquierdo del diagrama de dispersión, se identifican los municipios con indicador con valores 
#por debajo de la media y vecinos con la característica contraria (arriba de la media); 
#El cuadrante III (Low-Low), inferior izquierdo del diagrama, contiene a los municipios con 
#indicador por debajo de la media y vecinos con la misma característica; 
#y, finalmente el cuadrante IV (High-Low) con valores por arriba de la media y vecinos

# Grafica de diagrama de dispersión de Moran
moran.plot(maps18$`% 65 a 69`, wqueen, pch=20)
moran.plot(maps18$`% 80 a 99`, wqueen, pch=20)
moran.plot(maps18$`< 100 *100 mil`, wqueen, pch=20)


############################
## Análisis de correlación espacial local (LISA)

# Mapa de quintiles del logaritmo del 65 a 79

install.packages("RColorBrewer")
library(RColorBrewer)

brks <- round(quantile(maps18$`% 65 a 69`, probs=seq(0,1,0.25)), digits=2)
colours <- brewer.pal(4,"Reds")

plot(maps18, col=colours[findInterval(maps18$`% 65 a 69`, brks, all.inside=TRUE)], axes=F)
legend(x=-87.9, y=25.2, legend=leglabs(brks), fill=colours, bty="n")
invisible(title(main=paste("65 a 79", sep="\n")))
box()

# Mapa de quintiles del logaritmo del 65 a 79

brks <- round(quantile(maps18$`% 80 a 99`, probs=seq(0,1,0.25)), digits=2)
colours <- brewer.pal(4,"Blues")

plot(maps18, col=colours[findInterval(maps18$`% 80 a 99`, brks, all.inside=TRUE)], axes=F)
legend(x=-87.9, y=25.2, legend=leglabs(brks), fill=colours, bty="n")
invisible(title(main=paste("80 a 99", sep="\n")))
box()

# Mapa de quintiles del logaritmo del mas de 100

brks <- round(quantile(maps18$`< 100 *100 mil`, probs=seq(0,1,0.25)), digits=2)
colours <- brewer.pal(4,"Greens")

plot(maps18, col=colours[findInterval(maps18$`< 100 *100 mil`, brks, all.inside=TRUE)], axes=F)
legend(x=-87.9, y=25.2, legend=leglabs(brks), fill=colours, bty="n")
invisible(title(main=paste("Mas de 100", sep="\n")))
box()

#Para evaluar estadísticamente la asociación espacial detectada en los mapas con
#estratos de la variable poblacion mayo se aplica el análisis LISA.

# Valores de referencia z de la distribución t
z <- c(1.65, 1.96)
zc <- c(2.8284, 3.0471)

# Estimación de índice de Moran local (Ii) mejor el anterior metodo
#install.packages("spdep")
#library(spdep)

f.Ii <- localmoran(maps18$`% 65 a 69`, wqueen)
zIi <- f.Ii[,"Z.Ii"] # Asignación de la distribución Z del Ii
mx <- max(zIi)
mn <- min(zIi)
# Mapa de significancia para los z-scores
pal <- c("white", "blue", "red")
update.packages(ask = FALSE)
library(classInt)
z3.Ii <- classIntervals(zIi, n=3, style="fixed", fixedBreaks=c(mn, z, mx))
cols.Ii <- findColours(z3.Ii, pal)
plot(maps18, col=cols.Ii)
brks <- round(z3.Ii$brks,4)
leg <- paste(brks[-4], brks[-1], sep=" - ")
legend(x=-87.9, y=25.2, fill=pal, legend=leg, bty="n")



############################
############################
#############################
#Para estimar este modelo se utiliza primero una estimación OLS
ModeloEmpleo_OLS <- lm(maps18$`% 65 a 69`~ maps18$`Cabecera Municipal`
                       + log(maps18$`2018 - Valor agregado per cápita`) , data=maps18)
summary(ModeloEmpleo_OLS)


#Las pruebas de diagnóstico al modelo se muestran a continuación, donde los
#diferentes estadísticos de prueba contrastan la hipótesis nula de no
#autocorrelación espacial o de proceso aleatorio.
 #Prueba de Moran a residuales del modelo OLS
library(spdep)

I_Moran <- lm.morantest(ModeloEmpleo_OLS,wqueen)
print(I_Moran)

# Pruebas de Multiplicadores de Lagranges


lm.LMtests(ModeloEmpleo_OLS,wqueen,test=c("LMerr","RLMerr","LMlag","RLMlag","SARMA"))


# Estimar el Modelo Rezago Espacial
install.packages("spatialreg")
library(spatialreg)

Modelopobla_lag <- lagsarlm(maps18$`% 65 a 69`~ maps18$`Cabecera Municipal`+ log(maps18$`2018 - Valor agregado per cápita`) , data=maps18,wqueen)
summary(Modelopobla_lag)

# Estimar el modelo de Error Espacial
ModeloEmpleo_err <- errorsarlm(maps18$`% 65 a 69`~ maps18$`Cabecera Municipal` +
                                 log(maps18$`2018 - Valor agregado per cápita`) , data=maps18,wqueen)
summary(ModeloEmpleo_err)

##Estimar modelo SARAR
ModeloEmpleo_sarar <- sacsarlm(maps18$`% 65 a 69`~ maps18$`Cabecera Municipal` +
                                 log(maps18$`2018 - Valor agregado per cápita`) ,
                               data=maps18, wqueen,type="sac")
summary(ModeloEmpleo_sarar)



#Estimar el modelo de Durbin Rezago Espacial
ModeloEmpleo_lag_durbin <- lagsarlm(maps18$`% 65 a 69`~ maps18$`Cabecera Municipal` +
                                      log(maps18$`2018 - Valor agregado per cápita`) ,
                                    data=maps18,wqueen,type="mixed")
summary(ModeloEmpleo_lag_durbin)




##### matriz de correlaciones 
a <- d18

library(dplyr)

a2 <- select(a, -"COD",-"Centros Poblados y Rural Disperso", 
             - "2018 - Participación del valor agregado municipal en el departamental",
             -"2018 - Valor agregado", - "Centros Poblados y Rural Disperso" )
names (a2) <- c ("2018 - VA PC" , "% 65 a 69","% 80 a 99","< 100 *100 mil","Cabecera Municipal")

cor(a2)
round(cor(a2),2)  
library(corrplot)
correlacion<-round(cor(a2), 2)

corrplot(correlacion, method="number", type="upper")

