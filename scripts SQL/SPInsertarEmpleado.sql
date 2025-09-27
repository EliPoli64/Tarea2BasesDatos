CREATE OR ALTER PROCEDURE [dbo].[InsertarEmpleado]
    @inNombre VARCHAR(64)
    , @inPuesto VARCHAR(32)
    , @inDocumentoIdentidad VARCHAR(16)
    , @inIP VARCHAR(32)
    , @inUsuario VARCHAR(32)
    , @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @outResultCode = 0;
    
    -- Check for duplicate document
    IF EXISTS (SELECT 1 FROM dbo.Empleado WHERE ValorDocumentoIdentidad = @inDocumentoIdentidad)
    BEGIN
        SELECT @outResultCode = E.Codigo 
        FROM dbo.Error E 
        WHERE E.Descripcion LIKE '%usuario%';
        RETURN;
    END

    BEGIN TRY
        DECLARE @puestoID INT;
        DECLARE @bitacoraResultCode INT;  -- Separate variable for bitacora result
        
        -- Validate position exists
        SELECT @puestoID = P.IDPuesto
        FROM dbo.Puesto P
        WHERE P.Nombre = @inPuesto;

        IF @puestoID IS NULL
        BEGIN
            SET @outResultCode = 50002; -- Invalid position error
            RETURN;
        END

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
 
            -- Use separate variable for bitacora result
            EXEC dbo.InsertarBitacora 
                @inIP
                , @inUsuario
                , CONCAT(@descError, ', ', @inDocumentoIdentidad, ', ', @inNombre, ', ', @inPuesto)
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

        SELECT @outResultCode = E.Codigo
			FROM dbo.Error E 
			WHERE E.Descripcion 
			LIKE '%base de datos%';
    END CATCH;
END;
GO