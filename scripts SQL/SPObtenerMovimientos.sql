CREATE OR ALTER PROCEDURE dbo.ObtenerTipoMovimiento
    @outResultCode          INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON
    SET @outResultCode = 0;

    SELECT m.ID
           , m.Nombre AS Movimiento
           , m.TipoAccion
    FROM dbo.TipoMovimiento m
END;