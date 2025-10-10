document.addEventListener('DOMContentLoaded', () => {
    const usuario = sessionStorage.getItem('usuario');
    
    if (!usuario) {
        window.location.href = 'login.html'; // Si no hay sesión, volver al login
    }
    document.getElementById('user-display').textContent = `Usuario: ${usuario}`;

    cargarEmpleados();
});

function cargarEmpleados() {
    // Endpoint existente en backend.py
    fetch(`http://LOCALHOST:5000/proyecto/selectTodos`)
        .then(response => response.json())
        .then(data => {
            renderizarTabla(data);
        })
        .catch(error => console.error('Error al cargar empleados:', error));
}

function filtrarEmpleados() {
    const filtro = document.getElementById('filtro').value;
    const url = filtro ? `http://LOCALHOST:5000/proyecto/select/${filtro}` : `http://LOCALHOST:5000/proyecto/selectTodos`;
    
    fetch(url)
        .then(response => response.json())
        .then(data => {
            renderizarTabla(data);
        })
        .catch(error => console.error('Error al filtrar:', error));
}

function renderizarTabla(empleados) {
    const tabla = document.getElementById('empleados-tabla');
    tabla.innerHTML = '';
    empleados.forEach(emp => {
        const fila = document.createElement('tr');
        // Se asume que el backend devolverá estos campos
        fila.innerHTML = `
            <td>${emp.Nombre}</td>
            <td>${emp.ValorDocumentoIdentidad}</td>
            <td>${emp.Puesto}</td>
            <td class="acciones">
                <button onclick="consultarEmpleado('${emp.ValorDocumentoIdentidad}')">Consultar</button>
                <button onclick="editarEmpleado('${emp.ValorDocumentoIdentidad}')">Actualizar</button>
                <button class="delete-btn" onclick="eliminarEmpleado('${emp.ValorDocumentoIdentidad}', '${emp.Nombre}')">Eliminar</button>
                <button onclick="verMovimientos('${emp.ValorDocumentoIdentidad}')">Movimientos</button>
            </td>
        `;
        tabla.appendChild(fila);
    });
}

function eliminarEmpleado(docIdentidad, nombre) {
    // Requerimiento R4: Alerta de confirmación [cite: 42]
    if (confirm(`¿Está seguro de que desea eliminar a ${nombre}?`)) {
        // --- Endpoint Requerido en Backend ---
        // Se necesita un endpoint DELETE /empleado/eliminar/{docIdentidad}
        fetch(`http://LOCALHOST:5000/proyecto/eliminar/${docIdentidad}`, { method: 'DELETE' })
        .then(response => response.json())
        .then(data => {
            if (data.exito) {
                alert('Empleado eliminado correctamente.');
                cargarEmpleados(); // Recargar la lista
            } else {
                alert(`Error: ${data.mensaje}`);
            }
        });
    }
}

// Funciones de navegación
function irAInsertarEmpleado() { window.location.href = 'insertar.html'; }
function consultarEmpleado(doc) { window.location.href = `detalle.html?doc=${doc}`; }
function editarEmpleado(doc) { window.location.href = `actualizar.html?doc=${doc}`; }
function verMovimientos(doc) { window.location.href = `movimientos.html?doc=${doc}`; }

function cerrarSesion() {
    sessionStorage.removeItem('usuario');
    window.location.href = 'login.html';
    // Llamar a un SP para registrar el logout, está en los requerimientos del programa
}