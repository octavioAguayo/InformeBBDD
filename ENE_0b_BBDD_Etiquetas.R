# ENE_0b_BBDD_Etiquetas.R - v17 - 22-08-2026
# Mide variables, etiquetas y vigencias desde los DTA. Produce exclusivamente
# tablas R; no genera inventarios Markdown, CSV, TXT ni Excel.

if (!exists("fc_init_motor")) {
  source(file.path(dirname(getwd()), "Bibliotecas_R", "funciones_pipeline.R"))
}
source(file.path(dirname(getwd()), "Bibliotecas_R", "funciones_formato.R"))
source(file.path(dirname(getwd()), "Bibliotecas_R", "funciones_ene.R"))

fc_init_motor(c("dplyr", "tidyr", "haven", "stringr"))

if (!exists("periodo_inicio") || is.null(periodo_inicio)) {
  periodo_inicio <- 201002L
}

dire_out <- file.path(dirname(dirname(getwd())),
                      "Datos_Ine", "ENE", "metadatos")
if (!dir.exists(dire_out)) {
  dir.create(dire_out, recursive = TRUE)
}
ruta_salida <- file.path(dire_out, "ENE_0b_metadatos.RData")

fc_periodo_archivo <- function(x) {
  nombre <- basename(x)
  anio <- as.integer(stringr::str_extract(nombre, "(?<=ene-)\\d{4}"))
  mes <- as.integer(stringr::str_extract(nombre, "(?<=ene-\\d{4}-)\\d{2}"))
  anio * 100L + mes
}

archivos <- fc_archivos_ene(periodo_inicio = periodo_inicio)
if (!length(archivos)) {
  stop("No se encontró ningún DTA de la ENE.", call. = FALSE)
}

fc_leer_metadatos <- function(archivo) {
  periodo <- fc_periodo_archivo(archivo)
  ene <- haven::read_dta(archivo, n_max = 1)
  variables <- tibble::tibble(
    periodo = periodo,
    variable = names(ene),
    etiqueta_var = vapply(ene, function(columna) {
      etiqueta <- attr(columna, "label", exact = TRUE)
      if (is.null(etiqueta)) {
        NA_character_
      } else {
        as.character(etiqueta)
      }
    }, character(1)),
    tipo = vapply(ene, function(columna) class(columna)[1], character(1))
  )
  categorias <- lapply(names(ene), function(variable) {
    etiquetas <- attr(ene[[variable]], "labels", exact = TRUE)
    if (is.null(etiquetas) || !length(etiquetas)) {
      return(NULL)
    }
    tibble::tibble(
      periodo = periodo,
      variable = variable,
      valor = as.character(unname(etiquetas)),
      tipo_valor = class(unname(etiquetas))[1],
      etiqueta = as.character(names(etiquetas))
    )
  })
  list(variables = variables, categorias = dplyr::bind_rows(categorias))
}

lecturas <- lapply(seq_along(archivos), function(i) {
  message("[", i, "/", length(archivos), "] ", basename(archivos[i]))
  fc_leer_metadatos(archivos[i])
})

variables_dta <- dplyr::bind_rows(lapply(lecturas, `[[`, "variables"))
categorias_dta <- dplyr::bind_rows(lapply(lecturas, `[[`, "categorias"))
periodos <- sort(unique(variables_dta$periodo))

vigencia_variables <- variables_dta |>
  dplyr::group_by(.data$variable) |>
  dplyr::summarise(
    primer_periodo = min(.data$periodo),
    ultimo_periodo = max(.data$periodo),
    n_periodos = dplyr::n_distinct(.data$periodo),
    .groups = "drop"
  ) |>
  dplyr::rowwise() |>
  dplyr::mutate(
    n_esperados = sum(periodos >= .data$primer_periodo &
                        periodos <= .data$ultimo_periodo),
    con_huecos = .data$n_periodos < .data$n_esperados,
    vigente_al_ultimo = .data$ultimo_periodo == max(periodos)
  ) |>
  dplyr::ungroup()

variables_con_huecos <- dplyr::filter(vigencia_variables, .data$con_huecos)
if (nrow(variables_con_huecos)) {
  huecos_variables <- variables_dta |>
    dplyr::semi_join(variables_con_huecos, by = "variable") |>
    dplyr::group_by(.data$variable) |>
    dplyr::summarise(
      faltan = paste(setdiff(
        periodos[periodos >= min(.data$periodo) &
                   periodos <= max(.data$periodo)],
        .data$periodo
      ), collapse = ", "),
      .groups = "drop"
    )
} else {
  huecos_variables <- tibble::tibble(
    variable = character(), faltan = character()
  )
}

estabilidad_etiquetas <- categorias_dta |>
  dplyr::group_by(.data$variable, .data$valor, .data$etiqueta) |>
  dplyr::summarise(
    desde = min(.data$periodo),
    hasta = max(.data$periodo),
    n_periodos = dplyr::n_distinct(.data$periodo),
    .groups = "drop"
  ) |>
  dplyr::mutate(
    etiqueta_vista = paste0("«", .data$etiqueta, "»"),
    n_car = nchar(.data$etiqueta),
    vigente_hoy = .data$hasta == max(periodos)
  )

catalogo_etiquetas <- estabilidad_etiquetas |>
  dplyr::group_by(.data$variable, .data$valor) |>
  dplyr::arrange(dplyr::desc(.data$hasta),
                 dplyr::desc(.data$n_periodos), .by_group = TRUE) |>
  dplyr::summarise(
    n_redacciones = dplyr::n(),
    etiqueta_vigente = dplyr::first(.data$etiqueta),
    desde = min(.data$desde),
    hasta = max(.data$hasta),
    vigente_hoy = any(.data$vigente_hoy),
    .groups = "drop"
  ) |>
  dplyr::mutate(etiqueta_elegida = .data$etiqueta_vigente)

etiquetas_inestables <- estabilidad_etiquetas |>
  dplyr::semi_join(
    dplyr::filter(catalogo_etiquetas, .data$n_redacciones > 1L),
    by = c("variable", "valor")
  ) |>
  dplyr::arrange(.data$variable, .data$valor, .data$desde)

variables_nuevas <- vigencia_variables |>
  dplyr::filter(.data$primer_periodo > min(periodos))
categorias_nuevas <- catalogo_etiquetas |>
  dplyr::filter(.data$desde > min(periodos))

fc_vectores_ene1 <- function(ruta) {
  lineas <- readLines(ruta, warn = FALSE)
  entorno <- new.env(parent = baseenv())
  inicios <- grep("^vars_(base|opcionales)\\s*<-", lineas)
  for (inicio in inicios) {
    fin <- inicio
    repeat {
      expresion <- paste(lineas[inicio:fin], collapse = "\n")
      completa <- tryCatch({
        eval(parse(text = expresion), envir = entorno)
        TRUE
      }, error = function(e) FALSE)
      if (completa || fin >= length(lineas)) {
        break
      }
      fin <- fin + 1L
    }
  }
  list(
    base = if (exists("vars_base", entorno)) entorno$vars_base else character(),
    opcionales = if (exists("vars_opcionales", entorno)) {
      entorno$vars_opcionales
    } else {
      character()
    }
  )
}

vectores_ene1 <- fc_vectores_ene1(
  file.path(getwd(), "intermedios", "ENE_1_Cubo.R")
)
vigencia_variables <- vigencia_variables |>
  dplyr::mutate(
    en_ene1 = dplyr::case_when(
      .data$variable %in% vectores_ene1$opcionales ~ "opcional",
      .data$variable %in% vectores_ene1$base ~ "base",
      TRUE ~ "no usa"
    ),
    medida = dplyr::if_else(
      .data$primer_periodo > min(periodos), "opcional", "base"
    )
  )

clasificacion <- vigencia_variables |>
  dplyr::filter(.data$en_ene1 != "no usa") |>
  dplyr::mutate(
    veredicto = dplyr::case_when(
      .data$en_ene1 == .data$medida ~ "ok",
      .data$medida == "base" ~ "mover a vars_base",
      TRUE ~ "mover a vars_opcionales"
    )
  ) |>
  dplyr::arrange(.data$veredicto != "ok", .data$variable)

ciso_etiquetas <- catalogo_etiquetas |>
  dplyr::filter(stringr::str_detect(.data$variable, "^ciso")) |>
  dplyr::arrange(.data$variable, suppressWarnings(as.numeric(.data$valor)),
                 .data$valor)

save(
  variables_dta, categorias_dta, vigencia_variables, huecos_variables,
  estabilidad_etiquetas, catalogo_etiquetas, etiquetas_inestables,
  variables_nuevas, categorias_nuevas, clasificacion, ciso_etiquetas,
  file = ruta_salida
)

message("Tablas técnicas guardadas en: ", ruta_salida)
message("Variables: ", nrow(vigencia_variables),
        " | etiquetas inestables: ", nrow(etiquetas_inestables),
        " | clasificaciones ENE_1 por revisar: ",
        sum(clasificacion$veredicto != "ok"))
