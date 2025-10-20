function iniciarSesion() {
    const usuario = document.getElementById('username').value;
    const contrasena = document.getElementById('password').value;
    const mensajeError = document.getElementById('error-mensaje');

    if (!usuario || !contrasena) {
        mensajeError.textContent = 'Por favor, ingrese usuario y contraseña.';
        return;
    }

    fetch(`http://25.38.209.9:5000/proyecto/login/`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ usuario, contrasena }),
        credentials: 'include'
    })
    .then(response => {
        if (!response.ok) {
            // Manejar errores del servidor
            throw new Error('Respuesta del servidor no fue exitosa.');
        }
        return response.json();
    })
    .then(data => {
        if (data.autenticado) {
            sessionStorage.setItem('usuario', usuario);
            sessionStorage.setItem('ip', data.ip); // Traemos la ip desde el backend una vez se ha autenticado el usuario, esto porque en el backend no mantiene sesion activa
            window.location.href = 'index.html';
        } else {
            mensajeError.textContent = data.mensaje;
        }
    })
    .catch(error => {
        mensajeError.textContent = 'No se pudo conectar con el servidor.';
        console.error('Error en el login:', error);
    });
}
