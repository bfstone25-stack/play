extends RefCounted
class_name StoryEs

static func commentary(id: String) -> String:
	var pages := {
		"order": "NOTA DE CAMPO DE MARA: Pell fabricó urgencia, borró el nombre y me advirtió de los vecinos antes de llegar. La copia carbón de Harrow prueba que el procedimiento ya ocurrió. Fecharé cada hallazgo en local; el sistema del edificio no puede ser mi único registro.",
		"dane": "NOTA DE CAMPO DE MARA: Dane da nombre legal, tiempo de residencia, observación directa y una predicción falsable sobre su número. Su lenguaje es miedo, no incoherencia. Debo guardar la nota aunque el pasillo se mantenga estable.",
		"fire_plan": "NOTA DE CAMPO DE MARA: El piso existe en lo físico, no en el plano. La ruta de lápiz convierte el hueco en un cruce de frontera. Explica por qué Iris eligió la cavidad y por qué Pell llama al sonido golpe de ariete.",
		"notice": "NOTA DE CAMPO DE MARA: El aviso intenta convertir mi entrada en consentimiento. Esa redacción no tiene uso normal. El nombre de Iris sobrevive porque la humedad revirtió el corrector: el daño que Pell quiere borrar también conserva su identidad.",
		"checklist": "NOTA DE CAMPO DE MARA: Dos listas divergen en el muro. La versión limpia de Pell anticipa cada hallazgo. La de Harrow entra en pánico solo después del tercer punto. Debo tratar el orden mismo como trampa.",
		"frame": "NOTA DE CAMPO DE MARA: La foto perdida unía a Iris, Dane y un inspector antes de esta noche. Quitar caras espeja quitar nombres. El marco no es prueba sobrenatural sola, pero la fecha corrobora la tenencia de Dane.",
		"shoes": "NOTA DE CAMPO DE MARA: Calzado mojado, un billete de mañana y una maleta incompleta contradicen el abandono. Iris planeó una salida ordinaria. Alguien quiso la apariencia de huida sin dejarla terminar.",
		"thermostat": "NOTA DE CAMPO DE MARA: La ocupación se mide como estado del sistema. Los horarios siguen las etapas de Pell, no la calefacción. Cuando el recuento pasa a dos, el piso me registra como reemplazo antes de firmar.",
		"answering": "NOTA DE CAMPO DE MARA: Los mensajes prueban coacción, la presencia de Harrow y un conocimiento imposible de mi ruta. Iris anticipó el borrado y repartió la prueba en voz, foto, vecino y tubería.",
		"groceries": "NOTA DE CAMPO DE MARA: La comida fresca es prueba débil; el sello de la receta es externo. Coloca a Iris viva después de la entrega que Pell afirma. Fotografiar la etiqueta aparte del informe de cocina.",
		"invoice": "NOTA DE CAMPO DE MARA: La premeditación ya es documental. Cavidad, pestillo y aislante se pidieron antes de la fuga. La firma imposible de Harrow une la obra a la sustitución. Pell no descubrió el fenómeno: lo operó.",
		"kettle": "NOTA DE CAMPO DE MARA: Harrow dejó un objeto personal en el 404 y su empleador lo niega. Su frase grabada sugiere que la cavidad proyectó a Iris en su casa después de firmar.",
		"mirror": "NOTA DE CAMPO DE MARA: El reflejo conserva la ruta borrada igual que la guardada. La negación cambia lo que el informe puede probar, no lo que ocurrió.",
		"medicine": "NOTA DE CAMPO DE MARA: Pell reconvirtió un sonido reproducible en enfermedad. El clínico documentó oído normal y recibió la grabación de Iris. Segundo registro externo.",
		"drain": "NOTA DE CAMPO DE MARA: Iris entró por elección, con Dane y Harrow presentes. Eso no absuelve a Pell: la obra pedida de antemano forzó su estrategia.",
		"service": "NOTA DE CAMPO DE MARA: El diario de incidentes es un horario. Admisión, audibilidad, traslado, firma, desaparición. Mi línea lo sigue exactamente.",
		"clock": "NOTA DE CAMPO DE MARA: Siete inspectores borrados implican un ciclo practicado. Mis iniciales estaban programadas antes de aceptar el trabajo.",
		"locket": "NOTA DE CAMPO DE MARA: El detalle es resistencia. Si testifico, debo describir a una persona, no solo un registro anómalo.",
		"letters": "NOTA DE CAMPO DE MARA: El plan de Iris es coherente: permanecer dentro del límite, usar el cobre, forzar a un inspector a conservar el nombre fuera.",
		"wardrobe": "NOTA DE CAMPO DE MARA: Las marcas del lado de la habitación prueban que Iris no quedó sellada. El casete es la entrega prevista.",
		"cassette": "NOTA DE CAMPO DE MARA: Iris nombra el mecanismo y predice ambas rutas. Presenciar exige foto, respuesta, testimonio y umbral; obedecer exige borrado, aislamiento, firma y silencio.",
		"followup": "NOTA DE CAMPO DE MARA: Pell nunca discute los hechos juntos. Su pausa en la tubería prueba que oye a Iris.",
		"final_evidence": "NOTA DE CAMPO DE MARA: No hay salida neutra. Abrir apuesta mi identidad a la prueba de Iris; ignorar ratifica el registro reescrito."
	}
	return "\n---\n" + str(pages.get(id, "")) if pages.has(id) else ""


static func stage(s: int, flags: Dictionary) -> Array[Dictionary]:
	return StoryOverlay.apply(s, flags, TEXTS)


const TEXTS := {
	"order": {"prompt": "Abrir el folio sellado", "text": """VESPER COURT / INSPECCIÓN FUERA DE HORARIO 71-B
Unidad 404. Inquilina: [nombre eliminado]. Confirmar vacante; registrar humedad; no contactar vecinos. Si el trabajo pasa de medianoche, completar la cláusula de pernocta. — M. Pell

MARA: Ya era medianoche cuando llamó. Dijo que el inspector anterior abandonó y ofreció tarifa doble.
---
Al dorso, carbón: INSPECTOR E. HARROW / LLEGADA 01:47 / SALIDA — / DISPOSICIÓN: OCUPANTE SUSTITUIDO.
Debajo: NO FIRMES DESPUÉS DEL CUARTO GOLPE.
---
Harrow era el nombre del buzón de Pell. El formulario está fechado esta noche. El indicador del ascensor va de 4 a 0 y vuelve. Arriba, la madera responde una vez."""},
	"dane": {"prompt": "Desplegar la nota del 403", "text": """INSPECTORA—Pell dirá que el 404 está vacío. Pregunta por qué una habitación vacía golpea. Si la tubería llama tres veces, responde tres. No dos.

El primero es el gerente. El segundo es el edificio copiándolo. El tercero es a quien sustituyó el último inspector. — D, 403
---
Soy Dane Orlov. Iris Vale vivió a mi lado once meses. No entregó el piso. Vi a Pell subir pladur después de medianoche.
Si al volver mi puerta dice 402, baja esta nota. Recuérdanos en detalles que el edificio no pueda mejorar."""},
	"fire_plan": {"prompt": "Comparar el plano de incendios alterado", "text": """El plano oficial del cuarto piso muestra tres unidades. Un cuarto rectángulo aparece en lápiz azul junto al hueco.
---
USTED ESTÁ AQUÍ se volvió ELLA ESTÁ AQUÍ. Una ruta de lápiz va del baño del 404 al hueco del ascensor.
MARA: El grafito es fresco."""},
	"notice": {"prompt": "Examinar el aviso de acceso del 404", "text": """AVISO FINAL DE ACCESO. Local entregado. Contenido abandonado. La entrada confirma que no queda residente.

El corrector cubre la línea, pero la humedad levanta IRIS.
---
La entrada no confirma. La firma sí. Los dígitos de latón están calientes. Al tocar el segundo 4, una mujer inhala detrás de la puerta.
---
La llave gira antes de entrar del todo. Aire caliente a cobre mojado y naranja cocida.
MARA: Inspección. ¿Iris Vale?
Tres gotas responden. La cadena de Dane se mueve; el 403 sigue cerrado."""},
	"checklist": {"prompt": "Confrontar las dos listas", "text": """Lista de estado de salida
Objetos personales retirados. Pared de cocina seca. Hueco de baño cerrado. Armario vacío. Cláusula completada.
Pell marcó cada línea salvo tu firma.
---
Lista más vieja debajo:
1 Los zapatos están calientes. 2 El hervidor está caliente. 3 La pared dice un nombre.
4 Hay una mujer entre las habitaciones.
5 No me fui—
MARA: Zapatos, té, libro, cárdigan. Una casa abandonada se hunde. Esta aguanta la respiración."""},
	"frame": {"prompt": "Inspeccionar el marco vaciado", "text": """El polvo guarda la foto perdida. Dorso: Iris + Dane / primera noche con calor / octubre 2025.
---
Un borde rasgado muestra la risa de Dane y la manga amarilla de Iris. Entre ellos, un tercero con cordón de inspectora; la cara es un rectángulo extraído."""},
	"shoes": {"prompt": "Revisar zapatos y caja a medias", "text": """Bajo el zapatero, botas con yeso y zapatillas amarillas aún mojadas. Una caja a medias: tres camisas, funda de pasaporte vacía, entrega sin firmar y un billete de mañana, después de que Iris supuestamente se fuera."""},
	"thermostat": {"prompt": "Leer el historial térmico", "text": """01:47 18°C / 01:53 19°C / 02:01 21°C / 02:09 24°C / 02:17 ocupación.
El último valor no es temperatura.
---
Modo servicio: archivo 404 / compensación de calor corporal / ocupante objetivo: 1.
Mientras la mano sigue, el objetivo pasa a 2."""},
	"answering": {"prompt": "Reproducir los cinco mensajes", "text": """Msg 1 — Pell: Iris, firma la entrega. El ruido del hueco es golpe de ariete, no una voz.
Iris: ¿Llamas a mi máquina para decir que la máquina se equivoca?
---
Msg 2 — Iris: Dane, cuando Pell traiga inspectora la pared se humedece. Las manchas forman letras. Pon copias donde el edificio no pueda revisarlas.
---
Msg 3 — Pell: El inspector Harrow certificó vacante.
Iris: Nunca entró al dormitorio.
Harrow: ¿Quién metió mi abrigo en el muro?
---
Msg 4 empieza un minuto después de tu encargo. Voz de Mara: Cuarto piso. Diez minutos.
Otra voz te sigue con medio aliento de retraso.
---
Msg 5 graba pasos que aún no has dado.
MARA: Iris Vale. Dane Orlov. Elias Harrow. Tres nombres que Pell borró de tres papeles."""},
	"groceries": {"prompt": "Revisar la comida fresca", "text": """La nevera desenchufada está fría. Leche que caduca la semana que viene; media naranja en un plato.
---
Detrás: medicación de Iris Vale, retirada el 14 de noviembre a las 23:11 — dos horas después de que Pell afirmara la entrega de llaves."""},
	"invoice": {"prompt": "Leer la factura escondida", "text": """Pell Property / unidad 404-S
Abrir cavidad; aislar; cambiar pladur del lado ocupante. Programado seis días antes de la fuga.
---
Firma del cliente: Elias Harrow, fecha de mañana."""},
	"kettle": {"prompt": "Revisar el hervidor seco", "text": """El hervidor se secó tras al menos cuatro recargas. Una taza con piel de naranja; otra con el logo de Harrow Inspection.
Dentro, un hombre en voz baja: firmé porque ella golpeó desde el lado equivocado."""},
	"stain": {"prompt": "Registrar el nombre en la humedad", "text": """La cámara de la lista revela IRIS VALE — SIGUE AQUÍ en la mancha de palma.
Conservar la imagen saca el nombre del 404. Borrar marca la cocina seca y libera el pago de Pell.""", "a": "Conservar y subir la foto", "b": "Limpiar el muro y borrar"},
	"mirror": {"prompt": "Observar el espejo retrasado", "text": """Tu reflejo parpadea tarde. En el espejo la puerta del baño está cerrada; detrás de ti está abierta.
---
Aunque borres la foto de la cocina, la Mara del reflejo aún la sostiene. Una manga amarilla se retira del hueco."""},
	"medicine": {"prompt": "Leer la etiqueta de Iris", "text": """Iris Vale — retirada el 14 de noviembre. Pánico por ruido ambiental persistente.
El clínico confirmó oído normal y recibió una grabación: tres golpes de tubería y una mujer, el nombre completo de Iris."""},
	"drain": {"prompt": "Revisar el desagüe", "text": """El desagüe seco atrapa viruta de lápiz azul, un negativo y un botón de cobre con E.H.
A contraluz, Iris entra en la cavidad. Dane sujeta el tablero. Pell mira desde la puerta."""},
	"service": {"prompt": "Leer el diario del hueco", "text": """Hueco 4 / no aislar con ocupación. 01:47 admisión Harrow. 02:04 ocupante audible. 02:17 traslado. 02:23 firma. 02:29 unidad 404 no disponible.
Esta noche se escribe sola: 01:47 Venn admisión.
Tres golpes suben por el cobre. El aliento empaña la válvula."""},
	"pipe": {"prompt": "Responder o aislar la tubería", "text": """El hueco golpea tres veces. Responder crea una segunda testigo e invita a la voz más adentro. Cerrar cumple la lista de Pell.""", "a": "Responder con tres golpes", "b": "Cerrar y silenciar la válvula"},
	"clock": {"prompt": "Inspeccionar el reloj congelado", "text": """El segundero llega a 02:17 y cae. Siete fechas de alarma para siete inspecciones. La de esta noche: M.V. / 02:29."""},
	"locket": {"prompt": "Abrir el relicario bajo la almohada", "text": """Un lado, el retrato de Iris; el otro, un espejo pequeño.
Dane: recuérdame en detalles que no pueda copiar. Odio la mermelada de naranja. Canto desafinada. Elegí el amarillo porque dijiste que volvía el invierno provisional.
El espejo muestra el armario abierto. En la habitación sigue cerrado."""},
	"letters": {"prompt": "Leer las quejas no enviadas de Iris", "text": """Borrador 1: la humedad vuelve solo cuando administración programa inspección.
Borrador 2: Harrow me creyó hasta entrar en la cavidad. Salió preguntando por qué mis cosas estaban en su piso.
Borrador 3: me quedaré dentro del límite mientras Dane sujeta el tablero. El cobre cruza cada versión de esta habitación.
Inspectora: no me salves quitando la prueba. Guarda la imagen. Responde a la tubería. Abre desde dentro y declara lo que presenciaste."""},
	"wardrobe": {"prompt": "Abrir el armario y el falso muro", "text": """Abrigos gris, marrón, amarillo, luego una percha vacía que aún se mueve.
El pestillo interior abre el contrachapado: aislante, cobre, grabadora y una cavidad donde cabe una persona.
No hay cuerpo. Las uñas están del lado de la habitación."""},
	"cassette": {"prompt": "Reproducir el testimonio completo de Iris", "text": """IRIS: Me llamo Iris Vale. Hoy es 14 de noviembre. Alquilo el 404. Administración borró mi nombre mientras yo seguía dentro.
Cada inspectora llama abandono a mis cosas y golpe de ariete a mi voz. Harrow creyó y firmó vacante.
El edificio no quita habitaciones: equilibra ocupantes. Entré en la cavidad a propósito.
Deja mi nombre fuera de este piso. Responde tres golpes. En el último, abre desde dentro y declara."""},
	"followup_yes": {"prompt": "Atender la llamada en vivo de Pell", "text": """PELL: Tu informe contiene el nombre de la ocupante anterior. Bórralo antes de sincronizar.
MARA: Iris retiró medicación después de la entrega. Pediste este muro antes de la fuga. Harrow firmó una factura de mañana.
Iris golpea bajo su voz. En el tercero, Pell se detiene.
PELL: Cierra la válvula. Una voz sin unidad no tiene estatus.
MARA: Una testigo se lo da."""},
	"followup_no": {"prompt": "Atender la llamada en vivo de Pell", "text": """PELL: La foto corregida y la válvula cerrada se transmiten limpias.
MARA: Encontré medicación y cartas.
PELL: Objetos abandonados. Completa la cláusula.
Detrás de él, la cinta de Iris dice que siempre prefiere la historia más limpia.
Tu informe sustituye a la ocupante Iris Vale por la custodia Mara Venn."""},
	"clause": {"prompt": "Decidir la cláusula de pernocta", "text": """La firmante acepta la custodia del 404 y de los bienes pendientes hasta la mañana. La custodia sustituye la ocupación previa.
Firmar conserva la habitación y te nombra única ocupante. Rechazar tumba la orden de Pell y hace que el pasillo dude de que el 404 exista.""", "a": "Firmar como custodia temporal", "b": "Romper y rechazar la cláusula"},
	"final_signed": {"prompt": "Inspeccionar la llave cambiada y la mirilla", "text": """La etiqueta dice ahora ocupante — Mara Venn. Tu informe llama tuyos los zapatos de Iris.
DANE: La firma no es la puerta. Ábrela. Di su nombre antes de que el edificio termine el tuyo.
Cuatro golpes. En la mirilla, Pell no tiene cara. Detrás espera una manga amarilla."""},
	"final_refused": {"prompt": "Inspeccionar la llave cambiada y la mirilla", "text": """Las dos mitades dicen UNIDAD 404: NO ENCONTRADA. Los dientes de la llave están lisos.
DANE: Rompiste la cláusula, no la inspección. Abre y nómbrala, o calla y deja que el pasillo elija.
En la mirilla hay tres puertas. Donde estuvo el 404 ves tu propia nuca."""},
	"final": {"prompt": "Responder al último golpe", "text": """Cuatro golpes: 4 — silencio — 4. Abrir convierte la prueba en testimonio. Ignorar presenta el informe tal como ya lo reescribieron tus elecciones.""", "a": "Abrir y declarar lo presenciado", "b": "Certificar vacante e ignorar la puerta"},
}
