CREATE OR ALTER PROCEDURE [dbo].[sp_FiltrarEmpleados]
    @infiltro VARCHAR(64)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT ID, Nombre, Salario FROM [dbo].[Empleado] E 
        WHERE E.Nombre LIKE '%' + @infiltro + '%';
    END TRY

    BEGIN CATCH
        SELECT
            500 AS codigo,
            'Error inesperado.' AS mensaje;
    END CATCH;
END;
GO