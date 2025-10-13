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

-- Otorga el permiso de EJECUTAR en el procedimiento almacenado espec�fico
-- al usuario Remoto.
GRANT EXECUTE ON dbo.EliminarEmpleado TO Remoto;
GO

-- Otorga el permiso de EJECUTAR en el procedimiento almacenado espec�fico
-- al usuario Remoto.
GRANT EXECUTE ON dbo.ActualizarEmpleado TO Remoto;
GO

-- Otorga el permiso de EJECUTAR en el procedimiento almacenado espec�fico
-- al usuario Remoto.
GRANT EXECUTE ON dbo.ObtenerTipoMovimiento TO Remoto;
GO

-- Otorga el permiso de EJECUTAR en el procedimiento almacenado espec�fico
-- al usuario Remoto.
GRANT EXECUTE ON dbo.InsertarMovimiento TO Remoto;
GO

-- Otorga el permiso de EJECUTAR en el procedimiento almacenado espec�fico
-- al usuario Remoto.
GRANT EXECUTE ON dbo.ListarMovimientosPorEmpleado TO Remoto;
GO

-- Hay que cambiar el tama�o del error en la bitacora porque si no da error en el SP

ALTER TABLE dbo.DBError
ALTER COLUMN [Message] VARCHAR(512);

-- Hay que cambiar el tipo de dato del posttime porque si no da error al momento de cargar desde el XML
-- Tomar en cuenta que el orden de la tabla va a variar pero no afecta a nada, ver si en las indicaciones del proyecto eso 
-- afecta

ALTER TABLE dbo.Movimiento
DROP COLUMN PostTime;

ALTER TABLE dbo.Movimiento
ADD PostTime DATETIME NOT NULL;
