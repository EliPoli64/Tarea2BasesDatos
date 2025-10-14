CREATE OR ALTER PROCEDURE [dbo].[ListarMovimientosPorEmpleado]
    @inDocumentoIdentidad   VARCHAR(16)
    , @inIP                 VARCHAR(32)
    , @inUsuario            VARCHAR(32)
    , @outResultCode        INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @outResultCode = 0;

    BEGIN TRY
        DECLARE @empleadoID INT;
        
        SELECT @empleadoID = E.ID
        FROM dbo.Empleado E
        WHERE E.ValorDocumentoIdentidad = @inDocumentoIdentidad 
        AND E.EsActivo = 1;

        IF (@empleadoID IS NULL)
        BEGIN
            SET @outResultCode = 50008; -- Error: Empleado no encontrado
            RETURN;
        END;

        -- CTE para calcular el saldo acumulado
        WITH MovimientosConSaldo AS (
            SELECT
                M.Fecha
                , TM.Nombre AS TipoMovimiento
                , M.Monto
                , U.UserName AS Usuario
                , M.PostInIP
                , M.PostTime
                -- Se calcula el saldo acumulado ordenando por PostTime para asegurar la cronología
                , SUM(
                    CASE 
                        WHEN TM.TipoAccion = 'Cr' THEN M.Monto 
                        WHEN TM.TipoAccion = 'De' THEN -M.Monto 
                        ELSE 0 
                    END
                  ) OVER (PARTITION BY M.IDEmpleado ORDER BY M.PostTime ASC) AS NuevoSaldo
            FROM
                dbo.Movimiento AS M
            INNER JOIN
                dbo.TipoMovimiento AS TM ON M.IDTipoMovimiento = TM.ID
            INNER JOIN
                dbo.Usuario AS U ON M.IDPostByUser = U.ID
            WHERE
                (M.IDEmpleado = @empleadoID)
        )
        
        SELECT
            M.Fecha
            , M.TipoMovimiento
            , M.Monto
            , M.NuevoSaldo
            , M.Usuario
            , M.PostInIP
            , M.PostTime
        FROM
            MovimientosConSaldo M
        ORDER BY
            M.Fecha DESC, M.PostTime DESC; 

    END TRY
    BEGIN CATCH
        INSERT INTO dbo.DBError (
            [ID] -- Columna ID añadida
            , UserName
            , Number
            , State
            , Severity
            , Line
            , [Procedure]
            , Message
            , DateTime
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
        SET @outResultCode = 50008; -- Código de error: Error de base de datos
    END CATCH;

    SET NOCOUNT OFF;
END;
GO