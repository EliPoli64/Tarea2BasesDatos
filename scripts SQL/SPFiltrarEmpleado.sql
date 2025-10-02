CREATE OR ALTER PROCEDURE [dbo].[FiltrarEmpleados]
    @infiltro        VARCHAR(64)
    , @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @outResultCode = 0;
    BEGIN TRY
        SELECT 
        ID
        , Nombre
        , Salario 
        FROM [dbo].[Empleado] E 
        WHERE E.Nombre LIKE '%' + @infiltro + '%';
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
        SET @outResultCode = 50008; -- error bd
    END CATCH;
END;
GO