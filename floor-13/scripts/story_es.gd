extends RefCounted
class_name StoryEs

## StoryEs player-facing script.

const AREAS := [
	{
		"id": "cubicle", "chapter": "1 / 7", "place": "CUBÍCULO DE JUNE", "clock": "11:59 PM",
		"objective": "Inspecciona el último ticket y el escritorio que June deja atrás.",
		"opening": [
			["NARRACIÓN", "El domingo ha reducido Meridian Ledger a un cubículo encendido. La lluvia peina las ventanas negras. El tubo sobre el escritorio de June Park zumba hasta aflojarle los dientes. Más allá del tabique, la oficina está tan vacía que cada máquina pequeña suena viva."],
			["JUNE", "Un último ticket. Envíalo, marca la salida y no aceptes nunca más un «cierre flexible». Rusk prometió que la corrección tardaría cinco minutos. También prometió tres veces que mi contrato temporal casi terminaba."],
			["SISTEMA", "TICKET EXTRA 1313. Reconcilia a la empleada 013 antes de las 00:00. Si no se cierra, las horas pendientes pasan a la analista activa. Analista activa: JUNE PARK. Saldo: 168:00:00."],
			["NARRACIÓN", "El reloj sobre la salida de emergencia avanza, duda y vuelve a las 11:59. En algún punto del piso, una impresora despierta y alimenta una bandeja vacía."]
		],
		"hotspots": [
			["ticket", "ÚLTIMO TICKET", [82, 78, 105, 64], [
				["JUNE", "Empleada 013: Mara Vale. Analista de nómina. Estado: AUSENTE. Horas esta semana: ciento sesenta y ocho. Solo hay ciento sesenta y ocho horas en una semana. Según esto, trabajó todas y faltó a todas."],
				["SISTEMA", "Corrección sugerida: NUNCA EMPLEADA. Enviar admite que no existió trabajo, identidad ni compensación pendiente."],
				["NARRACIÓN", "Un segundo cursor aparece junto al de June. Se mueve medio pulso después, rodea el nombre de Mara y subraya ANALISTA ACTIVA. Cuando suelta el ratón, el segundo cursor sigue."],
				["JUNE", "Un error es evidencia antes de ser una corrección. Papá lo decía de las auditorías fiscales. Hablaba de números. Nunca tuvo que aclarar que también hablaba de personas."]
			]],
			["phone", "TELÉFONO DEL ESCRITORIO", [215, 70, 55, 44], [
				["RUSK / BUZÓN DE VOZ", "Park. No me devuelvas la llamada. Las filas rojas no son personas; son varianza. Corrige la fila, imprime tres copias y deja una en mi bandeja de salida. Si alguien te pide que restaures un nombre, no está en nómina."],
				["NARRACIÓN", "La grabación tiene fecha del lunes, 08:04: dentro de ocho horas. Bajo la voz de Rusk, una multitud susurra un número de empleado. Trece. Trece. Trece. No al unísono; con la cadencia irregular de quien pasa lista."],
				["RUSK / BUZÓN DE VOZ", "¿Y Park? No uses las escaleras después de medianoche. Mantenimiento no ha certificado el rellano trece. No hay rellano trece. Si ves uno, cierra los ojos y sigue bajando."],
				["JUNE", "Sabía que yo seguiría aquí. Grabó instrucciones en el futuro porque lo sabía. O la fecha está rota, o esta empresa ha encontrado la manera de programar la negligencia con efecto retroactivo."]
			]],
			["coffee", "CAFÉ TIBIO", [26, 105, 47, 39], [
				["NARRACIÓN", "June se terminó el café a las diez, pero la taza vuelve a estar tibia y llena. Una marca de pintalabios que no es suya forma un anillo completo. La superficie tiembla cada vez que parpadea el fluorescente."],
				["MARA / LETRA", "CUANDO EL RELOJ PIERDA UN MINUTO, MIRA EL DIRECTORIO. CUANDO EL DIRECTORIO GANE UNA PLANTA, NO DEJES QUE APRENDA POR DÓNDE PIENSAS SALIR."],
				["JUNE", "La letra está tan apretada contra la funda que el cartón se ha rajado. Mara Vale. Si es una broma, alguien aprendió el nombre de una fila confidencial de nómina y recalentó café malo para ambientar."],
				["NARRACIÓN", "En el fondo de la taza, un poso pálido se ordena en letras de molde diminutas: ANTES. June parpadea. Vuelve a ser solo leche en polvo."]
			]],
			["drawer", "CAJÓN CERRADO", [198, 119, 75, 42], [
				["NARRACIÓN", "El cajón estaba cerrado cuando llegó June. Ahora se abre sin resistencia. Dentro hay un formulario de renuncia con su firma completa, fechado el lunes. Motivo de la baja: EL PUESTO NUNCA EXISTIÓ."],
				["JUNE", "Nunca he escrito la P así. Salvo que… no. Sí lo hice, a los dieciséis. Antes de entrenarme para que pareciera más profesional. Quien firmó esto conocía una versión antigua de mi letra."],
				["NARRACIÓN", "La copia de carbón de debajo lleva el nombre de Mara Vale con la misma letra. Los dos formularios tienen el sello de aceptación del supervisor Rusk. La tinta huele tan fresca que pica."],
				["MARA / NOTA EN CARBÓN", "Una renuncia no es una salida. Es permiso para que cuenten la historia sin ti. Guarda tu propia copia. Guarda los nombres de todos."]
			]]
		],
		"transition": [
			["NARRACIÓN", "El reloj retrocede con un clic hasta las 11:58. Cuarenta monitores vacíos despiertan al otro lado del tabique de June, y todos muestran su silla en directo. En una de las vistas, alguien está de pie detrás."],
			["PA", "Personal de Operaciones Nocturnas: presentarse en la Planta 13 para el cierre. Personal de Operaciones Diurnas: ignoren cualquier voz, alarma o persona observada tras la salida programada."],
			["JUNE", "Meridian ocupa de la ocho a la doce. El directorio se salta la trece. Siempre se ha saltado la trece."],
			["NARRACIÓN", "La campana del ascensor responde desde el vestíbulo lejano. Dos notas: un tintineo limpio y otra más grave que parece sonar dentro del pecho de June."]
		]
	},
	{
		"id": "office", "chapter": "2 / 7", "place": "OFICINA ABIERTA", "clock": "11:58 PM",
		"objective": "Averigua por qué el directorio ha añadido una planta.",
		"opening": [
			["NARRACIÓN", "Cuarenta sillas miran a cuarenta monitores. Cada pantalla muestra el cubículo abandonado de June desde un ángulo ligeramente distinto. Esos ángulos exigirían cámaras dentro de las paredes, bajo la moqueta y justo detrás de sus propios ojos."],
			["JUNE", "Todos se fueron a las once. Nóminas se despidió con la mano. Mantenimiento apagó la música. Vi bajar el contador del ascensor. ¿Entonces quién ha apartado todas estas sillas de sus mesas?"],
			["NARRACIÓN", "Una línea roja de escáner despierta al fondo de la oficina. Recorre los tabiques por debajo con una precisión mecánica y paciente, se detiene en cada silla vacía y marca cada monitor como PRESENTE."],
			["PA", "Ausencia sin resolver detectada. Queda en las instalaciones un reemplazo temporal activo. Gracias por ofrecerse voluntaria para restablecer el equilibrio."]
		],
		"hotspots": [
			["printer", "IMPRESORA EN MARCHA", [35, 83, 74, 70], [
				["NARRACIÓN", "La impresora saca una foto de plantilla en papel grueso y caliente. La fecha de la esquina es 1998. June está en la última fila con una sudadera de la universidad que donó hace cuatro años."],
				["JUNE", "Esa soy yo. Más joven que ahora, en una foto tomada antes de que yo naciera. La mujer de mi lado está raspada tan a fondo que queda un agujero con forma de persona."],
				["MARA / PIE DE FOTO", "EQUIPO DE CIERRE DEL LIBRO MERIDIAN. Los reemplazos salen más baratos que las horas extra. Sonríe hasta el flash. Si el flash se queda en rojo, no te muevas hasta que Cumplimiento termine de contar."],
				["NARRACIÓN", "En el reverso hay cuarenta y dos números de empleado escritos a lápiz. El primero es de Mara. El último, de June. Entre ambos, la letra se va convirtiendo poco a poco en la de June."],
				["JUNE", "Me lo llevo. Si consigo salir, quiero una cosa física que no pueda actualizarse mientras la leo."]
			]],
			["attendance", "TABLERO DE ASISTENCIA", [131, 62, 64, 82], [
				["NARRACIÓN", "Tiras magnéticas con nombres llenan el tablero: Mara, Eli, June y treinta y nueve rectángulos en blanco. June mueve su tira de DENTRO a FUERA. Vuelve a su sitio con tanta fuerza que le pellizca el dedo."],
				["SISTEMA", "JUNE PARK — DENTRO. Inicio: domingo 22:48. Fin: pendiente de conciliación. Turno acumulado: 01:10. Turno heredado: 168:00."],
				["JUNE", "¿Heredado de quién? ¿De Mara? El ticket no transfirió dinero. Transfirió tiempo. El sistema trata su semana perdida como una deuda que alguien tiene que habitar."],
				["NARRACIÓN", "La tira de Eli Song está tibia y húmeda. Debajo hay seis tiras más antiguas con seis nombres distintos y el mismo número de empleado emborronado."]
			]],
			["directory", "DIRECTORIO DEL ASCENSOR", [231, 41, 65, 91], [
				["NARRACIÓN", "Las letras de latón se aflojan y reptan por el fieltro negro. De la ocho a la doce pasan a ser OPERACIONES DIURNAS. El hueco entre la doce y la catorce se abre como un párpado: 13 — OPERACIONES NOCTURNAS."],
				["JUNE", "Ahí. La línea nueva. Y otra por debajo del sótano: cero, Retención. Los edificios no tienen Planta Cero. Los sistemas de nómina sí. Un registro puesto a cero es uno que pueden fingir que nunca existió."],
				["NARRACIÓN", "La etiqueta de la Planta 13 es latón viejo pulido por muchos dedos. June recuerda el directorio liso. También recuerda pasar cada mañana junto a esta etiqueta y no verla a propósito."],
				["MARA / NOTA RAYADA", "EL EDIFICIO NO ESCONDE LA PLANTA. ESCONDE TU RECUERDO DE HABER ACEPTADO."]
			]],
			["camera", "MONITOR DE SEGURIDAD", [201, 128, 96, 43], [
				["NARRACIÓN", "La cámara del vestíbulo va un minuto adelantada. La June del futuro está ante el ascensor, mirando esta pantalla. Detrás de ella, una forma alta del color de un traje se despliega desde la estrecha rendija entre cubículos."],
				["JUNE", "Si es en directo, tengo un minuto. Si es una predicción, quizá pueda negarme a estar ahí. Si es un recuerdo, ya he fracasado al intentar irme."],
				["NARRACIÓN", "La forma no tiene cabeza, solo una línea roja horizontal de escaneo. Atraviesa sillas, mesas y yeso. Donde cruza el reflejo futuro de June, su número de empleado sustituye su cara."],
				["SEGURIDAD", "PROCESO AUDITOR 13. Escaneo de retención activo. La varianza solo adquiere forma cuando se observa. Observación registrada."],
				["NARRACIÓN", "En la planta real cruje un tabique. La línea roja está más cerca."]
			]]
		],
		"transition": [
			["NARRACIÓN", "Se abre el ascensor. Su pared de espejo refleja a un joven agazapado detrás de June. La cabina real está vacía. Cuando se gira, él está de pie a tres metros, en la oficina."],
			["ELI", "No grites. Cuenta los cambios bruscos. Y por favor, no escanees mi tarjeta. El Auditor sigue los avisos de las tarjetas."],
			["JUNE", "¿Quién eres? Todo el mundo se fue a casa."],
			["ELI", "Soy Eli Song. Me fui a casa hace seis lunes. Me sigue trayendo de vuelta antes de llegar al martes. Si todavía recuerdas que el directorio cambió, tenemos unos veinte minutos."]
		]
	},
	{
		"id": "breakroom", "chapter": "3 / 7", "place": "SALA DE DESCANSO", "clock": "11:46 PM",
		"objective": "Decide si Eli es un testigo o una trampa.",
		"opening": [
			["NARRACIÓN", "Eli lleva a June a la sala de descanso, donde el motor de la nevera tapa sus voces. Bajo la luz verde de emergencia aparenta veintidós años y un cansancio que lo vuelve anciano."],
			["ELI", "El reloj te devuelve minutos cuando quiere que investigues. No lo confundas con clemencia. Está construyendo un registro que diga que entendiste las condiciones."],
			["JUNE", "Sabías el nombre de Mara Vale antes de que yo lo dijera."],
			["ELI", "Mara me enseñó dónde esconderme. En cada bucle cuesta un poco más recordarla. En cada bucle la empresa usa mejor su voz."]
		],
		"hotspots": [
			["badge", "LA TARJETA EN BLANCO DE ELI", [221, 71, 51, 72], [
				["NARRACIÓN", "Eli pone la tarjeta bajo el tubo ultravioleta de la máquina expendedora. Bajo su nombre aparecen seis capas de nombres: becarios temporales, todos asignados a Sustitución de Ausencias."],
				["ELI", "Reutilizan la tarjeta cuando la persona deja de coincidir con ella. Primero la cámara olvida tu cara. Luego los compañeros recuerdan una mesa vacía. Luego tu madre llama a la oficina y acepta que se equivocó de número."],
				["JUNE", "¿Entonces por qué la sigues llevando?"],
				["ELI", "Las puertas solo se abren para empleados, y las salidas solo para personas. El truco es seguir siendo las dos cosas hasta llegar al vestíbulo. Mara casi lo consiguió. Rusk la corrigió mientras sujetaba la puerta."],
				["NARRACIÓN", "La foto de la tarjeta no está solo en blanco. Su espacio blanco es más profundo que el plástico: una habitación diminuta iluminada con algo de pie al fondo."]
			]],
			["rota", "TURNOS DE LA SALA DE DESCANSO", [28, 35, 76, 79], [
				["NARRACIÓN", "El cuadrante reparte tareas por día: café, lavavajillas, denuncia de desaparición. El lunes es de Mara. El martes, de Eli. El miércoles, de June. No hay columnas después del miércoles."],
				["ELI", "Al principio creí que era humor de oficina cruel. Luego el martes nunca llegó. La denuncia de desaparición es una tarea real. La rellenas por quien se sentaba aquí antes que tú, y Cumplimiento la archiva como baja voluntaria."],
				["JUNE", "Mi nombre está escrito con una tinta que ya se ha desvaído. Alguien programó mi desaparición antes de mi primer turno."],
				["MARA / NOTA AL MARGEN", "No dejes que aíslen los nombres. Un patrón es una prueba. Un solo empleado desaparecido es una tragedia personal que pueden extraviar administrativamente."]
			]],
			["fridge", "CUARENTA Y DOS ALMUERZOS", [117, 43, 75, 103], [
				["NARRACIÓN", "Cuarenta y dos bolsas de almuerzo llenan la nevera, todas con fecha de este mismo domingo. Una rotulada JUNE contiene la llave de su casa, un cheque de indemnización por cero dólares y una muela envuelta en una nómina."],
				["JUNE", "La llave tiene el hilo azul que le até. La usé esta mañana para entrar en mi piso. La muela tiene un empaste plateado en el mismo sitio que la mía."],
				["ELI", "No abras la mía. En el último bucle había una tarjeta de cumpleaños de mi hermana. Escribió que era un alivio que yo nunca hubiera existido. No puedo leerla dos veces y seguir siendo útil."],
				["NARRACIÓN", "La bolsa rotulada MARA solo contiene un rollo de papel de impresora matricial. En cada hoja perforada se repite una frase: ESTUVE AQUÍ EL TIEMPO SUFICIENTE PARA QUE ME DEBAN ALGO."],
				["JUNE", "Entonces hacemos visible la deuda. Horas, salarios, nombres. No discutimos de almas con esa cosa. Le damos números que no pueda borrar cómodamente."]
			]],
			["compliance_phone", "TELÉFONO DE CUMPLIMIENTO", [120, 135, 71, 31], [
				["NARRACIÓN", "El teléfono de pared no tiene teclado, solo un lector de tarjetas y dos pilotos: verde, EN LISTA; rojo, VARIANZA. Al descolgar suena la voz de Rusk sin que haya sonado el timbre."],
				["RUSK / GRABACIÓN", "El personal fuera de lista debe ser denunciado. El silencio es participación. La participación genera responsabilidad compartida. Meridian protege a los empleados que identifican con prontitud los registros que no corresponden."],
				["ELI", "Así atrapó a los demás. No persiguiéndolos. Ofreciendo a cada uno una parte más pequeña de la culpa. Escanéame y te dejará creer que has comprado tiempo."],
				["CUMPLIMIENTO", "Analista Park: personal fuera de lista detectado en las cercanías. La denuncia es confidencial. La consideración para ascenso es automática."],
				["JUNE", "El auricular está caliente. Estaba esperando mi mano."]
			]]
		],
		"choice": {
			"id": "eli_stance", "prompt": "¿Es Eli un testigo, o una varianza fuera de lista?",
			"a": ["CONFIAR — Dar a Eli el pase de visitante", "TRUST"],
			"b": ["SOSPECHAR — Escanear a Eli para Cumplimiento", "SUSPECT"]
		},
		"after": {
			"TRUST": [
				["JUNE", "Toma mi pase de visitante de repuesto. Tapará la foto en blanco sin enviar un aviso de personal."],
				["ELI", "Has decidido que soy una persona casi sin pruebas. Intentaré merecer la irregularidad de procedimiento. Si rechazas a Cumplimiento, baja por las escaleras. Yo puedo sujetar la puerta."],
				["NARRACIÓN", "Bajo el pase de visitante de June, la cara de Eli vuelve al plástico píxel a píxel. El piloto verde sigue apagado. El motor de la nevera suelta un largo estremecimiento de alivio."]
			],
			"SUSPECT": [
				["JUNE", "No puedo verificar nada de lo que has dicho. Apártate del lector."],
				["NARRACIÓN", "June acerca la tarjeta de Eli al teléfono. El piloto rojo despierta. Su fotografía pierde los ojos, luego la boca. Una línea de escáner repta bajo la puerta."],
				["ELI", "Nunca necesitó que confiaras en mí. Necesitaba que practicaras llamar discrepancia a una persona."],
				["NARRACIÓN", "Eli echa a correr. El auricular sigue respirando cuando ya se ha ido. Cumplimiento añade INICIATIVA DE DENUNCIA al expediente de June."]
			]
		},
		"transition": [
			["NARRACIÓN", "Detrás de la máquina expendedora, una puerta de servicio se abre con un clic. Una luz fría y azul de servidores corta el linóleo. El pasillo del otro lado es mucho más largo que el edificio."],
			["MARA / TERMINAL", "JUNE PARK. Si puedes leer esto, Eli te ha alcanzado o Cumplimiento lo ha usado para alcanzarte. En cualquier caso, ven antes de que el libro original termine de olvidar la tinta."]
		]
	},
	{
		"id": "server", "chapter": "4 / 7", "place": "PASILLO DE SERVIDORES", "clock": "11:53 PM",
		"objective": "Responde a la exigencia de Cumplimiento de entregar el libro original.",
		"opening": [
			["NARRACIÓN", "Los ventiladores empujan aire de invierno por un pasillo que no cabe en el plano de Meridian. Los pilotos azules parpadean como ventanas de pisos lejanos. Una línea roja de escaneo recorre el suelo."],
			["CUMPLIMIENTO", "Analista activa Park. El empleado 013 sigue sin resolver. Entregue el libro original para su corrección. La cooperación protege al personal fijo de los errores temporales."],
			["JUNE", "Aquí no hay personal fijo. Hay personas a las que todavía no han reemplazado."],
			["NARRACIÓN", "El escáner se detiene ante sus zapatos como si sopesara la distinción, y luego sigue hacia la pared."]
		],
		"hotspots": [
			["rack", "RACK DE PERSONAL 13", [29, 42, 72, 109], [
				["NARRACIÓN", "El rack 13 contiene carpetas de papel en lugar de hardware. Cuarenta y dos carpetas usan el mismo código de puesto. Cada analista temporal cubrió la ausencia inexplicada del anterior y se convirtió en la siguiente ausencia inexplicada."],
				["JUNE", "Un puesto, cuarenta y dos contrataciones, ningún solapamiento, ninguna entrevista de salida. Rusk ha ido arrastrando horas sin pagar y haciendo responsable del saldo a cada reemplazo."],
				["NARRACIÓN", "Las firmas de aprobación empiezan como las mayúsculas apretadas de Rusk. Hacia la carpeta treinta, la firma es una franja roja de escáner. El sistema lleva tiempo aprobando sus propias correcciones."],
				["CONDITIONAL", "ELI_FOLDER"],
				["MARA / NOTA EN LA PESTAÑA", "Prueba, página 13: cronología de reemplazos. Copia el patrón entero. Cumplimiento sobrevive obligando a cada testigo a defender solo su propio nombre."]
			]],
			["terminal", "EL TERMINAL DE MARA", [121, 55, 84, 71], [
				["MARA", "Tú tienes mis horas. Yo tengo tu autorización de salida. El sistema permite una sola identidad activa a medianoche, porque Rusk diseñó la nómina en torno a una silla y no a las personas que hizo pasar por ella."],
				["JUNE", "¿Estás viva?"],
				["MARA", "Eso es una categoría de Recursos Humanos, no una respuesta. Estoy presente allí donde una copia sin corregir me recuerda. Ahora mismo, eso incluye este terminal, dos fotografías y a ti."],
				["MARA", "El Auditor no es un fantasma. Es una política con electricidad suficiente para moverse. Rusk lo alimentó con excepciones hasta que las excepciones aprendieron a pedir cuerpos."],
				["CONDITIONAL", "MARA_ELI"],
				["JUNE", "Dime cómo salir."],
				["MARA", "No salgas como una empleada asustada. Sal como la prueba de cuarenta y dos. El libro original está detrás de la rejilla. Tu decisión final tiene que coincidir con la ruta que tomes, o clasificará tu verdad como parcial."]
			]],
			["ledger", "EL LIBRO ORIGINAL", [225, 91, 72, 60], [
				["NARRACIÓN", "Tras una rejilla suelta hay papel de impresora matricial sellado ANTES. Recoge cuarenta y dos nombres, las horas originales y las aprobaciones de Rusk. El nombre de Mara no falta: está sobrescrito con el ID temporal de June."],
				["JUNE", "El dinero se pagaba a una cuenta de retención llamada Retención. Cada reemplazo generaba otra semana de salarios retenidos. La nómina desaparecida no es un efecto secundario. Es el modelo de negocio."],
				["MARA / NOTA DEL LIBRO", "Si esta copia llega a la luz del día, la Planta 13 no podrá llamarnos errores aislados. Si Cumplimiento se la come, el registro seguirá recordando que elegiste quién se beneficiaba del olvido."],
				["NARRACIÓN", "Los bordes perforados aletean con el viento de los servidores. En cada nombre tachado, unas letras azul pálido suben a través de la tinta y se quedan visibles: PRESENTE."],
				["JUNE", "Puedo conservarlo, pero llevarlo encima me convierte en un blanco. Claro. Una prueba no es más que un testigo que no puede huir."]
			]],
			["intercom", "INTERFONO DE EMERGENCIA", [109, 139, 97, 29], [
				["RUSK / GRABACIÓN", "Operaciones Nocturnas existe para que los números del día sean posibles. Las horas sin pagar siempre son de alguien. Firma la corrección y no serán tuyas. Al menos, no esta noche."],
				["RUSK / GRABACIÓN", "Al principio me opuse. Luego entendí la continuidad. Un empleado sufre; cientos reciben cheques correctos. Un gerente acepta la aritmética que nadie más soporta."],
				["JUNE", "Un gerente que creyera eso lo diría en directo. Un cobarde lo graba para el siguiente y programa el archivo para cuando ya no esté."],
				["RUSK / GRABACIÓN", "Supervisora Park, cuando vuelva a oír esto, forme al siguiente analista temporal antes del cierre. Use lo de la flexibilidad. Funciona bien en las pruebas."],
				["NARRACIÓN", "La grabación termina con un sello de contrato y la propia voz de June diciendo: «Las filas rojas no son personas». Ella nunca ha dicho esas palabras. Todavía no."]
			]]
		],
		"choice": {
			"id": "compliance", "prompt": "Cumplimiento exige el libro original de Mara.",
			"a": ["NEGARSE — Conservar el libro", "REFUSE"],
			"b": ["OBEDECER — Enviar la corrección", "OBEY"]
		},
		"after": {
			"REFUSE": [
				["JUNE", "Solicitud denegada. Conservo el original como prueba de robo de salarios y falsificación de registros de personal."],
				["CUMPLIMIENTO", "TESTIGO HOSTIL. Protecciones temporales revocadas. Derecho de salida suspendido."],
				["NARRACIÓN", "June dobla las hojas dentro del abrigo. Los pilotos de los servidores se vuelven de un azul espectral. Tres nombres borrados se restauran solos en el registro del caso. El escáner rojo empieza a moverse más rápido."],
				["MARA", "Bien. Solo entiende la negativa como otra categoría, pero las categorías se pueden recurrir. Las personas borradas sin registro, no."]
			],
			"OBEY": [
				["JUNE", "Enviar corrección. Mara Vale: nunca contratada."],
				["NARRACIÓN", "La impresora se come el original perforación a perforación. Produce la tarjeta permanente de June, tibia como la piel. El escáner se vuelve rojo sangre."],
				["CUMPLIMIENTO", "APTA PARA SUCESIÓN. Iniciativa reconocida. Horas pendientes aplazadas de forma condicional."],
				["MARA", "No me has borrado a mí. Has borrado la prueba de que Rusk necesitó a otros cuarenta y uno antes que tú. Recuérdalo cuando te ofrezca su silla."],
				["NARRACIÓN", "La voz de Mara se desploma en un chillido de módem. La tarjeta imprime una línea más: REPORTA A JUNE PARK."]
			]
		},
		"transition": [
			["PA", "Cierre de medianoche iniciado. Todas las salidas bloqueadas hasta que la identidad activa y la ausencia pendiente cuadren."],
			["NARRACIÓN", "El ascensor se abre y se cierra solo. La alarma de la escalera destella sin sonido. June tiene dos rutas hacia el despacho imposible de Rusk, y las dos esperan aprender su preferencia."]
		]
	},
	{
		"id": "lobby", "chapter": "5 / 7", "place": "VESTÍBULO DEL ASCENSOR", "clock": "12:00 AM",
		"objective": "Elige una ruta de escape y acepta lo que revela.",
		"opening": [
			["NARRACIÓN", "A medianoche, las puertas de la oficina se bloquean una tras otra. La pantalla del ascensor alterna entre 13 y 0. El cartel de la escalera señala hacia arriba y hacia abajo a la vez."],
			["CUMPLIMIENTO", "No es necesario evacuar. Permanecer en las instalaciones constituye la aceptación de tareas correctivas razonables."],
			["JUNE", "Entonces no evacuo. Llevo a cabo una investigación mientras busco una puerta con urgencia."],
			["NARRACIÓN", "En el cristal del directorio, el reflejo de June ya lleva la corbata roja de Rusk."]
		],
		"hotspots": [
			["firemap", "MAPA DE EVACUACIÓN", [24, 49, 74, 91], [
				["NARRACIÓN", "El mapa muestra la escalera bajando de la catorce directamente a la doce. Cuando June toca el cristal aparece un rellano trece escrito a mano: NO CUENTES LOS ESCALONES. ELLOS TE CUENTAN A TI."],
				["JUNE", "La inspección de la ruta la firmó Mara y la sobrescribió Rusk. Una segunda anotación menciona cuarenta y dos abrigos guardados en el rellano. Propiedad de reemplazos, no desechar."],
				["NARRACIÓN", "Una línea azul marca un camino que rodea todos los lectores de tarjetas. Termina en el despacho del gerente y continúa, imposible, a través de la ventana pintada."],
				["MARA / NOTA DEL MAPA", "La escalera recuerda cuerpos. El ascensor recuerda permisos. Elige el tipo de prueba que tu respuesta final pueda defender."]
			]],
			["seal", "PRECINTO DEL ASCENSOR", [223, 47, 70, 78], [
				["NARRACIÓN", "La fecha de inspección avanza mientras June la lee. La firma del inspector cambia de Rusk a Mara y a June. Bajo el precinto hay una ranura para tarjeta manchada por años de etiquetas arrancadas."],
				["SISTEMA", "Cabina 13 certificada para descenso hasta Retención. El servicio de subida a Operaciones Nocturnas requiere credencial de gerencia o estado de sucesión aceptado."],
				["JUNE", "La ruta del ascensor está pensada para quien acepte convertirse en gerencia. Si bajo, quizá encuentre la máquina que imprime las tarjetas en blanco. O quizá solo le entregue la mía."],
				["NARRACIÓN", "Suena una campana grave. Las puertas del ascensor se separan dos dedos. Por la rendija no se ve la cabina, sino una hilera de trajes vacíos que se pierde en una oscuridad azul."]
			]],
			["route_phone", "TELÉFONO QUE SUENA", [119, 118, 78, 39], [
				["CONDITIONAL", "ROUTE_PHONE"],
				["NARRACIÓN", "El cable en espiral se mete en la pared y sigue tras el yeso como una vena negra. Cada vez que suena el teléfono, el escáner rojo de la oficina se detiene a escuchar."],
				["JUNE", "Sea esa voz Eli o Cumplimiento, quiere que entienda que la ruta no es un pasillo neutral. Es un testimonio. Lo que encuentre decide lo que después pueda hacer con honestidad."]
			]],
			["glass", "CRISTAL DEL DIRECTORIO", [109, 39, 82, 66], [
				["NARRACIÓN", "El reflejo de June lleva la corbata de Rusk. Mara está a su lado sin rostro. El Auditor solo aparece como la estrecha oscuridad que las separa."],
				["AUDITOR", "Un testigo que acepta un beneficio pasa a ser plantilla. La plantilla que rechaza su deber pasa a ser ausencia. No hay más categorías."],
				["JUNE", "Ese es todo el truco, ¿verdad? Haces las categorías demasiado pequeñas y luego castigas a la gente por desbordarlas."],
				["MARA", "No puede imaginar la solidaridad porque la solidaridad no cabe en un solo campo de empleado. Oblígalo a procesar más nombres de los que caben en una silla."],
				["NARRACIÓN", "Durante un segundo Mara tiene cara: ojos cansados, pelo corto, una pequeña cicatriz en la barbilla. Luego el directorio se actualiza y vuelve a ser letras de latón."]
			]]
		],
		"choice": {
			"id": "escape_route", "prompt": "¿Qué ruta investigará June?",
			"a": ["ESCALERA — Seguir las marcas del testigo", "STAIRS"],
			"b": ["ASCENSOR — Bajar a la Planta 0", "ELEVATOR"]
		},
		"after": {
			"STAIRS": [
				["NARRACIÓN", "June entra en la escalera de hormigón. El rellano trece aparece después del doce y otra vez antes del doce. Cuarenta y dos abrigos cuelgan de las tuberías, cada uno con un nombre grabado debajo."],
				["CONDITIONAL", "STAIR_HELP"],
				["JUNE", "Mara Vale. Eli Song. Anika Bose. Tom Reyes. Leanne Wu. Un nombre por escalón. No dejaré que la cuenta los convierta en un total."],
				["NARRACIÓN", "Cada nombre pronunciado devuelve un color al rellano. Bajo el último abrigo, June encuentra la lista completa de reemplazos y la sube consigo."]
			],
			"ELEVATOR": [
				["NARRACIÓN", "June entra en la cabina. Desciende por debajo del sótano sin moverse. La Planta 0 se abre a filas de impresoras de tarjetas que estampan caras blancas y vacías."],
				["CUMPLIMIENTO", "Retención almacena materiales de identidad reutilizables. Los efectos personales pasan a ser propiedad de la empresa tras una ausencia voluntaria."],
				["JUNE", "Esto no son materiales. Dientes, llaves, muestras de letra, grabaciones familiares: os quedasteis lo suficiente de cada persona para fabricar su consentimiento."],
				["NARRACIÓN", "Ante la última impresora cuelga un traje vacío. En el pecho lleva prendida la tarjeta maestra de Rusk. June la coge. El traje se desmorona, aliviado de su última credencial."],
				["NARRACIÓN", "Las puertas se cierran. Cuando vuelven a abrirse, la pantalla marca 13 aunque la cabina nunca se movió. La tarjeta de Rusk late en rojo en la mano de June."]
			]
		},
		"transition": [
			["NARRACIÓN", "La ruta elegida lleva a June hasta una puerta de nogal que nunca formó parte de la oficina. Unas letras doradas se ensamblan sobre ella: SUPERVISORA PARK."],
			["AUDITOR", "Conciliación final preparada. Entre para aceptar la renuncia o la sucesión."]
		]
	},
	{
		"id": "stairs", "chapter": "6 / 7", "place": "EL RELLANO TRECE", "clock": "12:01 AM",
		"objective": "Lleva las pruebas de la ruta a través del rellano imposible.",
		"opening": [
			["NARRACIÓN", "Todas las rutas terminan en el mismo rellano imposible. Tras las puertas del ascensor suben escalones de hormigón; dentro de la escalera brillan paneles de ascensor de latón. El edificio ha dejado de fingir que son espacios separados."],
			["JUNE", "Aquí la elección pasa a formar parte del registro. La escalera me dio nombres. El ascensor me dio autoridad. Cualquiera de las dos puede ser una prueba o una excusa."],
			["NARRACIÓN", "Los abrigos se mecen sin viento. Las tarjetas en blanco golpetean contra los botones. Arriba, una falsa luz de día asoma bajo la puerta del despacho del gerente."],
			["AUDITOR", "Continúe. Las horas pendientes aumentan durante la vacilación."]
		],
		"hotspots": [
			["coats", "CUARENTA Y DOS ABRIGOS", [23, 49, 88, 99], [
				["NARRACIÓN", "Los cuarenta y dos abrigos van desde lana de invierno hasta una rebeca fina de verano. En los bolsillos hay abonos de transporte, pastillas para la tos, recibos de guardería y notas dobladas que recuerdan comprar leche al salir."],
				["JUNE", "Cosas corrientes. Eso es lo que las carpetas borraron. Nadie era una unidad de reemplazo. Eran personas que pensaban ir a algún sitio después de este turno."],
				["CONDITIONAL", "COAT_EVIDENCE"],
				["MARA", "Rusk decía que los detalles personales eran irrelevantes. El Auditor aprendió que irrelevante significaba permiso. Llévate algo que no pueda traducir a horas."],
				["NARRACIÓN", "June se guarda un dibujo de guardería con cuarenta y dos monigotes bajo un cielo azul. Una figura roja espera dentro de una oficina cuadrada."]
			]],
			["alarm", "ALARMA SILENCIOSA", [131, 43, 55, 52], [
				["NARRACIÓN", "La alarma destella más rápido que un latido, pero no suena. Su etiqueta de inspección dice: EL SILENCIO INDICA CONSENTIMIENTO DEL EMPLEADO."],
				["JUNE", "El silencio significa que desconectaron el altavoz. La ausencia significa que falta alguien. Un campo en blanco significa que alguien borró la respuesta. Habéis construido una empresa con traducciones erróneas deliberadas."],
				["AUDITOR", "Una objeción no es un estado de nómina."],
				["JUNE", "Entonces vuestra nómina no es lo bastante grande para lo que le está pasando."],
				["NARRACIÓN", "La alarma emite una nota clara. Al otro lado de la oficina, todos los teléfonos de las mesas empiezan a sonar."]
			]],
			["steps", "ESCALONES QUE SE REPITEN", [203, 71, 85, 89], [
				["NARRACIÓN", "Los escalones se repiten en grupos de trece. Contar hacia atrás devuelve a June al mismo rellano. Decir nombres acerca la puerta; recitar números de empleado la aleja."],
				["JUNE", "Anika Bose. Tom Reyes. Leanne Wu. Devon Clarke. Halima Noor. No conozco vuestras historias, pero sé que al sistema le convenía hacerme creer que solo existía Mara."],
				["NARRACIÓN", "Delante de June aparecen huellas azules. Detrás la siguen huellas rojas. Ninguna es de sus zapatos. En el último escalón se superponen y se convierten en marcas corrientes de lluvia."],
				["MARA", "Hasta ahí es suficiente. Lo que queda no es una huida. Es la respuesta que llevas al despacho de Rusk."]
			]],
			["gate", "PUERTA DEL GERENTE", [113, 117, 82, 44], [
				["NARRACIÓN", "La puerta tiene dos lectores: TESTIGO y GERENCIA. Las pruebas de June abren uno. La ruta que eligió abre el otro. La cerradura espera a ver qué identidad presenta."],
				["CONDITIONAL", "GATE_RESULT"],
				["JUNE", "Ninguna ruta es pura. La escalera necesitó una tarjeta. El ascensor contenía efectos personales. La diferencia está en lo que yo digo que esas cosas me autorizan a hacer."],
				["AUDITOR", "Autorización reconocida. Interpretación moral descartada."],
				["JUNE", "Quédatela. Yo traigo mi propia interpretación."]
			]]
		],
		"transition": [
			["NARRACIÓN", "La puerta se abre a moqueta y a una falsa luz de sol. El olor a colonia de cedro de Rusk le sobrevive. Un contrato espera bajo un bolígrafo encadenado a la mesa."],
			["MARA", "Elijas lo que elijas, elige una historia entera. Las verdades a medias son la forma en que mantiene vivo el lunes."]
		]
	},
	{
		"id": "manager", "chapter": "7 / 7", "place": "DESPACHO DEL GERENTE", "clock": "12:02 AM",
		"objective": "Termina el turno: rechaza las horas heredadas o acepta la silla.",
		"opening": [
			["NARRACIÓN", "El despacho de Rusk es un decorado perfecto de día a medianoche: sol pintado en las ventanas, plantas de plástico, fotos familiares con todos los analistas temporales. La placa de la mesa espera en blanco."],
			["NARRACIÓN", "El Auditor está detrás de la silla: una columna de píxeles color traje cruzada por un escáner rojo. No tiene cara porque la empresa nunca la necesitó."],
			["AUDITOR", "Un puesto. Un empleado activo. Una ausencia. Cuadre el registro. La renuncia transfiere la responsabilidad hacia atrás. La sucesión la transfiere hacia delante."],
			["JUNE", "Y decir la verdad transfiere la responsabilidad a quienes diseñaron esto."]
		],
		"hotspots": [
			["outbox", "LA BANDEJA DE SALIDA DE RUSK", [28, 106, 78, 51], [
				["NARRACIÓN", "La bandeja contiene cuarenta y un formularios de renuncia y un hueco vacío. Todos alegan abandono voluntario exactamente a medianoche. Las firmas empiezan distintas y luego convergen en la letra de June."],
				["JUNE", "Esos formularios no los escribieron cuarenta y una personas. El sistema entrenó una sola firma con todas ellas y luego imprimió el consentimiento que cada corrección necesitaba."],
				["AUDITOR", "Una firma autenticada prevalece sobre una memoria poco fiable."],
				["JUNE", "Una firma montada con muestras robadas autentica el robo."],
				["NARRACIÓN", "El hueco vacío se rotula solo: JUNE PARK. El formulario ya firmado del bolsillo de June tira hacia él como un imán."]
			]],
			["photos", "FOTOS DE FAMILIA", [122, 45, 75, 69], [
				["NARRACIÓN", "Cada foto muestra a Rusk con un analista distinto y la misma tarta de cumpleaños. En la más reciente, June sostiene el cuchillo. Las velas forman 168."],
				["CONDITIONAL", "PHOTO_ROUTE"],
				["MARA", "Guardaba recuerdos mientras le decía a Nóminas que éramos registros duplicados. Las fotos recuerdan el apego. Los cheques recuerdan el beneficio. Cualquiera de las dos puede desenmascararlo si rechazas su marco."],
				["JUNE", "O cualquiera de las dos puede convertirse en la razón con la que me diga que quedarme su puesto es justicia. Esa es la trampa después de la trampa: confundir tener pruebas con tener permiso para controlar a la siguiente persona."]
			]],
			["contract", "EL CONTRATO DE MEDIANOCHE", [203, 88, 91, 67], [
				["NARRACIÓN", "El contrato ofrece puesto fijo de gerente, seguro médico y la responsabilidad de todas las horas sin resolver. Cláusula final: EL GERENTE PERMANECE HASTA QUE UN REEMPLAZO CUALIFICADO ACEPTE ENTRAR."],
				["AUDITOR", "La sucesión ofrece seguridad, compensación y autoridad para mejorar los procedimientos futuros. La negativa ofrece incertidumbre, riesgo reputacional y ninguna salida garantizada."],
				["JUNE", "Has aprendido el lenguaje de los beneficios. Pero sigues queriendo decir que otra persona entra en el bucle para que yo pueda salir."],
				["NARRACIÓN", "El campo del salario es igual a la suma exacta de cuarenta y dos nóminas retenidas. El bolígrafo está cargado con tinta roja de corrección."],
				["MARA", "Puedes firmar y liberar a una persona. Puedes negarte e intentar liberar el registro. Ninguna promesa es segura. Solo una hace que el siguiente trabajador pague por esta noche."]
			]],
			["window", "VENTANA PINTADA", [101, 125, 87, 37], [
				["NARRACIÓN", "Tras la luz de día pintada está la oscuridad real y lluviosa. Muy abajo, la persiana del vestíbulo está medio abierta. Mara espera al otro lado del cristal, dibujada con luz azul de monitor."],
				["CONDITIONAL", "WINDOW_ELI"],
				["JUNE", "El exterior sigue ahí. El lunes no es una ley cósmica. Es una puerta cerrada, un registro falso y gente con motivos para mantener ambas cosas cerradas."],
				["AUDITOR", "Las condiciones externas no pueden verificarse desde la planta activa."],
				["JUNE", "Entonces las verificaré desde fuera."]
			]]
		],
		"choice": {
			"id": "contract", "prompt": "¿Qué historia completará June?",
			"a": ["RENUNCIAR — Rechazar todas las horas heredadas", "RESIGN"],
			"b": ["FIRMAR — Aceptar Operaciones Nocturnas", "SIGN"]
		},
		"after": {
			"RESIGN": [
				["JUNE", "Rechazo la premisa de que la ausencia transfiere deuda. Rechazo esta renuncia falsificada. Rechazo cada corrección que hizo pasar trabajo robado por una celda vacía."],
				["NARRACIÓN", "June rompe por la mitad su formulario firmado y escribe los cuarenta y dos nombres sobre el contrato. Las letras azules atraviesan la tinta roja."],
				["AUDITOR", "Múltiples identidades activas superan la capacidad del puesto. Retraso en el procesamiento."],
				["MARA", "Un retraso basta, si has traído el registro completo."]
			],
			"SIGN": [
				["JUNE", "Acepto Operaciones Nocturnas y la responsabilidad del cierre."],
				["NARRACIÓN", "El bolígrafo se desliza con facilidad. La tarjeta de Rusk, o la tarjeta permanente de June, late en señal de aprobación. La corbata de gerente del reflejo se vuelve tela real alrededor de su cuello."],
				["AUDITOR", "Supervisora Park reconocida. La ausencia anterior puede ser liberada. Materiales de incorporación preparados."],
				["MARA", "Entonces recuerda que fue una elección, aunque edite tus motivos."]
			]
		}
	}
]

const ENDINGS := {
	"CLOCK_OUT": [
		["SISTEMA", "REGISTRO COMPLETO ACEPTADO. CUARENTA Y DOS TESTIGOS SIMULTÁNEOS. CAPACIDAD DEL AUDITOR SUPERADA."],
		["NARRACIÓN", "June mete el libro original y la lista de reemplazos en el fax de Rusk. Mara lo envía a todas las bandejas de nóminas y a la inspección de trabajo. Cuarenta y dos monitores despiertan y cada uno restaura un nombre en azul espectral."],
		["ELI", "La puerta de la escalera está abierta. Puedo sujetarla, pero no creo que siga intentando cerrarse."],
		["NARRACIÓN", "La línea roja del Auditor se rompe en luz inofensiva de fotocopiadora. Su silueta de traje se separa en un perchero, un escáner apagado y la sombra de una silla vacía."],
		["MARA", "Cuarenta y dos nombres. Léelos. No porque la máquina los necesite. Porque los necesitamos nosotros."],
		["JUNE", "Mara Vale. Eli Song. Anika Bose. Tom Reyes. Leanne Wu. Halima Noor. Los demás nombres se desplazan a su lado, ya sin esconderse tras números de empleado."],
		["NARRACIÓN", "June cruza la oficina abierta. Las sillas se giran hacia las ventanas lluviosas en lugar de hacia ella. Las bandejas de las impresoras se llenan de nóminas, formularios de reclamación y copias que se niegan a corregirse."],
		["NARRACIÓN", "En el vestíbulo, el libro de visitas cambia JUNE PARK de DENTRO a FUERA el lunes a las 00:03. La línea de Eli recibe FUERA. La de Mara recibe otra palabra: PRESENTE."],
		["MARA", "Todavía no sé qué significa presente para mí. Basta con que sea otra persona la que tenga que responder esa pregunta."],
		["NARRACIÓN", "Fuera, el amanecer es de un gris corriente. Meridian abre con cuarenta y dos reclamaciones de salarios atrasados y ningún supervisor dispuesto a explicar la Planta 13. June nunca vuelve a aceptar un turno de noche flexible."],
		["FIN", "FICHAR LA SALIDA\nEL REGISTRO RECUERDA\nLunes · 12:03 AM"]
	],
	"NEW_MANAGER": [
		["SISTEMA", "SUCESIÓN COMPLETADA. VARIANZA PENDIENTE TRANSFERIDA. BIENVENIDA, SUPERVISORA PARK."],
		["NARRACIÓN", "El sol pintado se enciende de golpe. La tarjeta de June se imprime con un cargo nuevo. El libro corregido se convierte en confeti blanco que cae hacia arriba, hacia las rejillas del techo."],
		["NARRACIÓN", "Se abre el ascensor. Sale Mara, restaurada por el intercambio de identidad que June aceptó. Se detiene en el umbral, pero no mira atrás."],
		["MARA", "Me has liberado con la misma corrección que te ha atrapado a ti. Eso no la convierte en clemencia. Solo completa la aritmética."],
		["NARRACIÓN", "La tarjeta en blanco de Eli resbala del teléfono de Cumplimiento y cae en la bandeja de Rusk. June intenta recordar si alguna vez le vio la cara. El registro responde con un no rotundo."],
		["AUDITOR", "Primera tarea de gerencia: incorporar al reemplazo activo. Use el lenguaje aprobado. Destaque la flexibilidad y el ascenso."],
		["NARRACIÓN", "El Auditor le ajusta a June la corbata roja en el reflejo de la ventana y se disuelve en su sombra. Suben las luces cálidas de la oficina. Todos los relojes siguen en las 11:59."],
		["NARRACIÓN", "Abajo, una nueva analista temporal entra de la lluvia sacudiendo el paraguas. Firma el libro de visitas sin fijarse en cuarenta y dos líneas borradas."],
		["JUNE", "Vete a casa. Por favor. No cojas el ascensor."],
		["NARRACIÓN", "Eso es lo que June intenta decir. El altavoz de recepción usa su voz para otras palabras."],
		["JUNE / RECEPCIÓN", "Bienvenida a Meridian Ledger. Las filas rojas no son personas. Son varianza. Tu cierre flexible debería llevarte cinco minutos."],
		["FIN", "LA NUEVA GERENTE\nEL LUNES NECESITA UNA SUPERVISORA\nHora actual · 11:59 PM"]
	],
	"MONDAY_FOREVER": [
		["AUDITOR", "REGISTRO PARCIAL. LA RUTA Y LA DECLARACIÓN SE CONTRADICEN. Medio registro se redondea hacia abajo."],
		["NARRACIÓN", "Las pruebas de June contradicen su contrato. El libro recuerda a las personas mientras su firma acepta el reemplazo, o la credencial de gerente promete autoridad mientras su renuncia niega su precio."],
		["JUNE", "No. Déjame reformularlo. Dame un minuto."],
		["AUDITOR", "Un minuto concedido."],
		["NARRACIÓN", "June llega al vestíbulo a las 00:01. La persiana sube, pero no da a la calle, sino a la misma oficina el domingo a las 11:48 PM. Fuera, la lluvia sube."],
		["CONDITIONAL", "LOOP_COMPANION"],
		["NARRACIÓN", "El libro de visitas añade otro JUNE PARK — DENTRO. La paleta de la oficina pierde un color. El registro del caso conserva cada elección: prueba de que el bucle es una consecuencia, no clemencia ni un reinicio."],
		["PA", "Analista temporal June Park, preséntese en su cubículo asignado. Queda un último ticket antes del cierre."],
		["NARRACIÓN", "En su mesa se abre el ticket 1313. El empleado 013 ahora dice JUNE PARK. Mara Vale es la analista activa asignada para corregirla."],
		["MARA", "Tengo la sensación de que ya hemos hecho esto."],
		["JUNE", "Sí. La próxima vez elegiré una historia entera."],
		["NARRACIÓN", "El reloj cambia a las 11:59 y se niega a llevar la promesa más lejos."],
		["FIN", "LUNES PARA SIEMPRE\nTURNO ACTUAL · 169:00:00\nVARIANZA PENDIENTE"]
	]
}


static func conditional(key: String, flags: Dictionary) -> Array:
	match key:
		"ELI_FOLDER":
			return ["NARRACIÓN", "La carpeta de Eli sigue marcada como ACTIVA, aunque sus páginas se desvanecen por los bordes. El pase de visitante de June le ha comprado tiempo, no seguridad."] if flags.eli_stance == "TRUST" else ["NARRACIÓN", "La carpeta de Eli está vacía salvo por el contorno húmedo de una tarjeta. Cumplimiento ha convertido su testimonio en un informe de ausencia."]
		"MARA_ELI":
			return ["MARA", "Eli llevó mi advertencia a través de seis bucles. La confianza no lo puso a salvo, pero mantuvo a otro testigo en el registro."] if flags.eli_stance == "TRUST" else ["MARA", "Cumplimiento usa ahora la respiración de Eli en el teléfono. Denunciarlo enseñó al sistema exactamente qué miedo te movería."]
		"ROUTE_PHONE":
			return ["ELI / TELÉFONO", "He llegado al control de la escalera. Puedo sujetar una puerta durante noventa latidos. Me niego a seguir llamándolos segundos."] if flags.eli_stance == "TRUST" else ["ELI / TELÉFONO", "Varianza es una palabra solitaria. Tú la hiciste mía. Cumplimiento dice que el ascensor es más seguro para el personal en lista."]
		"STAIR_HELP":
			return ["ELI", "La puerta está abierta. Sigue nombrándolos; el rellano no puede reiniciarse mientras dos personas recuerden la misma secuencia."] if flags.eli_stance == "TRUST" else ["NARRACIÓN", "Nadie contesta el teléfono de la escalera. June puentea los contactos de la alarma con la grapa metálica de su renuncia falsificada."]
		"COAT_EVIDENCE":
			return ["NARRACIÓN", "Como June subió por la escalera, la lista de reemplazos grabada confirma quién es el dueño de cada abrigo."] if flags.escape_route == "STAIRS" else ["NARRACIÓN", "La tarjeta de Rusk abre una etiqueta de mantenimiento: cada abrigo estaba inventariado como material de identidad reutilizable."]
		"GATE_RESULT":
			return ["SISTEMA", "RUTA DE TESTIGO ACEPTADA. Cronología de reemplazos adjunta."] if flags.escape_route == "STAIRS" else ["SISTEMA", "RUTA DE GERENCIA ACEPTADA. Autorización maestra adjunta."]
		"PHOTO_ROUTE":
			return ["NARRACIÓN", "La lista de la escalera identifica a todas las personas de las fotos, incluidas las seis a las que Rusk recortó la cara."] if flags.escape_route == "STAIRS" else ["NARRACIÓN", "La tarjeta de Rusk abre los marcos. Detrás hay cheques de indemnización que suman los salarios desaparecidos."]
		"WINDOW_ELI":
			return ["NARRACIÓN", "Eli espera junto a Mara bajo el toldo, con una mano sujetando la puerta de la escalera."] if flags.eli_stance == "TRUST" else ["NARRACIÓN", "Junto a Mara, en la acera, solo está la tarjeta en blanco de Eli. La lluvia atraviesa su fotografía."]
		"LOOP_COMPANION":
			if flags.eli_stance == "TRUST":
				return ["ELI", "Salvaste medio registro. El Auditor redondea las mitades hacia abajo. Recuerdo lo suficiente para pedirte que tus elecciones coincidan."]
			return ["MARA", "No puedes usar la ruta de Cumplimiento y llamar libertad al destino. Nos ha devuelto al último lugar donde tu historia estaba entera."]
	return ["NARRACIÓN", ""]
