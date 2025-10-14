document.addEventListener('DOMContentLoaded', () => {
    if (!sessionStorage.getItem('usuario')) {
        window.location.href = 'login.html';
        return;
    }

    const params = new URLSearchParams(window.location.search);
    const docIdentidad = params.get('doc');

    if (!docIdentidad) {
        alert("Documento de empleado no especificado.");
        window.location.href = 'index.html';
        return;
    }

    cargarDatosIniciales(docIdentidad);
});

function cargarDatosIniciales(docIdentidad) {
    const datosPeticion = {
        filtro: docIdentidad,
        usuario: sessionStorage.getItem('usuario'),
        ip: sessionStorage.getItem('ip')
    };
    const queryParams = new URLSearchParams(datosPeticion).toString();

    const empleadoPromise = fetch(`http://localhost:5000/proyecto/select?${queryParams}`, {
        method: 'GET',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include'
    })
    .then(res => res.json());

    const tiposMovimientoPromise = fetch(`http://localhost:5000/proyecto/tiposMovimiento/`, { credentials: 'include' })
        .then(res => res.json());

    Promise.all([empleadoPromise, tiposMovimientoPromise])
        .then(([empleado, tiposMovimiento]) => {
            if (empleado.error || tiposMovimiento.error) {
                alert("No se pudieron cargar los datos necesarios.");
                return;
            }

            document.getElementById('empleado-nombre').textContent = empleado[0].Nombre;
            document.getElementById('empleado-documento').textContent = empleado[0].ValorDocumentoIdentidad;
            document.getElementById('empleado-saldo').textContent = empleado[0].SaldoVacaciones;

            const dropdown = document.getElementById('tipos-movimiento-dropdown');
            tiposMovimiento.forEach(tipo => {
                const option = document.createElement('option');
                option.value = tipo.ID;

                option.textContent = (tipo.Tipo === 'Cr') ?  (tipo.Movimiento + " " + "(Crédito)") : (tipo.Movimiento + " " + "(Débito)");
                
                dropdown.appendChild(option);
            });
        })
        .catch(err => console.error("Error cargando datos:", err));
}

function guardarMovimiento() {
    const params = new URLSearchParams(window.location.search);
    const docIdentidad = params.get('doc');
    const tipoMovimiento = document.getElementById('tipos-movimiento-dropdown').value;
    const monto = document.getElementById('monto').value;

    if (!monto || parseFloat(monto) <= 0) {
        alert("Por favor, ingrese un monto válido y mayor a cero.");
        return;
    }

    const datosMovimiento = {
        documentoIdentidad: docIdentidad,
        tipoMovimiento: tipoMovimiento,
        monto: parseFloat(monto),
        usuario: sessionStorage.getItem('usuario'),
        ip: sessionStorage.getItem('ip')
    };

    fetch('http://localhost:5000/proyecto/insertarMovimiento/', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(datosMovimiento),
        credentials: 'include'
    })
    .then(response => response.json())
    .then(data => {
        alert(data.mensaje);
        if (data.exito) {
            // Regresa a la página de movimientos del empleado para ver el cambio
            window.location.href = `movimientos.html?doc=${docIdentidad}`;
        }
    })
    .catch(error => {
        console.error('Error al guardar movimiento:', error);
        alert('Error de conexión al guardar el movimiento.');
    });
}

function cancelar() {
    const params = new URLSearchParams(window.location.search);
    const docIdentidad = params.get('doc');
    window.location.href = `movimientos.html?doc=${docIdentidad}`;
}
