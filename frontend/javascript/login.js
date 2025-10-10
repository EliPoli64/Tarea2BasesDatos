function iniciarSesion() {
    const usuario = document.getElementById('username').value;
    const contrasena = document.getElementById('password').value;
    const mensajeError = document.getElementById('error-mensaje');

    if (!usuario || !contrasena) {
        mensajeError.textContent = 'Por favor, ingrese usuario y contraseña.';
        return;
    }

    fetch(`http://localhost:5000/proyecto/login`, {
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
            // Guardamos el usuario y redirigimos.
            // sessionStorage solo guarda el dato mientras la pestaña del navegador esté abierta.
            sessionStorage.setItem('usuario', usuario);
            window.location.href = 'index.html';
        } else {
            // El backend devolvió un mensaje de error
            mensajeError.textContent = data.mensaje || 'Usuario o contraseña incorrectos.';
        }
    })
    .catch(error => {
        mensajeError.textContent = 'No se pudo conectar con el servidor.';
        console.error('Error en el login:', error);
    });
}
