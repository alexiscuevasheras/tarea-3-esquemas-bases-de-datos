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

	-- Restriccion: la contrasena no puede ser ni el nombre ni el apellido del usuario.
	-- Se usa SHA256 sobre ambos lados con UPPER y TRIM para que la comparacion sea case-insensitive

	CONSTRAINT contrasena_no_nombre CHECK (SHA256(UPPER(TRIM(contrasena))::BYTEA) != SHA256(UPPER(TRIM(nombre))::BYTEA)),
	CONSTRAINT contrasena_no_apellido CHECK (SHA256(UPPER(TRIM(contrasena))::BYTEA) != SHA256(UPPER(TRIM(apellido))::BYTEA))
);

--- Proyecto 

CREATE TABLE proyecto (
	id BIGSERIAL PRIMARY KEY,
	nombre VARCHAR(100) NOT NULL,
	instrucciones TEXT,
	usuario_id BIGINT NOT NULL,

	-- No se debe eliminar un usuario que tiene proyectos; primero se deben borrar o reasignar sus proyectos de forma explicita.
	-- No se permite modificar el id del usuario referenciado ya que es autogenerado y no deberia cambiar.
	
	FOREIGN KEY (usuario_id) REFERENCES usuario (id) ON DELETE RESTRICT ON UPDATE RESTRICT
);

--- Conversacion 

CREATE TABLE conversacion (
	id BIGSERIAL PRIMARY KEY,
	titulo VARCHAR(100) NOT NULL,
	modelo_id BIGINT NOT NULL,
	proyecto_id BIGINT NOT NULL,

	-- No se puede eliminar un modelo que esta en uso por conversaciones activas (hacerlo dejaria conversaciones sin modelo asignado).
	
	FOREIGN KEY (modelo_id) REFERENCES modelo (id) ON DELETE RESTRICT ON UPDATE RESTRICT,

	-- No se puede eliminar un proyecto que tiene conversaciones asociadas, primero se deben eliminar o reasignar las conversaciones.
	FOREIGN KEY (proyecto_id) REFERENCES proyecto (id) ON DELETE RESTRICT ON UPDATE RESTRICT
);

--- Respuesta 

CREATE TABLE respuesta (
	id BIGSERIAL PRIMARY KEY,
	conversacion_id BIGINT NOT NULL,
	contenido TEXT NOT NULL,
	fecha_creacion TIMESTAMP NOT NULL,

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

	-- Restriccion: un usuario no puede repetirse en la misma conversacion
	UNIQUE(usuario_id, conversacion_id),

	-- No se debe eliminar una conversacion que tiene participantes registrados, primero se deben eliminar las participaciones de forma explicita.
	FOREIGN KEY (conversacion_id) REFERENCES conversacion (id) ON DELETE RESTRICT ON UPDATE RESTRICT,

	-- No se puede eliminar un usuario que participa en conversaciones, primero se deben eliminar sus participaciones.
	FOREIGN KEY (usuario_id) REFERENCES usuario (id) ON DELETE RESTRICT ON UPDATE RESTRICT
);

--- Mensaje 

CREATE TABLE mensaje (
	id BIGSERIAL PRIMARY KEY,
	participacion_id BIGINT NOT NULL,
	contenido TEXT NOT NULL,
	fecha_creacion TIMESTAMP NOT NULL,

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

	-- No se puede eliminar un usuario que tiene memorias almacenadas, ya que las memorias contienen informacion persistente que debe eliminarse de forma explicita antes de borrar al usuario.
	FOREIGN KEY (usuario_id) REFERENCES usuario (id) ON DELETE RESTRICT ON UPDATE RESTRICT
);
