// Variables globales para guardar los datos originales del empleado
let docOriginal = null;
let nombreOriginal = null;

document.addEventListener('DOMContentLoaded', () => {
    if (!sessionStorage.getItem('usuario')) {
        window.location.href = 'login.html';
        return;
    }

    const params = new URLSearchParams(window.location.search);
    docOriginal = params.get('doc');

    if (!docOriginal) {
        alert("No se especificó un empleado.");
        window.location.href = 'index.html';
        return;
    }

    cargarPuestosYEmpleado();
});

function cargarPuestosYEmpleado() {
    // Cargar la lista de todos los puestos
    const puestosPromise = fetch('http://25.38.209.9:5000/proyecto/puestos/', { credentials: 'include' })
        .then(res => res.json());

    // Cargar los datos del empleado actual
    const datosPeticion = {
        filtro: docOriginal,
        usuario: sessionStorage.getItem('usuario'),
        ip: sessionStorage.getItem('ip')
    };
    const queryParams = new URLSearchParams(datosPeticion).toString();

    
    const empleadoPromise = fetch(`http://25.38.209.9:5000/proyecto/select?${queryParams}`, {
        method: 'GET',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include'
    })
    .then(res => res.json());

    // Cuando ambas promesas se completen, poblar el formulario
    Promise.all([puestosPromise, empleadoPromise])
        .then(([puestos, empleado]) => {
            if (puestos.error || empleado.error) {
                alert("No se pudieron cargar los datos.");
                return;
            }

            // Poblar el dropdown de puestos
            const dropdown = document.getElementById('puestos-dropdown');
            puestos.forEach(puesto => {
                const option = document.createElement('option');
                option.value = puesto.nombre;
                option.textContent = puesto.nombre;
                dropdown.appendChild(option);
            });

            // Poblar los campos del formulario con los datos del empleado
            document.getElementById('nombre').value = empleado[0].Nombre;
            document.getElementById('docIdentidad').value = empleado[0].ValorDocumentoIdentidad;
            document.getElementById('saldo').value = empleado[0].SaldoVacaciones;
            dropdown.value = empleado[0].Puesto; // Seleccionar el puesto actual

            // Guardar el nombre original para la llamada al SP
            nombreOriginal = empleado[0].Nombre;
        })
        .catch(err => console.error("Error cargando datos para actualizar:", err));
}

function guardarCambios() {
    const nombreNuevo = document.getElementById('nombre').value;
    const docNuevo = document.getElementById('docIdentidad').value;
    const puestoNuevo = document.getElementById('puestos-dropdown').value;

    const datosActualizados = {
        nombreActual: nombreOriginal,
        documentoActual: docOriginal,
        nombreNuevo: nombreNuevo,
        documentoNuevo: docNuevo,
        puestoNuevo: puestoNuevo,
        usuario: sessionStorage.getItem('usuario'),
        ip: sessionStorage.getItem('ip')
    };

    fetch('http://25.38.209.9:5000/proyecto/actualizarEmpleado/', {
        method: 'PUT', // Usamos PUT para actualizaciones
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(datosActualizados),
        credentials: 'include'
    })
    .then(response => response.json())
    .then(data => {
        alert(data.mensaje);
        if (data.exito) {
            window.location.href = 'index.html';
        }
    })
    .catch(error => {
        console.error('Error al actualizar:', error);
        alert('Error de conexión al intentar actualizar el empleado.');
    });
}

function volverAPrincipal() {
    window.location.href = 'index.html';
}
