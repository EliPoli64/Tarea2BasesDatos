document.addEventListener('DOMContentLoaded', () => {
    const usuario = sessionStorage.getItem('usuario');

    if (!usuario) {
        alert("No ha iniciado sesión. Será redirigido.");
        window.location.href = 'login.html';
        return;
    }

    fetch(`http://25.38.209.9:5000/proyecto/puestos/`, {credentials: 'include'})
        .then(response => response.json())
        .then(puestos => {
            const dropdown = document.getElementById('puestos-dropdown');
            puestos.forEach(puesto => {
                const option = document.createElement('option');
                option.value = puesto.nombre;
                option.textContent = puesto.nombre;
                dropdown.appendChild(option);
            });
    });
});

function insertarEmpleado() {
    const nombreEmpleado = document.getElementById('nombre').value;
    const documentoIdentidad = document.getElementById('docIdentidad').value;
    const puestoEmpleado = document.getElementById('puestos-dropdown').value;

    if (!/^[a-zA-Z\s-]+$/.test(nombreEmpleado)) {
        alert("Por favor ingrese solo letras, espacios y guiones en el nombre de empleado.");
        return;
    }
    if (!/^[0-9]+$/.test(documentoIdentidad)) {
        alert("El documento de identidad solo debe contener números.");
        return;
    }

    // Creamos un objeto con los datos del nuevo empleado
    const datosNuevoEmpleado = {
        nombre: nombreEmpleado,
        puesto: puestoEmpleado,
        documento: documentoIdentidad,
        usuario: sessionStorage.getItem('usuario'),
        ip: sessionStorage.getItem('ip')
    };

    
    fetch(`http://25.38.209.9:5000/proyecto/insertarEmpleado/`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(datosNuevoEmpleado),
        credentials: 'include'
    })
    .then(response => response.json())
    .then(data => {
        
        
        if (data.exito) {
            alert('Empleado insertado correctamente.');
            document.getElementById('nombre').value = '';
            document.getElementById('docIdentidad').value = '';
            window.location.href = 'index.html';
        }
    })
    .catch(error => {
        console.error('Error al insertar:', error);
        alert('Error de conexión al intentar insertar el empleado.');
    });
}
function volverAPrincipal() {
    window.location.href = 'index.html';
}