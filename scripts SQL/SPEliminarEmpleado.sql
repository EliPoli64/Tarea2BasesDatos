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
    IF NOT EXISTS (SELECT COUNT(1) FROM dbo.Empleado E
                WHERE (E.Nombre = @inNombre
                AND E.ValorDocumentoIdentidad = @inDocumentoIdentidadActual))
    BEGIN
        -- no hay código para esta ocasión
        -- averiguar qué se inserta en logs aquí
        SET @outResultCode = 50008 -- error bd
        RETURN;
    END

    -- flujo normal
    BEGIN TRY
        DECLARE @puestoID INT;
        DECLARE @bitacoraResultCode INT;

        SELECT @puestoID = P.IDPuesto
        FROM dbo.Puesto P
        WHERE P.Nombre = @inPuesto;

        IF @puestoID IS NULL
        BEGIN
            -- averiguar qué se inserta en logs aquí
            SET @outResultCode = 50008; -- error bd
            RETURN;
        END
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
                , 6 -- insercion exitosa
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