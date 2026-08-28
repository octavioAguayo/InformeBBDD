# CreaBBDD_Master_BBDD.R - v6 - 26-08-2026
# Orquestador: une dt_ENE_Stata + dt_ENE_Excel en dt_ENE_Master.

if (!exists("fc_init_motor"))
  source(file.path(dirname(getwd()), "Bibliotecas_R", "funciones_pipeline.R"))

fc_init_motor(c("dplyr", "lubridate"))

# Modo de construcción: 1 = completa | 2 = solo dta | 3 = solo excel
if (!exists("modo_master", inherits = FALSE) || is.null(modo_master)) {
  modo_master <- 1
}
if (!modo_master %in% 1:3) {
  stop("modo_master debe ser 1 (completa), 2 (solo dta) o 3 (solo excel).")
}

dire_dta <- file.path(dirname(dirname(getwd())), "Datos_Ine", "ENE", "bbdd_minuta")
dire_xls <- dire_dta
if (!dir.exists(dire_dta)) {
  dir.create(dire_dta, recursive = TRUE)
}

# ==============================================================================
# CARGAR FUENTES ####
# ==============================================================================

load(file.path(dire_dta, "dt_ENE_Stata.RData"))        # → dt_ENE_Stata
load(file.path(dire_xls, "BBDD_Excel_Master.RData"))   # → dt_ENE_Excel

# Impide mezclar el lector Excel migrado con un producto microdatos anterior.
if (n_distinct(dt_ENE_Stata$categoria[
  grepl("_b14( |$)", dt_ENE_Stata$categoria)
]) != 63L) {
  stop("dt_ENE_Stata no contiene las 63 categorías _b14. ",
       "Regenera ENE_1 → ENE_2 → ENE_3 antes del Master.")
}

# Llave canónica (NO incluye `valor`: define identidad de fila, no su contenido)
# ── Relación admisible entre fuentes ─────────────────────────────────────────
# Excel publica antes que el microdato: o van parejos, o Excel va exactamente un
# período adelante (la ventana de ~12 horas entre una publicación y la otra).
# Cualquier otra distancia significa que una de las dos no se regeneró, y eso no
# se detecta solo: el anti_join no falla, produce una maestra a medias.
if (modo_master == 1) {
  per_dta   <- max(dt_ENE_Stata$periodo)
  per_excel <- max(dt_ENE_Excel$periodo)
  fc_sig <- function(p) if (p %% 100 == 12) p + 89 else p + 1   # AAAAMM + 1 mes
  if (!(per_excel == per_dta || per_excel == fc_sig(per_dta)))
    stop("Fuentes desalineadas: .dta llega a ", per_dta,
         " y Excel a ", per_excel,
         ". Solo se admite dta = excel o dta + 1 = excel. ",
         "Regenerar la fuente que quedó atrás antes de unir.", call. = FALSE)
  message("Fuentes: .dta hasta ", per_dta, " | Excel hasta ", per_excel,
          if (per_excel != per_dta) "  (Excel un período adelante)" else "  (alineadas)")
}

llave <- c("periodo", "fecha", "sexo", "sexo_label",
           "region", "region_label", "categoria")

# ==============================================================================
# CONSTRUIR SEGÚN MODO ####
# Reconstrucción completa desde cero — sin cargar la maestra previa
# ==============================================================================

if (modo_master == 2L) {
  # --- Modo 2: solo dta (validación) -----------------------------------------
  dt_ENE_Master <- dt_ENE_Stata
  excl_excel    <- dt_ENE_Excel[0, ]   # vacío, solo para diagnóstico
  message("MODO 2 — solo dta: dt_ENE_Master = dt_ENE_Stata")
  
} else if (modo_master == 3L) {
  # --- Modo 3: solo excel (validación) ---------------------------------------
  dt_ENE_Master <- dt_ENE_Excel
  excl_excel    <- dt_ENE_Excel[0, ]
  message("MODO 3 — solo excel: dt_ENE_Master = dt_ENE_Excel")
  
} else {
  # --- Modo 1: completa (producción) -----------------------------------------
  # Stata = espina dorsal (toda); Excel aporta solo sus llaves exclusivas.
  # En llaves compartidas se conserva el valor de Stata (más profundo/microdato).
  excl_excel <- anti_join(dt_ENE_Excel, dt_ENE_Stata, by = llave)
  
  dt_ENE_Master <- bind_rows(dt_ENE_Stata, excl_excel)
  message("MODO 1 — completa: dt_ENE_Stata (", nrow(dt_ENE_Stata),
          " filas) + Excel exclusivo (", nrow(excl_excel), " filas)")
}

dt_ENE_Master <- dt_ENE_Master %>%
  arrange(periodo, sexo, region, categoria)

# ==============================================================================
# CHEQUEO DE INTEGRIDAD ####
# La llave debe ser única: si hay duplicados, alguna fuente tiene filas
# repetidas o las etiquetas (sexo_label / region_label) no calzan entre fuentes.
# ==============================================================================

n_dup <- dt_ENE_Master %>% count(across(all_of(llave))) %>% filter(n > 1) %>% nrow()
if (n_dup > 0)
  warning(sprintf("dt_ENE_Master tiene %d llaves duplicadas. Revisa que sexo_label/region_label coincidan entre Stata y Excel.", n_dup))

# ==============================================================================
# DIAGNÓSTICO FINAL ####
# ==============================================================================

modo_txt <- c("1 = completa (Stata + Excel exclusivo)",
              "2 = solo dta", "3 = solo excel")[modo_master]

message("═══════════════════════════════════════════════")
message("dt_ENE_Master  |  modo ", modo_txt)
message("  Filas totales : ", nrow(dt_ENE_Master))
message("  Períodos      : ", n_distinct(dt_ENE_Master$periodo),
        "  [", min(dt_ENE_Master$fecha), " → ", max(dt_ENE_Master$fecha), "]")
message("  Categorías    : ", n_distinct(dt_ENE_Master$categoria))
message("  Regiones      : ", n_distinct(dt_ENE_Master$region_label))
if (modo_master == 1L)
  message("  Excl. Excel   : ", nrow(excl_excel), " filas agregadas sobre Stata")
if (n_dup > 0)
  message("  ⚠ Llaves dup. : ", n_dup)
message("═══════════════════════════════════════════════")

# ==============================================================================
# GUARDAR ####
# Producción (modo 1) escribe la maestra canónica. Validación (modos 2/3)
# escribe un archivo con sufijo para NO pisar la maestra de producción.
# (Como la reconstrucción es fresca, correr modo 1 luego regenera todo igual.)
# ==============================================================================

sufijo      <- c("", "_solo_dta", "_solo_excel")[modo_master]
ruta_master <- file.path(dire_dta, paste0("dt_ENE_Master", sufijo, ".RData"))

save(dt_ENE_Master, file = ruta_master)
message("Guardado en: ", ruta_master)

if (modo_master != 1L)
  message("⚠ Corrida de VALIDACIÓN (modo ", modo_master,
          "). La maestra de producción dt_ENE_Master.RData NO fue modificada. ",
          "Vuelve a correr con modo_master <- 1 para producción.")
