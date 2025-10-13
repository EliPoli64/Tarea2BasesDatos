document.addEventListener('DOMContentLoaded', () => {
    // Verifica que el usuario haya iniciado sesión
    const usuario = sessionStorage.getItem('usuario');
    if (!usuario) {
        window.location.href = 'login.html';
        return;
    }

    // Obtiene el documento de identidad del empleado desde la URL
    // Por ejemplo: movimientos.html?doc=56917772
    const params = new URLSearchParams(window.location.search);
    const docIdentidad = params.get('doc');

    if (!docIdentidad) {
        alert("No se especificó un empleado.");
        window.location.href = 'index.html';
        return;
    }

    // Llama a la función para cargar los datos
    cargarDatosMovimientos(docIdentidad);
});

function cargarDatosMovimientos(docIdentidad) {
    // Llama a un NUEVO endpoint en el backend que debes crear
    fetch(`http://localhost:5000/proyecto/movimientos/${docIdentidad}/`, {
        credentials: 'include'
    })
    .then(response => {
        if (response.status === 401) {
            window.location.href = 'login.html';
            return;
        }
        return response.json();
    })
    .then(data => {
        if (data.error) {
            alert(data.error);
            return;
        }

        // Rellena la información del empleado
        document.getElementById('empleado-nombre').textContent = data.empleado.Nombre;
        document.getElementById('empleado-documento').textContent = data.empleado.ValorDocumentoIdentidad;
        document.getElementById('empleado-saldo').textContent = data.empleado.SaldoVacaciones;

        // Rellena la tabla de movimientos
        const tabla = document.getElementById('movimientos-tabla');
        tabla.innerHTML = ''; // Limpia la tabla por si acaso

        if (data.movimientos.length === 0) {
            tabla.innerHTML = '<tr><td colspan="7">Este empleado no tiene movimientos registrados.</td></tr>';
            return;
        }
        
        // El requerimiento pide ordenar por fecha descendente
        data.movimientos.sort((a, b) => new Date(b.Fecha) - new Date(a.Fecha));

        data.movimientos.forEach(mov => {
            const fila = document.createElement('tr');
            fila.innerHTML = `
                <td>${new Date(mov.Fecha).toLocaleDateString()}</td>
                <td>${mov.TipoMovimiento}</td>
                <td>${mov.Monto}</td>
                <td>${mov.NuevoSaldo}</td>
                <td>${mov.Usuario}</td>
                <td>${mov.IP}</td>
                <td>${new Date(mov.PostTime).toLocaleString()}</td>
            `;
            tabla.appendChild(fila);
        });
    })
    .catch(error => console.error('Error al cargar los movimientos:', error));
}

function irAInsertarMovimiento() {
    const params = new URLSearchParams(window.location.search);
    const docIdentidad = params.get('doc');
    // Redirige a la página de insertar movimiento, pasando el documento del empleado
    window.location.href = `insertarMovimiento.html?doc=${docIdentidad}`;
}

function volverAPrincipal() {
    window.location.href = 'index.html';
}