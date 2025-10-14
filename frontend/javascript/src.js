document.addEventListener('DOMContentLoaded', () => {
    const usuario = sessionStorage.getItem('usuario');
    
    if (!usuario) {
        window.location.href = 'login.html';
    }
    document.getElementById('user-display').textContent = `Usuario: ${usuario}`;
    cargarEmpleados();
});

function cargarEmpleados() {
    fetch(`http://LOCALHOST:5000/proyecto/selectTodos/`, {credentials: 'include'})
        .then(response => response.json())
        .then(data => {
            renderizarTabla(data);
        })
        .catch(error => console.error('Error al cargar empleados:', error));
}

function filtrarEmpleados() {
    const filtro = document.getElementById('filtro').value;
    const datosPeticion = {
        filtro: filtro,
        usuario: sessionStorage.getItem('usuario'),
        ip: sessionStorage.getItem('ip')
    };
    const queryParams = new URLSearchParams(datosPeticion).toString();

    fetch(`http://localhost:5000/proyecto/select?${queryParams}`, {
        method: 'GET',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include'
    })

    
    const url = filtro ? `http://LOCALHOST:5000/proyecto/select?${queryParams}` : `http://LOCALHOST:5000/proyecto/selectTodos/`;
    
    fetch(url, {credentials: 'include'})
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
        // El backend devuelve estos campos
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

function eliminarEmpleado(documentoIdentidad, nombreEmpleado) {
    if (confirm(`¿Está seguro de que desea eliminar a ${nombreEmpleado} con documento de identidad ${documentoIdentidad}?`)) {
        
        // Creamos un objeto con los datos del empleado a eliminar
        const datosEmpleadoEliminar = {
            nombre: nombreEmpleado,
            documento: documentoIdentidad,
            usuario: sessionStorage.getItem('usuario'),
            ip: sessionStorage.getItem('ip')
        };
        
        fetch(`http://LOCALHOST:5000/proyecto/eliminarEmpleado/`, { 
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(datosEmpleadoEliminar),
            credentials: 'include'
        })
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
    const datosUsuario = {
        usuario: sessionStorage.getItem('usuario'),
        ip: sessionStorage.getItem('ip')
    };

    fetch('http://localhost:5000/proyecto/logout/', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(datosUsuario),
        credentials: 'include'
    })
    .then(response => response.json())
    .then(data => {
        console.log(data.mensaje); 
    
        sessionStorage.removeItem('usuario');
        sessionStorage.removeItem('ip');
        
        window.location.href = 'login.html';
    })
    .catch(error => {
        console.error('Error al cerrar sesión:', error);
        
        window.location.href = 'login.html';
    });
}