CREATE OR ALTER PROCEDURE [dbo].[EliminarEmpleado]
    @inNombre                       VARCHAR(64)
    , @inDocumentoIdentidad         VARCHAR(16)
    , @inIP                         VARCHAR(32)
    , @inUsuario                    VARCHAR(32)
    , @outResultCode                INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @outResultCode = 0; 
    DECLARE @descBitacora VARCHAR(128);

    -- verificar que exista el empleado
    IF NOT EXISTS (SELECT 1 FROM dbo.Empleado E
                WHERE (E.Nombre = @inNombre
                AND E.ValorDocumentoIdentidad = @inDocumentoIdentidad)
                AND E.EsActivo = 1)
    BEGIN
        -- no hay código para esta ocasión
        -- averiguar qué se inserta en logs aquí
        SET @outResultCode = 50008 -- error bd
        RETURN;
    END

    -- flujo normal
    BEGIN TRY
        DECLARE @bitacoraResultCode INT;

        DECLARE @puestoActual VARCHAR(32);
        SELECT @puestoActual = P.Nombre
            FROM dbo.Empleado E
            JOIN dbo.Puesto P ON E.IDPuesto = P.ID
            WHERE (E.Nombre = @inNombre
            AND E.ValorDocumentoIdentidad = @inDocumentoIdentidad);

        IF @puestoActual IS NULL
        BEGIN
            -- averiguar qué se inserta en logs aquí
            SET @outResultCode = 50008; -- error bd
            RETURN;
        END
        SET @descBitacora = CONCAT(@inDocumentoIdentidad
                            , ', '
                            , @inNombre
                            , ', '
                            , @puestoActual);

        BEGIN TRANSACTION

            UPDATE dbo.Empleado 
            SET EsActivo = 0
            WHERE Nombre = @inNombre
            AND ValorDocumentoIdentidad = @inDocumentoIdentidad;

            EXEC dbo.InsertarBitacora 
                @inIP
                , @inUsuario
                , @descBitacora
                , 10 -- borrado exitoso
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