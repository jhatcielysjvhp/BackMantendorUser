-- ===================================================================
-- PACKAGES CRUD 
-- Sistema de Usuarios, Roles y Variables
-- Creado por: Jhernadez
-- Modificado: Cursores agregados a métodos de consulta
-- ===================================================================

-- Configurar delimitador para procedimientos
DELIMITER $$

-- ===================================================================
-- PACKAGE 1: PKG_ROLES - CRUD COMPLETO PARA TABLA ROLES
-- ===================================================================

-- PROCEDIMIENTO: CREAR ROL
DROP PROCEDURE IF EXISTS PKG_ROLES_CREATE$$
CREATE PROCEDURE PKG_ROLES_CREATE(
    IN p_nombre VARCHAR(100),
    OUT p_resultado INT,
    OUT p_mensaje VARCHAR(500),
    OUT p_id_generado INT
)
MODIFIES SQL DATA
SQL SECURITY DEFINER
COMMENT 'Crear nuevo rol con validaciones'
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            p_resultado = MYSQL_ERRNO,
            p_mensaje = MESSAGE_TEXT;
        SET p_id_generado = 0;
    END;
    
    START TRANSACTION;
    
    -- Validaciones
    IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
        SET p_resultado = 1001;
        SET p_mensaje = 'El nombre del rol es obligatorio';
        SET p_id_generado = 0;
        ROLLBACK;
    ELSEIF LENGTH(TRIM(p_nombre)) > 100 THEN
        SET p_resultado = 1002;
        SET p_mensaje = 'El nombre del rol no puede exceder 100 caracteres';
        SET p_id_generado = 0;
        ROLLBACK;
    ELSEIF EXISTS (SELECT 1 FROM Roles WHERE UPPER(Nombre) = UPPER(TRIM(p_nombre))) THEN
        SET p_resultado = 1003;
        SET p_mensaje = 'Ya existe un rol con ese nombre';
        SET p_id_generado = 0;
        ROLLBACK;
    ELSE
        -- Insertar rol
        INSERT INTO Roles (Nombre) VALUES (TRIM(p_nombre));
        SET p_id_generado = LAST_INSERT_ID();
        SET p_resultado = 0;
        SET p_mensaje = CONCAT('Rol creado exitosamente con ID: ', p_id_generado);
        
        COMMIT;
    END IF;
END$$

-- PROCEDIMIENTO: LEER ROL POR ID (CON CURSOR)
DROP PROCEDURE IF EXISTS PKG_ROLES_READ_BY_ID$$
CREATE PROCEDURE PKG_ROLES_READ_BY_ID(
    IN p_id INT,
    OUT p_resultado INT,
    OUT p_mensaje VARCHAR(500)
)
READS SQL DATA
SQL SECURITY DEFINER
COMMENT 'Obtener rol por ID usando cursor'
BEGIN
    DECLARE v_count INT DEFAULT 0;
    DECLARE v_rol_id INT;
    DECLARE v_rol_nombre VARCHAR(100);
    DECLARE v_usuarios_count INT;
    DECLARE done INT DEFAULT FALSE;
    
    DECLARE rol_cursor CURSOR FOR
        SELECT 
            Id,
            Nombre,
            (SELECT COUNT(*) FROM Usuarios WHERE RolId = p_id) as usuarios_count
        FROM Roles 
        WHERE Id = p_id;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            p_resultado = MYSQL_ERRNO,
            p_mensaje = MESSAGE_TEXT;
    END;
    
    -- Validar ID
    IF p_id IS NULL OR p_id <= 0 THEN
        SET p_resultado = 2001;
        SET p_mensaje = 'ID inválido';
    ELSE
        SELECT COUNT(*) INTO v_count FROM Roles WHERE Id = p_id;
        
        IF v_count = 0 THEN
            SET p_resultado = 2002;
            SET p_mensaje = 'Rol no encontrado';
        ELSE
            OPEN rol_cursor;
            
            read_loop: LOOP
                FETCH rol_cursor INTO v_rol_id, v_rol_nombre, v_usuarios_count;
                IF done THEN
                    LEAVE read_loop;
                END IF;
                
                -- Retornar los datos del cursor
                SELECT v_rol_id as Id, v_rol_nombre as Nombre, v_usuarios_count as usuarios_count;
            END LOOP;
            
            CLOSE rol_cursor;
            
            SET p_resultado = 0;
            SET p_mensaje = 'Rol encontrado exitosamente';
        END IF;
    END IF;
END$$

-- PROCEDIMIENTO: LEER TODOS LOS ROLES (CON CURSOR)
DROP PROCEDURE IF EXISTS PKG_ROLES_READ_ALL$$
CREATE PROCEDURE PKG_ROLES_READ_ALL(
    IN p_offset INT,
    IN p_limit INT,
    OUT p_resultado INT,
    OUT p_mensaje VARCHAR(500),
    OUT p_total_registros INT
)
READS SQL DATA
SQL SECURITY DEFINER
COMMENT 'Obtener todos los roles con paginación usando cursor'
BEGIN
    DECLARE v_rol_id INT;
    DECLARE v_rol_nombre VARCHAR(100);
    DECLARE v_usuarios_count INT;
    DECLARE done INT DEFAULT FALSE;
    
    DECLARE roles_cursor CURSOR FOR
        SELECT 
            r.Id,
            r.Nombre,
            COUNT(u.Id) as usuarios_count
        FROM Roles r
        LEFT JOIN Usuarios u ON r.Id = u.RolId
        GROUP BY r.Id, r.Nombre
        ORDER BY r.Nombre
        LIMIT p_limit OFFSET p_offset;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            p_resultado = MYSQL_ERRNO,
            p_mensaje = MESSAGE_TEXT;
    END;
    
    -- Validar parámetros de paginación
    IF p_offset IS NULL OR p_offset < 0 THEN SET p_offset = 0; END IF;
    IF p_limit IS NULL OR p_limit <= 0 OR p_limit > 1000 THEN SET p_limit = 100; END IF;
    
    -- Obtener total de registros
    SELECT COUNT(*) INTO p_total_registros FROM Roles;
    
    -- Abrir cursor y procesar resultados
    OPEN roles_cursor;
    
    read_loop: LOOP
        FETCH roles_cursor INTO v_rol_id, v_rol_nombre, v_usuarios_count;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Retornar cada fila del cursor
        SELECT v_rol_id as Id, v_rol_nombre as Nombre, v_usuarios_count as usuarios_count;
    END LOOP;
    
    CLOSE roles_cursor;
    
    SET p_resultado = 0;
    SET p_mensaje = CONCAT('Se encontraron ', p_total_registros, ' roles');
END$$

-- PROCEDIMIENTO: ACTUALIZAR ROL
DROP PROCEDURE IF EXISTS PKG_ROLES_UPDATE$$
CREATE PROCEDURE PKG_ROLES_UPDATE(
    IN p_id INT,
    IN p_nombre VARCHAR(100),
    OUT p_resultado INT,
    OUT p_mensaje VARCHAR(500)
)
MODIFIES SQL DATA
SQL SECURITY DEFINER
COMMENT 'Actualizar rol existente'
BEGIN
    DECLARE v_nombre_anterior VARCHAR(100);
    DECLARE v_count INT DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            p_resultado = MYSQL_ERRNO,
            p_mensaje = MESSAGE_TEXT;
    END;
    
    START TRANSACTION;
    
    -- Validaciones
    IF p_id IS NULL OR p_id <= 0 THEN
        SET p_resultado = 3001;
        SET p_mensaje = 'ID inválido';
        ROLLBACK;
    ELSEIF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
        SET p_resultado = 3002;
        SET p_mensaje = 'El nombre del rol es obligatorio';
        ROLLBACK;
    ELSEIF LENGTH(TRIM(p_nombre)) > 100 THEN
        SET p_resultado = 3003;
        SET p_mensaje = 'El nombre del rol no puede exceder 100 caracteres';
        ROLLBACK;
    ELSE
        -- Verificar que el rol existe
        SELECT COUNT(*), COALESCE(Nombre, '') INTO v_count, v_nombre_anterior 
        FROM Roles WHERE Id = p_id;
        
        IF v_count = 0 THEN
            SET p_resultado = 3004;
            SET p_mensaje = 'Rol no encontrado';
            ROLLBACK;
        ELSEIF EXISTS (SELECT 1 FROM Roles WHERE UPPER(Nombre) = UPPER(TRIM(p_nombre)) AND Id != p_id) THEN
            SET p_resultado = 3005;
            SET p_mensaje = 'Ya existe otro rol con ese nombre';
            ROLLBACK;
        ELSE
            -- Actualizar rol
            UPDATE Roles 
            SET Nombre = TRIM(p_nombre)
            WHERE Id = p_id;
            
            SET p_resultado = 0;
            SET p_mensaje = 'Rol actualizado exitosamente';
            
            COMMIT;
        END IF;
    END IF;
END$$

-- PROCEDIMIENTO: ELIMINAR ROL
DROP PROCEDURE IF EXISTS PKG_ROLES_DELETE$$
CREATE PROCEDURE PKG_ROLES_DELETE(
    IN p_id INT,
    OUT p_resultado INT,
    OUT p_mensaje VARCHAR(500)
)
MODIFIES SQL DATA
SQL SECURITY DEFINER
COMMENT 'Eliminar rol (solo si no tiene usuarios asociados)'
BEGIN
    DECLARE v_count INT DEFAULT 0;
    DECLARE v_usuarios_count INT DEFAULT 0;
    DECLARE v_nombre VARCHAR(100);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            p_resultado = MYSQL_ERRNO,
            p_mensaje = MESSAGE_TEXT;
    END;
    
    START TRANSACTION;
    
    -- Validaciones
    IF p_id IS NULL OR p_id <= 0 THEN
        SET p_resultado = 4001;
        SET p_mensaje = 'ID inválido';
        ROLLBACK;
    ELSE
        -- Verificar que el rol existe
        SELECT COUNT(*), COALESCE(Nombre, '') INTO v_count, v_nombre 
        FROM Roles WHERE Id = p_id;
        
        IF v_count = 0 THEN
            SET p_resultado = 4002;
            SET p_mensaje = 'Rol no encontrado';
            ROLLBACK;
        ELSE
            -- Verificar que no tenga usuarios asociados
            SELECT COUNT(*) INTO v_usuarios_count FROM Usuarios WHERE RolId = p_id;
            
            IF v_usuarios_count > 0 THEN
                SET p_resultado = 4003;
                SET p_mensaje = CONCAT('No se puede eliminar el rol. Tiene ', v_usuarios_count, ' usuarios asociados');
                ROLLBACK;
            ELSE
                -- Eliminar rol
                DELETE FROM Roles WHERE Id = p_id;
                
                SET p_resultado = 0;
                SET p_mensaje = 'Rol eliminado exitosamente';
                COMMIT;
            END IF;
        END IF;
    END IF;
END$$

-- ===================================================================
-- PACKAGE 2: PKG_USUARIOS - CRUD COMPLETO PARA TABLA USUARIOS
-- ===================================================================

-- PROCEDIMIENTO: CREAR USUARIO
DROP PROCEDURE IF EXISTS PKG_USUARIOS_CREATE$$
CREATE PROCEDURE PKG_USUARIOS_CREATE(
    IN p_nombre VARCHAR(255),
    IN p_email VARCHAR(255),
    IN p_rol_id INT,
    OUT p_resultado INT,
    OUT p_mensaje VARCHAR(500),
    OUT p_id_generado INT
)
MODIFIES SQL DATA
SQL SECURITY DEFINER
COMMENT 'Crear nuevo usuario con validaciones'
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            p_resultado = MYSQL_ERRNO,
            p_mensaje = MESSAGE_TEXT;
        SET p_id_generado = 0;
    END;
    
    START TRANSACTION;
    
    -- Validaciones
    IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
        SET p_resultado = 5001;
        SET p_mensaje = 'El nombre del usuario es obligatorio';
        SET p_id_generado = 0;
        ROLLBACK;
    ELSEIF LENGTH(TRIM(p_nombre)) > 255 THEN
        SET p_resultado = 5002;
        SET p_mensaje = 'El nombre no puede exceder 255 caracteres';
        SET p_id_generado = 0;
        ROLLBACK;
    ELSEIF p_email IS NULL OR TRIM(p_email) = '' THEN
        SET p_resultado = 5003;
        SET p_mensaje = 'El email es obligatorio';
        SET p_id_generado = 0;
        ROLLBACK;
    ELSEIF LENGTH(TRIM(p_email)) > 255 THEN
        SET p_resultado = 5004;
        SET p_mensaje = 'El email no puede exceder 255 caracteres';
        SET p_id_generado = 0;
        ROLLBACK;
    ELSEIF NOT p_email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$' THEN
        SET p_resultado = 5005;
        SET p_mensaje = 'Formato de email inválido';
        SET p_id_generado = 0;
        ROLLBACK;
    ELSEIF p_rol_id IS NULL OR p_rol_id <= 0 THEN
        SET p_resultado = 5006;
        SET p_mensaje = 'ID de rol inválido';
        SET p_id_generado = 0;
        ROLLBACK;
    ELSEIF NOT EXISTS (SELECT 1 FROM Roles WHERE Id = p_rol_id) THEN
        SET p_resultado = 5007;
        SET p_mensaje = 'El rol especificado no existe';
        SET p_id_generado = 0;
        ROLLBACK;
    ELSEIF EXISTS (SELECT 1 FROM Usuarios WHERE UPPER(Email) = UPPER(TRIM(p_email))) THEN
        SET p_resultado = 5008;
        SET p_mensaje = 'Ya existe un usuario con ese email';
        SET p_id_generado = 0;
        ROLLBACK;
    ELSE
        -- Insertar usuario
        INSERT INTO Usuarios (Nombre, Email, RolId) 
        VALUES (TRIM(p_nombre), LOWER(TRIM(p_email)), p_rol_id);
        
        SET p_id_generado = LAST_INSERT_ID();
        SET p_resultado = 0;
        SET p_mensaje = CONCAT('Usuario creado exitosamente con ID: ', p_id_generado);
        
        COMMIT;
    END IF;
END$$

-- PROCEDIMIENTO: LEER USUARIO POR ID (CON CURSOR)
DROP PROCEDURE IF EXISTS PKG_USUARIOS_READ_BY_ID$$
CREATE PROCEDURE PKG_USUARIOS_READ_BY_ID(
    IN p_id INT,
    OUT p_resultado INT,
    OUT p_mensaje VARCHAR(500)
)
READS SQL DATA
SQL SECURITY DEFINER
COMMENT 'Obtener usuario por ID con información del rol usando cursor'
BEGIN
    DECLARE v_count INT DEFAULT 0;
    DECLARE v_user_id INT;
    DECLARE v_user_nombre VARCHAR(255);
    DECLARE v_user_email VARCHAR(255);
    DECLARE v_user_rol_id INT;
    DECLARE v_rol_nombre VARCHAR(100);
    DECLARE done INT DEFAULT FALSE;
    
    DECLARE user_cursor CURSOR FOR
        SELECT 
            u.Id,
            u.Nombre,
            u.Email,
            u.RolId,
            r.Nombre as RolNombre
        FROM Usuarios u
        INNER JOIN Roles r ON u.RolId = r.Id
        WHERE u.Id = p_id;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            p_resultado = MYSQL_ERRNO,
            p_mensaje = MESSAGE_TEXT;
    END;
    
    -- Validar ID
    IF p_id IS NULL OR p_id <= 0 THEN
        SET p_resultado = 6001;
        SET p_mensaje = 'ID inválido';
    ELSE
        SELECT COUNT(*) INTO v_count FROM Usuarios WHERE Id = p_id;
        
        IF v_count = 0 THEN
            SET p_resultado = 6002;
            SET p_mensaje = 'Usuario no encontrado';
        ELSE
            OPEN user_cursor;
            
            read_loop: LOOP
                FETCH user_cursor INTO v_user_id, v_user_nombre, v_user_email, v_user_rol_id, v_rol_nombre;
                IF done THEN
                    LEAVE read_loop;
                END IF;
                
                -- Retornar los datos del cursor
                SELECT v_user_id as Id, v_user_nombre as Nombre, v_user_email as Email, 
                       v_user_rol_id as RolId, v_rol_nombre as RolNombre;
            END LOOP;
            
            CLOSE user_cursor;
            
            SET p_resultado = 0;
            SET p_mensaje = 'Usuario encontrado exitosamente';
        END IF;
    END IF;
END$$

-- PROCEDIMIENTO: LEER TODOS LOS USUARIOS (CON CURSOR)
DROP PROCEDURE IF EXISTS PKG_USUARIOS_READ_ALL$$
CREATE PROCEDURE PKG_USUARIOS_READ_ALL(
    IN p_offset INT,
    IN p_limit INT,
    IN p_rol_id INT,
    OUT p_resultado INT,
    OUT p_mensaje VARCHAR(500),
    OUT p_total_registros INT
)
READS SQL DATA
SQL SECURITY DEFINER
COMMENT 'Obtener todos los usuarios con paginación y filtro por rol usando cursor'
BEGIN
    DECLARE v_user_id INT;
    DECLARE v_user_nombre VARCHAR(255);
    DECLARE v_user_email VARCHAR(255);
    DECLARE v_user_rol_id INT;
    DECLARE v_rol_nombre VARCHAR(100);
    DECLARE done INT DEFAULT FALSE;
    
    DECLARE users_cursor CURSOR FOR
        SELECT 
            u.Id,
            u.Nombre,
            u.Email,
            u.RolId,
            r.Nombre as RolNombre
        FROM Usuarios u
        INNER JOIN Roles r ON u.RolId = r.Id
        WHERE (p_rol_id IS NULL OR u.RolId = p_rol_id)
        ORDER BY u.Nombre
        LIMIT p_limit OFFSET p_offset;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            p_resultado = MYSQL_ERRNO,
            p_mensaje = MESSAGE_TEXT;
    END;
    
    -- Validar parámetros de paginación
    IF p_offset IS NULL OR p_offset < 0 THEN SET p_offset = 0; END IF;
    IF p_limit IS NULL OR p_limit <= 0 OR p_limit > 1000 THEN SET p_limit = 100; END IF;
    
    -- Obtener total para el resultado
    SELECT COUNT(*) INTO p_total_registros 
    FROM Usuarios u
    WHERE (p_rol_id IS NULL OR u.RolId = p_rol_id);
    
    -- Abrir cursor y procesar resultados
    OPEN users_cursor;
    
    read_loop: LOOP
        FETCH users_cursor INTO v_user_id, v_user_nombre, v_user_email, v_user_rol_id, v_rol_nombre;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Retornar cada fila del cursor
        SELECT v_user_id as Id, v_user_nombre as Nombre, v_user_email as Email, 
               v_user_rol_id as RolId, v_rol_nombre as RolNombre;
    END LOOP;
    
    CLOSE users_cursor;
    
    SET p_resultado = 0;
    SET p_mensaje = CONCAT('Se encontraron ', p_total_registros, ' usuarios');
END$$

-- PROCEDIMIENTO: ACTUALIZAR USUARIO
DROP PROCEDURE IF EXISTS PKG_USUARIOS_UPDATE$$
CREATE PROCEDURE PKG_USUARIOS_UPDATE(
    IN p_id INT,
    IN p_nombre VARCHAR(255),
    IN p_email VARCHAR(255),
    IN p_rol_id INT,
    OUT p_resultado INT,
    OUT p_mensaje VARCHAR(500)
)
MODIFIES SQL DATA
SQL SECURITY DEFINER
COMMENT 'Actualizar usuario existente'
BEGIN
    DECLARE v_count INT DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            p_resultado = MYSQL_ERRNO,
            p_mensaje = MESSAGE_TEXT;
    END;
    
    START TRANSACTION;
    
    -- Validaciones básicas
    IF p_id IS NULL OR p_id <= 0 THEN
        SET p_resultado = 7001;
        SET p_mensaje = 'ID inválido';
        ROLLBACK;
    ELSEIF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
        SET p_resultado = 7002;
        SET p_mensaje = 'El nombre del usuario es obligatorio';
        ROLLBACK;
    ELSEIF LENGTH(TRIM(p_nombre)) > 255 THEN
        SET p_resultado = 7003;
        SET p_mensaje = 'El nombre no puede exceder 255 caracteres';
        ROLLBACK;
    ELSEIF p_email IS NULL OR TRIM(p_email) = '' THEN
        SET p_resultado = 7004;
        SET p_mensaje = 'El email es obligatorio';
        ROLLBACK;
    ELSEIF LENGTH(TRIM(p_email)) > 255 THEN
        SET p_resultado = 7005;
        SET p_mensaje = 'El email no puede exceder 255 caracteres';
        ROLLBACK;
    ELSEIF NOT p_email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$' THEN
        SET p_resultado = 7006;
        SET p_mensaje = 'Formato de email inválido';
        ROLLBACK;
    ELSEIF p_rol_id IS NULL OR p_rol_id <= 0 THEN
        SET p_resultado = 7007;
        SET p_mensaje = 'ID de rol inválido';
        ROLLBACK;
    ELSEIF NOT EXISTS (SELECT 1 FROM Roles WHERE Id = p_rol_id) THEN
        SET p_resultado = 7008;
        SET p_mensaje = 'El rol especificado no existe';
        ROLLBACK;
    ELSE
        -- Verificar que el usuario existe
        SELECT COUNT(*) INTO v_count FROM Usuarios WHERE Id = p_id;
        
        IF v_count = 0 THEN
            SET p_resultado = 7009;
            SET p_mensaje = 'Usuario no encontrado';
            ROLLBACK;
        ELSEIF EXISTS (SELECT 1 FROM Usuarios WHERE UPPER(Email) = UPPER(TRIM(p_email)) AND Id != p_id) THEN
            SET p_resultado = 7010;
            SET p_mensaje = 'Ya existe otro usuario con ese email';
            ROLLBACK;
        ELSE
            -- Actualizar usuario
            UPDATE Usuarios 
            SET Nombre = TRIM(p_nombre),
                Email = LOWER(TRIM(p_email)),
                RolId = p_rol_id
            WHERE Id = p_id;
            
            SET p_resultado = 0;
            SET p_mensaje = 'Usuario actualizado exitosamente';
            
            COMMIT;
        END IF;
    END IF;
END$$

-- PROCEDIMIENTO: ELIMINAR USUARIO
DROP PROCEDURE IF EXISTS PKG_USUARIOS_DELETE$$
CREATE PROCEDURE PKG_USUARIOS_DELETE(
    IN p_id INT,
    OUT p_resultado INT,
    OUT p_mensaje VARCHAR(500)
)
MODIFIES SQL DATA
SQL SECURITY DEFINER
COMMENT 'Eliminar usuario'
BEGIN
    DECLARE v_count INT DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            p_resultado = MYSQL_ERRNO,
            p_mensaje = MESSAGE_TEXT;
    END;
    
    START TRANSACTION;
    
    -- Validaciones
    IF p_id IS NULL OR p_id <= 0 THEN
        SET p_resultado = 8001;
        SET p_mensaje = 'ID inválido';
        ROLLBACK;
    ELSE
        -- Verificar que el usuario existe
        SELECT COUNT(*) INTO v_count FROM Usuarios WHERE Id = p_id;
        
        IF v_count = 0 THEN
            SET p_resultado = 8002;
            SET p_mensaje = 'Usuario no encontrado';
            ROLLBACK;
        ELSE
            -- Eliminar usuario
            DELETE FROM Usuarios WHERE Id = p_id;
            
            SET p_resultado = 0;
            SET p_mensaje = 'Usuario eliminado exitosamente';
            COMMIT;
        END IF;
    END IF;
END$$

-- ===================================================================
-- PACKAGE 3: PKG_VARIABLES - CRUD COMPLETO PARA TABLA VARIABLES
-- ===================================================================

-- PROCEDIMIENTO: CREAR VARIABLE
DROP PROCEDURE IF EXISTS PKG_VARIABLES_CREATE$$
CREATE PROCEDURE PKG_VARIABLES_CREATE(
    IN p_nombre VARCHAR(255),
    IN p_valor TEXT,
    IN p_tipo ENUM('texto', 'numerico', 'booleano'),
    OUT p_resultado INT,
    OUT p_mensaje VARCHAR(500),
    OUT p_id_generado INT
)
MODIFIES SQL DATA
SQL SECURITY DEFINER
COMMENT 'Crear nueva variable con validaciones de tipo'
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            p_resultado = MYSQL_ERRNO,
            p_mensaje = MESSAGE_TEXT;
        SET p_id_generado = 0;
    END;
    
    START TRANSACTION;
    
    -- Validaciones básicas
    IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
        SET p_resultado = 9001;
        SET p_mensaje = 'El nombre de la variable es obligatorio';
        SET p_id_generado = 0;
        ROLLBACK;
    ELSEIF LENGTH(TRIM(p_nombre)) > 255 THEN
        SET p_resultado = 9002;
        SET p_mensaje = 'El nombre no puede exceder 255 caracteres';
        SET p_id_generado = 0;
        ROLLBACK;
    ELSEIF p_tipo NOT IN ('texto', 'numerico', 'booleano') THEN
        SET p_resultado = 9003;
        SET p_mensaje = 'Tipo inválido. Debe ser: texto, numerico o booleano';
        SET p_id_generado = 0;
        ROLLBACK;
    ELSEIF EXISTS (SELECT 1 FROM Variables WHERE UPPER(Nombre) = UPPER(TRIM(p_nombre))) THEN
        SET p_resultado = 9004;
        SET p_mensaje = 'Ya existe una variable con ese nombre';
        SET p_id_generado = 0;
        ROLLBACK;
    ELSE
        -- Validaciones específicas por tipo
        CASE p_tipo
            WHEN 'numerico' THEN
                IF p_valor IS NOT NULL AND NOT p_valor REGEXP '^[+-]?[0-9]*\\.?[0-9]+([eE][+-]?[0-9]+)?$' THEN
                    SET p_resultado = 9005;
                    SET p_mensaje = 'El valor no es un número válido';
                    SET p_id_generado = 0;
                    ROLLBACK;
                END IF;
            WHEN 'booleano' THEN
                IF p_valor IS NOT NULL AND p_valor NOT IN ('true', 'false', '1', '0', 'yes', 'no', 'si', 'no') THEN
                    SET p_resultado = 9006;
                    SET p_mensaje = 'El valor booleano debe ser: true/false, 1/0, yes/no, si/no';
                    SET p_id_generado = 0;
                    ROLLBACK;
                END IF;
            ELSE
                -- Para tipo 'texto' no hay validaciones adicionales
                BEGIN END;
        END CASE;
        
        -- Si pasó todas las validaciones, insertar
        IF p_resultado IS NULL THEN
            INSERT INTO Variables (Nombre, Valor, Tipo) 
            VALUES (TRIM(p_nombre), p_valor, p_tipo);
            
            SET p_id_generado = LAST_INSERT_ID();
            SET p_resultado = 0;
            SET p_mensaje = CONCAT('Variable creada exitosamente con ID: ', p_id_generado);
            COMMIT;
        END IF;
    END IF;
END$$

-- PROCEDIMIENTO: LEER VARIABLE POR ID (CON CURSOR)
DROP PROCEDURE IF EXISTS PKG_VARIABLES_READ_BY_ID$$
CREATE PROCEDURE PKG_VARIABLES_READ_BY_ID(
    IN p_id INT,
    OUT p_resultado INT,
    OUT p_mensaje VARCHAR(500)
)
READS SQL DATA
SQL SECURITY DEFINER
COMMENT 'Obtener variable por ID usando cursor'
BEGIN
    DECLARE v_count INT DEFAULT 0;
    DECLARE v_var_id INT;
    DECLARE v_var_nombre VARCHAR(255);
    DECLARE v_var_valor TEXT;
    DECLARE v_var_tipo ENUM('texto', 'numerico', 'booleano');
    DECLARE done INT DEFAULT FALSE;
    
    DECLARE var_cursor CURSOR FOR
        SELECT 
            Id,
            Nombre,
            Valor,
            Tipo
        FROM Variables 
        WHERE Id = p_id;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            p_resultado = MYSQL_ERRNO,
            p_mensaje = MESSAGE_TEXT;
    END;
    
    -- Validar ID
    IF p_id IS NULL OR p_id <= 0 THEN
        SET p_resultado = 10001;
        SET p_mensaje = 'ID inválido';
    ELSE
        SELECT COUNT(*) INTO v_count FROM Variables WHERE Id = p_id;
        
        IF v_count = 0 THEN
            SET p_resultado = 10002;
            SET p_mensaje = 'Variable no encontrada';
        ELSE
            OPEN var_cursor;
            
            read_loop: LOOP
                FETCH var_cursor INTO v_var_id, v_var_nombre, v_var_valor, v_var_tipo;
                IF done THEN
                    LEAVE read_loop;
                END IF;
                
                -- Retornar los datos del cursor
                SELECT v_var_id as Id, v_var_nombre as Nombre, v_var_valor as Valor, v_var_tipo as Tipo;
            END LOOP;
            
            CLOSE var_cursor;
            
            SET p_resultado = 0;
            SET p_mensaje = 'Variable encontrada exitosamente';
        END IF;
    END IF;
END$

-- PROCEDIMIENTO: LEER VARIABLE POR NOMBRE (CON CURSOR)
DROP PROCEDURE IF EXISTS PKG_VARIABLES_READ_BY_NAME$
CREATE PROCEDURE PKG_VARIABLES_READ_BY_NAME(
    IN p_nombre VARCHAR(255),
    OUT p_resultado INT,
    OUT p_mensaje VARCHAR(500)
)
READS SQL DATA
SQL SECURITY DEFINER
COMMENT 'Obtener variable por nombre usando cursor'
BEGIN
    DECLARE v_count INT DEFAULT 0;
    DECLARE v_var_id INT;
    DECLARE v_var_nombre VARCHAR(255);
    DECLARE v_var_valor TEXT;
    DECLARE v_var_tipo ENUM('texto', 'numerico', 'booleano');
    DECLARE done INT DEFAULT FALSE;
    
    DECLARE var_cursor CURSOR FOR
        SELECT 
            Id,
            Nombre,
            Valor,
            Tipo
        FROM Variables 
        WHERE UPPER(Nombre) = UPPER(TRIM(p_nombre));
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            p_resultado = MYSQL_ERRNO,
            p_mensaje = MESSAGE_TEXT;
    END;
    
    -- Validar nombre
    IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
        SET p_resultado = 10003;
        SET p_mensaje = 'Nombre inválido';
    ELSE
        SELECT COUNT(*) INTO v_count FROM Variables WHERE UPPER(Nombre) = UPPER(TRIM(p_nombre));
        
        IF v_count = 0 THEN
            SET p_resultado = 10004;
            SET p_mensaje = 'Variable no encontrada';
        ELSE
            OPEN var_cursor;
            
            read_loop: LOOP
                FETCH var_cursor INTO v_var_id, v_var_nombre, v_var_valor, v_var_tipo;
                IF done THEN
                    LEAVE read_loop;
                END IF;
                
                -- Retornar los datos del cursor
                SELECT v_var_id as Id, v_var_nombre as Nombre, v_var_valor as Valor, v_var_tipo as Tipo;
            END LOOP;
            
            CLOSE var_cursor;
            
            SET p_resultado = 0;
            SET p_mensaje = 'Variable encontrada exitosamente';
        END IF;
    END IF;
END$

-- PROCEDIMIENTO: LEER TODAS LAS VARIABLES (CON CURSOR)
DROP PROCEDURE IF EXISTS PKG_VARIABLES_READ_ALL$
CREATE PROCEDURE PKG_VARIABLES_READ_ALL(
    IN p_offset INT,
    IN p_limit INT,
    IN p_tipo ENUM('texto', 'numerico', 'booleano'),
    OUT p_resultado INT,
    OUT p_mensaje VARCHAR(500),
    OUT p_total_registros INT
)
READS SQL DATA
SQL SECURITY DEFINER
COMMENT 'Obtener todas las variables con paginación y filtro por tipo usando cursor'
BEGIN
    DECLARE v_var_id INT;
    DECLARE v_var_nombre VARCHAR(255);
    DECLARE v_var_valor TEXT;
    DECLARE v_var_tipo ENUM('texto', 'numerico', 'booleano');
    DECLARE done INT DEFAULT FALSE;
    
    DECLARE vars_cursor CURSOR FOR
        SELECT 
            Id,
            Nombre,
            Valor,
            Tipo
        FROM Variables
        WHERE (p_tipo IS NULL OR Tipo = p_tipo)
        ORDER BY Tipo, Nombre
        LIMIT p_limit OFFSET p_offset;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            p_resultado = MYSQL_ERRNO,
            p_mensaje = MESSAGE_TEXT;
    END;
    
    -- Validar parámetros de paginación
    IF p_offset IS NULL OR p_offset < 0 THEN SET p_offset = 0; END IF;
    IF p_limit IS NULL OR p_limit <= 0 OR p_limit > 1000 THEN SET p_limit = 100; END IF;
    
    -- Obtener total de registros
    SELECT COUNT(*) INTO p_total_registros 
    FROM Variables 
    WHERE (p_tipo IS NULL OR Tipo = p_tipo);
    
    -- Abrir cursor y procesar resultados
    OPEN vars_cursor;
    
    read_loop: LOOP
        FETCH vars_cursor INTO v_var_id, v_var_nombre, v_var_valor, v_var_tipo;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Retornar cada fila del cursor
        SELECT v_var_id as Id, v_var_nombre as Nombre, v_var_valor as Valor, v_var_tipo as Tipo;
    END LOOP;
    
    CLOSE vars_cursor;
    
    SET p_resultado = 0;
    SET p_mensaje = CONCAT('Se encontraron ', p_total_registros, ' variables');
END$

-- PROCEDIMIENTO: ACTUALIZAR VARIABLE
DROP PROCEDURE IF EXISTS PKG_VARIABLES_UPDATE$
CREATE PROCEDURE PKG_VARIABLES_UPDATE(
    IN p_id INT,
    IN p_nombre VARCHAR(255),
    IN p_valor TEXT,
    IN p_tipo ENUM('texto', 'numerico', 'booleano'),
    OUT p_resultado INT,
    OUT p_mensaje VARCHAR(500)
)
MODIFIES SQL DATA
SQL SECURITY DEFINER
COMMENT 'Actualizar variable existente'
BEGIN
    DECLARE v_count INT DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            p_resultado = MYSQL_ERRNO,
            p_mensaje = MESSAGE_TEXT;
    END;
    
    START TRANSACTION;
    
    -- Validaciones básicas
    IF p_id IS NULL OR p_id <= 0 THEN
        SET p_resultado = 11001;
        SET p_mensaje = 'ID inválido';
        ROLLBACK;
    ELSEIF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
        SET p_resultado = 11002;
        SET p_mensaje = 'El nombre de la variable es obligatorio';
        ROLLBACK;
    ELSEIF LENGTH(TRIM(p_nombre)) > 255 THEN
        SET p_resultado = 11003;
        SET p_mensaje = 'El nombre no puede exceder 255 caracteres';
        ROLLBACK;
    ELSEIF p_tipo NOT IN ('texto', 'numerico', 'booleano') THEN
        SET p_resultado = 11004;
        SET p_mensaje = 'Tipo inválido. Debe ser: texto, numerico o booleano';
        ROLLBACK;
    ELSE
        -- Verificar que la variable existe
        SELECT COUNT(*) INTO v_count FROM Variables WHERE Id = p_id;
        
        IF v_count = 0 THEN
            SET p_resultado = 11005;
            SET p_mensaje = 'Variable no encontrada';
            ROLLBACK;
        ELSEIF EXISTS (SELECT 1 FROM Variables WHERE UPPER(Nombre) = UPPER(TRIM(p_nombre)) AND Id != p_id) THEN
            SET p_resultado = 11006;
            SET p_mensaje = 'Ya existe otra variable con ese nombre';
            ROLLBACK;
        ELSE
            -- Validaciones específicas por tipo
            CASE p_tipo
                WHEN 'numerico' THEN
                    IF p_valor IS NOT NULL AND NOT p_valor REGEXP '^[+-]?[0-9]*\\.?[0-9]+([eE][+-]?[0-9]+)?' THEN
                        SET p_resultado = 11007;
                        SET p_mensaje = 'El valor no es un número válido';
                        ROLLBACK;
                    END IF;
                WHEN 'booleano' THEN
                    IF p_valor IS NOT NULL AND p_valor NOT IN ('true', 'false', '1', '0', 'yes', 'no', 'si', 'no') THEN
                        SET p_resultado = 11008;
                        SET p_mensaje = 'El valor booleano debe ser: true/false, 1/0, yes/no, si/no';
                        ROLLBACK;
                    END IF;
                ELSE
                    -- Para tipo 'texto' no hay validaciones adicionales
                    BEGIN END;
            END CASE;
            
            -- Si pasó todas las validaciones
            IF p_resultado IS NULL THEN
                -- Actualizar variable
                UPDATE Variables 
                SET Nombre = TRIM(p_nombre),
                    Valor = p_valor,
                    Tipo = p_tipo
                WHERE Id = p_id;
                
                SET p_resultado = 0;
                SET p_mensaje = 'Variable actualizada exitosamente';
                COMMIT;
            END IF;
        END IF;
    END IF;
END$

-- PROCEDIMIENTO: ELIMINAR VARIABLE
DROP PROCEDURE IF EXISTS PKG_VARIABLES_DELETE$
CREATE PROCEDURE PKG_VARIABLES_DELETE(
    IN p_id INT,
    OUT p_resultado INT,
    OUT p_mensaje VARCHAR(500)
)
MODIFIES SQL DATA
SQL SECURITY DEFINER
COMMENT 'Eliminar variable'
BEGIN
    DECLARE v_count INT DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            p_resultado = MYSQL_ERRNO,
            p_mensaje = MESSAGE_TEXT;
    END;
    
    START TRANSACTION;
    
    -- Validaciones
    IF p_id IS NULL OR p_id <= 0 THEN
        SET p_resultado = 12001;
        SET p_mensaje = 'ID inválido';
        ROLLBACK;
    ELSE
        -- Verificar que la variable existe
        SELECT COUNT(*) INTO v_count FROM Variables WHERE Id = p_id;
        
        IF v_count = 0 THEN
            SET p_resultado = 12002;
            SET p_mensaje = 'Variable no encontrada';
            ROLLBACK;
        ELSE
            -- Eliminar variable
            DELETE FROM Variables WHERE Id = p_id;
            
            SET p_resultado = 0;
            SET p_mensaje = 'Variable eliminada exitosamente';
            COMMIT;
        END IF;
    END IF;
END$


-- Restaurar delimitador original
DELIMITER ;