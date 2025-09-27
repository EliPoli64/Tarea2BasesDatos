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
    IF EXISTS (SELECT 1 FROM dbo.Empleado WHERE Nombre = @innombre)
    BEGIN
        SELECT @outResultCode = E.Codigo 
        FROM dbo.Error E 
        WHERE E.Descripcion LIKE '%usuario%';

        RETURN;
    END

    BEGIN TRY
        DECLARE @puestoID INT;
        BEGIN TRANSACTION

            SELECT @puestoID = P.IDPuesto
            FROM dbo.Puesto P
            WHERE P.Nombre = @inPuesto;

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
            DECLARE @codResultado INT;
            EXEC dbo.InsertarBitacora 
                @inIP
                , @inUsuario
                , CONCAT(@inDocumentoIdentidad, ', ', @inNombre, ', ', @inPuesto)
                , 6, -- insercion exitosa
                , @codResultado OUTPUT;

            SET @outResultCode = 0;
        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        DECLARE @descError VARCHAR(128); -- descripcion error
        SELECT @descError = E.Descripcion
        FROM dbo.Error E 
        WHERE E.Codigo = 7; -- error insercion empleado
        EXEC dbo.InsertarBitacora 
            @inIP
            , @inUsuario
            , CONCAT(@descError, @inDocumentoIdentidad, ', ', @inNombre, ', ', @inPuesto)
            , 7 -- insercion exitosa
            , @codResultado OUTPUT;
        SELECT @outResultCode = E.Codigo 
        FROM dbo.Error E 
        WHERE E.Descripcion LIKE '%usuario%';

    END CATCH;
END;

GO