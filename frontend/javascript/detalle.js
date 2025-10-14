document.addEventListener('DOMContentLoaded', () => {
    if (!sessionStorage.getItem('usuario')) {
        window.location.href = 'login.html';
        return;
    }

    // Obtiene el documento de identidad del empleado desde la URL
    const params = new URLSearchParams(window.location.search);
    const docIdentidad = params.get('doc');

    if (!docIdentidad) {
        alert("No se especificó un empleado.");
        window.location.href = 'index.html';
        return;
    }

    const datosPeticion = {
        filtro: docIdentidad,
        usuario: sessionStorage.getItem('usuario'),
        ip: sessionStorage.getItem('ip')
    };
    const queryParams = new URLSearchParams(datosPeticion).toString();

    fetch(`http://localhost:5000/proyecto/select?${queryParams}`, {
        method: 'GET',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include'
    })
    .then(response => {
        if (response.status === 401) { window.location.href = 'login.html'; }
        return response.json();
    })
    .then(data => {
        if (data.error) {
            alert(data.error);
            window.location.href = 'index.html';
        } else {
            console.log(data.Nombre)
            console.log(data.ValorDocumentoIdentidad)
            console.log(data.Puesto)
            console.log(data.SaldoVacaciones)
            document.getElementById('empleado-nombre').textContent = data[0].Nombre;
            document.getElementById('empleado-documento').textContent = data[0].ValorDocumentoIdentidad;
            document.getElementById('empleado-puesto').textContent = data[0].Puesto;
            document.getElementById('empleado-saldo').textContent = data[0].SaldoVacaciones;
        }
    })
    .catch(error => console.error('Error al cargar detalle del empleado:', error));
});

function volverAPrincipal() {
    window.location.href = 'index.html';
}
