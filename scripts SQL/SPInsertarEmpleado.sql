CREATE OR ALTER PROCEDURE [dbo].[InsertarEmpleado]
    @inNombre               VARCHAR(64)
    , @inPuesto             VARCHAR(32)
    , @inDocumentoIdentidad VARCHAR(16)
    , @inIP                 VARCHAR(32)
    , @inUsuario            VARCHAR(32)
    , @outResultCode        INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @outResultCode = 0;
    
    IF EXISTS (SELECT 1 FROM dbo.Empleado WHERE ValorDocumentoIdentidad = @inDocumentoIdentidad)
    BEGIN
        -- desc bitácora para inserción
        SET @descBitacora = CONCAT('Empleado con ValorDocumentoIdentidad ya existe en actualización,'
            , @inDocumentoIdentidad
            , ','
            , @inNombre
            , ','
            , @inPuesto)

        EXEC dbo.InsertarBitacora 
            @inIP
            , @inUsuario
            , @descBitacora
            , 5 -- insert no exitoso
            , @bitacoraResultCode OUTPUT;
        SET @outResultCode = 50005; -- ya existe nombre en la BD
    END
    
    DECLARE @puestoID INT;
    SELECT @puestoID = P.IDPuesto
        FROM dbo.Puesto P
        WHERE P.Nombre = @inPuesto;

    IF @puestoID IS NULL -- no existe el puesto, por cualquier razón
    BEGIN
        -- desc bitácora para inserción
        SET @descBitacora = CONCAT('Empleado con ValorDocumentoIdentidad ya existe en actualización,'
            , @inDocumentoIdentidad
            , ','
            , @inNombre
            , ','
            , @inPuesto)

        EXEC dbo.InsertarBitacora 
            @inIP
            , @inUsuario
            , @descBitacora
            , 5 -- insert no exitoso
            , @bitacoraResultCode OUTPUT;
        SET @outResultCode = 50008; -- error bd
        RETURN;
    END


    BEGIN TRY
        DECLARE @bitacoraResultCode INT;
        SET @descBitacora = CONCAT(@inDocumentoIdentidad
                            , ', '
                            , @inNombre
                            , ', '
                            , @inPuesto);

        BEGIN TRANSACTION

            INSERT INTO dbo.Empleado (
                [IDPuesto]
                , [ValorDocumentoIdentidad]
                , [Nombre]
                , [FechaContratacion]
                , [SaldoVacaciones]
                , [EsActivo])
            VALUES (
                @puestoID
                , @inDocumentoIdentidad 
                , @inNombre
                , GETDATE()
                , 0
                , 1
            );

            EXEC dbo.InsertarBitacora 
                @inIP
                , @inUsuario
                , @descBitacora
                , 6  -- insercion exitosa
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
GO