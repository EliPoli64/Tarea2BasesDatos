document.addEventListener('DOMContentLoaded', () => {
    if (!sessionStorage.getItem('usuario')) {
        window.location.href = 'login.html';
        return;
    }

    const params = new URLSearchParams(window.location.search);
    const docIdentidad = params.get('doc');

    if (!docIdentidad) {
        alert("No se especificó un empleado.");
        window.location.href = 'index.html';
        return;
    }
    
    cargarInfoEmpleado(docIdentidad);
    cargarListaMovimientos(docIdentidad);
});


function cargarInfoEmpleado(docIdentidad) {
    fetch(`http://localhost:5000/proyecto/select/${docIdentidad}/`, {
        credentials: 'include'
    })
    .then(response => {
        if (response.status === 401) { window.location.href = 'login.html'; }
        return response.json();
    })
    .then(empleado => {
        if (empleado.error) {
            alert(empleado.error);
        } else {
            document.getElementById('empleado-nombre').textContent = empleado[0].Nombre;
            document.getElementById('empleado-documento').textContent = empleado[0].ValorDocumentoIdentidad;
            document.getElementById('empleado-saldo').textContent = empleado[0].SaldoVacaciones;
        }
    })
    .catch(error => console.error('Error al cargar info del empleado:', error));
}



function cargarListaMovimientos(docIdentidad) {
    
    const datosPeticion = {
        documentoIdentidad: docIdentidad,
        usuario: sessionStorage.getItem('usuario'),
        ip: sessionStorage.getItem('ip')
    };
    const queryParams = new URLSearchParams(datosPeticion).toString();

    fetch(`http://localhost:5000/proyecto/movimientos?${queryParams}`, {
        method: 'GET',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include'
    })
    .then(response => {
        if (response.status === 401) { window.location.href = 'login.html'; }
        return response.json();
    })
    .then(movimientos => {
        const tabla = document.getElementById('movimientos-tabla');
        tabla.innerHTML = '';

        if (movimientos.error) {
            alert(movimientos.error);
            tabla.innerHTML = `<tr><td colspan="7">${movimientos.error}</td></tr>`;
            return;
        }

        if (movimientos.length === 0) {
            tabla.innerHTML = '<tr><td colspan="7">Este empleado no tiene movimientos registrados.</td></tr>';
            return;
        }
        
        
        movimientos.forEach(mov => {
            const fila = document.createElement('tr');

            const fechaFormateada = new Date(mov.Fecha).toLocaleDateString();
            const montoFormateado = parseFloat(mov.Monto).toFixed(2);

            const nuevoSaldoFormateado = mov.NuevoSaldo ? parseFloat(mov.NuevoSaldo).toFixed(2) : 'N/A';
            const horaFormateada = new Date(mov.PostTime).toLocaleString();


            fila.innerHTML = `
                <td>${fechaFormateada}</td>
                <td>${mov.TipoMovimiento}</td>
                <td>${montoFormateado}</td>
                <td>${mov.NuevoSaldo}</td>
                <td>${mov.Usuario}</td>
                <td>${mov.IP}</td>
                <td>${horaFormateada}</td>
            `;
            tabla.appendChild(fila);
        });
    })
    .catch(error => console.error('Error al cargar la lista de movimientos:', error));
}

function irAInsertarMovimiento() {
    const params = new URLSearchParams(window.location.search);
    const docIdentidad = params.get('doc');
    window.location.href = `insertarMovimiento.html?doc=${docIdentidad}`;
}

function volverAPrincipal() {
    window.location.href = 'index.html';
}