-- TODO: adaptar este script para cargar de xml: andrés
-- VALIDAR en frontend si entrada es nombre o cédula: andrés
-- seleccionar empleado: frontend
-- insertar movimiento: andrés
-- listar movimientos: andrés
-- saldos: andrés
-- backend: elías


SET NOCOUNT ON;

BEGIN TRY
    
    DECLARE @xmlData XML;

    SELECT @xmlData = X
    FROM OPENROWSET(
        BULK 'C:/Users/Elias/projs/Tarea2BasesDatos/archivoDatos.xml', -- <-- Esto es una ruta relativa, cambiar en caso de ser necesario
        SINGLE_BLOB
    ) AS T(X);

    PRINT 'Archivo XML cargado en memoria. Iniciando inserción de datos...';

    PRINT 'Poblando catálogos...';


    INSERT INTO dbo.Puesto (ID, Nombre, SalarioxHora)
    SELECT
        ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS ID, -- Genera un ID secuencial, xq no es identity
        Puesto.value('@Nombre', 'VARCHAR(32)') AS Nombre,
        Puesto.value('@SalarioxHora', 'MONEY') AS SalarioxHora
    FROM
        @xmlData.nodes('/Datos/Puestos/Puesto') AS T(Puesto);


    -- Usando IDENTITY_INSERT porque la tabla lo requiere pero el XML trae los IDs)
    SET IDENTITY_INSERT dbo.TipoEvento ON;
    INSERT INTO dbo.TipoEvento (ID, Nombre)
    SELECT
        TipoEvento.value('@Id', 'INT') AS Id,
        TipoEvento.value('@Nombre', 'VARCHAR(64)') AS Nombre
    FROM
        @xmlData.nodes('/Datos/TiposEvento/TipoEvento') AS T(TipoEvento);
    SET IDENTITY_INSERT dbo.TipoEvento OFF;

    -- Cargar Tipos de Movimiento
    -- Se trunca TipoAccion a 2 caracteres ('Cr'/'De') para que quepa en varchar(2)
    INSERT INTO dbo.TipoMovimiento (ID, Nombre, TipoAccion)
    SELECT
        TipoMovimiento.value('@Id', 'INT') AS Id,
        TipoMovimiento.value('@Nombre', 'VARCHAR(16)') AS Nombre,
        LEFT(TipoMovimiento.value('@TipoAccion', 'VARCHAR(10)'), 2) AS TipoAccion -- Trunca 'Credito' a 'Cr'
    FROM
        @xmlData.nodes('/Datos/TiposMovimientos/TipoMovimiento') AS T(TipoMovimiento);

    -- Cargar Usuarios
    INSERT INTO dbo.Usuario (ID, UserName, Password)
    SELECT
        Usuario.value('@Id', 'INT') AS Id,
        Usuario.value('@Nombre', 'VARCHAR(32)') AS Username,
        Usuario.value('@Pass', 'VARCHAR(256)') AS Password
    FROM
        @xmlData.nodes('/Datos/Usuarios/usuario') AS T(Usuario);

    -- Cargar Catálogo de Errores
    INSERT INTO dbo.Error (ID, Codigo, Descripcion)
    SELECT
        Error.value('@Id', 'INT') AS Id,
        Error.value('@Codigo', 'INT') AS Codigo,
        Error.value('@Descripcion', 'VARCHAR(128)') AS Descripcion
    FROM
        @xmlData.nodes('/Datos/Error/errorCodigo') AS T(Error);
    
    PRINT 'Catálogos poblados exitosamente.';

    --
    -- 2. Cargar Empleados
    --
    PRINT 'Poblando tabla Empleado...';

    INSERT INTO dbo.Empleado (ID, IDPuesto, ValorDocumentoIdentidad, Nombre, FechaContratacion, SaldoVacaciones, EsActivo)
    SELECT
        ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS ID, -- Genera un ID secuencial, xq no es identity
        p.ID AS IDPuesto,
        Empleado.value('@ValorDocumentoIdentidad', 'VARCHAR(32)') AS ValorDocumentoIdentidad,
        Empleado.value('@Nombre', 'VARCHAR(64)') AS Nombre,
        Empleado.value('@FechaContratacion', 'DATE') AS FechaContratacion,
        0 AS SaldoVacaciones, -- El saldo inicial es 0 
        1 AS EsActivo -- Se asume que todos los empleados cargados están activos
    FROM
        @xmlData.nodes('/Datos/Empleados/empleado') AS T(Empleado)
    INNER JOIN
        dbo.Puesto AS p ON T.Empleado.value('@Puesto', 'VARCHAR(100)') = p.Nombre;

    PRINT 'Tabla Empleado poblada exitosamente.';

    --
    -- 3. Cargar Movimientos 
    --
    PRINT 'Poblando tabla Movimiento...';
    
    DECLARE @outResultCode INT;

    DECLARE @documentoIdentidad VARCHAR(32);
    DECLARE @idTipoMovimiento   INT;
    DECLARE @monto              INT;
    DECLARE @ip                 VARCHAR(32);
    DECLARE @usuario            VARCHAR(32);

    DECLARE @contador INT = 1;
    DECLARE @totalMovimientos INT;

    SELECT @totalMovimientos = @xmlData.value('count(/Datos/Movimientos/movimiento)', 'INT');

    WHILE @contador <= @totalMovimientos
    BEGIN
        SELECT
            @documentoIdentidad = T.Movimiento.value('@ValorDocId', 'VARCHAR(50)')
            , @idTipoMovimiento = T.Movimiento.value('@IdTipoMovimiento', 'INT')
            , @monto = T.Movimiento.value('@Monto', 'INT')
            , @ip = T.Movimiento.value('@PostInIP', 'VARCHAR(32)')
            , @usuario = T.Movimiento.value('@PostByUser', 'VARCHAR(32)')
        FROM @xmlData.nodes('/Datos/Movimientos/movimiento[sql:variable("@contador")]') AS T(Movimiento);

        EXEC [dbo].[InsertarMovimiento]
            @inDocumentoIdentidad = @documentoIdentidad
            , @inIdTipoMovimiento = @idTipoMovimiento
            , @inMonto = @monto
            , @inIP = @ip
            , @inUsuario = @usuario
            , @outResultCode = @outResultCode OUTPUT;

        IF @outResultCode <> 0
        BEGIN
            PRINT 'Error al insertar movimiento: ' + CAST(@outResultCode AS VARCHAR(10)) + 
                ' - Documento: ' + @documentoIdentidad;
        END

        SET @contador = @contador + 1;
    END

    PRINT 'Tabla Movimiento poblada exitosamente.';

END TRY
BEGIN CATCH
    PRINT '¡ERROR! Ocurrió un problema durante la carga de datos.';
    PRINT 'Error Número: ' + CAST(ERROR_NUMBER() AS VARCHAR);
    PRINT 'Error Mensaje: ' + ERROR_MESSAGE();
    PRINT 'Error Línea: ' + CAST(ERROR_LINE() AS VARCHAR);
END CATCH

SET NOCOUNT OFF;
GO