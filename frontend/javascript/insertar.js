document.addEventListener('DOMContentLoaded', () => {
    const usuario = sessionStorage.getItem('usuario');
    if (!usuario) {
        alert("No ha iniciado sesión. Será redirigido.");
        window.location.href = 'login.html';
        return;
    }

    fetch(`http://LOCALHOST:5000/proyecto/puestos/`, {credentials: 'include'})
        .then(response => response.json())
        .then(puestos => {
            const dropdown = document.getElementById('puestos-dropdown');
            puestos.forEach(puesto => {
                const option = document.createElement('option');
                option.value = puesto.Nombre;
                option.textContent = puesto.Nombre;
                dropdown.appendChild(option);
            });
    });
});





function insertarEmpleado() {
    const nombreEmpleado = document.getElementById('nombre').value;
    const documentoIdentidad = document.getElementById('docIdentidad').value;
    const puestoEmpleado = document.getElementById('puestos-dropdown').value;

    // Validaciones (tu código de regex estaba bien)
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
        documento: documentoIdentidad
    };

    
    fetch(`http://localhost:5000/proyecto/insertarEmpleado/`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(datosNuevoEmpleado),
        credentials: 'include'
    })
    .then(response => response.json())
    .then(data => {
        
        alert(data.mensaje);
        
        if (data.exito) {
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