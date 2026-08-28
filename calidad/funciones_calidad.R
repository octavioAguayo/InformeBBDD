# funciones_calidad.R - v4 - 22-08-2026
# Controles tabulares del pipeline ENE. No exporta archivos ni modifica bases.

if (!exists("fc_init_motor")) {
  source(file.path(dirname(getwd()), "Bibliotecas_R", "funciones_pipeline.R"))
}

fc_init_motor(c("dplyr", "tidyr", "stringr", "tibble"))

fc_calidad_cargar <- function(ruta, objeto) {
  if (!file.exists(ruta)) {
    stop("No existe la base requerida: ", ruta, call. = FALSE)
  }
  entorno <- new.env(parent = emptyenv())
  objetos <- load(ruta, envir = entorno)
  if (!objeto %in% objetos) {
    stop("La base ", ruta, " no contiene el objeto ", objeto, ".",
         call. = FALSE)
  }
  entorno[[objeto]]
}

fc_calidad_resumen <- function(datos, nombre) {
  requeridas <- c("periodo", "categoria", "valor")
  faltantes <- setdiff(requeridas, names(datos))
  if (length(faltantes)) {
    stop(nombre, " no contiene: ", paste(faltantes, collapse = ", "),
         call. = FALSE)
  }
  tibble::tibble(
    objeto = nombre,
    filas = nrow(datos),
    periodos = dplyr::n_distinct(datos$periodo),
    periodo_min = min(datos$periodo, na.rm = TRUE),
    periodo_max = max(datos$periodo, na.rm = TRUE),
    categorias = dplyr::n_distinct(datos$categoria),
    valores_na = sum(is.na(datos$valor))
  )
}

fc_calidad_duplicados <- function(datos) {
  llave <- c("periodo", "fecha", "sexo", "sexo_label",
             "region", "region_label", "categoria")
  faltantes <- setdiff(llave, names(datos))
  if (length(faltantes)) {
    stop("No se puede comprobar la llave; faltan: ",
         paste(faltantes, collapse = ", "), call. = FALSE)
  }
  datos |>
    dplyr::count(dplyr::across(dplyr::all_of(llave)), name = "n") |>
    dplyr::filter(.data$n > 1L) |>
    dplyr::arrange(.data$periodo, .data$categoria)
}

fc_calidad_dta <- function(dt_ENE_Stata) {
  duplicados <- fc_calidad_duplicados(dt_ENE_Stata)
  familias_rama <- tibble::tibble(
    familia = c("r_p", "b14"),
    categorias = c(
      dplyr::n_distinct(dt_ENE_Stata$categoria[
        grepl("^Rama_", dt_ENE_Stata$categoria) &
          !grepl("_b14( |$)", dt_ENE_Stata$categoria)
      ]),
      dplyr::n_distinct(dt_ENE_Stata$categoria[
        grepl("_b14( |$)", dt_ENE_Stata$categoria)
      ])
    ),
    esperadas = c(63L, 63L)
  ) |>
    dplyr::mutate(estado = dplyr::if_else(
      .data$categorias == .data$esperadas, "OK", "ERROR"
    ))
  list(
    resumen = fc_calidad_resumen(dt_ENE_Stata, "dt_ENE_Stata"),
    duplicados = duplicados,
    familias_rama = familias_rama
  )
}

fc_calidad_periodos_dta <- function(dire_ene, resumen_base,
                                    resumen_SexoRegion, dt_ENE_Stata) {
  archivos <- list.files(
    dire_ene,
    pattern = "^ene-\\d{4}-\\d{2}-.*\\.dta$",
    full.names = FALSE
  )
  if (!length(archivos)) {
    stop("No hay DTA de la ENE en: ", dire_ene, call. = FALSE)
  }
  periodos_fuente <- sort(unique(as.integer(paste0(
    stringr::str_extract(archivos, "(?<=ene-)\\d{4}"),
    stringr::str_extract(archivos, "(?<=ene-\\d{4}-)\\d{2}")
  ))))
  productos <- list(
    ENE_1 = sort(unique(resumen_base$periodo)),
    ENE_2 = sort(unique(resumen_SexoRegion$periodo)),
    dt_ENE_Stata = sort(unique(dt_ENE_Stata$periodo))
  )
  dplyr::bind_rows(lapply(names(productos), function(nombre) {
    reales <- productos[[nombre]]
    faltantes <- setdiff(periodos_fuente, reales)
    extras <- setdiff(reales, periodos_fuente)
    tibble::tibble(
      producto = nombre,
      periodos_potenciales = length(periodos_fuente),
      periodos_reales = length(reales),
      faltantes = paste(faltantes, collapse = ", "),
      extras = paste(extras, collapse = ", "),
      estado = if (length(faltantes) || length(extras)) "ERROR" else "OK"
    )
  }))
}

fc_calidad_excel <- function(dt_ENE_Excel, dt_Series_Excel = NULL,
                             dt_Coyuntural = NULL) {
  resultado <- list(
    resumen = fc_calidad_resumen(dt_ENE_Excel, "dt_ENE_Excel"),
    duplicados = fc_calidad_duplicados(dt_ENE_Excel),
    cobertura = dt_ENE_Excel |>
      dplyr::group_by(.data$periodo) |>
      dplyr::summarise(
        categorias = dplyr::n_distinct(.data$categoria),
        sexos = dplyr::n_distinct(.data$sexo),
        regiones = dplyr::n_distinct(.data$region),
        .groups = "drop"
      ) |>
      dplyr::arrange(.data$periodo)
  )
  if (!is.null(dt_Series_Excel) && !is.null(dt_Coyuntural)) {
    resultado$duplicados_series <- fc_calidad_duplicados(dt_Series_Excel)
    resultado$duplicados_coyuntural <- fc_calidad_duplicados(dt_Coyuntural)
    categorias_series <- dplyr::distinct(dt_Series_Excel, .data$categoria)
    categorias_coyuntural <- dplyr::distinct(dt_Coyuntural, .data$categoria)
    resultado$composicion <- dplyr::bind_rows(
      dplyr::anti_join(categorias_series, categorias_coyuntural,
                       by = "categoria") |>
        dplyr::mutate(origen = "Solo Series"),
      dplyr::anti_join(categorias_coyuntural, categorias_series,
                       by = "categoria") |>
        dplyr::mutate(origen = "Solo Coyuntural"),
      dplyr::inner_join(categorias_series, categorias_coyuntural,
                        by = "categoria") |>
        dplyr::mutate(origen = "Ambas")
    ) |>
      dplyr::select(.data$origen, .data$categoria) |>
      dplyr::arrange(.data$origen, .data$categoria)
  }
  resultado
}

fc_calidad_fuentes <- function(dt_ENE_Stata, dt_ENE_Excel) {
  llave <- c("periodo", "fecha", "sexo", "sexo_label",
             "region", "region_label", "categoria")
  categorias_dta <- dplyr::distinct(dt_ENE_Stata, .data$categoria)
  categorias_excel <- dplyr::distinct(dt_ENE_Excel, .data$categoria)
  categorias <- dplyr::full_join(
    dplyr::mutate(categorias_dta, en_dta = TRUE),
    dplyr::mutate(categorias_excel, en_excel = TRUE),
    by = "categoria"
  ) |>
    dplyr::mutate(
      estado = dplyr::case_when(
        is.na(.data$en_dta) ~ "Solo Excel",
        is.na(.data$en_excel) ~ "Solo DTA",
        TRUE ~ "Ambas"
      )
    ) |>
    dplyr::select(.data$categoria, .data$estado) |>
    dplyr::arrange(.data$estado, .data$categoria)

  valores_compartidos <- dplyr::inner_join(
    dplyr::select(dt_ENE_Stata, dplyr::all_of(llave), valor_dta = .data$valor),
    dplyr::select(dt_ENE_Excel, dplyr::all_of(llave), valor_excel = .data$valor),
    by = llave
  ) |>
    dplyr::mutate(diferencia = .data$valor_dta - .data$valor_excel)

  list(
    categorias = categorias,
    solo_dta = dplyr::filter(categorias, .data$estado == "Solo DTA"),
    solo_excel = dplyr::filter(categorias, .data$estado == "Solo Excel"),
    valores_compartidos = valores_compartidos
  )
}

fc_calidad_canon <- function(dt_ENE_Master, diccionario) {
  es_plantilla <- !is.na(diccionario$corte) & diccionario$corte != ""
  tramos <- c(
    "15 a 19 años", "20 a 24 años", "25 a 29 años", "30 a 34 años",
    "35 a 39 años", "40 a 44 años", "45 a 49 años", "50 a 54 años",
    "55 a 59 años", "60 a 64 años", "65 a 69 años", "70 años o más"
  )
  esperadas <- diccionario$categoria[!es_plantilla]
  for (tramo in tramos) {
    esperadas <- c(
      esperadas,
      sub("{tramo}", tramo, diccionario$categoria[es_plantilla], fixed = TRUE)
    )
  }
  publicadas <- sort(unique(dt_ENE_Master$categoria))
  normalizar <- function(x) {
    x <- chartr("áéíóúüñÁÉÍÓÚÜÑ", "aeiouunAEIOUUN", x)
    gsub("\\s+", " ", trimws(tolower(x)))
  }
  tabla <- tibble::tibble(
    categoria = publicadas,
    en_canon = publicadas %in% esperadas,
    clave_normalizada = normalizar(publicadas)
  )
  casi_duplicadas <- tabla |>
    dplyr::group_by(.data$clave_normalizada) |>
    dplyr::filter(dplyr::n() > 1L) |>
    dplyr::ungroup() |>
    dplyr::arrange(.data$clave_normalizada, .data$categoria)
  list(
    categorias = tabla,
    fuera_canon = dplyr::filter(tabla, !.data$en_canon),
    nunca_publicadas = tibble::tibble(
      categoria = sort(setdiff(esperadas, publicadas))
    ),
    casi_duplicadas = casi_duplicadas
  )
}

fc_calidad_master <- function(dt_ENE_Master, dt_ENE_Stata, dt_ENE_Excel,
                              diccionario) {
  llave <- c("periodo", "fecha", "sexo", "sexo_label",
             "region", "region_label", "categoria")
  excel_exclusivo <- dplyr::anti_join(dt_ENE_Excel, dt_ENE_Stata, by = llave)
  master_esperado <- dplyr::bind_rows(dt_ENE_Stata, excel_exclusivo) |>
    dplyr::arrange(dplyr::across(dplyr::all_of(llave)))
  master_actual <- dt_ENE_Master |>
    dplyr::arrange(dplyr::across(dplyr::all_of(llave)))
  iguales <- isTRUE(all.equal(master_actual, master_esperado,
                             check.attributes = FALSE))
  periodos <- tibble::tibble(
    fuente = c("DTA", "Excel", "Master"),
    periodo_max = c(max(dt_ENE_Stata$periodo), max(dt_ENE_Excel$periodo),
                    max(dt_ENE_Master$periodo))
  )
  list(
    resumen = fc_calidad_resumen(dt_ENE_Master, "dt_ENE_Master"),
    periodos = periodos,
    duplicados = fc_calidad_duplicados(dt_ENE_Master),
    reconstruccion = tibble::tibble(
      control = "Master = DTA + Excel exclusivo",
      estado = if (iguales) "OK" else "ERROR",
      filas_actual = nrow(master_actual),
      filas_esperadas = nrow(master_esperado)
    ),
    canon = fc_calidad_canon(dt_ENE_Master, diccionario),
    fuentes = fc_calidad_fuentes(dt_ENE_Stata, dt_ENE_Excel)
  )
}

fc_calidad_version_cabecera <- function(ruta) {
  lineas <- readLines(ruta, n = 8L, warn = FALSE, encoding = "UTF-8")
  coincidencia <- regmatches(
    paste(lineas, collapse = " "),
    regexpr("(?:^|[ _-])v[0-9]+", paste(lineas, collapse = " "),
            perl = TRUE, ignore.case = TRUE)
  )
  if (!length(coincidencia) || !nzchar(coincidencia)) {
    return(NA_integer_)
  }
  as.integer(sub(".*[vV]", "", coincidencia))
}

fc_calidad_bloques_version <- function(lineas_log) {
  inicios <- grep("^\\*\\*[^*]+\\*\\*\\s*:", lineas_log, perl = TRUE)
  if (!length(inicios)) {
    return(character())
  }
  vapply(inicios, function(inicio) {
    posteriores <- which(seq_along(lineas_log) > inicio & lineas_log == "")
    fin <- if (length(posteriores)) posteriores[[1]] - 1L else length(lineas_log)
    paste(lineas_log[inicio:fin], collapse = " ")
  }, character(1))
}

fc_calidad_version_log <- function(nombre, bloques_log) {
  versiones <- integer()
  for (bloque in bloques_log) {
    referencias <- gregexpr("`[^`]+`", bloque, perl = TRUE)[[1]]
    if (identical(referencias[[1]], -1L)) {
      next
    }
    largos <- attr(referencias, "match.length")
    etiquetas <- substring(bloque, referencias + 1L,
                           referencias + largos - 2L)
    indices <- which(basename(etiquetas) == nombre)
    for (indice in indices) {
      inicio <- referencias[[indice]] + largos[[indice]]
      fin <- if (indice < length(referencias)) {
        referencias[[indice + 1L]] - 1L
      } else {
        nchar(bloque)
      }
      segmento <- substring(bloque, inicio, fin)
      halladas <- regmatches(segmento,
                             gregexpr("v[0-9]+", segmento, perl = TRUE))[[1]]
      if (length(halladas) && !identical(halladas, "")) {
        versiones <- c(versiones,
                       as.integer(sub("v", "", halladas, fixed = TRUE)))
      }
    }
  }
  if (!length(versiones)) {
    return(NA_integer_)
  }
  max(versiones)
}

fc_calidad_versiones <- function(raiz_proyecto) {
  raiz <- normalizePath(raiz_proyecto, winslash = "/", mustWork = TRUE)
  ruta_documentacion <- file.path(raiz, "Documentacion")
  ruta_log <- file.path(ruta_documentacion, "CHANGELOG_InformeBBDD.md")
  if (!file.exists(ruta_log)) {
    stop("No existe el changelog canónico: ", ruta_log, call. = FALSE)
  }
  archivos_r <- list.files(
    raiz,
    pattern = "[.]R$",
    recursive = TRUE,
    full.names = TRUE
  )
  archivos_r <- archivos_r[!grepl("[.]Rproj[.]user", archivos_r, fixed = TRUE)]
  artefactos <- c(
    archivos_r,
    file.path(raiz, "calidad", "Calidad_ENE.Rmd"),
    file.path(ruta_documentacion, "MANUAL_InformeBBDD.md"),
    file.path(ruta_documentacion, "ESTADO_PROYECTO.md")
  )
  artefactos <- artefactos[file.exists(artefactos)]
  lineas_log <- readLines(ruta_log, warn = FALSE, encoding = "UTF-8")
  bloques_log <- fc_calidad_bloques_version(lineas_log)
  tabla <- lapply(artefactos, function(ruta) {
    ruta_normalizada <- normalizePath(ruta, winslash = "/")
    version_cabecera <- fc_calidad_version_cabecera(ruta)
    version_log <- fc_calidad_version_log(basename(ruta), bloques_log)
    tibble::tibble(
      archivo = substring(ruta_normalizada, nchar(raiz) + 2L),
      tipo = if (grepl("[.]R$", ruta, ignore.case = TRUE)) "Código" else
        "Documentación",
      version_cabecera = version_cabecera,
      version_changelog = version_log,
      estado = dplyr::case_when(
        is.na(version_cabecera) ~ "Sin versión",
        is.na(version_log) ~ "Sin registro explícito",
        version_cabecera == version_log ~ "Coincide",
        TRUE ~ "Revisar"
      )
    )
  })
  dplyr::arrange(dplyr::bind_rows(tabla), .data$estado, .data$archivo)
}

fc_calidad_productos <- function(raiz_proyecto, ruta_bases,
                                 ruta_metadatos_ene) {
  raiz <- normalizePath(raiz_proyecto, winslash = "/", mustWork = TRUE)
  biblioteca <- normalizePath(file.path(raiz, "..", "Bibliotecas_R"),
                              winslash = "/", mustWork = TRUE)
  p <- function(...) file.path(raiz, ...)
  b <- function(...) file.path(biblioteca, ...)
  compartidas <- c(
    b("funciones_pipeline.R"), b("funciones_formato.R"), b("funciones_ene.R")
  )
  fuentes_excel <- c(
    p("CreaBBDD_Master_Excel.R"),
    p("intermedios", "CreaBBDD_Excel_Series.R"),
    p("intermedios", "CreaBBDD_Excel_Coyuntural.R"),
    compartidas
  )
  fuentes_dta <- c(
    p("CreaBBDD_Pipeline_DTA.R"),
    p("intermedios", "ENE_1_Cubo.R"),
    p("intermedios", "ENE_2_Colapso_SexoRegionEdad.R"),
    p("intermedios", "ENE_3_Derivadas_Master_dta.R"),
    b("fc_diccionario_ene.R"), b("ENE_diccionario_categorias.R"),
    compartidas
  )
  contratos <- list(
    list(producto = file.path(ruta_bases, "BBDD_Series.RData"),
         fuentes = c(p("CreaBBDD_Master_Excel.R"),
                     p("intermedios", "CreaBBDD_Excel_Series.R"), compartidas)),
    list(producto = file.path(ruta_bases, "BBDD_Coyuntural.RData"),
         fuentes = c(p("CreaBBDD_Master_Excel.R"),
                     p("intermedios", "CreaBBDD_Excel_Coyuntural.R"), compartidas)),
    list(producto = file.path(ruta_bases, "BBDD_Excel_Master.RData"),
         fuentes = fuentes_excel),
    list(producto = file.path(ruta_bases, "ENE_1_cubo.RData"),
         fuentes = c(p("CreaBBDD_Pipeline_DTA.R"),
                     p("intermedios", "ENE_1_Cubo.R"), compartidas)),
    list(producto = file.path(ruta_bases, "ENE_2_SexoRegionEdad.RData"),
         fuentes = c(p("CreaBBDD_Pipeline_DTA.R"),
                     p("intermedios", "ENE_1_Cubo.R"),
                     p("intermedios", "ENE_2_Colapso_SexoRegionEdad.R"),
                     compartidas)),
    list(producto = file.path(ruta_bases, "dt_ENE_Stata.RData"),
         fuentes = fuentes_dta),
    list(producto = file.path(ruta_bases, "dt_ENE_Master.RData"),
         fuentes = c(p("CreaBBDD_Master_BBDD.R"), fuentes_excel, fuentes_dta)),
    list(producto = file.path(ruta_metadatos_ene, "ENE_0b_metadatos.RData"),
         fuentes = c(p("ENE_0b_BBDD_Etiquetas.R"), compartidas))
  )
  filas <- lapply(contratos, function(contrato) {
    fuentes <- unique(contrato$fuentes)
    faltantes <- fuentes[!file.exists(fuentes)]
    if (length(faltantes)) {
      return(tibble::tibble(
        producto = basename(contrato$producto), existe = file.exists(contrato$producto),
        modificado = as.POSIXct(NA), fuente_mas_reciente = basename(faltantes[[1]]),
        fuente_modificada = as.POSIXct(NA), huella_md5 = NA_character_,
        estado = "Falta fuente declarada"
      ))
    }
    fechas_fuente <- file.info(fuentes)$mtime
    indice_reciente <- which.max(fechas_fuente)
    existe <- file.exists(contrato$producto)
    fecha_producto <- if (existe) file.info(contrato$producto)$mtime else
      as.POSIXct(NA)
    tibble::tibble(
      producto = basename(contrato$producto),
      existe = existe,
      modificado = fecha_producto,
      fuente_mas_reciente = basename(fuentes[[indice_reciente]]),
      fuente_modificada = fechas_fuente[[indice_reciente]],
      huella_md5 = if (existe) unname(tools::md5sum(contrato$producto)) else
        NA_character_,
      estado = dplyr::case_when(
        !existe ~ "Producto ausente",
        fecha_producto < fechas_fuente[[indice_reciente]] ~ "Revisar: fuente posterior",
        TRUE ~ "Vigente por fecha"
      )
    )
  })
  dplyr::bind_rows(filas)
}
