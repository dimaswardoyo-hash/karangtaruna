-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Jul 27, 2025 at 03:51 PM
-- Server version: 8.0.30
-- PHP Version: 8.1.10

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `karangtaruna`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `CountCompletedKegiatan` (IN `tanggal_cutoff` DATE, OUT `hasilPesan` VARCHAR(255))   BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE agd_id BIGINT;
    DECLARE agd_nama VARCHAR(255);
    DECLARE jumlah INT DEFAULT 0;

    DECLARE cur CURSOR FOR
        SELECT id, nama_agenda FROM karangtaruna.agendas
        WHERE kategori = 'kegiatan' AND waktu_selesai < tanggal_cutoff;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO agd_id, agd_nama;
        IF done THEN
            LEAVE read_loop;
        END IF;
        SET jumlah = jumlah + 1;
    END LOOP;
    CLOSE cur;

    IF jumlah = 0 THEN
        SET hasilPesan = 'Tidak ada kegiatan yang selesai sebelum tanggal tersebut.';
    ELSE
        SET hasilPesan = CONCAT('Terdapat ', jumlah, ' kegiatan yang telah selesai.');
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ShowActiveAgenda` ()   BEGIN
    SELECT id, nama_agenda, kategori, waktu_mulai, waktu_selesai, lokasi
    FROM karangtaruna.agendas
    WHERE presensi_open = 1;
END$$

--
-- Functions
--
CREATE DEFINER=`root`@`localhost` FUNCTION `TotalAnggota` () RETURNS INT DETERMINISTIC BEGIN
    DECLARE total INT;
    SELECT COUNT(*) INTO total FROM karangtaruna.users WHERE role = 'anggota';
    RETURN total;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `TotalKasByJumlahAnggota` (`min_anggota` INT, `deskripsi_param` TEXT) RETURNS INT DETERMINISTIC BEGIN
    DECLARE total INT DEFAULT 0;
    DECLARE jumlah_anggota INT;
    DECLARE deskripsi_fixed TEXT CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci;

    SET deskripsi_fixed = deskripsi_param;

    SELECT COUNT(*) INTO jumlah_anggota FROM karangtaruna.users WHERE role = 'anggota';

    IF jumlah_anggota >= min_anggota THEN
        SELECT SUM(jumlah) INTO total 
        FROM karangtaruna.kas 
        WHERE deskripsi LIKE CONCAT('%', deskripsi_fixed, '%');
    END IF;

    RETURN IFNULL(total, 0);
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `agendas`
--

CREATE TABLE `agendas` (
  `id` bigint UNSIGNED NOT NULL,
  `nama_agenda` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `kategori` enum('kegiatan','rapat') COLLATE utf8mb4_unicode_ci NOT NULL,
  `foto` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `deskripsi` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `waktu_mulai` datetime NOT NULL,
  `waktu_selesai` datetime NOT NULL,
  `lokasi` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `presensi_open` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `agendas`
--

INSERT INTO `agendas` (`id`, `nama_agenda`, `kategori`, `foto`, `deskripsi`, `waktu_mulai`, `waktu_selesai`, `lokasi`, `presensi_open`, `created_at`, `updated_at`) VALUES
(3, 'Konser Dangdut', 'kegiatan', 'foto_agenda/rRg9OXZp3JNOOraxBz3GleDiOTCJQ8tSfz520s9Y.jpg', 'Konser dangdut bersama para gus', '2025-07-27 17:35:00', '2025-07-27 22:35:00', 'Daerah Jawa', 0, '2025-07-25 16:36:55', '2025-07-25 16:36:55'),
(4, 'Ngaji Bareng', 'kegiatan', 'foto_agenda/o1sxqFDaUhvtlTHzW7KFkzD6FbJ3Y9SOCf0eNT78.jpg', 'Ngaji bareng mendengarkan ustad felix', '2025-07-26 22:56:00', '2025-07-26 23:56:00', 'Masjidil haram', 0, '2025-07-26 15:57:53', '2025-07-26 15:57:53'),
(5, 'Kegiatan Sosialisasi', 'kegiatan', NULL, 'Workshop untuk UMKM', '2025-07-26 23:00:39', '2025-07-27 01:00:39', 'Balai Desa', 1, NULL, NULL),
(6, 'Bersih desa', 'kegiatan', 'foto_agenda/8fujqijW6goC3smesxaHpEvhGGUbKSwruBGqbGJA.png', 'Kegiatan bersih desa, untuk menyambut HUT RI ke 80', '2025-07-30 09:00:00', '2025-07-30 13:00:00', 'Daerah Jawa', 0, '2025-07-27 06:07:08', '2025-07-27 06:07:08'),
(7, 'Rapat Kabeint', 'rapat', NULL, 'Rapat kabinet membahas tentang indonesia merdeka', '2025-07-27 21:59:00', '2025-07-27 23:59:00', 'Amikom', 1, '2025-07-27 15:13:17', '2025-07-27 15:16:51');

--
-- Triggers `agendas`
--
DELIMITER $$
CREATE TRIGGER `after_update_agenda` AFTER UPDATE ON `agendas` FOR EACH ROW BEGIN
    IF OLD.nama_agenda <> NEW.nama_agenda THEN
        INSERT INTO karangtaruna.agenda_logs (agenda_id, perubahan)
        VALUES (NEW.id, CONCAT('Nama agenda diubah dari "', OLD.nama_agenda, '" menjadi "', NEW.nama_agenda, '"'));
    END IF;

    IF OLD.deskripsi <> NEW.deskripsi THEN
        INSERT INTO karangtaruna.agenda_logs (agenda_id, perubahan)
        VALUES (NEW.id, CONCAT('Deskripsi agenda diubah.'));
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `before_delete_agenda` BEFORE DELETE ON `agendas` FOR EACH ROW BEGIN
    IF OLD.presensi_open = 1 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Agenda dengan presensi terbuka tidak dapat dihapus.';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `agenda_logs`
--

CREATE TABLE `agenda_logs` (
  `id` bigint NOT NULL,
  `agenda_id` bigint DEFAULT NULL,
  `perubahan` text,
  `tanggal` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `agenda_logs`
--

INSERT INTO `agenda_logs` (`id`, `agenda_id`, `perubahan`, `tanggal`) VALUES
(1, 2, 'Nama agenda diubah dari \"Budaya Ponorogo kaya akan berbagai kesenian dan tradisi.\" menjadi \"Rapat Koordinasi Final\"', '2025-07-26 16:44:58'),
(2, 5, 'Nama agenda diubah dari \"Pelatihan UMKM\" menjadi \"Kegiatan Sosialisasi\"', '2025-07-26 23:02:22');

-- --------------------------------------------------------

--
-- Table structure for table `banners`
--

CREATE TABLE `banners` (
  `id` bigint UNSIGNED NOT NULL,
  `gambar` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `banners`
--

INSERT INTO `banners` (`id`, `gambar`, `created_at`, `updated_at`) VALUES
(1, 'banner/GwFIQQ9gmbU2ZocQvrjvcqEcIazFsx9McVSQP2rF.jpg', '2025-07-17 06:10:38', '2025-07-25 16:05:09'),
(2, 'banner/LIB0tEA5XkCWYy7w0vXla47R8gCeg61nSZXMg5B3.jpg', '2025-07-25 16:05:25', '2025-07-25 16:37:29'),
(3, 'banner/76HukZaeu6iSDjWdL8mpnTb72mPto5LUCh5UDx0G.jpg', '2025-07-25 16:05:35', '2025-07-25 16:05:35');

-- --------------------------------------------------------

--
-- Table structure for table `dana_lains`
--

CREATE TABLE `dana_lains` (
  `id` bigint UNSIGNED NOT NULL,
  `tanggal` date NOT NULL,
  `jumlah` int NOT NULL,
  `deskripsi` text COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `dana_lains`
--

INSERT INTO `dana_lains` (`id`, `tanggal`, `jumlah`, `deskripsi`, `created_at`, `updated_at`) VALUES
(1, '2025-07-17', 2000000, 'Dana Desa', '2025-07-17 05:53:49', '2025-07-17 05:53:49');

-- --------------------------------------------------------

--
-- Table structure for table `failed_jobs`
--

CREATE TABLE `failed_jobs` (
  `id` bigint UNSIGNED NOT NULL,
  `uuid` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `connection` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `queue` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `payload` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `exception` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `failed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `hutangs`
--

CREATE TABLE `hutangs` (
  `id` bigint UNSIGNED NOT NULL,
  `user_id` bigint UNSIGNED NOT NULL,
  `tanggal` date NOT NULL,
  `jumlah` int NOT NULL,
  `keterangan` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `hutangs`
--

INSERT INTO `hutangs` (`id`, `user_id`, `tanggal`, `jumlah`, `keterangan`, `created_at`, `updated_at`) VALUES
(31, 37, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(32, 38, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(33, 39, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(34, 40, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(35, 41, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(36, 42, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(37, 43, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(38, 44, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(39, 45, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(40, 46, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(41, 47, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(42, 48, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(43, 49, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(44, 50, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(45, 51, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(46, 52, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(47, 53, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(48, 54, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(49, 55, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(50, 56, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(51, 57, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(52, 58, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(53, 59, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(54, 60, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(55, 61, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(56, 62, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(57, 63, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(58, 64, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(59, 65, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(60, 66, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(61, 67, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(62, 68, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(63, 69, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(64, 70, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(65, 71, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(66, 72, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(67, 73, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(68, 74, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(69, 75, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(70, 76, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(71, 77, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(72, 78, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(73, 79, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(74, 80, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(75, 81, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(76, 82, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(77, 83, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(78, 84, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(79, 85, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(80, 86, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(81, 87, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(82, 88, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(83, 89, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(84, 90, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(85, 91, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(86, 92, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(87, 93, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(88, 94, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(89, 95, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(90, 96, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(91, 97, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(92, 98, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(93, 99, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(94, 100, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(95, 101, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(96, 102, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(97, 103, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(98, 104, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(99, 105, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(100, 106, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(101, 107, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(102, 108, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(103, 109, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(104, 110, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(105, 111, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(106, 112, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(107, 113, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(108, 114, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(109, 115, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(110, 116, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(111, 117, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(112, 118, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(113, 119, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(114, 120, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(115, 121, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(116, 122, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(117, 123, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(118, 124, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(119, 125, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(120, 126, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(121, 127, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(122, 128, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(123, 129, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(124, 130, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(125, 131, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(126, 132, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(127, 133, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(128, 134, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(129, 135, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(130, 136, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(131, 137, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(132, 138, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(133, 139, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(134, 140, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(135, 141, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(136, 142, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(137, 143, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(138, 144, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(139, 145, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(140, 146, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(141, 147, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(142, 148, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(143, 149, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(144, 150, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(145, 151, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(146, 152, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(147, 153, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(148, 154, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(149, 155, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(150, 156, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(151, 157, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(152, 158, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(153, 159, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(154, 160, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(155, 161, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(156, 162, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(157, 163, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(158, 164, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(159, 165, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(160, 167, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(161, 168, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(162, 169, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(163, 170, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(164, 171, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(165, 172, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(166, 173, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(167, 174, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(168, 175, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(169, 176, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(170, 177, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(171, 178, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(172, 179, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(173, 180, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(174, 181, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(175, 182, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(176, 183, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(177, 184, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(178, 185, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(179, 186, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(180, 187, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(181, 188, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(182, 189, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(183, 190, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(184, 191, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(185, 192, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(186, 193, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(187, 194, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(188, 195, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(189, 196, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(190, 197, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(191, 198, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(192, 199, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(193, 200, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(194, 201, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(195, 202, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(196, 203, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(197, 204, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(198, 205, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(199, 206, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(200, 207, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(201, 208, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(202, 209, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(203, 210, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(204, 211, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(205, 212, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(206, 213, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(207, 214, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(208, 215, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(209, 216, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(210, 217, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(211, 218, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(212, 219, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(213, 220, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(214, 221, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(215, 222, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(216, 223, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(217, 224, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(218, 225, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(219, 226, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(220, 227, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(221, 228, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(222, 229, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(223, 230, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(224, 231, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(225, 232, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(226, 233, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(227, 234, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(228, 235, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(229, 236, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(230, 237, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(231, 238, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(232, 239, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(233, 240, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(234, 241, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(235, 242, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(236, 243, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(237, 244, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(238, 245, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(239, 246, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(240, 247, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(241, 248, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(242, 249, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(243, 250, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(244, 251, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(245, 252, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(246, 253, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(247, 254, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(248, 255, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(249, 256, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(250, 257, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(251, 258, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(252, 259, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(253, 260, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(254, 261, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(255, 262, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(256, 263, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(257, 264, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(258, 265, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(259, 266, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(260, 267, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(261, 268, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(262, 269, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(263, 270, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(264, 271, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(265, 272, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(266, 273, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(267, 274, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(268, 275, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(269, 276, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(270, 277, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(271, 278, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(272, 279, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(273, 280, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(274, 281, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(275, 282, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(276, 283, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(277, 284, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(278, 285, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(279, 286, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(280, 287, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(281, 288, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(282, 289, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(283, 290, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(284, 291, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(285, 292, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(286, 293, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(287, 294, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(288, 295, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(289, 296, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(290, 297, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(291, 298, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(292, 299, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(293, 300, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(294, 301, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(295, 302, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(296, 303, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(297, 304, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(298, 305, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(299, 306, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(300, 307, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(301, 308, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(302, 309, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(303, 310, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(304, 311, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(305, 312, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(306, 313, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(307, 314, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(308, 315, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(309, 316, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(310, 317, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(311, 318, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(312, 319, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(313, 320, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(314, 321, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(315, 322, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(316, 323, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(317, 324, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(318, 325, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(319, 326, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(320, 327, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(321, 328, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(322, 329, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(323, 330, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(324, 331, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(325, 332, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(326, 333, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(327, 334, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(328, 335, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(329, 336, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(330, 337, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(331, 338, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(332, 339, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(333, 340, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(334, 341, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(335, 342, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(336, 343, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(337, 344, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(338, 345, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(339, 346, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(340, 347, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(341, 348, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(342, 349, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(343, 350, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(344, 351, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(345, 352, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(346, 353, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(347, 354, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(348, 355, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(349, 356, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(350, 357, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(351, 358, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(352, 359, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(353, 360, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(354, 361, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(355, 362, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(356, 363, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(357, 364, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(358, 365, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(359, 366, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(360, 367, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(361, 368, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(362, 369, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(363, 370, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(364, 371, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(365, 372, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(366, 373, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(367, 374, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(368, 375, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(369, 376, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(370, 377, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(371, 378, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(372, 379, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(373, 380, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(374, 381, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(375, 382, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(376, 383, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(377, 384, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(378, 385, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(379, 386, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(380, 387, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(381, 388, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(382, 389, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(383, 390, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(384, 391, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(385, 392, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(386, 393, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(387, 394, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(388, 395, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(389, 396, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(390, 397, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(391, 398, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(392, 399, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(393, 400, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(394, 401, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(395, 402, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(396, 403, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(397, 404, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(398, 405, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(399, 406, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(400, 407, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(401, 408, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(402, 409, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(403, 410, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(404, 411, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(405, 412, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(406, 413, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(407, 414, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(408, 415, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(409, 416, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(410, 417, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(411, 418, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(412, 419, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(413, 420, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(414, 421, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(415, 422, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(416, 423, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(417, 424, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(418, 425, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(419, 426, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(420, 427, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(421, 428, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(422, 429, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(423, 430, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(424, 431, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(425, 432, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(426, 433, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(427, 434, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(428, 435, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(429, 436, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(430, 437, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(431, 438, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(432, 439, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(433, 440, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(434, 441, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(435, 442, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(436, 443, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(437, 444, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(438, 445, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(439, 446, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(440, 447, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(441, 448, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(442, 449, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(443, 450, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(444, 451, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(445, 452, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(446, 453, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(447, 454, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(448, 455, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(449, 456, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(450, 457, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(451, 458, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(452, 459, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(453, 460, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(454, 461, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(455, 462, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(456, 463, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(457, 464, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45');
INSERT INTO `hutangs` (`id`, `user_id`, `tanggal`, `jumlah`, `keterangan`, `created_at`, `updated_at`) VALUES
(458, 465, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(459, 466, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(460, 467, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(461, 468, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(462, 469, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(463, 470, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(464, 471, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(465, 472, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(466, 473, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(467, 474, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(468, 475, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(469, 476, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(470, 477, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(471, 478, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(472, 479, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(473, 480, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(474, 481, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(475, 482, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(476, 483, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(477, 484, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(478, 485, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(479, 486, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(480, 487, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(481, 488, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(482, 489, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(483, 490, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(484, 491, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(485, 492, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(486, 493, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(487, 494, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(488, 495, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(489, 496, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(490, 497, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(491, 498, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(492, 499, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(493, 500, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(494, 501, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(495, 502, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(496, 503, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(497, 504, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(498, 505, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(499, 506, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(500, 507, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(501, 508, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(502, 509, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(503, 510, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(504, 511, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(505, 512, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(506, 513, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(507, 514, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(508, 515, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(509, 516, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(510, 517, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(511, 518, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(512, 519, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(513, 520, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(514, 521, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(515, 522, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(516, 523, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(517, 524, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(518, 525, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(519, 526, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(520, 527, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(521, 528, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(522, 529, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(523, 530, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(524, 531, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(525, 532, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(526, 533, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(527, 534, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(528, 535, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(529, 536, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(530, 537, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(531, 538, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(532, 539, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(533, 540, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(534, 541, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(535, 542, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(536, 543, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(537, 544, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(538, 545, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(539, 546, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(540, 547, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(541, 548, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(542, 549, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(543, 550, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(544, 551, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(545, 552, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(546, 553, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(547, 554, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(548, 555, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(549, 556, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(550, 557, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(551, 558, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(552, 559, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(553, 560, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(554, 561, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(555, 562, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(556, 563, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(557, 564, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(558, 565, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(559, 566, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(560, 567, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(561, 568, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(562, 569, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(563, 570, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(564, 571, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(565, 572, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(566, 573, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(567, 574, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(568, 575, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(569, 576, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(570, 577, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(571, 578, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(572, 579, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(573, 580, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(574, 581, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(575, 582, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(576, 583, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(577, 584, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(578, 585, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(579, 586, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(580, 587, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(581, 588, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(582, 589, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(583, 590, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(584, 591, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(585, 592, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(586, 593, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(587, 594, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(588, 595, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(589, 596, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:45', '2025-07-17 05:50:45'),
(590, 597, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(591, 598, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(592, 599, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(593, 600, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(594, 601, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(595, 602, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(596, 603, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(597, 604, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(598, 605, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(599, 606, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(600, 607, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(601, 608, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(602, 609, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(603, 610, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(604, 611, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(605, 612, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(606, 613, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(607, 614, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(608, 615, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(609, 616, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(610, 617, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(611, 618, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(612, 619, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(613, 620, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(614, 621, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(615, 622, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(616, 623, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(617, 624, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(618, 625, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(619, 626, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(620, 627, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(621, 628, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(622, 629, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(623, 630, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(624, 631, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(625, 632, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(626, 633, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(627, 634, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(628, 635, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(629, 636, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(630, 637, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(631, 638, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(632, 639, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(633, 640, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(634, 641, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(635, 642, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(636, 643, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(637, 644, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(638, 645, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(639, 646, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(640, 647, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(641, 648, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(642, 649, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(643, 650, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(644, 651, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(645, 652, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(646, 653, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(647, 654, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(648, 655, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(649, 656, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(650, 657, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(651, 658, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(652, 659, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(653, 660, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(654, 661, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(655, 662, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(656, 663, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(657, 664, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(658, 665, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(659, 666, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(660, 667, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(661, 668, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(662, 669, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(663, 670, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(664, 671, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(665, 672, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(666, 673, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(667, 674, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(668, 675, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(669, 676, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(670, 677, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(671, 678, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(672, 679, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(673, 680, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(674, 681, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(675, 682, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(676, 683, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(677, 684, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(678, 685, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(679, 686, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(680, 687, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(681, 688, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(682, 689, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(683, 690, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(684, 691, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(685, 692, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(686, 693, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(687, 694, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(688, 695, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(689, 696, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(690, 697, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(691, 698, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(692, 699, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(693, 700, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(694, 701, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(695, 702, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(696, 703, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(697, 704, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(698, 705, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(699, 706, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(700, 707, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(701, 708, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(702, 709, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(703, 710, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(704, 711, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(705, 712, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(706, 713, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(707, 714, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(708, 715, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(709, 716, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(710, 717, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(711, 718, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(712, 719, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(713, 720, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(714, 721, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(715, 722, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(716, 723, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(717, 724, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(718, 725, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(719, 726, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(720, 727, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(721, 728, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(722, 729, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(723, 730, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(724, 731, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(725, 732, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(726, 733, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(727, 734, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(728, 735, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(729, 736, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(730, 737, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(731, 738, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(732, 739, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(733, 740, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(734, 741, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(735, 742, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(736, 743, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(737, 744, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(738, 745, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(739, 746, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(740, 747, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(741, 748, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(742, 749, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(743, 750, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(744, 751, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(745, 752, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(746, 753, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(747, 754, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(748, 755, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(749, 756, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(750, 757, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(751, 758, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(752, 759, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(753, 760, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(754, 761, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(755, 762, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(756, 763, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(757, 764, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(758, 765, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(759, 766, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(760, 767, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(761, 768, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(762, 769, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(763, 770, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(764, 771, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(765, 772, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(766, 773, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(767, 774, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(768, 775, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(769, 776, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(770, 777, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(771, 778, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(772, 779, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(773, 780, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(774, 781, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(775, 782, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(776, 783, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(777, 784, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(778, 785, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(779, 786, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(780, 787, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(781, 788, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(782, 789, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(783, 790, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(784, 791, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(785, 792, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(786, 793, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(787, 794, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(788, 795, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(789, 796, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(790, 797, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(791, 798, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(792, 799, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(793, 800, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(794, 801, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(795, 802, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(796, 803, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(797, 804, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(798, 805, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(799, 806, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(800, 807, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(801, 808, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(802, 809, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(803, 810, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(804, 811, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(805, 812, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(806, 813, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(807, 814, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(808, 815, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(809, 816, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(810, 817, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(811, 818, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(812, 819, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(813, 820, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(814, 821, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(815, 822, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(816, 823, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(817, 824, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(818, 825, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(819, 826, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(820, 827, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(821, 828, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(822, 829, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(823, 830, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(824, 831, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(825, 832, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(826, 833, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(827, 834, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(828, 835, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(829, 836, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(830, 837, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(831, 838, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(832, 839, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(833, 840, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(834, 841, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(835, 842, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(836, 843, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(837, 844, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(838, 845, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(839, 846, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(840, 847, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(841, 848, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(842, 849, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(843, 850, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(844, 851, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(845, 852, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(846, 853, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(847, 854, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(848, 855, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(849, 856, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(850, 857, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(851, 858, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(852, 859, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(853, 860, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(854, 861, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(855, 862, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(856, 863, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(857, 864, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(858, 865, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(859, 866, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(860, 867, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(861, 868, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(862, 869, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(863, 870, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(864, 871, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(865, 872, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(866, 873, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(867, 874, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(868, 875, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(869, 876, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(870, 877, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(871, 878, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(872, 879, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(873, 880, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(874, 881, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(875, 882, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(876, 883, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(877, 884, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(878, 885, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(879, 886, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(880, 887, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(881, 888, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(882, 889, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(883, 890, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46');
INSERT INTO `hutangs` (`id`, `user_id`, `tanggal`, `jumlah`, `keterangan`, `created_at`, `updated_at`) VALUES
(884, 891, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(885, 892, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(886, 893, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(887, 894, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(888, 895, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(889, 896, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(890, 897, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(891, 898, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(892, 899, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(893, 900, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(894, 901, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(895, 902, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(896, 903, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(897, 904, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(898, 905, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(899, 906, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(900, 907, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(901, 908, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(902, 909, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(903, 910, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(904, 911, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(905, 912, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(906, 913, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(907, 914, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:46', '2025-07-17 05:50:46'),
(908, 915, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(909, 916, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(910, 917, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(911, 918, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(912, 919, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(913, 920, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(914, 921, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(915, 922, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(916, 923, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(917, 924, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(918, 925, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(919, 926, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(920, 927, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(921, 928, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(922, 929, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(923, 930, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(924, 931, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(925, 932, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(926, 933, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(927, 934, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(928, 935, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(929, 936, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(930, 937, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(931, 938, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(932, 939, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(933, 940, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(934, 941, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(935, 942, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(936, 943, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(937, 944, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(938, 945, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(939, 946, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(940, 947, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(941, 948, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(942, 949, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(943, 950, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(944, 951, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(945, 952, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(946, 953, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(947, 954, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(948, 955, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(949, 956, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(950, 957, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(951, 958, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(952, 959, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(953, 960, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(954, 961, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(955, 962, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(956, 963, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(957, 964, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(958, 965, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(959, 966, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(960, 967, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(961, 968, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(962, 969, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(963, 970, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(964, 971, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(965, 972, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(966, 973, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(967, 974, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(968, 975, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(969, 976, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(970, 977, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(971, 978, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(972, 979, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(973, 980, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(974, 981, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(975, 982, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(976, 983, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(977, 984, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(978, 985, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(979, 986, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(980, 987, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(981, 988, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(982, 989, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(983, 990, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(984, 991, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(985, 992, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(986, 993, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(987, 994, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(988, 995, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(989, 996, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(990, 997, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(991, 998, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(992, 999, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47'),
(993, 1000, '2025-07-17', 5000, 'Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:50:47', '2025-07-17 05:50:47');

-- --------------------------------------------------------

--
-- Table structure for table `identitas`
--

CREATE TABLE `identitas` (
  `id` bigint UNSIGNED NOT NULL,
  `user_id` bigint UNSIGNED NOT NULL,
  `no_whatsapp` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tanggal_lahir` date NOT NULL,
  `status` enum('aktif','tidak') COLLATE utf8mb4_unicode_ci NOT NULL,
  `alasan` enum('sekolah di luar kota','bekerja di luar kota') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `identitas`
--

INSERT INTO `identitas` (`id`, `user_id`, `no_whatsapp`, `tanggal_lahir`, `status`, `alasan`, `created_at`, `updated_at`) VALUES
(1, 2, '082231295144', '2025-07-17', 'aktif', NULL, '2025-07-17 06:14:18', '2025-07-17 06:14:18');

-- --------------------------------------------------------

--
-- Table structure for table `kas`
--

CREATE TABLE `kas` (
  `id` bigint UNSIGNED NOT NULL,
  `user_id` bigint UNSIGNED NOT NULL,
  `tanggal` date NOT NULL,
  `jumlah` int NOT NULL,
  `deskripsi` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `kas`
--

INSERT INTO `kas` (`id`, `user_id`, `tanggal`, `jumlah`, `deskripsi`, `created_at`, `updated_at`) VALUES
(1, 1, '2025-07-17', 5000, 'Pembayaran kas pada 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(2, 2, '2025-07-17', 5000, 'Pembayaran kas pada 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(3, 3, '2025-07-17', 5000, 'Pembayaran kas pada 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(4, 4, '2025-07-17', 5000, 'Pembayaran kas pada 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(5, 5, '2025-07-17', 5000, 'Pembayaran kas pada 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(6, 7, '2025-07-17', 5000, 'Pembayaran kas pada 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(7, 166, '2025-07-17', 5000, 'Pembayaran kas pada 2025-07-17', '2025-07-17 05:50:44', '2025-07-17 05:50:44'),
(8, 6, '2025-07-17', 5000, 'Pembayaran hutang: Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:51:39', '2025-07-17 05:51:39'),
(9, 8, '2025-07-17', 5000, 'Pembayaran hutang: Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:51:43', '2025-07-17 05:51:43'),
(10, 9, '2025-07-17', 5000, 'Pembayaran hutang: Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:51:48', '2025-07-17 05:51:48'),
(11, 10, '2025-07-17', 5000, 'Pembayaran hutang: Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:51:51', '2025-07-17 05:51:51'),
(12, 11, '2025-07-17', 5000, 'Pembayaran hutang: Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:51:53', '2025-07-17 05:51:53'),
(13, 12, '2025-07-17', 5000, 'Pembayaran hutang: Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:51:57', '2025-07-17 05:51:57'),
(14, 13, '2025-07-17', 5000, 'Pembayaran hutang: Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:51:59', '2025-07-17 05:51:59'),
(15, 14, '2025-07-17', 5000, 'Pembayaran hutang: Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:52:01', '2025-07-17 05:52:01'),
(16, 15, '2025-07-17', 5000, 'Pembayaran hutang: Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:52:04', '2025-07-17 05:52:04'),
(17, 16, '2025-07-17', 5000, 'Pembayaran hutang: Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:52:06', '2025-07-17 05:52:06'),
(18, 17, '2025-07-17', 5000, 'Pembayaran hutang: Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:52:08', '2025-07-17 05:52:08'),
(19, 18, '2025-07-17', 5000, 'Pembayaran hutang: Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:52:11', '2025-07-17 05:52:11'),
(20, 19, '2025-07-17', 5000, 'Pembayaran hutang: Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:52:13', '2025-07-17 05:52:13'),
(21, 20, '2025-07-17', 5000, 'Pembayaran hutang: Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:52:17', '2025-07-17 05:52:17'),
(22, 21, '2025-07-17', 5000, 'Pembayaran hutang: Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:52:19', '2025-07-17 05:52:19'),
(23, 22, '2025-07-17', 5000, 'Pembayaran hutang: Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:52:22', '2025-07-17 05:52:22'),
(24, 23, '2025-07-17', 5000, 'Pembayaran hutang: Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:52:24', '2025-07-17 05:52:24'),
(25, 24, '2025-07-17', 5000, 'Pembayaran hutang: Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:52:28', '2025-07-17 05:52:28'),
(26, 25, '2025-07-17', 5000, 'Pembayaran hutang: Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:52:31', '2025-07-17 05:52:31'),
(27, 26, '2025-07-17', 5000, 'Pembayaran hutang: Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:52:35', '2025-07-17 05:52:35'),
(28, 27, '2025-07-17', 5000, 'Pembayaran hutang: Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:52:37', '2025-07-17 05:52:37'),
(29, 28, '2025-07-17', 5000, 'Pembayaran hutang: Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:52:40', '2025-07-17 05:52:40'),
(30, 29, '2025-07-17', 5000, 'Pembayaran hutang: Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:52:42', '2025-07-17 05:52:42'),
(31, 30, '2025-07-17', 5000, 'Pembayaran hutang: Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:52:45', '2025-07-17 05:52:45'),
(32, 31, '2025-07-17', 5000, 'Pembayaran hutang: Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:52:49', '2025-07-17 05:52:49'),
(33, 32, '2025-07-17', 5000, 'Pembayaran hutang: Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:52:51', '2025-07-17 05:52:51'),
(34, 33, '2025-07-17', 5000, 'Pembayaran hutang: Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:52:54', '2025-07-17 05:52:54'),
(35, 34, '2025-07-17', 5000, 'Pembayaran hutang: Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:52:57', '2025-07-17 05:52:57'),
(36, 35, '2025-07-17', 5000, 'Pembayaran hutang: Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:52:59', '2025-07-17 05:52:59'),
(37, 36, '2025-07-17', 5000, 'Pembayaran hutang: Belum membayar kas tanggal 2025-07-17', '2025-07-17 05:53:02', '2025-07-17 05:53:02'),
(38, 1, '2025-07-26', 1000, 'Test Trigger Kas', NULL, NULL),
(39, 1, '2025-07-26', 500, 'Test Trigger Kas', NULL, NULL);

--
-- Triggers `kas`
--
DELIMITER $$
CREATE TRIGGER `before_insert_kas` BEFORE INSERT ON `kas` FOR EACH ROW BEGIN
    IF NEW.jumlah < 1000 THEN
        SET NEW.jumlah = 1000;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `kategoris`
--

CREATE TABLE `kategoris` (
  `id` bigint UNSIGNED NOT NULL,
  `nama_kategori` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `gambar_kategori` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `kategoris`
--

INSERT INTO `kategoris` (`id`, `nama_kategori`, `gambar_kategori`, `created_at`, `updated_at`) VALUES
(1, 'SOSIAL', 'kategori/lPFopzHrKDcVOuyigRyvmo7zZwWSoHICx4RKV0EO.svg', '2025-07-17 06:03:25', '2025-07-17 06:03:25'),
(2, 'OLAHRAGA', 'kategori/lztTNNe30pMmbVq7fBXmeO7ye7hYAV0EBbz75xPf.svg', '2025-07-17 06:03:47', '2025-07-17 06:03:47'),
(3, 'LINGKUNGAN', 'kategori/3uk8R9xBH3C4PFHs37riL3RcpVZ5FQSAAm12fTzU.svg', '2025-07-17 06:04:11', '2025-07-17 06:04:11'),
(4, 'EKONOMI', 'kategori/DMovix9cXRjL0jUHK0uJDSCRPyMZiCpn7R8ZN6cc.svg', '2025-07-17 06:04:44', '2025-07-17 06:04:44');

-- --------------------------------------------------------

--
-- Table structure for table `kategori_konten`
--

CREATE TABLE `kategori_konten` (
  `konten_id` bigint UNSIGNED NOT NULL,
  `kategori_id` bigint UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `kategori_konten`
--

INSERT INTO `kategori_konten` (`konten_id`, `kategori_id`) VALUES
(1, 1),
(1, 2);

-- --------------------------------------------------------

--
-- Table structure for table `keluargas`
--

CREATE TABLE `keluargas` (
  `id` bigint UNSIGNED NOT NULL,
  `undangan_id` bigint UNSIGNED NOT NULL,
  `nama` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `hubungan` enum('orangtua','suami','istri','anak','cucu','buyut') COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `keluargas`
--

INSERT INTO `keluargas` (`id`, `undangan_id`, `nama`, `hubungan`, `created_at`, `updated_at`) VALUES
(1, 1, 'Kamu', 'orangtua', '2025-07-17 06:12:11', '2025-07-17 06:12:11'),
(2, 1, 'anda', 'cucu', '2025-07-17 06:12:11', '2025-07-17 06:12:11'),
(3, 1, 'Mbah aja', 'buyut', '2025-07-17 06:12:11', '2025-07-17 06:12:11');

-- --------------------------------------------------------

--
-- Table structure for table `kontens`
--

CREATE TABLE `kontens` (
  `id` bigint UNSIGNED NOT NULL,
  `nama_konten` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tanggal_konten` date NOT NULL,
  `deskripsi` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `gambar1` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `gambar2` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `gambar3` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `kontens`
--

INSERT INTO `kontens` (`id`, `nama_konten`, `tanggal_konten`, `deskripsi`, `gambar1`, `gambar2`, `gambar3`, `created_at`, `updated_at`) VALUES
(1, 'Lomba Memperingati Hari Kemerdekaan Indonesia', '2024-08-17', '<p>Hari Kemerdekaan Bangsa Indonesia adalah hari libur nasional di Indonesia untuk memperingati proklamasi kemerdekaan Indonesia pada tanggal 17 Agustus 1945 yang merupakan deklarasi independensi Indonesia.</p>', 'konten/6FU8NN9qBVkT9Eh7Dl9mnXS6ZnamTB0bbQDFmyXd.jpg', 'konten/YMPvetqxzPdevo6byP1TBXRnlpn9ZpFsK26aRBdp.jpg', 'konten/fVcDKIqqLmnpwI1m4lyxEKPY4S7In7maEDoH9u2r.jpg', '2025-07-17 06:10:23', '2025-07-17 06:10:23');

-- --------------------------------------------------------

--
-- Table structure for table `logs_kas`
--

CREATE TABLE `logs_kas` (
  `id` bigint NOT NULL,
  `user_id` bigint DEFAULT NULL,
  `perubahan` text,
  `tanggal` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `migrations`
--

CREATE TABLE `migrations` (
  `id` int UNSIGNED NOT NULL,
  `migration` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `batch` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `migrations`
--

INSERT INTO `migrations` (`id`, `migration`, `batch`) VALUES
(1, '2014_10_12_000000_create_users_table', 1),
(2, '2014_10_12_100000_create_password_reset_tokens_table', 1),
(3, '2019_08_19_000000_create_failed_jobs_table', 1),
(4, '2019_12_14_000001_create_personal_access_tokens_table', 1),
(5, '2025_07_01_073014_add_role_to_users_table', 1),
(6, '2025_07_01_073054_create_identitas_table', 1),
(7, '2025_07_01_073113_create_agendas_table', 1),
(8, '2025_07_01_073134_create_presensis_table', 1),
(9, '2025_07_01_073157_create_notulens_table', 1),
(10, '2025_07_01_073236_alter_notulens_kesimpulan_nullable', 1),
(11, '2025_07_01_073302_create_kas_table', 1),
(12, '2025_07_01_073323_create_dana_lains_table', 1),
(13, '2025_07_01_073338_create_pengeluarans_table', 1),
(14, '2025_07_01_073455_add_jumlah_to_pengeluarans_table', 1),
(15, '2025_07_01_073521_create_kategoris_table', 1),
(16, '2025_07_01_073539_create_kontens_table', 1),
(17, '2025_07_01_073554_create_perlengkapans_table', 1),
(18, '2025_07_01_073609_create_peminjamans_table', 1),
(19, '2025_07_01_073626_create_hutangs_table', 1),
(20, '2025_07_01_073817_add_sumber_dana_to_pengeluarans_table', 1),
(21, '2025_07_01_073835_create_strukturs_table', 1),
(22, '2025_07_01_073921_add_unique_user_id_to_strukturs_table', 1),
(23, '2025_07_01_073937_create_banners_table', 1),
(24, '2025_07_01_074011_add_kategori_and_foto_to_agendas_table', 1),
(25, '2025_07_10_230011_create_undangans_table', 1),
(26, '2025_07_12_113726_create_keluargas_table', 1),
(27, '2025_07_16_084903_remove_kategori_id_from_kontens_table', 1),
(28, '2025_07_16_084954_create_kategori_konten_table', 1);

-- --------------------------------------------------------

--
-- Table structure for table `notulens`
--

CREATE TABLE `notulens` (
  `id` bigint UNSIGNED NOT NULL,
  `agenda_id` bigint UNSIGNED NOT NULL,
  `notulen` text COLLATE utf8mb4_unicode_ci,
  `pembicara` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `poin_pembahasan` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `kesimpulan` text COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `notulens`
--

INSERT INTO `notulens` (`id`, `agenda_id`, `notulen`, `pembicara`, `poin_pembahasan`, `kesimpulan`, `created_at`, `updated_at`) VALUES
(2, 7, 'edit', 'Dimas Aryo Wardoyo', 'Test Notulen rapat', NULL, '2025-07-27 15:28:29', '2025-07-27 15:30:35');

-- --------------------------------------------------------

--
-- Table structure for table `password_reset_tokens`
--

CREATE TABLE `password_reset_tokens` (
  `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `token` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `peminjamans`
--

CREATE TABLE `peminjamans` (
  `id` bigint UNSIGNED NOT NULL,
  `user_id` bigint UNSIGNED NOT NULL,
  `perlengkapan_id` bigint UNSIGNED NOT NULL,
  `jumlah` int NOT NULL,
  `tanggal_pinjam` date NOT NULL,
  `tanggal_kembali` date NOT NULL,
  `status` enum('menunggu','ditolak','berlangsung','selesai') COLLATE utf8mb4_unicode_ci NOT NULL,
  `tanggapan_admin` text COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `peminjamans`
--

INSERT INTO `peminjamans` (`id`, `user_id`, `perlengkapan_id`, `jumlah`, `tanggal_pinjam`, `tanggal_kembali`, `status`, `tanggapan_admin`, `created_at`, `updated_at`) VALUES
(1, 4, 1, 100, '2025-07-17', '2025-07-17', 'berlangsung', 'oke saya stujui', '2025-07-17 06:17:03', '2025-07-17 06:17:30');

-- --------------------------------------------------------

--
-- Table structure for table `pengeluarans`
--

CREATE TABLE `pengeluarans` (
  `id` bigint UNSIGNED NOT NULL,
  `kegiatan` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `sumber_dana` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tanggal` date NOT NULL,
  `deskripsi` text COLLATE utf8mb4_unicode_ci,
  `jumlah` bigint UNSIGNED NOT NULL,
  `bukti` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `perlengkapans`
--

CREATE TABLE `perlengkapans` (
  `id` bigint UNSIGNED NOT NULL,
  `nama` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `deskripsi` text COLLATE utf8mb4_unicode_ci,
  `stok` int NOT NULL,
  `stok_awal` int NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `perlengkapans`
--

INSERT INTO `perlengkapans` (`id`, `nama`, `deskripsi`, `stok`, `stok_awal`, `created_at`, `updated_at`) VALUES
(1, 'Kursi', 'Kursi KarangTaruna.', 400, 500, '2025-07-17 05:56:42', '2025-07-17 06:17:30');

-- --------------------------------------------------------

--
-- Table structure for table `personal_access_tokens`
--

CREATE TABLE `personal_access_tokens` (
  `id` bigint UNSIGNED NOT NULL,
  `tokenable_type` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tokenable_id` bigint UNSIGNED NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `token` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `abilities` text COLLATE utf8mb4_unicode_ci,
  `last_used_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `presensis`
--

CREATE TABLE `presensis` (
  `id` bigint UNSIGNED NOT NULL,
  `agenda_id` bigint UNSIGNED NOT NULL,
  `user_id` bigint UNSIGNED NOT NULL,
  `waktu_presensi` datetime NOT NULL,
  `token_yang_dipakai` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `presensis`
--

INSERT INTO `presensis` (`id`, `agenda_id`, `user_id`, `waktu_presensi`, `token_yang_dipakai`, `created_at`, `updated_at`) VALUES
(5, 7, 1, '2025-07-27 22:16:51', '7jZ51x', '2025-07-27 15:16:51', '2025-07-27 15:16:51'),
(6, 7, 2, '2025-07-27 22:19:53', 'eb25da', '2025-07-27 15:19:53', '2025-07-27 15:19:53');

-- --------------------------------------------------------

--
-- Table structure for table `strukturs`
--

CREATE TABLE `strukturs` (
  `id` bigint UNSIGNED NOT NULL,
  `jabatan` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` bigint UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `strukturs`
--

INSERT INTO `strukturs` (`id`, `jabatan`, `user_id`, `created_at`, `updated_at`) VALUES
(1, 'Ketua', 1, '2025-07-17 05:55:18', '2025-07-17 05:55:18'),
(2, 'Wakil Ketua', 3, '2025-07-17 05:55:18', '2025-07-17 05:55:18'),
(3, 'Sekretaris I', 4, '2025-07-17 05:55:18', '2025-07-17 05:55:18'),
(4, 'Sekretaris II', 5, '2025-07-17 05:55:18', '2025-07-17 05:55:18'),
(5, 'Bendahara I', 6, '2025-07-17 05:55:18', '2025-07-17 05:55:18'),
(6, 'Bendahara II', 7, '2025-07-17 05:55:18', '2025-07-17 05:55:18'),
(7, 'Pengurus I', 8, '2025-07-17 05:55:18', '2025-07-17 05:55:18'),
(8, 'Pengurus II', 9, '2025-07-17 05:55:18', '2025-07-17 05:55:18'),
(9, 'Pengurus III', 10, '2025-07-17 05:55:18', '2025-07-17 05:55:18'),
(10, 'Pengurus IV', 11, '2025-07-17 05:55:18', '2025-07-17 05:55:18');

-- --------------------------------------------------------

--
-- Table structure for table `undangans`
--

CREATE TABLE `undangans` (
  `id` bigint UNSIGNED NOT NULL,
  `nama_almarhum` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `umur` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `hari_wafat` date NOT NULL,
  `jam_wafat` time NOT NULL,
  `lokasi_wafat` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `hari_pemakaman` date NOT NULL,
  `jam_pemakaman` time NOT NULL,
  `tempat_pemakaman` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `undangans`
--

INSERT INTO `undangans` (`id`, `nama_almarhum`, `umur`, `hari_wafat`, `jam_wafat`, `lokasi_wafat`, `hari_pemakaman`, `jam_pemakaman`, `tempat_pemakaman`, `created_at`, `updated_at`) VALUES
(1, 'Almarhum Namikaze Minato', 'Dumugi yuswo 35 tahun lumayan tua', '2025-07-17', '13:11:00', 'Ndalem Konohagakure RT 16/RW 06', '2025-07-17', '17:11:00', 'Makam Sasono Mojo Loyo Konoha', '2025-07-17 06:12:11', '2025-07-17 06:12:11');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` bigint UNSIGNED NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `password` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `remember_token` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `role` enum('anggota','admin') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'anggota'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `email_verified_at`, `password`, `remember_token`, `created_at`, `updated_at`, `role`) VALUES
(1, 'Dimas Tampan', 'dimaswardoyo10@gmail.com', NULL, '$2y$12$5ox6L4K5elwm87Pq4XJkXeBFdMMA1SH/TxH62dcT2542rrAw/SGMC', NULL, '2025-07-17 04:19:46', '2025-07-17 04:19:46', 'admin'),
(2, 'Anggota 1', 'anggota1@gmail.com', NULL, '$2y$12$wQ5k1QwsgQFcjhdibtmcg.Z0DW4mcZ6NcEnQ85EvgFq5N7kROG2D.', NULL, '2025-07-17 04:19:48', '2025-07-17 04:19:48', 'anggota'),
(3, 'Anggota 2', 'anggota2@gmail.com', NULL, '$2y$12$V1aIEYld3BNJDJSpTHNG5OK2rdzvHxrUY3Kg9ZLmdy0TbpvXD.b/S', NULL, '2025-07-17 04:19:48', '2025-07-17 04:19:48', 'anggota'),
(4, 'Anggota 3', 'anggota3@gmail.com', NULL, '$2y$12$AXUEeSj297hG1xkBSnGhCu9WI/15FdQcPVkLJr5kEIui5qS23mUuS', NULL, '2025-07-17 04:19:49', '2025-07-17 04:19:49', 'anggota'),
(5, 'Anggota 4', 'anggota4@gmail.com', NULL, '$2y$12$KJSYgq7HH.yyoudkHHBps.GMIFRkuxrUsTL0tnkF/LiMVTp90/AKi', NULL, '2025-07-17 04:19:49', '2025-07-17 04:19:49', 'anggota'),
(6, 'Anggota 5', 'anggota5@gmail.com', NULL, '$2y$12$sLToqv8RCy4hrECWTejZc.9PG2pFhPqp2j/imvgc3s/UM1i3T7PPy', NULL, '2025-07-17 04:19:49', '2025-07-17 04:19:49', 'anggota'),
(7, 'Anggota 6', 'anggota6@gmail.com', NULL, '$2y$12$8HZLOcYtnhKIGnyA7/LfVu7CXj7KhpEFHN73NSiWsLmk8i6ril3Da', NULL, '2025-07-17 04:19:50', '2025-07-17 04:19:50', 'anggota'),
(8, 'Anggota 7', 'anggota7@gmail.com', NULL, '$2y$12$OAd9QWBr/YEgIonNlmuSXO8Kcru8unoSI6irrPosJHHvgFCz4RAx.', NULL, '2025-07-17 04:19:50', '2025-07-17 04:19:50', 'anggota'),
(9, 'Anggota 8', 'anggota8@gmail.com', NULL, '$2y$12$71H7kgknfN3OoKgS2L3gROSMALPyZCbZr0qpBCvZ6voZ3EyJTJtEC', NULL, '2025-07-17 04:19:50', '2025-07-17 04:19:50', 'anggota'),
(10, 'Anggota 9', 'anggota9@gmail.com', NULL, '$2y$12$sC17Ug5pzjF3qSJoBxR.fOBXtZ5PomUL6bdyqwCMqYXRaPQ8uxCVm', NULL, '2025-07-17 04:19:51', '2025-07-17 04:19:51', 'anggota'),
(11, 'Anggota 10', 'anggota10@gmail.com', NULL, '$2y$12$RXL71uzLGGhklGl2lCZlTO2o.MmBM69nrsAN3.gDIxQ6BjunXvvYG', NULL, '2025-07-17 04:19:51', '2025-07-17 04:19:51', 'anggota'),
(12, 'Anggota 11', 'anggota11@gmail.com', NULL, '$2y$12$F5h7eXGNJTPWN0Qd3GPHqOOs.5970GzmaHrfLMoBioMRPqLhCGuUG', NULL, '2025-07-17 04:19:51', '2025-07-17 04:19:51', 'anggota'),
(13, 'Anggota 12', 'anggota12@gmail.com', NULL, '$2y$12$kKxMhR5bCQvY/eMVYBQD3.GDKDrRnJZBfE7.0.khoXK8vMKIyYoiS', NULL, '2025-07-17 04:19:52', '2025-07-17 04:19:52', 'anggota'),
(14, 'Anggota 13', 'anggota13@gmail.com', NULL, '$2y$12$G5gFjdSQA8.9Dey0VFFjpuE0gSt0as/GE1YotlZvJ5OQL0F0Cn9vi', NULL, '2025-07-17 04:19:52', '2025-07-17 04:19:52', 'anggota'),
(15, 'Anggota 14', 'anggota14@gmail.com', NULL, '$2y$12$uIH5uWvxrJ.832WJHTdgAegTyGWAv6n4budhO3LQ32UG8osV517lK', NULL, '2025-07-17 04:19:52', '2025-07-17 04:19:52', 'anggota'),
(16, 'Anggota 15', 'anggota15@gmail.com', NULL, '$2y$12$rtKYGTEf3avv6qe0wXnvneFrrInHp751c2eJADFUYt1UWLT2VX0EC', NULL, '2025-07-17 04:19:52', '2025-07-17 04:19:52', 'anggota'),
(17, 'Anggota 16', 'anggota16@gmail.com', NULL, '$2y$12$cmb200N29CQFhbRg.3EZlOvxJ.iOdyucKaDthV64tZQVx9ub2ICUe', NULL, '2025-07-17 04:19:53', '2025-07-17 04:19:53', 'anggota'),
(18, 'Anggota 17', 'anggota17@gmail.com', NULL, '$2y$12$N.CvWmURfyzmM271XjIUley.VUTP8E5w9HabBIWwn.oi47v7D/AvO', NULL, '2025-07-17 04:19:53', '2025-07-17 04:19:53', 'anggota'),
(19, 'Anggota 18', 'anggota18@gmail.com', NULL, '$2y$12$vC6yuNcKQqLk8i5VqSgD9OtAtY6dO2GEbLHSl2mDC/4h9W/QpxSRO', NULL, '2025-07-17 04:19:53', '2025-07-17 04:19:53', 'anggota'),
(20, 'Anggota 19', 'anggota19@gmail.com', NULL, '$2y$12$NKOoYEturZEImB9MvI3KdOG13jTMH7S28b4dkdI60wQijw4xa2C42', NULL, '2025-07-17 04:19:54', '2025-07-17 04:19:54', 'anggota'),
(21, 'Anggota 20', 'anggota20@gmail.com', NULL, '$2y$12$BunHa2Jk4tnDT9njwJ7zBehv.hbqrMAK44fFvcV1ggRY..MsZK32u', NULL, '2025-07-17 04:19:54', '2025-07-17 04:19:54', 'anggota'),
(22, 'Anggota 21', 'anggota21@gmail.com', NULL, '$2y$12$9I8OIVwvMymHhnWGmzu5veGJTWh0ACa4U.QPjny6kbbDfKPeQJ0fK', NULL, '2025-07-17 04:19:54', '2025-07-17 04:19:54', 'anggota'),
(23, 'Anggota 22', 'anggota22@gmail.com', NULL, '$2y$12$J6zffPQoqnBsW2/5UsyGIOFtJkyrEoxjIZIrU2Zgf86RjjYhg0ram', NULL, '2025-07-17 04:19:55', '2025-07-17 04:19:55', 'anggota'),
(24, 'Anggota 23', 'anggota23@gmail.com', NULL, '$2y$12$nYOB5ktP5X.5MdAcM9vtEO91BY9RvV1wV69nPCQ1vrBEoomre7bh2', NULL, '2025-07-17 04:19:55', '2025-07-17 04:19:55', 'anggota'),
(25, 'Anggota 24', 'anggota24@gmail.com', NULL, '$2y$12$reTesK3hXvPUZJsGsoYdEOLlkALf.1Vw7AbvipYRWx6biuuwPNDNm', NULL, '2025-07-17 04:19:55', '2025-07-17 04:19:55', 'anggota'),
(26, 'Anggota 25', 'anggota25@gmail.com', NULL, '$2y$12$eczw2IwtENGj1jPL4YWtouo36fFPHvUclxUSiK7e9ZgRXsWPxGUZK', NULL, '2025-07-17 04:19:55', '2025-07-17 04:19:55', 'anggota'),
(27, 'Anggota 26', 'anggota26@gmail.com', NULL, '$2y$12$DY/wo2XQyZmvqXwiJHTvuu5nDbgqQiVfTkYj84yKbl.cZKsRNn5qC', NULL, '2025-07-17 04:19:56', '2025-07-17 04:19:56', 'anggota'),
(28, 'Anggota 27', 'anggota27@gmail.com', NULL, '$2y$12$ZvLDWR29R4bPJwRoycccn.51GTq1FpfkGDYxlbbJuLK3NcEaOffSu', NULL, '2025-07-17 04:19:56', '2025-07-17 04:19:56', 'anggota'),
(29, 'Anggota 28', 'anggota28@gmail.com', NULL, '$2y$12$JJTRPDe8ss465EzFA2XRI.voM8jBTO9v1fb3pLIi5fUPR6p.5i47G', NULL, '2025-07-17 04:19:56', '2025-07-17 04:19:56', 'anggota'),
(30, 'Anggota 29', 'anggota29@gmail.com', NULL, '$2y$12$W.S62MFnGUrWoHQj4O5CTO58w/mu9.RE/aVwp9FrHoRI3rRuTzwua', NULL, '2025-07-17 04:19:57', '2025-07-17 04:19:57', 'anggota'),
(31, 'Anggota 30', 'anggota30@gmail.com', NULL, '$2y$12$pZMN4sPHFwtlsD3z/nE4JOBvM4byP539xHxyCwwKyN1/7v97zPQr2', NULL, '2025-07-17 04:19:57', '2025-07-17 04:19:57', 'anggota'),
(32, 'Anggota 31', 'anggota31@gmail.com', NULL, '$2y$12$zACqIXSoWJ6MmAf2lDgKtur4d5aXjmmzLuNnQjB8c/3LYy7B6bnc.', NULL, '2025-07-17 04:19:57', '2025-07-17 04:19:57', 'anggota'),
(33, 'Anggota 32', 'anggota32@gmail.com', NULL, '$2y$12$hIK9cCND//AA53K9FXswS.MQp5TJQq7CQZe7botaj9yXsW5pppJqC', NULL, '2025-07-17 04:19:58', '2025-07-17 04:19:58', 'anggota'),
(34, 'Anggota 33', 'anggota33@gmail.com', NULL, '$2y$12$v9.Uf1dlokuQ7ceezEN.OOSA2pDieY8DNcI1F1jn.JmByHWylgJ.i', NULL, '2025-07-17 04:19:58', '2025-07-17 04:19:58', 'anggota'),
(35, 'Anggota 34', 'anggota34@gmail.com', NULL, '$2y$12$RpQyezp8OLIWI1EIZTjFe.NmmFG1upqqXKCfxEJeD6jlcEGO5Doja', NULL, '2025-07-17 04:19:58', '2025-07-17 04:19:58', 'anggota'),
(36, 'Anggota 35', 'anggota35@gmail.com', NULL, '$2y$12$ulZscd4hLIKv3vc0flPGcOBnIjMrM0TptZSjUNCSHy2fD6a9rMJTK', NULL, '2025-07-17 04:19:58', '2025-07-17 04:19:58', 'anggota'),
(37, 'Anggota 36', 'anggota36@gmail.com', NULL, '$2y$12$KdJ4s.SXUvwUxmKOH7Mx3O/Cl0S2eYFK1/BHdKyE0YAyMFRkfNIAa', NULL, '2025-07-17 04:19:59', '2025-07-17 04:19:59', 'anggota'),
(38, 'Anggota 37', 'anggota37@gmail.com', NULL, '$2y$12$7YR4anWzJqFdoHrfRGaLQe/zWQ/qHy1e7/8h7oW.G11KOyNxPdSOq', NULL, '2025-07-17 04:19:59', '2025-07-17 04:19:59', 'anggota'),
(39, 'Anggota 38', 'anggota38@gmail.com', NULL, '$2y$12$3MZNLuShM1wVwDABfHN80Okdkz5U9OQvbD0VqAXVFxBjAQH8OyJtW', NULL, '2025-07-17 04:19:59', '2025-07-17 04:19:59', 'anggota'),
(40, 'Anggota 39', 'anggota39@gmail.com', NULL, '$2y$12$5oMhGg3YPqeaZYjv3j7td.HTfBlcNL6roNlpRfXMAqki3A4bQGRKW', NULL, '2025-07-17 04:20:00', '2025-07-17 04:20:00', 'anggota'),
(41, 'Anggota 40', 'anggota40@gmail.com', NULL, '$2y$12$ubng3WByzz85X4hvKn0B..zcL3WRhGid4IxWlxgRgUtP3jGbrnN8K', NULL, '2025-07-17 04:20:00', '2025-07-17 04:20:00', 'anggota'),
(42, 'Anggota 41', 'anggota41@gmail.com', NULL, '$2y$12$rdIHfyocpaVxXUYikOYMWOmg6r2Da8JhXbghJvF/zQkvcM.gv1DDK', NULL, '2025-07-17 04:20:00', '2025-07-17 04:20:00', 'anggota'),
(43, 'Anggota 42', 'anggota42@gmail.com', NULL, '$2y$12$N7tUbVBCrnaUFnj/t8a58OSsDNGMTvDbX8oz7tT3TzBU.TsUVZvia', NULL, '2025-07-17 04:20:01', '2025-07-17 04:20:01', 'anggota'),
(44, 'Anggota 43', 'anggota43@gmail.com', NULL, '$2y$12$vSNHr7x4hxekeeWLOZAlEewrsmiry9I9xA9w42spJdygituE/arIO', NULL, '2025-07-17 04:20:01', '2025-07-17 04:20:01', 'anggota'),
(45, 'Anggota 44', 'anggota44@gmail.com', NULL, '$2y$12$o67uvBMhJs3HGOaKFgKldewxhXD6t4n31MeXlzMwJyphBUG3/vzFi', NULL, '2025-07-17 04:20:01', '2025-07-17 04:20:01', 'anggota'),
(46, 'Anggota 45', 'anggota45@gmail.com', NULL, '$2y$12$.Emts1BC99GZTfLaiFeHGeLeEpuMpQ7aJtMNXmRgAe8Q.YLE.d0Qm', NULL, '2025-07-17 04:20:02', '2025-07-17 04:20:02', 'anggota'),
(47, 'Anggota 46', 'anggota46@gmail.com', NULL, '$2y$12$3qDnWbf0H3m30olQxg7d.erqDb6zIAIOb49sDQJxnrnJqZ6XAzO5m', NULL, '2025-07-17 04:20:02', '2025-07-17 04:20:02', 'anggota'),
(48, 'Anggota 47', 'anggota47@gmail.com', NULL, '$2y$12$GasIcO1OdqPNfacy0BNbeOclZe3vAaQ36dZmj1tNd2/xVIGe3gLLm', NULL, '2025-07-17 04:20:02', '2025-07-17 04:20:02', 'anggota'),
(49, 'Anggota 48', 'anggota48@gmail.com', NULL, '$2y$12$sdYxDisIj1NsgvH4PgHcZuIM.lqgxW09AVd86UPaU4Iu.mfBGEZ7C', NULL, '2025-07-17 04:20:02', '2025-07-17 04:20:02', 'anggota'),
(50, 'Anggota 49', 'anggota49@gmail.com', NULL, '$2y$12$tM2nLVsHR6Cj8zVaVRfhde1WYvURQz2TH3umjN/zg1g1ZW8.BQh2G', NULL, '2025-07-17 04:20:03', '2025-07-17 04:20:03', 'anggota'),
(51, 'Anggota 50', 'anggota50@gmail.com', NULL, '$2y$12$MKVQ1qExnR7vCgYHznWroe3YpamHt3x0WKpUaO9uOXN.eCB0GbAb6', NULL, '2025-07-17 04:20:03', '2025-07-17 04:20:03', 'anggota'),
(52, 'Anggota 51', 'anggota51@gmail.com', NULL, '$2y$12$Lgy9qep9jFTS8mX2IRfhmuKkw2iE7dc6ndCBoeA5D4w1zIUmP1zHi', NULL, '2025-07-17 04:20:03', '2025-07-17 04:20:03', 'anggota'),
(53, 'Anggota 52', 'anggota52@gmail.com', NULL, '$2y$12$PuF.yx32dShgytzrZ61/8uedsvZa044bPbZcle/vIc6cHJvjENHy.', NULL, '2025-07-17 04:20:04', '2025-07-17 04:20:04', 'anggota'),
(54, 'Anggota 53', 'anggota53@gmail.com', NULL, '$2y$12$jSVMYwsSDjTMVa/1DOlv2u9Yh5ekFvBy2Cuos4gfeEDa/jIyH9Uj.', NULL, '2025-07-17 04:20:04', '2025-07-17 04:20:04', 'anggota'),
(55, 'Anggota 54', 'anggota54@gmail.com', NULL, '$2y$12$nNu.vruMGWYo6NA8i2yvauWcmoDXqyWZckMyKVEZrj9kyJ4YIdfdG', NULL, '2025-07-17 04:20:04', '2025-07-17 04:20:04', 'anggota'),
(56, 'Anggota 55', 'anggota55@gmail.com', NULL, '$2y$12$.hzs4YjWupwW0fdDew6PN.Td0US8NKdXXjoIQHwSfcxkDlRFGCVxG', NULL, '2025-07-17 04:20:05', '2025-07-17 04:20:05', 'anggota'),
(57, 'Anggota 56', 'anggota56@gmail.com', NULL, '$2y$12$Tmo1CWGw8miCVZS6hRVEiu5bTFGi1IqBsH99aDM682iqvlCOJa3ii', NULL, '2025-07-17 04:20:05', '2025-07-17 04:20:05', 'anggota'),
(58, 'Anggota 57', 'anggota57@gmail.com', NULL, '$2y$12$xOkaedqvvu1EjvKB.nVx2urQOtS7FBLqSFmsxUQFohFKDyI4gz.hK', NULL, '2025-07-17 04:20:05', '2025-07-17 04:20:05', 'anggota'),
(59, 'Anggota 58', 'anggota58@gmail.com', NULL, '$2y$12$D1YCTFT0R657lSrtRxWdgOden/5B6dmdz7Ns8DIJT0YJfs9hLAsV6', NULL, '2025-07-17 04:20:05', '2025-07-17 04:20:05', 'anggota'),
(60, 'Anggota 59', 'anggota59@gmail.com', NULL, '$2y$12$dSKXpsiuowntDKCRNzpDKOmxodRUe9L1LL68Y1TKlNcm17zN.KoEm', NULL, '2025-07-17 04:20:06', '2025-07-17 04:20:06', 'anggota'),
(61, 'Anggota 60', 'anggota60@gmail.com', NULL, '$2y$12$u.yQzzj.7fFw5bim1IWEhuU0yvxgmatiSBABXc28XguPXIsLTfm3K', NULL, '2025-07-17 04:20:06', '2025-07-17 04:20:06', 'anggota'),
(62, 'Anggota 61', 'anggota61@gmail.com', NULL, '$2y$12$bliDeMdnBNjqqIAEKtKwluEPm33qambxjTXIDSNlg1MGxPocLISZi', NULL, '2025-07-17 04:20:06', '2025-07-17 04:20:06', 'anggota'),
(63, 'Anggota 62', 'anggota62@gmail.com', NULL, '$2y$12$e/.7iCkkQmOq4pxoVYJ5qu2mYavG4ha2GykMeoLxSKEH0Ho1PaTh2', NULL, '2025-07-17 04:20:07', '2025-07-17 04:20:07', 'anggota'),
(64, 'Anggota 63', 'anggota63@gmail.com', NULL, '$2y$12$Ir83sfPqmHRjdz3GgWxac.ULVPpzXZ2P0O9g6QSkSSz7nUaMZVs3a', NULL, '2025-07-17 04:20:07', '2025-07-17 04:20:07', 'anggota'),
(65, 'Anggota 64', 'anggota64@gmail.com', NULL, '$2y$12$WOuW1MJOnCDrejgWPWfHhedzMmYFkGkh6sUy6RiDS0E4lLh8eR.Um', NULL, '2025-07-17 04:20:07', '2025-07-17 04:20:07', 'anggota'),
(66, 'Anggota 65', 'anggota65@gmail.com', NULL, '$2y$12$Jm0oC3Ptl3TNbSqMufqbMOqy5ExY051MgrcEua6MJO46Ry4dQYjyG', NULL, '2025-07-17 04:20:08', '2025-07-17 04:20:08', 'anggota'),
(67, 'Anggota 66', 'anggota66@gmail.com', NULL, '$2y$12$.B0oG3aiBve2LaaaH9QtaeArjWtELKKATwMLa2.ZEdy/YtF38ZV4a', NULL, '2025-07-17 04:20:08', '2025-07-17 04:20:08', 'anggota'),
(68, 'Anggota 67', 'anggota67@gmail.com', NULL, '$2y$12$Uf8KW1h7uAmyyxvoA7MCt.IPf/yDkeW0Vbt/q097wtIzt7QQ51F7a', NULL, '2025-07-17 04:20:08', '2025-07-17 04:20:08', 'anggota'),
(69, 'Anggota 68', 'anggota68@gmail.com', NULL, '$2y$12$zqtMLuc0fjQ07ewE7dR4yucFQUvl9ATEv6m19Bz/sZsD51Xy/zfge', NULL, '2025-07-17 04:20:08', '2025-07-17 04:20:08', 'anggota'),
(70, 'Anggota 69', 'anggota69@gmail.com', NULL, '$2y$12$347puWQzFRt5yYadtVsGkuKedhkhlSmmno2iJFECQ8p7QCUPP8Pjq', NULL, '2025-07-17 04:20:09', '2025-07-17 04:20:09', 'anggota'),
(71, 'Anggota 70', 'anggota70@gmail.com', NULL, '$2y$12$OipLDu6WzFqoqyX82vHbcOU/ahofZl3vHh60iY6drjHilEeCH6ZUO', NULL, '2025-07-17 04:20:09', '2025-07-17 04:20:09', 'anggota'),
(72, 'Anggota 71', 'anggota71@gmail.com', NULL, '$2y$12$Bzhk8YtrsaNOsIG9SMlaTOY2mDwmDf51Grcuoge3LPbPLuEXQZ18.', NULL, '2025-07-17 04:20:09', '2025-07-17 04:20:09', 'anggota'),
(73, 'Anggota 72', 'anggota72@gmail.com', NULL, '$2y$12$zgDpR1osY/PsIv3rwWQa1.WYvy/Bpcu/spNqKo4VMZktVY/jz9.IW', NULL, '2025-07-17 04:20:10', '2025-07-17 04:20:10', 'anggota'),
(74, 'Anggota 73', 'anggota73@gmail.com', NULL, '$2y$12$N32q3.NuWtZxuIVr5ytWce7S7gEWjAjiZVq/5tINucKGH/7TpcAf6', NULL, '2025-07-17 04:20:10', '2025-07-17 04:20:10', 'anggota'),
(75, 'Anggota 74', 'anggota74@gmail.com', NULL, '$2y$12$86CooiWes.rgTSxgkdwSNOTfm44wQMtCrLyqINPxDfHj53xITcYhm', NULL, '2025-07-17 04:20:10', '2025-07-17 04:20:10', 'anggota'),
(76, 'Anggota 75', 'anggota75@gmail.com', NULL, '$2y$12$9N4N/dZQAv9di5yOi6U0YOj0K92E9DUIrDFN23lzjyhxk8Ks1FgJ6', NULL, '2025-07-17 04:20:11', '2025-07-17 04:20:11', 'anggota'),
(77, 'Anggota 76', 'anggota76@gmail.com', NULL, '$2y$12$F/dacNtG4wtw6hQNsVylBupYqut9xixIkqXEhgXjVcyae10IMrbvG', NULL, '2025-07-17 04:20:11', '2025-07-17 04:20:11', 'anggota'),
(78, 'Anggota 77', 'anggota77@gmail.com', NULL, '$2y$12$PktRFQV3EQ2k4VA13zTNqebndJEalvIBgzeFv94G9jFANyOvu/SWa', NULL, '2025-07-17 04:20:11', '2025-07-17 04:20:11', 'anggota'),
(79, 'Anggota 78', 'anggota78@gmail.com', NULL, '$2y$12$6aI2WxEQ.Fu1YxWLR65PWeG34Io565Kcjoicb2Nf6CPL0Eq/QA./i', NULL, '2025-07-17 04:20:11', '2025-07-17 04:20:11', 'anggota'),
(80, 'Anggota 79', 'anggota79@gmail.com', NULL, '$2y$12$M3A7Y2mvsp4BHy4ugwJ6h.5i29NVTe0eYUIFHsrQvz9J9WbSBjn0e', NULL, '2025-07-17 04:20:12', '2025-07-17 04:20:12', 'anggota'),
(81, 'Anggota 80', 'anggota80@gmail.com', NULL, '$2y$12$3F8MFrpxTcSCKgEaBhP/UeUXXOJJeZlEGpOjHFLJayysuKt364khO', NULL, '2025-07-17 04:20:12', '2025-07-17 04:20:12', 'anggota'),
(82, 'Anggota 81', 'anggota81@gmail.com', NULL, '$2y$12$dcjdahqfqWLty3JUf5uV0eZ6A3jct35aoBeBo2eYb74JqlhxwwdKe', NULL, '2025-07-17 04:20:12', '2025-07-17 04:20:12', 'anggota'),
(83, 'Anggota 82', 'anggota82@gmail.com', NULL, '$2y$12$.xkrWRmYhIPvY8pNSQ.HvehNwyvPIVQZVKYCs7McqhB05jAVDT8H.', NULL, '2025-07-17 04:20:13', '2025-07-17 04:20:13', 'anggota'),
(84, 'Anggota 83', 'anggota83@gmail.com', NULL, '$2y$12$MROGRGlYbV9iqBQLRi0Nb.Eky6LoK2YCmr34Ii9kyrNDN4FCNdnuW', NULL, '2025-07-17 04:20:13', '2025-07-17 04:20:13', 'anggota'),
(85, 'Anggota 84', 'anggota84@gmail.com', NULL, '$2y$12$Ez0PCCD1lCuqrdWEn4D6EOrUE39UPQk0lpnXmCqGBnlt7RkNDvq1u', NULL, '2025-07-17 04:20:13', '2025-07-17 04:20:13', 'anggota'),
(86, 'Anggota 85', 'anggota85@gmail.com', NULL, '$2y$12$b2SxGmWEKCr31IXzHOW3/euEn5hoQtdVLWVHTZy/igwOi6VM40YTq', NULL, '2025-07-17 04:20:14', '2025-07-17 04:20:14', 'anggota'),
(87, 'Anggota 86', 'anggota86@gmail.com', NULL, '$2y$12$m5kkR8op0Oel6pE2jg2tS./NrD7izQxJHKKTcDkgfVaV5oV9rxQ9.', NULL, '2025-07-17 04:20:14', '2025-07-17 04:20:14', 'anggota'),
(88, 'Anggota 87', 'anggota87@gmail.com', NULL, '$2y$12$OY13JWhN4cKhsAS31avnpeIaIjmiR/7MSWR2sT9TEsz4m1lUfKOwC', NULL, '2025-07-17 04:20:14', '2025-07-17 04:20:14', 'anggota'),
(89, 'Anggota 88', 'anggota88@gmail.com', NULL, '$2y$12$FdBJuRPzN1FSFU6znKhkd.7Ktqwkeqp3gAeSKRAoijeAj4ndCBXFO', NULL, '2025-07-17 04:20:15', '2025-07-17 04:20:15', 'anggota'),
(90, 'Anggota 89', 'anggota89@gmail.com', NULL, '$2y$12$7qmoVZCSYgul3Ema8X09/OBuOBe3Q9VbYFcKs.BY/N3uEY2ixUoAO', NULL, '2025-07-17 04:20:15', '2025-07-17 04:20:15', 'anggota'),
(91, 'Anggota 90', 'anggota90@gmail.com', NULL, '$2y$12$TOfosBZ8fQ1RvGEDIIfX5.hdtcyaTYxgeHZO9E39whF1IGQYkaZVW', NULL, '2025-07-17 04:20:15', '2025-07-17 04:20:15', 'anggota'),
(92, 'Anggota 91', 'anggota91@gmail.com', NULL, '$2y$12$ofC0.LiPeGQ0RdnD1yj3TO7mch9YeffbBVrnKudoE4e6AO.QruBia', NULL, '2025-07-17 04:20:15', '2025-07-17 04:20:15', 'anggota'),
(93, 'Anggota 92', 'anggota92@gmail.com', NULL, '$2y$12$7O8sPUtF0j455yQ.4RQICO.sezOcQ5McTPwQKkW6Xr7lomqmOjW1W', NULL, '2025-07-17 04:20:16', '2025-07-17 04:20:16', 'anggota'),
(94, 'Anggota 93', 'anggota93@gmail.com', NULL, '$2y$12$DuhYstnh.xS.1L68BV9XTepl8nPuIJBGx.eSPO5iEPsYgGjBVNDfu', NULL, '2025-07-17 04:20:16', '2025-07-17 04:20:16', 'anggota'),
(95, 'Anggota 94', 'anggota94@gmail.com', NULL, '$2y$12$7/LOWrAIyoQbQW/v5I.JnOvByoEuExvyrKM.sr8eY/kCELV3wGwH2', NULL, '2025-07-17 04:20:16', '2025-07-17 04:20:16', 'anggota'),
(96, 'Anggota 95', 'anggota95@gmail.com', NULL, '$2y$12$kEoY7g5kAuvltrf8R8Cv9O5xBg.K9Lxe/bUPB8ZUnHd9Snfnkd/Eq', NULL, '2025-07-17 04:20:17', '2025-07-17 04:20:17', 'anggota'),
(97, 'Anggota 96', 'anggota96@gmail.com', NULL, '$2y$12$6r7t4FdTg5U5jlX4AeFWN.SYpKjT7/v.RpDIJeSCcVBLkGUyyZB8G', NULL, '2025-07-17 04:20:17', '2025-07-17 04:20:17', 'anggota'),
(98, 'Anggota 97', 'anggota97@gmail.com', NULL, '$2y$12$va6FPrY1LH9IJfanLwWiGebyahNwmk.65Xrop848FGPUwF/KJDQHe', NULL, '2025-07-17 04:20:17', '2025-07-17 04:20:17', 'anggota'),
(99, 'Anggota 98', 'anggota98@gmail.com', NULL, '$2y$12$zN18Y1cu6ouyW9CsYtBzsOiWu6KS2.q5JeuIZ5bzZqjMRkzzgHl3C', NULL, '2025-07-17 04:20:18', '2025-07-17 04:20:18', 'anggota'),
(100, 'Anggota 99', 'anggota99@gmail.com', NULL, '$2y$12$YCwqiDWtZc0o3irHgzlx0OdE.PWPoeUKGvcBZpPbKBqBZZhQCncsC', NULL, '2025-07-17 04:20:18', '2025-07-17 04:20:18', 'anggota'),
(101, 'Anggota 100', 'anggota100@gmail.com', NULL, '$2y$12$T8XcAPyQMZATce9J8HUfceWt.P93DUsDG0LLIt2j1AKre3QwFuiAS', NULL, '2025-07-17 04:20:18', '2025-07-17 04:20:18', 'anggota'),
(102, 'Anggota 101', 'anggota101@gmail.com', NULL, '$2y$12$tv.YsSQrb/a7pkJ2dgbdJ.58NhHczIxUaQ9oLj5/r8L4HKdJ2JzNq', NULL, '2025-07-17 04:20:18', '2025-07-17 04:20:18', 'anggota'),
(103, 'Anggota 102', 'anggota102@gmail.com', NULL, '$2y$12$Y.9Bc.rfCFftfHixHm9ng.vh/l7gjpSDkbUJMU6PTiLFgTZjXVvYK', NULL, '2025-07-17 04:20:19', '2025-07-17 04:20:19', 'anggota'),
(104, 'Anggota 103', 'anggota103@gmail.com', NULL, '$2y$12$LxMFh4UkWouuF9wdZ8X7fe.TWE1zQ6tXyA3SuZoGM2i.ZUZXBjHjG', NULL, '2025-07-17 04:20:19', '2025-07-17 04:20:19', 'anggota'),
(105, 'Anggota 104', 'anggota104@gmail.com', NULL, '$2y$12$sQk/K/kWmDJD8QdCg1C5qOE72b4yD3KGF.u2RK3sQKzP97lqxZ1XO', NULL, '2025-07-17 04:20:19', '2025-07-17 04:20:19', 'anggota'),
(106, 'Anggota 105', 'anggota105@gmail.com', NULL, '$2y$12$MEWT3yxJzqbfbl0jajnLLeLtijl8poXJ3E7iabWsG4hgD9mIpoa6W', NULL, '2025-07-17 04:20:20', '2025-07-17 04:20:20', 'anggota'),
(107, 'Anggota 106', 'anggota106@gmail.com', NULL, '$2y$12$YxU1ddFiSihtqSyVBMGpDedXRcL.JNyVwDzr176GasyDnNohTyWw.', NULL, '2025-07-17 04:20:20', '2025-07-17 04:20:20', 'anggota'),
(108, 'Anggota 107', 'anggota107@gmail.com', NULL, '$2y$12$gjawmLmTCUdOTcNTK8WdKuW4vgqFTWCYV5MkZWkLSMuBC2jkdx8Na', NULL, '2025-07-17 04:20:20', '2025-07-17 04:20:20', 'anggota'),
(109, 'Anggota 108', 'anggota108@gmail.com', NULL, '$2y$12$er4psZVVdGmVLMxbO0HrAe4gCyKOy4uFQY3lZP.naHMNaL5vkldem', NULL, '2025-07-17 04:20:21', '2025-07-17 04:20:21', 'anggota'),
(110, 'Anggota 109', 'anggota109@gmail.com', NULL, '$2y$12$E90VqcReOFIjkmvUvR4Xy.aIisuzo66qj9eu35w9KfQjGmbMRs4eq', NULL, '2025-07-17 04:20:21', '2025-07-17 04:20:21', 'anggota'),
(111, 'Anggota 110', 'anggota110@gmail.com', NULL, '$2y$12$/x1uHsLUc67IDgTVJIpkyeLTa6iKxoY4HzemhqcZzBHfO32eJ1Mea', NULL, '2025-07-17 04:20:21', '2025-07-17 04:20:21', 'anggota'),
(112, 'Anggota 111', 'anggota111@gmail.com', NULL, '$2y$12$symV32uKL7j1OV3oc28S6uJ/zTxPVnDSJI/zsAtKBP8XHcxKw0DnO', NULL, '2025-07-17 04:20:22', '2025-07-17 04:20:22', 'anggota'),
(113, 'Anggota 112', 'anggota112@gmail.com', NULL, '$2y$12$446jorpBIw6AsWQ10OmNre1mzYyoW7QuJBEzXGF3zjKzzSSTi3oqK', NULL, '2025-07-17 04:20:22', '2025-07-17 04:20:22', 'anggota'),
(114, 'Anggota 113', 'anggota113@gmail.com', NULL, '$2y$12$tzgpherj99tD.pJFQ8DigOzfgkeRezjXLk2w0eKp35hGL0p4kU/ra', NULL, '2025-07-17 04:20:22', '2025-07-17 04:20:22', 'anggota'),
(115, 'Anggota 114', 'anggota114@gmail.com', NULL, '$2y$12$evizhu7tZ2/2rfA.mb8UnO1kPh4/lKqBBxBulZd0nooMu2NdvOtRy', NULL, '2025-07-17 04:20:23', '2025-07-17 04:20:23', 'anggota'),
(116, 'Anggota 115', 'anggota115@gmail.com', NULL, '$2y$12$QsNSUCnFBZ0Bsz9oYxFvfOcfYJlEOcUlgjt9OqSqcL3Bd48rkHY/G', NULL, '2025-07-17 04:20:23', '2025-07-17 04:20:23', 'anggota'),
(117, 'Anggota 116', 'anggota116@gmail.com', NULL, '$2y$12$4Qx7zz6q3AV1tw1cl57G.eKN2Xmk5wbAhKK9wdl0I2Ep7JREbEEoq', NULL, '2025-07-17 04:20:23', '2025-07-17 04:20:23', 'anggota'),
(118, 'Anggota 117', 'anggota117@gmail.com', NULL, '$2y$12$yH9V9.nzTLBeJx7aUAy1Bei.IP50fb8qyhYiAkObRvNITJo9p/iTm', NULL, '2025-07-17 04:20:24', '2025-07-17 04:20:24', 'anggota'),
(119, 'Anggota 118', 'anggota118@gmail.com', NULL, '$2y$12$R7gtIrwDS4H0AYvITP58jeEug5ZkzEWGbIgmYOVptAXvBav/MqWtK', NULL, '2025-07-17 04:20:24', '2025-07-17 04:20:24', 'anggota'),
(120, 'Anggota 119', 'anggota119@gmail.com', NULL, '$2y$12$PdjMpPG73aDjlPytOEJy3.NQFHA7QdrIsJeJCBSVQLLZy.jVg00ci', NULL, '2025-07-17 04:20:24', '2025-07-17 04:20:24', 'anggota'),
(121, 'Anggota 120', 'anggota120@gmail.com', NULL, '$2y$12$9gx4NKcbw3x7aohRnyFB9.FVUB7BXQAQWxuVow5RTTNqlktKw5Q5.', NULL, '2025-07-17 04:20:25', '2025-07-17 04:20:25', 'anggota'),
(122, 'Anggota 121', 'anggota121@gmail.com', NULL, '$2y$12$6g5aqvNw6bW2GYkclFxVZeonMf8wkVHwYjkTUOTBBg2FC3rq3DByW', NULL, '2025-07-17 04:20:25', '2025-07-17 04:20:25', 'anggota'),
(123, 'Anggota 122', 'anggota122@gmail.com', NULL, '$2y$12$y5IrpKAO0LioJs6c0LSiJeekrZupywKAZxhqCgjsg2O3Da0F8xrC2', NULL, '2025-07-17 04:20:25', '2025-07-17 04:20:25', 'anggota'),
(124, 'Anggota 123', 'anggota123@gmail.com', NULL, '$2y$12$ZKREJRDWSD204Pll7pzPb.kxkwOZmvC9LZ69d6nij0R6B0QT1eORW', NULL, '2025-07-17 04:20:26', '2025-07-17 04:20:26', 'anggota'),
(125, 'Anggota 124', 'anggota124@gmail.com', NULL, '$2y$12$xKGaI7J88TnbKeXlbUuPKeheiiJqaqWD8kFi2dWjBAz6keBwDbQma', NULL, '2025-07-17 04:20:26', '2025-07-17 04:20:26', 'anggota'),
(126, 'Anggota 125', 'anggota125@gmail.com', NULL, '$2y$12$fiV4MGSCGeZ6CcGeGlGGm.LbieKIVSIxtKvTVTLK.u39KooMlR1r.', NULL, '2025-07-17 04:20:26', '2025-07-17 04:20:26', 'anggota'),
(127, 'Anggota 126', 'anggota126@gmail.com', NULL, '$2y$12$AXlT86G0.Xs1.LRt/mSEwO.eUeap8ZIJw7Mt21tcf79bx3uIKUjX2', NULL, '2025-07-17 04:20:26', '2025-07-17 04:20:26', 'anggota'),
(128, 'Anggota 127', 'anggota127@gmail.com', NULL, '$2y$12$I8FIkKUZAszd0oLjaOlfiOLlUsWgtfzGz8YlKHvH9bar00b9/pfhm', NULL, '2025-07-17 04:20:27', '2025-07-17 04:20:27', 'anggota'),
(129, 'Anggota 128', 'anggota128@gmail.com', NULL, '$2y$12$k7L.zno3Wf.nNpaARgrT9eIxpkHUULEaB3aiMx2Rrsrz3jZK4yLFy', NULL, '2025-07-17 04:20:27', '2025-07-17 04:20:27', 'anggota'),
(130, 'Anggota 129', 'anggota129@gmail.com', NULL, '$2y$12$0PS32282yfEjFUa9aYblZe/HIzw/JnhHdJIAC6e8Swz8m5WoFjOS6', NULL, '2025-07-17 04:20:27', '2025-07-17 04:20:27', 'anggota'),
(131, 'Anggota 130', 'anggota130@gmail.com', NULL, '$2y$12$zfbpVakXK87Esd9Kqg3bYet7vAOsRGb8rFHs3OxblZZrKjPDnUSS6', NULL, '2025-07-17 04:20:28', '2025-07-17 04:20:28', 'anggota'),
(132, 'Anggota 131', 'anggota131@gmail.com', NULL, '$2y$12$87d7XCQH1LHlh7DHmVe9A.ky.0wHoJyNfI9CI1aaSYRvtsJ9JR3na', NULL, '2025-07-17 04:20:28', '2025-07-17 04:20:28', 'anggota'),
(133, 'Anggota 132', 'anggota132@gmail.com', NULL, '$2y$12$4qhj6wWnDF0ZieL931thjOBiHNnrT00pQ4q876nfVR3JVHYiMNyda', NULL, '2025-07-17 04:20:28', '2025-07-17 04:20:28', 'anggota'),
(134, 'Anggota 133', 'anggota133@gmail.com', NULL, '$2y$12$njp0l38Nga2fM/eDFhbnP.2Wj6qvGqkW5KOhaOGa9Og98C1jQKp1S', NULL, '2025-07-17 04:20:29', '2025-07-17 04:20:29', 'anggota'),
(135, 'Anggota 134', 'anggota134@gmail.com', NULL, '$2y$12$KjPJDT..Xfi8TMDToZkRcOsYBdK6NZ3pMB5HeDKcXPcUEUXdZFJpG', NULL, '2025-07-17 04:20:29', '2025-07-17 04:20:29', 'anggota'),
(136, 'Anggota 135', 'anggota135@gmail.com', NULL, '$2y$12$5HzqNVjhnN3TnKylVWhpgONXEzU4EReOf4RooogvZUNmqv9dD26vK', NULL, '2025-07-17 04:20:29', '2025-07-17 04:20:29', 'anggota'),
(137, 'Anggota 136', 'anggota136@gmail.com', NULL, '$2y$12$kn1Ze1d3soEnhpOY7ayfauQ4eM5NwpEFpMKXUHth87PBkJST3CyY6', NULL, '2025-07-17 04:20:30', '2025-07-17 04:20:30', 'anggota'),
(138, 'Anggota 137', 'anggota137@gmail.com', NULL, '$2y$12$ZW7nlcpb0h5CNONVaoQuw.43zhUNBQgV05fMyb7fYZ/kbMg48P1LG', NULL, '2025-07-17 04:20:30', '2025-07-17 04:20:30', 'anggota'),
(139, 'Anggota 138', 'anggota138@gmail.com', NULL, '$2y$12$H1wObSfeq7qtniqauizNquzA1Pnq2vigafC4v7SqGyQnWohFJO6qS', NULL, '2025-07-17 04:20:30', '2025-07-17 04:20:30', 'anggota'),
(140, 'Anggota 139', 'anggota139@gmail.com', NULL, '$2y$12$xvjg0b8OejzDD/I70nY/r.h5enyiuxDbq9PDWzjrv9LflPK3IctSq', NULL, '2025-07-17 04:20:30', '2025-07-17 04:20:30', 'anggota'),
(141, 'Anggota 140', 'anggota140@gmail.com', NULL, '$2y$12$5ioZLujsiZZfqN8eyZa8B.IxOjja3KmuUyp03mDbVlO1i848EMJsu', NULL, '2025-07-17 04:20:31', '2025-07-17 04:20:31', 'anggota'),
(142, 'Anggota 141', 'anggota141@gmail.com', NULL, '$2y$12$D493xMXarveFNqOWYpUCV.mw7YRy.nphar3rYT71B7UW6HmUNwEbO', NULL, '2025-07-17 04:20:31', '2025-07-17 04:20:31', 'anggota'),
(143, 'Anggota 142', 'anggota142@gmail.com', NULL, '$2y$12$a5i20X1KhqwTPZdDdH7Ct.smY86uZbqYX2IS3urSMo9uKUhRgedUy', NULL, '2025-07-17 04:20:31', '2025-07-17 04:20:31', 'anggota'),
(144, 'Anggota 143', 'anggota143@gmail.com', NULL, '$2y$12$gdUtO4JRZ9WQf8ABfiSz8OfMYhL1CKgw8I3XE21zSQgnO/Ey8xYKy', NULL, '2025-07-17 04:20:32', '2025-07-17 04:20:32', 'anggota'),
(145, 'Anggota 144', 'anggota144@gmail.com', NULL, '$2y$12$7Ql0qsI4t/hGxFbuBfyTTOHsdITSYCuqrRfF2Hwp03ynTvTp4z7Dy', NULL, '2025-07-17 04:20:32', '2025-07-17 04:20:32', 'anggota'),
(146, 'Anggota 145', 'anggota145@gmail.com', NULL, '$2y$12$uLVMW6IUtqna1XJDUSv2KOkiD18ylD/d7h0SC14F8J/hx4edsk90u', NULL, '2025-07-17 04:20:32', '2025-07-17 04:20:32', 'anggota'),
(147, 'Anggota 146', 'anggota146@gmail.com', NULL, '$2y$12$jUMJdHIhGIWQE7I4UQbSbuguOJfQAImVEIx/0W1JPzlXvvQ11qyFe', NULL, '2025-07-17 04:20:33', '2025-07-17 04:20:33', 'anggota'),
(148, 'Anggota 147', 'anggota147@gmail.com', NULL, '$2y$12$sFFgVKGz2wCFNOm..ecCF.RyNpCb3OByELfwIJr74yGSUNaoPl8Au', NULL, '2025-07-17 04:20:33', '2025-07-17 04:20:33', 'anggota'),
(149, 'Anggota 148', 'anggota148@gmail.com', NULL, '$2y$12$TySpmaahy1vgrYfdoxEHa.oQyN4rJg25I92vF56KPRlO.6mZpmAN6', NULL, '2025-07-17 04:20:33', '2025-07-17 04:20:33', 'anggota'),
(150, 'Anggota 149', 'anggota149@gmail.com', NULL, '$2y$12$zXTwqU6if4V0uW7w79dq3uiSQ53tkv.CcpHubHygWex66rpq5DMlS', NULL, '2025-07-17 04:20:34', '2025-07-17 04:20:34', 'anggota'),
(151, 'Anggota 150', 'anggota150@gmail.com', NULL, '$2y$12$TzNiCdcXv33g9kuPBm02uOvWkuIDbsriVFjENylfy2dknN/bWiq4a', NULL, '2025-07-17 04:20:34', '2025-07-17 04:20:34', 'anggota'),
(152, 'Anggota 151', 'anggota151@gmail.com', NULL, '$2y$12$ki5SYTeQR9rG5QSkyvgPq.tV1OEUwwyai2UKVww68AGX86EiYAdd6', NULL, '2025-07-17 04:20:34', '2025-07-17 04:20:34', 'anggota'),
(153, 'Anggota 152', 'anggota152@gmail.com', NULL, '$2y$12$1F8o6l63/Las6NWckkS2buoelYxaTSJcGBslBBDUxM9tZ2JhBhgzS', NULL, '2025-07-17 04:20:34', '2025-07-17 04:20:34', 'anggota'),
(154, 'Anggota 153', 'anggota153@gmail.com', NULL, '$2y$12$/OiEnowFzDBr0qnxjMirKuWnTf8196.ylC6/bcvCJZi3.Z6wRcBgm', NULL, '2025-07-17 04:20:35', '2025-07-17 04:20:35', 'anggota'),
(155, 'Anggota 154', 'anggota154@gmail.com', NULL, '$2y$12$xvMonsQ1xx/FnEsQLdVwyuHocDDlBXqyfVdF4Ss4NRG35D7CUh1ZC', NULL, '2025-07-17 04:20:35', '2025-07-17 04:20:35', 'anggota'),
(156, 'Anggota 155', 'anggota155@gmail.com', NULL, '$2y$12$KOOdvAQ6bPFGul0XbDjVW.kzp5nKD.llqi184ecjZC28Wjh/X/.JK', NULL, '2025-07-17 04:20:35', '2025-07-17 04:20:35', 'anggota'),
(157, 'Anggota 156', 'anggota156@gmail.com', NULL, '$2y$12$PZ7rvtpSUUKuYworZ3El0OySdG6jiRsb5vWprcVPRwn.Y3UtSHomW', NULL, '2025-07-17 04:20:36', '2025-07-17 04:20:36', 'anggota'),
(158, 'Anggota 157', 'anggota157@gmail.com', NULL, '$2y$12$PwD3eTKo4uw2k.p7UfozNur63AuN07lL0kXDX.7U1T.xxcmopHMl6', NULL, '2025-07-17 04:20:36', '2025-07-17 04:20:36', 'anggota'),
(159, 'Anggota 158', 'anggota158@gmail.com', NULL, '$2y$12$2hbYg7t1JxwHIl4/VcYEKe5D/pqoa9yLkuGIhAE9fanoERXIKJBUC', NULL, '2025-07-17 04:20:36', '2025-07-17 04:20:36', 'anggota'),
(160, 'Anggota 159', 'anggota159@gmail.com', NULL, '$2y$12$F6qo5lGS8W57pHaC.FBGw.iiVp.gl/mDnPFM0ZS9ogbz2p3fmXuAC', NULL, '2025-07-17 04:20:37', '2025-07-17 04:20:37', 'anggota'),
(161, 'Anggota 160', 'anggota160@gmail.com', NULL, '$2y$12$yNJZIFXB2II7jCn.rNj6U.EbBzf1HWw0aX2RPo1P38DrO.HBbbCyq', NULL, '2025-07-17 04:20:37', '2025-07-17 04:20:37', 'anggota'),
(162, 'Anggota 161', 'anggota161@gmail.com', NULL, '$2y$12$r9P.gDjtFQgB2DAVk30UK.zE5ZaF8ipf5RMdeiESRASobXaJshveO', NULL, '2025-07-17 04:20:37', '2025-07-17 04:20:37', 'anggota'),
(163, 'Anggota 162', 'anggota162@gmail.com', NULL, '$2y$12$11wqCwgWA/3.fRdHEKggbOFGAVzQ8eNZZrtOwupb7mpMO2p3IDnXO', NULL, '2025-07-17 04:20:37', '2025-07-17 04:20:37', 'anggota'),
(164, 'Anggota 163', 'anggota163@gmail.com', NULL, '$2y$12$8kSpK0ZsCzoPoeunPu9uTOgKyLCVNkLMFMoXhCl7EJ0rGxLaUKxkW', NULL, '2025-07-17 04:20:38', '2025-07-17 04:20:38', 'anggota'),
(165, 'Anggota 164', 'anggota164@gmail.com', NULL, '$2y$12$69qJmmsopwkGN7Z017FtSuBC.ax0wohN2T0VD9y1PRea.jjcwxg36', NULL, '2025-07-17 04:20:38', '2025-07-17 04:20:38', 'anggota'),
(166, 'Anggota 165', 'anggota165@gmail.com', NULL, '$2y$12$czKTGbeBCbodblbC9IynCumfVFIwhZrvqOfr8Mip/dAE.8HEOSgmO', NULL, '2025-07-17 04:20:38', '2025-07-17 04:20:38', 'anggota'),
(167, 'Anggota 166', 'anggota166@gmail.com', NULL, '$2y$12$HVwuyvGFVeWLbALTDFh/2eTF7t.5TYC5ZNxHajxpi.KXOhRFKhnhi', NULL, '2025-07-17 04:20:39', '2025-07-17 04:20:39', 'anggota'),
(168, 'Anggota 167', 'anggota167@gmail.com', NULL, '$2y$12$d61KAzmKCtv8mBjM3zMrFeE93HjvJk63ydFLuODyVoD4yCtzOl5tu', NULL, '2025-07-17 04:20:39', '2025-07-17 04:20:39', 'anggota'),
(169, 'Anggota 168', 'anggota168@gmail.com', NULL, '$2y$12$gTtqXwxnOvy6hC/vPSQq/OI6X7NeL9QUo1722C1ndiHQnIGYDxv.i', NULL, '2025-07-17 04:20:39', '2025-07-17 04:20:39', 'anggota'),
(170, 'Anggota 169', 'anggota169@gmail.com', NULL, '$2y$12$oBbW5beEImq2JAxj1oba9OnXXrh7g9xHDvBABGwX5ecDZsmrxqASa', NULL, '2025-07-17 04:20:40', '2025-07-17 04:20:40', 'anggota'),
(171, 'Anggota 170', 'anggota170@gmail.com', NULL, '$2y$12$LLnnT9.F2iSpHWxZaCq2fus4QQg28wteT5vaPKj8F0yrIPtmnl38S', NULL, '2025-07-17 04:20:40', '2025-07-17 04:20:40', 'anggota'),
(172, 'Anggota 171', 'anggota171@gmail.com', NULL, '$2y$12$oW1c286Ukl2p.SmEFLWvgeqBlDOOU.IwJIphC2sv8sJT7Q/uUxf.a', NULL, '2025-07-17 04:20:40', '2025-07-17 04:20:40', 'anggota'),
(173, 'Anggota 172', 'anggota172@gmail.com', NULL, '$2y$12$hRwCS9VnmiW1UwX16WApdej1lg.nC2xAX.WpcYdcFw.Pqqbd5qo4y', NULL, '2025-07-17 04:20:41', '2025-07-17 04:20:41', 'anggota'),
(174, 'Anggota 173', 'anggota173@gmail.com', NULL, '$2y$12$OMwOz0qgBVkZZqI/CUp48uZ1hKGK.rE/cQlSo6tz4EhNjAvIyDwvG', NULL, '2025-07-17 04:20:41', '2025-07-17 04:20:41', 'anggota'),
(175, 'Anggota 174', 'anggota174@gmail.com', NULL, '$2y$12$GF2mIGdoshtgboKamsZi5eK4oiaROQl8yZ2Ew/78r3UQJef3ramEW', NULL, '2025-07-17 04:20:41', '2025-07-17 04:20:41', 'anggota'),
(176, 'Anggota 175', 'anggota175@gmail.com', NULL, '$2y$12$FGJ760Q1eVFNfcTuRjlm3ur.ew.qGnI6VMguLJmL6ozvlMSENCmga', NULL, '2025-07-17 04:20:41', '2025-07-17 04:20:41', 'anggota'),
(177, 'Anggota 176', 'anggota176@gmail.com', NULL, '$2y$12$BPGaZ.hHpJe/dB5xEr1uluq8DSsI7nnSrPZZVuHNu/qSdorRyXd52', NULL, '2025-07-17 04:20:42', '2025-07-17 04:20:42', 'anggota'),
(178, 'Anggota 177', 'anggota177@gmail.com', NULL, '$2y$12$mm1oTWldI.wxce2i0rHxbO7LPipj7EUiyyl.8nbAmvEC1TfNVduDi', NULL, '2025-07-17 04:20:42', '2025-07-17 04:20:42', 'anggota'),
(179, 'Anggota 178', 'anggota178@gmail.com', NULL, '$2y$12$W7c8.DOo5BI1Nw7diKO.4Opj5UnrHomT1871Zx85fL9b3gsqZLuJC', NULL, '2025-07-17 04:20:42', '2025-07-17 04:20:42', 'anggota'),
(180, 'Anggota 179', 'anggota179@gmail.com', NULL, '$2y$12$DK4Ui/mesz0eObcjVZIxd.R/1ZaGUcCKWG4uE1EBerGiUZJPUx8Ca', NULL, '2025-07-17 04:20:43', '2025-07-17 04:20:43', 'anggota'),
(181, 'Anggota 180', 'anggota180@gmail.com', NULL, '$2y$12$Cn0mrWBduiUlUSaUON.uzed0WP5U3/bOa.LZn.UhDxg/SY.ZOrlJi', NULL, '2025-07-17 04:20:43', '2025-07-17 04:20:43', 'anggota'),
(182, 'Anggota 181', 'anggota181@gmail.com', NULL, '$2y$12$zyVyTYRakf9Mw0WrL18rke2sFJywYU/DE4pCdc03NB7KitO51C8FW', NULL, '2025-07-17 04:20:43', '2025-07-17 04:20:43', 'anggota'),
(183, 'Anggota 182', 'anggota182@gmail.com', NULL, '$2y$12$7.g4se.hqM.QtnajAfGQgOQpnoomZTQNInJa68mck.4uAsrRC3T0e', NULL, '2025-07-17 04:20:44', '2025-07-17 04:20:44', 'anggota'),
(184, 'Anggota 183', 'anggota183@gmail.com', NULL, '$2y$12$uBKd91hDVMdtt//xULoHA.aW/YsCWXaRozMpXvZm4/yb1mB255zpa', NULL, '2025-07-17 04:20:44', '2025-07-17 04:20:44', 'anggota'),
(185, 'Anggota 184', 'anggota184@gmail.com', NULL, '$2y$12$ECVINUt8DSbehDDYdpg30e1Edy0XHBJJCaTU632Q5Go1PLG11n.oG', NULL, '2025-07-17 04:20:44', '2025-07-17 04:20:44', 'anggota'),
(186, 'Anggota 185', 'anggota185@gmail.com', NULL, '$2y$12$FZeLjAZP4mMJengYgsQHIenZ4Qhpa2/2HMtm9qK9W.nqGcb8Tj6SC', NULL, '2025-07-17 04:20:44', '2025-07-17 04:20:44', 'anggota'),
(187, 'Anggota 186', 'anggota186@gmail.com', NULL, '$2y$12$jL/uGpQNxY10.bPokX/4y.EYKHIWWuM.SC5dwBYrJ1MvbzPPNIHzO', NULL, '2025-07-17 04:20:45', '2025-07-17 04:20:45', 'anggota'),
(188, 'Anggota 187', 'anggota187@gmail.com', NULL, '$2y$12$N.5d9YID7BME95hHjsJygO2ILXFWRhHBNWCSEMOnOegHPsgZpt0i6', NULL, '2025-07-17 04:20:45', '2025-07-17 04:20:45', 'anggota'),
(189, 'Anggota 188', 'anggota188@gmail.com', NULL, '$2y$12$MyA2a0mYWKxkfzWApqyEzezINcrKpjeyyse8LKplg2XqIgJDVoupa', NULL, '2025-07-17 04:20:45', '2025-07-17 04:20:45', 'anggota'),
(190, 'Anggota 189', 'anggota189@gmail.com', NULL, '$2y$12$gvpMkjNX14..fv4VVmQFQOCKVUhwGkka3kt9ZKXaVNiEsr.A76SSm', NULL, '2025-07-17 04:20:46', '2025-07-17 04:20:46', 'anggota'),
(191, 'Anggota 190', 'anggota190@gmail.com', NULL, '$2y$12$zLiTuBUfscdHGaMMhUQvZelLEMJZNfCLPAzfoQCJWGHSCj6eDx5jW', NULL, '2025-07-17 04:20:46', '2025-07-17 04:20:46', 'anggota'),
(192, 'Anggota 191', 'anggota191@gmail.com', NULL, '$2y$12$TWlGWklhFBdh./tCuSvHTOHF.QmOpwVjt5wUP1e26C8zRbluAu46G', NULL, '2025-07-17 04:20:46', '2025-07-17 04:20:46', 'anggota'),
(193, 'Anggota 192', 'anggota192@gmail.com', NULL, '$2y$12$5i9kokqdtHHb/RjH9srJCODcEH4Ddmjvyk114c.WeOY/1Z1arkKtG', NULL, '2025-07-17 04:20:47', '2025-07-17 04:20:47', 'anggota'),
(194, 'Anggota 193', 'anggota193@gmail.com', NULL, '$2y$12$4s/1qcllfcsOCDC6/hHPouMFo9qZjP.kqQUrV9u3hBAK41U2vJvYi', NULL, '2025-07-17 04:20:47', '2025-07-17 04:20:47', 'anggota'),
(195, 'Anggota 194', 'anggota194@gmail.com', NULL, '$2y$12$9cUl37NFL0V4cFe.0ULgyOB928juKK6XRJggbdcdDWVTrH8MlUI4O', NULL, '2025-07-17 04:20:47', '2025-07-17 04:20:47', 'anggota'),
(196, 'Anggota 195', 'anggota195@gmail.com', NULL, '$2y$12$tic6vbIxOKie7YvtWHtabu.SO3WmQbIImGO4MNDIstDDO/fKC/lMm', NULL, '2025-07-17 04:20:48', '2025-07-17 04:20:48', 'anggota'),
(197, 'Anggota 196', 'anggota196@gmail.com', NULL, '$2y$12$PalAhNbMy0Ha8fKvn14rU.r6fCNhjHjcdPuOQqPfiJUIOTDbO60yS', NULL, '2025-07-17 04:20:48', '2025-07-17 04:20:48', 'anggota'),
(198, 'Anggota 197', 'anggota197@gmail.com', NULL, '$2y$12$F.KZLl9DS/303/2Z6QLpmO9ivV27zCmJbA.sB5Di7kBmTmACgrDvC', NULL, '2025-07-17 04:20:48', '2025-07-17 04:20:48', 'anggota'),
(199, 'Anggota 198', 'anggota198@gmail.com', NULL, '$2y$12$69MnR6UK3vjriuUjV0g56uv90WnbjqmSmyi7uGQEHJiZJC82ZNVuC', NULL, '2025-07-17 04:20:48', '2025-07-17 04:20:48', 'anggota'),
(200, 'Anggota 199', 'anggota199@gmail.com', NULL, '$2y$12$NiRhjcwuoXskpPwNsvq1muQGZrHpj1Vr.LT4Rh4dAiAGuXzML.XbO', NULL, '2025-07-17 04:20:49', '2025-07-17 04:20:49', 'anggota'),
(201, 'Anggota 200', 'anggota200@gmail.com', NULL, '$2y$12$9WqGjjFjcD/0aXh4QzCSRe1LvTNBkWOBN576UnDbditgTv0wGVDdG', NULL, '2025-07-17 04:20:49', '2025-07-17 04:20:49', 'anggota'),
(202, 'Anggota 201', 'anggota201@gmail.com', NULL, '$2y$12$lYyKFkHLdUEEZTvb7m8kkub/rQUj4CQDgk0laqfXD/uxEESZPsc7y', NULL, '2025-07-17 04:20:49', '2025-07-17 04:20:49', 'anggota'),
(203, 'Anggota 202', 'anggota202@gmail.com', NULL, '$2y$12$h2hoqECyerTEL/uT4Ihcy..3B68OmFeY20QgbshAg5WmVhIFtXT72', NULL, '2025-07-17 04:20:50', '2025-07-17 04:20:50', 'anggota'),
(204, 'Anggota 203', 'anggota203@gmail.com', NULL, '$2y$12$Eul6i2gYAzqyQNRUKueT1OCD40u7nRuZwNuMf.0CWd/3HofdSyUY2', NULL, '2025-07-17 04:20:50', '2025-07-17 04:20:50', 'anggota'),
(205, 'Anggota 204', 'anggota204@gmail.com', NULL, '$2y$12$AH3TMjXWC9eB6sqItrskqOlmzIl5GU6bgayUrw5Q2BFf5n/ujb5mC', NULL, '2025-07-17 04:20:50', '2025-07-17 04:20:50', 'anggota'),
(206, 'Anggota 205', 'anggota205@gmail.com', NULL, '$2y$12$JE4qyI.dDc7KhpwNjn9teeM9P.vF01RaQ5rsjdMu/9nXTyCbcFlAa', NULL, '2025-07-17 04:20:51', '2025-07-17 04:20:51', 'anggota'),
(207, 'Anggota 206', 'anggota206@gmail.com', NULL, '$2y$12$8sO3dxTDpujQTUuujSLKS.m45fVautskw6i6S50Fb9yU87CxeB7cy', NULL, '2025-07-17 04:20:51', '2025-07-17 04:20:51', 'anggota'),
(208, 'Anggota 207', 'anggota207@gmail.com', NULL, '$2y$12$cXKTtNj0kFv4/eZuW9bS4.vvkBKzTehhX1D.AZ7TpWOFu4kKFf4a2', NULL, '2025-07-17 04:20:51', '2025-07-17 04:20:51', 'anggota'),
(209, 'Anggota 208', 'anggota208@gmail.com', NULL, '$2y$12$rkygfaAvq2dYoavyaX0cqO//jsPCZpNMjkKg10e.4Yzlw9MpyGIgu', NULL, '2025-07-17 04:20:51', '2025-07-17 04:20:51', 'anggota'),
(210, 'Anggota 209', 'anggota209@gmail.com', NULL, '$2y$12$OWD8fk3O8LB9LKbmTm6ywubVX2pbWfBUU5Wl7Yu5uYVkyW6G7jqQm', NULL, '2025-07-17 04:20:52', '2025-07-17 04:20:52', 'anggota'),
(211, 'Anggota 210', 'anggota210@gmail.com', NULL, '$2y$12$kkIEPDPnFvgh3ysngTRYPuQ16yYEA2ieU18FeU.oDetujAnp659Qm', NULL, '2025-07-17 04:20:52', '2025-07-17 04:20:52', 'anggota'),
(212, 'Anggota 211', 'anggota211@gmail.com', NULL, '$2y$12$b003/3qrlMZhJHr4iD4FpeIRDlDIPubvMmi1y5Qw2w73aCvBxYk9W', NULL, '2025-07-17 04:20:52', '2025-07-17 04:20:52', 'anggota'),
(213, 'Anggota 212', 'anggota212@gmail.com', NULL, '$2y$12$P7h8PzkzSEz612zKkZXwn.VcxaV0QM9iwSGoou0hENA5pF5PevoG2', NULL, '2025-07-17 04:20:53', '2025-07-17 04:20:53', 'anggota'),
(214, 'Anggota 213', 'anggota213@gmail.com', NULL, '$2y$12$sbHZ5MbvV/wS8MmO8ndgL.wz4Wx4jRRALrzOXliIjUPkpAVJpwhg6', NULL, '2025-07-17 04:20:53', '2025-07-17 04:20:53', 'anggota'),
(215, 'Anggota 214', 'anggota214@gmail.com', NULL, '$2y$12$IzX5DqR45jrL/bv0E5FDgupfqE6Tara22j56O3u8LdiMAYTjkEsyi', NULL, '2025-07-17 04:20:53', '2025-07-17 04:20:53', 'anggota'),
(216, 'Anggota 215', 'anggota215@gmail.com', NULL, '$2y$12$rBOmRA0dgC0/O3UI8EMIHeemWCOFocH58k0O0gPQhMOhBxAt0lup2', NULL, '2025-07-17 04:20:54', '2025-07-17 04:20:54', 'anggota'),
(217, 'Anggota 216', 'anggota216@gmail.com', NULL, '$2y$12$wyCHYr45KZkSNbJZMkpDhOMC9N1KF/CII3bfQBHvLo3/u1OOU1JGi', NULL, '2025-07-17 04:20:54', '2025-07-17 04:20:54', 'anggota'),
(218, 'Anggota 217', 'anggota217@gmail.com', NULL, '$2y$12$OiPfFqpI2EP2wYqN3aUIVuTSlKnL63SM41gs0iLodWRlvnHTgcVB.', NULL, '2025-07-17 04:20:54', '2025-07-17 04:20:54', 'anggota'),
(219, 'Anggota 218', 'anggota218@gmail.com', NULL, '$2y$12$nuFWaWm/hTrM9geQ.yHQPe6wWmJ5FTmzeO3rjnNTG3bPqQXYb7Mz2', NULL, '2025-07-17 04:20:54', '2025-07-17 04:20:54', 'anggota'),
(220, 'Anggota 219', 'anggota219@gmail.com', NULL, '$2y$12$R4I/2wfGNJkeUIF2VRWNV.3woeEE4hVpkYdqwa0v6LRZPM2B8ovwO', NULL, '2025-07-17 04:20:55', '2025-07-17 04:20:55', 'anggota'),
(221, 'Anggota 220', 'anggota220@gmail.com', NULL, '$2y$12$m/kT.riu6MDc4vhArDit5OdzAZNFbFyasHZrO8vHe1YZwrcYeHOJC', NULL, '2025-07-17 04:20:55', '2025-07-17 04:20:55', 'anggota'),
(222, 'Anggota 221', 'anggota221@gmail.com', NULL, '$2y$12$YWX4gJ2SAlBn1CXDAVGt2.kOoPC3A/R4BbCGZsTr4fYS5tk/DhjLS', NULL, '2025-07-17 04:20:55', '2025-07-17 04:20:55', 'anggota'),
(223, 'Anggota 222', 'anggota222@gmail.com', NULL, '$2y$12$vw7Ov9P5bz8gqD1QjQlooeqDnwlKlcSWcZ1PCYK7ntsUH4xBZRcTm', NULL, '2025-07-17 04:20:56', '2025-07-17 04:20:56', 'anggota'),
(224, 'Anggota 223', 'anggota223@gmail.com', NULL, '$2y$12$uQQL.Phoumm7uK9ptEDhdeTQpriuWmnX6crU1uqw75rLw/AWbT79u', NULL, '2025-07-17 04:20:56', '2025-07-17 04:20:56', 'anggota'),
(225, 'Anggota 224', 'anggota224@gmail.com', NULL, '$2y$12$9Cv/l/0Q1XPFYHYMEKORAeYkioesYcQUCwgLq/WUD1d1H0i8.xHfG', NULL, '2025-07-17 04:20:56', '2025-07-17 04:20:56', 'anggota'),
(226, 'Anggota 225', 'anggota225@gmail.com', NULL, '$2y$12$Byl6kEVtgn1L34fnAxxKpecRTunW2brJeMvUVBNSPjbWWcxnRgjnG', NULL, '2025-07-17 04:20:57', '2025-07-17 04:20:57', 'anggota'),
(227, 'Anggota 226', 'anggota226@gmail.com', NULL, '$2y$12$JcfJl3QHpmb0ZRfQQSk7AOZaNq/o46d.5b7cAchsriSM.SZqcnmB2', NULL, '2025-07-17 04:20:57', '2025-07-17 04:20:57', 'anggota'),
(228, 'Anggota 227', 'anggota227@gmail.com', NULL, '$2y$12$GaJ6vd4L9e1a0ATeX9BDs.JSPASCtbetuEJhMuc20d9HZ2BY5gm1q', NULL, '2025-07-17 04:20:57', '2025-07-17 04:20:57', 'anggota'),
(229, 'Anggota 228', 'anggota228@gmail.com', NULL, '$2y$12$8kJ.TkUnh/CXmyBO4dEBxOcko.lHaAekkqFkhXvKS0KsU2OAMI/gG', NULL, '2025-07-17 04:20:58', '2025-07-17 04:20:58', 'anggota'),
(230, 'Anggota 229', 'anggota229@gmail.com', NULL, '$2y$12$ZaESytsiqo6SI.KhVv9v9OjyhYXowyQszfB3pnDjvK6Yq3T3wjUYG', NULL, '2025-07-17 04:20:58', '2025-07-17 04:20:58', 'anggota'),
(231, 'Anggota 230', 'anggota230@gmail.com', NULL, '$2y$12$UY6Ep2.lmIMHPjCbPvKGz.AFtN/T0TtI3gpqvhSusMkA9jQvdVgD2', NULL, '2025-07-17 04:20:58', '2025-07-17 04:20:58', 'anggota'),
(232, 'Anggota 231', 'anggota231@gmail.com', NULL, '$2y$12$SDiemPYAS7nDQn7QcNFRBOOsaI3npP9xIEvApR31C/s8Py4OrDF5q', NULL, '2025-07-17 04:20:59', '2025-07-17 04:20:59', 'anggota'),
(233, 'Anggota 232', 'anggota232@gmail.com', NULL, '$2y$12$yqcE4EvDu6qeFb4b1c1HKeZ6cu90KivOqQ8NcivSX7WfxpB9G2O8K', NULL, '2025-07-17 04:20:59', '2025-07-17 04:20:59', 'anggota'),
(234, 'Anggota 233', 'anggota233@gmail.com', NULL, '$2y$12$ytQmUF1wN6dvqSlCix0pQOwRRS2TotZP3/AxECi/QH3j7x2.y1j0C', NULL, '2025-07-17 04:20:59', '2025-07-17 04:20:59', 'anggota'),
(235, 'Anggota 234', 'anggota234@gmail.com', NULL, '$2y$12$H8qmmzWqLGkMvNGkfVxqm.PIdhEwBCqQR0LJHdkZrP/4mCGoww.t.', NULL, '2025-07-17 04:21:00', '2025-07-17 04:21:00', 'anggota'),
(236, 'Anggota 235', 'anggota235@gmail.com', NULL, '$2y$12$xSVlOdxpCVkKzB.u/TZ3p.X1cTdZZcXbVj9HOmU/a9MoOD1qHJ9cq', NULL, '2025-07-17 04:21:00', '2025-07-17 04:21:00', 'anggota'),
(237, 'Anggota 236', 'anggota236@gmail.com', NULL, '$2y$12$38mJrxZEfUVc0XGZRE4RVe.LEfdKUws.hRXFCyJThLSFyud4RCEf.', NULL, '2025-07-17 04:21:00', '2025-07-17 04:21:00', 'anggota'),
(238, 'Anggota 237', 'anggota237@gmail.com', NULL, '$2y$12$jbOwSr6b4MTBe4k6ai.PBuchVTcTOKtDovZ0g1BXh7eOoyau.V7Nq', NULL, '2025-07-17 04:21:00', '2025-07-17 04:21:00', 'anggota'),
(239, 'Anggota 238', 'anggota238@gmail.com', NULL, '$2y$12$PLfU5M0ZwnM5gKbECs6g.ODo5zouYE7SQJ4dctxVtaedmOEPSKooq', NULL, '2025-07-17 04:21:01', '2025-07-17 04:21:01', 'anggota'),
(240, 'Anggota 239', 'anggota239@gmail.com', NULL, '$2y$12$dM7b/kcfKuXOhzbG4bx4ruiBoqWaEmF.W6dB63NqV9ZpTowjTbNaK', NULL, '2025-07-17 04:21:01', '2025-07-17 04:21:01', 'anggota'),
(241, 'Anggota 240', 'anggota240@gmail.com', NULL, '$2y$12$1GNAv/IqPdf35QRoWUBdRuLtSicTkqHm/BVc5OiwVQ0isqUElpoju', NULL, '2025-07-17 04:21:01', '2025-07-17 04:21:01', 'anggota'),
(242, 'Anggota 241', 'anggota241@gmail.com', NULL, '$2y$12$hKKVRUzvrQetYhLFYci1heRO/jDyqLJv0MebZNIYY.qX064jOaLNW', NULL, '2025-07-17 04:21:02', '2025-07-17 04:21:02', 'anggota'),
(243, 'Anggota 242', 'anggota242@gmail.com', NULL, '$2y$12$JZnM69ycNya1BgkKS9EVwO3XpHA6tVi2wx4Aat7l9xeZXqhYQPUUS', NULL, '2025-07-17 04:21:02', '2025-07-17 04:21:02', 'anggota'),
(244, 'Anggota 243', 'anggota243@gmail.com', NULL, '$2y$12$6WetuuXs1a0WXXn5wExVT.y5VR9tBpn2Uwygtp8Zl2o706r.WQqC.', NULL, '2025-07-17 04:21:02', '2025-07-17 04:21:02', 'anggota'),
(245, 'Anggota 244', 'anggota244@gmail.com', NULL, '$2y$12$5HmgQMfF1QNRwba6GXPaZeWtHIEpTLtpMfwbghOH/3YXU2gl6Y3Gm', NULL, '2025-07-17 04:21:03', '2025-07-17 04:21:03', 'anggota'),
(246, 'Anggota 245', 'anggota245@gmail.com', NULL, '$2y$12$vZ5OBS.0VOwO6w/iXjDX6uebQjApacNNgm2z2nA/GYScL8ckgB5H2', NULL, '2025-07-17 04:21:03', '2025-07-17 04:21:03', 'anggota'),
(247, 'Anggota 246', 'anggota246@gmail.com', NULL, '$2y$12$8lI3/FdWVVw8xZfbnsgfJuAbph86NG15VYqTXJm9WWpruGUAWELcm', NULL, '2025-07-17 04:21:03', '2025-07-17 04:21:03', 'anggota'),
(248, 'Anggota 247', 'anggota247@gmail.com', NULL, '$2y$12$TjRYZV8NqP7o.dX.zqK4qePgn.UJu8LSKnY0upPgoPuIDGkulz9sa', NULL, '2025-07-17 04:21:03', '2025-07-17 04:21:03', 'anggota'),
(249, 'Anggota 248', 'anggota248@gmail.com', NULL, '$2y$12$PiRS0P0bdT/mPSeUci9/M.qfxDLuzC.lx55XdQ8l.Se5JlEqe5FRy', NULL, '2025-07-17 04:21:04', '2025-07-17 04:21:04', 'anggota'),
(250, 'Anggota 249', 'anggota249@gmail.com', NULL, '$2y$12$KQEJiZ0hYdnaX/hLYQapN.Bhs2F7.OSEBr5m8qdYzJOrowxs0.cT6', NULL, '2025-07-17 04:21:04', '2025-07-17 04:21:04', 'anggota'),
(251, 'Anggota 250', 'anggota250@gmail.com', NULL, '$2y$12$ThJfP8OZRWT4sN7UQxbQHu8.3JGHdsTVvO.q/Sj1CtXzf.T7m8CMC', NULL, '2025-07-17 04:21:04', '2025-07-17 04:21:04', 'anggota'),
(252, 'Anggota 251', 'anggota251@gmail.com', NULL, '$2y$12$BMYBo2NLJh6SjwpADN2ZUe0ySHhHF4TnirkewNPaE19R/4MxWcWt6', NULL, '2025-07-17 04:21:05', '2025-07-17 04:21:05', 'anggota'),
(253, 'Anggota 252', 'anggota252@gmail.com', NULL, '$2y$12$9AuZVNDYO6q19RiooFCnletNxeh73k1PfdA.zREVqONPmZNvUKiqW', NULL, '2025-07-17 04:21:05', '2025-07-17 04:21:05', 'anggota'),
(254, 'Anggota 253', 'anggota253@gmail.com', NULL, '$2y$12$oyN884MlM3c/2Tk1QKjn1O8B2F6o5wsppjMjQRvESPTVGiiFH0xR6', NULL, '2025-07-17 04:21:05', '2025-07-17 04:21:05', 'anggota'),
(255, 'Anggota 254', 'anggota254@gmail.com', NULL, '$2y$12$lBCn.Nu7p9k4KlQk6NKog.vAK8oIdQvpxcbU9IOtLgR/iAmShsBlm', NULL, '2025-07-17 04:21:06', '2025-07-17 04:21:06', 'anggota'),
(256, 'Anggota 255', 'anggota255@gmail.com', NULL, '$2y$12$2XaBTLZvK3IBJ1L7oGSbr.NwE0JZNtqbkZQ5OLeXbMVxuIfDQv8zG', NULL, '2025-07-17 04:21:06', '2025-07-17 04:21:06', 'anggota'),
(257, 'Anggota 256', 'anggota256@gmail.com', NULL, '$2y$12$cM.tzSCTkugd9mPDA.Dytu4ucncbJNTPuHd7uYbmD3nGaxloIFOCq', NULL, '2025-07-17 04:21:06', '2025-07-17 04:21:06', 'anggota'),
(258, 'Anggota 257', 'anggota257@gmail.com', NULL, '$2y$12$es0xOjIPCRib34kcyLZQjOudbz5KK3vp0g/ghWuzBjo4vHxr..imS', NULL, '2025-07-17 04:21:07', '2025-07-17 04:21:07', 'anggota'),
(259, 'Anggota 258', 'anggota258@gmail.com', NULL, '$2y$12$HxVsv5xxz.fQy/ijTWDr9u5vki9qmMV8OITJbEO2ZtksGVDpkM/Z2', NULL, '2025-07-17 04:21:07', '2025-07-17 04:21:07', 'anggota'),
(260, 'Anggota 259', 'anggota259@gmail.com', NULL, '$2y$12$V2nzJsp79OK58lySg9FtwuDHf2GN6hi.IyUb8b0D0dpEuxEiHVgcG', NULL, '2025-07-17 04:21:07', '2025-07-17 04:21:07', 'anggota'),
(261, 'Anggota 260', 'anggota260@gmail.com', NULL, '$2y$12$NYmSL4NLxG.09K9BqV.ijeQKJXvvD/Vm9QY9QwKX8hiPyDtFzSNie', NULL, '2025-07-17 04:21:07', '2025-07-17 04:21:07', 'anggota'),
(262, 'Anggota 261', 'anggota261@gmail.com', NULL, '$2y$12$1u9uAC3NRds44HSYaIEOXOuYTSpc6LAc6f0TJIDCzO8bs7Mo3SVDq', NULL, '2025-07-17 04:21:08', '2025-07-17 04:21:08', 'anggota'),
(263, 'Anggota 262', 'anggota262@gmail.com', NULL, '$2y$12$ftIGLVAaPiDN9BJOTf5P.eGIciZrvVMrN8MKf82QsAibZvkLepjha', NULL, '2025-07-17 04:21:08', '2025-07-17 04:21:08', 'anggota'),
(264, 'Anggota 263', 'anggota263@gmail.com', NULL, '$2y$12$kG5baSf62ls/kre8Wbhm1OEFunZdCA4x8r.Sdpv8Vj12yrFpEleJi', NULL, '2025-07-17 04:21:08', '2025-07-17 04:21:08', 'anggota'),
(265, 'Anggota 264', 'anggota264@gmail.com', NULL, '$2y$12$fGQhagVhC2UM1P8LRHrfbOwq9hKZd5Ya9gO0HzjL.3PV7p.zSwFmW', NULL, '2025-07-17 04:21:09', '2025-07-17 04:21:09', 'anggota'),
(266, 'Anggota 265', 'anggota265@gmail.com', NULL, '$2y$12$0HzbMmyJeCadQBxOrPiyA..ztW7ENX25TV8ZcqaQvjX5ezABsrFue', NULL, '2025-07-17 04:21:09', '2025-07-17 04:21:09', 'anggota'),
(267, 'Anggota 266', 'anggota266@gmail.com', NULL, '$2y$12$j9ISasopkDddXGuwJpNoy.6iCgNT5ibH20gNh.yrV2wgfyhyOx6fK', NULL, '2025-07-17 04:21:09', '2025-07-17 04:21:09', 'anggota'),
(268, 'Anggota 267', 'anggota267@gmail.com', NULL, '$2y$12$QujBonryDicjV6XBdQa2YO6axO6kqnI5/ATrma7mP6zBcjcKN8tiu', NULL, '2025-07-17 04:21:10', '2025-07-17 04:21:10', 'anggota'),
(269, 'Anggota 268', 'anggota268@gmail.com', NULL, '$2y$12$ivkeJheNASqLvl1AO0u7UuuxFjKUhVP2YDA3aRdawp856cDTQQ3rK', NULL, '2025-07-17 04:21:10', '2025-07-17 04:21:10', 'anggota'),
(270, 'Anggota 269', 'anggota269@gmail.com', NULL, '$2y$12$FyCXbHuNZvpwkw/MH8qLlOeSU6G.6ad5D43WiiwRQpLmkaechefK2', NULL, '2025-07-17 04:21:10', '2025-07-17 04:21:10', 'anggota'),
(271, 'Anggota 270', 'anggota270@gmail.com', NULL, '$2y$12$ThtQIq6mkE6sSu0CVJgUjegMnmLOaXxzm0GbuzJlLuGH7r2W240T6', NULL, '2025-07-17 04:21:11', '2025-07-17 04:21:11', 'anggota'),
(272, 'Anggota 271', 'anggota271@gmail.com', NULL, '$2y$12$RbobgKjb9/NXfB3ksdDkIOxIh6AYLpUU3Eg3whOyJUyW.6mPI.OEy', NULL, '2025-07-17 04:21:11', '2025-07-17 04:21:11', 'anggota'),
(273, 'Anggota 272', 'anggota272@gmail.com', NULL, '$2y$12$dfuW5atSZ2PLvVrauTqvgOauibHeZWsPhk0RfvIGNR0LhasVs7hO2', NULL, '2025-07-17 04:21:11', '2025-07-17 04:21:11', 'anggota'),
(274, 'Anggota 273', 'anggota273@gmail.com', NULL, '$2y$12$ei5EP/aySX74qkFchZxnkOUj8sRHPhWudeiZGG1LQ8ZvA.m/fx8AK', NULL, '2025-07-17 04:21:11', '2025-07-17 04:21:11', 'anggota'),
(275, 'Anggota 274', 'anggota274@gmail.com', NULL, '$2y$12$rwwHGKSEWCOT9LZEmveA6u0mYFvyv3hSihb6sxcnzOoW6Mylsyr.W', NULL, '2025-07-17 04:21:12', '2025-07-17 04:21:12', 'anggota'),
(276, 'Anggota 275', 'anggota275@gmail.com', NULL, '$2y$12$MhBrq.DnmkQmIiCPvVSdeOZx13W5MbT07NuhHlSa4EXPMv0z2R2s2', NULL, '2025-07-17 04:21:12', '2025-07-17 04:21:12', 'anggota'),
(277, 'Anggota 276', 'anggota276@gmail.com', NULL, '$2y$12$kT2pTrx1yvJRxSxZ2P3geuk6Zg.rWgFWuBFT2iTsUfuxLQalZ3J9a', NULL, '2025-07-17 04:21:12', '2025-07-17 04:21:12', 'anggota'),
(278, 'Anggota 277', 'anggota277@gmail.com', NULL, '$2y$12$yHI2/XHZDErSmILYzX8ePuScUlDq15NlkMtRXY42JGqcQsp5xa8Fu', NULL, '2025-07-17 04:21:13', '2025-07-17 04:21:13', 'anggota'),
(279, 'Anggota 278', 'anggota278@gmail.com', NULL, '$2y$12$Dv0nZj.Vwr4xtyB6/GXCYuIYF/plXIXua3C73ChOts90Xy0LIiLLC', NULL, '2025-07-17 04:21:13', '2025-07-17 04:21:13', 'anggota'),
(280, 'Anggota 279', 'anggota279@gmail.com', NULL, '$2y$12$oDkDW4DaWhik2E1cFGstV.PCiETWmjU5Zk4KwZjGgqxsJxAhHx6pm', NULL, '2025-07-17 04:21:13', '2025-07-17 04:21:13', 'anggota'),
(281, 'Anggota 280', 'anggota280@gmail.com', NULL, '$2y$12$10Opwe5ihE7NCEajOhmz6.hsrOccVrUGwtm/LVKdd.662cXsOhr.i', NULL, '2025-07-17 04:21:14', '2025-07-17 04:21:14', 'anggota'),
(282, 'Anggota 281', 'anggota281@gmail.com', NULL, '$2y$12$iw8mpBhnxNFjTF/KAyZk8eKJ4CLZFYqgNANjdUaMkd2HMGtGxt7se', NULL, '2025-07-17 04:21:14', '2025-07-17 04:21:14', 'anggota'),
(283, 'Anggota 282', 'anggota282@gmail.com', NULL, '$2y$12$637zXZBzv/1XB5Gs/kXXd.CZpelfipE7PQ6IeAg5fEpoWHfzbWTmy', NULL, '2025-07-17 04:21:14', '2025-07-17 04:21:14', 'anggota');
INSERT INTO `users` (`id`, `name`, `email`, `email_verified_at`, `password`, `remember_token`, `created_at`, `updated_at`, `role`) VALUES
(284, 'Anggota 283', 'anggota283@gmail.com', NULL, '$2y$12$a7kqRhj8BhlIT79NfM4/FOT4gprI2L58H7pMHZ2s/4uDFgsjGNfz6', NULL, '2025-07-17 04:21:14', '2025-07-17 04:21:14', 'anggota'),
(285, 'Anggota 284', 'anggota284@gmail.com', NULL, '$2y$12$X1uuCNtskY26XHsqUilBlOqm0vfZ2gY3d/7iwz3FfrIc3bape2VYK', NULL, '2025-07-17 04:21:15', '2025-07-17 04:21:15', 'anggota'),
(286, 'Anggota 285', 'anggota285@gmail.com', NULL, '$2y$12$CidgZuqAkptC6UNcIIAiC.0rRH0Gi9IoWysDMqhBIam/Fl/htI45e', NULL, '2025-07-17 04:21:15', '2025-07-17 04:21:15', 'anggota'),
(287, 'Anggota 286', 'anggota286@gmail.com', NULL, '$2y$12$PMSXQHdBCoGNvMMxHSbAguPefj6FTKLxw9OoU.qylfh7MAqIQ5Nu.', NULL, '2025-07-17 04:21:15', '2025-07-17 04:21:15', 'anggota'),
(288, 'Anggota 287', 'anggota287@gmail.com', NULL, '$2y$12$0fX0JDx0n7oscZXY0Ifz/eaEdOXDvcIh.fJtyLnKQtz35UGIufZoC', NULL, '2025-07-17 04:21:16', '2025-07-17 04:21:16', 'anggota'),
(289, 'Anggota 288', 'anggota288@gmail.com', NULL, '$2y$12$RoVjNeCfViJTTGyzGuTmEeam7YbLcJvdceeD0KhCRwpoRJ.B.z/xK', NULL, '2025-07-17 04:21:16', '2025-07-17 04:21:16', 'anggota'),
(290, 'Anggota 289', 'anggota289@gmail.com', NULL, '$2y$12$aHWkRBkrBvoBKGKt48Hru.A3xw4nPL5I9.kXz7IspFpuUPpsBo0uO', NULL, '2025-07-17 04:21:16', '2025-07-17 04:21:16', 'anggota'),
(291, 'Anggota 290', 'anggota290@gmail.com', NULL, '$2y$12$lHThrg2ocSIF3k95DrgQvOZz05A2nrFAgdnNPyiEgu9YXNp7eCLRK', NULL, '2025-07-17 04:21:17', '2025-07-17 04:21:17', 'anggota'),
(292, 'Anggota 291', 'anggota291@gmail.com', NULL, '$2y$12$fCO9hUfmdttCSaR0kOr9L.jkayIl787lCKoqWt1PG0RfIju/wR/TS', NULL, '2025-07-17 04:21:17', '2025-07-17 04:21:17', 'anggota'),
(293, 'Anggota 292', 'anggota292@gmail.com', NULL, '$2y$12$8n4C4dj/8nbAjOd7roJNKe7CQMkmWJcK6uVqAItpCSIJ.iecF6Vl2', NULL, '2025-07-17 04:21:17', '2025-07-17 04:21:17', 'anggota'),
(294, 'Anggota 293', 'anggota293@gmail.com', NULL, '$2y$12$Yit22NFX.sqR8jnE4wfNkejCWEW0Zwwpi1MNpCYXD0S2y2LLBElGS', NULL, '2025-07-17 04:21:17', '2025-07-17 04:21:17', 'anggota'),
(295, 'Anggota 294', 'anggota294@gmail.com', NULL, '$2y$12$v19n78lcZDe345WW9piWeOusQxBrK/MUWjdYavkQ.aqZYJ0O/NH/2', NULL, '2025-07-17 04:21:18', '2025-07-17 04:21:18', 'anggota'),
(296, 'Anggota 295', 'anggota295@gmail.com', NULL, '$2y$12$mBNDe.KSmfC4W5dLy8NSauQBmfoFVYgW1Afg5oPxmW8y6fUI23Mku', NULL, '2025-07-17 04:21:18', '2025-07-17 04:21:18', 'anggota'),
(297, 'Anggota 296', 'anggota296@gmail.com', NULL, '$2y$12$0iQF.8U2y7myBdH1uOlgd.pNaMqR50a6ZqArk.MbseriOs6rleLgK', NULL, '2025-07-17 04:21:18', '2025-07-17 04:21:18', 'anggota'),
(298, 'Anggota 297', 'anggota297@gmail.com', NULL, '$2y$12$bd61/p6buT9M7/YLQvd7IOb4OiwhH.xYX/Z38Rp.dm0I7KtZHlFuS', NULL, '2025-07-17 04:21:19', '2025-07-17 04:21:19', 'anggota'),
(299, 'Anggota 298', 'anggota298@gmail.com', NULL, '$2y$12$ChFKzc6Cmeaah.sy6UA6rO33nX/juA7o.Q0kHny4A.46arAnJaF2a', NULL, '2025-07-17 04:21:19', '2025-07-17 04:21:19', 'anggota'),
(300, 'Anggota 299', 'anggota299@gmail.com', NULL, '$2y$12$C8DOC9a3RBQg0POMkFFtvOoLeG6K8AXplj8ugy971WsbwnEznGlLy', NULL, '2025-07-17 04:21:19', '2025-07-17 04:21:19', 'anggota'),
(301, 'Anggota 300', 'anggota300@gmail.com', NULL, '$2y$12$zXvHeIfzN2dmWZGZ1hb9qeS4E/MW0KyOXWWbiveUrRevSOyXmQfwe', NULL, '2025-07-17 04:21:20', '2025-07-17 04:21:20', 'anggota'),
(302, 'Anggota 301', 'anggota301@gmail.com', NULL, '$2y$12$D6IfF8FdfD02.zLwd5gfLeQon1mmMdp94QIqRQrfloYUR38SAtUfa', NULL, '2025-07-17 04:21:20', '2025-07-17 04:21:20', 'anggota'),
(303, 'Anggota 302', 'anggota302@gmail.com', NULL, '$2y$12$AJPoOBmfSZWyZt9iZtArqOqfRn4Sf2fAneySDdU2WjY3KHwz0JsMC', NULL, '2025-07-17 04:21:20', '2025-07-17 04:21:20', 'anggota'),
(304, 'Anggota 303', 'anggota303@gmail.com', NULL, '$2y$12$KOvh9JjWyOZNuQFo/sx4DeVRKixfuxSFkP9ry.JcoMeOoAlBhD.Y6', NULL, '2025-07-17 04:21:21', '2025-07-17 04:21:21', 'anggota'),
(305, 'Anggota 304', 'anggota304@gmail.com', NULL, '$2y$12$qKyeNqlE06nWiNqhMHrzHODkliRJ0okC36h/cFjyijeAQi2/50mA2', NULL, '2025-07-17 04:21:21', '2025-07-17 04:21:21', 'anggota'),
(306, 'Anggota 305', 'anggota305@gmail.com', NULL, '$2y$12$mla9ZJFMQjAsOXnyjRFW4egUYt19hafnysqDbLvxFBnwBH0LM4P1y', NULL, '2025-07-17 04:21:21', '2025-07-17 04:21:21', 'anggota'),
(307, 'Anggota 306', 'anggota306@gmail.com', NULL, '$2y$12$HrhiHcfGRn66UlSHjFwTLuCiUT2N123KcypZ/kHZ/mOGJ7r0goVKu', NULL, '2025-07-17 04:21:22', '2025-07-17 04:21:22', 'anggota'),
(308, 'Anggota 307', 'anggota307@gmail.com', NULL, '$2y$12$hvsUkagfR0xkQwtwEXLqv.SXioQVTMgNUhYuZehSlzq.6bZOyxy32', NULL, '2025-07-17 04:21:22', '2025-07-17 04:21:22', 'anggota'),
(309, 'Anggota 308', 'anggota308@gmail.com', NULL, '$2y$12$SW2.NvkXWXAJuFwKJQXQ9uVpIKiMQ56sYSeynwZClNrUgGXYN6bCq', NULL, '2025-07-17 04:21:22', '2025-07-17 04:21:22', 'anggota'),
(310, 'Anggota 309', 'anggota309@gmail.com', NULL, '$2y$12$Jlt28eXQz5luCbi8g/nV4e6Im.7aaha8n4LojMbwoBCOmxDKpo4.q', NULL, '2025-07-17 04:21:22', '2025-07-17 04:21:22', 'anggota'),
(311, 'Anggota 310', 'anggota310@gmail.com', NULL, '$2y$12$8aO.mRSzWbWtYDzVwBt07u9r7fnUbfSD9EZkQHaliaSn3By7Fcl92', NULL, '2025-07-17 04:21:23', '2025-07-17 04:21:23', 'anggota'),
(312, 'Anggota 311', 'anggota311@gmail.com', NULL, '$2y$12$cblVEa/fjBjZEHYay9yiLuyJCXHw/wodL2T.gP5hFMOH7hPG.WRwi', NULL, '2025-07-17 04:21:23', '2025-07-17 04:21:23', 'anggota'),
(313, 'Anggota 312', 'anggota312@gmail.com', NULL, '$2y$12$LK7SKxiyBqQn0OUTm.U9JO1Da50mn0vRaqqUqgZubsE7KFkkHeAn.', NULL, '2025-07-17 04:21:23', '2025-07-17 04:21:23', 'anggota'),
(314, 'Anggota 313', 'anggota313@gmail.com', NULL, '$2y$12$k1j9d.Tsnux1lwxcyYf1GOmpZHuIKUQNGU4/Kyai5TJG9XDzpYiO6', NULL, '2025-07-17 04:21:24', '2025-07-17 04:21:24', 'anggota'),
(315, 'Anggota 314', 'anggota314@gmail.com', NULL, '$2y$12$6q3fjWj3zirVUbSi9OBCnubvWr6RufK0Mm4sP0nFwklqlyfAjRduy', NULL, '2025-07-17 04:21:24', '2025-07-17 04:21:24', 'anggota'),
(316, 'Anggota 315', 'anggota315@gmail.com', NULL, '$2y$12$K3aJQowGkcSoO3RS/0ZhU.rEfOuwwAftWTJfaxpGNpjyrUfL11H42', NULL, '2025-07-17 04:21:24', '2025-07-17 04:21:24', 'anggota'),
(317, 'Anggota 316', 'anggota316@gmail.com', NULL, '$2y$12$qFxgvPGBaNZPMH4xJTv7auQSQzomkkTzva2JeKoVv6yRgjyAsXTjq', NULL, '2025-07-17 04:21:25', '2025-07-17 04:21:25', 'anggota'),
(318, 'Anggota 317', 'anggota317@gmail.com', NULL, '$2y$12$Hy1pb8KRYkuaZH0YD5Yfq.tVf4/38yMEFm3VZJo9dmRD8WnuZ46oq', NULL, '2025-07-17 04:21:25', '2025-07-17 04:21:25', 'anggota'),
(319, 'Anggota 318', 'anggota318@gmail.com', NULL, '$2y$12$IkzywIaapDZEcaE6FJSe4uxLB6LnAug4X9Z24JOF2rXqfPmu2x6s6', NULL, '2025-07-17 04:21:25', '2025-07-17 04:21:25', 'anggota'),
(320, 'Anggota 319', 'anggota319@gmail.com', NULL, '$2y$12$cXfP9a0X31nu7iQ14P2b3eJ1RVNqv/lWAJPordqV6hqZ4TJ1tyG2W', NULL, '2025-07-17 04:21:26', '2025-07-17 04:21:26', 'anggota'),
(321, 'Anggota 320', 'anggota320@gmail.com', NULL, '$2y$12$INFY1N0vj6DdDHbgHFNW.ekBl9wH/zPDaJY6bQn47pVFmnbJK4y6a', NULL, '2025-07-17 04:21:26', '2025-07-17 04:21:26', 'anggota'),
(322, 'Anggota 321', 'anggota321@gmail.com', NULL, '$2y$12$rUKyyMJ4NeipMIhp326IL.hBrVhgTnqtXWwqyN0CTW7FbQdIzHq12', NULL, '2025-07-17 04:21:26', '2025-07-17 04:21:26', 'anggota'),
(323, 'Anggota 322', 'anggota322@gmail.com', NULL, '$2y$12$nuE9F2A3t3c2NALyFVI/P.Pr167k0qQI8MHorqskJ9y6FM9A4wkgG', NULL, '2025-07-17 04:21:27', '2025-07-17 04:21:27', 'anggota'),
(324, 'Anggota 323', 'anggota323@gmail.com', NULL, '$2y$12$rV5erIZ0oUngN/NIq9I3q..lwQ7f/9MGAtsoKEUPpBDahfvv4L.e2', NULL, '2025-07-17 04:21:27', '2025-07-17 04:21:27', 'anggota'),
(325, 'Anggota 324', 'anggota324@gmail.com', NULL, '$2y$12$epwBoeH3LFMuq78NygykJOjeCO3Pq/d4bPW5Kr3KY96vP1RZubXym', NULL, '2025-07-17 04:21:27', '2025-07-17 04:21:27', 'anggota'),
(326, 'Anggota 325', 'anggota325@gmail.com', NULL, '$2y$12$w80wpnD2BMBbGm.tVhp13OUidnzCsGlHEhBf69Sj56ycsPrHsQl2u', NULL, '2025-07-17 04:21:28', '2025-07-17 04:21:28', 'anggota'),
(327, 'Anggota 326', 'anggota326@gmail.com', NULL, '$2y$12$ZwRBrLYz9wgCsJ9MLaQ1w.y9vOtkpOdh/W3.evjFUeKnDWpg35ygK', NULL, '2025-07-17 04:21:28', '2025-07-17 04:21:28', 'anggota'),
(328, 'Anggota 327', 'anggota327@gmail.com', NULL, '$2y$12$At3XfFnby3o6/rmAI2s8be7/MnxLkidIrbNM6M3eFIL/WcwgDZNwe', NULL, '2025-07-17 04:21:28', '2025-07-17 04:21:28', 'anggota'),
(329, 'Anggota 328', 'anggota328@gmail.com', NULL, '$2y$12$SmUOwEEwy62x85r356eII.Vb1NEc5fhyzZTKhML4FsBbn23nMqaLe', NULL, '2025-07-17 04:21:29', '2025-07-17 04:21:29', 'anggota'),
(330, 'Anggota 329', 'anggota329@gmail.com', NULL, '$2y$12$oXdZlkovsULgMaDPRUk1Huqli/jKdFVDTQX2fUc13mKEMm1pQUZg.', NULL, '2025-07-17 04:21:29', '2025-07-17 04:21:29', 'anggota'),
(331, 'Anggota 330', 'anggota330@gmail.com', NULL, '$2y$12$KB8ePQFy3Lta8DyU2.XPPOcG81M8oMMOhIf6.QQnf37Vm2LoIp3n.', NULL, '2025-07-17 04:21:29', '2025-07-17 04:21:29', 'anggota'),
(332, 'Anggota 331', 'anggota331@gmail.com', NULL, '$2y$12$WL9ISNjgLrcIJNT93/UX2u1dGfRu7CLnIJSx5CSn3CHtbO.LWYsba', NULL, '2025-07-17 04:21:30', '2025-07-17 04:21:30', 'anggota'),
(333, 'Anggota 332', 'anggota332@gmail.com', NULL, '$2y$12$nXngWOMKCryyMEFrAm0zvuUyyEnYyR7DnTBo/jNj1f6j1pUOuYrfy', NULL, '2025-07-17 04:21:30', '2025-07-17 04:21:30', 'anggota'),
(334, 'Anggota 333', 'anggota333@gmail.com', NULL, '$2y$12$bpwsdzyKINDWlWy69AxTSu1btfwPgriw7nn0WrE.4IodYSTSe94jK', NULL, '2025-07-17 04:21:30', '2025-07-17 04:21:30', 'anggota'),
(335, 'Anggota 334', 'anggota334@gmail.com', NULL, '$2y$12$NyCeFLrV1pAd3B5S95eZm.gEVcKdhMXfz27HaYx9UAk1xFTyJxA1a', NULL, '2025-07-17 04:21:31', '2025-07-17 04:21:31', 'anggota'),
(336, 'Anggota 335', 'anggota335@gmail.com', NULL, '$2y$12$mgLUMR1pJznjuV2nuXEZg.bLblHvJMLUbSE8zYFsvso1VVFtgjwjm', NULL, '2025-07-17 04:21:31', '2025-07-17 04:21:31', 'anggota'),
(337, 'Anggota 336', 'anggota336@gmail.com', NULL, '$2y$12$VFsYkkjinmyQIdP3YoJNzu2Mhmq7xjaaHzqW48XmBtdMY10ULgAvS', NULL, '2025-07-17 04:21:31', '2025-07-17 04:21:31', 'anggota'),
(338, 'Anggota 337', 'anggota337@gmail.com', NULL, '$2y$12$AAqjTK57ReOvnsINQVWrZeelDQaFUVg/AgKdO5.LVEIYRWeZXhHrO', NULL, '2025-07-17 04:21:32', '2025-07-17 04:21:32', 'anggota'),
(339, 'Anggota 338', 'anggota338@gmail.com', NULL, '$2y$12$upRvqNth77nvX8Xa1eiazu6eNObfbfnCHepAjPNGx7pKuFz9VWkS2', NULL, '2025-07-17 04:21:32', '2025-07-17 04:21:32', 'anggota'),
(340, 'Anggota 339', 'anggota339@gmail.com', NULL, '$2y$12$KaZx3IJNlqigFTO1SkgIvuDeuCWPhSsWuTh0D/4eoJVm3Rf6vH2du', NULL, '2025-07-17 04:21:32', '2025-07-17 04:21:32', 'anggota'),
(341, 'Anggota 340', 'anggota340@gmail.com', NULL, '$2y$12$oA.sD7krszMZuAmE29Pe3OFX.jJBCQYOO13eZiBKRLybvwR0YtoA.', NULL, '2025-07-17 04:21:32', '2025-07-17 04:21:32', 'anggota'),
(342, 'Anggota 341', 'anggota341@gmail.com', NULL, '$2y$12$Y/cY96bVTpSi.Hch70tPce9FoThc1DpGlSX3pfnYJSliN6Po3XojO', NULL, '2025-07-17 04:21:33', '2025-07-17 04:21:33', 'anggota'),
(343, 'Anggota 342', 'anggota342@gmail.com', NULL, '$2y$12$bO8a6jelloF1DNftUf4dvu1r9Jw3Jz33Uz89hx.jbrPRqKCnPK07u', NULL, '2025-07-17 04:21:33', '2025-07-17 04:21:33', 'anggota'),
(344, 'Anggota 343', 'anggota343@gmail.com', NULL, '$2y$12$YmseJWu2fUtW0NJfJAieqeHoCM7a8yizTg5BTMRSJolOrECZpMWGS', NULL, '2025-07-17 04:21:33', '2025-07-17 04:21:33', 'anggota'),
(345, 'Anggota 344', 'anggota344@gmail.com', NULL, '$2y$12$uwFn.u1y8PQfDiEFT2M2SO9GeU.aQ5ruphpfOg3JM6YV9LopfRajO', NULL, '2025-07-17 04:21:34', '2025-07-17 04:21:34', 'anggota'),
(346, 'Anggota 345', 'anggota345@gmail.com', NULL, '$2y$12$z9c8CaCRGpzeUV7dGZ/5n.KT9Xa25PbSirykVHARP8BBHj.FqMLRu', NULL, '2025-07-17 04:21:34', '2025-07-17 04:21:34', 'anggota'),
(347, 'Anggota 346', 'anggota346@gmail.com', NULL, '$2y$12$x5BgfyN58mxMrrmoen9EJ.Y6Hv6q1gfKZWSszMlPv0MLf4vojDWe.', NULL, '2025-07-17 04:21:34', '2025-07-17 04:21:34', 'anggota'),
(348, 'Anggota 347', 'anggota347@gmail.com', NULL, '$2y$12$3qg2Rptd7VbtY5yvxRwY/eAwYexnj1SE70TNGPU4HRFvNm3Ouil2O', NULL, '2025-07-17 04:21:35', '2025-07-17 04:21:35', 'anggota'),
(349, 'Anggota 348', 'anggota348@gmail.com', NULL, '$2y$12$yjAndGZQde05NLpOGQo9JeuE5pF5wsthYMOpEBSGOO36NA/Kktv6K', NULL, '2025-07-17 04:21:35', '2025-07-17 04:21:35', 'anggota'),
(350, 'Anggota 349', 'anggota349@gmail.com', NULL, '$2y$12$2mh88iKlmGYA3rFVG3U6aOfySzncHMUVAr1JEfrzvEz52QunE7Xs.', NULL, '2025-07-17 04:21:35', '2025-07-17 04:21:35', 'anggota'),
(351, 'Anggota 350', 'anggota350@gmail.com', NULL, '$2y$12$.DKr69QAZw5yEBSZGigpP.Y29tNeG6tZkDR0Gdgn/.C53OFHmCBlC', NULL, '2025-07-17 04:21:35', '2025-07-17 04:21:35', 'anggota'),
(352, 'Anggota 351', 'anggota351@gmail.com', NULL, '$2y$12$Kss8EyOleanHSdeJdGwQ8.DYKzPt4kBrOWI8508oUnWBMiM8vIng6', NULL, '2025-07-17 04:21:36', '2025-07-17 04:21:36', 'anggota'),
(353, 'Anggota 352', 'anggota352@gmail.com', NULL, '$2y$12$nr2gHC4J3fmcOGV3uRDvx.axOvnG4sLE8U0.t0PveuFjfpSz4/b1S', NULL, '2025-07-17 04:21:36', '2025-07-17 04:21:36', 'anggota'),
(354, 'Anggota 353', 'anggota353@gmail.com', NULL, '$2y$12$EXPniXRrzoJBeOCDPlFCFeV5NLgZyGIe71t2yX70NbYxmuavDpS5C', NULL, '2025-07-17 04:21:36', '2025-07-17 04:21:36', 'anggota'),
(355, 'Anggota 354', 'anggota354@gmail.com', NULL, '$2y$12$tk3zz.21dlg7P463fZfuAeU4vh4rM.6HEyU3I.2aD8hE6.MMbfJK6', NULL, '2025-07-17 04:21:37', '2025-07-17 04:21:37', 'anggota'),
(356, 'Anggota 355', 'anggota355@gmail.com', NULL, '$2y$12$psNI46rkUrV2.RlCV6MvcOVigo39KUMInAKUTSQU27NEWJrOTX.gi', NULL, '2025-07-17 04:21:37', '2025-07-17 04:21:37', 'anggota'),
(357, 'Anggota 356', 'anggota356@gmail.com', NULL, '$2y$12$rgVVBxdhG7j2NF6Jz8vkVuWrghrZBhiZe9nIRG2b4ZceHnvmHrbu.', NULL, '2025-07-17 04:21:37', '2025-07-17 04:21:37', 'anggota'),
(358, 'Anggota 357', 'anggota357@gmail.com', NULL, '$2y$12$bMI1XBvIIOOnAsuWVHwRuu9h0rq.usspmdDn51X3AFC1MWh31mFmq', NULL, '2025-07-17 04:21:38', '2025-07-17 04:21:38', 'anggota'),
(359, 'Anggota 358', 'anggota358@gmail.com', NULL, '$2y$12$xozlya6dfN/DYFRDKQWqtON52nsTu4EkCVoZ2j/m32jipu.zYnd/2', NULL, '2025-07-17 04:21:38', '2025-07-17 04:21:38', 'anggota'),
(360, 'Anggota 359', 'anggota359@gmail.com', NULL, '$2y$12$ImQg44QHnqMlIIJDAHn.PeiL.vgNrdH1wgq/ezz7ewFlMlqc9rIsa', NULL, '2025-07-17 04:21:38', '2025-07-17 04:21:38', 'anggota'),
(361, 'Anggota 360', 'anggota360@gmail.com', NULL, '$2y$12$y8jHW4M4Q9KY1eBYdbfw6uva3wRscLY1ax/ml1.AUaSY/tgIV/GQu', NULL, '2025-07-17 04:21:39', '2025-07-17 04:21:39', 'anggota'),
(362, 'Anggota 361', 'anggota361@gmail.com', NULL, '$2y$12$4kh21gHv.glzbV/wuHfxbuL4AykqFfMj5S7nOlHGiCBKibdrhG3o6', NULL, '2025-07-17 04:21:39', '2025-07-17 04:21:39', 'anggota'),
(363, 'Anggota 362', 'anggota362@gmail.com', NULL, '$2y$12$4CvTY0GVdxNBFQCeConuMehEUkauE7ZtkZxA31lUJUfZsQJdyzAjS', NULL, '2025-07-17 04:21:39', '2025-07-17 04:21:39', 'anggota'),
(364, 'Anggota 363', 'anggota363@gmail.com', NULL, '$2y$12$gqjLCQtvvpEmvhoBBgMajeY3NIBsxWftGDq9Z63a7emIG2bk9akjO', NULL, '2025-07-17 04:21:39', '2025-07-17 04:21:39', 'anggota'),
(365, 'Anggota 364', 'anggota364@gmail.com', NULL, '$2y$12$9Zv8BfLdxy1cBG1sGoXPC.O7.p3JNJYYte4AeR.ZB8fQb2Z0OcTLa', NULL, '2025-07-17 04:21:40', '2025-07-17 04:21:40', 'anggota'),
(366, 'Anggota 365', 'anggota365@gmail.com', NULL, '$2y$12$z1iqGI1vUGpIxKOLFccIPONoN36hxImbtfj2cwAvIRNToEaBLY/b2', NULL, '2025-07-17 04:21:40', '2025-07-17 04:21:40', 'anggota'),
(367, 'Anggota 366', 'anggota366@gmail.com', NULL, '$2y$12$55D8V6Ua8DUiy1lMAckXs.nWLy6N3II3CrjtTL2dhtB54jCoZgdkC', NULL, '2025-07-17 04:21:40', '2025-07-17 04:21:40', 'anggota'),
(368, 'Anggota 367', 'anggota367@gmail.com', NULL, '$2y$12$gHKsE9Pxs329V64O1NotuOKLKriNGHU/dlUIKhoclf7hj9V1tRBaa', NULL, '2025-07-17 04:21:41', '2025-07-17 04:21:41', 'anggota'),
(369, 'Anggota 368', 'anggota368@gmail.com', NULL, '$2y$12$1Y84SnQmTsh.m2HlLg5tSO2P94kWw1NIj7NYy2Cr6IHXpEabcA6Iu', NULL, '2025-07-17 04:21:41', '2025-07-17 04:21:41', 'anggota'),
(370, 'Anggota 369', 'anggota369@gmail.com', NULL, '$2y$12$gjZsbLWObe4L9mlIsJBF5uLb4GO27JjN536OQ18DhwD31JAZCaJGm', NULL, '2025-07-17 04:21:41', '2025-07-17 04:21:41', 'anggota'),
(371, 'Anggota 370', 'anggota370@gmail.com', NULL, '$2y$12$ynVoyM31EUcLAvo3V2mI6etuLhg8HPGNa1lDsc2dFWQBNm3Qoaxx2', NULL, '2025-07-17 04:21:42', '2025-07-17 04:21:42', 'anggota'),
(372, 'Anggota 371', 'anggota371@gmail.com', NULL, '$2y$12$/pqbFhnu768aFfVmHQkxnuouU3KKBOsAK4015/mof1M3rCCjblb9e', NULL, '2025-07-17 04:21:42', '2025-07-17 04:21:42', 'anggota'),
(373, 'Anggota 372', 'anggota372@gmail.com', NULL, '$2y$12$ntUhh1JCFEJYBnqLuOrwpuvq4suybpzjUPcB/THkSHH/VdF8VwLFe', NULL, '2025-07-17 04:21:42', '2025-07-17 04:21:42', 'anggota'),
(374, 'Anggota 373', 'anggota373@gmail.com', NULL, '$2y$12$KQFYo6e50zh2cgasazU.qe0vZAe0GGXOaPMykKdZG5sSObExxMSIm', NULL, '2025-07-17 04:21:42', '2025-07-17 04:21:42', 'anggota'),
(375, 'Anggota 374', 'anggota374@gmail.com', NULL, '$2y$12$soJC5f9CRnV.u9lo3dy0susVOD5yXoLYPwGa7LhFKb2HctuQ0NaR2', NULL, '2025-07-17 04:21:43', '2025-07-17 04:21:43', 'anggota'),
(376, 'Anggota 375', 'anggota375@gmail.com', NULL, '$2y$12$/I4A3Sp2qmbIfrJE/2VeDeoXmva1twhuD2xD6PeL.sp1UZUyrI6Fi', NULL, '2025-07-17 04:21:43', '2025-07-17 04:21:43', 'anggota'),
(377, 'Anggota 376', 'anggota376@gmail.com', NULL, '$2y$12$AiKCys2wqKTLYX5fZ52/4u6.YXCXHPdEwIOJ6zlwhzJLvesEm1RsW', NULL, '2025-07-17 04:21:43', '2025-07-17 04:21:43', 'anggota'),
(378, 'Anggota 377', 'anggota377@gmail.com', NULL, '$2y$12$d5R51HXa8bQtttuUrklJtulr.tKfx3vrZvR/dDEharFw3HHampA..', NULL, '2025-07-17 04:21:44', '2025-07-17 04:21:44', 'anggota'),
(379, 'Anggota 378', 'anggota378@gmail.com', NULL, '$2y$12$Ch2VlWV9/WB.Y7ok2LsgBOroEt.DOYEkcT0IA89oQWldDh/NERQAu', NULL, '2025-07-17 04:21:44', '2025-07-17 04:21:44', 'anggota'),
(380, 'Anggota 379', 'anggota379@gmail.com', NULL, '$2y$12$FfWvQbB7rSlocGuqCIjUrO0Xum9EP8cf9Gu407vGHYeG/wRqVrDxe', NULL, '2025-07-17 04:21:44', '2025-07-17 04:21:44', 'anggota'),
(381, 'Anggota 380', 'anggota380@gmail.com', NULL, '$2y$12$or8.Bb9HqLoRR5qG6sJLWu8yUawfjcv1.9xkNc0zBdK1jvGJ.8GwS', NULL, '2025-07-17 04:21:45', '2025-07-17 04:21:45', 'anggota'),
(382, 'Anggota 381', 'anggota381@gmail.com', NULL, '$2y$12$hVtgGe8xdZQa0Gz5.IZuLuiPfCmpVkFgj0rN3XFAJOGaPHGRmOFfu', NULL, '2025-07-17 04:21:45', '2025-07-17 04:21:45', 'anggota'),
(383, 'Anggota 382', 'anggota382@gmail.com', NULL, '$2y$12$UXD9RVrdgIeWcqhLdz5Vfe77.7LW8MRSOBs.1em7B/X3abUzC7DV.', NULL, '2025-07-17 04:21:45', '2025-07-17 04:21:45', 'anggota'),
(384, 'Anggota 383', 'anggota383@gmail.com', NULL, '$2y$12$mUQZQF6sXeIJlTZhuOpXIelb2eJ.ZH38yTt/aU5xe0h1KvZzdO5t6', NULL, '2025-07-17 04:21:45', '2025-07-17 04:21:45', 'anggota'),
(385, 'Anggota 384', 'anggota384@gmail.com', NULL, '$2y$12$ajJHEsUTX8bODA0lxYXsWOTcPR5h.OLDqQRw5aHwXkJ9yioEajbNy', NULL, '2025-07-17 04:21:46', '2025-07-17 04:21:46', 'anggota'),
(386, 'Anggota 385', 'anggota385@gmail.com', NULL, '$2y$12$QtR6VgcqpZ5P1GGjG98ik.5e6noLn/Ih2U.ZNAseoKhgSXKL8rQxe', NULL, '2025-07-17 04:21:46', '2025-07-17 04:21:46', 'anggota'),
(387, 'Anggota 386', 'anggota386@gmail.com', NULL, '$2y$12$bYeKFrDz6W9EEgTlHQltZevp1gMK.ZqThc8mzHvO1o4XtOReHZQ5C', NULL, '2025-07-17 04:21:46', '2025-07-17 04:21:46', 'anggota'),
(388, 'Anggota 387', 'anggota387@gmail.com', NULL, '$2y$12$QvRqd.TaPtGJoZ0DPnZHLOYXeoxqI98e4Pu3jnTeldp3iokjRvDIe', NULL, '2025-07-17 04:21:47', '2025-07-17 04:21:47', 'anggota'),
(389, 'Anggota 388', 'anggota388@gmail.com', NULL, '$2y$12$TC.lxU81l0KV.xdIKiDC6e7QhFDpV9dxtrCFHV06TpsRZ5jqfkiUG', NULL, '2025-07-17 04:21:47', '2025-07-17 04:21:47', 'anggota'),
(390, 'Anggota 389', 'anggota389@gmail.com', NULL, '$2y$12$Ih1nMeeZj1zX5.ARAqV1aOouhkX53bGAHj1bZf49ibwdqOCv7AjKO', NULL, '2025-07-17 04:21:47', '2025-07-17 04:21:47', 'anggota'),
(391, 'Anggota 390', 'anggota390@gmail.com', NULL, '$2y$12$pLm3fpREbSztxmrKgal6uu4BSmTe7hkuN9eI4cy.Uasyb88mI3r3i', NULL, '2025-07-17 04:21:48', '2025-07-17 04:21:48', 'anggota'),
(392, 'Anggota 391', 'anggota391@gmail.com', NULL, '$2y$12$eMzCOiaQPPqLYjgAoFwLieb98WfPRU1S1SxjPqXgBtnpBKeSUaYoK', NULL, '2025-07-17 04:21:48', '2025-07-17 04:21:48', 'anggota'),
(393, 'Anggota 392', 'anggota392@gmail.com', NULL, '$2y$12$K2UEsigxJUqV4epB.73F..rOAe0taFMI4DMi1a.IiRQWifIy8EDc.', NULL, '2025-07-17 04:21:48', '2025-07-17 04:21:48', 'anggota'),
(394, 'Anggota 393', 'anggota393@gmail.com', NULL, '$2y$12$7irTeHsCUiqKs1PTnND4oekIX6Fat26iGQsrPYTIRQ2ozOjhOeV2a', NULL, '2025-07-17 04:21:49', '2025-07-17 04:21:49', 'anggota'),
(395, 'Anggota 394', 'anggota394@gmail.com', NULL, '$2y$12$j3BM9i.o3bAKP0dAlBN27.BtpENK02GBrr48ztcgXi4YE4PUmytlq', NULL, '2025-07-17 04:21:49', '2025-07-17 04:21:49', 'anggota'),
(396, 'Anggota 395', 'anggota395@gmail.com', NULL, '$2y$12$cleo2guxFwQleN65urFo..rjsyuOz9fowbXwcWjoVHNoOBn1yTKwK', NULL, '2025-07-17 04:21:49', '2025-07-17 04:21:49', 'anggota'),
(397, 'Anggota 396', 'anggota396@gmail.com', NULL, '$2y$12$QsCGc3fQ7aE5ag2YoiZY7ONB3wAK3yPQDA93nJPiMrNMaQU52Bfpq', NULL, '2025-07-17 04:21:49', '2025-07-17 04:21:49', 'anggota'),
(398, 'Anggota 397', 'anggota397@gmail.com', NULL, '$2y$12$laYyvQo4PcQ7fLLcRounZuVmbLpzg6ewyK7FZCsZHGcvhycaSio7.', NULL, '2025-07-17 04:21:50', '2025-07-17 04:21:50', 'anggota'),
(399, 'Anggota 398', 'anggota398@gmail.com', NULL, '$2y$12$vZ.K1Ttfp0ekxSBaQeIoc.ymNnJqXssdtfIOmiPcN7TBixtyejcIG', NULL, '2025-07-17 04:21:50', '2025-07-17 04:21:50', 'anggota'),
(400, 'Anggota 399', 'anggota399@gmail.com', NULL, '$2y$12$Y.Q7jLUuJE412hzYx8sHsOyx5Dcc88KR88RwoGqkxvJ9h/264Uw0a', NULL, '2025-07-17 04:21:50', '2025-07-17 04:21:50', 'anggota'),
(401, 'Anggota 400', 'anggota400@gmail.com', NULL, '$2y$12$.M7EKYC1ii/hf1UAKxKCIuL.GGO1h842smAMNSQgUk28nLQzMWGhK', NULL, '2025-07-17 04:21:51', '2025-07-17 04:21:51', 'anggota'),
(402, 'Anggota 401', 'anggota401@gmail.com', NULL, '$2y$12$GWt3GCytf4jwtcI3Sp53ke2eMoXC2ygnoUA1pjLTHmvb8MigfnHhW', NULL, '2025-07-17 04:21:51', '2025-07-17 04:21:51', 'anggota'),
(403, 'Anggota 402', 'anggota402@gmail.com', NULL, '$2y$12$3Rc/7gDqV7nkD4PjF6tgKepAqv/fhYyE48lgaa/i76tTLtIcFJdIC', NULL, '2025-07-17 04:21:51', '2025-07-17 04:21:51', 'anggota'),
(404, 'Anggota 403', 'anggota403@gmail.com', NULL, '$2y$12$vwyeOKvMtLMzYC2lNzauK.vkb4h.6YfmO/BUKLd2oImoVWz9j/IwG', NULL, '2025-07-17 04:21:52', '2025-07-17 04:21:52', 'anggota'),
(405, 'Anggota 404', 'anggota404@gmail.com', NULL, '$2y$12$gpWCzXoarVYgg79ciCubO.C2xgga/nYUWNqsfbuLhDpQ9b7LrTtIm', NULL, '2025-07-17 04:21:52', '2025-07-17 04:21:52', 'anggota'),
(406, 'Anggota 405', 'anggota405@gmail.com', NULL, '$2y$12$4ESHUNFhedwtJfIX4/hveO/AVvx0OzpM2i2yaQo/dbTEfBzgfar8W', NULL, '2025-07-17 04:21:52', '2025-07-17 04:21:52', 'anggota'),
(407, 'Anggota 406', 'anggota406@gmail.com', NULL, '$2y$12$iS17eFiI52rp80onp6a5OuTZULVWFdnZnjcnPfBMkM7ew0fvTfGv.', NULL, '2025-07-17 04:21:52', '2025-07-17 04:21:52', 'anggota'),
(408, 'Anggota 407', 'anggota407@gmail.com', NULL, '$2y$12$Fv4ILOnoys6gC5ygw75xEeCUnyDIiF1qz7SxghJQc32zkfmDcnb9G', NULL, '2025-07-17 04:21:53', '2025-07-17 04:21:53', 'anggota'),
(409, 'Anggota 408', 'anggota408@gmail.com', NULL, '$2y$12$.En2tftIXaQy5z6v2gh2XuGrsOdluGtuzujthfSgNLt3G9rupwBR.', NULL, '2025-07-17 04:21:53', '2025-07-17 04:21:53', 'anggota'),
(410, 'Anggota 409', 'anggota409@gmail.com', NULL, '$2y$12$fzfvPYsSjT2VamBrR3Mqk.XooI5gSE32y4w2C/9M6wHYmK7bRlYHm', NULL, '2025-07-17 04:21:53', '2025-07-17 04:21:53', 'anggota'),
(411, 'Anggota 410', 'anggota410@gmail.com', NULL, '$2y$12$EV3kR.JIPF/Fz1MVyLtBsezpZHSuhDRz.2ehCvuWHh/RYURqFfko.', NULL, '2025-07-17 04:21:54', '2025-07-17 04:21:54', 'anggota'),
(412, 'Anggota 411', 'anggota411@gmail.com', NULL, '$2y$12$7MDRZCqT/UAH7iIbhq77beC1gG0P01dXPXUCCRPuJjBZwWd2ha876', NULL, '2025-07-17 04:21:54', '2025-07-17 04:21:54', 'anggota'),
(413, 'Anggota 412', 'anggota412@gmail.com', NULL, '$2y$12$pL6E/T8Z0nl/06Mu8sqVieG50h4Bj/AKAP2gjGQso95fOyn8MSs0W', NULL, '2025-07-17 04:21:54', '2025-07-17 04:21:54', 'anggota'),
(414, 'Anggota 413', 'anggota413@gmail.com', NULL, '$2y$12$MbbytGaH4r3mw10kqA9BKeDINmvSxL9SnEaTsSg/7SZL87Bc1Pksi', NULL, '2025-07-17 04:21:55', '2025-07-17 04:21:55', 'anggota'),
(415, 'Anggota 414', 'anggota414@gmail.com', NULL, '$2y$12$/EugyVxYcBQ7xani2kqp7uGVK0i3rmgh14keG3KQ.AlTsCQa6en2K', NULL, '2025-07-17 04:21:55', '2025-07-17 04:21:55', 'anggota'),
(416, 'Anggota 415', 'anggota415@gmail.com', NULL, '$2y$12$e0QGmMvV50.DED5bYbuOle511CcYGhEbd4NoOu.ADgz.ooyDJMm3u', NULL, '2025-07-17 04:21:55', '2025-07-17 04:21:55', 'anggota'),
(417, 'Anggota 416', 'anggota416@gmail.com', NULL, '$2y$12$GvyOBaIwPM8xka24SRU8/en.VxbjQKiBch6hB0aLosbD2rZSEg.2.', NULL, '2025-07-17 04:21:55', '2025-07-17 04:21:55', 'anggota'),
(418, 'Anggota 417', 'anggota417@gmail.com', NULL, '$2y$12$/f4RpFEMikwDoXLIe1W02uzNCgqEDqzsR/g5g.mo1WVUXxzbm/tgK', NULL, '2025-07-17 04:21:56', '2025-07-17 04:21:56', 'anggota'),
(419, 'Anggota 418', 'anggota418@gmail.com', NULL, '$2y$12$xR5mjOe60G8Sp6Z1EawGvu/bbTITwI05fmUuN9WBoALGptYgxU0xS', NULL, '2025-07-17 04:21:56', '2025-07-17 04:21:56', 'anggota'),
(420, 'Anggota 419', 'anggota419@gmail.com', NULL, '$2y$12$8pmLUv/B7luGLMRGwS5XBezgGx9qCk16.UJ4GEq1EsOEnYpSVVfom', NULL, '2025-07-17 04:21:56', '2025-07-17 04:21:56', 'anggota'),
(421, 'Anggota 420', 'anggota420@gmail.com', NULL, '$2y$12$WLRVdY8pt7LBbM20sI1xAOkMKgP7RGSeEhpgp1rw.N2HJ5MlQnBiK', NULL, '2025-07-17 04:21:57', '2025-07-17 04:21:57', 'anggota'),
(422, 'Anggota 421', 'anggota421@gmail.com', NULL, '$2y$12$NC/ouG3PYOj7weDn9CSB.OLhFUD86jmy2hy3LBnscEdLcQkaVuB1.', NULL, '2025-07-17 04:21:57', '2025-07-17 04:21:57', 'anggota'),
(423, 'Anggota 422', 'anggota422@gmail.com', NULL, '$2y$12$RCM1LG8um0CF80OYAMri2uxX1aMyn8qZIdfA8c.O6mkTNBsBOWPRm', NULL, '2025-07-17 04:21:57', '2025-07-17 04:21:57', 'anggota'),
(424, 'Anggota 423', 'anggota423@gmail.com', NULL, '$2y$12$Z.Ltz0yaetgtFpdl7coxxenelvSprCUVYjzCkS8gC1b2jX7VP2UPC', NULL, '2025-07-17 04:21:58', '2025-07-17 04:21:58', 'anggota'),
(425, 'Anggota 424', 'anggota424@gmail.com', NULL, '$2y$12$cwQe1kjVmu/FFRMgQcbmQe9WGcQHbLaTylXvR.ZJy8gRTT51uFpNu', NULL, '2025-07-17 04:21:58', '2025-07-17 04:21:58', 'anggota'),
(426, 'Anggota 425', 'anggota425@gmail.com', NULL, '$2y$12$sNvER8aHUDkfLNeDukvDUuIBKFasldCBbDmAXtDvMYmrzdU.dvq8K', NULL, '2025-07-17 04:21:58', '2025-07-17 04:21:58', 'anggota'),
(427, 'Anggota 426', 'anggota426@gmail.com', NULL, '$2y$12$gH6wOYB98wjHIuD9oWYVzesX.kM8CmFUcOycel.QkV4ZbNcT39N/m', NULL, '2025-07-17 04:21:59', '2025-07-17 04:21:59', 'anggota'),
(428, 'Anggota 427', 'anggota427@gmail.com', NULL, '$2y$12$TzZFiMG5QHQJdHizHTo6QeOAhWYgb4Ad6zSDw8UBAA9sas3WGmox2', NULL, '2025-07-17 04:21:59', '2025-07-17 04:21:59', 'anggota'),
(429, 'Anggota 428', 'anggota428@gmail.com', NULL, '$2y$12$Ynj5UfUgRfwLW0So.sckQ.Rl.B8wH2mRUQIciPT5nAFVS8UemUdWS', NULL, '2025-07-17 04:21:59', '2025-07-17 04:21:59', 'anggota'),
(430, 'Anggota 429', 'anggota429@gmail.com', NULL, '$2y$12$Wvc1j1iPzzVOlscAdl9kUOroPHyTv.RWIp44N5cyhL5DJYQ6OKTV6', NULL, '2025-07-17 04:21:59', '2025-07-17 04:21:59', 'anggota'),
(431, 'Anggota 430', 'anggota430@gmail.com', NULL, '$2y$12$h8IlZw9htnxCOo3q6KDsr.I7dXAS9aRVLV57twhjUYqKuLUaJx8BK', NULL, '2025-07-17 04:22:00', '2025-07-17 04:22:00', 'anggota'),
(432, 'Anggota 431', 'anggota431@gmail.com', NULL, '$2y$12$WBoR9q2xNVO3GJbJXI.JOuAGQQnkQmBXXBxp/itcdTiwFoYlNKQNG', NULL, '2025-07-17 04:22:00', '2025-07-17 04:22:00', 'anggota'),
(433, 'Anggota 432', 'anggota432@gmail.com', NULL, '$2y$12$litH2XsaEG6D8M7uXHwhf.1uOGZUsL7AF4rmdp/axo.xo5GWKxvDa', NULL, '2025-07-17 04:22:00', '2025-07-17 04:22:00', 'anggota'),
(434, 'Anggota 433', 'anggota433@gmail.com', NULL, '$2y$12$7mZCO6CFtLEHUB2ExJhOaufHs1AdHHu7yzDr2NDUMkMB14HIeUnma', NULL, '2025-07-17 04:22:01', '2025-07-17 04:22:01', 'anggota'),
(435, 'Anggota 434', 'anggota434@gmail.com', NULL, '$2y$12$PYxZUHfCrPUeKYpbMKO1eeykRwUqL4.JcGfPEikcruVsqWKpeQA6C', NULL, '2025-07-17 04:22:01', '2025-07-17 04:22:01', 'anggota'),
(436, 'Anggota 435', 'anggota435@gmail.com', NULL, '$2y$12$ZogU.hezKHOxsQn84bY3CuohO3nbqP/W.hWdYYzap6aCbObBdJU/O', NULL, '2025-07-17 04:22:01', '2025-07-17 04:22:01', 'anggota'),
(437, 'Anggota 436', 'anggota436@gmail.com', NULL, '$2y$12$g/o0eRVWP5YhUncADue5T.83Lof2DLWskpyWRhq5V7qSOB/c6mzcW', NULL, '2025-07-17 04:22:02', '2025-07-17 04:22:02', 'anggota'),
(438, 'Anggota 437', 'anggota437@gmail.com', NULL, '$2y$12$QPP52MPCB8X3NoPJ69y/Cu8t3aFRBd2MH2EKa0RHfPTR2FE4hAg8O', NULL, '2025-07-17 04:22:02', '2025-07-17 04:22:02', 'anggota'),
(439, 'Anggota 438', 'anggota438@gmail.com', NULL, '$2y$12$X3I4DC1xy3zKyUW8apND/ebg7DTl0JBjMi8bwoFgxO8k1IZuSd/7m', NULL, '2025-07-17 04:22:02', '2025-07-17 04:22:02', 'anggota'),
(440, 'Anggota 439', 'anggota439@gmail.com', NULL, '$2y$12$BEpT9p4bQnt8PbM4kse/gOZVHwmLwft8jPWmDCdDUEnX1XnevHWGi', NULL, '2025-07-17 04:22:02', '2025-07-17 04:22:02', 'anggota'),
(441, 'Anggota 440', 'anggota440@gmail.com', NULL, '$2y$12$oMun5jlzUZmtcJXTpbq7DecPvM0OU1c.G3iRYh0FDH4wiJ528YGNS', NULL, '2025-07-17 04:22:03', '2025-07-17 04:22:03', 'anggota'),
(442, 'Anggota 441', 'anggota441@gmail.com', NULL, '$2y$12$hu0GXoaw3E2NBi.MNd0wpuQ6g9eBkqvYcOqcT6EPEeIpfEfhJ/eZS', NULL, '2025-07-17 04:22:03', '2025-07-17 04:22:03', 'anggota'),
(443, 'Anggota 442', 'anggota442@gmail.com', NULL, '$2y$12$ZHebkE648oq/DakH6C0Daeq9ucQ6QwGoKMKqrfvzdzyoAcZoxWyd2', NULL, '2025-07-17 04:22:03', '2025-07-17 04:22:03', 'anggota'),
(444, 'Anggota 443', 'anggota443@gmail.com', NULL, '$2y$12$QtSZY7AO/Hvk7MdaNDMtlOxc7OQwC.m8Am8Stw50.yAtfcxIQpcHG', NULL, '2025-07-17 04:22:04', '2025-07-17 04:22:04', 'anggota'),
(445, 'Anggota 444', 'anggota444@gmail.com', NULL, '$2y$12$h0ufV1J4/VF5Oht6g0br6OuyVi0s8WFhloba5BMZaJ2bHaQD3jYcG', NULL, '2025-07-17 04:22:04', '2025-07-17 04:22:04', 'anggota'),
(446, 'Anggota 445', 'anggota445@gmail.com', NULL, '$2y$12$akIBfm2lH7qOjW18ddbKauQwGNdlrz39ZrjXiZKnlfOLyPERDkbwe', NULL, '2025-07-17 04:22:04', '2025-07-17 04:22:04', 'anggota'),
(447, 'Anggota 446', 'anggota446@gmail.com', NULL, '$2y$12$TSewLI/lQW2ZmSWeuOObJ.ZknJ7Qtp7C.VrgaOn5iVndQ4OalYqrO', NULL, '2025-07-17 04:22:05', '2025-07-17 04:22:05', 'anggota'),
(448, 'Anggota 447', 'anggota447@gmail.com', NULL, '$2y$12$Cy77Z0GjWFrczcJIHx/yV.8FY6HhfAypBFKSHlgSmNMuYlGsRjaEG', NULL, '2025-07-17 04:22:05', '2025-07-17 04:22:05', 'anggota'),
(449, 'Anggota 448', 'anggota448@gmail.com', NULL, '$2y$12$ICJLfmEQbhMKsN8vfhr07epHkBImvBB6bImF8I1vvW4UBWII/F0B2', NULL, '2025-07-17 04:22:05', '2025-07-17 04:22:05', 'anggota'),
(450, 'Anggota 449', 'anggota449@gmail.com', NULL, '$2y$12$0O9mNvGeLqHPc2oJCpKRtu31UybrLabEaBMz.BssZjB/.IrPwONi2', NULL, '2025-07-17 04:22:06', '2025-07-17 04:22:06', 'anggota'),
(451, 'Anggota 450', 'anggota450@gmail.com', NULL, '$2y$12$Ey2aGtf8Q03cYujGj1S9reyGVnDpsG/LeVJNHwp4BNLK84u8anICC', NULL, '2025-07-17 04:22:06', '2025-07-17 04:22:06', 'anggota'),
(452, 'Anggota 451', 'anggota451@gmail.com', NULL, '$2y$12$wj9fCgITS4M0aK2ZdAa0eO2jKGJg71mZkiILNGtqYudRrWMSedoFu', NULL, '2025-07-17 04:22:06', '2025-07-17 04:22:06', 'anggota'),
(453, 'Anggota 452', 'anggota452@gmail.com', NULL, '$2y$12$1NP..sTbEKet.sJcpdeSyOxVrUDa9Mu7hBnkIX7eIJohcQbHNgOP6', NULL, '2025-07-17 04:22:06', '2025-07-17 04:22:06', 'anggota'),
(454, 'Anggota 453', 'anggota453@gmail.com', NULL, '$2y$12$n1B9pOYySqTdN8QSehD39uYF.kVj9YMgeGYy/1lJuu7p68iRIV/US', NULL, '2025-07-17 04:22:07', '2025-07-17 04:22:07', 'anggota'),
(455, 'Anggota 454', 'anggota454@gmail.com', NULL, '$2y$12$D0rPfMr53tdWeRkXCxjmO.Tfc8rQN.OoUEcR867qUoKYOeTx7HLfm', NULL, '2025-07-17 04:22:07', '2025-07-17 04:22:07', 'anggota'),
(456, 'Anggota 455', 'anggota455@gmail.com', NULL, '$2y$12$9VN5PmPVeiLrV3usmaE1KeDSMsJHsKu6Fzu5mH4IUxElZnDol7CQW', NULL, '2025-07-17 04:22:07', '2025-07-17 04:22:07', 'anggota'),
(457, 'Anggota 456', 'anggota456@gmail.com', NULL, '$2y$12$QM8XcJtzSjebz5qQDfzeHeBJKfCQ0qYfjRcyso596KyHX.TnE6Gcu', NULL, '2025-07-17 04:22:08', '2025-07-17 04:22:08', 'anggota'),
(458, 'Anggota 457', 'anggota457@gmail.com', NULL, '$2y$12$FeQh5M6XsAhVFGBD1Cmqd.s1/DnAgbKnWGTTeYOJa8aP3.utp.JkK', NULL, '2025-07-17 04:22:08', '2025-07-17 04:22:08', 'anggota'),
(459, 'Anggota 458', 'anggota458@gmail.com', NULL, '$2y$12$6dpKLQo93ycdkcv5eJXaPO7PfjAZMexhsZ3YVvp4Ryq2eFaS0I6WC', NULL, '2025-07-17 04:22:08', '2025-07-17 04:22:08', 'anggota'),
(460, 'Anggota 459', 'anggota459@gmail.com', NULL, '$2y$12$1YJZ8rwlfqbQY0O9z/fwl.WKIdtjIM2aLwHK0/PMUUGO5Vc9zMMVW', NULL, '2025-07-17 04:22:09', '2025-07-17 04:22:09', 'anggota'),
(461, 'Anggota 460', 'anggota460@gmail.com', NULL, '$2y$12$7ZlPzxr.YvgFyba6jUCldOToz5mwJGEPu22TWMF7yVAfvoHAXYzjC', NULL, '2025-07-17 04:22:09', '2025-07-17 04:22:09', 'anggota'),
(462, 'Anggota 461', 'anggota461@gmail.com', NULL, '$2y$12$tthkESvXKQ5EMiz63rtoqOGO/IP2MUIG.XLnq1zP7fATngu4m/YGy', NULL, '2025-07-17 04:22:09', '2025-07-17 04:22:09', 'anggota'),
(463, 'Anggota 462', 'anggota462@gmail.com', NULL, '$2y$12$cbIbjc3cEZc336aih0Xuy.SHto.QUT4m73esQCAK/ABGPSM6yB6de', NULL, '2025-07-17 04:22:10', '2025-07-17 04:22:10', 'anggota'),
(464, 'Anggota 463', 'anggota463@gmail.com', NULL, '$2y$12$89zaP7WiWaamhIO/4RRRQextw21v4mMo5DeSMjT.2FzRjnEv7L/JG', NULL, '2025-07-17 04:22:10', '2025-07-17 04:22:10', 'anggota'),
(465, 'Anggota 464', 'anggota464@gmail.com', NULL, '$2y$12$PpefOPlG3XTZYfxoIpquO.H9UWi9Py0hIy2hsauwIZrJhezFnRV9q', NULL, '2025-07-17 04:22:10', '2025-07-17 04:22:10', 'anggota'),
(466, 'Anggota 465', 'anggota465@gmail.com', NULL, '$2y$12$b4o3HopdtksHZ1svD5080efBKw6fYVpnM0IjheXPR6YB5ZnJ86GMC', NULL, '2025-07-17 04:22:10', '2025-07-17 04:22:10', 'anggota'),
(467, 'Anggota 466', 'anggota466@gmail.com', NULL, '$2y$12$Bg5uxsxVhqsCAOA1/fpRd.tKS64dWMS8GsCy2PfU1dJtPdWkgwivq', NULL, '2025-07-17 04:22:11', '2025-07-17 04:22:11', 'anggota'),
(468, 'Anggota 467', 'anggota467@gmail.com', NULL, '$2y$12$hif9gq.wXvK2pFUq9SfUQOBfeu7MTQTvgFOePq.5upEq/RMGgOvHq', NULL, '2025-07-17 04:22:11', '2025-07-17 04:22:11', 'anggota'),
(469, 'Anggota 468', 'anggota468@gmail.com', NULL, '$2y$12$alKAZPlqzLDZ3F7NWjXIq.cZv8L3Ot8qkkxMSIhwBPIoWiLXs0JPa', NULL, '2025-07-17 04:22:11', '2025-07-17 04:22:11', 'anggota'),
(470, 'Anggota 469', 'anggota469@gmail.com', NULL, '$2y$12$lO2hzsj9GD6Zm/lysHY0t.bP7SWPR7YbJGzN5a4jRvOFHLItvCV4m', NULL, '2025-07-17 04:22:12', '2025-07-17 04:22:12', 'anggota'),
(471, 'Anggota 470', 'anggota470@gmail.com', NULL, '$2y$12$Ty3KQySiXxnHFTF84Xk02eVZMNy10CE7hWPRULDdLMwhIKbGPYUVy', NULL, '2025-07-17 04:22:12', '2025-07-17 04:22:12', 'anggota'),
(472, 'Anggota 471', 'anggota471@gmail.com', NULL, '$2y$12$NSPZ0cQSSVyWYgSDWAWeW.NVxZ6cDXYCT1rXaJm1AiJUylc94vh7i', NULL, '2025-07-17 04:22:12', '2025-07-17 04:22:12', 'anggota'),
(473, 'Anggota 472', 'anggota472@gmail.com', NULL, '$2y$12$L7TSbsBm3viMGdovejJEXOX7p63pSMMQB3jGonZJ0eciIwd6HLalG', NULL, '2025-07-17 04:22:13', '2025-07-17 04:22:13', 'anggota'),
(474, 'Anggota 473', 'anggota473@gmail.com', NULL, '$2y$12$aEqar4S9UmrXvRLtgKRrmOXVQqJaxt/tooTm7J1UBsNXgSysZTDHq', NULL, '2025-07-17 04:22:13', '2025-07-17 04:22:13', 'anggota'),
(475, 'Anggota 474', 'anggota474@gmail.com', NULL, '$2y$12$V/uSwE7eF5uv0Rb1ovDgNeaWT0/dQL44X0TczwZ4STglJtwfOYXXy', NULL, '2025-07-17 04:22:13', '2025-07-17 04:22:13', 'anggota'),
(476, 'Anggota 475', 'anggota475@gmail.com', NULL, '$2y$12$T1cbqLZfQUVuC8KbUeumJ.YjzMtjL8zC8J0eXSNzFwNXwa9VpHr8K', NULL, '2025-07-17 04:22:13', '2025-07-17 04:22:13', 'anggota'),
(477, 'Anggota 476', 'anggota476@gmail.com', NULL, '$2y$12$0gxEqVtu1ONYOx3bXsODKucSDkCZK8B7U5eE8bwq9fuMs.xITFybO', NULL, '2025-07-17 04:22:14', '2025-07-17 04:22:14', 'anggota'),
(478, 'Anggota 477', 'anggota477@gmail.com', NULL, '$2y$12$Owh/XlbI0VEOrMdpa5a50uW/9gTi3nVASfVqa.dSB9JHfErssJiXm', NULL, '2025-07-17 04:22:14', '2025-07-17 04:22:14', 'anggota'),
(479, 'Anggota 478', 'anggota478@gmail.com', NULL, '$2y$12$UpkAhFQSbyJPMrdJbG3N5OfWZlRztKQav5I.8xVCZ/cb/8gzYw4FS', NULL, '2025-07-17 04:22:14', '2025-07-17 04:22:14', 'anggota'),
(480, 'Anggota 479', 'anggota479@gmail.com', NULL, '$2y$12$bXuMAOZX6b4s00pq6x3vjOSMPT.FlHPUPsU2iK94XapFYP32LnUp2', NULL, '2025-07-17 04:22:15', '2025-07-17 04:22:15', 'anggota'),
(481, 'Anggota 480', 'anggota480@gmail.com', NULL, '$2y$12$nyUFzsSsLa/HrxOjcl.rl.Xt8/9wTxROW64bLIKQ.pjmIyLJhbcKi', NULL, '2025-07-17 04:22:15', '2025-07-17 04:22:15', 'anggota'),
(482, 'Anggota 481', 'anggota481@gmail.com', NULL, '$2y$12$9hiQBLK4Z3KbSEX/650i.eHkFS27fN6heh2WrRE0DmSxY43lpxlBe', NULL, '2025-07-17 04:22:15', '2025-07-17 04:22:15', 'anggota'),
(483, 'Anggota 482', 'anggota482@gmail.com', NULL, '$2y$12$jeKZYJ6MvcKAmKnfBEZ/ju9O8B1YbPz4vAQH7lUc7XGXZtodkaFxi', NULL, '2025-07-17 04:22:16', '2025-07-17 04:22:16', 'anggota'),
(484, 'Anggota 483', 'anggota483@gmail.com', NULL, '$2y$12$ZbQugNx4t5YpKr0wNfajAOULiOzJueLH9cV1iQXAU7f2RR1TgSWtW', NULL, '2025-07-17 04:22:16', '2025-07-17 04:22:16', 'anggota'),
(485, 'Anggota 484', 'anggota484@gmail.com', NULL, '$2y$12$QkMspbYSj23yts.XRiM/UOA.Idibq1bL3Ieh9LuQNNszdaclueD3S', NULL, '2025-07-17 04:22:16', '2025-07-17 04:22:16', 'anggota'),
(486, 'Anggota 485', 'anggota485@gmail.com', NULL, '$2y$12$t0LJuVjUCRm2ci/bufnCz.KG/.Ud1ts99o9I/Ze7YamkHR1/NWNxe', NULL, '2025-07-17 04:22:16', '2025-07-17 04:22:16', 'anggota'),
(487, 'Anggota 486', 'anggota486@gmail.com', NULL, '$2y$12$ZGhDYHqa8ML34C.dMj4TKOz3otalb121Li5X5Qvdf.qfHUCiXd2ty', NULL, '2025-07-17 04:22:17', '2025-07-17 04:22:17', 'anggota'),
(488, 'Anggota 487', 'anggota487@gmail.com', NULL, '$2y$12$k7Ymh4ExEX3ZTwWSn81rp.BYWAS71kePcOLJpWUYJyjvDqbPpPs8K', NULL, '2025-07-17 04:22:17', '2025-07-17 04:22:17', 'anggota'),
(489, 'Anggota 488', 'anggota488@gmail.com', NULL, '$2y$12$0E5ayBckCpS5octqvyxK6OGa9vHQzXtGx9JpEo7/TSK/41rVi/rgm', NULL, '2025-07-17 04:22:17', '2025-07-17 04:22:17', 'anggota'),
(490, 'Anggota 489', 'anggota489@gmail.com', NULL, '$2y$12$KnaIU8kz2J10yw5vBmJ/RO85fzQEaJnbXpH5vvjvtSI84GfeqBK2.', NULL, '2025-07-17 04:22:18', '2025-07-17 04:22:18', 'anggota'),
(491, 'Anggota 490', 'anggota490@gmail.com', NULL, '$2y$12$/EZjVu.CTh3IKGJbX2i6qumWK4fld.Bt.078YAqSCwvSRNxX.w9IC', NULL, '2025-07-17 04:22:18', '2025-07-17 04:22:18', 'anggota'),
(492, 'Anggota 491', 'anggota491@gmail.com', NULL, '$2y$12$xnUBcHqUK69GzANsEbUxAuK3NE7lhxHozzRIBoVzJ7KKOIG96kPZK', NULL, '2025-07-17 04:22:18', '2025-07-17 04:22:18', 'anggota'),
(493, 'Anggota 492', 'anggota492@gmail.com', NULL, '$2y$12$IwZIoXyyM8hc6bS.CJULh.Jf2hgS4bxEFva08RxB5iD9Bckcy7PfG', NULL, '2025-07-17 04:22:19', '2025-07-17 04:22:19', 'anggota'),
(494, 'Anggota 493', 'anggota493@gmail.com', NULL, '$2y$12$wQxhEazgKh2S4yJj4tP6xu3HzMVgPIQjcy6sn8BoM5fx2CSARhQv.', NULL, '2025-07-17 04:22:19', '2025-07-17 04:22:19', 'anggota'),
(495, 'Anggota 494', 'anggota494@gmail.com', NULL, '$2y$12$jAGP2xqXdha3QEWBEwq1p.z1yp2DW8FeP3ZnSp4w3Fl4ApmUZZkO2', NULL, '2025-07-17 04:22:19', '2025-07-17 04:22:19', 'anggota'),
(496, 'Anggota 495', 'anggota495@gmail.com', NULL, '$2y$12$pUNO2oqKTCIIURbIju4mNOoP.FOh1dyOYjVX8pSrwvXcdB/GNFwVG', NULL, '2025-07-17 04:22:20', '2025-07-17 04:22:20', 'anggota'),
(497, 'Anggota 496', 'anggota496@gmail.com', NULL, '$2y$12$2dlQrcWwc5nTHDMz/BZN6eIBnDNKelPdFziuy/47DwDZ.JN3e6qVm', NULL, '2025-07-17 04:22:20', '2025-07-17 04:22:20', 'anggota'),
(498, 'Anggota 497', 'anggota497@gmail.com', NULL, '$2y$12$UFNbXTSHCUocaGt.0bkBUO0g0mP9bzg771TkmNF4sjS.slTr7pcLm', NULL, '2025-07-17 04:22:20', '2025-07-17 04:22:20', 'anggota'),
(499, 'Anggota 498', 'anggota498@gmail.com', NULL, '$2y$12$JzQhd2V1IbXdxRGsYTveB.Vz7NynTcVAgBrdzDCJPjRAcUaLoG.9W', NULL, '2025-07-17 04:22:20', '2025-07-17 04:22:20', 'anggota'),
(500, 'Anggota 499', 'anggota499@gmail.com', NULL, '$2y$12$9bOdNX2.PztlP3nR6.MGlu5ogPBaKx07y73RXK/I2CPzU8n2O.LN2', NULL, '2025-07-17 04:22:21', '2025-07-17 04:22:21', 'anggota'),
(501, 'Anggota 500', 'anggota500@gmail.com', NULL, '$2y$12$2pRVR69wyQ1hJFOwxeF6auhU5KtqdeBdwKrR.XFoEt5fLAgXGJeNq', NULL, '2025-07-17 04:22:21', '2025-07-17 04:22:21', 'anggota'),
(502, 'Anggota 501', 'anggota501@gmail.com', NULL, '$2y$12$T4SakzBHYK5VP9txpAqnvem17pP73l63qNjHNPZmV7KWPs/kiDTKq', NULL, '2025-07-17 04:22:21', '2025-07-17 04:22:21', 'anggota'),
(503, 'Anggota 502', 'anggota502@gmail.com', NULL, '$2y$12$qOhvNN9.uIltK/sXU9YnbuP8J9Pz7mcIt.GcHGg9PvrKIqV2fCap6', NULL, '2025-07-17 04:22:22', '2025-07-17 04:22:22', 'anggota'),
(504, 'Anggota 503', 'anggota503@gmail.com', NULL, '$2y$12$0KXIwLxNTDILjmywTPwLCupUdHn0xCUpT9B7OV2TjaS/b6wCGUKrm', NULL, '2025-07-17 04:22:22', '2025-07-17 04:22:22', 'anggota'),
(505, 'Anggota 504', 'anggota504@gmail.com', NULL, '$2y$12$5uACZMu5wv6vZcG9ZqMt5eJRm1bPk.PONiulkUw1y8BHwZgp/BKee', NULL, '2025-07-17 04:22:22', '2025-07-17 04:22:22', 'anggota'),
(506, 'Anggota 505', 'anggota505@gmail.com', NULL, '$2y$12$ihda8ywsaC1RpQWo1aHSs.kntWCUZ/blCVrduD1nRkSA4lNDLQkum', NULL, '2025-07-17 04:22:23', '2025-07-17 04:22:23', 'anggota'),
(507, 'Anggota 506', 'anggota506@gmail.com', NULL, '$2y$12$4T3AP94qyP5I.t5/EiF42e0m.snfTht2dFF9U7Y6xPwWQ093NjCjK', NULL, '2025-07-17 04:22:23', '2025-07-17 04:22:23', 'anggota'),
(508, 'Anggota 507', 'anggota507@gmail.com', NULL, '$2y$12$4Uo2IJeJvgGu43Fpgn0XZOzbs0lUd10aCLFbMCyYwtIAFwQgfPoUi', NULL, '2025-07-17 04:22:23', '2025-07-17 04:22:23', 'anggota'),
(509, 'Anggota 508', 'anggota508@gmail.com', NULL, '$2y$12$IGkHgC40CuIFbFPbx6.4VOzF8Ps8SPzS5pgACrgEQhk6X5xjCRoJS', NULL, '2025-07-17 04:22:23', '2025-07-17 04:22:23', 'anggota'),
(510, 'Anggota 509', 'anggota509@gmail.com', NULL, '$2y$12$dSzXKVcHFouTJNFUMRAwm.MmrmwI7PaCG6ikilJxpQMo7zWy9J75O', NULL, '2025-07-17 04:22:24', '2025-07-17 04:22:24', 'anggota'),
(511, 'Anggota 510', 'anggota510@gmail.com', NULL, '$2y$12$lZ3dlm0ynaM0f5eUBC9mK.1Kx0wLiI6UYlv2qldlYS6qzGJvhJxcu', NULL, '2025-07-17 04:22:24', '2025-07-17 04:22:24', 'anggota'),
(512, 'Anggota 511', 'anggota511@gmail.com', NULL, '$2y$12$vT4iUmxbpEIwQPU7MpP5Hen1JzrswgtqkN6yAFOwg8qkovv1AHWj.', NULL, '2025-07-17 04:22:24', '2025-07-17 04:22:24', 'anggota'),
(513, 'Anggota 512', 'anggota512@gmail.com', NULL, '$2y$12$Q8qipReJOq2n7UTsLOGWOeTUTPKmbU3fj8ld6NuEPtOiCDJLtImN2', NULL, '2025-07-17 04:22:25', '2025-07-17 04:22:25', 'anggota'),
(514, 'Anggota 513', 'anggota513@gmail.com', NULL, '$2y$12$/alLHkBdXeXt8ZhLCaL5hOT2ej1W9T17cueA1XvtMK2Atvt0V7gy.', NULL, '2025-07-17 04:22:25', '2025-07-17 04:22:25', 'anggota'),
(515, 'Anggota 514', 'anggota514@gmail.com', NULL, '$2y$12$qUAoN7MGxOoVcHzG/k4e4OTZC/xrpGujL6h1rsWokwYzqFG5kgoI.', NULL, '2025-07-17 04:22:25', '2025-07-17 04:22:25', 'anggota'),
(516, 'Anggota 515', 'anggota515@gmail.com', NULL, '$2y$12$NncIjSPcX1iCz3uRdDftaOf6KNTUT1l3Aa/k96YQiq9qmnDN5VXgy', NULL, '2025-07-17 04:22:26', '2025-07-17 04:22:26', 'anggota'),
(517, 'Anggota 516', 'anggota516@gmail.com', NULL, '$2y$12$UGwPNArVFynTNxBH99h52OcpvsGruhY75tDShX70TeDxZpNUsyuci', NULL, '2025-07-17 04:22:26', '2025-07-17 04:22:26', 'anggota'),
(518, 'Anggota 517', 'anggota517@gmail.com', NULL, '$2y$12$EZ2.rYTZL3wCQFDr86sPeOcemUmgVjZVPDj9Y5GvIp1gdtwvfTpE2', NULL, '2025-07-17 04:22:26', '2025-07-17 04:22:26', 'anggota'),
(519, 'Anggota 518', 'anggota518@gmail.com', NULL, '$2y$12$LhbPNa3t/xNq6lzkB2nIWuEluRI2T0TUHhVGBNoKsXzW7laRgLS6S', NULL, '2025-07-17 04:22:26', '2025-07-17 04:22:26', 'anggota'),
(520, 'Anggota 519', 'anggota519@gmail.com', NULL, '$2y$12$rYKb8Mh7cFLSDwlPIzl/MeYqH.azqf/QPtNoaoM1jUb8vH17niAxC', NULL, '2025-07-17 04:22:27', '2025-07-17 04:22:27', 'anggota'),
(521, 'Anggota 520', 'anggota520@gmail.com', NULL, '$2y$12$btuyuDG.qdIMs51ptSAVY.0yGWKJSzl0G8eCUDI1RdaNnaZFulhMm', NULL, '2025-07-17 04:22:27', '2025-07-17 04:22:27', 'anggota'),
(522, 'Anggota 521', 'anggota521@gmail.com', NULL, '$2y$12$dmFuapsJP4su2nPOs1sRLeeOAWIEMYNGskk/tXiuimDUl5ATrYI6m', NULL, '2025-07-17 04:22:27', '2025-07-17 04:22:27', 'anggota'),
(523, 'Anggota 522', 'anggota522@gmail.com', NULL, '$2y$12$HIRremioFpdMLfmPVWKTHOnTsRy.2skH.CoXMhh7g2wubI/enmvw2', NULL, '2025-07-17 04:22:28', '2025-07-17 04:22:28', 'anggota'),
(524, 'Anggota 523', 'anggota523@gmail.com', NULL, '$2y$12$ozEdEDcuyTVNaiNwqvWQ8eb31.83oTR3ru5K7pqo.T.0ZPbDgVzmi', NULL, '2025-07-17 04:22:28', '2025-07-17 04:22:28', 'anggota'),
(525, 'Anggota 524', 'anggota524@gmail.com', NULL, '$2y$12$4r9euUwgNJVStOVpmdAW5erkdDaAOFZ0.4vJI5KMqO.9gEFxLdQ3K', NULL, '2025-07-17 04:22:28', '2025-07-17 04:22:28', 'anggota'),
(526, 'Anggota 525', 'anggota525@gmail.com', NULL, '$2y$12$1IhXv4hambCxjVown5Sxi.isMZUOk.4LDe4KTWhhOCey2ruey52em', NULL, '2025-07-17 04:22:29', '2025-07-17 04:22:29', 'anggota'),
(527, 'Anggota 526', 'anggota526@gmail.com', NULL, '$2y$12$28N7G4LDNhOeQLGl4bzFW.YECmmlyrRdU6boc0umVFHilElJmZds2', NULL, '2025-07-17 04:22:29', '2025-07-17 04:22:29', 'anggota'),
(528, 'Anggota 527', 'anggota527@gmail.com', NULL, '$2y$12$.5RJqeELG.p1LwxSY45W3uv.NSNps8Cfkh.hYcOO1TML/jt5hCUpC', NULL, '2025-07-17 04:22:29', '2025-07-17 04:22:29', 'anggota'),
(529, 'Anggota 528', 'anggota528@gmail.com', NULL, '$2y$12$zezhqfTaG4eUoPpUE073s.sYioJNYDhlGBg.LvFIANwWn0lBnxCu.', NULL, '2025-07-17 04:22:30', '2025-07-17 04:22:30', 'anggota'),
(530, 'Anggota 529', 'anggota529@gmail.com', NULL, '$2y$12$S2XXyW1YktA7T0Z1gtgpDuNt1BCEfO5qlGCkGMTU5V93x599XUuG6', NULL, '2025-07-17 04:22:30', '2025-07-17 04:22:30', 'anggota'),
(531, 'Anggota 530', 'anggota530@gmail.com', NULL, '$2y$12$G4PrjJ3V32PL9VTrWlMwVuwJH0hJ6Ps0pn570Kgq4anwrF.r7KRRW', NULL, '2025-07-17 04:22:30', '2025-07-17 04:22:30', 'anggota'),
(532, 'Anggota 531', 'anggota531@gmail.com', NULL, '$2y$12$XIFznb1mjfLgNedEg39gD.S7M0ZHSc7GPSrNPZpJ339N/nzB5jdR6', NULL, '2025-07-17 04:22:30', '2025-07-17 04:22:30', 'anggota'),
(533, 'Anggota 532', 'anggota532@gmail.com', NULL, '$2y$12$aETltBmxOyPxrJGK4bMf7ey.es9Nv2tuJMAkmgFbg5jCDsgL9Ku0m', NULL, '2025-07-17 04:22:31', '2025-07-17 04:22:31', 'anggota'),
(534, 'Anggota 533', 'anggota533@gmail.com', NULL, '$2y$12$BfDuVagz5vMBV0mF5NVlR.kzmiTLMh9NTB3soQmhnM.oiBz/I/dji', NULL, '2025-07-17 04:22:31', '2025-07-17 04:22:31', 'anggota'),
(535, 'Anggota 534', 'anggota534@gmail.com', NULL, '$2y$12$1IcL5NLlFbpjofE1GqpRSOVdGOd49OzGbfZbBipzNCwAIScgmhC1u', NULL, '2025-07-17 04:22:31', '2025-07-17 04:22:31', 'anggota'),
(536, 'Anggota 535', 'anggota535@gmail.com', NULL, '$2y$12$RehZyh7izj6a5Js/cbJntOgTVNC.nX6.ri1QoGzUVdXQrLEmH8mmi', NULL, '2025-07-17 04:22:32', '2025-07-17 04:22:32', 'anggota'),
(537, 'Anggota 536', 'anggota536@gmail.com', NULL, '$2y$12$Lg3iG6qrUcjEDAI172jdFO4eehBkQA1eJ8qqutsijwMkfUQUgTGmK', NULL, '2025-07-17 04:22:32', '2025-07-17 04:22:32', 'anggota'),
(538, 'Anggota 537', 'anggota537@gmail.com', NULL, '$2y$12$4U3WiAs4/M5.tYYpsBeNg.6CGRFRpPy3jPHfSiLydSH/o4Y7Xtoiq', NULL, '2025-07-17 04:22:32', '2025-07-17 04:22:32', 'anggota'),
(539, 'Anggota 538', 'anggota538@gmail.com', NULL, '$2y$12$XYLowaVaEZE7L3paal8Yc.OJJULRBzX6wNokW4AVwhpmKlJPY6u/i', NULL, '2025-07-17 04:22:33', '2025-07-17 04:22:33', 'anggota'),
(540, 'Anggota 539', 'anggota539@gmail.com', NULL, '$2y$12$FUplnvqYqSKg.xfRzQ8cPOZe5x5YD.2ZZOTA6R6/KuCIUwmniZDcq', NULL, '2025-07-17 04:22:33', '2025-07-17 04:22:33', 'anggota'),
(541, 'Anggota 540', 'anggota540@gmail.com', NULL, '$2y$12$QulwEidkw5YuNv8W7WwlEOLUJCgm9pAIWeFth.24tv9CBPqZf89n6', NULL, '2025-07-17 04:22:33', '2025-07-17 04:22:33', 'anggota'),
(542, 'Anggota 541', 'anggota541@gmail.com', NULL, '$2y$12$W4avkz84INxcFKI8BsWzTeQYvnoWnR3Zl0lezQ2vwzPK8hWwxLcx6', NULL, '2025-07-17 04:22:33', '2025-07-17 04:22:33', 'anggota'),
(543, 'Anggota 542', 'anggota542@gmail.com', NULL, '$2y$12$UdJaZZHP/swpyPNbMUVxE.G2LrtsC1akwiOMgGsCs.zADvDFZNNGW', NULL, '2025-07-17 04:22:34', '2025-07-17 04:22:34', 'anggota'),
(544, 'Anggota 543', 'anggota543@gmail.com', NULL, '$2y$12$IfeWZlP3yAimpf2HAB/OIOIQgAQ8sVBVlzzgceivideuG.3App.6O', NULL, '2025-07-17 04:22:34', '2025-07-17 04:22:34', 'anggota'),
(545, 'Anggota 544', 'anggota544@gmail.com', NULL, '$2y$12$aJI3RO1323M0nSmQSY0kxuZsFMf8pfVzQU.1UKVjQW1zc1UwPGSaO', NULL, '2025-07-17 04:22:34', '2025-07-17 04:22:34', 'anggota'),
(546, 'Anggota 545', 'anggota545@gmail.com', NULL, '$2y$12$CUFBg7Ei3COVup./ZVbi7ONGHjsbNIv9OG01MdaeDREBQsDMt1xFy', NULL, '2025-07-17 04:22:35', '2025-07-17 04:22:35', 'anggota'),
(547, 'Anggota 546', 'anggota546@gmail.com', NULL, '$2y$12$8lILxj2y18zSLoHCBzmhmOKJxSYQejBgXXmu7tyIdoNziObXfuVOu', NULL, '2025-07-17 04:22:35', '2025-07-17 04:22:35', 'anggota'),
(548, 'Anggota 547', 'anggota547@gmail.com', NULL, '$2y$12$gKrdd8m//kfTuaUEasuUGOu9JqkGZ0v165ucVQsUOsBnIu/rufO12', NULL, '2025-07-17 04:22:35', '2025-07-17 04:22:35', 'anggota'),
(549, 'Anggota 548', 'anggota548@gmail.com', NULL, '$2y$12$jNNhLhrqCzVZhVV/fFdOq.AwCdiVEw5jZH7enEJva0hjql/Oq3kSW', NULL, '2025-07-17 04:22:36', '2025-07-17 04:22:36', 'anggota'),
(550, 'Anggota 549', 'anggota549@gmail.com', NULL, '$2y$12$ztXicoupev138Ge6W7/fL.fW/aVd2uufUZ5G8CWlgjADaVCSD/8kK', NULL, '2025-07-17 04:22:36', '2025-07-17 04:22:36', 'anggota'),
(551, 'Anggota 550', 'anggota550@gmail.com', NULL, '$2y$12$S3BpbYB3CFzhdmxvw/6ALOIqUuUMgdmFTFG1RHUvZdeChUVo4m.cW', NULL, '2025-07-17 04:22:36', '2025-07-17 04:22:36', 'anggota'),
(552, 'Anggota 551', 'anggota551@gmail.com', NULL, '$2y$12$MWia2j4h8CJHT9j9aeoumu0UoZu/RQGCZNh/Q0M0AfgE4a2W8RpVu', NULL, '2025-07-17 04:22:37', '2025-07-17 04:22:37', 'anggota'),
(553, 'Anggota 552', 'anggota552@gmail.com', NULL, '$2y$12$eG./059OaemwNGLH90PLn.9KEjJNo39wb.L2uhO5js01XMFCwYXrq', NULL, '2025-07-17 04:22:37', '2025-07-17 04:22:37', 'anggota'),
(554, 'Anggota 553', 'anggota553@gmail.com', NULL, '$2y$12$2e7vaziVqpH86MhpmOlOx.kFF4i245n/h38JwvOcgbxoPgT0pgQ4q', NULL, '2025-07-17 04:22:37', '2025-07-17 04:22:37', 'anggota'),
(555, 'Anggota 554', 'anggota554@gmail.com', NULL, '$2y$12$Szt/rpLK.s1QjLub3fjS1ePazYhqw39OphwYCcyRCohx3vRJw4CPC', NULL, '2025-07-17 04:22:37', '2025-07-17 04:22:37', 'anggota'),
(556, 'Anggota 555', 'anggota555@gmail.com', NULL, '$2y$12$ngb.35gjuwSqNES/OA135.shMw0PVQwCxsViihAo8SaM3kpc5i1HO', NULL, '2025-07-17 04:22:38', '2025-07-17 04:22:38', 'anggota'),
(557, 'Anggota 556', 'anggota556@gmail.com', NULL, '$2y$12$nYa7lz3MWmmC45nngFMq7.O.KTMuprIC0tl4kDTKONd8/oothUbKi', NULL, '2025-07-17 04:22:38', '2025-07-17 04:22:38', 'anggota'),
(558, 'Anggota 557', 'anggota557@gmail.com', NULL, '$2y$12$JN.FFLbEOTyGU5vdNxUD/eJH2bEH1X0WDaSRWMbp0l/9d2DRwP3q.', NULL, '2025-07-17 04:22:38', '2025-07-17 04:22:38', 'anggota'),
(559, 'Anggota 558', 'anggota558@gmail.com', NULL, '$2y$12$PHkEW88l.QI0J7SBlnyE5.vcv5wde/pJfFRE1ZHS.KJU0q2O1BBDu', NULL, '2025-07-17 04:22:39', '2025-07-17 04:22:39', 'anggota'),
(560, 'Anggota 559', 'anggota559@gmail.com', NULL, '$2y$12$OmzQEytia15MIDlHFSImG.I3mr.cXrgKCKpOcab.k0NfEFAbzqfzy', NULL, '2025-07-17 04:22:39', '2025-07-17 04:22:39', 'anggota'),
(561, 'Anggota 560', 'anggota560@gmail.com', NULL, '$2y$12$TffygdsnR4nXVMkBejcBO.eKPM2Vixk40h7xs8yHq49D41fLI6zfq', NULL, '2025-07-17 04:22:39', '2025-07-17 04:22:39', 'anggota'),
(562, 'Anggota 561', 'anggota561@gmail.com', NULL, '$2y$12$Vy3.KfjBzY0s0x80RuTJOONg1FSuVKrCI2kGWdJTecEE1jrDtSmse', NULL, '2025-07-17 04:22:40', '2025-07-17 04:22:40', 'anggota'),
(563, 'Anggota 562', 'anggota562@gmail.com', NULL, '$2y$12$vfjP887GN960vbHsQh73yuzaM4Wrx22DOgb/8PC4KX1O7XGVAEuCa', NULL, '2025-07-17 04:22:40', '2025-07-17 04:22:40', 'anggota'),
(564, 'Anggota 563', 'anggota563@gmail.com', NULL, '$2y$12$3UbAo2lNzHWJT1s42kE/Wu9OEV3KTw8n6l1xwjZoWZS7.J8EBNgme', NULL, '2025-07-17 04:22:40', '2025-07-17 04:22:40', 'anggota');
INSERT INTO `users` (`id`, `name`, `email`, `email_verified_at`, `password`, `remember_token`, `created_at`, `updated_at`, `role`) VALUES
(565, 'Anggota 564', 'anggota564@gmail.com', NULL, '$2y$12$nswJfquvzwnupqCe2SnGf.wZrxzqkv4.J9U5OzNGVZZ4bjY0IPQjm', NULL, '2025-07-17 04:22:41', '2025-07-17 04:22:41', 'anggota'),
(566, 'Anggota 565', 'anggota565@gmail.com', NULL, '$2y$12$ahjS4Px57CmOgBQ1Ue3qi.JYg.77S2YPCB/mxP897a0CtGIbBDgSW', NULL, '2025-07-17 04:22:41', '2025-07-17 04:22:41', 'anggota'),
(567, 'Anggota 566', 'anggota566@gmail.com', NULL, '$2y$12$2IIS9AnWnXXFy7kC8hm5BeMsne93hW/0ti/4r1Ch02FSTCIUEzA4S', NULL, '2025-07-17 04:22:41', '2025-07-17 04:22:41', 'anggota'),
(568, 'Anggota 567', 'anggota567@gmail.com', NULL, '$2y$12$FwiRxSsR1FJGfdtzy4e4l.wpItyDQrog2Ei/.phCB8Nc208WkSllq', NULL, '2025-07-17 04:22:41', '2025-07-17 04:22:41', 'anggota'),
(569, 'Anggota 568', 'anggota568@gmail.com', NULL, '$2y$12$N31nPRPZA8z/8.DY63OaW.0n56WT7NlO9dSMavZq5iwb4pRBWG0Sm', NULL, '2025-07-17 04:22:42', '2025-07-17 04:22:42', 'anggota'),
(570, 'Anggota 569', 'anggota569@gmail.com', NULL, '$2y$12$D/UchVQC5VjSuLt7YuOJCe6VeHO66S9aSX8UDD8yUZws.YLsfxkc2', NULL, '2025-07-17 04:22:42', '2025-07-17 04:22:42', 'anggota'),
(571, 'Anggota 570', 'anggota570@gmail.com', NULL, '$2y$12$C0B1G0SuKZCPGbjX4RLNoe6I4DHChNkK/QoqnBd/5hIcrEILiunl2', NULL, '2025-07-17 04:22:42', '2025-07-17 04:22:42', 'anggota'),
(572, 'Anggota 571', 'anggota571@gmail.com', NULL, '$2y$12$rfyYVkZbPLf8tdu3KaH2UeEP9JMKgyu.s0fNcdmxMCz3N9zjFxRvG', NULL, '2025-07-17 04:22:43', '2025-07-17 04:22:43', 'anggota'),
(573, 'Anggota 572', 'anggota572@gmail.com', NULL, '$2y$12$F7qQYsC1IK5j9jSDJ9o8ZuuYgLM2y7e2KYfBnhxCc3UdUm.chWPse', NULL, '2025-07-17 04:22:43', '2025-07-17 04:22:43', 'anggota'),
(574, 'Anggota 573', 'anggota573@gmail.com', NULL, '$2y$12$2G54rnChXGdytGEtNpmjluolbGVX8E2q8Fc1ISLpgTBuXNh9msbrC', NULL, '2025-07-17 04:22:43', '2025-07-17 04:22:43', 'anggota'),
(575, 'Anggota 574', 'anggota574@gmail.com', NULL, '$2y$12$NMtVrLmnsN7HRig23TfsLODSaCyctQenBw3lDT1C2AGewml0749bK', NULL, '2025-07-17 04:22:44', '2025-07-17 04:22:44', 'anggota'),
(576, 'Anggota 575', 'anggota575@gmail.com', NULL, '$2y$12$CnzlB5RsQVFiVeE3x3BxDOAlt4gYJ82VxlDBFFT8U05RAUju5VCXG', NULL, '2025-07-17 04:22:44', '2025-07-17 04:22:44', 'anggota'),
(577, 'Anggota 576', 'anggota576@gmail.com', NULL, '$2y$12$WCWFhUqeuTn24Fn.tXGgOOVcd6wVTjjupQQEGICR6SUORjYhRecF2', NULL, '2025-07-17 04:22:44', '2025-07-17 04:22:44', 'anggota'),
(578, 'Anggota 577', 'anggota577@gmail.com', NULL, '$2y$12$IqJhgyv3AJGEaoQdJnEJM.IkcU.ZHtEY42w799WWyQuRpzKfa29uy', NULL, '2025-07-17 04:22:44', '2025-07-17 04:22:44', 'anggota'),
(579, 'Anggota 578', 'anggota578@gmail.com', NULL, '$2y$12$WMobfHyjuxJzddd2eoDnOOxUHFK2Z/PiuO.Nvxa5cRV8DQVF1hP8K', NULL, '2025-07-17 04:22:45', '2025-07-17 04:22:45', 'anggota'),
(580, 'Anggota 579', 'anggota579@gmail.com', NULL, '$2y$12$ztbzARBKvUdXOnl8rWjZhuh/mNQzop1DUh6gX/TIBIWbuDZA9.LAC', NULL, '2025-07-17 04:22:45', '2025-07-17 04:22:45', 'anggota'),
(581, 'Anggota 580', 'anggota580@gmail.com', NULL, '$2y$12$/DxRGja2UqJ0PWMDfcpLguwkQnGgx1Z4LkneyRdtnTVPQovLRcfPi', NULL, '2025-07-17 04:22:45', '2025-07-17 04:22:45', 'anggota'),
(582, 'Anggota 581', 'anggota581@gmail.com', NULL, '$2y$12$WXLxY40XbVDbPS34ZZ3Z7.9ETDXe2Or.lF8/CicX.D4aeX2.d5r0y', NULL, '2025-07-17 04:22:46', '2025-07-17 04:22:46', 'anggota'),
(583, 'Anggota 582', 'anggota582@gmail.com', NULL, '$2y$12$IgUAsZYf0xF6s04HiSh3kOn6beOc/R5gYelKOdzDphsug/EfVRbWG', NULL, '2025-07-17 04:22:46', '2025-07-17 04:22:46', 'anggota'),
(584, 'Anggota 583', 'anggota583@gmail.com', NULL, '$2y$12$G348gdZJYp3nJ5MVX.0Wke2AQQQ9Dm6uVW7SGtTlmpeQGmPqnBzGK', NULL, '2025-07-17 04:22:46', '2025-07-17 04:22:46', 'anggota'),
(585, 'Anggota 584', 'anggota584@gmail.com', NULL, '$2y$12$rYMb7GkJexqeGlPWYfPATO7ajSj4VQoJduZq/Hk0QIcjMOY.Wedry', NULL, '2025-07-17 04:22:47', '2025-07-17 04:22:47', 'anggota'),
(586, 'Anggota 585', 'anggota585@gmail.com', NULL, '$2y$12$KgenL86rkb0Fd4jH2pGRiORpZ4LBMDEunbQUONO0kDWhyrEBdf9hS', NULL, '2025-07-17 04:22:47', '2025-07-17 04:22:47', 'anggota'),
(587, 'Anggota 586', 'anggota586@gmail.com', NULL, '$2y$12$ucIx8UAqJCGJn8aMBEL2J.tmqqldEek4dj39fR3GK760cEiWU2tfi', NULL, '2025-07-17 04:22:47', '2025-07-17 04:22:47', 'anggota'),
(588, 'Anggota 587', 'anggota587@gmail.com', NULL, '$2y$12$lTfLnoxP0EkrhiDCr2HtU.Ih.76pf2MPqn0.O.Ob1YV9Cvp1631qi', NULL, '2025-07-17 04:22:47', '2025-07-17 04:22:47', 'anggota'),
(589, 'Anggota 588', 'anggota588@gmail.com', NULL, '$2y$12$C//Du1ruU013Kv10L72Ry.bd3ZSw/Csqg/4DHlX7EayP96akMqfCW', NULL, '2025-07-17 04:22:48', '2025-07-17 04:22:48', 'anggota'),
(590, 'Anggota 589', 'anggota589@gmail.com', NULL, '$2y$12$xq4d/Kn2W5z4.NwTSvx/vO.0iRhAA.C5EU./m2rstak.jKlzz7diG', NULL, '2025-07-17 04:22:48', '2025-07-17 04:22:48', 'anggota'),
(591, 'Anggota 590', 'anggota590@gmail.com', NULL, '$2y$12$Ay5u2EoQ03QydxfLicTWNeH2GNLqq0NNjmCPbI4ouxJAkQNhJYMmC', NULL, '2025-07-17 04:22:48', '2025-07-17 04:22:48', 'anggota'),
(592, 'Anggota 591', 'anggota591@gmail.com', NULL, '$2y$12$DuPtEWbbAejB.nEoQW5IEujUaOrM29wo7yX4Ge2UlEbF7mqc0oCiG', NULL, '2025-07-17 04:22:49', '2025-07-17 04:22:49', 'anggota'),
(593, 'Anggota 592', 'anggota592@gmail.com', NULL, '$2y$12$ALWZXkOm6kVu5uIIQt2AVOfIVnzyIdOY8uSnndIyS2zIVz6qCEepK', NULL, '2025-07-17 04:22:49', '2025-07-17 04:22:49', 'anggota'),
(594, 'Anggota 593', 'anggota593@gmail.com', NULL, '$2y$12$oKJlUWAI21BAPmy5vPGEwuwOj4SyE3QPXdx9hgpNZpMJtQe4QL4UW', NULL, '2025-07-17 04:22:49', '2025-07-17 04:22:49', 'anggota'),
(595, 'Anggota 594', 'anggota594@gmail.com', NULL, '$2y$12$Mp6LsQ8ei5uLUxuVKg2qWOSvElT0XxO1CXD0rJkk1GnjCXYWJEtmW', NULL, '2025-07-17 04:22:50', '2025-07-17 04:22:50', 'anggota'),
(596, 'Anggota 595', 'anggota595@gmail.com', NULL, '$2y$12$z4YMmjS1RnB3wSQwb.06l.H2.2lS8lWi2CwK0PNLAuZxU8vOgtG0m', NULL, '2025-07-17 04:22:50', '2025-07-17 04:22:50', 'anggota'),
(597, 'Anggota 596', 'anggota596@gmail.com', NULL, '$2y$12$14twAYQs1V/4UEmrzakM4.6oCDHRlyCzlbtDtK475KPr5nw1XPYju', NULL, '2025-07-17 04:22:50', '2025-07-17 04:22:50', 'anggota'),
(598, 'Anggota 597', 'anggota597@gmail.com', NULL, '$2y$12$AQ7j76I6LnqCvVU6SKeB.eX9QvDDXgirebVkNTbV1QL3BUorg2MZ6', NULL, '2025-07-17 04:22:51', '2025-07-17 04:22:51', 'anggota'),
(599, 'Anggota 598', 'anggota598@gmail.com', NULL, '$2y$12$lpSGok.YMwEzGuP6EseuhuaPWuRuQBxhhKh9GPcpPH0JbzExVziD2', NULL, '2025-07-17 04:22:51', '2025-07-17 04:22:51', 'anggota'),
(600, 'Anggota 599', 'anggota599@gmail.com', NULL, '$2y$12$5dvjXBHBDvHhOHGenTEpZe7Aim47sE79.qeE2JHNM.TKoPwb7YtKa', NULL, '2025-07-17 04:22:51', '2025-07-17 04:22:51', 'anggota'),
(601, 'Anggota 600', 'anggota600@gmail.com', NULL, '$2y$12$WvkUycaSawlOnraPeGoWcOX4BNrp2GK7gxwoPhCBYvTJOdYYzDIu6', NULL, '2025-07-17 04:22:51', '2025-07-17 04:22:51', 'anggota'),
(602, 'Anggota 601', 'anggota601@gmail.com', NULL, '$2y$12$8U/wGx5SloY8s1iW9g93jO.ijKBmsIydIrMue9sXZfnvEAB67SApq', NULL, '2025-07-17 04:22:52', '2025-07-17 04:22:52', 'anggota'),
(603, 'Anggota 602', 'anggota602@gmail.com', NULL, '$2y$12$WiBWOjqYSoBtYu.C/u6VVe4rtxWBv5ieKSOfkBucWzsb3slyiO.bq', NULL, '2025-07-17 04:22:52', '2025-07-17 04:22:52', 'anggota'),
(604, 'Anggota 603', 'anggota603@gmail.com', NULL, '$2y$12$CDhWe98E/iP6WQ4ViJY1/.XjAlMQEucgZs19lp/3C4pXLMZc89N8K', NULL, '2025-07-17 04:22:52', '2025-07-17 04:22:52', 'anggota'),
(605, 'Anggota 604', 'anggota604@gmail.com', NULL, '$2y$12$MAqTaDs/Vc8vkStfepWLSepYw.XbVOrTiJj8j.yHeP.n7zP1MHP9.', NULL, '2025-07-17 04:22:53', '2025-07-17 04:22:53', 'anggota'),
(606, 'Anggota 605', 'anggota605@gmail.com', NULL, '$2y$12$1fDwouVRuSHEeqHhWjpXg.exg27kjOvGIV40c2vjdADDrshn3p58q', NULL, '2025-07-17 04:22:53', '2025-07-17 04:22:53', 'anggota'),
(607, 'Anggota 606', 'anggota606@gmail.com', NULL, '$2y$12$y.oWKxcqZ0o1jQ3R2q51t.gT04.lmQDCOhIJ8gOHowMkXjYA1kzgC', NULL, '2025-07-17 04:22:53', '2025-07-17 04:22:53', 'anggota'),
(608, 'Anggota 607', 'anggota607@gmail.com', NULL, '$2y$12$kQLFXQ61HDxPIVDakPZFB.JBdR41.tDvGT3l3TXWrdG8O8LiXsDnW', NULL, '2025-07-17 04:22:54', '2025-07-17 04:22:54', 'anggota'),
(609, 'Anggota 608', 'anggota608@gmail.com', NULL, '$2y$12$qzPr32CHySzOkOTsFYxLFO.m.BDQ29jLzpsDfA.i73ua3Hc/XZC6.', NULL, '2025-07-17 04:22:54', '2025-07-17 04:22:54', 'anggota'),
(610, 'Anggota 609', 'anggota609@gmail.com', NULL, '$2y$12$RxvxV1ricSFjU5bbpjS8vekdTdSiVcz5q06VYkW31n4YTzHgDUIpu', NULL, '2025-07-17 04:22:54', '2025-07-17 04:22:54', 'anggota'),
(611, 'Anggota 610', 'anggota610@gmail.com', NULL, '$2y$12$NBBngcVFK2thfPFpmeE1iepsqJneQbIAYN903yG.hr9DhJuwcSZ6O', NULL, '2025-07-17 04:22:54', '2025-07-17 04:22:54', 'anggota'),
(612, 'Anggota 611', 'anggota611@gmail.com', NULL, '$2y$12$oSwSuu/sHNTOF0VneLP4heeYDSdVjy1hBuT79N61u1F9SvdJ7Juq.', NULL, '2025-07-17 04:22:55', '2025-07-17 04:22:55', 'anggota'),
(613, 'Anggota 612', 'anggota612@gmail.com', NULL, '$2y$12$P0ZiD7UiVodyO57iwb29BuP6vWK4etux8/2Ve2CZ7tAu7IFaeAR7G', NULL, '2025-07-17 04:22:55', '2025-07-17 04:22:55', 'anggota'),
(614, 'Anggota 613', 'anggota613@gmail.com', NULL, '$2y$12$UsDWjgT305mmGEjqLzqqN.wGUhsv58S06Gj2WpNVKZe2qfiO9PGUO', NULL, '2025-07-17 04:22:55', '2025-07-17 04:22:55', 'anggota'),
(615, 'Anggota 614', 'anggota614@gmail.com', NULL, '$2y$12$t2d0yGcCuYgkyWjD.2ru1.ancyNHZErorV3mooCmDg13fd2RTfeLu', NULL, '2025-07-17 04:22:56', '2025-07-17 04:22:56', 'anggota'),
(616, 'Anggota 615', 'anggota615@gmail.com', NULL, '$2y$12$SNVODsj.SzjrpLSuEcHcTe2mZBKApH2AOeJUCOLenzQNQ9.SY2aN6', NULL, '2025-07-17 04:22:56', '2025-07-17 04:22:56', 'anggota'),
(617, 'Anggota 616', 'anggota616@gmail.com', NULL, '$2y$12$oyZ2zpsMYtyj/Au7.w5z/ew5lFP.T34wnNP90BEhDMOqmka92oLLm', NULL, '2025-07-17 04:22:56', '2025-07-17 04:22:56', 'anggota'),
(618, 'Anggota 617', 'anggota617@gmail.com', NULL, '$2y$12$ryfTxb/PhxtHYtvPYpQqJ.eB3l6mXBPvdpa1zq1cmSNGUB4hxLbFW', NULL, '2025-07-17 04:22:57', '2025-07-17 04:22:57', 'anggota'),
(619, 'Anggota 618', 'anggota618@gmail.com', NULL, '$2y$12$GpUA/wZbLuzoKe1jO58vAev3GABsccTBhLkj6EYu6mmKjFPiSHzE6', NULL, '2025-07-17 04:22:57', '2025-07-17 04:22:57', 'anggota'),
(620, 'Anggota 619', 'anggota619@gmail.com', NULL, '$2y$12$2xr63pI7QVzgPM8S2IViH.RyH1y.qqEVSSdsnVjGkFMPw0pPTGkKG', NULL, '2025-07-17 04:22:57', '2025-07-17 04:22:57', 'anggota'),
(621, 'Anggota 620', 'anggota620@gmail.com', NULL, '$2y$12$2vvTkc3qjrijnr72d5uCOOreIgBtjy.T.VDmOXqYGqnlavRTsP0YO', NULL, '2025-07-17 04:22:58', '2025-07-17 04:22:58', 'anggota'),
(622, 'Anggota 621', 'anggota621@gmail.com', NULL, '$2y$12$ckqkbQJ0wEnPB9ffbaYoaOhH20bHYQgQDbE/BuR.Y5equ6OXP/aO6', NULL, '2025-07-17 04:22:58', '2025-07-17 04:22:58', 'anggota'),
(623, 'Anggota 622', 'anggota622@gmail.com', NULL, '$2y$12$PYbg/X3cMnyXs5EiEPYmiO10/JQJFeTZPBWmZffaWs/EmM4MlcPji', NULL, '2025-07-17 04:22:58', '2025-07-17 04:22:58', 'anggota'),
(624, 'Anggota 623', 'anggota623@gmail.com', NULL, '$2y$12$MuQwP5vJZvsij09ER1adz.17HefsydFE8A5V.AswX0MWKeKmdpmsC', NULL, '2025-07-17 04:22:58', '2025-07-17 04:22:58', 'anggota'),
(625, 'Anggota 624', 'anggota624@gmail.com', NULL, '$2y$12$oUCApVwjyTTy96d/Kh59zePkEdcoLNUwSM3rHn1rWiVdu7yryO/ei', NULL, '2025-07-17 04:22:59', '2025-07-17 04:22:59', 'anggota'),
(626, 'Anggota 625', 'anggota625@gmail.com', NULL, '$2y$12$kkjmbDxTCRDxudAp6OmpZueknf.tSF5IHi02ZJcxZshgcUcx7ffhq', NULL, '2025-07-17 04:22:59', '2025-07-17 04:22:59', 'anggota'),
(627, 'Anggota 626', 'anggota626@gmail.com', NULL, '$2y$12$Tr/y0PPOhpDLbu7DQWJtZ.Zg78i9R7.j4MpmWGeYfiu33kNh5HEqO', NULL, '2025-07-17 04:22:59', '2025-07-17 04:22:59', 'anggota'),
(628, 'Anggota 627', 'anggota627@gmail.com', NULL, '$2y$12$BehgaTycY.ieGljSiRk3i.qj2EBdgRA2IGDbJzcTjhggCntmP3Lai', NULL, '2025-07-17 04:23:00', '2025-07-17 04:23:00', 'anggota'),
(629, 'Anggota 628', 'anggota628@gmail.com', NULL, '$2y$12$rza.yIHdamw4VhK3XbeQMOW5FKYVN8ovxHSI2Q7CiAVd1CqrrAe8y', NULL, '2025-07-17 04:23:00', '2025-07-17 04:23:00', 'anggota'),
(630, 'Anggota 629', 'anggota629@gmail.com', NULL, '$2y$12$BSiEwfHXawFwvs6coZoDZuF5J/w2SfEXO5prBU47BROAgc4Zo0jIG', NULL, '2025-07-17 04:23:00', '2025-07-17 04:23:00', 'anggota'),
(631, 'Anggota 630', 'anggota630@gmail.com', NULL, '$2y$12$Uu5uxYPNf2qKK0CMB0Iid.4s5.oHXT2gAtvgWOSgxmXzo43hwDpVS', NULL, '2025-07-17 04:23:01', '2025-07-17 04:23:01', 'anggota'),
(632, 'Anggota 631', 'anggota631@gmail.com', NULL, '$2y$12$R2l17E7M0/4.xbcJyzk21uRp/jB/RaxjOAV1d/ls7r9Kn3KPCRG.G', NULL, '2025-07-17 04:23:01', '2025-07-17 04:23:01', 'anggota'),
(633, 'Anggota 632', 'anggota632@gmail.com', NULL, '$2y$12$LK91SNFjQcjg8i7bXWcIyOY8q4mCXHqvrbuiU.Cl8xoZvhWZXcv/O', NULL, '2025-07-17 04:23:01', '2025-07-17 04:23:01', 'anggota'),
(634, 'Anggota 633', 'anggota633@gmail.com', NULL, '$2y$12$SBGFVbU1L.TyzfOZJzhPGeG9Di5XW1NCMR6YWzmscbzOerm2FsCSO', NULL, '2025-07-17 04:23:01', '2025-07-17 04:23:01', 'anggota'),
(635, 'Anggota 634', 'anggota634@gmail.com', NULL, '$2y$12$8..kB0dtOo5960QoVZDWQObkIF5xxnDbzK4UnuL.tm5CitmmpxoKq', NULL, '2025-07-17 04:23:02', '2025-07-17 04:23:02', 'anggota'),
(636, 'Anggota 635', 'anggota635@gmail.com', NULL, '$2y$12$HCeBaI9F/AHDdNu4O5TidOBc7Tz96H8hHyrOA5axXUcDqsD55bhe2', NULL, '2025-07-17 04:23:02', '2025-07-17 04:23:02', 'anggota'),
(637, 'Anggota 636', 'anggota636@gmail.com', NULL, '$2y$12$ZhAIZ4OuZBLd2nbDfgOXVOevDLlcSFEmUyieHzEsdwli/olIwIjae', NULL, '2025-07-17 04:23:02', '2025-07-17 04:23:02', 'anggota'),
(638, 'Anggota 637', 'anggota637@gmail.com', NULL, '$2y$12$O.kdRIsbZiEy0BKZlyv2pexBVRUQH8ZKatywCe5NpvpkRyvyf0Q8i', NULL, '2025-07-17 04:23:03', '2025-07-17 04:23:03', 'anggota'),
(639, 'Anggota 638', 'anggota638@gmail.com', NULL, '$2y$12$aGrRjBTMps03ReNYNEvlvuhxUH2vvezZ7zOOuEyOe0LYwOCA2d5jy', NULL, '2025-07-17 04:23:03', '2025-07-17 04:23:03', 'anggota'),
(640, 'Anggota 639', 'anggota639@gmail.com', NULL, '$2y$12$nJP.E0LAa0qPDHo23E/dn.dZtJ4m32m/5rZy90pGDuqFUWQH5PpVm', NULL, '2025-07-17 04:23:03', '2025-07-17 04:23:03', 'anggota'),
(641, 'Anggota 640', 'anggota640@gmail.com', NULL, '$2y$12$xHk2zRqMBAUTaakcKNH4oO6rRlb5pZzmvIHIU0vB2lvh7wijcl1A6', NULL, '2025-07-17 04:23:04', '2025-07-17 04:23:04', 'anggota'),
(642, 'Anggota 641', 'anggota641@gmail.com', NULL, '$2y$12$jZ30SK7A17263XuvZPjM0.5CCsGDQ2AZ6KsulKLwj45vBl3Zg7vsC', NULL, '2025-07-17 04:23:04', '2025-07-17 04:23:04', 'anggota'),
(643, 'Anggota 642', 'anggota642@gmail.com', NULL, '$2y$12$9OBNx5kn6nT4r1wbmkB6suAquOx2yMeB2Obb9qafa9mL5SwjiRdQ6', NULL, '2025-07-17 04:23:04', '2025-07-17 04:23:04', 'anggota'),
(644, 'Anggota 643', 'anggota643@gmail.com', NULL, '$2y$12$pA.OwUsszRdLY4haQADPyO6YU9h8Yy1aq9MgxpqR25ngwsQaRAps.', NULL, '2025-07-17 04:23:05', '2025-07-17 04:23:05', 'anggota'),
(645, 'Anggota 644', 'anggota644@gmail.com', NULL, '$2y$12$79GKlOJNM.y1coy4t2zAkeeML5BGS1wMN2C6Zuty7HIABe186nsku', NULL, '2025-07-17 04:23:05', '2025-07-17 04:23:05', 'anggota'),
(646, 'Anggota 645', 'anggota645@gmail.com', NULL, '$2y$12$3b4smWaid9JRxkqzPiFENeRzYKzz7G8vpxpbERB6R5HtX1wBGXuVG', NULL, '2025-07-17 04:23:05', '2025-07-17 04:23:05', 'anggota'),
(647, 'Anggota 646', 'anggota646@gmail.com', NULL, '$2y$12$4Om8u/AUL6xvV.7jB0V5pOrO9RGnvkQByBHkN29UkAOS3ahwvtuVa', NULL, '2025-07-17 04:23:05', '2025-07-17 04:23:05', 'anggota'),
(648, 'Anggota 647', 'anggota647@gmail.com', NULL, '$2y$12$.BnGBI7pFqUhCp5Wgfb4yudzI1Lc01lsgI4sJansiPHRdxdyZ74RO', NULL, '2025-07-17 04:23:06', '2025-07-17 04:23:06', 'anggota'),
(649, 'Anggota 648', 'anggota648@gmail.com', NULL, '$2y$12$/.sUsgwaRkWzLEYLrUrAEeAp6xImVgJ20eF4GKk9COlFg/UJbKGcC', NULL, '2025-07-17 04:23:06', '2025-07-17 04:23:06', 'anggota'),
(650, 'Anggota 649', 'anggota649@gmail.com', NULL, '$2y$12$fb3prODy8E9OYCdbqaUoDuRxU51DvN0epiYoPbWWKMioxYgnkdKzC', NULL, '2025-07-17 04:23:06', '2025-07-17 04:23:06', 'anggota'),
(651, 'Anggota 650', 'anggota650@gmail.com', NULL, '$2y$12$ojUTqdo8mjTtWGuOM0rRjueOx2H5v2UHztCf85KffOIiis2llARqa', NULL, '2025-07-17 04:23:07', '2025-07-17 04:23:07', 'anggota'),
(652, 'Anggota 651', 'anggota651@gmail.com', NULL, '$2y$12$ne2aGvojcxHKt9lBd3uInODS/3XLVGoLYNpyoDdmKZuRj7.Row/fi', NULL, '2025-07-17 04:23:07', '2025-07-17 04:23:07', 'anggota'),
(653, 'Anggota 652', 'anggota652@gmail.com', NULL, '$2y$12$VJN2bSJNpBz68gKSd4X4/up8weNf61WGAsy4.h/5uRNLFnJXeojZG', NULL, '2025-07-17 04:23:07', '2025-07-17 04:23:07', 'anggota'),
(654, 'Anggota 653', 'anggota653@gmail.com', NULL, '$2y$12$zX921dylf90lR/gRV5Q9reOnFv133vL/XQAmnwOrXSSiBC.mgHdWW', NULL, '2025-07-17 04:23:08', '2025-07-17 04:23:08', 'anggota'),
(655, 'Anggota 654', 'anggota654@gmail.com', NULL, '$2y$12$ZwDvNxkcaWwQOX8szlht0ufVrXHIbPJzb.F.3LlFpCu2VN55WmCwS', NULL, '2025-07-17 04:23:08', '2025-07-17 04:23:08', 'anggota'),
(656, 'Anggota 655', 'anggota655@gmail.com', NULL, '$2y$12$LycE3umSt9O6V4C.npPxsObxc17nRNheJ9xURc7TlI8B/GIy1Myiq', NULL, '2025-07-17 04:23:08', '2025-07-17 04:23:08', 'anggota'),
(657, 'Anggota 656', 'anggota656@gmail.com', NULL, '$2y$12$AMvmWjqs/MOwEgHBo0SH3eBeWpVvjsonoTR1CQcEf224W9I8cEB7y', NULL, '2025-07-17 04:23:08', '2025-07-17 04:23:08', 'anggota'),
(658, 'Anggota 657', 'anggota657@gmail.com', NULL, '$2y$12$12mQ59AaRYiKKs2hYGD0YuLeJBy/sETq.ye7oehskCWaSq65sr2H.', NULL, '2025-07-17 04:23:09', '2025-07-17 04:23:09', 'anggota'),
(659, 'Anggota 658', 'anggota658@gmail.com', NULL, '$2y$12$zT30r8O4DEGQ.HBdH0PJDuRsvwcK94NKR9osVWN.vgnJ0y1IhRNVq', NULL, '2025-07-17 04:23:09', '2025-07-17 04:23:09', 'anggota'),
(660, 'Anggota 659', 'anggota659@gmail.com', NULL, '$2y$12$lKDm8r01XNtw8P5A/FJwROOTAaCVMlQhSgJ1XvJQbLFl2M/vXAgeu', NULL, '2025-07-17 04:23:09', '2025-07-17 04:23:09', 'anggota'),
(661, 'Anggota 660', 'anggota660@gmail.com', NULL, '$2y$12$v5ZHNXzniJXo.J9UipBtX.0o3yg3ckXvNv11HU5s8DMRVPk4OqEDm', NULL, '2025-07-17 04:23:10', '2025-07-17 04:23:10', 'anggota'),
(662, 'Anggota 661', 'anggota661@gmail.com', NULL, '$2y$12$0Jhp7Oe5GXUmVwXUUbm3/uATSy89MCd8ggEwagN5ZU2Uzs7zVvlNi', NULL, '2025-07-17 04:23:10', '2025-07-17 04:23:10', 'anggota'),
(663, 'Anggota 662', 'anggota662@gmail.com', NULL, '$2y$12$c6czPoE6gFavTI3BSt9cY.J/tW4xwKIgPoFs1qM2icFRB59PLnNmy', NULL, '2025-07-17 04:23:10', '2025-07-17 04:23:10', 'anggota'),
(664, 'Anggota 663', 'anggota663@gmail.com', NULL, '$2y$12$gG6eabfXStY9o67nGln4lehMd2.CdYGZjLOGfApg7ZzUTuKWXhvPq', NULL, '2025-07-17 04:23:11', '2025-07-17 04:23:11', 'anggota'),
(665, 'Anggota 664', 'anggota664@gmail.com', NULL, '$2y$12$c2exhp5GQ0bvKyNekAtl7.bH.GE5tjYqzyVdQKX0Bz4DpkPuaq6FW', NULL, '2025-07-17 04:23:11', '2025-07-17 04:23:11', 'anggota'),
(666, 'Anggota 665', 'anggota665@gmail.com', NULL, '$2y$12$wtMnaiBjgNG/VdSweexvP.IK8Qh.ltYqa6KFL/hGNvy8qiSMUz0L6', NULL, '2025-07-17 04:23:11', '2025-07-17 04:23:11', 'anggota'),
(667, 'Anggota 666', 'anggota666@gmail.com', NULL, '$2y$12$BOVwi45ljrZQ7JV3LD9LuODT5At2UlpxlBdIvU9X6Mz/pw19HpjJm', NULL, '2025-07-17 04:23:12', '2025-07-17 04:23:12', 'anggota'),
(668, 'Anggota 667', 'anggota667@gmail.com', NULL, '$2y$12$WiPvr/fstGDEBNpL0cDvn.czmE0iuXREdTKeaCMCAGhlfMCOtpKty', NULL, '2025-07-17 04:23:12', '2025-07-17 04:23:12', 'anggota'),
(669, 'Anggota 668', 'anggota668@gmail.com', NULL, '$2y$12$B3UT8V.poqI4GAlrObEqSOyAvePo8wI7Y/yEScLboUNtSnxIIOp/K', NULL, '2025-07-17 04:23:12', '2025-07-17 04:23:12', 'anggota'),
(670, 'Anggota 669', 'anggota669@gmail.com', NULL, '$2y$12$8AXmpxi9RVb1UL0V2EiL0.4SICj4t1BtoNYloz6f7aCxVxu0UczZe', NULL, '2025-07-17 04:23:12', '2025-07-17 04:23:12', 'anggota'),
(671, 'Anggota 670', 'anggota670@gmail.com', NULL, '$2y$12$Nn7/KSK1EDZhl0GVIXRdmef5kTtgz4dptmRhhvBYy92K7y2U.yHaq', NULL, '2025-07-17 04:23:13', '2025-07-17 04:23:13', 'anggota'),
(672, 'Anggota 671', 'anggota671@gmail.com', NULL, '$2y$12$R2PZBAHbYCgTUoXFipXa.ubBBmf5QEL9SAaEKtXEmp7kwmDkPB7ci', NULL, '2025-07-17 04:23:13', '2025-07-17 04:23:13', 'anggota'),
(673, 'Anggota 672', 'anggota672@gmail.com', NULL, '$2y$12$lpkADfwV9a3OxAPRHHimSOeSY93I4F2GygWvpD2kHH/4rdWe50hHe', NULL, '2025-07-17 04:23:13', '2025-07-17 04:23:13', 'anggota'),
(674, 'Anggota 673', 'anggota673@gmail.com', NULL, '$2y$12$otZLtnH0QbmRRSVDX4Wpv.vT5XIyn5BvTib.EXg2p9BbxtL2BjQ/q', NULL, '2025-07-17 04:23:14', '2025-07-17 04:23:14', 'anggota'),
(675, 'Anggota 674', 'anggota674@gmail.com', NULL, '$2y$12$PneucZg15ipqdIH3uJs4RemwhXgIVEgvrlkgICxc6/eyhoIylJV0S', NULL, '2025-07-17 04:23:14', '2025-07-17 04:23:14', 'anggota'),
(676, 'Anggota 675', 'anggota675@gmail.com', NULL, '$2y$12$CL.A.cpiDitRiW4nF4NIaOp93omQIdueExxlDJAVyqLcsSnuM0pNW', NULL, '2025-07-17 04:23:14', '2025-07-17 04:23:14', 'anggota'),
(677, 'Anggota 676', 'anggota676@gmail.com', NULL, '$2y$12$BaFYH/9C0p56lKLr3rTzqOLUTYH9idFN5s.0LZf6RWtg3OWloLKgK', NULL, '2025-07-17 04:23:15', '2025-07-17 04:23:15', 'anggota'),
(678, 'Anggota 677', 'anggota677@gmail.com', NULL, '$2y$12$WMQdH1sgQvchTafLh89URec1Ehnm6Uxb55egPHjjDsmdtaU/3IqlO', NULL, '2025-07-17 04:23:15', '2025-07-17 04:23:15', 'anggota'),
(679, 'Anggota 678', 'anggota678@gmail.com', NULL, '$2y$12$AEOEy6enWCNwbBu.rWJJiuWq5266RHTPWdMRrRRC6V6tA.fl7DJ9S', NULL, '2025-07-17 04:23:15', '2025-07-17 04:23:15', 'anggota'),
(680, 'Anggota 679', 'anggota679@gmail.com', NULL, '$2y$12$AJeqobFgWmolZX65h9O4wettGca0n8z.AeKOTXkz3M9bbCgVg/CGy', NULL, '2025-07-17 04:23:15', '2025-07-17 04:23:15', 'anggota'),
(681, 'Anggota 680', 'anggota680@gmail.com', NULL, '$2y$12$iX/Q/LTMiLn1WZ/6wauWvOKZ4vkXUIFYqmRJV6mvC3hSDD99bK0Qe', NULL, '2025-07-17 04:23:16', '2025-07-17 04:23:16', 'anggota'),
(682, 'Anggota 681', 'anggota681@gmail.com', NULL, '$2y$12$25Fmgk0bW5lIMTNCyAtT7eXr.Z7aXUduNgklZjk7C.6N1uk6soTAu', NULL, '2025-07-17 04:23:16', '2025-07-17 04:23:16', 'anggota'),
(683, 'Anggota 682', 'anggota682@gmail.com', NULL, '$2y$12$nfSEEHKkJzgWgwOykT94Q.AU.Ee2BB4PzzItw54yhSMXJPj5KvO7i', NULL, '2025-07-17 04:23:16', '2025-07-17 04:23:16', 'anggota'),
(684, 'Anggota 683', 'anggota683@gmail.com', NULL, '$2y$12$OQ.0DNVeH0RLso.7ntdDXeASrwgeg4Lanl4oQWgYw21rjdvCn5xbq', NULL, '2025-07-17 04:23:17', '2025-07-17 04:23:17', 'anggota'),
(685, 'Anggota 684', 'anggota684@gmail.com', NULL, '$2y$12$WrgyssGbitVqGeoQ7uzaje.B44aIEtST6SwALwMhb6YTXATF0LBYe', NULL, '2025-07-17 04:23:17', '2025-07-17 04:23:17', 'anggota'),
(686, 'Anggota 685', 'anggota685@gmail.com', NULL, '$2y$12$gNfjDbHa8l9MQ5/4i6.hy.6vpiOjT1lKIeDQHZkEQL293TwRXZziC', NULL, '2025-07-17 04:23:17', '2025-07-17 04:23:17', 'anggota'),
(687, 'Anggota 686', 'anggota686@gmail.com', NULL, '$2y$12$C.aFgjOpfMseq2qAcLQ9nOIbfiEe38k7dDQSF.Of5H34pHdXM.5e6', NULL, '2025-07-17 04:23:18', '2025-07-17 04:23:18', 'anggota'),
(688, 'Anggota 687', 'anggota687@gmail.com', NULL, '$2y$12$2/5zY1UfeQR6sjL5nxiEnecoLt62UM50daP852lMbhBWUwShCeB6C', NULL, '2025-07-17 04:23:18', '2025-07-17 04:23:18', 'anggota'),
(689, 'Anggota 688', 'anggota688@gmail.com', NULL, '$2y$12$wzpLM5RRu3oO/FuRH2cyhOVJBEzgCtSFPE5KzyEU.7U.sRmgH9dZW', NULL, '2025-07-17 04:23:18', '2025-07-17 04:23:18', 'anggota'),
(690, 'Anggota 689', 'anggota689@gmail.com', NULL, '$2y$12$C4yk4AfZ.5D6TC1cEGAkdOempTp2jJ1CGXdtZ58IVPSiJSJ2ghIpC', NULL, '2025-07-17 04:23:19', '2025-07-17 04:23:19', 'anggota'),
(691, 'Anggota 690', 'anggota690@gmail.com', NULL, '$2y$12$QYN.UeldwWHDiW1vdIQeBObKjQcqrrzgPoXyh0xpzdu74yNsb9.Om', NULL, '2025-07-17 04:23:19', '2025-07-17 04:23:19', 'anggota'),
(692, 'Anggota 691', 'anggota691@gmail.com', NULL, '$2y$12$57pEf0b4bGzMRK0m9QJ3tOTRrNTN80OGUwjH4.vVfH58R56K4.fGi', NULL, '2025-07-17 04:23:19', '2025-07-17 04:23:19', 'anggota'),
(693, 'Anggota 692', 'anggota692@gmail.com', NULL, '$2y$12$TXcpZqdqRC7auCzZlqzk5utAKwPm7WNkTLVOG9hzo5hQOsRpKj.Fe', NULL, '2025-07-17 04:23:19', '2025-07-17 04:23:19', 'anggota'),
(694, 'Anggota 693', 'anggota693@gmail.com', NULL, '$2y$12$WnDa1CKDRLBcMiGfio1sD.Tlf5IjF3s5RqapAIVdBQaxdbafn2KcK', NULL, '2025-07-17 04:23:20', '2025-07-17 04:23:20', 'anggota'),
(695, 'Anggota 694', 'anggota694@gmail.com', NULL, '$2y$12$Fhocpgk0ikm/ZcklyNj5FOpXx0h6QkD.qHoQdYSR9afdWpGIAd1Im', NULL, '2025-07-17 04:23:20', '2025-07-17 04:23:20', 'anggota'),
(696, 'Anggota 695', 'anggota695@gmail.com', NULL, '$2y$12$vtEy0TPjh9xDcYrwBfrq4ONnjKJ4BLU6ZtrvUuknx5KxaZy28INg.', NULL, '2025-07-17 04:23:20', '2025-07-17 04:23:20', 'anggota'),
(697, 'Anggota 696', 'anggota696@gmail.com', NULL, '$2y$12$34FUttoTjGBxm/i6yEBKM.H0LqO28tKbsjoTmvB3VooYZTbhbBute', NULL, '2025-07-17 04:23:21', '2025-07-17 04:23:21', 'anggota'),
(698, 'Anggota 697', 'anggota697@gmail.com', NULL, '$2y$12$0EOJn.KrXKeRlcKO5/BySuLKJh1cSXfDpg15IzWY3BOzSa0J0fMT.', NULL, '2025-07-17 04:23:21', '2025-07-17 04:23:21', 'anggota'),
(699, 'Anggota 698', 'anggota698@gmail.com', NULL, '$2y$12$yAQRE3dk0s5lkLJEBcpC0.F2CwUXtdpkn/V0BAExWjz0TvGDNyY0K', NULL, '2025-07-17 04:23:21', '2025-07-17 04:23:21', 'anggota'),
(700, 'Anggota 699', 'anggota699@gmail.com', NULL, '$2y$12$pyu9.qq363xyuJpWSbaoOeIwGP5wavSXUbXPxJrXyLZO6fc82Ze6O', NULL, '2025-07-17 04:23:22', '2025-07-17 04:23:22', 'anggota'),
(701, 'Anggota 700', 'anggota700@gmail.com', NULL, '$2y$12$.prryub77xqRweaJmnHRvuYHCydhm11ZvG2x8zwS5wjVYlosEOZoC', NULL, '2025-07-17 04:23:22', '2025-07-17 04:23:22', 'anggota'),
(702, 'Anggota 701', 'anggota701@gmail.com', NULL, '$2y$12$dMj2LpvHtU.EIHWSRFgX8eAT5zcynokt.vDE48auUi7P8MvJnMINi', NULL, '2025-07-17 04:23:22', '2025-07-17 04:23:22', 'anggota'),
(703, 'Anggota 702', 'anggota702@gmail.com', NULL, '$2y$12$4mjfY1FjWrvnmcwNnKiHeeqCzzkZEIwDVwLCXfmngm3FMX.zX4oRm', NULL, '2025-07-17 04:23:23', '2025-07-17 04:23:23', 'anggota'),
(704, 'Anggota 703', 'anggota703@gmail.com', NULL, '$2y$12$y1hiEHbuBQYd8Td5W16VDOvrKn0Mh0jm.GjJjBtfDQYVDBzcRqwY6', NULL, '2025-07-17 04:23:23', '2025-07-17 04:23:23', 'anggota'),
(705, 'Anggota 704', 'anggota704@gmail.com', NULL, '$2y$12$QVlmpxY5.uFGPF.tH78Zoeke4yfXPRW7aKWlFPJ4ws0lu3vW92Da6', NULL, '2025-07-17 04:23:23', '2025-07-17 04:23:23', 'anggota'),
(706, 'Anggota 705', 'anggota705@gmail.com', NULL, '$2y$12$v6NhWm10Jo9C8nnQP3SrdurdGdCc5rT3DvjWm0ZJaXdAXmnUT8vgG', NULL, '2025-07-17 04:23:24', '2025-07-17 04:23:24', 'anggota'),
(707, 'Anggota 706', 'anggota706@gmail.com', NULL, '$2y$12$ft3qrz7oGVL4NYSnoF./Je5j8rBIeXQCmiLpx8oHccp6qnEaqCGN2', NULL, '2025-07-17 04:23:24', '2025-07-17 04:23:24', 'anggota'),
(708, 'Anggota 707', 'anggota707@gmail.com', NULL, '$2y$12$5RXJ9hkasye9Up6jHX3JIeEroeAxGfspUHH9WNPkUTp/myaLPgEKy', NULL, '2025-07-17 04:23:25', '2025-07-17 04:23:25', 'anggota'),
(709, 'Anggota 708', 'anggota708@gmail.com', NULL, '$2y$12$1WnZGZ70CoOyMBGo2O1jPOg5eS3WRd4RXqBpM8HEcY0Qd38d801HW', NULL, '2025-07-17 04:23:25', '2025-07-17 04:23:25', 'anggota'),
(710, 'Anggota 709', 'anggota709@gmail.com', NULL, '$2y$12$boOw09imP9jbwGA5SqQnauZaZGeS6sjvBDvhlReu.1c5wEcq5G9bi', NULL, '2025-07-17 04:23:25', '2025-07-17 04:23:25', 'anggota'),
(711, 'Anggota 710', 'anggota710@gmail.com', NULL, '$2y$12$mcKzhdQG0j5b69XJ.RcrJ.K32PLgcTtT2Ymz0sHcbyOuWNF82AFa6', NULL, '2025-07-17 04:23:26', '2025-07-17 04:23:26', 'anggota'),
(712, 'Anggota 711', 'anggota711@gmail.com', NULL, '$2y$12$EOzQqbRZB5o7UfoQOa3vWO7J7KTE86CqVybsC7W5GMy062tPZzlHO', NULL, '2025-07-17 04:23:26', '2025-07-17 04:23:26', 'anggota'),
(713, 'Anggota 712', 'anggota712@gmail.com', NULL, '$2y$12$rhiWj3YveMROcE1cr4l//eQAruX.AyTNy.D//OVhSrVe9e7STrTei', NULL, '2025-07-17 04:23:27', '2025-07-17 04:23:27', 'anggota'),
(714, 'Anggota 713', 'anggota713@gmail.com', NULL, '$2y$12$269Octq7kGKV/cec8sQZzeagzNJRR8KHLKMnhatMh28DsIeLOyRlO', NULL, '2025-07-17 04:23:27', '2025-07-17 04:23:27', 'anggota'),
(715, 'Anggota 714', 'anggota714@gmail.com', NULL, '$2y$12$sR5QKow4QmXFbMLdzGzUZedQpuM0schY7KvvxWqGZsGabMU5blKFe', NULL, '2025-07-17 04:23:27', '2025-07-17 04:23:27', 'anggota'),
(716, 'Anggota 715', 'anggota715@gmail.com', NULL, '$2y$12$hV3T4qQ8N4fvFOtW/kOCD.C7w7tIkOqs26IHBg7JSKsYsKvCzY2.i', NULL, '2025-07-17 04:23:28', '2025-07-17 04:23:28', 'anggota'),
(717, 'Anggota 716', 'anggota716@gmail.com', NULL, '$2y$12$Ud3NcDyIbinsWjh.FC/XturTXZLlwLCoGKg6J3DknVTGHkl7vh7mW', NULL, '2025-07-17 04:23:28', '2025-07-17 04:23:28', 'anggota'),
(718, 'Anggota 717', 'anggota717@gmail.com', NULL, '$2y$12$3l4dL02qKe3a6N4m1Ujgf.CQ5D1XWCtGMVzKwrpw63dO8BIlVTMDa', NULL, '2025-07-17 04:23:28', '2025-07-17 04:23:28', 'anggota'),
(719, 'Anggota 718', 'anggota718@gmail.com', NULL, '$2y$12$AWRIrhYwIFN58BFygp9srufmLhCCTPvGYQHtShK5TDVTz8Uh11Ptm', NULL, '2025-07-17 04:23:29', '2025-07-17 04:23:29', 'anggota'),
(720, 'Anggota 719', 'anggota719@gmail.com', NULL, '$2y$12$yzRXtaEMQdmhr2aZZlFvAe3Vi1bdt86ykhQ1TXNf7qgqDSGS4JMGi', NULL, '2025-07-17 04:23:29', '2025-07-17 04:23:29', 'anggota'),
(721, 'Anggota 720', 'anggota720@gmail.com', NULL, '$2y$12$ZW/bVD/DxHJYY3PntLyudOaTqaITyrfiJFfpEJFjfiy7.39Mvgysa', NULL, '2025-07-17 04:23:30', '2025-07-17 04:23:30', 'anggota'),
(722, 'Anggota 721', 'anggota721@gmail.com', NULL, '$2y$12$4YQLuJSH2FnH69TtadXd0OGEPM9qLtbm5buFZyN9GkOSQA/xaIR4m', NULL, '2025-07-17 04:23:30', '2025-07-17 04:23:30', 'anggota'),
(723, 'Anggota 722', 'anggota722@gmail.com', NULL, '$2y$12$iOX8abdnx0js6RB.gpnwY.3GPo1tEp6srUxmxG.lafCVMNclDqUGq', NULL, '2025-07-17 04:23:30', '2025-07-17 04:23:30', 'anggota'),
(724, 'Anggota 723', 'anggota723@gmail.com', NULL, '$2y$12$JqL5PKoHZGpwlTb.EvwM../nWPeLtL2WJit1.udndBxWOQq4khxIm', NULL, '2025-07-17 04:23:31', '2025-07-17 04:23:31', 'anggota'),
(725, 'Anggota 724', 'anggota724@gmail.com', NULL, '$2y$12$Oa9sKm9E6jTGI1/xEgSznO2vbpCKBCmsjbCuym6kjgM53iPYglrxa', NULL, '2025-07-17 04:23:31', '2025-07-17 04:23:31', 'anggota'),
(726, 'Anggota 725', 'anggota725@gmail.com', NULL, '$2y$12$HjhNZFkGtnG5a9.j9R6WTuRFuPJAxmWXzlLF4YAGL2mwXgfgLuy6C', NULL, '2025-07-17 04:23:31', '2025-07-17 04:23:31', 'anggota'),
(727, 'Anggota 726', 'anggota726@gmail.com', NULL, '$2y$12$guzM9g34JB7RzcQcfPkr.elBtmjkpROpE1ul/A.Tzu2kPU8cXooD6', NULL, '2025-07-17 04:23:32', '2025-07-17 04:23:32', 'anggota'),
(728, 'Anggota 727', 'anggota727@gmail.com', NULL, '$2y$12$sWTegXr2kR37aEwtgtWXe.MU2jAcAmdzblwDiIt6imuPy1oB/7NJW', NULL, '2025-07-17 04:23:32', '2025-07-17 04:23:32', 'anggota'),
(729, 'Anggota 728', 'anggota728@gmail.com', NULL, '$2y$12$.VbwwwnKQeIpcPIiuiIpguiYUnYUItFDc/xnBQMFGJLq/ex3AXBGy', NULL, '2025-07-17 04:23:33', '2025-07-17 04:23:33', 'anggota'),
(730, 'Anggota 729', 'anggota729@gmail.com', NULL, '$2y$12$trqv58SlnlqMQ0RS3n0P4OLtxSl.qwt/HMjYFJlds9PJWryJikfQq', NULL, '2025-07-17 04:23:33', '2025-07-17 04:23:33', 'anggota'),
(731, 'Anggota 730', 'anggota730@gmail.com', NULL, '$2y$12$Dk/NTpEaKsSDrRUMi20y/u.AHJcua.62u51iXz4V//2/aG4BziOKC', NULL, '2025-07-17 04:23:33', '2025-07-17 04:23:33', 'anggota'),
(732, 'Anggota 731', 'anggota731@gmail.com', NULL, '$2y$12$P9Bv1lGIW.B/pBMtOpUijuPP2lm8.8HEhI3MfHl/CQpM7b7gXwyNO', NULL, '2025-07-17 04:23:34', '2025-07-17 04:23:34', 'anggota'),
(733, 'Anggota 732', 'anggota732@gmail.com', NULL, '$2y$12$G/vnkXPAMW7zd1y6PPp0JuWaHehhgWs0lnKQYFroqM.Ilgec5tSga', NULL, '2025-07-17 04:23:34', '2025-07-17 04:23:34', 'anggota'),
(734, 'Anggota 733', 'anggota733@gmail.com', NULL, '$2y$12$aIbn84P/xkak98yYKHfZN.8ekEZduDvM/5ikxd5mQ8MHaftuJpvPG', NULL, '2025-07-17 04:23:35', '2025-07-17 04:23:35', 'anggota'),
(735, 'Anggota 734', 'anggota734@gmail.com', NULL, '$2y$12$K6fe0bbqVhpBpfmn6/YGx.G3Egque6t6UqOwtnCmuOuru0WWVCot.', NULL, '2025-07-17 04:23:35', '2025-07-17 04:23:35', 'anggota'),
(736, 'Anggota 735', 'anggota735@gmail.com', NULL, '$2y$12$GcvzoE44AAv5OSMwgFHmB..O7Isb6OY9KiQDCJXDSOm112vRW2W.6', NULL, '2025-07-17 04:23:35', '2025-07-17 04:23:35', 'anggota'),
(737, 'Anggota 736', 'anggota736@gmail.com', NULL, '$2y$12$01j6/C3r7qqkslW1pAhfOuw.efK/Y/XhzZ/ga.vQ/7hrhSBdYmlYe', NULL, '2025-07-17 04:23:36', '2025-07-17 04:23:36', 'anggota'),
(738, 'Anggota 737', 'anggota737@gmail.com', NULL, '$2y$12$M/ESh5MjFfB44.2md/2YJeNS1P5/YoiZrk/0GZp4Il3RNLToU5v.q', NULL, '2025-07-17 04:23:36', '2025-07-17 04:23:36', 'anggota'),
(739, 'Anggota 738', 'anggota738@gmail.com', NULL, '$2y$12$cTmftvti3xe4MWqM5xVabOLGz6t4242h4ahVXKqOhpYgA4FsvzKDS', NULL, '2025-07-17 04:23:36', '2025-07-17 04:23:36', 'anggota'),
(740, 'Anggota 739', 'anggota739@gmail.com', NULL, '$2y$12$lN2xbVzwnVtxtsX/Q3.DWuEtzHHI.iE4YOCJ.WeInM2PWp00bXxg.', NULL, '2025-07-17 04:23:37', '2025-07-17 04:23:37', 'anggota'),
(741, 'Anggota 740', 'anggota740@gmail.com', NULL, '$2y$12$.7.hAgiGruQlL1c4PvXYYOEGl3kmx0PRPwaEga0Q3rXiG8T2.0PB6', NULL, '2025-07-17 04:23:37', '2025-07-17 04:23:37', 'anggota'),
(742, 'Anggota 741', 'anggota741@gmail.com', NULL, '$2y$12$Vu19eNDRK.8LGfjdmnJORuwgzr7NXWayeQqrdpoeDtp9XIV8XQInS', NULL, '2025-07-17 04:23:38', '2025-07-17 04:23:38', 'anggota'),
(743, 'Anggota 742', 'anggota742@gmail.com', NULL, '$2y$12$dTPgypZux0i0/66rtrhtrOM5Nx764W4fgVQFdA/buk.ZMeFwEIVze', NULL, '2025-07-17 04:23:38', '2025-07-17 04:23:38', 'anggota'),
(744, 'Anggota 743', 'anggota743@gmail.com', NULL, '$2y$12$sFhN/a5L1feJn1XW0fqjU.UI6BwclI8bCV0so06f3cmHGUzhjDPfa', NULL, '2025-07-17 04:23:38', '2025-07-17 04:23:38', 'anggota'),
(745, 'Anggota 744', 'anggota744@gmail.com', NULL, '$2y$12$O8iM8p69YfaENssGkm5G/egXnF11DT6XPLWDUaoUST2bObMauA4eK', NULL, '2025-07-17 04:23:39', '2025-07-17 04:23:39', 'anggota'),
(746, 'Anggota 745', 'anggota745@gmail.com', NULL, '$2y$12$iLD9am3YU/HHUQ9NSWIPr.zp76F5RlvKgrGvyiBwNhEQp5aujNnm2', NULL, '2025-07-17 04:23:39', '2025-07-17 04:23:39', 'anggota'),
(747, 'Anggota 746', 'anggota746@gmail.com', NULL, '$2y$12$pfaOSzhVUA.u2oTvqLgece8MEdXPfHyRaJ5xq8mOzBkh0sIdiVmKG', NULL, '2025-07-17 04:23:40', '2025-07-17 04:23:40', 'anggota'),
(748, 'Anggota 747', 'anggota747@gmail.com', NULL, '$2y$12$YwYFHO3USQmMmc6hR9ou0eas3udBSHRGa7WIHFC2U6PwENbFTQ5Xq', NULL, '2025-07-17 04:23:40', '2025-07-17 04:23:40', 'anggota'),
(749, 'Anggota 748', 'anggota748@gmail.com', NULL, '$2y$12$3/5KW.G9Zu6Mi9TF0fVa3uPGea9yhbsKBpaZm4uT15FgFGkv9wQii', NULL, '2025-07-17 04:23:40', '2025-07-17 04:23:40', 'anggota'),
(750, 'Anggota 749', 'anggota749@gmail.com', NULL, '$2y$12$DoKYDq4HBy0RvsRA9DrbjuZEVSBQCRuSdiAAoZZCOrnDjEZWL3e5W', NULL, '2025-07-17 04:23:41', '2025-07-17 04:23:41', 'anggota'),
(751, 'Anggota 750', 'anggota750@gmail.com', NULL, '$2y$12$UiVGGUq1O9442qbY89.NM.tOWFEHAaseIogSOQ1I9ITR0oNyeIa.G', NULL, '2025-07-17 04:23:41', '2025-07-17 04:23:41', 'anggota'),
(752, 'Anggota 751', 'anggota751@gmail.com', NULL, '$2y$12$M0w9v3GmM06gaLiaGiPJ.eDA.A4yoHy.wi88HP/3cM51D.Da58xzG', NULL, '2025-07-17 04:23:42', '2025-07-17 04:23:42', 'anggota'),
(753, 'Anggota 752', 'anggota752@gmail.com', NULL, '$2y$12$rglP36NGjJwLsbFwnAgbKO87X8Tv3k1cIiZTKfWcDC9Qz.p2d/Yz6', NULL, '2025-07-17 04:23:42', '2025-07-17 04:23:42', 'anggota'),
(754, 'Anggota 753', 'anggota753@gmail.com', NULL, '$2y$12$chNBtUEeWvzWK2m8z4z./u5KBH3UEDNBKg7jG5N7bbPMmrlbWNOn6', NULL, '2025-07-17 04:23:42', '2025-07-17 04:23:42', 'anggota'),
(755, 'Anggota 754', 'anggota754@gmail.com', NULL, '$2y$12$SWTj71g9yQItH/cgpv2JW.mktIe8emgJGso6Z7wiPi.vurWtzQmVm', NULL, '2025-07-17 04:23:43', '2025-07-17 04:23:43', 'anggota'),
(756, 'Anggota 755', 'anggota755@gmail.com', NULL, '$2y$12$yyzyeK/LBA/DD55KnszmYOT03yT5QEP7pRv9/V8dyxluniQ/Wjyq.', NULL, '2025-07-17 04:23:43', '2025-07-17 04:23:43', 'anggota'),
(757, 'Anggota 756', 'anggota756@gmail.com', NULL, '$2y$12$9mLObGBUAgzzmLwrq6pTse.D628uFNKvG9tJ9ZnJg1IzTGJoD3nzW', NULL, '2025-07-17 04:23:44', '2025-07-17 04:23:44', 'anggota'),
(758, 'Anggota 757', 'anggota757@gmail.com', NULL, '$2y$12$sLNHyPMQWy3gvbQm8e/b5OffgsUP9JurI5TLr9D.ZdCZCn2B7wFlC', NULL, '2025-07-17 04:23:44', '2025-07-17 04:23:44', 'anggota'),
(759, 'Anggota 758', 'anggota758@gmail.com', NULL, '$2y$12$lWcBH968sIUzdxdp0VCQfOc43o3P0Hr/yCMeyBSq.5MD8iT7B3UcS', NULL, '2025-07-17 04:23:45', '2025-07-17 04:23:45', 'anggota'),
(760, 'Anggota 759', 'anggota759@gmail.com', NULL, '$2y$12$6dpcBauiZqyOD8lUrjDrMOOXCTQXi31x0zkIt6FDmxYde280IKETW', NULL, '2025-07-17 04:23:45', '2025-07-17 04:23:45', 'anggota'),
(761, 'Anggota 760', 'anggota760@gmail.com', NULL, '$2y$12$v/Vx5ruxB1t5Fxu6GayiB.AC37JmC17Unyrrqr9kVAIDulOrT2cP6', NULL, '2025-07-17 04:23:45', '2025-07-17 04:23:45', 'anggota'),
(762, 'Anggota 761', 'anggota761@gmail.com', NULL, '$2y$12$tXCqdWitJqd7aQpo0sCixuPkpOlzMLbpHmXl43wnDpdL2mKxhvIea', NULL, '2025-07-17 04:23:46', '2025-07-17 04:23:46', 'anggota'),
(763, 'Anggota 762', 'anggota762@gmail.com', NULL, '$2y$12$RUdV5H.M.VTmgISBQ3Oqmu3d4EEV12HC.MXb4Fjwdf1APXGI.WY3W', NULL, '2025-07-17 04:23:46', '2025-07-17 04:23:46', 'anggota'),
(764, 'Anggota 763', 'anggota763@gmail.com', NULL, '$2y$12$MTz1BqxWQaLZtD8xRSjKFuS8emPEq/o8mBMdPlFFR.CIdbyH1FjOC', NULL, '2025-07-17 04:23:47', '2025-07-17 04:23:47', 'anggota'),
(765, 'Anggota 764', 'anggota764@gmail.com', NULL, '$2y$12$04Cwkm386c.Z6akQ8SVE0.TYYhku68G5zEDWauFCx2jY9BgWY.geG', NULL, '2025-07-17 04:23:47', '2025-07-17 04:23:47', 'anggota'),
(766, 'Anggota 765', 'anggota765@gmail.com', NULL, '$2y$12$yNgIwG4KYKWEsaNSoMFXiu2pOz9cW.gOd32GSl2OvlKrs0hMoDgiy', NULL, '2025-07-17 04:23:48', '2025-07-17 04:23:48', 'anggota'),
(767, 'Anggota 766', 'anggota766@gmail.com', NULL, '$2y$12$xqgPkj1Y3Vfydc7M2vo9weCCY/jb6eDWR2NQFiIgLDn.fUuCIsyTS', NULL, '2025-07-17 04:23:48', '2025-07-17 04:23:48', 'anggota'),
(768, 'Anggota 767', 'anggota767@gmail.com', NULL, '$2y$12$zqxBlnOTQLJQxJD0bIT7.eZR8ZKSW/XuoEzy9A5k1C6qZaYFI4HK6', NULL, '2025-07-17 04:23:48', '2025-07-17 04:23:48', 'anggota'),
(769, 'Anggota 768', 'anggota768@gmail.com', NULL, '$2y$12$3hq7w66k4mT7aCCfQiCNCuPSSpqIcx8BCLJEG7amif171CU3xLGIS', NULL, '2025-07-17 04:23:49', '2025-07-17 04:23:49', 'anggota'),
(770, 'Anggota 769', 'anggota769@gmail.com', NULL, '$2y$12$.sWWf6zdPtDVQJHm7T8ogeq7FYAlDI2f56rjtkHchh5jya.9qrmOC', NULL, '2025-07-17 04:23:49', '2025-07-17 04:23:49', 'anggota'),
(771, 'Anggota 770', 'anggota770@gmail.com', NULL, '$2y$12$XFosxLcpIxfOwSdl9WI4JuHwxTvQ12waOZHQzAwQJBUR0sUlgNkmy', NULL, '2025-07-17 04:23:50', '2025-07-17 04:23:50', 'anggota'),
(772, 'Anggota 771', 'anggota771@gmail.com', NULL, '$2y$12$DBOweQZU3tDmY7CgneJOVuLT443sEvVV7CJcahGfaIP11uoSJLEiu', NULL, '2025-07-17 04:23:50', '2025-07-17 04:23:50', 'anggota'),
(773, 'Anggota 772', 'anggota772@gmail.com', NULL, '$2y$12$YvoW2oeYIyXmBZoMv4OwAeVuVwbJGz1jVQoGIuN8Cg11lYgUD0x1W', NULL, '2025-07-17 04:23:50', '2025-07-17 04:23:50', 'anggota'),
(774, 'Anggota 773', 'anggota773@gmail.com', NULL, '$2y$12$9ew1qxzsiIfQ4n1I4TDv.umP48uCGlq2GUDK7/nntnD561Job.XMm', NULL, '2025-07-17 04:23:51', '2025-07-17 04:23:51', 'anggota'),
(775, 'Anggota 774', 'anggota774@gmail.com', NULL, '$2y$12$IF0NpQE92DbXGRWA7ho.tOe4KoDy/eX7bjpSmpT/Q1cRpmZV/pWQe', NULL, '2025-07-17 04:23:51', '2025-07-17 04:23:51', 'anggota'),
(776, 'Anggota 775', 'anggota775@gmail.com', NULL, '$2y$12$bfEFlqsNLSNrgA5LCTP.HumMGjWHPjMjuAi93yI/5zDYtG38CIy5q', NULL, '2025-07-17 04:23:51', '2025-07-17 04:23:51', 'anggota'),
(777, 'Anggota 776', 'anggota776@gmail.com', NULL, '$2y$12$sxUyKLFen2ro/3ndmaqW6OEuDy6zdHpOxtMSnXYHZ89bqkrs/oqqS', NULL, '2025-07-17 04:23:52', '2025-07-17 04:23:52', 'anggota'),
(778, 'Anggota 777', 'anggota777@gmail.com', NULL, '$2y$12$7S34GnjDIc6UiUmFuG4cY.R4QlOBLuPk2HADsq9GiJZ4UaeBOAw.C', NULL, '2025-07-17 04:23:52', '2025-07-17 04:23:52', 'anggota'),
(779, 'Anggota 778', 'anggota778@gmail.com', NULL, '$2y$12$RQxi2Jb3gPbZqHIZX1elEuOLXhl5fonJpYPiK37vocQpcBaIKioFK', NULL, '2025-07-17 04:23:53', '2025-07-17 04:23:53', 'anggota'),
(780, 'Anggota 779', 'anggota779@gmail.com', NULL, '$2y$12$yi6heKqqlBHtRSgMp1Lq7ex83wVArmPSBTdTOBpTcLOjJXWIoaUay', NULL, '2025-07-17 04:23:53', '2025-07-17 04:23:53', 'anggota'),
(781, 'Anggota 780', 'anggota780@gmail.com', NULL, '$2y$12$T6AikYymZn.6t0skxQaq5urq.PXZXAbDvyrNMbi.EUX6Flx73jWqC', NULL, '2025-07-17 04:23:53', '2025-07-17 04:23:53', 'anggota'),
(782, 'Anggota 781', 'anggota781@gmail.com', NULL, '$2y$12$IArHB1H16SaoaNri5sVId.uk86MhNAGBtTYe1RcnH05wO/f7i56pe', NULL, '2025-07-17 04:23:54', '2025-07-17 04:23:54', 'anggota'),
(783, 'Anggota 782', 'anggota782@gmail.com', NULL, '$2y$12$ethm/J8O1iD59CaXj0UgYOMcOavUHyi.M5C.SPi4RMtMCBtZr1vM6', NULL, '2025-07-17 04:23:54', '2025-07-17 04:23:54', 'anggota'),
(784, 'Anggota 783', 'anggota783@gmail.com', NULL, '$2y$12$w2SIQIS8LYmOLf929zrJz.H3yt.Xla26mZOOgotTTQLoEkMGR.ioS', NULL, '2025-07-17 04:23:55', '2025-07-17 04:23:55', 'anggota'),
(785, 'Anggota 784', 'anggota784@gmail.com', NULL, '$2y$12$IcTGeSxs/GHLxe0IpReLHenpKwnhtAHQ8QjI/lQJA0nd.j/LcZbTy', NULL, '2025-07-17 04:23:55', '2025-07-17 04:23:55', 'anggota'),
(786, 'Anggota 785', 'anggota785@gmail.com', NULL, '$2y$12$AUa0a7Z1KasxRmRpJIBKB.RTPglLyO7q7k1K4m0yvI5A5WpYFsW9i', NULL, '2025-07-17 04:23:55', '2025-07-17 04:23:55', 'anggota'),
(787, 'Anggota 786', 'anggota786@gmail.com', NULL, '$2y$12$OZrPoRZQA0gZVy0yFydLxubH3eY0MOpP1WeTgcaaZ9QmHlmKVN2rK', NULL, '2025-07-17 04:23:56', '2025-07-17 04:23:56', 'anggota'),
(788, 'Anggota 787', 'anggota787@gmail.com', NULL, '$2y$12$71g3Jjv2n6P2wqjMhLwjmOZp46dRgu.SYmWhIAAestNQb6cIF8bMe', NULL, '2025-07-17 04:23:56', '2025-07-17 04:23:56', 'anggota'),
(789, 'Anggota 788', 'anggota788@gmail.com', NULL, '$2y$12$t9OfuJ8MAoNXyc0vtPsy3eGKTyd2OwO9FNCLHZz3H4zG63YBzW7fC', NULL, '2025-07-17 04:23:57', '2025-07-17 04:23:57', 'anggota'),
(790, 'Anggota 789', 'anggota789@gmail.com', NULL, '$2y$12$LPpewOZCYsEItfJC/594uu/yx8zbI4C27bXlxSHlBaqYnu3SAcITG', NULL, '2025-07-17 04:23:57', '2025-07-17 04:23:57', 'anggota'),
(791, 'Anggota 790', 'anggota790@gmail.com', NULL, '$2y$12$ipstqturRrRT80Ga/3TY2.MDBg2sxfKKuG0wmZ8s5J8wSnrEA/edu', NULL, '2025-07-17 04:23:58', '2025-07-17 04:23:58', 'anggota'),
(792, 'Anggota 791', 'anggota791@gmail.com', NULL, '$2y$12$ljvyCuts0w1aMKFXCa/w4ORRllsc2tN.on8YP9sgo/epSAd/t/rui', NULL, '2025-07-17 04:23:58', '2025-07-17 04:23:58', 'anggota'),
(793, 'Anggota 792', 'anggota792@gmail.com', NULL, '$2y$12$Ss7Js1fr19lKT7wDlhmIe.BjSVUq7XlGN/Qs8/QdGKfFqlb.PEv56', NULL, '2025-07-17 04:23:58', '2025-07-17 04:23:58', 'anggota'),
(794, 'Anggota 793', 'anggota793@gmail.com', NULL, '$2y$12$JQaN3Qg5yKReUe7vttqGu.WYJAv7WdMzdpv3itmanwPMTfMdu/3EO', NULL, '2025-07-17 04:23:59', '2025-07-17 04:23:59', 'anggota'),
(795, 'Anggota 794', 'anggota794@gmail.com', NULL, '$2y$12$AoKAmDx9jiQeN.tEcFl8YOcYC874.1O1TX9F4M.UxU/YEQ.5jr/.a', NULL, '2025-07-17 04:23:59', '2025-07-17 04:23:59', 'anggota'),
(796, 'Anggota 795', 'anggota795@gmail.com', NULL, '$2y$12$I5/WccXqDm6xlw0wrX5HmuJuZKxp3Lw//Vr5U9Hvm/u2ZTsaGTPSm', NULL, '2025-07-17 04:24:00', '2025-07-17 04:24:00', 'anggota'),
(797, 'Anggota 796', 'anggota796@gmail.com', NULL, '$2y$12$sHidCVpnw73YGcuBcpGHcOr0sLUk751Es6XFHt1oueGyIgtVA6Myi', NULL, '2025-07-17 04:24:00', '2025-07-17 04:24:00', 'anggota'),
(798, 'Anggota 797', 'anggota797@gmail.com', NULL, '$2y$12$LXoricEqoYXsK/77p7dxrOPQWpmVSLiWJRekKmJ7tTNCzV7SX2pD6', NULL, '2025-07-17 04:24:01', '2025-07-17 04:24:01', 'anggota'),
(799, 'Anggota 798', 'anggota798@gmail.com', NULL, '$2y$12$eTnM8.tJWVKSBu/0gCifbuIOPN4Hptx.7Saa3wIaXPY7IlPvVDBCK', NULL, '2025-07-17 04:24:01', '2025-07-17 04:24:01', 'anggota'),
(800, 'Anggota 799', 'anggota799@gmail.com', NULL, '$2y$12$IAVVdfZCryzWQUO9E/ciOeogOATMAl3pLSu52KaHOFnr8QRQMdMvi', NULL, '2025-07-17 04:24:01', '2025-07-17 04:24:01', 'anggota'),
(801, 'Anggota 800', 'anggota800@gmail.com', NULL, '$2y$12$7WsB1yk58F1.70j2FHBU4ut00v8F9KPAd9Quxbp/NrdYeGUJ/rvMy', NULL, '2025-07-17 04:24:02', '2025-07-17 04:24:02', 'anggota'),
(802, 'Anggota 801', 'anggota801@gmail.com', NULL, '$2y$12$a.yGZvhtF1/hVdO.z.7c7uOpMt6DwtP1OMjVCFzAjUiisTmevBx1i', NULL, '2025-07-17 04:24:02', '2025-07-17 04:24:02', 'anggota'),
(803, 'Anggota 802', 'anggota802@gmail.com', NULL, '$2y$12$mzLrLgKH68S3B2/QZ6.4Ju.Bb5TKLFobKA.k0LWU0mpQo7.P/VA12', NULL, '2025-07-17 04:24:03', '2025-07-17 04:24:03', 'anggota'),
(804, 'Anggota 803', 'anggota803@gmail.com', NULL, '$2y$12$bH.bc3kM/eHbCUMBuPmp6.tnIgF53W2FoVDOYXQdUSZdNk4c9Tqpm', NULL, '2025-07-17 04:24:03', '2025-07-17 04:24:03', 'anggota'),
(805, 'Anggota 804', 'anggota804@gmail.com', NULL, '$2y$12$oWXDP/PjGnPfOgizuAnj.eYK2YFUZMsohintnl6DoskJOweDhtsDa', NULL, '2025-07-17 04:24:04', '2025-07-17 04:24:04', 'anggota'),
(806, 'Anggota 805', 'anggota805@gmail.com', NULL, '$2y$12$DJJN5ZxjbAVxLU97.MFygeKXWEUbUZEyWqYWId2dm3RVsbb.7DK.a', NULL, '2025-07-17 04:24:04', '2025-07-17 04:24:04', 'anggota'),
(807, 'Anggota 806', 'anggota806@gmail.com', NULL, '$2y$12$i7d7K6psiqPEgpWa9jplR.OLKjLG/ZSo0or8KVur9s3AJy6LMxSae', NULL, '2025-07-17 04:24:04', '2025-07-17 04:24:04', 'anggota'),
(808, 'Anggota 807', 'anggota807@gmail.com', NULL, '$2y$12$b8i.z1xDd0Rs78h14djJcuVo3wHbeoiNTJvcbtbCwMfAlCLMX/J0K', NULL, '2025-07-17 04:24:05', '2025-07-17 04:24:05', 'anggota'),
(809, 'Anggota 808', 'anggota808@gmail.com', NULL, '$2y$12$r48mWNad4OJ6qQ90PBc21OvQ15qISWJgtvqOEiLdzHIQp70lKHCmO', NULL, '2025-07-17 04:24:05', '2025-07-17 04:24:05', 'anggota'),
(810, 'Anggota 809', 'anggota809@gmail.com', NULL, '$2y$12$.Pd9CLI5bxKqiJYP8oN4NeIHlTT2HLdq3aMWojZRXJWNFWmCQMs0C', NULL, '2025-07-17 04:24:06', '2025-07-17 04:24:06', 'anggota'),
(811, 'Anggota 810', 'anggota810@gmail.com', NULL, '$2y$12$uYUCA9LRH/10K4Pn6PQAq.0Q1gSQSUScmfqD6bi5pmZrSwyoTf2xy', NULL, '2025-07-17 04:24:06', '2025-07-17 04:24:06', 'anggota'),
(812, 'Anggota 811', 'anggota811@gmail.com', NULL, '$2y$12$.v9wnv.1mPgSoCI5tbldyuJ19SAMb6GBu/zYopVJpPX1PkVa4ztO6', NULL, '2025-07-17 04:24:06', '2025-07-17 04:24:06', 'anggota'),
(813, 'Anggota 812', 'anggota812@gmail.com', NULL, '$2y$12$R/LjgPkOzL1dww41et5lQebXRfPLS8benerGFYjNifMHww8c/QKgC', NULL, '2025-07-17 04:24:07', '2025-07-17 04:24:07', 'anggota'),
(814, 'Anggota 813', 'anggota813@gmail.com', NULL, '$2y$12$fnT7nZS/agx46qf.np7NQOwndazehmdHhtTNDIAR1mnU/U0v3o0zi', NULL, '2025-07-17 04:24:07', '2025-07-17 04:24:07', 'anggota'),
(815, 'Anggota 814', 'anggota814@gmail.com', NULL, '$2y$12$IOH1CUODOOxW2HmzkJxDwegxYMSmRntogwfO5f0u/zf0eufJjRpAu', NULL, '2025-07-17 04:24:08', '2025-07-17 04:24:08', 'anggota'),
(816, 'Anggota 815', 'anggota815@gmail.com', NULL, '$2y$12$o6CjpIPitMmcLQNwGxFVN.xQQxi4j3OSDxwtI3kPQix94wkccl8Di', NULL, '2025-07-17 04:24:08', '2025-07-17 04:24:08', 'anggota'),
(817, 'Anggota 816', 'anggota816@gmail.com', NULL, '$2y$12$4w3xSatvn.uqH5BUhQsHmui2o.6pgXMUDTXs/JDVI7ge1TLP4oM5i', NULL, '2025-07-17 04:24:09', '2025-07-17 04:24:09', 'anggota'),
(818, 'Anggota 817', 'anggota817@gmail.com', NULL, '$2y$12$Kw89KFzv7t7xkKEwalmIaOLSuhTge0kRyAxoJ.gF0u7nsdGhjsAai', NULL, '2025-07-17 04:24:09', '2025-07-17 04:24:09', 'anggota'),
(819, 'Anggota 818', 'anggota818@gmail.com', NULL, '$2y$12$7F6b3arSNl61mIfWASPtb.ktRZ8LLD7rRexbLkBSibqh3ZcPeGb7W', NULL, '2025-07-17 04:24:09', '2025-07-17 04:24:09', 'anggota'),
(820, 'Anggota 819', 'anggota819@gmail.com', NULL, '$2y$12$D7JqcKUF58T6aj1mli/Jo.QvfSfozs6X8HH1Up7tNgYZ7IkkUfmbi', NULL, '2025-07-17 04:24:10', '2025-07-17 04:24:10', 'anggota'),
(821, 'Anggota 820', 'anggota820@gmail.com', NULL, '$2y$12$zor4GfpbCPPaWoImZHuWX.xCX6.BOrXBAQjGKnF3VQsZeNZJbIk/G', NULL, '2025-07-17 04:24:10', '2025-07-17 04:24:10', 'anggota'),
(822, 'Anggota 821', 'anggota821@gmail.com', NULL, '$2y$12$Efq3tw1zgOH.QQtw2W5LjuGZm2PNkZnKTMd916zR3jRDHPUYNRL6S', NULL, '2025-07-17 04:24:11', '2025-07-17 04:24:11', 'anggota'),
(823, 'Anggota 822', 'anggota822@gmail.com', NULL, '$2y$12$MGZuztbC4jz0/Vdmw0v9XeamSiOjIvw11FB6vbg6QKiJ04j2ga7Bi', NULL, '2025-07-17 04:24:11', '2025-07-17 04:24:11', 'anggota'),
(824, 'Anggota 823', 'anggota823@gmail.com', NULL, '$2y$12$t59rQh3c4OrRkAVlM2eUjeCjRjJMe2.D7BLfqWvoNuiPeg8cS3S9m', NULL, '2025-07-17 04:24:11', '2025-07-17 04:24:11', 'anggota'),
(825, 'Anggota 824', 'anggota824@gmail.com', NULL, '$2y$12$d3pdAZ88JUlUO29Ft0qZ2eVbul4sjoSTgUUovA1DFQ/wXtSHB93Lq', NULL, '2025-07-17 04:24:12', '2025-07-17 04:24:12', 'anggota'),
(826, 'Anggota 825', 'anggota825@gmail.com', NULL, '$2y$12$EfN65kRw3RGwol/9nnIi8.2/byMs0kqBdl6OPTUXnz9rvjaUSIgEy', NULL, '2025-07-17 04:24:12', '2025-07-17 04:24:12', 'anggota'),
(827, 'Anggota 826', 'anggota826@gmail.com', NULL, '$2y$12$fqLxFnzoQIlk5Jjf0PT1j.phJaF1dKy6jzLFqGTklseQr3cCDfaAm', NULL, '2025-07-17 04:24:13', '2025-07-17 04:24:13', 'anggota'),
(828, 'Anggota 827', 'anggota827@gmail.com', NULL, '$2y$12$XC8VX13zPBzAlAu4FhPeqOjy1kpEoJXOPBcDxgOKj3hiIUcc0puxS', NULL, '2025-07-17 04:24:13', '2025-07-17 04:24:13', 'anggota'),
(829, 'Anggota 828', 'anggota828@gmail.com', NULL, '$2y$12$Kks8WJvHgRumNbYKN7yphehdsBOAVGOoLkeLi3fKowif7rY4.yTmS', NULL, '2025-07-17 04:24:13', '2025-07-17 04:24:13', 'anggota'),
(830, 'Anggota 829', 'anggota829@gmail.com', NULL, '$2y$12$.A3fSbQOGfeXd3qq7FPn7OD4hOLfuVIpZ9PCfQJpmxiH.q0T3QNCu', NULL, '2025-07-17 04:24:14', '2025-07-17 04:24:14', 'anggota'),
(831, 'Anggota 830', 'anggota830@gmail.com', NULL, '$2y$12$sw8Ty5R0/uxk6y4gqvocj.Ddc2sASwU2/Y2bblpFYhVx6ZT452Ufy', NULL, '2025-07-17 04:24:14', '2025-07-17 04:24:14', 'anggota'),
(832, 'Anggota 831', 'anggota831@gmail.com', NULL, '$2y$12$t2bikAcwiA1VtZ/Aqbga8uzByiuRdIoKG9ObVBwUsPauxLHKTxqCe', NULL, '2025-07-17 04:24:14', '2025-07-17 04:24:14', 'anggota'),
(833, 'Anggota 832', 'anggota832@gmail.com', NULL, '$2y$12$gN/ggsDMPoDfusq39Hcj4Or7lm6BaxClZw7zYgt0sUpgBfTshYW4.', NULL, '2025-07-17 04:24:15', '2025-07-17 04:24:15', 'anggota'),
(834, 'Anggota 833', 'anggota833@gmail.com', NULL, '$2y$12$0HQxAk9MpgNiB3HEO9bNK.LnTW5ZoS0AxdIgVmhoAioCobwgf.j4e', NULL, '2025-07-17 04:24:15', '2025-07-17 04:24:15', 'anggota'),
(835, 'Anggota 834', 'anggota834@gmail.com', NULL, '$2y$12$z8xNyioQiZndbJpq2dKo6e7LMngGyj41opcosO3XD6c0RinMPr2ne', NULL, '2025-07-17 04:24:15', '2025-07-17 04:24:15', 'anggota'),
(836, 'Anggota 835', 'anggota835@gmail.com', NULL, '$2y$12$RctXwK3YgYO6GuwyI/wMeeyff1Y9QuTO1RHJNaqTKT6uxm2SeBtmS', NULL, '2025-07-17 04:24:16', '2025-07-17 04:24:16', 'anggota'),
(837, 'Anggota 836', 'anggota836@gmail.com', NULL, '$2y$12$l0G/WORbGF9eMUEX1ST55eU2WsGx1ep/30k3XotOLqYTd8DxbQH4O', NULL, '2025-07-17 04:24:16', '2025-07-17 04:24:16', 'anggota'),
(838, 'Anggota 837', 'anggota837@gmail.com', NULL, '$2y$12$wYDude0QEvGULQP0JgbezuNt8dpC.XDRKcTTr2qY/5zJatyJshdYG', NULL, '2025-07-17 04:24:16', '2025-07-17 04:24:16', 'anggota'),
(839, 'Anggota 838', 'anggota838@gmail.com', NULL, '$2y$12$BX7D303xh3hvk5mxstaMVeQwoem01dLbu.Jp3UaVHp0VyLFUM3/TC', NULL, '2025-07-17 04:24:17', '2025-07-17 04:24:17', 'anggota'),
(840, 'Anggota 839', 'anggota839@gmail.com', NULL, '$2y$12$oNEcewLREsdb8.wPbjToT.NnrMT7kXDkZwa6TlAGyj5856Tam6.ge', NULL, '2025-07-17 04:24:17', '2025-07-17 04:24:17', 'anggota'),
(841, 'Anggota 840', 'anggota840@gmail.com', NULL, '$2y$12$P4DhuMCdzW.f485QJCYg9uqxoG500ZlrOr40oJjOTs89pfUVnPV3m', NULL, '2025-07-17 04:24:17', '2025-07-17 04:24:17', 'anggota'),
(842, 'Anggota 841', 'anggota841@gmail.com', NULL, '$2y$12$uOWTRf4mCbYfGVdaOCr/mOkGtzPXakRFLWnJ3Ox/alNnBkOZo33FS', NULL, '2025-07-17 04:24:18', '2025-07-17 04:24:18', 'anggota'),
(843, 'Anggota 842', 'anggota842@gmail.com', NULL, '$2y$12$SkF2nUZySMKw3gCRtvI/LuxBBqTIRXYZClZKQ3xFTYh2pyUmR3//W', NULL, '2025-07-17 04:24:18', '2025-07-17 04:24:18', 'anggota'),
(844, 'Anggota 843', 'anggota843@gmail.com', NULL, '$2y$12$InJmJA6G12QvvQ6l68yh3ehvtj76UFaORs3FuwvtNPhIpM5jQT7Ze', NULL, '2025-07-17 04:24:18', '2025-07-17 04:24:18', 'anggota'),
(845, 'Anggota 844', 'anggota844@gmail.com', NULL, '$2y$12$x9Vd4Dzr/Px5tkWN2KpuVOmHNzTVqmbkwp31VS9W0X4Km6P96d192', NULL, '2025-07-17 04:24:18', '2025-07-17 04:24:18', 'anggota');
INSERT INTO `users` (`id`, `name`, `email`, `email_verified_at`, `password`, `remember_token`, `created_at`, `updated_at`, `role`) VALUES
(846, 'Anggota 845', 'anggota845@gmail.com', NULL, '$2y$12$nbdooeorXsPFvn4d9RnBIeeXNsFm2IXJO60unPYYWYAPo1L.ptrFK', NULL, '2025-07-17 04:24:19', '2025-07-17 04:24:19', 'anggota'),
(847, 'Anggota 846', 'anggota846@gmail.com', NULL, '$2y$12$VhjZ8sGGFG/rynOuByH3WeLXDOv47tSzOtXTzDrlCZpKE.RZ5mNpW', NULL, '2025-07-17 04:24:19', '2025-07-17 04:24:19', 'anggota'),
(848, 'Anggota 847', 'anggota847@gmail.com', NULL, '$2y$12$jminKvGGYhOVMTYbPgFqxOwu8PsDO3Rpix7P9X8.X5W8Xk9Z8kTFu', NULL, '2025-07-17 04:24:19', '2025-07-17 04:24:19', 'anggota'),
(849, 'Anggota 848', 'anggota848@gmail.com', NULL, '$2y$12$AKdjOpBLOKhMBu5NvwwVte6OOhchhbdBcDdDETBvOpOAFhmG.O/0u', NULL, '2025-07-17 04:24:20', '2025-07-17 04:24:20', 'anggota'),
(850, 'Anggota 849', 'anggota849@gmail.com', NULL, '$2y$12$W2/07ycJknKZvqGNwBgcwuDp8dMAad54uKuC1is1LhlbKvCOcNQTi', NULL, '2025-07-17 04:24:20', '2025-07-17 04:24:20', 'anggota'),
(851, 'Anggota 850', 'anggota850@gmail.com', NULL, '$2y$12$aSNi1JzdAQzN8AtAOin9KuGU.cta2xwp793Wp88oxZj8i6zFE.hKW', NULL, '2025-07-17 04:24:20', '2025-07-17 04:24:20', 'anggota'),
(852, 'Anggota 851', 'anggota851@gmail.com', NULL, '$2y$12$gHhOSBKY5reffu4GbZhQsOVH2B2bZvltMuZl/gYqMJiAoqT2iolgO', NULL, '2025-07-17 04:24:21', '2025-07-17 04:24:21', 'anggota'),
(853, 'Anggota 852', 'anggota852@gmail.com', NULL, '$2y$12$cj2HGGTPX.85tYBvZY/iJ.5YfDk5cTxFVLSO.4HDY.8..2ZGthMPO', NULL, '2025-07-17 04:24:21', '2025-07-17 04:24:21', 'anggota'),
(854, 'Anggota 853', 'anggota853@gmail.com', NULL, '$2y$12$LCIor0iDXtGSaTo0xHCPx.At1iFIuVPw3gGTr/EA3gm9B/uLSGHQ.', NULL, '2025-07-17 04:24:21', '2025-07-17 04:24:21', 'anggota'),
(855, 'Anggota 854', 'anggota854@gmail.com', NULL, '$2y$12$Kq3LfNNwS0XuQk.Xj9H7puPIWOfhX8gSiTUkDezj7l8zh2jGg3Tz.', NULL, '2025-07-17 04:24:22', '2025-07-17 04:24:22', 'anggota'),
(856, 'Anggota 855', 'anggota855@gmail.com', NULL, '$2y$12$mJm6Xd9lwcRrbm8Jr27tx.Q91o2wduDMUSxSpD8eD/Z8K3DHuPL7.', NULL, '2025-07-17 04:24:22', '2025-07-17 04:24:22', 'anggota'),
(857, 'Anggota 856', 'anggota856@gmail.com', NULL, '$2y$12$O5zyp0lHVm1T4Z0BMQUQ/.HvtUnYanv.rhNxBjX1SZz3/xQHB6fOO', NULL, '2025-07-17 04:24:23', '2025-07-17 04:24:23', 'anggota'),
(858, 'Anggota 857', 'anggota857@gmail.com', NULL, '$2y$12$ei6ufNPaVkT.Ptm4L6g3e.onYqhr6ChGKHMy7MCjTBmgl8vlp6WR2', NULL, '2025-07-17 04:24:23', '2025-07-17 04:24:23', 'anggota'),
(859, 'Anggota 858', 'anggota858@gmail.com', NULL, '$2y$12$4usLMQjR2rFaBr2KT5OQ4O8EQd1hacFVo1n2P8Pu5eG/VRdOIuRjm', NULL, '2025-07-17 04:24:23', '2025-07-17 04:24:23', 'anggota'),
(860, 'Anggota 859', 'anggota859@gmail.com', NULL, '$2y$12$OQQSmhxBHEt6FMOhDUwIWui1WsHp552iPww2wd.Tc784IL7cpglyC', NULL, '2025-07-17 04:24:24', '2025-07-17 04:24:24', 'anggota'),
(861, 'Anggota 860', 'anggota860@gmail.com', NULL, '$2y$12$oersrPJp0HwKi1wBd87Py.hI4tZlMWBriCA0nRGHe9qMKMxMeAj1.', NULL, '2025-07-17 04:24:24', '2025-07-17 04:24:24', 'anggota'),
(862, 'Anggota 861', 'anggota861@gmail.com', NULL, '$2y$12$1SnQ2Kh8bjQurj9LwVImf.maNpbBTWb71kHh7QLskLA2jfVZnvgxu', NULL, '2025-07-17 04:24:24', '2025-07-17 04:24:24', 'anggota'),
(863, 'Anggota 862', 'anggota862@gmail.com', NULL, '$2y$12$DGKdG7VfaVt7o9UO/nCfB.8kUJtjsM2/dhnvD63v1S3FIJWQUfDN6', NULL, '2025-07-17 04:24:24', '2025-07-17 04:24:24', 'anggota'),
(864, 'Anggota 863', 'anggota863@gmail.com', NULL, '$2y$12$I6lOiZqbKXBNfzYgS/UefusK6rkeQpFHQAWdghhedgKqU5Cw.IRl6', NULL, '2025-07-17 04:24:25', '2025-07-17 04:24:25', 'anggota'),
(865, 'Anggota 864', 'anggota864@gmail.com', NULL, '$2y$12$oniCz5gKHua1WWvNRxmLa.jPsVm5yJIDFEqyenqqylz.Ux6uGpF6e', NULL, '2025-07-17 04:24:25', '2025-07-17 04:24:25', 'anggota'),
(866, 'Anggota 865', 'anggota865@gmail.com', NULL, '$2y$12$MBvi3.gybVIJOXJKSygabeP5aeiLuwqmkSqSAwLq147vLNsL/PlPi', NULL, '2025-07-17 04:24:25', '2025-07-17 04:24:25', 'anggota'),
(867, 'Anggota 866', 'anggota866@gmail.com', NULL, '$2y$12$OZ0HQ0MLndZwnsGYiCZC.Okoaze0NgigeYMpq1kuLrT36iKZGUxnK', NULL, '2025-07-17 04:24:26', '2025-07-17 04:24:26', 'anggota'),
(868, 'Anggota 867', 'anggota867@gmail.com', NULL, '$2y$12$Y5XUnu9mfHVU5cOrsqGSUea6gaLH3OiKODS08T2TCBgpVbUhddgz.', NULL, '2025-07-17 04:24:26', '2025-07-17 04:24:26', 'anggota'),
(869, 'Anggota 868', 'anggota868@gmail.com', NULL, '$2y$12$F4hKl2zl74inIDMrLuPFz.yuOC4dC94UuDYFsYPaNCizIERKggBdO', NULL, '2025-07-17 04:24:26', '2025-07-17 04:24:26', 'anggota'),
(870, 'Anggota 869', 'anggota869@gmail.com', NULL, '$2y$12$17bWE2jwgsqQmwDyZOzaoeioA/f84AgIP1EcAj1UjJ7EuY8NVLOau', NULL, '2025-07-17 04:24:27', '2025-07-17 04:24:27', 'anggota'),
(871, 'Anggota 870', 'anggota870@gmail.com', NULL, '$2y$12$L7xr0lOP.f.jiKcrYly4xO0TLfrLopF2qfFPD2dwD1Xjoi9c3l9NG', NULL, '2025-07-17 04:24:27', '2025-07-17 04:24:27', 'anggota'),
(872, 'Anggota 871', 'anggota871@gmail.com', NULL, '$2y$12$SJgvwMAgMxwxQqkeBX1DouIW4VB5zsH8PHOcVJ9p7Uu3RyuGnq/Aq', NULL, '2025-07-17 04:24:27', '2025-07-17 04:24:27', 'anggota'),
(873, 'Anggota 872', 'anggota872@gmail.com', NULL, '$2y$12$2PGlACJhqrmrKnQagH02DuOY24qt8ZZaIa9BtaSyv6dgfNsXIhTvC', NULL, '2025-07-17 04:24:28', '2025-07-17 04:24:28', 'anggota'),
(874, 'Anggota 873', 'anggota873@gmail.com', NULL, '$2y$12$so8fGcd9qMivZev2Ngz2Bejr6BRCYQDTTjgHoQE3oJDDvwqi6aPbO', NULL, '2025-07-17 04:24:28', '2025-07-17 04:24:28', 'anggota'),
(875, 'Anggota 874', 'anggota874@gmail.com', NULL, '$2y$12$SDO6xD.q72gU8mJ8xMgDP.PqJUkixtpdzXz6R2hrxMoxm.IFX5wQm', NULL, '2025-07-17 04:24:28', '2025-07-17 04:24:28', 'anggota'),
(876, 'Anggota 875', 'anggota875@gmail.com', NULL, '$2y$12$tFGfSFOg0WL1uR.Me7f5quB.ePJWbfFbzVkrqSOKeWEiiWaTjz4ie', NULL, '2025-07-17 04:24:29', '2025-07-17 04:24:29', 'anggota'),
(877, 'Anggota 876', 'anggota876@gmail.com', NULL, '$2y$12$MhneY6GgyyKB9XTHayxnqOmhsveo/B2WtJ.IKcXi6GKyjhsZf98XW', NULL, '2025-07-17 04:24:29', '2025-07-17 04:24:29', 'anggota'),
(878, 'Anggota 877', 'anggota877@gmail.com', NULL, '$2y$12$8Fra33w70DuAKL2eYofPFevZpXKTBsFH6gxhMrOgdt.3le2U3EqXW', NULL, '2025-07-17 04:24:30', '2025-07-17 04:24:30', 'anggota'),
(879, 'Anggota 878', 'anggota878@gmail.com', NULL, '$2y$12$xo5a4l6X8DTLp4RceXM5l.0LIuEqbJwimuael30RIdAR9hUmchZrS', NULL, '2025-07-17 04:24:30', '2025-07-17 04:24:30', 'anggota'),
(880, 'Anggota 879', 'anggota879@gmail.com', NULL, '$2y$12$7Ot7PatyUR2L9t31E6tQHe62v8.CWICc8O5mQuAqMa6zpDKKVFV7m', NULL, '2025-07-17 04:24:30', '2025-07-17 04:24:30', 'anggota'),
(881, 'Anggota 880', 'anggota880@gmail.com', NULL, '$2y$12$j3V.TvU2DPDn5C2b9r4pZ.iR6k1pQQllc93p7eDkbJstFqP4y/K3.', NULL, '2025-07-17 04:24:31', '2025-07-17 04:24:31', 'anggota'),
(882, 'Anggota 881', 'anggota881@gmail.com', NULL, '$2y$12$Yi.964/6Puvmdu76zhJ4b.c/5BfU53wLhHgG07Z3s8kXKCS54PUqq', NULL, '2025-07-17 04:24:31', '2025-07-17 04:24:31', 'anggota'),
(883, 'Anggota 882', 'anggota882@gmail.com', NULL, '$2y$12$nniAhgFt8GUMmjW6IsJhGesU/3l6fPsQBKyRqyDCwFX/Wpzt6TYKe', NULL, '2025-07-17 04:24:32', '2025-07-17 04:24:32', 'anggota'),
(884, 'Anggota 883', 'anggota883@gmail.com', NULL, '$2y$12$M8iRpML40bA7D7p4knaShuQE8OoOJKA5H6tr15eJTrFKeaQ93VpHy', NULL, '2025-07-17 04:24:32', '2025-07-17 04:24:32', 'anggota'),
(885, 'Anggota 884', 'anggota884@gmail.com', NULL, '$2y$12$yQ0VbASwoW6Dho9GOePm5e4OoTuTVjpoIs7nQqBgYPQIpXGHeQglq', NULL, '2025-07-17 04:24:33', '2025-07-17 04:24:33', 'anggota'),
(886, 'Anggota 885', 'anggota885@gmail.com', NULL, '$2y$12$xx75CU0o/WRLuMhs2vEOe.FhAq7228q9cX.qqV.iY5xUcqH.lVvEe', NULL, '2025-07-17 04:24:33', '2025-07-17 04:24:33', 'anggota'),
(887, 'Anggota 886', 'anggota886@gmail.com', NULL, '$2y$12$BJZAa8y3K4B8JxUC4/G4VO53IoqCzvjSF0BK0SK.yooavNTGScp0G', NULL, '2025-07-17 04:24:33', '2025-07-17 04:24:33', 'anggota'),
(888, 'Anggota 887', 'anggota887@gmail.com', NULL, '$2y$12$QaRmG.s8fMalv1kw23y91.1WLWOSMd/yy5m1.zwT5/b9H9wbY140y', NULL, '2025-07-17 04:24:34', '2025-07-17 04:24:34', 'anggota'),
(889, 'Anggota 888', 'anggota888@gmail.com', NULL, '$2y$12$vne6X9eiEwWxAtju7LOTJuiaeOKHSpzK/i8Z2FCwHamoq3f828YR2', NULL, '2025-07-17 04:24:34', '2025-07-17 04:24:34', 'anggota'),
(890, 'Anggota 889', 'anggota889@gmail.com', NULL, '$2y$12$wZH1IijfJTdFnhSVHAI1AujidetjVGm1jjU6bWlx9CPJ0lW4yXn.W', NULL, '2025-07-17 04:24:34', '2025-07-17 04:24:34', 'anggota'),
(891, 'Anggota 890', 'anggota890@gmail.com', NULL, '$2y$12$gWaWaqVgdW9wbWifBRUyjOY9xLfutNKayDvVsqb4y4COmxOWIO2Rm', NULL, '2025-07-17 04:24:35', '2025-07-17 04:24:35', 'anggota'),
(892, 'Anggota 891', 'anggota891@gmail.com', NULL, '$2y$12$4fNthBQmk7KjpJtP7ghkpObE0a27v0i7fRnjYxzqpW0a2nHjypMnq', NULL, '2025-07-17 04:24:35', '2025-07-17 04:24:35', 'anggota'),
(893, 'Anggota 892', 'anggota892@gmail.com', NULL, '$2y$12$CPh3DabM6LbLRgltpa8qkuUmYtaG5Cc5w3zVnMzvwYZe6fL4qG5v.', NULL, '2025-07-17 04:24:36', '2025-07-17 04:24:36', 'anggota'),
(894, 'Anggota 893', 'anggota893@gmail.com', NULL, '$2y$12$BZE0MB9MG7yijSTct5vJVu8wO8gsznpaKq/GcJ.sDVPBWvxAi7Zg6', NULL, '2025-07-17 04:24:36', '2025-07-17 04:24:36', 'anggota'),
(895, 'Anggota 894', 'anggota894@gmail.com', NULL, '$2y$12$pwPtuyl//qU1.U9MCDSKP.hZlmb4uRaOOdVetLANTukSYjn6RQz9y', NULL, '2025-07-17 04:24:36', '2025-07-17 04:24:36', 'anggota'),
(896, 'Anggota 895', 'anggota895@gmail.com', NULL, '$2y$12$.CPJ.GwE9mfIToN7ylFVUuaUx7ildxDiu0ohmUY.kNjsi4UIIqlB2', NULL, '2025-07-17 04:24:37', '2025-07-17 04:24:37', 'anggota'),
(897, 'Anggota 896', 'anggota896@gmail.com', NULL, '$2y$12$wRSSRb9BXpHqMpZ.P2.SauK31O5h231lov5WT00lJ081Dwxvenh5G', NULL, '2025-07-17 04:24:37', '2025-07-17 04:24:37', 'anggota'),
(898, 'Anggota 897', 'anggota897@gmail.com', NULL, '$2y$12$n8ddKgPF59CkOByXl8hnxuFz1eknNOZlyFXUUsZtUKZY7nv7oPGA6', NULL, '2025-07-17 04:24:38', '2025-07-17 04:24:38', 'anggota'),
(899, 'Anggota 898', 'anggota898@gmail.com', NULL, '$2y$12$rAiHbvUX.mQK9uHVN.pZIOdy0FiiOQhmoicJRK1oJ.Qdpppq7BBAC', NULL, '2025-07-17 04:24:38', '2025-07-17 04:24:38', 'anggota'),
(900, 'Anggota 899', 'anggota899@gmail.com', NULL, '$2y$12$/fBgixMkVPelSLRFzdaKgOCrBQvqPKnPdgjBKpxqcc1eYyfwxLiaW', NULL, '2025-07-17 04:24:38', '2025-07-17 04:24:38', 'anggota'),
(901, 'Anggota 900', 'anggota900@gmail.com', NULL, '$2y$12$nMvtREPy2/uGjfWnY4Owg.nQkFunQWvi/8gM75WVn0RKYoj.PzlV.', NULL, '2025-07-17 04:24:39', '2025-07-17 04:24:39', 'anggota'),
(902, 'Anggota 901', 'anggota901@gmail.com', NULL, '$2y$12$Ng1xDG9ivP0/pAYbKl.L3elgWAWBvuH0Wm8tj2TrqpqGrBdFBcRsu', NULL, '2025-07-17 04:24:39', '2025-07-17 04:24:39', 'anggota'),
(903, 'Anggota 902', 'anggota902@gmail.com', NULL, '$2y$12$BD4eHxehmmyFG7EURgVRje75pgz4FjZ3qNA4GYKy75Al/DN0gJ6HC', NULL, '2025-07-17 04:24:40', '2025-07-17 04:24:40', 'anggota'),
(904, 'Anggota 903', 'anggota903@gmail.com', NULL, '$2y$12$YnWLw.84rsyyonAXTcYYreOLYt0/6tFc74uWx5a6fBheK.LNy1PUS', NULL, '2025-07-17 04:24:40', '2025-07-17 04:24:40', 'anggota'),
(905, 'Anggota 904', 'anggota904@gmail.com', NULL, '$2y$12$avsgT6Sh4p2LwjYE2FAfYeDKsN5..PLiWd/rtCR8kONBeCzvqBJce', NULL, '2025-07-17 04:24:40', '2025-07-17 04:24:40', 'anggota'),
(906, 'Anggota 905', 'anggota905@gmail.com', NULL, '$2y$12$ut2hoLxTOEZB9iE0O248sep4tTuxbr/Ljs74FPT92U0nUjvzQrra.', NULL, '2025-07-17 04:24:41', '2025-07-17 04:24:41', 'anggota'),
(907, 'Anggota 906', 'anggota906@gmail.com', NULL, '$2y$12$JYEln8MPGmgEUfoGCGNCPemzUfKKIj1ywnUQdHL6fx.JTBc3vX77q', NULL, '2025-07-17 04:24:41', '2025-07-17 04:24:41', 'anggota'),
(908, 'Anggota 907', 'anggota907@gmail.com', NULL, '$2y$12$QccPSAQVch2XaiiknGc15el3YtLZxdiLECztly.GdVU.TLj9TRfeK', NULL, '2025-07-17 04:24:42', '2025-07-17 04:24:42', 'anggota'),
(909, 'Anggota 908', 'anggota908@gmail.com', NULL, '$2y$12$y6v./e36TCEfpqbLYIikUuC17FTH94joDqoMh3PmC/N8d1kE1jp9.', NULL, '2025-07-17 04:24:42', '2025-07-17 04:24:42', 'anggota'),
(910, 'Anggota 909', 'anggota909@gmail.com', NULL, '$2y$12$VVfWa/SaJ6B0rGsIS6LoJuygyJ/D8oqpzs21BGhnwK4j0VmsbX61q', NULL, '2025-07-17 04:24:42', '2025-07-17 04:24:42', 'anggota'),
(911, 'Anggota 910', 'anggota910@gmail.com', NULL, '$2y$12$0IarkzzJgq9CsXwDpvsIMOjhUSZ8U5jFnnbthrsTkC/6zNOMATogK', NULL, '2025-07-17 04:24:43', '2025-07-17 04:24:43', 'anggota'),
(912, 'Anggota 911', 'anggota911@gmail.com', NULL, '$2y$12$eVE7bEShUjvnUM16zAgeguvxm5XYKFwgScoedSw6dPWyBLDl5qyaO', NULL, '2025-07-17 04:24:43', '2025-07-17 04:24:43', 'anggota'),
(913, 'Anggota 912', 'anggota912@gmail.com', NULL, '$2y$12$YX8fswVaZ8WO5uho7KvEw.FXnVHxsahx/uKsrGIO0PG/h6VOiaydy', NULL, '2025-07-17 04:24:44', '2025-07-17 04:24:44', 'anggota'),
(914, 'Anggota 913', 'anggota913@gmail.com', NULL, '$2y$12$jvsEROFeHLjoFtcJ6Ly26uAQv.CYq0WoCxHc1tnAI63qf//UGBXvu', NULL, '2025-07-17 04:24:44', '2025-07-17 04:24:44', 'anggota'),
(915, 'Anggota 914', 'anggota914@gmail.com', NULL, '$2y$12$jytI.sGkfsh5iqOW65UFP.6RGLrmizhUpt8HZQp4.2P5CSSk284qy', NULL, '2025-07-17 04:24:44', '2025-07-17 04:24:44', 'anggota'),
(916, 'Anggota 915', 'anggota915@gmail.com', NULL, '$2y$12$4OMO2IU/v02KNgU8VJi9HOZ6yXwB1OHCprvtbU9CnuvRbJOgIeVFu', NULL, '2025-07-17 04:24:45', '2025-07-17 04:24:45', 'anggota'),
(917, 'Anggota 916', 'anggota916@gmail.com', NULL, '$2y$12$gggEaO/NwCk/nWzvWMbi6ezJPCYLFwtzrEVQDwHUped4xVJxHz5P.', NULL, '2025-07-17 04:24:45', '2025-07-17 04:24:45', 'anggota'),
(918, 'Anggota 917', 'anggota917@gmail.com', NULL, '$2y$12$ZuEbJjBNptzqFV3qxMF0led8v1hMr5QWzY3s/Ds4CTcyuT2xR18S2', NULL, '2025-07-17 04:24:46', '2025-07-17 04:24:46', 'anggota'),
(919, 'Anggota 918', 'anggota918@gmail.com', NULL, '$2y$12$ldPRQwsDqzdDMX1Z0YKN.OrAojCACW78Vm7LOcJVhx1CxKH5g/6da', NULL, '2025-07-17 04:24:46', '2025-07-17 04:24:46', 'anggota'),
(920, 'Anggota 919', 'anggota919@gmail.com', NULL, '$2y$12$X/1uu3k8WvWteR6sDpg2w.OzN94XOvmTgwSh/dUQuHeh8cxK3/RRC', NULL, '2025-07-17 04:24:46', '2025-07-17 04:24:46', 'anggota'),
(921, 'Anggota 920', 'anggota920@gmail.com', NULL, '$2y$12$./tTNEfyi4UTw5.nC1jKr.nWPyDVTD/LJ8VBlX26RGG2ehx.OBcVi', NULL, '2025-07-17 04:24:47', '2025-07-17 04:24:47', 'anggota'),
(922, 'Anggota 921', 'anggota921@gmail.com', NULL, '$2y$12$osNLPRZxidr4weI0rda0Oe7LoR2REvuvYstmWFNCjudk4MOzQs49q', NULL, '2025-07-17 04:24:47', '2025-07-17 04:24:47', 'anggota'),
(923, 'Anggota 922', 'anggota922@gmail.com', NULL, '$2y$12$hngnbCbVAUonfQC25D3VdeE03tuvgltn45rotPJhF9zgb2TXJb3Qq', NULL, '2025-07-17 04:24:48', '2025-07-17 04:24:48', 'anggota'),
(924, 'Anggota 923', 'anggota923@gmail.com', NULL, '$2y$12$cYA2sHlqGzrEE49tCZ1XU.vhdC/exfJ2XeYK2rVz5r6jlOZVCNWSi', NULL, '2025-07-17 04:24:48', '2025-07-17 04:24:48', 'anggota'),
(925, 'Anggota 924', 'anggota924@gmail.com', NULL, '$2y$12$.hBdl14AyelYEEcEFjzHCuzbCpHM6seMIvxMd8hi/dD0t3GV8HEOK', NULL, '2025-07-17 04:24:48', '2025-07-17 04:24:48', 'anggota'),
(926, 'Anggota 925', 'anggota925@gmail.com', NULL, '$2y$12$/CFoLfsprGgrvJoCdLoCd.qgItPAcv2754SpiEKFOXGMgwj5XmK.m', NULL, '2025-07-17 04:24:49', '2025-07-17 04:24:49', 'anggota'),
(927, 'Anggota 926', 'anggota926@gmail.com', NULL, '$2y$12$TRmC.kHGqEZfv8ykyFxEPOX5XZSGs50xCrI7YmCRx7cU7fubdLTA.', NULL, '2025-07-17 04:24:49', '2025-07-17 04:24:49', 'anggota'),
(928, 'Anggota 927', 'anggota927@gmail.com', NULL, '$2y$12$DkrIttE3AUrpZ6EGWkTPyueZSJjPf0QCltgKC3BEfkU76LSxcLZrq', NULL, '2025-07-17 04:24:50', '2025-07-17 04:24:50', 'anggota'),
(929, 'Anggota 928', 'anggota928@gmail.com', NULL, '$2y$12$iHEoJCHhKZuf/r.Zt9LLGOleRZkefvcBKIJWevv7vTSRFiyTKfdey', NULL, '2025-07-17 04:24:50', '2025-07-17 04:24:50', 'anggota'),
(930, 'Anggota 929', 'anggota929@gmail.com', NULL, '$2y$12$aG1n.S6hg6aSuHgge30XDOHedLKPzoBn5syL1BXErQLQAu6ptXDCS', NULL, '2025-07-17 04:24:50', '2025-07-17 04:24:50', 'anggota'),
(931, 'Anggota 930', 'anggota930@gmail.com', NULL, '$2y$12$tG6pzLquss63JsZ.wBRifuIq2dnBp8YZ9Sc6Tze2QzBSDkqk/AVze', NULL, '2025-07-17 04:24:51', '2025-07-17 04:24:51', 'anggota'),
(932, 'Anggota 931', 'anggota931@gmail.com', NULL, '$2y$12$9tIzFZxaKC1Pz0oZ0rp37OdrGsauPsr2GxPv.EyGCPbhD5FeDpgxm', NULL, '2025-07-17 04:24:51', '2025-07-17 04:24:51', 'anggota'),
(933, 'Anggota 932', 'anggota932@gmail.com', NULL, '$2y$12$L12O7mBSsY8idedPTYqziuB5MrmAPo.12ICULlFVyUIz.h/pz6wUK', NULL, '2025-07-17 04:24:52', '2025-07-17 04:24:52', 'anggota'),
(934, 'Anggota 933', 'anggota933@gmail.com', NULL, '$2y$12$bd..japF6BfRm2n1vjp06.us3bFMw6lJJTaEZZWcZbAI50ka27dvi', NULL, '2025-07-17 04:24:52', '2025-07-17 04:24:52', 'anggota'),
(935, 'Anggota 934', 'anggota934@gmail.com', NULL, '$2y$12$hI.tDR87jzLu1hoDjetSEu0hfmQE1Z4ZtXIFZfccXOpqfx/tDxMl.', NULL, '2025-07-17 04:24:53', '2025-07-17 04:24:53', 'anggota'),
(936, 'Anggota 935', 'anggota935@gmail.com', NULL, '$2y$12$jrYzJPGABXvPirCzqhlK6e7inBqGW6qOSCaHSOobARt9DCMI2PoK.', NULL, '2025-07-17 04:24:53', '2025-07-17 04:24:53', 'anggota'),
(937, 'Anggota 936', 'anggota936@gmail.com', NULL, '$2y$12$hVETDugfsMNLVEHBvrUlp.b.CIDJik8.Z0mXxUCCB8fMEkA3vd/Cu', NULL, '2025-07-17 04:24:53', '2025-07-17 04:24:53', 'anggota'),
(938, 'Anggota 937', 'anggota937@gmail.com', NULL, '$2y$12$S9dEZYh8YAjwBderOR1.vu38dgJH12.Le93A5u9eb4QFFNVdxK3gS', NULL, '2025-07-17 04:24:54', '2025-07-17 04:24:54', 'anggota'),
(939, 'Anggota 938', 'anggota938@gmail.com', NULL, '$2y$12$tCYKlAYGWTZyDYY0PN.Eme0cmy1hBkZCe0KC6m/mVYsiBk8MvXUce', NULL, '2025-07-17 04:24:54', '2025-07-17 04:24:54', 'anggota'),
(940, 'Anggota 939', 'anggota939@gmail.com', NULL, '$2y$12$CLnUEAd6qx5b3QUTjJ2LM.Zx/iDCj.OejhoLyP62Ht/M9WYNXj0Ki', NULL, '2025-07-17 04:24:54', '2025-07-17 04:24:54', 'anggota'),
(941, 'Anggota 940', 'anggota940@gmail.com', NULL, '$2y$12$fOjgDUyqtXsi46ugemHjfOSocdH.Vlh3AaS9TPlT.2M./NVEgNh7u', NULL, '2025-07-17 04:24:55', '2025-07-17 04:24:55', 'anggota'),
(942, 'Anggota 941', 'anggota941@gmail.com', NULL, '$2y$12$gjO5hm4K6/q27raA4BeHW.HbwPF0sYZ9F8ceexc3h1Zg/m18DZ62G', NULL, '2025-07-17 04:24:55', '2025-07-17 04:24:55', 'anggota'),
(943, 'Anggota 942', 'anggota942@gmail.com', NULL, '$2y$12$CX3mIDrQiVWRcf5pWZuxtOxHHTwO.dPCmJ4G4544MXnHiAaxUTSD2', NULL, '2025-07-17 04:24:56', '2025-07-17 04:24:56', 'anggota'),
(944, 'Anggota 943', 'anggota943@gmail.com', NULL, '$2y$12$qaJQFPppMqrSUkoVc5y7j.HDg9fqqjNBUSuzoWvrMIOkDiv5OOXWy', NULL, '2025-07-17 04:24:56', '2025-07-17 04:24:56', 'anggota'),
(945, 'Anggota 944', 'anggota944@gmail.com', NULL, '$2y$12$t1rtfp9kLkWKPGs0gevE.ubfuwK8HUSNWKsSxbDnigcuN295.gOLy', NULL, '2025-07-17 04:24:56', '2025-07-17 04:24:56', 'anggota'),
(946, 'Anggota 945', 'anggota945@gmail.com', NULL, '$2y$12$19M.oznIC/yh3R7KhNfIU.A7eYzGmh4BzfEZyu4ge641FLvrH.Kki', NULL, '2025-07-17 04:24:57', '2025-07-17 04:24:57', 'anggota'),
(947, 'Anggota 946', 'anggota946@gmail.com', NULL, '$2y$12$xxgCqX6MQqTSxVzKDIC8qegkNa0GogrFGlGr/Bna736d4/5Hsz4fi', NULL, '2025-07-17 04:24:57', '2025-07-17 04:24:57', 'anggota'),
(948, 'Anggota 947', 'anggota947@gmail.com', NULL, '$2y$12$NcbECO14numeOjjgiB6yWe2l4OJWdidKT5QQglOgd90H.6IJW2MJu', NULL, '2025-07-17 04:24:57', '2025-07-17 04:24:57', 'anggota'),
(949, 'Anggota 948', 'anggota948@gmail.com', NULL, '$2y$12$P4fjARpJg8K8MQAcWkRFNeazvCzv9vs8jkxR81/c5NMw72dSo0ru2', NULL, '2025-07-17 04:24:58', '2025-07-17 04:24:58', 'anggota'),
(950, 'Anggota 949', 'anggota949@gmail.com', NULL, '$2y$12$GKin4Le6bbSeUD5Ooc6nAuhu6LI7zM64ckZoGkshkupLwdTohHtYO', NULL, '2025-07-17 04:24:58', '2025-07-17 04:24:58', 'anggota'),
(951, 'Anggota 950', 'anggota950@gmail.com', NULL, '$2y$12$f01KwIRe..M4fx.pRXULbO7JkiQEwStTHmEVEe3ZGpHYV4LdnjJ2q', NULL, '2025-07-17 04:24:59', '2025-07-17 04:24:59', 'anggota'),
(952, 'Anggota 951', 'anggota951@gmail.com', NULL, '$2y$12$5a7NMfJDwhfXVciZG.tgRO3HL4LPCfHdVCoru5Nm0A/63Z3Qfyv/u', NULL, '2025-07-17 04:24:59', '2025-07-17 04:24:59', 'anggota'),
(953, 'Anggota 952', 'anggota952@gmail.com', NULL, '$2y$12$wxvj14ELFbUkwxFrKSwYDObNwAKGOp1unOIZ/6AdMMoK6MvwBa5sG', NULL, '2025-07-17 04:24:59', '2025-07-17 04:24:59', 'anggota'),
(954, 'Anggota 953', 'anggota953@gmail.com', NULL, '$2y$12$WTO3YRxKGMD3wDd9aQnuKOA.9RwBUS8km674WPJ3IIoVcYTHVUxv6', NULL, '2025-07-17 04:25:00', '2025-07-17 04:25:00', 'anggota'),
(955, 'Anggota 954', 'anggota954@gmail.com', NULL, '$2y$12$zb09SXh6/Voh9dkJ6Cs8q.6QL.Y31a/LM74/YeI5hBJIMf/OlGOBy', NULL, '2025-07-17 04:25:00', '2025-07-17 04:25:00', 'anggota'),
(956, 'Anggota 955', 'anggota955@gmail.com', NULL, '$2y$12$sO05g3hzu8GBaSG./uFyJuD1WFc4uralSs9UTeTTqI56Fk9GJbimm', NULL, '2025-07-17 04:25:00', '2025-07-17 04:25:00', 'anggota'),
(957, 'Anggota 956', 'anggota956@gmail.com', NULL, '$2y$12$9ej/LNug5mEEeHb3/h0sUu//xUq1KV5lSbh/aHS/DXfHmFVZqTEBe', NULL, '2025-07-17 04:25:01', '2025-07-17 04:25:01', 'anggota'),
(958, 'Anggota 957', 'anggota957@gmail.com', NULL, '$2y$12$1XvfkuLVICYeynn9AZ8e0OzKvb4QiSCMLHVxClp6rSHGMo7VIgI0q', NULL, '2025-07-17 04:25:01', '2025-07-17 04:25:01', 'anggota'),
(959, 'Anggota 958', 'anggota958@gmail.com', NULL, '$2y$12$pHArMjnL6c2tCTcJ6OnvpOpnDIBI.qjNsBwnN308kWhqu0BX.ojL6', NULL, '2025-07-17 04:25:02', '2025-07-17 04:25:02', 'anggota'),
(960, 'Anggota 959', 'anggota959@gmail.com', NULL, '$2y$12$ieSx1epYv0wznwwDjSyvG.FniC3s5hDjiiWa/g3aFxgeK6AWKl3Hm', NULL, '2025-07-17 04:25:02', '2025-07-17 04:25:02', 'anggota'),
(961, 'Anggota 960', 'anggota960@gmail.com', NULL, '$2y$12$AT2npuVa6AFaYvFHa23UFuuzpkyEONNND2Y9DmugE1sH5xYjZlON2', NULL, '2025-07-17 04:25:02', '2025-07-17 04:25:02', 'anggota'),
(962, 'Anggota 961', 'anggota961@gmail.com', NULL, '$2y$12$RCfh3W8PIycZlu8zkLl7RukRN/TiP959BHWph.yuGxi99PEWSD8xO', NULL, '2025-07-17 04:25:03', '2025-07-17 04:25:03', 'anggota'),
(963, 'Anggota 962', 'anggota962@gmail.com', NULL, '$2y$12$sIfdihdgWTLMEMHIm9.ABeO.rO89KsFAGoPFE6r7YoiTXdTvG.R1q', NULL, '2025-07-17 04:25:03', '2025-07-17 04:25:03', 'anggota'),
(964, 'Anggota 963', 'anggota963@gmail.com', NULL, '$2y$12$Bt33n7kyehCHuvosLgFJwOa.LlKHbmU3bMVKcPnwBJCbMM3YxehJK', NULL, '2025-07-17 04:25:04', '2025-07-17 04:25:04', 'anggota'),
(965, 'Anggota 964', 'anggota964@gmail.com', NULL, '$2y$12$RjF5JrXIV5AyyShRGUya/ukJsJkfff76ADjjfwAotqKJpm8fMl/76', NULL, '2025-07-17 04:25:04', '2025-07-17 04:25:04', 'anggota'),
(966, 'Anggota 965', 'anggota965@gmail.com', NULL, '$2y$12$MHj17pKOpC8SkxuCtCngwei4Q1QQB1O/QFAm4.37lOz63cdGn/q9m', NULL, '2025-07-17 04:25:05', '2025-07-17 04:25:05', 'anggota'),
(967, 'Anggota 966', 'anggota966@gmail.com', NULL, '$2y$12$YCSpBVEkc1O2XpnV1RYWTuT8/aAgq.jEmnJhTHGxzDxoZ/rZ.pVdC', NULL, '2025-07-17 04:25:05', '2025-07-17 04:25:05', 'anggota'),
(968, 'Anggota 967', 'anggota967@gmail.com', NULL, '$2y$12$yoSEmGEmAW/B1lgD5XL4zejX5KP4gs8zB/.Mk0w6XH6DZIvAC8NCu', NULL, '2025-07-17 04:25:05', '2025-07-17 04:25:05', 'anggota'),
(969, 'Anggota 968', 'anggota968@gmail.com', NULL, '$2y$12$cbhUp0km1JMmI1nnytPuKucDVkpYSrzb4j2bCDvOOCfrPtnTiCqRi', NULL, '2025-07-17 04:25:06', '2025-07-17 04:25:06', 'anggota'),
(970, 'Anggota 969', 'anggota969@gmail.com', NULL, '$2y$12$sUi.d28PmOVvDVbVY4UGlOBObr4PoJw6c2XoOkN7.Kww4Aetwnbp6', NULL, '2025-07-17 04:25:06', '2025-07-17 04:25:06', 'anggota'),
(971, 'Anggota 970', 'anggota970@gmail.com', NULL, '$2y$12$GY59Uxn1UU1Lk/DxsETWbuL6ImdqQ13o7SnkgwpOt8tfgMsJN59uu', NULL, '2025-07-17 04:25:07', '2025-07-17 04:25:07', 'anggota'),
(972, 'Anggota 971', 'anggota971@gmail.com', NULL, '$2y$12$PxCa8j.MRFSWWT9hK11r3uToOHI2CDZeZIuHC9QjR7FBib9PITqJO', NULL, '2025-07-17 04:25:07', '2025-07-17 04:25:07', 'anggota'),
(973, 'Anggota 972', 'anggota972@gmail.com', NULL, '$2y$12$JPXJICcUXhbjCopmmFOC0em1Lrtyk9EeOEVHO.2n4ZkskMyX5p3ly', NULL, '2025-07-17 04:25:08', '2025-07-17 04:25:08', 'anggota'),
(974, 'Anggota 973', 'anggota973@gmail.com', NULL, '$2y$12$o9cwJOg86XkEXKKlK5Kzq.VfULBRwo9WP0CVDubHEb.zthRRCArhK', NULL, '2025-07-17 04:25:08', '2025-07-17 04:25:08', 'anggota'),
(975, 'Anggota 974', 'anggota974@gmail.com', NULL, '$2y$12$LDxa.y3d5hJ4cy22v3XB/e8YwdTflBAluE5JDOzj6mbjZwzr4.Cfe', NULL, '2025-07-17 04:25:08', '2025-07-17 04:25:08', 'anggota'),
(976, 'Anggota 975', 'anggota975@gmail.com', NULL, '$2y$12$Nfb.hEfi55veqRWQsvYNt.nisV5YcX9MnZZ8Pt8veWh6/ZY08KM2i', NULL, '2025-07-17 04:25:09', '2025-07-17 04:25:09', 'anggota'),
(977, 'Anggota 976', 'anggota976@gmail.com', NULL, '$2y$12$HbWwnEy.J02.4mmeIBE8eOoECY6SDHACTIh0bVcMAErIDZNlwojBq', NULL, '2025-07-17 04:25:09', '2025-07-17 04:25:09', 'anggota'),
(978, 'Anggota 977', 'anggota977@gmail.com', NULL, '$2y$12$JL05LUrP3MrOEW7wkQABI.GcywPje10KkmaPlH7/pejkVeLDZ9Lwy', NULL, '2025-07-17 04:25:09', '2025-07-17 04:25:09', 'anggota'),
(979, 'Anggota 978', 'anggota978@gmail.com', NULL, '$2y$12$Zkrq94Q9DhWaZEavt1wCuepqNjT9d6iBVWKT2tCUeQTA2zwv3HTZ2', NULL, '2025-07-17 04:25:10', '2025-07-17 04:25:10', 'anggota'),
(980, 'Anggota 979', 'anggota979@gmail.com', NULL, '$2y$12$GpIruLz.RCriN7i2mdWw2OBkICFtQvIV5sR/E2WksdchKnogXzdoW', NULL, '2025-07-17 04:25:10', '2025-07-17 04:25:10', 'anggota'),
(981, 'Anggota 980', 'anggota980@gmail.com', NULL, '$2y$12$aDa.7X1ru3Gs5Nh7bf2CMeMFukCtez3.Z3jk993HzPBHn21HdIBNm', NULL, '2025-07-17 04:25:10', '2025-07-17 04:25:10', 'anggota'),
(982, 'Anggota 981', 'anggota981@gmail.com', NULL, '$2y$12$wJunYz/.BpSCu3WjFzRwdeA0CrVxCl4ehRVP8S7uR0ap5chGBUJYa', NULL, '2025-07-17 04:25:11', '2025-07-17 04:25:11', 'anggota'),
(983, 'Anggota 982', 'anggota982@gmail.com', NULL, '$2y$12$UtrthUQVV9UPXA1Zxatl..8ffYMm36upqRZUo.kemkGiTgqEKbory', NULL, '2025-07-17 04:25:11', '2025-07-17 04:25:11', 'anggota'),
(984, 'Anggota 983', 'anggota983@gmail.com', NULL, '$2y$12$w4oUlSutKUxoITpOEJ8WxOk1fH/.NEjZoRq31Wo1u14wbolo44BDS', NULL, '2025-07-17 04:25:12', '2025-07-17 04:25:12', 'anggota'),
(985, 'Anggota 984', 'anggota984@gmail.com', NULL, '$2y$12$RyxNQbAucKsuY20Q3HMPQOVM0f1icKzOGdvO6qATkXX0HjZqtK4uS', NULL, '2025-07-17 04:25:12', '2025-07-17 04:25:12', 'anggota'),
(986, 'Anggota 985', 'anggota985@gmail.com', NULL, '$2y$12$z8Uh1mkHvADWBBFc0jOfP.Pvy3XYXt5YP4eqnSJxG238ofJOgn78W', NULL, '2025-07-17 04:25:12', '2025-07-17 04:25:12', 'anggota'),
(987, 'Anggota 986', 'anggota986@gmail.com', NULL, '$2y$12$/XhzNIuFR0FkDQLDPWnk0uCCzgQg32QVjNtqIIL3qsIwAdw1kIFni', NULL, '2025-07-17 04:25:13', '2025-07-17 04:25:13', 'anggota'),
(988, 'Anggota 987', 'anggota987@gmail.com', NULL, '$2y$12$2GcWoJAKDtazFNWVMX.44u9WmgMcUp91I.vqko/XUdT1bldNuexnu', NULL, '2025-07-17 04:25:13', '2025-07-17 04:25:13', 'anggota'),
(989, 'Anggota 988', 'anggota988@gmail.com', NULL, '$2y$12$T2MZT3OnIQk4ozjevO9e4u7XwdPwKY.qgcjBcIuReqDbIRum6wbu6', NULL, '2025-07-17 04:25:14', '2025-07-17 04:25:14', 'anggota'),
(990, 'Anggota 989', 'anggota989@gmail.com', NULL, '$2y$12$k/t416ptNkgyUn3XiAl9C.2xCz0wTW/wlTys3JUHqppSNQHUyMknG', NULL, '2025-07-17 04:25:14', '2025-07-17 04:25:14', 'anggota'),
(991, 'Anggota 990', 'anggota990@gmail.com', NULL, '$2y$12$lEpEh/FimEB7W0Om7A2SjOrjIRW6Ha/UoN0BtoC8DV/7TpdbWwVAy', NULL, '2025-07-17 04:25:15', '2025-07-17 04:25:15', 'anggota'),
(992, 'Anggota 991', 'anggota991@gmail.com', NULL, '$2y$12$BIXI2i8sIVT/uH2VCRxJyeLtdMfCGIla6WyYSW4ndXP0zOCLWNUDm', NULL, '2025-07-17 04:25:15', '2025-07-17 04:25:15', 'anggota'),
(993, 'Anggota 992', 'anggota992@gmail.com', NULL, '$2y$12$LP/ULBUKnjflSRr3k4Z.OuWLCzq/e1LbRgKFL.qhaH6K6HWXqQb4a', NULL, '2025-07-17 04:25:15', '2025-07-17 04:25:15', 'anggota'),
(994, 'Anggota 993', 'anggota993@gmail.com', NULL, '$2y$12$R9CWETbpeClR7kmfCtIfyumHiJq.4yHxJVUQzm1I87lvAc9gn3mMm', NULL, '2025-07-17 04:25:16', '2025-07-17 04:25:16', 'anggota'),
(995, 'Anggota 994', 'anggota994@gmail.com', NULL, '$2y$12$skVSFDS2ropViUdXF30uk.L0MdltffMJsGnmXpgN/sbkI4D30UnWa', NULL, '2025-07-17 04:25:16', '2025-07-17 04:25:16', 'anggota'),
(996, 'Anggota 995', 'anggota995@gmail.com', NULL, '$2y$12$uov3MtdxSh/HxcnkI90bruWHO5MDUjY2Th2ala7dHyuWM51q6hl.K', NULL, '2025-07-17 04:25:16', '2025-07-17 04:25:16', 'anggota'),
(997, 'Anggota 996', 'anggota996@gmail.com', NULL, '$2y$12$kPvRuC6..AlZfNPxj3guDeEm95Jg4u0DjD3iDMzY/CASbbgKz/oyS', NULL, '2025-07-17 04:25:17', '2025-07-17 04:25:17', 'anggota'),
(998, 'Anggota 997', 'anggota997@gmail.com', NULL, '$2y$12$XT9584Sn8gnjEsvYO4MfmOuY/Uf3CqxtNhzAnfnYgsphvg9fzV1n6', NULL, '2025-07-17 04:25:17', '2025-07-17 04:25:17', 'anggota'),
(999, 'Anggota 998', 'anggota998@gmail.com', NULL, '$2y$12$nQuXgzMBr46LueyhiLmYgOt95X8rARgKlV55J9vF6mvn6IF3PLn0i', NULL, '2025-07-17 04:25:18', '2025-07-17 04:25:18', 'anggota'),
(1000, 'Anggota 999', 'anggota999@gmail.com', NULL, '$2y$12$qJY.mRucrUkNaRbIIXGgxevFmSU8FRDw1iWKNqbM9N6NoXvbYQh5O', NULL, '2025-07-17 04:25:18', '2025-07-17 04:25:18', 'anggota');

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_horizontal_agenda`
-- (See below for the actual view)
--
CREATE TABLE `v_horizontal_agenda` (
`id` bigint unsigned
,`nama_agenda` varchar(255)
,`kategori` enum('kegiatan','rapat')
,`waktu_mulai` datetime
,`waktu_selesai` datetime
,`presensi_open` tinyint(1)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_insideview_kegiatan`
-- (See below for the actual view)
--
CREATE TABLE `v_insideview_kegiatan` (
`id` bigint unsigned
,`nama_agenda` varchar(255)
,`kategori` enum('kegiatan','rapat')
,`foto` varchar(255)
,`deskripsi` text
,`waktu_mulai` datetime
,`waktu_selesai` datetime
,`lokasi` varchar(255)
,`presensi_open` tinyint(1)
,`created_at` timestamp
,`updated_at` timestamp
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_vertical_kegiatan`
-- (See below for the actual view)
--
CREATE TABLE `v_vertical_kegiatan` (
`id` bigint unsigned
,`nama_agenda` varchar(255)
,`kategori` enum('kegiatan','rapat')
,`foto` varchar(255)
,`deskripsi` text
,`waktu_mulai` datetime
,`waktu_selesai` datetime
,`lokasi` varchar(255)
,`presensi_open` tinyint(1)
,`created_at` timestamp
,`updated_at` timestamp
);

-- --------------------------------------------------------

--
-- Structure for view `v_horizontal_agenda`
--
DROP TABLE IF EXISTS `v_horizontal_agenda`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_horizontal_agenda`  AS SELECT `agendas`.`id` AS `id`, `agendas`.`nama_agenda` AS `nama_agenda`, `agendas`.`kategori` AS `kategori`, `agendas`.`waktu_mulai` AS `waktu_mulai`, `agendas`.`waktu_selesai` AS `waktu_selesai`, `agendas`.`presensi_open` AS `presensi_open` FROM `agendas` ;

-- --------------------------------------------------------

--
-- Structure for view `v_insideview_kegiatan`
--
DROP TABLE IF EXISTS `v_insideview_kegiatan`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_insideview_kegiatan`  AS SELECT `v_vertical_kegiatan`.`id` AS `id`, `v_vertical_kegiatan`.`nama_agenda` AS `nama_agenda`, `v_vertical_kegiatan`.`kategori` AS `kategori`, `v_vertical_kegiatan`.`foto` AS `foto`, `v_vertical_kegiatan`.`deskripsi` AS `deskripsi`, `v_vertical_kegiatan`.`waktu_mulai` AS `waktu_mulai`, `v_vertical_kegiatan`.`waktu_selesai` AS `waktu_selesai`, `v_vertical_kegiatan`.`lokasi` AS `lokasi`, `v_vertical_kegiatan`.`presensi_open` AS `presensi_open`, `v_vertical_kegiatan`.`created_at` AS `created_at`, `v_vertical_kegiatan`.`updated_at` AS `updated_at` FROM `v_vertical_kegiatan` WHERE (`v_vertical_kegiatan`.`presensi_open` = 1)WITH LOCAL CHECK OPTION  ;

-- --------------------------------------------------------

--
-- Structure for view `v_vertical_kegiatan`
--
DROP TABLE IF EXISTS `v_vertical_kegiatan`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_vertical_kegiatan`  AS SELECT `agendas`.`id` AS `id`, `agendas`.`nama_agenda` AS `nama_agenda`, `agendas`.`kategori` AS `kategori`, `agendas`.`foto` AS `foto`, `agendas`.`deskripsi` AS `deskripsi`, `agendas`.`waktu_mulai` AS `waktu_mulai`, `agendas`.`waktu_selesai` AS `waktu_selesai`, `agendas`.`lokasi` AS `lokasi`, `agendas`.`presensi_open` AS `presensi_open`, `agendas`.`created_at` AS `created_at`, `agendas`.`updated_at` AS `updated_at` FROM `agendas` WHERE (`agendas`.`kategori` = 'kegiatan') ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `agendas`
--
ALTER TABLE `agendas`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_kategori_presensi` (`kategori`,`presensi_open`);

--
-- Indexes for table `agenda_logs`
--
ALTER TABLE `agenda_logs`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `banners`
--
ALTER TABLE `banners`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `dana_lains`
--
ALTER TABLE `dana_lains`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `failed_jobs`
--
ALTER TABLE `failed_jobs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`);

--
-- Indexes for table `hutangs`
--
ALTER TABLE `hutangs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `hutangs_user_id_foreign` (`user_id`);

--
-- Indexes for table `identitas`
--
ALTER TABLE `identitas`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `identitas_user_id_unique` (`user_id`);

--
-- Indexes for table `kas`
--
ALTER TABLE `kas`
  ADD PRIMARY KEY (`id`),
  ADD KEY `kas_user_id_foreign` (`user_id`),
  ADD KEY `idx_deskripsi_tanggal` (`deskripsi`(100),`tanggal`);

--
-- Indexes for table `kategoris`
--
ALTER TABLE `kategoris`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `kategori_konten`
--
ALTER TABLE `kategori_konten`
  ADD PRIMARY KEY (`konten_id`,`kategori_id`),
  ADD KEY `kategori_konten_kategori_id_foreign` (`kategori_id`);

--
-- Indexes for table `keluargas`
--
ALTER TABLE `keluargas`
  ADD PRIMARY KEY (`id`),
  ADD KEY `keluargas_undangan_id_foreign` (`undangan_id`);

--
-- Indexes for table `kontens`
--
ALTER TABLE `kontens`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `logs_kas`
--
ALTER TABLE `logs_kas`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_user_tanggal` (`user_id`,`tanggal`);

--
-- Indexes for table `migrations`
--
ALTER TABLE `migrations`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `notulens`
--
ALTER TABLE `notulens`
  ADD PRIMARY KEY (`id`),
  ADD KEY `notulens_agenda_id_foreign` (`agenda_id`);

--
-- Indexes for table `password_reset_tokens`
--
ALTER TABLE `password_reset_tokens`
  ADD PRIMARY KEY (`email`);

--
-- Indexes for table `peminjamans`
--
ALTER TABLE `peminjamans`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `peminjamans_user_id_perlengkapan_id_unique` (`user_id`,`perlengkapan_id`),
  ADD KEY `peminjamans_perlengkapan_id_foreign` (`perlengkapan_id`);

--
-- Indexes for table `pengeluarans`
--
ALTER TABLE `pengeluarans`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `perlengkapans`
--
ALTER TABLE `perlengkapans`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `personal_access_tokens_token_unique` (`token`),
  ADD KEY `personal_access_tokens_tokenable_type_tokenable_id_index` (`tokenable_type`,`tokenable_id`);

--
-- Indexes for table `presensis`
--
ALTER TABLE `presensis`
  ADD PRIMARY KEY (`id`),
  ADD KEY `presensis_agenda_id_foreign` (`agenda_id`),
  ADD KEY `presensis_user_id_foreign` (`user_id`);

--
-- Indexes for table `strukturs`
--
ALTER TABLE `strukturs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `strukturs_user_id_unique` (`user_id`);

--
-- Indexes for table `undangans`
--
ALTER TABLE `undangans`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `users_email_unique` (`email`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `agendas`
--
ALTER TABLE `agendas`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `agenda_logs`
--
ALTER TABLE `agenda_logs`
  MODIFY `id` bigint NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `banners`
--
ALTER TABLE `banners`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `dana_lains`
--
ALTER TABLE `dana_lains`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `failed_jobs`
--
ALTER TABLE `failed_jobs`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `hutangs`
--
ALTER TABLE `hutangs`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=994;

--
-- AUTO_INCREMENT for table `identitas`
--
ALTER TABLE `identitas`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `kas`
--
ALTER TABLE `kas`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=40;

--
-- AUTO_INCREMENT for table `kategoris`
--
ALTER TABLE `kategoris`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `keluargas`
--
ALTER TABLE `keluargas`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `kontens`
--
ALTER TABLE `kontens`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `logs_kas`
--
ALTER TABLE `logs_kas`
  MODIFY `id` bigint NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `migrations`
--
ALTER TABLE `migrations`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=29;

--
-- AUTO_INCREMENT for table `notulens`
--
ALTER TABLE `notulens`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `peminjamans`
--
ALTER TABLE `peminjamans`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `pengeluarans`
--
ALTER TABLE `pengeluarans`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `perlengkapans`
--
ALTER TABLE `perlengkapans`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `presensis`
--
ALTER TABLE `presensis`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `strukturs`
--
ALTER TABLE `strukturs`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `undangans`
--
ALTER TABLE `undangans`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1001;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `hutangs`
--
ALTER TABLE `hutangs`
  ADD CONSTRAINT `hutangs_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `identitas`
--
ALTER TABLE `identitas`
  ADD CONSTRAINT `identitas_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `kas`
--
ALTER TABLE `kas`
  ADD CONSTRAINT `kas_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `kategori_konten`
--
ALTER TABLE `kategori_konten`
  ADD CONSTRAINT `kategori_konten_kategori_id_foreign` FOREIGN KEY (`kategori_id`) REFERENCES `kategoris` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `kategori_konten_konten_id_foreign` FOREIGN KEY (`konten_id`) REFERENCES `kontens` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `keluargas`
--
ALTER TABLE `keluargas`
  ADD CONSTRAINT `keluargas_undangan_id_foreign` FOREIGN KEY (`undangan_id`) REFERENCES `undangans` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `notulens`
--
ALTER TABLE `notulens`
  ADD CONSTRAINT `notulens_agenda_id_foreign` FOREIGN KEY (`agenda_id`) REFERENCES `agendas` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `peminjamans`
--
ALTER TABLE `peminjamans`
  ADD CONSTRAINT `peminjamans_perlengkapan_id_foreign` FOREIGN KEY (`perlengkapan_id`) REFERENCES `perlengkapans` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `peminjamans_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `presensis`
--
ALTER TABLE `presensis`
  ADD CONSTRAINT `presensis_agenda_id_foreign` FOREIGN KEY (`agenda_id`) REFERENCES `agendas` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `presensis_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `strukturs`
--
ALTER TABLE `strukturs`
  ADD CONSTRAINT `strukturs_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
