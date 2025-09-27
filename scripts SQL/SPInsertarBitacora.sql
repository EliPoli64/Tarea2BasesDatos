CREATE PROCEDURE dbo.InsertarBitacora
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

		INSERT INTO dbo.Bitacora (	
			PostInIP
			, Usuario
			, Descripcion
			, TipoEvento
			, [TimeStamp]
		) VALUES (
			@inIP
			, @inUsuario
			, @inDescripcion
			, @inTipoEvento
			, GETDATE()
		);

	END TRY
	BEGIN CATCH

		INSERT INTO dbo.DBError	(
			UserName
			, Number
			, State
			, Severity
			, Line
			, [Procedure]
			, Message
			, DateTime
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

		SELECT @outResultCode = E.Codigo 
        FROM dbo.Error E 
        WHERE E.Descripcion 
        LIKE '%base de datos%';
	
	END CATCH
	SET NOCOUNT OFF;
END;