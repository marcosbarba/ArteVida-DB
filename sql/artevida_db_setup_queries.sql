DROP DATABASE IF EXISTS ArteVidaCultural;
CREATE DATABASE ArteVidaCultural;
USE ArteVidaCultural;

/*----------------------------------------------------------------------------
Marcos Barba Ballarin
ArteVida Cultural
------------------------------------------------------------------------------*/



/*----------------------------------------------------------------------------
Definición de la estructura de la base de datos
------------------------------------------------------------------------------*/

CREATE TABLE ubicacion (
	idUbi smallint auto_increment primary key, -- ID autonumerado ubicacion.
    nomUbi varchar(50) not null, -- Nombre de la ubicación.
    direccion varchar(40) not null, -- Dirección de la ubicación.
    poblacion varchar(20) not null, -- Nombre del pueblo o ciudad donde se encuentra la ubicación.
    caractUbi text not null, -- Caracteristicas de la ubicación.
    aforo int not null check (aforo>0), -- Aforo de la ubicación, comprobacion positivo.
    precio_alquiler numeric(11,2) not null check (precio_alquiler>=0) -- Precio del alquiler de la ubicación, comprobación >=0.
	);
    
CREATE TABLE persona(
	idPers int auto_increment primary key, -- ID autonumerado persona.
    nomPers varchar(20) not null, -- Nombre de pila de la persona.
    ap1Pers varchar(20) not null, -- Primer apellido de la persona.
    ap2Pers varchar(20) not null -- Segundo apellido de la persona.
    );

CREATE TABLE artista(
	idArtis smallint auto_increment primary key, -- ID autonumerado artista.
    nomArtis varchar(60) not null, -- Nombre del artista.
    biografia text not null -- Biografía del artista.
    );
    
CREATE TABLE genero(
	idGenero smallint auto_increment primary key, -- ID autonumerado genero.
    nomGenero varchar(40) not null -- Genero del tipo de actividad (pop, blues, rock,... para conciertos de musica; drama, comedia,... para Obras de teatro)
    );

CREATE TABLE tipo(
	idTipo smallint auto_increment primary key, -- ID autonumerado tipo de actividad.
    nomTipo varchar(40) not null, -- Tipo de actividad (Concierto de música, Exposición, Obra de Teatro, Conferencia)
    idGenero smallint, -- (FK) ID del género del tipo de actividad. Puede ser NULL (no todas los tipos de actividad tienen género).
    foreign key(idGenero) references genero(idGenero) on delete set null on update cascade -- Si se elimina un genero de la tabla, los tipos que lo llevan se ponen NULL. Se actualiza en cascada.
    );
    
CREATE TABLE actividad(
	idActiv smallint auto_increment primary key, -- ID autonumerado actividad.
    idTipo smallint not null, -- (FK) ID del tipo de actividad, NOT NULL porque una actividad tiene que tener un tipo.
    nomActiv varchar(100) not null, -- Nombre de la actividad
    foreign key(idTipo) references tipo(idTipo) on delete cascade on update cascade -- Si se elimina o actualiza un tipo de actividad, se elimina o actualiza en la tabla actividad.
    );
    
CREATE TABLE evento(
	idEvent smallint auto_increment primary key, -- ID autonumerado evento.
    nomEvent varchar(100) not null, -- Nombre del evento.
    idUbi smallint not null, -- (FK) ID de la ubicación del evento, NOT NULL porque un evento tiene que tener una ubicación.
    idActiv smallint not null, -- (FK) ID de la actividad que se organiza en el evento, NOT NULL porque un evento tiene que tener una actividad.
    descrEvent text not null, -- Descripción del evento
    momEvent timestamp not null, -- Fecha y hora del evento
    precio_entrada numeric(7,2) check (precio_entrada>=0), -- Precio de la entrada. Comprobación de que no es negativo (puede haber un evento gratuito).
    foreign key(idUbi) references ubicacion(idUbi) on delete cascade on update cascade, -- Si se elimina o actualiza una ubicación, se elimina o actualiza en la tabla evento.
    foreign key(idActiv) references actividad(idActiv) on delete cascade on update cascade	-- Si se elimina o actualiza una actividad, se elimina o actualiza en la tabla evento.
    );

CREATE TABLE telefono( -- Tabla de entidad multivalorada telefono.
	idTelf smallint auto_increment primary key, -- ID autonumerado telefono.
    idPers int not null, -- (FK) ID persona a la que corresponde el telefono, NOT NULL porque el telefono tiene que corresponder a alguien.
    telf  varchar(9) unique not null check(telf REGEXP '^[0-9]{9}$'), -- Se comprueba el formato de telefono. UNIQUE porque tiene que ser distinto del resto de telefonos.
    foreign key(idPers) references persona(idPers) on delete cascade on update cascade -- Si se elimina o actualiza una persona, se elimina o actualiza en la tabla telefono.
    );
    
CREATE TABLE email(
	idMail smallint auto_increment primary key, -- ID autonumeradao email.
    idPers int, -- (FK) ID persona a la que corresponde el email, NOT NULL porque el email tiene que corresponder a alguien.
	mail varchar(50) unique not null check (mail REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'), -- Se comprueba el formato de email. UNIQUE porque tiene que ser distinto del resto de emails.
    foreign key(idPers) references persona(idPers) on delete cascade on update cascade -- Si se elimina o actualiza una persona, se elimina o actualiza en la tabla email.
    );

CREATE TABLE asisten(
	idEvent smallint, -- (FK) ID del evento al que asiste la persona.
    idPers int, -- (FK) ID de la persona que asiste al evento.
    valoracion smallint check (valoracion between 0 and 5), -- Valoración que el asistente pone al evento (0 a 5).
	primary key(idEvent, idPers), -- ID de persona y evento identifican de forma única cada asistenica. Claves primarias de la tabla asisten, por eso no necesitamos el NOT NULL en la definicion.
    foreign key(idEvent) references evento(idEvent) on delete cascade on update cascade, -- Si se elimina o actualiza un evento, se elimina o acutaliza en la tabla asisten.
    foreign key(idPers) references persona(idPers) on delete cascade on update cascade -- Si se elimina o actualiza una persona, se elimina o actualiza en la tabla asisten.
    );
    
CREATE TABLE participa(
	idActiv smallint, -- (FK) ID de la actividad en la que participa el artista.
    idArtis smallint, -- (FK) ID del artista que participa en la actividad.
    cache numeric(6,2) check (cache>=0), -- Cache del artista para la actividad en la que participa. Comprobación de que no es negativo (podría haber una participación gratuita).
	primary key(idActiv, idArtis), -- ID de actividad y artista identifican de forma única cada participación. Claves primarias de la tabla participa, por eso no necesitamos el NOT NULL en la definición.
    foreign key(idActiv) references actividad(idActiv) on delete cascade on update cascade, -- Si se elimina o actualiza una actividad, se elimina o actualiza en la tabla participa.
    foreign key(idArtis) references artista(idArtis) on delete cascade on update cascade -- Si se elimina o actualiza un artista, se elimina o actualiza en la tabla participa.
    );



/*----------------------------------------------------------------------------
Creamos el TRIGGER que comprueba BEFORE INSERT en asiste que no se supera
el aforo de la ubicación en la que se realiza el evento.
------------------------------------------------------------------------------*/

DELIMITER //

CREATE TRIGGER compruebaAsisteAforo before insert on asisten for each row
    begin
    
		if (select count(*)
			from asisten
			where idEvent=new.idEvent) -- Contamos las instancias de asisten con un mismo idEvent (personas que asisten a la actividad).
            >= 
            (select ubi.aforo
			from evento eve inner join ubicacion ubi on eve.idUbi=ubi.idUbi
			where eve.idEvent=new.idEvent) then -- Seleccionamos el aforo de la ubicación en la que se realiza el evento.
            
            -- En caso de que el aforo ya este completo, damos error para añadir un nuevo asistente:
            
			signal sqlstate '45000'
			set message_text = 'No se pueden agregar asistentes, el aforo esta completo';
			end if;
	end //

DELIMITER ;



/*----------------------------------------------------------------------------
Inserción de datos
------------------------------------------------------------------------------*/

INSERT INTO ubicacion (nomUbi, direccion, poblacion, caractUbi, aforo, precio_alquiler) VALUES
('Estadio Santiago Bernabeu', 'Av. de Concha Espina, 1', 'Madrid', 'Estadio de fútbol del Real Madrid, con césped natural y gradas cubiertas', 81044, 50000.00),
('Teatro María Guerrero', 'Calle de Huertas, 28', 'Madrid', 'Teatro clásico con capacidad media, ideal para obras de teatro y conciertos pequeños', 700, 2000.00),
('Auditorio Nacional de Música', 'C/ del Príncipe de Vergara, 146', 'Madrid', 'Auditorio para conciertos sinfónicos y recitales, con excelente acústica', 2175, 3500.00),
('Sala Galileo Galilei', 'Calle Galileo, 100', 'Madrid', 'Sala de conciertos de mediano tamaño, popular para música alternativa y teatro', 500, 1200.00),
('Palacio de Deportes de la Comunidad', 'C/ Goya, 5', 'Madrid', 'Recinto polideportivo con capacidad para eventos masivos y conciertos', 15500, 15000.00),
('Teatro Lope de Vega', 'Calle Gran Vía, 57', 'Madrid', 'Teatro histórico en pleno centro, especializado en musicales y obras clásicas', 1500, 2500.00);

INSERT INTO persona (nomPers, ap1Pers, ap2Pers) VALUES
('Ana', 'García', 'López'),
('Carlos', 'Martínez', 'Sánchez'),
('Lucía', 'Fernández', 'Ruiz'),
('Miguel', 'Hernández', 'Pérez'),
('Laura', 'Gómez', 'Vega'),
('Javier', 'Díaz', 'Castro'),
('Sofía', 'Jiménez', 'Morales'),
('David', 'Romero', 'Ortiz'),
('María', 'Santos', 'Ramos'),
('Antonio', 'Cruz', 'Luna'),
('Elena', 'Navarro', 'Serrano'),
('Pablo', 'Molina', 'Torres'),
('Carmen', 'Rojas', 'Rey'),
('Ricardo', 'Blanco', 'Méndez'),
('Isabel', 'Vargas', 'Fuentes');

INSERT INTO artista (nomArtis, biografia) VALUES
('Pablo Alarcón', 'Pintor contemporáneo especializado en arte abstracto, con exposiciones en varias galerías internacionales.'),
('Marina Torres', 'Cantante y compositora de música pop, conocida por su potente voz y sus giras nacionales.'),
('Javier Muñoz', 'Actor de teatro clásico y moderno, con más de 15 años de trayectoria en compañías nacionales.'),
('Elena Rivas', 'Bailarina de danza contemporánea, premiada en concursos internacionales y colaboradora de compañías de renombre.'),
('Carlos Herrera', 'Músico de jazz y saxofonista, con varios discos grabados y actuaciones en festivales europeos.'),
('Lucía Fernández', 'Actriz de cine y televisión, ha participado en varias películas independientes y series televisivas.'),
('Miguel Ángel Soto', 'Escultor reconocido por sus obras en metal y madera, expuestas en museos y espacios públicos.'),
('Sofía Navarro', 'Cantante de ópera, con formación en conservatorios europeos y numerosas actuaciones en teatros líricos.'),
('David Romero', 'Fotógrafo especializado en retratos y fotografía urbana, con publicaciones en revistas de arte.'),
('Ana López', 'Coreógrafa y profesora de danza contemporánea, creadora de obras premiadas en festivales de danza.');

INSERT INTO genero (idGenero, nomGenero) VALUES
(1, 'Clásica'),
(2, 'Pop'),
(3, 'Blues'),
(4, 'Soul'),
(5, 'Rock and Roll'),
(6, 'Jazz'),
(7, 'Reggaeton'),
(8, 'Gospel'),
(9, 'Country'),
(10, 'Pintura'),
(11, 'Drama'),
(12, 'Comedia'),
(13, 'Ciencia');

INSERT INTO tipo (nomTipo, idGenero) VALUES
('Conciertos de música', 1),   -- Clásica
('Conciertos de música', 2),   -- Pop
('Conciertos de música', 3),   -- Blues
('Conciertos de música', 4),   -- Soul
('Conciertos de música', 5),   -- Rock and Roll
('Conciertos de música', 6),   -- Jazz
('Conciertos de música', 7),   -- Reggaeton
('Conciertos de música', 8),   -- Gospel
('Conciertos de música', 9),   -- Country
('Exposiciones', 10),          -- Pintura
('Exposiciones', NULL),        -- sin género
('Obras de teatro', 11),       -- Drama
('Obras de teatro', 12),       -- Comedia
('Conferencias', 13),          -- Ciencia
('Conferencias', NULL);        -- sin género

INSERT INTO actividad (idTipo, nomActiv) VALUES
(1,  'Concierto de música clásica'),
(2,  'Concierto de música pop'),
(3,  'Concierto de blues'),
(4,  'Concierto de soul'),
(5,  'Concierto de rock and roll'),
(6,  'Concierto de jazz'),
(7,  'Concierto de reggaeton'),
(8,  'Concierto de gospel'),
(9,  'Concierto de country'),
(10, 'Exposición de arte contemporáneo'),
(11, 'Exposición'),
(12, 'Obra de teatro dramática'),
(13, 'Obra de teatro cómica'),
(14, 'Conferencia científica'),
(15, 'Conferencia');

INSERT INTO evento (nomEvent, idUbi, idActiv, descrEvent, momEvent, precio_entrada) VALUES
('Festival Clásico de Primavera', 3, 1, 'Concierto de música clásica con la Orquesta Nacional de España', '2025-05-10 20:00:00', 45.00),
('Pop Fest 2025', 1, 2, 'Festival de música pop con artistas nacionales e internacionales', '2025-06-15 18:00:00', 60.00),
('Blues Night', 5, 3, 'Noche de blues con bandas invitadas', '2025-07-01 20:00:00', 30.00),
('Soul Experience', 4, 4, 'Concierto de soul con voces destacadas de la escena local', '2025-07-01 21:00:00', 28.00),
('Rock & Roll Night', 1, 5, 'Evento de rock clásico con bandas tributo y DJ', '2025-08-12 21:00:00', 40.00),
('Jazz en el Parque', 5, 6, 'Concierto de jazz al aire libre con bandas nacionales', '2025-07-15 19:00:00', 25.00),
('Reggaeton Summer Party', 1, 7, 'Concierto de reggaeton con DJs y artistas invitados', '2025-08-12 22:00:00', 50.00),
('Gospel Voices Madrid', 2, 8, 'Coro gospel internacional en una actuación única', '2025-09-20 19:30:00', 35.00),
('Country Night Live', 4, 9, 'Noche de country con artistas nacionales e internacionales', '2025-10-05 20:00:00', 32.00),
('V Congreso de Arte Contemporáneo', 4, 10, 'Exposición colectiva de artistas contemporáneos', '2025-09-10 10:00:00', 12.00),
('Exposición Urbana de Fotografía', 4, 11, 'Exposición fotográfica de artistas locales', '2025-09-01 11:00:00', 8.00),
('Drama en Escena', 2, 12, 'Obra dramática clásica con actores reconocidos', '2025-09-05 20:00:00', 25.00),
('Obra de Teatro: La Casa de los Sueños', 2, 13, 'Comedia teatral interpretada por la compañía local', '2025-03-18 19:30:00', 20.00),
('Conferencia sobre Innovación Tecnológica', 3, 14, 'Ponencia sobre avances en tecnología y startups', '2025-10-10 17:00:00', 15.00),
('Charla Motivacional', 6, 15, 'Evento inspirador con conferencista invitado', '2025-11-20 18:00:00', 10.00);


INSERT INTO telefono (idPers, telf) VALUES
(1, '612345678'),
(1, '698765432'),
(2, '623456789'),
(3, '634567890'),
(4, '645678901'),
(5, '656789012'),
(6, '667890123'),
(7, '678901234'),
(8, '689012345'),
(9, '690123456'),
(10, '601234567'),
(10, '602345678'),
(11, '603456789'),
(12, '604567890'),
(13, '605678901'),
(14, '606789012'),
(15, '607890123');

INSERT INTO email (idPers, mail) VALUES
(1, 'ana.garcia@example.com'),
(1, 'ana.garcia.trabajo@example.com'),
(2, 'carlos.martinez@example.com'),
(3, 'lucia.fernandez@example.com'),
(4, 'miguel.hernandez@example.com'),
(5, 'laura.gomez@example.com'),
(6, 'javier.diaz@example.com'),
(7, 'sofia.jimenez@example.com'),
(8, 'david.romero@example.com'),
(9, 'maria.santos@example.com'),
(10, 'antonio.cruz@example.com'),
(10, 'antonio.cruz.trabajo@example.com'),
(11, 'elena.navarro@example.com'),
(12, 'pablo.molina@example.com'),
(13, 'carmen.rojas@example.com'),
(14, 'ricardo.blanco@example.com'),
(15, 'isabel.vargas@example.com'),
(15, 'isabel.vargas.personal@example.com');

INSERT INTO asisten (idEvent, idPers, valoracion) VALUES
(1, 1, 5),
(1, 2, 4),
(1, 3, 5),

(2, 2, 4),
(2, 4, 3),
(2, 5, 4),

(3, 1, 5),
(3, 6, 4),
(3, 7, 5),

(4, 8, 3),
(4, 9, 4),
(4, 3, 4),

(5, 10, 5),
(5, 11, 4),
(5, 12, 3),

(6, 13, 4),
(6, 14, 5),

(7, 1, 5),
(7, 15, 4),

(8, 2, 4),
(8, 5, 3),

(9, 6, 4),
(9, 7, 5),

(10, 8, 3),
(10, 9, 4),

(11, 10, 5),
(11, 11, 4),

(12, 12, 4),
(12, 13, 5);

INSERT INTO participa (idActiv, idArtis, cache) VALUES
(1, 1, 1500.00),
(1, 2, 1200.00),
(2, 2, 1000.00),
(2, 3, 1100.00),
(3, 5, 900.00),
(4, 6, 1800.00),
(4, 4, 1300.00),
(5, 4, 1200.00),
(5, 7, 1000.00),
(6, 3, 1100.00),
(6, 5, 1500.00),
(7, 7, 900.00),
(7, 2, 1300.00),
(8, 9, 1600.00),
(8, 10, 1400.00),
(9, 5, 1200.00),
(9, 2, 1000.00),
(10, 1, 2000.00),
(10, 7, 1800.00),
(10, 9, 1500.00),
(11, 9, 1300.00),
(11, 1, 1400.00),
(12, 2, 2000.00),
(12, 6, 1800.00),
(13, 3, 1600.00),
(13, 6, 1400.00),
(14, 9, 900.00),
(14, 5, 1100.00),
(15, 8, 1000.00),
(15, 10, 1200.00);



/*
Consultas, modificaciones, borrados y vistas.
*/

-- Fecha con más eventos (Muestra todas las fechas si empatan en número de eventos) y número de eventos que hay ese día
SELECT DATE(momEvent) Fecha, COUNT(*) nEventos
FROM evento
GROUP BY DATE(momEvent)
HAVING nEventos=(SELECT COUNT(*)
				FROM evento
                GROUP BY DATE(momEvent)
                ORDER BY COUNT(*) DESC
                LIMIT 1
                );

-- Eventos en cuya actividad solo participa un artista
SELECT ev.idEvent, ev.nomEvent
FROM evento ev
INNER JOIN actividad av   ON ev.idActiv = av.idActiv
INNER JOIN participa part ON av.idActiv = part.idActiv
GROUP BY ev.idEvent, ev.nomEvent, av.idActiv
HAVING COUNT(*) = 1;

-- Evento más multitudinario (Muestra todos los eventos que empaten en numero de personas) con el número de personas que asisten
SELECT ev.idEvent, ev.nomEvent, count(*) nAsistentes
FROM evento ev
INNER JOIN asisten asi ON ev.idEvent = asi.idEvent
GROUP BY ev.idEvent
HAVING nAsistentes=(SELECT COUNT(*)
				 FROM asisten
                 GROUP BY idEvent
                 ORDER BY COUNT(*) DESC
                 LIMIT 1
                 );
                 
-- Eventos ordenados por valoracion media
SELECT ev.idEvent, ev.nomEvent, avg(asi.valoracion) MediaValoracion
FROM evento ev
INNER JOIN asisten asi ON ev.idEvent=asi.idEvent
GROUP BY ev.idEvent
ORDER BY MediaValoracion DESC;

-- Artistas participantes en los eventos mejor valorados
SELECT art.idArtis, round(avg(asi.valoracion),2) MediaValoracion
FROM evento ev
INNER JOIN asisten asi ON ev.idEvent=asi.idEvent
INNER JOIN participa part ON ev.idActiv=part.idActiv
INNER JOIN artista art ON part.idArtis=art.idArtis
GROUP BY ev.idEvent, part.idActiv, art.idArtis
HAVING MediaValoracion =(SELECT round(avg(valoracion),2)
						FROM asisten                        
                        GROUP BY idEvent
                        ORDER BY avg(valoracion) DESC
                        LIMIT 1
                        );

-- Tipos de actividad por asistencia
SELECT tp.nomTipo, count(asi.idPers) nAsistentes
FROM tipo tp
INNER JOIN actividad av ON av.idTipo=tp.idTipo
INNER JOIN evento ev ON ev.idActiv=av.idActiv
INNER JOIN asisten asi ON ev.idEvent=asi.idEvent
GROUP BY tp.nomTipo
ORDER BY nAsistentes DESC;

-- Actividades por coste (Solo tiene en cuenta el costo de los artistas participantes).
SELECT part.idActiv, av.nomActiv, sum(part.cache) CostoActividad
FROM participa part
RIGHT JOIN actividad av ON av.idActiv=part.idActiv
GROUP BY av.idActiv
ORDER BY CostoActividad DESC;

-- Eventos por coste (Hay que tener en cuenta la ubicacion igual)
SELECT ev.idEvent, ev.nomEvent, sum(part.cache)+ubi.precio_alquiler CostoEvento
FROM evento ev
INNER JOIN participa part ON part.idActiv=ev.idActiv
INNER JOIN ubicacion ubi ON ev.idUbi=ubi.idUbi
GROUP BY ev.idEvent, ev.idActiv
ORDER BY sum(part.cache)+ubi.precio_alquiler DESC;

-- Personas que han asistido a mas de un evento
SELECT pers.idPers, pers.nomPers, pers.ap1Pers, pers.ap2Pers
FROM persona pers
INNER JOIN asisten asi ON pers.idPers=asi.idPers
GROUP BY idPers
HAVING count(asi.idEvent)>1;

-- Vista para obtener los beneficios de los eventos (precio_entrada*nAsistentes-CostoEvento)
CREATE VIEW BeneficioEvento AS
SELECT ev.idEvent, ev.nomEvent, sum(part.cache)+ubi.precio_alquiler CostoEvento, count(idPers)*precio_entrada IngresoEvento, count(asi.idPers)*precio_entrada-sum(part.cache)-ubi.precio_alquiler Beneficio
FROM evento ev
INNER JOIN participa part ON part.idActiv=ev.idActiv
INNER JOIN ubicacion ubi ON ev.idUbi=ubi.idUbi
LEFT JOIN asisten asi ON ev.idEvent=asi.idEvent -- LEFT JOIN por si no hay asistenetes a un evento, no aparecen en la tabla asisten pero igualmente tiene un costo el evento.
GROUP BY ev.idEvent
ORDER BY Beneficio DESC;

-- Modificamos a 3 el aforo de <<Sala Galileo Galilei>>(4), en la que se realiza el evento <<Soul Experience>>(4) y que ya tiene 3 asistentes.
UPDATE ubicacion
SET aforo=3
WHERE idUbi=4;

-- Añadimos un nuevo asistente al evento <<Soul Experience>>(4) para comprobar que funciona bien el TRIGGER
INSERT INTO asisten VALUES
(4,15,4);