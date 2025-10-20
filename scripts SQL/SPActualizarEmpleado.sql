CREATE OR ALTER PROCEDURE [dbo].[ActualizarEmpleado]
    @inNombre                       VARCHAR(64)
    , @inPuesto                     VARCHAR(32)
    , @inDocumentoIdentidad         VARCHAR(16)
    , @inNombreActual               VARCHAR(64)
    , @inDocumentoIdentidadActual   VARCHAR(16)
    , @inIP                         VARCHAR(32)
    , @inUsuario                    VARCHAR(32)
    , @outResultCode                INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @outResultCode = 0; 
    DECLARE @descBitacora VARCHAR(128);
    DECLARE @bitacoraResultCode INT;

    -- buscar puesto para inserciones en bitacora
    -- se usó join para no declarar otra variable
    DECLARE @puestoActual VARCHAR(32);
    SELECT @puestoActual = P.Nombre
        FROM dbo.Empleado E
        JOIN dbo.Puesto P ON E.IDPuesto = P.ID
        WHERE (E.Nombre = @inNombreActual
        AND E.ValorDocumentoIdentidad = @inDocumentoIdentidadActual);
    
    -- buscar saldo para inserciones en bitacora
    DECLARE @saldoVacaciones INT;
    SELECT @saldoVacaciones = E.SaldoVacaciones
        FROM dbo.Empleado E
        WHERE (E.Nombre = @inNombreActual
        AND E.ValorDocumentoIdentidad = @inDocumentoIdentidadActual);
    
    -- verificar que no haya otros empleados con ese nombre
    IF EXISTS (SELECT 1 FROM dbo.Empleado E
                WHERE (E.Nombre = @inNombre
                AND E.ValorDocumentoIdentidad <> @inDocumentoIdentidadActual))
    BEGIN
        -- desc bitácora para inserción
        SET @descBitacora = CONCAT('Empleado con mismo nombre ya existe en actualización,'
            , @inDocumentoIdentidadActual
            , ','
            , @inNombreActual
            , ','
            , @puestoActual
            , ','
            , @inDocumentoIdentidad
            , CAST(@saldoVacaciones AS VARCHAR))

        EXEC dbo.InsertarBitacora 
            @inIP
            , @inUsuario
            , @descBitacora
            , 7 -- update no exitoso
            , @bitacoraResultCode OUTPUT;
        SET @outResultCode = 50007 -- existe empleado con ese nombre en update
        RETURN;
    END

    -- verificar que no haya otros empleados con ese doc identidad
    IF EXISTS (SELECT 1 FROM dbo.Empleado E
                WHERE (E.ValorDocumentoIdentidad = @inDocumentoIdentidad
                AND E.Nombre <> @inNombreActual))
    BEGIN
        -- desc bitácora para inserción
        SET @descBitacora = CONCAT('Empleado con ValorDocumentoIdentidad ya existe en actualización,'
            , @inDocumentoIdentidadActual
            , ','
            , @inNombreActual
            , ','
            , @puestoActual
            , ','
            , @inDocumentoIdentidad
            , CAST(@saldoVacaciones AS VARCHAR))

        EXEC dbo.InsertarBitacora 
            @inIP
            , @inUsuario
            , @descBitacora
            , 7 -- update no exitoso
            , @bitacoraResultCode OUTPUT;
        SET @outResultCode = 50006 -- existe empleado con ese docid en update
        RETURN;
    END

    DECLARE @puestoID INT;
    SELECT @puestoID = P.ID
        FROM dbo.Puesto P
        WHERE P.Nombre = @inPuesto;

    IF @puestoID IS NULL -- no existe el puesto, por cualquier razón
    BEGIN
        -- desc bitácora para inserción
        SET @descBitacora = CONCAT('Empleado con ValorDocumentoIdentidad ya existe en actualización,'
            , @inDocumentoIdentidadActual
            , ','
            , @inNombreActual
            , ','
            , @puestoActual
            , ','
            , @inDocumentoIdentidad
            , CAST(@saldoVacaciones AS VARCHAR))

        EXEC dbo.InsertarBitacora 
            @inIP
            , @inUsuario
            , @descBitacora
            , 7 -- update no exitoso
            , @bitacoraResultCode OUTPUT;
        SET @outResultCode = 50008; -- error bd
        RETURN;
    END

    -- flujo normal
    BEGIN TRY
        SET @descBitacora = CONCAT(@inDocumentoIdentidad
                                , ', '
                                , @inNombre
                                , ', '
                                , @inPuesto);        

        BEGIN TRANSACTION

            UPDATE dbo.Empleado 
            SET [IDPuesto] = @puestoID
                , [ValorDocumentoIdentidad] = @inDocumentoIdentidad 
                , [Nombre] = @inNombre
            WHERE Nombre = @inNombreActual 
            AND ValorDocumentoIdentidad = @inDocumentoIdentidadActual;

            EXEC dbo.InsertarBitacora 
                @inIP
                , @inUsuario
                , @descBitacora
                , 8  -- insercion exitosa
                , @bitacoraResultCode OUTPUT;
            
            IF (@bitacoraResultCode <> 0)
            BEGIN
                ROLLBACK TRANSACTION;
                SET @outResultCode = @bitacoraResultCode;
                RETURN;
            END
            
        COMMIT TRANSACTION;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		INSERT INTO dbo.DBError (
			[UserName]
			, [Number]
			, [State]
			, [Severity]
			, [Line]
			, [Procedure]
			, [Message]
			, [DateTime]
		) VALUES (
			SUSER_SNAME()
			, ERROR_NUMBER()
			, ERROR_STATE()
			, ERROR_SEVERITY()
			, ERROR_LINE()
			, ERROR_PROCEDURE()
			, ERROR_MESSAGE()
			, GETDATE()
		);

		SET @outResultCode = 50008; -- error bd
    END CATCH;
END;
