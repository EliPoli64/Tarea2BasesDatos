function insertarEmpleado() {
    let nombreEmpleado = document.getElementById('name').value;
    let salarioEmpleado = document.getElementById('salary').value.toString();
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
    fetch(`http://25.42.57.218:5000/proyecto/insert/${nombreEmpleado}/${parseFloat(salarioEmpleado).toFixed(2).toString()}`)
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

function volverPagPrincipal() {
    window.location.href = 'index.html';
}