# ENE_0a_BBDD_Descarga_INE.R - v4 - 22-08-2026
# Descarga los .dta de la ENE desde el sitio del INE a Datos_Ine/ENE.
# Previo al pipeline: no produce base, solo trae los archivos que ENE_1 lee.

if (!exists("fc_init_motor"))
  source(file.path(dirname(getwd()), "Bibliotecas_R", "funciones_pipeline.R"))

fc_init_motor(c("lubridate"))

# ── PARÁMETROS ────────────────────────────────────────────────────────────────

# forzar = FALSE : incremental, baja solo lo que no está en disco. Uso normal.
# forzar = TRUE  : rebaja TODO. Necesario cuando el INE reprocesa la serie —la
#                  retrocarga de CISO anunciada para 202002, por ejemplo—, porque
#                  ahí el archivo existe pero su contenido cambió y el
#                  incremental lo saltaría sin mirarlo.
forzar <- TRUE

anio_inicio <- 2010

# ── RUTAS ─────────────────────────────────────────────────────────────────────

dire_ene <- file.path(dirname(dirname(getwd())), "Datos_Ine", "ENE")
if (!dir.exists(dire_ene)) {
  dir.create(dire_ene, recursive = TRUE)
  message("Carpeta creada: ", dire_ene)
}

# Se baja acá y se mueve al destino solo si la descarga terminó. Mismo patrón
# que GeneraInformes.R con los .docx: una descarga cortada deja el archivo a
# medias en la raíz, a la vista, y el bueno del destino no se toca.
dire_temp <- getwd()

link <- "https://www.ine.gob.cl/docs/default-source/ocupacion-y-desocupacion/bbdd/"

trimestres <- c("01-def", "02-efm", "03-fma", "04-mam", "05-amj", "06-mjj",
                "07-jja", "08-jas", "09-aso", "10-son", "11-ond", "12-nde")

# ── CANDIDATOS ────────────────────────────────────────────────────────────────

candidatos <- expand.grid(
  trim = trimestres,
  ano  = anio_inicio:year(now()),
  stringsAsFactors = FALSE
)
candidatos <- candidatos[order(candidatos$ano, candidatos$trim), ]

candidatos$url <- paste0(link, candidatos$ano, "/stata/ene-",
                         candidatos$ano, "-", candidatos$trim, ".dta")
candidatos$archivo <- paste0("ene-", candidatos$ano, "-", candidatos$trim, ".dta")
candidatos$destino <- file.path(dire_ene, candidatos$archivo)

# No se valida la URL por separado: eran ~200 conexiones para averiguar lo que
# la propia descarga dice. Los trimestres del año en curso que aún no existen
# fallan al bajar y se cuentan como no publicados.
pendientes <- if (forzar) candidatos else candidatos[!file.exists(candidatos$destino), ]

message("Trimestres posibles: ", nrow(candidatos),
        " | ya en disco: ", sum(file.exists(candidatos$destino)),
        " | a intentar: ", nrow(pendientes))
if (forzar) message("MODO FORZADO: se rebaja la serie completa.")

# ── DESCARGA ──────────────────────────────────────────────────────────────────

bajados <- fallidos <- character(0)

for (i in seq_len(nrow(pendientes))) {
  archivo <- pendientes$archivo[i]
  temporal <- file.path(dire_temp, archivo)

  ok <- tryCatch({
    suppressWarnings(
      download.file(pendientes$url[i], destfile = temporal,
                    mode = "wb", quiet = TRUE)
    )
    file.exists(temporal) && file.size(temporal) > 0
  }, error = function(e) FALSE)

  if (ok) {
    file.rename(temporal, pendientes$destino[i])
    bajados <- c(bajados, archivo)
    message("  bajado  ", archivo, " (",
            round(file.size(pendientes$destino[i]) / 1e6, 1), " MB)")
  } else {
    if (file.exists(temporal)) unlink(temporal)
    fallidos <- c(fallidos, archivo)
  }
}

# ── RESUMEN ───────────────────────────────────────────────────────────────────

message("\n── Resumen ──")
message("Bajados     : ", length(bajados))
message("No obtenidos: ", length(fallidos),
        "  (trimestres aún no publicados o caídos)")
if (length(fallidos))
  message("  ", paste(utils::tail(fallidos, 6), collapse = ", "))

en_disco <- list.files(dire_ene, pattern = "^ene-\\d{4}-\\d{2}-.*\\.dta$")
message("Total en ", dire_ene, ": ", length(en_disco), " archivos")

rm(list = setdiff(ls(), c("dire_ene", "bajados", "fallidos", "en_disco")))
