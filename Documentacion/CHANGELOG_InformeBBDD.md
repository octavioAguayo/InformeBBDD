# Changelog -- InformeBBDD

## 2026-08-28 -- Progreso DTA compatible con Shiny

`intermedios/ENE_1_Cubo.R` v11→v12 deja de activar manejadores globales de
`progressr` desde el módulo. La llamada `handlers(global = TRUE)` fallaba al
ejecutarse dentro de la pila reactiva de Shiny con el mensaje `should not be
called with handlers on the stack`. El progreso de consola queda limitado al
bloque `with_progress()` mediante `handler_txtprogressbar`, por lo que el mismo
módulo conserva progreso al ejecutarse directamente y puede ser orquestado por
la app sin alterar el estado global de manejadores.

## 2026-08-26 -- App de orquestacion y aislamiento de parametros

**Corrección posterior**: `intermedios/ENE_1_Cubo.R` (v10→v11) ahora
convierte el nombre `ene-AAAA-MM-*.dta` a `AAAAMM` antes de delimitar una
ventana. El filtro anterior buscaba seis dígitos contiguos, generaba un `NA` y
terminaba intentando leer un archivo llamado `NA`. Si una ventana realmente no
contiene DTA, el proceso se detiene antes de tocar el cubo existente con un
mensaje explícito.

**Archivos**: `app.R` (nuevo v1→v2), `CreaBBDD_Master_Excel.R` (v5→v6),
`CreaBBDD_Pipeline_DTA.R` (v4→v5), `CreaBBDD_Master_BBDD.R` (v5→v6) e
`InformeMensualBBDD.Rproj`.

Se incorpora una app con tres acciones productivas: Master Excel, DTA y Master
BBDD. La app solo entrega `RECREAR_SERIE_DTA` como opcion de reconstruccion;
los orquestadores conservan la decision de periodo, etapas y productos.

Antes de ejecutar Excel se validan sus 19 insumos efectivos bajo la carpeta
AAAAMM mas reciente. `rama.csv` e `informalidad_tasas.xlsx` son archivos
redundantes de la entrega y no forman parte del contrato de lectura.

La app lee los periodos finales de Excel y DTA. Habilita Master BBDD solo si
ambos estan calzados o Excel esta exactamente un periodo adelantado; el
orquestador vuelve a comprobar esa misma condicion antes de construir.

Los tres orquestadores ahora buscan parametros solo en su entorno de ejecucion
y sourcean sus etapas hermanas en el mismo entorno. Esto evita que la app, una
sesion restaurada o un objeto global heredado alteren silenciosamente una corrida.
RStudio deja de restaurar, guardar o conservar historial como estado de ejecucion.
La v2 de la app libera los botones según el fin efectivo de la operación, no
solo cuando cambia el estado leído de los productos: reconstruir Excel puede
terminar dejando los mismos períodos y antes mantenía los controles bloqueados.

Historial completo del proyecto y de sus archivos retirados. Los módulos
vigentes propios son `ENE_0a_BBDD_Descarga_INE.R`,
`ENE_0b_BBDD_Etiquetas.R`, las cinco etapas de `intermedios/` y los tres
orquestadores `CreaBBDD_*.R`. Las bibliotecas que solo este proyecto carga son
`ENE_diccionario_categorias.R` y `fc_diccionario_ene.R`.

Estuvo repartida en dos archivos, `CHANGELOG_InformeBBDD.md` y
`CHANGELOG_Bibliotecas_InformeBBDD.md`. Se fusionaron el 2026-08-12 con el mismo
criterio que InformeRegional el día anterior: **se separa cuando la biblioteca la
carga más de un proyecto o está destinada a heredarse**, y estas bibliotecas no. La
señal de que iban juntas fue que la entrada de CISO quedó partida en dos y una
mitad remitía a la otra. **`CHANGELOG_Bibliotecas_InformeBBDD.md` no debe volver
a aparecer.**

Lo que **no** entra acá y tiene log propio:

| Archivo | Changelog |
|---|---|
| `funciones_pipeline.R`, `funciones_formato.R`, `funciones_ene.R` | `Bibliotecas_R/log/CHANGELOG_general_R.md` |
| `funciones_informe.R`, `funciones_textoActivo.R` | `CHANGELOG_InformeRegional.md` |
| `funciones_series_temporales.R` | `CHANGELOG_series_temporales.md` |
| `funciones_transiciones.R` | `Bibliotecas_R/log/CHANGELOG_Transiciones.md` |

`funciones_ene.R` se queda en el genérico aunque este proyecto la cargue: la
usan cuatro consumidores —InformeBBDD, Crea Transiciones, Informe Transiciones e
`Informalidad_mod_serie.R`— y si su historia viviera acá, un cambio hecho desde
Transiciones quedaría invisible.

Orden: primero las entradas del proyecto por fecha, después el historial por
biblioteca. En ambos casos, más reciente arriba.

---

## 2026-08-22 -- Control de versiones y trazabilidad entra al Notebook

**Archivos**: `ENE_0a_BBDD_Descarga_INE.R` (cabecera v2→v4, alineada con el
registro vigente), `calidad/funciones_calidad.R` (v3→v4),
`calidad/Calidad_ENE.Rmd` (v4→v5), `MANUAL_InformeBBDD.md` (v15→v16) y
`ESTADO_PROYECTO.md` (v27→v28).

Se adaptó el patrón de `InformeCISECISO/calidad/control_versiones.R` sin copiar
su salida HTML. `fc_calidad_versiones()` compara las cabeceras de los R, el
Notebook, el manual y el Estado contra bloques declarativos de archivos del
changelog. `fc_calidad_productos()` controla los ocho RData del proyecto contra
sus productores reales, incluidas etapas intermedias, diccionario y bibliotecas
compartidas; devuelve fecha, fuente más reciente y MD5.

La fecha se documenta como alarma unilateral: demuestra atraso cuando una
fuente es posterior al producto, pero un producto más nuevo no demuestra que se
haya ejecutado con esa fuente. Las tablas viven en memoria dentro del Notebook;
no se agrega un informe que también requiera versionamiento.

La primera ejecución detectó una discrepancia verdadera: ENE_0a declaraba v2 en
su cabecera aunque el changelog ya fijaba v4. Se corrigió la cabecera sin alterar
el código. Las demás aparentes diferencias provenían de etiquetas históricas
como `**Intermedios**` o `**Archivos productivos**`; el lector las reconoce como
bloques declarativos sin confundirlas con prosa histórica.

## 2026-08-22 -- Estado, metadatos y cierre normativo

**Archivos**: `ENE_0b_BBDD_Etiquetas.R` (v16→v17),
`calidad/Calidad_ENE.Rmd` (v3→v4), `MANUAL_InformeBBDD.md` (v14→v15) y
`ESTADO_PROYECTO.md` (v26→v27, trasladado a `Documentacion/`).

El Estado dejó la raíz para cumplir la ubicación documental del proyecto.
ENE_0b separa sus tablas técnicas de las bases productivas: escribe ahora
`Datos_Ine/ENE/metadatos/ENE_0b_metadatos.RData`, y el Notebook consume esa
misma ruta. El archivo existente se trasladó sin regenerar su contenido.

Las carpetas vacías `cuarentena` y `obsoletas` ya no existen. El Estado registra
la auditoría v5 como tabla con atributos y deja la ejecución del Notebook como
control periódico desde RStudio, no como una primera ejecución pendiente.

## 2026-08-22 -- Obsoletos vaciado y referencia histórica retirada

El usuario eliminó el contenido completo de `Bibliotecas_R/obsoletas` después
de cerrar su evaluación. `fc_diccionario_ene.R` v8 retira el comentario que
señalaba `ENE_vector_categorias.xlsx` como registro del renombre, pues el libro
ya no existe. Se conserva la regla ejecutiva: no hay puente automático de
nombres legacy porque ocultaría migraciones parciales y podría duplicar llaves.

## 2026-08-22 -- Cierre de cuarentena del vector histórico de categorías

`ENE_vector_categorias.xlsx` pasó de `Bibliotecas_R/cuarentena` a
`Bibliotecas_R/obsoletas`. La inspección de sus 447 equivalencias confirmó que
es la lista histórica de trabajo de la migración: conserva 303 filas marcadas
`Pendiente`, pese a que el pipeline ya publica bajo el canon. No tiene
consumidores activos y su función quedó sustituida por
`ENE_diccionario_categorias.R` y las validaciones ejecutables asociadas.

La cuarentena queda sin artefactos pendientes; se conserva únicamente su
`README.md` para dejar explícito el criterio de entrada y salida.

## 2026-08-22 -- Retiro del falso manual operativo de variables

`ENE_manual_variables.R` pasó de `Bibliotecas_R/Nueva carpeta` a obsoletos.
Aunque reunía 250 filas extraídas del manual INE, la mayoría no estaba
verificada y varias descripciones quedaron mezcladas durante la extracción. La
tabla tampoco era confiable como vigencia: mantenía `id` sin fecha de término,
omitía `idisp` y asignaba a `b14_rev4cl_caenes` una vigencia incompatible con
su presencia efectiva en los microdatos.

Ningún código activo llamaba `fc_manual()` ni `fc_vigencia()`, y la ruta que
usaban apuntaba a un archivo inexistente. `fc_diccionario_ene.R` v7 elimina
ambas funciones, `RUTA_MANUAL` y `MANUAL_EDICION`. La producción continúa
filtrando exclusivamente con `vigencia_desde` del diccionario canónico; ENE_0b
mide por separado la presencia real de las variables en los DTA.

## 2026-08-22 -- Duplicado del vector eliminado y fc_base retirado

Se eliminó `Bibliotecas_R/Nueva carpeta/ENE_vector_categorias.xlsx` después de
comparar las dos planillas completas: sus 447 filas y cuatro columnas eran
idénticas a la copia ya preservada en obsoletos. La diferencia de tamaño era
sólo binaria, no de contenido.

`fc_base_R.R` pasó desde `Nueva carpeta` a obsoletos. Era el antecesor de la
separación vigente: `fc_init_motor()`, `fc_exigir()` y `fc_exigir_valor()` están
en `funciones_pipeline.R`, mientras `fc_Form_Num()` está en
`funciones_formato.R`. Ningún archivo activo carga `fc_base_R.R`; sus referencias
restantes pertenecen a copias antiguas que siguen bajo análisis.

## 2026-08-22 -- Copia antigua de funciones_informe retirada

`Bibliotecas_R/Nueva carpeta/funciones_informe.R` pasó a obsoletos después de
comparar sus definiciones con las bibliotecas activas. Sus 33 funciones
compartidas están presentes en `Bibliotecas_R/funciones_informe.R`. Las únicas
dos definiciones adicionales, `fc_generar_predicciones()` y
`fc_tendencia_lp()`, ya viven en `funciones_series_temporales.R`. La copia vieja
además dependía del retirado `fc_base_R.R`.

## 2026-08-22 -- Eliminación definitiva de los restos de Nueva carpeta

Se eliminaron de `Bibliotecas_R/obsoletas` los doce archivos cuya procedencia
era `Bibliotecas_R/Nueva carpeta`. Ninguno tenía consumidores activos ni
conocimiento exclusivo defendible: las funciones útiles ya existen en las
bibliotecas vigentes, los inventarios eran copias de transporte y los dos
changelogs habían sido absorbidos por los registros actuales.

La eliminación alcanzó `ENE_manual_variables.R`, `fc_base_R.R`, las copias de
`funciones_informe.R`, `funciones_textoActivo.R`, `funciones_CreaBBDD.R`,
`funciones_ene_resp.R`, `funciones_ene.R`, `funciones_estadisticas.R`,
`funciones_transiciones.R`, `Nueva_carpeta_funciones_inventario.R` y los dos
changelogs antiguos. No se tocó ningún archivo de obsoletos con otra
procedencia.

## 2026-08-22 -- Nueva carpeta deja de ser una ubicación ambigua

Por decisión de arquitectura, los nueve archivos que todavía permanecían en
`Bibliotecas_R/Nueva carpeta` pasaron íntegros a `Bibliotecas_R/obsoletas`. Su
eventual rescate se evaluará desde allí; permanecer junto a las bibliotecas
vigentes les daba una apariencia operativa que no correspondía.

Se trasladaron dos changelogs antiguos y las copias de
`funciones_CreaBBDD.R`, `funciones_ene_resp.R`, `funciones_ene.R`,
`funciones_estadisticas.R`, `funciones_inventario.R`,
`funciones_transiciones.R` y `funciones_textoActivo.R`. Como ya existía otro
`funciones_inventario.R` en obsoletos, la copia procedente de esa carpeta se
renombró `Nueva_carpeta_funciones_inventario.R`; no se sobrescribió evidencia.

## 2026-08-22 -- Diccionario de códigos declarado obsoleto

**Archivos**: `ENE_Diccionario_Codigos.R` (v2→v3, obsoleto) y
`ESTADO_PROYECTO.md` (v18→v19).

El archivo definía 21 tablas manuscritas sin consumidores activos y ocho
funciones, siete sin llamadas. `fc_region_label()` además competía con la
definición canónica de `funciones_ene.R`. Variables, códigos, etiquetas y
vigencias se obtienen hoy desde las tablas medidas por ENE_0b; las
recodificaciones utilizadas viven en `funciones_ene.R`.

No se encontró una regla exclusiva que justificara rescatar una transcripción
parcial. El diccionario pasó a obsoletos y la cuarentena quedó reducida a
`ENE_vector_categorias.xlsx`.

## 2026-08-22 -- Diagnóstico DTA declarado obsoleto

**Archivos**: `InformeBBDD_ENE_Diagnostico_dta.R` (v4→v5, obsoleto) y
`ESTADO_PROYECTO.md` (v17→v18).

El diagnóstico DTA contenía inventarios manuales de objetos y fórmulas y
exportaba un libro de 500 líneas de código. Su única validación ejecutable
exclusiva aparente era la llave duplicada de `dt_ENE_Stata`, ya cubierta por
`fc_calidad_dta()`. Pasó a obsoletos sin rescatar tablas escritas a mano.

La cuarentena queda reducida al diccionario de códigos y al libro de auditoría
de categorías.

## 2026-08-22 -- Primera purga de cuarentena

**Obsoletos**: `InformeBBDD_calidadVariables.R` (v2→v3),
`InformeBBDD_ENE_Diagnostico_Excel.R` (v3→v4),
`InformeBBDD_ENE_Diagnostico_Master.R` (v4→v5),
`ENE_0_Etiquetas_dta.R` (v7→v8) e
`InformeBBDD_ENE_0b_BBDD_Etiquetas_con_reportes.R` (v15→v16).
**Documentación**: `ESTADO_PROYECTO.md` (v16→v17).

La comparación DTA/Excel y los diagnósticos Excel/Master ya están absorbidos en
las tablas del Notebook. ENE_0 está completamente contenido en ENE_0b, y la
versión de ENE_0b con generadores Markdown/CSV no conserva lógica tabular que no
exista en la versión activa. Los cinco archivos pasaron de cuarentena a
obsoletos sin modificar código productivo.

Permanecen bajo análisis únicamente el diagnóstico DTA, el diccionario de
códigos y el libro de auditoría de categorías.

## 2026-08-22 -- Huella genérica de funciones para controlar dispersiones

**Archivo**: `ESTADO_PROYECTO.md` (v13→v14). La herramienta compartida nueva,
`Bibliotecas_R/funciones_auditoria_codigo.R` (v4), se versiona en
`Bibliotecas_R/log/CHANGELOG_general_R.md`.

No se restauraron los inventarios obsoletos. Su propósito útil se reconstruyó
como `fc_auditar_funciones(directorio)`: encapsula cada definición en campos de
texto original y normalizado, registra huellas de funciones, archivos y captura,
y separa duplicados exactos, conflictos y posibles funciones hermanas. La salida
son tablas en memoria y los archivos inspeccionados nunca se ejecutan.

La primera ejecución real falló al recorrer argumentos vacíos de llamadas R. La
v3 salta esos nodos sintácticos y conserva cualquier otro error como falla real.
La segunda ejecución encontró operadores que eran expresiones completas; la v4
los descarta antes de comparar el símbolo de asignación.
`ESTADO_PROYECTO.md` sube de v14 a v16.

## 2026-08-22 -- Control por etapa Excel y retiro de inventarios

**Archivos**: `calidad/funciones_calidad.R` (v2→v3),
`calidad/Calidad_ENE.Rmd` (v2→v3), `ESTADO_PROYECTO.md` (v12→v13),
`Inventario_Funciones.R` (v2→v3, obsoleto) y
`funciones_inventario.R` (v2→v3, obsoleto).

El Notebook carga `BBDD_Series`, `BBDD_Coyuntural` y el Master Excel para
controlar duplicados en cada etapa por separado. También devuelve una tabla de
composición con categorías exclusivas de Series, exclusivas de Coyuntural y
compartidas; sustituye la parte comprobable del diagnóstico Excel sin exportar
un libro.

Los dos inventarios pasaron de cuarentena a obsoletos. Su propósito era copiar
cuerpos de funciones entre conversaciones sin acceso simultáneo a archivos;
no contienen reglas de dominio ni controles necesarios en el entorno actual.

## 2026-08-22 -- Continuidad directa de períodos y retiro de ENE_4

**Archivos**: `calidad/funciones_calidad.R` (v1→v2),
`calidad/Calidad_ENE.Rmd` (v2), `ESTADO_PROYECTO.md` (v11→v12) y
`InformeBBDD_ENE_4_Calidad_Categorias.R` (v6→v7, obsoleto).

Se descartaron los controles de ceros iniciales e intermedios: eran síntomas
posteriores de una vigencia incorrecta, que ENE_0b mide directamente sobre las
variables de cada DTA. También se descartó exigir tres sexos y diecisiete
regiones a toda categoría, porque las geometrías legítimas de DTA, Excel y edad
son distintas.

El control sustituto compara los períodos potenciales observados en los nombres
de los DTA con los períodos reales de ENE_1, ENE_2 y `dt_ENE_Stata`, e informa
faltantes y extras como tablas. Como ENE_4 no conserva lógica exclusiva después
de esa sustitución, salió de cuarentena hacia `Bibliotecas_R/obsoletas`.

## 2026-08-22 -- Calidad en un Notebook y cuarentena del código sustituido

**Nuevos**: `calidad/Calidad_ENE.Rmd` y
`calidad/funciones_calidad.R` (v1). **Reemplazado**:
`ENE_0b_BBDD_Etiquetas.R` (v14→v16; versión con reportes preservada como v15).
**Documentación**: `MANUAL_InformeBBDD.md` (v13→v14) y
`ESTADO_PROYECTO.md` (v10→v11).

Los cinco intentos de calidad se sustituyeron por un R Notebook ejecutable por
bloques. Las funciones nuevas cargan sus propias bases y devuelven tablas para
DTA, Excel, diferencias entre fuentes, reconstrucción del Master, duplicados y
canon de categorías. No escriben Excel, CSV, TXT ni Markdown; el Notebook solo
muestra la tabla del bloque que se decide ejecutar.

ENE_0b conservaba generadores de dos Markdown y tres CSV. Se preservó esa
versión completa en cuarentena y se reconstruyó el archivo activo para producir
solo tablas R: variables, categorías, vigencias, huecos, estabilidad de
etiquetas, clasificación de los vectores de ENE_1 y CISO. Su único archivo
persistente es `ENE/bbdd_minuta/ENE_0_etiquetas.RData`, que permite abrir esas
tablas desde el Notebook sin releer 196 DTA.

El RData vigente, con diez tablas y cobertura hasta `202605`, se trasladó desde
`Datos_Ine/Procesados` a esa ruta canónica; no se regeneró ni se dejó una copia
antigua.

Los diagnósticos anteriores, `calidadVariables.R`, los dos inventarios, el censo
anterior, el diccionario de códigos y `ENE_vector_categorias.xlsx` quedaron en
`Bibliotecas_R/cuarentena`. Ningún código activo carga esa carpeta. Sintaxis
verificada para el módulo, el Notebook y ENE_0b; la ejecución funcional quedó
pendiente en RStudio porque el `Rscript` externo no tiene acceso a su biblioteca
de paquetes instalada.

## 2026-08-22 -- Separación del árbol operativo, intermedios y calidad

**Puntos de entrada**: `CreaBBDD_Pipeline_DTA.R` (v3→v4) y
`CreaBBDD_Master_Excel.R` (v4→v5).

**Intermedios**: `ENE_1_Cubo.R` (v9→v10),
`ENE_2_Colapso_SexoRegionEdad.R` (v3→v4),
`ENE_3_Derivadas_Master_dta.R` (v6→v7),
`CreaBBDD_Excel_Series.R` (v7→v8) y
`CreaBBDD_Excel_Coyuntural.R` (v5→v6).

**Calidad**: `ENE_4_Calidad_Categorias.R` (v4→v5),
`ENE_Diagnostico_dta.R` (v2→v3), `ENE_Diagnostico_Excel.R` (v1→v2),
`ENE_Diagnostico_Master.R` (v2→v3) y `calidadVariables.R` (v1).

**Retirados para análisis**: `ENE_0_Etiquetas_dta.R` (v5→v6),
`ENE_Diccionario_Codigos.R` (v1), `Inventario_Funciones.R` (v1) y
`funciones_inventario.R` (v1). **Documentación**:
`MANUAL_InformeBBDD.md` (v12→v13) y `ESTADO_PROYECTO.md` (v9→v10).

La raíz quedó reservada para los tres puntos de entrada y los pasos previos
ENE_0a/ENE_0b. Las etapas productivas que no se ejecutan por sí solas pasaron a
`intermedios/`, y los controles posteriores a `calidad/`. Los dos orquestadores
se actualizaron para resolver las nuevas rutas sin cambiar cálculos ni salidas.

Los inventarios nacieron como mecanismo para transportar cuerpos de funciones a
un chat que no podía leer simultáneamente sus archivos de origen y destino; en
el entorno actual generan versiones antiguas y ya no aportan seguridad. Junto
con el diccionario de códigos y el censo anterior se trasladaron, sin borrarse,
a `Bibliotecas_R/por_analizar`. `Bibliotecas_R/obsoletas` queda como cuarentena
temporal y ninguna de las dos carpetas puede ser cargada por código activo.

## 2026-08-22 -- Pipeline DTA separado de la unión final

**Archivos**: `CreaBBDD_Master_DTA.R` (v1→v2, retirado),
`CreaBBDD_Pipeline_DTA.R` (v3), `MANUAL_InformeBBDD.md` (v10→v12) y
`ESTADO_PROYECTO.md` (v7→v9).

Se agregó un orquestador que detecta el DTA más reciente —o acepta
`Periodo_DTA`— y ejecuta en orden ENE_1, ENE_2 y ENE_3. La operación normal
reemplaza solo el período elegido y conserva el resto del cubo;
`RECREAR_SERIE_DTA` reserva la reconstrucción histórica para una decisión
explícita. `RECREAR_CACHE` permanece independiente, porque recalcular las
categorías desde un RDS crudo válido no exige volver a decodificar el Stata.

La primera versión también ejecutaba `CreaBBDD_Master_BBDD.R`. Se descartó esa
arquitectura porque mezclaba la producción de una fuente con la unión de ambas:
Excel y DTA deben terminar por separado en `dt_ENE_Excel` y `dt_ENE_Stata`, y
solo después el Master BBDD construye `dt_ENE_Master`. Por ello el archivo se
renombró de Master DTA a Pipeline DTA y quedó limitado a tres etapas.

La validación inicial cubre sintaxis, resolución de las tres etapas y
selección automática del período. La primera regeneración productiva queda
pendiente para medir su tiempo real sobre caché.

La validación rechaza además un `Periodo_DTA` sin archivo fuente, antes de que
ENE_1 pueda continuar con una ventana vacía.

## 2026-08-22 -- Cierre de la migración de rutas y limpieza de duplicados

**Archivos**: `ENE_1_Cubo.R` (v8→v9), `MANUAL_InformeBBDD.md`
(v9→v10), `ESTADO_PROYECTO.md` (v6→v7) y, en InformeRegional,
`Prepara_bbdd.R` (v6→v7).

La prueba de ruta se hizo renombrando la maestra antigua a
`dt_ENE_Master2.RData`; InformeRegional generó el documento igualmente, lo que
demostró que cargó `ENE/bbdd_minuta/dt_ENE_Master.RData`. Se retiraron las
lecturas transitorias desde `Procesados` tanto en ENE_1 como en InformeRegional.

La caché materializada contiene 196 RDS, pesa 350,2 MB frente a 10.993,8 MB de
los DTA originales y alcanza una reducción de 31,4 veces. Tras verificar las
bases nuevas, se eliminaron únicamente las cuatro copias antiguas del pipeline
DTA en `Procesados` y los tres RData Excel de `Exceles/202605`; no se tocaron
otros productos.

## 2026-08-22 -- Caché cruda y centralización en ENE/bbdd_minuta

**Archivos productivos**: `ENE_1_Cubo.R` (v7→v8),
`ENE_2_Colapso_SexoRegionEdad.R` (v2→v3),
`ENE_3_Derivadas_Master_dta.R` (v5→v6),
`ENE_4_Calidad_Categorias.R` (v3→v4), `CreaBBDD_Excel_Series.R`
(v6→v7), `CreaBBDD_Excel_Coyuntural.R` (v4→v5),
`CreaBBDD_Master_Excel.R` (v3→v4) y `CreaBBDD_Master_BBDD.R` (v4→v5).

**Controles y documentación**: `ENE_Diagnostico_dta.R` (v1→v2),
`ENE_Diagnostico_Master.R` (v1→v2), `ENE_Diagnostico_Excel.R` (v1),
`MANUAL_InformeBBDD.md` (v8→v9), `ESTADO_PROYECTO.md` (v5→v6) y, en
InformeRegional, `Prepara_bbdd.R` (v5→v6).

ENE_1 incorpora una caché cruda por encuesta en
`Datos_Ine/ENE/cache_ene_bbdd`. Lee el RDS cuando coincide con el DTA, el vector
esperado y la versión de lectura; en caso contrario vuelve al Stata, selecciona
solo las variables requeridas, elimina etiquetas Haven y recrea el RDS.
`RECREAR_CACHE` permite invalidación voluntaria cuando una duda de lógica no
cambia nombres de columnas.

Todas las bases finales y de paso —DTA, Excel y Master— pasan a escribirse en
`Datos_Ine/ENE/bbdd_minuta`. Los diagnósticos leen esa misma ubicación.
InformeRegional busca primero la maestra nueva y mantiene lectura de respaldo
desde `Procesados` durante la transición. Los RData antiguos no se movieron ni
eliminaron.

Los doce scripts modificados pasan parseo con R 4.5.2 y la revisión de rutas no
encuentra escrituras productivas nuevas hacia `Procesados`. Todavía no se ha
materializado la caché ni regenerado las bases en `bbdd_minuta`.

## 2026-08-22 -- Guardia documental para id, idisp e idrph

**Archivos**: `MANUAL_InformeBBDD.md` (v7→v8) y
`ESTADO_PROYECTO.md` (v4→v5).

Durante la revisión del futuro caché DTA se propuso retirar `id` por interpretar
su nombre como un identificador de persona. La medición de vigencias evitó el
error: `id` aparece de forma continua entre 201002 y 201911, `idisp` desde
201912 hasta 202605, y ENE_1 unifica ambos nombres para construir
`Iniciadores_disp`. El identificador longitudinal de personas es `idrph`, no
ninguna de esas dos columnas.

Se incorpora como regla estable que ninguna variable se elimina por semántica
inferida desde su nombre. Antes deben comprobarse etiqueta, vigencia y consumidor
efectivo. Retirar `id` habría eliminado silenciosamente 118 períodos válidos de
la serie. No se modificó código ni se regeneraron productos.

## 2026-08-22 -- Validación de productos y cierre aguas abajo

**Archivos**: `MANUAL_InformeBBDD.md` (v6→v7) y
`ESTADO_PROYECTO.md` (v3→v4). Cambio coordinado en InformeRegional:
`crea_objetos_sector.R` (v11→v12).

La ejecución completa terminó sin errores. `ENE_1_cubo.RData` contiene 341
columnas: 63 `r_p` y 63 `_b14`. La diferencia máxima observada en la identidad
total `r_p` = formal + informal es `3,64 × 10^-12`, atribuible a precisión de
punto flotante. `dt_ENE_Stata` contiene 4.300.811 filas, 583 categorías y las
63 categorías `_b14`, con período máximo 202605. La rama Series Excel contiene
476.823 filas, 236 categorías y 21 totales `_b14`; su maestra contiene 479.497
filas, 441 categorías y llega igualmente a 202605.

Con el dato ya coherente, InformeRegional retiró `var_rama` y la advertencia de
discrepancia de `nota_rama`. `dta_rezagado` no se eliminó porque mantiene otros
usos legítimos de control de disponibilidad.

## 2026-08-21 -- Implementación de las familias de rama r_p y b14

**Archivos**: `ENE_1_Cubo.R` (v6→v7), `CreaBBDD_Excel_Series.R`
(v5→v6), `CreaBBDD_Excel_Coyuntural.R` (v3→v4),
`CreaBBDD_Master_BBDD.R` (v3→v4), `ENE_diccionario_categorias.R`
(v1→v2), `MANUAL_InformeBBDD.md` (v5→v6) y
`ESTADO_PROYECTO.md` (v2→v3).

`ENE_1` recalcula las 63 columnas de rama existentes con
`r_p_rev4cl_caenes` y agrega 63 columnas paralelas calculadas con
`b14_rev4cl_caenes`. La familia nueva conserva `_b14` en el nombre interno y
publicado; formal e informal permanecen como atributos terminales. El total
`r_p` se restringe a la misma partición `ocup_form` y una guarda exige que sea
idéntico a formal + informal.

En Series, `informalidad_rama.xlsx` aporta formal e informal `r_p` y el lector
construye sus 21 totales fila a fila. `rama.xlsx` pasa a publicar 21 categorías
`_b14`; Coyuntural adopta el mismo nombre. El diccionario duplica de manera
controlada las 63 filas de rama para b14, fija vigencia 201302 para sus totales
y 201708 para sus aperturas, mientras toda la familia `r_p` rige desde 201708.

El Master conserva su precedencia por llave —DTA en coincidencias y Excel en
categorías exclusivas— y ahora se niega a unir si `dt_ENE_Stata` no contiene las
63 categorías `_b14`. Esto evita mezclar una rama Excel migrada con un cubo
anterior.

Los ocho scripts involucrados parsean con R 4.5.2. Los conteos estáticos de
ENE_1 son 63 columnas `r_p`, 63 `_b14` y 21 totales `r_p` definidos sobre la
partición de formalidad. No se regeneraron aún los RData; la validación del
producto queda como siguiente corrida obligatoria.

## 2026-08-21 -- Contrato para las dos definiciones de rama económica

**Archivos**: `MANUAL_InformeBBDD.md` (v4→v5) y
`ESTADO_PROYECTO.md` (v1→v2).

Se documenta la decisión metodológica que deberá implementarse en toda la
línea. Las 63 categorías actuales de rama —21 ramas por total, formal e
informal— pasarán a usar `r_p_rev4cl_caenes`; se crearán otras 63 con
`b14_rev4cl_caenes`, identificadas siempre por `_b14`. En el lector Excel,
`rama.xlsx` alimentará la familia `_b14`, mientras
`informalidad_rama.xlsx` aportará formal e informal `r_p` y permitirá construir
su total coyuntural antes de la llegada del `.dta`.

También se fija que la precedencia no puede resolverse solo comparando fechas:
el `.dta` manda en categorías equivalentes, pero no reemplaza series
desestacionalizadas ni otros productos exclusivos del Excel. InformeRegional
dejará de corregir o advertir esta diferencia cuando reciba la maestra ya
coherente; la responsabilidad queda en InformeBBDD.

No se cambió código ni se regeneraron productos. El contrato queda pendiente de
implementación y verificación conjunta desde ENE_1 hasta el Master.

## 2026-08-21 -- Documentación reunida dentro del proyecto

**Archivos**: `MANUAL_InformeBBDD.md` (v3→v4),
`CHANGELOG_InformeBBDD.md` (trasladado) y `ESTADO_PROYECTO.md` (nuevo, v1).

El manual y el changelog salen de `Bibliotecas_R/log/` y pasan a
`InformeBBDD/Documentacion/`. Ambos describen este proyecto, no una biblioteca
compartida; mantenerlos junto al código hace visible su ubicación para cualquier
persona o sesión de Codex que entre por `Proyectos_R/AGENTS.md`.

Se crea `ESTADO_PROYECTO.md` en la raíz como relevo breve: producto vigente,
arquitectura, decisiones que no deben rediscutirse, estado comprobado hasta
202605, alertas operativas y próximo paso. También inventaría los archivos que
no forman parte clara del pipeline canónico, sin moverlos ni eliminarlos.

No cambió código productivo ni se regeneró ninguna base durante esta
reorganización.

La verificación reparó además dos referencias documentales que apuntaban a
nombres inexistentes: el log general de bibliotecas es `CHANGELOG_general_R.md`
y el de Transiciones es `CHANGELOG_Transiciones.md`. Se dejó registrada, sin
moverla, la ubicación anómala de `ENE_manual_variables.R`.

---

## 2026-08-14 -- Se retira el CSV de etiquetas sin consumidores

**Archivo**: `ENE_0b_BBDD_Etiquetas.R` (v13→v14).

`ENE_0b_catalogo_etiquetas.csv` se escribía en `Datos_Ine/Procesados`, pero no
tenía ningún consumidor. Trasladarlo a `Bibliotecas_R` habría convertido una
salida abandonada en una falsa definición compartida.

Se eliminó el CSV y su llamada de escritura. `catalogo_etiquetas` se mantiene
solo como objeto intermedio durante la ejecución porque alimenta los controles
de estabilidad, categorías nuevas y el reporte CISO. El script parsea
correctamente y no quedan referencias de código al archivo retirado.

---

## 2026-08-12 -- Limpieza de comentarios y fc_init_motor en los diez archivos

**Archivos**: `ENE_2_Colapso_SexoRegionEdad.R` (v1→v2),
`ENE_3_Derivadas_Master_dta.R` (v4→v5), `ENE_4_Calidad_Categorias.R` (v2→v3),
`CreaBBDD_Excel_Series.R` (v4→v5), `CreaBBDD_Excel_Coyuntural.R` (v2→v3),
`CreaBBDD_Master_Excel.R` (v2→v3), `CreaBBDD_Master_BBDD.R` (v2→v3).
**Versionados por primera vez**: `ENE_Diagnostico_dta.R` (v1),
`ENE_Diagnostico_Master.R` (v1).

Los diez pasan la pasada de comentarios de `CONVENCIONES_Proyectos_ENE.md` §4:
historia al changelog, dominio al manual, trampas pegadas al código. Ninguno
tenía el nombre del archivo en su línea de versión; los dos `Diagnostico` no
tenían línea de versión.

**Los únicos cambios de código son los `library()` y tres `source()` muertos.**
Verificado comparando el código sin comentarios contra los originales.

---

### Tres archivos sourceaban un módulo que no existe

`ENE_4_Calidad_Categorias.R`, `ENE_Diagnostico_dta.R` y
`ENE_Diagnostico_Master.R` cargaban `funciones_CreaBBDD.R`, disuelto en la
partición del 2026-08-10. **Los tres estuvieron rotos dos días.**

No se notó porque ninguno produce base: son control y documentación, y se corren
cuando alguien quiere mirar, no en la cadena de producción. Es el mismo caso que
`fc_archivos_ene` en `ENE_1`, pero al revés: allá el pipeline se caía y la sesión
sucia lo tapaba; acá nadie los corrió.

Reemplazados por el guard de `funciones_pipeline.R` más `funciones_formato.R`
donde hacía falta.

---

### `library()` retirado de los cuatro CreaBBDD

Los cuatro cargaban paquetes con `library()` a pelo, contra la convención §5.9
adoptada el 2026-08-12. Ahora usan el guard y `fc_init_motor()`, con la lista
medida contra el uso real. Los cuatro `ENE_*` ya la usaban.

---

### Lo que salió de las cabeceras al manual

De `CreaBBDD_Master_BBDD.R`, que era el más cargado —45% de comentarios—: que la
maestra **se reconstruye completa en cada corrida** y por qué —partir de la
anterior arrastra corrupción, porque un `anti_join` nunca corrige filas
existentes—; que `dt_ENE_Stata` es la columna vertebral y `dt_ENE_Excel` aporta
solo lo que Stata no puede tener; que en llaves compartidas mandan los valores de
Stata; y los tres `modo_master`.

De `CreaBBDD_Master_Excel.R`: que es el único punto de entrada de su rama, que
los sub-scripts **heredan `Trim_Actual`** del entorno global —lo que evita
correrlos por separado con períodos distintos— y que el período se **deduce del
directorio** porque un literal por defecto envejece en silencio.

De `ENE_Diagnostico_Master.R`: el diagrama de las dos ramas y la ventana de
disponibilidad de 15 horas. Ese diagrama estaba en un comentario de un archivo
de diagnóstico, que es el último lugar donde alguien lo buscaría.

---

### Trampas conservadas

Que `resumen_Edad` de `ENE_2` trae **solo stocks** y las tasas se recalculan en
`ENE_3` desde los stocks sumados, nunca promediando. Que `ENE_4` y los dos
`Diagnostico` no modifican nada. Y en `CreaBBDD_Master_BBDD.R`, la advertencia de
que su `anti_join` incluye `categoria` en la llave: si una fuente quedara sin
migrar, no fallaría — publicaría cada medida dos veces.

---

### Un puntero muerto que queda anotado

`ENE_Diagnostico_Master.R` cita `CreaBBDD_Master_dta.R` como el script que une
las dos fuentes. El archivo se llama `CreaBBDD_Master_BBDD.R`. Es el mismo tipo
de fósil que `CreaBBDD_desde_DTA_v3.R` en la cabecera de `ENE_1_Cubo.R`: nombre
viejo que sobrevivió al renombre.

---

## 2026-08-12 -- CISO-18 incorporado al cubo y a los dos pipelines

**Archivos**: `ENE_1_Cubo.R` (v3→v5), `CreaBBDD_Excel_Series.R` (v4→v5),
`ENE_3_Derivadas_Master_dta.R` (v4→v5).
**Nuevos**: `ENE_0a_BBDD_Descarga_INE.R` (v4), `ENE_0b_BBDD_Etiquetas.R` (v14).
`ENE_diccionario_categorias.R` (v1→v2) se registra en
`CHANGELOG_Bibliotecas_InformeBBDD.md`.

CISO-18 reemplaza a CISE-93 como clasificación de situación en la ocupación. No
es CISE con una categoría más: es otro acuerdo OIT, con preguntas propias sobre
dependencia organizativa, dependencia económica y riesgo económico, que reasigna
a toda la población ocupada desde cero.

**Por qué existe.** Un repartidor de aplicación no cabe en CISE. No es cuenta
propia —no fija precio ni elige clientes— ni asalariado —sin contrato, pone su
vehículo y asume el riesgo—. `Contratista dependiente` nombra esa contradicción,
y sus cinco aperturas son los criterios que deciden de qué lado cae. Es la única
forma de medir el trabajo de plataforma, que hoy queda repartido entre cuenta
propia y asalariado informal sin poder distinguirse.

El cubo pasa de 194 a 278 columnas: **84 categorías CISO**, cada una en sus tres
niveles de formalidad (total, formal, informal).

---

### Qué se capturó y qué no

`ciso2` (7 categorías) y `ciso3_b` (19) entran como opcionales, con vigencia
**202002** medida sobre los 196 `.dta`. `ciso1` no se trae: sus dos valores son
agrupación de `ciso2` y se calculan con `%in% 1:2` y `%in% 3:7` directo en el
`summarise`, sin columna intermedia.

`ciso3_a` **no se captura**. Es la forma alternativa del tercer nivel: parte a
los contratistas por la categoría a la que se parecen en vez de por tipo de
dependencia, y tiene 18 categorías contra 19. El INE publica la forma B — sus 19
calzan una a una, en orden, con las columnas de `categoria_ciso_tnj.xlsx`.

---

### Dos clasificaciones que no se empalman

`ciso2` es el empalme **de lógica**, no de serie. Los siete conceptos son los
mismos de CISE salvo el que se creó, así que el instrumento puede seguir
pensando igual aunque las cifras no se encadenen.

El nombre canónico es el de CISE más el token ` ciso`, invariante (R5), para que
la diferencia salga por `join` sobre el nombre base y no por una tabla de
correspondencia escrita a mano:

| CISO | CISE |
|---|---|
| `Empleadores ciso` | `Empleadores` |
| `Cuenta propia ciso` | `Cuenta propia` |
| `Asalariados privados ciso` | `Asalariados privados` |
| `Asalariados públicos ciso` | `Asalariados públicos` |
| `Servicio doméstico ciso` | `ServDom_afuera` + `ServDom_adentro` |
| `Familiar no remunerado ciso` | `Familiares no remunerados` |
| `Contratista dependiente ciso` | **sin par: la categoría es nueva** |

**No se encadenan ni las de nombre idéntico.** Las preguntas nuevas reasignan
casos desde y hacia todas las categorías, no solo hacia contratistas. La
diferencia de cada par mide cuánto reasignó CISO, período a período desde
202002; no es una serie continua.

**Trampa de agrupación**: en CISE, familiar no remunerado va con los
Independientes. En CISO cae en Dependiente. Es decisión del INE, y significa que
`Independientes` y `Independientes ciso` agrupan distinto. Quien las ponga en la
misma tabla va a ver un salto que no es del mercado laboral sino de la
clasificación.

---

### Por qué los nombres se declaran y no se heredan del .dta

Las etiquetas del `.dta` describen **de dónde viene** el caso, no dónde queda.
Los códigos 5, 6 y 7 de `ciso3_b` se etiquetan "Trabajador/a por cuenta propia
con dependencia…" y el 8 y el 9 "Asalariado/a con…", pero los cinco son
contratistas: caen en `ciso2 == 3`. Construir el nombre publicado desde ahí
habría publicado cinco contratistas disfrazados.

Y son inconsistentes entre sí: "corta duración" para el privado, "baja duración"
para público y doméstico, para lo mismo. El Excel usa "corta" en las tres y el
canon sigue al Excel.

El calce con el Excel es **por posición de columna**, no por encabezado: el libro
del tercer nivel dice "Empleadores/as con empresa regisrada como sociedad", sin
la t. Es error de tipeo del INE, en los dos libros y en las 20 hojas.

---

### Verificación de que los dos caminos convergen

Los 28 nombres del lector de Excel están todos en el diccionario: ninguno se
publica aparte. El Excel aporta las 28 de nivel total y el cubo las mismas 28
más las 56 de formalidad, que el Excel no trae. Por eso la maestra suma 84 y no
168. Si un nombre difiriera en un carácter, el `anti_join` de
`CreaBBDD_Master_BBDD.R` no calzaría y cada medida se publicaría dos veces, sin
error ni advertencia.

---

### Errores corregidos durante la incorporación

- **`ciso_Dependi_*` no sumaba contratistas.** Estaba escrito como suma de
  cuatro columnas —privados, públicos, doméstico, familiar— y faltaba
  `ciso_Contrat_*`. Reemplazado por `ciso2 %in% 3:7`: el rango no se puede
  quedar corto y no depende del orden de definición dentro del `summarise`.
- **`ciso_Asal_Priv_Form` estaba definida dos veces**, una suelta antes del
  bloque. `summarise` conserva la posición de la primera y el valor de la
  segunda, así que la columna salía correcta pero fuera de lugar.
- **El comentario de vigencia decía EFM 2022.** Es EFM 2020, 202002.

---

## 2026-08-12 -- Iniciadores_disp publicaba ceros desde 201002

**Archivos**: `ENE_1_Cubo.R` (v4→v5), `ENE_diccionario_categorias.R` (nota).

`vars_base` pedía `idisp` y el `summarise` sumaba sobre ella. Pero el INE
**renombró la variable en 201912**: `id` rige de 201002 a 201911, `idisp` desde
201912. Sin traslape, sin hueco, 118 + 78 = 196 períodos.

Como `idisp` no existe en los 118 archivos previos, la columna no se leía,
`sum(fact_cal[...])` sobre lo que no está devuelve 0 y no NA, y **el cero se
publicaba como dato**. Diez años de serie en cero.

Arreglo: las dos entran a `vars_opcionales` y un `rename` inmediatamente después
del `read_dta` deja siempre `idisp`. No hay riesgo de colisión porque nunca
coexisten.

En el diccionario, `Iniciadores_disp` conserva `vigencia_desde = 201002`, que ya
estaba bien: **la vigencia es del concepto, no del nombre de la variable**. Se
agregó la nota para que nadie la "corrija" a 201912.

**Requiere reproceso completo**, no incremental: los 118 períodos antiguos tienen
la columna en cero y una corrida desde 202001 no los toca.

---

### Cómo se encontró, y por qué no se había encontrado antes

Lo destapó el censo de variables de `ENE_0b_BBDD_Etiquetas.R`, que mide sobre los
196 `.dta` qué variable existe en qué período. `id` aparecía con vigencia
201002-201911 y `idisp` con 201912-202605.

No se había encontrado porque **`vars_opcionales` es una lista de "si no está,
sigue"**. Un nombre que no existe se comporta igual que una variable con
vigencia tardía: `setdiff` la marca ausente, el mensaje dice "opcionales
ausentes: id" y la corrida continúa. Ese aviso sale todos los meses mezclado con
ausencias legítimas —`ciso2`, `e22`—, así que nadie distingue un nombre mal
escrito de una vigencia posterior.

En `vars_base` habría reventado el primer día. La lista permisiva es lo que lo
mantuvo invisible.

**Pendiente**: contrastar las opcionales declaradas contra el censo. Una variable
que no aparece en NINGÚN período de la serie no es una vigencia tardía, es un
nombre inexistente. Son dos casos distintos y hoy se ven iguales.

---

## 2026-08-12 -- Dos scripts previos al pipeline

**Nuevos**: `ENE_0a_BBDD_Descarga_INE.R` (v4), `ENE_0b_BBDD_Etiquetas.R` (v14).

Ninguno produce base. Corren antes de `ENE_1` y por eso llevan el prefijo `0`.

**`ENE_0a`** descarga los `.dta` del sitio del INE. Reemplaza a
`BajaBBDD_Ene.R`, que se perdía en el directorio por no llevar el prefijo de la
cadena. Tres cambios sobre el original:

Los nombres de archivo **se construyen** desde la combinación año × trimestre y
se preguntan con `file.exists`, en vez de leer el directorio con un patrón. Un
`list.files` aceptaría un `ene-2020-05-amj_2.dta` de una descarga repetida y lo
contaría como válido. Lo que no calza con un nombre construido se declara
sobrante y **se mueve a `ENE/basura/`** con sello de fecha: nada se borra, pero
el directorio queda con la serie canónica y nada más, que es lo que hace
confiable al `file.exists`.

Tres modos: `completar` rellena huecos y avanza hasta el primer fallo —el borde
de lo publicado—, `forzar` rebaja la serie entera para cuando el INE reprocesa,
y `reparar` solo los dañados. El diagnóstico corre siempre y se imprime antes de
bajar nada.

La descarga cae en la raíz y se mueve al destino con `file.rename` solo si
terminó, mismo patrón que `GeneraInformes.R` con los `.docx`. Una descarga
cortada deja el archivo a medias a la vista y no pisa el bueno.

**`ENE_0b`** recorre los `.dta` leyendo solo metadatos —`n_max = 1`— y produce el
censo de variables y el catálogo de etiquetas. De ahí salieron el hallazgo de
`idisp`, la vigencia 202002 de CISO medida en vez de supuesta, y la confirmación
de que **ninguna variable de la serie tiene huecos de período**.

Escribe cuatro `.csv` y dos `.md`. El reporte contrasta los vectores de `ENE_1`
contra lo medido y emite el veredicto por variable.

---

## 2026-07-30 -- Módulo de calidad de categorías

**Archivos**: `ENE_4_Calidad_Categorias.R` (nuevo, v1 → v2)

Propuesto por el usuario: un `group_by(categoria)` con conteo, mínimo y máximo
de período, y cantidad de sexos y regiones distintos, ordenado por categoría,
de modo que leyendo las ~300 líneas de corrido se vea la basura -- el caso que
dio como ejemplo fue `Producción` conviviendo con `Produccion`.

Se implementó eso más cinco reportes derivados. El que importa para los datos
publicados es **ceros al inicio de la serie**: cuenta cuántos períodos iniciales
tienen TODAS las celdas en cero (3 sexos × 17 regiones), usando `rle()` sobre la
secuencia para que un cero aislado a mitad de serie no cuente. Esa es la firma
exacta de una vigencia mal declarada -- la variable fuente todavía no existía,
`sum()` de un vector vacío devuelve 0 y no NA, y el cero se publica como dato.
Los otros cuatro (casi duplicadas, fuera del diccionario, cobertura anómala,
huecos de período) son higiene: no afectan lo que sale hoy.

v2 tras observación del usuario: `en_canon` y `clave_norm` pasaron de ser tablas
filtradas aparte a ser COLUMNAS de `calidad_categorias`, y la tabla se ordena
por `clave_norm` -- así los duplicados por tilde quedan en líneas contiguas y se
ven leyendo, que era el punto original.

## 2026-07-30 -- Migración al canon: pipeline Excel

**Archivos**: `CreaBBDD_Excel_Series.R` (v1 → v2),
`CreaBBDD_Excel_Coyuntural.R` (v1), `CreaBBDD_Master_Excel.R` (v1),
`CreaBBDD_Master_BBDD.R` (v1)

Los tres pipelines (Stata, Series, Coyuntural) tenían que migrar en el mismo
commit. `CreaBBDD_Master_BBDD.R` hace `anti_join` sobre una llave que incluye
`categoria`, y 384 categorías compartían string exacto entre Excel y Stata: al
renombrar solo un lado, esas 384 dejan de calzar y pasan a "exclusivas de
Excel". El resultado no es un error ni una advertencia -- la maestra publica
cada medida dos veces, una con nombre canónico y otra con nombre viejo, y el
chequeo de llaves duplicadas no lo detecta porque las llaves son distintas.

Series: 55 literales, 56 símbolos desnudos y 20 referencias entre backticks. Los
símbolos desnudos importaban -- `PET`, `FT`, `B_t_p_v` y las derivadas se
referencian como columnas dentro de las fórmulas, no como strings, así que un
reemplazo solo sobre comillas habría dejado el script sintácticamente válido
pero roto en ejecución.

Coyuntural: 34 literales, más tres cambios estructurales. Se eliminó
`No sabe - No responde` de rama (`columnas_excel` de `4:25` a `4:24`): es el
residuo de no respuesta, derivable como Ocupados menos la suma de ramas, y
Series ya lo excluía con `solo_cols = 1:21` -- solo Coyuntural lo traía.

Los dos orquestadores no contienen un solo literal de categoría, así que
sobrevivieron la migración sin cambios de lógica; se versionaron para dejar
constancia de que fueron revisados.

## 2026-07-30 -- Escalas: conversión en el borde

**Archivos**: `CreaBBDD_Excel_Series.R`, `CreaBBDD_Excel_Coyuntural.R`

`leer_serie_auto()` ya detectaba la fila de tipos del Excel (`"en miles"`,
`"tasa (%)"`, `"en horas"`) pero solo la usaba para saber cuáles columnas eran
datos, y descartaba el valor. Esa misma información se reconstruía a mano al
final, en la lista `Excluir`. Dos fuentes de verdad para lo mismo, sin nada que
las obligara a coincidir.

Ahora la conversión ocurre AL LEER, contra lo que el propio Excel declara.
Desaparecen `Excluir` (Series), `vars_tasa_edad` (Coyuntural) y el parámetro
`escala` de `leer_coyuntural()` -- que además tenía la rama `else` inalcanzable,
porque la condición era `escala %in% c("miles", "raw")` y solo se le pasaban
esos dos valores.

Como consecuencia `dt_unida` queda en unidades finales antes de calcular nada, y
`FFT_d` pasa de `PET - FT_d/1000` a `PET - FT_d`. Es traducción de unidades, no
corrección: la fórmula original era correcta en su lugar, verificado que la
línea 505 corría antes de la amplificación de la 554. Ídem
`T_participación_d`.

**Error de producción corregido**: las 4 tasas por tramo etario de Coyuntural se
multiplicaban por 1000. El `if_else` que las protegía comparaba
`variable_base` (que toma valores de `vars_edad`: `"Tasa de desocupación"`)
contra `vars_tasa_edad` (que listaba `"T_desocupación"`) -- intersección vacía,
condición siempre falsa, caída al `else`. Fósil de un renombre anterior donde se
actualizó una lista y no la otra. En la maestra quedaba tapado porque Stata gana
en llave compartida, pero salía mal en `modo_master = 3` y en la ventana de ~15
horas en que solo existe el Excel, que es el propósito del pipeline. Confirmado
por el usuario contra `coyuntural_sft_edad.xlsx`, donde la fila 7 declara
`tasa (%)` para las 4 últimas columnas.

## 2026-07-30 -- Migración al canon: pipeline Stata

**Archivos**: `ENE_1_Cubo.R` (v1 → v3), `ENE_2_Colapso_SexoRegionEdad.R` (v1),
`ENE_3_Derivadas_Master_dta.R` (v1 → v4)

Punto de partida: `categoria` no era un nombre sino una llave compuesta
serializada en texto libre, tipeada a mano ~250 veces sin gramática. Funcionaba
porque las cadenas resultaban únicas, no porque siguieran una regla.

`ENE_3` bajó de 621 a 273 líneas. `tabla_nombres` (210 literales) y `vars_edad`
(19) se reemplazan por el diccionario único -- eso cierra por construcción la
divergencia `FT` / `Fuerza de Trabajo` y `T_desocupación` /
`Tasa de desocupación`, que existían porque el nombre se escribía en dos
lugares. `cats_desde_JAS2017` y `cats_desde_EFM2017` (111 literales) pasan a
`filter(periodo >= vigencia_desde)`. El pivot se reestructuró para que ambas
ramas lleguen a la misma forma y se unan ANTES del canon; como efecto lateral,
el bloque de labels de sexo y región, que estaba escrito dos veces, corre una
sola.

El `stop()` sobre columnas sin entrada en el diccionario es lo que evita que
esto se degrade de nuevo: si alguien agrega un `summarise` en ENE_1 y no lo
registra, el pipeline se cae en vez de publicar el nombre interno crudo.

`ENE_1` solo cambió en `vars_base`/`vars_opcionales` (ver entrada de vigencias);
el cubo sale byte a byte idéntico, verificado comparando líneas de código sin
comentarios. `ENE_2` solo cabecera.

v4 de ENE_3: la columna del diccionario se llama `categoria`, no
`categoria_canonica` -- al podar la tabla a sus columnas permanentes se fueron
las de migración y la etiqueta quedó con su nombre definitivo. El módulo pedía
el nombre viejo; el chequeo de duplicados miraba una columna inexistente y
devolvía `NULL` sin fallar, así que el error recién saltaba en el `select()`.

## 2026-07-30 -- Vigencias corregidas contra el manual INE

**Archivos**: `ENE_1_Cubo.R` (v1 → v3), `ENE_3_Derivadas_Master_dta.R`

Las vigencias se derivaron de `codigos-ene-2020_actual.pdf`, columna
Observaciones, con la regla que dio el usuario: sin texto = serie completa =
201002.

- **`b14_rev4cl_caenes` rige desde EFM 2013, no desde JAS 2017.** El comentario
  del script describía `r_p_rev4cl_caenes`, que es otra variable -- el ajuste de
  INE 2020b. `cats_desde_JAS2017` SOBRE-FILTRABA las 21 ramas base y descartaba
  54 trimestres móviles válidos (201302 a 201707). Único hallazgo de esta
  migración que agrega datos en vez de quitarlos.
- **`b15_1` no trae observaciones**, luego rige desde 201002. El script asumía
  Nov-Ene 2019: `Tam_*` base recupera nueve años de serie.
- **`deseo_trabajar` rige desde EFM 2020** y no estaba en ninguna lista, así que
  `Desea_trabajar` se publicaba como 0 durante una década.
- `Tam_*_form/inf`, `Motivo_*` y `RazonFin_*` tampoco estaban en ninguna lista.
- `GOcup_*_F/_I` estaban en `cats_desde_EFM2017` pero dependen de `ocup_form`
  (JAS 2017): 5 meses de ceros en 2017.
- **El filtro de vigencia corría antes del `bind_rows` de la rama de edad**
  (línea 509 vs 606), así que ninguna categoría con tramo etario se filtraba
  jamás.

Balance: 21 categorías sobre-filtradas y 38 publicando ceros donde no hay dato.

**Conversión de trimestre móvil**: el código del trimestre es el MES CENTRAL
(manual p.17), no el mes inicial. `EFM 2017` es 201702 y no 201703; `JJA 2020`
es 202007 y no 202006. El script original arrastraba el error en
`cats_desde_EFM2017 & periodo < 201703`. Notable: `fc_fecha_a_trimestre()` de
`funciones_informe.R` ya tenía la tabla correcta.

**`vars_opcionales` reducida a las seis que sí tienen fecha en el manual**
(`ocup_form`, `b14_rev4cl_caenes`, `sector`, `b1`, `deseo_trabajar`, `e22`).
`tpi`, `obe`, `id`, `ftp`, `c10`, `c11` y `b15_1` pasaron a `vars_base`,
verificado contra los listados reales de variables de los `.dta` de 201002 y
202604 que compartió el usuario. Queda como INVARIANTE escrito en la cabecera:
`vars_opcionales` contiene exactamente las variables con vigencia posterior a
201002. Una variable mal clasificada como opcional se rellena con NA, se suma
como 0 y se publica como dato -- mecanismo detrás de casi todos los hallazgos.
Además `procesar_dta()` ahora avisa por archivo qué opcionales rellenó.

## 2026-07-30 -- Vector de renombre (registro de auditoría)

**Archivos**: `ENE_vector_categorias.xlsx` (nuevo)

447 filas: `categoria_actual`, `categoria_canonica`, `fuente`, `estado`. 436 de
origen Stata y 11 de origen Excel (6 desestacionalizadas, 2 presentes
tradicionales, 3 redacciones divergentes de Series que convergen a un canónico
ya existente).

**No lo lee ningún código.** Es el instrumento de migración, de un solo uso: se
aplicó como reemplazo directo sobre el texto de los scripts y queda en el
control de versiones como registro de qué cambió y de qué a qué. La tabla viva
es `ENE_diccionario_categorias.R`, en `Bibliotecas_R/`.

Se generó de forma determinista tras detectar que una versión anterior contenía
12 filas que el generador no producía y que no se pudieron explicar -- un
artefacto de migración que no se puede regenerar idéntico no sirve para
auditar.

## 2026-07-30 -- Canon de nombres de categoría

**Archivos**: todos los del pipeline

Nueve reglas. Las centrales:

- **R1 -- canon cerrado bajo composición**: toda categoría publicada es un átomo
  registrado o una concatenación de átomos registrados. El reconocimiento se
  hace por lookup contra el diccionario, nunca por split de la cadena.
  Formulación del usuario: "si todas las partes son canónicas el espacio basta y
  es más bello, pues cualquier nombre fuera del canon es una combinación de
  canon".
- **R3 -- separador único**: espacio simple, sin excepciones, incluidos los
  cortes transversales. Reemplaza al `-` de la rama de edad. No se reserva
  ningún token porque por R1 no hace falta. Verificado: las 436 categorías son
  únicas bajo espacio simple.
- **R4 -- sin códigos en la capa de salida**: `PET`, `FT`, `FFT`, `B_t_p_v`,
  `T_*`, `Form_PET`, `Deficit_*` pasan a texto legible; la sigla vive en
  `col_interna`.
- **R5 -- atributos con token invariante**: ` formal` / ` informal` y
  ` desestacionalizado`, sin concordar con la medida base. La concordancia
  gramatical vive en la columna de etiqueta visible, no en la llave.
- **R9 -- prefijo de medida cuando el valor nombra otra entidad**: aplica a
  tamaño de empresa, `Micro empresa` → `Ocupados Micro empresa`, porque sin el
  prefijo puede leerse como número de empresas.

---

# Historial de las bibliotecas propias

Las tres que solo carga este proyecto. Se listan por archivo y no por fecha
porque su historia es corta y se lee mejor junta.

---

## ENE_diccionario_categorias.R

Tabla VIVA del canon de categorías de la ENE: nombre publicado, descomposición
en medida y dimensiones, vigencia y fuente. La sourcean `fc_diccionario_ene.R`,
`ENE_3_Derivadas_Master_dta.R` (proyecto InformeBBDD) y
`ENE_4_Calidad_Categorias.R`. Vive acá y no en `Datos_Ine/` porque un renombre
tiene que aterrizar en el mismo commit que los scripts que lo usan: si se
sincroniza aparte, se desfasa y el `stop()` de ENE_3 recién avisa en la corrida
siguiente.

### 2026-08-12 -- v2: 84 categorías CISO-18

Se agregan las 84 categorías de CISO-18 con `vigencia_desde = 202002`: 28
conceptos en sus tres niveles de formalidad. El detalle de la clasificación y
por qué no se empalma con CISE está en la entrada del 2026-08-12 de
`CHANGELOG_InformeBBDD.md`.

Dimensión propia, `Categoría ciso` y `Categoría ciso3`, distinta de la
`Categoría en la ocupación` de CISE. Son dos acuerdos OIT diferentes —CISE-93 y
CISO-18— y compartir dimensión los haría parecer alternativas de lo mismo.

Los nombres se declaran acá y no se heredan de las etiquetas del `.dta`, que en
cinco categorías describen de dónde viene el caso y no dónde queda: los códigos
5 a 9 de `ciso3_b` se etiquetan como cuenta propia o asalariado y los cinco son
contratistas.

Verificado que los 28 nombres del lector de Excel de `CreaBBDD_Excel_Series.R`
están todos acá: los dos caminos convergen y la maestra suma 84 y no 168.

**Nota agregada a `Iniciadores_disp`**: su `vigencia_desde` es 201002 aunque su
variable fuente cambie de nombre —el INE renombró `id` a `idisp` en 201912—. La
vigencia es del concepto, no del nombre. Sin la nota, alguien la "corrige" a
201912 y se pierden diez años de serie.

### 2026-07-30 -- v1: archivo nuevo

235 filas: 227 derivadas del cubo de `ENE_1_Cubo.R` y 8 que nacen en los Excel
(6 desestacionalizadas, que Stata no puede calcular, y 2 de presentes
tradicionales). Reemplaza a `tabla_nombres` (210 literales) y `vars_edad` (19)
de ENE_3, que eran dos lugares donde escribir el mismo nombre -- de ahí venía la
divergencia `FT` / `Fuerza de Trabajo`. Reemplaza también a
`cats_desde_JAS2017` y `cats_desde_EFM2017` (111 literales) vía la columna
`vigencia_desde`.

Va como `.R` y no como `.xlsx`/`.csv` a propósito, a pedido del usuario: los
lectores de planilla negocian encoding y ahí se pierden las tildes y la ñ --
tuvo que abrir y regrabar el `.xlsx` con Excel para que tomara Unicode. Dentro
de un archivo fuente en UTF-8 no hay capa intermedia. `fc_diccionario()` lo
sourcea con `encoding = "UTF-8"` explícito, porque en Windows con locale latino
`source()` sin ese argumento reinterpreta el archivo.

Trae sus invariantes como `stopifnot` al final de su propio archivo: unicidad
del par `(col_interna, corte)` -- se repite `col_interna` entre la fila base y
su plantilla de edad, por diseño -- y unicidad de `categoria`.

---

## ENE_manual_variables.R

Tabla de variables del manual INE (`codigos-ene-2020_actual.pdf`, edición
30-09-2025). Fuente de verdad de `vigencia_desde` para las variables NATIVAS del
`.dta`. Las columnas DERIVADAS del cubo componen varias variables y su vigencia
es el máximo de sus insumos -- esa composición la declara
`ENE_diccionario_categorias.R`, no el manual.

### 2026-07-30 -- v1: archivo nuevo

250 variables. Cubre las 214 presentes en los `.dta` de 201002 y 202604 que
compartió el usuario, más las transitorias que existieron solo en períodos
intermedios (módulos COVID, variables descontinuadas).

Columna `verificada`: las 28 que usa el pipeline más las dos de rama se leyeron
directamente de la página del PDF. Las otras 222 son extracción automática y
están marcadas como no confiables. **No se logró una extracción automática
fiable**: las tablas del PDF centran verticalmente las celdas multilínea, de
modo que el texto de una variable puede empezar por encima de la línea que lleva
su nombre. Asignar por bloque perdía `r_p_rev4cl_caenes`; asignar por cercanía
perdía `ocup_form` y `sector`. 50 filas quedan marcadas `revisar`.

Las columnas `en_201002` / `en_202604` contrastan contra el listado real de
variables de ambos `.dta`. Fueron las que hicieron visible el problema: una
variable ausente en 201002 pero con vigencia declarada 201002 es una
contradicción detectable.

Tres fallas distintas de extracción encontradas y corregidas: `idrph` es una
fila sin categorías ni observaciones y `extract_tables()` la descartaba entera;
`efectivas` quedaba como `efectivas8` por el marcador de nota al pie; y
`cae_especifico` viene partido como `cae_ especifico`, con un espacio dentro del
nombre.

---

## fc_diccionario_ene.R

Funciones del canon de categorías: carga y validación del diccionario,
composición de etiquetas, aplicación del canon, filtro de vigencia,
descomposición para consumidores, y conversión de trimestre móvil a período.
Candidata a fundirse dentro de `funciones_ene.R`; se mantuvo separada para que
el `source()` de ENE_3 haga visible de dónde sale el canon.

### 2026-07-30 -- v6: columnas del diccionario alineadas, `fc_migrar_legacy()` eliminada

El diccionario expone `categoria`; el módulo pedía `categoria_canonica` y
`categoria_actual`, que eran los nombres de la versión con columnas de
migración. El chequeo de duplicados miraba una columna inexistente y devolvía
`NULL` sin fallar, así que el error recién saltaba en el `select()` de ENE_3.

`fc_migrar_legacy()` se eliminó, no se arregló. Un puente de nombres viejos a
nuevos hace que una migración a medias PAREZCA funcionar; con `anti_join` sobre
una llave que incluye `categoria`, eso no falla: duplica en silencio. El
registro del renombre vive en `ENE_vector_categorias.xlsx`, en el control de
versiones.

### 2026-07-30 -- v5: el diccionario y el manual pasan a `.R` y se sourcean

Ver la entrada v1 de `ENE_diccionario_categorias.R` para el motivo. Salen
`openxlsx` y `readr` de las dependencias.

### 2026-07-30 -- v3: `fc_periodo_trimestre()`, `fc_manual()`, `fc_vigencia()`

El código del trimestre móvil es el MES CENTRAL (manual p.17), no el mes
inicial: `EFM 2017` es 201702 y no 201703, `JJA 2020` es 202007 y no 202006.
Convertir a ojo era la fuente del error -- el script original de ENE_3
arrastraba `cats_desde_EFM2017 & periodo < 201703`, y esta biblioteca ya tenía
la tabla correcta en `fc_fecha_a_trimestre()` de `funciones_informe.R`, dos
carpetas más allá.

### 2026-07-30 -- v1 y v2: archivo nuevo

`fc_diccionario()`, `fc_categoria()`, `fc_aplicar_canon()`,
`fc_filtrar_vigencia()`, `fc_descomponer()` y `fc_validar_cierre()`. Esta última
es la contraparte ejecutable de la formulación del usuario: si el canon es
cerrado bajo composición, toda categoría publicada tiene que poder
reconstruirse desde el vocabulario de átomos registrados; si una cadena deja
resto, alguien inventó una etiqueta fuera del canon.
