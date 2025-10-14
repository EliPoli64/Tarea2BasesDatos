CREATE OR ALTER PROCEDURE dbo.InsertarMovimiento
    @inDocumentoIdentidad   VARCHAR(32)
    , @inIdTipoMovimiento     INT
    , @inMonto              MONEY
    , @inIP                 VARCHAR(32)
    , @inUsuario            VARCHAR(32)
    , @outResultCode        INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    SET @outResultCode = 0;
    DECLARE @bitacoraResultCode INT;
    DECLARE @descBitacora VARCHAR(256);

    -- Pre-proceso: Obtener IDs y datos necesarios antes de la transacción
    DECLARE @empleadoID INT;
    DECLARE @saldoActual MONEY;
    DECLARE @nombreEmpleado VARCHAR(64);
    
    SELECT 
        @empleadoID = E.ID
        , @saldoActual = E.SaldoVacaciones
        , @nombreEmpleado = E.Nombre
    FROM 
        dbo.Empleado E
    WHERE 
        (E.ValorDocumentoIdentidad = @inDocumentoIdentidad);

    DECLARE @tipoAccion VARCHAR(2);
    DECLARE @nombreMovimiento VARCHAR(16);

    SELECT 
        @tipoAccion = TM.TipoAccion
        , @nombreMovimiento = TM.Nombre
    FROM 
        dbo.TipoMovimiento TM
    WHERE 
        (TM.ID = @inIdTipoMovimiento);

    -- Calcular el nuevo saldo proyectado
    DECLARE @nuevoSaldo MONEY = @saldoActual;
    IF (@tipoAccion = 'Cr')
        SET @nuevoSaldo = @saldoActual + @inMonto;
    ELSE IF (@tipoAccion = 'De')
        SET @nuevoSaldo = @saldoActual - @inMonto;


    IF (@nuevoSaldo < 0)
    BEGIN
        SET @descBitacora = CONCAT(
            'Saldo negativo. Empleado: ', @inDocumentoIdentidad, ', ', @nombreEmpleado,
            '. Saldo actual: ', CAST(@saldoActual AS VARCHAR), 
            '. Movimiento: ', @nombreMovimiento, ', Monto: ', CAST(@inMonto AS VARCHAR)
        );
        EXEC dbo.InsertarBitacora @inIP, @inUsuario, @descBitacora, 13, @bitacoraResultCode OUTPUT; -- Evento: Intento de insertar movimiento
        SET @outResultCode = 50011; -- Monto del movimiento rechazado
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;
            -- Insertar el nuevo movimiento
            INSERT INTO dbo.Movimiento (
                [ID] 
                , [IDEmpleado] 
                , [IDTipoMovimiento] 
                , [IDPostByUser] 
                , [Fecha] 
                , [PostInIP] 
                , [Descripcion] 
                , [Monto] 
                , [PostTime]
            ) VALUES (
                (SELECT ISNULL(MAX(ID), 0) + 1 FROM dbo.Movimiento) 
                , @empleadoID 
                , @inIdTipoMovimiento 
                , (SELECT ID FROM dbo.Usuario WHERE UserName = @inUsuario)
                , GETDATE()
                , @inIP
                , 'Registro de movimiento manual' -- Descripción genérica
                , @inMonto
                , GETDATE()
            );

            -- Actualizar el saldo de vacaciones del empleado
            UPDATE dbo.Empleado
            SET SaldoVacaciones = @nuevoSaldo
            WHERE ID = @empleadoID;

            -- Registrar en bitácora de éxito
            SET @descBitacora = CONCAT(
                'Empleado: ', @inDocumentoIdentidad, ', ', @nombreEmpleado, 
                '. Nuevo Saldo: ', CAST(@nuevoSaldo AS VARCHAR), 
                '. Movimiento: ', @nombreMovimiento, ', Monto: ', CAST(@inMonto AS VARCHAR)
            );
            EXEC dbo.InsertarBitacora @inIP, @inUsuario, @descBitacora, 14, @bitacoraResultCode OUTPUT; -- Evento: Insertar movimiento exitoso

            IF (@bitacoraResultCode <> 0)
            BEGIN
                ROLLBACK TRANSACTION;
                SET @outResultCode = @bitacoraResultCode;
                RETURN;
            END

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF (@@TRANCOUNT > 0)
            ROLLBACK TRANSACTION;

        INSERT INTO dbo.DBError (
            [ID] -- Columna ID añadida
            , [UserName] 
            , [Number] 
            , [State] 
            , [Severity] 
            , [Line] 
            , [Procedure] 
            , [Message] 
            , [DateTime]
        ) VALUES (
            (SELECT ISNULL(MAX(ID), 0) + 1 FROM dbo.DBError)
            , SUSER_SNAME() 
            , ERROR_NUMBER() 
            , ERROR_STATE() 
            , ERROR_SEVERITY() 
            , ERROR_LINE()
            , ERROR_PROCEDURE() 
            , ERROR_MESSAGE()
            , GETDATE()
        );
        SET @outResultCode = 50008;
    END CATCH;

    SET NOCOUNT OFF;
END;
GO