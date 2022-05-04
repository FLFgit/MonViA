---
  title: "R_Markdown Introduction (Fieldsize)"
  author: Jannes Uhlott @ JKI
  date: 2022-05-04
  output: pdf_document
---

# Introduction

Here we develop our first pdf-file from an R-Markdown(.Rmd)-Script. As an example, we will use test data (vector) from MonViA, which shows a test region in Brandenburg. The segments show the different fields that can be observed in the region. As an example, we calculate the field size for each field. To do this, we import the test data, filter it, perform the calculation, export it and create an overview map.

To create the pdf file, the entire R code is executed once. Therefore, the data source must be available and all required packages must be installed.

We can add new code blocks called "chunk" using the green button in the top bar which will add 3 semicolons and curly brackets and another 3 semicolons. In the curly brackets we will insert our options: the first argument is the language we use (*r*) followed by a chunk name. Note: For export, it is necessary that each chunk has a unique name.

We can use \# to structure our document, e.g.:

# 1. example header

## 2. example header

Please make sure that the file name and the file title does not contain any "Umlaute". For using äöü etc. in text: file -> Save with encoding -> UTF8

## Packages

To create the pdf-document the package tinytex have to be installed. If problems occur, then try: tinytex::install_tinytex(). 

Here we load the necessary packages. As we do not want to have warnings or messages from R in our pdf document, we can hide them with **warning = FALSE, message = FALSE** as chunk options.

```{r, packages, warning = FALSE, message = FALSE}
library(sp)
library(sf)
library(units)
library(ggplot2)
library(tidyverse)
library(tidyr) 
```

## Input

Import the data as *shp_data*. The data show the different crop fields. Here we also hide the warnings and messages as well as the results.

```{r, data_import, warning = FALSE, message = FALSE, results='hide'}
shp_data <- st_read("~/Daten/R-Markdown/BB_segments_2019_BB-Test.shp")
```

# Area Calculation

The calculation of the polygon area is done with the sf package based on the command *st_area* for which the geometry must be present (*st_geometry*). The area is set to the unit km².

```{r, calculation}

polygon_area <- shp_data %>% 
  st_geometry(.) %>% 
  st_area(.) 

polygon_area <- units::set_units(x = polygon_area, value = km^2)

shp_details <- cbind(shp_data, polygon_area)

```

## Table

To check the results, let us output the first lines of the data as a table.

```{r, table}
knitr::kable(shp_details [4:5, 2:4], caption = "shp_details")
```

## Export

Here we export the data in a common way.

```{r, polygon_details, warning = FALSE, message = FALSE, results='hide'}
st_write(shp_details, "~/Daten/R-Markdown/R-Markdown_Feldgroesse.shp", delete_dsn = TRUE)
```

## Plot Fieldsize

To get an overview, we finally want to print the data. We can control the display size in the final document with **fig.asp=0.6, fig.width=7**. (This will not control the picture size of the saved picture. This size must be controlled in the save command). Because we don´t want to print the code for creating the image we can suppress it with **echo=FALSE** as chunk option.

```{r, plot_fieldsize, fig.asp=0.6, fig.width=7, warning=FALSE, message=FALSE, results='hide', echo=FALSE}
shp_details_unitless <- shp_details %>% 
  drop_units(.)

title = "Fieldsize cropland test region BB"
gg<- ggplot() + 
  geom_sf(data = shp_details_unitless, aes(fill = polygon_area), linetype = "blank") + 
  scale_fill_distiller(palette = "GnBu", direction = 1, na.value="white", 
                       labels =scales::unit_format(unit = "km²")) +  
  labs(title = title)
# ggsave(filename = "~/Daten/R-Markdown/R-Markdown_Feldgroesse.png", dpi=300, width = 8, height = 4)
gg
```
