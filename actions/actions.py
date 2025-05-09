# from dotenv import load_dotenv
import os
from rasa_sdk.events import SlotSet, ActiveLoop

# load_dotenv()

import asyncio
import sys

# Solución para evitar "RuntimeError: Event loop is closed" en Windows
if sys.platform.startswith("win"):
    asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
       
import mysql.connector
from rasa_sdk import Action
from rasa_sdk.events import SlotSet
from rasa_sdk.forms import FormValidationAction
from typing import Any, Dict, Text, List
from rasa_sdk import Tracker
from rasa_sdk.executor import CollectingDispatcher
from rasa_sdk.events import FollowupAction
import bcrypt


# Configurar la conexión con MySQL
def connect_db():
    return mysql.connector.connect(
        host=os.getenv("DB_HOST"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        database=os.getenv("DB_NAME"),
        port=int(os.getenv("DB_PORT"))
    )

class ValidateConsultarNotasForm(FormValidationAction):
    def name(self) -> str:
        return "validate_consultar_notas_form"
    
class SubmitConsultarNotas(Action):
    def name(self) -> str:
        return "submit_consultar_notas"

    def run(self, dispatcher, tracker, domain):
        # 1) Validar autenticación
        if not tracker.get_slot("autenticado"):
            dispatcher.utter_message(
                text="⚠️ Debes iniciar sesión como apoderado para acceder a esta información. "
                     "Escribe 'Soy apoderado' para comenzar."
            )
            return []

        # 2) Leer los slots
        nombre_slot   = (tracker.get_slot("nombre_alumno") or "").strip()
        apellido_slot = (tracker.get_slot("apellido_alumno") or "").strip()

        # 3) Si apellido_slot tiene >2 tokens, el primero es en realidad
        #    el segundo nombre del alumno, así que lo movemos a nombre_slot.
        ap_tokens = apellido_slot.split()
        if len(ap_tokens) > 2:
            # Extraigo el primer token como segundo nombre
            segundo_nombre = ap_tokens.pop(0)
            nombre_slot = (nombre_slot + " " + segundo_nombre).strip()
            apellido_slot = " ".join(ap_tokens)

        # Debug: comprueba cómo quedó cada slot
        print(f"🔍 nombre_slot final:   '{nombre_slot}'")
        print(f"🔍 apellido_slot final: '{apellido_slot}'")

        # 4) Construir filtros:
        #    - Nombre: usamos todo nombre_slot (uno o dos nombres)
        filtro_nombre = nombre_slot

        #    - Apellidos: últimos dos tokens si hay >=2, o el único si hay uno
        ap_tokens = apellido_slot.split()
        if len(ap_tokens) >= 2:
            filtro_apellidos = f"{ap_tokens[-2]} {ap_tokens[-1]}"
        elif len(ap_tokens) == 1:
            filtro_apellidos = ap_tokens[0]
        else:
            filtro_apellidos = ""

        # Debug final antes de consulta
        print(f"🔍 filtro_nombre:     '{filtro_nombre}'")
        print(f"🔍 filtro_apellidos: '{filtro_apellidos}'")

        try:
            db = connect_db()
            cursor = db.cursor()

            query = """
                SELECT 
                    c.nombre_curso, 
                    e.nombre_evaluacion, 
                    ce.fecha_evaluacion,
                    n.nota
                FROM apoderado ap
                JOIN persona pa              ON ap.id_persona       = pa.id_persona
                JOIN apoderado_alumno aa     ON ap.id_apoderado     = aa.id_apoderado
                JOIN alumno a                ON aa.id_alumno        = a.id_alumno
                JOIN persona p               ON a.id_persona        = p.id_persona
                JOIN nota n                  ON a.id_alumno         = n.id_alumno
                JOIN curso_evaluacion ce     ON n.id_curso_evaluacion = ce.id_curso_evaluacion
                JOIN curso c                 ON ce.id_curso         = c.id_curso
                JOIN evaluacion e            ON ce.id_evaluacion    = e.id_evaluacion
                WHERE 
                  p.nombre_persona   LIKE %s
                  AND p.apellidos_personas LIKE %s
            """

            params = (
                f"%{filtro_nombre}%",
                f"%{filtro_apellidos}%"
            )
            cursor.execute(query, params)
            resultados = cursor.fetchall()

            if resultados:
                mensaje = f"📝 Notas de {filtro_nombre} {filtro_apellidos}:\n"
                for curso, evaluacion, fecha, nota in resultados:
                    mensaje += f"- {curso} ({evaluacion}, {fecha}): {nota}\n"
            else:
                mensaje = f"⚠️ No se encontraron notas para {filtro_nombre} {filtro_apellidos}."

            cursor.close()
            db.close()
            dispatcher.utter_message(text=mensaje)

        except Exception as e:
            dispatcher.utter_message(text="❌ Ocurrió un error al consultar las notas.")
            print(f"Error en submit_consultar_notas: {e}")

        mostrar_menu_personalizado(dispatcher, tracker)

        return [
            SlotSet("contexto_actual", "menu_principal"),
            SlotSet("nombre_completo_alumno", None)
        ]





class ConsultarAsistencia(Action):
    def name(self):
        return "action_consultar_asistencia"

    def run(self, dispatcher, tracker, domain):
        if not tracker.get_slot("autenticado"):
            dispatcher.utter_message(text="⚠️ Debes iniciar sesión como apoderado para acceder a esta información. Escribe 'Soy apoderado' para comenzar.")
            return []
        nombre_alumno = tracker.get_slot("nombre_alumno") or ""
        apellido_slot = tracker.get_slot("apellido_alumno") or ""

        if not nombre_alumno or not apellido_slot:
            dispatcher.utter_message(text="Faltan datos para realizar la consulta.")
            return []

        tokens = apellido_slot.strip().split()
        if len(tokens) >= 2:
            filtro_apellidos = f"{tokens[-2]} {tokens[-1]}"
        else:
            filtro_apellidos = tokens[0]
        try:
            db = connect_db()
            cursor = db.cursor()

            query = """
                SELECT 
                    c.nombre_curso, 
                    a.fecha_asistencia, 
                    a.estado_asistencia 
                FROM 
                    apoderado ap
                JOIN persona pa ON ap.id_persona = pa.id_persona
                JOIN apoderado_alumno aa ON ap.id_apoderado = aa.id_apoderado
                JOIN alumno al ON aa.id_alumno = al.id_alumno
                JOIN persona pe ON al.id_persona = pe.id_persona
                JOIN alumno_curso ac ON al.id_alumno = ac.id_alumno
                JOIN curso c ON ac.id_curso = c.id_curso
                JOIN asistencia a ON ac.id_alumno_curso = a.id_alumno_curso 
                WHERE pe.nombre_persona LIKE %s
                  AND pe.apellidos_personas LIKE %s
                ORDER BY a.fecha_asistencia DESC
                LIMIT 5;
            """
            # justo antes de cursor.execute(query, …)
            print(f"🔍 Slots -> nombre_alumno: '{nombre_alumno}', apellido_alumno: '{filtro_apellidos}'")
            print("🔍 Query completa:", query % (f"'%{nombre_alumno}%'", f"'%{filtro_apellidos}%'" ))

            cursor.execute(query, (f"%{nombre_alumno}%", f"%{filtro_apellidos}%"))
            resultados = cursor.fetchall()

            if resultados:
                mensaje = f"📋 Últimas asistencias de {nombre_alumno} {filtro_apellidos}:\n"
                for curso, fecha, estado in resultados:
                    mensaje += f"- {fecha} | {curso}: {estado}\n"
            else:
                mensaje = f"⚠️ No se encontraron registros recientes de asistencia para {nombre_alumno} {filtro_apellidos}."

            cursor.close()
            db.close()
            dispatcher.utter_message(text=mensaje)

        except Exception as e:
            dispatcher.utter_message(text="Ocurrió un error al consultar las asistencias.")
            print(f"❌ Error en action_consultar_asistencia: {e}")

        mostrar_menu_personalizado(dispatcher, tracker)
       
        return [
            SlotSet("contexto_actual", "menu_principal"),
            SlotSet("nombre_completo_alumno", None)
        ]


class ConsultarEventos(Action):
    def name(self):
        return "action_consultar_eventos"

    def run(self, dispatcher, tracker, domain):
        if not tracker.get_slot("autenticado"):
            dispatcher.utter_message(text="⚠️ Debes iniciar sesión como apoderado para acceder a esta información. Escribe 'Soy apoderado' para comenzar.")
            return []
        try:
            db = connect_db()
            cursor = db.cursor()

            query = """
                SELECT titulo, descripcion, fecha_publicacion
                FROM comunicado
                WHERE estado_comunicado = 1
                ORDER BY fecha_publicacion ASC
                LIMIT 5;
            """
            cursor.execute(query)
            resultados = cursor.fetchall()

            if resultados:
                mensaje = "📅 Próximos comunicados importantes:\n\n"
                for titulo, descripcion, fecha in resultados:
                    mensaje += f"📝 {titulo}: \n{descripcion}\n\n"
            else:
                mensaje = "No hay comunicados próximos por el momento."

            cursor.close()
            db.close()
            dispatcher.utter_message(text=mensaje)

        except Exception as e:
            dispatcher.utter_message(text="Ocurrió un error al consultar los comunicados.")
            print(f"❌ Error en action_consultar_eventos: {e}")

        mostrar_menu_personalizado(dispatcher, tracker)

        return [
            SlotSet("contexto_actual", "menu_principal"),
            SlotSet("nombre_completo_alumno", None)
        ]



class ActionGuardarDatosApoderado(Action):
    def name(self) -> str:
        return "action_guardar_datos_apoderado"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:

        if tracker.get_slot("autenticado"):
            # Ya está autenticado, no volver a mostrar mensaje
            return []

        nombre = tracker.get_slot("nombre_apoderado")
        apellido = tracker.get_slot("apellido_apoderado")
        dni = tracker.get_slot("dni_apoderado")

        print(f"✅ Apoderado autenticado: {nombre} {apellido} | DNI: {dni}")
        dispatcher.utter_message(response="utter_confirm_autenticacion")

        return [
            SlotSet("alumno_seleccionado", None),
            SlotSet("alumnos_disponibles", None),
            SlotSet("filtro_asistencia", None),
            SlotSet("nombre_apoderado", nombre),
            SlotSet("apellido_apoderado", apellido),
            SlotSet("dni_apoderado", dni),
            SlotSet("autenticado", True),
            SlotSet("contexto_actual", None)
        ]

    
class ValidateFormAutenticacion(FormValidationAction):
    def name(self) -> str:
        return "validate_form_autenticacion"

    def validate_nombre_apoderado(self, slot_value, dispatcher, tracker, domain):
        return {"nombre_apoderado": slot_value}

    def validate_apellido_apoderado(self, slot_value, dispatcher, tracker, domain):
        return {"apellido_apoderado": slot_value}

    def validate_dni_apoderado(self, slot_value, dispatcher, tracker, domain):
        return {"dni_apoderado": slot_value}

    def validate_clave_acceso(self, slot_value, dispatcher, tracker, domain):
        clave_ingresada = slot_value
        nombre = tracker.get_slot("nombre_apoderado")
        apellido = tracker.get_slot("apellido_apoderado")
        dni = tracker.get_slot("dni_apoderado")

        try:
            db = connect_db()
            cursor = db.cursor()

            query = """
                SELECT password_persona
                FROM persona
                WHERE nombre_persona LIKE %s
                  AND apellidos_personas LIKE %s
                  AND dni_persona = %s
                  AND estado_persona = 1
                LIMIT 1
            """
            cursor.execute(query, (f"%{nombre}%", f"%{apellido}%", dni))
            resultado = cursor.fetchone()

            if resultado:
                hash_guardado = resultado[0]
                if bcrypt.checkpw(clave_ingresada.encode(), hash_guardado.encode()):
                    return {"clave_acceso": slot_value}

            dispatcher.utter_message(text="❌ La clave o los datos ingresados no son válidos. Intenta nuevamente.")
            return {
                "nombre_apoderado": None,
                "apellido_apoderado": None,
                "dni_apoderado": None,
                "clave_acceso": None,
                "requested_slot": "nombre_apoderado"
            }

        except Exception as e:
            dispatcher.utter_message(text="⚠️ Ocurrió un error al validar tus datos.")
            print(f"❌ Error en validate_form_autenticacion: {e}")
            return {
                "nombre_apoderado": None,
                "apellido_apoderado": None,
                "dni_apoderado": None,
                "clave_acceso": None,
                "requested_slot": "nombre_apoderado"
            }


class ActionMostrarAlumnos(Action):
    def name(self) -> str:
        return "action_mostrar_alumnos"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:

        nombre = tracker.get_slot("nombre_apoderado")
        apellido = tracker.get_slot("apellido_apoderado")
        dni = tracker.get_slot("dni_apoderado")

        try:
            db = connect_db()
            cursor = db.cursor()

            query = """
                    SELECT a.id_alumno, p.nombre_persona, p.apellidos_personas
                    FROM apoderado ap
                    JOIN persona pa ON ap.id_persona = pa.id_persona
                    JOIN apoderado_alumno aa ON ap.id_apoderado = aa.id_apoderado
                    JOIN alumno a ON aa.id_alumno = a.id_alumno
                    JOIN persona p ON a.id_persona = p.id_persona
                    WHERE pa.nombre_persona LIKE %s
                    AND pa.apellidos_personas LIKE %s
                    AND pa.dni_persona = %s
                """
            cursor.execute(query, (f"%{nombre}%", f"%{apellido}%", dni))
            alumnos = cursor.fetchall()

            if not alumnos:
                dispatcher.utter_message(text="⚠️ No se encontraron alumnos asociados a este apoderado.")
                return []

            # Guarda la lista para usarla más adelante
            lista_alumnos = [{"id": str(a[0]), "nombre": f"{a[1]} {a[2]}"} for a in alumnos]
            
            if len(lista_alumnos) == 1:
                alumno = lista_alumnos[0]

                return [
                    SlotSet("alumno_seleccionado", alumno["id"]),
                    SlotSet("nombre_alumno", alumno["nombre"].split()[0]),
                    SlotSet("apellido_alumno", " ".join(alumno["nombre"].split()[1:])),
                    SlotSet("contexto_actual", "menu_principal"),
                    SlotSet("nombre_completo_alumno", alumno["nombre"]),
                    FollowupAction("action_mostrar_menu")
                ]
                                            
            nombres_texto = "\n".join([f"{i+1}. {a['nombre']}" for i, a in enumerate(lista_alumnos)])

            dispatcher.utter_message(
                template="utter_pedir_seleccion_alumno",
                alumnos=nombres_texto
            )

            return [
                SlotSet("alumnos_disponibles", lista_alumnos),
                SlotSet("contexto_actual", "seleccion_alumno")
            ]


        except Exception as e:
            print(f"❌ Error en action_mostrar_alumnos: {e}")
            dispatcher.utter_message(text="Ocurrió un error al obtener los alumnos.")
            return []

class ActionCambiarAlumno(Action):
    def name(self) -> str:
        return "action_cambiar_alumno"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:

        alumnos = tracker.get_slot("alumnos_disponibles")

        if not alumnos:
            dispatcher.utter_message(text="⚠️ No hay alumnos disponibles para seleccionar.")
            return []

        nombres_texto = "\n".join([f"{idx + 1}. {a['nombre']}" for idx, a in enumerate(alumnos)])

        dispatcher.utter_message(
            text=f"Estos son tus estudiantes registrados:\n{nombres_texto}\n\nPuedes responder con el número. Ejemplo: '1'."
        )


        return [
        SlotSet("alumno_seleccionado", None),
        SlotSet("contexto_actual", "seleccion_alumno")
        ]


class ActionSeleccionarNumero(Action):
    def name(self) -> str:
        return "action_seleccionar_numero"

    def run(self, dispatcher: CollectingDispatcher, tracker: Tracker, domain: Dict) -> List[Dict]:
        mensaje = tracker.latest_message.get("text")
        numero = None

        for palabra in mensaje.split():
            if palabra.isdigit():
                numero = int(palabra)
                break

        contexto = tracker.get_slot("contexto_actual")
        alumnos = tracker.get_slot("alumnos_disponibles")

        if numero is None:
            dispatcher.utter_message(text="No entendí el número. Intenta de nuevo.")
            return []

        # ✅ Selección de alumno
        if contexto == "seleccion_alumno":
            if alumnos and 1 <= numero <= len(alumnos):
                alumno = alumnos[numero - 1]

                dispatcher.utter_message(text=f"✅ Alumno actualizado: {alumno['nombre']}.")
                if alumnos and len(alumnos) > 1:
                    texto = (
                        "\n"
                        "📋 ¿Qué deseas hacer ahora?\n"
                        "☑️  Consultar notas\n"
                        "☑️  Consultar asistencias\n"
                        "☑️  Consultar eventos\n"
                        "☑️  Ver observaciones del docente\n"
                        "☑️  Ver horario de clases\n"
                        "☑️  Ver información del docente\n"
                        "☑️  Ver grado actual\n"
                        "☑️  Cambiar de estudiante\n"
                        "Puedes escribirme directamente lo que deseas hacer."
                    )
                else:
                    texto = (
                        "\n"
                        "📋¿Qué deseas hacer ahora?\n"
                        "☑️  Consultar notas\n"
                        "☑️  Consultar asistencias\n"
                        "☑️  Consultar eventos\n"
                        "☑️  Ver observaciones del docente\n"
                        "☑️  Ver horario de clases\n"
                        "☑️  Ver información del docente\n"
                        "☑️  Ver grado actual\n"
                        "Puedes escribirme directamente lo que deseas hacer."
                    )

                dispatcher.utter_message(text=texto)   

                return [
                    SlotSet("alumno_seleccionado", alumno["id"]),
                    SlotSet("nombre_alumno", alumno["nombre"].split()[0]),
                    SlotSet("apellido_alumno", " ".join(alumno["nombre"].split()[1:])),
                    SlotSet("contexto_actual", "menu_principal"),
                    SlotSet("nombre_completo_alumno", None)
                ]
            else:
                dispatcher.utter_message(response="utter_numero_fuera_de_rango")
                return []

        dispatcher.utter_message(text="Ese número no corresponde a ninguna opción.")
        return []


class ActionMostrarMenu(Action):
    def name(self) -> str:
        return "action_mostrar_menu"

    def run(self, dispatcher: CollectingDispatcher, tracker: Tracker, domain: Dict) -> List[Dict]:
        alumnos = tracker.get_slot("alumnos_disponibles")
        nombre_completo = tracker.get_slot("nombre_completo_alumno")

        if nombre_completo:
            dispatcher.utter_message(text=f"✅ Alumno actualizado: {nombre_completo}.")

        if alumnos and len(alumnos) > 1:
            texto = (
                "\n"
                "📋¿Qué deseas hacer ahora?\n"
                "☑️  Consultar notas\n"
                "☑️  Consultar asistencias\n"
                "☑️  Consultar eventos\n"
                "☑️  Ver observaciones del docente\n"
                "☑️  Ver horario de clases\n"
                "☑️  Ver información del docente\n"
                "☑️  Ver grado actual\n"
                "☑️  Cambiar de estudiante\n"
                "Puedes escribirme directamente lo que deseas hacer."
            )
        else:
            texto = (
                "\n"
                "📋¿Qué deseas hacer ahora?\n"
                "☑️  Consultar notas\n"
                "☑️  Consultar asistencias\n"
                "☑️  Consultar eventos\n"
                "☑️  Ver observaciones del docente\n"
                "☑️  Ver horario de clases\n"
                "☑️  Ver información del docente\n"
                "☑️  Ver grado actual\n"
                "Puedes escribirme directamente lo que deseas hacer."
            )

        dispatcher.utter_message(text=texto)

        return [
            SlotSet("contexto_actual", "menu_principal"),
            SlotSet("nombre_completo_alumno", None)
        ]


class ActionActivarFiltroAsistencia(Action):
    def name(self) -> str:
        return "action_activar_filtro_asistencia"

    def run(self, dispatcher, tracker, domain):
        dispatcher.utter_message(text="""
                📌 ¿Qué tipo de asistencia deseas consultar?
                Puedes escribirme por ejemplo:
                ✔️  Ùltimas asistencias
                ✔️  Solo faltas
                ✔️  Resumen mensual
                ✔️  Historial completo
                O escribe 'menú' para volver al menú principal.
                """)
        return [SlotSet("contexto_actual", "asistencia")]



class ActionConsultarUltimasAsistencias(Action):
    def name(self) -> str:
        return "action_consultar_ultimas_asistencias"

    def run(self, dispatcher, tracker, domain):
        if not tracker.get_slot("autenticado"):
            dispatcher.utter_message(text="⚠️ Debes iniciar sesión como apoderado para acceder a esta información. Escribe 'Soy apoderado' para comenzar.")
            return []
        return consultar_asistencias(dispatcher, tracker, tipo="ultimas")


class ActionConsultarSoloFaltas(Action):
    def name(self) -> str:
        return "action_consultar_solo_faltas"

    def run(self, dispatcher, tracker, domain):
        if not tracker.get_slot("autenticado"):
            dispatcher.utter_message(text="⚠️ Debes iniciar sesión como apoderado para acceder a esta información. Escribe 'Soy apoderado' para comenzar.")
            return []
        return consultar_asistencias(dispatcher, tracker, tipo="faltas")


class ActionConsultarResumenAsistencia(Action):
    def name(self) -> str:
        return "action_consultar_resumen_asistencia"

    def run(self, dispatcher, tracker, domain):
        if not tracker.get_slot("autenticado"):
            dispatcher.utter_message(text="⚠️ Debes iniciar sesión como apoderado para acceder a esta información. Escribe 'Soy apoderado' para comenzar.")
            return []
        return consultar_asistencias(dispatcher, tracker, tipo="resumen")


class ActionConsultarHistorialAsistencia(Action):
    def name(self) -> str:
        return "action_consultar_historial_asistencia"

    def run(self, dispatcher, tracker, domain):
        if not tracker.get_slot("autenticado"):
            dispatcher.utter_message(text="⚠️ Debes iniciar sesión como apoderado para acceder a esta información. Escribe 'Soy apoderado' para comenzar.")
            return []
        return consultar_asistencias(dispatcher, tracker, tipo="historial")

def consultar_asistencias(dispatcher, tracker, tipo="ultimas"):
    # 1) Leer y limpiar slots
    nombre_slot   = (tracker.get_slot("nombre_alumno") or "").strip()
    apellido_slot = (tracker.get_slot("apellido_alumno") or "").strip()

    # Debug: mostrar valores crudos
    print(f"🔍 nombre_slot raw:   '{nombre_slot}'")
    print(f"🔍 apellido_slot raw: '{apellido_slot}'")

    # 2) Si apellido_slot tiene más de 2 tokens, mover el primero al nombre
    ap_tokens = apellido_slot.split()
    if len(ap_tokens) > 2:
        segundo_nombre = ap_tokens.pop(0)
        nombre_slot = f"{nombre_slot} {segundo_nombre}".strip()
        apellido_slot = " ".join(ap_tokens)

    # Debug: ver cómo quedó tras el ajuste
    print(f"🔍 nombre_slot ajustado:   '{nombre_slot}'")
    print(f"🔍 apellido_slot ajustado: '{apellido_slot}'")

    # 3) Construir filtros PARA CONSULTA
    #    Nombre: usamos todo lo que haya en nombre_slot
    filtro_nombre = nombre_slot

    #    Apellidos: últimos dos tokens o el único
    ap_tokens = apellido_slot.split()
    if len(ap_tokens) >= 2:
        filtro_apellidos = f"{ap_tokens[-2]} {ap_tokens[-1]}"
    elif len(ap_tokens) == 1:
        filtro_apellidos = ap_tokens[0]
    else:
        filtro_apellidos = ""

    # Debug: filtros finales
    print(f"🔍 filtro_nombre:     '{filtro_nombre}'")
    print(f"🔍 filtro_apellidos: '{filtro_apellidos}'")

    try:
        db = connect_db()
        cursor = db.cursor()

        if tipo == "resumen":
            query = """
                SELECT MONTH(a.fecha_asistencia), COUNT(*),
                       SUM(a.estado_asistencia = 'Presente'),
                       SUM(a.estado_asistencia = 'Ausente')
                FROM apoderado ap
                JOIN persona pa       ON ap.id_persona       = pa.id_persona
                JOIN apoderado_alumno aa ON ap.id_apoderado  = aa.id_apoderado
                JOIN alumno al        ON aa.id_alumno        = al.id_alumno
                JOIN persona pe       ON al.id_persona       = pe.id_persona
                JOIN alumno_curso ac  ON al.id_alumno        = ac.id_alumno
                JOIN asistencia a     ON ac.id_alumno_curso  = a.id_alumno_curso 
                WHERE pe.nombre_persona   LIKE %s
                  AND pe.apellidos_personas LIKE %s
                GROUP BY MONTH(a.fecha_asistencia)
            """
            params = (f"%{filtro_nombre}%", f"%{filtro_apellidos}%")

        else:
            query = """
                SELECT c.nombre_curso, a.fecha_asistencia, a.estado_asistencia
                FROM apoderado ap
                JOIN persona pa       ON ap.id_persona       = pa.id_persona
                JOIN apoderado_alumno aa ON ap.id_apoderado  = aa.id_apoderado
                JOIN alumno al        ON aa.id_alumno        = al.id_alumno
                JOIN persona pe       ON al.id_persona       = pe.id_persona
                JOIN alumno_curso ac  ON al.id_alumno        = ac.id_alumno
                JOIN curso c          ON ac.id_curso         = c.id_curso
                JOIN asistencia a     ON ac.id_alumno_curso  = a.id_alumno_curso 
                WHERE pe.nombre_persona   LIKE %s
                  AND pe.apellidos_personas LIKE %s
            """
            if tipo == "ultimas":
                query += " ORDER BY a.fecha_asistencia DESC LIMIT 15"
            elif tipo == "faltas":
                query += " AND a.estado_asistencia = 'Ausente'"
            elif tipo == "historial":
                query += " ORDER BY a.fecha_asistencia DESC"
            params = (f"%{filtro_nombre}%", f"%{filtro_apellidos}%")

        # Debug: consulta y parámetros
        print("🔍 Query:", query)
        print("🔍 Params:", params)

        cursor.execute(query, params)
        resultados = cursor.fetchall()
        cursor.close()
        db.close()

        if not resultados:
            dispatcher.utter_message(text="⚠️ No se encontraron registros de asistencia.")
            return [SlotSet("contexto_actual", "menu_principal")]

        if tipo == "resumen":
            mensaje = f"📊 Resumen mensual de asistencia de {filtro_nombre} {filtro_apellidos}:\n"
            for mes, total, pres, aus in resultados:
                mensaje += f"- Mes {mes}: {total} clases | {pres} presentes | {aus} ausentes\n"
        else:
            mensaje = f"🗓️ Asistencias de {filtro_nombre} {filtro_apellidos}:\n"
            for curso, fecha, estado in resultados:
                mensaje += f"- {fecha} | {curso}: {estado}\n"

        dispatcher.utter_message(text=mensaje)
        dispatcher.utter_message(text="""
📌 ¿Deseas consultar otro tipo de asistencia?
✔️ Últimas asistencias
✔️ Solo faltas
✔️ Resumen mensual
✔️ Historial completo
Escribe 'menú' para volver al menú principal.
        """)
        return [SlotSet("contexto_actual", "asistencia")]

    except Exception as e:
        print(f"❌ Error en consultar_asistencias: {e}")
        dispatcher.utter_message(text="❌ Ocurrió un error al consultar las asistencias.")
        return [SlotSet("contexto_actual", "menu_principal")]




class ActionPedirOpcionesAsistencia(Action):
    def name(self) -> str:
        return "action_pedir_opciones_asistencia"

    def run(self, dispatcher, tracker, domain):
        dispatcher.utter_message(text="""
            📌 ¿Qué tipo de asistencia deseas consultar?
                Puedes escribirme por ejemplo:
                ✔️  Últimas asistencias
                ✔️  Solo faltas
                ✔️  Resumen mensual
                ✔️  Historial completo
                    """)
        return []

class ActionConsultarObservaciones(Action):
    def name(self) -> str:
        return "action_consultar_observaciones"

    def run(self, dispatcher, tracker, domain):
        # 1) Validar autenticación
        if not tracker.get_slot("autenticado"):
            dispatcher.utter_message(
                text="⚠️ Debes iniciar sesión como apoderado para acceder a esta información. "
                     "Escribe 'Soy apoderado' para comenzar."
            )
            return []

        # 2) Leer y limpiar slots
        nombre_slot   = (tracker.get_slot("nombre_alumno") or "").strip()
        apellido_slot = (tracker.get_slot("apellido_alumno") or "").strip()

        # Debug: mostrar valores crudos de los slots
        print(f"🔍 nombre_slot raw:   '{nombre_slot}'")
        print(f"🔍 apellido_slot raw: '{apellido_slot}'")

        # 3) Si apellido_slot tiene >2 tokens, mover el primero a nombre_slot
        ap_tokens = apellido_slot.split()
        if len(ap_tokens) > 2:
            segundo_nombre = ap_tokens.pop(0)
            nombre_slot = f"{nombre_slot} {segundo_nombre}".strip()
            apellido_slot = " ".join(ap_tokens)

        # Debug: tras ajustar
        print(f"🔍 nombre_slot ajustado:   '{nombre_slot}'")
        print(f"🔍 apellido_slot ajustado: '{apellido_slot}'")

        # 4) Construir filtro de nombre: primeros dos tokens o el único
        nombre_tokens = nombre_slot.split()
        if len(nombre_tokens) >= 2:
            filtro_nombre = f"{nombre_tokens[0]} {nombre_tokens[1]}"
        elif len(nombre_tokens) == 1:
            filtro_nombre = nombre_tokens[0]
        else:
            filtro_nombre = ""
        print(f"🔍 filtro_nombre: '{filtro_nombre}'")

        # 5) Construir filtro de apellidos: últimos dos tokens o el único
        ap_tokens = apellido_slot.split()
        if len(ap_tokens) >= 2:
            filtro_apellidos = f"{ap_tokens[-2]} {ap_tokens[-1]}"
        elif len(ap_tokens) == 1:
            filtro_apellidos = ap_tokens[0]
        else:
            filtro_apellidos = ""
        print(f"🔍 filtro_apellidos: '{filtro_apellidos}'")

        try:
            db = connect_db()
            cursor = db.cursor()

            query = """
                SELECT 
                    c.nombre_curso,
                    CONCAT(dp.nombre_persona, ' ', dp.apellidos_personas),
                    o.fecha_observacion,
                    o.observacion
                FROM observacion o
                JOIN docente_curso dc 
                  ON o.id_docente_curso = dc.id_docente_curso
                JOIN curso c 
                  ON dc.id_curso = c.id_curso
                JOIN docente d 
                  ON dc.id_docente = d.id_docente
                JOIN persona dp 
                  ON d.id_persona = dp.id_persona
                JOIN alumno a 
                  ON o.id_alumno = a.id_alumno
                JOIN persona p 
                  ON a.id_persona = p.id_persona
                JOIN alumno_grado ag 
                  ON a.id_alumno = ag.id_alumno 
                 AND dc.id_grado = ag.id_grado 
                 AND dc.id_periodo = ag.id_periodo
                JOIN periodo pe 
                  ON ag.id_periodo = pe.id_periodo
                WHERE p.nombre_persona     LIKE %s
                  AND p.apellidos_personas LIKE %s
                  AND pe.estado_periodo = 1;
            """
            params = (f"%{filtro_nombre}%", f"%{filtro_apellidos}%")

            # Debug: mostrar query y parámetros
            print("🔍 Query a ejecutar:", query)
            print("🔍 Parámetros:", params)

            cursor.execute(query, params)
            resultados = cursor.fetchall()

            cursor.close()
            db.close()

            if resultados:
                mensaje = f"📌 Observaciones de {filtro_nombre} {filtro_apellidos}:\n\n"
                for curso, docente, fecha, obs in resultados:
                    mensaje += f"- {curso} ({fecha}) - Docente {docente}:\n  {obs}\n\n"
            else:
                mensaje = f"⚠️ No se encontraron observaciones para {filtro_nombre} {filtro_apellidos}."

            dispatcher.utter_message(text=mensaje)

        except Exception as e:
            print(f"❌ Error en action_consultar_observaciones: {e}")
            dispatcher.utter_message(text="❌ Ocurrió un error al consultar las observaciones.")

        mostrar_menu_personalizado(dispatcher, tracker)
        return [SlotSet("contexto_actual", "menu_principal")]



class ActionConsultarHorarioClases(Action):
    def name(self) -> str:
        return "action_consultar_horario"

    def run(self, dispatcher, tracker, domain):
        # 1) Validar autenticación
        if not tracker.get_slot("autenticado"):
            dispatcher.utter_message(
                text="⚠️ Debes iniciar sesión como apoderado para acceder a esta información. "
                     "Escribe 'Soy apoderado' para comenzar."
            )
            return []

        # 2) Leer y limpiar slots
        nombre_slot   = (tracker.get_slot("nombre_alumno") or "").strip()
        apellido_slot = (tracker.get_slot("apellido_alumno") or "").strip()

        # Debug: ver valores crudos
        print(f"🔍 nombre_slot raw:   '{nombre_slot}'")
        print(f"🔍 apellido_slot raw: '{apellido_slot}'")

        # 3) Ajustar si apellido_slot tiene >2 tokens
        ap_tokens = apellido_slot.split()
        if len(ap_tokens) > 2:
            segundo_nombre = ap_tokens.pop(0)
            nombre_slot = f"{nombre_slot} {segundo_nombre}".strip()
            apellido_slot = " ".join(ap_tokens)

        # Debug: tras ajuste
        print(f"🔍 nombre_slot ajustado:   '{nombre_slot}'")
        print(f"🔍 apellido_slot ajustado: '{apellido_slot}'")

        # 4) Construir filtro de nombre: primeros dos tokens o el único
        nombre_tokens = nombre_slot.split()
        if len(nombre_tokens) >= 2:
            filtro_nombre = f"{nombre_tokens[0]} {nombre_tokens[1]}"
        elif len(nombre_tokens) == 1:
            filtro_nombre = nombre_tokens[0]
        else:
            filtro_nombre = ""
        print(f"🔍 filtro_nombre: '{filtro_nombre}'")

        # 5) Construir filtro de apellidos: últimos dos tokens o el único
        ap_tokens = apellido_slot.split()
        if len(ap_tokens) >= 2:
            filtro_apellidos = f"{ap_tokens[-2]} {ap_tokens[-1]}"
        elif len(ap_tokens) == 1:
            filtro_apellidos = ap_tokens[0]
        else:
            filtro_apellidos = ""
        print(f"🔍 filtro_apellidos: '{filtro_apellidos}'")

        try:
            db = connect_db()
            cursor = db.cursor()

            query = """
                SELECT 
                    c.nombre_curso,
                    h.dia,
                    h.hora_inicio,
                    h.hora_fin
                FROM horario h
                JOIN alumno_grado ag ON h.id_alumno_grado = ag.id_alumno_grado
                JOIN alumno a ON ag.id_alumno = a.id_alumno
                JOIN persona p ON a.id_persona = p.id_persona
                JOIN docente_curso dc ON h.id_docente_curso = dc.id_docente_curso
                JOIN curso c ON dc.id_curso = c.id_curso
                JOIN periodo pe ON ag.id_periodo = pe.id_periodo
                WHERE p.nombre_persona   LIKE %s
                  AND p.apellidos_personas LIKE %s
                  AND pe.estado_periodo = 1
                ORDER BY FIELD(h.dia, 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'),
                         h.hora_inicio;
            """

            params = (f"%{filtro_nombre}%", f"%{filtro_apellidos}%")
            # Debug: mostrar consulta y parámetros
            print("🔍 Query a ejecutar:", query)
            print("🔍 Parámetros:", params)

            cursor.execute(query, params)
            resultados = cursor.fetchall()
            cursor.close()
            db.close()

            if resultados:
                mensaje = f"🗓️ Horario de clases de {filtro_nombre} {filtro_apellidos}:\n"
                for curso, dia, inicio, fin in resultados:
                    mensaje += f"- {dia}: {curso} de {inicio} a {fin}\n"
            else:
                mensaje = f"⚠️ No se encontró un horario registrado para {filtro_nombre} {filtro_apellidos}."

            dispatcher.utter_message(text=mensaje)

        except Exception as e:
            dispatcher.utter_message(text="❌ Ocurrió un error al consultar el horario.")
            print(f"Error en action_consultar_horario: {e}")

        mostrar_menu_personalizado(dispatcher, tracker)
        return [SlotSet("contexto_actual", "menu_principal")]



class ActionConsultarDocente(Action):
    def name(self) -> str:
        return "action_consultar_docente"

    def run(self, dispatcher, tracker, domain):
        # 1) Validar autenticación
        if not tracker.get_slot("autenticado"):
            dispatcher.utter_message(
                text="⚠️ Debes iniciar sesión como apoderado para acceder a esta información. "
                     "Escribe 'Soy apoderado' para comenzar."
            )
            return []

        # 2) Leer y limpiar slots
        nombre_slot   = (tracker.get_slot("nombre_alumno") or "").strip()
        apellido_slot = (tracker.get_slot("apellido_alumno") or "").strip()

        # Debug: valores crudos
        print(f"🔍 nombre_slot raw:   '{nombre_slot}'")
        print(f"🔍 apellido_slot raw: '{apellido_slot}'")

        # 3) Si apellido_slot tiene >2 tokens, mover el primero a nombre_slot
        ap_tokens = apellido_slot.split()
        if len(ap_tokens) > 2:
            segundo_nombre = ap_tokens.pop(0)
            nombre_slot = f"{nombre_slot} {segundo_nombre}".strip()
            apellido_slot = " ".join(ap_tokens)

        # Debug: tras ajuste
        print(f"🔍 nombre_slot ajustado:   '{nombre_slot}'")
        print(f"🔍 apellido_slot ajustado: '{apellido_slot}'")

        # 4) Construir filtro de nombre: primeros dos tokens o el único
        nombre_tokens = nombre_slot.split()
        if len(nombre_tokens) >= 2:
            filtro_nombre = f"{nombre_tokens[0]} {nombre_tokens[1]}"
        elif len(nombre_tokens) == 1:
            filtro_nombre = nombre_tokens[0]
        else:
            filtro_nombre = ""
        print(f"🔍 filtro_nombre: '{filtro_nombre}'")

        # 5) Construir filtro de apellidos: últimos dos tokens o el único
        ap_tokens = apellido_slot.split()
        if len(ap_tokens) >= 2:
            filtro_apellidos = f"{ap_tokens[-2]} {ap_tokens[-1]}"
        elif len(ap_tokens) == 1:
            filtro_apellidos = ap_tokens[0]
        else:
            filtro_apellidos = ""
        print(f"🔍 filtro_apellidos: '{filtro_apellidos}'")

        try:
            db = connect_db()
            cursor = db.cursor()

            query = """
                SELECT DISTINCT
                    c.nombre_curso,
                    pd.nombre_persona,
                    pd.apellidos_personas,
                    pd.correo_persona,
                    pd.telefono_persona
                FROM alumno a
                JOIN persona pa ON a.id_persona = pa.id_persona
                JOIN alumno_curso ac ON a.id_alumno = ac.id_alumno
                JOIN curso c ON ac.id_curso = c.id_curso
                JOIN docente_curso dc 
                  ON c.id_curso = dc.id_curso 
                 AND ac.id_periodo = dc.id_periodo 
                 AND a.id_alumno IN (
                     SELECT id_alumno 
                       FROM alumno_grado ag 
                      WHERE ag.id_periodo = ac.id_periodo
                  )
                JOIN docente d ON dc.id_docente = d.id_docente
                JOIN persona pd ON d.id_persona = pd.id_persona
                JOIN periodo pe ON ac.id_periodo = pe.id_periodo
                WHERE pa.nombre_persona     LIKE %s
                  AND pa.apellidos_personas LIKE %s
                  AND pe.estado_periodo = 1;
            """
            params = (f"%{filtro_nombre}%", f"%{filtro_apellidos}%")

            # Debug: consulta y parámetros
            print("🔍 Query a ejecutar:", query)
            print("🔍 Parámetros:", params)

            cursor.execute(query, params)
            resultados = cursor.fetchall()
            cursor.close()
            db.close()

            if resultados:
                mensaje = f"👨‍🏫 Docentes de {filtro_nombre} {filtro_apellidos} en sus cursos actuales:\n"
                for curso, nom_doc, ape_doc, correo, telefono in resultados:
                    mensaje += (
                        f"\n📚 *{curso}*\n"
                        f"- Docente: {nom_doc} {ape_doc}\n"
                        f"- Correo: {correo}\n"
                        f"- Teléfono: {telefono}\n"
                    )
            else:
                mensaje = f"⚠️ No se encontró información de docentes para {filtro_nombre} {filtro_apellidos}."

            dispatcher.utter_message(text=mensaje)

        except Exception as e:
            dispatcher.utter_message(text="❌ Ocurrió un error al consultar la información de los docentes.")
            print(f"Error en action_consultar_docente: {e}")

        mostrar_menu_personalizado(dispatcher, tracker)
        return [SlotSet("contexto_actual", "menu_principal")]




class ActionConsultarEstadoMatricula(Action):
    def name(self) -> str:
        return "action_consultar_estado_matricula"

    def run(self, dispatcher, tracker, domain):
        if not tracker.get_slot("autenticado"):
            dispatcher.utter_message(text="⚠️ Debes iniciar sesión como apoderado para acceder a esta información. Escribe 'Soy apoderado' para comenzar.")
            return []
        nombre = tracker.get_slot("nombre_alumno")
        apellido_slot  = tracker.get_slot("apellido_alumno")

        tokens = apellido_slot.strip().split()
        if len(tokens) >= 2:
            filtro_apellidos = f"{tokens[-2]} {tokens[-1]}"
        else:
            filtro_apellidos = tokens[0]

        try:
            db = connect_db()
            cursor = db.cursor()

            query = """
                SELECT 
                    g.nombre_grado,
                    g.nombre_seccion,
                    p.nombre_periodo
                FROM alumno a
                JOIN persona pe ON a.id_persona = pe.id_persona
                JOIN alumno_grado ag ON a.id_alumno = ag.id_alumno
                JOIN grado g ON ag.id_grado = g.id_grado
                JOIN periodo p ON ag.id_periodo = p.id_periodo
                WHERE pe.nombre_persona LIKE %s
                  AND pe.apellidos_personas LIKE %s
                  AND p.estado_periodo = 1
                LIMIT 1;
            """
            cursor.execute(query, (f"%{nombre}%", f"%{filtro_apellidos}%"))
            resultado = cursor.fetchone()

            if resultado:
                grado, seccion, periodo = resultado
                mensaje = f"🎓 {nombre} {filtro_apellidos} está actualmente matriculado en:\n📘 *{grado}* - Sección *{seccion}* ({periodo})"
            else:
                mensaje = f"No se encontró información del grado actual para {nombre} {filtro_apellidos}."

            cursor.close()
            db.close()
            dispatcher.utter_message(text=mensaje)

        except Exception as e:
            dispatcher.utter_message(text="Ocurrió un error al consultar el grado actual.")
            print(f"❌ Error en action_consultar_grado_actual: {e}")

        mostrar_menu_personalizado(dispatcher, tracker)

        return [SlotSet("contexto_actual", "menu_principal")]



def mostrar_menu_personalizado(dispatcher: CollectingDispatcher, tracker: Tracker):
    alumnos = tracker.get_slot("alumnos_disponibles")
    nombre_completo = tracker.get_slot("nombre_completo_alumno")   
    if nombre_completo:
        dispatcher.utter_message(text=f"✅ Alumno actualizado: {nombre_completo}.")
        return [SlotSet("nombre_completo_alumno", None), SlotSet("contexto_actual", "menu_principal")]

    texto = (
        "\n"
        "📋¿Qué deseas hacer ahora?\n"
        "☑️  Consultar notas\n"
        "☑️  Consultar asistencias\n"
        "☑️  Consultar eventos\n"
        "☑️  Ver observaciones del docente\n"
        "☑️  Ver horario de clases\n"
        "☑️  Ver información del docente\n"
        "☑️  Ver grado actual\n"
    )

    if alumnos and len(alumnos) > 1:
        texto += "☑️  Cambiar de estudiante\n"

    texto += "Puedes escribirme directamente lo que deseas hacer."

    dispatcher.utter_message(text=texto)

class ActionCerrarSesion(Action):
    def name(self) -> str:
        return "action_cerrar_sesion"

    def run(self, dispatcher: CollectingDispatcher, tracker: Tracker, domain: Dict) -> List[Dict]:
        dispatcher.utter_message(text="🔒 Has cerrado sesión exitosamente. Si deseas volver a ingresar, escribe: 'Soy apoderado'.")

        # Limpiar todos los slots relacionados con la sesión
        return [
            SlotSet("nombre_apoderado", None),
            SlotSet("apellido_apoderado", None),
            SlotSet("dni_apoderado", None),
            SlotSet("nombre_alumno", None),
            SlotSet("apellido_alumno", None),
            SlotSet("clave_acceso", None),           # <-- aquí
            SlotSet("requested_slot", None), 
            SlotSet("autenticado", None),
            SlotSet("alumnos_disponibles", None),
            SlotSet("alumno_seleccionado", None),
            SlotSet("contexto_actual", None),
            SlotSet("nombre_completo_alumno", None),
            SlotSet("filtro_asistencia", None),

            ActiveLoop(None)

        ]
    

class ActionDefaultFallback(Action):
    def name(self) -> str:
        return "action_default_fallback"

    def run(self, dispatcher, tracker, domain):
        if not tracker.get_slot("autenticado"):
            dispatcher.utter_message(text="⚠️ No entendí tu mensaje. Soy un asistente para consultas académicas. Escribe 'Soy apoderado' para comenzar.")
        else:
            dispatcher.utter_message(text="⚠️ No entendí tu mensaje. Puedes preguntarme sobre notas, asistencias, eventos, docentes y más.")

        return []
