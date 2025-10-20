CREATE OR ALTER PROCEDURE dbo.TraerPuestos 
AS
BEGIN  
    SET NOCOUNT ON;

    SELECT p.ID, p.Nombre
    FROM dbo.Puesto p

END;