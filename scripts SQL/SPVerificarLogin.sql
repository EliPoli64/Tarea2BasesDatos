CREATE OR ALTER PROCEDURE dbo.VerificarLogin
	@inIP 				VARCHAR(32)
	, @inUsuario 		VARCHAR(32)
	, @inContrasenna 	VARCHAR(256)
	, @outResultCode 	INT OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	SET @outResultCode = 0;
	
	BEGIN TRY
		-- validar existencia de usuario
		IF NOT EXISTS (SELECT 1 FROM dbo.Usuario U WHERE U.Nombre = @inUsuario)
		BEGIN
			SET @outResultCode = 50001; -- usuario no existe

			DECLARE @bitacoraResultCode INT;
			EXEC dbo.InsertarBitacora 
				@inIP
				, @inUsuario
				, CONCAT('Failed login: User not found - ', @inUsuario)
				, 2  -- login fallido
				, @bitacoraResultCode OUTPUT;
				
			RETURN;
		END;

		DECLARE @IDUsuario INT;
		DECLARE @contrasennaCorrecta VARCHAR(256);

		-- Get user ID and password
		SELECT 
			@IDUsuario = U.IDUsuario,
			@contrasennaCorrecta = U.Contrasenna
		FROM dbo.Usuario U 
		WHERE U.Nombre = @inUsuario;

		DECLARE @deshabilitado INT;
		SELECT @deshabilitado = COUNT(1) 
		FROM dbo.Bitacora B
		WHERE B.IP = @inIP
			AND B.Usuario = @inUsuario
			AND B.[TimeStamp] >= DATEADD(MINUTE, -10, GETDATE())
			AND B.TipoEvento = 3;  -- login deshabilitado
			
		IF (@deshabilitado > 0)
		BEGIN
			SELECT @outResultCode = E.Codigo
			FROM dbo.Error E 
			WHERE E.Descripcion LIKE '%login deshabilitado%';
			
			RETURN;
		END;

		DECLARE @cantLoginsFallidos INT;
		SELECT @cantLoginsFallidos = COUNT(6) 
		FROM dbo.Bitacora B
		WHERE B.IP = @inIP
			AND B.Usuario = @inUsuario
			AND B.[TimeStamp] >= DATEADD(MINUTE, -5, GETDATE())
			AND B.TipoEvento = 2;  -- login no exitoso

		IF (@cantLoginsFallidos >= 5) 
		BEGIN
			SET @outResultCode = 50003;

			IF (@cantLoginsFallidos = 5) 
			BEGIN
				-- bloquear user
				UPDATE dbo.Usuario 
				SET EsActivo = 0 
				WHERE IDUsuario = @IDUsuario;
				
				-- insertar bloqueo en bitacora
				DECLARE @lockResultCode INT;
				EXEC dbo.InsertarBitacora 
					@inIP
					, @inUsuario
					, ''
					, 3  -- bloqueo usuario
					, @lockResultCode OUTPUT;
			END;
			
			RETURN;
		END;

		-- validar contraseña
		IF (@contrasennaCorrecta <> @inContrasenna)
		BEGIN
			DECLARE @failResultCode INT;
			EXEC dbo.InsertarBitacora 
				@inIP
				, @inUsuario
				, CONCAT('Cantidad intentos fallidos: ', CAST(@cantLoginsFallidos AS CHAR), ', ', CAST(@outResultCode AS CHAR))
				, 2  -- login fallido
				, @failResultCode OUTPUT;
				
			SELECT @outResultCode = E.Codigo 
			FROM dbo.Error E 
			WHERE E.Descripcion LIKE '%credenciales%' OR E.Descripcion LIKE '%contraseña%';
			
			RETURN;
		END;

		BEGIN TRANSACTION
		 	-- LOGIN EXITOSO
			DECLARE @successResultCode INT;
			EXEC dbo.InsertarBitacora 
				@inIP
				, @inUsuario
				, ''
				, 1  -- login exitoso
				, @successResultCode OUTPUT;
			
		COMMIT TRANSACTION

	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

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
	
	SET NOCOUNT OFF;
END;