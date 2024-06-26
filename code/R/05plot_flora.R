#!/usr/bin/env Rscript

source("code/R/07process_map_layers.R")

species <- f_species("coord_plantae.tsv") |>
  filter(category != "Especie protegida")

system("python code/python/03_count_pne_species.py")
species_pne <- read_csv("data/temp_species.csv")
protected_species_pne <- read_csv("data/protected_species/temp_protected_species.csv")
all_species_pne <- rbind(species_pne, protected_species_pne)

enp_map <- enp_map |> 
  left_join(all_species_pne, by = "codigo") |>
  mutate(category = str_replace_all(tolower(category), pattern = " ", replacement = "_")) |>
  pivot_wider(names_from = "category", values_from = n) |> 
  select(-"NA") |>  
  mutate(across(everything(), ~replace_na(., 0)),
         total_species = especie_nativa + especie_protegida + especie_introducida + especie_traslocada) 


pal_species <- colorFactor(
  palette = c("#ff0000", "#59ff00", "#ffae00"),
  domain = species$category
)

bins <- c(1, 2, 4, 6, Inf)
pal_protected_especies <- colorBin("YlOrRd", domain = protected_species$n, bins = bins)

sd <- SharedData$new(data = species)

map <- leaflet() |>
  setView(-15.6, 27.95, zoom = 10) |>
  addTiles() |>
  addPolygons(
    data = enp_map, 
    fillColor = ~pal_pne(categoria), 
    color = "transparent",
    weight = 0, fillOpacity = .5,
    dashArray = "3",
    highlightOptions = highlightOptions(weight = 5, 
                                        color = "#666", 
                                        fillOpacity = .7,
                                        dashArray = "", 
                                        bringToFront = FALSE),
    popup =  paste0(
      "<strong>ENP</strong>: ", 
      enp_map$codigo, " ", 
      glue("<u>{enp_map$nombre}</u>"), 
      "<br>", 
      "<strong>Categoría</strong>: ", 
      enp_map$categoria,
      glue("<br><a href={url_pne_info}{enp_map$info}>Información del espacio</a>"),
      "<br>---<br><strong><u>Nº de especies observadas en el ENP:</u></strong>",
      glue("<br><strong><span style='color: #15d600'>Nativas</span></strong> = {enp_map$especie_nativa}, <strong><span style='color: blue'>Protegidas</span></strong> = {enp_map$especie_protegida}"), 
      glue("<br><strong><span style='color: #ff0000'>Introducidas</span></strong> = {enp_map$especie_introducida}, <strong><span style='color: #ffae00'>Traslocadas<span></strong> = {enp_map$especie_traslocada}"),
      glue("<br><strong>Total de especies observadas</strong> = <u>{enp_map$total_species}</u>")
      ) |> 
        lapply(htmltools::HTML),
    popupOptions = labelOptions(
      style = list("font-weight" = "normal",
                   padding = "3px 8px"),
      textsize = "15px",
      direction = "auto"
    ),
    group = "Espacios Naturales<br>Protegidos") |>
  addPolygons(data = zec_map,  
              fillColor = "#4ce600",
              color = "transparent",
              dashArray = "3",
              highlightOptions = highlightOptions(weight = 5,
                                                  color = "#666",
                                                  fillOpacity = .7,
                                                  dashArray = "",
                                                  bringToFront = FALSE),              
              label = paste0("<strong>Código:</strong> ", zec_map$cod_zec, 
                             "<br>", 
                             "<strong>Nombre de la ZEC:</strong> ", 
                             glue("<u>{zec_map$nom_zec}</u>")) |> 
                lapply(htmltools::HTML),
              labelOptions = labelOptions(
                style = list("font-weight" = "normal",
                             padding = "3px 8px"),
                textsize = "15px",
                direction = "auto"
              ),              
              weight = 0, fillOpacity = .5,
              group = "Red Natura 2000") |>
  addPolygons(data = protected_species,
              fillColor = ~pal_protected_especies(n),
              color = "transparent",
              dashArray = "3",
              popup = paste0("<p style='text-align:left;'>",
                             "###=================================###",
                             "<br>### <strong>ESPECIES PROTEGIUDAS DEL LUGAR</strong> ###", 
                             "<br>###=================================###", 
                             glue("<br>==> <strong>Número de especies protegidas en total: <u>{protected_species$n}</u></strong>"),
                             glue("<br>> {protected_species$species}"),
                             "</p>") |> 
                lapply(htmltools::HTML),
              popupOptions = labelOptions(
                style = list("font-weight" = "normal",
                             padding = "3px 8px"),
                textsize = "10px",
                direction = "auto"
              ),              
              highlightOptions = highlightOptions(weight = 5,
                                                  color = "#666",
                                                  fillOpacity = .7,
                                                  dashArray = "",
                                                  bringToFront = FALSE),
              weight = 0, fillOpacity = .9,
              group = "Especies Protegidas") |>
  addPolygons(data = jardin_botanico, 
              fillColor = "yellow", fillOpacity = .5, weight = 1) |>
  addCircleMarkers(data = sd, 
                   lat = ~latitude, lng = ~longitude,
                   popup = paste0(#glue("<img src='{species$sourcefile}'/>"),
                                  "<p style='text-align:left;'>", 
                                  "<strong>Identificador (ID):</strong> ", species$id,
                                  glue("<br><a href={url_biota}{species$id_biota}><strong>Biota:</strong> {species$id_biota}</a>"), 
                                  "<br>=========================",  
                                  "<br><strong>División:</strong> ", species$division,
                                  "<br><strong>Clase:</strong> ", species$class,
                                  "<br><strong>Orden:</strong> ", species$order,
                                  "<br><strong>Familia:</strong> ", species$family,
                                  "<br><strong>Especie:</strong> ", glue("<i>{species$specie}</i>"), " ", species$author,
                                  "<br><strong>Nomb. común:</strong> ", species$name,
                                  "<br>=========================",
                                  "<br><strong>Género Endémico</strong>: ", species$endemic_genus, 
                                  "<br><strong>Especie Endémica:</strong> ", species$endemic_specie,
                                  "<br><strong>Subespecie Endémica:</strong> ", species$endemic_subspecie,
                                  "<br><strong>Origen:</strong> ", species$origin,
                                  "<br>=========================",
                                  "<br><strong>Fecha:</strong> ", species$gpsdatetime,
                                  "<br>=========================",
                                  "</p>") |> lapply(htmltools::HTML), 
                   label = glue("<i>{species$specie}</i><br>({species$name})") |> lapply(htmltools::HTML), 
                   labelOptions = labelOptions(textsize = 11),
                   fillOpacity = 1, 
                   fillColor = ~pal_species(category), weight = .3, # fillColor = ~pal_species(class)  
                   radius = 8,
                   group = "Especies") |>
  addLegend(data = protected_species, 
            "bottomright", 
            pal = pal_protected_especies,
            values = ~n, 
            title = "<strong>Especies protegidas</strong>", 
            opacity=1, 
            group = "Leyenda especies<br>protegidas") |>
  addLegend(data = species, "bottomright", pal = pal_species,
            values = ~category, title = "<strong>Especies NO protegidas</strong>", 
            opacity=1, group = "Leyenda Especies") |> 
  addLayersControl(baseGroups = c("SIN CAPA", 
                                  "Espacios Naturales<br>Protegidos", 
                                  "Red Natura 2000", 
                                  "Especies Protegidas"), 
                   overlayGroups = c("Especies", "Leyenda Especies", 
                                     "Leyenda especies<br>protegidas"),
                   options = layersControlOptions(collapsed = T, autoZIndex = TRUE))  |>
  addResetMapButton() |>
  addScaleBar("bottomleft", scaleBarOptions(metric = TRUE, imperial = FALSE)) |>
  htmlwidgets::onRender("
    function(el, x) {
      this.on('baselayerchange', function(e) {
        e.layer.bringToBack();
      });

      var css = '.info.legend.leaflet-control { text-align: left; }';
      var head = document.head || document.getElementsByTagName('head')[0];
      var style = document.createElement('style');
      style.type = 'text/css';
      if (style.styleSheet) {
        style.styleSheet.cssText = css;
      } else {
        style.appendChild(document.createTextNode(css));
      }
      head.appendChild(style);
    }
  ") 

