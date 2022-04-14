---
  title: "Calculation of the Shannon index per hexagon"
  author: Jannes Uhlott @ JKI
  date: 2022-01-06
  output: pdf_document
    # pdf_document: 
      # toc: true
      # toc_depth: 2
---

```{r, first, include=FALSE, warning = FALSE, message = FALSE}
knitr::opts_chunk$set(message = FALSE)
knitr::opts_chunk$set(warning = FALSE)
```

# Beschreibung

The Shannon index provides information on agricultural species diversity ([Wolff et al. 2021](https://doi.org/10.1007/s41742-021-00328-y), [Uthes et al. 2020](https://doi.org/10.1016/j.ecolind.2019.105725). The number and abundance of species are considered. The function **get_diversity_per_hexagon** is used to calculate the Shannon index. In the following, a script for the calculation of the Shannon index with an example data set is presented and the function **get_diversity_per_hexagon** is explained.

After the data import, the hexagon data is overlayed with the polygon data to assign a hexagon to each polygon. This forms the data basis for calculating the area of each polygon with the **get_polygon_area** function. After calculating the Shannon index for each hexagon with **get_diversity_per_hexagon**, the values are exported as a shape file together with the geometry of the hexagons.    


## Packages  
``` {r, packages, warning = FALSE, message = FALSE}
library(sp)
library(sf)
library(units)
library(lwgeom)
library(ggplot2)
library(vegan)
library(tidyverse)
```

## Input

### Working directory

Definition des Arbeitsverzeichnisses und der Quelldatei für die Funktionen.

```{r, working directory, warning = FALSE, message = FALSE, results='hide'}
setwd("~/Daten/BB_segments_2019")
source("~/MonViA_Indikatoren/JU_MonViA/Skripte/Vektor/Functions_Indikatoren.R")
```

```{r, working directory_testen, warning = FALSE, message = FALSE, results='hide', echo=FALSE}
# setwd("~/Daten/BB_segments_2019_Test")
# source("~/MonViA_Indikatoren/JU_MonViA/Skripte/Vektor/Functions_Indikatoren.R")
```

### Daten
Loading the polygon (*shp_data*) and hexagon (*hexagon_data*) data.

```{r, data_testen, warning = FALSE, message = FALSE, results='hide', echo=FALSE}
# Testen
# setwd("~/Daten/BB_segments_2019_Test")
# shp_data <- st_read("~/Daten/BB_segments_2019_Test/BB_segments_2019_BB-Test.shp")
# hexagon_data <- st_read("~/Daten/BB_segments_2019_Test/Hexagone/BB_segments_2019_BB-Test_Hexagone.shp")
```

```{r, data, warning = FALSE, message = FALSE, results='hide'}
setwd("~/Daten/BB_segments_2019")
shp_data <- st_read("./raw/BB_segments_2019_xDhWSLU.shp")
hexagon_data <- st_read("../Hexagon_DE_UTM32/BB/BB_Hexagone.shp")
```

## Transformation and filtering

To intersect the data later, the data must be in the same coordinate reference system. For this purpose, the coordinate reference system of the polygons is transformed into that of the hexagons. In addition, the polygon data are filtered so that only arable crops remain.

```{r, transform_filter, results='hide'}
shp_data <- st_transform(shp_data, crs = st_crs(hexagon_data)) 

shp_filtered <- shp_data %>% 
  filter (shp_data$CM_full_19 != 200 & shp_data$CM_full_19 !=254 )
# 200: Grassland
# 254: other agricultural used area
```

```{r, filter_hauptfruchtarten, results='hide'}
shp_filtered <- shp_filtered %>% 
  filter (CM_full_19 %in% c(4, 5, 10, 11, 12))
# 4: Maize, 5: Winter rape seed, 10: Winter barley, 11: Winter rye, 12: Winter wheat
```

## Intersect

Intersection of the polygon and hexagon data with the **st_intersection** command from the **sf** package
```{r, intersection, results='hide'}
intersected <- st_intersection(shp_filtered, hexagon_data)
```

## Polygon area calculation
Mit der Funktion **get_polygon_area** wird die Fläche jedes Polygons berechnet. 
```{r, polygon_details, results='hide'}
polygon_details <- get_polygon_area(intersected) 
```

## Shannon Index calculation

The **get_diversity_per_hexagon** function is used to get the Shannon index for the *raw_polygon_details* [HexagonID, code, area] input dataset. This contains polygons that must include a hexagonID, a code for classification, and a value for area. Additionally, the hexagon data is needed, which was used to determine the HexagonID of the polygons. The calculation of the Shannon index is based on the package **vegan**.

Der Datensatz *raw_polygon_details* wird nach NAs in der Code-Spalte gefiltert und anhand der HexagonID und den vorhandenen Codes gruppiert. Anschließend wird die Summe der Flächen pro Code gebildet und das Ergebnis als *area_per_code_data* gespeichert. Hieraus kann nun der Shannon-Index H für die Spalte area_pro_code, gruppiert nach der HexagonID, berechnet werden. Das Ergebnis (*diversity_data*) umfasst die HexagonID, den Shannon-Index (H) und die Geometrie der Hexagone. 

```{r, diversity_data, warning = FALSE, message = FALSE}
raw_polygon_details <- data.frame(HexagonID = polygon_details$HexagonID,
                                  code=polygon_details$CM_full_19,
                                  area=polygon_details$area)
diversity_data <- get_diversity_per_hexagon(hexagon_data, raw_polygon_details)
```


## Filter Hexagone

Um vergleichbare Hexagone zu betrachten, werden Hexagone mit einer Fläche kleiner als 0.999 km² gefiltert. Dieses betrifft also die Randhexagone, deren Fläche durch z.B. Landesgrenzen zerschnitten werden.

```{r, hexagon_filter, results='hide'}
hexagon_area <- get_polygon_area(diversity_data)

hexagon_filtered <- hexagon_area %>% 
  filter (hexagon_area$area >= set_units(0.999, "km^2")) %>% 
  mutate(drop_units(.))
```

## Export

Exportieren der zusammengefassten und nach Randhexagonen gefilterten Daten mit Zentroid Mittelwert und gewichtetem Mittelwert.
```{r, meanarea_data_export_test, warning = FALSE, message = FALSE, results='hide', echo=FALSE}
# st_write(hexagon_filtered, "~/Daten/BB_segments_2019_Test/Shannon Index/BB_segments_2019_Test_main_diversity.shp", delete_dsn = TRUE)
```

```{r, meanarea_data_export, warning = FALSE, message = FALSE, results='hide'}
st_write(hexagon_filtered, "~/Daten/BB_segments_2019/Shannon Index/BB_segments_2019_main_diversity.shp", delete_dsn = TRUE)
```

## Plot
```{r, plot, fig.asp=0.8, fig.width=7, warning=FALSE, message=FALSE, echo=FALSE}
diversity <- hexagon_filtered$H
title = "Shannon Index BB"
gg<- ggplot() + 
  geom_sf(data =hexagon_filtered, aes(fill = diversity), linetype = "blank") +
  theme_monvia() + # MonViA-Theme (white background + grey lines)
  scale_fill_distiller(palette = "Blues", direction = 1, na.value="white") +  
  labs(title=title) 
# ggsave(filename = "~/Daten/BB_segments_2019_Test/Shannon Index/BB_segments_2019_Test_Shannon.png", dpi=300, width = 7, height = 4)
ggsave(filename = "~/Daten/BB_segments_2019/Shannon Index/BB_segments_2019_Shannon.png", dpi=300, width = 7, height = 4)
gg
```



# Funktionen

## get_diversity_per_hexagon 
Input: hexagon_data, raw_polygon_details [hexid, code, area]

Do: Calculate Shannon-Index (H) based on area for different codes per hexagon

Output: diversity_data

Packages: vegan, tidyverse

```{r, get_diversity_per_hexagon, warning = FALSE, message = FALSE}
get_diversity_per_hexagon <- function(hexagon_data, raw_polygon_details) {
 
  area_per_code_data <- raw_polygon_details %>% 
    filter(!is.na(code)) %>%  # filter code = NA
    group_by(hexid, code) %>% 
    summarise(area_per_code = sum(area))  # sum up all areas per code per hexagon
  
  diversity_output <- area_per_code_data %>%
    group_by(hexid) %>%
    summarise(H=diversity(area_per_code, "shannon")) 
    # calculation of shannon-index per hexagon
  
  diversity_data <- left_join(x= hexagon_data, y=diversity_output)
  return (diversity_data)
}
```

## get_polygon_area

Input: intersected with hexid, VEG

Do: Calculate area for each polygon

Output: intersected with area for each polygon

Packages: sf, sp, units, lwgeom, tidyverse

```{r, get_polygon_area, warning = FALSE, message = FALSE}
get_polygon_area <- function(intersected) {
  
  ## calculate area for every patch ##
  area <- intersected %>%
    st_geometry(.) %>% 
    st_area(.) 
  
  area <- units::set_units(x = area, value = km^2)
  
  ## add calculations to intersected 
  intersected_polygon_area <- cbind(intersected, area)
  
  return(intersected_polygon_area)
}
```
