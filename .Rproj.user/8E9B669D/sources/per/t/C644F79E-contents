# app.R - v2 - 26-08-2026
# Consola Shiny para orquestar las tres construcciones productivas de InformeBBDD.

if (!file.exists("CreaBBDD_Master_Excel.R") ||
    !file.exists("CreaBBDD_Pipeline_DTA.R") ||
    !file.exists("CreaBBDD_Master_BBDD.R")) {
  stop("Abre app.R desde la raiz de InformeBBDD.", call. = FALSE)
}

if (!exists("fc_init_motor")) {
  source(file.path(dirname(getwd()), "Bibliotecas_R", "funciones_pipeline.R"))
}
fc_init_motor(c("shiny", "shinyjs"), instalar = FALSE)

ruta_datos <- file.path(dirname(dirname(getwd())), "Datos_Ine")
ruta_excel <- file.path(ruta_datos, "Exceles")
ruta_ene <- file.path(ruta_datos, "ENE")
ruta_bbdd <- file.path(ruta_ene, "bbdd_minuta")

exceles_requeridos <- c(
  "series_ene/ajuste_estacional_historico.xlsx",
  "series_ene/categoria_cise.xlsx",
  "series_ene/categoria_ciso_tnj.xlsx",
  "series_ene/categoria_ciso.xlsx",
  "series_ene/complementarios.xlsx",
  "series_ene/grupo.xlsx",
  "series_ene/horas.xlsx",
  "series_ene/indicadores_principales.xlsx",
  "series_ene/ocupados_ausentes.xlsx",
  "series_ene/rama.xlsx",
  "series_informalidad/informalidad_categoria.xlsx",
  "series_informalidad/informalidad_grupo.xlsx",
  "series_informalidad/informalidad_rama.xlsx",
  "trimestre_movil/coyuntural_categoria.xlsx",
  "trimestre_movil/coyuntural_rama.xlsx",
  "trimestre_movil/coyuntural_sft.xlsx",
  "trimestre_movil/coyuntural_sft_desagregado.xlsx",
  "trimestre_movil/coyuntural_sft_edad.xlsx",
  "trimestre_movil/tamano.xlsx"
)

fc_periodo_siguiente <- function(periodo) {
  anio <- periodo %/% 100L
  mes <- periodo %% 100L
  if (mes == 12L) (anio + 1L) * 100L + 1L else periodo + 1L
}

fc_periodo_rdata <- function(ruta, objeto) {
  if (!file.exists(ruta)) return(NA_integer_)
  datos <- new.env(parent = emptyenv())
  load(ruta, envir = datos)
  if (!exists(objeto, envir = datos, inherits = FALSE)) return(NA_integer_)
  tabla <- get(objeto, envir = datos, inherits = FALSE)
  if (!is.data.frame(tabla) || !"periodo" %in% names(tabla)) return(NA_integer_)
  periodos <- suppressWarnings(as.integer(tabla$periodo))
  if (!length(periodos) || all(is.na(periodos))) NA_integer_ else max(periodos, na.rm = TRUE)
}

fc_estado_bbdd <- function() {
  carpetas <- if (dir.exists(ruta_excel)) {
    grep("^[0-9]{6}$", basename(list.dirs(ruta_excel, recursive = FALSE)), value = TRUE)
  } else character()
  periodo_excel_fuente <- if (length(carpetas)) max(carpetas) else NA_character_
  ruta_periodo_excel <- if (is.na(periodo_excel_fuente)) NA_character_ else
    file.path(ruta_excel, periodo_excel_fuente)
  faltantes_excel <- if (is.na(ruta_periodo_excel)) {
    exceles_requeridos
  } else {
    exceles_requeridos[!file.exists(file.path(ruta_periodo_excel, exceles_requeridos)) |
                       file.info(file.path(ruta_periodo_excel, exceles_requeridos))$size <= 0]
  }

  archivos_dta <- if (dir.exists(ruta_ene)) {
    list.files(ruta_ene, pattern = "^ene-[0-9]{4}-[0-9]{2}-.*[.]dta$", full.names = FALSE)
  } else character()
  periodos_dta_archivo <- suppressWarnings(as.integer(sub(
    "^ene-([0-9]{4})-([0-9]{2})-.*$", "\\1\\2", archivos_dta
  )))
  periodo_dta_fuente <- if (length(periodos_dta_archivo)) max(periodos_dta_archivo, na.rm = TRUE) else NA_integer_

  periodo_excel_producto <- fc_periodo_rdata(
    file.path(ruta_bbdd, "BBDD_Excel_Master.RData"), "dt_ENE_Excel"
  )
  periodo_dta_producto <- fc_periodo_rdata(
    file.path(ruta_bbdd, "dt_ENE_Stata.RData"), "dt_ENE_Stata"
  )

  master_habilitado <- !is.na(periodo_excel_producto) && !is.na(periodo_dta_producto) &&
    (periodo_excel_producto == periodo_dta_producto ||
       periodo_excel_producto == fc_periodo_siguiente(periodo_dta_producto))
  estado_master <- if (is.na(periodo_excel_producto) || is.na(periodo_dta_producto)) {
    "Faltan productos Excel o DTA para construir la maestra."
  } else if (periodo_excel_producto == periodo_dta_producto) {
    paste0("Fuentes calzadas. Excel y DTA estan actualizados hasta ", periodo_dta_producto, ".")
  } else if (master_habilitado) {
    paste0("Fuentes temporalmente descalzadas. Excel esta actualizado hasta ",
           periodo_excel_producto, " y DTA hasta ", periodo_dta_producto,
           "; el desfase de un periodo es admisible.")
  } else {
    paste0("Fuentes descalzadas no admisiblemente. Excel llega a ",
           periodo_excel_producto, " y DTA a ", periodo_dta_producto,
           ". Actualiza la fuente atrasada antes de construir la maestra.")
  }

  list(
    periodo_excel_fuente = periodo_excel_fuente,
    faltantes_excel = faltantes_excel,
    periodo_dta_fuente = periodo_dta_fuente,
    periodo_excel_producto = periodo_excel_producto,
    periodo_dta_producto = periodo_dta_producto,
    master_habilitado = master_habilitado,
    estado_master = estado_master
  )
}

ui <- shiny::fluidPage(
  shinyjs::useShinyjs(),
  shiny::titlePanel("Actualizacion de BBDD ENE"),
  shiny::uiOutput("estado"),
  shiny::fluidRow(
    shiny::column(
      4,
      shiny::h4("1. Master Excel"),
      shiny::p("Valida la ultima carpeta Excel y ejecuta el orquestador unico."),
      shiny::actionButton("actualizar_excel", "Actualizar Master Excel", class = "btn-primary", width = "100%")
    ),
    shiny::column(
      4,
      shiny::h4("2. Master DTA"),
      shiny::checkboxInput("reconstruir_dta", "Reconstruir toda la serie DTA", value = FALSE),
      shiny::actionButton("actualizar_dta", "Actualizar DTA", class = "btn-primary", width = "100%")
    ),
    shiny::column(
      4,
      shiny::h4("3. Master BBDD"),
      shiny::p("Solo se habilita con fuentes temporalmente compatibles."),
      shiny::actionButton("crear_master", "Construir Master BBDD", class = "btn-success", width = "100%")
    )
  ),
  shiny::hr(),
  shiny::h4("Resultado de la sesion"),
  shiny::verbatimTextOutput("resultado")
)

server <- function(input, output, session) {
  estado <- shiny::reactiveVal(fc_estado_bbdd())
  resultado <- shiny::reactiveVal("Aun no se ha ejecutado ningun orquestador.")
  en_curso <- shiny::reactiveVal(FALSE)

  output$estado <- shiny::renderUI({
    e <- estado()
    estado_excel <- if (is.na(e$periodo_excel_fuente)) {
      "No existe una carpeta Excel AAAAMM."
    } else if (length(e$faltantes_excel)) {
      paste0("Excel ", e$periodo_excel_fuente, ": faltan ", length(e$faltantes_excel),
             " insumos: ", paste(e$faltantes_excel, collapse = ", "), ".")
    } else {
      paste0("Excel ", e$periodo_excel_fuente, ": los 19 insumos efectivos estan disponibles.")
    }
    estado_dta <- if (is.na(e$periodo_dta_fuente)) {
      "No se encontro un archivo DTA final."
    } else {
      paste0("DTA final mas reciente: ", e$periodo_dta_fuente, ".")
    }
    shiny::tagList(
      shiny::div(shiny::strong("Entrada Excel: "), estado_excel),
      shiny::div(shiny::strong("Entrada DTA: "), estado_dta),
      shiny::div(shiny::strong("Master: "), e$estado_master)
    )
  })

  shiny::observe({
    e <- estado()
    ocupada <- en_curso()
    shinyjs::toggleState("actualizar_excel", condition = !ocupada && !is.na(e$periodo_excel_fuente) && !length(e$faltantes_excel))
    shinyjs::toggleState("actualizar_dta", condition = !ocupada && !is.na(e$periodo_dta_fuente))
    shinyjs::toggleState("crear_master", condition = !ocupada && e$master_habilitado)
  })
  output$resultado <- shiny::renderText(resultado())

  ejecutar <- function(script, configuracion = list(), etiqueta) {
    if (isTRUE(en_curso())) {
      shiny::showNotification("Ya hay una operacion en curso.", type = "warning")
      return(invisible(NULL))
    }
    bloqueo <- file.path(ruta_bbdd, ".app_operacion_en_curso")
    if (!dir.create(bloqueo, showWarnings = FALSE)) {
      shiny::showNotification("Ya existe una operacion en otra sesion.", type = "warning")
      return(invisible(NULL))
    }
    on.exit(unlink(bloqueo, recursive = TRUE, force = TRUE), add = TRUE)
    en_curso(TRUE)
    shinyjs::disable("actualizar_excel")
    shinyjs::disable("actualizar_dta")
    shinyjs::disable("crear_master")
    on.exit({
      en_curso(FALSE)
      e <- fc_estado_bbdd()
      estado(e)
    }, add = TRUE)

    resultado(paste0("Ejecutando: ", etiqueta, "."))
    ok <- tryCatch({
      ejecucion <- list2env(configuracion, parent = globalenv())
      shiny::withProgress(message = etiqueta, value = 0.2, {
        source(script, local = ejecucion, encoding = "UTF-8")
        shiny::incProgress(0.8)
      })
      TRUE
    }, error = function(e) {
      mensaje <- conditionMessage(e)
      message("Error completo en ", etiqueta, ": ", mensaje)
      shiny::showNotification(mensaje, type = "error", duration = NULL)
      resultado(paste0("Operacion interrumpida: ", mensaje))
      FALSE
    })
    if (ok) {
      resultado(paste0(etiqueta, " terminado. Revisa el estado actualizado de las fuentes."))
      shiny::showNotification(paste0(etiqueta, " terminado."), type = "message")
    }
  }

  shiny::observeEvent(input$actualizar_excel, {
    e <- estado()
    if (length(e$faltantes_excel)) {
      shiny::showNotification("No se puede ejecutar: faltan insumos Excel.", type = "error")
      return(invisible(NULL))
    }
    ejecutar("CreaBBDD_Master_Excel.R", etiqueta = "Actualizacion Master Excel")
  })

  shiny::observeEvent(input$actualizar_dta, {
    ejecutar(
      "CreaBBDD_Pipeline_DTA.R",
      configuracion = list(RECREAR_SERIE_DTA = isTRUE(input$reconstruir_dta)),
      etiqueta = if (isTRUE(input$reconstruir_dta)) "Reconstruccion completa DTA" else "Actualizacion DTA"
    )
  })

  shiny::observeEvent(input$crear_master, {
    if (!estado()$master_habilitado) {
      shiny::showNotification("Las fuentes no cumplen la relacion temporal admisible.", type = "error")
      return(invisible(NULL))
    }
    ejecutar("CreaBBDD_Master_BBDD.R", etiqueta = "Construccion Master BBDD")
  })
}

shiny::shinyApp(ui, server)
