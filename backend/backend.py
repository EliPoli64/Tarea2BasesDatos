from datetime import datetime, time, date
from flask import Flask, jsonify, request, session
from flask_cors import CORS
import pyodbc

# Cadena de conexión a la base de datos
connectionString = "DRIVER={ODBC Driver 17 for SQL Server};SERVER=25.38.209.9,1433;DATABASE=EmpleadosDB;UID=Remoto;PWD=1234;"

app = Flask(__name__)
CORS(app, supports_credentials=True)

app.secret_key = 'claveSecreta1234'

def obtenerDescripcionError(codigoError):
    """
    Obtiene la descripción de un código de error de la base de datos.
    """
    descripcion = "Error desconocido."
    conexion = None
    try:
        conexion = pyodbc.connect(connectionString)
        cursor = conexion.cursor()
        sql = """
        DECLARE @outDescripcion VARCHAR(256);
        EXEC dbo.ObtenerDescripcionError @inCodigo = ?, @outDescripcion = @outDescripcion OUTPUT;
        SELECT @outDescripcion;
        """
        # Se convierte el código de error a int para la ejecución del SP
        descripcion = cursor.execute(sql, int(codigoError)).fetchval()
    except pyodbc.Error as ex:
        print(f"Error al obtener descripción del error: {ex}")
    finally:
        if conexion:
            conexion.close()
    return descripcion

# --- Endpoints para Empleados ---

@app.route("/proyecto/select", methods=['GET'])
def ejecutarSpFiltrarEmpleados():
    """
    Ejecuta el stored procedure FiltrarEmpleados con un filtro.
    """
    conexion = None
    try:
        # Obtener parámetros de la query string
        ip = request.args.get('ip')
        usuarioLogueado = request.args.get('usuario')
        filtro = request.args.get('filtro')

        conexion = pyodbc.connect(connectionString)
        cursor = conexion.cursor()
        sql = """
            DECLARE @outResultCode INT;
            EXEC dbo.FiltrarEmpleados @infiltro = ?, @inUsuario = ?, @inIP = ?, @outResultCode = @outResultCode OUTPUT;
            SELECT @outResultCode;
            """
        parametros = (filtro, usuarioLogueado, ip)
        
        # Ejecutar SP. El SP devuelve una tabla de resultados.
        # El primer SELECT (@outResultCode) se ignora aquí ya que el SP
        # también retorna un conjunto de resultados con los datos de los empleados.
        # **Nota:** Una mejor práctica sería ejecutar el SP sin el SELECT @outResultCode 
        # y manejar el código de resultado como un valor de retorno del cursor si el SP
        # está diseñado para devolver primero la tabla de resultados y luego el código
        # de retorno. Tal como está, el .fetchall() leerá los resultados del SP.
        cursor.execute(sql, parametros)
        filas = cursor.fetchall()
        
        # Definir los encabezados (headers) esperados
        headers = ["id", "Nombre", "ValorDocumentoIdentidad", "Puesto", "SalarioHora", "SaldoVacaciones"]
        listaEmpleados = []
        for fila in filas:
            filaLista = dict(zip(headers, fila))
            listaEmpleados.append(filaLista)
            
        return jsonify(listaEmpleados)

    except pyodbc.Error as ex:
        # sqlstate = ex.args[0] # No usado actualmente pero útil para depuración
        print(f"Error en FiltrarEmpleados: {ex}")
        return jsonify({"error": "Error al obtener los empleados"}), 500
    finally:
        if 'conexion' in locals() and conexion:
            conexion.close()

@app.route("/proyecto/selectTodos/")
def ejecutarSpSeleccionarTodosEmpleados():
    """
    Ejecuta el stored procedure FiltrarEmpleados para obtener todos los empleados.
    Asume que el SP no requiere los parámetros inUsuario e inIP para la selección total.
    """
    conexion = None
    try:
        conexion = pyodbc.connect(connectionString)
        cursor = conexion.cursor()
        sql = "{CALL dbo.FiltrarEmpleados (?, ?, ?, ?)}"
        # Valores de ejemplo/placeholder para un 'select all'
        parametros = ("%", 0, 0, 0)
        cursor.execute(sql, parametros)
        filas = cursor.fetchall()

        headers = ["id", "Nombre", "ValorDocumentoIdentidad", "Puesto", "SalarioHora"] 
        listaEmpleados = []
        for fila in filas:
            filaLista = dict(zip(headers, fila))
            listaEmpleados.append(filaLista)
            
        return jsonify(listaEmpleados)

    except pyodbc.Error as ex:
        # sqlstate = ex.args[0]
        print(f"Error en FiltrarEmpleados: {ex}")
        return jsonify({"error": "Error al obtener todos los empleados"}), 500
    finally:
        if 'conexion' in locals() and conexion:
            conexion.close()

@app.route("/proyecto/insertarEmpleado/", methods=['POST'])
def insertarEmpleado():
    """
    Ejecuta el stored procedure InsertarEmpleado.
    """
    conn = None
    data = request.get_json()
    nombreNuevo = data.get('nombre')
    puestoNuevo = data.get('puesto')
    documentoNuevo = data.get('documento')
    usuarioLogueado = data.get('usuario')
    ipUsuario = data.get('ip')

    try:
        conn = pyodbc.connect(connectionString, autocommit=False)
        cursor = conn.cursor()
        
        sql = """
        DECLARE @outResultCode INT;
        EXEC dbo.InsertarEmpleado @inNombre = ?, @inPuesto = ?, @inDocumentoIdentidad = ?, @inIP = ?, @inUsuario = ?, @outResultCode = @outResultCode OUTPUT;
        SELECT @outResultCode;
        """
        params = (nombreNuevo, puestoNuevo, documentoNuevo, ipUsuario, usuarioLogueado)
        
        resultCode = cursor.execute(sql, params).fetchval()
        
        if resultCode == 0:
            conn.commit()
            return jsonify({"exito": True, "message": "Empleado insertado correctamente."})
        else:
            conn.rollback()
            errorMessage = obtenerDescripcionError(resultCode)
            return jsonify({"exito": False, "message": errorMessage})

    except pyodbc.Error as ex:
        if 'conn' in locals() and conn:
            conn.rollback()
        print(f"Error al insertar empleado: {ex}")
        return jsonify({"exito": False, "message": "Error en la base de datos al insertar."}), 500
    finally:
        if conn:
            conn.close()

@app.route("/proyecto/eliminarEmpleado/", methods=['POST'])
def eliminarEmpleado():
    """
    Ejecuta el stored procedure EliminarEmpleado.
    """
    conn = None
    data = request.get_json()
    nombre = data.get('nombre')
    documentoIdentidad = data.get('documento')
    usuarioLogueado = data.get('usuario')
    ipUsuario = data.get('ip')

    try:
        conn = pyodbc.connect(connectionString, autocommit=False)
        cursor = conn.cursor()
        
        sql = """
        DECLARE @outResultCode INT;
        EXEC dbo.EliminarEmpleado @inNombre = ?, @inDocumentoIdentidad = ?, @inIP = ?, @inUsuario = ?, @outResultCode = @outResultCode OUTPUT;
        SELECT @outResultCode;
        """
        params = (nombre, documentoIdentidad, ipUsuario, usuarioLogueado)
        
        resultCode = cursor.execute(sql, params).fetchval()
        
        if resultCode == 0:
            conn.commit()
            return jsonify({"exito": True, "message": "Empleado eliminado correctamente."})
        else:
            conn.rollback()
            errorMessage = obtenerDescripcionError(resultCode)
            return jsonify({"exito": False, "message": errorMessage})

    except pyodbc.Error as ex:
        if 'conn' in locals() and conn:
            conn.rollback()
        print(f"Error al eliminar empleado: {ex}")
        return jsonify({"exito": False, "message": "Error en la base de datos al eliminar."}), 500
    finally:
        if conn:
            conn.close()

@app.route("/proyecto/actualizarEmpleado/", methods=['PUT'])
def actualizarEmpleado():
    """
    Ejecuta el stored procedure ActualizarEmpleado.
    """
    conn = None
    data = request.get_json()
    nombreActual = data.get('nombreActual')
    documentoActual = data.get('documentoActual')
    nombreNuevo = data.get('nombreNuevo')
    documentoNuevo = data.get('documentoNuevo')
    puestoNuevo = data.get('puestoNuevo')
    usuarioLogueado = data.get('usuario')
    ipUsuario = data.get('ip')

    try:
        conn = pyodbc.connect(connectionString, autocommit=False)
        cursor = conn.cursor()
        
        sql = """
        DECLARE @outResultCode INT;
        EXEC dbo.ActualizarEmpleado @inNombre = ?, @inPuesto = ?, @inDocumentoIdentidad = ?, @inNombreActual = ?, @inDocumentoIdentidadActual = ?, @inIP = ?, @inUsuario = ?, @outResultCode = @outResultCode OUTPUT;
        SELECT @outResultCode;
        """
        params = (nombreNuevo, puestoNuevo, documentoNuevo, nombreActual, documentoActual, ipUsuario, usuarioLogueado)
        resultCode = cursor.execute(sql, params).fetchval()
        
        if resultCode == 0:
            conn.commit()
            return jsonify({"exito": True, "message": "Empleado actualizado correctamente."})
        else:
            conn.rollback()
            errorMessage = obtenerDescripcionError(resultCode)
            return jsonify({"exito": False, "message": errorMessage})

    except pyodbc.Error as ex:
        if 'conn' in locals() and conn:
            conn.rollback()
        print(f"Error al actualizar empleado: {ex}")
        return jsonify({"exito": False, "message": "Error en la base de datos al actualizar."}), 500
    finally:
        if conn:
            conn.close()

# --- Endpoints para Puestos ---

@app.route("/proyecto/puestos/")
def ejecutarSpObtenerPuestos():
    """
    Ejecuta el stored procedure TraerPuestos para obtener la lista de puestos.
    """
    conexion = None
    try:
        conexion = pyodbc.connect(connectionString)
        cursor = conexion.cursor()
        sql = "{CALL dbo.TraerPuestos}"
        # Parámetros de ejemplo/placeholder
        cursor.execute(sql)
        filas = cursor.fetchall()
        
        headers = ["id","nombre"]
        listaPuestos = []
        for fila in filas:
            filaLista = dict(zip(headers, fila))
            listaPuestos.append(filaLista)
        return jsonify(listaPuestos)

    except pyodbc.Error as ex:
        # sqlstate = ex.args[0]
        print(f"Error en TraerPuestos: {ex}")
        return jsonify({"error": "Error al obtener los puestos"}), 500
    finally:
        if 'conexion' in locals() and conexion:
            conexion.close()

# --- Endpoints para Autenticación ---

@app.route("/proyecto/login/", methods=['POST'])
def ejecutarSpLogin():
    """
    Ejecuta el stored procedure VerificarLogin.
    """
    conexion = None
    try:
        data = request.get_json()
        usuario = data.get('usuario')
        contrasena = data.get('contrasena')
        ipCliente = request.remote_addr # Obtener la IP del cliente

        if not usuario or not contrasena:
            return jsonify({"authenticated": False, "message": "Usuario y contraseña son requeridos."}), 400

        conexion = pyodbc.connect(connectionString, autocommit=False)
        cursor = conexion.cursor()
        sql = """
        DECLARE @outResultCode INT;
        EXEC dbo.VerificarLogin @inIP = ?, @inUsuario = ?, @inContrasenna = ?, @outResultCode = @outResultCode OUTPUT;
        SELECT @outResultCode;
        """
        
        parametros = (ipCliente, usuario, contrasena)

        resultCode = cursor.execute(sql, parametros).fetchval()
        
        if resultCode == 0:
            conexion.commit()
            # Establecer variables de sesión
            session['usuario'] = usuario
            session['ip'] = ipCliente
            return jsonify({"autenticado": True, "usuario": usuario, "ip": ipCliente})
        else:
            conexion.rollback()
            errorMessage = obtenerDescripcionError(resultCode)
            return jsonify({"autenticado": False, "mensaje": errorMessage})

    except pyodbc.Error as ex:
        if 'conexion' in locals() and conexion:
            conexion.rollback()
        print(f"Error de base de datos en login: {ex}")
        return jsonify({"authenticated": False, "message": "Error de conexión con el servidor."}), 500
    finally:
        if conexion:
            conexion.close()

@app.route("/proyecto/logout/", methods=['POST'])
def ejecutarSpLogout():
    """
    Ejecuta el stored procedure RegistrarLogout y limpia la sesión.
    """
    conn = None
    data = request.get_json()
    usuario = data.get('usuario')
    ip = data.get('ip')
    
    try:
        conn = pyodbc.connect(connectionString, autocommit=False)
        cursor = conn.cursor()
        sql = """
        DECLARE @outResultCode INT;
        EXEC dbo.RegistrarLogout @inUsuario = ?, @inIP = ?, @outResultCode = @outResultCode OUTPUT;
        SELECT @outResultCode;
        """
        params = (usuario, ip)
        cursor.execute(sql, params)
        conn.commit()

    except pyodbc.Error as ex:
        if 'conn' in locals() and conn:
            conn.rollback()
        print(f"Error de base de datos al registrar logout: {ex}")
    finally:
        if conn:
            conn.close()

    # Siempre limpiar la sesión de Flask, independientemente del éxito en la DB
    session.clear()
    return jsonify({"message": "Sesión cerrada correctamente."})

# --- Endpoints para Movimientos ---

@app.route("/proyecto/tiposMovimiento/", methods=['GET'])
def obtenerTiposMovimiento():
    """
    Ejecuta el stored procedure ObtenerTipoMovimiento para listar los tipos de movimientos.
    """
    conn = None
    try:
        conn = pyodbc.connect(connectionString)
        cursor = conn.cursor()
        
        sql = """
        DECLARE @outResultCode INT;
        EXEC dbo.ObtenerTipoMovimiento @outResultCode = @outResultCode OUTPUT;
        SELECT @outResultCode;
        """
        # Se ejecuta el SP que debe devolver el conjunto de resultados (filas)
        cursor.execute(sql)
        filas = cursor.fetchall() 
        
        # Ojo: El SP retorna primero las filas y luego el código de resultado (que aquí se ignora)
        headers = ["ID", "Movimiento", "Tipo"]
        listaTiposMovimiento = []
        for fila in filas:
            filaLista = dict(zip(headers, fila))
            listaTiposMovimiento.append(filaLista)
            
        return jsonify(listaTiposMovimiento)

    except pyodbc.Error as ex:
        print(f"Error al cargar tipos de movimientos: {ex}")
        return jsonify({"exito": False, "message": "Error en la base de datos al cargar tipos de movimientos."}), 500
    finally:
        if conn:
            conn.close()

@app.route("/proyecto/insertarMovimiento/", methods=['POST'])
def insertarMovimiento():
    """
    Ejecuta el stored procedure InsertarMovimiento.
    """
    conn = None
    data = request.get_json()
    documentoIdentidad = data.get('documentoIdentidad')
    tipoMovimiento = data.get('tipoMovimiento')
    monto = data.get('monto')
    usuarioLogueado = data.get('usuario')
    ipUsuario = data.get('ip')

    try:
        conn = pyodbc.connect(connectionString, autocommit=False)
        cursor = conn.cursor()
        
        sql = """
        DECLARE @outResultCode INT;
        EXEC dbo.InsertarMovimiento @inDocumentoIdentidad = ?, @inIdTipoMovimiento = ?, @inMonto = ?, @inIP = ?, @inUsuario = ?, @outResultCode = @outResultCode OUTPUT;
        SELECT @outResultCode;
        """
        params = (documentoIdentidad, tipoMovimiento, monto, ipUsuario, usuarioLogueado)
        
        resultCode = cursor.execute(sql, params).fetchval()
        
        if resultCode == 0:
            conn.commit()
            return jsonify({"exito": True, "message": "Movimiento insertado correctamente."})
        else:
            conn.rollback()
            errorMessage = obtenerDescripcionError(resultCode)
            return jsonify({"exito": False, "message": errorMessage})

    except pyodbc.Error as ex:
        if 'conn' in locals() and conn:
            conn.rollback()
        print(f"Error al insertar movimiento: {ex}")
        return jsonify({"exito": False, "message": "Error en la base de datos al insertar."}), 500
    finally:
        if conn:
            conn.close()

@app.route("/proyecto/movimientos", methods=['GET'])
def listarMovimientos():
    conexion = None
    try:
        documentoIdentidad = request.args.get('documentoIdentidad')
        usuarioLogueado = request.args.get('usuario')
        ip = request.args.get('ip')

        if not documentoIdentidad or not usuarioLogueado or not ip:
            return jsonify({"error": "Faltan parámetros en la solicitud"}), 400

        conexion = pyodbc.connect(connectionString)
        cursor = conexion.cursor()
        
        sql = """
        DECLARE @outResultCode INT;
        EXEC dbo.ListarMovimientosPorEmpleado @inDocumentoIdentidad = ?, @inIP = ?, @inUsuario = ?, @outResultCode = @outResultCode OUTPUT;
        SELECT @outResultCode;
        """
        parametros = (documentoIdentidad, ip, usuarioLogueado)
        cursor.execute(sql, parametros)

        filasMovimientos = cursor.fetchall()

        cursor.nextset()
        
        resultadoDb = cursor.fetchone()
        outResultCode = resultadoDb[0] if resultadoDb else 0

        if outResultCode != 0:
            if outResultCode == 50008:
                return jsonify({"error": "Empleado no encontrado o error en la base de datos"}), 404
            else:
                return jsonify({"error": f"Error desconocido en DB: {outResultCode}"}), 500

        headers = ["Fecha", "TipoMovimiento", "Monto", "NuevoSaldo", "Usuario", "IP", "PostTime"]

        listaMovimientos = []
        for fila in filasMovimientos:
            filaDict = dict(zip(headers, fila))
            
            # Conversión de Fecha (date o datetime)
            fecha = filaDict.get("Fecha")
            if isinstance(fecha, (datetime, date)):
                filaDict["Fecha"] = fecha.strftime("%Y-%m-%d")

            # Conversión de PostTime (time o datetime)
            postTime = filaDict.get("PostTime")
            filaDict["PostTime"] = postTime.strftime("%H:%M:%S")
            if postTime is not None:
                if isinstance(postTime, datetime):
                    filaDict["PostTime"] = postTime.strftime("%Y-%m-%d %H:%M:%S")
                elif isinstance(postTime, time):
                    filaDict["PostTime"] = postTime.strftime("%H:%M:%S")

            listaMovimientos.append(filaDict)
            
        return jsonify(listaMovimientos)

    except pyodbc.Error as ex:
        print(f"Error de pyodbc: {ex}")
        return jsonify({"error": "Error de conexión o consulta en la base de datos"}), 500
    
    except Exception as e:
        print(f"Error inesperado: {e}")
        return jsonify({"error": "Ocurrió un error interno"}), 500
        
    finally:
        if conexion:
            conexion.close()

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000, debug=True)