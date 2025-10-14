CREATE OR ALTER PROCEDURE [dbo].[FiltrarEmpleados]
    @infiltro        VARCHAR(64)
    , @inUsuario        VARCHAR(32)
    , @inIP             VARCHAR(32)
    , @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @outResultCode = 0;

    BEGIN TRY
        DECLARE @bitacoraResultCode INT;

        IF (@infiltro <> '')  
        BEGIN
            -- Si es numérico, es una búsqueda por documento de identidad
            IF (ISNUMERIC(@infiltro) = 1)
            BEGIN
                EXEC dbo.InsertarBitacora
                    @inIP            = @inIP
                    , @inUsuario     = @inUsuario
                    , @inDescripcion = @infiltro
                    , @inTipoEvento  = 12 -- Consulta con filtro de cédula
                    , @outResultCode = @bitacoraResultCode OUTPUT;
            END
            -- Si no es numérico, es una búsqueda por nombre
            ELSE
            BEGIN
                EXEC dbo.InsertarBitacora
                    @inIP            = @inIP
                    , @inUsuario     = @inUsuario
                    , @inDescripcion = @infiltro
                    , @inTipoEvento  = 11 -- Consulta con filtro de nombre
                    , @outResultCode = @bitacoraResultCode OUTPUT;
            END
        END

        SELECT E.ID
              , E.Nombre
              , E.ValorDocumentoIdentidad
              , P.Nombre AS Puesto
              , P.SalarioxHora
              , E.SaldoVacaciones
            FROM [dbo].[Empleado] E
            JOIN [dbo].[Puesto] P ON E.IDPuesto = P.ID
            WHERE E.EsActivo = 1
            AND (
                @infiltro = ''
                OR E.Nombre LIKE '%' + @infiltro + '%'
                OR E.ValorDocumentoIdentidad LIKE '%' + @infiltro + '%'
            )
            ORDER BY E.Nombre ASC;
    END TRY

    BEGIN CATCH
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