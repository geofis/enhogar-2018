library(foreign)
library(rstudioapi)

setwd(dirname(getActiveDocumentContext()$path))
print(getwd())

d <- read.spss('Personas_ENH18.sav') 
(nom_cols <- attr(d, 'variable.labels'))
df <- as.data.frame(d)
colnames(df) <- nom_cols
df$`H203. ¿Cuántos años cumplidos tiene nombre?` <- as.numeric(as.character(df$`H203. ¿Cuántos años cumplidos tiene nombre?`))
levels(df$`H202. ¿Es (nombre) varón o hembra?`) <- c('Hombre', 'Mujer')

barras_apiladas_condicion_o <- function(
  patron_cols = c('H401|^H402|^H403'),
  categorias = 'provincias',
  desde_y_mas = 5,
  valor = 'Sí',
  titulo_grafico = 'Porcentaje de la población de 5 años y más, por tenencia de computadora, laptop, tableta',
  color_hex_v = '#4ac9bf',
  color_hex_resto = '#e1be6a') {
  # Ejemplos:
  # patron_cols = c('H401|^H402|^H403'), #Columnas que comienzan por estas cadenas
  # categorias = 'provincias', #Nivel de salida de los resúmenes. 'estratos', 'provincias', 'regiones', 'urbano_rural', 'hombre_mujer'
  # desde_y_mas = 5, #Edad, en el ejemplo, cinco años o más
  # valor = 'Sí', #Condición: el valor 'Sí' aparece en cualquier columna
  # titulo_grafico = 'Porcentaje de la población de 5 años y más, por tenencia de computadora, laptop, tableta',
  # color_hex_v = '#4ac9bf',
  # color_hex_resto = '#e1be6a'
  library(tidyverse)
  patron_cols <- paste0(patron_cols, collapse = '|')
  para_reemplazo <- list(
    'estratos' = 'HESTRAT. Estratos Geográficos',
    'provincias' = 'HPROVI. Provincia',
    'regiones' = 'Region. Regiones de planificación',
    'urbano_rural' = 'HZONA. Zona de residencia',
    'hombre_mujer' = '^H202',
    'grupo_socioecon' = '^grupsec'
  )
  categorias_i <- gsubfn::gsubfn(
    pattern = paste(names(para_reemplazo), collapse = "|"),
    replacement = para_reemplazo,
    x = categorias
  )
  resumen <- df %>% 
    { if(!is.null(desde_y_mas)) filter_at(., vars(matches('^H203\\. ')), ~ is.na(.x)|.x >= desde_y_mas) else .} %>% 
    select_at(vars(matches(paste0(c('^Factor_Ponderacion', categorias_i, patron_cols), collapse = '|')))) %>% 
    rename_at(vars(matches('^Factor_Ponderacion')), ~ 'pond') %>% 
    group_by_at(vars(matches(categorias_i))) %>%
    mutate(n = sum(pond)) %>% 
    filter_at(vars(matches(paste0('^', patron_cols))), any_vars(. == valor)) %>% 
    select_at(vars(!matches(paste0('^', patron_cols)))) %>%
    summarise(!!valor := sum(pond)/mean(n), resto = 1 - (sum(pond)/mean(n))) %>% 
    rename_at(vars(matches(categorias_i)), ~ categorias)
  colores <- c(color_hex_v, color_hex_resto)
  names(colores) <- c(valor, 'resto')
  g <- resumen %>%
    gather(respuesta, pct, -!!enquo(categorias)) %>% 
    rename_at(vars(all_of(categorias)), ~ 'eje_x') %>% 
    ggplot + aes(x = eje_x, y = pct, fill = respuesta) +
    geom_col() +
    geom_text(aes(label = scales::percent(pct, accuracy = 1)), size = 2, position = position_stack(vjust = 0.5)) +
    theme_bw() +
    scale_y_continuous(labels = scales::percent) +
    scale_fill_manual(values = colores) +
    coord_flip() +
    ggtitle(titulo_grafico) +
    theme(plot.title = element_text(hjust = 0.5)) +
    labs(x = categorias, y = 'porcentaje\n(redondeo a entero)')
  l <- list(
    resumen_tibble = resumen,
    resumen_md = resumen %>% mutate_if(is.numeric, ~ scales::percent(., accuracy = 0.1)) %>% knitr::kable(),
    `gráfico` = g
  )
  return(l)
}
# Porcentaje de la población de 5 años y más, por tenencia de computadora, laptop, tableta
categorias <- c('provincias', 'regiones', 'estratos', 'urbano_rural', 'hombre_mujer', 'grupo_socioecon')
sapply(
  categorias,
  function(x) {
    ba <- barras_apiladas_condicion_o(
      categorias = x,
      titulo_grafico = 'Porcentaje de la población de 5 años y más, por tenencia de computadora, laptop, tableta')
    jpeg(filename = paste0(x, '_pc_tableta', '.jpg'), width = 1280, height = 1000, res = 150)
    print(ba$`gráfico`)
    dev.off()
  })

# Porcentaje de la población de 5 años y más, por tenencia de celular
titulo_grafico <- 'Porcentaje de la población de 5 años y más, por tenencia de celular'
sapply(
  categorias,
  function(x) {
    ba <- barras_apiladas_condicion_o(
      categorias = x,
      titulo_grafico = 'Porcentaje de la población de 5 años y más, por tenencia de celular',
      patron_cols = '^H406')
    jpeg(filename = paste0(x, '_celular', '.jpg'), width = 1280, height = 1000, res = 150)
    print(ba$`gráfico`)
    dev.off()
  })

# Twitter
# ENHOGAR 2018, TIC. Y pensar que la #raspberrypi usa la misma arquitectura de CPU que los celulares. En fin, que ampliar cobertura de docencia virtual, sin contar con el software libre, yo es que no lo veo
