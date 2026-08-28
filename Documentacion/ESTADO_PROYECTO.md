# Estado del proyecto — InformeBBDD

_v29 · 26-08-2026_

## Propósito

Construir `dt_ENE_Master.RData`, la base longitudinal canónica de la Encuesta
Nacional de Empleo que consumen InformeRegional y otros análisis ENE.

## Entradas y salidas

- **Entra:** microdatos mensuales `.dta` del INE y libros oficiales de series y
  coyuntura almacenados en `Datos_Ine`.
- **Sale:** todas las bases finales y de paso viven en
  `Datos_Ine/ENE/bbdd_minuta`. Los libros Excel permanecen en
  `Datos_Ine/Exceles/AAAAMM`, pero sus RData ya no se escriben junto a la
  fuente.
- **Caché de lectura:** `Datos_Ine/ENE/cache_ene_bbdd`, un RDS crudo reducido
  por encuesta. No es producto publicable.
- **Metadatos medidos:** `Datos_Ine/ENE/metadatos`, separado de las bases
  productivas y de paso.
- **Documentación:** arquitectura y dominio en
  `Documentacion/MANUAL_InformeBBDD.md`; historia comprobada en
  `Documentacion/CHANGELOG_InformeBBDD.md`.

## Arquitectura vigente

- **Rama microdatos:** `ENE_1_Cubo.R` →
  `ENE_2_Colapso_SexoRegionEdad.R` →
  `ENE_3_Derivadas_Master_dta.R` → `dt_ENE_Stata`.
- **Rama Excel:** `CreaBBDD_Master_Excel.R` ejecuta Series y Coyuntural y
  produce `dt_ENE_Excel`.
- **Unión:** `CreaBBDD_Master_BBDD.R` reconstruye la maestra completa. Stata es
  la columna vertebral y Excel aporta solo llaves exclusivas.
- **Previos:** `ENE_0a_BBDD_Descarga_INE.R` descarga microdatos y
  `ENE_0b_BBDD_Etiquetas.R` mide variables, etiquetas y vigencias.
- **Controles:** `calidad/Calidad_ENE.Rmd` ejecuta por bloques las funciones de
  `calidad/funciones_calidad.R`. Devuelven tablas en memoria y no exportan
  inventarios ni forman parte de la producción.
- **App:** `app.R` orquesta Master Excel, DTA y Master BBDD. No define
  períodos ni etapas: valida entradas, muestra el estado temporal y entrega
  únicamente la opción de reconstruir la serie DTA.
- **Canon:** `Bibliotecas_R/ENE_diccionario_categorias.R` y
  `Bibliotecas_R/fc_diccionario_ene.R` gobiernan nombres y vigencias.

## Decisiones que no deben rediscutirse sin evidencia nueva

- Las tasas agregadas se recalculan desde stocks; nunca se promedian.
- La maestra se reconstruye desde sus dos fuentes y no desde una maestra previa.
- En llaves compartidas manda Stata; Excel aporta únicamente llaves exclusivas.
- Rama económica tendrá dos familias explícitas: la familia sin sufijo se
  construirá con `r_p_rev4cl_caenes` y la familia basada en el lugar donde
  trabaja la persona se identificará siempre con `_b14`.
- Para la familia `r_p`, total, formal e informal deben compartir definición.
  Mientras el Excel anteceda al `.dta`, el total coyuntural se construirá desde
  formal + informal. Cuando ambas fuentes cubran el período, la precedencia se
  resolverá por categoría y tipo de serie: el `.dta` no sustituye las series
  desestacionalizadas exclusivas del Excel.
- El código del trimestre móvil corresponde al mes central.
- CISE-93 y CISO-18 son clasificaciones distintas y sus series no se empalman.
- La vigencia se mide sobre los `.dta`; una ausencia no se convierte en cero
  publicable.
- Los nombres de salida se resuelven contra el diccionario canónico.
- Una sesión debe fallar antes que producir un valor plausible bajo un supuesto
  no declarado.
- `id` e `idisp` no son identificadores personales. Son los dos nombres
  sucesivos del insumo de `Iniciadores_disp`: `id` cubre 201002–201911 e
  `idisp` desde 201912. El identificador longitudinal de personas es `idrph`.
  Ninguna variable se elimina por interpretar su nombre; antes se comprueban
  etiqueta, vigencia y consumidor efectivo.

## Estado actual y próximo paso

- **Estado del código:** implementado el contrato de rama. `ENE_1` produce 63
  columnas `r_p` y 63 `_b14`; Series construye el total `r_p` desde formal e
  informal, y tanto Series como Coyuntural identifican `rama.xlsx` con `_b14`.
  El diccionario genera las 63 categorías `_b14` y el Master rechaza un
  `dt_ENE_Stata` anterior a la migración.
- **Arquitectura de archivos:** ENE_1 lee primero `cache_ene_bbdd`; vuelve al
  DTA si el RDS no existe, cambió el archivo fuente, cambió el vector requerido
  o se fijó `RECREAR_CACHE <- TRUE`. Todas las etapas productivas y diagnósticas
  apuntan a `ENE/bbdd_minuta`. InformeRegional lee exclusivamente esa ruta.
- **Ejecución DTA:** `CreaBBDD_Pipeline_DTA.R` es el punto de entrada de esa
  rama y termina en `dt_ENE_Stata`; no ejecuta la unión final. Por
  defecto detecta y reemplaza solo el último período disponible; permite elegir
  `Periodo_DTA`, rehacer la historia con `RECREAR_SERIE_DTA` e invalidar el
  caché por separado con `RECREAR_CACHE`.
- **Árbol operativo:** la raíz conserva los tres puntos de entrada y los pasos
  previos ENE_0a/ENE_0b. Las cinco etapas coordinadas viven en `intermedios/`;
  calidad contiene solo el Notebook y su módulo de funciones. Los controles,
  inventarios y referencias sustituidos fueron eliminados después de comprobar
  que ningún código activo los cargaba.
- **Metadatos:** ENE_0b fue reducido a tablas R y ahora escribe únicamente
  `ENE/metadatos/ENE_0b_metadatos.RData`. La versión que generaba Markdown y
  CSV fue eliminada después de rescatar sus controles útiles.
- **Continuidad DTA:** el Notebook compara los períodos disponibles en los DTA
  contra ENE_1, ENE_2 y `dt_ENE_Stata`. ENE_4 quedó obsoleto: sus controles de
  ceros duplicaban vigencias y su cobertura genérica de sexo/región no respetaba
  las distintas geometrías de las categorías.
- **Calidad Excel:** el Notebook controla duplicados por separado en Series,
  Coyuntural y Master Excel, y calcula como tabla qué categorías aparecen solo
  en una fuente o en ambas. Los dos inventarios de funciones quedaron obsoletos:
  eran herramientas de transporte de código, no controles del proyecto.
- **Trazabilidad:** el Notebook compara cabeceras con las entradas explícitas
  del changelog y relaciona los ocho RData con sus productores efectivos. La
  fecha sirve como alarma de atraso y la huella MD5 identifica el archivo; no se
  interpreta como prueba de reproducibilidad.
- **Auditoría de código:** `Bibliotecas_R/funciones_auditoria_codigo.R` reemplaza
  la idea útil de los inventarios sin restaurarlos. Recorre cualquier directorio,
  encapsula cada función como texto y detecta duplicados, conflictos y familias
  parecidas mediante huellas; devuelve una tabla principal y no genera archivos.
  La v5 conserva captura, archivos, duplicados, conflictos, familias y errores
  como atributos de esa tabla.
- **Estado de productos:** línea completa regenerada el 22-08-2026 hasta
  `202605`. El cubo tiene 341 columnas, con 63 `r_p` y 63 `_b14`; la identidad
  total `r_p` = formal + informal presenta diferencia máxima de
  `3,64 × 10^-12`. `dt_ENE_Stata` contiene 583 categorías, incluidas las 63
  `_b14`. Series Excel contiene 21 totales `_b14` y la maestra Excel llega a
  `202605`.
- **Estado de la migración:** la caché quedó materializada con 196 RDS y pesa
  350,2 MB frente a 10.993,8 MB de los DTA: reducción de 31,4 veces. Toda la
  línea y un InformeRegional se ejecutaron desde `bbdd_minuta`; se retiraron las
  lecturas de respaldo y las copias antiguas de estas bases.
- **Siguiente paso:** en la próxima entrega, ejecutar Master Excel, Pipeline DTA
  y Master BBDD; luego revisar por bloques el Notebook de calidad.

## Alertas operativas

- `ENE_1_Cubo.R` está configurado actualmente con `RecrearBase <- "Si"`; una
  ejecución reprocesa la serie completa.
- `ENE_0a_BBDD_Descarga_INE.R` tiene `forzar <- TRUE`; una ejecución intenta
  descargar nuevamente toda la serie.
- El Notebook se ejecuta desde RStudio, cuya biblioteca contiene los paquetes
  del proyecto; el `Rscript` externo no comparte esa biblioteca.
- El antiguo `ENE_manual_variables.R` fue eliminado. Era una extracción
  automática de 250 variables, mayoritariamente sin verificar, con textos
  recortados y vigencias erróneas (`id` sin término e `idisp` ausente). No tenía
  consumidores; se retiraron también `fc_manual()`, `fc_vigencia()` y su ruta
  rota de `fc_diccionario_ene.R`.
- La copia de `ENE_vector_categorias.xlsx` que permanecía en
  `Bibliotecas_R/Nueva carpeta` fue eliminada después de comprobar igualdad de
  sus 447 filas con la copia preservada en obsoletos. `fc_base_R.R` fue
  eliminado: sus funciones vigentes ya viven en `funciones_pipeline.R` y
  `funciones_formato.R`, y no conservaba consumidores activos.
- La copia antigua de `funciones_informe.R` fue eliminada. Sus 33 funciones
  compartidas existen en la biblioteca activa; las
  dos funciones adicionales fueron trasladadas a
  `funciones_series_temporales.R`. No se perdió ninguna definición.
- `Bibliotecas_R/Nueva carpeta` quedó vacía. Los doce archivos procedentes de
  ella fueron eliminados después de comprobar que carecían de consumidores o
  que sus funciones útiles ya estaban en bibliotecas vigentes. El cascarón de
  la carpeta persiste únicamente porque OneDrive impide borrarlo.
- `InformeMensualBBDD.Rproj` permite restaurar y guardar el espacio de trabajo.
  Como varios parámetros se heredan si ya existen, una sesión restaurada puede
  alterar una corrida; preferir una sesión limpia y parámetros explícitos.
- La carpeta no es reconocida actualmente como repositorio Git.
