-- Otorga el permiso de EJECUTAR en el procedimiento almacenado espec�fico
-- al usuario Remoto.
GRANT EXECUTE ON dbo.FiltrarEmpleados TO Remoto;
GO


-- Otorga el permiso de EJECUTAR en el procedimiento almacenado espec�fico
-- al usuario Remoto.
GRANT EXECUTE ON dbo.TraerPuestos TO Remoto;
GO

-- Otorga el permiso de EJECUTAR en el procedimiento almacenado espec�fico
-- al usuario Remoto.
GRANT EXECUTE ON dbo.VerificarLogin TO Remoto;
GO

-- Otorga el permiso de EJECUTAR en el procedimiento almacenado espec�fico
-- al usuario Remoto.
GRANT EXECUTE ON dbo.ObtenerDescripcionError TO Remoto;
GO

-- Otorga el permiso de EJECUTAR en el procedimiento almacenado espec�fico
-- al usuario Remoto.
GRANT EXECUTE ON dbo.RegistrarLogout TO Remoto;
GO


-- Otorga el permiso de EJECUTAR en el procedimiento almacenado espec�fico
-- al usuario Remoto.
GRANT EXECUTE ON dbo.InsertarEmpleado TO Remoto;
GO

-- Hay que cambiar el tama�o del error en la bitacora porque si no da error en el SP

ALTER TABLE dbo.DBError
ALTER COLUMN [Message] VARCHAR(512);


