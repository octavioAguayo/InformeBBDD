# Manual — InformeBBDD

_v16 · 22-08-2026_

Este proyecto produce `dt_ENE_Master.RData`, la base que consume InformeRegional
y cualquier proyecto futuro. No publica documentos: publica datos.

Estado vigente: `ESTADO_PROYECTO.md`. Historial:
`CHANGELOG_InformeBBDD.md`, que incluye las tres bibliotecas que solo
este proyecto carga. Los tres módulos compartidos —`funciones_pipeline.R`,
`funciones_formato.R` y `funciones_ene.R`— van en
`Bibliotecas_R/log/CHANGELOG_general_R.md`.

---

## 1. Dónde vive cada cosa

| Necesito | Está en |
|---|---|
| Bajar los `.dta` del INE | `ENE_0a_BBDD_Descarga_INE.R` |
| Revisar DTA, Excel, Master y metadatos | `calidad/Calidad_ENE.Rmd` |
| Saber qué variable existe en qué período | `ENE_0b_BBDD_Etiquetas.R` |
| Ejecutar toda la rama DTA | `CreaBBDD_Pipeline_DTA.R` |
| Agregar los microdatos a stocks | `intermedios/ENE_1_Cubo.R` |
| Colapsar a sexo × región × edad | `intermedios/ENE_2_Colapso_SexoRegionEdad.R` |
| Aplicar el canon y armar la maestra desde Stata | `intermedios/ENE_3_Derivadas_Master_dta.R` |
| Leer las series del Excel INE | `intermedios/CreaBBDD_Excel_Series.R` |
| Leer el Excel coyuntural | `intermedios/CreaBBDD_Excel_Coyuntural.R` |
| Unir Stata y Excel | `CreaBBDD_Master_BBDD.R` |
| Definir controles tabulares | `calidad/funciones_calidad.R` |
| El canon de nombres | `ENE_diccionario_categorias.R` (biblioteca) |

### Ubicación canónica de datos

Los `.dta` originales permanecen en `Datos_Ine/ENE`. Dentro de esa carpeta hay
dos subdirectorios con responsabilidades distintas:

| Directorio | Contenido |
|---|---|
| `cache_ene_bbdd/` | Un RDS crudo reducido por encuesta; acelerador descartable, no producto |
| `bbdd_minuta/` | Todos los RData finales y de paso de las ramas DTA y Excel |
| `metadatos/` | Tablas medidas de variables, etiquetas y vigencias producidas por ENE_0b |

`Procesados/` y `Exceles/AAAAMM` dejan de recibir bases de este pipeline. Los
libros originales siguen en `Exceles`; solo sus objetos R se centralizan en
`bbdd_minuta`.

### Organización del código

La raíz contiene únicamente los puntos de entrada del pipeline y sus dos pasos
previos. `intermedios/` contiene etapas productivas que ejecutan los
orquestadores. `calidad/` contiene un R Notebook ejecutable por bloques y las
funciones que devuelven sus tablas; no exporta reportes automáticamente. El
código retirado fue evaluado y eliminado; no quedan carpetas de cuarentena en el
árbol de bibliotecas.

---

## 2. Pipeline

```
  Pipeline Excel                      Pipeline microdatos
  ──────────────                      ───────────────────
  CreaBBDD_Excel_Series      →        ENE_1_Cubo
  CreaBBDD_Excel_Coyuntural  →        ENE_2_Colapso
  CreaBBDD_Master_Excel      →        ENE_3_Derivadas
         │                                    │
         ▼                                    ▼
    dt_ENE_Excel                        dt_ENE_Stata
              └───────────┬─────────────┘
                CreaBBDD_Master_BBDD
                          │
                          ▼
                    dt_ENE_Master
```

**Disponibilidad.** `dt_ENE_Excel` está desde la hora 0, con los libros que el
INE publica a las 18:00. `dt_ENE_Stata` y por tanto `dt_ENE_Master` recién unas
15 horas después, cuando llega el `.dta`. Esa ventana es el propósito del
pipeline Excel.

**La maestra se reconstruye completa en cada corrida**, desde las dos fuentes
actuales. No se carga la maestra anterior como base: las dos fuentes ya
contienen toda la historia, y partir de la anterior solo arrastra corrupción de
corridas previas — un `anti_join` nunca corrige ni reemplaza filas que ya
existen. Reconstruir desde cero la hace reproducible.

**`dt_ENE_Stata` es la columna vertebral.** Trae el cruce sexo × región, la
dimensión edad y la historia completa. `dt_ENE_Excel` tiene menos profundidad
—región **o** sexo, no cruzados— y aporta solo lo que Stata no puede tener: las
series exclusivas del Excel, entre ellas las desestacionalizadas, que Stata no
calcula. **En llaves compartidas mandan los valores de Stata.**

`modo_master` permite validar cada fuente por separado: 1 es producción, 2 solo
`.dta`, 3 solo Excel.

**Un solo punto de entrada por rama.** `CreaBBDD_Pipeline_DTA.R` detecta el DTA
más reciente y propaga ese período a ENE_1 antes de ejecutar ENE_2 y ENE_3
hasta producir `dt_ENE_Stata`. Por defecto reemplaza únicamente ese período y
conserva el resto del cubo. `Periodo_DTA` permite escoger otro período;
`RECREAR_SERIE_DTA <- TRUE`
rehace toda la historia y `RECREAR_CACHE <- TRUE` vuelve a leer los DTA aunque
el caché sea válido. Son controles separados: rehacer cálculos no obliga a
decodificar nuevamente los archivos originales.

`CreaBBDD_Master_Excel.R` fija
`Trim_Actual` una vez y los dos sub-scripts lo heredan del entorno global, lo
que evita correrlos por separado con períodos distintos. Y `Trim_Actual` se
**deduce del directorio** —la carpeta `AAAAMM` más reciente en
`Datos_Ine/Exceles`— porque un literal por defecto envejece en silencio: el
script corre con un trimestre viejo sin quejarse y el problema aparece varios
pasos después.

Las dos ramas no se ejecutan mutuamente. Cuando ambas están listas,
`CreaBBDD_Master_BBDD.R` carga `dt_ENE_Stata` y `dt_ENE_Excel`, aplica las
guardias de alineación y produce `dt_ENE_Master`.

`ENE_0a` y `ENE_0b` son previos. ENE_0b guarda tablas técnicas en
`ENE/metadatos/ENE_0b_metadatos.RData`; no genera Markdown, CSV, TXT ni Excel. El Notebook de
calidad es posterior y no produce bases: carga los objetos actuales y permite
ejecutar por separado los bloques DTA, Excel, comparación, Master, canon y
metadatos.

### Caché cruda de lectura

`ENE_1` no vuelve a decodificar el DTA completo cuando existe un RDS válido en
`cache_ene_bbdd`. Cada caché contiene únicamente `vars_base` y las variables
opcionales presentes en esa encuesta, sin etiquetas Haven. No filtra filas ni
guarda recodificaciones: las reglas de dominio continúan dentro de ENE_1.

La caché se invalida automáticamente cuando falta, es anterior al DTA, cambia
el vector esperado o le falta una columna que el DTA sí contiene. El atributo
`CACHE_LECTURA_VERSION` cubre cambios del formato de lectura. Para una
reconstrucción voluntaria se define `RECREAR_CACHE <- TRUE`; es la salida ante
una recodificación dudosa que no altera nombres y, por tanto, no puede ser
detectada comparando columnas.

Todas las lecturas y escrituras productivas usan exclusivamente
`ENE/bbdd_minuta`. La compatibilidad temporal con `Datos_Ine/Procesados` se
retiró después de verificar la primera corrida completa y generar un informe
regional desde la ruta nueva.

---

## 3. Vigencias: el modo de falla central

**Una variable mal declarada se rellena con NA, se suma como 0 y se publica como
dato.** No hay error ni advertencia. Es el mecanismo detrás de casi todos los
hallazgos del proyecto: 21 categorías sobre-filtradas y 38 publicando ceros en la
corrección del 30-07-2026, y los 118 períodos de `Iniciadores_disp` en cero
encontrados el 12-08-2026.

**El invariante**: `vars_opcionales` contiene exactamente las variables con
vigencia posterior a 201002. `vars_base` el resto. Una variable de vigencia
tardía puesta en `vars_base` hace caer la lectura; una de serie completa puesta
en opcionales no falla, y por eso es la que hay que vigilar.

**Se mide, no se declara.** `ENE_0b_BBDD_Etiquetas.R` recorre los 196 `.dta`
leyendo solo metadatos y produce el censo: qué variable existe en qué período,
con su etiqueta. De ahí sale `vigencia_desde` como hecho y no como lectura del
PDF del manual, cuya columna de descripción está contaminada.

**Trampa: la lista de opcionales es permisiva.** Un nombre que no existe se
comporta igual que una variable con vigencia tardía — `setdiff` la marca
ausente, el mensaje dice "opcionales ausentes: x" y la corrida sigue. Ese aviso
sale todos los meses mezclado con ausencias legítimas. Así estuvo `idisp` mal
escrito diez años.

**Trampa: la vigencia es del concepto, no del nombre de la variable.** El INE
renombró `id` a `idisp` en 201912. `Iniciadores_disp` rige desde 201002 y su
fuente cambia de nombre a mitad de serie; `ENE_1` lee la que exista y unifica.

**`id` no es un identificador de persona.** Su nombre aislado induce a leerlo
como una llave y a descartarlo como variable ajena al análisis. En realidad,
`id` cubre 201002–201911 e `idisp` cubre desde 201912 el concepto que alimenta
`Iniciadores_disp`; ambas vigencias son continuas y sin huecos. El identificador
longitudinal utilizado para reconocer personas es `idrph`, propio del proyecto
Transiciones.

La regla operativa es detener cualquier eliminación basada solo en el nombre de
una columna. Antes de retirar una variable se deben comprobar tres evidencias:
su etiqueta en el DTA, su vigencia medida y el código que consume el resultado.
En este caso, eliminar `id` habría borrado silenciosamente 118 períodos de
`Iniciadores_disp` anteriores a 201912.

---

## 4. Los dos caminos: Stata y Excel

**Si los dos no producen exactamente el mismo nombre de categoría, la maestra
publica cada medida dos veces.** El `anti_join` de `CreaBBDD_Master_BBDD.R` usa
una llave que incluye `categoria`; si difiere en un carácter, las dos versiones
pasan como categorías distintas. No hay error, y el chequeo de llaves duplicadas
no lo detecta porque las llaves son distintas. Pasó con 384 categorías en la
migración del 30-07-2026.

Por eso los nombres del lector de Excel **no son una lista propia**: son la
columna `categoria` del diccionario, en el orden de columna del libro.

**El calce con el libro es por posición, no por encabezado.** El libro de CISO
dice "Empleadores/as con empresa regisrada como sociedad", sin la t. Es error de
tipeo del INE, en los dos libros y en las 20 hojas. Con calce posicional da
igual, y si algún día lo corrigen tampoco pasa nada.

**Qué aporta cada uno.** El Excel trae los totales; el cubo trae eso más las
aperturas por formalidad, que el Excel no publica. Por eso CISO suma 84
categorías y no 168: 28 por los dos caminos y 56 solo por el cubo.

**Ventana de publicación.** El Excel sale a las 18:00 y el `.dta` al día
siguiente a las 9:00. En esas quince horas solo existe el Excel, y ese es el
propósito del pipeline coyuntural.

---

## 5. El canon de categorías

### Contrato de rama económica

Las 21 etiquetas CAENES aparecen bajo dos definiciones que no son
intercambiables. `r_p_rev4cl_caenes` clasifica la actividad de la unidad que
paga el sueldo o de la cual es dueña la persona ocupada; es la definición usada
por las series de informalidad. `b14_rev4cl_caenes` clasifica la empresa donde
trabaja y responde otra pregunta, especialmente cuando existe subcontratación.

El contrato acordado para la siguiente migración es:

- las categorías sin sufijo forman la familia `r_p`;
- las categorías de `rama.xlsx` y las calculadas con
  `b14_rev4cl_caenes` llevan obligatoriamente el sufijo `_b14`;
- cada familia contiene 21 ramas × total/formal/informal, es decir, 63
  categorías;
- en el adelanto coyuntural de Excel, el total `r_p` se construye como formal
  + informal del mismo libro y la misma definición;
- la unión no decide por fecha solamente. En una llave compartida manda el
  `.dta`, pero las series desestacionalizadas y demás categorías exclusivas del
  Excel permanecen aunque ambas fuentes lleguen al mismo período.

El propósito es que InformeRegional reciba datos semánticamente coherentes y
no tenga que elegir clasificadores ni advertir discrepancias entre tablas. La
distinción metodológica se conserva en los nombres y en esta capa productora;
la minuta consume la familia pertinente sin profundizar en una diferencia que
no cambia su lectura sustantiva.

El contrato está implementado y fue verificado sobre la línea completa
regenerada el 22-08-2026. InformeRegional recibe la familia coherente sin sufijo
y no necesita seleccionar clasificadores ni advertir discrepancias; `_b14`
queda disponible para análisis que requieran explícitamente esa definición.

Nueve reglas, en la entrada del 30-07-2026 del changelog. Las que se usan a
diario:

**R1 — canon cerrado bajo composición.** Toda categoría publicada es un átomo
registrado o concatenación de átomos registrados. El reconocimiento es por
lookup contra el diccionario, nunca por split de la cadena.

**R3 — separador único**: espacio simple, sin excepciones.

**R4 — sin códigos en la capa de salida.** `PET`, `FT`, `T_*` pasan a texto
legible; la sigla vive en `col_interna`. Las siglas de clasificaciones OIT
—CISE, CISO, CINE, CIIU, CAENES— no son códigos internos: son nombres propios de
estándares y sí van en la capa de salida.

**R5 — atributos con token invariante**: ` formal`, ` informal`,
` desestacionalizado`, ` ciso`. No concuerdan con la medida base. La concordancia
gramatical vive en la etiqueta visible, no en la llave.

**El `stop()` de ENE_3** sobre columnas sin entrada en el diccionario es lo que
impide que esto se degrade: si alguien agrega un `summarise` en `ENE_1` y no lo
registra, el pipeline se cae en vez de publicar el nombre interno crudo. Lo que
NO cubre es registrar la categoría con la vigencia equivocada.

---

## 6. Las dos clasificaciones de situación en la ocupación

**CISE-93** (`categoria_ocupacion`, 7 valores) y **CISO-18** (`ciso1` a
`ciso3_b`, desde 202002). Son dos acuerdos OIT distintos, no uno con una
categoría más.

**Por qué existe CISO.** Un repartidor de aplicación no cabe en CISE: no es
cuenta propia —no fija precio ni elige clientes— ni asalariado —sin contrato,
pone su vehículo, asume el riesgo—. `Contratista dependiente` nombra esa
contradicción: contratista por la figura comercial, dependiente por la
subordinación de hecho. Sus cinco aperturas —dependencia organizativa,
económica, ambas, contrato comercial, riesgo económico— son los criterios que
deciden de qué lado cae. Es la única forma de medir el trabajo de plataforma.

**Empalme de lógica, no de serie.** Los siete conceptos de `ciso2` son los
mismos de CISE salvo el que se creó, y por eso el nombre canónico es el de CISE
más ` ciso`: la diferencia sale por `join` sobre el nombre base. Pero **las
series no se encadenan, ni las de nombre idéntico**: las preguntas nuevas
reasignan casos desde y hacia todas las categorías.

**Trampa de agrupación**: en CISE, familiar no remunerado va con los
Independientes; en CISO cae en Dependiente. Es decisión del INE. Poner
`Independientes` e `Independientes ciso` en la misma tabla muestra un salto que
es de clasificación, no de mercado laboral.

**Las etiquetas del `.dta` describen de dónde viene el caso, no dónde queda.**
Los códigos 5 a 9 de `ciso3_b` se etiquetan como cuenta propia o asalariado y los
cinco son contratistas. Por eso el nombre publicado se declara en el diccionario.

**`ciso3_a` no se captura**: es la forma alternativa del tercer nivel, con 18
categorías, y el INE publica la B.

---

## 7. Modos de falla conocidos

**Ceros que se publican como dato.** El caso central, sección 3. Su control debe
calcularse como tabla desde las bases vigentes; nunca mantenerse como inventario
manual ni como reporte estático.

**Categorías duplicadas en la maestra.** Cuando los dos caminos producen nombres
distintos. Sección 4.

**`$` sobre listas hace coincidencia parcial.** `filas$corte` calza con
`filas$cortes` y devuelve el vector completo. Todo acceso a una declaración usa
`[["campo"]]`, que es exacto.

**Trimestre móvil: el código es el MES CENTRAL**, no el inicial. `EFM 2017` es
201702 y no 201703. Convertir a ojo fue la fuente de un error de 54 trimestres.

**Los controles antiguos podían romperse sin afectar la base.** ENE_4 y los
diagnósticos estuvieron dos días cargando una biblioteca disuelta. Se retiraron
a cuarentena: la interfaz vigente es `Calidad_ENE.Rmd` y toda su lógica vive en
`funciones_calidad.R`.

---

## 8. Cómo se verifica

**Versiones y productos se miden juntos.** El primer bloque del Notebook compara
la versión declarada por cada R, Rmd, manual y Estado contra las entradas
explícitas del changelog. El segundo relaciona cada RData con sus productores
reales —incluidos `intermedios/` y las bibliotecas cargadas— y muestra fecha,
fuente más reciente y MD5. Una fuente posterior obliga a revisar; un producto
posterior es sólo una condición necesaria y no prueba qué código fue ejecutado.

Este patrón nació en el control de InformeCISECISO y se adaptó como tabla en
memoria. No genera un HTML adicional: el propio control no se convierte en otro
producto que después haya que versionar y mantener.

**El censo antes que el manual.** `ENE_0b` mide sobre los archivos; el PDF del
INE se usa para las observaciones metodológicas, no para las vigencias.

**Que los dos caminos convergen**: los nombres del lector de Excel tienen que
estar todos en el diccionario. Si la maestra gana el doble de categorías de las
esperadas, los nombres no calzan.

**Que las agrupaciones cuadran**: `ciso2` es rollup de `ciso3_b` y el INE publica
los dos, así que la correspondencia se comprueba en vez de suponerse. `ENE_1` se
detiene si no calza.

**Que la partición es completa**: `Independientes + Dependientes` tiene que dar
`Ocupados` desde 202002. Si da menos, falta una categoría en un rango.
