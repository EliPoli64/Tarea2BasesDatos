CREATE OR ALTER PROCEDURE dbo.RegistrarLogout
    @inUsuario  VARCHAR(32)
    , @inIP     VARCHAR(32)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @outResultCode INT = 0;  -- no error
    
    BEGIN TRY
        -- Insertar registro en la bitácora para el cierre de sesión
        INSERT INTO dbo.Bitacora (
            IP,
            Usuario, 
            Descripcion,
            TipoEvento,
            [TimeStamp]
        ) VALUES (
            @inIP,
            @inUsuario,
            'Cierre de sesión exitoso',
            3,  -- Código para evento de cierre de sesión
            GETDATE()
        );
        
    END TRY
    BEGIN CATCH
        INSERT INTO dbo.DBError (
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
        
        SET @outResultCode = 50008; -- error bd
    END CATCH;
    
    -- Retornar código de resultado
    SELECT @outResultCode AS ResultCode;
END;
GO