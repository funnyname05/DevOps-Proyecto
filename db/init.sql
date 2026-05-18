CREATE USER IF NOT EXISTS 'user_ventas'@'%' IDENTIFIED BY 'password_ventas';
CREATE USER IF NOT EXISTS 'user_despachos'@'%' IDENTIFIED BY 'password_despachos';

-- Comando Test

-- Base de datos de Ventas
CREATE DATABASE IF NOT EXISTS db_ventas;
USE db_ventas;
DROP TABLE IF EXISTS venta;
CREATE TABLE venta (
    id_venta BIGINT NOT NULL AUTO_INCREMENT,
    direccion_compra VARCHAR(255) NOT NULL,
    valor_compra INT NOT NULL,
    fecha_compra DATE NOT NULL,
    despacho_generado BIT(1) NOT NULL DEFAULT b'0',
    PRIMARY KEY (id_venta)
) ENGINE=InnoDB;

INSERT INTO venta (direccion_compra, valor_compra, fecha_compra, despacho_generado) VALUES
('Av. Vitacura 1230, Santiago', 45000, '2026-05-10', b'1'),
('Calle Los Almendros 452, Viña del Mar', 12500, '2026-05-12', b'1'),
('Pasaje El Sol 89, Concepción', 89990, '2026-05-15', b'0'),
('Av. El Bosque 7741, Providencia', 32000, '2026-05-16', b'1'),
('Camino Melipilla KM 32, Talagante', 150000, '2026-05-17', b'0');

-- Base de datos de Despachos
CREATE DATABASE IF NOT EXISTS db_despachos;
USE db_despachos;
DROP TABLE IF EXISTS despacho;
CREATE TABLE despacho (
    id_despacho BIGINT NOT NULL AUTO_INCREMENT,
    fecha_despacho DATE,
    patente_camion VARCHAR(50),
    intento INT NOT NULL,
    id_compra BIGINT,
    direccion_compra VARCHAR(255),
    valor_compra BIGINT,
    despachado BIT(1) NOT NULL DEFAULT b'0',
    PRIMARY KEY (id_despacho)
) ENGINE=InnoDB;

INSERT INTO despacho (fecha_despacho, patente_camion, intento, id_compra, direccion_compra, valor_compra, despachado) VALUES
('2026-05-11', 'AB-CD-12', 1, 1, 'Av. Vitacura 1230, Santiago', 45000, b'1'),
('2026-05-13', 'EF-GH-34', 1, 2, 'Calle Los Almendros 452, Viña del Mar', 12500, b'0'),
('2026-05-14', 'EF-GH-34', 2, 2, 'Calle Los Almendros 452, Viña del Mar', 12500, b'1'),
('2026-05-17', 'XY-ZW-99', 1, 4, 'Av. El Bosque 7741, Providencia', 32000, b'0'),
(NULL, NULL, 0, NULL, 'Dirección de Prueba Manual', 7500, b'0');
