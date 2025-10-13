document.addEventListener('DOMContentLoaded', () => {
    // Verifica si el usuario ha iniciado sesión
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

    // Llama a un nuevo endpoint para obtener los datos de un solo empleado
    fetch(`http://localhost:5000/proyecto/empleado/${docIdentidad}/`, {
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
            document.getElementById('empleado-nombre').textContent = data.Nombre;
            document.getElementById('empleado-documento').textContent = data.ValorDocumentoIdentidad;
            document.getElementById('empleado-puesto').textContent = data.Puesto;
            document.getElementById('empleado-saldo').textContent = data.SaldoVacaciones;
        }
    })
    .catch(error => console.error('Error al cargar detalle del empleado:', error));
});

function volverAPrincipal() {
    window.location.href = 'index.html';
}
