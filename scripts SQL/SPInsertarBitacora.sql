CREATE OR ALTER PROCEDURE dbo.InsertarBitacora
	@inIP VARCHAR(32)
	, @inUsuario VARCHAR(32)
	, @inDescripcion VARCHAR(256)
	, @inTipoEvento INT
	, @outResultCode INT OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		SET @outResultCode = 0;  -- no error code

		DECLARE @userID INT;
		SELECT @userID = U.ID
			FROM dbo.Usuario U
			WHERE U.UserName = @inUsuario;

		INSERT INTO dbo.BitacoraEvento (	
			[ID]
			, PostInIP
			, [IDPostByUser]
			, Descripcion
			, IDTipoEvento
			, [PostTime]
		) VALUES (
			(SELECT ISNULL(MAX(ID), 0) + 1 FROM dbo.BitacoraEvento)
			, @inIP
			, @userID
			, @inDescripcion
			, @inTipoEvento
			, GETDATE()
		);

	END TRY
	BEGIN CATCH

		INSERT INTO dbo.DBError (
			[ID] -- Columna ID añadida
			, [UserName]
			, [Number]
			, [State]
			, [Severity]
			, [Line]
			, [Procedure]
			, [Message]
			, [DateTime]
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

		SET @outResultCode = 50008; -- error bd
	
	END CATCH
	SET NOCOUNT OFF;
END;