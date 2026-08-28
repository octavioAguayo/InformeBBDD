# CreaBBDD_Excel_Series.R - v8 - 22-08-2026
# Lee las series históricas de los libros Excel del INE.

if (!exists("fc_init_motor"))
  source(file.path(dirname(getwd()), "Bibliotecas_R", "funciones_pipeline.R"))

fc_init_motor(c("readxl", "dplyr", "tidyr", "lubridate", "stringr"))


# Funciones y parametros globales ####

options(scipen = 999)

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
    stop("[Excel/Series] No hay carpetas AAAAMM en ", .raiz_excel,
         ". Define Trim_Actual manualmente.", call. = FALSE)
  Trim_Actual <- max(.periodos)
  rm(.raiz_excel, .periodos)
}
if (!grepl("^[0-9]{6}$", Trim_Actual))
  stop("[Excel/Series] Trim_Actual debe ser AAAAMM de 6 dígitos. Valor: ", Trim_Actual)
message("[Excel/Series] Trim_Actual = ", Trim_Actual)

fecha_Actual <- as.Date(paste0(Trim_Actual, "01"), "%Y%m%d")

dire_series <- file.path(dirname(dirname(getwd())), "Datos_Ine", "Exceles", Trim_Actual, "series_ene")
dire_inform <- file.path(dirname(dirname(getwd())), "Datos_Ine", "Exceles", Trim_Actual, "series_informalidad")
dire_coy <- file.path(dirname(dirname(getwd())), "Datos_Ine", "Exceles", Trim_Actual, "trimestre_movil")

dire_out <- file.path(dirname(dirname(getwd())), "Datos_Ine", "ENE", "bbdd_minuta")
if (!dir.exists(dire_out)) {
  dir.create(dire_out, recursive = TRUE)
}

## Función auxiliar: convierte etiqueta de trimestre móvil a mes ####

trimestre_a_mes <- function(t) {
  case_when(
    t == "Ene - Mar" ~ 2,  t == "Feb - Abr" ~ 3,  t == "Mar - May" ~ 4,
    t == "Abr - Jun" ~ 5,  t == "May - Jul" ~ 6,  t == "Jun - Ago" ~ 7,
    t == "Jul - Sep" ~ 8,  t == "Ago - Oct" ~ 9,  t == "Sep - Nov" ~ 10,
    t == "Oct - Dic" ~ 11, t == "Nov - Ene" ~ 12, t == "Dic - Feb" ~ 1,
    TRUE ~ NA_real_
  )
}

# ______________________________________________________________________________
# leer_serie_auto: detecta automáticamente columnas de datos desde las filas de
#   encabezado del Excel ENE.
#
# Estructura del Excel INE (todas las series siguen este patrón):
#   Fila 5 (skip=4): nombres de variables en columnas PARES (0-indexed: 2, 4, 6…)
#   Fila 6 (skip=4): tipo en columnas IMPARES → "en miles", "tasa (%)", "en horas"
#                    y "nota" en columnas PARES (ignorar)
#   Fila 7+:         datos en columnas IMPARES; columnas PARES siempre NA (notas)
#
#   → La función lee filas 5-6 sin skip para mapear nombre→columna de dato,
#     luego lee los datos con skip=5 usando solo esas columnas.
#
# Argumentos:
#   archivo      : ruta al .xlsx
#   hojas        : vector de nombres de hojas (uno por sexo/región)
#   nombres_col  : vector de nombres canónicos (en el mismo orden que cols del Excel)
#                  Si NULL, usa los nombres originales del Excel (fila 5, limpios)
#   excluir_cols : (opcional) índices 0-based de columnas a excluir aunque sean datos
#   solo_cols    : (opcional) índices 0-based de columnas a mantener (subset)
# ______________________________________________________________________________

leer_serie_auto <- function(archivo, hojas,
                            nombres_col  = NULL,
                            excluir_cols = NULL,
                            solo_cols    = NULL) {
  
  message("  → Procesando Excel: ", basename(archivo),
          "  [hojas: ", paste(hojas, collapse = ", "), "]")
  
  # --- 1. Detectar columnas de datos dinámicamente ----------------------------
  # Los excels ENE no tienen todos el mismo número de filas de encabezado:
  # algunos tienen una fila vacía extra antes de los nombres. Se busca la fila
  # que contiene "nota" (fila de tipos) y se toma la inmediatamente anterior
  # como fila de nombres.
  hdr <- suppressMessages(
    read_excel(archivo, sheet = hojas[1], col_names = FALSE,
               skip = 4, n_max = 4, .name_repair = "minimal")
  )
  
  fila_tipos_idx <- which(apply(hdr, 1, function(r) any(r == "nota", na.rm = TRUE)))[1]
  if (is.na(fila_tipos_idx))
    stop(sprintf("[%s] No se encontró fila de tipos ('nota') en las primeras 4 filas.", basename(archivo)))
  
  fila_nombres <- as.character(unlist(hdr[fila_tipos_idx - 1, ]))
  fila_tipos   <- as.character(unlist(hdr[fila_tipos_idx,     ]))
  
  # Columnas de datos: las que en fila_tipos NO son "nota" y no están vacías
  tipos_dato <- c("en miles", "tasa (%)", "en horas")
  idx_datos  <- which(fila_tipos %in% tipos_dato)   # 1-based (R)
  
  # Cada columna de dato tiene su nombre en la columna anterior (idx-1)
  nombres_excel <- fila_nombres[idx_datos - 1]
  nombres_excel <- str_squish(nombres_excel)         # limpiar espacios extra
  
  # Filtrar por posición ordinal (0-based) dentro del vector de columnas de datos
  # solo_cols    = c(1,2,3)  → mantener esas posiciones (0-based)
  # excluir_cols = c(0,10)   → descartar esas posiciones (0-based)
  if (!is.null(solo_cols)) {
    keep          <- (seq_along(idx_datos) - 1) %in% solo_cols
    idx_datos     <- idx_datos[keep]
    nombres_excel <- nombres_excel[keep]
  }
  if (!is.null(excluir_cols)) {
    keep          <- !((seq_along(idx_datos) - 1) %in% excluir_cols)
    idx_datos     <- idx_datos[keep]
    nombres_excel <- nombres_excel[keep]
  }
  
  # Unidad declarada por el Excel para cada columna de dato. Se conserva para
  # convertir a unidad final al leer, en vez de reescalar después.
  unidades <- fila_tipos[idx_datos]
  
  # Nombres finales: usar los canónicos si se proveen, si no los del Excel
  if (!is.null(nombres_col)) {
    if (length(nombres_col) != length(idx_datos))
      stop(sprintf(
        "[%s] nombres_col tiene %d elementos pero se detectaron %d columnas de datos.",
        basename(archivo), length(nombres_col), length(idx_datos)
      ))
    noms <- nombres_col
  } else {
    noms <- nombres_excel
  }
  
  # --- 2. Leer datos para cada hoja ------------------------------------------
  lapply(hojas, function(i) {
    dt <- suppressMessages(
      read_excel(archivo, sheet = i, skip = 5, col_names = FALSE,
                 .name_repair = "minimal")
    )
    # Tomar col 1 (Año), col 2 (Trimestre) + columnas de datos
    dt <- dt[, c(1, 2, idx_datos)]
    names(dt) <- c("Año", "Trimestre", noms)
    
    dt %>%
      # Conservar solo filas de datos reales: la col 2 (Trimestre) debe ser un
      # trimestre móvil válido. Descarta encabezados, fila de unidades y notas
      # al pie de forma robusta (mismo criterio que en las series desest.) y
      # evita warnings de coerción al no correr as.numeric(Año) sobre basura.
      filter(!is.na(trimestre_a_mes(Trimestre))) %>%
      mutate(
        mes   = trimestre_a_mes(Trimestre),
        sexo  = toupper(i),
        fecha = make_date(year = as.numeric(Año), month = mes, day = 1)
      )
  }) %>%
    bind_rows() %>%
    mutate(across(
      all_of(noms),
      ~ suppressWarnings(as.numeric(str_replace_all(as.character(.), "[^0-9.,-]", "")))
    )) %>%
    # Conversión a unidad final en el borde: ×1000 solo donde el Excel dice
    # "en miles". Tasas y horas quedan como vienen.
    mutate(across(
      all_of(noms[unidades == "en miles"]),
      ~ .x * 1000
    )) %>%
    filter(!is.na(fecha)) %>%
    select(-Año, -Trimestre, -mes)
}

hojas_completas <- c("AS","M","H","AP","TA","AN","AT","CO","VA","RM","LI","ML","NB","BI","AR","LR","LL","AI","MA")


# 1. Series temporales Estadigrafos ENE ####

### 1.1.7 Series Desestacionalizadas ####
# Estructura del libro "ajuste_estacional_historico.xlsx":
#   - Cada "vintage" (proyección publicada en un mes) ocupa un bloque de columnas.
#       hojas tasa_*    : 2 columnas por vintage  -> [Tasa oficial | Tasa ajustada]
#       hojas niveles_* : 6 columnas por vintage  -> [`Fuerza de trabajo`|Ocupados|Desocupados] x [oficial|ajustada]
#   - El vintage MÁS RECIENTE está siempre a la derecha (últimas 2 cols en tasas,
#     últimas 6 en niveles) y cubre todo el histórico. Las columnas a la izquierda
#     son proyecciones de meses anteriores y se descartan.
#   - Para la serie desestacionalizada nos quedamos solo con la versión AJUSTADA:
#       tasa   -> última columna           (Tasa ajustada)
#       nivel  -> últimas 3 columnas        (`Fuerza de trabajo` / Ocupados / Desocupados ajustados)
#
# IMPORTANTE: las hojas tasa_* y niveles_* NO tienen el mismo nº de filas (difieren
# en filas vacías y notas al pie), por eso se UNEN por (Año, Trimestre) en lugar de
# pegarse por posición con cbind() — que es lo que rompía el script.

arch_desest <- paste0(dire_series, "/ajuste_estacional_historico.xlsx")
sexos_d     <- c("AS","H","M")

# Lee una hoja y devuelve Año + Trimestre + las últimas `n_tail` columnas
# (= el vintage más reciente). Filtra a filas con trimestre válido, lo que
# descarta automáticamente cabeceras, fila de unidades y notas al pie.
leer_desest <- function(hoja, n_tail) {
  message("  → Procesando Excel: ", basename(arch_desest), "  [hoja: ", hoja, "]")
  d <- suppressMessages(
    read_excel(arch_desest, sheet = hoja, skip = 5,
               col_names = FALSE, .name_repair = "unique")
  )
  d <- d[, c(1, 2, (ncol(d) - n_tail + 1):ncol(d))]
  names(d) <- c("Año", "Trimestre", paste0("v", seq_len(n_tail)))  # nombrar TODO: evita nombres "" en mutate
  d %>%
    mutate(Año = as.character(Año), Trimestre = as.character(Trimestre)) %>%
    filter(!is.na(trimestre_a_mes(Trimestre)))
}

dt_Desest <- lapply(seq_along(sexos_d), function(i) {
  sx <- tolower(sexos_d[i])
  
  # tasas: últimas 2 cols [oficial | ajustada] -> ajustada = la última
  dt1 <- leer_desest(paste0("tasa_", sx), n_tail = 2)
  dt1 <- dt1[, c(1, 2, ncol(dt1))]
  names(dt1)[3] <- "Tasa de desocupación desestacionalizado"
  
  # niveles: últimas 6 cols [oficial x3 | ajustada x3] -> ajustada = las últimas 3
  dt2 <- leer_desest(paste0("niveles_", sx), n_tail = 6)
  dt2 <- dt2[, c(1, 2, (ncol(dt2) - 2):ncol(dt2))]
  names(dt2)[3:5] <- c("Fuerza de trabajo desestacionalizado", "Ocupados desestacionalizado", "Desocupados desestacionalizado")
  
  # Unir por periodo (robusto ante distinto nº de filas / orden entre hojas)
  dt1 %>%
    inner_join(dt2, by = c("Año", "Trimestre")) %>%
    mutate(
      mes   = trimestre_a_mes(Trimestre),
      sexo  = sexos_d[i],
      fecha = make_date(year = as.numeric(Año), month = mes, day = 1)
    )
}) %>%
  bind_rows() %>%
  select(fecha, sexo, `Tasa de desocupación desestacionalizado`, `Fuerza de trabajo desestacionalizado`, `Ocupados desestacionalizado`, `Desocupados desestacionalizado`) %>%
  mutate(across(`Tasa de desocupación desestacionalizado`:`Desocupados desestacionalizado`,
                ~ suppressWarnings(as.numeric(str_replace_all(as.character(.), "[^0-9.,-]", "")))))


### 1.1.1 Indicadores principales ####
# Excel: `Población en edad de trabajar` | `Fuerza de trabajo` | Ocupados | Desocupados | Cesantes | `Buscan trabajo por primera vez` | FFT |
#        FFT_Ini | FFT_IPA | FFT_IH | T_desoc | T_ocup | T_part

dt_principal <- leer_serie_auto(
  archivo     = paste0(dire_series, "/indicadores_principales.xlsx"),
  hojas       = hojas_completas,
  nombres_col = c(
    "Población en edad de trabajar","Fuerza de trabajo","Ocupados","Desocupados","Cesantes","Buscan trabajo por primera vez",
    "Fuera de la fuerza de trabajo","Fuera de la fuerza de trabajo iniciadores","Fuera de la fuerza de trabajo potencialmente activos","Fuera de la fuerza de trabajo habituales",
    "Tasa de desocupación","Tasa de ocupación","Tasa de participación"
  )
)

### 1.1.2 Indicadores Complementarios ####
# Excluir primeras 3 columnas (`Fuerza de trabajo`/Ocup/Desoc) ya en dt_principal → solo_cols 3..14

dt_complementarios <- leer_serie_auto(
  archivo     = paste0(dire_series, "/complementarios.xlsx"),
  hojas       = hojas_completas,
  nombres_col = c(
    "Iniciadoras disponibles","Tiempo parcial involuntario",
    "Ocupados que buscaron empleo","Fuerza de trabajo potencial",
    "Fuerza de trabajo ampliada","Desea trabajar",
    "Tasa presión laboral",
    "Tasa desocupación + ID (SU1)","Tasa desocupación + TPI (SU2)",
    "Tasa desocupación + FTP (SU3)","Tasa subutilización (SU4)"
  ),
  solo_cols = c(3:8, 10:14)   # saltar `Fuerza de trabajo`(0), Ocup(1), Desoc(2), T_desoc(9)
)

### 1.1.3 Grupos Ocupacionales ####
# Excluir primera columna (Ocupados total) → solo_cols 1..9

dt_grupos <- leer_serie_auto(
  archivo     = paste0(dire_series, "/grupo.xlsx"),
  hojas       = hojas_completas,
  nombres_col = c(
    "Directores, gerentes y administradores",
    "Profesionales, científicos e intelectuales",
    "Técnicos y profesionales de nivel medio",
    "Personal de apoyo administrativo",
    "Trabajadores de los servicios y vendedores de comercios y mercados",
    "Agricultores y trabajadores calificados agropecuarios, forestales y pesqueros",
    "Artesanos y operarios de oficios",
    "Operadores de instalaciones, máquinas y ensambladores",
    "Ocupaciones elementales"
  ),
  solo_cols = 1:9
)

### 1.1.4 Horas Laborales ####
# Excluir primera columna (Ocupados total) → solo_cols 1..13

dt_horas <- leer_serie_auto(
  archivo     = paste0(dire_series, "/horas.xlsx"),
  hojas       = c("AS","M","H"),
  nombres_col = c(
    "Personas trabajaron 1 - 30 horas habituales",
    "Personas tiempo parcial voluntario (TPV)",
    "Personas tiempo parcial involuntario (TPI)",
    "Personas a tiempo parcial S-I voluntariedad",
    "Personas trabajaron 31 - 44 horas habituales",
    "Personas trabajaron 45 horas habituales",
    "Personas trabajaron más de 45 horas habituales",
    "Personas trabajaron más de 45 horas efectivas",
    "Personas declararon horas trabajadas",
    "Promedio horas efectivas a la semana (con ocupados ausentes)",
    "Promedio horas efectivas a la semana (sin ocupados ausentes)",
    "Promedio horas habitualmente a la semana"
  ),
  solo_cols = 1:12
)

### 1.1.5 Categoría Ocupacionales ####
# Excluir primera columna (Ocupados total) → solo_cols 1..11

dt_categoria <- leer_serie_auto(
  archivo     = paste0(dire_series, "/categoria_cise.xlsx"),
  hojas       = hojas_completas,
  nombres_col = c(
    "Independientes","Empleadores","Cuenta propia","Familiares no remunerados",
    "Dependientes","Asalariados","Asalariados privados","Asalariados públicos",
    "Servicio doméstico","Servicio doméstico puertas afuera","Servicio doméstico puertas adentro"
  ),
  solo_cols = 1:11
)

### 1.1.5b Categoría Ocupacional CISO — nivel agregado ####
# Excluir primera columna (Población ocupada Total) → solo_cols 1..9
# En el libro los totales van ANTES de sus componentes: Independientes (Total)
# aparece en la posición 1 y sus dos partes en la 2 y la 3; Dependientes (Total)
# en la 4 y sus cuatro partes de la 5 a la 8.

dt_categoria_ciso <- leer_serie_auto(
  archivo     = paste0(dire_series, "/categoria_ciso.xlsx"),
  hojas       = hojas_completas,
  nombres_col = c(
    "Independientes ciso",
    "Empleadores ciso",
    "Cuenta propia ciso",
    "Dependiente ciso",
    "Contratista dependiente ciso",
    "Asalariados privados ciso",
    "Asalariados públicos ciso",
    "Servicio doméstico ciso",
    "Familiar no remunerado ciso"
  ),
  solo_cols = 1:9
)

### 1.1.5c Categoría Ocupacional CISO — tercer nivel jerárquico ####
# Excluir primera columna (Población ocupada Total) → solo_cols 1..19
# Acá el único agregado es el total: las 19 son excluyentes y suman.
# Calzan una a una, en orden, con los códigos 1 a 19 de ciso3_b.
dt_categoria_ciso3 <- leer_serie_auto(
  archivo     = paste0(dire_series, "/categoria_ciso_tnj.xlsx"),
  hojas       = hojas_completas,
  nombres_col = c(
    "Empleadores con empresa registrada como sociedad ciso3",
    "Empleadores con empresa no registrada o persona natural ciso3",
    "Cuenta propia con empresa registrada como sociedad ciso3",
    "Cuenta propia con empresa no registrada o persona natural ciso3",
    "Contratistas con dependencia organizativa exclusiva ciso3",
    "Contratistas con dependencia económica exclusiva ciso3",
    "Contratistas con ambas dependencias (organizativa y económica) ciso3",
    "Contratistas con contrato comercial ciso3",
    "Contratistas con riesgo económico ciso3",
    "Asalariados privados con contrato indefinido ciso3",
    "Asalariados privados por tiempo determinado ciso3",
    "Asalariados privados con contrato de corta duración ciso3",
    "Asalariados públicos con contrato indefinido ciso3",
    "Asalariados públicos por tiempo determinado ciso3",
    "Asalariados públicos con contrato de corta duración ciso3",
    "Servicio doméstico con contrato indefinido ciso3",
    "Servicio doméstico por tiempo determinado ciso3",
    "Servicio doméstico con contrato de corta duración ciso3",
    "Familiar o personal no remunerado ciso3"
  ),
  solo_cols = 1:19
)

### 1.1.6 Sector Económico ####
# Excluir primera columna (Ocupados total) → solo_cols 1..22

dt_rama <- leer_serie_auto(
  archivo     = paste0(dire_series, "/rama.xlsx"),
  hojas       = hojas_completas,
  nombres_col = paste0(c(
    "Agricultura, ganadería, silvicultura y pesca",
    "Explotación de minas y canteras",
    "Industrias manufactureras",
    "Suministro de electricidad, gas, vapor y aire acondicionado",
    "Suministro de agua","Construcción",
    "Comercio al por mayor y al por menor",
    "Transporte y almacenamiento",
    "Actividades de alojamiento y de servicio de comidas",
    "Información y comunicaciones",
    "Actividades financieras y de seguros",
    "Actividades inmobiliarias",
    "Actividades profesionales, científicas y técnicas",
    "Actividades de servicios administrativos y de apoyo",
    "Administración pública y defensa","Enseñanza",
    "Actividades de atención de la salud humana y de asistencia social",
    "Actividades artísticas, de entretenimiento y recreativas",
    "Otras actividades de servicios",
    "Actividades de los hogares como empleadores",
    "Actividades de organizaciones y órganos extraterritoriales"
  ), "_b14"),
  solo_cols = 1:21
)


### 1.1.8 Ocupados Ausentes ####
# Solo hoja "nacional" → fuerza sexo = "AS" luego

dt_ausentes <- leer_serie_auto(
  archivo     = paste0(dire_series, "/ocupados_ausentes.xlsx"),
  hojas       = c("nacional"),
  nombres_col = c(
    "Ocupados presentes","Ocupados ausentes",
    "Ocupados ausentes con vínculo efectivo",
    "Ocupados ausentes con pronto retorno",
    "Ocupados ausentes con sueldo o ganancias"
  ),
  solo_cols = 1:5
) %>%
  mutate(sexo = "AS")

### 1.1.9 Informalidad Categoría ####
# Columnas: OcupForm | Empl_F | CxP_F | AsPr_F | AsPub_F | ServDom_F |
#           OcupInf  | Empl_I | CxP_I | FamNR_I | AsPr_I | AsPub_I | ServDom_I

dt_Form_Categoria <- leer_serie_auto(
  archivo     = paste0(dire_inform, "/informalidad_categoria.xlsx"),
  hojas       = hojas_completas,
  nombres_col = c(
    "Ocupados formal",
    "Empleadores formal","Cuenta propia formal",
    "Asalariados privados formal","Asalariados públicos formal",
    "Servicio doméstico formal","Ocupados informal",
    "Empleadores informal","Cuenta propia informal",
    "Familiares no remunerados informal","Asalariados privados informal",
    "Asalariados públicos informal","Servicio doméstico informal"
  )
)

### 1.1.10 Informalidad Sector Económico ####
# 21 ramas formales + 21 ramas informales = 42 columnas de datos
# (excluir col 0 = Ocupados formales total, col 22 = Ocupados informales total)

ramas_nombres <- c(
  "Agricultura, ganadería, silvicultura y pesca",
  "Explotación de minas y canteras",
  "Industrias manufactureras",
  "Suministro de electricidad, gas, vapor y aire acondicionado",
  "Suministro de agua","Construcción",
  "Comercio al por mayor y al por menor",
  "Transporte y almacenamiento",
  "Actividades de alojamiento y de servicio de comidas",
  "Información y comunicaciones",
  "Actividades financieras y de seguros",
  "Actividades inmobiliarias",
  "Actividades profesionales, científicas y técnicas",
  "Actividades de servicios administrativos y de apoyo",
  "Administración pública y defensa","Enseñanza",
  "Actividades de atención de la salud humana y de asistencia social",
  "Actividades artísticas, de entretenimiento y recreativas",
  "Otras actividades de servicios",
  "Actividades de los hogares como empleadores",
  "Actividades de organizaciones y órganos extraterritoriales"
)

dt_form_rama <- leer_serie_auto(
  archivo     = paste0(dire_inform, "/informalidad_rama.xlsx"),
  hojas       = hojas_completas,
  nombres_col = c(paste(ramas_nombres, "formal"),
                  paste(ramas_nombres, "informal")),
  solo_cols   = c(1:21, 24:44)   # saltar [0]=OcupForm total, [22]=NoSabe form, [23]=OcupInf total, [45]=NoSabe inf
)

# El libro de informalidad usa r_p_rev4cl_caenes. Su total compatible se
# construye desde las dos partes del mismo clasificador; no se mezcla con
# rama.xlsx, que pertenece a b14_rev4cl_caenes.
for (rama in ramas_nombres) {
  columnas_estado <- paste(rama, c("formal", "informal"))
  if (!all(columnas_estado %in% names(dt_form_rama))) {
    stop("[Excel/Series] Faltan columnas formal/informal para: ", rama)
  }
  dt_form_rama[[rama]] <- rowSums(dt_form_rama[columnas_estado], na.rm = FALSE)
}

### 1.1.11 Informalidad Grupos Ocupacionales ####

grupos_nombres <- c(
  "Directores, gerentes y administradores",
  "Profesionales, científicos e intelectuales",
  "Técnicos y profesionales de nivel medio",
  "Personal de apoyo administrativo",
  "Trabajadores de los servicios y vendedores de comercios y mercados",
  "Agricultores y trabajadores calificados agropecuarios, forestales y pesqueros",
  "Artesanos y operarios de oficios",
  "Operadores de instalaciones, máquinas y ensambladores",
  "Ocupaciones elementales"
)

dt_form_grupos <- leer_serie_auto(
  archivo     = paste0(dire_inform, "/informalidad_grupo.xlsx"),
  hojas       = hojas_completas,
  nombres_col = c(paste(grupos_nombres, "formal"),
                  paste(grupos_nombres, "informal")),
  solo_cols   = c(1:9, 13:21)   # saltar col 0 (OcupForm total) y col 12 (OcupInf total)
)


### 1.1.12 Tamaño de Empresa ####
# Excel: 3 hojas (AS / formales / informales) — todas sexo = "AS"
# solo_cols: excluye col 0 (Ocupados total, ya en dt_principal)
#            y col 2 (Total que responde = Ocupados - Serv.doméstico, redundante)
# col 1 (Serv. doméstico excluido) + col 7 (No sabe/no responde) → "Ocupados Sin clasificar por tamaño"

tamano_hojas  <- c("AS", "formales", "informales")
tamano_sufijo <- c("", " formal", " informal")

dt_tamano <- lapply(seq_along(tamano_hojas), function(i) {
  leer_serie_auto(
    archivo     = paste0(dire_coy, "/tamano.xlsx"),
    hojas       = tamano_hojas[i],
    nombres_col = c(
      ".sin_clasificar_a",                                    # col 1: serv. doméstico
      paste0("Ocupados Micro empresa",   tamano_sufijo[i]),            # col 3: 1-10
      paste0("Ocupados Pequeña empresa", tamano_sufijo[i]),            # col 4: 11-49
      paste0("Ocupados Mediana empresa", tamano_sufijo[i]),            # col 5: 50-199
      paste0("Ocupados Gran empresa",    tamano_sufijo[i]),            # col 6: 200+
      ".sin_clasificar_b"                                     # col 7: no sabe/no responde
    ),
    solo_cols = c(1, 3, 4, 5, 6, 7)
  ) %>%
    mutate(
      !!paste0("Ocupados Sin clasificar por tamaño", tamano_sufijo[i]) :=
        rowSums(cbind(.sin_clasificar_a, .sin_clasificar_b), na.rm = FALSE),
      sexo = "AS"
    ) %>%
    select(-.sin_clasificar_a, -.sin_clasificar_b)
}) %>%
  bind_rows() %>%
  # Las 3 hojas son todas AS → colapsar por fecha+sexo en columnas anchas
  group_by(fecha, sexo) %>%
  # na.omit(.)[1] toma el único valor no-NA del grupo; con corchete simple
  # devuelve NA (en vez de error) cuando el grupo no tiene ningún valor,
  # p.ej. períodos antiguos donde formales/informales aún no tienen serie.
  summarise(across(everything(), ~ na.omit(.)[1]), .groups = "drop")


## 1.2 Unir BBDD integrada ####

message("═══ Lecturas de Excel completas. Uniendo BBDD integrada... ═══")

dt_unida <- dt_categoria %>%
  left_join(dt_categoria_ciso,  by = c("fecha","sexo")) %>%
  left_join(dt_categoria_ciso3, by = c("fecha","sexo")) %>%
  left_join(dt_complementarios, by = c("fecha","sexo")) %>%
  left_join(dt_Desest,          by = c("fecha","sexo")) %>%
  left_join(dt_Form_Categoria,  by = c("fecha","sexo")) %>%
  left_join(dt_form_grupos,     by = c("fecha","sexo")) %>%
  left_join(dt_form_rama,       by = c("fecha","sexo")) %>%
  left_join(dt_grupos,          by = c("fecha","sexo")) %>%
  left_join(dt_horas,           by = c("fecha","sexo")) %>%
  left_join(dt_principal,       by = c("fecha","sexo")) %>%
  left_join(dt_rama,            by = c("fecha","sexo")) %>%
  left_join(dt_ausentes,        by = c("fecha","sexo")) %>%
  left_join(dt_tamano,          by = c("fecha","sexo"))

## 1.2.2 Calcular variables complementarias ####

message("═══ Calculando variables complementarias... ═══")

fecha_Inicio_Covid <- as.Date("2020-01-01")

factores_base <- dt_unida %>%
  filter(fecha == fecha_Inicio_Covid) %>%
  select(sexo, `Ocupados formal`, `Ocupados informal`, `Población en edad de trabajar`)

dt_unida <- dt_unida %>%
  left_join(factores_base, by = "sexo", suffix = c("", "_base")) %>%
  mutate(
    `Asalariados dependientes formal`   = `Asalariados privados formal` + `Asalariados públicos formal` + `Servicio doméstico formal`,
    `Asalariados dependientes informal` = `Asalariados privados informal` + `Asalariados públicos informal` + `Servicio doméstico informal`,
    `Asalariados dependientes`        = `Asalariados dependientes formal` + `Asalariados dependientes informal`,
    `Tasa de ocupación informal`      = ifelse(!is.na(`Ocupados informal`) & !is.na(Ocupados),
                                               `Ocupados informal` / Ocupados * 100, NA_real_),
    `Tasa de cesantía`      = ifelse(!is.na(Cesantes) & !is.na(`Fuerza de trabajo`), Cesantes / `Fuerza de trabajo` * 100, NA_real_),
    `Tasa búsqueda trabajo`         = ifelse(!is.na(`Buscan trabajo por primera vez`) & !is.na(`Fuerza de trabajo`), `Buscan trabajo por primera vez` / `Fuerza de trabajo` * 100, NA_real_),
    `Fuera de la fuerza de trabajo desestacionalizado`           = ifelse(!is.na(`Fuerza de trabajo desestacionalizado`) & !is.na(`Población en edad de trabajar`), `Población en edad de trabajar` - `Fuerza de trabajo desestacionalizado`, NA_real_),
    `Tasa de participación desestacionalizado` = ifelse(!is.na(`Fuerza de trabajo desestacionalizado`) & !is.na(`Población en edad de trabajar`),
                                                        `Fuerza de trabajo desestacionalizado` / `Población en edad de trabajar` * 100, NA_real_),
    `Ocupados formal sobre PET`        = ifelse(!is.na(`Ocupados formal`) & !is.na(`Población en edad de trabajar`),
                                                `Ocupados formal` / `Población en edad de trabajar` * 100, NA_real_),
    `Ocupados informal sobre PET`      = ifelse(!is.na(`Ocupados informal`) & !is.na(`Población en edad de trabajar`),
                                                `Ocupados informal` / `Población en edad de trabajar` * 100, NA_real_),
    `Ocupados sector privado` = ifelse(!is.na(`Asalariados públicos`) & !is.na(Ocupados),
                                       Ocupados - `Asalariados públicos`, NA_real_),
    `Déficit de ocupación formal`    = ifelse(!is.na(`Ocupados formal`) & !is.na(`Población en edad de trabajar`),
                                              `Ocupados formal` - (`Ocupados formal_base` / `Población en edad de trabajar_base`) * `Población en edad de trabajar`, NA_real_),
    `Déficit de ocupación informal`  = ifelse(!is.na(`Ocupados informal`) & !is.na(`Población en edad de trabajar`),
                                              `Ocupados informal` - (`Ocupados informal_base` / `Población en edad de trabajar_base`) * `Población en edad de trabajar`, NA_real_)
  )

## 1.3 Construir BBDD final ####

message("═══ Construyendo BBDD final (pivot_longer)... ═══")

# La lista `Excluir` se elimina: la unidad de cada columna ya se resolvió al
# leer, contra lo que el propio Excel declara. Era la misma información escrita
# dos veces sin nada que obligara a las dos copias a coincidir.

# Nombres tal como quedan tras el left_join con suffix = c("", "_base").
# Ojo: select(-any_of()) ignora en silencio lo que no calza, así que un nombre
# mal escrito acá NO falla: deja la columna auxiliar entrar al pivot y
# publicarse como categoría.
AuxiliaresPivot <- c(
  "Ocupados formal_base", "Ocupados informal_base",
  "Población en edad de trabajar_base"
)
# Las series _d (desestacionalizadas) dejaron de ser auxiliares: ahora pivotan
# a la maestra. Solo existen para AS/H/M (región TT) — en códigos regionales
# quedan NA y el filter(!is.na(valor)) las omite: agregación región 0 gratis.

dt_completo <- dt_unida %>%
  select(-any_of(AuxiliaresPivot)) %>%
  pivot_longer(
    cols      = -c(fecha, sexo),
    names_to  = "categoria",
    values_to = "valor"
  ) %>%
  filter(!is.na(valor))

## 1.4 Construir dt_Series_Excel con estructura unificada ####

dt_Series_Excel <- dt_completo %>%
  mutate(
    region = case_when(
      sexo %in% c("AS","M","H") ~ "TT",
      TRUE                      ~ sexo
    ),
    region_label = case_when(
      sexo %in% c("AS","M","H") ~ "Total nacional",
      sexo == "AP" ~ "Arica y Parinacota", sexo == "TA" ~ "Tarapacá",
      sexo == "AN" ~ "Antofagasta",        sexo == "AT" ~ "Atacama",
      sexo == "CO" ~ "Coquimbo",           sexo == "VA" ~ "Valparaíso",
      sexo == "RM" ~ "Metropolitana",      sexo == "LI" ~ "O'Higgins",
      sexo == "ML" ~ "Maule",              sexo == "NB" ~ "Ñuble",
      sexo == "BI" ~ "Biobío",             sexo == "AR" ~ "La Araucanía",
      sexo == "LR" ~ "Los Ríos",           sexo == "LL" ~ "Los Lagos",
      sexo == "AI" ~ "Aysén",              sexo == "MA" ~ "Magallanes",
      TRUE ~ sexo
    ),
    sexo_label = case_when(
      sexo == "AS" ~ "Ambos sexos",
      sexo == "M"  ~ "Mujeres",
      sexo == "H"  ~ "Hombres",
      TRUE         ~ "Ambos sexos"
    ),
    sexo = case_when(
      sexo %in% c("AS","M","H") ~ sexo,
      TRUE                      ~ "AS"
    )
  ) %>%
  mutate(periodo = as.numeric(format(fecha, "%Y%m"))) %>%
  select(periodo, fecha, sexo, sexo_label, region, region_label, categoria, valor)

# La salida Excel debe contener 21 ramas totales, formales e informales bajo
# r_p, además de los 21 totales alternativos identificados como _b14.
categorias_rama_esperadas <- c(
  ramas_nombres,
  paste(ramas_nombres, "formal"),
  paste(ramas_nombres, "informal"),
  paste0(ramas_nombres, "_b14")
)
faltan_rama_excel <- setdiff(categorias_rama_esperadas,
                             unique(dt_Series_Excel$categoria))
if (length(faltan_rama_excel)) {
  stop("[Excel/Series] Contrato de rama incompleto. Faltan: ",
       paste(faltan_rama_excel, collapse = ", "))
}
rm(categorias_rama_esperadas, faltan_rama_excel)


# ______________________________________________________________________________
# GUARDAR RData  tabla dt_Coyuntural del pipeline Excel ####
# ______________________________________________________________________________

save(dt_Series_Excel, file = paste0(dire_out, "/BBDD_Series.RData"))

message("═══════════════════════════════════════════════")
message("dt_Series_Excel   : ", nrow(dt_Series_Excel), " filas | ",
        n_distinct(dt_Series_Excel$periodo), " períodos | ",
        n_distinct(dt_Series_Excel$categoria), " categorías")
message("Guardado en: ", paste0(dire_out, "/BBDD_Series.RData"))
message("═══════════════════════════════════════════════")
