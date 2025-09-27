CREATE OR ALTER PROCEDURE dbo.VerificarLogin
	@inIP VARCHAR(32)
	, @inUsuario VARCHAR(32)
	, @inContrasenna VARCHAR(256)
	, @outResultCode INT OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	SET @outResultCode = 0;
	
	BEGIN TRY
		-- Validate user exists
		IF NOT EXISTS (SELECT 1 FROM dbo.Usuario U WHERE U.Nombre = @inUsuario)
		BEGIN
			SELECT @outResultCode = E.Codigo 
			FROM dbo.Error E 
			WHERE E.Descripcion LIKE '%usuario%';
			
			-- Log failed login attempt
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

		-- Check failed login attempts in last 15 minutes
		DECLARE @cantLoginsFallidos INT;
		SELECT @cantLoginsFallidos = COUNT(*)  -- Fixed: COUNT(*) instead of COUNT(6)
		FROM dbo.Bitacora B  -- Fixed: Assuming table name is Bitacora, not BitacoraEvento
		WHERE B.IP = @inIP
			AND B.Usuario = @inUsuario  -- Fixed: Using Usuario instead of IDPostByUser
			AND B.[TimeStamp] >= DATEADD(MINUTE, -15, GETDATE())
			AND B.TipoEvento = 2;  -- login fallido

		IF (@cantLoginsFallidos >= 5) 
		BEGIN
			SELECT @outResultCode = E.Codigo
			FROM dbo.Error E 
			WHERE E.Descripcion LIKE '%login deshabilitado%';

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
					, 8  -- bloqueo usuario
					, @lockResultCode OUTPUT;
			END;
			
			RETURN;
		END;

		-- Validate password
		IF (@contrasennaCorrecta <> @inContrasenna)
		BEGIN
			-- Log failed login attempt
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
		-- Rollback transaction if active
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

		SELECT @outResultCode = E.Codigo
			FROM dbo.Error E 
			WHERE E.Descripcion 
			LIKE '%base de datos%';
	END CATCH;
	
	SET NOCOUNT OFF;
END;