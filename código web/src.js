fetch(`http://25.42.57.218:5000/proyecto/selectTodos`)
    .then(response => response.json())
    .then(data => {
        const tabla = document.getElementById('empleados-tabla');
        tabla.innerHTML = '';
        data.forEach(empleado => {
            const fila = document.createElement('tr');
            fila.innerHTML = `
                <td>${empleado.ID}</td>
                <td>${empleado.Nombre}</td>
                <td>${empleado.Salario}</td>
            `;
            tabla.appendChild(fila);
        }); 
    })

function buscarEmpleado() {
    let filtro = document.getElementById('name').value.toLowerCase();
    if (filtro !== '') {
        fetch(`http://25.38.209.9:5000/proyecto/select/${filtro}`)
        .then(response => response.json())
        .then(data => {
            const tabla = document.getElementById('empleados-tabla');
            tabla.innerHTML = '';
            data.sort((a, b) => {
                const nombreA = a.Nombre;
                const nombreB = b.Nombre;
                if (nombreA < nombreB) return -1;
                if (nombreA > nombreB) return 1;
                return 0;
            } ); // ordenar por nombre
            data.forEach(empleado => {
                const fila = document.createElement('tr');
                fila.innerHTML = `
                    <td>${empleado.ID}</td>
                    <td>${empleado.Nombre}</td>
                    <td>${empleado.Salario}</td>
                `;
                tabla.appendChild(fila);
            }); 
        })
    } else { // si el filtro está vacío carga todos los empleados
        fetch(`http://25.38.209.9:5000/proyecto/selectTodos`)
        .then(response => response.json())
        .then(data => {
            const tabla = document.getElementById('empleados-tabla');
            tabla.innerHTML = '';
            data.sort((a, b) => {
                const nombreA = a.Nombre;
                const nombreB = b.Nombre;
                if (nombreA < nombreB) return -1;
                if (nombreA > nombreB) return 1;
                return 0;
            } ); // ordenar por nombre
            data.forEach(empleado => {
                const fila = document.createElement('tr');
                fila.innerHTML = `
                    <td>${empleado.ID}</td>
                    <td>${empleado.Nombre}</td>
                    <td>${empleado.Salario}</td>
                `;
                tabla.appendChild(fila);
            }); 
        })
    }
    
}   

function cargarInsertarEmpleado() {
    window.location.href = 'insertar.html';
}

