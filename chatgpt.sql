DROP TABLE IF EXISTS mensaje CASCADE;
DROP TABLE IF EXISTS memoria CASCADE;
DROP TABLE IF EXISTS participacion CASCADE;
DROP TABLE IF EXISTS respuesta CASCADE;
DROP TABLE IF EXISTS conversacion CASCADE;
DROP TABLE IF EXISTS proyecto CASCADE;
DROP TABLE IF EXISTS modelo CASCADE;
DROP TABLE IF EXISTS usuario CASCADE;

--- Modelo

CREATE TABLE modelo (
	id BIGSERIAL PRIMARY KEY,
	nombre VARCHAR(100) NOT NULL,
	descripcion VARCHAR(300) NOT NULL,
	es_premium BOOLEAN NOT NULL DEFAULT TRUE,
	conexion VARCHAR(100) NOT NULL,

	-- Restriccion: la conexion debe empezar con https://
	CONSTRAINT conexion_https CHECK (conexion LIKE 'https://%')
);

--- Usuario

CREATE TABLE usuario (
	id BIGSERIAL PRIMARY KEY,
	nombre VARCHAR(100) NOT NULL,
	apellido VARCHAR(100) NOT NULL,
	correo VARCHAR(254) NOT NULL,
	contrasena VARCHAR(100) NOT NULL,

	-- Restriccion: la contrasena no puede ser ni el nombre ni el apellido del usuario y no se puede repetir el mismo mail para dos usuarios
	--<(@.@)>
    CONSTRAINT unico_correo UNIQUE (correo),
	CONSTRAINT contrasena_no_nombre CHECK (contrasena != SHA256(nombre::BYTEA)),
	CONSTRAINT contrasena_no_apellido CHECK (contrasena != SHA256(apellido::BYTEA))
);

--- Proyecto

CREATE TABLE proyecto (
	id BIGSERIAL PRIMARY KEY,
	nombre VARCHAR(100) NOT NULL,
	instrucciones TEXT, --puede ser NULL
	usuario_id BIGINT NOT NULL,

    --Llaves foraneas
	-- Si se elimina un usuario se eliminan sus proyectos también
	-- No se permite modificar el id del usuario referenciado ya que es autogenerado y no deberia cambiar.

	FOREIGN KEY (usuario_id) REFERENCES usuario (id) ON DELETE CASCADE ON UPDATE RESTRICT
);

--- Conversacion

CREATE TABLE conversacion (
	id BIGSERIAL PRIMARY KEY,
	titulo VARCHAR(100) NOT NULL,
	modelo_id BIGINT NOT NULL,
	proyecto_id BIGINT NOT NULL,

    --Llaves foraneas

	-- No se puede eliminar un modelo que esta en uso por conversaciones activas (hacerlo dejaria conversaciones sin modelo asignado).
	FOREIGN KEY (modelo_id) REFERENCES modelo (id) ON DELETE RESTRICT ON UPDATE RESTRICT,

	-- Si se elimina un proyecto se eliminan sus conversaciones
	FOREIGN KEY (proyecto_id) REFERENCES proyecto (id) ON DELETE CASCADE ON UPDATE RESTRICT
);

--- Respuesta

CREATE TABLE respuesta (
	id BIGSERIAL PRIMARY KEY,
	conversacion_id BIGINT NOT NULL,
	contenido TEXT NOT NULL,
	fecha_creacion TIMESTAMP NOT NULL,

    --Llaves foraneas
	-- Si se elimina una conversacion, sus respuestas generadas por el modelo pierden sentido fuera de ese contexto, por lo que se eliminan en cascada.
	-- Se restringe la actualizacion del id ya que es autogenerado.
	FOREIGN KEY (conversacion_id) REFERENCES conversacion (id) ON DELETE CASCADE ON UPDATE RESTRICT
);

--- Participacion

CREATE TABLE participacion (
	id BIGSERIAL PRIMARY KEY,
	conversacion_id BIGINT NOT NULL,
	usuario_id BIGINT NOT NULL,
	rol VARCHAR(1) NOT NULL,


	-- Restriccion: <(@.@)> un usuario no puede repetirse en la misma conversacion
    --Asegurarse de que el rol no es una cadena vacía
	CONSTRAINT usuario_conversacion_unico UNIQUE(usuario_id, conversacion_id),
    CONSTRAINT rol_valido CHECK (rol != ''),
    --Llaves foraneas
	-- Si se elimina una conversacion, se eliminan las participaciones
	FOREIGN KEY (conversacion_id) REFERENCES conversacion (id) ON DELETE CASCADE ON UPDATE RESTRICT,

	-- Si no hay usuario no hay participaciones, entonces se eliminan en cascada
	FOREIGN KEY (usuario_id) REFERENCES usuario (id) ON DELETE CASCADE ON UPDATE RESTRICT
);

CREATE TABLE mensaje (
	id BIGSERIAL PRIMARY KEY,
	participacion_id BIGINT NOT NULL,
	contenido TEXT NOT NULL,
	fecha_creacion TIMESTAMP NOT NULL,

    --Llaves foraneas
	-- Si se elimina una participacion, los mensajes enviados por ese participante en esa conversacion se eliminan en cascada, ya que no hace sentido un mensaje sin participante asociado.
	-- Se restringe la actualizacion del id ya que es autogenerado.
	FOREIGN KEY (participacion_id) REFERENCES participacion (id) ON DELETE CASCADE ON UPDATE RESTRICT
);

--- Memoria

CREATE TABLE memoria (
	id BIGSERIAL PRIMARY KEY,
	nombre VARCHAR(100) NOT NULL,
	contenido TEXT NOT NULL,
	usuario_id BIGINT NOT NULL,

    --Llaves foraneas
	--Si se elimina un usuario no tiene sentido mantener las memorias, entonces se eliminan en cascada
	FOREIGN KEY (usuario_id) REFERENCES usuario (id) ON DELETE CASCADE ON UPDATE RESTRICT
);

-- POOL DE PRUEBAS
-- QUE NO DEBERÍA FUNCIONAR
-- variacion con nombre
INSERT INTO usuario (nombre, apellido, correo, contrasena)
VALUES ('Ben', 'Zimbron', 'benvoy@ggitam.mx', 'ben');

INSERT INTO usuario (nombre, apellido, correo, contrasena)
VALUES ('Ben', 'Zimbron', 'benvoy2@ggitam.mx', 'BEN');

INSERT INTO usuario (nombre, apellido, correo, contrasena)
VALUES ('Ben', 'Zimbron', 'benvoy3@ggitam.mx', 'BeN');

INSERT INTO usuario (nombre, apellido, correo, contrasena)
VALUES ('Ben', 'Zimbron', 'benvoy4@ggitam.mx', 'bEn');


-- variacion con apellido
INSERT INTO usuario (nombre, apellido, correo, contrasena)
VALUES ('Ben', 'Zimbron', 'benvoy5@ggitam.mx', 'zimbron');

INSERT INTO usuario (nombre, apellido, correo, contrasena)
VALUES ('Ben', 'Zimbron', 'benvoy6@ggitam.mx', 'ZIMBRON');

INSERT INTO usuario (nombre, apellido, correo, contrasena)
VALUES ('Ben', 'Zimbron', 'benvoy7@ggitam.mx', 'ZiMbRoN');

INSERT INTO usuario (nombre, apellido, correo, contrasena)
VALUES ('Ben', 'Zimbron', 'benvoy8@ggitam.mx', 'zImBrOn');


-- casos validos
INSERT INTO usuario (nombre, apellido, correo, contrasena)
VALUES ('Ben', 'Zimbron', 'benvoy9@ggitam.mx', 'maslogro');

INSERT INTO usuario (nombre, apellido, correo, contrasena)
VALUES ('Ben', 'Zimbron', 'benvoy10@ggitam.mx', 'masLogro');

INSERT INTO usuario (nombre, apellido, correo, contrasena)
VALUES ('Ben', 'Zimbron', 'benvoy11@ggitam.mx', 'MasLogro123');

INSERT INTO usuario (nombre, apellido, correo, contrasena)
VALUES ('Ben', 'Zimbron', 'benvoy12@ggitam.mx', 'logroBen');

INSERT INTO usuario (nombre, apellido, correo, contrasena)
VALUES ('Ben', 'Zimbron', 'benvoy13@ggitam.mx', '123zimbron');