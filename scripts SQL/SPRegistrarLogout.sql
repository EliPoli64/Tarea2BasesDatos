CREATE OR ALTER PROCEDURE dbo.RegistrarLogout
    @inUsuario          VARCHAR(32)
    , @inIP             VARCHAR(32)
    , @outResultCode    INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    SET @outResultCode = 0;  -- no error
    DECLARE @bitacoraResultCode INT;
    
    BEGIN TRY
        
        EXEC dbo.InsertarBitacora 
			@inIP
			, @inUsuario
			, ''
			, 4  -- logout
			, @bitacoraResultCode OUTPUT;
        
    END TRY
    BEGIN CATCH
        INSERT INTO dbo.DBError (
            [ID] -- Columna ID añadida
            , UserName
            , Number
            , State
            , Severity
            , Line
            , [Procedure]
            , Message
            , DateTime
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
    END CATCH;
END;
GO