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
    
    DECLARE @descBitacora VARCHAR(128);
    DECLARE @bitacoraResultCode INT;
    
    IF EXISTS (SELECT 1 FROM dbo.Empleado WHERE ValorDocumentoIdentidad = @inDocumentoIdentidad AND EsActivo = 1)
    BEGIN
        SET @descBitacora = CONCAT(
            'Empleado con ValorDocumentoIdentidad ya existe en actualización,'
            , @inDocumentoIdentidad
            , ','
            , @inNombre
            , ','
            , @inPuesto)

        EXEC dbo.InsertarBitacora 
            @inIP
            , @inUsuario
            , @descBitacora
            , 5
            , @bitacoraResultCode OUTPUT;
        SET @outResultCode = 50005;
        RETURN;
    END
    
    DECLARE @puestoID INT;
    SELECT @puestoID = P.ID
        FROM dbo.Puesto P
        WHERE P.Nombre = @inPuesto;

    IF @puestoID IS NULL
    BEGIN
        SET @descBitacora = CONCAT(
            'Puesto no encontrado para empleado,'
            , @inDocumentoIdentidad
            , ','
            , @inNombre
            , ','
            , @inPuesto)

        EXEC dbo.InsertarBitacora 
            @inIP
            , @inUsuario
            , @descBitacora
            , 5
            , @bitacoraResultCode OUTPUT;
        SET @outResultCode = 50008;
        RETURN;
    END

    BEGIN TRY
        SET @descBitacora = CONCAT(
                        @inDocumentoIdentidad
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
                , 6
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

		SET @outResultCode = 50008;
    END CATCH;
END;
GO