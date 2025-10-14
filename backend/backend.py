from flask import Flask, jsonify, request, session
from flask_cors import CORS
import pyodbc

stringConexion = "DRIVER={ODBC Driver 17 for SQL Server};SERVER=LOCALHOST,1433;DATABASE=EmpleadosDB;UID=Remoto;PWD=Contraseña123;"

app = Flask(__name__)
CORS(app, supports_credentials=True, origins=["http://127.0.0.1:5500"])

app.secret_key = 'claveSecreta1234'

# Funciones auxiliares
# Funcion Auxiliar para los errores del login
def obtener_descripcion_error(codigo_error):
    descripcion = "Error desconocido."
    try:
        conexion = pyodbc.connect(stringConexion)
        cursor = conexion.cursor()
        sql = """
        DECLARE @outDescripcion VARCHAR(256);
        EXEC dbo.ObtenerDescripcionError @inCodigo = ?, @outDescripcion = @outDescripcion OUTPUT;
        SELECT @outDescripcion;
        """
        descripcion = cursor.execute(sql, codigo_error).fetchval()
    except pyodbc.Error as ex:
        print(f"Error al obtener descripción del error: {ex}")
    finally:
        if 'conexion' in locals():
            conexion.close()
    return descripcion

# Endpoints
@app.route("/proyecto/select/<string:nombre>/") # Endpoint corregido
def ejecutarSPSelect(nombre):
    try:
        conexion = pyodbc.connect(stringConexion)
        cursor = conexion.cursor()
        sql = "{CALL dbo.FiltrarEmpleados (?, ?)}"
        parametros = (nombre, 0)
        cursor.execute(sql, parametros)
        filas = cursor.fetchall()
        headers = ["ID", "Nombre", "ValorDocumentoIdentidad", "Puesto", "Salario x Hora", "SaldoVacaciones"]
        listaEmpleados = []
        for fila in filas:
            filaLista = dict(zip(headers, fila))
            listaEmpleados.append(filaLista)
        return jsonify(listaEmpleados)
        
    except pyodbc.Error as ex:
        sqlstate = ex.args[0]
        print(f"Error: {sqlstate}")
    finally:
        if 'cursor' in locals():
            cursor.close()
        if 'conexion' in locals():
            conexion.close()
    return jsonify({"error": "Error al obtener los empleados"})

@app.route("/proyecto/selectTodos/") # Endpoint corregido
def ejecutarSPSelectTodos():
    try:
        conexion = pyodbc.connect(stringConexion)
        cursor = conexion.cursor()
        sql = "{CALL dbo.FiltrarEmpleados (?, ?)}"
        parametros = ("%", 0)
        cursor.execute(sql, parametros)
        filas = cursor.fetchall()
        headers = ["ID", "Nombre", "ValorDocumentoIdentidad", "Puesto", "Salario x Hora"]
        listaEmpleados = []
        for fila in filas:
            filaLista = dict(zip(headers, fila))
            listaEmpleados.append(filaLista)
        return jsonify(listaEmpleados)
        
    except pyodbc.Error as ex:
        sqlstate = ex.args[0]
        print(f"Error: {sqlstate}")
    finally:
        if 'cursor' in locals():
            cursor.close()
        if 'conexion' in locals():
            conexion.close()
    return jsonify({"error": "Error al obtener los empleados"})

@app.route("/proyecto/puestos/") # Endpoint nuevo
def ejecutarSPTraerPuestos():
    try:
        conexion = pyodbc.connect(stringConexion)
        cursor = conexion.cursor()
        sql = "{CALL dbo.TraerPuestos (?, ?)}"
        parametros = (0, 0)
        cursor.execute(sql, parametros)
        filas = cursor.fetchall()
        headers = ["ID","Nombre"]
        listaEmpleados = []
        for fila in filas:
            filaLista = dict(zip(headers, fila))
            listaEmpleados.append(filaLista)
        return jsonify(listaEmpleados)
        
    except pyodbc.Error as ex:
        sqlstate = ex.args[0]
        print(f"Error: {sqlstate}")
    finally:
        if 'cursor' in locals():
            cursor.close()
        if 'conexion' in locals():
            conexion.close()
    return jsonify({"error": "Error al obtener los puestos"})

@app.route("/proyecto/login/", methods=['POST']) # Endpoint nuevo
def ejecutarSPLogin():
    conexion = None
    cursor = None
    try:
        datos = request.get_json()
        usuario = datos.get('usuario')
        contrasena = datos.get('contrasena')
        ip_cliente = request.remote_addr

        if not usuario or not contrasena:
            return jsonify({"autenticado": False, "mensaje": "Usuario y contraseña son requeridos."}), 400

 
        conexion = pyodbc.connect(stringConexion, autocommit=False)
        cursor = conexion.cursor()
        sql = """
        DECLARE @outResultCode INT;
        EXEC dbo.VerificarLogin @inIP = ?, @inUsuario = ?, @inContrasenna = ?, @outResultCode = @outResultCode OUTPUT;
        SELECT @outResultCode;
        """
        parametros = (ip_cliente, usuario, contrasena)
        
        codigo_resultado = cursor.execute(sql, parametros).fetchval()

        print(codigo_resultado)
        
        if codigo_resultado == 0:  # 0 significa éxito
            # Creamos la sesión del usuario
            session['usuario'] = usuario
            session['ip'] = ip_cliente
            return jsonify({"autenticado": True, "usuario": usuario, "ip": ip_cliente})
        else:
            # Si hay un error, obtenemos su descripción
            mensaje_error = obtener_descripcion_error(codigo_resultado)
            return jsonify({"autenticado": False, "mensaje": mensaje_error})

    except pyodbc.Error as ex:
        print(f"Error de base de datos en login: {ex}")
        return jsonify({"autenticado": False, "mensaje": "Error de conexión con el servidor."}), 500
    finally:
        if 'conexion' in locals():
            conexion.close()

@app.route("/proyecto/logout/", methods=['POST']) # Endpoint nuevo
def logout():
    if 'usuario' in session:
        usuario = session.get('usuario')
        ip_cliente = session.get('ip')
        
        try:
            conn = pyodbc.connect(stringConexion)
            cursor = conn.cursor()
            sql = """
            DECLARE @outResultCode INT;
            EXEC dbo.RegistrarLogout @inIP = ?, @inUsuario = ?, @outResultCode = @outResultCode OUTPUT;
            SELECT @outResultCode;
            """
            params = (ip_cliente, usuario)
            cursor.execute(sql, params)
            conn.commit()

        except pyodbc.Error as ex:
            print(f"Error de base de datos al registrar logout: {ex}")
            # Aunque falle el registro, se debe cerrar sesion
        finally:
            if 'conn' in locals():
                conn.close()

    # Limpia/destruye la sesión del usuario
    session.clear()
    return jsonify({"mensaje": "Sesión cerrada correctamente."})

@app.route("/proyecto/insertarEmpleado/", methods=['POST']) # Endpoint nuevo
def insertar_empleado():
    # Verifica si el usuario ha iniciado sesión
    #if 'usuario' not in session:
        #return jsonify({"exito": False, "mensaje": "No autorizado. Por favor, inicie sesión."}), 401

    datos_empleado = request.get_json()
    nombre_nuevo = datos_empleado.get('nombre')
    puesto_nuevo = datos_empleado.get('puesto')
    documento_nuevo = datos_empleado.get('documento')
    usuario_logueado = datos_empleado.get('usuario')
    ip_usuario = datos_empleado.get('ip')

    try:
        conn = pyodbc.connect(stringConexion)
        cursor = conn.cursor()     
        
        sql = """
        DECLARE @outResultCode INT;
        EXEC dbo.InsertarEmpleado @inNombre = ?, @inPuesto = ?, @inDocumentoIdentidad = ?, @inIP = ?, @inUsuario = ?, @outResultCode = @outResultCode OUTPUT;
        SELECT @outResultCode;
        """
        params = (nombre_nuevo, puesto_nuevo, documento_nuevo, ip_usuario, usuario_logueado)
        print(params)
        
        codigo_resultado = cursor.execute(sql, params).fetchval()
        conn.commit() 

        if codigo_resultado == 0:
             return jsonify({"exito": True, "mensaje": "Empleado insertado correctamente."})
        else:
            mensaje_error = obtener_descripcion_error(codigo_resultado)
            return jsonify({"exito": False, "mensaje": mensaje_error})

    except pyodbc.Error as ex:
        print(f"Error al insertar empleado: {ex}")
        return jsonify({"exito": False, "mensaje": "Error en la base de datos al insertar."}), 500
    finally:
        if 'conn' in locals():
            conn.close()

@app.route("/proyecto/eliminarEmpleado/", methods=['POST']) # Endpoint nuevo
def eliminar_empleado():
        
    datos_empleado = request.get_json()
    nombre = datos_empleado.get('nombre')
    documento_identidad = datos_empleado.get('documento')
    usuario_logueado = datos_empleado.get('usuario')
    ip_usuario = datos_empleado.get('ip')

    try:
        conn = pyodbc.connect(stringConexion)
        cursor = conn.cursor()     
        
        sql = """
        DECLARE @outResultCode INT;
        EXEC dbo.EliminarEmpleado @inNombre = ?, @inDocumentoIdentidad = ?, @inIP = ?, @inUsuario = ?, @outResultCode = @outResultCode OUTPUT;
        SELECT @outResultCode;
        """
        params = (nombre, documento_identidad, ip_usuario, usuario_logueado)
        print(params)
        
        codigo_resultado = cursor.execute(sql, params).fetchval()
        conn.commit() 

        if codigo_resultado == 0:
             return jsonify({"exito": True, "mensaje": "Empleado eliminado correctamente."})
        else:
            mensaje_error = obtener_descripcion_error(codigo_resultado)
            return jsonify({"exito": False, "mensaje": mensaje_error})

    except pyodbc.Error as ex:
        print(f"Error al eliminar empleado: {ex}")
        return jsonify({"exito": False, "mensaje": "Error en la base de datos al eliminar."}), 500
    finally:
        if 'conn' in locals():
            conn.close()

@app.route("/proyecto/actualizarEmpleado/", methods=['PUT']) # Endpoint nuevo
def actualizar_empleado():
        
    datos_empleado = request.get_json()
    nombreActual = datos_empleado.get('nombreActual')
    documentoActual = datos_empleado.get('documentoActual')
    nombreNuevo = datos_empleado.get('nombreNuevo')
    documentoNuevo = datos_empleado.get('documentoNuevo')
    puestoNuevo = datos_empleado.get('puestoNuevo')
    usuario_logueado = datos_empleado.get('usuario')
    ip_usuario = datos_empleado.get('ip')

    try:
        conn = pyodbc.connect(stringConexion)
        cursor = conn.cursor()     
        
        sql = """
        DECLARE @outResultCode INT;
        EXEC dbo.ActualizarEmpleado @inNombre = ?, @inPuesto = ?, @inDocumentoIdentidad = ?, @inNombreActual = ?, @inDocumentoIdentidadActual = ?, @inIP = ?, @inUsuario = ?, @outResultCode = @outResultCode OUTPUT;
        SELECT @outResultCode;
        """
        params = (nombreNuevo, puestoNuevo, documentoNuevo, nombreActual, documentoActual, ip_usuario, usuario_logueado)
        codigo_resultado = cursor.execute(sql, params).fetchval()
        conn.commit() 

        if codigo_resultado == 0:
             return jsonify({"exito": True, "mensaje": "Empleado actualizado correctamente."})
        else:
            mensaje_error = obtener_descripcion_error(codigo_resultado)
            return jsonify({"exito": False, "mensaje": mensaje_error})

    except pyodbc.Error as ex:
        print(f"Error al actualizar empleado: {ex}")
        return jsonify({"exito": False, "mensaje": "Error en la base de datos al actualizar."}), 500
    finally:
        if 'conn' in locals():
            conn.close()

@app.route("/proyecto/tiposMovimiento/", methods=['GET']) # Endpoint nuevo
def TiposMovimiento():
    try:
        conn = pyodbc.connect(stringConexion)
        cursor = conn.cursor()     
        
        sql = """
        DECLARE @outResultCode INT;
        EXEC dbo.ObtenerTipoMovimiento @outResultCode = @outResultCode OUTPUT;
        SELECT @outResultCode;
        """
        #codigo_resultado = cursor.execute(sql).fetchval()
        cursor.execute(sql)
        filas = cursor.fetchall()
        headers = ["ID", "Movimiento", "Tipo"]
        listaMovimientos = []
        for fila in filas:
            filaLista = dict(zip(headers, fila))
            listaMovimientos.append(filaLista)
        return jsonify(listaMovimientos)

    except pyodbc.Error as ex:
        print(f"Error al cargar tipos de movimientos: {ex}")
        return jsonify({"exito": False, "mensaje": "Error en la base de datos al cargar tipos de movimientos."}), 500
    finally:
        if 'conn' in locals():
            conn.close()

@app.route("/proyecto/insertarMovimiento/", methods=['POST']) # Endpoint nuevo
def insertar_movimiento():
    
    datos_movimiento = request.get_json()
    documentoIdentidad = datos_movimiento.get('documentoIdentidad')
    tipoMovimiento = datos_movimiento.get('tipoMovimiento')
    monto = datos_movimiento.get('monto')
    usuario_logueado = datos_movimiento.get('usuario')
    ip_usuario = datos_movimiento.get('ip')

    try:
        conn = pyodbc.connect(stringConexion)
        cursor = conn.cursor()     
        
        sql = """
        DECLARE @outResultCode INT;
        EXEC dbo.InsertarMovimiento @inDocumentoIdentidad = ?, @inIdTipoMovimiento = ?, @inMonto = ?, @inIP = ?, @inUsuario = ?, @outResultCode = @outResultCode OUTPUT;
        SELECT @outResultCode;
        """
        params = (documentoIdentidad, tipoMovimiento, monto, ip_usuario, usuario_logueado)
        print(params)
        
        codigo_resultado = cursor.execute(sql, params).fetchval()
        conn.commit() 

        if codigo_resultado == 0:
             return jsonify({"exito": True, "mensaje": "Movimiento insertado correctamente."})
        else:
            mensaje_error = obtener_descripcion_error(codigo_resultado)
            return jsonify({"exito": False, "mensaje": mensaje_error})

    except pyodbc.Error as ex:
        print(f"Error al insertar movimiento: {ex}")
        return jsonify({"exito": False, "mensaje": "Error en la base de datos al insertar."}), 500
    finally:
        if 'conn' in locals():
            conn.close()

@app.route("/proyecto/movimientos", methods=['GET']) # Endpoint nuevo
def listar_movimientos():
    try:
        documentoIdentidad = request.args.get('documentoIdentidad')
        usuario_logueado = request.args.get('usuario')
        ip = request.args.get('ip')

        if not documentoIdentidad or not usuario_logueado or not ip:
            return jsonify({"error": "Faltan parámetros en la solicitud"}), 400

        conexion = pyodbc.connect(stringConexion)
        cursor = conexion.cursor()
        sql = """
        DECLARE @outResultCode INT;
        EXEC dbo.ListarMovimientosPorEmpleado @inDocumentoIdentidad = ?, @inIP = ?, @inUsuario = ?, @outResultCode = @outResultCode OUTPUT;
        SELECT @outResultCode;
        """
        parametros = (documentoIdentidad, usuario_logueado, ip)
        cursor.execute(sql, parametros)
        filas = cursor.fetchall()
        headers = ["Fecha", "TipoMovimiento", "Monto", "NuevoSaldo", "Usuario", "IP", "PostTime"]
        listaMovimientos = []
        for fila in filas:
            filaLista = dict(zip(headers, fila))
            listaMovimientos.append(filaLista)
        return jsonify(listaMovimientos)
        
    except pyodbc.Error as ex:
        sqlstate = ex.args[0]
        print(f"Error: {sqlstate}")
    finally:
        if 'cursor' in locals():
            cursor.close()
        if 'conexion' in locals():
            conexion.close()
    return jsonify({"error": "Error al obtener los movimientos"})



app.run(host="0.0.0.0", port=5000, debug=True)
