barras_apiladas_condicion_o <- function(
  patron_cols = c('H401|^H402|^H403'),
  categorias_col = 'HPROVI. Provincia',
  categorias_lab = 'provincias',
  desde_y_mas = 5,
  valor = 'Sí',
  titulo_grafico = 'Porcentaje de la población de 5 años y más, por tenencia de computadora, laptop, tableta',
  color_hex_v = '#4ac9bf',
  color_hex_resto = '#e1be6a') {
  # Ejemplos:
  # patron_cols = c('H401|^H402|^H403'), #Columnas que comienzan por estas cadenas
  # categorias_col = 'HPROVI. Provincia', #Columna de categorías
  # categorias_lab = 'provincias', #Etiqueta de columna de categorías
  # desde_y_mas = 5, #Edad, en el ejemplo, cinco años o más
  # valor = 'Sí', #Condición: el valor 'Sí' aparece en cualquier columna
  # titulo_grafico = 'Porcentaje de la población de 5 años y más, por tenencia de computadora, laptop, tableta',
  # color_hex_v = '#4ac9bf',
  # color_hex_resto = '#e1be6a'
  library(tidyverse)
  patron_cols <- paste0(patron_cols, collapse = '|')
  resumen <- df %>% 
    { if(!is.null(desde_y_mas)) filter_at(., vars(matches('^H203\\. ')), ~ is.na(.x)|.x >= desde_y_mas) else .} %>% 
    select_at(vars(matches(paste0(c('^Factor_Ponderacion', categorias_col, patron_cols), collapse = '|')))) %>% 
    rename_at(vars(matches('^Factor_Ponderacion')), ~ 'pond') %>% 
    mutate_at(vars(matches(categorias_col)), ~ factor(ifelse(is.na(.x), 'Sin información', as.character(.x)))) %>%
    group_by_at(vars(matches(categorias_col))) %>%
    mutate(n = sum(pond)) %>% 
    filter_at(vars(matches(paste0('^', patron_cols))), any_vars(. == valor)) %>% 
    select_at(vars(!matches(paste0('^', patron_cols)))) %>%
    summarise(!!valor := sum(pond)/mean(n), resto = 1 - (sum(pond)/mean(n))) %>% 
    mutate_at(vars(matches(categorias_col)), ~ fct_reorder(.x, resto, .desc = T)) %>% 
    mutate_at(vars(matches(categorias_col)), ~ forcats::fct_relevel(.x, "Sin información", after = 0)) %>% 
    rename_at(vars(matches(categorias_col)), ~ categorias_lab)
  colores <- c(color_hex_v, color_hex_resto)
  names(colores) <- c(valor, 'resto')
  g <- resumen %>%
    gather(respuesta, pct, -!!enquo(categorias_lab)) %>% 
    rename_at(vars(all_of(categorias_lab)), ~ 'eje_x') %>% 
    ggplot + aes(x = eje_x, y = pct, fill = respuesta) +
    geom_col() +
    geom_text(aes(label = scales::percent(pct, accuracy = 1)), size = 2, position = position_stack(vjust = 0.5)) +
    theme_bw() +
    scale_y_continuous(labels = scales::percent) +
    scale_fill_manual(values = colores) +
    coord_flip() +
    ggtitle(titulo_grafico) +
    theme(plot.title = element_text(hjust = 0.5)) +
    labs(x = categorias_lab, y = 'porcentaje\n(redondeo a entero)')
  l <- list(
    resumen_tibble = resumen,
    resumen_md = resumen %>% mutate_if(is.numeric, ~ scales::percent(., accuracy = 0.1)) %>% knitr::kable(),
    `gráfico` = g
  )
  return(l)
}

