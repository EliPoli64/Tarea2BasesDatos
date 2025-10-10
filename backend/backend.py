from flask import Flask, jsonify, request, session
from flask_cors import CORS
import pyodbc

stringConexion = "DRIVER={ODBC Driver 17 for SQL Server};SERVER=LOCALHOST,1433;DATABASE=EmpleadosDB;UID=Remoto;PWD=1234;"

app = Flask(__name__)
CORS(app)

@app.route("/proyecto/select/<string:nombre>") # Endpoint corregido
def ejecutarSPSelect(nombre):
    try:
        conexion = pyodbc.connect(stringConexion)
        cursor = conexion.cursor()
        sql = "{CALL dbo.FiltrarEmpleados (?, ?)}"
        parametros = (nombre, 0)
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

@app.route("/proyecto/selectTodos") # Endpoint corregido
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

@app.route("/proyecto/puestos") # Endpoint nuevo
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

@app.route("/proyecto/login", methods=['POST']) # Endpoint nuevo
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
        sql = """"\
        DECLARE @outResultCode INT;
        EXEC dbo.VerificarLogin @inIP = ?, @inUsuario = ?, @inContrasenna = ?, @outResultCode = @outResultCode OUTPUT;
        SELECT @outResultCode;
        """""
        parametros = (ip_cliente, usuario, contrasena)
        
        codigo_resultado = cursor.execute(sql, parametros).fetchval()
        
        if codigo_resultado == 0:  # 0 significa éxito
            # Creamos la sesión del usuario
            session['usuario'] = usuario
            session['ip'] = ip_cliente
            return jsonify({"autenticado": True, "usuario": usuario})
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


app.run(host="0.0.0.0", port=5000, debug=True)