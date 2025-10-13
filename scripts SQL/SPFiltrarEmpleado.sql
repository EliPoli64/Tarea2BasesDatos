CREATE OR ALTER PROCEDURE [dbo].[FiltrarEmpleados]
    @infiltro        VARCHAR(64)
    , @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @outResultCode = 0;
    BEGIN TRY
        SELECT E.ID
              , E.Nombre
              , E.ValorDocumentoIdentidad
              , P.Nombre AS Puesto
              , P.SalarioxHora
              , E.SaldoVacaciones
            FROM [dbo].[Empleado] E 
            JOIN [dbo].[Puesto] P ON E.IDPuesto = P.ID -- join para info de puesto
            WHERE E.EsActivo = 1
            AND (
                -- si es vac�o retorne todo
                @infiltro = '' 
                OR 
                (
                    @infiltro <> '' 
                    AND 
                    (
                        -- si es num�rico busque por c�dula
                        (@infiltro NOT LIKE '%[^0-9]%' AND E.ValorDocumentoIdentidad LIKE '%' + @infiltro + '%')
                        OR
                        -- si tiene letras
                        (E.Nombre LIKE '%' + @infiltro + '%')
                    )
                )
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