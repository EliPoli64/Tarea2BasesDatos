CREATE PROCEDURE dbo.InsertarBitacora
	@inIP VARCHAR(32)
	, @inUsuario VARCHAR(32)
	, @inContrasenna VARCHAR(256)
	, @outResultCode INT OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY  -- no siempre se hace try catch en SP que hacen consultas
		SET @outResultCode = 0;  -- no error code

		-- SE HACEN VALIDACIONES

		IF (@inUsuario IS NULL)
		BEGIN
			SET @outResultCode = 50001;  -- parametro de entrada es nulo
			RETURN;
		END;
		IF (@inContrasenna IS NULL)
		BEGIN
			SET @outResultCode = 50002;  -- parametro de entrada es nulo
			RETURN;
		END;

		SELECT @outResultCode AS resultado;


		IF EXISTS (SELECT 1 
		FROM dbo.Usuario U 
		WHERE U.Nombre = @inUsuario 
		AND U.Contrasenna = @inContrasenna)
		BEGIN
			-- LOGIN OK
			DECLARE @IDUsuario INT;
			SELECT @IDUsuario = U.IDUsuario
			FROM dbo.Usuario U 
			WHERE U.Nombre = @inUsuario;
			 -- TODO: EXEC InsertarLog @
		END
		ELSE

	END TRY
	BEGIN CATCH

		INSERT INTO dbo.DBError	(
			UserName,
			`Number`,
			`State`,
			`Severity`,
			`Line`,
			`Procedure`,
			`Message`,
			`DateTime`
		) VALUES (
			SUSER_SNAME(),
			ERROR_NUMBER(),
			ERROR_STATE(),
			ERROR_SEVERITY(),
			ERROR_LINE(),
			ERROR_PROCEDURE(),
			ERROR_MESSAGE(),
			GETDATE()
		);

		SET @outResultCode=50005;
	
	END CATCH
	SET NOCOUNT OFF;
END;