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
		DECLARE @descripcionBitacora VARCHAR(128);
		DECLARE @userID INT;
		DECLARE @contrasennaCorrecta VARCHAR(256);
		DECLARE @esActivo BIT;
		
		SELECT @userID = U.ID,
		       @contrasennaCorrecta = U.[Password],
			   @esActivo = 1  -- Asumiendo que todos los usuarios están activos
		FROM dbo.Usuario U
		WHERE U.UserName = @inUsuario;
		
		-- Si no existe el usuario
		IF @userID IS NULL
		BEGIN
			SET @outResultCode = 50001; -- usuario no existe
			
			-- Obtener intentos fallidos
			DECLARE @cantLoginsFallidos INT = 0;
			SELECT @cantLoginsFallidos = COUNT(*) 
			FROM dbo.BitacoraEvento B
			WHERE B.PostInIP = @inIP
				AND B.PostTime >= DATEADD(MINUTE, -5, GETDATE())
				AND B.IDTipoEvento = 2;

			SET @descripcionBitacora = CONCAT(CAST(@cantLoginsFallidos AS VARCHAR), ',50001');

			DECLARE @bitacoraResultCode INT;
			EXEC dbo.InsertarBitacora 
				@inIP
				, @inUsuario
				, @descripcionBitacora
				, 2
				, @bitacoraResultCode OUTPUT;
				
			RETURN;
		END;

		-- obtener numero de intentos de login recientes
		DECLARE @cantLoginsFallidosUser INT;
		SELECT @cantLoginsFallidosUser = COUNT(*) 
		FROM dbo.BitacoraEvento B
		WHERE B.PostInIP = @inIP
			AND B.IDPostByUser = @userID
			AND B.PostTime >= DATEADD(MINUTE, -5, GETDATE())
			AND B.IDTipoEvento = 2;

		DECLARE @deshabilitado INT;
		SELECT @deshabilitado = COUNT(1) 
		FROM dbo.BitacoraEvento B
		WHERE B.[PostInIP] = @inIP
			AND B.[IDPostByUser] = @userID
			AND B.[PostTime] >= DATEADD(MINUTE, -10, GETDATE())
			AND B.IDTipoEvento = 3;
			
		IF (@deshabilitado > 0)
		BEGIN
			SET @descripcionBitacora = CONCAT(CAST(@cantLoginsFallidos AS VARCHAR), ',50001');
			EXEC dbo.InsertarBitacora 
				@inIP
				, @inUsuario
				, @descripcionBitacora
				, 2
				, @bitacoraResultCode OUTPUT;
				
			RETURN;
			SET @outResultCode = 50004; -- login deshabilitado
			RETURN;
		END;

		IF (@cantLoginsFallidosUser >= 5) 
		BEGIN
			SET @outResultCode = 50003; -- demasiados intentos

			IF (@cantLoginsFallidosUser = 5) 
			BEGIN
				-- insertar bloqueo en bitacora
				DECLARE @lockResultCode INT;
				EXEC dbo.InsertarBitacora 
					@inIP
					, @inUsuario
					, ''
					, 3
					, @lockResultCode OUTPUT;
			END;
			
			RETURN;
		END;

		-- validar contraseña
		IF (@contrasennaCorrecta <> @inContrasenna)
		BEGIN
			SET @descripcionBitacora = CONCAT('Cantidad intentos fallidos: '
										, CAST(@cantLoginsFallidosUser AS CHAR));
			DECLARE @failResultCode INT;
			EXEC dbo.InsertarBitacora 
				@inIP
				, @inUsuario
				, @descripcionBitacora
				, 2
				, @failResultCode OUTPUT;
				
			SET @outResultCode = 50002; -- password incorrecta
			
			RETURN;
		END;

		BEGIN TRANSACTION
		 	-- LOGIN EXITOSO
			DECLARE @successResultCode INT;
			EXEC dbo.InsertarBitacora 
				@inIP
				, @inUsuario
				, ''
				, 1
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

		SET @outResultCode = 50008;
	END CATCH;
	
	SET NOCOUNT OFF;
END;