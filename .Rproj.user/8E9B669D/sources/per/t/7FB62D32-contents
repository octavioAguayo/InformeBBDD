# CreaBBDD_Pipeline_DTA.R - v5 - 26-08-2026
# Orquestador de la rama DTA: fija el período una vez y ejecuta ENE_1,
# ENE_2 y ENE_3 hasta producir dt_ENE_Stata.

if (!exists("fc_init_motor")) {
  source(file.path(dirname(getwd()), "Bibliotecas_R", "funciones_pipeline.R"))
}
source(file.path(dirname(getwd()), "Bibliotecas_R", "funciones_formato.R"))
source(file.path(dirname(getwd()), "Bibliotecas_R", "funciones_ene.R"))

fc_init_motor(c("stringr"))

# Para forzar otro período, definir Periodo_DTA antes de ejecutar este archivo.
# Por defecto se usa el período del DTA más reciente disponible.
archivos_dta <- fc_archivos_ene(periodo_inicio = 201002)
if (!length(archivos_dta)) {
  stop("No hay archivos DTA de la ENE disponibles.", call. = FALSE)
}
nombres_dta <- basename(archivos_dta)
periodos_disponibles <- as.integer(paste0(
  stringr::str_extract(nombres_dta, "(?<=ene-)\\d{4}"),
  stringr::str_extract(nombres_dta, "(?<=ene-\\d{4}-)\\d{2}")
))

if (!exists("Periodo_DTA", inherits = FALSE) || is.null(Periodo_DTA)) {
  Periodo_DTA <- max(periodos_disponibles)
  message("Periodo_DTA deducido del archivo más reciente: ", Periodo_DTA)
}

if (length(Periodo_DTA) != 1L || is.na(Periodo_DTA) ||
    !grepl("^[0-9]{6}$", as.character(Periodo_DTA))) {
  stop("Periodo_DTA debe ser un único período AAAAMM. Valor actual: ",
       paste(Periodo_DTA, collapse = ", "), call. = FALSE)
}
if (!as.integer(Periodo_DTA) %in% periodos_disponibles) {
  stop("No existe un DTA para Periodo_DTA = ", Periodo_DTA, ".",
       call. = FALSE)
}

if (!exists("RECREAR_SERIE_DTA", inherits = FALSE) || is.null(RECREAR_SERIE_DTA)) {
  RECREAR_SERIE_DTA <- FALSE
}
if (!is.logical(RECREAR_SERIE_DTA) || length(RECREAR_SERIE_DTA) != 1L ||
    is.na(RECREAR_SERIE_DTA)) {
  stop("RECREAR_SERIE_DTA debe ser TRUE o FALSE.", call. = FALSE)
}

if (!exists("RECREAR_CACHE", inherits = FALSE) || is.null(RECREAR_CACHE)) {
  RECREAR_CACHE <- FALSE
}
if (!is.logical(RECREAR_CACHE) || length(RECREAR_CACHE) != 1L ||
    is.na(RECREAR_CACHE)) {
  stop("RECREAR_CACHE debe ser TRUE o FALSE.", call. = FALSE)
}

if (!exists("modo_master", inherits = FALSE) || is.null(modo_master)) {
  modo_master <- 1L
}

if (!exists("dir_scripts", inherits = FALSE) || is.null(dir_scripts)) {
  dir_scripts <- tryCatch({
    of <- NULL
    for (i in seq_len(sys.nframe())) {
      archivo_origen <- sys.frame(i)$ofile
      if (!is.null(archivo_origen)) {
        of <- archivo_origen
        break
      }
    }
    if (is.null(of)) {
      args <- commandArgs(trailingOnly = FALSE)
      argumento_archivo <- grep("^--file=", args, value = TRUE)
      if (length(argumento_archivo)) {
        of <- sub("^--file=", "", argumento_archivo[1])
      }
    }
    if (is.null(of)) getwd() else dirname(normalizePath(of))
  }, error = function(e) getwd())
}

rutas_etapas <- file.path(
  dir_scripts,
  "intermedios",
  c(
    "ENE_1_Cubo.R",
    "ENE_2_Colapso_SexoRegionEdad.R",
    "ENE_3_Derivadas_Master_dta.R"
  )
)
faltan_etapas <- rutas_etapas[!file.exists(rutas_etapas)]
if (length(faltan_etapas)) {
  stop("No encuentro etapas del pipeline: ",
       paste(faltan_etapas, collapse = ", "), call. = FALSE)
}

if (RECREAR_SERIE_DTA) {
  RecrearBase <- "Si"
  periodo_ini <- NULL
  periodo_fin <- NULL
  alcance <- "serie completa"
} else {
  RecrearBase <- "No"
  periodo_ini <- as.integer(Periodo_DTA)
  periodo_fin <- as.integer(Periodo_DTA)
  alcance <- paste0("solo período ", Periodo_DTA)
}

message("═══════════════════════════════════════════════")
message("PIPELINE DTA — ", alcance,
        " | recrear caché = ", RECREAR_CACHE,
        " | modo master = ", modo_master)
message("═══════════════════════════════════════════════")

for (ruta_etapa in rutas_etapas) {
  message("→ Ejecutando ", basename(ruta_etapa), " ...")
  source(ruta_etapa, local = environment())
}

message("Pipeline DTA terminado: ", alcance, ".")
