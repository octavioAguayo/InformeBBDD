# CreaBBDD_Excel_Coyuntural.R - v6 - 22-08-2026
# Lee el libro coyuntural del INE: solo el trimestre actual, con más
# desagregación que las series.

if (!exists("fc_init_motor"))
  source(file.path(dirname(getwd()), "Bibliotecas_R", "funciones_pipeline.R"))

fc_init_motor(c("readxl", "dplyr", "tidyr", "lubridate", "stringr", "openxlsx"))

# Trim_Actual: si ya existe en el entorno (p. ej. lo fijó CreaBBDD_Master_Excel.R
# al sourcear este script), se HEREDA. En corrida suelta se DEDUCE del
# directorio: la carpeta AAAAMM más reciente de Datos_Ine/Exceles. Antes había un
# literal hardcodeado, y los cuatro archivos del pipeline llegaron a tener tres
# valores distintos ("202604" acá, "202605" en Coyuntural y en Master_Excel) sin
# que nada lo advirtiera: el script corría con un trimestre viejo en silencio.
if (!exists("Trim_Actual") || is.null(Trim_Actual)) {
  .raiz_excel <- file.path(dirname(dirname(getwd())), "Datos_Ine", "Exceles")
  .periodos <- grep("^[0-9]{6}$", basename(list.dirs(.raiz_excel, recursive = FALSE)),
                    value = TRUE)
  if (!length(.periodos))
    stop("[Excel/Coyuntural] No hay carpetas AAAAMM en ", .raiz_excel,
         ". Define Trim_Actual manualmente.", call. = FALSE)
  Trim_Actual <- max(.periodos)
  rm(.raiz_excel, .periodos)
}
if (!grepl("^[0-9]{6}$", Trim_Actual))
  stop("[Excel/Coyuntural] Trim_Actual debe ser AAAAMM de 6 dígitos. Valor: ", Trim_Actual)
message("[Excel/Coyuntural] Trim_Actual = ", Trim_Actual)

dire_coy <- file.path(dirname(dirname(getwd())), "Datos_Ine", "Exceles", Trim_Actual, "trimestre_movil")
dire_out <- file.path(dirname(dirname(getwd())), "Datos_Ine", "ENE", "bbdd_minuta")
if (!dir.exists(dire_out)) {
  dir.create(dire_out, recursive = TRUE)
}

# Tabla de nombres de región largos → cortos
tabla_regiones <- tibble::tibble(
  larga = c(
    "Región de Arica y Parinacota","Región de Tarapacá","Región de Antofagasta",
    "Región de Atacama","Región de Coquimbo","Región de Valparaíso",
    "Región Metropolitana de Santiago",
    "Región del Libertador General Bernardo O'Higgins",
    "Región del Maule","Región del Ñuble","Región del Biobío",
    "Región de La Araucanía","Región de Los Ríos","Región de Los Lagos",
    "Región de Aysén del General Carlos Ibáñez del Campo",
    "Región de Magallanes y de la Antártica Chilena",
    "Total nacional"
  ),
  corta = c(
    "Arica y Parinacota","Tarapacá","Antofagasta","Atacama","Coquimbo",
    "Valparaíso","Metropolitana","O'Higgins","Maule","Ñuble","Biobío",
    "La Araucanía","Los Ríos","Los Lagos","Aysén","Magallanes",
    "Total nacional"
  )
)

# ______________________________________________________________________________
# FUNCIÓN DE LECTURA — mismo patrón que leer_serie en CreaBBDD_Series.R ####
# Lee un excel coyuntural (filas = región o tramo edad, hojas = sexo)
# y devuelve tabla larga con fecha × sexo × region_label × categoria × valor
# ______________________________________________________________________________

# fc_unidades: la fila 1 del bloque de datos declara la unidad de cada columna
# ("en miles", "tasa (%)", "en horas"). Se usa para convertir a unidad final al
# momento de leer, en vez de reescalar después contra una lista de excepciones.
fc_unidades <- function(tabla, columnas_excel, nombres_col) {
  u <- as.character(unlist(tabla[1, columnas_excel]))
  setNames(u, nombres_col)
}

leer_coyuntural <- function(archivo, hojas, filas_excel, columnas_excel,
                            nombres_col) {
  unidades <- NULL
  lapply(hojas, function(hoja) {
    tabla <- read_excel(archivo, sheet = hoja, skip = 5, .name_repair = "minimal")
    if (is.null(unidades)) unidades <<- fc_unidades(tabla, columnas_excel, nombres_col)
    tabla <- tabla[filas_excel, columnas_excel]
    names(tabla) <- nombres_col
    tabla %>%
      mutate(
        sexo  = toupper(hoja),
        fecha = as.Date(paste0(Trim_Actual, "01"), "%Y%m%d")
      )
  }) %>%
    bind_rows() %>%
    pivot_longer(
      cols      = -c(region_label, sexo, fecha),
      names_to  = "categoria",
      values_to = "valor"
    ) %>%
    mutate(
      valor = suppressWarnings(as.numeric(
        str_replace_all(as.character(valor), "[^0-9.,-]", "")
      )),
      # ×1000 solo donde el Excel declara "en miles". Tasas y horas se toman
      # como vienen. Los ENE_* ya están en unidades finales y no pasan por acá.
      valor = if_else(grepl("miles", unidades[categoria], fixed = TRUE),
                      round(valor * 1000, 0), round(valor, 1))
    ) %>%
    left_join(tabla_regiones, by = c("region_label" = "larga")) %>%
    mutate(region_label = coalesce(corta, region_label)) %>%
    select(-corta) %>%
    filter(!is.na(valor)) %>%
    select(fecha, sexo, region_label, categoria, valor)
}

hojas_coy <- c("as", "m", "h")

# ______________________________________________________________________________
# 2.1 Sector Económico × Región ####
# ______________________________________________________________________________

ramas <- c(
  "Agricultura, ganadería, silvicultura y pesca",
  "Explotación de minas y canteras",
  "Industrias manufactureras",
  "Suministro de electricidad, gas, vapor y aire acondicionado",
  "Suministro de agua", "Construcción",
  "Comercio al por mayor y al por menor",
  "Transporte y almacenamiento",
  "Actividades de alojamiento y de servicio de comidas",
  "Información y comunicaciones",
  "Actividades financieras y de seguros",
  "Actividades inmobiliarias",
  "Actividades profesionales, científicas y técnicas",
  "Actividades de servicios administrativos y de apoyo",
  "Administración pública y defensa", "Enseñanza",
  "Actividades de atención de la salud humana y de asistencia social",
  "Actividades artísticas, de entretenimiento y recreativas",
  "Otras actividades de servicios",
  "Actividades de los hogares como empleadores",
  "Actividades de organizaciones y órganos extraterritoriales"
)

dt_coy_rama <- leer_coyuntural(
  archivo        = paste0(dire_coy, "/coyuntural_rama.xlsx"),
  hojas          = hojas_coy,
  filas_excel    = 2:18,
  columnas_excel = c(1, 4:24),
  nombres_col    = c("region_label", paste0(ramas, "_b14"))
)

# ______________________________________________________________________________
# 2.2 Categoría Ocupacional × Región ####
# ______________________________________________________________________________

dt_coy_categoria <- leer_coyuntural(
  archivo        = paste0(dire_coy, "/coyuntural_categoria.xlsx"),
  hojas          = hojas_coy,
  filas_excel    = 2:18,
  columnas_excel = c(1, 4:9),
  nombres_col    = c("region_label",
                     "Empleadores","Cuenta propia","Asalariados privados",
                     "Asalariados públicos","Servicio doméstico","Familiares no remunerados")
)

# ______________________________________________________________________________
# 2.4.1 Mercado Laboral y FFT × Región ####
# ______________________________________________________________________________

dt_coy_sft <- leer_coyuntural(
  archivo        = paste0(dire_coy, "/coyuntural_sft.xlsx"),
  hojas          = hojas_coy,
  filas_excel    = 2:18,
  columnas_excel = c(1, 3:10, 12:13),
  nombres_col    = c("region_label",
                     "Población","Población en edad de trabajar","Fuerza de trabajo","Ocupados","Desocupados","Cesantes",
                     "Buscan trabajo por primera vez","Fuera de la fuerza de trabajo",
                     "Fuera de la fuerza de trabajo potencialmente activos","Fuera de la fuerza de trabajo habituales")
)

# ______________________________________________________________________________
# 2.4.2 Ocupados y FFT Ampliada × Región ####
# ______________________________________________________________________________

dt_coy_sft_desag <- leer_coyuntural(
  archivo        = paste0(dire_coy, "/coyuntural_sft_desagregado.xlsx"),
  hojas          = hojas_coy,
  filas_excel    = 2:18,
  columnas_excel = c(1, 7:13, 18:28),
  nombres_col    = c("region_label",
                     "Ocupados presentes",
                     "Ocupados presentes tradicionales",
                     "Ocupados presentes no tradicionales",
                     "Ocupados ausentes",
                     "Ocupados ausentes con vínculo efectivo",
                     "Ocupados ausentes con pronto retorno",
                     "Ocupados ausentes con sueldo o ganancias",
                     "Fuera de la fuerza de trabajo iniciadores",
                     "Fuera de la fuerza de trabajo por razones familiares permanentes",
                     "Fuera de la fuerza de trabajo por estudio",
                     "Fuera de la fuerza de trabajo por jubilación",
                     "Fuera de la fuerza de trabajo por pensión o montepío",
                     "Fuera de la fuerza de trabajo por razones de salud permanentes",
                     "Fuera de la fuerza de trabajo por razones personales temporales",
                     "Fuera de la fuerza de trabajo sin deseos de trabajar",
                     "Fuera de la fuerza de trabajo por razones estacionales",
                     "Fuera de la fuerza de trabajo por desaliento",
                     "Fuera de la fuerza de trabajo por otras razones")
)

# ______________________________________________________________________________
# 2.3 Mercado Laboral × Edad — solo Nacional, variables con nombre compuesto ####
# Formato: "Población en edad de trabajar 15 a 19 años", "Ocupados 35 a 39 años"
# ______________________________________________________________________________

vars_edad <- c(
  "Población en edad de trabajar","Fuerza de trabajo","Ocupados",
  "Ocupados formal","Ocupados informal",
  "Desocupados","Cesantes","Buscan trabajo por primera vez",
  "Fuera de la fuerza de trabajo","Fuera de la fuerza de trabajo iniciadores",
  "Fuera de la fuerza de trabajo potencialmente activos",
  "Fuera de la fuerza de trabajo habituales",
  "Tasa de desocupación","Tasa de ocupación",
  "Tasa de participación","Tasa de ocupación informal"
)
# vars_tasa_edad se elimina: la unidad de cada columna se lee de la fila que el
# propio Excel declara ("en miles" / "tasa (%)"). Era la segunda lista que debía
# coincidir con la primera y no lo hacía — listaba los nombres viejos (T_*), de
# modo que el if_else nunca era verdadero y las 4 tasas se multiplicaban ×1000.

unidades_edad <- NULL

dt_coy_edad_raw <- lapply(hojas_coy, function(hoja) {
  tabla <- read_excel(
    paste0(dire_coy, "/coyuntural_sft_edad.xlsx"),
    sheet = hoja, skip = 5, .name_repair = "minimal"
  )
  if (is.null(unidades_edad))
    unidades_edad <<- setNames(as.character(unlist(tabla[1, 3:18])), vars_edad)
  tabla <- tabla[2:14, c(1, 3:18)]
  names(tabla) <- c("tramo_edad", vars_edad)
  tabla %>%
    filter(!tramo_edad %in% c("Total nacional", "Total")) %>%
    mutate(
      sexo  = toupper(hoja),
      fecha = as.Date(paste0(Trim_Actual, "01"), "%Y%m%d")
    )
}) %>%
  bind_rows() %>%
  pivot_longer(
    cols      = all_of(vars_edad),
    names_to  = "variable_base",
    values_to = "valor"
  ) %>%
  mutate(
    valor = suppressWarnings(as.numeric(
      str_replace_all(as.character(valor), "[^0-9.,-]", "")
    )),
    # ×1000 solo donde el Excel declara "en miles"; las tasas se toman como vienen
    valor = if_else(
      grepl("miles", unidades_edad[variable_base], fixed = TRUE),
      round(valor * 1000, 0),
      round(valor, 1)
    ),
    # Composición canónica: espacio simple. "Población en edad de trabajar 15 a 19 años"
    categoria    = paste(variable_base, tramo_edad),
    region_label = "Total nacional"
  ) %>%
  filter(!is.na(valor)) %>%
  select(fecha, sexo, region_label, categoria, valor)

# ______________________________________________________________________________
# INTEGRACIÓN FINAL ####
# ______________________________________________________________________________

dt_Coyuntural <- bind_rows(
  dt_coy_rama,
  dt_coy_categoria,
  dt_coy_sft,
  dt_coy_sft_desag,
  dt_coy_edad_raw
) %>%
  mutate(
    sexo       = toupper(sexo),
    sexo_label = factor(sexo,
                        levels = c("H", "M", "AS"),
                        labels = c("Hombres", "Mujeres", "Ambos sexos")),
    region = case_when(
      region_label == "Total nacional"      ~  "TT",
      region_label == "Arica y Parinacota"  ~  "AP",
      region_label == "Tarapacá"            ~  "TA",
      region_label == "Antofagasta"         ~  "AN",
      region_label == "Atacama"             ~  "AT",
      region_label == "Coquimbo"            ~  "CO",
      region_label == "Valparaíso"          ~  "VA",
      region_label == "O'Higgins"           ~  "LI",
      region_label == "Maule"               ~  "ML",
      region_label == "Ñuble"               ~  "NB",
      region_label == "Biobío"              ~  "BI",
      region_label == "La Araucanía"        ~  "AR",
      region_label == "Los Ríos"            ~  "LR",
      region_label == "Los Lagos"           ~  "LL",
      region_label == "Aysén"               ~  "AI",
      region_label == "Magallanes"          ~  "MA",
      region_label == "Metropolitana"       ~  "RM"
    )
  ) %>%
  mutate(periodo = as.numeric(Trim_Actual)) %>%
  select(periodo, fecha, sexo, sexo_label, region, region_label, categoria, valor)

# ______________________________________________________________________________
# GUARDAR — RData  tabla dt_Coyuntural del pipeline Excel ####
# ______________________________________________________________________________

save(dt_Coyuntural, file = paste0(dire_out, "/BBDD_Coyuntural.RData"))

message("═══════════════════════════════════════════════")
message("dt_Coyuntural     : ", nrow(dt_Coyuntural), " filas | ",
        "período: ", Trim_Actual, " | ",
        n_distinct(dt_Coyuntural$categoria), " categorías")
message("Guardado en: ", paste0(dire_out, "/BBDD_Coyuntural.RData"))
message("═══════════════════════════════════════════════")
