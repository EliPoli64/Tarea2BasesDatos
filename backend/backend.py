from flask import Flask, jsonify
from flask_cors import CORS
import pyodbc

stringConexion = "DRIVER={ODBC Driver 17 for SQL Server};SERVER=25.42.57.218,1433;DATABASE=EmpleadosDB;UID=Remoto;PWD=1234;"

app = Flask(__name__)
CORS(app)

@app.route("/proyecto/select/<string:nombre>")
def ejecutarSPSelect(nombre):
    try:
        conexion = pyodbc.connect(stringConexion)
        cursor = conexion.cursor()
        cursor.execute("EXEC dbo.sp_FiltrarEmpleados @infiltro = ?", nombre)
        filas = cursor.fetchall()
        headers = ["ID", "Nombre", "Salario"]
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

@app.route("/proyecto/selectTodos")
def ejecutarSPSelectTodos():
    try:
        conexion = pyodbc.connect(stringConexion)
        cursor = conexion.cursor()
        cursor.execute("EXEC dbo.sp_FiltrarEmpleados @infiltro = '%'")
        filas = cursor.fetchall()
        conexion.commit() 
        headers = ["ID", "Nombre", "Salario"]
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

@app.route("/proyecto/insert/<string:nombre>/<float:salario>")
def ejecutarSPInsert(nombre, salario):
    conexion = None
    cursor = None
    try:
        conexion = pyodbc.connect(stringConexion, autocommit=False)
        cursor = conexion.cursor()
        cursor.execute("EXEC dbo.sp_InsertarEmpleado @innombre = ?, @insalario = ?", nombre, salario)
        filas = cursor.fetchall()
        conexion.commit() 
        
        headers = ["Codigo", "Mensaje"]
        mensaje = []
        for fila in filas:
            filaLista = dict(zip(headers, fila))
            mensaje.append(filaLista)
        
        print(mensaje)
        return jsonify(mensaje)
    
    except pyodbc.Error as ex:
        if conexion:
            conexion.rollback()
        sqlstate = ex.args[0]
        print(f"Error: {sqlstate}")
        return jsonify({"Error": f"Error del servidor: {sqlstate}"}) 
        
    finally:
        if cursor:
            cursor.close()
        if conexion:
            conexion.close()

app.run(host="0.0.0.0", port=5000, debug=True)