CREATE OR ALTER PROCEDURE dbo.TraerPuestos
    @inCodigo           INT
    , @outNombre  VARCHAR(256) OUTPUT
AS
BEGIN  
    SET NOCOUNT ON;
    SET @outNombre = NULL;

    SELECT p.ID, p.Nombre
    FROM dbo.Puesto p

    IF @outNombre IS NULL
    BEGIN
        SET @outNombre = 'Error desconocido al momento de cargar los puestos';
    END
END;