document.addEventListener('DOMContentLoaded', () => {
    // --- Endpoint Requerido en Backend ---
    // Se necesita un endpoint GET /puestos para obtener la lista de puestos
    fetch(`http://LOCALHOST:5000/proyecto/puestos`)
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
    let nombreEmpleado = document.getElementById('name').value;
    let documentoIdentidad = document.getElementById('docIdentidad').value.toString();
    let puesto = parseInt(document.getElementById('puestos-dropdown').value)
    const regexNombre = /[^áÁéÉíÍóÓúÚüÜñÑa-zA-Z\s-]/i; // valida que no tenga números ni caracteres especiales
    if (regexNombre.test(nombreEmpleado)) {
        alert("Por favor ingrese solo letras, espacios y guiones en el nombre de empleado.");
        return;
    }
    const regexSalario = /^\d*\.?\d*$/i; // valida que sea número
    if (!regexSalario.test(salarioEmpleado) || isNaN(salarioEmpleado) || salarioEmpleado <= 0) {
        alert("Por favor ingrese un salario válido (número positivo).");
        return;
    }


    fetch(`http://LOCALHOST:5000/proyecto/insert/${nombreEmpleado}/${puesto}/${documentoIdentidad}`)
        .then(response => response.json())
        .then(data => {
            if (data[0].Codigo == 200) {
                alert(`Empleado ${nombreEmpleado} con el salario ${parseFloat(salarioEmpleado).toFixed(2).toString()} insertado correctamente.`);
            } else {
                alert(`Error al insertar el empleado: ${data[0].Mensaje}`);
            }
            console.log(data[0]);
            document.getElementById('name').value = '';
            document.getElementById('salary').value = '';
        })
}

function volverAPrincipal() {
    window.location.href = 'index.html';
}